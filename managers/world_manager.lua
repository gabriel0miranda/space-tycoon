local WorldManager = {}

WorldManager.currentSystemId = 1
WorldManager.systems = {}

function WorldManager.loadSystem(systemId)
  for i = #Entities.all, 1, -1 do
    local e = Entities.all[i]
    if e.tag ~= "ship" then
      if e.rigidbody and e.rigidbody.body then
        e.rigidbody.body:destroy()
      end
      Entities.remove(e)
    end
  end

  WorldManager.currentSystemId = systemId

  local sys = WorldManager.systems[systemId]
  if not sys then
    print("WARNING: System "..systemId.." not defined!")
    return
  end

  Entities.create("star", {
    x = sys.starX or 0,
    y = sys.starY or 0,
    mass = sys.starMass or 50000,
    radius = sys.starRadius or 30,
    sprite = require("components.sprite")({1,1,1},love.physics.newCircleShape(sys.starRadius or 30), "Circle")
  })

  local starList = Entities.with("star")
  local star = starList[1]

  for i =1, sys.asteroidCount or 30 do
    local theta = love.math.random() * 2 * math.pi
    local r_min_sq = ASTEROID_MIN_RADIUS^2
    local r_max_sq = ASTEROID_MAX_RADIUS^2
    local r_sq = r_min_sq + love.math.random() * (r_max_sq - r_min_sq)
    local r = math.sqrt(r_sq)

    local x = star.x + r * math.cos(theta)
    local y = star.x + r * math.sin(theta)

    local GM = GRAVITY_CONSTANT * star.mass
    local circular_v = math.sqrt(GM/r)

    --local speed_factor = 0.72 + love.math.random() * 0.38
    local orbital_speed = circular_v --* speed_factor

    local vx = -math.sin(theta) * orbital_speed
    local vy = math.cos(theta) * orbital_speed

    local size = love.math.random(10,100)

    local rigidBody = {}
    rigidBody.body = love.physics.newBody(world, x, y, "dynamic")
    rigidBody.shape = love.physics.newCircleShape(size)
    rigidBody.fixture = love.physics.newFixture(rigidBody.body,rigidBody.shape)
    rigidBody.color = {70/100, 80/100, 59/100}

    rigidBody.body:setMass(((4/3)*math.pi*(size)^3)*170)
    rigidBody.body:setLinearVelocity(vx,vy)
    rigidBody.fixture:setRestitution(0.3)
    --rigidBody.body:setLinearDamping(0.12)
    rigidBody.body:setAngularDamping(0.8)

    Entities.create("asteroid", {
      x = x or 0,
      y = y or 0,
      rigidbody = require("components.rigidbody")(rigidBody.body),
      sprite = require("components.sprite")(rigidBody.color,rigidBody.shape,"Circle"),
      glow = 0,
    })
  end

  for _, data in ipairs(sys.landables or {}) do
    data.orbitRadius = math.sqrt((data.x - star.x)^2 + (data.y - star.y)^2)
    data.orbitAngle = math.atan2(data.y - star.y, data.x - star.x)
    data.orbitSpeed = 0.0008
    Entities.create("landable", data)
  end

  print("Loaded star system: " ..(sys.name or systemId))
end

return WorldManager
