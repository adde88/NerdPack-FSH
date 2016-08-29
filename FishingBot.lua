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
			NeP.Core.Print('[|cff'..NeP.Interface.addonColor..'Fishing Bot|r]: (Reseting Gear): '..GetItemInfo(_currentGear[k])..' (remaning): '..#_currentGear)
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
** GUI table **
---------------------------------------------------]]
local config = {
	key = 'NePfishingBot',
	profiles = true,
	title = '|T'..NeP.Interface.Logo..':10:10|t'..' '..NeP.Info.Name,
	subtitle = 'Fishing Bot Settings',
	color = NeP.Interface.addonColor,
	width = 250,
	height = 310,
	config = {
		{ type = 'header', text = '|cff'..NeP.Interface.addonColor..'Fishing Bot', size = 25, align = 'Center'},
		{ type = 'text', text = NeP.FSH.Version, align = 'Center'},
		{ type = 'text', text = '|cfffd1c15[Warning]|r Requires A Supported Unlocker', align = 'Center' },
		-- [[ Settings ]]
		{ type = 'rule' },{ type = 'spacer' },
			{ type = 'dropdown', text = 'Bait:', key = 'bait', width = 170, list = {
				{text = 'None', key = 'none'},	
				{text = 'Jawless Skulker', key = 'jsb'},
				{text = 'Fat Sleeper', key = 'fsb'},
				{text = 'Blind Lake Sturgeon', key = 'blsb'},
				{text = 'Fire Ammonite', key = 'fab'},
				{text = 'Sea Scorpion', key = 'ssb'},
				{text = 'Abyssal Gulper Eel', key = 'ageb'},
				{text = 'Blackwater Whiptail', key = 'bwb'},
			}, default = 'none' },
			{ type = 'checkbox', text = 'Use Fishing Hat', key = 'FshHat', default = true },
			{ type = 'checkbox', text = 'Use Fishing Poles', key = 'FshPole', default = true },
			{ type = 'checkbox', text = 'Use Fish Hooks', key = 'ApplyFishHooks', default = true },
			{ type = 'checkbox', text = 'Use Bladebone Hooks', key = 'BladeBoneHook', default = false },
			{  type = 'checkbox',  text = 'Destroy Lunarfall Carp', key = 'LunarfallCarp', default = false },
		-- [[ Timer ]]
			{ type = 'rule' },{ type = 'spacer' },
			{ type = 'text', text = '|cff'..NeP.Interface.addonColor..'Running For: ', size = 11, offset = -11 },
			{ key = 'current_Time', type = 'text', text = '...', size = 11, align = 'right', offset = 0 },
			-- Looted Items Counter
			{ type = 'text', text = '|cff'..NeP.Interface.addonColor..'Looted Items: ', size = 11, offset = -11 },
			{ key = 'current_Loot', type = 'text', text = '...', size = 11, align = 'right', offset = 0 },
			-- Predicted Average Items Per Hour
			{ type = 'text', text = '|cff'..NeP.Interface.addonColor..'Average Items Per Hour: ', size = 11, offset = -11 },
			{ key = 'current_average', type = 'text', text = '...', size = 11, align = 'right', offset = 0 },
		-- [[ Start Button ]]
		{ type = 'spacer' },
			{ type = 'button', text = 'Start Fishing', width = 230, height = 20, callback = function(self, button)
				-- Required APIS
				if InteractUnit and ObjectField then
					SetOffsets()
					if OBJECT_BOBBING_OFFSET and OBJECT_CREATOR_OFFSET then
						if _fishRun then
							self:SetText('Start Fishing')
							JumpOrAscendStart() -- Jump to stop channeling.
							equipNormalGear()
							_timeStarted = nil
						else
							self:SetText('Stop Fishing')
							local currentTime = GetTime()
							_timeStarted = currentTime
							_Lootedcounter = 0
						end
						_fishRun = not _fishRun
					else
						error('Failed to find the offsets')
					end
				else
					error('Your unlocker is not supported!')
				end
			end},
	}	
}

NeP.Interface.buildGUI(config)
NeP.Interface.CreatePlugin('Fishing Bot', function() NeP.Interface.ShowGUI('NePfishingBot') end)

