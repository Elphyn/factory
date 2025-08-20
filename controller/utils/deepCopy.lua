local function deepCopy(itemStorage)
	local itemList = {}
	for k, v in pairs(itemStorage) do
		itemList[k] = {
			count = v.count,
			capacity = v.capacity,
			displayName = v.displayName,
		}
	end
	return itemList
end

return deepCopy
