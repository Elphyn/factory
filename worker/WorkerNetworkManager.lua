local NetworkManager = dofile("factory/shared/NetworkManager.lua")
local buffer = dofile("config.lua").bufferNameGlobal

local WorkerNetworkManager = {}
WorkerNetworkManager.__index = WorkerNetworkManager
setmetatable(WorkerNetworkManager, { __index = NetworkManager })

function WorkerNetworkManager.new(eventEmitter, stationManager, threader)
	local self = NetworkManager.new(eventEmitter, threader) -- base fields initialized
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
		self:sendStationsCount(msg)
	end)
	self.eventEmitter:subscribe("crafting-order", function(order)
		self:confirmOrder(order)
	end)
	self.eventEmitter:subscribe("order-finished", function(order)
		self:notifyOrderFinished(order)
	end)
end

function WorkerNetworkManager:findMainID()
	if self.mainID then
		return true
	end
	local devices = peripheral.getNames()
	for _, name in ipairs(devices) do
		if string.match(name, "^computer") then
			local pc = peripheral.wrap(name)
			local pcName = pc.getLabel()
			if pcName == "MainPC" then
				self.mainID = pc.getID()
				return true
			end
		end
	end
	return false
end

function WorkerNetworkManager:notifyStart(n, buffer, type)
	local msg = {
		event = "node-ready",
		type = type,
		id = os.getComputerID(),
		stations = n,
		buffer = buffer,
	}
	local ok = self:findMainID()
	if ok then
		rednet.send(self.mainID, msg)
		print("Sent start notification on main")
	else
		error("Could't find the mainPC")
	end
end

function WorkerNetworkManager:confirmOrder(order)
	self:fulfilRequest(order, {})
end

function WorkerNetworkManager:notifyOrderFinished(order)
	local msg = {
		event = "order-finished",
		name = order.name,
		yield = order.yield,
		orderID = order.id,
		buffer = buffer,
	}

	rednet.send(order.senderID, msg)
end

function WorkerNetworkManager:sendStationsCount(request)
	local count = self.stationManager:countStations()
	local msg = {
		n = count,
	}
	self:fulfilRequest(request, msg)
end

function WorkerNetworkManager:fulfilRequest(request, data)
	if request.event == "get-stations" then
		data.event = "response-stations"
	elseif request.event == "get-buffer" then
		data.event = "response-buffer"
	elseif request.event == "crafting-order" then
		data.event = "response-order"
	end

	data.messageID = request.messageID
	local ok = rednet.send(request.senderID, data)
end

function WorkerNetworkManager:sendBuffer(request)
	local buffer = dofile("config.lua").bufferNameGlobal
	local msg = {
		buffer = buffer,
	}
	self:fulfilRequest(request, msg)
end

return WorkerNetworkManager
