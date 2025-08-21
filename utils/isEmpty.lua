local function isEmpty(table)
	for _ in pairs(table) do
		return false
	end
	return true
end

return isEmpty
