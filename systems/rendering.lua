local Rendering = {}

local STAR_LAYERS = {
  { cellSize = 900, starsPerCell = 2, parallax = 0.05, sizeRange = {0.5, 1.0}, color = {0.55, 0.6, 0.75, 0.5} },
  { cellSize = 1000, starsPerCell = 3, parallax = 0.15, sizeRange = {0.8, 1.6}, color = {0.7, 0.75, 0.9, 0.7} },
  { cellSize = 1200, starsPerCell = 1, parallax = 0.35, sizeRange = {1.2, 2.4}, color = {0.9, 0.92, 1.0, 0.9} },
}

-- Hash determinístico simples — mesma célula sempre gera as mesmas estrelas.
-- Usa apenas operações inteiras seguras em Lua 5.1+ (sem bitwise nativo).
local function hashCell(cx, cy, salt)
    -- love.math.noise é determinístico e bem distribuído,
    -- sem problemas de overflow em coordenadas grandes
    return love.math.noise(cx * 0.1 + salt * 17.0, cy * 0.1 + salt * 31.0)
end

local function drawParallaxBackground(camera)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local camX = camera.x or 0
  local camY = camera.y or 0
  local scale = camera.scale or 1

  for _, layer in ipairs(STAR_LAYERS) do
    -- Posição "virtual" do mundo nesta camada, aplicando o fator de paralaxe.
    -- Camadas com parallax baixo se movem menos que a câmera real,
    -- dando a sensação de estarem mais distantes.
    local layerX = camX * layer.parallax
    local layerY = camY * layer.parallax

    -- Área visível em coordenadas de mundo (ajustado pelo zoom)
    local viewW = sw / scale
    local viewH = sh / scale

    local cell = layer.cellSize
    local startCx = math.floor((layerX - viewW / 2) / cell) - 1
    local endCx   = math.floor((layerX + viewW / 2) / cell) + 1
    local startCy = math.floor((layerY - viewH / 2) / cell) - 1
    local endCy   = math.floor((layerY + viewH / 2) / cell) + 1

    love.graphics.setColor(layer.color)

    for cx = startCx, endCx do
      for cy = startCy, endCy do
        for i = 1, layer.starsPerCell do
          local salt = i * 97
          local rx = hashCell(cx, cy, salt)
          local ry = hashCell(cx, cy, salt + 1)
          local rs = hashCell(cx, cy, salt + 2)

          -- Posição da estrela dentro da célula (espaço da camada)
          local worldX = cx * cell + rx * cell
          local worldY = cy * cell + ry * cell

          -- Converte para tela, relativo ao deslocamento desta camada
          local screenX = (worldX - layerX) * scale + sw / 2
          local screenY = (worldY - layerY) * scale + sh / 2

          if screenX >= -10 and screenX <= sw + 10
          and screenY >= -10 and screenY <= sh + 10 then
            local size = layer.sizeRange[1]
                + rs * (layer.sizeRange[2] - layer.sizeRange[1])
            love.graphics.circle("fill", screenX, screenY, size)
          end
        end
      end
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

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
    local c = laser.color
    local fadeT = laser.lifetime / (laser.maxLifetime or laser.lifetime)
    local dirX = math.cos(laser.angle)
    local dirY = math.sin(laser.angle)
    local endX = laser.x + dirX * laser.range
    local endY = laser.y + dirY * laser.range
    if laser.hitX == nil then
      laser.hitX = endX
    end
    if laser.hitY == nil then
      laser.hitY = endY
    end

    -- Halo externo (largo, fraco)
    love.graphics.setColor(c[1], c[2], c[3], 0.15 * fadeT)
    love.graphics.setLineWidth(8)
    love.graphics.line(laser.x, laser.y, laser.hitX, laser.hitY)

    -- Halo médio
    love.graphics.setColor(c[1], c[2], c[3], 0.35 * fadeT)
    love.graphics.setLineWidth(4)
    love.graphics.line(laser.x, laser.y, laser.hitX, laser.hitY)

    -- Núcleo brilhante (quase branco)
    love.graphics.setColor(
      math.min(1, c[1] + 0.5),
      math.min(1, c[2] + 0.5),
      math.min(1, c[3] + 0.5),
      fadeT)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(laser.x, laser.y, laser.hitX, laser.hitY)

    love.graphics.setLineWidth(1)

    -- Flash no ponto de impacto
    love.graphics.setColor(c[1], c[2], c[3], 0.6 * fadeT)
    love.graphics.circle("fill", laser.hitX, laser.hitY, 4 * fadeT)
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
    local t = 1 - (explosion.duration / (explosion.maxDuration or 1))  -- 0 → 1
    local c = explosion.color

    -- Núcleo: começa cheio, encolhe e esmaece
    local coreAlpha  = (c[4] or 1) * (1 - t)
    local coreRadius = explosion.radius * (1 - t * 0.6)
    love.graphics.setColor(c[1], c[2], c[3], coreAlpha)
    love.graphics.circle("fill", explosion.x, explosion.y, coreRadius)

    -- Anel de choque: expande até o raio total e desaparece
    local ringAlpha  = (1 - t) * 0.6
    local ringRadius = explosion.radius * t
    love.graphics.setColor(1, 0.9, 0.6, ringAlpha)
    love.graphics.setLineWidth(3 * (1 - t) + 1)
    love.graphics.circle("line", explosion.x, explosion.y, ringRadius)
    love.graphics.setLineWidth(1)
  end
end

local function drawInventory()
  config.InventoryUI.draw()
end

local function drawProperty()
  config.PropertyUI.draw()
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
    drawParallaxBackground(camera)
    camera:attach()
        drawWorldLayer()
        drawExplosion()
        drawPulse()
        drawMine()
        drawProjectiles()
        drawLaser()
        -- drawParallaxBackground()
    camera:detach()
    config.HudUI.draw(playerFlagShip,camera)
    drawInventory()
    drawProperty()
    drawDebugOverlay(playerFlagShip)
end


return Rendering
