local recipes = dofile("factory/shared/recipes.lua")
local deepCopy = dofile("factory/utils/deepCopy.lua")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
	local self = setmetatable({}, Scheduler)
	self.queue = {}
	return self
end

function Scheduler:planCrafts(storage)
	local items = deepCopy(storage)
	for item, recipe in pairs(recipes) do
		-- if we don't have anything queued for this item
		if self.queue[item] == nil then
		end
	end
end
-- local function whatCanCraft(itemsToCraft, itemStorage)
-- 	-- probably something like {"minecarft:gravel = {count = 10}"}
-- 	-- if we got here, assume regent is in recipe
--   --
--   local itemList = deepCopy(itemStorage)
-- 	local canCraft = {}
-- 	for name, info in pairs(itemsToCraft) do
-- 		local maxCraft = info.count
-- 		for neededIngredientName, needed in pairs(recipes[name].dependencies) do
-- 			local stock = itemList[neededIngredientName] and itemList[neededIngredientName].count or 0
-- 			local maxByIngridient = math.floor(stock / needed)
--       if maxByIngridient == 0 then
--         goto continue
--       end
-- 			if maxCraft > maxByIngridient then
-- 				maxCraft = maxByIngridient
-- 			end
-- 		end
--     local curOrder = {order = name, count = maxCraft}
-- 		for neededIngredientName, needed in pairs(recipes[name].dependencies) do
--       itemList[neededIngredientName].count = itemList[neededIngredientName].count - maxCraft * needed
--     end
--     canCraft[name] = curOrder
--     ::continue::
-- 	end
--   return canCraft
-- end
--
-- -- should wait until we've crafted a batch, then it can look into crafting somethng else
-- local function scheduler(itemTable)
--   -- TODO make a refactor
-- 	local queue = {}
-- 	for item, info in pairs(itemTable) do
--     if info.count < info.capacity and recipes[item] ~= nil then
-- 			-- not enough items + there's a recipe, now we need to check for dependencies
--       queue[item] = {count = info.capacity - info.count}
-- 		end
-- 	end
--   -- need to refactor this
--   -- for item, info in pairs(recipes) do
--   --   local inStorage = nil
--   --   if itemTable[item] == nil then
--   --     inStorage = 0
--   --   else
--   --     inStorage = itemTable[item].count
--   --   end
--   --   if inStorage < recipes[item].capacity and
--
--   end
--   queue = whatCanCraft(queue, itemTable)
--   return queue
-- end
--
-- return scheduler
