-- just for reference, not used

-- that's initial design, very limiting
local message = {
	task = {
		order = "minecraft:gravel",
		count = 1,
	},
}

local request = {
	action = { "get-stations", "crafting-order" },
	-- if it's crafting-order, then next field is here, an example
	id = 8, -- id of the order, not pc
	task = {
		order = "minecraft:gravel",
		count = 1,
	},
}

local message = {
	-- an example would we action = "withdraw", and not a table
	-- table is for listing possible actions you choose from
	action = { "get-stations", "withdraw" },
	-- get-station field
	nStations = 7,
	-- withdraw field
	id = 8,
	-- when finished with order by id 8, ask to withdraw carfted items
}
