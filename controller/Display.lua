local recipes = dofile("factory/shared/recipes.lua")
local empty = dofile("factory/utils/isEmpty.lua")
local Display = {}

Display.__index = Display

function Display.new(eventEmitter)
	local self = setmetatable({}, Display)
	self.eventEmitter = eventEmitter
	self.items = {}
	self.queue = {}
	self.totalCapacity = 0
	self.capacity = 0
	self:setupEventListeners()
	return self
end

function Display:setupEventListeners()
	self.eventEmitter:subscribe("inventory_changed", function(storage)
		self.items = storage
		self:render()
	end)
	self.eventEmitter:subscribe("queue_changed", function(queue)
		self.queue = queue
		self:render()
	end)
	self.eventEmitter:subscribe("capacity_changed", function(capacity)
		print("received new capacity in Display")
		self.totalCapacity = capacity.total
		self.capacity = capacity.current
		print(textutils.serialize(capacity))
		self:render()
	end)
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
	local itemTable = self.items
	local queue = self.queue
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
	monitor.setCursorPos(1, 1)
	monitor.write("Storage capacity: " .. self.totalCapacity .. "/" .. self.totalCapacity - self.capacity)
	local line = 2
	for name, info in pairs(itemTable) do
		if info.total > 0 then
			monitor.setCursorPos(1, line)
			local itemInfoString = string.format("%d | %s", info.total, info.displayName)
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
		local itemInfoString = string.format("%s | Can craft: %d | %s", name, order.count, order.state)
		monitor.write(itemInfoString)
		line = line + 1
	end
end

return Display
