local unpack = table.unpack or unpack

return function(playerName, property)
  playerName = playerName or "Space Guy"
  property = property or {config.ShipEntity(300, 400, playerName, true)}

  return config.Entities.create("player", {
    name      = playerName,
    property  = config.PropertyComponent(property),
    credits          = config.CreditsComponent(1500),
  })
end
