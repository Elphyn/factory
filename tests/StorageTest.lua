-- push/pull item back and forth
--
local StorageManager = dofile("factory/controller/StorageManager.lua")
local storageManager = StorageManager.new()

local buffer = "minecraft:barrel_7"
local item = "minecraft:cobblestone"

local function main()
	storageManager:update()
	storageManager:pushItem(buffer, item, 10)
end

main()
