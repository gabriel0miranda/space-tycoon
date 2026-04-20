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
      -- Laser/bala: círculo simples
      love.graphics.circle("fill", proj.x, proj.y, proj.size)
    end
  end
end

local function drawDrillEffect(armedEntities)
  for _, e in ipairs(armedEntities) do
    local weapon = e.weapon
    if weapon.def.type == "drill" and weapon.intent and weapon.intent.firing and weapon.timer > 0 then
      local x, y = e.rigidbody.body:getPosition()
      local tx = x + math.cos(weapon.angle) * weapon.def.range
      local ty = y + math.sin(weapon.angle) * weapon.def.range
      -- Pulsa com base no cooldown restante
      local alpha = weapon.timer / weapon.def.cooldown
      love.graphics.setColor(weapon.def.color[1], weapon.def.color[2], weapon.def.color[3], alpha)
      love.graphics.setLineWidth(weapon.def.size * alpha)
      love.graphics.line(x, y, tx, ty)
      love.graphics.circle("fill", tx, ty, weapon.def.size * alpha)
      love.graphics.setLineWidth(1)
    end
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
    for _, star in ipairs(config.Entities.with("star")) do
        local dx = (star.x - playerX) * mapScale
        local dy = (star.y - playerY) * mapScale
        love.graphics.setColor(0.91, 0.75, 0.37)
        love.graphics.circle("fill", cx + dx, cy + dy, 5)
    end

    -- Planetas e estações
    for _, e in ipairs(config.Entities.with("landable")) do
        local dx = (e.x - playerX) * mapScale
        local dy = (e.y - playerY) * mapScale
        local color = e.type == "station"
            and {0.48, 0.67, 0.87}
            or  {0.33, 0.55, 0.33}
        love.graphics.setColor(color)
        love.graphics.circle("fill", cx + dx, cy + dy, 4)
    end

    -- Asteroides
    for _, ast in ipairs(config.Entities.with("asteroid")) do
        if ast.rigidbody and ast.rigidbody.body then
            local ax, ay = ast.rigidbody.body:getPosition()
            local dx = (ax - playerX) * mapScale
            local dy = (ay - playerY) * mapScale
            love.graphics.setColor(0.55, 0.45, 0.35, 0.7)
            love.graphics.circle("fill", cx + dx, cy + dy, 1.5)
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
    "Ship mass:"..playerFlagShip.mass..
    "\nShip X:"..playerFlagShip.rigidbody.body:getX()..
    "\nShip Y:"..playerFlagShip.rigidbody.body:getY()..
    "\nShip angle:"..playerFlagShip.rigidbody.body:getAngle()..
    "\nShip angular velocity:"..playerFlagShip.rigidbody.body:getAngularVelocity()..
    "\nShip RCS:"..tostring(playerFlagShip.rcs)..
    "\nShip weapon:"..playerFlagShip.weapon.def.type
  )
  love.graphics.setColor(1,1,1)
end

function Rendering.draw(playerFlagShip, armedEntities, camera)
    camera:attach()
        drawWorldLayer()
        -- drawParallaxBackground()
        drawProjectiles()
        drawDrillEffect(armedEntities)
    camera:detach()
    drawInventory()
    drawProperty()
    drawMinimap(playerFlagShip, camera)
    drawDebugOverlay(playerFlagShip)
end


return Rendering
