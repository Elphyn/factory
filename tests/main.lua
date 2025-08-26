local Threader = dofile("factory/tests/threader.lua")
local dispatcher = dofile("factory/worker/dispatcher.lua")
local getStations = dofile("factory/worker/stations.lua")

local queue = {}

local function handleQ()
	local threader = Threader.new()
	local stationStates, stationsAvailable = getStations()

	-- Start a periodic timer for queue processing
	local queueTimer = os.startTimer(0.1)

	while true do
		local event, param = os.pullEvent()

		if event == "timer" and param == queueTimer then
			-- Process queue
			for i = 1, #queue do
				if queue[i] then
					if queue[i].state == "waiting" then
						print("Starting dispatcher for " .. queue[i].id)
						threader:addThread(function()
							queue[i].state = "in progress"
							dispatcher(queue[i].task, stationsAvailable, stationStates)
						end, function(info)
							queue[info.index].state = "finished"
						end, { index = i })
					elseif queue[i].state == "finished" then
						print("Order id: " .. queue[i].id .. " is Finished!")
						queue[i] = false
					end
				end
			end

			-- Run threader
			threader:run()

			-- Restart timer
			queueTimer = os.startTimer(0.1)
		else
			-- Pass other events to threader
			threader:run()
		end
	end
end

local function listen()
	while true do
		rednet.open("top")
		local _, message = rednet.receive()

		if message and message.action == "crafting-order" then
			print("Adding order")
			local order = message.order
			order.state = "waiting"
			table.insert(queue, order)
		end
	end
end

local function main()
	local threader = Threader.new()
	threader:addThread(listen)
	threader:addThread(handleQ)

	while true do
		threader:run()
	end
end

main()
