local WorldManager = {}

WorldManager.currentSystemId = 1
WorldManager.systems = {}
WorldManager.snapshot = nil

function WorldManager.freeze()
  WorldManager.snapshot = {}
  for _, e in ipairs(config.Entities.all) do
    if e.tag ~= "ship" and e.rigidbody and e.rigidbody.body then
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

local function createStars(starX,starY,starMass,starRadius,starColor)
  config.Entities.create("star", {
    x = starX or 0,
    y = starY or 0,
    mass = starMass or 50000,
    radius = starRadius or 30,
    sprite = config.SpriteComponent(starColor,love.physics.newCircleShape(starRadius or 30), "Circle"),
    layer = 0
  })
end

local function createAsteroids(star,asteroidCount,asteroidOres)
  for i =1, asteroidCount or 30 do
    local theta = love.math.random() * 2 * math.pi
    local r_min_sq = config.ASTEROID_MIN_RADIUS^2
    local r_max_sq = config.ASTEROID_MAX_RADIUS^2
    local r_sq = r_min_sq + love.math.random() * (r_max_sq - r_min_sq)
    local r = math.sqrt(r_sq)

    local x = star.x + r * math.cos(theta)
    local y = star.y + r * math.sin(theta)

    local GM = config.GRAVITY_CONSTANT * star.mass
    local circular_v = math.sqrt(GM/r)

    --local speed_factor = 0.72 + love.math.random() * 0.38
    local orbital_speed = circular_v --* speed_factor

    local vx = -math.sin(theta) * orbital_speed
    local vy = math.cos(theta) * orbital_speed

    local size = love.math.random(config.MIN_ASTEROID_SIZE,config.MAX_ASTEROID_SIZE)
    local stages = math.max(1, math.round and math.round or math.floor(
      ((size - config.MIN_ASTEROID_SIZE) / (config.MAX_ASTEROID_SIZE - config.MIN_ASTEROID_SIZE)) * config.MAX_STAGES
    ))

    local rigidBody = {}
    rigidBody.body = love.physics.newBody(config.World, x, y, "dynamic")
    rigidBody.shape = love.physics.newCircleShape(size)
    rigidBody.fixture = love.physics.newFixture(rigidBody.body,rigidBody.shape)
    rigidBody.fixture:setUserData("asteroid")
    local color = {99/100, 87/100, 67/100}

    rigidBody.body:setMass(((4/3)*math.pi*(size)^3)*170)
    rigidBody.body:setLinearVelocity(vx,vy)
    rigidBody.fixture:setRestitution(0.3)
    --rigidBody.body:setLinearDamping(0.12)
    rigidBody.body:setAngularDamping(0.8)

    config.Entities.create("asteroid", {
      x = x or 0,
      y = y or 0,
      rigidbody = config.RigidbodyComponent(rigidBody.body,rigidBody.fixture),
      sprite = config.SpriteComponent(color,rigidBody.shape,"Circle"),
      mineable = config.MineableComponent(stages,rigidBody.body:getMass(),size, 100, asteroidOres),
      glow = 0,
      layer = 1
    })
  end
end

local function createLandables(star,landables)
  for _, landable in ipairs(landables or {}) do
    local orbitRadius = math.sqrt((config.Landables[landable].x - star.x)^2 + (config.Landables[landable].y - star.y)^2)
    local orbitAngle = math.atan2(config.Landables[landable].y - star.y, config.Landables[landable].x - star.x)
    local sprite = config.SpriteComponent(config.Landables[landable].color,love.physics.newCircleShape(config.Landables[landable].x,config.Landables[landable].y,config.Landables[landable].radius),"Circle")
    local orbitSpeed = 0.0008
    local inventory = {}
    if config.Landables[landable].market then
      inventory = config.InventoryComponent(config.Landables[landable].market.capacity)
    end
    config.Entities.create("landable",{
      name=landable,
      x=config.Landables[landable].x,
      y=config.Landables[landable].y,
      radius=config.Landables[landable].radius,
      sprite=sprite,
      inventory=inventory,
      orbitRadius=orbitRadius,
      orbitAngle=orbitAngle,
      orbitSpeed=orbitSpeed,
      layer = 0
    })
  end
end

local function createWormholes(wormholes)
  for _, data in ipairs(wormholes or {}) do
    data.sprite = config.SpriteComponent({0.5, 0.8, 1}, love.physics.newCircleShape(data.x, data.y, 120), "Circle")
    data.radius = 100
    data.layer = 0
    config.Entities.create("landable", data)
  end
end

local function createNPC(x, y, faction)
  local rigidBody = {}
  rigidBody.body = love.physics.newBody(config.World, 400, 200, "dynamic")
  rigidBody.shape = love.physics.newPolygonShape(0, -25, 50, 0, 0, 25)
  rigidBody.fixture = love.physics.newFixture(rigidBody.body, rigidBody.shape)
  rigidBody.color = {95/255, 117/255, 94/255}
  rigidBody.body:setAngle(math.random())

  return config.Entities.add({
    x = x, y = y,
    tags = { "npc", faction },  -- "passive" ou "hostile"
    rigidbody = config.RigidbodyComponent(rigidBody.body,rigidBody.fixture),
    sprite = config.SpriteComponent(rigidBody.color, rigidBody.shape,"Polygon"),
    ai = {
      state = "idle",           -- estado atual da FSM
      target = nil,             -- entidade alvo
      timer = 0,                -- timer genérico (patrol, cooldown)
      faction = faction,
    },
    weapon = config.WeaponComponent(config.Weapons.laser),
  })
end

function WorldManager.loadSystem(systemId)
  for i = #config.Entities.all, 1, -1 do
    local e = config.Entities.all[i]
    if e.tag ~= "ship" then
      if e.rigidbody and e.rigidbody.body then
        e.rigidbody.body:destroy()
      end
      config.Entities.remove(e)
    end
  end

  WorldManager.currentSystemId = systemId

  local sys = WorldManager.systems[systemId]
  if not sys then
    print("WARNING: System "..systemId.." not defined!")
    return
  end

  createStars(sys.starX,sys.starY,sys.starMass,sys.starRadius,sys.starColor)

  local starList = config.Entities.with("star")
  local star = starList[1]

  createAsteroids(star,sys.asteroidCount,sys.asteroidOres)

  createLandables(star,sys.landables)

  createWormholes(sys.wormholes)

  createNPC(500,300)

  config.Entities.sort()

  print("Loaded star system: " ..(sys.name or systemId))
  return sorted
end


return WorldManager
