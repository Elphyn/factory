local EventEmitter = {}
EventEmitter.__index = EventEmitter

local Queue = dofile("factory/shared/Queue.lua")

function EventEmitter.new(threader)
	local self = setmetatable({}, EventEmitter)
	self.threader = threader
	self.callbacks = {}
	self.asyncCallbacks = {}
	self.events = Queue.new()
	self.nextID = 1
	return self
end

function EventEmitter:generateID()
	local id = self.nextID
	self.nextID = self.nextID + 1
	return id
end

function EventEmitter:subscribe(event, callback)
	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end

	local eventID = self:generateID() -- to safely remove in the future
	if callback then
		self.callbacks[event][eventID] = callback
	end

	-- for clear up, unsubcribe function
	return function()
		self.callbacks[event][eventID] = nil
	end
end

function EventEmitter:handleEvents()
	while #self.events > 0 do
		local unprocessedEvent = self.events:pop() -- stack behaiviour, might change to fifo in the future if there's issues
		local event = unprocessedEvent.event
		local data = unprocessedEvent.data

		if self.callbacks[event] then
			for _, callback in pairs(self.callbacks[event]) do
				-- there's a bunch of blocking operations and they take time
				-- so we need to make them work in parallel
				self.threader:addThread(function()
					callback(table.unpack(data))
				end)
			end
		end
	end
end

function EventEmitter:emit(event, ...)
	print("Received an event: ", event)
	local unprocessedEvent = {
		event = event,
		data = table.pack(...),
	}
	self.events:push(unprocessedEvent)
end

return EventEmitter
