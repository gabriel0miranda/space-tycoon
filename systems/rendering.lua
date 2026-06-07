local Rendering = {}

local function drawWorldLayer()
  -- Draw all entities that have a draw method
  for _, entity in ipairs(config.Entities.all) do
    if entity.draw then
      entity:draw()
    elseif entity.fixtures then
      -- Nave multi-part: desenha cada fixture com sua própria cor
      for _, part in ipairs(entity.fixtures) do
        love.graphics.setColor(part.color)
        love.graphics.polygon("fill",
          entity.rigidbody.body:getWorldPoints(part.shape:getPoints()))
      end

    elseif entity.sprite then
      love.graphics.setColor(entity.sprite.color or {0,1,0})
      if entity.sprite.shapeType == "Circle" then
        if entity.rigidbody then
          love.graphics.circle("fill",
            entity.rigidbody.body:getX(),
            entity.rigidbody.body:getY(),
            entity.sprite.shape:getRadius())
        else
          love.graphics.circle("fill", entity.x, entity.y,
            entity.sprite.shape:getRadius())
        end
      elseif entity.sprite.shapeType == "Polygon" then
        love.graphics.polygon("fill",
          entity.rigidbody.body:getWorldPoints(entity.sprite.shape:getPoints()))
      end
    end
  end
end

local function drawProjectiles()
  for _, proj in ipairs(config.Entities.getByTag("projectile")) do
    love.graphics.setColor(proj.color)
    if proj.projType == "missile" then
      -- Míssil: um retângulo orientado na direção do movimento
      local angle = math.atan2(proj.vy, proj.vx)
      love.graphics.push()
        love.graphics.translate(proj.x, proj.y)
        love.graphics.rotate(angle)
        love.graphics.rectangle("fill", -proj.size * 2, -proj.size / 2, proj.size * 4, proj.size)
      love.graphics.pop()
    else
      -- Bala: círculo simples
      love.graphics.circle("fill", proj.x, proj.y, proj.size)
    end
  end
end

local function drawLaser()
  for _, laser in ipairs(config.Entities.getByTag("laser")) do
    love.graphics.setColor(laser.color)
    -- Laser: line
    love.graphics.line(laser.x, laser.y, laser.hitX, laser.hitY)
  end
end

local function drawPulse()
  for _, pulse in ipairs(config.Entities.getByTag("pulse")) do
    love.graphics.setColor(pulse.color)
    -- pulse: circle
    love.graphics.circle('fill', pulse.x, pulse.y, pulse.range)
  end
end

local function drawMine()
  for _, mine in ipairs(config.Entities.getByTag("mine")) do
    love.graphics.setColor(mine.color)
    -- mine: square
    love.graphics.rectangle('fill', mine.x, mine.y, 15,15,3,3)
    -- range indicators
    love.graphics.setColor(mine.indicator.color)
    love.graphics.circle('line', mine.x, mine.y, mine.range)
  end
end

local function drawExplosion()
  for _, explosion in ipairs(config.Entities.getByTag("explosion")) do
    love.graphics.setColor(explosion.color)
    -- explosion: circle
    love.graphics.circle('fill', explosion.x, explosion.y, explosion.radius)
    explosion.radius = explosion.radius+explosion.duration
  end
end

local function drawInventory()
  config.InventoryUI.draw()
end

local function drawProperty()
  config.PropertyUI.draw()
end

