local recipes = dofile("factory/shared/recipes.lua")
local fp = dofile("factory/utils/fp.lua")

-- local recipes = dofile("../shared/recipes.lua") -- for testing
-- local fp = dofile("../utils/fp.lua") -- for testing

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(eventEmitter, nodeManager)
	local self = setmetatable({}, Scheduler)
	self.eventEmitter = eventEmitter
	self.nodeManager = nodeManager
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

		self.eventEmitter:subscribe("order-finished-received", function(info)
			-- ?
		end)
	end
end

function Scheduler:calculateMaxCraftable(item, recipe, inventory)
	-- assigned - reserved ammount for other orders, that were queued before this one
	local assigned = inventory[item] and inventory[item].assigned or 0
	local total = inventory[item] and inventory[item].total or 0
	local stock = total - assigned

	-- calculate how much we could craft at max, in best conditions
	local maxCraft = recipe.craftingLimit - stock

	-- taking into account how many dependencies we have, and how much we can make with them
	local ingredientConstrainsts = fp.map(recipe.dependencies, function(ratio, ingredient)
		local ingredientTotal = inventory[ingredient] and inventory[ingredient].total or 0
		local ingredientAssigned = inventory[ingredient] and inventory[ingredient].assigned or 0
		local depStock = ingredientTotal - ingredientAssigned
		return math.floor(depStock / ratio)
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

function Scheduler:reserveMaterials(recipe, count, inventory)
	-- if we're making an item, need to reserve it's dependencies
	for dep, ratio in pairs(recipe.dependencies) do
		inventory[dep].assigned = inventory[dep].assigned + count * ratio
		if inventory[dep].assigned > inventory[dep].total then
			error("Can't assign more resources then there is, were trying to assign: " .. count .. " " .. dep)
		end
	end
end

function Scheduler:resetReservedMaterials(inventory)
	for item, _ in pairs(inventory) do
		inventory[item].assigned = 0
	end
end

function Scheduler:planCrafts(inventory)
	-- need to reset items that we reserved
	self:resetReservedMaterials(inventory)
	-- all waiting entries in queue could be recalculated
	self:removeWaiting()

	-- find all items that we can make
	local newCraftableItems = {}
	for item, recipe in pairs(recipes) do
		if not self.itemsProcessing[item] then
			local maxCraft = self:calculateMaxCraftable(item, recipe, inventory)
			if maxCraft > 0 then
				newCraftableItems[item] = maxCraft
				self:reserveMaterials(recipe, maxCraft, inventory)
			end
		end
	end

	-- add new items to queue
	for item, count in pairs(newCraftableItems) do
		local fullOrder = self:generateQueueEntry(item, count)

		-- splitting orders into parts for each node, calculates by how many stations node has
		-- the more stations node has, the bigger part of order it gets
		local finalOrders = self.nodeManager:getLoadBalancedOrders(fullOrder)
		for _, order in ipairs(finalOrders) do
			local id = order.id
			self.queue[id] = order
			self:onNewOrder(order)
		end
	end

	-- signal change, so components update
	self:onChange()
end

function Scheduler:onNewOrder(order)
	self.eventEmitter:emit("new-order", order)
end

function Scheduler:onChange()
	self.eventEmitter:emit("queue_changed", self.queue)
end

function Scheduler:generateQueueEntry(item, count)
	return {
		name = item,
		count = count,
	}
end

function Scheduler:getQueue()
	return self.queue
end

return Scheduler
