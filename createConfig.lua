function generateConfig(stationType, bufferName)
	local config = {
		stationType = stationType,
		bufferName = bufferName,
		modemLocation = "top",
	}

	-- open file for writing
	local file = fs.open("factory/worker/config.lua", "w")
	file.write("return {\n")
	for k, v in pairs(config) do
		if v == "nil" then
			file.write(("  %s = nil,\n"):format(k))
		elseif type(v) == "string" then
			file.write(("  %s = %q,\n"):format(k, v))
		else
			file.write(("  %s = %s,\n"):format(k, tostring(v)))
		end
	end
	file.write("}\n")
	file.close()

	print("config.lua generated!")
end
return generateConfig
