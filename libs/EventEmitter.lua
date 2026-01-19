---@alias callbackID number
---@alias eventName string
---
---
---@class callback
---@field async boolean
---@field fn function
---
---@alias callbacks table<callbackID, callback>
---
---@class EventEmitter
---@field threader Threader
---@field callbacks table<eventName, callbacks>
---@field nextID number
---
local EventEmitter = {}
EventEmitter.__index = EventEmitter

--- Creates new EventEmitter
---@param threader Threader
---@return EventEmitter
function EventEmitter.new(threader)
	local self = setmetatable({}, EventEmitter)
	self.threader = threader
	self.callbacks = {}
	self.nextID = 1
	return self
end

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
---@return function returns an unsubcribe function to remove listener
function EventEmitter:on(event, callback, async)
	if not callback then
		error("Not passed callback in eventEmitter.on")
	end

	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end

	local eventID = self:generateID()
	self.callbacks[event][eventID] = {
		fn = callback,
		async = async or false,
	}

	-- for clean up, unsubcribe function
	return function()
		self.callbacks[event][eventID] = nil
	end
end

---Triggers an event, triggering subscribed callbacks
---Note: for non async callback need be careful about blocking behaivor
---@param event eventName
---@param ... unknown args for callback
function EventEmitter:emit(event, ...)
	if not self.callbacks[event] then
		return
	end

	local args = table.pack(...)
	for _, callback in pairs(self.callbacks[event]) do
		-- if async
		if callback.async then
			self.threader:addThread(function()
				callback.fn(table.unpack(args))
			end)
			goto continue
		end
		-- if not async
		callback.fn(...)
		::continue::
	end
end

return EventEmitter
