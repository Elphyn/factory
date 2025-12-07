--- A helper function aimed to check types of the parameters before running a function
--- made for safety
--- @alias paramName string
--- @param value unknown
--- @param expected type
--- @param name paramName
local function assertType(value, expected, name)
	assert(type(value) == expected, name .. " expected to be of type: " .. expected .. " got: " .. type(value))
end

return assertType
