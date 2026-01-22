local DEFAULT_SLOT_CAPACITY = 64
local DEFAULT_SLOT_CAPACITY_DRAWER = 1024

---
--- @class peripheralInfo
--- @field slotCount number
--- @field slotLimit number
---
--- List of peripherals that are using UnlimitedPeripherals storage API, and their additional info
--- @alias supportedPeriphearlsList table<string, peripheralInfo>

---
--- @type supportedPeriphearlsList
return {
	["create:basin"] = {
		slotCount = 9,
		slotLimit = DEFAULT_SLOT_CAPACITY,
	},
	["create:depot"] = {
		slotCount = 1,
		slotLimit = DEFAULT_SLOT_CAPACITY,
	},
	["create:millstone"] = {
		slotCount = 1,
		slotLimit = DEFAULT_SLOT_CAPACITY,
	},
	["extended_drawers:single_drawer"] = {
		slotCount = 1,
		slotLimit = DEFAULT_SLOT_CAPACITY_DRAWER,
	},
	["extended_drawers:double_drawer"] = {
		slotCount = 2,
		slotLimit = DEFAULT_SLOT_CAPACITY_DRAWER / 2,
	},
	["extended_drawers:quad_drawer"] = {
		slotCount = 4,
		slotLimit = DEFAULT_SLOT_CAPACITY_DRAWER / 4,
	},
}
