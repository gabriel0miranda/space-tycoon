local Targeting = {
  current = nil,
  locked  = false,
}

local cycleIndex = 0
local candidates = {}

local CLICK_RADIUS = 40
local TARGET_TAGS = {"ship", "asteroid", "landable", "star", "wormhole"}

function Targeting.isValidTarget(entity)
  if not entity then return false end
  if entity.tag == "ship" or entity.tag == "asteroid" then
    if not entity.rigidbody or not entity.rigidbody.body then return false end
    if entity.rigidbody.body:isDestroyed() then return false end
    return true, "body"
  elseif entity.tag == "landable" or entity.tag == "star" or entity.tag == "wormhole" then
    if not entity.sprite or not entity.sprite.shape then return false end
    return true, "nobody"
  end
end

function Targeting.getTargetPosition()
  local validity, shapetype = Targeting.isValidTarget(Targeting.current)
  if not validity then
    return nil, nil
  end
  if shapetype == "body" then
    return Targeting.current.rigidbody.body:getPosition()
  elseif shapetype == "nobody" then
    return Targeting.current.x, Targeting.current.y
  end
end

local function clearTarget()
  Targeting.current = nil
  Targeting.locked = false
  cycleIndex = 0
end

local function updateCandidates(player)
  candidates = {}
  for _, tag in ipairs(TARGET_TAGS) do
    for _, e in ipairs(config.Entities.getByTag(tag)) do
      local validity, shapetype = Targeting.isValidTarget(e)
      --print("e.tag"..e.tag.."\ne.validity"..tostring(validity).."\ne.type"..type)
      if e ~= player and validity then
        table.insert(candidates,{e = e,shapetype = shapetype})
      end
    end
  end

  if player and player.rigidbody and player.rigidbody.body then
    local px, py = player.rigidbody.body:getPosition()
    table.sort(candidates,function(a,b)
      local ax, ay, bx, by = 0,0,0,0
      if a.shapetype == "body" then
        ax, ay = a.e.rigidbody.body:getPosition()
      elseif a.shapetype == "nobody" then
        ax, ay = a.e.x, a.e.y
      end
      if b.shapetype == "body" then
        bx, by = b.e.rigidbody.body:getPosition()
      elseif b.shapetype == "nobody" then
        bx, by = b.e.x, b.e.y
      end
      local da = (ax-px)^2 + (ay-py)^2
      local db = (bx-px)^2 + (by-py)^2
      return da < db
    end)
  end
end

function Targeting.update(player,dt)
  updateCandidates(player)
  if not Targeting.isValidTarget(Targeting.current) then
    if config.AutopilotSystem.isEngaged(player) then
      config.AutopilotSystem.disengage(player)
    end
    clearTarget()
  end
  if config.Input.state.target_next then
    if config.AutopilotSystem.isEngaged(player) then
      config.AutopilotSystem.disengage(player)
    end
    Targeting.cycleNext()
  end
  if config.Input.state.target_prev then
    if config.AutopilotSystem.isEngaged(player) then
      config.AutopilotSystem.disengage(player)
    end
    Targeting.cyclePrev()
  end
  if config.Input.state.target_clear then
    config.AutopilotSystem.disengage(player)
    clearTarget()
  end
  if config.Input.state.followTarget then
    config.AutopilotSystem.engage(player,"follow",Targeting.current,{distance=200})
  end
  if config.Input.state.orbitTarget then
    config.AutopilotSystem.engage(player,"orbit",Targeting.current,{distance=500,clockwise=1})
  end
  if config.Input.state.escortTarget then
    config.AutopilotSystem.engage(player,"escort",Targeting.current,{offsetX=-200,offsetY=150})
  end
  if config.Input.state.fleeTarget then
    config.AutopilotSystem.engage(player,"flee",Targeting.current,{fleeRadius=2000})
  end
  if config.Input.state.landOnTarget then
    config.AutopilotSystem.engage(player,"land",Targeting.current)
  end
end

function Targeting.mousepressed(mx,my,button)
  if button ~= 2 then return end
  local wx,wy = config.Camera:toWorld(mx,my)
  local best = nil
  local bestDist = math.huge

  for _, e in ipairs(candidates) do
    local ex,ey = 0,0
    if e.shapetype == "body" then
      ex, ey = e.e.rigidbody.body:getPosition()
    elseif e.shapetype == "nobody" then
      ex, ey = e.e.x, e.e.y
    end
    local dx, dy = ex - wx, ey - wy
    local d2 = dx*dx + dy*dy

    local worldRadius = CLICK_RADIUS / (config.Camera.scale or 1)
    if d2 < worldRadius * worldRadius and d2 < bestDist then
      bestDist = d2
      best = e.e
    end
  end

  if best then
    if Targeting.current == best then
      Targeting.locked = true
    else
      Targeting.current = best
      Targeting.locked = false
      for i, e in ipairs(candidates) do
        if e.e == best then cycleIndex = i; break end
      end
    end
  else
    clearTarget()
  end
end

function Targeting.cycleNext()
  if #candidates == 0 then return end
  cycleIndex = (cycleIndex % #candidates) + 1
  Targeting.current = candidates[cycleIndex].e
  Targeting.locked  = false
end

function Targeting.cyclePrev()
  if #candidates == 0 then return end
  cycleIndex = ((cycleIndex - 2) % #candidates) + 1
  Targeting.current = candidates[cycleIndex].e
  Targeting.locked  = false
end

function Targeting.keypressed(key)
  -- Escape limpa o alvo
  if key == "escape" and Targeting.current then
    clearTarget()
  end
end

return Targeting
