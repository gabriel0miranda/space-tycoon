-- hud_ui.lua  —  HUD do Playing state
--
-- Primeira versão: casco/escudo (canto inferior esquerdo) e energia/gerador
-- (canto inferior direito). RCS, arma equipada e mira ficam para versões
-- futuras — os espaços já estão reservados no layout.
--
-- USO
--
--   function Playing.draw()
--       ...
--       config.HudUI.draw(playerFlagShip)
--   end
--
-- Não precisa de update/input — é só leitura dos componentes da entidade.

local HudUI = {}

-- Cores (mesmo tema do projeto)

local C = {
  bg          = {0.06, 0.03, 0.01, 0.85},
  bgDark      = {0.04, 0.02, 0.01, 1},
  border      = {0.23, 0.13, 0.05, 1},
  borderAccent= {0.75, 0.38, 0.13, 1},
  textNormal  = {0.78, 0.62, 0.42, 1},
  textBright  = {0.92, 0.78, 0.58, 1},
  textMuted   = {0.38, 0.22, 0.10, 1},

  -- Barras
  shieldFill  = {0.35, 0.65, 0.85, 1},
  shieldBack  = {0.12, 0.18, 0.22, 1},
  hullFill    = {0.80, 0.35, 0.20, 1},
  hullBack    = {0.18, 0.10, 0.06, 1},
  hullCrit    = {0.90, 0.15, 0.15, 1},   -- casco abaixo de 25%
  energyFill  = {0.85, 0.65, 0.20, 1},
  energyBack  = {0.18, 0.13, 0.06, 1},
  cooldownTint= {0.30, 0.45, 0.55, 0.5}, -- overlay quando escudo em cooldown
  -- Outros
  reticule = {0.99,0.8, 0.2,1},
  reticuleLocked = {0.9,0.5, 0.1, 1},
}

-- Layout

local MARGIN     = 16
local PANEL_W    = 220
local PANEL_H    = 78
local BAR_H      = 14
local BAR_GAP    = 6
local PADDING    = 10

-- Cantos da tela

HudUI.Corner = {
  TOP_LEFT     = "top_left",
  TOP_RIGHT    = "top_right",
  BOTTOM_LEFT  = "bottom_left",
  BOTTOM_RIGHT = "bottom_right",
}

-- Retorna x, y (canto superior-esquerdo do painel) para que um painel
-- de tamanho (w, h) fique ancorado no `corner` escolhido, respeitando
-- a margem padrão.
local function getCornerPosition(corner, w, h)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  local x, y
  if corner == HudUI.Corner.TOP_LEFT then
      x, y = MARGIN, MARGIN
  elseif corner == HudUI.Corner.TOP_RIGHT then
      x, y = sw - MARGIN - w, MARGIN
  elseif corner == HudUI.Corner.BOTTOM_LEFT then
      x, y = MARGIN, sh - MARGIN - h
  elseif corner == HudUI.Corner.BOTTOM_RIGHT then
      x, y = sw - MARGIN - w, sh - MARGIN - h
  else
      x, y = MARGIN, MARGIN  -- fallback
  end

  return x, y
end

local fontLabel, fontValue

local function initFonts()
  if fontLabel then return end
  fontLabel = love.graphics.newFont(10)
  fontValue = love.graphics.newFont(12)
end

-- Helpers de desenho

local function sc(c)
  love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function rect(x, y, w, h, color, mode, r)
  sc(color)
  love.graphics.rectangle(mode or "fill", x, y, w, h, r or 2)
end

