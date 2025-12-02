---@class storedItem
---@field name string
---@field displayName string
---@field total number
---@field slots table TODO: need to change this to an actual type here
---
local storedItem = {}
storedItem.__index = storedItem

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
	return self
end

--- Get total of the item
---@return number
function storedItem:getTotal()
	return self.total
end

return storedItem
