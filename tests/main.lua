local craft = dofile("factory/worker/crafting.lua")
local config = dofile("factory/worker/config.lua")
local Threader = dofile("factory/tests/threader.lua")
-- function standardCrafting(takeFromName, placeWhereName, stationName, task)
--
local queue = {
	{
		action = "crafting-order",
		order = {
			id = 1,
			task = {
				item = "minecraft:gravel",
				count = 10,
			},
			state = "waiting",
		},
	},
}

local function main()
	local threader = Threader.new()
	while true do
		for _, entry in ipairs(queue) do
			if entry.order.state == "waiting" then
				-- first is dispatcher, second is a callback when thread is dead
				threader.addThread(function()
					-- dispatcher goes here
				end, function()
					entry.order.state = "finished"
				end)
			elseif entry.order.state == "finished" then
				print("Order id: " .. entry.order.id .. " is Finished!")
			end
		end
		threader.run()
	end
end

local function socket()
	while true do
		local message = rednet.receive()

		if message.action == "crafting-order" then
			local order = message.order
			order.state = "waiting"
			table.insert(queue, order)
		end
		sleep()
	end
end

parallel.waitForAll(socket, main)

-- notes, I might just add time of the start of productin, to the end, and then based on that calculate time per unit, based on how many things were crafted, and how long it took
