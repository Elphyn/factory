-- function NetworkManager:sendNStations(id, n)
-- function NetworkManager:sendBuffer(id)
-- function NetworkManager:onOrderDone(order)
local NetworkManager = dofile("factory/shared/NetworkManager.lua")

local WorkerNetworkManager = {}
WorkerNetworkManager.__index = WorkerNetworkManager
setmetatable(WorkerNetworkManager, { __index = NetworkManager })

function WorkerNetworkManager.new(eventEmitter, stationManager)
	local self = NetworkManager.new(eventEmitter) -- base fields initialized
	setmetatable(self, WorkerNetworkManager)
	self.stationManager = stationManager
	self:setupEvents()
	return self
end

function WorkerNetworkManager:setupEvents()
	self.eventEmitter:subscribe("get-buffer", function(msg)
		self:sendBuffer(msg)
	end)
	self.eventEmitter:subscribe("get-stations", function(msg)
		print("handling event get-stations")
		self:sendStationsCount(msg)
	end)
	self.eventEmitter:subscribe("crafting-order", function(order)
		self:confirmOrder(order)
	end)
	self.eventEmitter:subscribe("order-finished", function(order)
		self:notifyOrderFinished(order)
	end)
end

function WorkerNetworkManager:confirmOrder(order)
	self:fulfilRequest(order, {})
end

function WorkerNetworkManager:notifyOrderFinished(order)
	local msg = {
		action = "order-finished",
		yeild = order.yeild,
		orderId = order.id,
		buffer = buffer,
	}

	print("order-finished")
	print(textutils.serialize(order))

	self:makeRequest(order.senderID, msg, "response-order-received")
end

function WorkerNetworkManager:sendStationsCount(request)
	local count = self.stationManager:countStations()
	local msg = {
		n = count,
	}
	self:fulfilRequest(request, msg)
end

function WorkerNetworkManager:fulfilRequest(request, data)
	if request.action == "get-stations" then
		data.action = "response-stations"
	elseif request.action == "get-buffer" then
		data.action = "response-buffer"
	elseif request.action == "crafting-order" then
		data.action = "response-order"
	end

	data.messageID = request.messageID
	rednet.send(request.senderID, data)
end

function WorkerNetworkManager:sendBuffer(request)
	local buffer = dofile("factory/worker/config.lua").bufferNameGlobal
	local msg = {
		buffer = buffer,
	}
	self:fulfilRequest(request, msg)
end

return WorkerNetworkManager
