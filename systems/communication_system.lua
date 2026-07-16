-- ─────────────────────────────────────────────────────────────────────────────
-- communication_system.lua
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Três responsabilidades:
--   1. MessageQueue  — fila global de mensagens, inbox de NPCs, feed do HUD
--   2. SignalSystem  — broadcast com range, TTL curto, handlers no NpcAI
--   3. DialogueManager — UI de comunicação do player (texto + botões)
--
-- INTEGRAÇÃO
--
--   Playing.update(dt):
--       config.CommunicationSystem.update(playerFlagShip, dt)
--
--   Playing.draw() — após camera:detach(), antes de drawInventory:
--       config.CommunicationSystem.draw()
--
--   Playing.keypressed(key):
--       config.CommunicationSystem.keypressed(key)
--
--   Playing.mousepressed(mx, my, button):
--       config.CommunicationSystem.mousepressed(mx, my, button)
--
-- ─────────────────────────────────────────────────────────────────────────────

local Comm = {}

-- ─────────────────────────────────────────
-- Configuração
-- ─────────────────────────────────────────

local MAX_FEED_MESSAGES = 8     -- mensagens visíveis no HUD (ajustável)
local FEED_MESSAGE_TTL  = 6     -- segundos antes de sumir do feed
local SIGNAL_TTL        = 0.1   -- sinais duram 2 frames (~0.1s)
local ROLL_CD_OPEN      = 5     -- CD para NPC aceitar comunicação
local ROLL_CD_TRIBUTE   = 15    -- CD para demandar tributo
local ROLL_CD_RECRUIT   = 15    -- CD para recrutar

-- ─────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────

-- Feed global (HUD)
Comm.feedMessages = {}
-- { text, sender, ttl, maxTtl, color }

-- Sinais ativos
local activeSignals = {}
-- { source, signalType, x, y, range, payload, ttl }

-- Estado do diálogo aberto
Comm.dialogue = {
  open      = false,
  target    = nil,      -- entidade alvo (npc ou landable)
  targetType = nil,     -- "npc" | "landable"
  log       = {},       -- { text, side } side = "target"|"player"
  buttons   = {},       -- { label, action }
  portrait  = nil,      -- love.Image opcional
  scrollY   = 0,
  totalH    = 0,
}

-- ─────────────────────────────────────────
-- Cores
-- ─────────────────────────────────────────

local C = {
  textNormal   = {0.78, 0.62, 0.42, 1},
  textMuted    = {0.38, 0.22, 0.10, 1},
  textActive   = {0.88, 0.60, 0.22, 1},
  textSystem   = {0.50, 0.50, 0.50, 1},
}

-- ─────────────────────────────────────────
-- Helpers internos
-- ─────────────────────────────────────────

local function rollD12(bonus)
  bonus = bonus or 0
  return love.math.random(1, 12) + bonus
end

-- Reputação do player com uma facção (stub simples)
local function getReputation(player, faction)
  if not player or not player.reputation then return 0 end
  return player.reputation[faction] or 0
end

-- Nome de exibição de uma entidade
local function entityName(e)
  if not e then return "?" end
  return e.name or e.tag or "Desconhecido"
end


-- ─────────────────────────────────────────
-- 1. FEED DE MENSAGENS (HUD)
-- ─────────────────────────────────────────

-- Adiciona uma mensagem ao feed global
function Comm.pushFeed(text, color)
  table.insert(Comm.feedMessages, {
    text   = text,
    color  = color or C.textNormal,
    ttl    = FEED_MESSAGE_TTL,
    maxTtl = FEED_MESSAGE_TTL,
  })
  -- Mantém o limite
  while #Comm.feedMessages > MAX_FEED_MESSAGES do
    table.remove(Comm.feedMessages, 1)
  end
end

function Comm.setFeedLimit(n)
  MAX_FEED_MESSAGES = n
end

-- ─────────────────────────────────────────
-- 2. INBOX DE NPCS
-- ─────────────────────────────────────────

-- Envia uma mensagem para a inbox de um NPC
-- msg = { type, sender, payload }
function Comm.sendMessage(targetNpc, msg)
  if not targetNpc or not targetNpc.ai then return end
  if not targetNpc.ai.inbox then targetNpc.ai.inbox = {} end
  msg.timestamp = love.timer.getTime()
  table.insert(targetNpc.ai.inbox, msg)
end