--[[-----------------------------------------------
** DoCountLoot **
DESC: Counts the loot from fishing.

Build By: darkjacky @ github
---------------------------------------------------]]
local fshGUI = NeP.Interface.getGUI('NePfishingBot')
local DoCountLoot = false
local CounterFrame = CreateFrame('frame')
CounterFrame:RegisterEvent('LOOT_READY')
CounterFrame:SetScript('OnEvent', function()
	if DoCountLoot then -- only count when triggered by _startFish()
		DoCountLoot = false -- trigger once.
		for i=1,GetNumLootItems() do
			local lootIcon, lootName, lootQuantity, rarity, locked = GetLootSlotInfo(i)
			_Lootedcounter = _Lootedcounter + lootQuantity
			fshGUI.elements.current_average:SetText(math.floor(3600 / (GetTime() - _timeStarted) * _Lootedcounter))
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
	for i=1, #NeP.OM.GameObjects do
		local Obj = NeP.OM.GameObjects[i]
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
** _startFish **
DESC: Actualy start fishing ;P

Build By: MTS
Modifed by: darkjacky @ github
---------------------------------------------------]]
local FishCD = 0
local function _startFish()
	local BobberObject = getBobber()
	if BobberObject then
		local bobbing = ObjectField(getBobber(), OBJECT_BOBBING_OFFSET, Types.Bool)
		if bobbing == 0 then bobbing = false end
		if bobbing then
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
** _FishHook **
DESC: Applies the best of any fishing hooks found in bag.

Build By: darkjacky @ github
---------------------------------------------------]]
local FishHooks = {
	{ ItemID = 118391, BuffID = 5386, Weight = 200,	ItemName = 'Worm Supreme'               }, -- 10 min
	{ ItemID = 124674, BuffID = 5386, Weight = 200,	ItemName = 'Day-Old Darkmoon Doughnut'  }, -- 10 min
	{ ItemID = 68049,  BuffID = 4225, Weight = 150,	ItemName = 'Heat-Treated Spinning Lure' }, -- 15 min
	{ ItemID = 46006,  BuffID = 3868, Weight = 100,	ItemName = 'Glow Worm'                  }, -- 1 hour
	{ ItemID = 34861,  BuffID = 266,  Weight = 100,	ItemName = 'Sharpened Fish Hook'        }, -- 10 min
	{ ItemID = 6533,   BuffID = 266,  Weight = 100,	ItemName = 'Aquadynamic Fish Attractor' }, -- 10 min
	{ ItemID = 7307,   BuffID = 265,  Weight = 75,	ItemName = 'Flesh Eating Worm'          }, -- 10 min
	{ ItemID = 6532,   BuffID = 265,  Weight = 75,	ItemName = 'Bright Baubles'             }, -- 10 min
	{ ItemID = 62673,  BuffID = 266,  Weight = 75,	ItemName = 'Feathered Lure'             }, -- 10 min
	{ ItemID = 6811,   BuffID = 264,  Weight = 50,	ItemName = 'Aquadynamic Fish Lens'      }, -- 10 min
	{ ItemID = 6530,   BuffID = 264,  Weight = 50,	ItemName = 'Nightcrawlers'              }, -- 10 min
	{ ItemID = 69907,  BuffID = 263,  Weight = 25,	ItemName = 'Corpse Worm'                }, -- 10 min
	{ ItemID = 6529,   BuffID = 263,  Weight = 25,	ItemName = 'Shiny Bauble'               }, -- 10 min
	{ ItemID = 67404,  BuffID = 4264, Weight = 15,	ItemName = 'Glass Fishing Bobber'       }, -- 10 min
}

local HookCD = 0
local function _FishHook()
	if getBobber() then return end -- if we are fishing we don't want to interrupt it.
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface.fetchKey('NePfishingBot', 'ApplyFishHooks') and GetTime() > HookCD then
		if select(7, GetItemInfo(GetInventoryItemLink('player', 16))) == 'Fishing Poles' then
			local hasEnchant, timeleft, _, enchantID = GetWeaponEnchantInfo()
			if hasEnchant and timeleft / 1000 > 15 then
				for i=1,#FishHooks do
					if enchantID == FishHooks[i].BuffID then
						return -- if we have the item enchant don't run.
					end
				end
			end
			for i=1,#FishHooks do
				local HasItem, Count = ItemInBag(FishHooks[i].ItemID)
				if HasItem then
					HookCD = GetTime() + 5 -- it seems to be chain casting it otherwise :S
					UseItem(FishHooks[i].ItemID)
					NeP.Core.Print('[|cff'..NeP.Interface.addonColor..'Fishing Bot|r]: (Used Hook): '..FishHooks[i].ItemName..' ' ..tostring(Count - 1)..' left.' )
					return true
				end
			end
		end
	end
