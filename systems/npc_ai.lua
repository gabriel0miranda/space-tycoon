local NpcAI = {}

local DETECT_RANGE   = 600
local ATTACK_RANGE   = 200
local PATROL_RADIUS  = 800
local PATROL_TIMEOUT = 5  -- segundos em idle antes de escolher novo waypoint

-- ── helpers ────────────────────────────────────────────────────

local function dist2(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return dx*dx + dy*dy
end

local function set_npc_intent(npc, tx, ty)
  local nx, ny = npc.rigidbody.body:getPosition()
  local dx, dy = tx - nx, ty - ny

  -- Aponta pro alvo
  npc.intent.targetAngle = math.atan2(dy, dx)

  -- Empurra pra frente só quando já está razoavelmente alinhado
  local currentAngle = npc.rigidbody.body:getAngle()
  local da = npc.intent.targetAngle - currentAngle
  da = ((da + math.pi) % (2 * math.pi)) - math.pi

  if math.abs(da) < 0.3 then
    npc.intent.thrust = 1
  else
    npc.intent.thrust = 0  -- para e gira primeiro
  end

  npc.intent.dampLinear  = true
  npc.intent.dampAngular = false  -- o targetAngle já cuida da rotação
end

-- ── estados passivos ───────────────────────────────────────────

local function state_idle(npc, ai, dt)
  npc.intent.thrust = 0
  npc.intent.targetAngle = nil
  npc.intent.dampLinear = true
  npc.intent.dampAngular = true
  ai.timer = ai.timer - dt
  if ai.timer <= 0 then
    -- escolhe um waypoint aleatório próximo
    local nx, ny = npc.rigidbody.body:getPosition()
    ai.waypoint = {
      x = nx + math.random(-PATROL_RADIUS, PATROL_RADIUS),
      y = ny + math.random(-PATROL_RADIUS, PATROL_RADIUS),
    }
    ai.state = "patrolling"
  end
end

local function state_patrolling(npc, ai, dt)
  local nx, ny = npc.rigidbody.body:getPosition()
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)

  -- chegou perto o suficiente? volta pra idle
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) < 60*60 then
    ai.timer = math.random(2, PATROL_TIMEOUT)
    ai.state = "idle"
  end
end

-- ── estados hostis ─────────────────────────────────────────────

local function state_chasing(npc, ai, dt, player)
  if not player then ai.state = "idle"; return end
  local nx, ny = npc.rigidbody.body:getPosition()
  local px, py = player.rigidbody.body:getPosition()

  set_npc_intent(npc, px, py)

  if dist2(nx, ny, px, py) < ATTACK_RANGE*ATTACK_RANGE then
    ai.state = "attacking"
  elseif dist2(nx, ny, px, py) > DETECT_RANGE*DETECT_RANGE * 1.5 then
    -- jogador escapou (1.5× o range de detecção como histerese)
    ai.state = "idle"
  end
end

local function state_attacking(npc, ai, dt, player)
  if not player then ai.state = "idle"; return end
  local nx, ny = npc.rigidbody.body:getPosition()
  local px, py = player.rigidbody.body:getPosition()
  local ang = npc.rigidbody.body:getAngle()

  -- continua apontando pro jogador mas mais devagar
    set_npc_intent(npc, px, py)

  -- atira (delega pro WeaponSystem ou inline aqui)
  if npc.weapon.cooldown <= 0 then
    config.WeaponSystem.fire_projectile(npc,npc.weapon, px, py,ang)
    npc.weapon.cooldown = npc.weapon.fireRate or 1.0
  end
  npc.weapon.cooldown = npc.weapon.cooldown - dt

  -- saiu do range de ataque? volta a perseguir
  if dist2(nx, ny, px, py) > ATTACK_RANGE*ATTACK_RANGE * 1.4 then
    ai.state = "chasing"
  end
end

-- ── update principal ───────────────────────────────────────────

function NpcAI.update(dt)
  local player = config.Entities.with("ship")[1]

  for _, npc in ipairs(config.Entities.with("npc")) do
    local ai = npc.ai
    if not ai then goto continue end

    -- detecção de jogador (só hostis)
    if ai.faction == "hostile" and (ai.state == "idle" or ai.state == "patrolling") then
      if player then
        local nx, ny = npc.rigidbody.body:getPosition()
        local px, py = player.rigidbody.body:getPosition()
        if dist2(nx, ny, px, py) < DETECT_RANGE*DETECT_RANGE then
          ai.state = "chasing"
        end
      end
    end

    -- despacha pro estado atual
    if     ai.state == "idle"       then state_idle(npc, ai, dt)
    elseif ai.state == "patrolling" then state_patrolling(npc, ai, dt)
    elseif ai.state == "chasing"    then state_chasing(npc, ai, dt, player)
    elseif ai.state == "attacking"  then state_attacking(npc, ai, dt, player)
    end

    ::continue::
  end
end

return NpcAI
