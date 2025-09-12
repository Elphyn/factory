local split = dofile("../controller/even.lua")
local serialize = dofile("../utils/serialize.lua")

local stations = { [8] = 2, [2] = 1 }

local res = split(10, stations)

print(serialize(res))
