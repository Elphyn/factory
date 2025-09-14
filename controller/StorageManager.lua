local deepCopy = dofile("factory/utils/deepCopy.lua")
local log = dofile("factory/utils/logging.lua")
local deepEqual = dofile("factory/utils/deepEqual.lua")
local recipes = dofile("factory/shared/recipes.lua")
local empty = dofile("factory/utils/isEmpty.lua")
local Queue = dofile("factory/shared/Queue.lua")
local StorageManager = {}

StorageManager.__index = StorageManager
function StorageManager.new(eventEmitter)
	local self = setmetatable({}, StorageManager)
	self.eventEmitter = eventEmitter
	self.items = {}
	self.freeSlots = Queue.new()
	self.cachedDetails = {}
	self.capacity = 0
	self.updateLock = false
	self:update()
	self:setupEventListeners()
	return self
end

function StorageManager:setupEventListeners()
	if self.eventEmitter then
		self.eventEmitter:subscribe("order-finished", function(info)
			self:withdraw(info.buffer, info.yield)
		end)
	end
end

function StorageManager:itemDetailsCached(item)
	if self.cachedDetails[item] ~= nil then
		return true
	end
	return false
end

function StorageManager:cacheItemDetails(chestName, slotIDX, item)
	-- you need to know where item is stored to request details
	local chest = peripheral.wrap(chestName)

	self.cachedDetails[item] = {
		-- this one might slow system down quite a bit if not cached
		displayName = chest.getItemDetail(slotIDX).displayName,
		itemLimit = chest.getItemLimit(slotIDX),
	}
end

function StorageManager:saveItemDetails(item, slotIndex, chestName)
	if self.items[item.name] == nil then
		self.items[item.name] = {
			name = item.name,
			displayName = self.cachedDetails[item.name].displayName,
			total = 0,
			slots = {}, -- for pulling out
			partiallyFilledSlots = Queue.new(), -- for pushing in
		}
	end
	local slotDetails = {
		chest = chestName,
		index = slotIndex,
		count = item.count,
	}
	self.items[item.name].total = self.items[item.name].total + item.count

	-- if slot isn't full, meaning it's 64 or 16 for pearls, we can push it into this slot
	if slotDetails.count < self.cachedDetails[item.name].itemLimit then
		self.items[item.name].partiallyFilledSlots:push(slotDetails)
	end
	table.insert(self.items[item.name].slots, slotDetails)
end

function StorageManager:scanChest(chestName)
	local chest = peripheral.wrap(chestName)

	local filledSlots = chest.list()
	local numSlots = chest.size()
	local chestSpace = numSlots * 64

	-- updaing how many items storage can hold
	self.capacity = self.capacity + chestSpace

	-- filling in item details, generating free slots table
	for i, item in pairs(filledSlots) do
		local name = item.name

		-- caching details about an item, so it happens only once per new item
		if not self:itemDetailsCached(name) then
			self:cacheItemDetails(chestName, i, name)
		end

		-- saving where item is being held, it's count, updaing total count
		self:saveItemDetails(item, i, chestName)
	end
	-- saving free slots in qeuue, so when we need to insert something, we insert at the first empty, not last
	for i = 1, numSlots do
		if not filledSlots[i] then
			local slot = {
				chest = chestName,
				index = i,
				count = 0,
			}
			self.freeSlots:push(slot)
		end
	end
end

function StorageManager:searchForChests()
	local peripherals = peripheral.getNames()
	local chests = {}

	for _, periph in ipairs(peripherals) do
		if string.match(periph, "^minecraft:chest") then
			table.insert(chests, periph)
		end
	end
	return chests
end

function StorageManager:scan()
	local chests = self:searchForChests()

	for _, chestName in ipairs(chests) do
		self:scanChest(chestName)
	end
end

function StorageManager:reset()
	self.items = {}
	self.freeSlots:reset()
	self.capacity = 0
end

function StorageManager:inventoryChange()
	self.eventEmitter:emit("inventory_changed", self.items)
end

function StorageManager:capacityChange()
	self.eventEmitter:emit("capacity_changed", self.capacity)
end

function StorageManager:getSnapshot()
	local snapshot = {
		items = deepCopy(self.items),
		freeSlots = deepCopy(self.freeSlots), -- no point in making that a queue here
	}

	return snapshot
end

