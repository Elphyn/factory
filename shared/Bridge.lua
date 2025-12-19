local EventEmitter = require("EventEmitter")
local Queue = require("Queue")
---@type Buffer
local Buffer = dofile("factory/utils/Buffer.lua")

local BUFFER_CAPACITY = 1024
local MAX_RETRY = 5
local ACK_TIMEOUT = 5
local CHECK_INTERVAL = 0.05

---@alias messageContent table

---@class message
---@field ack boolean
---@field messageID number
---@field from? number
---@field messageContent? messageContent

---An interface by which communication is done between mainpc and node's
---@class Bridge: EventEmitter
---@field messages Queue
---@field acceptedACKS Buffer
---@field processedMessages Buffer
---@field nextID number
local Bridge = {}
Bridge.__index = Bridge
setmetatable(Bridge, { __index = EventEmitter })

---@param threader Threader
function Bridge.new(threader)
	local self = setmetatable(EventEmitter.new(threader), Bridge)
	self.messages = Queue.new()
	self.processedMessages = Buffer.new(BUFFER_CAPACITY)
	self.acceptedACKS = Buffer.new(BUFFER_CAPACITY)
	self.nextID = 1
	return self
end

function Bridge:geneateID()
	local id = self.nextID
	self.nextID = self.nextID + 1
	return id
end

--- main loop of the bridge, always listening for messages
function Bridge:startListening()
	-- A loop that listens and a loop that is handling should never be on the same thread, one could easily block the other one
	-- More so when using EventEmitter:emit method, since it could execute multiple callbacks
	--
	-- main listening loop
	self.threader:addThread(function()
		while true do
			-- TODO: make this information come from config
			if not rednet.isOpen("back") then
				error("Can't listen if rednet isn't open")
			end

			-- rednet.receive has yeild it's source code, just as sleep, so it's non blocking
			local id, message = rednet.receive()
			if not message then
				error("[BRIDGE] Received an empty message from " .. id)
			end
			self.messages:push(message)
		end
	end)

	-- main message handling loop
	self.threader:addThread(function()
		while true do
			while self.messages:length() > 0 do
				---@type message
				local msg = self.messages:pop()
				self:handleMessage(msg)
			end
			sleep(CHECK_INTERVAL)
		end
	end)
end

---@param message message
function Bridge:handleMessage(message)
	-- early exit if the message was already handled

	-- handling acks
	if message.ack then
		self.acceptedACKS:add(message.messageID)
		return
	end

	if self.processedMessages:lookup(message.messageID) then
		-- if we received same message as a retry that means we processed it, but it didn't receive an ack, so sending it again
		self:sendACK(message.from, message.messageID)
		return
	end

	self.processedMessages:add(message.messageID)
	-- before processing sending an ack to inidicate that we received the message
	self:sendACK(message.from, message.messageID)
	self:emit("message_received", message.from, message.messageContent)
end

---@param nodeID number
---@param messageID number
function Bridge:sendACK(nodeID, messageID)
	-- Important to note here, success indicates if the message was sent, not received
	local ack = {
		ack = true,
		messageID = messageID,
	}
	local ok = rednet.send(nodeID, ack)
	if not ok then
		error("[BRIDGE] Failed to send an ack on message, could be due to broken modem")
	end
end

--- Checks whether the message was received on the other end
--- @param messageID number
function Bridge:checkACK(messageID)
	return self.acceptedACKS:lookup(messageID)
end

---@param nodeID number
---@param payload any
---@return success
function Bridge:sendMessage(nodeID, payload)
	local messageID = self:geneateID()
	---@type message
	local message = {
		messageID = messageID,
		ack = false,
		content = payload,
	}

	local acked = false
	local retryCount = 0
	while retryCount < MAX_RETRY do
		local ok = rednet.send(nodeID, message)
		if not ok then
			error("[BRIDGE] Failed to send a message, could be due to broken modem")
		end

		local startTime = os.clock()
		while os.clock() - startTime < ACK_TIMEOUT do
			if self:checkACK(messageID) then
				acked = true
				break
			end
			sleep(CHECK_INTERVAL)
		end
		retryCount = retryCount + 1
	end

	if acked then
		return true
	end

	return false
end

return Bridge
