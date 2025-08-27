local config = dofile("factory/worker/config.lua")

local function getStations()
	local devices = peripheral.getNames()

	local stationStates = {}
	local stationsAvailable = {}

	for _, name in ipairs(devices) do
		if string.match(name, string.format("^create:%s", config.stationType)) then
			stationStates[name] = { state = "idle" }
			table.insert(stationsAvailable, name)
		end
	end
	print("Found this many stations: (states)", #stationStates)
	print("Found this many stations (avail)", #stationsAvailable)
	return stationStates, stationsAvailable
end

return getStations
