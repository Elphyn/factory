if not rednet.isOpen() then
	rednet.open("top")
end
rednet.send(8, { order = "minecraft:gravel", count = 10 })
