local recipes = require("libs.recipes")

local GenericAdapter = {}
GenericAdapter.__index = GenericAdapter

--- @class GenericAdapter
function GenericAdapter.new(name, type)
	local self = setmetatable({}, GenericAdapter)
	assert(
		peripheral.isPresent(name),
		"Creation of station with name " .. name .. " has failed, no peripheral with that name present"
	)

	assert(recipes.stationTypes[type] ~= nil, "Creation of station with type " .. type .. " has failed, no such type")

	self.name = name
	self.type = type
	return self
end
