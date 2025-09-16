local function getValueSet(table)
	local res = {}
	for _, v in pairs(table) do
		res[v] = true
	end
	return res
end

return getValueSet
