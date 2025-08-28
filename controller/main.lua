local threader = dofile("factory/utils/threader.lua")
local storageManager = require("storageManager")
local displayStorageItems = require("display")

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
