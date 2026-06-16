local EnergySystem = {}

function EnergySystem.update(entities, dt)
  for _, entity in ipairs(entities) do
    if not entity.generator.disabled then
      entity.weapons[entity.currentWeapon].capacitor.current = math.min(entity.weapons[entity.currentWeapon].capacitor.max, entity.weapons[entity.currentWeapon].capacitor.current + entity.generator.maxOutput * dt)
      if not entity.shields.disabled and entity.shields.currentCooldown == 0 then
        entity.shields.currentCapacity = math.min(entity.shields.totalCapacity,entity.shields.currentCapacity+entity.generator.maxOutput*dt)
      else
        entity.shields.currentCooldown = math.max(0,entity.shields.currentCooldown - dt)
      end
    end
  end
end

return EnergySystem
