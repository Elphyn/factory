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
	if not itemSlot then
		-- if we didn't find an item, it's spent and we're done
		return true
	else
		-- if we found an item, meaning it's still crafting
		return false
	end
end

function exhaustCrafting(takeFromName, placeWhereName, stationName, task)
	-- assuming it's one dependencie type of crafting
	local craftingItemName = task.order
	local howManyToCraft = task.count
	local recipeItem = recipes[craftingItemName].dependencies[1]
	local recipeItemRatio = recipes[craftingItemName]

	-- place itmes in a station
	local station = peripheral.wrap(stationName)

	-- take one item in bulk here

	while not isDone(craftingItemName, howManyToCraft, stationName) do
		sleep(0.1)
	end
	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
end

return standardCrafting
