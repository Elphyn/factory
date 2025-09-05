local Threader = dofile("factory/utils/threader.lua")
local StationManager = require("stationManager")
local EventEmitter = dofile("factory/utils/EventEmitter.lua")
local NetworkManager = dofile("factory/shared/NetworkManager.lua")

local threader = Threader.new()
local eventEmitter = EventEmitter.new()
local stationManager = StationManager.new(eventEmitter)
local networkManager = NetworkManager.new(threader, eventEmitter)

local function main()
	rednet.open(config.modemLocation)
	threader.addThread(function()
		-- listening for commands
		networkManager.listen()
	end)

	while true do
		threader.run()
	end
end

main()
