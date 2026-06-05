local EnergySystem = {}

function EnergySystem.update(entities, dt)
  for _, entity in ipairs(entities) do
    entity.weapons[entity.currentWeapon].capacitor.current = math.min(entity.weapons[entity.currentWeapon].capacitor.max, entity.weapons[entity.currentWeapon].capacitor.current + entity.generator.maxOutput * dt)
  end
end
return EnergySystem
