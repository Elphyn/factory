local generateConfig = require("createConfig")

local function setupMain()
	os.setComputerLabel("MainPC")
	if fs.exists("startup.lua") then
		fs.delete("startup.lua")
	end

	if fs.exists("factory/controller/startup.lua") then
		fs.copy("factory/controller/startup.lua", "startup.lua")
	end
end

local function collectInputForNode()
	local collected = {
		modemLocation = "top", -- a default for now
	}
	print("Enter what type of station this pc should manage: ")
	collected.stationType = read()
	print("Enter a buffer peripheral name(local): ")
	collected.bufferName = read()
	print("Enter a buffer peripheral name(global): ")
	collected.bufferNameGlobal = read()

	return collected
end

local function setupNode()
	local config = collectInputForNode()
	local pcLabel = string.format("worker:%s", config.stationType)
	os.setComputerLabel(pcLabel)

	if fs.exists("startup.lua") then
		fs.delete("startup.lua")
	end
	if fs.exists("factory/worker/startup.lua") then
		fs.copy("factory/worker/startup.lua", "startup.lua")
	end
	generateConfig(config)
end

local function setup()
	-- prompt if it's a main pc or a node
	print("Enter main | node to know which pc that is: ")
	local type = read()

	if type == "main" then
		setupMain()
	elseif type == "node" then
		setupNode()
	else
		print("Wrong type, try again")
		setup()
	end
end

setup()
