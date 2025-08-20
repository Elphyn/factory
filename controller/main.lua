local getStorageItems = require("storage")
local scheduler = require("scheduler")
local displayStorageItems = require("display")

local function displayLoop()
	while true do
		local itemTable = getStorageItems()
		local queue = scheduler(itemTable)
		displayStorageItems(itemTable, queue)

		sleep(0.1)
	end
end

displayLoop()
