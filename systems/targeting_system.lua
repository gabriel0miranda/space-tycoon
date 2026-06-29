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
  if not entity.rigidbody or not entity.rigidbody.body then return false end
  if entity.rigidbody.body:isDestroyed() then return false end
  return true
end

function Targeting.getTargetPosition()
  if not Targeting.isValidTarget(Targeting.current) then
    return nil, nil
  end
  return Targeting.current.rigidbody.body:getPosition()
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
      if e ~= player and Targeting.isValidTarget(e) then
        table.insert(candidates,e)
      end
    end
  end

  if player and player.rigidbody and player.rigidbody.body then
    local px, py = player.rigidbody.body:getPosition()
    table.sort(candidates,function(a,b)
      local ax, ay = a.rigidbody.body:getPosition()
      local bx, by = b.rigidbody.body:getPosition()
      local da = (ax-px)^2 + (ay-py)^2
      local db = (bx-px)^2 + (by-py)^2
      return da < db
    end)
  end
end

function Targeting.update(player,dt)
  updateCandidates(player)
  if not Targeting.isValidTarget(Targeting.current) then
    clearTarget()
  end
  if config.Input.state.target_next then
    Targeting.cycleNext()
  end
  if config.Input.state.target_prev then
    Targeting.cyclePrev()
  end
  if config.Input.state.target_clear then
    clearTarget()
  end
end

function Targeting.mousepressed(mx,my,button)
  if button ~= 2 then return end
  local wx,wy = config.Camera:toWorld(mx,my)
  local best = nil
  local bestDist = math.huge

  for _, e in ipairs(candidates) do
    local ex, ey = e.rigidbody.body:getPosition()
    local dx, dy = ex - wx, ey - wy
    local d2 = dx*dx + dy*dy

    local worldRadius = CLICK_RADIUS / (config.Camera.scale or 1)
    if d2 < worldRadius * worldRadius and d2 < bestDist then
      bestDist = d2
      best = e
    end
  end

  if best then
    if Targeting.current == best then
      Targeting.locked = true
    else
      Targeting.current = best
      Targeting.locked = false
      for i, e in ipairs(candidates) do
        if e == best then cycleIndex = i; break end
      end
    end
  else
    clearTarget()
  end
end

function Targeting.cycleNext()
  if #candidates == 0 then return end
  cycleIndex = (cycleIndex % #candidates) + 1
  Targeting.current = candidates[cycleIndex]
  Targeting.locked  = false
end

function Targeting.cyclePrev()
  if #candidates == 0 then return end
  cycleIndex = ((cycleIndex - 2) % #candidates) + 1
  Targeting.current = candidates[cycleIndex]
  Targeting.locked  = false
end

function Targeting.keypressed(key)
  -- Escape limpa o alvo
  if key == "escape" and Targeting.current then
    clearTarget()
  end
end

return Targeting
