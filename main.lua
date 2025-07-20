-- main.lua
--
local detect = require("detect")
local storage = require("storage")
local recipes = require("recipes")

local peripherals = detect.DetectPeripherals()

local available_items = storage.UpdateStorage(peripherals.storage)


local queue = {}
while true do
    -- ordering 
    term.clear()
    for _, drawer in ipairs(peripherals.storage) do
        local device = peripheral.wrap(drawer)
        local info = device.items()[1]
        local count = info.count
        if count < 256 then
            if not queue[drawer] and recipes[info.name] ~= nil then
                queue[drawer] = {
                    name = info.name,
                    need = 256 - count,
                    state = "queued"
                }
            end
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
