local WorldManager = {}

WorldManager.currentSystemId = 1
WorldManager.systems = {}
WorldManager.snapshot = nil

function WorldManager.freeze()
  WorldManager.snapshot = {}
  for _, e in ipairs(config.Entities.all) do
    if  e.rigidbody and e.rigidbody.body then
      local vx, vy = e.rigidbody.body:getLinearVelocity()
      table.insert(WorldManager.snapshot, {
        entity = e,
        x      = e.rigidbody.body:getX(),
        y      = e.rigidbody.body:getY(),
        vx     = vx,
        vy     = vy,
        angle  = e.rigidbody.body:getAngle(),
        av     = e.rigidbody.body:getAngularVelocity(),
      })
      e.rigidbody.body:setActive(false)
    end
  end
end

function WorldManager.unfreeze()
  if not WorldManager.snapshot then return end
  for _, s in ipairs(WorldManager.snapshot) do
    if s.entity.rigidbody and s.entity.rigidbody.body then
      s.entity.rigidbody.body:setPosition(s.x, s.y)
      s.entity.rigidbody.body:setLinearVelocity(s.vx, s.vy)
      s.entity.rigidbody.body:setAngle(s.angle)
      s.entity.rigidbody.body:setAngularVelocity(s.av)
      s.entity.rigidbody.body:setActive(true)
    end
  end
  WorldManager.snapshot = nil
end

function WorldManager.loadSystem(systemId)
  local toRemove = {}
  for _, e in ipairs(config.Entities.all) do
    if e.tag ~= "player" and not e.isFlagShip then
      toRemove[#toRemove+1] = e
    end
  end
  for _, e in ipairs(toRemove) do
    config.Entities.remove(e)
  end

  WorldManager.currentSystemId = systemId

  local sys = WorldManager.systems[systemId]
  if not sys then
    print("WARNING: System "..systemId.." not defined!")
    return
  end

  config.StarEntity(sys.starX,sys.starY,sys.starMass,sys.starRadius,sys.starColor)

  local starList = config.Entities.getByTag("star")
  local star = starList[1]

  config.AsteroidEntity(star,sys.asteroidCount,sys.asteroidOres)

  config.LandableEntity(star,sys.landables)

  config.WormholeEntity(sys.wormholes)

  config.NpcEntity(500,300,"passive")

  config.Entities.sortByLayer()

  print("Loaded star system: " ..(sys.name or systemId))
end


return WorldManager
