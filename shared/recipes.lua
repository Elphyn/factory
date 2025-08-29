return {
	["minecraft:gravel"] = {
		displayName = "Gravel",
		crafter = "mill",
		dependencies = {
			["minecraft:cobblestone"] = 1,
		},
		craftingLimit = 15,
	},
	["minecraft:flint"] = {
		displayName = "Flint",
		crafter = "mill",
		dependencies = {
			["minecraft:gravel"] = 1,
		},
		craftingLimit = 15,
	},
}
