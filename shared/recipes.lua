---@alias ratio number how many of this item need for crafting one of requested
---
--- @class recipe
--- @field displayName string
--- @field dependencies table<itemName, ratio>
--- @field craftingLimit number Specified by player as to how many to hold in storage
---
--- Notes:
--- Certain recipes don't yield strick amount of dependencie to item ratio, so should probably add a boolean field for that
return {
	["mill"] = {
		["minecraft:gravel"] = {
			displayName = "Gravel",
			dependencies = {
				["minecraft:cobblestone"] = 1,
			},
			craftingLimit = 3,
		},
		["minecraft:flint"] = {
			displayName = "Flint",
			dependencies = {
				["minecraft:gravel"] = 1,
			},
			craftingLimit = 3,
		},
	},
	["press"] = {
		["minecraft:iron_ingot"] = {
			displayName = "Iron ingot",
			dependencies = {
				["minecraft:iron_nugget"] = 9,
			},
			craftingLimit = 10,
		},
		["minecraft:iron_block"] = {
			displayName = "Iron Block",
			dependencies = {
				["minecraft:iron_ingot"] = 9,
			},
			craftingLimit = 10,
		},
	},
}
