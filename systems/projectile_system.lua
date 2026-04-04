local ProjectileSystem = {}

local function handle_hit(proj, target)
  if target.mineable then
    config.MiningSystem.damage(target, proj.damage)
  end
  -- Futuramente: target.health, shields, etc.
  config.Entities.remove(proj)
end

local function update_homing(proj, ast_hash, dt)
  -- Míssil: busca o asteroide mais próximo
  local best, bestDist = nil, math.huge
  local candidates = config.SpatialHash.query(ast_hash, config.CELL_SIZE, proj.x, proj.y, proj.size + 20)
  for _, ast in ipairs(candidates) do
    if ast.rigidbody and ast.rigidbody.body and not ast.rigidbody.body:isDestroyed() then
      local ax, ay = ast.rigidbody.body:getPosition()
      local d = (ax-proj.x)^2 + (ay-proj.y)^2
      if d < bestDist then bestDist = d; best = ast end
    end
  end

  if not best then return end
  local ax, ay = best.rigidbody.body:getPosition()
  local targetAngle = math.atan2(ay - proj.y, ax - proj.x)
  local currentAngle = math.atan2(proj.vy, proj.vx)
  -- Rotaciona suavemente em direção ao alvo
  local diff = targetAngle - currentAngle
  -- Normaliza para [-pi, pi]
  while diff >  math.pi do diff = diff - 2*math.pi end
  while diff < -math.pi do diff = diff + 2*math.pi end
  local turn = math.min(math.abs(diff), proj.turnSpeed * dt)
  local newAngle = currentAngle + (diff > 0 and turn or -turn)
  local speed = math.sqrt(proj.vx^2 + proj.vy^2)
  proj.vx = math.cos(newAngle) * speed
  proj.vy = math.sin(newAngle) * speed
end

function ProjectileSystem.update(ast_hash, dt)
  local projectiles = config.Entities.with("projectile")

  for _, proj in ipairs(projectiles) do
    -- Homing
    if proj.homing then
      update_homing(proj, ast_hash, dt)
    end
    -- Move (projéteis simples não têm rigidbody, só posição)
    proj.x = proj.x + proj.vx * dt
    proj.y = proj.y + proj.vy * dt
    -- Lifetime
    proj.lifetime = proj.lifetime - dt
    if proj.lifetime <= 0 then
      config.Entities.remove(proj)
    else
      -- Colisão com asteroides
      local candidates = config.SpatialHash.query(ast_hash, config.CELL_SIZE, proj.x, proj.y, proj.size + 20)
      for _, ast in ipairs(candidates) do
        if ast.rigidbody and ast.rigidbody.body and not ast.rigidbody.body:isDestroyed() then
          local ax, ay = ast.rigidbody.body:getPosition()
          local r = (ast.sprite.shape and ast.sprite.shape:getRadius()) or 20
          local dx, dy = proj.x - ax, proj.y - ay
          if dx*dx + dy*dy < (r + proj.size)^2 then
            handle_hit(proj, ast)
            break
          end
        end
      end
    end
  end
end

return ProjectileSystem
