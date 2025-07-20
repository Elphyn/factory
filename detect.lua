-- detect.lua

function DetectPeripherals()
    local list = peripheral.getNames()

    local peripherals = {
        basins = {},
        storage = {}
    } 


    for _, name in ipairs(list) do
        if string.match(name, "^create:basin") then
            peripherals.basins[name] = { state = "idle"}
        elseif string.match(name, "^extended_drawers:single_drawer") then
            table.insert(peripherals.storage, name)
        end

    end

    print("Basins: ")
    for name, _ in pairs(peripherals.basins) do
        print(name)
    end

    print("Storage: ")
    for _, name in ipairs(peripherals.storage) do
        print(name)
    end
    
    return peripherals
end

return {
    DetectPeripherals = DetectPeripherals
}