local recipes = dofile("factory/shared/recipes.lua")
local empty = dofile("factory/utils/isEmpty.lua")
local Display = {}

Display.__index = Display

function Display.new(eventEmitter)
	local self = setmetatable({}, Display)
	self.eventEmitter = eventEmitter
	return self
end

function Display:setupEventListeners()
	self.eventEmitter:subscribe("inventory_changed", function(storage)
		self:renderStorage(storage)
	end)
	-- self.eventEmitter:subscribe("queue_changed", function(queue)
	-- 	self:renderQueue(queue)
	-- end)
end

function Display:_findMonitor()
	local list = peripheral.getNames()

	for _, name in ipairs(list) do
		if string.match(name, "^monitor") then
			return name
		end
	end
	return nil
end

function Display:render()
	local itemTable = self.storageManager:getItems()
	local queue = self.scheduler:getQueue()
	if itemTable == nil then
		print("No items in storage")
		return
	end
	local monitorName = self:_findMonitor()
	if monitorName == nil then
		print("No monitor found")
		return
	end
	local monitor = peripheral.wrap(monitorName)
	monitor.clear()
	local line = 1
	for name, info in pairs(itemTable) do
		if info.total > 0 then
			monitor.setCursorPos(1, line)
			local itemInfoString = string.format("%d/%d | %s", info.total, info.capacity, info.displayName)
			monitor.write(itemInfoString)
			line = line + 1
		end
	end
	-- name = {order = name, count = how much we crafting}
	line = line + 1
	monitor.setCursorPos(1, line)
	if not empty(queue) then
		monitor.write("Queue: ")
	end
	line = line + 1
	for _, order in pairs(queue) do
		local name = recipes[order.name].displayName
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | Can craft: %d", name, order.count)
		monitor.write(itemInfoString)
		line = line + 1
	end
end

function Display:renderStorage(storage)
	local itemTable = storage
	if itemTable == nil then
		print("No items in storage")
		return
	end
	local monitorName = self:_findMonitor()
	if monitorName == nil then
		print("No monitor found")
		return
	end
	local monitor = peripheral.wrap(monitorName)
	monitor.clear()
	local line = 1
	for name, info in pairs(itemTable) do
		if info.total > 0 then
			monitor.setCursorPos(1, line)
			local itemInfoString = string.format("%d/%d | %s", info.total, info.capacity, info.displayName)
			monitor.write(itemInfoString)
			line = line + 1
		end
	end
end

function Display:renderQueue(queue)
	local monitorName = self:_findMonitor()
	if monitorName == nil then
		print("No monitor found")
		return
	end
	local monitor = peripheral.wrap(monitorName)
	local line = 5
	monitor.setCursorPos(1, line)
	if not empty(queue) then
		monitor.write("Queue: ")
	end
	line = line + 1
	for _, order in pairs(queue) do
		local name = recipes[order.name].displayName
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | Can craft: %d", name, order.count)
		monitor.write(itemInfoString)
		line = line + 1
	end
end

return Display
