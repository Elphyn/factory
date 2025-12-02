local OrderManager = {}
local craft = require("crafting")
local buffer = dofile("config.lua").bufferName
OrderManager.__index = OrderManager

function OrderManager.new(threader, stationManager, eventEmitter)
	local self = setmetatable({}, OrderManager)
	self.threader = threader
	self.stationManager = stationManager
	self.eventEmitter = eventEmitter
	self.orders = {}
	self:setupEventListeners()
	return self
end

function OrderManager:setupEventListeners()
	self.eventEmitter:subscribe("crafting-order", function(order)
		self:onNewOrder(order)
	end)
end

---@param order crafting_order
function OrderManager:onNewOrder(order)
	-- supposed to trigger on event
	self.orders[order.orderID] = order
	self.threader:addThread(function()
		self:startOrder(order)
	end, function()
		self:onOrderFinished(order)
	end)
end

---@param order crafting_order
---@return boolean
function OrderManager:orderFinished(order)
	-- order is finished when count went to 0, and all processes finished
	return order.requestedItemCount == 0 and order.aliveProcesses == 0
end

function OrderManager:awaitStations()
	-- switch to different process while there's no available stations
	while self.stationManager:available() == 0 do
		sleep(0.05)
	end
end

--- Splitting order between stations
---@param order crafting_order
---@return standard_crafting_task
function OrderManager:generateTask(order)
	if order.requestedItemCount <= 0 then
		error("Trying to generateTask for finished order")
	end
	local task = {
		requestedItemName = order.requestedItemName,
		requestedItemCount = 1,
	}
	order.requestedItemCount = order.requestedItemCount - 1
	return task
end

function OrderManager:startCrafting(task, order, station)
	order.aliveProcesses = order.aliveProcesses + 1
	self.threader:addThread(function()
		-- main function
		craft(buffer, buffer, station, task, order)
	end, function()
		-- callback when it's done
		order.aliveProcesses = order.aliveProcesses - 1
		self.stationManager:onFinished(station)
	end)
end

---@param order crafting_order
function OrderManager:assignStations(order)
	local total = self.stationManager:available()
	for _ = 1, total do
		local task = self:generateTask(order)
		local station = self.stationManager:getOneStation()
		self:startCrafting(task, order, station)
	end
end

function OrderManager:assignStation(order)
	if self.stationManager:available() <= 0 then
		error("Trying to assign a task, but no free stations")
	end
	local task = self:generateTask(order)
	local station = self.stationManager:getOneStation()
	self:startCrafting(task, order, station)
end

---@param order crafting_order
function OrderManager:startOrder(order)
	-- self.queue[id]= { name = item, count = maxCraft, state = "waiting", id = id}
	order.aliveProcesses = 0

	while not self:orderFinished(order) do
		self:awaitStations() -- wait for stations to be free

		-- assign station if order isn't assigned fully
		while self.stationManager:anyFreeStations() and order.requestedItemCount > 0 do
			self:assignStation(order)
		end

		sleep(0.05)
	end
end

---@param order crafting_order
function OrderManager:onOrderFinished(order)
	self.eventEmitter:emit("order-finished", order)
end

return OrderManager
