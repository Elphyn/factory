-- function NetworkManager:getBufferOfNode(nodeId)
-- function NetworkManager:sendOrder(order)
-- function NetworkManager:getNumStations(nodeId)
--
local NetworkManager = dofile("factory/shared/NetworkManager.lua")

local ControllerNetworkManager = {}
ControllerNetworkManager.__index = ControllerNetworkManager
setmetatable(ControllerNetworkManager, { __index = NetworkManager })

function ControllerNetworkManager.new(eventEmitter, storageManager)
	local self = setmetatable(NetworkManager.new(eventEmitter), ControllerNetworkManager)
	self.storageManager = storageManager
	self:setupEvents()
	return self
end

function ControllerNetworkManager:setupEvents()
	self.eventEmitter:subscribe("new-order", function(order)
		self:sendOrder(order)
	end)
	self.eventEmitter:subscribe("order-finished", function(msg)
		self:confirmOrderReceived(msg)
	end)
end

function ControllerNetworkManager:getNodeBuffer(nodeID)
	local msg = {
		action = "get-buffer",
	}
	return self:makeRequest(nodeID, msg, "response-buffer").buffer
end

function ControllerNetworkManager:requestStationCount(nodeID)
	local msg = {
		action = "get-stations",
	}
	return self:makeRequest(nodeID, msg, "response-stations").n
end

function ControllerNetworkManager:confirmOrderReceived(msg)
	local response = {
		action = "response-order-received",
		messageID = msg.messageID,
	}
	print("responding to orderReceived")
	rednet.send(msg.senderID, response)
end

function ControllerNetworkManager:sendOrder(order)
	local buffer = self:getNodeBuffer(order.assignedNodeId)
	self.storageManager:insertOrderDependencies(order, buffer)

	self:makeRequest(order.assignedNodeId, order, "response-order")
	order.state = "Sent"
end

return ControllerNetworkManager
