local generateConfig = require("createConfig")

local function setupMain()
	os.setComputerLabel("MainPC")
	if fs.exists("startup.lua") then
		fs.delete("startup.lua")
	end

	if fs.exists("factory/startupMain.lua") then
		fs.copy("factory/startupMain.lua", "startup.lua")
	end
end

local function setupNode(stationType, bufferName)
	local pcLabel = string.format("worker:%s", stationType)
	os.setComputerLabel(pcLabel)

	if fs.exists("startup.lua") then
		fs.delete("startup.lua")
	end
	if fs.exists("fatory/worker/startup.lua") then
		fs.copy("factory/worker/startup.lua", "startup.lua")
	end
	-- if fs.exists("startup.lua") then
	-- 	fs.delete("startup.lua")
	-- end
	--
	-- if fs.exists("config.lua") then
	-- 	fs.delete("config.lua")
	-- end
	--
	-- if fs.exists("factory/startupNode.lua") then
	-- 	fs.copy("factory/startupNode.lua", "startup.lua")
	-- end
	generateConfig(stationType, bufferName)
end

local function setup()
	-- prompt if it's a main pc or a node
	print("Enter main | node to know which pc that is: ")
	local type = read()

	if type == "main" then
		setupMain()
	elseif type == "node" then
		-- if it's a node prompt as to which type of station it's going to manage
		print("Enter what type of station this pc should manage: ")
		local stationType = read()
		print("Enter a buffer peripheral name: ")
		local bufferName = read()
		setupNode(stationType, bufferName)
	else
		print("Wrong type, try again")
		setup()
	end
end

setup()
