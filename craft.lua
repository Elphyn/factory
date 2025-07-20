
-- order would look like: [drawer_name] = {resource_name, amount, state}

local recipes = require("recipes")

local function findResource(storage, name)
    return storage[name].location
end

local function millFinished(station_name, resource_name, expected)
    local mill = peripheral.wrap(station_name)
    local table = mill.items()

    -- first fine resource
    local function findIdx(table)
        for i, item_info in ipairs(table) do
            if item_info.name == resource_name then
                return i
            end
        end
    end
    local idx = findIdx(table)
    local cur_count = table.items[idx].count
    if cur_count == expected then
        return true
    end
    return false

end

local function millCraft(order, station_name)
    return coroutine.create(function()
        local resource_name = order.name
        local mill = peripheral.wrap(station_name)
        
        local reagent = recipes["minecraft:gravel"].items[1]
        mill.pullItem(findResource(reagent), reagent, order.count)
        
        while not millFinished(station_name, resource_name, order.count) do
            coroutine.yield()
        end
        
        mill.pushItem(order.location, resource_name, order.count)
        order.state = "done"
    end)
end

local activeCoroutines = {}
-- here it should chunk it into smaller orders
function Craft(order, storage, station_type) 
    if station_type == "mill" then
        local co = millCraft(order)
        table.insert(activeCoroutines, co)
        millCraft()
    end
end


return {
    Craft = Craft
}