local CommUI = {}

local PORTRAIT_W = 80
local PORTRAIT_H = 80

local C = {
  bg           = {0.06, 0.03, 0.01, 0.97},
  bgDark       = {0.04, 0.02, 0.01, 1},
  bgRow        = {0.08, 0.04, 0.02, 1},
  bgRowHover   = {0.12, 0.06, 0.02, 1},
  border       = {0.23, 0.13, 0.05, 1},
  borderAccent = {0.75, 0.38, 0.13, 1},
  textNormal   = {0.78, 0.62, 0.42, 1},
  textBright   = {0.92, 0.78, 0.58, 1},
  textMuted    = {0.38, 0.22, 0.10, 1},
  textActive   = {0.88, 0.60, 0.22, 1},
  textTarget   = {0.60, 0.80, 0.90, 1},  -- fala do alvo
  textPlayer   = {0.78, 0.62, 0.42, 1},  -- fala do player
  textSystem   = {0.50, 0.50, 0.50, 1},  -- mensagens de sistema
  overlay      = {0.00, 0.00, 0.00, 0.55},
  feedBg       = {0.04, 0.02, 0.01, 0.80},
}

-- Fonts (lazy init)
local fontLog, fontBtn, fontName, fontHint

local function initFonts()
  if fontLog then return end
  fontLog  = love.graphics.newFont(11)
  fontBtn  = love.graphics.newFont(12)
  fontName = love.graphics.newFont(13)
  fontHint = love.graphics.newFont(10)
end

-- Helpers
local function sc(c)
  love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end
local function entityName(e)
  if not e then return "?" end
  return e.name or e.tag or "Desconhecido"
end

-- Monta os botões dependendo do tipo de alvo
local function buildButtons(targetType)
  if targetType == "landable" then
    return {
      { label = "Trocar",    action = "trade"   },
      { label = "Encerrar", action = "close"   },
    }
  else -- npc
    return {
      { label = "Trocar",          action = "trade"   },
      { label = "Recrutar",        action = "recruit" },
      { label = "Demandar tributo",action = "tribute" },
      { label = "Encerrar",       action = "close"   },
    }
  end
end

-- Texto inicial de saudação do alvo
local function greetingText(target, targetType)
  local name = entityName(target)
  if targetType == "landable" then
    return "Bem-vindo a " .. name .. ". Como podemos ajudá-lo?"
  else
    -- NPC: saudação genérica por facção
    local faction = target.profile and target.profile.faction or "Desconhecidos"
    return "[" .. faction .. "] " .. name .. ": \"O que você quer?\""
  end
end

-- Abre o diálogo (chamado internamente após roll de aceitação)
function CommUI._openDialogue(player, target, targetType)
  initFonts()
  config.CommunicationSystem.dialogue.open       = true
  config.CommunicationSystem.dialogue.target     = target
  config.CommunicationSystem.dialogue.targetType = targetType
  config.CommunicationSystem.dialogue.player     = player
  config.CommunicationSystem.dialogue.log        = {}
  config.CommunicationSystem.dialogue.scrollY    = 0
  config.CommunicationSystem.dialogue.buttons    = buildButtons(targetType)

  -- Saudação inicial do alvo
  table.insert(config.CommunicationSystem.dialogue.log, {
    text = greetingText(target, targetType),
    side = "target",
  })

  config.Input.pushContext("comm")
end

-- API pública: player inicia comunicação com o alvo atual do targeting
function CommUI.openComm(player)
  local target = config.TargetingSystem and config.TargetingSystem.current
  if not target then
    config.CommunicationSystem.pushFeed("Nenhum alvo selecionado.", C.textMuted)
    return
  end

  local validity, shapetype = config.TargetingSystem.isValidTarget(target)
  if not validity then
    config.CommunicationSystem.pushFeed("Alvo inválido.", C.textMuted)
    return
  end

  if shapetype == "nobody" then
    -- Landable: aceita sempre
    CommUI._openDialogue(player, target, "landable")
  else
    -- NPC: envia mensagem para a inbox, o NPC decide no próximo frame
    local npc = nil
    for _, n in ipairs(config.Entities.getByTag("npc")) do
      if n.ship == target or n == target then npc = n; break end
    end
    if npc then
      config.CommunicationSystem.sendMessage(npc, { type = "openComm", sender = player })
      config.CommunicationSystem.pushFeed("Abrindo canal com " .. entityName(target) .. "...", C.textMuted)
    else
      -- Nave sem NPC wrapper (ex: escort do player): abre direto
      CommUI._openDialogue(player, target, "npc")
    end
  end
end

function CommUI.closeDialogue()
  if not config.CommunicationSystem.dialogue.open then return end
  config.CommunicationSystem.dialogue.open = false
  config.Input.popContext("comm")
end

function CommUI.isOpen()
  return config.CommunicationSystem.dialogue.open
end

