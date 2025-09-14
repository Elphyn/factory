local NetworkManager = dofile("factory/shared/NetworkManager.lua")

local ControllerNetworkManager = {}
ControllerNetworkManager.__index = ControllerNetworkManager
setmetatable(ControllerNetworkManager, { __index = NetworkManager })

function ControllerNetworkManager.new(eventEmitter, storageManager, threader)
	local self = setmetatable(NetworkManager.new(eventEmitter, threader), ControllerNetworkManager)
	self.storageManager = storageManager
	self:setupEvents()
	return self
end

function ControllerNetworkManager:setupEvents()
	self.eventEmitter:subscribe("new-order", function(order)
		self:sendOrder(order)
	end)
end

function ControllerNetworkManager:getNodeBuffer(nodeID)
	local msg = {
		event = "get-buffer",
	}
	return self:makeRequest(nodeID, msg, "response-buffer").buffer
end

function ControllerNetworkManager:requestStationCount(nodeID)
	local msg = {
		event = "get-stations",
	}
	return self:makeRequest(nodeID, msg, "response-stations").n
end

function ControllerNetworkManager:sendOrder(order)
	self.threader:addThread(function()
		local buffer = self:getNodeBuffer(order.assignedNodeId)
		self.storageManager:insertOrderDependencies(order, buffer)

		self:makeRequest(order.assignedNodeId, order, "response-order")
		order.state = "Sent"
	end)
end

return ControllerNetworkManager
