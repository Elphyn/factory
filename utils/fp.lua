-- tooling module for functional programming
local M = {}

function M.map(table, fn)
	local result = {}
	for k, v in pairs(table) do
		result[k] = fn(v, k)
	end
	return result
end

function M.reduce(table, fn, initial)
	local acc = initial
	for _, v in pairs(table) do
		acc = fn(v, initial)
	end
	return acc
end

function M.filter(table, predictate)
	local result = {}
	for k, v in pairs(table) do
		if predictate(v, k) then
			result[k] = v
		end
	end
	return result
end

return M
