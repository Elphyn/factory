-- main.lua
--
local detect = require("detect")
local storage = require("storage")
local recipes = require("recipes")
local crafting = require("craft")
local peripherals = detect.DetectPeripherals()

local available_items = storage.UpdateStorage(peripherals.storage)


local queue = {}
local activeProcesses = {}
while true do
    -- ordering 
    term.clear()
    for _, drawer_name in ipairs(peripherals.storage) do
        local drawer = peripheral.wrap(drawer_name)
        local info = drawer.items()[1]
        local count = info.count
        local regent = info.name
        if count < 64 and recipes[regent] ~= nil and not queue[regent] then
            queue[regent] = {
                what_to_craft = regent,
                how_much = 64 - count,
                where_put = drawer_name,
                state = "queued"
            }
        end
    end

    for key, _ in pairs(peripherals) do
        print(string.format("P: %s | %d", key, #peripherals[key]))
    end
    -- logs
    for name, order in pairs(queue) do
        print(string.format("Order for %s: %d %s", name, order.need, order.name))
    end 
    
    -- processing orders

    sleep(5)
end
