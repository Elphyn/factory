local InventoryBase = require("adapters.unlimited.components.InventoryBase")

--- @class drawerAdapter
local Drawer = {}
Drawer.__index = Drawer
setmetatable(Drawer, { __index = InventoryBase })

function Drawer.new(p_name)
	local self = InventoryBase.new(p_name)
	setmetatable(self, Drawer)
	return self
end

return Drawer
