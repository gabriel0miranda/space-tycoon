local MineSystem = {}

local function resolveHit(ship_hash,ast_hash,mine)
  local hitEntities = {}

  for _, ship in ipairs(config.SpatialHash.query(ship_hash, config.CELL_SIZE, mine.x, mine.y, mine.range)) do
    if ship.owner == mine.owner then break end
    table.insert(hitEntities, ship)
  end
  for _, ast in ipairs(config.SpatialHash.query(ast_hash, config.CELL_SIZE, mine.x, mine.y, mine.range)) do
    table.insert(hitEntities, ast)
  end

  if #hitEntities > 0 then
    config.Entities.create("explosion",{
      color    = {1,0.2,0,0.4},
      x        = mine.x,
      y        = mine.y,
      radius   = mine.range,
      duration = 1,
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
      break
    end
    resolveHit(ship_hash,ast_hash,mine)
  end
end

return MineSystem
