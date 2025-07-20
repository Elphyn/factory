
local list = peripheral.getNames()

local basins = {}

local i = 0
for _, device in ipairs(list) do
    if string.match(device, "^create:basin") then
        basins[i] = device
        i = i + 1
    end
end

for num, basin in ipairs(basin) do
    local line = string.format("%d Basin: %s", num, basin)
    print(line)
end
