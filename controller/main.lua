local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("StorageManager")
local Scheduler = require("Scheduler")
local Display = require("Display")
local EventEmitter = dofile("factory/utils/EventEmitter.lua")
local NetworkManager = dofile("factory/shared/NetworkManager.lua")
local NodeManager = require("NodeManager")

local threader = Threader.new()
local eventEmitter = EventEmitter.new()
local storageManager = StorageManager.new(eventEmitter)
local networkManager = NetworkManager.new(eventEmitter, storageManager)
local nodeManager = NodeManager.new(eventEmitter, networkManager)
local scheduler = Scheduler.new(eventEmitter, nodeManager)
local display = Display.new(eventEmitter)

local function main()
	rednet.open("back")

	threader:addThread(function()
		while true do
			networkManager:listen()
		end
	end)

	threader:addThread(function()
		-- updating and displaying contents of storage
		while true do
			storageManager:update()
			sleep(0.05)
		end
	end)
	while true do
		threader:run()
	end
end

main()