local function drawDialogue()
  if not config.CommunicationSystem.dialogue.open then return end
  initFonts()

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local mx, my = love.mouse.getPosition()

  local panelW  = 480
  local panelH  = 420
  local btnH    = 32
  local btnPad  = 8
  local padding = 14

  local numBtn  = #config.CommunicationSystem.dialogue.buttons
  local btnAreaH = numBtn * (btnH + btnPad) - btnPad + 16
  local headerH  = 36
  local logH     = panelH - headerH - btnAreaH - padding * 2

  local px = math.floor(sw / 2 - panelW / 2)
  local py = math.floor(sh / 2 - panelH / 2)

  -- Overlay
  sc(C.overlay)
  love.graphics.rectangle("fill", 0, 0, sw, sh)

  -- Painel
  sc(C.bg)
  love.graphics.rectangle("fill", px, py, panelW, panelH, 4)
  sc(C.border)
  love.graphics.rectangle("line", px, py, panelW, panelH, 4)
  sc(C.borderAccent)
  love.graphics.rectangle("fill", px + 1, py + 1, panelW - 2, 2, 4)

  -- Header
  sc(C.bgDark)
  love.graphics.rectangle("fill", px, py, panelW, headerH, 4)
  sc(C.border)
  love.graphics.rectangle("fill", px, py + headerH - 1, panelW, 1)

  love.graphics.setFont(fontName)
  sc(C.textBright)
  local name = entityName(config.CommunicationSystem.dialogue.target)
  love.graphics.print(name, px + padding, py + math.floor(headerH / 2 - fontName:getHeight() / 2))

  sc(C.textMuted)
  love.graphics.setFont(fontHint)
  local typeLabel = config.CommunicationSystem.dialogue.targetType == "landable" and "Instalação" or "Nave"
  local tw = fontHint:getWidth(typeLabel)
  love.graphics.print(typeLabel, px + panelW - padding - tw,
    py + math.floor(headerH / 2 - fontHint:getHeight() / 2))

  -- Área de log com clipping
  local logX = px + padding
  local logY = py + headerH + padding
  local logW = panelW - padding * 2

  love.graphics.setScissor(logX, logY, logW, logH)

  -- Calcula altura total do log
  local lineH = fontLog:getHeight() + 4
  local totalLogH = 0
  local wrappedLines = {}
  for _, entry in ipairs(config.CommunicationSystem.dialogue.log) do
    local lines = {}
    local prefix = entry.side == "player" and "> " or ""
    local fullText = prefix .. entry.text
    -- Wrap manual simples
    local words = {}
    for w in fullText:gmatch("%S+") do table.insert(words, w) end
    local current = ""
    for _, word in ipairs(words) do
      local test = current == "" and word or (current .. " " .. word)
      if fontLog:getWidth(test) <= logW - 8 then
        current = test
      else
        if current ~= "" then table.insert(lines, current) end
        current = word
      end
    end
    if current ~= "" then table.insert(lines, current) end
    table.insert(wrappedLines, { lines = lines, side = entry.side })
    totalLogH = totalLogH + #lines * lineH + 6
  end

  -- Auto-scroll para o final
  local maxScroll = math.max(0, totalLogH - logH)
  if config.CommunicationSystem.dialogue.scrollY > maxScroll then config.CommunicationSystem.dialogue.scrollY = maxScroll end

  local drawY = logY - config.CommunicationSystem.dialogue.scrollY
  for _, entry in ipairs(wrappedLines) do
    local color = entry.side == "target" and C.textTarget or C.textPlayer
    sc(color)
    love.graphics.setFont(fontLog)
    for _, line in ipairs(entry.lines) do
      if drawY + lineH >= logY and drawY <= logY + logH then
        love.graphics.print(line, logX + 4, drawY)
      end
      drawY = drawY + lineH
    end
    drawY = drawY + 6
  end

  love.graphics.setScissor()
  sc(C.border)
  love.graphics.rectangle("line", logX, logY, logW, logH, 2)

  -- Scrollbar do log
  if totalLogH > logH then
    local ratio  = logH / totalLogH
    local thumbH = math.max(16, logH * ratio)
    local thumbY = logY + (config.CommunicationSystem.dialogue.scrollY / maxScroll) * (logH - thumbH)
    sc(C.bgDark)
    love.graphics.rectangle("fill", px + panelW - 6, logY, 4, logH)
    sc(C.border)
    love.graphics.rectangle("fill", px + panelW - 6, thumbY, 4, thumbH, 2)
  end

  -- Divisor antes dos botões
  local footerY = logY + logH + padding
  sc(C.border)
  love.graphics.rectangle("fill", px, footerY - 1, panelW, 1)

  -- Botões
  for i, btn in ipairs(config.CommunicationSystem.dialogue.buttons) do
    local bx = px + 12
    local by = footerY + (i - 1) * (btnH + btnPad)
    local bw = panelW - 24
    local isHov = mx >= bx and mx <= bx + bw and my >= by and my <= by + btnH
    local isDanger = btn.action == "tribute"

    sc(isHov and {0.16, 0.08, 0.02, 1} or C.bgDark)
    love.graphics.rectangle("fill", bx, by, bw, btnH, 3)

    local borderColor = isDanger and {0.6, 0.2, 0.1, 1}
      or (isHov and C.borderAccent or C.border)
    sc(borderColor)
    love.graphics.rectangle("line", bx, by, bw, btnH, 3)

    if isHov then
      sc(C.borderAccent)
      love.graphics.rectangle("fill", bx, by, 2, btnH)
    end

    love.graphics.setFont(fontBtn)
    sc(isDanger and {0.80, 0.35, 0.20, 1} or (isHov and C.textActive or C.textNormal))
    local lw = fontBtn:getWidth(btn.label)
    love.graphics.print(btn.label, bx + math.floor(bw / 2 - lw / 2),
      by + math.floor(btnH / 2 - fontBtn:getHeight() / 2))
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function CommUI.draw()
  drawDialogue()
end
return CommUI
