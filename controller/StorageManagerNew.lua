local EventEmitter = require("libs.EventEmitter")
local config = require("controller.StorageConfig")
local adapters = require("adapters.adapters")
local deepCopy = require("libs.deepCopy")

-- TODO: later when experimenting with advanced peripherals add check for which mod is currently being used
local integrationMod = "unlimited"

--- @class storageManager
local storageManager = {}
storageManager.__index = storageManager
setmetatable(storageManager, { __index = EventEmitter })

function storageManager.new(threader)
	local self = setmetatable(EventEmitter.new(threader), storageManager)
	self.storageUnits = {}
	self.items = {}
	self.itemLocations = {}
	self.sharedItemDetails = {}
	self.updateLock = false
	self.updating = false
	return self
end

-- TODO: as of now make it run once, then we can run it over and over, but for that we need to add check if peripheral is already in system
function storageManager:locatePeripherals()
	local storageUnitTypes = config.peripherals

	for _, unitType in ipairs(storageUnitTypes) do
		local p_list = { peripheral.find(unitType) }

		for _, p in ipairs(p_list) do
			local p_name = peripheral.getName(p)
			if not self.storageUnits[p_name] then
				local adapter = adapters[integrationMod][unitType].new(p_name, self.sharedItemDetails)
				self.storageUnits[p_name] = adapter
			end
		end
	end
end

function storageManager:start()
	self.threader:addThread(function()
		while true do
			if not self.updateLock then
				-- storage check
				self:runStorageCheck()
			end
			sleep(0.05)
		end
	end)
end

function storageManager:makeSnapshot()
	return deepCopy(self.items)
end

function storageManager:reset()
	self.items = {}
	self.itemLocations = {}
end

function storageManager:runStorageCheck()
	local oldItems = self:makeSnapshot()

	self.updating = true
	self:reset()
	self:fullScan()
	self.updating = false

	if self:totalsDiffer(oldItems) then
		self:signalChange()
	end
end

function storageManager:signalChange()
	self:emit("inventory_changed", self.items)
end

function storageManager:totalsDiffer(with)
	local compare = function(t1, t2)
		for k, v in pairs(t1) do
			if t2[k] ~= v then
				return false
			end
		end
		return true
	end

	return compare(self.items, with) and compare(with, self.items)
end

-- TODO: add capacity scan
function storageManager:fullScan()
	self:locatePeripherals()

	for p_name, adapter in pairs(self.storageUnits) do
		local items = adapter:getItems()

		for itemName, itemCount in pairs(items) do
			self.items[itemName] = (self.items[itemName] or 0) + itemCount

			if not self.itemLocations[p_name] then
				self.itemLocations[p_name] = {}
			end

			self.itemLocations[p_name][itemName] = (self.itemLocations[p_name][itemName] or 0) + itemCount
		end
	end
end

return storageManager
