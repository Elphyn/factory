local Threader = dofile("factory/tests/threader.lua")
local dispatcher = dofile("factory/worker/dispatcher.lua")
local getStations = dofile("factory/worker/stations.lua")

local queue = {}

local function handleQ()
	local threader = Threader.new()
	local stationStates, stationsAvailable = getStations()
	-- print("This many stations available" .. #stationsAvailable)
	for i = 1, #queue do
		if queue[i] then
			if queue[i].state == "waiting" then
				-- first is dispatcher, second is a callback when thread is dead
				print("Starting dispatcher for " .. queue[i].id)
				threader:addThread(function()
					queue[i].state = "in progress"
					dispatcher(queue[i].task, stationsAvailable, stationStates)
					-- dispatcher goes here
				end, function(info)
					queue[info.index] = "finished"
				end, { index = i })
			elseif queue[i].state == "finished" then
				print("Order id: " .. queue[i].id .. " is Finished!")
				queue[i] = false
			end
		end
	end
	threader:run()
end

local function listen()
	rednet.open("top")
	local _, message = rednet.receive(nil, 5)

	if message.action == "crafting-order" then
		print("Adding order")
		local order = message.order
		order.state = "waiting"
		table.insert(queue, order)
	end
end

local function main()
	while true do
		parallel.waitForAll(handleQ, listen)
	end
end

main()

-- notes, I might just add time of the start of productin, to the end, and then based on that calculate time per unit, based on how many things were crafted, and how long it took
