local Autopilot = {}

-- ─────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────

-- Retorna a posição do alvo independente do tipo
local function getTargetPos(target, shapetype)
  if shapetype == "body" then
    return target.rigidbody.body:getWorldCenter()
  else
    return target.x, target.y
  end
end

-- Valida e retorna validity + shapetype, bloqueando "nobody" por padrão
local function validateTarget(ap, allowNobody)
  local validity, shapetype = config.TargetingSystem.isValidTarget(ap.target)
  if not validity then return false, nil end
  if not allowNobody and shapetype == "nobody" then return false, nil end
  return validity, shapetype
end

-- ─────────────────────────────────────────
-- Behaviors
-- ─────────────────────────────────────────

local function behaviorFollow(ship, ap, dt)
  local validity, shapetype = validateTarget(ap)
  if not validity then Autopilot.disengage(ship); return end

  local tx, ty = getTargetPos(ap.target, shapetype)
  local sx, sy = ship.rigidbody.body:getPosition()
  local dx, dy = tx - sx, ty - sy
  local dist   = math.sqrt(dx*dx + dy*dy)

  local followDist = ap.params.distance or 200

  ship.intent.targetAngle = math.atan2(dy, dx)
  ship.intent.dampLinear  = true
  ship.intent.dampAngular = true

  if dist > followDist * 1.2 then
    ship.intent.thrust = math.min(1, (dist - followDist) / followDist)
  elseif dist < followDist * 0.8 then
    ship.intent.thrust = -math.min(0.5, (followDist - dist) / followDist)
  else
    ship.intent.thrust = 0
  end
end

local function behaviorOrbit(ship, ap, dt)
  local validity, shapetype = validateTarget(ap)
  if not validity then Autopilot.disengage(ship); return end

  local tx, ty = getTargetPos(ap.target, shapetype)
  local sx, sy = ship.rigidbody.body:getPosition()
  local dx, dy = sx - tx, sy - ty
  local dist   = math.sqrt(dx*dx + dy*dy)

  local orbitDist = ap.params.distance or 400
  local direction = ap.params.clockwise and 1 or -1

  local tangentX = -dy * direction
  local tangentY =  dx * direction
  local tLen     = math.sqrt(tangentX*tangentX + tangentY*tangentY)
  tangentX = tangentX / tLen
  tangentY = tangentY / tLen

  local radialCorrection = (orbitDist - dist) / orbitDist
  local goalX = sx + tangentX + dx * radialCorrection * 0.5
  local goalY = sy + tangentY + dy * radialCorrection * 0.5

  ship.intent.targetAngle = math.atan2(goalY - sy, goalX - sx)
  ship.intent.dampAngular = true
  ship.intent.dampLinear  = false
  ship.intent.thrust      = 1
end

local function behaviorEscort(ship, ap, dt)
  local validity, shapetype = validateTarget(ap)
  if not validity then Autopilot.disengage(ship); return end

  local target = ap.target
  local tx, ty = getTargetPos(target, shapetype)
  local tAngle = shapetype == "body"
    and target.rigidbody.body:getAngle()
    or  0

  local offX = ap.params.offsetX or -100
  local offY = ap.params.offsetY or  80

  local cos, sin  = math.cos(tAngle), math.sin(tAngle)
  local worldOffX = offX * cos - offY * sin
  local worldOffY = offX * sin + offY * cos

  local goalX = tx + worldOffX
  local goalY = ty + worldOffY

  local sx, sy = ship.rigidbody.body:getPosition()
  local dx, dy = goalX - sx, goalY - sy
  local dist   = math.sqrt(dx*dx + dy*dy)

  ship.intent.targetAngle = math.atan2(dy, dx)
  ship.intent.dampLinear  = true
  ship.intent.dampAngular = true
  ship.intent.thrust      = math.min(1, dist / 150)
end

