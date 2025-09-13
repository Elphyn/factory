local function deep_equal(t1, t2)
	if t1 == t2 then
		return true
	end
	if type(t1) ~= "table" or type(t2) ~= "table" then
		return false
	end

	-- count keys
	local count1, count2 = 0, 0
	for _ in pairs(t1) do
		count1 = count1 + 1
	end
	for _ in pairs(t2) do
		count2 = count2 + 1
	end
	if count1 ~= count2 then
		return false
	end

	-- compare all keys/values
	for k, v1 in pairs(t1) do
		local v2 = t2[k]
		if not deep_equal(v1, v2) then
			return false
		end
	end

	return true
end
return deep_equal
