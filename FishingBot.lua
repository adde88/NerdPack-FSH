local n_name, FSH = ...

-- Offsets
local OBJECT_BOBBING_OFFSET = nil
local OBJECT_CREATOR_OFFSET = nil

-- APIs
local GameVer                  = select(2, GetBuildInfo())
GameVer                        = tonumber(GameVer)
local GetContainerNumSlots     = GetContainerNumSlots
local GetContainerItemInfo     = GetContainerItemInfo
local GetItemCount             = GetItemCount
local GetContainerItemID       = GetContainerItemID
local PickupContainerItem      = PickupContainerItem
local CursorHasItem            = CursorHasItem
local DeleteCursorItem         = DeleteCursorItem
local GetItemInfo              = GetItemInfo
local AutoEquipCursorItem      = AutoEquipCursorItem
local UnitBuff                 = UnitBuff
local InteractUnit             = InteractUnit
local UseItem                  = UseItem
local GetTime                  = GetTime
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetSpellInfo             = GetSpellInfo
local UnitCastingInfo          = UnitCastingInfo
local NUM_BAG_SLOTS            = NUM_BAG_SLOTS
local GetNumLootItems          = GetNumLootItems
local wipe                     = wipe
local GetLootSlotInfo          = GetLootSlotInfo
local CreateFrame              = CreateFrame
local InCombatLockdown         = InCombatLockdown
local GetInventoryItemID       = GetInventoryItemID
local GetWeaponEnchantInfo     = GetWeaponEnchantInfo
local GetInventoryItemLink     = GetInventoryItemLink
local C_Timer                  = C_Timer
local JumpOrAscendStart        = JumpOrAscendStart
local GetCVar                  = GetCVar
local SetCVar                  = SetCVar

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
local EWT              = EWT
local FireHack         = FireHack
local IsHackEnabled    = IsHackEnabled
local ObjectExists     = ObjectExists
local ObjectDescriptor = ObjectDescriptor
local ObjectField      = ObjectField

-- Offsets change betweem 64bit and 32bit
function FSH:SetOffsets()
	-- From EWT's
	if EWT then
		OBJECT_BOBBING_OFFSET = GetOffset("CGGameObject_C__Animation") 		
                OBJECT_CREATOR_OFFSET = GetDescriptor("CGGameObjectData", "CreatedBy")
	--From Table
	elseif self.X64.OBJECT_BOBBING_OFFSET[GameVer] and self.X64.OBJECT_CREATOR_OFFSET[GameVer] then
		OBJECT_BOBBING_OFFSET = self.X64.OBJECT_BOBBING_OFFSET[GameVer]
		OBJECT_CREATOR_OFFSET = self.X64.OBJECT_CREATOR_OFFSET[GameVer]
	-- Defaults
	else
		NeP.Core:Print(n_name, 'Missing the Offsets for', GameVer, "Trying the default ones...")
		OBJECT_BOBBING_OFFSET = 0x1C4
		OBJECT_CREATOR_OFFSET = 0x030
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
	if GetItemCount(item, false, false) > 0 then
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(bag) do
				if GetContainerItemID(bag, slot) == item then
					PickupContainerItem(bag, slot)
				end
			end
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

--[[-----------------------------------------------
** FSH:equipNormalGear **
DESC: Equip the gear we had before starting.

Build By: MTS
---------------------------------------------------]]
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

--[[-----------------------------------------------
** FSH.DoCountLoot **
DESC: Counts the loot from fishing.

Build By: darkjacky @ github
---------------------------------------------------]]
local CounterFrame = CreateFrame('frame')
CounterFrame:RegisterEvent('LOOT_READY')
CounterFrame:SetScript('OnEvent', function()
	if FSH.DoCountLoot then -- only count when triggered by FSH:startFish()
		FSH.DoCountLoot = false -- trigger once.
		for i=1,GetNumLootItems() do
			local lootQuantity = select(3, GetLootSlotInfo(i))
			FSH.Lootedcounter = FSH.Lootedcounter + lootQuantity
			NeP.Interface:GetElement(n_name, 'current_average'):SetText(math.floor(3600 / (GetTime() - FSH.timeStarted) * FSH.Lootedcounter))
		end
	end
end )

--[[-----------------------------------------------
** getBobber **
DESC: Gets the fishing bober object.
Only Suppoted by FH atm...

Build By: MTS
---------------------------------------------------]]
local function GetObjectGUID(object)
	if ObjectExists(object) then
		return tonumber(ObjectDescriptor(object, 0, FSH.Types.ULong))
	end
end

local function IsObjectCreatedBy(owner, object)
	if ObjectExists(owner) and ObjectExists(object) then
		return tonumber(ObjectDescriptor(object, OBJECT_CREATOR_OFFSET, FSH.Types.ULong)) == GetObjectGUID(owner)
	end
end

local BobberCache = nil
local function getBobber()
	if BobberCache and ObjectExists(BobberCache) then return BobberCache end
	for _, Obj in pairs(NeP.OM:Get('Objects')) do
		if FSH.BobberID == Obj.id then
			if IsObjectCreatedBy('player', Obj.key) then
				BobberCache = Obj.key
				return Obj.key
			end
		end
	end
end

