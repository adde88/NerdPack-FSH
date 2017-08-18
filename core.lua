local n_name, FSH = ...
FSH.Version = 1.5
local GameVer = select(2, GetBuildInfo())
GameVer = tonumber(GameVer)
local InteractUnit = InteractUnit
local C_Timer = C_Timer
local JumpOrAscendStart = JumpOrAscendStart
local GetCVar = GetCVar
local SetCVar = SetCVar
local CastSpellByID = CastSpellByID
local GetLootSlotInfo = GetLootSlotInfo
local InCombatLockdown = InCombatLockdown
local GetNumLootItems = GetNumLootItems
local GetTime = GetTime

-- Advanced APIs
local ObjectExists = ObjectExists
local ObjectPointer = ObjectPointer
local ObjectField = ObjectField
local ObjectCreator = ObjectCreator
local GetOffset = GetOffset
local GameObjectIsAnimating = GameObjectIsAnimating

--temp workaround until EWT and FH update
local ObjectDescriptor = ObjectDescriptor
local Types = Types
ObjectCreator = ObjectCreator or function(Obj) return ObjectDescriptor(Obj, 0x30, Types.GUID) end
GameObjectIsAnimating = GameObjectIsAnimating or function(Obj) return ObjectField(Obj, 0x1C4, Types.Bool) end

-- Vars
local NeP         = NeP
FSH.fishRun       = false
FSH.timeStarted   = nil
FSH.Lootedcounter = 0
FSH.currentGear   = {}
FSH.FshSpell      = 131474
FSH.BobberID      = {
	35591,
	245190 -- Oversized bobber
}
FSH.DoCountLoot   = false
FSH.autoloot      = GetCVar("autoLootDefault")

local function IsObjectCreatedBy(owner, object)
	local creator = ObjectCreator(object)
	return creator and creator == ObjectPointer(owner)
end

local BobberCache = nil
local function getBobber()
	if BobberCache and ObjectExists(BobberCache) then return BobberCache end
	for _, Obj in pairs(NeP.OM:Get('Objects')) do
		for i=1, #FSH.BobberID do
			if FSH.BobberID[i] == Obj.id then
				if IsObjectCreatedBy('player', Obj.key) then
					BobberCache = Obj.key
					return BobberCache
				end
			end
		end
	end
end

function FSH.FormatTime(_, seconds)
	if not seconds then return '0 Seconds' end
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds / 60) % 60)
	seconds = seconds % 60
	local firstrow = hours == 1 and hours .. ' Hour ' or hours > 1 and hours .. ' Hours ' or ''
	local secondrow = minutes == 1 and minutes .. ' Minute ' or minutes > 1 and minutes .. ' Minutes ' or ''
	local thirdrow = seconds == 1 and seconds .. ' Second ' or seconds > 1 and seconds .. ' Seconds ' or ''
	return firstrow .. secondrow .. thirdrow
end

function FSH:Start(val)
	if FSH.fishRun then
		val:SetText('Start Fishing')
		JumpOrAscendStart() -- Jump to stop channeling.
		self:equipNormalGear()
		self.timeStarted = nil
		SetCVar("autoLootDefault", FSH.autoloot)
	else
		val:SetText('Stop Fishing')
		local currentTime = GetTime()
		self.timeStarted = currentTime
		self.Lootedcounter = 0
		SetCVar("autoLootDefault", "1")
    --Rebuild cache
		self.HatsCache = {}
		self:findHats()
		self.PolesCache = {}
		self:findPoles()
	end
	self.fishRun = not self.fishRun
end

NeP.Listener:Add(n_name, "LOOT_READY", function()
	if not FSH.timeStarted then return end
	for i=1,GetNumLootItems() do
		local lootQuantity = select(3, GetLootSlotInfo(i))
		FSH.Lootedcounter = FSH.Lootedcounter + lootQuantity
		FSH.GUI.elements['current_average'].parent:SetText(
			math.floor(3600 / (GetTime() - FSH.timeStarted) * FSH.Lootedcounter)
		)
	end
end)

local FishCD = 0

local function StartFishing()
	FSH:CarpDestruction()
	FSH:equitHat()
	FSH:equitPole()
	FSH:AutoBait()
	if FSH:FishHook() then return end -- If it is true we stop because we have to wait.
	if FSH:BladeBone() then return end -- Same here
	--Start fishing
	if (not InCombatLockdown())
	and GetNumLootItems() == 0
	and FishCD < GetTime() then -- not in combat, not looting, and not soon after trying to cast fishing.
		FishCD = GetTime() + 2
		CastSpellByID(FSH.FshSpell)
	end
end

local function Interact(BobberObject)
	if GameObjectIsAnimating(BobberObject) then
		InteractUnit(BobberObject)
		FSH.DoCountLoot = true
	end
end

C_Timer.NewTicker(0.5, (function()
	if not FSH.fishRun then return end
	if FSH:BagSpace() < 2 then NeP.Core:Print(n_name, 'Not Enough Bag Space.'); return end
	-- Update GUI Elements (FIXME: current GUI stuff does not work like this anymore)
	if FSH.timeStarted then
		local time = FSH:FormatTime(NeP.Core:Round(GetTime() - FSH.timeStarted))
		FSH.GUI.elements['current_Time']:SetText(time)
		FSH.GUI.elements['current_Loot']:SetText(FSH.Lootedcounter)
	end
	-- Get BobberObject
	local BobberObject = getBobber()
	if not BobberObject then StartFishing() end
	if BobberObject then Interact(BobberObject)end
end), nil)
