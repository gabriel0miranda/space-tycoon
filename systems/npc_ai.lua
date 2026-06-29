local NpcAI = {}

local DETECT_RANGE   = 4000
local ATTACK_RANGE   = 1000
local PATROL_RADIUS  = 8000
local PATROL_TIMEOUT = 5  -- segundos em idle antes de escolher novo waypoint

-- helpers 

local function dist2(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return dx*dx + dy*dy
end

local function set_npc_intent(npc, tx, ty)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  local dx, dy = tx - nx, ty - ny
  if npc.ship.rigidbody.body:getAngularVelocity() > 4 then
    npc.ship.intent.targetAngle = nil
    npc.ship.intent.torque = 0
    return
  end

  npc.ship.intent.targetAngle = math.atan2(dy, dx)
  npc.ship.intent.dampAngular = true   -- deixa o damping estabilizar a rotação
  npc.ship.intent.dampLinear  = true

  local da = npc.ship.intent.targetAngle - npc.ship.rigidbody.body:getAngle()
  da = ((da + math.pi) % (2 * math.pi)) - math.pi
  if math.abs(da) < 0.3 then
    npc.ship.intent.thrust = 1
    npc.ship.intent.targetAngle = nil
  else
    npc.ship.intent.thrust = 0
  end
end

local function clear_weapon_intent(npc)
  if npc.ship.weapons_intent then
    npc.ship.weapons_intent.firing  = false
    npc.ship.weapons_intent.targetX = nil
    npc.ship.weapons_intent.targetY = nil
  end
end

-- estados passivos

local function state_idle(npc, ai, dt)
  clear_weapon_intent(npc)
  ai.timer = ai.timer - dt
  if ai.timer <= 0 then
    -- escolhe um waypoint aleatório próximo
    local nx, ny = npc.ship.rigidbody.body:getPosition()
    ai.waypoint = {
      x = nx + math.random(-PATROL_RADIUS, PATROL_RADIUS),
      y = ny + math.random(-PATROL_RADIUS, PATROL_RADIUS),
    }
    if npc.name == "Miner" then
      ai.state = "mining"
    elseif npc.name == "Hauler" then
      ai.state = "hauling"
    elseif npc.name == "Taxi" then
      ai.state = "taxi"
    else
      ai.state = "patrolling"
    end
  end
end

local function state_patrolling(npc, ai, dt)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  clear_weapon_intent(npc)
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)

  -- chegou perto o suficiente? volta pra idle
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) < 60*60 then
    ai.timer = math.random(2, PATROL_TIMEOUT)
    ai.state = "idle"
  end
end

