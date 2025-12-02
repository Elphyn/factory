---@module 'StorageManager'
---
---@class storageManager
---@field eventEmitter EventEmitter
---
local storageManager = {}
storageManager.__index = storageManager

---Creates a Storage Manager
---@param eventEmitter EventEmitter
function storageManager.new(eventEmitter)
	local self = setmetatable({}, storageManager)
	self.eventEmitter = eventEmitter
	return self
end

return storageManager
