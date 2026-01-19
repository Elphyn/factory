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

function Drawer.new(p_name, sharedCachedDetails)
	local self = setmetatable({}, Drawer)
	assert(peripheral.isPresent(p_name) == true, "StorageUnit with name: " .. p_name .. " does not exist")
	self.name = p_name
	self.cachedDetails = sharedCachedDetails
	self.totalCapacity = DEFAULT_DRAWER_CAPACITY
	self.currentCapacity = DEFAULT_DRAWER_CAPACITY
	self.singleSlotCapacity = 0
	self.items = {}
	self.numSlots = 0
	self:setup()
	return self
end

function Drawer:setup()
	local typeList = peripheral.getType(self.name)

	-- documentation on cc:tweaked isn't complete, need to shut the lsp here, more so on mod integrations
	---@diagnostic disable-next-line
	for _, type in pairs(typeList) do
		if DRAWER_TYPES[type] then
			local nSlots = DRAWER_TYPES[type]
			self.singleSlotCapacity = DEFAULT_DRAWER_CAPACITY / nSlots
			self.numSlots = nSlots
			return
		end
	end

	-- Impossible condition, should not happen, if triggered I did something wrong
	error("Drawer adapter setup failed")
end

function Drawer:gatherDetails(slotInfo)
	self.cachedDetails[slotInfo.name] = {
		displayName = slotInfo.displayName,
		maxCount = slotInfo.maxCount,
		-- TODO: not sure if I need weight anymore
		weight = 64 / slotInfo.maxCount,
	}
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
			self:gatherDetails(p)
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
