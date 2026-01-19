-- Note:
-- Non determenistic yeilds should be tested next time
---
---@type Crafting_module
local Crafting = dofile("../controller/Crafting.lua")

local storage = {
	["minecraft:cobblestone"] = 2,
	["minecraft:iron_nugget"] = 90,
	["minecraft:iron_ingot"] = 9,
}

local millResults = Crafting.findCraftableItemsForNodeType(storage, "mill")

print("Items we can make for mill:")
for itemName, itemCount in pairs(millResults) do
	print(itemName .. ": " .. itemCount)
end

print("\nAny storage changes?")
for itemName, itemCount in pairs(storage) do
	print(itemName .. ": " .. itemCount)
end

local pressResults = Crafting.findCraftableItemsForNodeType(storage, "press")

print("\nItems we can make for press:")
for itemName, itemCount in pairs(pressResults) do
	print(itemName .. ": " .. itemCount)
end

print("\nAny storage changes?")
for itemName, itemCount in pairs(storage) do
	print(itemName .. ": " .. itemCount)
end

print("\nChanging to non determenistic recipes now")

storage = {
	["minecraft:gravel"] = 9,
}

local washingResults = Crafting.findCraftableItemsForNodeType(storage, "fan:washing")

print("Results for washing with fan: ")
for itemName, itemCount in pairs(washingResults) do
	print(itemName .. ": " .. itemCount)
end
