local function findMonitor()
	local list = peripheral.getNames()

	for _, name in ipairs(list) do
		if string.match(name, "^monitor") then
			return name
		end
	end
	return nil
end

local function displayStorageItems(itemTable, queue, crafting)
	if itemTable == nil then
		print("No items in storage")
		return
	end
	local monitorName = findMonitor()
	if monitorName == nil then
		print("No monitor found")
		return
	end
	local monitor = peripheral.wrap(monitorName)
	monitor.clear()
	local line = 1
	for name, info in pairs(itemTable) do
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | %d/%d", info.displayName, info.count, info.capacity)
		monitor.write(itemInfoString)
		line = line + 1
	end
	-- items to craft:
	-- local queue = scheduler(itemTable)

	-- name = {order = name, count = how much we crafting}
	line = line + 1
	monitor.setCursorPos(1, line)
	monitor.write("Queue: ")
	line = line + 1
	for name, info in pairs(queue) do
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | Can craft: %d", itemTable[name].displayName, info.count)
		monitor.write(itemInfoString)
		line = line + 1
	end

	line = line + 1

	monitor.setCursorPos(1, line)
	monitor.write("Crafting: ")
	line = line + 1
	for item, requests in ipairs(crafting) do
		print("this many requests: " .. #requests .. " for " .. item)
		for i, request in ipairs(requests) do
			monitor.setCursorPos(1, line)
			print(
				request.assignedNode .. " " .. request.order.item .. " " .. request.order.count .. " " .. request.state
			)
			monitor.write(
				request.assignedNode .. " " .. request.order.item .. " " .. request.order.count .. " " .. request.state
			)
			line = line + 1
		end
	end
end

return displayStorageItems
