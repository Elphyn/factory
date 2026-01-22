local Deque = require("libs.Deque")

local DEFAULT_SLOT_CAPACITY = 64

---@class chestAdapter
local Uniform = {}
Uniform.__index = Uniform

function Uniform.new(chestName, sharedCachedDetails)
	local self = setmetatable({}, Uniform)
	assert(peripheral.isPresent(chestName) == true, "StorageUnit with name: " .. chestName .. " does not exist")
	self.cachedDetails = sharedCachedDetails
	self.name = chestName
	self.items = {}
	self.filledSlots = {}
	self.partiallyFilledSlots = {}
	self.totalCapacity = 0
	self.currentCapacity = 0
	return self
end

function Uniform:gatherDetails(itemName, slotIndex)
	local p = peripheral.wrap(self.name)
	if not p then
		return "local peripheral unreachable"
	end
	local info = p.getItemDetail(slotIndex)
	if not info then
		error("Impossible condition: gatheringItem details got empty slotIndex")
	end
	self.cachedDetails[itemName] = {
		displayName = info.displayName,
		maxCount = info.maxCount,
		weight = 64 / info.maxCount,
	}
	return nil
end

function Uniform:resetInfo()
	self.items = {}
	self.filledSlots = {}
	self.partiallyFilledSlots = {}
	self.totalCapacity = 0
	self.currentCapacity = 0
end

function Uniform:update()
	local p = peripheral.wrap(self.name)
	if not p then
		return "local peripheral unreachable"
	end

	self:resetInfo()
	self.totalCapacity = p.size() * DEFAULT_SLOT_CAPACITY
	self.currentCapacity = self.totalCapacity

	local items = p.list()
	for slotIndex, itemInfo in pairs(items) do
		self.items[itemInfo.name] = (self.items[itemInfo.name] or 0) + itemInfo.count
		self.currentCapacity = self.currentCapacity - itemInfo.count

		if not self.cachedDetails[itemInfo.name] then
			self:gatherDetails(itemInfo.name, slotIndex)
		end

		-- slot handling here
		--- @class slot
		local slot = {
			chestIndex = slotIndex,
			itemCount = itemInfo.count,
		}

		if p.getItemLimit(slotIndex) > itemInfo.count then
			if not self.partiallyFilledSlots[itemInfo.name] then
				self.partiallyFilledSlots[itemInfo.name] = Deque.new()
			end
			self.partiallyFilledSlots[itemInfo.name]:push(slot)
		else
			if not self.filledSlots[itemInfo.name] then
				self.filledSlots[itemInfo.name] = {}
			end
			table.insert(self.filledSlots[itemInfo.name], slot)
		end
	end
	return nil
end

function Uniform:getItems()
	local err = self:update()
	if err then
		return {}, err
	end

	return self.items, nil
end

function Uniform:getSlot(itemName)
	if not self.partiallyFilledSlots[itemName]:empty() then
		return self.partiallyFilledSlots[itemName]:popRight()
	end
	return table.remove(self.filledSlots[itemName])
end

function Uniform:pushItem(to, itemName, itemCount)
	local p = peripheral.wrap(self.name)
	if not p then
		return 0, "local peripheral unreachable"
	end

	if not peripheral.isPresent(to) then
		return 0, "remote peripheral unreachable"
	end

	local err = self:update()
	if err then
		return 0, err
	end

	if self.items[itemName] < itemCount then
		-- core manager never should request more then the chest has
		-- if it failed at that, and we proceeded, that means we have a state desync issue
		return 0, "state desync"
	end

	local totalMoved = 0
	local left = itemCount
	while totalMoved < itemCount do
		if #self.filledSlots[itemName] == 0 and self.partiallyFilledSlots[itemName]:empty() then
			-- itemCount of item is satisfactory, but not having slots? Something is very wrong
			error("Impossible condition: no slots, but storedCount >= requestedCount, check ChestAdapterImplementation")
		end

		local slot = self:getSlot(itemName)
		local insertAmount = math.min(left, slot.itemCount)

		local moved = p.pushItems(to, slot.chestIndex, insertAmount)

		totalMoved = totalMoved + moved
		left = left - moved
		slot.itemCount = slot.itemCount - moved

		if slot.itemCount < 0 then
			error("Impossible condition: slot.itemCount dropped below 0, check ChestAdapterImplementation")
		end

		if self.cachedDetails[itemName].maxCount > slot.itemCount then
			-- TODO: possibly change peek and pop instead of pop and push if any left
			self.partiallyFilledSlots[itemName]:push(slot)
		else
			-- if we are here, then moved == 0, something is wrong probably
			-- but for now just make a log for it
			table.insert(self.filledSlots[itemName], slot)
			print("[LOG] A filled slot was popped and instered back\nMeanin that moved amount was 0")
		end
	end
	return totalMoved, nil
end

return Uniform
