---@alias ratio number how many of this item need for crafting one of requested
---
--- @class recipe
--- @field displayName string
--- @field crafter ccTweaked.peripherals.type
--- @field dependencies table<itemName, ratio>
--- @field craftingLimit number Specified by player as to how many to hold in storage

return {
	["minecraft:gravel"] = {
		displayName = "Gravel",
		crafter = "mill",
		dependencies = {
			["minecraft:cobblestone"] = 1,
		},
		craftingLimit = 3,
	},
	["minecraft:flint"] = {
		displayName = "Flint",
		crafter = "mill",
		dependencies = {
			["minecraft:gravel"] = 1,
		},
		craftingLimit = 3,
	},
	["minecraft:iron_ingot"] = {
		displayName = "Iron ingot",
		crafter = "press",
		dependencies = {
			["minecraft:iron_nugget"] = 9,
		},
		craftingLimit = 10,
	},
	["minecraft:iron_block"] = {
		displayName = "Iron Block",
		crafter = "press",
		dependencies = {
			["minecraft:iron_ingot"] = 9,
		},
		craftingLimit = 10,
	},
}
