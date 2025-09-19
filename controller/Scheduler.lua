local recipes = dofile("factory/shared/recipes.lua")
local fp = dofile("factory/utils/fp.lua")
local empty = dofile("factory/utils/isEmpty.lua")
local split = require("even")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(eventEmitter, nodeManager, threader, networkManager, storageManager)
	local self = setmetatable({}, Scheduler)
	self.eventEmitter = eventEmitter
	self.nodeManager = nodeManager
	self.storageManager = storageManager
	self.threader = threader
	self.networkManager = networkManager
	self.nextId = 1
	self.queue = {}
	self.assigned = {}
	self.itemsProcessing = {}
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
			self.threader:addThread(function()
				self:planCrafts(storage)
			end)
		end)
		self.eventEmitter:subscribe("order-finished", function(msg)
			self:handleFinishedOrder(msg)
		end)
	end
end

function Scheduler:removeOrderFromQueue(id, item)
	-- setting order to nil would remove the order
	self.queue[id] = nil
	self.itemsProcessing[item][id] = nil

	-- if there's no orders that process this item,
	if empty(self.itemsProcessing[item]) then
		self.itemsProcessing[item] = nil
	end
end

function Scheduler:handleFinishedOrder(msg)
	self:removeOrderFromQueue(msg.orderID, msg.name)
	self:onChange()
end

function Scheduler:calculateMaxCraftable(item, recipe, inventory)
	-- assigned - reserved ammount for other orders, that were queued before this one
	local assigned = self.assigned[item] or 0
	local total = inventory[item] and inventory[item].total or 0
	local stock = total - assigned

	-- calculate how much we could craft at max, in best conditions
	local maxCraft = recipe.craftingLimit - stock

	-- taking into account how many dependencies we have, and how much we can make with them
	local ingredientConstrainsts = fp.map(recipe.dependencies, function(ratio, ingredient)
		local ingredientTotal = inventory[ingredient] and inventory[ingredient].total or 0
		local ingredientAssigned = self.assigned[item] or 0
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
		self.assigned[dep] = self.assigned[dep] or 0
		self.assigned[dep] = self.assigned[dep] + count * ratio
		if self.assigned[dep] > inventory[dep].total then
			error("Can't assign more resources then there is, were trying to assign: " .. count .. " " .. dep)
		end
	end
end

function Scheduler:resetReservedMaterials(inventory)
	self.assigned = {}
end

function Scheduler:findCraftableItems(inventory)
	local CraftableItems = {}
	-- going through each item in recipes
	for item, recipe in pairs(recipes) do
		-- if there's no nodes that handle this type of recipe, then we skip
		-- if item is being processed right now, we skip it for now
		if self.nodeManager:anyNodesOfType(recipe.crafter) and not self.itemsProcessing[item] then
			-- checking how much we can make
			local maxCraft = self:calculateMaxCraftable(item, recipe, inventory)
			if maxCraft > 0 then
				CraftableItems[item] = maxCraft
				self:reserveMaterials(recipe, maxCraft, inventory)
			end
		end
	end
	return CraftableItems
end

function Scheduler:planCrafts(inventory)
	-- need to reset items that we reserved
	self:resetReservedMaterials(inventory)
	-- all waiting entries in queue could be recalculated
	self:removeWaiting()

	-- find all items that we can make
	local newCraftableItems = self:findCraftableItems(inventory)

	-- add new items to queue
	for item, count in pairs(newCraftableItems) do
		-- splitting orders into parts for each node, calculates by how many stations node has
		-- the more stations node has, the bigger part of order it gets
		local orders = self:balanceLoad(item, count)

		for _, order in ipairs(orders) do
			local id = order.id
			if order.count > 0 then
				if not self.itemsProcessing[item] then
					self.itemsProcessing[item] = {}
				end
				self.itemsProcessing[item][id] = order
				self.threader:addThread(function()
					local success = self:sendOrder(order)
					if success then
						self.queue[id] = order
					else
						self.itemsProcessing[item][id] = nil
					end
				end)
			end
		end
	end

	-- -- signal change, so components update
	self:onChange()
end

function Scheduler:balanceLoad(item, count)
	-- if there aren't any nodes that could fulfil the order, we can't finalize order
	local nodeType = recipes[item].crafter

	-- if there's no nodes that handle this typoe of crafting, then we return nothing
	if not self.nodeManager:anyNodesOfType(nodeType) then
		return {}
	end

	-- collecting info on how many stations each node of type has
	local nodeStations = self.nodeManager:getNodesStaitionsCount(nodeType)

	-- calculating how to split order across nodes of same type
	local spread = split(count, nodeStations)

	-- finalizing orders, paritioning them evenly, assigning nodes
	local finalizedOrders = {}
	for nodeID, share in pairs(spread) do
		local order = self:generateOrder(nodeID, item, share)
		table.insert(finalizedOrders, order)
	end
	return finalizedOrders
end

function Scheduler:generateOrder(nodeID, item, count)
	local order = {
		event = "crafting-order",
		assignedNodeId = nodeID,
		name = item,
		count = count,
		state = "waiting",
		id = self:generateId(),
	}
	return order
end

function Scheduler:sendOrder(order)
	local buffer = self.networkManager:getNodeBuffer(order.assignedNodeId)
	local success = self.storageManager:insertOrderDependencies(order, buffer)
	if success then
		self.networkManager:makeRequest(order.assignedNodeId, order, "response-order")
		order.state = "Sent"
		return true
	end
	return false
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
