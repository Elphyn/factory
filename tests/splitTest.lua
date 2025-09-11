local split = dofile("../controller/even.lua")

local stations = {}

table.insert(stations, 1)
print(split(7, stations))
