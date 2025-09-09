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

function NetworkManager.new(eventEmitter, threader)
	local self = setmetatable({}, NetworkManager)
	self.threader = threader
	self.eventEmitter = eventEmitter
	self.nextID = 1
	self.messages = {}
	return self
end

function NetworkManager:generateID()
	local id = self.nextID
	self.nextID = self.nextID + 1
	return id
end

function NetworkManager:makeRequest(nodeID, request, awaitEvent)
	print("Making a request to: ", nodeID)
	local retryCount = 0
	local startTime = os.clock()

	request.messageID = self:generateID()
	request.senderID = os.getComputerID()

	local resolved = false
	local captured = nil

	while retryCount < 5 do
		local ok = rednet.send(nodeID, request)
		if not ok then
			error("Couldn't send a message: ", textutils.serialize(request))
		end

		local removeListener = self.eventEmitter:subscribe(awaitEvent, function(response)
			print(response.messageID .. " ? " .. request.messageID)
			if response.messageID == request.messageID then
				resolved = true
				captured = response
			end
		end)

		while os.clock() - startTime < 5 do
			print("switching")
			sleep(0.05) -- switch
		end

		removeListener()
		if resolved then
			return captured
		end
		print("retry attempt : ", retryCount)
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
	print("received : ")
	print(textutils.serialize(msg))

	table.insert(self.messages, msg)
end

function NetworkManager:handleMessages()
	while #self.messages > 0 do
		local msg = table.remove(self.messages)
		self:handleMessage(msg)
	end
end

function NetworkManager:handleMessage(msg)
	self.eventEmitter:emit(msg.action, msg)
end

return NetworkManager
