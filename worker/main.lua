local getStations = require("stations")
local config = require("config")
local handleInstructions = require("dispatcher")
local function main()
	if not config.pcType then
		print("The worker needs a manual set up")
		return
	end

	if not rednet.isOpen() then
		rednet.open(config.modemLocation)
	end

	local stationStates, stationsAvailable = getStations() -- also finds a buffer chest
	handleInstructions(stationsAvailable, stationStates)
end

main()
