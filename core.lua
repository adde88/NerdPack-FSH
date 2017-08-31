local n_name, FSH = ...
FSH.Version = 1.6
local GameVer = select(2, GetBuildInfo())
GameVer = tonumber(GameVer)

-- Advanced APIs

--temp workaround until EWT and FH update
ObjectCreator = ObjectCreator or function(Obj) return GetObjectDescriptorAccessor(Obj, 0x30, Type.GUID) end
GameObjectIsAnimating = GameObjectIsAnimating or function(Obj) return GetObjectFieldAccessor(Obj, 0x1C4, Type.Bool) end

-- Vars
local NeP         = NeP
FSH.fishRun       = false
FSH.timeStarted   = nil
FSH.Lootedcounter = 0
FSH.currentGear   = {}
FSH.FshSpell      = 131474

-- List of bobbers
FSH.BobberID      = {
	35591, 	-- noob
	245190, -- Oversized bobber
	241593, -- Can of Worms
	241594, -- Cat Head
	266869, -- Wooden Pepe
	241592, --Tugboat
}

FSH.DoCountLoot   = false
FSH.autoloot      = GetCVar("autoLootDefault")

local function IsObjectCreatedBy(owner, object)
	local creator = ObjectCreator(object)
	return creator and creator == ObjectIdentifier(owner)
end

local BobberCache = nil
local function getBobber()
	if BobberCache and ObjectIsVisible(BobberCache) then return BobberCache end
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
		FSH.GUI.elements['current_average']:SetText(
			math.floor(3600 / (GetTime() - FSH.timeStarted) * FSH.Lootedcounter)
		)
	end
end)

local FishCD = 0
local loopfuncs = {
	"equitHat",
	"equitPole",
	"AutoBait",
	"FishHook",
	"BladeBone",
	"LeyscaleKoi"
}

local function StartFishing()
	-- delay
	if FishCD > GetTime() then return end
	--stop if any of these is true
	for i=1, #loopfuncs do
		if FSH[loopfuncs[i]](FSH) then return end
	end
	--Start fishing
	if (not InCombatLockdown())
	and GetNumLootItems() == 0 then
		CastSpellByID(FSH.FshSpell)
	end
	FishCD = GetTime() + 2
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
