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

function NetworkManager:respond(senderID, messageID, additionalData)
	local response = {
		action = "confirm",
		messageID = messageID,
	}
	-- any additianal data
	local anyAdditionalData = false
	for k, v in pairs(additionalData) do
		anyAdditionalData = true
		response[k] = v
	end
	-- if there's additianal data you want confirmation
	self:sendMessage(senderID, response, 0, anyAdditionalData)
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

function NetworkManager:listen()
	if not rednet.isOpen() then
		error("Can't listen if rednet isn't open")
	end

	local _, msg = rednet.receive()
	self:handleMessage(msg)
end

function NetworkManager:handleMessage(msg)
	self.eventEmitter:emit(msg.action, msg)
end

function NetworkManager:sendMessage(id, msg, timeout, needConfirm, responseEvent)
	-- sending anythign but table with action would break the event system
	if type(msg) ~= "table" then
		error("We can only send messages of table format")
	end
	if not msg.action then
		error("Message doesn't have an event attached")
	end

	-- message id is required to know which message is being confirmed
	msg.messageID = self:generateID()
	-- just to make life easier
	msg.senderID = os.getComputerID()

	while true do
		print("Sending: ")
		print(textutils.serialize(msg))
		local ok = rednet.send(id, msg)
		print("Sent an event: ", msg.action)
		-- we check if message was sent, not if it was received
		if not ok then
			error("Couldn't send a message: ", msg.action)
		end

		-- if we don't need a confirmation then we just quit early, made for confirm messages
		if not needConfirm then
			break
		end

		-- here we check if it was received
		print("Waiting for response for id: ", msg.messageID)
		local ok, data = self:awaitResponse(msg.messageID, timeout)
		if ok then
			print("Got response for id: ", msg.messageID)
			return data
		end
	end
end

return NetworkManager
