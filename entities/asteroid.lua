return function(star,asteroidCount,asteroidOres)
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
