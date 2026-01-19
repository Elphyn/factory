---@class Deque
---@field first number
---@field last number
---@field table table
---@field length number
---@field new fun(): Deque
---@field push fun(self: table, value: any)
---@field popLeft fun(self: table): any
---@field popRight fun(self: table): any
---@field peekLeft fun(self: table): any
---@field peekRight fun(self: table): any
---@field empty fun(self: table): boolean

---@class Deque
local Deque = {}
Deque.__index = Deque

function Deque.new()
	local self = setmetatable({}, Deque)
	self.first = 1
	self.last = 0
	self.table = {}
	return self
end

function Deque:empty()
	return self.first > self.last
end

function Deque:push(value)
	self.last = self.last + 1
	self.table[self.last] = value
end

function Deque:peekLeft()
	if self:empty() then
		error("Trying to peek into an empty queue")
	end
	local value = self.table[self.first]
	return value
end

function Deque:peekRight()
	if self:empty() then
		error("Trying to peek into an empty queue")
	end
	local value = self.table[self.last]
	return value
end

function Deque:popLeft()
	if self:empty() then
		error("Trying to pop from an empty queue")
	end
	local value = self.table[self.first]
	self.table[self.first] = nil
	self.first = self.first + 1
	return value
end

function Deque:popRight()
	if self:empty() then
		error("Trying to pop from an empty queue")
	end
	local value = self.table[self.last]
	self.table[self.last] = nil
	self.last = self.last - 1
	return value
end

return Deque
