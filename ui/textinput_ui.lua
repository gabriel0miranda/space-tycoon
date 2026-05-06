-- ─────────────────────────────────────────────────────────────────────────────
-- text_input_ui.lua  —  Caixa de input de texto modal e reutilizável
-- ─────────────────────────────────────────────────────────────────────────────
--
-- USO BÁSICO
--
--   config.TextInputUI.open({
--       title       = "Nome da Nave",
--       placeholder = "Digite o nome...",
--       maxLength   = 32,
--       onConfirm   = function(text)
--           playerShip.name = text
--       end,
--       onCancel = function() end,  -- opcional
--   })
--
-- INTEGRAÇÃO NOS CALLBACKS DO STATE ATIVO
--
--   function MyState.update(dt)
--       config.TextInputUI.update(dt)
--   end
--
--   function MyState.draw()
--       -- ... desenha o resto ...
--       config.TextInputUI.draw()   -- sempre por último
--   end
--
--   function MyState.keypressed(key)
--       if config.TextInputUI.isOpen() then
--           config.TextInputUI.keypressed(key)
--           return
--       end
--   end
--
--   function MyState.mousepressed(mx, my, button)
--       if config.TextInputUI.isOpen() then
--           config.TextInputUI.mousepressed(mx, my, button)
--           return
--       end
--   end
--
--   -- Em main.lua, adicione uma vez:
--   function love.textinput(char)
--       config.TextInputUI.textinput(char)
--   end
--
-- API
--
--   open(opts)          Abre o modal.
--     opts.title        string   — obrigatório
--     opts.placeholder  string   — texto fantasma quando vazio
--     opts.default      string   — valor inicial do campo
--     opts.maxLength    number   — padrão: 64
--     opts.onConfirm    function(text)
--     opts.onCancel     function()
--     opts.validate     function(text) → ok, errmsg
--                         Chamada antes do onConfirm. Retorne false + mensagem
--                         para bloquear a confirmação e exibir o erro.
--
--   close()             Fecha sem chamar callbacks.
--   isOpen()            Retorna bool.
--   update(dt)          Atualiza o cursor piscante.
--   draw()              Desenha o modal sobre tudo.
--   keypressed(key)     Processa backspace, enter, escape, setas, home, end,
--                       ctrl+a, ctrl+c, ctrl+v, ctrl+x.
--   textinput(char)     Recebe caracteres do love.textinput.
--   mousepressed(x,y,b) Clique fora cancela; clique no campo posiciona cursor.
--
-- ─────────────────────────────────────────────────────────────────────────────

local TextInputUI = {}
local utf8 = require("utf8")

-- ─────────────────────────────────────────
-- Cores
-- ─────────────────────────────────────────

