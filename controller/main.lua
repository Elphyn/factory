local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("storageManager")
local Scheduler = require("scheduler")
local Display = require("Display")

local threader = Threader.new()
local storageManager = StorageManager.new()
local scheduler = Scheduler.new(storageManager)
local display = Display.new(storageManager, scheduler)

local function main()
	threader:addThread(function()
		-- updating and displaying contents of storage
		while true do
			storageManager:scan()
			sleep(0.05)
		end
	end)
	while true do
		threader:run()
	end
end

main()
