local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.new()
	local self = setmetatable({}, StorageManager)
	self.items = {}
	self.freeChests = {}
	self.cashedInfo = {}
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
	-- self.items = {}
	-- self.freeChests = {}
	for _, name in ipairs(chests) do
		local chest = peripheral.wrap(name)
		local items = chest.list()
		if #items == 0 then
			table.insert(self.freeChests, name)
			goto continue
		end
		local chestSlots = chest.size()
		for idx, itemInfo in pairs(items) do
			local itemName = itemInfo.name
			if self.cashedInfo[itemInfo.name] == nil then
				local moreInfo = chest.getItemDetail(idx)
				self.cashedInfo[itemInfo.name] = {
					displayName = moreInfo.displayName,
					itemLimit = chest.getItemLimit(idx),
				}
			end
			if self.items[itemName] == nil then
				self.items[itemName] = {
					name = itemName,
					displayName = self.cashedInfo[itemInfo.name].displayName,
					total = 0,
					slots = {},
					capacity = chestSlots * self.cashedInfo[itemInfo.name].itemLimit,
				}
			end
			self.items[itemName].total = self.items[itemName].total + itemInfo.count
			table.insert(self.items[itemName].slots, { name, idx, itemInfo.count })
		end
		::continue::
	end
	return self.items
end

return StorageManager

-- function StorageManager:exist() end
--
-- function StorageManager:getCount() end
--
-- function StorageManager:push() end
--
-- function StorageManager:pull() end
