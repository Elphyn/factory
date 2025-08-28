local recipes = dofile("factory/shared/recipes.lua")
local deepCopy = dofile("factory/utils/deepCopy.lua")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(storageManager)
	local self = setmetatable({}, Scheduler)
	self.queued = {}
	self.queue = {}
	return self
end

function Scheduler:planCrafts(storage)
	self.queue = {}
	local items = deepCopy(storage)
	for item, recipe in pairs(recipes) do
		-- if we don't have anything queued for this item
		if self.queued[item] == nil then
			local maxCraft = recipe.craftingLimit - (items[item] and items[item].total or 0)
			if maxCraft <= 0 then
				goto continue
			end
			for itemReq, ratio in pairs(recipe.dependencies) do
				local stock = items[itemReq] and items[itemReq].total or 0
				local maxByIngridient = math.floor(stock / ratio)
				if maxByIngridient == 0 then
					goto continue
				end
				if maxCraft > maxByIngridient then
					maxCraft = maxByIngridient
				end
			end
			for itemReq, ratio in pairs(recipe.dependencies) do
				items[itemReq].total = items[itemReq].total - maxCraft * ratio
			end
			local order = { name = item, count = maxCraft }
			self.queued[item] = {}
			table.insert(self.queued[item], order)
			table.insert(self.queue, order)
			::continue::
		end
	end
	return self.queue
end

return Scheduler
