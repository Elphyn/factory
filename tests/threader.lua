local exception = dofile("factory/tests/exception.lua")
local Threader = {}
Threader.__index = Threader

function Threader.new()
	local self = setmetatable({}, Threader)
	self.threads = {}
	self.event = { n = 0 }
	return self
end

function Threader:addThread(fn, callback, info)
	local barrier_ctx = { co = coroutine.running() }
	local co = coroutine.create(function()
		return exception.try_barrier(barrier_ctx, fn)
	end)
	local thread = {
		co = co,
		filter = nil,
		callback = callback,
		info = info or {}, -- additional info
	}
	-- need to make sure they don't overrride each other
	table.insert(self.threads, thread)
end

function Threader:alive()
	if #self.threads < 1 then
		return false
	end
	for _, thread in ipairs(self.threads) do
		if thread and coroutine.status(thread.co) ~= "dead" then
			return true
		end
	end
	return false
end

function Threader:run()
	for i = 1, #self.threads do
		local thread = self.threads[i]
		if thread and (thread.filter == nil or thread.filter == self.event[1] or self.event[1] == "terminate") then
			local ok, param = coroutine.resume(thread.co, table.unpack(self.event, 1, self.event.n))

			if ok then
				thread.filter = param
			elseif type(param) == "string" and exception.can_wrap_errors() then
				error(exception.make_exception(param, thread.co))
			else
				error(param, 0)
			end

			if coroutine.status(thread.co) == "dead" then
				if self.threads[i].callback then
					self.threads[i].callback(thread.info)
				end
				self.threads[i] = false
			end
		end
	end
	if self:alive() then
		self.event = table.pack(os.pullEventRaw())
	else
		self.event = { n = 0 }
	end

	-- self.event = table.pack(os.pullEventRaw())
end

return Threader
