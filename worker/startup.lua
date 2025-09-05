local clone = require("factory.upd")
if fs.exists("factory") then
	fs.delete("factory")
end

print("Updating...")
clone("https://github.com/Elphyn/factory")
print("Update finished")

if fs.exists("factory/worker/main.lua") then
	shell.run("factory/worker/main.lua")
else
	print("Something went wrong, there's no main file")
end
