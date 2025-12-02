local recipes = dofile("factory/shared/recipes.lua")

--- Searches for item in a given storage table
---@param requested_item_name string
---@param storage table
---@return boolean, integer | nil
local function findItem(requested_item_name, storage)
	for i, item in pairs(storage) do
		if requested_item_name == item.name then
			return true, i
		end
	end
	return false, nil
end

---Checks whether enough items were crafted in a given station
---@param item_name string
---@param requested_item_count integer
---@param station_name string
---@return boolean
local function isFinished(item_name, requested_item_count, station_name)
	local station = peripheral.wrap(station_name)

	if station == nil then
		error("Station " .. station_name .. " no longer exists")
	end

	local station_storage = station.items()

	local found, item_slot = findItem(item_name, station_storage)

	if not found then
		return false
	end

	if station_storage[item_slot].count >= requested_item_count then
		return true
	end

	return false
end

---Standard crafting that has stict yeild and requires no fluids
---@param buffer_name string
---@param station_name string
---@param task standard_crafting_task
---@param order crafting_order
function standardCrafting(buffer_name, station_name, task, order) end

function standardCrafting(takeFromName, placeWhereName, stationName, task, order)
	-- Should note, that if we got here, we must assume we have enough items
	-- Also, this crafting assumes we get one to one ratio, no, when it's concrete how many items you get
	local craftingItemName = task.name
	local howManyToCraft = task.count
	local recipeItemList = recipes[craftingItemName].dependencies

	-- place itmes in a station
	local station = peripheral.wrap(stationName)

	if station == nil then
		error("Station " .. stationName .. " no longer exists")
	end

	if station.setFilterItem ~= nil then
		station.setFilterItem(craftingItemName)
	end

	for key, value in pairs(recipeItemList) do
		-- local ok, result = pcall(station.pullItem(takeFromName, key, value * howManyToCraft))
		station.pullItem(takeFromName, key, value * howManyToCraft)
	end

	while not isDone(craftingItemName, howManyToCraft, stationName) do
		sleep(0.05)
	end
	-- withdraw items
	station.pushItem(placeWhereName, craftingItemName, howManyToCraft)
	-- since it's concrete for this type of crafting, we always end up with what we needed to craft
	if not order.yield then
		order.yield = {}
	end
	if not order.yield[craftingItemName] then
		order.yield[craftingItemName] = 0
	end
	order.yield[craftingItemName] = order.yield[craftingItemName] + howManyToCraft

	if station.clearFilterItem ~= nil then
		station.clearFilterItem()
	end
end

return standardCrafting
