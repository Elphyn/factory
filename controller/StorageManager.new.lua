local storedItem = require("storedItem")
local deepCopy = dofile("factory/utils/deepCopy.lua")
---
---@class storageManager
---@field eventEmitter EventEmitter
---@field items table<string, storedItem> -- <-- Setting up storedItem class here
---@field mutex boolean
---
local storageManager = {}
storageManager.__index = storageManager

---Creates a Storage Manager
---@param eventEmitter EventEmitter
---@return storageManager
function storageManager.new(eventEmitter)
	local self = setmetatable({}, storageManager)
	self.eventEmitter = eventEmitter -- <-- recognized as eventEmitter class here
	self.items = {}
	self.mutex = false
	return self
end

-- Notes:
-- 1) Look into update locks, probably enough to have one variable

---Creates a snapshot of all item's totals for comparison
---@return table<string, number>
function storageManager:snapshotTotals()
	local totals = {}
	for name, item in pairs(self.items) do
		totals[name] = item:getTotal()
	end
	return deepCopy(totals)
end

---Initialize item for the first time
---@param name string
---@param displayName string
function storageManager:initializeItem(name, displayName)
	self.items[name] = storedItem.new(name, displayName)
end

--- Checks for changes in storage and updates it
function storageManager:update() end

return storageManager
