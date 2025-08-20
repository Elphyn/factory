local config = require("config")
local recipes = require("factory.recipes")
local executeTask = require("factory.executeTask")
-- config should be something like {pcType = "node", stationType = "mill"}

local stationStates = {}
local stationsAvailable = {}
local bufferChest = "minecraft:barrel_1"

local function getStations()
	local devices = peripheral.getNames()

	for _, name in ipairs(devices) do
		if string.match(name, string.format("^create:%s", config.stationType)) then
			stationStates[name] = { state = "idle" }
			table.insert(stationsAvailable, name)
		end
		if string.match(name, "^minecraft:chest") then
			print("found a chest")
		end
	end
end

-- how should instruction look like?
-- {order = "minecraft:gravel", count = 10}
--

local function distribute_even(total, k)
	if k <= 0 then
		return {}
	end
	local base = math.floor(total / k)
	local r = total % k
	local loads = {}
	for i = 1, k do
		loads[i] = base + (i <= r and 1 or 0)
	end
	return loads
end

local function wrapper(func, ...)
	local args = { ... }
	return function()
		return func(table.unpack(args))
	end
end

local function getTaskFunctions(tasks)
	local functions = {}
	for _, task in ipairs(tasks) do
		local wrappedFunction = wrapper(executeTask, bufferChest, bufferChest, task.station, task)
		table.insert(functions, wrappedFunction)
	end
	return functions
end

local function startProduction(tasks)
	local functions = getTaskFunctions(tasks)

	parallel.waitForAll(table.unpack(functions))
end

local function handleInstructions()
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

local function main()
	if not config.pcType then
		print("The worker needs a manual set up")
		return
	end

	if not rednet.isOpen() then
		rednet.open(config.modemLocation)
	end

	getStations() -- also finds a buffer chest
	handleInstructions()
end

main()
