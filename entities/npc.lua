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
