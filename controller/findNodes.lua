local function getWorkers()
	local workers = {}

	local devices = peripheral.getNames()

	for _, Pname in ipairs(devices) do
		if string.match(Pname, "^computer") then
			local pc = peripheral.wrap(Pname)
			local name = pc.getLabel()
			if name ~= nil then
				if string.match(name, "^worker") then
					local type = string.match(name, "^worker:(.+)$")
					if workers[type] == nil then
						workers[type] = {}
					end
					if not pc.isOn() then
						pc.turnOn()
					end
					table.insert(workers[type], { id = pc.getID(), capacity = 1024 })
				end
			end
		end
	end
	return workers
end

return getWorkers
