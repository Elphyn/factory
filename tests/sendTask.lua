local request = {
	action = "crafting-order",
	order = {
		id = 1,
		task = {
			item = "minecraft:gravel",
			count = 5,
		},
	},
}

rednet.open("top")
rednet.send(8, request)
