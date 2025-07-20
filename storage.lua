-- storage.lua

function UpdateStorage(drawers)
    -- should return a table of available items, key(name) : table = {count, where}
    -- table : name = {count = how_much, location = name_of_peripheral}
    local items = {}
    for _, name in ipairs(drawers) do
        local device = peripheral.wrap(name)
        local table = device.items()[1]
        items[table.name] = {count = table.count, location= name}         
    end
    return items
end

return {
    UpdateStorage = UpdateStorage
}