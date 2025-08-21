local function craft(buffer, stationName)
	local station = peripheral.wrap(stationName)
	station.pullItem(buffer, "minecraft:cobblestone", 1)

	local flag = true
	while flag do
		local stationInv = station.items()
		for _, itemTable in ipairs(stationInv) do
			if itemTable.name == "minecraft:gravel" then
				flag = false
			end
		end
		sleep(0.1)
	end

	station.pushItem(buffer, "minecraft:gravel", 1)
end

local buffer = "minecraft:barrel_1"
local station = "create:millstone_30"
local secStation = "create:millstone_27"

local co = coroutine.create(function()
	craft(buffer, station)
end)

local co2 = coroutine.create(function()
	craft(buffer, secStation)
end)

local first = { co = co, filter = nil }
local second = { co = co2, filter = nil }

local threads = {}
table.insert(threads, first)
table.insert(threads, second)

local event = { n = 0 }
while true do
	for _, thread in ipairs(threads) do
		if thread.filter == nil or thread.filter == event[1] or event[1] == "terminate" then
			local ok, param = coroutine.resume(thread.co, table.unpack(event, 1, event.n))

			if coroutine.status(thread.co) == "dead" then
				print("One coroutine finished")
			end
		end
	end
	event = table.pack(os.pullEventRaw())
end

print("coroutine is finished")
