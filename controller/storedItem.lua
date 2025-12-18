---@type Queue
local Queue = dofile("factory/shared/Queue.lua")
---@type fun(value: unknown, expected: type, name: string)
local assertType = dofile("factory/utils/assertType.lua")

---@alias movedItems number Number of moved items in the process
---@alias success boolean a flag to indicate whether the operation succeded
---@alias moved number amount of items moved during an operation
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
---@field freeSlots freeSlot[]
---
local item = {}
item.__index = item
---
---@param itemName itemName
---@param displayName string
---@param itemLimit number
---@param weight number
---@param sharedFreeSlots slot[]
function item.new(itemName, displayName, itemLimit, weight, sharedFreeSlots)
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
	self.freeSlots = sharedFreeSlots
	return self
end

---Saves information about item occurence in a chest, to later reference
---@param chestName string
---@param chestIndex number
---@param itemCount number
function item:addSlot(chestName, chestIndex, itemCount)
	if itemCount > self.itemLimit then
		error(
			"Fatal error, adding slot with count of "
				.. itemCount
				.. " while limit on the item "
				.. self.displayName
				.. " is "
				.. self.itemLimit
		)
	end
	---@type slot
	local slot = {
		chestName = chestName,
		chestIndex = chestIndex,
		itemCount = itemCount,
	}
	self.total = self.total + slot.itemCount

	-- If the slot is fully filled we add it to slots, from now on considering all slots to be fully filled
	-- also, that would require to update the state of the storage before triggering any movements
	if itemCount == self.itemLimit then
		table.insert(self.slots, slot)
		return
	end

	-- if slot isn't fully filled then we're adding it to
	self.partiallyFilledSlots:push(slot)
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

-- Note:
-- There's a lot of error's thrown here, for now those are for debugging
-- It's planned to make it non failing, most of the fails could be recovered with a retry + update of the state
-- The error on drawer being inaccessible is more tricky, not sure about that yet, since node and controller interact with it differently

---@param from string a storage from which to relocate items
---@param itemSlots slot[] number of slots in which items are located
---@param itemCount number amount of items to relocate
---@param slots Queue a slots in which items could be relocated, accepting Queue that is consists of partially filled or free slots
---@return moved
function item:relocateItems(from, itemSlots, itemCount, slots)
	-- since the only movement from and to storage is with node's buffer, which I decided to be a drawer block
	local drawer = peripheral.wrap(from)

	if not drawer then
		-- Note:
		-- If system thinks node's buffer `from` exists but it doesn't then something is wrong
		-- This doesn't mean I should crash the system here though, should be an error for now, but later just abort the operation and retry after an update
		-- This does insinuate that I have to make sure node's communation bridge is reporting correctly of it's own changes of state
		-- That includes a `broken` state, and an upate when it's `stable` again to interact with it
		error("Buffer " .. from .. " no longer exists, check state of the node assosiated with it")
	end

	local totalMoved = 0
	while itemCount > 0 and slots:length() > 0 do
		---@type slot|freeSlot
		local insertSlot = slots:peek()

		if #itemSlots == 0 then
			error("[Item relocation] item slots are exhausted but the itemCount is still above 0")
		end
		--
		local slot = itemSlots[#itemSlots]
		-- Since freeSlot doesn't have a field of itemCount, since it's empty need to take care of that
		local maxInsertPossible = self.itemLimit - (insertSlot.itemCount or 0)
		-- amount of items we can insert into
		local insertAmount = math.min(maxInsertPossible, itemCount, slot.itemCount)

		local chest = peripheral.wrap(insertSlot.chestName)

		-- if that happens then there's a mismatch of reality, system thinks there's a chest with a slot to fill, but there's none
		-- keeping system going after that is not a good idea until there's a proper retry system with updates in between
		if not chest then
			error(
				"[FATAL ERROR] system has wrong state of the system, acesed a slot but no chest is present, chest: "
					.. insertSlot.chestName
			)
		end

		-- the movement itself:
		local moved = chest.pullItems(from, slot.chestIndex, insertAmount, insertSlot.chestIndex)

		-- we expected to move insertAmount, if the actual moved isn't the same amount, then something is wrong, for debugging should log it
		if moved ~= insertAmount then
			error(
				"[DEBUG] Expected to move "
					.. insertAmount
					.. " to "
					.. slot.chestName
					.. " of item "
					.. self.displayName
					.. " but moved "
					.. moved
			)
		end

		-- aftermath of the operation:
		slot.itemCount = slot.itemCount - moved
		insertSlot.itemCount = insertSlot.itemCount + moved
		itemCount = itemCount - moved
		totalMoved = totalMoved + moved

		-- on exhausiting either insert slots or item slots we stop the loop
		if slot.itemCount == 0 then
			-- removing slot if we exhausted it
			table.remove(itemSlots)

			if #itemSlots == 0 then
				break
			end
		end

		if insertSlot.itemCount == self.itemLimit then
			slots:pop()

			if slots:length() == 0 then
				break
			end
		end
	end
	return totalMoved
end

--- @param from string peripheral name from which to pullItems from
--- @param count itemCount amount of items needed to move
--- @return success, moved
function item:pullItem(from, count)
	-- locating all item occurences in a chest
	local slots = self:locateSlots(from)

	-- wrapping a chest
	local chest = peripheral.wrap(from)
	if not chest then
		error("[ITEM OPERATION] peripheral with a name: " .. from .. " does not exist")
	end

	-- First I need to use up as much of partially filled as possible
	print("[DEBUG] checking if the count was mutated: " .. count)
	local moved = self:relocateItems(from, slots, count, self.partiallyFilledSlots)
	print("[DEBUG] checking if the count was mutated: " .. count)
	-- What's left after filling partially filled slots goes into free slots
	local left = count - moved
	moved = moved + self:relocateItems(from, slots, left, self.freeSlots)

	print("[DEBUG] relocation operation expected to move " .. count .. " moved: " .. moved)
	return moved == count, moved
end

return item
