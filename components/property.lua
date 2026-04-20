return function(properties)
  return {
    properties = properties or {},

    add = function(self, property)
      if not self.properties[property.name] then
        self.properties[property.name] = property
        return true
      end
      return false, "Property already owned"
    end,

    remove = function(self, property)
      if not self.properties[property.name] then
          return false, "Doesn't have property"
      end
      self.properties[property.name] = nil
      return true
    end,

    has = function(self, property)
      return self.properties[property.name] and true or false
    end,

    --countByType = function(self, propertyType)
    --  total = 0
    --  for _, property in ipairs(properties) do
    --    if property.type 
    --  end
    --end
  }
end
