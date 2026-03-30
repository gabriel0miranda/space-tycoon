local WeaponSystem = {}

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

  Entities.create("projectile", {
    x        = x,
    y        = y,
    vx       = vx,
    vy       = vy,
    lifetime = def.lifetime,
    damage   = def.damage,
    size     = def.size,
    color    = def.color,
    projType = def.type,
    owner    = owner,
    homing   = def.homing,
    turnSpeed = def.turnSpeed,
  })
end

local function fire_drill(owner, weapon, x, y, angle)
    local def = weapon.def
    local dirX = math.cos(angle)
    local dirY = math.sin(angle)

    for _, ast in ipairs(Entities.with("asteroid")) do
        if ast.rigidbody and ast.rigidbody.body then
            local ax, ay = ast.rigidbody.body:getPosition()
            local dx, dy = ax - x, ay - y
            local radius = ast.sprite.shape and ast.sprite.shape:getRadius() or 20

            -- projeção sobre a direção do drill (já normalizada)
            local dot = dx * dirX + dy * dirY

            if dot > -radius and dot < def.range then
                -- ponto mais próximo na linha do drill
                local px = dot * dirX
                local py = dot * dirY

                -- distância perpendicular do asteroide ao raio
                local perpDist = math.sqrt((dx - px)^2 + (dy - py)^2)

                if perpDist < radius then
                    require("systems.mining").damage(ast, def.damage)
                end
            end
        end
    end
end

function WeaponSystem.update(dt)
  local armed = Entities.with("weapon")
  for _, e in ipairs(armed) do
    local weapon = e.weapon
    -- Faz o cooldown regredir
    if weapon.timer > 0 then
      weapon.timer = weapon.timer - dt
    end
    -- Só atira se o input mandou e o cooldown zerou
    if weapon.firing and weapon.timer <= 0 then
      weapon.timer = weapon.def.cooldown
      local x, y
      if e.rigidbody and e.rigidbody.body then
        x, y = e.rigidbody.body:getPosition()
      else
        x, y = e.x or 0, e.y or 0
      end
      if weapon.def.type == "drill" then
        fire_drill(e, weapon, x, y, weapon.angle)
      else
        fire_projectile(e, weapon, x, y, weapon.angle)
      end
    end
  end
end

return WeaponSystem
