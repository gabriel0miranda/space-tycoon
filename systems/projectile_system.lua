local ProjectileSystem = {}

local function handle_hit(proj, target)
  if target.mineable then
    config.MiningSystem.damage(target, proj.damage.hullDamage)
  else
    config.DamageSystem.apply(target, proj.damage.shieldDamage, proj.damage.hullDamage)
  end
  -- Futuramente: target.health, shields, etc.
  config.Entities.remove(proj)
end

local function update_homing(proj, ship_hash, dt)
  -- Míssil: busca o alvo mais próximo
  local best, bestDist = nil, math.huge
  local candidates = config.SpatialHash.query(ship_hash, config.CELL_SIZE, proj.x, proj.y, proj.size + proj.range)
  for _, ship in ipairs(candidates) do
    if ship.rigidbody and ship.rigidbody.body and not ship.rigidbody.body:isDestroyed() and ship ~= proj.owner then
      local ax, ay = ship.rigidbody.body:getPosition()
      local d = (ax-proj.x)^2 + (ay-proj.y)^2
      if d < bestDist then bestDist = d; best = ship end
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

function ProjectileSystem.update(ship_hash, ast_hash, dt)
  local projectiles = config.Entities.getByTag("projectile")

  for _, proj in ipairs(projectiles) do
    -- Homing
    if proj.homing then
      update_homing(proj, ship_hash, dt)
    end
    -- Move (projéteis simples não têm rigidbody, só posição)
    proj.x = proj.x + proj.vx * dt
    proj.y = proj.y + proj.vy * dt
    -- Lifetime
    proj.lifetime = proj.lifetime - dt
    if proj.lifetime <= 0 then
      config.Entities.remove(proj)
    else
      -- Colisão
      local candidates = config.TableConcat.concat(config.SpatialHash.query(ast_hash, config.CELL_SIZE, proj.x, proj.y, proj.size + 20),config.SpatialHash.query(ship_hash, config.CELL_SIZE, proj.x, proj.y, proj.size + 20))
      for _, entity in ipairs(candidates) do
        if entity.rigidbody and entity.rigidbody.body and not entity.rigidbody.body:isDestroyed() then
          if entity.owner and entity.owner == proj.owner.owner then break end
          local ax, ay = entity.rigidbody.body:getPosition()
          local r = (entity.sprite.shape and entity.sprite.shape:getRadius()) or 20
          local dx, dy = proj.x - ax, proj.y - ay
          if dx*dx + dy*dy < (r + proj.size)^2 then
            handle_hit(proj, entity)
            break
          end
        end
      end
    end
  end
end

return ProjectileSystem
