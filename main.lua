
local getWorkers = require("getWorkers")
local recipes = require("recipes")
local crafting = {} 
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


local function deepCopy(itemStorage)
  local itemList = {}
  for k, v in pairs(itemStorage) do
    itemList[k] = {
      count = v.count,
      capacity = v.capacity,
      displayName = v.displayName
    }
  end
  return itemList
end


local function whatCanCraft(itemsToCraft, itemStorage)
	-- probably something like {"minecarft:gravel = {count = 10}"}
	-- if we got here, assume regent is in recipe
  --
  local itemList = deepCopy(itemStorage) 
	local canCraft = {}
	for name, info in pairs(itemsToCraft) do
		local maxCraft = info.count
		for neededIngredientName, needed in pairs(recipes[name]) do
      if neededIngredientName == "crafterType" then
        goto jump
      end
			local stock = itemList[neededIngredientName] and itemList[neededIngredientName].count or 0
			local maxByIngridient = math.floor(stock / needed)
      if maxByIngridient == 0 then
        goto continue
      end
			if maxCraft > maxByIngridient then
				maxCraft = maxByIngridient
			end
      ::jump::
		end  
    local curOrder = {order = name, count = maxCraft}
		for neededIngredientName, needed in pairs(recipes[name]) do
      itemList[neededIngredientName].count = itemList[neededIngredientName].count - maxCraft * needed 
    end
    canCraft[name] = curOrder
    ::continue::
	end
  return canCraft
end
-- should wait until we've crafted a batch, then it can look into crafting somethng else
local function scheduler(itemTable)

	local queue = {}
	for item, info in pairs(itemTable) do 
    if info.count < info.capacity and recipes[item] ~= nil and not crafting[item] then
			-- not enough items + there's a recipe, now we need to check for dependencies
      queue[item] = {count = info.capacity - info.count}
		end
	end
  queue = whatCanCraft(queue, itemTable)
  return queue 
end

local function displayStorageItems(itemTable, queue)
	local monitorName = findMonitor()
	if monitorName == nil then
		print("No monitor found")
    return
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
  -- local queue = scheduler(itemTable)
   
  -- name = {order = name, count = how much we crafting}
  line = line + 1
	monitor.setCursorPos(1, line)
  monitor.write("Queue: ")
  line = line + 1
  for name, info in pairs(queue) do
		monitor.setCursorPos(1, line)
    local itemInfoString = string.format("%s | Can craft: %d", itemTable[name].displayName, info.count)
    monitor.write(itemInfoString)
    line = line + 1
  end
end

function isEmpty(table)
  for _ in pairs(table) do
    return false
  end
  return true 
end

local function mainLoop()
	while true do
    local itemTable = getStorageItems()
    local queue = scheduler(itemTable)
		displayStorageItems(itemTable, queue)

    if isEmpty(crafting) then
      crafting = queue
    end
    queue = {}
		sleep(0.1)
	end
end

mainLoop()


-- scheduler