end

--[[-----------------------------------------------
** _BladeBone **
DESC: Applies the best of any fishing hook found in bag.

Build By: darkjacky @ github
---------------------------------------------------]]
local BladeBoneCD = 0
local function _BladeBone()
	if getBobber() then return end -- if we are fishing we don't want to interrupt it.
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface.fetchKey('NePfishingBot', 'BladeBoneHook') and GetTime() > BladeBoneCD then
		local expires = select(7, UnitBuff('player', GetSpellInfo(182226)))
		if expires and expires - GetTime() > 15 then return end
		local HasItem, Count = ItemInBag(122742)
		if HasItem then
			BladeBoneCD = GetTime() + 5 -- it seems to be chain casting it otherwise :S
			UseItem(122742)
			NeP.Core.Print('[|cff'..NeP.Interface.addonColor..'Fishing Bot|r]: (Used Hook): '..GetSpellInfo(182226)..' ' ..tostring(Count - 1)..' left.' )
			return true
		end
	end
end

--[[-----------------------------------------------
** Hats **
DESC: finds and equips fishing hats.

Build By: MTS
---------------------------------------------------]]
local hatsTable = {
	{ ID = 118380, Bonus = 100, Name = 'Hightfish Cap' },
	{ ID = 118393, Bonus = 100, Name = 'Tentacled Hat' },
	{ ID = 117405, Bonus = 10,  Name = 'Nat\'s Drinking Hat' },
	{ ID = 19972,  Bonus = 5,   Name = 'Lucky Fishing Hat' },
	{ ID = 88710,  Bonus = 5,   Name = 'Nat\'s Hat' },
	{ ID = 93732,  Bonus = 5,   Name = 'Darkmoon Fishing Cap' },
}
local function _findHats()
	local hatsFound = {}
	for i = 1, #hatsTable do
		if GetItemCount(hatsTable[i].ID, false, false) > 0 then
			hatsFound[#hatsFound+1] = {
				ID = hatsTable[i].ID,
				Name = hatsTable[i].Name,
				Bonus = hatsTable[i].Bonus
			}
		end
	end
	table.sort(hatsFound, function(a,b) return a.Bonus > b.Bonus end)
	return hatsFound
end

local function _equitHat()
	if NeP.Interface.fetchKey('NePfishingBot', 'FshHat') then
		local hatsFound = _findHats()
		if #hatsFound > 0 then
			local headItemID = GetInventoryItemID('player', 1)
			local bestHat = hatsFound[1]
			if headItemID ~= bestHat.ID then
				NeP.Core.Print('[|cff'..NeP.Interface.addonColor..'Fishing Bot|r]: (Equiped): '..bestHat.Name)
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
local polesTable = {
	{ ID = 118381, Bonus = 100, Name = 'Ephemeral Fishing Pole' },
	{ ID = 19970,  Bonus = 40,  Name = 'Arcanite Fishing Pole' },
	{ ID = 84661,  Bonus = 30,  Name = 'Dragon Fishing Pole' },
	{ ID = 116825, Bonus = 30,  Name = 'Savage Fishing Pole' },
	{ ID = 116826, Bonus = 30,  Name = 'Draenic Fishing Pole' },
	{ ID = 45991,  Bonus = 30,  Name = 'Bone Fishing Pole' },
	{ ID = 45992,  Bonus = 30,  Name = 'Jeweled Fishing Pole' },
	{ ID = 44050,  Bonus = 30,  Name = 'Mastercraft Kalu\'ak Fishing Pole' },
	{ ID = 45858,  Bonus = 25,  Name = 'Nat\'s Lucky Fishing Pole' },
	{ ID = 6367,   Bonus = 20,  Name = 'Big Iron Fishing Pole' },
	{ ID = 19022,  Bonus = 20,  Name = 'Nat Pagle\'s Extreme Angler FC-5000' },
	{ ID = 25978,  Bonus = 20,  Name = 'Seth\'s Graphite Fishing Pole' },
	{ ID = 6366,   Bonus = 15,  Name = 'Darkwood Fishing Pole' },
	{ ID = 84660,  Bonus = 10,  Name = 'Pandaren Fishing Pole' },
	{ ID = 6365,   Bonus = 5,   Name = 'Strong Fishing Pole' },
	{ ID = 12225,  Bonus = 3,   Name = 'Blump Family Fishing Pole' },
	{ ID = 46337,  Bonus = 3,   Name = 'Staats\' Fishing Pole' },
	{ ID = 120163, Bonus = 3,   Name = 'Thruk\'s Fishing Rod' },
	{ ID = 6256,   Bonus = 0,   Name = 'Fishing Pole' },
}

