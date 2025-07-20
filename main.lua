

local detect = require("detect")
local peripherals = detect.DetectPeripherals()
local queue = {}

local function fmt(str, vars)
    return (str:gsub("{(.-)}", function(key)
        return tostring(vars[key] or "{"..key.."}")
    end))
end

while true do
    for _, drawer in ipairs(peripherals.storage) do
        local info = drawer.items()
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
    
    term.clear()
    for storage_unit, table in pairs(queue) do
        local line = fmt("Order for {storage_unit} | {table.count} {table.name}")
    end
    
    sleep(5)
end
