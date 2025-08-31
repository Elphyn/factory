local deepCopy = dofile("factory/utils/deepCopy.lua")
local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.new(eventEmitter)
	local self = setmetatable({}, StorageManager)
	self.eventEmitter = eventEmitter
	self.items = {}
	self.freeChests = {}
	self.cachedInfo = {}
	self.callbacks = {}
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

function StorageManager:scan()
	self.freeChests = {}
	local chests = StorageManager:_getStorageUnits()

	local oldTotals = {}
	for item, info in pairs(self.items) do
		oldTotals[item] = info.total
		info.total = 0
		info.slots = {}
	end

	for _, name in ipairs(chests) do
		self:_scanChest(name)
	end

	local oldCount = 0
	for _ in pairs(oldTotals) do
		oldCount = oldCount + 1
	end

	local newCount = 0
	for _ in pairs(self.items) do
		newCount = newCount + 1
	end

	if oldCount ~= newCount then
		self.eventEmitter.emit("inventory_changed", self:getItems())
		return
	end

	for item, info in pairs(self.items) do
		local old = oldTotals[item] or 0
		local new = info.total

		if old ~= new then
			self.eventEmitter.emit("inventory_changed", self:getItems())
			return
		end
	end
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
		if self.cachedInfo[itemInfo.name] == nil then
			-- it's possible that item could get in and out of the system, caching important values makes system work much faster
			self.cachedInfo[itemInfo.name] = {
				-- this one is really slow, the whole reason I added caching
				displayName = chest.getItemDetail(idx).displayName,
				itemLimit = chest.getItemLimit(idx),
			}
		end

		-- init
		if self.items[itemName] == nil then
			self.items[itemName] = {
				name = itemName,
				displayName = self.cachedInfo[itemInfo.name].displayName,
				total = 0,
				slots = {},
				capacity = chestSlots * self.cachedInfo[itemInfo.name].itemLimit,
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
