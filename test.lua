
local list = peripheral.getNames()

local basins = {}

i = 0
for _, device in ipairs(list) do
    if strings.match(device, "^create:basin") then
        basins[i] = device
        i = i + 1
    end
end

for num, basin in ipairs(basin) do
    line = string.format("%d Basin: %s", num, basin)
    print(line)
end
