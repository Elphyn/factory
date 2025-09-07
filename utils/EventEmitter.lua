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

function EventEmitter:awaitWithRetry(event, fn, predictate)
	-- function that executes before waiting, just to send a request
	fn()

	-- a flag to know if we received an answer
	local resolved = false

	-- catching data if we received the answer
	local captured = nil
	local unsubcribe = self:subscribe(event, function(data)
		if predictate(data) then
			captured = data
			resolved = true
		end
	end)

	-- our timeout
	sleep(0.1)
	-- if by the time of getting back here after 100ms we haven't received an answer
	-- we try again
	if not resolved then
		unsubcribe()
		-- recursion, really didn't want to bother with timers
		print("Didn't receive an event, retrying")
		return self:awaitWithRetry(event, fn, predictate)
	end
	unsubcribe()
	return captured
end

function EventEmitter:await(event, predictate)
	local resolved = false

	local captured = nil
	-- predictate is just a condition to differienciate, could be multiple awaits on same event
	-- so which one we resolve? The one that passes predictate condition
	-- although it's probably a bad idea to control this part outside of this function
	local unsubcribe = self:subscribe(event, function(data)
		if predictate(data) then
			captured = data
			resolved = true
		end
	end)

	-- waiting until resolved
	while not resolved do
		sleep(0.05) -- non blocking due to how event's work in cc:tweaked
	end

	-- clean up
	unsubcribe()
	return captured
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
