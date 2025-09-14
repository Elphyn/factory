local Queue = dofile("factory/shared/Queue.lua")
local function deepCopy(t)
	-- if it's not table, we don't need a deep copy
	if type(t) ~= "table" then
		return t
	end

	-- if table is queue we use specific methods
	if t._isQueue then
		return Queue.initFromTable(t:toTable())
	end

	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

return deepCopy
