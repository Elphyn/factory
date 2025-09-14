local NetworkManager = {}
NetworkManager.__index = NetworkManager

local Queue = dofile("factory/shared/Queue.lua")

function NetworkManager.new(eventEmitter, threader)
	local self = setmetatable({}, NetworkManager)
	self.threader = threader
	self.eventEmitter = eventEmitter
	self.nextID = 1
	self.messages = Queue.new()
	return self
end

function NetworkManager:generateID()
	local id = self.nextID
	self.nextID = self.nextID + 1
	return id
end

function NetworkManager:makeRequest(nodeID, request, awaitEvent)
	-- local retryCount = 0

	request.messageID = self:generateID()
	request.senderID = os.getComputerID()

	local resolved = false
	local captured = nil

	-- while retryCount < 5 do
	while true do
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
		end, true)

		print("Wating for: " .. awaitEvent)
		while os.clock() - startTime < 5 and not resolved do
			sleep(0.05) -- switch
		end

		removeListener()
		if resolved then
			return captured
		end
	end
end

function NetworkManager:listen()
	if not rednet.isOpen() then
		error("Can't listen if rednet isn't open")
	end

	local _, msg = rednet.receive()

	self.messages:push(msg)
end

function NetworkManager:handleMessages()
	while self.messages:length() > 0 do
		local msg = self.messages:pop()
		self:handleMessage(msg)
	end
end

function NetworkManager:handleMessage(msg)
	self.eventEmitter:emit(msg.event, msg)
end

return NetworkManager
