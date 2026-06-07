local ShipMovement = {}

-- ─────────────────────────────────────────
-- Intent API
-- Anything can write to ship.intent —
-- player input, autopilot, scripted events.
-- The physics step only reads from intent.
-- ─────────────────────────────────────────

-- helpers
local function applyLinearDamping(body, mov)
  local vx, vy = body:getLinearVelocity()
  body:applyForce(-vx*mov.linearDamping, -vy*mov.linearDamping)
end
local function applyAngularDamping(body, mov, torqueActive)
  if torqueActive then return end
  local av = body:getAngularVelocity()
  if math.abs(av) < 0.01 then
    body:setAngularVelocity(0)
    return
  end
  -- Multiplica a velocidade por um fator < 1 a cada frame
  body:setAngularVelocity(av * mov.angularDampingFactor)
end
-- Returns a blank intent table (all neutral)
function ShipMovement.newIntent()
    return {
        thrust      = 0,    -- -1.0 to 1.0 (forward/back)
        strafe      = 0,    -- -1.0 to 1.0 (left/right)
        strafeV     = 0,    -- -1.0 to 1.0 (up/down)
        torque      = 0,    -- -1.0 to 1.0 (rotate left/right)
        dampLinear  = true, -- inertia dampeners on/off
        dampAngular = true, -- RCS on/off
        -- autopilot helpers (set by autonomous systems)
        targetAngle = nil,  -- if set, RCS steers toward this angle
        targetPos   = nil,  -- if set, autopilot flies toward {x, y}
    }
end

-- ─────────────────────────────────────────
-- Player input → intent
-- ─────────────────────────────────────────

local function applyPlayerInput(ship)
    local intent = ship.intent

    intent.thrust = (config.Input.state.ship_thrust and 1 or 0) + (config.Input.state.ship_brake and -1 or 0)
    intent.strafe = (config.Input.state.ship_strafe_right and -1 or 0) + (config.Input.state.ship_strafe_left and 1 or 0)
    intent.strafeV = (config.Input.state.ship_strafe_up and -1 or 0) + (config.Input.state.ship_strafe_down and 1 or 0)

    if config.Input.state.ship_rotate_left then
        intent.torque      = -1
        --intent.dampAngular = false
        intent.targetAngle = nil
    elseif config.Input.state.ship_rotate_right then
        intent.torque      = 1
        --intent.dampAngular = false
        intent.targetAngle = nil
    else
        intent.torque      = 0
    end

    intent.dampAngular = not config.Input.state.rcs_off
    intent.dampLinear = ship.inertiaDampeners and not config.Input.state.rcs_off
end

-- ─────────────────────────────────────────
-- Apply intent to ship
-- ─────────────────────────────────────────

local function applyIntent(ship, dt)
    local body   = ship.rigidbody.body
    local mov    = ship.movement
    local intent = ship.intent
    local angle  = body:getAngle()
    local mass   = body:getMass()

    -- Thrust (forward/back)
    if intent.thrust ~= 0 then
        body:applyForce(
            math.cos(angle) * intent.thrust * mov.linearAcceleration * mass,
            math.sin(angle) * intent.thrust * mov.linearAcceleration * mass
        )
    end

    -- 2. Strafe Lateral (Esquerda/Direita) - Relativo ao lado da nave
    if intent.strafe ~= 0 then
        -- Multiplicamos por -sin e cos para pegar o vetor perpendicular ao ângulo atual
        body:applyForce(
            -intent.strafe * mov.strafeAcceleration * mass,
            0
        )
    end

    -- 3. Strafe Vertical (Cima/Baixo)
    if intent.strafeV ~= 0 then
        body:applyForce(
            0,
            intent.strafeV * mov.strafeAcceleration * mass
        )
    end

    -- Rotation: steer toward targetAngle if set, otherwise use raw torque
    if intent.targetAngle ~= nil then
        local da = intent.targetAngle - angle
        -- Wrap to [-pi, pi]
        da = ((da + math.pi) % (2 * math.pi)) - math.pi
        local I       = body:getMass() * (5 * 5 / 2)
        local maxStep = mov.angularAcceleration * dt
        -- Proportional control — slows down as it approaches target
        local torque  = math.max(-1, math.min(1, da / 0.3)) * mov.angularAcceleration
        body:applyTorque(torque)
    elseif intent.torque ~= 0 then
        body:applyTorque(intent.torque * mov.angularAcceleration)
    end

    -- Linear dampening (inertia dampeners)
    if intent.dampLinear then
      applyLinearDamping(body,mov)
    end

    -- Angular dampening (RCS)
    if intent.dampAngular then
      applyAngularDamping(body, mov, intent.torque ~= 0 or intent.targetAngle ~= nil)
    end
end

function ShipMovement.update(playerFlagShip, dt)
    if not playerFlagShip.rigidbody or not playerFlagShip.rigidbody.body then return end
    if not playerFlagShip.intent then playerFlagShip.intent = ShipMovement.newIntent() end

    -- Player input writes to intent unless autopilot is active
    if not playerFlagShip.autopilot then
        applyPlayerInput(playerFlagShip)
    end

    applyIntent(playerFlagShip, dt)
    for _, npc in ipairs(config.Entities.getByTag("npc")) do
      if not npc.ship.intent then npc.ship.intent = ShipMovement.newIntent() end
      applyIntent(npc.ship, dt)
    end
end

return ShipMovement
