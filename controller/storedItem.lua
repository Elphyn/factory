---@type Queue
local Queue = dofile("factory/shared/Queue.lua")
---@type fun(value: unknown, expected: type, name: string)
local assertType = dofile("factory/utils/assertType.lua")

--- @alias movedItems number Number of moved items in the process
---
---@class slot
---@field chestName string
---@field chestIndex number
---@field itemCount number

---@class item
---@field itemName string
---@field displayName string
---@field itemLimit number
---@field weight number
---@field slots slot[]
---@field partiallyFilledSlots Queue
---@field total number
---
local item = {}
item.__index = item
---
---@param itemName itemName
---@param displayName string
---@param itemLimit number
---@param weight number
function item.new(itemName, displayName, itemLimit, weight)
	assertType(itemName, "string", "itemName")
	assertType(displayName, "string", "displayName")
	assertType(itemLimit, "number", "itemLimit")
	assertType(weight, "number", "weight")
	local self = setmetatable({}, item)
	self.itemName = itemName
	self.displayName = displayName
	self.itemLimit = itemLimit
	self.weight = weight
	self.slots = {}
	self.partiallyFilledSlots = Queue.new()
	self.total = 0
	return self
end

---Saves information about item occurence in a chest, to later reference
---@param chestName string
---@param chestIndex number
---@param itemCount number
function item:addSlot(chestName, chestIndex, itemCount)
	---@type slot
	local slot = {
		chestName = chestName,
		chestIndex = chestIndex,
		itemCount = itemCount,
	}
	self.total = self.total + slot.itemCount
	table.insert(self.slots, slot)
end
--- Remove all saved item slots and total count
function item:reset()
	self.slots = {}
	self.partiallyFilledSlots = Queue.new()
	self.total = 0
end

--- Moves items in other storage peripheral
--- @param location string
--- @param count number
--- @return boolean, movedItems
function item:pushItem(location, count)
	-- Count check should happen up the abstraction, if total is lower here, then something is very wrong
	if count > self.total then
		error("Not enough items when moving item " .. self.displayName)
	end

	local initialCount = count
	local totalMoved = 0
	while count > 0 do
		-- If we're here we're assuming we have enough, if no slots but total thinks it's enough then something is very wrong
		if #self.slots == 0 then
			error("Not enough slots when moving items, please check if scanner works well")
		end

		local slot = self.slots[#self.slots]
		local insertAmount = math.min(count, slot.itemCount)

		local chest = peripheral.wrap(slot.chestName)

		-- Chest could be broken mid transfer
		if chest == nil then
			return false, totalMoved
		end

		local moved = chest.pushItems(location, slot.chestIndex, insertAmount)

		totalMoved = totalMoved + moved
		count = count - moved
		slot.itemCount = slot.itemCount - moved

		if slot.itemCount < 0 then
			error("Slot item count is below 0, a bug, look into this")
		end

		if slot.itemCount == 0 then
			table.remove(self.slots)
		end
	end
	return initialCount == totalMoved, totalMoved
end

---@class locatedSlot
---@field count itemCount
---@field index number
---
---Finds every slot in a peripheral that is of this item name
---@param chestName string
---@return locatedSlot[]
function item:locateSlots(chestName)
	local chest = peripheral.wrap(chestName)
	if not chest then
		error("chest with a name: " .. chestName .. " does not exist")
	end
	local items = chest.list()

	local slots = {}
	for i, slot in pairs(items) do
		if slot.name == self.itemName then
			local slotInfo = {
				count = slot.count,
				index = i,
			}
			table.insert(slots, slotInfo)
		end
	end

	return slots
end

--- @param from string
--- @param count itemCount
function item:pullItem(from, count)
	local slots = self:locateSlots(from)
end

return item
