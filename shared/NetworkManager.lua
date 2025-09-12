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

		local async = true
		local removeListener = self.eventEmitter:subscribe(awaitEvent, function(response)
			if response.messageID == request.messageID then
				resolved = true
				captured = response
			end
		end, async)

		while os.clock() - startTime < 5 do
			sleep(0.05) -- switch
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

	local _, msg = rednet.receive()

	table.insert(self.messages, msg)
end

function NetworkManager:handleMessages()
	while #self.messages > 0 do
		local msg = table.remove(self.messages)
		self:handleMessage(msg)
	end
end

function NetworkManager:handleMessage(msg)
	self.eventEmitter:emit(msg.event, msg)
end

return NetworkManager
