local function Empty(table)
	for _ in pairs(table) do
		return false
	end
	return true
end

return Empty
