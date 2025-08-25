local Threader = dofile("factory/tests/threader.lua")
local craft = dofile("factory/worker/crafting.lua")
local buffer = dofile("factory/worker/config.lua").bufferName
local function popStation(stationsAvailable)
	if #stationsAvailable < 1 then
		error("No stations available")
	end
	local name = table.remove(stationsAvailable)
	return name
end

local function dispatcher(order, stationsAvailable, stationStates)
	-- you get task = {item = "minecraft:gravel", count = 10}
	-- checking if there are any staions available
	print("DEBUG: dispatcher started with n = ", #stationsAvailable)
	while #stationsAvailable < 1 do
		sleep(0.1)
	end
	print("Dispatcher assigning stations: n = " .. #stationsAvailable)
	local threader = Threader.new()
	while order.count > 0 or threader:alive() do
		-- assaigning stations
		if #stationsAvailable > 0 then
			local total = #stationsAvailable
			for i = 1, total do
				if order.count > 0 then
					local miniTask = {
						order = order.item,
						count = 1,
					}
					order.count = order.count - 1
					local station = popStation(stationsAvailable)
					stationStates[station].state = "working"
					threader:addThread(function()
						print("DEBUG: Starting crafting")
						craft(buffer, buffer, station, miniTask)
					end, function(info)
						print("DEBUG: dispatcher callback")
						if info.station == nil then
							print("info.station is nil")
						end
						print("Station finished it's piece")
						stationStates[info.station].state = "idle"
						table.insert(stationsAvailable, info.station)
						print("DEBUG: Callback is finished")
						sleep(0.1)
					end, { station = station })
				end
			end
		end
		print("DEBUG: in dispatecher before checking threads")
		threader:run()
	end
end

return dispatcher
