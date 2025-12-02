---@class storedItem
---@field name string
---@field displayName string
---@field total number
---@field slots table TODO: need to change this to an actual type here
---@field partiallyFilledSlots Queue
---
local storedItem = {}
storedItem.__index = storedItem

---@type Queue
local Queue = dofile("factory/utils/Queue.lua")

---Creates stored item
---@param name string
---@param displayName string
---@return storedItem
function storedItem.new(name, displayName)
	local self = setmetatable({}, storedItem)
	self.name = name
	self.displayName = displayName
	self.total = 0
	self.slots = {}
	self.partiallyFilledSlots = Queue.new()
	return self
end

-- Notes:
-- 1) In previous version of storageManager there was item info cached
-- -- So need to add more fields besides displayName
-- 2) Should make a merge function, should be careful with it honestly

--- Get total of the item
---@return number
function storedItem:getTotal()
	return self.total
end

--- Resets total, slots
function storedItem:reset()
	self.total = 0
	self.slots = {}
	self.partiallyFilledSlots:reset()
end

return storedItem
