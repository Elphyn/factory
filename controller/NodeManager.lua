local recipes = dofile("factory/shared/recipes.lua")
local split = require("even")
local NodeManager = {}
NodeManager.__index = NodeManager

function NodeManager.new(eventEmitter, networkManager)
	local self = setmetatable({}, NodeManager)
	self.nodes = {}
	self.networkManager = networkManager
	self.eventEmitter = eventEmitter
	self.nextId = 0
	self:scan()
	return self
end

function NodeManager:generateId()
	local id = self.nextId
	self.nextId = self.nextId + 1
	return id
end

function NodeManager:anyNodesOfType(type)
	if self.nodes[type] then
		return true
	end
	return false
end

function NodeManager:getNodesStaitionsCount(nodeType)
	local stations = {}
	for _, node in ipairs(self.nodes[nodeType]) do
		local nStations = self.networkManager:requestStationCount(node.id)
		stations[node.id] = nStations
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
			-- if computer has name, it's likely a node
			if name ~= nil then
				-- if name of computer is worker, it's a node
				if string.match(name, "^worker") then
					-- we're taking type of the node with (.+)$, takes what comes after worker:
					local type = string.match(name, "^worker:(.+)$")
					-- init
					if self.nodes[type] == nil then
						self.nodes[type] = {}
					end
					-- if pc isn't on, we turn it on
					if not pc.isOn() then
						pc.turnOn()
					end

					table.insert(self.nodes[type], { id = pc.getID(), capacity = 1024 })
				end
			end
		end
	end
end

return NodeManager
