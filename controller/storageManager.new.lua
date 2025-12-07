---@type item
local storedItem = require("storedItem")
---@type itemDetailStore
local itemDetailsStore = require("controller.itemDetails")
---@type Queue
local Queue = dofile("factory/utils/Queue.lua")

local deepCopy = dofile("factory/utils/deepCopy.lua")

local slotMax = 64
---
---@alias itemName string
---
---@class storageManager
---@field eventEmitter EventEmitter
---@field items table<itemName, item>
---@field itemDetails itemDetailStore
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
	self.itemDetails = itemDetailsStore.new()
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

---@class chestInfo
---@field items item[]
---@field currentCapacity number
---@field totalCapacity number
---@field freeSlots Queue

---@param chestName string
---@return boolean, chestInfo?
function storageManager:scanChest(chestName)
	local chest = peripheral.wrap(chestName)

	if chest == nil then
		return false
	end

	---@type chestInfo
	local chestInfo = {}

	local numSlots = chest.size()
	local chestSpace = numSlots * slotMax
	chestInfo.currentCapacity = chestSpace
	chestInfo.totalCapacity = chestSpace

	local filledSlots = chest.list()
	for i, item in pairs(filledSlots) do
		local itemName = item.name

		if not self.itemDetails:isSaved(itemName) then
			local displayName = chest.getItemDetail(i).displayName
			local itemLimit = chest.getItemLimit(i)

			self.itemDetails:saveDetails(itemName, displayName, itemLimit, slotMax / itemLimit)
		end

		-- Continue here
	end

	return true, chestInfo
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
