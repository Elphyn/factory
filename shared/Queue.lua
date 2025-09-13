-- FIFO queue implementation
local Queue = {}
Queue.__index = Queue

function Queue.new()
	local self = setmetatable({}, Queue)
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

return Queue
