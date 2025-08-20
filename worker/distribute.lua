local function distribute_even(total, k)
	if k <= 0 then
		return {}
	end
	local base = math.floor(total / k)
	local r = total % k
	local loads = {}
	for i = 1, k do
		loads[i] = base + (i <= r and 1 or 0)
	end
	return loads
end
return distribute_even
