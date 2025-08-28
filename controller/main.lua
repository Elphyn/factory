local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("storageManager")
local displayStorageItems = require("display")

local threader = Threader.new()
local storageManager = StorageManager.new()

local items = nil

local function main()
	threader:addThread(function()
		while true do
			local ok, res = pcall(function()
				-- disconnecting a chest while this is running would throw an error
				return storageManager:scan()
			end)
			if ok then
				items = res
				displayStorageItems(items)
			end
			sleep(0.05)
		end
	end)
	while true do
		threader:run()
	end
end

main()
