---@type item
local storedItem = require("storedItem")
---@type Queue
local Queue = dofile("factory/utils/Queue.lua")
---@type table<itemName, recipe>
local recipes = dofile("factory/shared/recipes.lua")
---@type EventEmitter
local eventEmitter = dofile("factory/shared/EventEmitter.lua")

local deepCopy = dofile("factory/utils/deepCopy.lua")

local slotMax = 64
---
---@alias itemName string
---@alias itemCount number
---
---@class storageManager
---@field eventEmitter EventEmitter
---@field items table<itemName, item>
---@field freeSlots Queue
---@field totalCapacity number
---@field currentCapacity number
---@field updating boolean
---@field updateLock boolean
---
local storageManager = {}
storageManager.__index = storageManager
setmetatable(storageManager, {__index = })

---Creates a Storage Manager
---@return storageManager
function storageManager.new()
	local self = setmetatable({}, storageManager)
	self.items = {}
	self.freeSlots = Queue.new()
	self.totalCapacity = 0
	self.currentCapacity = 0
	self.updating = false
	self.updateLock = false
	return self
end

-- Notes:
-- 1) Look into update locks, probably enough to have one variable
-- 2) Wiping on update fully is not a good idea, just leaving total as 0 is a better option
-- -- 1) No need for separate cashing table, all is initialized within an itemStored class
-- -- 2) Easier to compare changes in the inventory (just comparing two table snapshots of items)

---@return { total: number, current: number}
function storageManager:snapshotCapacity()
	return deepCopy({
		total = self.totalCapacity,
		current = self.currentCapacity,
	})
end

function storageManager:fullReset()
	for _, item in pairs(self.items) do
		item:reset()
	end
	self.freeSlots:reset()
	self.totalCapacity = 0
	self.currentCapacity = 0
end

---Scans peripherals for chests
---@return string[]
function storageManager:searchForChests()
	local peripherals = peripheral.getNames()
	local chests = {}

	for _, periph in ipairs(peripherals) do
		-- TODO: Probably a good idea to extract name to a config
		if string.match(periph, "^minecraft:chest") then
			table.insert(chests, periph)
		end
	end
	return chests
end

---@param chestName string
function storageManager:scanChest(chestName)
	local chest = peripheral.wrap(chestName)

	if chest == nil then
		return
	end

	local numSlots = chest.size()
	local chestSpace = numSlots * slotMax
	self.totalCapacity = self.totalCapacity + chestSpace

	local filledSlots = chest.list()
	for i, item in pairs(filledSlots) do
		local itemName = item.name
		local itemCount = item.count

		if not self.items[itemName] then
			local displayName = chest.getItemDetail(i).displayName
			local itemLimit = chest.getItemLimit(i)
			self.items[itemName] = storedItem.new(itemName, displayName, itemLimit, slotMax / itemLimit)
		end

		self.items[itemName]:addSlot(chestName, i, itemCount)
		chestSpace = chestSpace - itemCount
	end
	self.currentCapacity = self.currentCapacity + chestSpace
end

function storageManager:scan()
	local chests = self:searchForChests()

	for _, chestName in ipairs(chests) do
		self:scanChest(chestName)
	end
end

---Creates a snapshot of all item's totals for comparison
---@return table<itemName, itemCount>
function storageManager:snapshotTotals()
	local totals = {}
	for name, item in pairs(self.items) do
		totals[name] = item.total
	end
	return deepCopy(totals)
end

---Compares old and new total values of items
---@param oldTotals table<itemName, itemCount>
---@param newTotals table<itemName, itemCount>
---@return boolean
function storageManager:totalsDiffer(oldTotals, newTotals)
	-- Note: since there could be different amount of items in the system on comparison
	-- need to compare to newTotals, since they hold all the old items with total of 0 and new ones with their count
	for itemName, itemCount in pairs(newTotals) do
		local oldCount = oldTotals[itemName] or 0
		if itemCount ~= oldCount then
			return true
		end
	end
	return false
end

function storageManager:signalChange()
	self.eventEmitter:emit("inventory_changed", self.items)
end

--- Checks for changes in storage and updates it
--- if changed would trigger an event
function storageManager:update()
	local oldTotals = self:snapshotTotals()
	local oldCapacitry = self:snapshotCapacity()

	-- Locking storageManager from any item movements until the update is finished
	self.updating = true
	self:fullReset()
	self:scan()
	self.updating = false

	local newTotals = self:snapshotTotals()
	local newCapacity = self:snapshotCapacity()

	if self:totalsDiffer(oldTotals, newTotals) or oldCapacitry ~= newCapacity then
		self:signalChange()
	end
end

---@param order crafting_order
---@param to string
function storageManager:insertOrderDependencies(order, to)
	while self.updating do
		sleep(0.05)
	end

	self.updateLock = true
	local itemsMoved = {}
	local recipe = recipes[order.requestedItemName]
	for dep, ratio in pairs(recipe.dependencies) do
		local itemObject = self.items[dep]
		local success, moved = itemObject:pushItem(to, order.requestedItemCount * ratio)

		-- we save how much we moved, so if one of the inserts fail, we can rollback
		if moved > 0 then
			itemsMoved[dep] = moved
		end

		-- rollback of what we've moved so far, if one of the inserts failed
		if not success then
			self:withdraw(to, itemsMoved)
			-- there's really no point in adding retry here, if it failed, then we have wrong representation of self.items
			-- meaning we need to update first, to update we need to first set updateLock to false
			return false
		end
	end
	self.updateLock = false
	return true
end

---@param from string
---@param items table<itemName, itemCount>
function storageManager:withdraw(from, items)
	while self.updating do
		sleep(0.05)
	end
	self.updateLock = true
	for item, crafted in pairs(items) do
		local success = self:pullItem(from, item, crafted)
		if not success then
			error("Failed to withdraw item: " .. item .. " something is very wrong, look into the flow of items")
		end
	end
	self.updateLock = false
end

return storageManager
