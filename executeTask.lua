local task = {
	order = "minecraft:gravel",
	count = 2,
}

local recipes = {
	["minecraft:gravel"] = {
		["minecraft:cobblestone"] = 1,
	},
}

-- local chest_name = "minecraft:chest_14"
local mill_name = "create:millstone_14"
local gravel_drawer = "extended_drawers:single_drawer_15"
local cobblestone_drawer = "extended_drawers:single_drawer_16"

local function findItem(stationName, itemName)
	local station = peripheral.wrap(stationName)

	local inventory = station.items()
	for i, _ in ipairs(inventory) do
		local curItemName = inventory[i].name
		if curItemName == itemName then
			return i
		end
	end
	return nil
end

local function isDone(craftingItemName, howManyToCraft, stationName)
	local station = peripheral.wrap(stationName)
	local stationStorage = station.items()

	local itemSlot = findItem(stationName, craftingItemName)

	if itemSlot then
		local curCount = stationStorage[itemSlot].count
		if curCount >= howManyToCraft then
			return true
		end
		return false
	else
		return false
	end
end

local function executeTask(takeFromName, placeWhereName, stationName, task)
	-- Should note, that if we got here, we must assume we have enough items
	local craftingItemName = task.order
	local howManyToCraft = task.count
	local recipeItemList = recipes[craftingItemName]

	-- place itmes in a station
	local station = peripheral.wrap(stationName)
	local drawer = peripheral.wrap(takeFromName)

	for key, value in pairs(recipeItemList) do
		-- local ok, result = pcall(station.pullItem(takeFromName, key, value * howManyToCraft))
		drawer.pushItem(stationName, key, value * howManyToCraft)
	end

	while not isDone(craftingItemName, howManyToCraft, stationName) do
		print("Pausing")
		sleep(1)
	end
	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
end

-- executeTask(chest_name, chest_name, mill_name, task)

local function wrapper(func, ...)
	local args = { ... }
	return function()
		return func(table.unpack(args))
	end
end

parallel.waitForAll(wrapper(executeTask, cobblestone_drawer, gravel_drawer, mill_name, task))
