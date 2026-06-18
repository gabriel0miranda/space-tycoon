local EnergySystem = {}

local routingModes = {
  "balanced",
  "weaponPriority",
  "shieldsOnly"
}

local function nextRoutingMode(currentMode)
  for i, mode in ipairs(routingModes) do
    if mode == currentMode then
      return routingModes[(i % #routingModes) + 1]
    end
  end
  return routingModes[1]
end

function EnergySystem.update(entities, dt)
  for _, entity in ipairs(entities) do
    local weaponDrain = 0
    local shieldDrain = 0
    local currentWeapon = entity.weapons[entity.currentWeapon]

    if entity.owner == config.Entities.getByTag("player")[1].name then
      if config.Input.state.ship_generator_switch_mode then
        entity.generator.routingMode = nextRoutingMode(entity.generator.routingMode)
      end
    end

    if not entity.generator.disabled and currentWeapon.capacitor.current <= currentWeapon.capacitor.max then
      if entity.generator.routingMode == "balanced" then
        weaponDrain = entity.generator.maxOutput/2
        shieldDrain = 0
      elseif entity.generator.routingMode == "weaponPriority" then
        weaponDrain = currentWeapon.capacitor.max <= entity.generator.maxOutput and currentWeapon.capacitor.max or entity.generator.maxOutput
      elseif entity.generator.routingMode == "shieldsOnly" then
        shieldDrain = entity.generator.maxOutput
        weaponDrain = 0
        currentWeapon.capacitor.current = 0
      end

      if currentWeapon.capacitor.current == currentWeapon.capacitor.max then weaponDrain = 0 end

      currentWeapon.capacitor.current = math.min(currentWeapon.capacitor.max, currentWeapon.capacitor.current + weaponDrain)
      if not entity.shields.disabled and entity.shields.currentCooldown == 0 and entity.shields.currentCapacity < entity.shields.totalCapacity then
        shieldDrain = entity.generator.maxOutput - weaponDrain
        entity.shields.currentCapacity = math.min(entity.shields.totalCapacity, entity.shields.currentCapacity + (shieldDrain*dt))
      else
        entity.shields.currentCooldown = math.max(0, entity.shields.currentCooldown - dt)
        shieldDrain = 0
      end
    end
    entity.generator.currentOutput = weaponDrain + shieldDrain
  end
end

return EnergySystem
