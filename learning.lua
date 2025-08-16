local task = {
	order = "minecraft:gravel",
	count = 2,
}

local recipes = {
	["minecraft:gravel"] = {
		["minecraft:cobblestone"] = 1,
	},
}

local chest_name = "minecraft:chest_14"
local mill_name = "create:millstone_14"

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

	for key, value in pairs(recipeItemList) do
		station.pullItem(takeFromName, key, value * howManyToCraft)
	end

	while not isDone(craftingItemName, howManyToCraft, stationName) do
		coroutine.yield()
	end
	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
end

-- executeTask(chest_name, chest_name, mill_name, task)

local co = coroutine.create(executeTask)

coroutine.resume(co, chest_name, chest_name, mill_name, task)
while coroutine.status(co) ~= "dead" do
	local ok, err = coroutine.resume(co)
	if not ok then
		print("Something went wrong: ", err)
	end
	sleep(1)
end

print("coroutine is finished!")
