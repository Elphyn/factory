-- local scheduler = require("scheduler")
--
-- local function displayLoop()
-- 	while true do
-- 		local itemTable = getStorageItems()
-- 		local queue = scheduler(itemTable)
-- 		displayStorageItems(itemTable, queue)
--
-- 		sleep(0.1)
-- 	end
-- end
--
-- displayLoop()
local getStorageItems = require("storage")
local Threader = dofile("factory/utils/threader.lua")
local scheduler = require("scheduler")
local displayStorageItems = require("display")

local threader = Threader.new()

local itemTable = getStorageItems()
local queue = scheduler(itemTable)

local function main()
	threader:addThread(function()
		-- update storage and queue
		while true do
			itemTable = getStorageItems()
			queue = scheduler(itemTable)
			displayStorageItems(itemTable, queue)
			sleep(0.05)
		end
	end)

	-- main loop
	while true do
		threader:run()
	end
end

main()