-- Drena e processa a inbox de um NPC — chame no início do NpcAI.update
-- Retorna true se alguma mensagem foi processada (pode interromper o estado atual)
function Comm.drainInbox(npc, ai, dt)
  if not ai.inbox or #ai.inbox == 0 then return false end
  local processed = false
  local remaining = {}
  for _, msg in ipairs(ai.inbox) do
    local handled = false
    if msg.type == "openComm" then
      -- Player pediu para abrir canal de comunicação
      local player = msg.sender
      local faction = npc.profile and npc.profile.faction or nil
      local rep = getReputation(player, faction)
      local roll = rollD12(rep)
      if roll >= ROLL_CD_OPEN then
        -- NPC aceita: abre o diálogo no próximo frame
        config.CommunicationUI._openDialogue(player, npc, "npc")
      else
        Comm.pushFeed(
          entityName(npc) .. " ignorou sua tentativa de comunicação.",
          C.textMuted
        )
      end
      handled = true
      processed = true
    end
    -- Mensagens não tratadas permanecem na inbox
    if not handled then
      table.insert(remaining, msg)
    end
  end
  ai.inbox = remaining
  return processed
end

-- ─────────────────────────────────────────
-- 3. SINAIS
-- ─────────────────────────────────────────

-- Emite um sinal que será recebido por ouvintes dentro do range
-- source   = entidade emissora
-- sigType  = string identificadora ("beingAttacked", "distressCall", etc)
-- range    = raio em unidades de mundo
-- payload  = tabela opcional com dados extras
function Comm.emitSignal(source, sigType, range, payload)
  local x, y
  if source.rigidbody and source.rigidbody.body then
    x, y = source.rigidbody.body:getPosition()
  else
    x, y = source.x or 0, source.y or 0
  end
  table.insert(activeSignals, {
    source     = source,
    signalType = sigType,
    x          = x,
    y          = y,
    range      = range,
    payload    = payload or {},
    ttl        = SIGNAL_TTL,
  })
end

-- Processa sinais ativos para um NPC e chama o handler adequado
-- handlers = tabela { [sigType] = function(npc, signal) end }
-- Passe config.NpcAI.signalHandlers (definido no npc_ai.lua)
function Comm.processSignals(npc, handlers, dt)
  if not npc.ship or not npc.ship.rigidbody then return end
  local nx, ny = npc.ship.rigidbody.body:getPosition()
  for _, sig in ipairs(activeSignals) do
    if sig.source ~= npc and sig.source ~= npc.ship then
      local dx, dy = nx - sig.x, ny - sig.y
      local dist2  = dx*dx + dy*dy
      if dist2 <= sig.range * sig.range then
        local fn = handlers and handlers[sig.signalType]
        if fn then fn(npc, sig) end
      end
    end
  end
end

-- Processa sinais ativos para o player e exibe no feed
-- playerSignalHandlers = { [sigType] = { show = bool, text = string|function(sig) } }
function Comm.processSignalsForPlayer(player, playerSignalHandlers)
  if not player or not player.rigidbody then return end
  local px, py = player.rigidbody.body:getPosition()
  for _, sig in ipairs(activeSignals) do
    if sig.source ~= player then
      local dx, dy = px - sig.x, py - sig.y
      local dist2  = dx*dx + dy*dy
      if dist2 <= sig.range * sig.range then
        local handler = playerSignalHandlers and playerSignalHandlers[sig.signalType]
        if handler and handler.show then
          local text
          if type(handler.text) == "function" then
            text = handler.text(sig)
          else
            text = handler.text or sig.signalType
          end
          Comm.pushFeed(text, handler.color or C.textSystem)
        end
      end
    end
  end
end

-- ─────────────────────────────────────────
-- 5. AÇÕES DOS BOTÕES (stubs)
-- ─────────────────────────────────────────

local function actionTrade(player, target, targetType)
  -- TODO: abrir MarketUI com o market do target
  table.insert(Comm.dialogue.log, {
    text = "[Player]: \"Quero ver o que você tem pra oferecer.\"",
    side = "player",
  })
  table.insert(Comm.dialogue.log, {
    text = entityName(target) .. ": \"Veja à vontade.\"",
    side = "target",
  })
  -- config.MarketUI.open(target)
end

local function actionRecruit(player, target)
  local faction = target.profile and target.profile.faction or nil
  local rep = getReputation(player, faction)
  local roll = rollD12(rep)
  table.insert(Comm.dialogue.log, {
    text = "[Player]: \"Preciso de mais uma nave na minha ala. Topa?\"",
    side = "player",
  })
  if roll >= ROLL_CD_RECRUIT then
    table.insert(Comm.dialogue.log, {
      text = entityName(target) .. ": \"Certo. Vou cobrir você.\"",
      side = "target",
    })
    Comm.pushFeed(entityName(target) .. " entrou para sua escolta.", C.textActive)
    -- TODO: config.AutopilotSystem.engage(target.ship, "escort", player, {...})
  else
    table.insert(Comm.dialogue.log, {
      text = entityName(target) .. ": \"Não tenho interesse nisso agora.\"",
      side = "target",
    })
    Comm.pushFeed("Recrutamento falhou (rolagem: " .. roll .. "/" .. ROLL_CD_RECRUIT .. ").", C.textMuted)
  end
