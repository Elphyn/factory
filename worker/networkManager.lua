local NetworkManager = {}
NetworkManager.__index = NetworkManager

function NetworkManager.new(threader, EventEmitter)
	local self = setmetatable({}, NetworkManager)
	return self
end

function NetworkManager:listen() end
