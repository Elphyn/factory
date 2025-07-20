-- detect.lua

function DetectPeripherals()
    local list = peripheral.getNames()

    local peripherals = {
        basins = {},
        storage = {},
        generators = {},
        mills = {}
    } 


    for _, name in ipairs(list) do
        if string.match(name, "^create:basin") then
            peripherals.basins[name] = { state = "idle"}
        elseif string.match(name, "^extended_drawers:single_drawer") then
            table.insert(peripherals.storage, name)
        elseif string.match(name, "^createcobblestone:cobblestone_generator") then
            table.insert(peripherals.generators, name)
        elseif string.match(name, "^create:millstone") then
            table.insert(peripherals.mills, name)
        end
    end
    

    return peripherals
end

return {
    DetectPeripherals = DetectPeripherals
}