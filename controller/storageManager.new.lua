local storedItem = require("storedItem")
local deepCopy = dofile("factory/utils/deepCopy.lua")
---@type Queue
local Queue = dofile("factory/utils/Queue.lua")
---
---@class storageManager
---@field eventEmitter EventEmitter
---@field items table<string, storedItem>
---@field freeSlots Queue
---@field totalCapacity number
---@field currentCapacity number
---@field updating boolean
---
local storageManager = {}
storageManager.__index = storageManager

---Creates a Storage Manager
---@param eventEmitter EventEmitter
---@return storageManager
function storageManager.new(eventEmitter)
	local self = setmetatable({}, storageManager)
	self.eventEmitter = eventEmitter
	self.items = {}
	self.freeSlots = Queue.new()
	self.totalCapacity = 0
	self.currentCapacity = 0
	self.updating = false
	return self
end

-- Notes:
-- 1) Look into update locks, probably enough to have one variable
-- 2) Wiping on update fully is not a good idea, just leaving total as 0 is a better option
-- -- 1) No need for separate cashing table, all is initialized within an itemStored class
-- -- 2) Easier to compare changes in the inventory (just comparing two table snapshots of items)

---Creates a snapshot of all item's totals for comparison
---@return table<string, number>
function storageManager:snapshotTotals()
	local totals = {}
	for name, item in pairs(self.items) do
		totals[name] = item:getTotal()
	end
	return deepCopy(totals)
end

---@return { total: number, current: number}
function storageManager:snapshotCapacity()
	return deepCopy({
		total = self.totalCapacity,
		current = self.currentCapacity,
	})
end

---Initialize item for the first time
---@param name string
---@param displayName string
function storageManager:initializeItem(name, displayName)
	self.items[name] = storedItem.new(name, displayName)
end

function storageManager:resetItemCounts()
	for _, item in pairs(self.items) do
		item:reset()
	end
end

function storageManager:fullReset()
	self:resetItemCounts()
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

---@class collectedInfo
---@field

---@param chestName string
---@return boolean,
function storageManager:scanChest(chestName)
	local chest = peripheral.wrap(chestName)
end

function storageManager:scan()
	local chests = self:searchForChests()

	for _, chestName in ipairs(chests) do
	end
end

--- Checks for changes in storage and updates it
--- if changed would trigger an event
function storageManager:update()
	local oldTotals = self:snapshotTotals()
	local oldCapacitry = self:snapshotCapacity()

	-- Locking storageManager from any item movements until the update is finished
	self.updating = true
	self:fullReset()
end

return storageManager
