return {
	["minecraft:gravel"] = {
		crafter = "mill",
		dependencies = {
			["minecraft:cobblestone"] = 1,
		},
		craftingLimit = 1024,
	},
	["minecraft:flint"] = {
		crafter = "mill",
		dependencies = {
			["minecraft:gravel"] = 1,
		},
		craftingLimit = 1024,
	},
}