-- Desenha uma barra de progresso com label + valor numérico
-- ratio: 0.0–1.0
local function drawBar(x, y, w, h, ratio, fillColor, backColor, label, valueStr)
  ratio = math.max(0, math.min(1, ratio))

  -- Fundo
  rect(x, y, w, h, backColor, "fill", 2)
  rect(x, y, w, h, C.border, "line", 2)

  -- Preenchimento
  if ratio > 0 then
    rect(x + 1, y + 1, (w - 2) * ratio, h - 2, fillColor, "fill", 1)
  end

  -- Label dentro da barra (canto esquerdo)
  love.graphics.setFont(fontLabel)
  sc(C.textBright)
  love.graphics.print(label, x + 6, y + math.floor(h / 2 - fontLabel:getHeight() / 2))

  -- Valor (canto direito)
  if valueStr then
    local tw = fontLabel:getWidth(valueStr)
    love.graphics.print(valueStr, x + w - tw - 6, y + math.floor(h / 2 - fontLabel:getHeight() / 2))
  end
end

-- Painel: Casco / Escudo (inferior esquerdo)

local function drawHullShieldPanel(ship, corner)
  local x, y = getCornerPosition(corner, PANEL_W, PANEL_H)

  -- Corpo do painel
  rect(x, y, PANEL_W, PANEL_H, C.bg, "fill", 4)
  rect(x, y, PANEL_W, PANEL_H, C.border, "line", 4)
  sc(C.borderAccent)
  love.graphics.rectangle("fill", x + 1, y + 1, PANEL_W - 2, 2, 4)

  local barX = x + PADDING
  local barW = PANEL_W - PADDING * 2
  local barY = y + PADDING

  -- ── Escudo ──
  local shield = ship.shields
  if shield then
    local ratio = shield.totalCapacity > 0
      and (shield.currentCapacity / shield.totalCapacity) or 0
    local valueStr = math.floor(shield.currentCapacity) .. " / " .. math.floor(shield.totalCapacity)

    drawBar(barX, barY, barW, BAR_H, ratio, C.shieldFill, C.shieldBack, "ESCUDO", valueStr)

    -- Overlay de cooldown (escudo não recarrega ainda)
    if shield.currentCooldown and shield.currentCooldown > 0 then
      sc(C.cooldownTint)
      love.graphics.rectangle("fill", barX + 1, barY + 1, barW - 2, BAR_H - 2, 1)
    end

    -- Indicador "desativado"
    if shield.active == false then
      love.graphics.setFont(fontLabel)
      sc({0.9, 0.3, 0.3, 1})
      local label = "OFFLINE"
      local tw = fontLabel:getWidth(label)
      love.graphics.print(label, barX + barW / 2 - tw / 2, barY + math.floor(BAR_H / 2 - fontLabel:getHeight() / 2))
    end
  else
    drawBar(barX, barY, barW, BAR_H, 0, C.shieldFill, C.shieldBack, "ESCUDO", "—")
  end

  barY = barY + BAR_H + BAR_GAP

  -- ── Casco ──
  local hull = ship.hull
  if hull then
    local ratio = hull.health > 0
      and (hull.currentHealth / hull.health) or 0
    local valueStr = math.floor(hull.currentHealth) .. " / " .. math.floor(hull.health)

    local fillColor = ratio < 0.25 and C.hullCrit or C.hullFill
    drawBar(barX, barY, barW, BAR_H, ratio, fillColor, C.hullBack, "CASCO", valueStr)

    -- Pulso de aviso quando crítico
    if ratio < 0.25 then
      local pulse = (math.sin(love.timer.getTime() * 6) + 1) / 2  -- 0..1
      sc({1, 0.2, 0.2, 0.3 + pulse * 0.3})
      love.graphics.rectangle("line", barX, barY, barW, BAR_H, 2)
    end

    if hull.breached then
      love.graphics.setFont(fontLabel)
      sc({1, 0.3, 0.1, 1})
      love.graphics.print("BREACH", barX + barW + 6, barY + math.floor(BAR_H / 2 - fontLabel:getHeight() / 2))
    end
  else
    drawBar(barX, barY, barW, BAR_H, 0, C.hullFill, C.hullBack, "CASCO", "—")
  end

  barY = barY + BAR_H + BAR_GAP

  -- ── RCS (placeholder simples — status binário) ──
  love.graphics.setFont(fontLabel)
  local rcsOn = ship.intent and ship.intent.dampAngular
  sc(C.textMuted)
  love.graphics.print("RCS", barX, barY)
  sc(rcsOn and {0.4, 0.85, 0.5, 1} or {0.85, 0.4, 0.3, 1})
  local rcsLabel = rcsOn and "ON" or "OFF"
  love.graphics.print(rcsLabel, barX + 32, barY)
