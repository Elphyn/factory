local NetworkManager = dofile("factory/shared/NetworkManager.lua")

local ControllerNetworkManager = {}
ControllerNetworkManager.__index = ControllerNetworkManager
setmetatable(ControllerNetworkManager, { __index = NetworkManager })

function ControllerNetworkManager.new(eventEmitter, storageManager, threader)
	local self = setmetatable(NetworkManager.new(eventEmitter, threader), ControllerNetworkManager)
	self.storageManager = storageManager
	self.cached = {
		buffers = {},
		stationCount = {},
	}
	self:setupEvents()
	return self
end

function ControllerNetworkManager:setupEvents()
	self.eventEmitter:subscribe("new-order", function(order)
		self.threader:addThread(function()
			self:sendOrder(order)
		end)
	end)
end

function ControllerNetworkManager:getNodeBuffer(nodeID)
	if not self.cached.buffers[nodeID] then
		print("Requesting buffer")
		local msg = {
			event = "get-buffer",
		}
		local res = self:makeRequest(nodeID, msg, "response-buffer").buffer
		self.cached.buffers[nodeID] = res
		return res
	end
	return self.cached.buffers[nodeID]
end

function ControllerNetworkManager:requestStationCount(nodeID)
	if not self.cached.stationCount[nodeID] then
		print("requesting station")
		local msg = {
			event = "get-stations",
		}
		local res = self:makeRequest(nodeID, msg, "response-stations").n
		self.cached.stationCount[nodeID] = res
		return res
	end
	return self.cached.stationCount[nodeID]
end

return ControllerNetworkManager
