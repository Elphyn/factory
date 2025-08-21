local wrapper = dofile("factory/utils/wrapper")
local standardCrafting = require("crafting")
local distribute_even = require("distribute")
local bufferChest = require("config").bufferName

local function getTaskFunctions(tasks)
	local functions = {}
	for _, task in ipairs(tasks) do
		local wrappedFunction = wrapper(standardCrafting, bufferChest, bufferChest, task.station, task)
		table.insert(functions, wrappedFunction)
	end
	return functions
end

local function startProduction(tasks)
	local functions = getTaskFunctions(tasks)

	parallel.waitForAll(table.unpack(functions))
end

local function handleInstructions(stationsAvailable, stationStates)
	local _, bulkOrder = rednet.receive()
	print("received order")

	local totalStationsAvailable = #stationsAvailable
	local totalRegentToCraft = bulkOrder.count
	local loads = distribute_even(totalRegentToCraft, totalStationsAvailable)

	local tasks = {}

	for _, load in ipairs(loads) do
		local assignedStation = table.remove(stationsAvailable)
		stationStates[assignedStation].state = "working"
		table.insert(tasks, { order = bulkOrder.order, count = load, station = assignedStation })
	end

	startProduction(tasks)
end

return handleInstructions
