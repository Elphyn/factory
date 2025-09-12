local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new(threader)
	local self = setmetatable({}, EventEmitter)
	self.threader = threader
	self.callbacks = {}
	self.asyncCallbacks = {}
	self.events = {}
	return self
end

function EventEmitter:subscribe(event, callback, async)
	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end

	local fn = {
		-- if you didn't pass async, then it's gonna make it nil
		-- we need false if nil
		async = async or false,
		callback = callback,
	}

	if callback then
		table.insert(self.callbacks[event], fn)
	end

	-- for clear up, unsubcribe function
	local index = #self.callbacks[event]
	return function()
		table.remove(self.callbacks[event], index)
	end
end

function EventEmitter:handleEvents()
	while #self.events > 0 do
		local unprocessedEvent = table.remove(self.events) -- stack behaiviour, might change to fifo in the future if there's issues
		local event = unprocessedEvent.event
		print("Processing event: ", event)
		local data = unprocessedEvent.data
		if self.callbacks[event] then
			for _, fn in ipairs(self.callbacks[event]) do
				if fn.async then
					self.threader:addThread(
						function() -- if callback async, it's might be blocking, we need to separate it from others
							fn.callback(table.unpack(data))
						end
					)
				else
					fn.callback(table.unpack(data))
				end
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
	table.insert(self.events, unprocessedEvent)
end

return EventEmitter
