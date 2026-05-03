local MainMenu = {}

-- ─────────────────────────────────────────
-- Cores  (tema marrom/âmbar — igual ao market_ui)
-- ─────────────────────────────────────────

local C = {
    bg          = {0.06, 0.03, 0.01, 1},
    bgBtn       = {0.08, 0.04, 0.02, 1},
    bgBtnHover  = {0.14, 0.07, 0.02, 1},
    border      = {0.23, 0.13, 0.05, 1},
    borderAccent= {0.75, 0.38, 0.13, 1},
    borderDanger= {0.45, 0.12, 0.06, 1},
    textNormal  = {0.78, 0.62, 0.42, 1},
    textBright  = {0.92, 0.78, 0.58, 1},
    textMuted   = {0.38, 0.22, 0.10, 1},
    textActive  = {0.88, 0.60, 0.22, 1},
    textDanger  = {0.87, 0.30, 0.18, 1},
    keyNormal   = {0.38, 0.22, 0.10, 1},
    keyHover    = {0.75, 0.38, 0.13, 1},
    keyDanger   = {0.87, 0.30, 0.18, 1},
}

-- ─────────────────────────────────────────
-- Estrelas (geradas uma vez no onEnter)
-- ─────────────────────────────────────────

local stars = {}

local function generateStars()
    stars = {}
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    for i = 1, 140 do
        table.insert(stars, {
            x = love.math.random() * sw,
            y = love.math.random() * sh,
            r = love.math.random() * 1.5 + 0.3,
            a = 0.2 + love.math.random() * 0.5,
        })
    end
end

-- ─────────────────────────────────────────
-- Botões
-- ─────────────────────────────────────────

local BTN_W   = 240
local BTN_H   = 34
local BTN_GAP = 4

local buttons = {
    { key = "1", label = "New Game",  action = "new",  danger = false },
    { key = "2", label = "Continue",  action = "cont", danger = false },
    { key = "4", label = "Quit",      action = "quit", danger = true  },
}

local hoveredBtn = 1

-- ─────────────────────────────────────────
-- Geometria
-- ─────────────────────────────────────────

local G = {}

local function recalcGeometry()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    G.titleX = sw / 2
    G.titleY = sh / 2 - 140

    local dividerH = 18
    local totalH   = #buttons * BTN_H + (#buttons - 1) * BTN_GAP + dividerH
    G.btnStartX = sw / 2 - BTN_W / 2
    G.btnStartY = sh / 2 - totalH / 2 + 40

    G.btnY = {}
    local curY = G.btnStartY
    for i = 1, #buttons do
        G.btnY[i] = curY
        curY = curY + BTN_H + BTN_GAP
        if i == 2 then
            curY = curY + dividerH
        end
    end

    G.dividerY = G.btnY[2] + BTN_H + BTN_GAP / 2 + 4

    -- Planeta decorativo (canto superior direito)
    G.planetX = sw * 0.82
    G.planetY = sh * 0.22
    G.planetR = 55

    G.footerY = sh - 24
end

-- ─────────────────────────────────────────
-- Gamestate hooks
-- ─────────────────────────────────────────

function MainMenu.onEnter()
    config.Input.pushContext("mainmenu")
    love.mouse.setVisible(true)
    love.mouse.setRelativeMode(false)
    generateStars()
    recalcGeometry()
    hoveredBtn = 1
end

function MainMenu.onExit()
    config.Input.popContext("mainmenu")
    love.mouse.setVisible(false)
    love.mouse.setRelativeMode(true)
end

function MainMenu.update(dt)
    local mx, my = love.mouse.getPosition()
    hoveredBtn = -1
    for i = 1, #buttons do
        local bx = G.btnStartX
        local by = G.btnY[i]
        if mx >= bx and mx <= bx + BTN_W and my >= by and my <= by + BTN_H then
            hoveredBtn = i
            break
        end
    end
end

function MainMenu.mousepressed(mx, my, button)
    if button ~= 1 then return end
    for i = 1, #buttons do
        local bx = G.btnStartX
        local by = G.btnY[i]
        if mx >= bx and mx <= bx + BTN_W and my >= by and my <= by + BTN_H then
            executeAction(buttons[i].action)
            return
        end
    end
end

