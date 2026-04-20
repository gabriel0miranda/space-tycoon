local unpack = table.unpack or unpack

return function (x, y, faction, shipType)
  shipType = shipType or "PP-2340"
  local def = config.Ships[shipType]

  local body = love.physics.newBody(config.World,x,y,"dynamic")
  local fixtures = {}

  for _, part in ipairs(def.parts) do
    local shape = love.physics.newPolygonShape(unpack(part.points))
    local fixture = love.physics.newFixture(body,shape)
    fixture:setUserData("npc")
    fixtures[#fixtures+1] = { fixture= fixture, shape= shape, color= part.color }
  end

  body:setAngle(math.random())

  return config.Entities.create("npc",{
    x = x, y = y,
    rigidbody = config.RigidbodyComponent(body,fixtures[1].fixture),
    fixtures = fixtures,
    sprite = { shipType = shipType },
    movement  = config.MovementComponent(
      def.movement.linearAcceleration,
      def.movement.strafeAcceleration,
      def.movement.angularAcceleration,
      def.movement.linearDamping
    ),
    ai = {
      state = "idle",           -- estado atual da FSM
      target = nil,             -- entidade alvo
      timer = 0,                -- timer genérico (patrol, cooldown)
      faction = faction,
    },
    weapon = config.WeaponComponent(config.Weapons.laser),
    layer = 2,
  })
end
