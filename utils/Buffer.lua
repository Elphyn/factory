local Queue = require("Queue")

---Fixed size circular buffer, needs to avoid having an abnormally big tables for instant lookup
---@class Buffer
---@field capacity number
---@field q Queue
---@field set table<number, boolean>
---@field size number
local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(capacity)
	local self = setmetatable({}, Buffer)
	self.capacity = capacity
	self.q = Queue.new()
	self.set = {}
	self.size = 0
	return self
end

function Buffer:evict()
	if self.q:length() <= 0 then
		error("[BUFFER] trying to evict on an empty queue, impossible condition")
	end
	local removed = self.q:pop()
	self.set[removed] = nil
	self.size = self.size - 1
end

---@param id number
function Buffer:add(id)
	if self.set[id] then
		error("[BUFFER] Trying to add a duplicate in a buffer")
	end

	if self.size >= self.capacity then
		self:evict()
	end

	self.size = self.size + 1
	self.q:push(id)
	self.set[id] = true
end

---A membership check of id in a buffer
---@param id number
---@return boolean
function Buffer:lookup(id)
	return self.set[id] == true
end
