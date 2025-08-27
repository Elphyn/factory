local function getWorkers()
	local workers = {}

	local devices = peripheral.getNames()

	for _, name in ipairs(devices) do
		if string.match(name, "^computer") then
			local pc = peripheral.wrap(name)
			local name = pc.getLabel()
			if string.match(name, "^worker") then
				local type = string.match(name, "^worker(.+)$")
				workers[type] = {}
				table.insert(workers[type], { id = pc.getID })
			end
		end
	end
	return workers
end

return getWorkers
