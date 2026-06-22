local WeaponSystem = {}

-- ─────────────────────────────────────────
-- Funções de disparo (privadas)
-- ─────────────────────────────────────────

local function fire_projectile(owner, weapon, x, y, angle)
  local def = weapon.def
  local weaponSpread = def.spread or 0
  local spread = (love.math.random() - 0.5) * weaponSpread
  local a = angle + spread
  local vx = math.cos(a) * def.speed
  local vy = math.sin(a) * def.speed

  if owner.rigidbody and owner.rigidbody.body then
    local ovx, ovy = owner.rigidbody.body:getLinearVelocity()
    vx = vx + ovx
    vy = vy + ovy
  end

  config.Entities.create("projectile", {
    x             = x,
    y             = y,
    vx            = vx,
    vy            = vy,
    lifetime      = def.lifetime,
    maxLifetime   = def.lifetime,
    damage        = def,
    size          = def.size or 3,
    color         = def.color,
    projType      = def.type,
    owner         = owner,
    homing        = def.homing,
    turnSpeed     = def.turnSpeed,
    range         = def.range
  })

  weapon.capacitor.current = 0
end

local function fire_mine(owner, weapon, x, y, angle)
  config.Entities.create("mine", {
    x               = x,
    y               = y,
    damage          = weapon.def,
    range           = weapon.def.range,
    color           = weapon.def.color,
    owner           = owner,
    armTime         = weapon.def.armTime,
    indicator       = {color = {0,0.3,0.7,0.2}}
  })

  weapon.capacitor.current = 0
end

local function fire_pulse(owner, weapon, x, y, angle)
  config.Entities.create("pulse", {
    x         = x,
    y         = y,
    lifetime  = weapon.def.lifetime,
    color     = weapon.def.color,
    range     = weapon.def.range,
    effect    = weapon.def.effect,
    owner     = owner,
    damage    = weapon.def.damage
  })

  weapon.capacitor.current = 0
end

local function fire_laser(owner, weapon, x, y, angle)
  config.Entities.create("laser", {
    x        = x,
    y        = y,
    angle    = angle,
    range    = weapon.def.range,
    damage   = weapon.def,
    color    = weapon.def.color,
    owner    = owner,
    lifetime = 0.02,
    hitX     = nil,
    hitY     = nil,
  })

  weapon.capacitor.current = weapon.capacitor.current - weapon.capacitor.drain
end

local fireFunctions = {
    projectile = fire_projectile,
    missile    = fire_projectile,
    laser      = fire_laser,
    mine       = fire_mine,
    pulse      = fire_pulse,
    drill      = fire_laser,
}

-- ─────────────────────────────────────────
-- Intent API
-- ─────────────────────────────────────────

function WeaponSystem.newIntent()
  return {
    firing    = false,
    targetX   = nil,   -- se definido, aponta o disparo pra esse ponto
    targetY   = nil,
    currentWeapon = nil,
  }
end

-- Jogador escreve no intent via input
local function applyPlayerInput(e)
  local intent = e.weapons_intent
  local input  = config.Input.state

  intent.firing = input.ship_fire

  if input.ship_weapon_1 then
    if e.weapons[1] then
      intent.currentWeapon = 1
    end
  end
  if input.ship_weapon_2 then
    if e.weapons[2] then
      intent.currentWeapon = 2
    end
  end
  if input.ship_weapon_3 then
    if e.weapons[3] then
      intent.currentWeapon = 3
    end
  end
  if input.ship_weapon_4 then
    if e.weapons[4] then
      intent.currentWeapon = 4
    end
  end
  if input.ship_weapon_5 then
    if e.weapons[5] then
      intent.currentWeapon = 5
    end
  end

  -- Jogador atira na direção que a nave está apontando
  intent.targetX = nil
  intent.targetY = nil
end

-- Aplica o intent — executa o disparo se as condições batem
local function applyIntent(e, dt)
  if e.disabled then return end
  local weapon = e.weapons[e.currentWeapon]
  local intent = e.weapons_intent

  -- Troca de arma se o intent pediu
  if intent.currentWeapon then
    e.currentWeapon = intent.currentWeapon
  end


  local x, y
  if e.rigidbody and e.rigidbody.body and not e.rigidbody.body:isDestroyed() then
    x, y = e.rigidbody.body:getPosition()
  else
    x, y = e.x or 0, e.y or 0
  end

  -- Ângulo: aponta pro target se definido, senão usa o ângulo do corpo
  local angle
  if intent.targetX and intent.targetY then
    angle = math.atan2(intent.targetY - y, intent.targetX - x)
  else
    angle = not e.rigidbody.body:isDestroyed() and e.rigidbody.body:getAngle() or (weapon.angle or 0)
  end

  weapon.angle = angle

  if not intent.firing then weapon.firing = intent.firing return end
  weapon.firing = intent.firing
  if weapon.capacitor.current < weapon.capacitor.max then return end

  local fn = fireFunctions[weapon.def.type]
  if fn then fn(e, weapon, x, y, angle) end

end

-- ─────────────────────────────────────────
-- Update principal
-- ─────────────────────────────────────────

function WeaponSystem.update(armedEntities, dt)
  for _, e in ipairs(armedEntities) do
    if not e.weapons_intent then
      e.weapons_intent = WeaponSystem.newIntent()
    end

    -- Jogador escreve via input, NPC já escreveu no intent antes (no NpcAI)
    if e.isFlagShip then
      applyPlayerInput(e)
    end

    applyIntent(e, dt)
  end
end

return WeaponSystem
