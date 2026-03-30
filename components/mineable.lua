return function(stage, mass, radius, health, loot_table)
  return {
    originalRadius = radius,
    originalMass = mass,
    health     = health or 100,
    max_health = health or 100,
    loot_table = loot_table or { {item="Iron Ore", min=1, max=3} },
    stage = stage,
    debris     = {},
  }
end
