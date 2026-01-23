---
---@type modAdapterStorage
return {
	["unlimited"] = {
		["minecraft:chest"] = require("adapters.regular.storage.chest"),
		["extended_drawers:single_drawer"] = require("adapters.unlimited.storage.extended_drawer"),
		["extended_drawers:double_drawer"] = require("adapters.unlimited.storage.extended_drawer"),
		["extended_drawers:quad_drawer"] = require("adapters.unlimited.storage.extended_drawer"),
	},
}
