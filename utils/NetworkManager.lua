local NetworkManager = {}
local buffer = require("config").bufferName
NetworkManager.__index = NetworkManager

function NetworkManager.new(eventEmitter, storageManager)
	local self = setmetatable({}, NetworkManager)
	self.eventEmitter = eventEmitter
	self.storageManager = storageManager
	self:setupEventListeners()
	return self
end

function NetworkManager:setupEventListeners()
	self.eventEmitter:subscribe("order-finished", function(...)
		self:onOrderDone(...)
	end)
end

function NetworkManager:listen()
	if not rednet.isOpen() then
		error("Rednet isn't open, can't listen")
	end
	local id, msg = rednet.receive()
	self:handleMessage(id, msg)
end

function NetworkManager:sendBuffer(id)
	local ok = rednet.send(id, buffer)
	if not ok then
		error("Wasn't able to send buffer " .. buffer .. " to " .. id)
	end
end

function NetworkManager:onOrderDone(order)
	-- there's no yeild of the craft yet so I dunno
	local info = {
		action = "order-finished",
		orderId = order.id,
		yeild = order.yeild,
	}
	local ok = rednet.send(order.senderId, info)
	if not ok then
		error("Couldn't send finished order back to mainPC")
	end
end

function NetworkManager:handleMessage(senderId, msg)
	if msg.action == "crafting-order" then
		self.eventEmitter:emit("crafting-order", msg)
	elseif msg.action == "get-stations" then
		self.eventEmitter:emit("get-stations", senderId)
	elseif msg.action == "get-buffer" then
		self:sendBuffer(senderId)
	elseif msg.action == "order-finished" then
	-- hmm
	else
		error("Unknown message recieved")
	end
end