local C = {
    bg          = {0.06, 0.03, 0.01, 0.97},
    bgDark      = {0.04, 0.02, 0.01, 1},
    bgInput     = {0.04, 0.02, 0.01, 1},
    border      = {0.23, 0.13, 0.05, 1},
    borderAccent= {0.75, 0.38, 0.13, 1},
    textNormal  = {0.78, 0.62, 0.42, 1},
    textBright  = {0.92, 0.78, 0.58, 1},
    textMuted   = {0.38, 0.22, 0.10, 1},
    textActive  = {0.88, 0.60, 0.22, 1},
    overlay     = {0.00, 0.00, 0.00, 0.62},
    errorText   = {0.80, 0.35, 0.25, 1},
    cursorColor = {0.75, 0.38, 0.13, 1},
    selection   = {0.75, 0.38, 0.13, 0.28},
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local W        = 380
local HEADER_H = 36
local INPUT_H  = 36
local FOOTER_H = 44
local PADDING  = 18
local BTN_W    = 110
local BTN_H    = 28

-- ─────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────

local s = {
    open        = false,
    title       = "",
    placeholder = "",
    maxLength   = 64,
    text        = "",
    cursor      = 0,
    selStart    = nil,
    selEnd      = nil,
    cursorBlink = 0,
    cursorVis   = true,
    errorMsg    = nil,
    onConfirm   = nil,
    onCancel    = nil,
    validate    = nil,
    -- geometria
    x = 0, y = 0, totalH = 0,
    inputX = 0, inputY = 0, inputW = 0,
    footerY = 0,
    btnConfX = 0, btnCancX = 0, btnY = 0,
}

local fontTitle, fontInput, fontBtn, fontSmall

local function initFonts()
    if fontTitle then return end
    fontTitle = love.graphics.newFont(13)
    fontInput = love.graphics.newFont(14)
    fontBtn   = love.graphics.newFont(12)
    fontSmall = love.graphics.newFont(11)
end

-- ─────────────────────────────────────────
-- Helpers UTF-8
-- ─────────────────────────────────────────

local function uLen(str)
    return utf8.len(str) or 0
end

local function charToBytePos(str, charIdx)
    -- Retorna a posição de byte do charIdx-ésimo caractere (1-based).
    -- charIdx == 0 → retorna 1 (antes do texto).
    -- charIdx > len → retorna #str + 1.
    if charIdx <= 0 then return 1 end
    local count = 0
    for bytePos, _ in utf8.codes(str) do
        count = count + 1
        if count == charIdx then return bytePos end
    end
    return #str + 1
end

local function uSub(str, i, j)
    local bi = charToBytePos(str, i)
    if j then
        local bj = charToBytePos(str, j + 1) - 1
        return str:sub(bi, bj)
    end
    return str:sub(bi)
end

local function uInsert(str, cursorPos, chars)
    local before = cursorPos > 0 and uSub(str, 1, cursorPos) or ""
    local after  = cursorPos < uLen(str) and uSub(str, cursorPos + 1) or ""
    return before .. chars .. after
end

local function uDeleteAt(str, charPos)
    -- Remove o char na posição charPos (1-based).
    if charPos < 1 or charPos > uLen(str) then return str end
    local before = charPos > 1 and uSub(str, 1, charPos - 1) or ""
    local after  = charPos < uLen(str) and uSub(str, charPos + 1) or ""
    return before .. after
end

-- ─────────────────────────────────────────
-- Geometria
-- ─────────────────────────────────────────

local function recalcGeometry()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    s.totalH  = HEADER_H + PADDING + INPUT_H + PADDING + FOOTER_H
    s.x       = math.floor(sw / 2 - W / 2)
    s.y       = math.floor(sh / 2 - s.totalH / 2)
    s.inputX  = s.x + PADDING
    s.inputY  = s.y + HEADER_H + PADDING
    s.inputW  = W - PADDING * 2
    s.footerY = s.inputY + INPUT_H + PADDING
    s.btnConfX = s.x + W - PADDING - BTN_W
    s.btnCancX = s.btnConfX - BTN_W - 8
    s.btnY     = s.footerY + (FOOTER_H - BTN_H) / 2
end

-- ─────────────────────────────────────────
-- Seleção
-- ─────────────────────────────────────────

local function clearSel()   s.selStart = nil; s.selEnd = nil end
local function hasSel()     return s.selStart ~= nil and s.selStart ~= s.selEnd end
local function selLo()      return math.min(s.selStart or 0, s.selEnd or 0) end
local function selHi()      return math.max(s.selStart or 0, s.selEnd or 0) end

local function deleteSel()
    if not hasSel() then return end
    local lo, hi = selLo(), selHi()
    local before = lo > 0 and uSub(s.text, 1, lo) or ""
    local after  = hi < uLen(s.text) and uSub(s.text, hi + 1) or ""
    s.text   = before .. after
    s.cursor = lo
    clearSel()
end

-- ─────────────────────────────────────────
-- Cursor
-- ─────────────────────────────────────────

local function resetBlink()
    s.cursorVis   = true
    s.cursorBlink = 0
end

-- ─────────────────────────────────────────
-- Confirmar / cancelar
-- ─────────────────────────────────────────

local function doConfirm()
    local text = s.text
    if s.validate then
        local ok, err = s.validate(text)
        if not ok then
            s.errorMsg = err or "Entrada inválida."
            return
        end
    end
    local cb = s.onConfirm
    TextInputUI.close()
    if cb then cb(text) end
end

local function doCancel()
    local cb = s.onCancel
    TextInputUI.close()
    if cb then cb() end
end

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function TextInputUI.open(opts)
    assert(opts and opts.title, "TextInputUI.open: 'title' é obrigatório")
    initFonts()
    recalcGeometry()

    local def  = opts.default or ""
    s.open        = true
    s.title       = opts.title
    s.placeholder = opts.placeholder or ""
    s.maxLength   = opts.maxLength   or 64
    s.text        = def
    s.cursor      = uLen(def)
    s.selStart    = nil
    s.selEnd      = nil
    s.cursorBlink = 0
    s.cursorVis   = true
    s.errorMsg    = nil
    s.onConfirm   = opts.onConfirm
    s.onCancel    = opts.onCancel
    s.validate    = opts.validate

    if config and config.Input then
        config.Input.pushContext("textinput")
    end
    love.keyboard.setTextInput(true)
end

function TextInputUI.close()
    s.open = false
    love.keyboard.setTextInput(false)
    if config and config.Input then
        config.Input.popContext("textinput")
    end
end

function TextInputUI.isOpen() return s.open end

-- ─────────────────────────────────────────
-- Update
-- ─────────────────────────────────────────

function TextInputUI.update(dt)
    if not s.open then return end
    s.cursorBlink = s.cursorBlink + dt
    if s.cursorBlink >= 0.53 then
        s.cursorBlink = 0
        s.cursorVis   = not s.cursorVis
    end
end

-- ─────────────────────────────────────────
-- Textinput  (caracteres imprimíveis via love.textinput)
-- ─────────────────────────────────────────

function TextInputUI.textinput(char)
    if not s.open then return end
    s.errorMsg = nil
    if hasSel() then deleteSel() end
    if uLen(s.text) >= s.maxLength then return end
    s.text   = uInsert(s.text, s.cursor, char)
    s.cursor = s.cursor + uLen(char)
    resetBlink()
end

-- ─────────────────────────────────────────
-- Keypressed
-- ─────────────────────────────────────────

function TextInputUI.keypressed(key)
    if not s.open then return end
    s.errorMsg = nil

    local ctrl  = love.keyboard.isDown("lctrl")  or love.keyboard.isDown("rctrl")
    local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    local len   = uLen(s.text)

    -- ── Atalhos de ctrl ──
    if ctrl then
        if key == "a" then
            s.selStart = 0; s.selEnd = len; s.cursor = len
        elseif key == "c" then
            if hasSel() then
                love.system.setClipboardText(uSub(s.text, selLo() + 1, selHi()))
            end
        elseif key == "x" then
            if hasSel() then
                love.system.setClipboardText(uSub(s.text, selLo() + 1, selHi()))
                deleteSel()
            end
        elseif key == "v" then
            local clip = (love.system.getClipboardText() or ""):gsub("[\n\r]", " ")
            if hasSel() then deleteSel() end
            local space = s.maxLength - uLen(s.text)
            local paste = uLen(clip) > space and uSub(clip, 1, space) or clip
            if uLen(paste) > 0 then
                s.text   = uInsert(s.text, s.cursor, paste)
                s.cursor = s.cursor + uLen(paste)
            end
        end
        resetBlink()
        return
    end

    -- ── Confirmação e cancelamento ──
    if key == "return" or key == "kpenter" then doConfirm(); return end
    if key == "escape" then doCancel(); return end

    -- ── Edição ──
    if key == "backspace" then
        if hasSel() then deleteSel()
        elseif s.cursor > 0 then
            s.text   = uDeleteAt(s.text, s.cursor)
            s.cursor = s.cursor - 1
        end
        resetBlink(); return
    end

    if key == "delete" then
        if hasSel() then deleteSel()
        elseif s.cursor < len then
            s.text = uDeleteAt(s.text, s.cursor + 1)
        end
        resetBlink(); return
    end

    -- ── Navegação ──
    if key == "left" then
        if shift then
            if not s.selStart then s.selStart = s.cursor end
            s.cursor = math.max(0, s.cursor - 1)
            s.selEnd = s.cursor
        else
            s.cursor = hasSel() and selLo() or math.max(0, s.cursor - 1)
            clearSel()
        end
        resetBlink(); return
    end

    if key == "right" then
        if shift then
            if not s.selStart then s.selStart = s.cursor end
            s.cursor = math.min(len, s.cursor + 1)
            s.selEnd = s.cursor
        else
            s.cursor = hasSel() and selHi() or math.min(len, s.cursor + 1)
            clearSel()
        end
        resetBlink(); return
    end

    if key == "home" then
        if shift then
            if not s.selStart then s.selStart = s.cursor end
            s.selEnd = 0
        else clearSel() end
        s.cursor = 0; resetBlink(); return
    end

    if key == "end" then
        if shift then
            if not s.selStart then s.selStart = s.cursor end
            s.selEnd = len
        else clearSel() end
        s.cursor = len; resetBlink(); return
    end
end

-- ─────────────────────────────────────────
-- Mousepressed
-- ─────────────────────────────────────────

function TextInputUI.mousepressed(mx, my, button)
    if not s.open then return end
    if button ~= 1 then return end

    -- Fora do modal → cancela
    if mx < s.x or mx > s.x + W or my < s.y or my > s.y + s.totalH then
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

    -- Campo de texto → posiciona cursor pelo clique
    if mx >= s.inputX and mx <= s.inputX + s.inputW
    and my >= s.inputY and my <= s.inputY + INPUT_H then
        initFonts()
        local relX   = mx - s.inputX - PADDING
        local best   = 0
        local bestD  = math.abs(relX)
        for i = 1, uLen(s.text) do
            local px   = fontInput:getWidth(uSub(s.text, 1, i))
            local dist = math.abs(relX - px)
            if dist < bestD then bestD = dist; best = i end
        end
        s.cursor = best
        clearSel()
        resetBlink()
    end
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

function TextInputUI.draw()
    if not s.open then return end
    initFonts()

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- Overlay
    sc(C.overlay)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Corpo
    rect(s.x, s.y, W, s.totalH, C.bg, "fill", 4)
    rect(s.x, s.y, W, s.totalH, C.border, "line", 4)

    -- Acento superior âmbar
    sc(C.borderAccent)
    love.graphics.rectangle("fill", s.x + 1, s.y + 1, W - 2, 2, 4)

    -- Header
    rect(s.x, s.y, W, HEADER_H, C.bgDark, "fill", 4)
    sc(C.border)
    love.graphics.rectangle("fill", s.x, s.y + HEADER_H - 1, W, 1)

    -- Ícone de lápis
    local ix0 = s.x + PADDING
    local iy0 = s.y + math.floor(HEADER_H / 2) - 5
    sc(C.borderAccent)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(ix0,     iy0 + 8, ix0 + 6, iy0 + 2)
    love.graphics.line(ix0 + 6, iy0 + 2, ix0 + 8, iy0 + 4)
    love.graphics.line(ix0 + 8, iy0 + 4, ix0 + 2, iy0 + 10)
    love.graphics.setLineWidth(1)

    -- Título
    love.graphics.setFont(fontTitle)
    sc(C.textBright)
    love.graphics.print(s.title, s.x + PADDING + 14,
        s.y + math.floor(HEADER_H / 2 - fontTitle:getHeight() / 2))

    -- Contador de chars
    local countStr = uLen(s.text) .. "/" .. s.maxLength
    love.graphics.setFont(fontSmall)
    sc(C.textMuted)
    love.graphics.print(countStr,
        s.x + W - PADDING - fontSmall:getWidth(countStr),
        s.y + math.floor(HEADER_H / 2 - fontSmall:getHeight() / 2))

    -- ── Campo de input ──
    local ix, iy, iw = s.inputX, s.inputY, s.inputW

    rect(ix, iy, iw, INPUT_H, C.bgInput, "fill", 3)
    rect(ix, iy, iw, INPUT_H, C.borderAccent, "line", 3)

    -- Clipping
    love.graphics.setScissor(ix + 2, iy, iw - 4, INPUT_H)

    local textY = iy + math.floor(INPUT_H / 2 - fontInput:getHeight() / 2)
    local textX = ix + PADDING

    love.graphics.setFont(fontInput)

    if uLen(s.text) == 0 then
        sc(C.textMuted)
        love.graphics.print(s.placeholder, textX, textY)
    else
        -- Highlight de seleção
        if hasSel() then
            local lo, hi = selLo(), selHi()
            local beforeSel = lo > 0 and uSub(s.text, 1, lo) or ""
            local selStr    = uSub(s.text, lo + 1, hi)
            local sx        = textX + fontInput:getWidth(beforeSel)
            local sw2       = fontInput:getWidth(selStr)
            sc(C.selection)
            love.graphics.rectangle("fill", sx, iy + 4, sw2, INPUT_H - 8, 2)
        end

        sc(C.textBright)
        love.graphics.print(s.text, textX, textY)
    end

    -- Cursor piscante
    if s.cursorVis then
        local prefix  = s.cursor > 0 and uSub(s.text, 1, s.cursor) or ""
        local cursorX = textX + fontInput:getWidth(prefix)
        sc(C.cursorColor)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(cursorX, iy + 6, cursorX, iy + INPUT_H - 6)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setScissor()

    -- ── Footer ──
    local footerY = s.footerY

    -- Mensagem de erro
    if s.errorMsg then
        love.graphics.setFont(fontSmall)
        sc(C.errorText)
        love.graphics.print("  " .. s.errorMsg, ix, footerY + 2)
    end

    -- Hint
    love.graphics.setFont(fontSmall)
    sc(C.textMuted)
    love.graphics.print("Enter confirma  ·  Esc cancela", ix,
        s.btnY + math.floor(BTN_H / 2 - fontSmall:getHeight() / 2))

    -- Posição do mouse para hover
    local mx, my = love.mouse.getPosition()

    -- Botão Cancelar
    local cancH = mx >= s.btnCancX and mx <= s.btnCancX + BTN_W
               and my >= s.btnY    and my <= s.btnY    + BTN_H
    rect(s.btnCancX, s.btnY, BTN_W, BTN_H,
        cancH and {0.14, 0.07, 0.02, 1} or C.bgDark, "fill", 3)
    rect(s.btnCancX, s.btnY, BTN_W, BTN_H, C.border, "line", 3)
    love.graphics.setFont(fontBtn)
    sc(cancH and C.textNormal or C.textMuted)
    local cL = "Cancelar"
    love.graphics.print(cL,
        s.btnCancX + math.floor(BTN_W / 2 - fontBtn:getWidth(cL) / 2),
        s.btnY     + math.floor(BTN_H / 2 - fontBtn:getHeight() / 2))

    -- Botão Confirmar
    local confH = mx >= s.btnConfX and mx <= s.btnConfX + BTN_W
               and my >= s.btnY    and my <= s.btnY    + BTN_H
    rect(s.btnConfX, s.btnY, BTN_W, BTN_H,
        confH and {0.20, 0.10, 0.02, 1} or C.bgDark, "fill", 3)
    rect(s.btnConfX, s.btnY, BTN_W, BTN_H,
        confH and C.borderAccent or C.border, "line", 3)
    if confH then
        sc(C.borderAccent)
        love.graphics.rectangle("fill", s.btnConfX, s.btnY, 2, BTN_H)
    end
    sc(confH and C.textActive or C.textNormal)
    love.graphics.setFont(fontBtn)
    local cfL = "Confirmar"
    love.graphics.print(cfL,
        s.btnConfX + math.floor(BTN_W / 2 - fontBtn:getWidth(cfL) / 2),
        s.btnY     + math.floor(BTN_H / 2 - fontBtn:getHeight() / 2))

    love.graphics.setColor(1, 1, 1, 1)
end

return TextInputUI
