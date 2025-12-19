---@type Threader
local Threader = dofile("factory/utils/threader.lua")
local StorageManager = require("StorageManager")

local function main()
	rednet.open("back")

	local threader = Threader.new()
	local storageManager = StorageManager.new(threader)

	storageManager:on("inventory_changed", function(items)
		print("Inventroy changed, state: ")
		print(textutils.serialise(items))
	end)

	storageManager:start()

	while true do
		threader:run()
	end
end

main()
