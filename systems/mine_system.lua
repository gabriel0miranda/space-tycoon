local MineSystem = {}

local function resolveHit(ship_hash, ast_hash, mine)
  local hitEntities = {}
  local range2 = mine.range * mine.range

  local function inRange(entity)
    local ex, ey
    if entity.rigidbody and entity.rigidbody.body then
      ex, ey = entity.rigidbody.body:getPosition()
    else
      ex, ey = entity.x, entity.y
    end
    local dx, dy = ex - mine.x, ey - mine.y
    return dx*dx + dy*dy <= range2
  end

  for _, ship in ipairs(config.SpatialHash.query(ship_hash, config.CELL_SIZE, mine.x, mine.y, mine.range)) do
    if ship ~= mine.owner and inRange(ship) then  -- continue em vez de break
      table.insert(hitEntities, ship)
    end
  end

  for _, ast in ipairs(config.SpatialHash.query(ast_hash, config.CELL_SIZE, mine.x, mine.y, mine.range)) do
    if inRange(ast) then
      table.insert(hitEntities, ast)
    end
  end

  if #hitEntities > 0 then
    config.Entities.create("explosion", {
      color    = {1, 0.2, 0, 0.4},
      x        = mine.x,
      y        = mine.y,
      radius   = mine.range,
      duration = 1,
      maxDuration = 1,
    })
    for _, entity in ipairs(hitEntities) do
      if entity.mineable then
        config.MiningSystem.damage(entity, mine.damage.hullDamage)
      else
        config.DamageSystem.apply(entity, mine.damage.shieldDamage, mine.damage.hullDamage)
      end
    end
    config.Entities.remove(mine)
  end
end

function MineSystem.update(ship_hash, ast_hash,dt)
  for _, mine in ipairs(config.Entities.getByTag("mine")) do
    if mine.armTime and mine.armTime > 0 then
      mine.armTime = mine.armTime - dt
      goto continue
    end
    resolveHit(ship_hash, ast_hash, mine)
    ::continue::
  end
end

return MineSystem
