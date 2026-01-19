---
---@type modAdapterStorage
return {
	["unlimited"] = {
		["minecraft:chest"] = require("adapters.unlimited.chest"),
		["extended_drawers:single_drawer"] = require("adapters.unlimited.extended_drawer"),
		["extended_drawers:double_drawer"] = require("adapters.unlimited.extended_drawer"),
		["extended_drawers:quad_drawer"] = require("adapters.unlimited.extended_drawer"),
	},
}
