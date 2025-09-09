local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new()
	local self = setmetatable({}, EventEmitter)
	self.callbacks = {}
	return self
end

function EventEmitter:subscribe(event, callback)
	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end
	if callback then
		table.insert(self.callbacks[event], callback)
	end

	-- for clear up, unsubcribe function
	local index = #self.callbacks[event]
	return function()
		table.remove(self.callbacks[event], index)
	end
end

function EventEmitter:emit(event, ...)
	if not self.callbacks[event] then
		return
	end
	print("Received an event: ", event)
	for _, callback in ipairs(self.callbacks[event]) do
		callback(...)
	end
end

return EventEmitter
