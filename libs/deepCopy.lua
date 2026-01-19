local function deepCopy(t)
	-- if it's not table, we don't need a deep copy
	if type(t) ~= "table" then
		return t
	end

	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

return deepCopy
