local NetworkManager = {}
-- local buffer = dofile("factory/").bufferName
NetworkManager.__index = NetworkManager

function NetworkManager.new(eventEmitter, storageManager)
	local self = setmetatable({}, NetworkManager)
	self.storageManager = storageManager
	self.eventEmitter = eventEmitter
	self:setupEventListeners()
	return self
end

function NetworkManager:setupEventListeners()
	self.eventEmitter:subscribe("order-finished", function(...)
		self:onOrderDone(...)
	end)
	self.eventEmitter:subscribe("send-stations", function(senderId, n)
		self:sendNStations(senderId, n)
	end)
	self.eventEmitter:subscribe("new-order", function(order)
		self:sendOrder(order)
	end)
end

function NetworkManager:getBufferOfNode(nodeId)
	local msg = {
		action = "get-buffer",
	}
	return self:sendAwait(nodeId, msg)
end

function NetworkManager:sendOrder(order)
	-- can't send if channel isn't open
	if not rednet.isOpen() then
		error("rednet isn't open")
	end

	-- we need insert items in buffer of Node
	local buffer = self:getBufferOfNode(order.assignedNodeId)
	self.storageManager:insertOrderDependencies(order, buffer)

	-- sending order, and confirming it was received
	-- if it wasn't, we try again
	while true do
		--  sending the order
		local ok = rednet.send(order.assignedNodeId, order)
		if not ok then
			error("Can't send a message")
		end

		-- now we need a confirmation that order was received
		local timeout = 0.1 -- time before trying again
		local protocol = nil
		local id, response = rednet.receive(protocol, timeout)

		-- if we received response + response is for this order
		if id and response == order.id then
			order.state = "In progress"
			return
		end
	end
end

function NetworkManager:sendAwait(id, msg)
	-- since it's possible that in the moment we send
	-- node could not listen
	-- so we need to try a few times
	while true do
		rednet.send(id, msg)
		local senderId, answ = rednet.receive(nil, 0.1)
		if senderId then
			return answ
		end
	end
end

function NetworkManager:getNumStations(nodeId)
	print("Requesting number of stations from: ", nodeId)
	local msg = {
		action = "get-stations",
	}

	local ans = self:sendAwait(nodeId, msg)

	print("Recieved this many stations: ", ans)
	return ans
end

function NetworkManager:sendNStations(id, n)
	print("sending n stations: ", n)
	rednet.send(id, n)
end

function NetworkManager:listen()
	if not rednet.isOpen() then
		error("Rednet isn't open, can't listen")
	end
	local id, msg = rednet.receive()
	self:handleMessage(id, msg)
end

function NetworkManager:sendBuffer(id)
	local buffer = dofile("factory/worker/config.lua").bufferNameGlobal
	local ok = rednet.send(id, buffer)
	if not ok then
		error("Wasn't able to send buffer " .. buffer .. " to " .. id)
	end
end

function NetworkManager:onOrderDone(order)
	if not self.mainPcId then
		error("Node pc hasn't found the main pc")
	end
	if not rednet.isOpen() then
		error("Rednet isn't open, can't send mesasges")
	end

	-- relevant info about order
	local info = {
		action = "order-finished",
		orderId = order.id,
		yeild = order.yeild,
		buffer = buffer,
	}

	local ok = rednet.send(order.senderId, info)

	if not ok then
		error("Couldn't send finished order back to mainPC")
	end
end

function NetworkManager:sendConfirmation(senderId, msg)
	rednet.send(senderId, msg.id)
end

function NetworkManager:handleMessage(senderId, msg)
	print("Received message: ")
	print(textutils.serialize(msg))
	if msg.action == "crafting-order" then
		self.eventEmitter:emit("crafting-order", msg)
		self:sendConfirmation(senderId, msg)
	elseif msg.action == "get-stations" then
		self.eventEmitter:emit("get-stations", senderId)
	elseif msg.action == "get-buffer" then
		self:sendBuffer(senderId)
	elseif msg.action == "order-finished" then
		self.eventEmitter:emit("order-finished-received", msg)
	else
		error("Unknown message recieved")
	end
end

function NetworkManager:sendToMain(info)
	rednet.send(self.mainPcId, info)
end

return NetworkManager
