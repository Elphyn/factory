local function splitN(total, stations)
	local total_stations = 0
	for _, s in ipairs(stations) do
		total_stations = total_stations + s
	end
	if total_stations == 0 then
		local z = {}
		for i = 1, #stations do
			z[i] = 0
		end
		return z
	end

	local assigned, frac, sum = {}, {}, 0
	for i, s in ipairs(stations) do
		local num = total * s
		local q = math.floor(num / total_stations)
		assigned[i] = q
		sum = sum + q
		frac[i] = num - q * total_stations -- integer "fraction"
	end

	local remainder = total - sum
	if remainder > 0 then
		local idx = {}
		for i = 1, #stations do
			idx[i] = i
		end
		table.sort(idx, function(i, j)
			if frac[i] == frac[j] then
				return stations[i] > stations[j]
			end
			return frac[i] > frac[j]
		end)
		for k = 1, remainder do
			assigned[idx[k]] = assigned[idx[k]] + 1
		end
	end
	return assigned
end

return splitN
