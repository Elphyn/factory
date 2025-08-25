local craft = dofile("factory/worker/crafting.lua")
local config = dofile("factory/worker/config.lua")
local Threader = dofile("factory/tests/threader.lua")
local dispatcher = dofile("factory/worker/dispatcher.lua")
local getStations = dofile("factory/worker/stations.lua")
-- function standardCrafting(takeFromName, placeWhereName, stationName, task)

local queue = {
	{
		id = 1,
		task = {
			item = "minecraft:gravel",
			count = 5,
		},
		state = "waiting",
	},
}

local function main()
	local threader = Threader.new()
	local stationStates, stationsAvailable = getStations()
	while true do
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
		sleep(0.1)
	end
end

-- local function socket()
-- 	while true do
-- 		rednet.open("top")
-- 		local _, message = rednet.receive()
--
-- 		if message.action == "crafting-order" then
-- 			print("Adding order")
-- 			local order = message.order
-- 			order.state = "waiting"
-- 			table.insert(queue, order)
-- 		end
-- 		sleep(0.1)
-- 	end
-- end

main()
-- parallel.waitForAll(socket, main)

-- notes, I might just add time of the start of productin, to the end, and then based on that calculate time per unit, based on how many things were crafted, and how long it took
