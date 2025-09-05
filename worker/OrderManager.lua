local OrderManager = {}
local craft = require("crafting")
local buffer = require("config").bufferName
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

function OrderManager:onNewOrder(order)
	-- supposed to trigger on event
	self.orders[order.id] = order
	print("Starting order:")
	self.threader:addThread(function()
		self:startOrder(order)
	end, function()
		self:onOrderFinished(order)
	end)
end

function OrderManager:orderFinished(order)
	-- order is finished when count went to 0, and all processes finished
	return order.count == 0 and order.aliveProcesses == 0
end

function OrderManager:awaitStations()
	-- switch to different process while there's no available stations
	while self.stationManager:available() == 0 do
		sleep(0.05)
	end
end

function OrderManager:generateTask(order)
	if order.count <= 0 then
		error("Trying to generateTask for finished order")
	end
	local task = {
		order = order.item,
		count = 1,
	}
	order.count = order.count - 1
	return task
end

function OrderManager:startCrafting(task, order, station)
	order.aliveProcesses = order.aliveProcesses + 1
	self.threader:addThread(function()
		-- main function
		print("Started crafting: ")
		craft(buffer, buffer, station, task, order)
	end, function()
		-- callback when it's done
		order.aliveProcesses = order.aliveProcesses - 1
		self.stationManager:onFinished(station)
	end)
end

function OrderManager:assignStations(order)
	local total = self.stationManager:available()
	for i = 1, total do
		local task = self:generateTask(order)
		local station = self.stationManager:getOneStation()
		self:startCrafting(task, order, station)
	end
end

function OrderManager:startOrder(order)
	-- self.queue[id]= { name = item, count = maxCraft, state = "waiting", id = id}
	order.aliveProcesses = 0

	while not self:orderFinished(order) do
		self:awaitStations()

		if order.count > 0 then
			self:assignStations(order)
		end

		sleep(0.05)
	end
end

function OrderManager:onOrderFinished(order)
	self.eventEmitter:emit("order-finished", order)
end

return OrderManager
