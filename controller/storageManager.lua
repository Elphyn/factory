local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.new()
	local self = setmetatable({}, StorageManager)
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

function StorageManager:scan()
	self.items = {}
	self.freeChests = {}
	local chests = StorageManager:_getStorageUnits()
	for _, name in ipairs(chests) do
		-- disconnecting a chest while this is running would throw an error, needs to be protected
		local ok = pcall(function()
			self:_scanChest(name)
		end)
		if not ok then
			print("Failed to scan a chest: ", name)
		end
	end
	return self.items
end

function StorageManager:_scanChest(name)
	local chest = peripheral.wrap(name)
	local items = chest.list()
	if #items == 0 then
		table.insert(self.freeChests, name)
		goto continue
	end
	local chestSlots = chest.size()
	for idx, itemInfo in pairs(items) do
		local itemName = itemInfo.name
		if self.cachedInfo[itemInfo.name] == nil then
			-- it's possible that item could get in and out of the system, caching important values makes system work much faster
			-- besides, this function resets self.items, meaning it's gonna be doing a lot of extra work I would rather it not do
			local moreInfo = chest.getItemDetail(idx)
			self.cachedInfo[itemInfo.name] = {
				displayName = moreInfo.displayName,
				itemLimit = chest.getItemLimit(idx),
			}
		end
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
	::continue::
end

function StorageManager:_exist(item)
	if self.items[item] ~= nil then
		return true
	end
	return false
end

function StorageManager:getTotal(item)
	if not self:_exist(item) then
		return 0
	end
	return self.items[item].total
end

return StorageManager

--
--
--
-- function StorageManager:pull() end
