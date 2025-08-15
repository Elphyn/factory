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
		print("Found item in slot: %d", i)
		if curItemName == itemName then
			return i
		end
	end
	print("No item in %s", stationName)
	return nil
end

local function executeTask(takeFromName, placeWhereName, stationName, task)
	-- Should note, that if we got here, we must assume we have enough items
	local craftingItemName = task.order
	local howManyToCraft = task.count
	local recipeItemList = recipes["minecraft:gravel"]

	-- place itmes in a station
	local station = peripheral.wrap(stationName)

	for key, value in pairs(recipeItemList) do
		station.pullItem(takeFromName, key, value)
	end

	-- wait for it to be finished
	local itemSlot = nil
	while true do
		if not itemSlot then
			itemSlot = findItem(stationName, craftingItemName)
		end
		if itemSlot then
			local isFinished = station.items()[itemSlot].count == howManyToCraft
			if isFinished then
				break
			end
		end
	end

	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
end

executeTask(chest_name, chest_name, mill_name, task)