function MainMenu.keypressed(key)
    for _, btn in ipairs(buttons) do
        if key == btn.key then
            executeAction(btn.action)
            return
        end
    end
    if key == "return" then
        executeAction(buttons[hoveredBtn > 0 and hoveredBtn or 1].action)
    end
    if key == "escape" then
        love.event.quit()
    end
    if key == "up" then
        hoveredBtn = math.max(1, (hoveredBtn > 0 and hoveredBtn or 1) - 1)
    end
    if key == "down" then
        hoveredBtn = math.min(#buttons, (hoveredBtn > 0 and hoveredBtn or 1) + 1)
    end
end

function executeAction(action)
    if action == "new" then
        config.GameState.switch("playing")
    elseif action == "cont" then
        -- TODO: implementar save/load
    elseif action == "control" then
        -- TODO: implementar tela de controles
    elseif action == "quit" then
        love.event.quit()
    end
end

-- ─────────────────────────────────────────
-- Draw
-- ─────────────────────────────────────────

local function setColor(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function drawBackground()
    setColor(C.bg)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Estrelas com tom âmbar/marrom quente em vez de azul-frio
    for _, s in ipairs(stars) do
        love.graphics.setColor(0.72, 0.55, 0.32, s.a)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Planeta decorativo — mesmo esquema do landed
    setColor({0.08, 0.04, 0.02, 1})
    love.graphics.circle("fill", G.planetX, G.planetY, G.planetR)
    setColor({0.23, 0.13, 0.05, 1})
    love.graphics.circle("line", G.planetX, G.planetY, G.planetR)

    -- Núcleo interno
    setColor({0.04, 0.02, 0.01, 1})
    love.graphics.circle("fill", G.planetX, G.planetY, G.planetR * 0.76)

    -- Anel
    love.graphics.setColor(0.20, 0.10, 0.04, 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.push()
        love.graphics.translate(G.planetX, G.planetY)
        love.graphics.rotate(-0.2)
        love.graphics.scale(1, 0.18)
        love.graphics.circle("line", 0, 0, G.planetR * 1.3)
    love.graphics.pop()
    love.graphics.setLineWidth(1)
end

local function drawTitle()
    setColor(C.textBright)
    love.graphics.setFont(config.bigFont)
    local title = "Space Tycoon"
    local tw    = config.bigFont:getWidth(title)
    love.graphics.print(title, G.titleX - tw / 2, G.titleY)

    -- Linha decorativa abaixo do título
    local lineW = tw * 0.6
    setColor(C.border)
    love.graphics.rectangle("fill", G.titleX - lineW / 2, G.titleY + config.bigFont:getHeight() + 6, lineW, 1)

    -- Subtítulo
    setColor(C.textMuted)
    love.graphics.setFont(config.smallFont)
    local sub  = "a simple space adventure"
    local sw2  = config.smallFont:getWidth(sub)
    love.graphics.print(sub, G.titleX - sw2 / 2, G.titleY + config.bigFont:getHeight() + 16)
end

local function drawButtons()
    for i, btn in ipairs(buttons) do
        local bx       = G.btnStartX
        local by       = G.btnY[i]
        local isHover  = hoveredBtn == i
        local isDanger = btn.danger

        -- Fundo
        local bg = isHover and C.bgBtnHover or C.bgBtn
        setColor(bg)
        love.graphics.rectangle("fill", bx, by, BTN_W, BTN_H, 2)

        -- Borda
        local border = isDanger
            and (isHover and C.borderDanger or C.border)
            or  (isHover and C.borderAccent or C.border)
        setColor(border)
        love.graphics.rectangle("line", bx, by, BTN_W, BTN_H, 2)

        -- Acento esquerdo quando hover
        if isHover then
            local accent = isDanger and C.borderDanger or C.borderAccent
            setColor(accent)
            love.graphics.rectangle("fill", bx, by, 2, BTN_H, 0)
        end

        -- Tecla de atalho
        love.graphics.setFont(config.smallFont)
        local keyColor = isDanger
            and (isHover and C.keyDanger  or C.textMuted)
            or  (isHover and C.keyHover   or C.keyNormal)
        setColor(keyColor)
        love.graphics.print(btn.key, bx + 12, by + BTN_H / 2 - config.smallFont:getHeight() / 2)

        -- Label
        local labelColor = isDanger
            and (isHover and C.textDanger or C.textNormal)
            or  (isHover and C.textActive or C.textNormal)
        setColor(labelColor)
        love.graphics.setFont(config.normalFont)
        love.graphics.print(btn.label, bx + 34, by + BTN_H / 2 - config.normalFont:getHeight() / 2)
    end

    -- Divisor antes do Quit
    setColor(C.border)
    love.graphics.rectangle("fill", G.btnStartX, G.dividerY, BTN_W, 1)
end

local function drawFooter()
    setColor(C.textMuted)
    love.graphics.setFont(config.smallFont)
    local text = "PRESS NUMBER OR CLICK TO SELECT"
    local tw   = config.smallFont:getWidth(text)
    love.graphics.print(text, love.graphics.getWidth() / 2 - tw / 2, G.footerY)
end

function MainMenu.draw()
    drawBackground()
    drawTitle()
    drawButtons()
    drawFooter()
    love.graphics.setColor(1, 1, 1, 1)
end

return MainMenu
