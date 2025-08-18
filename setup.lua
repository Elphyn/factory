local function input() end

local function setupMain()
	print("Not yet done")
end

local function setupNode(stationType)
	local pcLabel = string.format("worker:%s", stationType)
	os.setComputerLabel(pcLabel)
	if fs.exists("factory/startupNode.lua") then
		fs.copy("factory/startupNode.lua", "startup.lua")
	end
	if fs.exists("factory/config.lua") then
		fs.copy("factory/config.lua", "config.lua")
	end
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
		setupNode(stationType)
	else
		print("Wrong type, try again")
		setup()
	end
end

setup()
