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

	-- wait for it to be finished
	local itemSlot = nil
	while true do
		if not itemSlot then
			itemSlot = findItem(stationName, craftingItemName)
		end
		if itemSlot then
			local itemSlot = station.items()[itemSlot]
			local curCount = 0
			-- not sure that's needed, but it failed a few times, no count for some reason
			if not itemSlot.count then
				curCount = 1
			else
				curCount = itemSlot.count
			end

			if curCount == howManyToCraft then
				break
			end
		end
		sleep(0.1)
	end

	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
end

executeTask(chest_name, chest_name, mill_name, task)
