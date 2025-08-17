-- This should handle checking storage/queing tasks/station states

-- we do need a main loop right, which checks for items we lack

-- Find storage, check if it's not full
--
--
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
	for _, name in ipairs(itemStorageTable) do
		local drawer = peripheral.wrap(name)

		local itemTable = drawer.items()[1]
		if itemTable == nil then
			goto continue
		end
		if itemStorageTable[itemTable.name] ~= nil then
			itemStorageTable[itemTable.name].count = itemStorageTable[itemTable.name].count + itemTable.count
			itemStorageTable[itemTable.name].capacity = itemStorageTable[itemTable.name].capacity + 1024
		else
			itemStorageTable[itemTable.name] = { count = itemTable.count, capacity = 1024 }
		end
		::continue::
	end
	return itemStorageTable
end

local function findMonitor()
	local list = peripheral.getNames()

	for _, name in ipairs(list) do
		if string.match(name, "^monitor") then
			return name
		end
	end
	return nil
end

local function displayStorageItems()
	local itemTable = getStorageItems()

	local monitorName = findMonitor()
	if monitorName == nil then
		error("No monitor found")
	end
	local monitor = peripheral.wrap(monitorName)
	monitor.clear()
	local line = 1
	for name, info in pairs(itemTable) do
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | %d/%d", name, info.count, info.capacity)
		line = line + 1
	end
end

local function displayLoop()
	while true do
		displayStorageItems()
		sleep(2)
	end
end

parallel.waitForAll(displayLoop)
