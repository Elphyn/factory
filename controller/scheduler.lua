local recipes = dofile("factory/shared/recipes.lua")
local deepCopy = dofile("factory/utils/deepCopy.lua")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(storageManager)
	local self = setmetatable({}, Scheduler)
  self.nextId = 1
	self.queue = {}
  -- the plan is to insert items that are crafting right now
  -- to stop any new entries of the same items appearing in queue 
  -- insert should probably be done by event handler, event would be
  -- emitted by NetworkManager, once order would be sent to Node
  self.itemsProcessing = {} -- poor man's set 
	storageManager:subscribe(function()
		self:planCrafts(storageManager:getItems())
	end, "inventory_changed")
	return self
end

function Scheduler:planCrafts(storage)
	-- placeholders for now, the logic would be different in a bit
	-- checking if I should add or not should depend on things we actually craft
	-- meaning it's a job of NetworkManager, which I didn't made yet

  -- removing entries that aren't processed, so we can recalculate
  for id, entry in pairs(self.queue) do
    if entry.state == "waiting" then
      self.queue[id] = nil
    end
  end

  
	local items = deepCopy(storage)
	for item, recipe in pairs(recipes) do
    if not self.itemsProcessing[item] then   
      -- if we don't have anything queued for this item
      local maxCraft = recipe.craftingLimit - (items[item] and items[item].total or 0)
      if maxCraft <= 0 then
        goto continue
      end
      for itemReq, ratio in pairs(recipe.dependencies) do
        local stock = items[itemReq] and items[itemReq].total or 0
        local maxByIngridient = math.floor(stock / ratio)
        if maxByIngridient == 0 then
          goto continue
        end
        if maxCraft > maxByIngridient then
          maxCraft = maxByIngridient
        end
      end
      for itemReq, ratio in pairs(recipe.dependencies) do
        items[itemReq].total = items[itemReq].total - maxCraft * ratio
      end
      local id = self.nextId
      self.nextId = self.nextId + 1
      self.queue[id]= { name = item, count = maxCraft, state = "waiting" }
      ::continue::
      
    end
	end
	return self.queue
end

function Scheduler:getQueue()
	return self.queue
end

return Scheduler
