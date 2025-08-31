local config = require("config")
local StationManager = {}

StationManager.__index = StationManager

function StationManager.new()
	local self = setmetatable({}, StationManager)
	self.stations = { states = {}, available = {} }
	self.buffer = config.bufferName
	return self
end

function StationManager:findStations()
	-- TODO: could only be used once, otherwise would break everything
	local devices = peripheral.getNames()
	for _, name in ipairs(devices) do
		if string.match(name, string.format("^create:%s", config.stationType)) then
			self.stations.states[name] = "idle"
			table.insert(self.stations.available, name)
		end
	end
end

function StationManager:getOneStation()
	if #self.stations.available == 0 then
		error("Trying to get station: there's none")
	end
	local stationName = table.remove(self.stations.available)
	self.stations.states[name] = "working"
	return stationName
end

function StationManager:onFinished(station)
	self.stations.states[station] = "idle"
	table.insert(self.stations.available, station)
end

function StationManager:available()
	return #self.stations.available
end

return StationManager
