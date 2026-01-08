---@type recipes
local recipes = dofile("../shared/recipes.lua")

local DESIRED_CONFIDENCE = 0.8

local LongCrafting = {}

---@param items table<itemName, itemCount>
---@param neededItem itemName
---@param quantity itemCount
---@return boolean
function LongCrafting.checkNonDeterministicCraftAndReserve(items, neededItem, quantity)
	local recipe = recipes.recipes[neededItem]

	local reservedItems = {}

	-- Checking if we have enough items to craft something with DESIRED_CONFIDENCE
	for depName, depRatio in pairs(recipe.dependencies) do
		local p = 1 / depRatio

		local reqForOne = math.log(1 - DESIRED_CONFIDENCE) / math.log(1 - p)
		local totalRequired = math.ceil(reqForOne * quantity)

		local stock = (items[depName] or 0) - (reservedItems[depName] or 0)
		if stock < totalRequired then
			return false
		end

		reservedItems[depName] = totalRequired
	end

	-- At this point if we didn't hit return false, we can craft it with DESIRED_CONFIDENCE and need to reserve resources
	-- So we actually mutate items here
	for depName, depReserved in pairs(reservedItems) do
		assert(
			items[depName] >= depReserved,
			"Critical error: trying to reserve more items that we have, in LongCrafting module"
		)

		items[depName] = items[depName] - depReserved
	end

	return true
end

function LongCrafting.checkDeterministicCraftAndReserve(items, neededItem, quantity)
	local recipe = recipes.recipes[neededItem]

	local reservedItems = {}

	for depName, depRatio in pairs(recipe.dependencies) do
		local totalRequired = quantity * depRatio
		local stock = (items[depName] or 0) - (reservedItems[depName] or 0)

		if stock < totalRequired then
			return false
		end

		reservedItems[depName] = totalRequired
	end

	for depName, depReserved in pairs(reservedItems) do
		assert(
			items[depName] >= depReserved,
			"Critical error: trying to reserve more items that we have, in LongCrafting module"
		)

		items[depName] = items[depName] - depReserved
	end

	return true
end

---This function checks if zero-degree crafting is possible (oneshot crafting, no DAG)
---@param items table<itemName, itemCount>
---@param neededItem itemName
---@param quantity itemCount
---@param availableNodeTypes table<nodeType, boolean>
---@return boolean
function LongCrafting.shortCraftPossible(items, neededItem, quantity, availableNodeTypes)
	local requiredStation = recipes.stationType(neededItem)
	if not availableNodeTypes[requiredStation] then
		return false
	end

	local neededRecipe = recipes.recipes[neededItem]

	if neededRecipe.nonDeterministic then
		return LongCrafting.checkNonDeterministicCraftAndReserve(items, neededItem, quantity)
	end

	return LongCrafting.checkDeterministicCraftAndReserve(items, neededItem, quantity)
end

function LongCrafting.findCraftableItems(items, availableNodeTypes) end

return LongCrafting
