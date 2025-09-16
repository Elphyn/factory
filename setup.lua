local generateConfig = require("createConfig")
local stationBlocks = require("worker.stationBlocks")

local function validateInput(reference, input)
	if reference[input] then
		return true, input
	end
	return false, input
end

local function prompt(validOptions, string)
	while true do
		term.clear()
		term.setCursorPos(1, 1)
		print("--------------------------------------------")
		print(string)
		local ok, input = validateInput(validOptions, read())
		if ok then
			return input
		end
		print(input .. " isn't a valid option, try again")
	end
end

local function collectInputForNode(table)
	local getKeySet = require("utils.getKeysSet")
	local getValueSet = require("utils.getValueSet")

	local validStationTypes = getKeySet(stationBlocks)
	table.stationType = prompt(validStationTypes, "Enter what type of station this pc should manage: ")

	local peripherals = peripheral.list()
	local validPeripherals = getValueSet(peripherals)
	table.bufferName = prompt(validPeripherals, "Enter a buffer peripheral name(local): ")
	table.bufferNameGlobal = prompt(validPeripherals, "Enter a buffer peripheral name(global): ")
end

local function setup()
	local configInput = {}

	-- prompt if it's a main pc or a node
	configInput.pcType = prompt({ ["main"] = true, ["node"] = true }, "Is this pc a mainPC, or a nodePC?: ")

	local validModemLocations = {
		["top"] = true,
		["bottom"] = true,
		["back"] = true,
		["front"] = true,
		["left"] = true,
		["right"] = true,
	}
	table.modemLocation = prompt(validModemLocations, "Enter modem location:")

	if configInput.pcType == "main" then
		-- collectInputMain(configInput) -- later add for a monitor setup
		os.setComputerLabel("MainPC")
	elseif configInput.pcType == "node" then
		collectInputForNode(configInput)
		local pcLabel = string.format("worker:%s", configInput.stationType)
		os.setComputerLabel(pcLabel)
	else
		error("Something gone wrong, wrong pcType")
	end
	generateConfig(configInput, "config.lua")

	if fs.exists("startup.lua") then
		fs.delete("startup.lua")
	end
	fs.copy("factory/startup.lua", "startup.lua")
end

setup()
