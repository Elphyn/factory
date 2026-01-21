---@type recipes
local recipes = dofile("shared/recipes.lua")

local DESIRED_CONFIDENCE_FOR_SINGLE_NODE = 0.8

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

		local reqForOne = math.log(1 - DESIRED_CONFIDENCE_FOR_SINGLE_NODE) / math.log(1 - p)
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
	local requiredStation = recipes.stationType[neededItem]
	if not requiredStation or not availableNodeTypes[requiredStation] then
		return false
	end

	local neededRecipe = recipes.recipes[neededItem]

	if neededRecipe.nonDeterministic then
		return LongCrafting.checkNonDeterministicCraftAndReserve(items, neededItem, quantity)
	end

	return LongCrafting.checkDeterministicCraftAndReserve(items, neededItem, quantity)
end

---Finds all items that can be crafted with current inventory and available nodes
---@param items table<itemName, itemCount> Current inventory
---@param availableNodeTypes table<nodeType, boolean> Available station types
---@return table<itemName, number> Items that can be crafted and their quantities
function LongCrafting.findCraftableItems(items, availableNodeTypes)
	local craftableItems = {}
	local itemsCopy = {}

	-- Deep copy items to avoid mutating original
	for itemName, count in pairs(items) do
		itemsCopy[itemName] = count
	end

	-- Check each recipe
	for itemName, recipe in pairs(recipes.recipes) do
		local requiredStation = recipes.stationType[itemName]

		-- Skip if we don't have the required station type
		if not availableNodeTypes[requiredStation] then
			goto continue
		end

		-- Calculate maximum craftable quantity
		local maxQuantity = math.huge

		for depName, depRatio in pairs(recipe.dependencies) do
			local availableDep = itemsCopy[depName] or 0

			if recipe.nonDeterministic then
				-- For non-deterministic, use confidence-based calculation
				local p = 1 / depRatio
				local reqForOne = math.log(1 - DESIRED_CONFIDENCE_FOR_SINGLE_NODE) / math.log(1 - p)
				local possibleQuantity = math.floor(availableDep / reqForOne)
				maxQuantity = math.min(maxQuantity, possibleQuantity)
			else
				-- For deterministic, use simple ratio
				local possibleQuantity = math.floor(availableDep / depRatio)
				maxQuantity = math.min(maxQuantity, possibleQuantity)
			end
		end

		-- Only add if we can craft at least 1 item
		if maxQuantity > 0 then
			craftableItems[itemName] = maxQuantity
		end

		::continue::
	end

	return craftableItems
end

return LongCrafting
