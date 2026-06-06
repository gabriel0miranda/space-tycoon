local unpack = table.unpack or unpack

return function (x, y, profile, shipType, id)
  shipType = shipType or "PP-2340"
  local def = config.Ships[shipType]
  local cargo = {
    ["Cocaine"] = 12,
    ["Steel Sheets"] = 2,
  }

  config.Entities.create("npc", {
    profile = profile,
    id = id,
    ai = {
      state = "idle",           -- estado atual da FSM
      target = nil,             -- entidade alvo
      timer = 0,                -- timer genérico (patrol, cooldown)
      faction = profile.faction,
    },
    ship = config.ShipEntity(x, y, id, false, profile.ship, profile.ship, nil, config.Ships[profile.ship].weapons, cargo)
  })
end
