local DEFAULT_DRAWER_CAPACITY = 1024

local DRAWER_TYPES = {
	-- also it's not only types, but also how many slots each type has
	["extended_drawers:single_drawer"] = 1,
	["extended_drawers:double_drawer"] = 2,
	["extended_drawers:quad_drawer"] = 4,
}

-- Note:
-- Since as of now I am not implementing movement operations here then I don't need to remember where items are, only that I have them

--- @class drawerAdapter
local Drawer = {}
Drawer.__index = Drawer

function Drawer.new(p_name)
	local self = setmetatable({}, Drawer)
	self.name = p_name
	self.totalCapacity = DEFAULT_DRAWER_CAPACITY
	self.currentCapacity = DEFAULT_DRAWER_CAPACITY
	self.singleSlotCapacity = 0
	self.items = {}
	self.numSlots = 0
	self.inventory = require("adapters.inventory_unlimited").new(p_name, true)
	self:setup()
	return self
end

function Drawer:setup()
	local type = self.inventory:getType()

	assert(DRAWER_TYPES[type], "[GUARDRAIL] drawer setup failed, unkown type: " .. type)

	self.numSlots = DRAWER_TYPES[type]
	self.singleSlotCapacity = DEFAULT_DRAWER_CAPACITY / self.numSlots
end

function Drawer:resetInfo()
	self.currentCapacity = self.totalCapacity
	self.items = {}
end

function Drawer:update()
	local p = peripheral.wrap(self.name)
	if not p then
		return "local peripheral unreachable"
	end

	self:resetInfo()

	local itemInfo = p.items()
	for i = 1, self.numSlots do
		local slotInfo = itemInfo[i]
		if not slotInfo then
			goto continue
		end

		self.items[slotInfo.name] = (self.items[slotInfo.name] or 0) + slotInfo.count
		self.currentCapacity = self.currentCapacity - slotInfo.count

		if not self.cachedDetails[slotInfo.name] then
			self:gatherDetails(slotInfo)
		end

		::continue::
	end
	return nil
end

function Drawer:getItems()
	local err = self:update()
	if err then
		return {}, err
	end

	return self.items, nil
end

return Drawer
