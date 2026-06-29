return function(start, playerName)
  playerName = playerName ~= "" and playerName or start.name
  local property_owned = {}
  for _, property in ipairs(start.starting_property) do
    table.insert(property_owned,property)
  end

  return config.Entities.create("player", {
    name      = playerName,
    property  = config.PropertyComponent(property_owned),
    credits          = config.CreditsComponent(start.starting_credits),
    x         = start.x or config.Landables[start.starting_place].x,
    y         = start.y or config.Landables[start.starting_place].y,
    landedAt  = start.landedAt,
    startingScenario = start
  })
end
