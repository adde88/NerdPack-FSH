local n_name, FSH = ...

-- Offsets
local OBJECT_BOBBING_OFFSET = nil

-- APIs
local GameVer = select(2, GetBuildInfo())
GameVer = tonumber(GameVer)
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetItemCount = GetItemCount
local GetContainerItemID = GetContainerItemID
local PickupContainerItem = PickupContainerItem
local CursorHasItem = CursorHasItem
local DeleteCursorItem = DeleteCursorItem
local GetItemInfo = GetItemInfo
local AutoEquipCursorItem = AutoEquipCursorItem
local UnitBuff = UnitBuff
local InteractUnit = InteractUnit
local UseItem = UseItem
local GetTime = GetTime
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetSpellInfo = GetSpellInfo
local UnitCastingInfo = UnitCastingInfo
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local GetNumLootItems = GetNumLootItems
local wipe = wipe
local GetLootSlotInfo = GetLootSlotInfo
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetInventoryItemID = GetInventoryItemID
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemLink = GetInventoryItemLink
local C_Timer = C_Timer
local JumpOrAscendStart = JumpOrAscendStart
local GetCVar = GetCVar
local SetCVar = SetCVar
local CastSpellByID = CastSpellByID

-- Vars
local NeP         = NeP
FSH.fishRun       = false
FSH.timeStarted   = nil
FSH.Lootedcounter = 0
FSH.currentGear   = {}
FSH.FshSpell      = 131474
FSH.BobberID      = 35591
FSH.DoCountLoot   = false
FSH.autoloot      = GetCVar("autoLootDefault")

-- Advanced APIs
local ObjectExists = ObjectExists
local ObjectPointer = ObjectPointer
local ObjectField = ObjectField
local ObjectCreator = UnitCreator
local GetOffset = GetOffset
local GameObjectIsAnimating = GameObjectIsAnimating

-- Offsets change betweem 64bit and 32bit
local function FindOffsets()
	-- From EWT's
	if GetOffset then
		OBJECT_BOBBING_OFFSET = GetOffset("CGGameObject_C__Animation")
	--From Table
elseif FSH.X64.OBJECT_BOBBING_OFFSET[GameVer] then
		OBJECT_BOBBING_OFFSET = FSH.X64.OBJECT_BOBBING_OFFSET[GameVer]
	-- Defaults
	else
		NeP.Core:Print(n_name, 'Missing the Offsets for', GameVer, "Trying the default ones...")
		OBJECT_BOBBING_OFFSET = 0x1C4
	end
	return true
end

local function ItemInBag( ItemID )
	local ItemCount = 0
	local ItemFound = false
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			if select(10, GetContainerItemInfo(bag, slot)) == ItemID then
				ItemFound = true
				ItemCount = ItemCount + select(2, GetContainerItemInfo(bag, slot))
			end
		end
	end
	if ItemFound then
		return true, ItemCount
	end
	return false, 0
end

local function pickupItem(item)
	if not GetItemCount(item, false, false) > 0 then return end
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			if GetContainerItemID(bag, slot) == item then PickupContainerItem(bag, slot) end
		end
	end
end

local function deleteItem(ID, number)
	if GetItemCount(ID, false, false) > number then
		pickupItem(ID)
		if CursorHasItem() then
			DeleteCursorItem();
		end
	end
end

