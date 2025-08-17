-- This should handle checking storage/queing tasks/station states

-- we do need a main loop right, which checks for items we lack

-- Find storage, check if it's not full
--
--

local recipes = {
	["minecraft:gravel"] = {
		["minecraft:cobblestone"] = 1,
	},
}

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

local function findMonitor()
	local list = peripheral.getNames()

	for _, name in ipairs(list) do
		if string.match(name, "^monitor") then
			return name
		end
	end
	return nil
end


local function initStations(stationStartsWith)
	local devices = peripheral.getNames()

	local stationTable = {}
	local stationStack = {}

	for _, name in ipairs(devices) do
		if string.match(name, "^" .. stationStartsWith) then
			table.insert(stationStack, name)
			stationTable[name] = { state = "idle" }
		end
	end
	return stationTable, stationStack
end


local function whatCanCraft(itemsToCraft, itemList)
	-- probably something like {"minecarft:gravel = {count = 10}"}
	-- if we got here, assume regent is in recipe
  --
  local itemList = itemList
	local canCraft = {}
	for name, info in pairs(itemsToCraft) do
		local maxCraft = info.count
		for neededIngridientName, needed in pairs(recipes[name]) do
			local stock = itemList[neededIngridientName] and itemList[neededIngridientName].count or 0
			local maxByIngridient = math.floor(stock / needed)
      if maxByIngridient == 0 then
        goto continue
      end
			if maxCraft > maxByIngridient then
				maxCraft = maxByIngridient
			end
		end  
    local curOrder = {order = name, count = maxCraft}
		for neededIngridientName, needed in pairs(recipes[name]) do
      itemList[neededIngridientName].count = itemList[neededIngridientName].count - maxCraft * needed 
    end
    canCraft[name] = curOrder
    ::continue::
	end
  return canCraft
end
-- should wait until we've crafted a batch, then it can look into crafting somethng else
local function scheduler(itemTable)
	local stationTable, stationStack = initStations("create:mill")

	local queue = {}
	for item, info in pairs(itemTable) do
		if info.count < info.capacity and recipes[item] ~= nil then
			-- not enough items + there's a recipe, now we need to check for dependencies
      queue[item] = {count = item.capacity - info.count}
		end
	end
  queue = whatCanCraft(queue)
  return queue 
end

local function displayStorageItems(itemTable)
	local monitorName = findMonitor()
	if monitorName == nil then
		error("No monitor found")
	end
	local monitor = peripheral.wrap(monitorName)
	monitor.clear()
	local line = 1
	for name, info in pairs(itemTable) do
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | %d/%d", info.displayName, info.count, info.capacity)
		monitor.write(itemInfoString)
		line = line + 1
	end
  -- items to craft:
  local queue = scheduler(itemTable)
  
  -- name = {order = name, count = how much we crafting}
  line = line + 1
	monitor.setCursorPos(1, line)
  monitor.write("Queue: ")
  line = line + 1
  for name, info in pairs(queue) do
		monitor.setCursorPos(1, line)
    local itemInfoString = string.format("%s | Can craft: %d", name, info.count)
    monitor.write(itemInfoString)
    line = line + 1
  end
end

local function displayLoop(itemTable)
	while true do
		displayStorageItems(itemTable)
		sleep(0.1)
	end
end

local function wrapper(func, ...)
	local args = { ... }
	return function()
		return func(table.unpack(args))
	end
end

local function main()
	local itemTable = getStorageItems()

	parallel.waitForAll(wrapper(displayLoop, itemTable))
end

main()

-- scheduler
