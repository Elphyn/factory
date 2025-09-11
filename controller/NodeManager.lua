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

function NodeManager:getLoadBalancedOrders(order)
	-- if there aren't any nodes that could fulfil the order, we can't finalize order
	local crafterType = recipes[order.name].crafter
	print("Crafting type for recipe of: " .. order.name)
	print(crafterType)
	if not self:anyNodesOfType(crafterType) then
		return {}
	end

	-- collecting info on how many stations each node of type has
	local stations = {}
	for _, node in ipairs(self.nodes[crafterType]) do
		local nStations = self.networkManager:requestStationCount(node.id)
		table.insert(stations, nStations)
	end

	local total = order.count
	-- spreading order across nodes
	local spread = split(total, stations)

	print("Available nodes:")
	print(textutils.serialize(self.nodes[crafterType]))
	-- finalizing orders, paritioning them evenly, assigning Nodes
	local finalizedOrders = {}
	for nodeId, part in pairs(spread) do
		local nodeId = self.nodes[crafterType][nodeId].id
		local splitOrder = {
			action = "crafting-order",
			assignedNodeId = nodeId,
			name = order.name,
			count = part,
			state = "waiting",
			id = self:generateId(),
		}
		table.insert(finalizedOrders, splitOrder)
	end
	return finalizedOrders
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
	print("Nodes:")
	print(textutils.serialize(self.nodes))
end

return NodeManager
