local unpack = table.unpack or unpack

return function(start, playerName)
  playerName = playerName or start.name
  local property_owned = {}
  for _, property in ipairs(start.starting_property) do
    local x, y
    if property.ship then
      if config.Landables[start.starting_place] then
        x = config.Landables[start.starting_place].x
        y = config.Landables[start.starting_place].y
      else
        x = start.x
        y = start.y
      end
      local isFlagShip = property.flagShip or false
      local ship = config.ShipEntity(x, y, playerName, isFlagShip, property.name)
      for _, item in ipairs(property.cargo) do
        ship.inventory:add(item.name, item.quantity)
      end

      if property.landedAt then
        ship.landedAt = property.landedAt
      end

      table.insert(property_owned,ship)
    end
  end

  return config.Entities.create("player", {
    name      = playerName,
    property  = config.PropertyComponent(property_owned),
    credits          = config.CreditsComponent(start.starting_credits),
  })
end
