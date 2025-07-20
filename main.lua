-- main.lua

local detect = require("detect")
local peripherals = detect.DetectPeripherals()
local queue = {}

while true do
    for _, drawer in ipairs(peripherals.storage) do
        print(drawer)
        local device = peripheral.wrap(drawer)
        local info = device.items()
        print(info)
        local count = info.count
        if count < 256 then
            if not queue[drawer] then
                queue[drawer] = {
                    name = info.name,
                    need = 256 - count,
                    state = "queued"
                }
            end
        end
    end
    for name, order in pairs(queue) do
        print(string.format("Order for %s: %d %s", name, order.need, order.name))
    end 
    
    sleep(5)
end
