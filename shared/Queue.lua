-- FIFO queue implementation

local Queue = {}
Queue.__index = Queue

local deepEqual = dofile("factory/utils/deepEqual.lua")

function Queue.new()
	local self = setmetatable({}, Queue)
	self._isQueue = true
	self.first = 1
	self.last = 0
	self.table = {}
	return self
end

function Queue:push(value)
	self.last = self.last + 1
	self.table[self.last] = value
end

function Queue:pop()
	if self.first > self.last then
		error("Trying to pop from an empty queue")
	end
	local value = self.table[self.first]
	self.table[self.first] = nil
	self.first = self.first + 1
	return value
end

function Queue:peek()
	if self.first > self.last then
		error("Trying to peek into an empty queue")
	end
	local value = self.table[self.first]
	return value
end

function Queue:length()
	return self.last - self.first + 1
end

function Queue:reset()
	self.first = 1
	self.last = 0
	self.table = {}
end

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
