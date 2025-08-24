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

local function dispatcher(order)
	-- you get task = {item = "minecraft:gravel", count = 10}
	-- checking if there are any staions available
	-- while #available < 1 do
	-- 	sleep(0.1)
	-- end
	print("dispatcher started")
	local threader = Threader.new()
	while order.count > 0 or threader.alive() do
		-- assaigning stations
		if #stationsAvailable > 0 then
			local total = #stationsAvailable
			print("Total: ", total)
			for i = 1, total do
				print("assigning station")
				if order.count > 0 then
					local miniTask = {
						order = order.item,
						count = 1,
					}
					order.count = order.count - 1
					local station = popStation()
					stationStates[station].state = "working"
					threader:addThread(function()
						-- thread.info.station = station
						craft(buffer, buffer, station, miniTask)
					end, function(info)
						if info.station == nil then
							print("info.station is nil")
						end
						print("Finished a piece, freeing up the station", info.station)
						stationStates[info.station].state = "idle"
						table.insert(stationsAvailable, info.station)
					end, { station = station })
				end
			end
		end
		print("re")
		threader:run()
	end
end

print("Before order")
print("Number of stations: ", #stationsAvailable)
local order = { item = "minecraft:gravel", count = 10 }
dispatcher(order)
