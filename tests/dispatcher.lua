local Threader = dofile("factory/tests/threader.lua")
local craft = dofile("factory/worker/crafting.lua")
local getStations = dofile("factory/worker/stations.lua")

local buffer = "minecraft:barrel_1"

local stationStates, stationsAvailable = getStations() -- also finds a buffer chest

local function popStation()
	if #stationsAvailable < 1 then
		error("No stations available")
	end
	local name = table.remove(stationsAvailable)
	return name
end

local function dispatcher(order, available, stations)
	-- you get task = {item = "minecraft:gravel", count = 10}
	-- checking if there are any staions available
	-- while #available < 1 do
	-- 	sleep(0.1)
	-- end
	local threader = Threader.new()
	while order.count > 0 or threader.alive() do
		-- assaigning stations
		if #available > 0 then
			local total = #available
			for i = 1, total do
				if order.count > 0 then
					local miniTask = {
						order = order.item,
						count = 1,
					}
					order.count = order.count - 1
					threader:addThread(function(thread)
						local station = popStation()
						stationStates[station].state = "working"
						thread.info.station = station
						craft(buffer, buffer, station, miniTask)
					end, function(info)
						local station = info.station
						stationStates[station].state = "idle"
						table.insert(available, station)
					end)
				end
			end
		end
		threader:run()
	end
end
