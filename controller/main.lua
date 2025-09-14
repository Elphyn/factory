local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("StorageManager")
local Scheduler = require("Scheduler")
local Display = require("Display")
local EventEmitter = dofile("factory/shared/EventEmitter.lua")
local ControllerNetworkManager = require("ControllerNetworkManager")
local NodeManager = require("NodeManager")

local threader = Threader.new()
local eventEmitter = EventEmitter.new(threader)
local storageManager = StorageManager.new(eventEmitter)
local networkManager = ControllerNetworkManager.new(eventEmitter, storageManager, threader)
local nodeManager = NodeManager.new(eventEmitter, networkManager)
local scheduler = Scheduler.new(eventEmitter, nodeManager)
local display = Display.new(eventEmitter)

local function main()
	rednet.open("back")

	if fs.exists("storage_log.txt") then
		fs.delete("storage_log.txt")
	end

	threader:addThread(function()
		while true do
			networkManager:listen()
		end
	end)

	threader:addThread(function()
		while true do
			networkManager:handleMessages()
			sleep(0.05)
		end
	end)

	threader:addThread(function()
		-- updating and displaying contents of storage
		while true do
			if not storageManager.updateLock then
				storageManager:update()
			end
			eventEmitter:handleEvents()
			sleep(0.05)
		end
	end)

	while true do
		threader:run()
	end
end

main()
