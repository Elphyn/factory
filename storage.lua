-- storage.lua

function UpdateStorage(drawers)
    -- should return a table of available items, key(name) : table = {count, where}
    local items = {}
    for _, name in ipairs(drawers) do
        local device = peripheral.wrap(name)
        local table = device.items()[1]
        items[table.name] = {table.count, name}
    end
    return items
end

return {
    UpdateStorage = UpdateStorage
}