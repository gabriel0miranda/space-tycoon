return function(x, y, owner, flagShip, name, type)
  type = type or "PP-2340"
  name = name or owner..'s ship #'
  local def = config.Ships[type]

  local body = love.physics.newBody(config.World, x, y, "dynamic")
  local fixtures = {}

  for _, part in ipairs(def.parts) do
    local shape   = love.physics.newPolygonShape(unpack(part.points))
    local fixture = love.physics.newFixture(body, shape)
    fixture:setUserData(name)
    fixtures[#fixtures + 1] = { fixture = fixture, shape = shape, color = part.color }
  end

  body:setAngle(0)

  return config.Entities.create('ship', {
    name        = def.name,
    rigidbody = config.RigidbodyComponent(body, fixtures[1].fixture),
    fixtures  = fixtures,   -- todas as partes ficam aqui
    inertiaDampeners = true,
    rcs              = true,
    sprite      = { shipType = type },  -- sinaliza pro renderer que é multi-part
    movement    = config.MovementComponent(
      def.movement.linearAcceleration,
      def.movement.strafeAcceleration,
      def.movement.angularAcceleration,
      def.movement.linearDamping
    ),
    weapon      = config.WeaponComponent(def.weapons[1]),
    inventory   = config.InventoryComponent(def.cargo),
    layer       = 2,
    persistent  = true,
    isFlagShip  = true,
    landedAt    = nil,
  })
end
