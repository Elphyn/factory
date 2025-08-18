local function getWorkers()
	local workers = {}

	local devices = peripheral.getNames()

	for _, name in ipairs(devices) do
		if string.match(name, "^worker") then
			local pc = peripheral.wrap(name)
			local type = string.match(name, "^worker(.+)$")
			table.insert(workers[type], { id = pc.getID })
		end
	end
	return workers
end
