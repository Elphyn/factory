---@type fun(value: unknown, expected: type, name: string)
local assertType = dofile("factory/utils/assertType.lua")

---@alias itemDisplayName string
---
---@class itemDetails
---@field name itemName
---@field displayName itemDisplayName
---@field weight number
---@field itemLimit number
---
---
---@class itemDetailStore
---@field savedItems table<itemName, itemDetails>
---
local itemDetailStore = {}

itemDetailStore.__index = itemDetailStore

---@return itemDetailStore
function itemDetailStore.new()
	local self = setmetatable({}, itemDetailStore)
	self.savedItems = {}
	return self
end

---Checks whether the itemDetails are cached
---@param itemName string
---@return boolean
function itemDetailStore:isSaved(itemName)
	if self.savedItems[itemName] ~= nil then
		return true
	end
	return false
end

---Caches item details
---@param itemName itemName
---@param displayName itemDisplayName
---@param itemLimit number
---@param weight number
function itemDetailStore:saveDetails(itemName, displayName, itemLimit, weight)
	assertType(itemName, "string", "itemName")
	assertType(displayName, "string", "displayName")
	assertType(itemLimit, "number", "itemLimit")
	assertType(weight, "number", "weight")

	if self:isSaved(itemName) then
		return
	end

	---@type itemDetails
	local details = {
		name = itemName,
		displayName = displayName,
		itemLimit = itemLimit,
		weight = weight,
	}
	self.savedItems[itemName] = details
end

return itemDetailStore