function FSH:equipNormalGear()
	if #self.currentGear > 0 then
		for k=1, #self.currentGear do
			NeP.Core:Print(n_name, '(Reseting Gear): '..GetItemInfo(self.currentGear[k])..' (remaning): '..#self.currentGear)
			pickupItem(self.currentGear[k])
			AutoEquipCursorItem()
		end
	end
	wipe(self.currentGear)
end

NeP.Listener:Add(n_name, "LOOT_READY", function()
	for i=1,GetNumLootItems() do
		local lootQuantity = select(3, GetLootSlotInfo(i))
		FSH.Lootedcounter = FSH.Lootedcounter + lootQuantity
		FSH.GUI.elements['current_average'].parent:SetText(
			math.floor(3600 / (GetTime() - FSH.timeStarted) * FSH.Lootedcounter)
		)
	end
end)

local function IsObjectCreatedBy(owner, object)
	local creator = ObjectCreator(object)
	return creator and creator == ObjectPointer(owner)
end

local BobberCache = nil
local function getBobber()
	if BobberCache and ObjectExists(BobberCache) then return BobberCache end
	for _, Obj in pairs(NeP.OM:Get('Objects')) do
		if FSH.BobberID == Obj.id then
			if IsObjectCreatedBy('player', Obj.key) then
				BobberCache = Obj.key
				return BobberCache
			end
		end
	end
end

local HookCD = 0
function FSH:FishHook()
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface:Fetch(n_name, 'ApplyFSH.FishHooks') and GetTime() > HookCD
	and select(7, GetItemInfo(GetInventoryItemLink('player', 16))) == 'Fishing Poles' then
		local hasEnchant, timeleft, _, enchantID = GetWeaponEnchantInfo()
		if hasEnchant and timeleft / 1000 > 15 then
			-- if we have the item enchant don't run.
			for i=1,#self.FishHooks do
				if enchantID == self.FishHooks[i].BuffID then return end
			end
			for i=1,#self.FishHooks do
				local HasItem, Count = ItemInBag(self.FishHooks[i].ItemID)
				if HasItem then
					HookCD = GetTime() + 5 -- it seems to be chain casting it otherwise :S
					UseItem(self.FishHooks[i].ItemID)
					NeP.Core:Print(n_name, '(Used Hook): '..self.FishHooks[i].ItemName..' ' ..tostring(Count - 1)..' left.' )
					return true
				end
			end
		end
	end
end

local BladeBoneCD = 0
function FSH.BladeBone()
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface:Fetch(n_name, 'BladeBoneHook') and GetTime() > BladeBoneCD then
		local expires = select(7, UnitBuff('player', GetSpellInfo(182226)))
		if expires and expires - GetTime() > 15 then return end
		local HasItem, Count = ItemInBag(122742)
		if HasItem then
			BladeBoneCD = GetTime() + 5 -- it seems to be chain casting it otherwise :S
			UseItem(122742)
			NeP.Core:Print(n_name, '(Used Hook): '..GetSpellInfo(182226)..' ' ..tostring(Count - 1)..' left.' )
			return true
		end
	end
end

function FSH:findHats()
	for i = 1, #self.hatsTable do
		if GetItemCount(self.hatsTable[i].ID, false, false) > 0 then
			self.HatsCache[#FSH.HatsCache+1] = {
				ID = self.hatsTable[i].ID,
				Name = self.hatsTable[i].Name,
				Bonus = self.hatsTable[i].Bonus
			}
		end
	end
	table.sort(self.HatsCache, function(a,b) return a.Bonus > b.Bonus end)
end

function FSH:equitHat()
	if NeP.Interface:Fetch(n_name, 'FshHat') then
		local hatsFound = self.HatsCache
		if #hatsFound > 0 then
			local headItemID = GetInventoryItemID('player', 1)
			local bestHat = hatsFound[1]
			if headItemID ~= bestHat.ID then
				NeP.Core:Print(n_name, '(Equiped): '..bestHat.Name)
				FSH.currentGear[#FSH.currentGear+1] = headItemID
				pickupItem(bestHat.ID)
				AutoEquipCursorItem()
			end
		end
	end
end

function FSH:findPoles()
	for i = 1, #self.polesTable do
		if GetItemCount(self.polesTable[i].ID, false, false) > 0 then
			--print('found:'..self.polesTable[i].Name)
			self.PolesCache[#self.PolesCache+1] = {
				ID = self.polesTable[i].ID,
				Name = self.polesTable[i].Name,
				Bonus = self.polesTable[i].Bonus
			}
		end
	end
	table.sort(self.PolesCache, function(a,b) return a.Bonus > b.Bonus end)
end

function FSH:equitPole()
	if NeP.Interface:Fetch(n_name, 'FshPole') then
		local polesFound = self:findPoles()
		if #polesFound > 0 then
			local weaponItemID = GetInventoryItemID('player', 16)
			local bestPole = polesFound[1]
			if weaponItemID ~= bestPole.ID then
				NeP.Core:Print(n_name, '(Equiped): '..bestPole.Name)
				FSH.currentGear[#FSH.currentGear+1] = weaponItemID
				-- Also equip OffHand if user had one.
				if GetInventoryItemID('player', 17) then
					FSH.currentGear[#FSH.currentGear+1] = GetInventoryItemID('player', 17)
				end
				pickupItem(bestPole.ID)
				AutoEquipCursorItem()
			end
		end
	end
end

function FSH:AutoBait()
	if NeP.Interface:Fetch(n_name, 'bait') ~= 'none' or NeP.Interface:Fetch(n_name, 'bait') ~= nil then
		if self.baitsTable[NeP.Interface:Fetch(n_name, 'bait')] ~= nil then
			local _Bait = self.baitsTable[NeP.Interface:Fetch(n_name, 'bait')]
			if GetItemCount(_Bait.ID, false, false) > 0 then
				local endtime = select(7, UnitBuff('player', GetSpellInfo(_Bait.Debuff)))
				if (not endtime) or endtime < GetTime() + 14 then
					NeP.Core:Print(n_name, '(Used Bait): '.._Bait.Name)
					UseItem(_Bait.ID)
				end
			end
		end
	end
end

function FSH.CarpDestruction()
	if NeP.Interface:Fetch(n_name, 'LunarfallCarp') then
		deleteItem(116158, 0)
	end
end

local function FormatTime( seconds )
	if not seconds then return '0 Seconds' end
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds / 60) % 60)
	seconds = seconds % 60
	local firstrow = hours == 1 and hours .. ' Hour ' or hours > 1 and hours .. ' Hours ' or ''
	local secondrow = minutes == 1 and minutes .. ' Minute ' or minutes > 1 and minutes .. ' Minutes ' or ''
	local thirdrow = seconds == 1 and seconds .. ' Second ' or seconds > 1 and seconds .. ' Seconds ' or ''
	return firstrow .. secondrow .. thirdrow
end

function FSH.BagSpace()
	local freeslots = 0
	for lbag = 0, NUM_BAG_SLOTS do
		local numFreeSlots = GetContainerNumFreeSlots(lbag)
		freeslots = freeslots + numFreeSlots
	end
	return freeslots
end

function FSH.Start(self)
	if FSH.fishRun then
		self:SetText('Start Fishing')
		JumpOrAscendStart() -- Jump to stop channeling.
		FSH:equipNormalGear()
		FSH.timeStarted = nil
		SetCVar("autoLootDefault", FSH.autoloot)
		--Rebuild cache
		FSH.HatsCache = {}
		FSH:findHats()
		FSH.PolesCache = {}
		FSH:findPoles()
	else
		self:SetText('Stop Fishing')
		local currentTime = GetTime()
		FSH.timeStarted = currentTime
		FSH.Lootedcounter = 0
		SetCVar("autoLootDefault", "1")
	end
	FSH.fishRun = not FSH.fishRun
end

local function IsAnimating(BobberObject)
	if GameObjectIsAnimating then
		return GameObjectIsAnimating(BobberObject)
	else
		if not OBJECT_BOBBING_OFFSET then FindOffsets() end
		return ObjectField(BobberObject, OBJECT_BOBBING_OFFSET, FSH.Types.Bool)
	end
end

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
	if IsAnimating(BobberObject) then
		InteractUnit(BobberObject)
		FSH.DoCountLoot = true
	end
end

C_Timer.NewTicker(0.5, (function()
	if not FSH.fishRun then return end
	if FSH:BagSpace() < 2 then NeP.Core:Print(n_name, 'Not Enough Bag Space.'); return end
	-- Update GUI Elements (FIXME: current GUI stuff does not work like this anymore)
	if FSH.timeStarted then
		local time = FormatTime(NeP.Core:Round(GetTime() - FSH.timeStarted))
		FSH.GUI.elements['current_Time'].parent:SetText(time)
		FSH.GUI.elements['current_Loot'].parent:SetText(FSH.Lootedcounter)
	end
	-- Get BobberObject
	local BobberObject = getBobber()
	if not BobberObject then StartFishing() end
	if BobberObject then Interact(BobberObject)end
end), nil)
