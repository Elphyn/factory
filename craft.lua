
-- order would look like: [drawer_name] = {resource_name, amount, state}

local recipes = require("recipes")
local storage = require("storage")
local detect = require("detect")



local drawers = detect.DetectPeripherals()[storage]
local available_items = storage.UpdateStorage(drawers)

local function Done(expected_regent, expected_amount, station_name) 
    local mill = peripheral.wrap(station_name)
    
    -- need to find regent table
    local function findIdx()
        for i, table in ipairs(mill.items()) do
            if table[i].name == expected_regent then
                return i
            end
        end
    end
    
    local idx = findIdx()
    local count = mill.items[idx].count
    if count < expected_amount then
        return false
    end
    return true

end

local function millCraft(order, station_name)
    local regent_crafting = order.what_to_craft
    local regent_needed = recipes[regent_crafting].items[1]

    
    local mill = peripheral.wrap(station_name)
    mill.pullItem(available_items[regent_needed].location, regent_needed, order.how_much)
    
    while not Done(regent_crafting, order.how_much, station_name) do
        coroutine.yield()
    end
    
    mill.pushItem(order.where_put, regent_crafting, order.how_much)
    print("Finished Order")
end


-- manual testing
local queue = {
    ["minecraft:gravel"] = {
        what_to_craft = "minecraft:gravel",
        how_much = 2,
        where_put = "extended_drawers:single_drawer_14",
        state = "queued"
    }
}

local co = coroutine.create(millCraft(queue["minecraft:gravel"], "craete:millstone_11"))

coroutine.resume(co)
coroutine.resume(co)