local function state_hauling(npc, ai, dt)
  clear_weapon_intent(npc)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  if not ai.target or ai.target.tag ~= "landable" then
    local RNG = love.math.newRandomGenerator(os.time())
    -- escolhe um planeta/estação aleatório próximo
    local target = config.Systems[config.WorldManager.currentSystemId].landables[RNG:random(1,#config.Systems[config.WorldManager.currentSystemId].landables)]
    ai.waypoint = {
      x = config.Landables[target].x,
      y = config.Landables[target].y,
    }
  end
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) < 60*60 then
    ai.timer = math.random(2, 10)
    ai.state = "trading"
  end
end

local function state_trading(npc, ai, dt)
  clear_weapon_intent(npc)
  npc.ship.inventory:clear()
  ai.timer = ai.timer - dt
  if ai.timer <= 0 then
    if npc.name == "Miner" then
      ai.state = "mining"
    elseif npc.name == "Hauler" then
      ai.state = "hauling"
    elseif npc.name == "Taxi" then
      ai.state = "taxi"
    end
  end
end

local function state_taxi(npc, ai, dt)
  clear_weapon_intent(npc)
  if not ai.target or ai.target.tag ~= "landable" then
    local RNG = love.math.newRandomGenerator(os.time())
    -- escolhe um planeta/estação aleatório próximo
    local target = config.Systems[config.WorldManager.currentSystem].landables[RNG:random(1,#config.Systems[config.WorldManager.currentSystem].landables)]
    ai.waypoint = {
      x = config.Landables[target].x,
      y = config.Landables[target].y,
    }
  end
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)

  -- chegou perto o suficiente? procura outro alvo
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) < 60*60 then
    ai.timer = math.random(2, 5)
    ai.target = nil
  end
end

local function state_mining(npc, ai, dt)
  clear_weapon_intent(npc)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  if not ai.target or ai.target.tag ~= "asteroid" or ai.target.rigidbody.body:isDestroyed() then
    local asteroids = config.Entities.getByTag("asteroid")
    ai.timer = ai.timer - dt
    if ai.timer <= 0 then
      local RNG = love.math.newRandomGenerator(os.time())
      -- escolhe um asteroide aleatório próximo
      ai.target = asteroids[RNG:random(1,#asteroids)]
      ai.waypoint = {
        x = ai.target.rigidbody.body:getX(),
        y = ai.target.rigidbody.body:getY(),
      }
    end
  end
  local px, py = ai.target.rigidbody.body:getX(), ai.target.rigidbody.body:getY()
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)
  if dist2(nx, ny, px, py) < ATTACK_RANGE*ATTACK_RANGE then
    ai.state = "attacking"
  elseif npc.ship.inventory.capacityUsed == npc.ship.inventory.capacity then
    ai.state = "hauling"
  end
end

-- estados hostis

local function state_chasing(npc, ai, dt, player)
  if not player then ai.state = "idle"; return end
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  local px, py = player.rigidbody.body:getPosition()

  set_npc_intent(npc, px, py)

  local ATTACK_RANGE = npc.ship.weapons[npc.ship.currentWeapon].range or 1000
  if dist2(nx, ny, px, py) < ATTACK_RANGE*ATTACK_RANGE then
    ai.target = player
    ai.state = "attacking"
  elseif dist2(nx, ny, px, py) > DETECT_RANGE*DETECT_RANGE * 1.5 then
    ai.state = "idle"
  end
end

local function state_attacking(npc, ai, dt, player)
  if not ai.target or not ai.target.rigidbody or not ai.target.rigidbody.body or ai.target.rigidbody.body:isDestroyed() then ai.state = "idle"; return end
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  local px, py = ai.target.rigidbody.body:getPosition()
  local ang = npc.ship.rigidbody.body:getAngle()

  -- continua apontando pro jogador mas mais devagar
  clear_weapon_intent(npc)
  set_npc_intent(npc, px, py)

  -- atira (delega pro WeaponSystem)
  if npc.ship.weapons and npc.ship.weapons_intent then
    npc.ship.weapons_intent.firing  = true
    npc.ship.weapons_intent.angle = npc.ship.rigidbody.body:getAngle()
  end

  -- saiu do range de ataque? volta a perseguir
  if dist2(nx, ny, px, py) > ATTACK_RANGE*ATTACK_RANGE * 1.2 then
    if npc.aggressiveTowardsPlayer then
      ai.state = "chasing"
    elseif npc.name == "Miner" then
      ai.state = "mining"
    elseif npc.name == "Hauler" then
      ai.state = "hauling"
    elseif npc.name == "Taxi" then
      ai.state = "taxi"
    else
      ai.state = "idle"
    end
  end
end

-- update principal

function NpcAI.update(playerFlagShip, dt)
  for _, npc in ipairs(config.Entities.getByTag("npc")) do
    if not npc.ship or not npc.ship.rigidbody or not npc.ship.rigidbody.body or npc.ship.rigidbody.body:isDestroyed() then
      config.Entities.remove(npc)
      return
    end
    local ai = npc.ai
    repeat
      if not ai then break end

      -- detecção de jogador (só hostis)
      if ai.aggressiveTowardsPlayer == true and (ai.state == "idle" or ai.state == "patrolling") then
        if playerFlagShip then
          local nx, ny = npc.ship.rigidbody.body:getPosition()
          local px, py = playerFlagShip.rigidbody.body:getPosition()
          if dist2(nx, ny, px, py) < DETECT_RANGE*DETECT_RANGE then
            ai.state = "chasing"
          end
        end
      end

      -- despacha pro estado atual
      if     ai.state == "idle"       then state_idle(npc, ai, dt)
      elseif ai.state == "patrolling" then state_patrolling(npc, ai, dt)
      elseif ai.state == "hauling"    then state_hauling(npc, ai, dt)
      elseif ai.state == "trading"    then state_trading(npc, ai, dt)
      elseif ai.state == "taxi"       then state_taxi(npc, ai, dt)
      elseif ai.state == "mining"     then state_mining(npc, ai, dt)
      elseif ai.state == "chasing"    then state_chasing(npc, ai, dt, playerFlagShip)
      elseif ai.state == "attacking"  then state_attacking(npc, ai, dt, playerFlagShip)
      end

    until true
  end
end

return NpcAI
