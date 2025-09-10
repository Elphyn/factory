local config = require("config")
local StationManager = {}

StationManager.__index = StationManager

function StationManager.new(eventEmitter)
	local self = setmetatable({}, StationManager)
	self.stations = { states = {}, available = {} }
	self.buffer = config.bufferName
	self.eventEmitter = eventEmitter
	self:setupEventListeners()
	self:findStations()
	return self
end

function StationManager:countStations()
	local count = 0
	for _ in pairs(self.stations.states) do
		count = count + 1
	end
	return count
end

function StationManager:setupEventListeners()
	if self.eventEmitter then
		self.eventEmitter:subscribe("get-stations", function(senderId)
			self.eventEmitter:emit("send-stations", senderId, self:countStations())
		end)
	end
end

function StationManager:findStations()
	-- TODO: could only be used once, otherwise would break everything
	local devices = peripheral.getNames()
	for _, name in ipairs(devices) do
		local stationPattern = require("stationBlocks")[config.stationType]
		if string.match(name, string.format("^create:%s", stationPattern)) then
			self.stations.states[name] = "idle"
			table.insert(self.stations.available, name)
		end
	end
	print("Found this many stations: ", #self.stations.available)
end

function StationManager:getOneStation()
	if #self.stations.available == 0 then
		error("Trying to get station: there's none")
	end
	local stationName = table.remove(self.stations.available)
	self.stations.states[stationName] = "working"
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
