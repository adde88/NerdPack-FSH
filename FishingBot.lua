local _, FSH = ...

-- Offsets
local OBJECT_BOBBING_OFFSET = nil
local OBJECT_CREATOR_OFFSET = nil

-- Vars
local _fishRun = false
local _timeStarted = nil
local _Lootedcounter = 0
local FshSpell = 131474

-- Offsets change betweem 64bit and 32bit
local function SetOffsets()
	if EWT then
		OBJECT_BOBBING_OFFSET = 0xF8
		OBJECT_CREATOR_OFFSET = 0x30
	elseif FireHack then
		OBJECT_BOBBING_OFFSET = 0x1C4
		OBJECT_CREATOR_OFFSET = 0x30
	end
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
				currentItemID = GetContainerItemID(bag, slot)
				if currentItemID == item then
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
** equipNormalGear **
DESC: Equip the gear we had before starting.

Build By: MTS
---------------------------------------------------]]
local _currentGear = {}
local function equipNormalGear()
	if #_currentGear > 0 then
		for k=1, #_currentGear do
			NeP.Core:Print('[Fishing Bot]: (Reseting Gear): '..GetItemInfo(_currentGear[k])..' (remaning): '..#_currentGear)
			pickupItem(_currentGear[k])
			AutoEquipCursorItem()
		end
	end
	wipe(_currentGear)
end

local function error(text)
	NeP.Core.Message(NeP.Interface.addonColor..'[Fishing Bot]|r: '..text)
end

--[[-----------------------------------------------
** DoCountLoot **
DESC: Counts the loot from fishing.

Build By: darkjacky @ github
---------------------------------------------------]]
local DoCountLoot = false
local CounterFrame = CreateFrame('frame')
CounterFrame:RegisterEvent('LOOT_READY')
CounterFrame:SetScript('OnEvent', function()
	if DoCountLoot then -- only count when triggered by FSH:startFish()
		DoCountLoot = false -- trigger once.
		for i=1,GetNumLootItems() do
			local lootIcon, lootName, lootQuantity, rarity, locked = GetLootSlotInfo(i)
			_Lootedcounter = _Lootedcounter + lootQuantity
			FSH.GUI.elements.current_average:SetText(math.floor(3600 / (GetTime() - _timeStarted) * _Lootedcounter))
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
		return tonumber(ObjectDescriptor(object, 0, Types.ULong))
	end
end

local function IsObjectCreatedBy(owner, object)
	if ObjectExists(owner) and ObjectExists(object) then
		return tonumber(ObjectDescriptor(object, OBJECT_CREATOR_OFFSET, Types.ULong)) == GetObjectGUID(owner)
	end
end

local BobberID = '35591'
local BobberCache = nil
local function getBobber()
	if BobberCache and ObjectExists(BobberCache) then return BobberCache end
	for i=1, #NeP.OM['GameObjects'] do
		local Obj = NeP.OM['GameObjects'][i]
		local oID = tostring(Obj.id)

		if BobberID == oID then
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
		local bobbing = ObjectField(getBobber(), OBJECT_BOBBING_OFFSET, Types.Bool)
		if bobbing == true or bobbing == 1 then
			InteractUnit(getBobber())
			DoCountLoot = true
		end
	else
		if (not InCombatLockdown()) and GetNumLootItems() == 0 and FishCD < GetTime() then -- not in combat, not looting, and not soon after trying to cast fishing.
			FishCD = GetTime() + 2
			NeP.Engine.Cast(FshSpell)
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
	if NeP.Interface:fetchKey('NeP_fishingBot', 'ApplyFSH.FishHooks') and GetTime() > HookCD then
		if select(7, GetItemInfo(GetInventoryItemLink('player', 16))) == 'Fishing Poles' then
			local hasEnchant, timeleft, _, enchantID = GetWeaponEnchantInfo()
			if hasEnchant and timeleft / 1000 > 15 then
				for i=1,#FSH.FishHooks do
					if enchantID == FSH.FishHooks[i].BuffID then
						return -- if we have the item enchant don't run.
					end
				end
			end
			for i=1,#FSH.FishHooks do
				local HasItem, Count = ItemInBag(FSH.FishHooks[i].ItemID)
				if HasItem then
					HookCD = GetTime() + 5 -- it seems to be chain casting it otherwise :S
					UseItem(FSH.FishHooks[i].ItemID)
					NeP.Core:Print('[Fishing Bot]: (Used Hook): '..FSH.FishHooks[i].ItemName..' ' ..tostring(Count - 1)..' left.' )
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
	if NeP.Interface:fetchKey('NeP_fishingBot', 'BladeBoneHook') and GetTime() > BladeBoneCD then
		local expires = select(7, UnitBuff('player', GetSpellInfo(182226)))
		if expires and expires - GetTime() > 15 then return end
		local HasItem, Count = ItemInBag(122742)
		if HasItem then
			BladeBoneCD = GetTime() + 5 -- it seems to be chain casting it otherwise :S
			UseItem(122742)
			NeP.Core:Print('[Fishing Bot]: (Used Hook): '..GetSpellInfo(182226)..' ' ..tostring(Count - 1)..' left.' )
			return true
		end
	end
end

--[[-----------------------------------------------
** Hats **
DESC: finds and equips fishing hats.

Build By: MTS
---------------------------------------------------]]
local function _findHats()
	local hatsFound = {}
	for i = 1, #FSH.hatsTable do
		if GetItemCount(FSH.hatsTable[i].ID, false, false) > 0 then
			hatsFound[#hatsFound+1] = {
				ID = FSH.hatsTable[i].ID,
				Name = FSH.hatsTable[i].Name,
				Bonus = FSH.hatsTable[i].Bonus
			}
		end
	end
	table.sort(hatsFound, function(a,b) return a.Bonus > b.Bonus end)
	return hatsFound
end

function FSH:equitHat()
	if NeP.Interface:fetchKey('NeP_fishingBot', 'FshHat') then
		local hatsFound = _findHats()
		if #hatsFound > 0 then
			local headItemID = GetInventoryItemID('player', 1)
			local bestHat = hatsFound[1]
			if headItemID ~= bestHat.ID then
				NeP.Core:Print('[Fishing Bot]: (Equiped): '..bestHat.Name)
				_currentGear[#_currentGear+1] = headItemID
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
local function _findPoles()
	local polesFound = {}
	for i = 1, #FSH.polesTable do
		if GetItemCount(FSH.polesTable[i].ID, false, false) > 0 then
			--print('found:'..FSH.polesTable[i].Name)
			polesFound[#polesFound+1] = {
				ID = FSH.polesTable[i].ID,
				Name = FSH.polesTable[i].Name,
				Bonus = FSH.polesTable[i].Bonus
			}
		end
	end
	table.sort(polesFound, function(a,b) return a.Bonus > b.Bonus end)
	return polesFound
end

function FSH:equitPole()
	if NeP.Interface:fetchKey('NeP_fishingBot', 'FshPole') then
		local polesFound = _findPoles()
		if #polesFound > 0 then
			local weaponItemID = GetInventoryItemID('player', 16)
			local bestPole = polesFound[1]
			if weaponItemID ~= bestPole.ID then
				NeP.Core:Print('[Fishing Bot]: (Equiped): '..bestPole.Name)
				_currentGear[#_currentGear+1] = weaponItemID
				-- Also equip OffHand if user had one.
				if GetInventoryItemID('player', 17) ~= nil then _currentGear[#_currentGear+1] = GetInventoryItemID('player', 17) end
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
	if NeP.Interface:fetchKey('NeP_fishingBot', 'bait') ~= 'none' or NeP.Interface:fetchKey('NeP_fishingBot', 'bait') ~= nil then
		if FSH.baitsTable[NeP.Interface:fetchKey('NeP_fishingBot', 'bait')] ~= nil then
			local _Bait = FSH.baitsTable[NeP.Interface:fetchKey('NeP_fishingBot', 'bait')]
			if GetItemCount(_Bait.ID, false, false) > 0 then
				local endtime = select(7, UnitBuff('player', GetSpellInfo(_Bait.Debuff)))
				if (not endtime) or endtime < GetTime() + 14 then
					NeP.Core:Print('[Fishing Bot]: (Used Bait): '.._Bait.Name)
					UseItem(_Bait.ID)
				end
			end
		end
	end
end

function FSH:CarpDestruction()
	if NeP.Interface:fetchKey('NeP_fishingBot', 'LunarfallCarp') then
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
	local seconds = seconds % 60
	
	local firstrow = hours == 1 and hours .. ' Hour ' or hours > 1 and hours .. ' Hours ' or ''
	local secondrow = minutes == 1 and minutes .. ' Minute ' or minutes > 1 and minutes .. ' Minutes ' or ''
	local thirdrow = seconds == 1 and seconds .. ' Second ' or seconds > 1 and seconds .. ' Seconds ' or ''

	return firstrow .. secondrow .. thirdrow
end

function FSH:BagSpace()
	local freeslots = 0
	for lbag = 0, NUM_BAG_SLOTS do
		numFreeSlots, BagType = GetContainerNumFreeSlots(lbag)
		freeslots = freeslots + numFreeSlots
	end
	return freeslots
end

C_Timer.NewTicker(0.5, (function()
					
	if _fishRun then
		if FSH:BagSpace() > 2 then

			-- Update GUI Elements
			if _timeStarted then
				FSH.GUI.elements.current_Time:SetText(FormatTime(NeP.Core.Round(GetTime() - _timeStarted)))
				FSH.GUI.elements.current_Loot:SetText(_Lootedcounter)
			end

			FSH:CarpDestruction()
			FSH:equitHat()
			FSH:equitPole()
			FSH:AutoBait()
			if FSH:FishHook() then return end -- If it is true we stop because we have to wait.
			if FSH:BladeBone() then return end -- Same here
			if IsHackEnabled then
				-- Only Works with FH atm, due to object handling...
				-- (if someday more unlockers alow this then abstract FH only stuff)
				FSH:startFish()
			end
		else
			error('Not Enough Bag Space.')
		end
	end

end), nil)
