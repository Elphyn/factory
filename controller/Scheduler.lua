local recipes = dofile("factory/shared/recipes.lua")
local fp = dofile("factory/utils/fp.lua")
-- local recipes = dofile("../shared/recipes.lua") -- for testing
-- local fp = dofile("../utils/fp.lua") -- for testing

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(eventEmitter)
	local self = setmetatable({}, Scheduler)
	self.eventEmitter = eventEmitter
	self.nextId = 1
	self.queue = {}
	self.itemsProcessing = {} -- set imitation
	self:setupEventListeners()
	return self
end

function Scheduler:generateId()
	local id = self.nextId
	self.nextId = self.nextId + 1
	return id
end

function Scheduler:setupEventListeners()
	if self.eventEmitter then
		self.eventEmitter:subscribe("inventory_changed", function(storage)
			self:planCrafts(storage)
		end)
	end
end

function Scheduler:calculateMaxCraftable(item, recipe, inventory)
	-- calculate how much we could craft at max, in best conditions
	local stock = inventory[item] and inventory[item].total or 0
	local maxCraft = recipe.craftingLimit - stock

	-- taking into account how many dependencies we have, and how much we can make with them
	local ingredientConstrainsts = fp.map(recipe.dependencies, function(ratio, ingredient)
		local ingredientTotal = inventory[ingredient] and inventory[ingredient].total or 0
		return math.floor(ingredientTotal / ratio)
	end)

	-- the amount we can craft is maxCraft by lowest dependency
	return fp.reduce(ingredientConstrainsts, math.min, maxCraft)
end

function Scheduler:removeWaiting()
	for id, entry in pairs(self.queue) do
		if entry.state == "waiting" then
			self.queue[id] = nil
		end
	end
end

function Scheduler:planCrafts(inventory)
	-- all waiting entries in queue could be recalculated
	self:removeWaiting()

	-- items we can make
	local craftableItemsAll = fp.map(recipes, function(recipe, item)
		return self:calculateMaxCraftable(item, recipe, inventory)
	end)
	-- save only newItems, which aren't being processed atm
	local newCraftableItems = fp.filter(craftableItemsAll, function(count, item)
		return self.itemsProcessing[item] == nil and count > 0
	end)

	-- add new items in queue
	for item, count in pairs(newCraftableItems) do
		local id, entry = self:generateQueueEntry(item, count)
		self.queue[id] = entry
	end

	-- signal change, so components update
	self:signalChange()
end

function Scheduler:signalChange()
	self.eventEmitter:emit("queue_changed", self.queue)
end

function Scheduler:generateQueueEntry(item, count)
	local id = self:generateId()
	local entry = {
		name = item,
		count = count,
		id = id,
		state = "waiting",
	}
	return id, entry
end

function Scheduler:getQueue()
	return self.queue
end

return Scheduler
