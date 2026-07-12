local NpcAI = {}

local ATTACK_RANGE   = 1000
local PATROL_RADIUS  = 8000
local IDLE_TIMER = 15  -- segundos em idle antes de escolher novo waypoint
local RNG = love.math.newRandomGenerator(os.time())

-- helpers 

local function dist2(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return dx*dx + dy*dy
end

local function set_npc_intent(npc, tx, ty,range)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  local dx, dy = tx - nx, ty - ny
  local dist   = math.sqrt(dx*dx + dy*dy)

  npc.ship.intent.targetAngle = math.atan2(dy, dx)
  npc.ship.intent.dampAngular = true
  npc.ship.intent.dampLinear  = true

  if dist > (range and (1/math.log10(range))*10000 or 1000) then
    -- Longe: aproxima em velocidade máxima
    npc.ship.intent.thrust = math.min(1, (dist - (range or 500)) / (range or 500))
  elseif dist > (range and (1/math.log10(range))*1000 or 500) then
    -- Perto: desacelera proporcionalmente
    npc.ship.intent.thrust = math.min(0.2, (dist - (range or 500)) / (range or 500))
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
  if ai.target and ai.target.sprite then
    set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y,ai.target.sprite.shape:getRadius())
  end
  clear_weapon_intent(npc)
  ai.timer = ai.timer - dt
  if ai.timer <= 0 then
    ai.target = nil
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
  ai.waypoint = {
    x = nx + math.random(-PATROL_RADIUS, PATROL_RADIUS),
    y = ny + math.random(-PATROL_RADIUS, PATROL_RADIUS),
  }
  clear_weapon_intent(npc)
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)

  -- chegou perto o suficiente? volta pra idle
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) < 60*60 then
    ai.timer = math.random(5, IDLE_TIMER)
    ai.state = "idle"
  end
end

local function state_hauling(npc, ai, dt)
  clear_weapon_intent(npc)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  if not ai.target or ai.target.tag ~= "landable" then
    -- escolhe um planeta/estação aleatório próximo
    local candidates = config.Entities.getByTag("landable")
    local target = config.RandomChoice(candidates,function (a) if a.wormhole then return false end return true end)
    ai.target = target
  end
  ai.waypoint = {
    x = ai.target.x,
    y = ai.target.y,
  }
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y,ai.target.sprite.shape:getRadius())

  -- chegou perto o suficiente? procura outro alvo
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) <= math.pow(ai.target.sprite.shape:getRadius() + 100,2) then
    npc.ship.rigidbody.body:setLinearVelocity(0,0)
    ai.timer = math.random(5, IDLE_TIMER)
    ai.state = "trading"
  end
end

local function state_trading(npc, ai, dt)
  clear_weapon_intent(npc)
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y,ai.target.sprite.shape:getRadius())
  npc.ship.inventory:clear()
  ai.timer = ai.timer - dt
  if ai.timer <= 0 then
    ai.target = nil
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

local function state_taxi(npc, ai, dt)
  clear_weapon_intent(npc)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  if not ai.target or ai.target.tag ~= "landable" then
    -- escolhe um planeta/estação aleatório próximo
    local candidates = config.Entities.getByTag("landable")
    local target = config.RandomChoice(candidates,function (a) if a.wormhole then return false end return true end)
    ai.target = target
  end
  ai.waypoint = {
    x = ai.target.x,
    y = ai.target.y,
  }
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y,ai.target.sprite.shape:getRadius())

  -- chegou perto o suficiente? procura outro alvo
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) <= math.pow(ai.target.sprite.shape:getRadius() + 100,2) then
    npc.ship.rigidbody.body:setLinearVelocity(0,0)
    ai.timer = math.random(5, IDLE_TIMER)
    ai.state = "idle"
  end
end

local function state_mining(npc, ai, dt)
  clear_weapon_intent(npc)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  if not ai.target or ai.target.tag ~= "asteroid" then
    local asteroids = config.Entities.getByTag("asteroid")
    ai.target = asteroids[math.random(1,#asteroids)]
  end
  if ai.target.rigidbody.body:isDestroyed() then
    ai.state = "harvesting"
    return
  end
  ai.waypoint = {
    x = ai.target.rigidbody.body:getX(),
    y = ai.target.rigidbody.body:getY(),
  }
  local px, py = ai.target.rigidbody.body:getPosition()
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)
  if dist2(nx, ny, px, py) < ATTACK_RANGE*ATTACK_RANGE then
    if npc.ship.weapons and npc.ship.weapons_intent then
      npc.ship.weapons_intent.firing  = true
      npc.ship.weapons_intent.angle = npc.ship.rigidbody.body:getAngle()
    end
  end
end

local function state_harvesting(npc, ai, floatsome_hash, dt)
  clear_weapon_intent(npc)
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  local nr = npc.ship.rigidbody.fixture:getShape():getRadius()
  if not ai.target or ai.target.tag ~= "floatsome" or ai.target.removed then
    local floatsome = config.SpatialHash.query(floatsome_hash,config.CELL_SIZE,nx,ny,nr+50) or {}
    if #floatsome == 0 then
      ai.target = nil
      if npc.name == "Miner" then
        ai.state = "mining"
      elseif npc.name == "Hauler" then
        ai.state = "hauling"
      elseif npc.name == "Taxi" then
        ai.state = "taxi"
      else
        ai.state = "patrolling"
      end
      return
    end
    ai.target = floatsome[math.random(1,#floatsome)]
  end
  ai.waypoint = {
    x = ai.target.x,
    y = ai.target.y,
  }
  set_npc_intent(npc, ai.waypoint.x, ai.waypoint.y)
  if dist2(nx, ny, ai.waypoint.x, ai.waypoint.y) < math.pow(ai.target.radius + 50,2) then
    npc.ship.rigidbody.body:setLinearVelocity(0,0)
    npc.ship.inventory:add(ai.target.item, ai.target.qty)
    config.Entities.remove(ai.target)
    ai.target = nil
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
  elseif dist2(nx, ny, px, py) > config.HOSTILE_DETECT_RANGE*config.HOSTILE_DETECT_RANGE * 1.5 then
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

function NpcAI.update(playerFlagShip, floatsome_hash, dt)
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
          if dist2(nx, ny, px, py) < config.HOSTILE_DETECT_RANGE*config.HOSTILE_DETECT_RANGE then
            ai.state = "chasing"
          end
        end
      end

      -- despacha pro estado atual
      npc.ship.ai_state = ai.state
      if     ai.state == "idle"       then state_idle(npc, ai, dt)
      elseif ai.state == "patrolling" then state_patrolling(npc, ai, dt)
      elseif ai.state == "hauling"    then state_hauling(npc, ai, dt)
      elseif ai.state == "trading"    then state_trading(npc, ai, dt)
      elseif ai.state == "taxi"       then state_taxi(npc, ai, dt)
      elseif ai.state == "mining"     then state_mining(npc, ai, dt)
      elseif ai.state == "harvesting" then state_harvesting(npc, ai, floatsome_hash, dt)
      elseif ai.state == "chasing"    then state_chasing(npc, ai, dt, playerFlagShip)
      elseif ai.state == "attacking"  then state_attacking(npc, ai, dt, playerFlagShip)
      end

    until true
  end
end

return NpcAI
