if fs.exists("factory/worker/main.lua") then
	shell.run("main.lua")
else
	print("Something went wrong, there's no main file")
end
