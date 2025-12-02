-- FIFO queue implementation
---@module 'Queue'
---
---@class Queue
---@field _isQueue boolean Don't quire remember why I need this
---@field first number head of the queue
---@field last number tail of the queue
---@field table table the actual collection

local Queue = {}
Queue.__index = Queue

local deepEqual = dofile("factory/utils/deepEqual.lua")

---Creates a qeuue
---@return Queue
function Queue.new()
	local self = setmetatable({}, Queue)
	self._isQueue = true
	self.first = 1
	self.last = 0
	self.table = {}
	return self
end

---Add value to the end of the queue
---@param value any
function Queue:push(value)
	self.last = self.last + 1
	self.table[self.last] = value
end

--- Pops first value in the queue and returns it
---@return unknown
function Queue:pop()
	if self.first > self.last then
		error("Trying to pop from an empty queue")
	end
	local value = self.table[self.first]
	self.table[self.first] = nil
	self.first = self.first + 1
	return value
end

--- Look at the first item in the queue
---@return unknown
function Queue:peek()
	if self.first > self.last then
		error("Trying to peek into an empty queue")
	end
	local value = self.table[self.first]
	return value
end

--- Get number of items in the queue
---@return integer
function Queue:length()
	return self.last - self.first + 1
end

--- Reset the queue, removing all items inside
function Queue:reset()
	self.first = 1
	self.last = 0
	self.table = {}
end

-- These methods below are likely not going to be used anymore

function Queue:toTable()
	return {
		first = self.first,
		last = self.last,
		table = self.table,
	}
end

function Queue.initFromTable(data)
	local queue = Queue.new()
	queue.first = data.first
	queue.last = data.last
	queue.table = data.table
	return queue
end

function Queue:equals(other)
	if not other or getmetatable(other) ~= getmetatable(self) then
		return false
	end

	return self.first == other.first and self.last == other.last and deepEqual(self.table, other.table)
end

return Queue
