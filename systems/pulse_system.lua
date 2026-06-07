local PulseSystem = {}

local function apply_emp(pulse, entity)
  if entity.generator then
    entity.generator.impaired = true
  end
end

local function apply_jam(pulse, entity)
  entity.weaponImpaired = true
end

local function apply_repulsion(pulse, entity)
  entity.rigidbody.body:applyForce(pulse.range,pulse.range)
end

local pulseEffects = {
  emp         = apply_emp,
  jam         = apply_jam,
  repulsion   = apply_repulsion,
}

local function resolveHit(ship_hash,pulse)
  local hitEntities = {}

  for _, ship in ipairs(config.SpatialHash.query(ship_hash, config.CELL_SIZE, pulse.x, pulse.y, pulse.range)) do
    if ship.owner == pulse.owner then break end
    table.insert(hitEntities, ship)
  end

  if #hitEntities > 0 then
    for _, entity in ipairs(hitEntities) do
      if entity.mineable then
        config.MiningSystem.damage(entity, pulse.damage.hullDamage)
      elseif pulse.damage then
        config.DamageSystem.apply(entity, pulse.damage.shieldDamage, pulse.damage.hullDamage)
      else
        local fn = pulseEffects[pulse.effect]
        if fn then fn(entity, pulse) end
      end
    end
  end
end

function PulseSystem.update(ship_hash, ast_hash,dt)
  for _, pulse in ipairs(config.Entities.getByTag("pulse")) do
    pulse.lifetime = pulse.lifetime - dt
    pulse.x, pulse.y = pulse.owner.rigidbody.body:getX(), pulse.owner.rigidbody.body:getY()
    if pulse.lifetime <= 0 then
      config.Entities.remove(pulse)
    else
      resolveHit(ship_hash,pulse)
    end
  end
end

return PulseSystem
