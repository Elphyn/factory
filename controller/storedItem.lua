local Queue = dofile("factory/shared/Queue.lua")

---@class slot
---@field chestName string
---@field chestIndex number
---@field itemCount number

---@class item
---@field itemName string
---@field displayName string
---@field slots slot[]
---@field total number
---
local item = {}
item.__index = item

---@param itemName string
---@param displayName string
---@return item
function item.new(itemName, displayName)
	local self = setmetatable({}, item)
	self.itemName = itemName
	self.displayName = displayName
	self.slots = {}
	self.total = 0
	return self
end

---Saves informations about slot
---@param slot slot
function item:addSlot(slot)
	self.total = self.total + slot.itemCount
	table.insert(self.slots, slot)
end

---@return number
function item:getTotal()
	return self.total
end

return item
