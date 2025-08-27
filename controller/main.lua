local getStorageItems = require("storage")
local Threader = dofile("factory/utils/threader.lua")
local scheduler = require("scheduler")
local displayStorageItems = require("display")
local getWorkers = require("findNodes")
local recipes = dofile("factory/shared/recipes.lua")
local splitN = require("even")

local threader = Threader.new()
local itemTable = getStorageItems()
local queue = scheduler(itemTable)
local globalID = 1
local nodes = getWorkers()

local crafting = {}

local function getNstations(id)
	local _, msg = rednet.send(id, { action = "get-stations" })

	return msg.nStations
end

local function main()
	threader:addThread(function()
		-- updating info
		while true do
			nodes = getWorkers()
			itemTable = getStorageItems()
			queue = scheduler(itemTable)
			displayStorageItems(itemTable, queue, crafting)
			sleep(0.05)
		end
	end)

	threader:addThread(function()
		while true do
			for item, info in pairs(queue) do
				if crafting[item] == nil then
					local req = info.count
					local type = recipes[item].crafter

					local nodeStationsCount = {}
					for i, node in ipairs(nodes[type]) do
						local n = getNstations(node.id)
						table.insert(nodeStationsCount, n)
					end
					local spread = splitN(req, nodeStationsCount)
					-- table.insert(crafting[item], {assignedNode = nodes[type][]})
					for i, part in ipairs(spread) do
						local locId = globalID
						local request = {
							assignedNode = nodes[type][i].id,
							action = "crafting-order",
							id = locId,
							order = {
								item = item,
								count = part,
							},
							state = "waiting",
						}
						globalID = globalID + 1
						table.insert(crafting[item], request)
					end
				end
			end
			sleep(0.05)
		end
	end)

	-- main loop
	while true do
		threader:run()
	end
end

main()
