local EventEmitter = require("libs.EventEmitter")
local config = require("controller.StorageConfig")
local adapters = require("adapters.adapters")

-- TODO: later when experimenting with advanced peripherals add check for which mod is currently being used
local integrationMod = "unlimited"

--- @class storageManager
local storageManager = {}
storageManager.__index = storageManager
setmetatable(storageManager, { __index = EventEmitter })

function storageManager.new(threader)
	local self = setmetatable(EventEmitter.new(threader), storageManager)
	self.storageUnits = {}
	-- self.items = {}
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

			local adapter = adapters[integrationMod][unitType].new(p_name, self.sharedItemDetails)
			local storageUnit = {
				name = p_name,
				adapter = adapter,
			}
			table.insert(self.storageUnits, storageUnit)
		end
	end
end

-- For testing for now
function storageManager:scanUnits()
	print("Started scan")
	for _, storageUnit in ipairs(self.storageUnits) do
		local items, err = storageUnit.adapter:getItems()
		if err then
			error(err)
		end
		for itemName, itemCount in pairs(items) do
			print("Located item: " .. itemName .. "\n" .. "Count: " .. itemCount)
		end
	end
end

function storageManager:start()
	self.threader:addThread(function()
		while true do
			if not self.updateLock then
				self:scanUnits()
			end
			sleep(0.05)
		end
	end)
end

return storageManager
