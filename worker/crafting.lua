local recipes = dofile("factory/shared/recipes.lua")
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

function standardCrafting(takeFromName, placeWhereName, stationName, task)
	-- Should note, that if we got here, we must assume we have enough items
	-- Also, this crafting assumes we get one to one ratio, no, when it's concrete how many items you get
	local craftingItemName = task.order
	local howManyToCraft = task.count
	local recipeItemList = recipes[craftingItemName].dependencies

	-- place itmes in a station
	local station = peripheral.wrap(stationName)

	for key, value in pairs(recipeItemList) do
		-- local ok, result = pcall(station.pullItem(takeFromName, key, value * howManyToCraft))
		station.pullItem(takeFromName, key, value * howManyToCraft)
	end

	while not isDone(craftingItemName, howManyToCraft, stationName) do
		sleep(1)
	end
	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
end

return standardCrafting
