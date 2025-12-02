---@module 'EventEmitter'
local EventEmitter = {}
EventEmitter.__index = EventEmitter

local Queue = dofile("factory/shared/Queue.lua")

---@class EventEmitter
---@field threader Threader
---@field callbacks table
---@field asyncCallbacks table
---@field events Queue
---@field processedMessages table
---@field nextID number

--- Creates new EventEmitter
---@param threader Threader
---@return EventEmitter
function EventEmitter.new(threader)
	local self = setmetatable({}, EventEmitter)
	self.threader = threader
	self.callbacks = {}
	self.asyncCallbacks = {}
	self.events = Queue.new()
	self.processedMessages = {}
	self.nextID = 1
	return self
end

---Plain id generator
---@return number
function EventEmitter:generateID()
	local id = self.nextID
	self.nextID = self.nextID + 1
	return id
end

---Call a function on event
---@param event string
---@param callback function
---@param async? boolean
---@return function
function EventEmitter:subscribe(event, callback, async)
	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end

	local eventID = self:generateID() -- to safely remove in the future
	if callback then
		self.callbacks[event][eventID] = callback
		self.callbacks[event][eventID] = {
			fn = callback,
			async = async or false,
		}
	end

	-- for clear up, unsubcribe function
	return function()
		self.callbacks[event][eventID] = nil
	end
end

---Main loop of EventEmitter
function EventEmitter:handleEvents()
	while self.events:length() > 0 do
		local unprocessedEvent = self.events:pop()
		local event = unprocessedEvent.event
		print("Handling event: ", event)
		local data = unprocessedEvent.data

		-- making sure duplicate messages are ignored
		-- if one message with this id was handled, then we it's fine now
		if data.messageID ~= nil then
			-- this means that we're handling a message event, there could be duplicates so need to avoid them
			if self.processedMessages[data.messageID] then
				goto continue
			end
			self.processedMessages[data.messageID] = true
		end

		if self.callbacks[event] then
			for _, callback in pairs(self.callbacks[event]) do
				-- there's a bunch of blocking operations and they take time
				-- so we need to make them work in parallel
				--
				if callback.async then
					self.threader:addThread(function()
						callback.fn(table.unpack(data))
					end)
				else
					callback.fn(table.unpack(data))
				end
			end
		end
		::continue::
	end
end

---Emit an event, triggering subscribed callbacks
---@param event string
---@param ... unknown args for callbacks
function EventEmitter:emit(event, ...)
	local unprocessedEvent = {
		event = event,
		data = table.pack(...),
	}
	self.events:push(unprocessedEvent)
end

return EventEmitter
