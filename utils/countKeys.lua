local function counter()
	local count = 0
	for k, _ in pairs(table) do
		count = count + 1
	end
	return count
end

return counter
