return function(capacity, items)
  return {
    capacity = capacity or 100,
    items = items or {},
    capacityUsed = 0,
    add = function(self, item, quantity, item_volume)
      local total = (item_volume or 1) * quantity
      if self.capacityUsed + total > self.capacity then
        local space = self.capacity - self.capacityUsed
        quantity = math.floor(space / (item_volume or 1))
        if quantity <= 0 then return false, "Full inventory" end
        total = (item_volume or 1) * quantity
      end
      self.items[item] = (self.items[item] or 0) + quantity
      self.capacityUsed = self.capacityUsed + total
      return true, quantity
    end,
    remove = function(self, item, quantity)
      if not self.items[item] or self.items[item] < quantity then
          return false, "No items"
      end
      self.items[item] = self.items[item] - quantity
      if self.items[item] == 0 then self.items[item] = nil end
      if config.Items[item].volume then
        self.capacityUsed = self.capacityUsed - (quantity * config.Items[item].volume)
      end
      self.capacityUsed = self.capacityUsed - quantity
      return true
    end,
    has = function(self, item, quantity)
      return (self.items[item] or 0) >= (quantity or 1)
    end
  }
end
