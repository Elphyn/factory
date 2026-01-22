local itemContext = require("libs.itemContext")
local supportedPeripherals = require("adapters.unlimited.supported_peripherals")

--- @class InventoryComponentUnlimited
local InventoryBase = {}
InventoryBase.__index = InventoryBase

function InventoryBase.new(p_name)
	assert(peripheral.isPresent(p_name), "Peripheral with name: " .. p_name .. " does not exist")
	assert(
		InventoryBase.allowedType(p_name),
		"Peripheral with name: " .. p_name .. " is not supported in UnlimitedPeripheralAPI"
	)

	local self = setmetatable({}, InventoryBase)
	self.name = p_name
	self.type = self:getType()
	return self
end

--- @private
function InventoryBase.allowedType(p_name)
	local typeList = peripheral.getType(p_name)

	-- in case returned type is single, it's a string
	if type(typeList) == "string" then
		if supportedPeripherals[type] then
			return true
		end
	end

	-- documentation on cc:tweaked isn't complete, need to shut the lsp here, more so on mod integrations
	---@diagnostic disable-next-line
	for _, type in pairs(typeList) do
		if supportedPeripherals[type] then
			return true
		end
	end

	return false
end

function InventoryBase:checkPresent()
	return peripheral.isPresent(self.name)
end

function InventoryBase:getType()
	-- after inital setup it's just simple getter
	if self.type then
		return self.type
	end

	-- initial setup

	local types = peripheral.getType(self.name)

	-- if getType returned just one type we get a string
	if type(types) == "string" then
		local type = types
		if supportedPeripherals[type] then
			return type
		end
	end

	-- documentation on cc:tweaked isn't complete, need to shut the lsp here, more so on mod integrations
	-- docs say you get a string, but you might get a table if there's more then one type
	---@diagnostic disable-next-line
	for _, type in pairs(types) do
		if supportedPeripherals[type] then
			return type
		end
	end

	error("[GUARDRAIL] inventory.getType for " .. self.name .. " has failed, something is very wrong")
end

function InventoryBase:getItems()
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

		if not itemContext.itemRegistered(itemName) then
			itemContext.registerItem(itemName, slotInfo.displayName, slotInfo.maxCount)
		end

		::continue::
	end

	return items, nil
end

return InventoryBase
