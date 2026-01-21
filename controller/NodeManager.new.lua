---@type EventEmitter
local EventEmitter = dofile("factory/shared/EventEmitter.lua")
---@type Bridge
local Bridge = dofile("factory/shared/Bridge.lua")

local Crafting = require("Crafting")

---@class Node
---@field id number
---@field crafterType string
---@field bufferName string
---@field state string

---@class NodeManager
---@field bridge Bridge
---@field nodes table

---@class NodeManager: EventEmitter
local NodeManager = {}
NodeManager.__index = NodeManager
setmetatable(NodeManager, { __index = EventEmitter })

---@param threader Threader
function NodeManager.new(threader)
	local self = setmetatable(EventEmitter.new(threader), NodeManager)
	---@diagnostic disable-next-line
	self.bridge = Bridge.new(threader)
	self.nodes = {}
	return self
end

function NodeManager:start()
	self.bridge:on("message_received", function(from, content)
		print("Message received from:" .. from .. " content: ")
		print(textutils.serialise(content))
	end)

	self.bridge:startListening()
end

return NodeManager
