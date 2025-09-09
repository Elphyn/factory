-- function NetworkManager:sendConfirmation(senderId, msg)✔️
-- function NetworkManager:sendOrderConfirmation(senderId, msg)✔️
-- function NetworkManager:handleMessage(senderId, msg)✔️
-- function NetworkManager:listen() ✔️
--
-- function NetworkManager:getBufferOfNode(nodeId)
-- function NetworkManager:sendOrder(order)
-- function NetworkManager:getNumStations(nodeId)
-- function NetworkManager:sendNStations(id, n)
-- function NetworkManager:sendBuffer(id)
-- function NetworkManager:onOrderDone(order)
-- function NetworkManager:sendToMain(info)

local NetworkManager = {}
NetworkManager.__index = NetworkManager

function NetworkManager.new(eventEmitter)
	local self = setmetatable({}, NetworkManager)
	self.eventEmitter = eventEmitter
	self.nextID = 1
	return self
end

function NetworkManager:generateID()
	local id = self.nextID
	self.nextID = self.nextID + 1
	return id
end

function NetworkManager:awaitResponse(messageID, timeout)
	local resolved = false
	local data = nil

	-- using event system to detect if message is confirmed
	local unsubscribe = self.eventEmitter:subscribe("confirm", function(msg)
		-- this is to know which exact message was confirmed
		if msg.messageID == messageID then
			resolved = true
			data = msg
		end
	end)

	-- if no timeout is set, we wait indefinitely
	if not timeout then
		while true do
			if resolved then
				break
			end
			sleep(0.05)
		end
	end

	-- if there's timeout, then we wait set amount of time
	if timeout then
		sleep(timeout)
	end

	-- clean up
	unsubscribe()
	return resolved, data
end

function NetworkManager:makeRequest(nodeID, request, awaitEvent)
	local retryCount = 0

	request.messageID = self:generateID()
	request.senderID = os.getComputerID()

	local resolved = false
	local captured = nil

	while retryCount < 5 do
		local startTime = os.clock()
		local ok = rednet.send(nodeID, request)
		if not ok then
			error("Couldn't send a message: ", textutils.serialize(request))
		end

		local removeListener = self.eventEmitter:subscribe(awaitEvent, function(response)
			if response.messageID == request.messageID then
				resolved = true
				captured = response
			end
		end)

		while os.clock() - startTime < 1 do
			sleep(0.05) -- switching
		end

		removeListener()
		if resolved then
			return captured
		end
		retryCount = retryCount + 1
	end
	error("Request: " .. textutils.serialize(request) .. "Wasn't fulfilled")
end

function NetworkManager:listen()
	if not rednet.isOpen() then
		error("Can't listen if rednet isn't open")
	end

	print("listening for instructions: ")
	local _, msg = rednet.receive()
	self:handleMessage(msg)
end

function NetworkManager:handleMessage(msg)
	self.eventEmitter:emit(msg.action, msg)
end

return NetworkManager
