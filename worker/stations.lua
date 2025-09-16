local config = dofile("config.lua")

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
	return stationStates, stationsAvailable
end

return getStations