function StorageManager:update()
	log("Update started: ")
	-- is for comparison
	local oldTotals = self:getTotals()
	-- local oldFreeSlots = snapshot.freeSlots -- can't do for now, since it's a metatable

	self:reset()
	self:scan()
	log("Old totals: ")
	log(textutils.serialize(oldTotals))
	local newTotals = self:getTotals()
	log("New totals")
	log(textutils.serialize(newTotals))

	local changed = false

	for k, v in pairs(oldTotals) do
		if newTotals[k] ~= v then
			print("comparison failed")
			local old = newTotals[k] or 0
			local new = v or 0
			print("item: ", k)
			print(old .. " ~= " .. new)
			changed = true
			break
		end
	end

	for k, v in pairs(newTotals) do
		if oldTotals[k] ~= v then
			print("comparison failed")
			local old = oldTotals[k] or 0
			local new = v or 0
			print("item: ", k)
			print(old .. " ~= " .. new)
			changed = true
			break
		end
	end

	if changed then
		self:inventoryChange()
	end
end

function StorageManager:getTotals()
	local res = {}
	for item, details in pairs(self.items) do
		res[item] = details.total
	end
	return res
end

function StorageManager:getTotal(item)
	local total = 0
	if self.items[item] ~= nil then
		total = self.items[item].total
	end
	return total
end

function StorageManager:pushItem(to, item, count)
	log("Asked this resource: " .. item .. " " .. count)
	local total = self:getTotal(item)
	-- theoretically we shouldn't get this error if shceduler did calculations right
	-- and we have an accurate representation of item storage
	if total == 0 or count > total then
		error("Storage doesn't have/not enough of item")
	end

	local slots = self.items[item].slots
	for i = #slots, 1, -1 do
		local slot = slots[i]
		local take = 0
		if count >= slot.count then
			take = slot.count
		else
			take = count
		end
		peripheral.call(slot.chest, "pushItems", to, slot.index, take)
		count = count - take
		if count == 0 then
			break
		end
	end
end

function StorageManager:insertOrderDependencies(order, to)
	self.updateLock = true
	local recipe = recipes[order.name]
	for name, ratio in pairs(recipe.dependencies) do
		self:pushItem(to, name, order.count * ratio)
	end
	self.updateLock = false
end

function StorageManager:locateSlots(searchItem, chest)
	local items = peripheral.call(chest, "list")
	local slots = {}
	for i, slot in pairs(items) do
		if slot.name == searchItem then
			local slotInfo = {
				name = slot.name,
				count = slot.count,
				index = i,
			}
			table.insert(slots, slotInfo)
		end
	end
	return slots
end

function StorageManager:getItemLimit(item, chest, slot)
	local cached = self.cachedDetails[item] and self.cachedDetails[item].itemLimit
	if cached ~= nil then
		return cached
	end
	-- need to add if it's not cached
	return peripheral.call(chest, "getItemLimit", slot)
end

function StorageManager:fill(from, slots, item, count, outputSlots)
	local insertSlots = outputSlots or self.freeSlots
	local slot = table.remove(slots)
	-- we run this until we either exhaust count
	-- or until we exhaust slots
	while count > 0 do
		local insertSlot = insertSlots:peek()
		local itemLimit = self:getItemLimit(item, insertSlot.chest, insertSlot.index)
		local maxInsertAmount = itemLimit - insertSlot.count
		local insertAmount = math.min(slot.count, maxInsertAmount)

		-- inserting
		peripheral.call(insertSlot.chest, "pullItems", from, slot.index, insertAmount, insertSlot.index)

		-- aftermath
		count = count - insertAmount
		slot.count = slot.count - insertAmount
		insertSlot.count = insertSlot.count + insertAmount

		-- if slot we were inserting in is now full, we remove it from slots
		if insertSlot.count == itemLimit then
			insertSlots:pop()
		end

		-- if we exhausted slot, we move on to the next one
		if slot.count == 0 then
			if #slots > 0 then
				slot = table.remove(slots)
			else
				break -- if all slots were exhausted
			end
		end
	end
	return count -- leftover
end

function StorageManager:pullItem(from, item, count)
	-- get all slots in which item is located
	local slots = self:locateSlots(item, from)

	-- first fill partially filled slots, if there's any
	local left = count
	if self.items[item] then
		local partiallyFilled = self.items[item].partiallyFilledSlots
		left = self:fill(from, slots, item, left, partiallyFilled)
		print("Items left after fill: ", left)
	end

	--
	-- what's left is filled into impty slots
	left = self:fill(from, slots, item, left)

	-- throwing an error, because we should check if we can insert, before inserting
	-- so if leftover more then 0, means logic higher was wrong
	if left > 0 then
		print("Left: ", left)
		error("Coudln't insert item fully")
	end
end

function StorageManager:withdraw(buffer, yield)
	-- withdrawing each item we crafted from order from buffer
	self.updateLock = true
	for item, crafted in pairs(yield) do
		self:pullItem(buffer, item, crafted)
	end
	self.updateLock = false
end

return StorageManager
