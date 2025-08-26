local getStations = dofile("factory/worker/stations.lua")
local Threader = dofile("factory/tests/threader.lua")
local craft = dofile("factory/worker/crafting.lua")
local buffer = dofile("factory/worker/config.lua").bufferName

local queue = {}
local stationStates, stationsAvailable = getStations()

local threader = Threader.new()

local inProgress = {}

local function popStation()
	if #stationsAvailable < 1 then
		error("No stations available")
	end
	local name = table.remove(stationsAvailable)
	return name
end

local function dispatcher(order)
	while #stationsAvailable < 1 do
		sleep(0.1)
	end
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
					print("Station finished it's piece, freeing up: ", info.station)
					stationStates[info.station].state = "idle"
					table.insert(stationsAvailable, info.station)
					print("DEBUG: Callback is finished")
					sleep(0.1)
				end, { station = station })
			end
		end
	end
end

local function main()
	rednet.open("top")

	threader:addThread(function()
		while true do
			local _, message = rednet.receive()
			print("Got message, this many stations available: ", #stationsAvailable)

			if message then
				if message.action == "crafting-order" then
					print("Adding order")
					local order = message.order
					order.state = "waiting"
					table.insert(queue, order)
				end
			end
		end
	end)

	threader:addThread(function()
		while true do
			for i = 1, #queue do
				if queue[i] then
					if queue[i].state == "waiting" then
						-- first is dispatcher, second is a callback when thread is dead
						print("Starting dispatcher for " .. queue[i].id)
						threader:addThread(function()
							queue[i].state = "in progress"
							dispatcher(queue[i].task)
							-- dispatcher goes here
						end, function(info)
							print("DEBUG: Main Qhandler callback!")
							queue[info.index] = "finished"
						end, { index = i })
					elseif queue[i].state == "finished" then
						print("Order id: " .. queue[i].id .. " is Finished!")
						queue[i] = false
					end
				end
			end
			sleep(0.1)
		end
	end)

	while true do
		threader:run()
	end
end

main()
