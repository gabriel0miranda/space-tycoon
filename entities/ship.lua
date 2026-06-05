return function(x, y, owner, flagShip, name, type, landedAt, weapons, cargo)
  local shipType = type or "PP-2340"
  local shipName = name or owner..'s ship #'
  local shipWeapons = weapons or config.Ships[type].weapons
  local def = config.Ships[shipType]

  local body = love.physics.newBody(config.World, x, y, "dynamic")
  local fixtures = {}

  for _, part in ipairs(def.parts) do
    local shape   = love.physics.newPolygonShape(unpack(part.points))
    local fixture = love.physics.newFixture(body, shape)
    fixture:setUserData(name)
    fixtures[#fixtures + 1] = { fixture = fixture, shape = shape, color = part.color }
  end

  body:setAngle(0)

  local entity = config.Entities.create('ship', {
    name             = shipName,
    type             = shipType,
    rigidbody        = config.RigidbodyComponent(body, fixtures[1].fixture),
    fixtures         = fixtures,   -- todas as partes ficam aqui
    inertiaDampeners = true,
    rcs              = true,
    owner            = owner,
    sprite           = { shipType = shipType },  -- sinaliza pro renderer que é multi-part
    movement         = config.MovementComponent(
                        def.movement.linearAcceleration,
                        def.movement.strafeAcceleration,
                        def.movement.angularAcceleration,
                        def.movement.linearDamping,
                        def.movement.angularDampingFactor
                    ),
    weapons          = config.WeaponComponent(shipWeapons),
    currentWeapon    = 1,
    generator        = config.GeneratorComponent(def.generatorPower),
    inventory        = config.InventoryComponent(def.cargo,cargo or {}),
    layer            = 2,
    persistent       = true,
    isFlagShip       = flagShip,
    landedAt         = landedAt,
  })
  fixtures[1].fixture:setUserData(entity)
  return entity
end
