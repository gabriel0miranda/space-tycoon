local EnergySystem = {}

function EnergySystem.update(entities, dt)
  for _, entity in ipairs(entities) do
    if entity.generator.disabled then goto continue end
    entity.weapons[entity.currentWeapon].capacitor.current = math.min(entity.weapons[entity.currentWeapon].capacitor.max, entity.weapons[entity.currentWeapon].capacitor.current + entity.generator.maxOutput * dt)
    ::continue::
  end
end
return EnergySystem
