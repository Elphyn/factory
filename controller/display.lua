local recipes = dofile("factory/shared/recipes.lua")
local function findMonitor()
	local list = peripheral.getNames()

	for _, name in ipairs(list) do
		if string.match(name, "^monitor") then
			return name
		end
	end
	return nil
end

local function displayStorageItems(itemTable, queue)
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
		local itemInfoString = string.format("%s | %d/%d", info.displayName, info.total, info.capacity)
		monitor.write(itemInfoString)
		line = line + 1
	end
	-- name = {order = name, count = how much we crafting}
	line = line + 1
	monitor.setCursorPos(1, line)
	monitor.write("Queue: ")
	line = line + 1
	for _, order in ipairs(queue) do
		local name = recipes[order.name].displayName
		monitor.setCursorPos(1, line)
		local itemInfoString = string.format("%s | Can craft: %d", name, order.count)
		monitor.write(itemInfoString)
		line = line + 1
	end
	--
	-- line = line + 1
	--
	-- monitor.setCursorPos(1, line)
	-- monitor.write("Crafting: ")
	-- line = line + 1
	-- for item, requests in pairs(crafting) do
	-- 	for i, request in ipairs(requests) do
	-- 		monitor.setCursorPos(1, line)
	-- 		monitor.write(
	-- 			"to: "
	-- 				.. request.assignedNode
	-- 				.. " "
	-- 				.. itemTable[request.order.item].displayName
	-- 				.. " "
	-- 				.. request.order.count
	-- 				.. " "
	-- 				.. request.state
	-- 		)
	-- 		line = line + 1
	-- 	end
	-- end
end

return displayStorageItems
