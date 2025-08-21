local buffer = "minecraft:barrel_1"
local station = "create:millstone_30"

local function craft(buffer, station)
	station.pullItem(buffer, "minecraft:cobblestone", 1)

	local flag = true
	while flag do
		local stationInv = station.items()
		for _, itemTable in ipairs(stationInv) do
			if itemTable.name == "minecraft:gravel" then
				flag = false
			end
		end
		coroutine.yeild()
	end

	station.pushItem(buffer, "minecraft:cobblestone", 1)
end

local co = coroutine.create(function()
	craft(buffer, station)
end)

local thread = { co, filter = nil }

local event = { n = 0 }
while coroutine.status(thread.co) ~= "dead" do
	if thread.filter == nil or thread.filter == event[1] or event[1] == "terminate" then
		local ok, param = coroutine.resume(thread.co, table.unpack(event, 1, event.n))
		if not ok then
			print("Something went wrong while resuming coroutine", param)
		end
	end
	event = table.pack(os.pullEventRaw())
end

print("coroutine is finished")
