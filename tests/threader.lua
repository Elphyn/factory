local Threader = {}
Threader.__index = Threader

function Threader.new()
	local self = setmetatable({}, Threader)
	self.threads = {}
	self.event = { n = 0 }
	return self
end

function Threader:addThread(fn, callback)
	local co = coroutine.create(fn)
	local thread = {
		co = co,
		filter = nil,
		callback = callback,
		info = {}, -- additional info
	}
	table.insert(self.threads, thread)
end

function Threader:alive()
	for _, thread in ipairs(self.threads) do
		if thread then
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
	self.event = table.pack(os.pullEventRaw())
	-- thread.event = table.pack(os.pullEventRaw())
	sleep(0.1)
end

return Threader
