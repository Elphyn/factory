--- @alias ratio number how many of this item need for crafting one of requested
---
--- @alias stationType
--- | "mill"
--- | "press"
--- | "fan:washing"
---
---
--- @class recipe
--- @field displayName string
--- @field dependencies table<itemName, ratio>
--- @field craftingLimit number Specified by player as to how many to hold in storage
--- @field nonDeterministic boolean
---
--- @class recipes
--- @field stationType table<itemName, stationType>
--- @field recipes table<itemName, recipe>
---
---
---@type recipes
return {
	stationType = {
		["minecraft:gravel"] = "mill",
		["minecraft:flint"] = "mill",
		["minecraft:iron_ingot"] = "press",
		["minecraft:iron_block"] = "press",
		["minecraft:iron_nugget"] = "fan:washing",
	},
	recipes = {
		["minecraft:gravel"] = {
			displayName = "Gravel",
			dependencies = {
				["minecraft:cobblestone"] = 1,
			},
			craftingLimit = 3,
			["minecraft:flint"] = {
				displayName = "Flint",
				dependencies = {
					["minecraft:gravel"] = 1,
				},
				craftingLimit = 3,
			},
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
			["minecraft:iron_nugget"] = {
				displayName = "Iron Nugget",
				dependencies = {
					["minecraft:gravel"] = 1 / 0.12,
				},
				craftingLimit = 64,
				nonDeterministic = true,
			},
		},
	},
}