local function drawMinimap(playerFlagShip, camera)
    if not playerFlagShip then return end

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    local size   = 160
    local margin = 16
    local cx     = sw - margin - size / 2
    local cy     = sh - margin - size / 2

    -- Campo de visão da câmera em unidades de mundo
    local viewW  = sw / camera.scale
    local viewH  = sh / camera.scale

    -- Minimapa mostra um pouco além do que a câmera vê
    local viewRange  = math.max(viewW, viewH) * 0.7
    local mapScale   = (size / 2) / viewRange

    -- Fundo
    love.graphics.setColor(0.04, 0.05, 0.10, 0.85)
    love.graphics.circle("fill", cx, cy, size / 2)
    love.graphics.setColor(0.17, 0.21, 0.32)
    love.graphics.circle("line", cx, cy, size / 2)

    -- Stencil circular
    love.graphics.stencil(function()
        love.graphics.circle("fill", cx, cy, size / 2 - 1)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    local playerX, playerY = playerFlagShip.rigidbody.body:getPosition()

    -- Estrela central
    for _, star in ipairs(config.Entities.getByTag("star")) do
        local dx = (star.x - playerX) * mapScale
        local dy = (star.y - playerY) * mapScale
        love.graphics.setColor(0.91, 0.75, 0.37)
        love.graphics.circle("fill", cx + dx, cy + dy, 5)
    end

    -- Planetas e estações
    for _, e in ipairs(config.Entities.getByTag("landable")) do
        local dx = (e.x - playerX) * mapScale
        local dy = (e.y - playerY) * mapScale
        local color = e.type == "station"
            and {0.48, 0.67, 0.87}
            or  {0.33, 0.55, 0.33}
        love.graphics.setColor(color)
        love.graphics.circle("fill", cx + dx, cy + dy, 4)
    end

    -- Asteroides
    for _, ast in ipairs(config.Entities.getByTag("asteroid")) do
        if ast.rigidbody and ast.rigidbody.body then
            local ax, ay = ast.rigidbody.body:getPosition()
            local dx = (ax - playerX) * mapScale
            local dy = (ay - playerY) * mapScale
            love.graphics.setColor(0.55, 0.45, 0.35, 0.7)
            love.graphics.circle("fill", cx + dx, cy + dy, 1.5)
        end
    end

    -- Naves
    for _, ship in ipairs(config.Entities.getByTag("ship")) do
        if ship.rigidbody and ship.rigidbody.body then
            local ax, ay = ship.rigidbody.body:getPosition()
            local dx = (ax - playerX) * mapScale
            local dy = (ay - playerY) * mapScale
            love.graphics.setColor(0.3,1,0.5,0.7)
            love.graphics.circle("fill", cx + dx, cy + dy, 2)
        end
    end

    -- Retângulo do campo de visão atual
    local fovW = (viewW / 2) * mapScale
    local fovH = (viewH / 2) * mapScale
    love.graphics.setColor(0.78, 0.81, 0.88, 0.12)
    love.graphics.rectangle("fill", cx - fovW, cy - fovH, fovW * 2, fovH * 2)
    love.graphics.setColor(0.78, 0.81, 0.88, 0.25)
    love.graphics.rectangle("line", cx - fovW, cy - fovH, fovW * 2, fovH * 2)

    -- Nave (sempre no centro)
    love.graphics.setColor(0.48, 0.87, 0.67)
    love.graphics.circle("fill", cx, cy, 3)

    love.graphics.setStencilTest()
    love.graphics.setColor(0.17, 0.21, 0.32)
    love.graphics.circle("line", cx, cy, size / 2)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawDebugOverlay(playerFlagShip)
  if not config.Input.state.debugFlag then return end
  love.graphics.setColor(0, 1, 0)
  love.graphics.setFont(config.smallFont)
  love.graphics.print(
    "Ship X:"..playerFlagShip.rigidbody.body:getX()..
    "\nShip Y:"..playerFlagShip.rigidbody.body:getY()..
    "\nShip angle:"..playerFlagShip.rigidbody.body:getAngle()..
    "\nShip angular velocity:"..playerFlagShip.rigidbody.body:getAngularVelocity()..
    "\nShip RCS:"..tostring(not config.Input.state.rcs_off)..
    "\nShip weapon:"..playerFlagShip.weapons[playerFlagShip.currentWeapon].def.type..
    "\nWeapon capacitor:"..playerFlagShip.weapons[playerFlagShip.currentWeapon].capacitor.current
  )
  love.graphics.setColor(1,1,1)
end

function Rendering.draw(playerFlagShip, armedEntities, camera)
    camera:attach()
        drawWorldLayer()
        drawExplosion()
        drawPulse()
        drawMine()
        drawProjectiles()
        drawLaser()
        -- drawParallaxBackground()
    camera:detach()
    drawInventory()
    drawProperty()
    drawMinimap(playerFlagShip, camera)
    drawDebugOverlay(playerFlagShip)
end


return Rendering