end

-- Painel: Gerador / Energia (inferior direito)

local function drawEnergyPanel(ship, corner)
    local x, y = getCornerPosition(corner, PANEL_W, PANEL_H)

    rect(x, y, PANEL_W, PANEL_H, C.bg, "fill", 4)
    rect(x, y, PANEL_W, PANEL_H, C.border, "line", 4)
    sc(C.borderAccent)
    love.graphics.rectangle("fill", x + 1, y + 1, PANEL_W - 2, 2, 4)

    local barX = x + PADDING
    local barW = PANEL_W - PADDING * 2
    local barY = y + PADDING

    local gen = ship.generator
    if gen then
        -- "Output usado" = soma do que escudo + armas estão consumindo neste frame.
        -- Se o seu EnergySystem expõe isso diretamente (ex: gen.currentOutput),
        -- use esse valor; o cálculo abaixo é um fallback simples.
        local used = gen.currentOutput or 0
        local ratio = gen.maxOutput > 0 and (used / gen.maxOutput) or 0
        local valueStr = math.floor(used) .. " / " .. math.floor(gen.maxOutput)

        drawBar(barX, barY, barW, BAR_H, ratio, C.energyFill, C.energyBack, "USO DE ENERGIA", valueStr)

        barY = barY + BAR_H + BAR_GAP

        -- Modo de roteamento
        love.graphics.setFont(fontLabel)
        sc(C.textMuted)
        love.graphics.print("MODO", barX, barY)

        local modeLabels = {
            balanced       = "Balanceado",
            weaponPriority = "Prioridade: Armas",
            shieldsOnly    = "Prioridade: Escudos",
        }
        sc(C.textBright)
        local modeStr = modeLabels[gen.routingMode] or gen.routingMode or "—"
        local tw = fontLabel:getWidth(modeStr)
        love.graphics.print(modeStr, barX + barW - tw, barY)

        barY = barY + BAR_H + BAR_GAP
    else
        drawBar(barX, barY, barW, BAR_H, 0, C.energyFill, C.energyBack, "ENERGIA", "—")
        barY = barY + BAR_H + BAR_GAP * 2
    end

    -- ── Arma equipada + capacitor ──
    local weapon = ship.weapons and ship.weapons[ship.currentWeapon]
    love.graphics.setFont(fontLabel)
    if weapon then
        sc(C.textMuted)
        love.graphics.print("ARMA", barX, barY)
        sc(C.textBright)
        local nameStr = weapon.def.name or weapon.def.type or "?"
        local tw = fontLabel:getWidth(nameStr)
        love.graphics.print(nameStr, barX + barW - tw, barY)

        -- Mini barra de capacitor abaixo
        local capY = barY + fontLabel:getHeight() + 2
        local cap = weapon.capacitor
        if cap and cap.max and cap.max > 0 then
            local capRatio = cap.current / cap.max
            rect(barX, capY, barW, 4, C.energyBack, "fill", 1)
            if capRatio > 0 then
                local ready = capRatio >= 1
                local fillC = ready and {0.5, 0.9, 0.4, 1} or C.energyFill
                rect(barX, capY, barW * capRatio, 4, fillC, "fill", 1)
            end
        end
    else
        sc(C.textMuted)
        love.graphics.print("ARMA", barX, barY)
        sc(C.textBright)
        love.graphics.print("—", barX + barW - fontLabel:getWidth("—"), barY)
    end
end

-- Minimapa: Asteroides e naves

