local function getStorageUnits()
	local list = peripheral.getNames()

	local storageUnits = {}

	for _, connectedPeripheral in ipairs(list) do
		if string.match(connectedPeripheral, "^extended_drawers") then
			table.insert(storageUnits, connectedPeripheral)
		end
	end
	return storageUnits
end

local function getStorageItems()
	local storageUnits = getStorageUnits()

	local itemStorageTable = {}
	-- key should be [regent] = {curCount, capacity}
	for _, name in ipairs(storageUnits) do
		local drawer = peripheral.wrap(name)

		local itemTable = drawer.items()[1]
		if itemTable == nil then
			goto continue
		end
		if itemStorageTable[itemTable.name] ~= nil then
			itemStorageTable[itemTable.name].count = itemStorageTable[itemTable.name].count + itemTable.count
			itemStorageTable[itemTable.name].capacity = itemStorageTable[itemTable.name].capacity + 1024
		else
			itemStorageTable[itemTable.name] =
				{ count = itemTable.count, capacity = 1024, displayName = itemTable.displayName }
		end
		::continue::
	end
	return itemStorageTable
end

return getStorageItems
