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
	self.eventEmitter:subscribe("order-finished", function(order)
		self:notifyOrderFinished(order)
	end)
end

function WorkerNetworkManager:notifyOrderFinished(order)
	local msg = {
		action = "order-finished-received",
		yeild = order.yeild,
		orderId = order.id,
		buffer = buffer,
	}

	self:sendMessage(order.senderId, msg, 0.1, true)
end

function WorkerNetworkManager:sendStationsCount(request)
	local count = self.stationsManager:countStations()
	local msg = {
		n = count,
	}
	self:respond(request.senderID, request.messageID, msg)
end

function WorkerNetworkManager:sendBuffer(request)
	local buffer = dofile("factory/worker/config.lua").bufferNameGlobal
	local msg = {
		buffer = buffer,
	}
	-- since it's waiting for a response, we don't send, we confirm
	self:respond(request.senderID, request.messageID, msg)
end

return WorkerNetworkManager
