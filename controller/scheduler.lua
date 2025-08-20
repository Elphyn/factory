local recipes = require("shared.recipes")
local deepCopy = require("utils.deepCopy")
local function whatCanCraft(itemsToCraft, itemStorage)
	-- probably something like {"minecarft:gravel = {count = 10}"}
	-- if we got here, assume regent is in recipe
  --
  local itemList = deepCopy(itemStorage) 
	local canCraft = {}
	for name, info in pairs(itemsToCraft) do
		local maxCraft = info.count
		for neededIngredientName, needed in pairs(recipes[name]) do
      if neededIngredientName == "crafterType" then
        goto jump
      end
			local stock = itemList[neededIngredientName] and itemList[neededIngredientName].count or 0
			local maxByIngridient = math.floor(stock / needed)
      if maxByIngridient == 0 then
        goto continue
      end
			if maxCraft > maxByIngridient then
				maxCraft = maxByIngridient
			end
      ::jump::
		end  
    local curOrder = {order = name, count = maxCraft}
		for neededIngredientName, needed in pairs(recipes[name]) do
      itemList[neededIngredientName].count = itemList[neededIngredientName].count - maxCraft * needed 
    end
    canCraft[name] = curOrder
    ::continue::
	end
  return canCraft
end

-- should wait until we've crafted a batch, then it can look into crafting somethng else
local function scheduler(itemTable)

	local queue = {}
	for item, info in pairs(itemTable) do 
    if info.count < info.capacity and recipes[item] ~= nil then
			-- not enough items + there's a recipe, now we need to check for dependencies
      queue[item] = {count = info.capacity - info.count}
		end
	end
  queue = whatCanCraft(queue, itemTable)
  return queue 
end

return scheduler