end

local function actionTribute(player, target)
  local faction = target.profile and target.profile.faction or nil
  local rep = getReputation(player, faction)
  local roll = rollD12(rep)
  table.insert(Comm.dialogue.log, {
    text = "[Player]: \"Pague o pedágio ou vire destroços.\"",
    side = "player",
  })
  if roll >= ROLL_CD_TRIBUTE then
    local amount = love.math.random(500, 2000)
    table.insert(Comm.dialogue.log, {
      text = entityName(target) .. ": \"...Aqui está. Agora me deixe em paz.\"",
      side = "target",
    })
    Comm.pushFeed("Você recebeu " .. amount .. " créditos.", C.textActive)
    -- TODO: player.credits = player.credits + amount
  else
    table.insert(Comm.dialogue.log, {
      text = entityName(target) .. ": \"Você não me assusta. Prepare-se!\"",
      side = "target",
    })
    Comm.pushFeed("Tributo recusado. " .. entityName(target) .. " ficou hostil!", C.textSystem)
    -- TODO: marcar target como hostil
    config.CommunicationUI.closeDialogue()
  end
end

local actionHandlers = {
  trade   = actionTrade,
  recruit = actionRecruit,
  tribute = actionTribute,
  close   = function() config.CommunicationUI.closeDialogue() end,
}

local function handleButtonAction(action)
  local fn = actionHandlers[action]
  if fn then
    fn(Comm.dialogue.player, Comm.dialogue.target, Comm.dialogue.targetType)
  end
end

-- ─────────────────────────────────────────
-- 6. UPDATE
-- ─────────────────────────────────────────

function Comm.update(player, dt)
  -- Atualiza TTL do feed
  local keepFeed = {}
  for _, msg in ipairs(Comm.feedMessages) do
    msg.ttl = msg.ttl - dt
    if msg.ttl > 0 then
      table.insert(keepFeed, msg)
    end
  end
  Comm.feedMessages = keepFeed

  -- Atualiza TTL dos sinais
  local keepSignals = {}
  for _, sig in ipairs(activeSignals) do
    sig.ttl = sig.ttl - dt
    if sig.ttl > 0 then
      table.insert(keepSignals, sig)
    end
  end
  activeSignals = keepSignals

  -- Fecha diálogo com ui_cancel
  if Comm.dialogue.open and config.Input.state.ui_cancel then
    config.CommunicationUI.closeDialogue()
  end
end

-- ─────────────────────────────────────────
-- 7. INPUT
-- ─────────────────────────────────────────

function Comm.keypressed(key)
  if not Comm.dialogue.open then return end
  if key == "escape" then config.CommunicationUI.closeDialogue() end
end

function Comm.mousepressed(mx, my, button)
  if not Comm.dialogue.open then return end
  if button ~= 1 then return end

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  -- Geometria dos botões (calculada igual ao draw)
  local panelW = 480
  local btnH   = 32
  local btnPad = 8
  local px     = math.floor(sw / 2 - panelW / 2)
  local numBtn = #Comm.dialogue.buttons
  local btnsH  = numBtn * (btnH + btnPad) - btnPad + 16
  local panelH = 420
  local py     = math.floor(sh / 2 - panelH / 2)
  local footerY = py + panelH - btnsH - 12

  for i, btn in ipairs(Comm.dialogue.buttons) do
    local bx = px + 12
    local by = footerY + (i - 1) * (btnH + btnPad)
    local bw = panelW - 24
    if mx >= bx and mx <= bx + bw and my >= by and my <= by + btnH then
      handleButtonAction(btn.action)
      return
    end
  end

  -- Clique fora do painel fecha
  if mx < px or mx > px + panelW or my < py or my > py + panelH then
    config.CommunicationUI.closeDialogue()
  end
end

function Comm.wheelmoved(dx, dy)
  if not Comm.dialogue.open then return end
  Comm.dialogue.scrollY = Comm.dialogue.scrollY - dy * 20
  if Comm.dialogue.scrollY < 0 then Comm.dialogue.scrollY = 0 end
end

return Comm
