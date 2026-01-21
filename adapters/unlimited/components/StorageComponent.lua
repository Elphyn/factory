local itemContext = require("libs.itemContext")

--- @class StorageComponentUnlimited
local StorageComponent = {}
StorageComponent.__index = StorageComponent

-- set of peripheral types that can use this class
local allowedTypes = {
	["create:basin"] = true,
	["create:depot"] = true,
	["create:millstone"] = true,
	["extended_drawers:single_drawer"] = true,
	["extended_drawers:double_drawer"] = true,
	["extended_drawers:quad_drawer"] = true,
}

function StorageComponent.new(p_name)
	assert(peripheral.isPresent(p_name), "peripheral with name: " .. p_name .. " does not exist")
	assert(StorageComponent.checkType(p_name), "InventoryAdapter_unlimited isn't supported for peripheral " .. p_name)

	local self = setmetatable({}, StorageComponent)
	self.name = p_name
	return self
end

--- @private
function StorageComponent.checkType(p_name)
	local typeList = peripheral.getType(p_name)

	-- in case returned type is single, it's a string
	if type(typeList) == "string" then
		return allowedTypes[typeList]
	end

	-- documentation on cc:tweaked isn't complete, need to shut the lsp here, more so on mod integrations
	---@diagnostic disable-next-line
	for _, type in pairs(typeList) do
		if allowedTypes[type] then
			return true
		end
	end

	return false
end

-- TODO: should move into general peripheral class
function StorageComponent:checkPresent()
	return peripheral.isPresent(self.name)
end

-- TODO: this probably should be handled up a few layers
function StorageComponent:getType()
	local types = peripheral.getType(self.name)

	-- if getType returned just one type we get a string
	if type(types) == "string" then
		local type = types
		if allowedTypes[type] then
			return type
		end
	end

	-- documentation on cc:tweaked isn't complete, need to shut the lsp here, more so on mod integrations
	-- docs say you get a string, but you might get a table if there's more then one type
	---@diagnostic disable-next-line
	for _, type in pairs(types) do
		if allowedTypes[type] then
			return type
		end
	end

	error("[GUARDRAIL] inventory.getType for " .. self.name .. " has failed, something is very wrong")
end

function StorageComponent:getItems()
	local p = peripheral.wrap(self.name)
	if not p then
		return {}, "local peripheral unreachable"
	end

	local iteminfo = p.items()

	local items = {}
	for index, slotInfo in ipairs(iteminfo) do
		if not slotInfo then
			goto continue
		end

		local itemName = slotInfo.name
		local itemCount = slotInfo.count

		items[index] = {
			name = itemName,
			count = itemCount,
		}

		if not itemContext.itemRegisterd(itemName) then
			itemContext.registerItem(itemName, slotInfo.displayName, slotInfo.maxCount)
		end

		::continue::
	end

	return items, nil
end

return StorageComponent
