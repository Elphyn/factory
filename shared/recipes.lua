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
		craftingLimit = 9,
	},
	["minecraft:iron_block"] = {
		displayName = "Iron Block",
		crafter = "press",
		dependencies = {
			["minecraft:iron_ingot"] = 9,
		},
	},
}
