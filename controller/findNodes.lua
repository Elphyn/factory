local function getWorkers()
	local workers = {}

	local devices = peripheral.getNames()

	for _, name in ipairs(devices) do
		if string.match(name, "^computer") then
			local pc = peripheral.wrap(name)
			local name = pc.getLabel()
			if name ~= nil then
				if string.match(name, "^worker") then
					print("Print found worker pc")
					local type = string.match(name, "^worker(.+)$")
					print("It's type is ", type)
					if workers[type] == nil then
						workers[type] = {}
					end
					table.insert(workers[type], { id = pc.getID() })
				end
			end
		end
	end
	print("found this many mill nodes", #workers["mill"])
	return workers
end

return getWorkers
