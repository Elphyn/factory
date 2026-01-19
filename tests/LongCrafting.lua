---@type LongCrafting
local LongCrafting = dofile("controller/LongCrafting.lua")

-- Test data
local testItems = {
	["minecraft:cobblestone"] = 10,
	["minecraft:gravel"] = 5,
	["minecraft:iron_nugget"] = 100,
	["minecraft:iron_ingot"] = 2
}

local availableNodeTypes = {
	["mill"] = true,
	["press"] = true,
	["fan:washing"] = false
}

print("=== Testing LongCrafting.findCraftableItems ===")

local craftableItems = LongCrafting.findCraftableItems(testItems, availableNodeTypes)

print("Items that can be crafted:")
for itemName, quantity in pairs(craftableItems) do
	print(string.format("  %s: %d", itemName, quantity))
end

print("\n=== Testing shortCraftPossible ===")

-- Test deterministic crafting
local itemsCopy1 = {}
for k, v in pairs(testItems) do itemsCopy1[k] = v end

local canCraftGravel = LongCrafting.shortCraftPossible(itemsCopy1, "minecraft:gravel", 3, availableNodeTypes)
print(string.format("Can craft 3 gravel: %s", canCraftGravel and "YES" or "NO"))

-- Test non-deterministic crafting
local itemsCopy2 = {}
for k, v in pairs(testItems) do itemsCopy2[k] = v end

local canCraftNugget = LongCrafting.shortCraftPossible(itemsCopy2, "minecraft:iron_nugget", 5, {["fan:washing"] = true})
print(string.format("Can craft 5 iron nuggets: %s", canCraftNugget and "YES" or "NO"))

-- Test insufficient station type
local itemsCopy3 = {}
for k, v in pairs(testItems) do itemsCopy3[k] = v end

local canCraftNuggetNoStation = LongCrafting.shortCraftPossible(itemsCopy3, "minecraft:iron_nugget", 5, availableNodeTypes)
print(string.format("Can craft 5 iron nuggets without washing station: %s", canCraftNuggetNoStation and "YES" or "NO"))

print("\n=== Testing inventory reservation ===")

print("Original cobblestone count:", testItems["minecraft:cobblestone"])
local itemsCopy4 = {}
for k, v in pairs(testItems) do itemsCopy4[k] = v end

LongCrafting.shortCraftPossible(itemsCopy4, "minecraft:gravel", 3, availableNodeTypes)
print("Cobblestone after reserving for 3 gravel:", itemsCopy4["minecraft:cobblestone"])

print("\n=== Test completed ===")