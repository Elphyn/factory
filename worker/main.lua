local Threader = dofile("factory/utils/threader.lua")
local config = require("config")
local StationManager = require("stationManager")
local EventEmitter = dofile("factory/utils/EventEmitter.lua")
local WorkerNetworkManager = require("WorkerNetworkManager")
local OrderManager = require("OrderManager")

local threader = Threader.new()
local eventEmitter = EventEmitter.new(threader)
local stationManager = StationManager.new(eventEmitter)
local workerNetworkManager = WorkerNetworkManager.new(eventEmitter, stationManager, threader)
local orderManager = OrderManager.new(threader, stationManager, eventEmitter)

local function main()
	rednet.open(config.modemLocation)

	threader:addThread(function()
		-- listening for commands
		while true do
			workerNetworkManager:listen()
			sleep(0.05)
		end
	end)

	threader:addThread(function()
		while true do
			workerNetworkManager:handleMessages()
			sleep(0.05)
		end
	end)

	while true do
		threader:run()
	end
end

main()
