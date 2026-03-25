local ShipMovement = {}

function ShipMovement.update(dt)
  local ships = Entities.with("ship")

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
    if input.up then
      body:applyForce(
        fx * mov.linearAcceleration,
        fy * mov.linearAcceleration
      )
    elseif input.down then
      body:applyForce(
        -fx * mov.linearAcceleration,
        -fy * mov.linearAcceleration
      )
    end

    -- ====================== STRAFE ======================
    if input.left then
      body:applyForce(
        lx * mov.strafeAcceleration,
        ly * mov.strafeAcceleration
      )
    end
    if input.right then
      body:applyForce(
        -lx * mov.strafeAcceleration,
        -ly * mov.strafeAcceleration
      )
    end

    -- ====================== ROTATION ======================
    if input.rotateLeft then
      ship.rcs = false
      body:applyTorque(-mov.angularAcceleration)
    elseif input.rotateRight then
      ship.rcs = false
      body:applyTorque(mov.angularAcceleration)
    elseif input.rcs then
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
  end
end

return ShipMovement
