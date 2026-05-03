local Landed = {}

-- ─────────────────────────────────────────
-- Estado local
-- ─────────────────────────────────────────

local playerFlagShip        = nil
local activePanel = "trade"
local allButtonsFlat = {}
local hoveredBtn  = nil
local leftButtons = {}
local rightButtons= {}
local mousedx, mousedy

-- ─────────────────────────────────────────
-- Mapeamentos
-- ─────────────────────────────────────────

local buttonLabels = {
    trade     = "Trading",
    bar       = "Bar",
    bank      = "Bank",
    shipyard  = "Shipyard",
    outfitter = "Outfitter",
    contracts = "Contracts",
    spaceport = "Spaceport",
    depart    = "Depart",
}

local buttonScenes = {
    trade     = "station",
    bar       = "bar",
    bank      = "bank",
    shipyard  = "shipyard",
    outfitter = "station",
    contracts = "contracts",
    spaceport = "station",
    depart    = "space",
}

-- ─────────────────────────────────────────
-- Cores (tema #663300)
-- ─────────────────────────────────────────

local C = {
    bg          = {0.06, 0.03, 0.01, 1},
    bgPanel     = {0.08, 0.04, 0.02, 1},
    bgBtn       = {0.08, 0.04, 0.02, 1},
    bgBtnHover  = {0.14, 0.07, 0.02, 1},
    bgBtnActive = {0.12, 0.06, 0.02, 1},
    border      = {0.23, 0.13, 0.05, 1},
    borderAccent= {0.75, 0.38, 0.13, 1},
    borderDanger= {0.45, 0.12, 0.06, 1},
    textNormal  = {0.78, 0.62, 0.42, 1},
    textBright  = {0.92, 0.78, 0.58, 1},
    textMuted   = {0.38, 0.22, 0.10, 1},
    textActive  = {0.88, 0.60, 0.22, 1},
    textDanger  = {0.87, 0.30, 0.18, 1},
    sceneOverlay= {0.06, 0.03, 0.01, 0.55},
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local L = {
    marginX = 60,
    marginY = 40,
    btnW    = 110,
    btnH    = 32,
    btnGap  = 4,
    sceneH  = 200,
    padX    = 14,
    padY    = 10,
    lineH   = 16,
}

-- ─────────────────────────────────────────
-- Geometria
-- ─────────────────────────────────────────

local G = {}

local function getOwnedShipsCount(player)
    local count = 0
    for _ in pairs(player.property.properties) do count = count + 1 end
    return count
end

local function handleDepart()
  local player = config.Entities.getByTag("player")[1]
  local shipsCount = getOwnedShipsCount(player)
  if shipsCount > 1 then
    -- Ativa um estado de UI para o jogador escolher a nave
    -- player.choosingShip = true 
    print("Qual nave você deseja pilotar?")
    -- Protótipo de verificação de escolta futura:
    -- if player.hasAutoPilotModule or player.hiredPilots > 0 then
    --    print("Você pode decolar com sua frota completa!")
    -- end
    activePanel = "depart"
    config.Input.state.paused = false
    print("departing")
    config.GameState.switch("playing", { resuming = true })
  else
    -- Decolagem normal se só tiver uma nave
    activePanel = "depart"
    config.Input.state.paused = false
    print("departing")
    config.GameState.switch("playing", { resuming = true })
  end
end

local function recalcGeometry()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    G.x = L.marginX
    G.y = L.marginY
    G.w = sw - L.marginX * 2
    G.h = sh - L.marginY * 2

    G.leftX  = G.x
    G.leftW  = L.btnW
    G.rightX = G.x + G.w - L.btnW
    G.rightW = L.btnW

    G.centerX = G.leftX + G.leftW + 2
    G.centerW = G.rightX - G.centerX - 2

    G.sceneX = G.x
    G.sceneY = G.y
    G.sceneW = G.w
    G.sceneH = L.sceneH

    G.contentY = G.sceneY + G.sceneH + 2
    G.contentH = G.h - G.sceneH - 2

    G.leftBtnY  = {}
    G.rightBtnY = {}
    for i = 1, math.max(#leftButtons, 8) do
        G.leftBtnY[i]  = G.contentY + (i - 1) * (L.btnH + L.btnGap)
        G.rightBtnY[i] = G.contentY + (i - 1) * (L.btnH + L.btnGap)
    end

    G.textX = G.centerX + L.padX
    G.textY = G.contentY + L.padY + 40
end

-- ─────────────────────────────────────────
-- Cenas (arte procedural — tema marrom)
-- ─────────────────────────────────────────

local function starField()
    local stars = {
        {40,25},{180,15},{290,50},{70,140},{240,150},
        {480,35},{410,120},{140,160},{350,30},{520,100},
    }
    love.graphics.setColor(0.78, 0.68, 0.48, 0.45)
    for _, s in ipairs(stars) do
        love.graphics.circle("fill", G.sceneX + s[1], G.sceneY + s[2], 1.2)
    end
end

local function drawSceneStation()
    love.graphics.setColor(0.04, 0.02, 0.01)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)
    starField()

    local cx = G.sceneX + G.sceneW / 2
    local cy = G.sceneY + G.sceneH / 2

    -- Planeta distante
    love.graphics.setColor(0.12, 0.06, 0.02)
    love.graphics.circle("fill", G.sceneX + 80, G.sceneY + 55, 32)
    love.graphics.setColor(0.20, 0.10, 0.04, 0.5)
    love.graphics.circle("fill", G.sceneX + 80, G.sceneY + 55, 26)

    -- Anel
    love.graphics.setColor(0.18, 0.10, 0.04)
    love.graphics.rectangle("fill", cx - 70, cy - 5, 140, 10, 2)

    -- Corpo
    love.graphics.setColor(0.12, 0.06, 0.03)
    love.graphics.rectangle("fill", cx - 16, cy - 40, 32, 80, 3)

    -- Núcleo
    love.graphics.setColor(0.08, 0.04, 0.02)
    love.graphics.circle("fill", cx, cy, 22)
    love.graphics.setColor(0.75, 0.38, 0.13, 0.5)
    love.graphics.circle("line", cx, cy, 22)

    -- Braços
    love.graphics.setColor(0.12, 0.07, 0.03)
    love.graphics.rectangle("fill", cx - 110, cy - 4, 50, 8, 1)
    love.graphics.rectangle("fill", cx + 60,  cy - 4, 50, 8, 1)

    -- Luzes
    love.graphics.setColor(0.88, 0.55, 0.18, 0.9)
    love.graphics.circle("fill", cx - 105, cy, 2)
    love.graphics.circle("fill", cx + 105, cy, 2)
    love.graphics.circle("fill", cx, cy - 38, 2)
end

local function drawSceneBar()
    love.graphics.setColor(0.05, 0.03, 0.01)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)
    starField()

    local bx = G.sceneX + G.sceneW / 2 - 110
    local by = G.sceneY + 30

    love.graphics.setColor(0.08, 0.04, 0.02)
    love.graphics.rectangle("fill", bx, by, 220, 130, 3)
    love.graphics.setColor(0.23, 0.13, 0.05)
    love.graphics.rectangle("line", bx, by, 220, 130, 3)

    -- Balcão
    love.graphics.setColor(0.14, 0.07, 0.03)
    love.graphics.rectangle("fill", bx + 10, by + 80, 200, 30, 2)
    love.graphics.setColor(0.30, 0.16, 0.06)
    love.graphics.rectangle("line", bx + 10, by + 80, 200, 30, 2)

    -- Garrafas
    local bottleX = {bx+30, bx+55, bx+80, bx+105, bx+130}
    for _, bx2 in ipairs(bottleX) do
        love.graphics.setColor(0.20, 0.10, 0.04)
        love.graphics.rectangle("fill", bx2, by + 50, 10, 28, 2)
        love.graphics.setColor(0.40, 0.22, 0.08)
        love.graphics.rectangle("fill", bx2 + 3, by + 46, 4, 6, 1)
    end

    -- Silhuetas de clientes
    love.graphics.setColor(0.10, 0.05, 0.02)
    for i = 0, 2 do
        local px = bx + 30 + i * 70
        love.graphics.circle("fill", px, by + 72, 10)
        love.graphics.rectangle("fill", px - 8, by + 82, 16, 20, 2)
    end

    love.graphics.setColor(0.38, 0.22, 0.10)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("THE RUSTY ANCHOR", bx + 8, by + 6, 0, 0.82, 0.82)
end

local function drawSceneSpace()
    love.graphics.setColor(0.02, 0.01, 0.01)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)
    starField()

    local cx = G.sceneX + G.sceneW / 2
    local cy = G.sceneY + G.sceneH / 2

    love.graphics.setColor(0.14, 0.06, 0.02)
    love.graphics.circle("fill", cx, cy, 28)
    love.graphics.setColor(0.22, 0.10, 0.04, 0.5)
    love.graphics.circle("fill", cx, cy, 20)

    love.graphics.setColor(0.75, 0.38, 0.13, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(cx - 160, cy + 60, cx - 40, cy + 10)
    love.graphics.setLineWidth(1)

end

local sceneDrawers = {
    station  = drawSceneStation,
    bar      = drawSceneBar,
    bank     = drawSceneStation,
    shipyard = drawSceneStation,
    outfitter= drawSceneStation,
    contracts= drawSceneStation,
    spaceport= drawSceneStation,
    space    = drawSceneSpace,
}

-- ─────────────────────────────────────────
-- Utilitários de desenho
-- ─────────────────────────────────────────

local function setColor(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function drawRect(x, y, w, h, color, mode)
    setColor(color)
    love.graphics.rectangle(mode or "fill", x, y, w, h, 2)
end

local function drawButton(x, y, w, h, label, isActive, isHovered, isDanger)
    local bg = isActive  and C.bgBtnActive
            or isHovered and C.bgBtnHover
            or C.bgBtn

    local border = isDanger  and C.borderDanger
                or isActive  and C.borderAccent
                or C.border

    local text = isDanger  and C.textDanger
              or isActive  and C.textActive
              or C.textNormal

    drawRect(x, y, w, h, bg)
    drawRect(x, y, w, h, border, "line")

    if isActive and not isDanger then
        drawRect(x, y, 2, h, C.borderAccent)
    end

    setColor(text)
    love.graphics.setFont(config.smallFont)
    love.graphics.print(label, x + 10, y + h / 2 - 6)
end

-- ─────────────────────────────────────────
-- Hitboxes
-- ─────────────────────────────────────────

local function getButtonRects()
    local rects = {}
    for i, btn in ipairs(leftButtons) do
        rects[btn.key] = {
            x = G.leftX, y = G.leftBtnY[i], w = L.btnW, h = L.btnH,
        }
    end
    for i, btn in ipairs(rightButtons) do
        rects[btn.key] = {
            x = G.rightX, y = G.rightBtnY[i], w = L.btnW, h = L.btnH,
        }
    end
    return rects
end

local function pointInRect(px, py, r)
    return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

-- ─────────────────────────────────────────
-- Texto com quebra de linha
-- ─────────────────────────────────────────

local function wrapText(text, maxChars)
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        while #line > maxChars do
            local cut = line:sub(1, maxChars):match("^(.+)%s")
            table.insert(lines, cut or line:sub(1, maxChars))
            line = line:sub(#(cut or line:sub(1, maxChars)) + 2)
        end
        table.insert(lines, line)
    end
    return lines
end

-- ─────────────────────────────────────────
-- Gamestate hooks
-- ─────────────────────────────────────────

function Landed.onEnter()
    config.Input.pushContext("landed")
    mousedx, mousedy = love.mouse.getPosition()
    love.mouse.setVisible(true)
    love.mouse.setRelativeMode(false)
    playerFlagShip = config.Entities.with("isFlagShip")[1]

    -- Transição de wormhole
    if playerFlagShip.landedAt and playerFlagShip.landedAt.toSystem then
        local targetSystem      = playerFlagShip.landedAt.toSystem
        local currentSystemName = config.WorldManager.systems[config.WorldManager.currentSystemId].name
        config.WorldManager.loadSystem(targetSystem)
        local entries = config.WorldManager.systems[targetSystem].wormholes or {}
        local entryX, entryY = 0, 0
        for _, entry in ipairs(entries) do
            if entry.name == "To " .. currentSystemName then
                entryX, entryY = entry.x, entry.y
            end
        end
        playerFlagShip.rigidbody.body:setPosition(entryX, entryY)
        playerFlagShip.rigidbody.body:setLinearVelocity(0, 0)
        config.GameState.switch("playing")
        return
    end

    -- Gera estoque do mercado na primeira visita
    print(playerFlagShip.landedAt.name)
    if playerFlagShip.landedAt and config.Landables[playerFlagShip.landedAt.name].market then
        config.MarketSystem.generateStock(playerFlagShip.landedAt)
    end

    -- Constrói botões a partir dos dados do landable
    local allBtns = {}
    allButtonsFlat = {}
    for key in pairs(config.Landables[playerFlagShip.landedAt.name].buttons or {}) do
        table.insert(allBtns, { key = key, label = buttonLabels[key] or key })
    end
    table.sort(allBtns, function(a, b) return a.key < b.key end)

    leftButtons, rightButtons = {}, {}
    for i, btn in ipairs(allBtns) do
        table.insert(allButtonsFlat, btn)
        if i % 2 == 1 then table.insert(leftButtons, btn)
        else               table.insert(rightButtons, btn) end
    end
    local departBtn = { key = "depart", label = "Depart", danger = true }
    table.insert(rightButtons, departBtn)
    table.insert(allButtonsFlat, departBtn)

    activePanel = allButtonsFlat[1].key
    hoveredBtn = allButtonsFlat[1].key
    recalcGeometry()

    if playerFlagShip.rigidbody and playerFlagShip.rigidbody.body then
        playerFlagShip.rigidbody.body:setLinearVelocity(0, 0)
        playerFlagShip.rigidbody.body:setAngularVelocity(0)
    end

    print("Docked at " .. (playerFlagShip.landedAt and config.Landables[playerFlagShip.landedAt.name].name or "unknown"))
end

function Landed.onExit()
    activePanel = "none"
    config.Input.popContext("landed")
    love.mouse.setVisible(false)
    love.mouse.setRelativeMode(true)
    if playerFlagShip and playerFlagShip.rigidbody and playerFlagShip.rigidbody.body then
        local angle = playerFlagShip.rigidbody.body:getAngle()
        playerFlagShip.rigidbody.body:applyLinearImpulse(
            math.cos(angle) * 400,
            math.sin(angle) * 400
        )
    end
    playerFlagShip.landedAt = nil
    playerFlagShip = nil
    config.MarketUI.close()
    config.InventoryUI.closeAll()
    print("Launched into space")
end

local function activateButton(key)
    if key == "trade" and playerFlagShip.landedAt and config.Landables[playerFlagShip.landedAt.name].market then
      config.MarketUI.open(playerFlagShip, playerFlagShip.landedAt)
    elseif key == "shipyard" and playerFlagShip.landedAt and config.Landables[playerFlagShip.landedAt.name].shipyard then
      activePanel = "shipyard"
      config.ShipyardUI.toggle()
    elseif key == "depart" then
      handleDepart()
    else
      activePanel = key
    end
end

function Landed.update(dt)
    config.InventoryUI.update(dt)
    config.MarketUI.update(dt)

    if config.Input.state.ui_inventory then
        config.InventoryUI.toggle(playerFlagShip, { title = "Freight Bay" })
        config.Input.state.ui_inventory = false
    end

    -- Hover dos botões (apenas quando market não está aberto)
    if not config.MarketUI.isOpen() then
        local mx, my = love.mouse.getPosition()
        local rects  = getButtonRects()
        if mx ~= mousedx or my ~= mousedy then
          mousedx = mx
          mousedy = my
          for key, r in pairs(rects) do
              if pointInRect(mx, my, r) then
                  hoveredBtn = key
                  break
              end
          end
        end
    end

    if activePanel == "depart" or config.Input.state.ship_launch then
      handleDepart()
    end
end

function Landed.textinput(t)
    if activePanel == "shipyard" then
        config.ShipyardUI.textinput(t)
    end
end

function Landed.keypressed(key)
    -- Se o mercado estiver aberto, ele domina o input
    if config.MarketUI.isOpen() then
      config.MarketUI.keypressed(key)
      return
    end
    if config.ShipyardUI.isOpen() then
      if config.ShipyardUI.keypressed(key) then return end -- Se consumiu o input, para aqui
    end
    -- Encontra o índice atual do hoveredBtn
    local currentIndex = 1
    for i, btn in ipairs(allButtonsFlat) do
        if btn.key == hoveredBtn then
            currentIndex = i
            break
        end
    end

    local nextIndex = currentIndex

    if key == "up" then
        nextIndex = currentIndex - 2
    elseif key == "down" then
        nextIndex = currentIndex + 2
    elseif key == "left" then
        -- Se for par (direita), vai para a esquerda (-1)
        if currentIndex % 2 == 0 then nextIndex = currentIndex - 1 end
    elseif key == "right" then
        -- Se for ímpar (esquerda), vai para a direita (+1)
        if currentIndex % 2 ~= 0 then nextIndex = currentIndex + 1 end
    elseif key == "return" or key == "kpenter" or key == "space" then
        activateButton(hoveredBtn)
        return
    elseif key == "escape" then
        config.GameState.switch("playing", { resuming = true })
        return
    end

    -- Clamp: não deixa sair dos limites da lista
    if nextIndex < 1 then nextIndex = 1 end
    if nextIndex > #allButtonsFlat then nextIndex = #allButtonsFlat end

    hoveredBtn = allButtonsFlat[nextIndex].key
end

function Landed.mousepressed(_, mx, my, button)
    -- Market UI tem prioridade
    if config.MarketUI.isOpen() then
        config.MarketUI.mousepressed(mx, my, button)
        return
    end

    config.InventoryUI.mousepressed(mx, my, button)

    if button == 1 then
        local rects = getButtonRects()
        for key, r in pairs(rects) do
            if pointInRect(mx, my, r) then
              activateButton(key)
            end
        end
    end
end

function Landed.wheelmoved(dx, dy)
    if config.MarketUI.isOpen() then
        config.MarketUI.wheelmoved(dx, dy)
        return
    end
    config.InventoryUI.wheelmoved(dx, dy)
end

-- ─────────────────────────────────────────
-- Draw
-- ─────────────────────────────────────────

function Landed.draw()
    local landedData = config.Landables[playerFlagShip.landedAt.name]
    local panelData  = landedData.buttons and landedData.buttons[activePanel]
    local panelTitle = buttonLabels[activePanel] or activePanel
    local panelScene = buttonScenes[activePanel] or "station"
    local panelText  = {}

    if panelData then
        panelText = wrapText(panelData.description or "", 52)
    end

    -- Fundo
    drawRect(G.x, G.y, G.w, G.h, C.bg)
    drawRect(G.x, G.y, G.w, G.h, C.border, "line")

    -- Cena
    local drawer = sceneDrawers[panelScene] or drawSceneStation
    drawer()

    -- Overlay base da cena
    setColor(C.sceneOverlay)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY + G.sceneH - 30, G.sceneW, 30)

    -- Nome do local
    setColor(C.textBright)
    love.graphics.setFont(config.smallFont)
    love.graphics.print(
        landedData.name or "Unknown",
        G.sceneX + 10,
        G.sceneY + G.sceneH - 20
    )

    -- Separador
    drawRect(G.x, G.sceneY + G.sceneH, G.w, 2, C.border)

    -- Botões esquerda
    for i, btn in ipairs(leftButtons) do
        drawButton(
            G.leftX, G.leftBtnY[i], L.btnW, L.btnH,
            btn.label,
            activePanel == btn.key,
            hoveredBtn  == btn.key,
            false
        )
    end

    -- Botões direita
    for i, btn in ipairs(rightButtons) do
        drawButton(
            G.rightX, G.rightBtnY[i], L.btnW, L.btnH,
            btn.label,
            activePanel == btn.key,
            hoveredBtn  == btn.key,
            btn.danger or false
        )
    end

    -- Painel central
    drawRect(G.centerX, G.contentY, G.centerW, G.contentH, C.bgPanel)
    drawRect(G.centerX, G.contentY, G.centerW, G.contentH, C.border, "line")

    -- Título
    setColor(C.textActive)
    love.graphics.setFont(config.normalFont)
    love.graphics.print(panelTitle, G.centerX + L.padX, G.contentY + L.padY)

    drawRect(G.centerX + L.padX, G.contentY + L.padY + 30, G.centerW - L.padX * 2, 1, C.border)

    -- Texto
    love.graphics.setFont(config.smallFont)
    for j, line in ipairs(panelText) do
        setColor(C.textNormal)
        love.graphics.print(line, G.textX, G.textY + (j - 1) * L.lineH)
    end

    -- Barra de status
    local statusY = G.y + G.h - 18
    drawRect(G.x, statusY, G.w, 18, {0.04, 0.02, 0.01, 1})
    drawRect(G.x, statusY, G.w, 1, C.border)
    setColor(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("DOCKED · " .. string.upper(landedData.name or "?"), G.x + 10, statusY + 3)

    if playerFlagShip and playerFlagShip.credits then
        love.graphics.print("CR: " .. playerFlagShip.credits.amount, G.x + G.w / 2 - 30, statusY + 3)
    end
    if playerFlagShip and playerFlagShip.inventory then
        love.graphics.print(
            "CARGO: " .. playerFlagShip.inventory.capacityUsed .. "/" .. playerFlagShip.inventory.capacity,
            G.x + G.w - 130, statusY + 3
        )
    end

    -- Market UI e Inventory UI por cima de tudo
    config.MarketUI.draw()
    config.ShipyardUI.draw()
    config.InventoryUI.draw()

    love.graphics.setColor(1, 1, 1, 1)
end

return Landed
