--- @alias ratio number how many of this item need for crafting one of requested
---
--- @class recipe
--- @field dependencies table<itemName, ratio>
--- @field fluids? table TODO: in future
---
--- @class recipes
--- @field stationTypes table<itemName, stationType>
--- @field recipes table<itemName, recipe>
---
--- @type recipes
return {
	stationTypes = {
		["minecraft:gravel"] = "mill",
		["minecraft:flint"] = "mill",
		["minecraft:iron_ingot"] = "press",
		["minecraft:iron_block"] = "press",
		["minecraft:iron_nugget"] = "fan:washing",
	},
	recipes = {
		["mill"] = {
			["minecraft:gravel"] = {
				dependencies = {
					["minecraft:cobblestone"] = 1,
				},
			},
			["minecraft:flint"] = {
				dependencies = {
					["minecraft:gravel"] = 1,
				},
			},
		},
		["press"] = {
			["minecraft:iron_ingot"] = {
				dependencies = {
					["minecraft:iron_nugget"] = 9,
				},
			},
			["minecraft:iron_block"] = {
				dependencies = {
					["minecraft:iron_ingot"] = 9,
				},
			},
		},
		["fan:washing"] = {
			["minecraft:iron_nugget"] = {
				dependencies = {
					["minecraft:gravel"] = 1 / 0.12,
				},
			},
		},
	},
}
