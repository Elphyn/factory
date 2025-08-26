local getStations = dofile("factory/worker/stations.lua")
local Threader = dofile("factory/tests/threader.lua")
local craft = dofile("factory/worker/crafting.lua")
local buffer = dofile("factory/worker/config.lua").bufferName

local queue = {}
local stationStates, stationsAvailable = getStations()

local threader = Threader.new()

local function popStation()
	if #stationsAvailable < 1 then
		error("No stations available")
	end
	local name = table.remove(stationsAvailable)
	return name
end

local function alive(inProgress)
	for _, v in pairs(inProgress) do
		if v then
			return true
		end
	end
	return false
end

local function dispatcher(order)
	while #stationsAvailable < 1 do
		sleep(0.05)
	end
	local inProgress = {}
	local co_id = 1

	while order.count > 1 or alive(inProgress) do
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
					local station = popStation()
					stationStates[station].state = "working"
					threader:addThread(function()
						inProgress[co_id] = true
						co_id = co_id + 1
						craft(buffer, buffer, station, miniTask)
					end, function(info)
						inProgress[info.co_id] = false
						stationStates[info.station].state = "idle"
						table.insert(stationsAvailable, info.station)
					end, { station = station, co_id = co_id })
				end
			end
		end
		sleep(0.05)
	end
end

local function main()
	rednet.open("top")

	threader:addThread(function()
		-- receiving instructions
		while true do
			local _, message = rednet.receive()

			if message then
				if message.action == "crafting-order" then
					local order = message.order
					order.state = "waiting"
					table.insert(queue, order)
				end
			end
		end
	end)

	threader:addThread(function()
		-- Q handler
		while true do
			for i = 1, #queue do
				if queue[i] then
					if queue[i].state == "waiting" then
						-- first is dispatcher, second is a callback when thread is dead
						threader:addThread(function()
							queue[i].state = "in progress"
							dispatcher(queue[i].task)
							-- dispatcher goes here
						end, function(info)
							queue[info.index] = "finished"
						end, { index = i })
					end
				end
			end
			sleep(0.05)
		end
	end)
	threader:addThread(function()
		-- display function
		while true do
			term.clear()
			local line = 1
			for _, entry in ipairs(queue) do
				term.setCursorPos(1, line)
				term.write("Order for: " .. entry.task.item .. "| " .. entry.task.count .. " | " .. entry.state)
				line = line + 1
			end
			sleep(0.1)
		end
	end)

	while true do
		threader:run()
	end
end

main()
