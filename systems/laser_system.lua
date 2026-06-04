local LaserSystem = {}

-- Retorna hit (bool), dot (distância ao longo do raio até o centro do alvo)
local function testCircle(laser, rigidbody, dirX, dirY, radius)
  if not rigidbody or not rigidbody.body
  or rigidbody.body:isDestroyed() then return false, nil end

  local ax, ay = rigidbody.body:getPosition()
  local dx, dy = ax - laser.x, ay - laser.y
  local dot    = dx * dirX + dy * dirY

  if dot < -radius or dot > laser.range then return false, nil end

  local px      = dot * dirX
  local py      = dot * dirY
  local perpDist = math.sqrt((dx - px)^2 + (dy - py)^2)

  return perpDist < radius, dot
end

local function resolveHit(laser)
  if laser.hitX then return end

  local dirX = math.cos(laser.angle)
  local dirY = math.sin(laser.angle)
  local closest = nil
  local closestDot = math.huge

  -- Testa asteroides
  for _, ast in ipairs(config.Entities.getByTag("asteroid")) do
    local hit, dot = testCircle(laser, ast.rigidbody, dirX, dirY,
      ast.sprite.shape and ast.sprite.shape:getRadius() or 20)
    if hit and dot < closestDot then
      closest = { entity = ast, dot = dot, isAsteroid = true }
      closestDot = dot
    end
  end

  -- Testa naves (exceto o dono)
  for _, ship in ipairs(config.Entities.getByTag("ship")) do
    if ship ~= laser.owner then
      local radius = 25  -- aproximação; idealmente vem da def da nave
      local hit, dot = testCircle(laser, ship.rigidbody, dirX, dirY, radius)
      if hit and dot < closestDot then
        closest = { entity = ship, dot = dot, isAsteroid = false }
        closestDot = dot
      end
    end
  end

  -- Ponto de impacto (para o renderer)
  if closest then
    laser.hitX = laser.x + dirX * closestDot
    laser.hitY = laser.y + dirY * closestDot
    if closest.isAsteroid then
      config.MiningSystem.damage(closest.entity, laser.damage.hullDamage)
    else
      config.CombatSystem.apply(closest.entity, laser.damage.shieldDamage, laser.damage.hullDamage)
    end
  else
    laser.hitX = laser.x + dirX * laser.range
    laser.hitY = laser.y + dirY * laser.range
  end
end

function LaserSystem.update(dt)
  for _, laser in ipairs(config.Entities.getByTag("laser")) do
    laser.lifetime = laser.lifetime - dt
    if laser.lifetime <= 0 then
      config.Entities.remove(laser)
    else
      resolveHit(laser)
    end
  end
end

return LaserSystem
