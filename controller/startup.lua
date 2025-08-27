if fs.exists("factory/controller/main.lua") then
	shell.run("factory/controller/main.lua")
else
	print("Something went wrong, there's no main file")
end
