local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("storageManager")
local displayStorageItems = require("display")
local Scheduler = require("scheduler")

local threader = Threader.new()
local storageManager = StorageManager.new()
local scheduler = Scheduler.new()

local items = nil
local queue = nil

local function main()
	threader:addThread(function()
		-- updating and displaying contents of storage
		while true do
			items = storageManager:scan()
			queue = scheduler:planCrafts(items)
			displayStorageItems(items, queue)
			sleep(0.05)
		end
	end)
	while true do
		threader:run()
	end
end

main()
