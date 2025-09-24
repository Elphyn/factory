local recipes = dofile("factory/shared/recipes.lua")
local split = require("even")
local NodeManager = {}
NodeManager.__index = NodeManager

function NodeManager.new(eventEmitter, networkManager)
	local self = setmetatable({}, NodeManager)
	self.nodes = {}
	self.nodesType = {}
	self.nodesAvailable = {}
	self.networkManager = networkManager
	self.eventEmitter = eventEmitter
	self.nextId = 0
	self:setupEvents()
	self:scan()
	return self
end

function NodeManager:setupEvents()
	self.eventEmitter:subscribe("node-ready", function(msg)
		self.nodes[id].buffer = msg.buffer
		self.nodes[id].stations = msg.stations
		self.nodes[id].state = "ready"
		table.insert(self.nodesAvailable[msg.type], msg.id)
	end)
end

function NodeManager:generateId()
	local id = self.nextId
	self.nextId = self.nextId + 1
	return id
end

function NodeManager:anyNodesOfType(type)
	return #self.nodesAvailable[type] > 0
end

function NodeManager:getBufferOfNode(nodeID)
	if not self.nodes[nodeID] or self.nodes[nodeID].ready ~= "ready" then
		error("Trying to get node's buffer without it being ready")
	end
	return self.nodes[nodeID].buffer
end

function NodeManager:getNodesStaitionsCount(nodeType)
	local stations = {}
	for _, nodeID in ipairs(self.nodesAvailable[nodeType]) do
		local nStations = self.nodes[nodeID].stations
		stations[nodeID] = nStations
	end
	return stations
end

function NodeManager:scan()
	local devices = peripheral.getNames()

	-- go through all peripherals to find nodes, that we set up
	for _, Pname in ipairs(devices) do
		-- if peripheral is computer
		if string.match(Pname, "^computer") then
			local pc = peripheral.wrap(Pname)
			local name = pc.getLabel()
			local state = "ready"
			-- if computer has name, it's likely a node
			if name ~= nil then
				-- if name of computer is worker, it's a node
				if string.match(name, "^worker") then
					-- we're taking type of the node with (.+)$, takes what comes after worker:
					local type = string.match(name, "^worker:(.+)$")
					-- init
					if self.nodesType[type] == nil then
						self.nodesType[type] = {}
					end
					-- if pc isn't on, we turn it on
					if not pc.isOn() then
						state = "starting"
						pc.turnOn()
					end

					local nodeID = pc.getID()
					local node = { id = nodeID, state = state, stations = 0, buffer = nil }
					self.nodes[nodeID] = node
					table.insert(self.nodesType[type], nodeID)
				end
			end
		end
	end
end

return NodeManager
