-- ─────────────────────────────────────────────────────────────────────────────
-- hud_ui.lua  —  HUD do Playing state
-- ─────────────────────────────────────────────────────────────────────────────
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
-- ─────────────────────────────────────────────────────────────────────────────

local HudUI = {}

-- ─────────────────────────────────────────
-- Cores (mesmo tema do projeto)
-- ─────────────────────────────────────────

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
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local MARGIN     = 16
local PANEL_W    = 220
local PANEL_H    = 78
local BAR_H      = 14
local BAR_GAP    = 6
local PADDING    = 10

local fontLabel, fontValue

local function initFonts()
  if fontLabel then return end
  fontLabel = love.graphics.newFont(10)
  fontValue = love.graphics.newFont(12)
end

-- ─────────────────────────────────────────
-- Helpers de desenho
-- ─────────────────────────────────────────

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

-- ─────────────────────────────────────────
-- Painel: Casco / Escudo (inferior esquerdo)
-- ─────────────────────────────────────────

local function drawHullShieldPanel(ship)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local x = MARGIN
  local y = sh - MARGIN - PANEL_H

  -- Corpo do painel
  rect(x, y, PANEL_W, PANEL_H, C.bg, "fill", 4)
  rect(x, y, PANEL_W, PANEL_H, C.border, "line", 4)
  sc(C.borderAccent)
  love.graphics.rectangle("fill", x + 1, y + 1, PANEL_W - 2, 2, 4)

  local barX = x + PADDING
  local barW = PANEL_W - PADDING * 2
  local barY = y + PADDING

  -- ── Escudo ──
  local shield = ship.shield
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
          love.graphics.print("BREACH", barX + barW + 6, barY + math.floor(BAR_H / 2 - fontLabel:getHeight() / 2) - PANEL_H)
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

-- ─────────────────────────────────────────
-- Painel: Gerador / Energia (inferior direito)
-- ─────────────────────────────────────────

local function drawEnergyPanel(ship)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local x = sw - MARGIN - PANEL_W
  local y = sh - MARGIN - PANEL_H

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

      drawBar(barX, barY, barW, BAR_H, ratio, C.energyFill, C.energyBack, "ENERGIA", valueStr)

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

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function HudUI.draw(playerFlagShip)
  if not playerFlagShip then return end
  initFonts()

  drawHullShieldPanel(playerFlagShip)
  drawEnergyPanel(playerFlagShip)

  love.graphics.setColor(1, 1, 1, 1)
end

return HudUI
