local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("storageManager")
local displayStorageItems = require("display")

local threader = Threader.new()
local storageManager = StorageManager.new()

local items = nil

local function main()
	threader:addThread(function()
		while true do
			items = storageManager:scan()
			displayStorageItems(items)
			sleep(0.05)
		end
	end)
	while true do
		threader:run()
	end
end

main()