local function drawMinimap(ship, corner, camera)
  if not ship then return end

  local sw = love.graphics.getWidth()
  local sh = love.graphics.getHeight()
  local PANEL_W = 80
  local PANEL_H = 80

  local size   = 160
  --local margin = 16
  --local cx     = sw - margin - size / 2
  --local cy     = sh - margin - size / 2
  local cx, cy = getCornerPosition(corner, PANEL_W, PANEL_H)

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

  local playerX, playerY = ship.rigidbody.body:getPosition()

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

-- Targeting: retículo e info
local function getEntityRadius(e)
  if e.sprite and e.sprite.shape then
    return e.sprite.shape:getRadius() or 20
  end
  return 25
end

local function drawTargetInfo(camera)
  local target = config.TargetingSystem.current
  if not target then return end
  if not config.TargetingSystem.isValidTarget(target) then return end

  local tx, ty = target.rigidbody.body:getPosition()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  -- Converte posição do alvo para tela
  local sx, sy = camera:toScreen(tx, ty)

  -- Linha pontilhada do centro da tela até o alvo (só se estiver na tela)
  local onScreen = sx >= 0 and sx <= sw and sy >= 0 and sy <= sh
  if not onScreen then
      -- Indicador de fora da tela: seta na borda
      local cx, cy = sw / 2, sh / 2
      local dx, dy = sx - cx, sy - cy
      local angle  = math.atan2(dy, dx)
      local margin = 40
      local bx = cx + math.cos(angle) * (sw / 2 - margin)
      local by = cy + math.sin(angle) * (sh / 2 - margin)
      bx = math.max(margin, math.min(sw - margin, bx))
      by = math.max(margin, math.min(sh - margin, by))

      local color = config.TargetingSystem.locked and C.reticuleLocked or C.reticule
      love.graphics.setColor(color)
      love.graphics.push()
          love.graphics.translate(bx, by)
          love.graphics.rotate(angle)
          love.graphics.polygon("fill", 0, 0, -10, -5, -10, 5)
      love.graphics.pop()
  end

  -- Label: nome + hull (se tiver)
  local font = love.graphics.getFont()
  local label = target.name or target.type or "?"
  if target.hull then
      local pct = math.floor(target.hull.currentHealth / target.hull.health * 100)
      label = label .. "  " .. pct .. "%"
  end
  local lockStr = config.TargetingSystem.locked and " [LOCK]" or ""
  label = label .. lockStr

  local lx = math.max(4, math.min(sw - font:getWidth(label) - 4, sx - font:getWidth(label) / 2))
  local ly = math.max(4, sy - getEntityRadius(target) / (camera.scale or 1) - 20)

  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", lx - 4, ly - 2, font:getWidth(label) + 8, font:getHeight() + 4, 2)

  local color = config.TargetingSystem.locked and C.reticuleLocked or C.reticule
  love.graphics.setColor(color)
  love.graphics.print(label, lx, ly)

  love.graphics.setColor(1, 1, 1, 1)
end

-- API pública

-- opts (opcional):
--   opts.hullShieldCorner — HudUI.Corner, padrão BOTTOM_LEFT
--   opts.energyCorner     — HudUI.Corner, padrão TOP_RIGHT
--   opts.minimapCorner    - HudUI.Corner, padrão BOTTOM_RIGHT
function HudUI.draw(playerFlagShip, camera, opts)
  if not playerFlagShip then return end
  initFonts()
  opts = opts or {}

  drawHullShieldPanel(playerFlagShip, opts.hullShieldCorner or HudUI.Corner.BOTTOM_LEFT)
  drawEnergyPanel(playerFlagShip, opts.energyCorner or HudUI.Corner.TOP_RIGHT)
  drawMinimap(playerFlagShip, opts.minimapCorner or HudUI.Corner.BOTTOM_RIGHT, camera)
  drawTargetInfo(camera)

  love.graphics.setColor(1, 1, 1, 1)
end

return HudUI
