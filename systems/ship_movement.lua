local ShipMovement = {}

function ShipMovement.update(dt)
  local ships = config.Entities.with("ship")

  for _, ship in ipairs(ships) do
    if not ship.rigidbody or not ship.rigidbody.body then
      return
    end

    local rb = ship.rigidbody
    local mov = ship.movement
    local body = rb.body

    local angle = body:getAngle()

    local fx = math.cos(angle)
    local fy = math.sin(angle)

    local lx = math.sin(angle)
    local ly = -math.cos(angle)

    -- ====================== THRUST ======================
    if config.Input.up then
      body:applyForce(
        fx * mov.linearAcceleration,
        fy * mov.linearAcceleration
      )
    elseif config.Input.down then
      body:applyForce(
        -fx * mov.linearAcceleration,
        -fy * mov.linearAcceleration
      )
    end

    -- ====================== STRAFE ======================
    if config.Input.left then
      body:applyForce(
        lx * mov.strafeAcceleration,
        ly * mov.strafeAcceleration
      )
    end
    if config.Input.right then
      body:applyForce(
        -lx * mov.strafeAcceleration,
        -ly * mov.strafeAcceleration
      )
    end

    -- ====================== ROTATION ======================
    if config.Input.rotateLeft then
      ship.rcs = false
      body:applyTorque(-mov.angularAcceleration)
    elseif config.Input.rotateRight then
      ship.rcs = false
      body:applyTorque(mov.angularAcceleration)
    elseif config.Input.rcs then
      ship.rcs = true
      local I_approx = body:getMass() * (5 * 5 / 2)   -- approximate moment of inertia
      body:applyAngularImpulse(-I_approx * body:getAngularVelocity())
    end

    -- ====================== INERTIA DAMPENERS ======================
    if ship.inertiaDampeners then
      local vx, vy = body:getLinearVelocity()
      -- Gentle opposing force (you can tweak the 0.8 multiplier)
      body:applyForce(-vx * 0.2, -vy * 0.2)
    end

    if ship.weapon then
      ship.weapon.angle = body:getAngle()
      ship.weapon.firing = config.Input.fire_primary

    if config.Input.weapon_type == 1 then ship.weapon.def = config.Weapons.laser end
    if config.Input.weapon_type == 2 then ship.weapon.def = config.Weapons.machinegun end
    if config.Input.weapon_type == 3 then ship.weapon.def = config.Weapons.missile end
    if config.Input.weapon_type == 4 then ship.weapon.def = config.Weapons.drill end
    end
  end
end

return ShipMovement