--[[-----------------------------------------------
** FSH:startFish **
DESC: Actualy start fishing ;P

Build By: MTS
Modifed by: darkjacky @ github
---------------------------------------------------]]
local FishCD = 0
function FSH:startFish()
	local BobberObject = getBobber()
	if BobberObject then
		local bobbing = ObjectField(getBobber(), OBJECT_BOBBING_OFFSET, FSH.Types.Bool)
		if bobbing == true or bobbing == 1 then
			InteractUnit(getBobber())
			FSH.DoCountLoot = true
		end
	else
		if (not InCombatLockdown()) and GetNumLootItems() == 0 and FishCD < GetTime() then -- not in combat, not looting, and not soon after trying to cast fishing.
			FishCD = GetTime() + 2
			NeP:Queue(FSH.FshSpell)
		end
	end
end

--[[-----------------------------------------------
** FSH:FishHook **
DESC: Applies the best of any fishing hooks found in bag.

Build By: darkjacky @ github
---------------------------------------------------]]
local HookCD = 0
function FSH:FishHook()
	if getBobber() then return end -- if we are fishing we don't want to interrupt it.
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface:Fetch(n_name, 'ApplyFSH.FishHooks') and GetTime() > HookCD then
		if select(7, GetItemInfo(GetInventoryItemLink('player', 16))) == 'Fishing Poles' then
			local hasEnchant, timeleft, _, enchantID = GetWeaponEnchantInfo()
			if hasEnchant and timeleft / 1000 > 15 then
				for i=1,#self.FishHooks do
					if enchantID == self.FishHooks[i].BuffID then
						return -- if we have the item enchant don't run.
					end
				end
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

--[[-----------------------------------------------
** FSH:BladeBone **
DESC: Applies the best of any fishing hook found in bag.

Build By: darkjacky @ github
---------------------------------------------------]]
local BladeBoneCD = 0
function FSH:BladeBone()
	if getBobber() then return end -- if we are fishing we don't want to interrupt it.
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

--[[-----------------------------------------------
** Hats **
DESC: finds and equips fishing hats.

Build By: MTS
---------------------------------------------------]]
function FSH:findHats()
	local hatsFound = {}
	for i = 1, #self.hatsTable do
		if GetItemCount(self.hatsTable[i].ID, false, false) > 0 then
			hatsFound[#hatsFound+1] = {
				ID = self.hatsTable[i].ID,
				Name = self.hatsTable[i].Name,
				Bonus = self.hatsTable[i].Bonus
			}
		end
	end
	table.sort(hatsFound, function(a,b) return a.Bonus > b.Bonus end)
	return hatsFound
end

function FSH:equitHat()
	if NeP.Interface:Fetch(n_name, 'FshHat') then
		local hatsFound = self:findHats()
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

--[[-----------------------------------------------
** Poles **
DESC: finds and equips fishing Poles.

Build By: MTS
---------------------------------------------------]]
function FSH:findPoles()
	local polesFound = {}
	for i = 1, #self.polesTable do
		if GetItemCount(self.polesTable[i].ID, false, false) > 0 then
			--print('found:'..self.polesTable[i].Name)
			polesFound[#polesFound+1] = {
				ID = self.polesTable[i].ID,
				Name = self.polesTable[i].Name,
				Bonus = self.polesTable[i].Bonus
			}
		end
	end
	table.sort(polesFound, function(a,b) return a.Bonus > b.Bonus end)
	return polesFound
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

--[[-----------------------------------------------
** Baits **
DESC: finds and equips fishing Baits.

Build By: MTS
---------------------------------------------------]]
function FSH:AutoBait()
	if getBobber() then return end
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

function FSH:CarpDestruction()
	if NeP.Interface:Fetch(n_name, 'LunarfallCarp') then
		deleteItem(116158, 0)
	end
end

--[[-----------------------------------------------
** FormatTime **
DESC: Takes seconds and returns H:M:S.

Build By: darkjacky @ Github
---------------------------------------------------]]
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

function FSH:BagSpace()
	local freeslots = 0
	for lbag = 0, NUM_BAG_SLOTS do
		local numFreeSlots = GetContainerNumFreeSlots(lbag)
		freeslots = freeslots + numFreeSlots
	end
	return freeslots
end

function FSH.Start(self)
	-- Required APIS
	if FSH:SetOffsets() then
		if FSH.fishRun then
			self:SetText('Start Fishing')
			JumpOrAscendStart() -- Jump to stop channeling.
			FSH:equipNormalGear()
			FSH.timeStarted = nil
			SetCVar("autoLootDefault", FSH.autoloot)
		else
			self:SetText('Stop Fishing')
			local currentTime = GetTime()
			FSH.timeStarted = currentTime
			FSH.Lootedcounter = 0
			SetCVar("autoLootDefault", "1")
		end
		FSH.fishRun = not FSH.fishRun
		-- turn on the mastertoggle
		if not NeP.DSL:Get('toggle')(_, 'mastertoggle') then
			NeP.Interface:toggleToggle('mastertoggle')
		end
	end
end

C_Timer.NewTicker(0.5, (function()

	if not FSH.fishRun then return end
	if FSH:BagSpace() < 2 then NeP.Core:Print(n_name, 'Not Enough Bag Space.'); return end

	-- Update GUI Elements (FIXME: current GUI stuff does not work like this anymore)
	if FSH.timeStarted then
		local time = FormatTime(NeP.Core:Round(GetTime() - FSH.timeStarted))
		NeP.Interface:GetElement(n_name, 'current_Time'):SetText(time)
		NeP.Interface:GetElement(n_name, 'current_Loot'):SetText(FSH.Lootedcounter)
	end

	FSH:CarpDestruction()
	FSH:equitHat()
	FSH:equitPole()
	FSH:AutoBait()
	if FSH:FishHook() then return end -- If it is true we stop because we have to wait.
	if FSH:BladeBone() then return end -- Same here
	FSH:startFish()

end), nil)
