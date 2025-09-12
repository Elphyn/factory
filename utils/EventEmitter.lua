local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new(threader)
	local self = setmetatable({}, EventEmitter)
	self.threader = threader
	self.callbacks = {}
	self.asyncCallbacks = {}
	self.events = {}
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
	print("Draining events: ")
	while #self.events > 0 do
		local unprocessedEvent = table.remove(self.events) -- stack behaiviour, might change to fifo in the future if there's issues
		local event = unprocessedEvent.event
		local data = unprocessedEvent.data

		for _, callback in pairs(self.events[event]) do
			self.threader:addThread(function()
				callback(table.unpack(data))
			end)
		end
	end
end

function EventEmitter:emit(event, ...)
	print("Received an event: ", event)
	local unprocessedEvent = {
		event = event,
		data = table.pack(...),
	}
	table.insert(self.events, unprocessedEvent)
end

return EventEmitter
