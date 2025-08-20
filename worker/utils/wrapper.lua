local function wrapper(func, ...)
	local args = { ... }
	return function()
		return func(table.unpack(args))
	end
end
return wrapper
