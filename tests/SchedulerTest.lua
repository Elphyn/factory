local serialize = dofile("../utils/serialize.lua")
local Scheduler = dofile("../controller/Scheduler.lua")

local inventory = {
	["minecraft:cobblestone"] = { total = 30 },
}

local scheduler = Scheduler.new()

scheduler:planCrafts(inventory)

-- don't forget to switch imports if running not from within the game
print(serialize(scheduler:getQueue()))
