-- first need to update
local clone = require("upd")
if fs.exists("factory") then
	fs.delete("factory")
end

print("Updating...")
clone("https://github.com/Elphyn/factory")
print("Update finished")

if fs.exists("factory/controller/main.lua") then
	shell.run("factory/controller/main.lua")
else
	print("Something went wrong, there's no main file")
end
