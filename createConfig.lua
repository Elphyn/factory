local function generateConfig(table, path)
	-- open file for writing
	local file = fs.open(path, "w")
	file.write("return {\n")
	for k, v in pairs(table) do
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