local function behaviorFlee(ship, ap, dt)
  local validity, shapetype = validateTarget(ap)
  if not validity then Autopilot.disengage(ship); return end

  local tx, ty = getTargetPos(ap.target, shapetype)
  local sx, sy = ship.rigidbody.body:getPosition()
  local vx, vy = ship.rigidbody.body:getLinearVelocity()

  local dx, dy = sx - tx, sy - ty
  local dist   = math.sqrt(dx*dx + dy*dy)

  local fleeRadius = ap.params.fleeRadius or 1500

  if dist > fleeRadius then
    Autopilot.disengage(ship); return
  end

  local fleeX = dx / dist
  local fleeY = dy / dist

  local speed = math.sqrt(vx*vx + vy*vy)
  local steerX, steerY = fleeX, fleeY
  if speed > 1 then
    local nvx, nvy = vx / speed, vy / speed
    local momentumWeight = math.min(0.7, speed / 500)
    steerX = fleeX * (1 - momentumWeight) + nvx * momentumWeight
    steerY = fleeY * (1 - momentumWeight) + nvy * momentumWeight
    local sLen = math.sqrt(steerX*steerX + steerY*steerY)
    steerX = steerX / sLen
    steerY = steerY / sLen
  end

  ship.intent.targetAngle = math.atan2(steerY, steerX)
  ship.intent.dampLinear  = false
  ship.intent.dampAngular = true

  local danger = 1 - (dist / fleeRadius)
  ship.intent.thrust = 0.5 + danger * 0.5
end

-- Landing: só funciona com alvos "nobody" (landables, estrelas, wormholes)
-- Voa até o alvo e aciona o pouso quando estiver no range
local function behaviorLand(ship, ap, dt)
  -- Valida exigindo "nobody"
  local validity, shapetype = config.TargetingSystem.isValidTarget(ap.target)
  if not validity or shapetype ~= "nobody" then
    Autopilot.disengage(ship); return
  end

  local target = ap.target
  local tx, ty = target.x, target.y
  local sx, sy = ship.rigidbody.body:getPosition()
  local dx, dy = tx - sx, ty - sy
  local dist   = math.sqrt(dx*dx + dy*dy)

  local landRange = ap.params.landRange
    or (target.radius and target.radius + 40)
    or 200

  ship.intent.targetAngle = math.atan2(dy, dx)
  ship.intent.dampLinear  = true
  ship.intent.dampAngular = true

  if dist > landRange * 2 then
    -- Longe: aproxima em velocidade máxima
    if ship.intent.targetAngle == ship.rigidbody.body:getAngle() then
      ship.intent.targetAngle = nil
      ship.intent.thrust = math.min(1, (dist - landRange) / landRange)
    end
  elseif dist > landRange then
    -- Perto: desacelera proporcionalmente
    ship.intent.thrust = math.min(0.3, (dist - landRange) / landRange)
  else
    -- Dentro do range: aciona pouso
    ship.intent.thrust = 0
    ship.landedAt = target
    config.WorldManager:freeze()
    config.GameState.switch("landed")
    Autopilot.disengage(ship)
  end
end

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function Autopilot.engage(ship, behavior, target, params)
  if not ship.autopilot then return end
  -- Valida o alvo antes de engajar
  local validity, shapetype = config.TargetingSystem.isValidTarget(target)
  if not validity then
    print("Autopilot.engage: alvo inválido para behavior '"..tostring(behavior).."'")
    return
  end
  -- Landing só aceita "nobody"; os outros só aceitam "body"
  if behavior == "land" and shapetype ~= "nobody" then
    print("Autopilot.engage: 'land' requer alvo sem rigidbody (landable/star/wormhole)")
    return
  end
  if behavior ~= "land" and shapetype == "nobody" then
    print("Autopilot.engage: '"..behavior.."' não suporta alvos sem rigidbody")
    return
  end

  local ap = ship.autopilot
  ap.target   = target
  ap.behavior = behavior
  ap.params   = params or {}
  ap.active   = true
  print("Autopilot engajado: " .. behavior .. " → " .. tostring(target.name or target.tag))
end

function Autopilot.disengage(ship)
  if not ship.autopilot then return end
  local ap     = ship.autopilot
  local intent = ship.intent
  ap.target   = nil
  ap.behavior = nil
  ap.params   = {}
  ap.active   = false
  if intent then
    intent.targetAngle = nil
    intent.torque      = 0
    intent.thrust      = 0
    intent.targetPos   = nil
    intent.strafe      = 0
    intent.strafeV     = 0
  end
end

function Autopilot.update(ship, dt)
  local ap = ship.autopilot
  if not ap or not ap.active then return end

  local behaviors = {
    follow = behaviorFollow,
    orbit  = behaviorOrbit,
    escort = behaviorEscort,
    flee   = behaviorFlee,
    land   = behaviorLand,
  }

  local fn = behaviors[ap.behavior]
  if fn then fn(ship, ap, dt) end
end

return Autopilot
