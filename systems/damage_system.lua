local DamageSystem = {}

function DamageSystem.apply(entity, shieldDamage, hullDamage)
  if entity.shields and entity.shields.currentCapacity > 0 then
    entity.shields.currentCapacity = math.max(entity.shields.currentCapacity-shieldDamage, 0)
    return
  end
  if entity.hull then
    entity.hull.currentHealth = entity.hull.currentHealth-hullDamage
  end
end

function DamageSystem.update(dt)
  for _, ship in ipairs(config.Entities.getByTag("ship")) do
    if ship.hull.currentHealth <= 0 then
      if ship.hull.currentHealth <= ship.hull.health*-1 then
        config.Entities.remove(ship)
      else
        ship.disabled = true
      end
    end
  end
end

return DamageSystem
