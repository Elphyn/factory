local function serialize(value, indent)
	indent = indent or 0
	local t = type(value)

	if t == "number" or t == "boolean" then
		return tostring(value)
	elseif t == "string" then
		return string.format("%q", value) -- escape quotes
	elseif t == "table" then
		local spacing = string.rep("  ", indent)
		local spacingInner = string.rep("  ", indent + 1)
		local result = "{\n"

		for k, v in pairs(value) do
			local key
			if type(k) == "string" and k:match("^%a[%w_]*$") then
				key = k
			else
				key = "[" .. serialize(k, indent + 1) .. "]"
			end
			result = result .. spacingInner .. key .. " = " .. serialize(v, indent + 1) .. ",\n"
		end

		result = result .. spacing .. "}"
		return result
	else
		error("cannot serialize type: " .. t)
	end
end
return serialize
