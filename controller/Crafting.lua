-- local recipes = dofile("factory/shared/recipes.lua")
local recipes = dofile("../shared/recipes.lua")

---@class Crafting_module
local Crafting = {}

---@alias nodeType string a type of crafter node is overseeing
---@alias itemsLeft table<itemName, itemCount> items that weren't allocated
---@alias craftableItems table<itemName, itemCount> items that we can craft

---@param items table<itemName, itemCount> Items we currently have in system
---@param nodeType nodeType
---@return table<itemName, itemCount> Items we can make currently with items given
function Crafting.findCraftableItemsForNodeType(items, nodeType)
	---@type recipes
	local nodeRecipes = recipes[nodeType]

	---@type table<itemName, itemCount>
	local craftableItems = {}

	-- Going through each item to see which we can make and how many
	for itemName, recipe in pairs(nodeRecipes) do
		-- How much of this item we currently have
		local total = items[itemName] or 0
		-- Checking maximum possible craft amount
		local maxCraft = recipe.craftingLimit - total

		-- Checking if there's enough dependencies for craft
		for depName, depRatio in pairs(recipe.dependencies) do
			local depStock = items[depName] or 0
			local maxByDep = depStock / depRatio
			maxCraft = math.min(maxCraft, maxByDep)
		end

		-- Since we're working with floating point numbers we floor it, output should be more certain
		maxCraft = math.floor(maxCraft)
		-- If we can craft some of this item, then we also need to reserve amount of items needed for this craft
		if maxCraft > 0 then
			-- Adding to result table amount we can craft
			craftableItems[itemName] = maxCraft

			-- Reserving of items
			for depName, depRatio in pairs(recipe.dependencies) do
				items[depName] = items[depName] - (maxCraft * depRatio)
			end
		end
	end
	return craftableItems
end

---@param items table<itemName, itemCount> Items we currently have in system
---@param availableNodeTypes table<nodeType, boolean>
function Crafting.findCraftableItems(items, availableNodeTypes)
	local craftableItemsByNode = {}
	for _, nodeType in ipairs(availableNodeTypes) do
		craftableItemsByNode[nodeType] = Crafting.findCraftableItemsForNodeType(items, nodeType)
	end
	return craftableItemsByNode
end

return Crafting
