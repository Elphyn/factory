local function getKeysSet(table)
	local res = {}
	for k, _ in pairs(table) do
		res[k] = True
	end
	return res
end

return getKeysSet
