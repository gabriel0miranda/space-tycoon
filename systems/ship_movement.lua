local ShipMovement = {}

-- ─────────────────────────────────────────
-- Intent API
-- Anything can write to ship.intent —
-- player input, autopilot, scripted events.
-- The physics step only reads from intent.
-- ─────────────────────────────────────────

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
    local input  = config.Input.state

    intent.thrust = (input.thrust and 1 or 0) + (input.brake and -1 or 0)
    intent.strafe = (input.right and -1 or 0) + (input.left and 1 or 0)
    intent.strafeV = (input.up and -1 or 0) + (input.down and 1 or 0)

    if input.rotateLeft then
        intent.torque      = -1
        intent.dampAngular = false
        intent.targetAngle = nil
    elseif input.rotateRight then
        intent.torque      = 1
        intent.dampAngular = false
        intent.targetAngle = nil
    else
        intent.torque      = 0
        intent.dampAngular = input.rcs
    end

    intent.dampLinear = ship.inertiaDampeners
end

-- ─────────────────────────────────────────
-- Physics step — reads intent, applies forces
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
    -- Nota: Em 2D, se isso for strafe "de tela", use os eixos 0, 1. 
    -- Se for ship-relative (como subir/descer num plano), a lógica é a mesma do Thrust.
    if intent.strafeV ~= 0 then
        body:applyForce(
            0, -- Se for apenas vertical na tela
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
        local vx, vy = body:getLinearVelocity()
        body:applyForce(-vx * mov.linearDamping, -vy * mov.linearDamping)
    end

    -- Angular dampening (RCS)
    if intent.dampAngular and intent.targetAngle == nil then
        local I = body:getMass() * (5 * 5 / 2)
        body:applyAngularImpulse(-I * body:getAngularVelocity())
    end
end

-- ─────────────────────────────────────────
-- Main update
-- ─────────────────────────────────────────

function ShipMovement.update(dt)
    for _, ship in ipairs(config.Entities.with("ship")) do
        if not ship.rigidbody or not ship.rigidbody.body then return end
        if not ship.intent then ship.intent = ShipMovement.newIntent() end

        -- Player input writes to intent unless autopilot is active
        if not ship.autopilot then
            applyPlayerInput(ship)
        end

        applyIntent(ship, dt)
    end
    for _, npc in ipairs(config.Entities.with("npc")) do
      if not npc.intent then npc.intent = ShipMovement.newIntent() end
      applyIntent(npc, dt)
    end
end

return ShipMovement
