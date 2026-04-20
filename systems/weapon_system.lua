local WeaponSystem = {}

-- ─────────────────────────────────────────
-- Funções de disparo (privadas)
-- ─────────────────────────────────────────

local function fire_projectile(owner, weapon, x, y, angle)
  local def = weapon.def
  local spread = (love.math.random() - 0.5) * def.spread
  local a = angle + spread
  local vx = math.cos(a) * def.speed
  local vy = math.sin(a) * def.speed

  if owner.rigidbody and owner.rigidbody.body then
    local ovx, ovy = owner.rigidbody.body:getLinearVelocity()
    vx = vx + ovx
    vy = vy + ovy
  end

  config.Entities.create("projectile", {
    x         = x,
    y         = y,
    vx        = vx,
    vy        = vy,
    lifetime  = def.lifetime,
    damage    = def.damage,
    size      = def.size,
    color     = def.color,
    projType  = def.type,
    owner     = owner,
    homing    = def.homing,
    turnSpeed = def.turnSpeed,
  })
end

local function fire_drill(owner, weapon, x, y, angle)
  local def = weapon.def
  local dirX = math.cos(angle)
  local dirY = math.sin(angle)

  for _, ast in ipairs(config.Entities.getByTag("asteroid")) do
    if ast.rigidbody and ast.rigidbody.body and not ast.rigidbody.body:isDestroyed() then
      local ax, ay = ast.rigidbody.body:getPosition()
      local dx, dy = ax - x, ay - y
      local radius = ast.sprite.shape and ast.sprite.shape:getRadius() or 20
      local dot = dx * dirX + dy * dirY
      if dot > -radius and dot < def.range then
        local px = dot * dirX
        local py = dot * dirY
        local perpDist = math.sqrt((dx - px)^2 + (dy - py)^2)
        if perpDist < radius then
          config.MiningSystem.damage(ast, def.damage)
        end
      end
    end
  end
end

-- ─────────────────────────────────────────
-- Intent API
-- ─────────────────────────────────────────

function WeaponSystem.newIntent()
  return {
    firing    = false,
    targetX   = nil,   -- se definido, aponta o disparo pra esse ponto
    targetY   = nil,
    weaponDef = nil,   -- nil = usa o weapon.def atual sem trocar
  }
end

-- Jogador escreve no intent via input
local function applyPlayerInput(e)
  local intent = e.weapon.intent
  local input  = config.Input.state

  intent.firing = input.fire_primary

  if input.weapon_type == 1 then intent.weaponDef = config.Weapons.laser      end
  if input.weapon_type == 2 then intent.weaponDef = config.Weapons.machinegun end
  if input.weapon_type == 3 then intent.weaponDef = config.Weapons.missile    end
  if input.weapon_type == 4 then intent.weaponDef = config.Weapons.drill      end

  -- Jogador atira na direção que a nave está apontando
  intent.targetX = nil
  intent.targetY = nil
end

-- Aplica o intent — executa o disparo se as condições batem
local function applyIntent(e, dt)
  local weapon = e.weapon
  local intent = weapon.intent

  -- Troca de arma se o intent pediu
  if intent.weaponDef then
    weapon.def = intent.weaponDef
  end

  -- Cooldown
  if weapon.timer > 0 then
    weapon.timer = weapon.timer - dt
  end

  local x, y
  if e.rigidbody and e.rigidbody.body then
    x, y = e.rigidbody.body:getPosition()
  else
    x, y = e.x or 0, e.y or 0
  end

  -- Ângulo: aponta pro target se definido, senão usa o ângulo do corpo
  local angle
  if intent.targetX and intent.targetY then
    angle = math.atan2(intent.targetY - y, intent.targetX - x)
  else
    angle = e.rigidbody and e.rigidbody.body:getAngle() or (weapon.angle or 0)
  end

  weapon.angle = angle

  if not intent.firing or weapon.timer > 0 then return end

  weapon.timer = weapon.def.cooldown

  if weapon.def.type == "drill" then
    fire_drill(e, weapon, x, y, angle)
  else
    fire_projectile(e, weapon, x, y, angle)
  end
end

-- ─────────────────────────────────────────
-- Update principal
-- ─────────────────────────────────────────

function WeaponSystem.update(armedEntities, dt)
  for _, e in ipairs(armedEntities) do
    if not e.weapon.intent then
      e.weapon.intent = WeaponSystem.newIntent()
    end

    -- Jogador escreve via input, NPC já escreveu no intent antes (no NpcAI)
    if e.isFlagShip then
      applyPlayerInput(e)
    end

    applyIntent(e, dt)
  end
end

return WeaponSystem
