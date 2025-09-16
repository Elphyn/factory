local function getKeysSet(table)
	local res = {}
	for k, _ in pairs(table) do
		res[k] = true
	end
	return res
end

return getKeysSet
