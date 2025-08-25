local getStations = dofile("factory/worker/stations.lua")
local dispatcher = dofile("factory/worker/dispatcher.lua")

local queue = {
	{
		id = 1,
		task = {
			item = "minecraft:gravel",
			count = 5,
		},
		state = "waiting",
	},
}

local stationStates, stationsAvailable = getStations()

dispatcher(queue[1].task, stationsAvailable, stationStates)
