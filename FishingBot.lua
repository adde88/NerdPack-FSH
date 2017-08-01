local n_name, FSH = ...
local NeP = NeP
local UnitBuff = UnitBuff
local UseItem = UseItem
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local UnitCastingInfo = UnitCastingInfo
local wipe = wipe
local GetInventoryItemID = GetInventoryItemID
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local GetItemCount = GetItemCount


function FSH:equipNormalGear()
	if #self.currentGear > 0 then
		for k=1, #self.currentGear do
			NeP.Core:Print(n_name, '(Reseting Gear): '..GetItemInfo(self.currentGear[k])..' (remaning): '..#self.currentGear)
			FSH:pickupItem(self.currentGear[k])
		end
	end
	wipe(self.currentGear)
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
				local HasItem, Count = FSH:ItemInBag(self.FishHooks[i].ItemID)
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
		local HasItem, Count = FSH:ItemInBag(122742)
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
				FSH:pickupItem(bestHat.ID)
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
				FSH:pickupItem(bestPole.ID)
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
		FSH:deleteItem(116158, 0)
	end
end
