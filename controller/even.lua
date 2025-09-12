local function splitN(total, stations)
	-- calculate total stations
	local total_stations = 0
	for _, s in pairs(stations) do
		total_stations = total_stations + s
	end

	-- no stations -> return zeroes for all keys
	if total_stations == 0 then
		local z = {}
		for k in pairs(stations) do
			z[k] = 0
		end
		return z
	end

	local assigned, frac, sum = {}, {}, 0
	for k, s in pairs(stations) do
		local num = total * s
		local q = math.floor(num / total_stations)
		assigned[k] = q
		sum = sum + q
		frac[k] = num - q * total_stations
	end

	local remainder = total - sum
	if remainder > 0 then
		-- collect keys
		local idx = {}
		for k in pairs(stations) do
			table.insert(idx, k)
		end
		-- sort by frac (desc), tie-break by station count (desc)
		table.sort(idx, function(i, j)
			if frac[i] == frac[j] then
				return stations[i] > stations[j]
			end
			return frac[i] > frac[j]
		end)
		-- distribute leftover
		for r = 1, remainder do
			local key = idx[r]
			assigned[key] = assigned[key] + 1
		end
	end

	return assigned
end

return splitN
