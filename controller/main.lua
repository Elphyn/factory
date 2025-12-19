---@type Threader
local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("StorageManager")

local function main()
	rednet.open("back")

	local threader = Threader.new()
	local storageManager = StorageManager.new(threader)

	storageManager:on("inventory_changed", function(storage)
		print("Inventroy changed, state: " .. storage)
	end)
end

main()
