local n_name, FSH = ...

function FSH:equipNormalGear()
	if #self.currentGear > 0 then
		for k=1, #self.currentGear do
			NeP.Core:Print(n_name, '(Reseting Gear): '..GetItemInfo(self.currentGear[k])..' (remaning): '..#self.currentGear)
			self:pickupItem(self.currentGear[k])
		end
	end
	wipe(self.currentGear)
end

function FSH:FishHook()
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface:Fetch(n_name, 'ApplyFSH.FishHooks')
	and select(7, GetItemInfo(GetInventoryItemLink('player', 16))) == 'Fishing Poles' then
		local hasEnchant, timeleft, _, enchantID = GetWeaponEnchantInfo()
		if hasEnchant and timeleft / 1000 > 15 then
			-- if we have the item enchant don't run.
			for i=1,#self.FishHooks do
				if enchantID == self.FishHooks[i].BuffID then return end
			end
			for i=1,#self.FishHooks do
				local HasItem, Count = self:ItemInBag(self.FishHooks[i].ItemID)
				if HasItem then
					UseItem(self.FishHooks[i].ItemID)
					NeP.Core:Print(n_name, '(Used Hook): '..self.FishHooks[i].ItemName..' ' ..tostring(Count - 1)..' left.' )
					return true
				end
			end
		end
	end
end

function FSH:BladeBone()
	if UnitCastingInfo('player') then return true end -- we are casting stop here.
	if NeP.Interface:Fetch(n_name, 'BladeBoneHook') then
		local expires = select(7, UnitBuff('player', GetSpellInfo(182226)))
		if expires and expires - GetTime() > 15 then return end
		local HasItem, Count = self:ItemInBag(122742)
		if HasItem then
			UseItem(122742)
			NeP.Core:Print(n_name, '(Used Hook): '..GetSpellInfo(182226)..' ' ..tostring(Count - 1)..' left.' )
			return true
		end
	end
end

function FSH:findHats()
	for i = 1, #self.hatsTable do
		if GetItemCount(self.hatsTable[i].ID, false, false) > 0 then
			self.HatsCache[#self.HatsCache+1] = {
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
		if #self.HatsCache > 0 then
			local headItemID = GetInventoryItemID('player', 1)
			local bestHat = self.HatsCache[1]
			if headItemID ~= bestHat.ID then
				NeP.Core:Print(n_name, '(Equiped): '..bestHat.Name)
				self.currentGear[#self.currentGear+1] = headItemID
				self:pickupItem(bestHat.ID)
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
		if #self.PolesCache > 0 then
			local weaponItemID = GetInventoryItemID('player', 16)
			local bestPole = self.PolesCache[1]
			if weaponItemID ~= bestPole.ID then
				NeP.Core:Print(n_name, '(Equiped): '..bestPole.Name)
				self.currentGear[#self.currentGear+1] = weaponItemID
				-- Also equip OffHand if user had one.
				if GetInventoryItemID('player', 17) then
					self.currentGear[#self.currentGear+1] = GetInventoryItemID('player', 17)
				end
				self:pickupItem(bestPole.ID)
			end
		end
	end
end

function FSH:AutoBait()
	if NeP.Interface:Fetch(n_name, 'bait') ~= 'none' or NeP.Interface:Fetch(n_name, 'bait') ~= nil then
		if self.baitsTable[NeP.Interface:Fetch(n_name, 'bait')] ~= nil then
			local bait = self.baitsTable[NeP.Interface:Fetch(n_name, 'bait')]
			if GetItemCount(bait.ID, false, false) > 0 then
				local endtime = select(7, UnitBuff('player', GetSpellInfo(bait.Debuff)))
				if (not endtime) or endtime < GetTime() + 14 then
					NeP.Core:Print(n_name, '(Used Bait): '..bait.Name)
					self:UseItem(bait.ID)
				end
			end
		end
	end
end

function FSH:LeyscaleKoi()
	return NeP.Interface:Fetch(n_name, 'LeyscaleKoi') and self:UseItem(143748)
end
