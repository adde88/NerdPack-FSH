local _, FSH = ...

function FSH.ItemInBag(_, ItemID)
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
	return ItemFound, ItemCount
end

function FSH.UseItem(_, ItemID)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			if select(10, GetContainerItemInfo(bag, slot)) == ItemID then
				UseContainerItem(bag, slot)
				return true
			end
		end
	end
end

function FSH.pickupItem(_, item)
	if not GetItemCount(item, false, false) > 0 then return end
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			if GetContainerItemID(bag, slot) == item then
        PickupContainerItem(bag, slot)
        AutoEquipCursorItem()
      end
		end
	end
end

function FSH.deleteItem(_, ID, number)
	if GetItemCount(ID, false, false) > number then
		FSH:pickupItem(ID)
		if CursorHasItem() then
			DeleteCursorItem();
			return true
		end
	end
end

function FSH.BagSpace()
	local freeslots = 0
	for lbag = 0, NUM_BAG_SLOTS do
		local numFreeSlots = GetContainerNumFreeSlots(lbag)
		freeslots = freeslots + numFreeSlots
	end
	return freeslots
end
