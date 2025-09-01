local deepCopy = dofile("factory/utils/deepCopy.lua")
local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.new(eventEmitter)
	local self = setmetatable({}, StorageManager)
	self.eventEmitter = eventEmitter
	self.items = {}
	self.freeChests = {}
	self.cachedInfo = {}
	return self
end

function StorageManager:_getStorageUnits()
	local list = peripheral.getNames()
	local storageUnits = {}

	for _, connectedPeripheral in ipairs(list) do
		if string.match(connectedPeripheral, "^minecraft:chest") then
			table.insert(storageUnits, connectedPeripheral)
		end
	end
	return storageUnits
end

function StorageManager:getAllTotals()
	local totals = {}
	for item, info in pairs(self.items) do
		totals[item] = info.total
	end
	return totals
end

function StorageManager:reset()
	self.items = {}
end

function StorageManager:countItems()
	-- returns how many items there are in the system
	local count = 0
	for _ in pairs(self.items) do
		count = count + 1
	end
	return count
end

function StorageManager:update()
	-- snapshot of old values, so we can compare if there are any changes(relevant changes)
	local oldValuesOfItems = self:getAllTotals()
	local oldNumberOfItems = self:countItems()
	local changed = false

	self:reset()
	-- updating storage
	self:scan()

	-- now we compare
	for item, info in pairs(self.items) do
		local old = oldValuesOfItems[item] or 0
		local new = info.total

		if old ~= new then
			changed = true
			break
		end
	end

	if not changed then
		local newNumberOfItems = self:countItems()
		changed = oldNumberOfItems ~= newNumberOfItems
	end

	-- if there are any changes emit event
	if changed then
		self:signalChange()
	end
end

function StorageManager:signalChange()
	self.eventEmitter:emit("inventory_changed", self:getItems())
end

function StorageManager:scan()
	self.freeChests = {}
	local chests = StorageManager:_getStorageUnits()
	for _, name in ipairs(chests) do
		self:_scanChest(name)
	end
end

function StorageManager:scanChest(chestName)
	local chest = peripheral.wrap(chestName)
	local items = chest.list()
end

function StorageManager:_scanChest(name)
	local chest = peripheral.wrap(name)
	local items = chest.list()

	if #items == 0 then
		table.insert(self.freeChests, name)
		return
	end

	local chestSlots = chest.size()
	for idx, itemInfo in pairs(items) do
		local itemName = itemInfo.name

		-- caching
		if self.cachedInfo[itemName] == nil then
			-- it's possible that item could get in and out of the system, caching important values makes system work much faster
			self.cachedInfo[itemName] = {
				-- this one is really slow, the whole reason I added caching
				displayName = chest.getItemDetail(idx).displayName,
				itemLimit = chest.getItemLimit(idx),
			}
		end

		-- init
		if self.items[itemName] == nil then
			self.items[itemName] = {
				name = itemName,
				displayName = self.cachedInfo[itemName].displayName,
				total = 0,
				slots = {},
				capacity = chestSlots * self.cachedInfo[itemName].itemLimit,
				assigned = 0,
			}
		end

		self.items[itemName].total = self.items[itemName].total + itemInfo.count
		table.insert(self.items[itemName].slots, { name = name, slot_idx = idx, count = itemInfo.count })
	end
end

function StorageManager:pushItem(to, item, count)
	local total = self:getTotal(item)

	if total == 0 or count > total then
		error("Storage doesn't have/not enough of this item: ", item)
	end

	local slots = self.items[item].slots
	for _, slot in ipairs(slots) do
		local chest = peripheral.wrap(slot.name)

		local take = 0
		if count >= slot.count then
			take = slot.count
		else
			take = count
		end
		chest.pushItems(to, slot.slot_idx, take)
		count = count - take
		if count == 0 then
			break
		end
	end
end

function StorageManager:_exist(item)
	if self.items[item] ~= nil then
		return true
	end
	return false
end

function StorageManager:getItems()
	return self.items
end

function StorageManager:getTotal(item)
	if not self:_exist(item) then
		return 0
	end
	return self.items[item].total
end

function StorageManager:getSnapshot()
	local snapshot = deepCopy(self.items)
	return snapshot
end

return StorageManager
