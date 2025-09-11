local deepCopy = dofile("factory/utils/deepCopy.lua")
local recipes = dofile("factory/shared/recipes.lua")
local empty = dofile("factory/utils/isEmpty.lua")
local StorageManager = {}

-- TODO:
-- 1) If item.craftingLimit is > 256 then we assign a whole chest to them
-- 2) If it's <= 256 it's a misc chest from there on

StorageManager.__index = StorageManager

function StorageManager.new(eventEmitter)
	local self = setmetatable({}, StorageManager)
	self.eventEmitter = eventEmitter
	self.items = {}
	self.freeChests = {}
	self.assignedChests = {}
	self.cachedInfo = {}
	self:setupEventListeners()
	return self
end

function StorageManager:setupEventListeners()
	if self.eventEmitter then
		self.eventEmitter:subscribe("order-finished", function(info)
			print("Triggering withdrawing")
			self:withdraw(info.buffer, info.yeild)
		end)
	end
end

function StorageManager:insertOrderDependencies(order, to)
	local recipe = recipes[order.name]
	for name, ratio in pairs(recipe.dependencies) do
		self:pushItem(to, name, order.count * ratio)
	end
end

function StorageManager:withdraw(buffer, yeild)
	-- withdrawing each item we crafted from order from buffer
	for item, crafted in pairs(yeild) do
		print("Withdrawing item: ", item)
		print("pull: " .. buffer .. "|" .. item .. "|" .. crafted)
		self:pullItem(buffer, item, crafted)
	end
end

function StorageManager:_getStorageUnits()
	local list = peripheral.getNames()
	local storageUnits = {}

	-- we're looking for a all peripheral that start with minecraft:chest
	-- subject to change
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

function StorageManager:scan()
	self.freeChests = {}

	local chests = StorageManager:_getStorageUnits()
	for _, name in ipairs(chests) do
		self:_scanChest(name)
	end
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
	if self.eventEmitter then
		self.eventEmitter:emit("inventory_changed", self:getItems())
	end
end

function StorageManager:_scanChest(name)
	local chest = peripheral.wrap(name)
	local items = chest.list()

	if empty(items) then
		table.insert(self.freeChests, name)
		return
	end

	local chestSlots = chest.size()
	local chestSpace = chestSlots * 64
	for idx, itemInfo in pairs(items) do
		local itemName = itemInfo.name
		if not self.assignedChests[itemName] then
			self.assignedChests[itemName] = { name = name }
			self.assignedChests[itemName].space = chestSpace
		end
		self.assignedChests[itemName].space = self.assignedChests[itemName].space - itemInfo.count

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

function StorageManager:locateSlots(searchItem, chest)
	local items = peripheral.call(chest, "list")
	local slots = {}
	for idx, slot in pairs(items) do
		if slot.name == searchItem then
			slots[idx] = slot
		end
	end
	return slots
end

function StorageManager:pullItem(from, item, count)
	-- find all occ of item in "from" peripheral
	local slots = self:locateSlots(item, from)
	print("Located item in slots: ")
	print(textutils.serialize(slots))

	-- go through each slot, inserting
	for idx, slotInfo in pairs(slots) do
		print("Pulling item from slot: " .. idx)
		if count > 0 then
			local slotAmount = slotInfo.count

			-- for now just insert into assigned chest or take a new one
			local chest = nil
			if self.assignedChests[item] then
				chest = self.assignedChests[item]
			else
				local freeChest = self:getFreeChest()
				chest = {
					name = freeChest,
					space = peripheral.call(freeChest, "size") * 64,
				}
				self.assignedChests[item] = chest
			end
			if chest then
				local insertAmount = math.min(count, slotAmount, chest.space)
				count = count - insertAmount
				peripheral.call(chest.name, "pullItems", from, idx, insertAmount)
				return true
			end
			return false
		end
	end
end

function StorageManager:getFreeChest()
	if #self.freeChests == 0 then
		error("Trying to get a free chest, there's none")
	end
	return table.remove(self.freeChests)
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