local function _findPoles()
	local polesFound = {}
	for i = 1, #polesTable do
		if GetItemCount(polesTable[i].ID, false, false) > 0 then
			--print('found:'..polesTable[i].Name)
			polesFound[#polesFound+1] = {
				ID = polesTable[i].ID,
				Name = polesTable[i].Name,
				Bonus = polesTable[i].Bonus
			}
		end
	end
	table.sort(polesFound, function(a,b) return a.Bonus > b.Bonus end)
	return polesFound
end

local function _equitPole()
	if NeP.Interface.fetchKey('NePfishingBot', 'FshPole') then
		local polesFound = _findPoles()
		if #polesFound > 0 then
			local weaponItemID = GetInventoryItemID('player', 16)
			local bestPole = polesFound[1]
			if weaponItemID ~= bestPole.ID then
				NeP.Core.Print('[|cff'..NeP.Interface.addonColor..'Fishing Bot|r]: (Equiped): '..bestPole.Name)
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
local _baitsTable = {
	['jsb'] = 	{ ID = 110274, Debuff = 158031, Name = 'Jawless Skulker Bait' },
	['fsb'] = 	{ ID = 110289, Debuff = 158034, Name = 'Fat Sleeper Bait' },
	['blsb'] = 	{ ID = 110290, Debuff = 158035, Name = 'Blind Lake Sturgeon Bait' },
	['fab'] = 	{ ID = 110291, Debuff = 158036, Name = 'Fire Ammonite Bait' },
	['ssb'] = 	{ ID = 110292, Debuff = 158037, Name = 'Sea Scorpion Bait' },
	['ageb'] = 	{ ID = 110293, Debuff = 158038, Name = 'Abyssal Gulper Eel Bait' },
	['bwb'] = 	{ ID = 110294, Debuff = 158039, Name = 'Blackwater Whiptail Bait' }
}
local function _AutoBait()
	if getBobber() then return end
	if NeP.Interface.fetchKey('NePfishingBot', 'bait') ~= 'none' or NeP.Interface.fetchKey('NePfishingBot', 'bait') ~= nil then
		if _baitsTable[NeP.Interface.fetchKey('NePfishingBot', 'bait')] ~= nil then
			local _Bait = _baitsTable[NeP.Interface.fetchKey('NePfishingBot', 'bait')]
			if GetItemCount(_Bait.ID, false, false) > 0 then
				local endtime = select(7, UnitBuff('player', GetSpellInfo(_Bait.Debuff)))
				if (not endtime) or endtime < GetTime() + 14 then
					NeP.Core.Print('[|cff'..NeP.Interface.addonColor..'Fishing Bot|r]: (Used Bait): '.._Bait.Name)
					UseItem(_Bait.ID)
				end
			end
		end
	end
end

local function _CarpDestruction()
	if NeP.Interface.fetchKey('NePfishingBot', 'LunarfallCarp') then
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

local function BagSpace()
	local freeslots = 0
	for lbag = 0, NUM_BAG_SLOTS do
		numFreeSlots, BagType = GetContainerNumFreeSlots(lbag)
		freeslots = freeslots + numFreeSlots
	end
	return freeslots
end

C_Timer.NewTicker(0.5, (function()
					
	if _fishRun then
		if BagSpace() > 2 then

			-- Update GUI Elements
			if _timeStarted then
				fshGUI.elements.current_Time:SetText(FormatTime(NeP.Core.Round(GetTime() - _timeStarted)))
				fshGUI.elements.current_Loot:SetText(_Lootedcounter)
			end

			_CarpDestruction()
			_equitHat()
			_equitPole()
			_AutoBait()
			if _FishHook() then return end -- If it is true we stop because we have to wait.
			if _BladeBone() then return end -- Same here
			if IsHackEnabled then
				-- Only Works with FH atm, due to object handling...
				-- (if someday more unlockers alow this then abstract FH only stuff)
				_startFish()
			end
		else
			error('Not Enough Bag Space.')
		end
	end

end), nil)
