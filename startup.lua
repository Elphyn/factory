-- first need to update
local clone = require("factory.upd")

if not fs.exists("downloads") then
	fs.makeDir("downloads")
end

if fs.exists("downloads/factory") then
	fs.delete("downloads/factory")
end

print("Updating...")
local ok, _ = pcall(function()
	clone("https://github.com/Elphyn/factory", "factoryNew")
end)
if not ok then
	print("Update failed, try to reboot")
	return
end
if fs.exists("factory") then
	fs.delete("factory")
end

if fs.exists("factoryNew") then
	fs.move("factoryNew", "factory")
else
	error("There's no copy of factory in downloads in startup")
end

if fs.exists("config.lua") then
	local pcType = require("config").pcType
	if pcType == "main" then
		shell.run("factory/controller/main.lua")
	elseif pcType == "node" then
		shell.run("factory/worker/main.lua")
	else
		error("Wrong type  of pc in config, on a startup")
	end
else
	print("Factory requires a setup")
end
