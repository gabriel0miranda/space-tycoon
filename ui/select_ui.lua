-- ─────────────────────────────────────────────────────────────────────────────
-- select_ui.lua  —  Modal de seleção de uma opção em um conjunto
-- ─────────────────────────────────────────────────────────────────────────────
--
-- USO BÁSICO
--
--   config.SelectUI.open({
--       title   = "Escolha a nave",
--       options = {
--           { label = "Firefly",  sublabel = "Fragata leve",  value = entityA },
--           { label = "Condor",   sublabel = "Cargueiro",     value = entityB },
--       },
--       onConfirm = function(option)
--           -- option é a entrada da lista ({ label, sublabel, value })
--           pilotarNave(option.value)
--       end,
--       onCancel = function() end,   -- opcional
--   })
--
-- INTEGRAÇÃO NOS CALLBACKS DO STATE ATIVO
--
--   function MyState.update(dt)
--       config.SelectUI.update(dt)
--   end
--
--   function MyState.draw()
--       -- ...
--       config.SelectUI.draw()   -- sempre por último
--   end
--
--   function MyState.keypressed(key)
--       if config.SelectUI.isOpen() then
--           config.SelectUI.keypressed(key)
--           return
--       end
--   end
--
--   function MyState.mousepressed(mx, my, button)
--       if config.SelectUI.isOpen() then
--           config.SelectUI.mousepressed(mx, my, button)
--           return
--       end
--   end
--
-- API
--
--   open(opts)            Abre o modal.
--     opts.title          string            — obrigatório
--     opts.options        { {label, sublabel?, value, danger?} }  — obrigatório
--     opts.selected       number            — índice inicial (padrão: 1)
--     opts.confirmLabel   string            — texto do botão confirmar (padrão: "Confirmar")
--     opts.cancelLabel    string            — texto do botão cancelar  (padrão: "Cancelar")
--     opts.onConfirm      function(option)
--     opts.onCancel       function()
--
--   close()               Fecha sem chamar callbacks.
--   isOpen()              Retorna bool.
--   update(dt)            (reservado para animações futuras — chame mesmo que vazio)
--   draw()                Desenha o modal sobre tudo.
--   keypressed(key)       Processa up/down, enter, escape.
--   mousepressed(x,y,b)   Clique fora cancela; clique em item seleciona/confirma.
--
-- ─────────────────────────────────────────────────────────────────────────────

local SelectUI = {}

-- ─────────────────────────────────────────
-- Cores (idênticas ao textinput_ui)
-- ─────────────────────────────────────────

