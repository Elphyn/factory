local function initStations(stationStartsWith)
	local devices = peripherals.getNames()

	local stationTable = {}
	local stationStack = {}

	for _, name in ipairs(devices) do
		if string.match(name, "^" .. stationStartsWith) then
			table.insert(stationStack, name)
			stationTable[name] = { state = "idle" }
		end
	end
	return stationTable, stationStack
end

local function main()
	local stationTable, stationStack = initStations("create:mill")
end
