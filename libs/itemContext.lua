--- @class itemDetailStorage
local ItemContext = {
	displayNames = {},
	maxCounts = {},
}

function ItemContext.itemRegistered(itemName)
	return ItemContext.displayNames[itemName] ~= nil
end

function ItemContext.registerItem(itemName, displayName, maxCount)
	if ItemContext.itemRegistered(itemName) then
		return
	end

	ItemContext.displayNames[itemName] = displayName
	ItemContext.maxCounts[itemName] = maxCount
end

function ItemContext.getDisplayName(itemName)
	return ItemContext.displayNames[itemName]
end

function ItemContext.getMaxCount(itemName)
	return ItemContext.maxCounts[itemName]
end

return ItemContext
