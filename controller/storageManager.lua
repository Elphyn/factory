local deepCopy = dofile("factory/utils/deepCopy.lua")
local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.new()
	local self = setmetatable({}, StorageManager)
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

function StorageManager:subscribe(callback, event)
	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end
	table.insert(self.callbacks[event], callback)
end

function StorageManager:emit(event)
	if not self.callbacks[event] then
		return
	end
	for _, callback in ipairs(self.callbacks[event]) do
		callback()
	end
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
		self:emit("inventory_changed")
		return
	end

	for item, info in pairs(self.items) do
		local old = oldTotals[item] or 0
		local new = info.total
		if new == 0 then
			info = nil
		end

		if old ~= new then
			self:emit("inventory_changed")
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
		table.insert(self.items[itemName].slots, { name, idx, itemInfo.count })
	end
end

function StorageManager:push(to, item, count) end

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

--
--
--
-- function StorageManager:pull() end
