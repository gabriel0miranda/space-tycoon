return function(faction,aggressiveTowardsPlayer)
  return {
    state                   = "idle",
    target                  = nil,
    timer                   = 0,
    faction                 = faction,
    aggressiveTowardsPlayer = aggressiveTowardsPlayer,
  }
end
