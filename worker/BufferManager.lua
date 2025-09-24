BufferManager.__index = BufferManager
function BufferManager.new(bufferName)
	local self = setmetatable({}, BufferManager)
	self.buffer = bufferName
	self.totalCapacity = 0
	self.capacity = 0
	self:init()
	return self
end

function BufferManager:init()
	local space = peripheral.call(self.buffer, "size")
	self.totalCapacity = space * 64
end

function BufferManager:getTotalCapacity()
	return self.totalCapacity
end

function BufferManager:getCurrentCapacity()
	return self.totalCapacity
end

function BufferManager:updateCapacity()
	local inventory = peripheral.call(self.buffer, "items")
end

function BufferManager:isPresent()
	if peripheral.isPresent(self.buffer) then
		return true
	end
	return false
end

function BufferManager:locateSlots(item)
	local slots = {}
	local inventory = peripheral.call(self.buffer, "items")

	for index, slot in pairs(inventory) do
		if slot.name == item then
			slot.index = index
			table.insert(slots, slot)
		end
	end
	return slots
end

function BufferManager:pushItem(to, item, count)
	local initialCount = count
	local totalMoved = 0
	-- where system thinks item is located
	local slots = self:locateSlots(item)
	while count > 0 do
		local slot = slots[#slots] -- peek right most slot
		if not slot then
			return false, totalMoved -- if there's no slots anymore
		end

		-- insert either min of item in slot or if slot has more then we need, we insert count
		local insertAmount = math.min(count, slot.count)
		local moved = peripheral.call(self.buffer, "pushItems", to, slot.index, insertAmount)
		if moved == 0 then
			return false, totalMoved
		end

		-- aftermath
		totalMoved = totalMoved + moved
		count = count - moved
		slot.count = slot.count - moved

		-- stack pop if slot is drained
		if slot.count == 0 then
			table.remove(slots)
		end
	end
	return initialCount == totalMoved, totalMoved
end

function BufferManager:flushStation(station)
	local inventory = peripheral.call(self.buffer, "items")
	for index, slot in pairs(inventory) do
		peripheral.call(self.buffer, "pullItems", station, index)
	end
end

function BufferManager:insertDependencies(item, recipe, count, station)
	for dep, ratio in pairs(recipe.dependencies) do
		local amount = count * ratio
		local success = self:pushItem(station, dep, amount)
		if not success then
			-- rollback
		end
	end
end

return BufferManager