local C = {
    bg          = {0.06, 0.03, 0.01, 0.97},
    bgDark      = {0.04, 0.02, 0.01, 1},
    bgRow       = {0.08, 0.04, 0.02, 1},
    bgRowHover  = {0.12, 0.06, 0.02, 1},
    bgRowSel    = {0.16, 0.08, 0.02, 1},
    border      = {0.23, 0.13, 0.05, 1},
    borderAccent= {0.75, 0.38, 0.13, 1},
    textNormal  = {0.78, 0.62, 0.42, 1},
    textBright  = {0.92, 0.78, 0.58, 1},
    textMuted   = {0.38, 0.22, 0.10, 1},
    textActive  = {0.88, 0.60, 0.22, 1},
    textDanger  = {0.80, 0.30, 0.20, 1},
    overlay     = {0.00, 0.00, 0.00, 0.62},
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local W         = 380
local HEADER_H  = 36
local ROW_H     = 36
local FOOTER_H  = 48
local PADDING   = 14
local BTN_W     = 110
local BTN_H     = 28
local MAX_VISIBLE = 6   -- máximo de opções visíveis antes de scroll

-- ─────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────

local s = {
    open         = false,
    title        = "",
    options      = {},
    selectedIdx  = 1,
    scrollOffset = 0,
    confirmLabel = "Confirmar",
    cancelLabel  = "Cancelar",
    onConfirm    = nil,
    onCancel     = nil,
    -- geometria (calculada no open)
    x = 0, y = 0, totalH = 0,
    listY = 0, listH = 0,
    footerY = 0,
    btnConfX = 0, btnCancX = 0, btnY = 0,
}

local fontTitle, fontRow, fontSub, fontBtn

local function initFonts()
    if fontTitle then return end
    fontTitle = love.graphics.newFont(13)
    fontRow   = love.graphics.newFont(12)
    fontSub   = love.graphics.newFont(10)
    fontBtn   = love.graphics.newFont(12)
end

-- ─────────────────────────────────────────
-- Geometria
-- ─────────────────────────────────────────

local function recalcGeometry()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local visible = math.min(#s.options, MAX_VISIBLE)
    s.listH   = visible * ROW_H
    s.totalH  = HEADER_H + PADDING + s.listH + PADDING + FOOTER_H
    s.x       = math.floor(sw / 2 - W / 2)
    s.y       = math.floor(sh / 2 - s.totalH / 2)
    s.listY   = s.y + HEADER_H + PADDING
    s.footerY = s.listY + s.listH + PADDING
    s.btnConfX = s.x + W - PADDING - BTN_W
    s.btnCancX = s.btnConfX - BTN_W - 8
    s.btnY     = s.footerY + (FOOTER_H - BTN_H) / 2
end

-- ─────────────────────────────────────────
-- Scroll helper
-- ─────────────────────────────────────────

local function clampScroll()
    local maxScroll = math.max(0, #s.options - MAX_VISIBLE)
    s.scrollOffset = math.max(0, math.min(maxScroll, s.scrollOffset))
end

local function scrollToSelected()
    local visible = math.min(#s.options, MAX_VISIBLE)
    if s.selectedIdx - 1 < s.scrollOffset then
        s.scrollOffset = s.selectedIdx - 1
    elseif s.selectedIdx > s.scrollOffset + visible then
        s.scrollOffset = s.selectedIdx - visible
    end
    clampScroll()
end

-- ─────────────────────────────────────────
-- Confirmar / cancelar
-- ─────────────────────────────────────────

local function doConfirm()
    if #s.options == 0 then return end
    local opt = s.options[s.selectedIdx]
    local cb  = s.onConfirm
    SelectUI.close()
    if cb then cb(opt) end
end

local function doCancel()
    local cb = s.onCancel
    SelectUI.close()
    if cb then cb() end
end

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function SelectUI.open(opts)
    assert(opts and opts.title,   "SelectUI.open: 'title' é obrigatório")
    assert(opts and opts.options, "SelectUI.open: 'options' é obrigatório")
    assert(#opts.options > 0,     "SelectUI.open: 'options' não pode ser vazio")

    initFonts()

    s.open         = true
    s.title        = opts.title
    s.options      = opts.options
    s.selectedIdx  = opts.selected or 1
    s.scrollOffset = 0
    s.confirmLabel = opts.confirmLabel or "Confirmar"
    s.cancelLabel  = opts.cancelLabel  or "Cancelar"
    s.onConfirm    = opts.onConfirm
    s.onCancel     = opts.onCancel

    -- Garante índice válido
    s.selectedIdx = math.max(1, math.min(#s.options, s.selectedIdx))
    scrollToSelected()
    recalcGeometry()

    config.Input.pushContext("select")
end

function SelectUI.close()
    if not s.open then return end
    s.open = false
    config.Input.popContext("select")
end

function SelectUI.isOpen() return s.open end

function SelectUI.update(dt)
    -- reservado para animações futuras
end

-- ─────────────────────────────────────────
-- Input
-- ─────────────────────────────────────────

function SelectUI.keypressed(key)
    if not s.open then return end

    if config.Input.state.ui_up or key == "up" then
        s.selectedIdx = math.max(1, s.selectedIdx - 1)
        scrollToSelected()

    elseif config.Input.state.ui_down or key == "down" then
        s.selectedIdx = math.min(#s.options, s.selectedIdx + 1)
        scrollToSelected()

    elseif config.Input.state.ui_confirm or key == "return" or key == "kpenter" then
        doConfirm()

    elseif config.Input.state.ui_cancel or key == "escape" then
        doCancel()
    end
end

function SelectUI.mousepressed(mx, my, button)
    if not s.open then return end
    if button ~= 1 then return end

    -- Fora do modal → cancela
    if mx < s.x or mx > s.x + W
    or my < s.y or my > s.y + s.totalH then
        doCancel(); return
    end

    -- Botão Confirmar
    if mx >= s.btnConfX and mx <= s.btnConfX + BTN_W
    and my >= s.btnY    and my <= s.btnY    + BTN_H then
        doConfirm(); return
    end

    -- Botão Cancelar
    if mx >= s.btnCancX and mx <= s.btnCancX + BTN_W
    and my >= s.btnY    and my <= s.btnY    + BTN_H then
        doCancel(); return
    end

    -- Clique em uma linha
    local visible = math.min(#s.options, MAX_VISIBLE)
    for i = 1, visible do
        local realIdx = i + s.scrollOffset
        if realIdx > #s.options then break end
        local rowY = s.listY + (i - 1) * ROW_H
        if my >= rowY and my < rowY + ROW_H
        and mx >= s.x and mx <= s.x + W then
            if s.selectedIdx == realIdx then
                -- Duplo clique / segunda seleção confirma
                doConfirm()
            else
                s.selectedIdx = realIdx
            end
            return
        end
    end
end

function SelectUI.wheelmoved(dx, dy)
    if not s.open then return end
    s.scrollOffset = s.scrollOffset - dy
    clampScroll()
end

-- ─────────────────────────────────────────
-- Draw
-- ─────────────────────────────────────────

local function sc(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function rect(x, y, w, h, color, mode, r)
    sc(color)
    love.graphics.rectangle(mode or "fill", x, y, w, h, r or 3)
end

function SelectUI.draw()
    if not s.open then return end
    initFonts()

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local mx, my = love.mouse.getPosition()

    -- Overlay
    sc(C.overlay)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Corpo
    rect(s.x, s.y, W, s.totalH, C.bg, "fill", 4)
    rect(s.x, s.y, W, s.totalH, C.border, "line", 4)

    -- Acento superior âmbar
    sc(C.borderAccent)
    love.graphics.rectangle("fill", s.x + 1, s.y + 1, W - 2, 2, 4)

    -- ── Header ──
    rect(s.x, s.y, W, HEADER_H, C.bgDark, "fill", 4)
    sc(C.border)
    love.graphics.rectangle("fill", s.x, s.y + HEADER_H - 1, W, 1)

    -- Ícone de lista (três linhas)
    local ix0 = s.x + PADDING
    local iy0 = s.y + math.floor(HEADER_H / 2) - 5
    sc(C.borderAccent)
    love.graphics.setLineWidth(1.5)
    for li = 0, 2 do
        local lx1 = ix0 + (li == 0 and 0 or 2)
        love.graphics.line(lx1, iy0 + li * 4, ix0 + 10, iy0 + li * 4)
    end
    love.graphics.setLineWidth(1)

    -- Título
    love.graphics.setFont(fontTitle)
    sc(C.textBright)
    love.graphics.print(s.title, s.x + PADDING + 16,
        s.y + math.floor(HEADER_H / 2 - fontTitle:getHeight() / 2))

    -- Contador de opções
    local countStr = s.selectedIdx .. "/" .. #s.options
    love.graphics.setFont(fontSub)
    sc(C.textMuted)
    love.graphics.print(countStr,
        s.x + W - PADDING - fontSub:getWidth(countStr),
        s.y + math.floor(HEADER_H / 2 - fontSub:getHeight() / 2))

    -- ── Lista de opções ──
    love.graphics.setScissor(s.x, s.listY, W, s.listH)

    local visible = math.min(#s.options, MAX_VISIBLE)
    for i = 1, visible do
        local realIdx = i + s.scrollOffset
        if realIdx > #s.options then break end
        local opt  = s.options[realIdx]
        local rowY = s.listY + (i - 1) * ROW_H
        local isSel = s.selectedIdx == realIdx
        local isHov = mx >= s.x and mx <= s.x + W
                   and my >= rowY and my < rowY + ROW_H

        -- Fundo da linha
        local bg = isSel and C.bgRowSel or (isHov and C.bgRowHover or C.bgRow)
        sc(bg)
        love.graphics.rectangle("fill", s.x, rowY, W, ROW_H)

        -- Acento lateral esquerdo na selecionada
        if isSel then
            sc(C.borderAccent)
            love.graphics.rectangle("fill", s.x, rowY, 2, ROW_H)
        end

        -- Ícone de bullet
        if isSel then
            sc(C.borderAccent)
            love.graphics.circle("fill", s.x + PADDING + 4, rowY + ROW_H / 2, 3)
        else
            sc(C.textMuted)
            love.graphics.circle("line", s.x + PADDING + 4, rowY + ROW_H / 2, 2)
        end

        -- Label principal
        local labelColor = opt.danger and C.textDanger
                        or (isSel and C.textActive or (isHov and C.textBright or C.textNormal))
        sc(labelColor)
        love.graphics.setFont(fontRow)
        love.graphics.print(opt.label or "?", s.x + PADDING + 14, rowY + (opt.sublabel and 5 or 9))

        -- Sublabel (linha secundária)
        if opt.sublabel then
            sc(C.textMuted)
            love.graphics.setFont(fontSub)
            love.graphics.print(opt.sublabel, s.x + PADDING + 14, rowY + 20)
        end

        -- Divisor
        sc(C.border)
        love.graphics.rectangle("fill", s.x, rowY + ROW_H - 1, W, 1)
    end

    love.graphics.setScissor()

    -- Scrollbar (se necessário)
    if #s.options > MAX_VISIBLE then
        local trackH   = s.listH
        local ratio    = MAX_VISIBLE / #s.options
        local thumbH   = math.max(16, trackH * ratio)
        local maxOff   = #s.options - MAX_VISIBLE
        local thumbY   = s.listY + (s.scrollOffset / maxOff) * (trackH - thumbH)
        sc(C.bgDark)
        love.graphics.rectangle("fill", s.x + W - 5, s.listY, 4, trackH)
        sc(C.border)
        love.graphics.rectangle("fill", s.x + W - 5, thumbY, 4, thumbH, 2)
    end

    -- Borda da área de lista
    sc(C.border)
    love.graphics.rectangle("line", s.x, s.listY, W, s.listH)

    -- ── Footer ──
    local footerY = s.footerY
    sc(C.border)
    love.graphics.rectangle("fill", s.x, footerY, W, 1)

    -- Hint de teclado
    love.graphics.setFont(fontSub)
    sc(C.textMuted)
    love.graphics.print("↑↓ navegar  ·  Enter confirma  ·  Esc cancela",
        s.x + PADDING, s.btnY + math.floor(BTN_H / 2 - fontSub:getHeight() / 2))

    -- Botão Cancelar
    local cancHov = mx >= s.btnCancX and mx <= s.btnCancX + BTN_W
                 and my >= s.btnY    and my <= s.btnY    + BTN_H
    rect(s.btnCancX, s.btnY, BTN_W, BTN_H,
        cancHov and {0.14, 0.07, 0.02, 1} or C.bgDark, "fill", 3)
    rect(s.btnCancX, s.btnY, BTN_W, BTN_H, C.border, "line", 3)
    love.graphics.setFont(fontBtn)
    sc(cancHov and C.textNormal or C.textMuted)
    love.graphics.print(s.cancelLabel,
        s.btnCancX + math.floor(BTN_W / 2 - fontBtn:getWidth(s.cancelLabel) / 2),
        s.btnY     + math.floor(BTN_H / 2 - fontBtn:getHeight() / 2))

    -- Botão Confirmar
    local confHov = mx >= s.btnConfX and mx <= s.btnConfX + BTN_W
                 and my >= s.btnY    and my <= s.btnY    + BTN_H
    rect(s.btnConfX, s.btnY, BTN_W, BTN_H,
        confHov and {0.20, 0.10, 0.02, 1} or C.bgDark, "fill", 3)
    rect(s.btnConfX, s.btnY, BTN_W, BTN_H,
        confHov and C.borderAccent or C.border, "line", 3)
    if confHov then
        sc(C.borderAccent)
        love.graphics.rectangle("fill", s.btnConfX, s.btnY, 2, BTN_H)
    end
    sc(confHov and C.textActive or C.textNormal)
    love.graphics.setFont(fontBtn)
    love.graphics.print(s.confirmLabel,
        s.btnConfX + math.floor(BTN_W / 2 - fontBtn:getWidth(s.confirmLabel) / 2),
        s.btnY     + math.floor(BTN_H / 2 - fontBtn:getHeight() / 2))

    love.graphics.setColor(1, 1, 1, 1)
end

return SelectUI
