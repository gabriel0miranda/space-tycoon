-- ─────────────────────────────────────────────────────────────────────────────
-- dialogue_ui.lua  —  Modal de diálogo: texto narrativo + opções de resposta
-- ─────────────────────────────────────────────────────────────────────────────
--
-- USO BÁSICO — só texto (sem opções)
--
--   config.DialogueUI.open({
--       text = "O velho entrega um envelope amassado e se afasta sem dizer mais nada.",
--   })
--
-- USO COM OPÇÕES (Endless Sky-style)
--
--   config.DialogueUI.open({
--       text    = "O mercador olha para você com desconfiança.\n\"O que você quer?\"",
--       options = {
--           { label = "\"Só estou passando.\"",    value = "pass"  },
--           { label = "\"Preciso de trabalho.\"",  value = "work"  },
--           { label = "\"Nada. Me desculpe.\"",    value = "leave" },
--       },
--       onConfirm = function(option)
--           -- option = { label, value } da opção escolhida
--           -- Se não houver opções, option = nil (dismiss simples)
--           handleDialogue(option.value)
--       end,
--   })
--
-- INTEGRAÇÃO
--
--   function MyState.update(dt)     config.DialogueUI.update(dt)               end
--   function MyState.draw()         ...  config.DialogueUI.draw()               end
--   function MyState.keypressed(k)
--       if config.DialogueUI.isOpen() then
--           config.DialogueUI.keypressed(k); return
--       end
--   end
--   function MyState.mousepressed(mx, my, btn)
--       if config.DialogueUI.isOpen() then
--           config.DialogueUI.mousepressed(mx, my, btn); return
--       end
--   end
--   function MyState.wheelmoved(dx, dy)
--       if config.DialogueUI.isOpen() then
--           config.DialogueUI.wheelmoved(dx, dy); return
--       end
--   end
--
-- API
--
--   open(opts)
--     opts.speaker    string?           — nome do falante (opcional, aparece no header)
--     opts.text       string            — corpo do texto (suporta \n)
--     opts.options    { {label, value} }? — se ausente, só botão "Continuar"
--     opts.onConfirm  function(option)?
--     opts.portrait   love.Image?       — imagem do falante (opcional, canto esq.)
--
--   close()
--   isOpen() → bool
--   update(dt)
--   draw()
--   keypressed(key)
--   mousepressed(mx, my, button)
--   wheelmoved(dx, dy)
--
-- ─────────────────────────────────────────────────────────────────────────────

local DialogueUI = {}

-- ─────────────────────────────────────────
-- Cores (mesmo tema marrom do projeto)
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
    overlay     = {0.00, 0.00, 0.00, 0.55},
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local W            = 520        -- largura do modal
local HEADER_H     = 32         -- barra do falante
local PADDING      = 18         -- margem interna geral
local TEXT_WRAP    = 484        -- largura do wrap do texto
local LINE_H       = 20         -- altura de linha do texto principal
local OPTION_H     = 28         -- altura de cada linha de opção
local FOOTER_H     = 44         -- área do botão de dismiss
local BTN_W        = 120
local BTN_H        = 28
local PORTRAIT_W   = 64         -- largura da imagem do falante
local PORTRAIT_H   = 64
local MAX_TEXT_H   = 200        -- altura máxima da área de texto (scroll acima disso)

-- ─────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────

local s = {
    open         = false,
    speaker      = nil,
    text         = "",
    options      = {},        -- pode ser vazio
    selectedIdx  = 1,
    portrait     = nil,
    onConfirm    = nil,
    -- geometria (calculada no open)
    x = 0, y = 0, totalH = 0,
    textY = 0, textH = 0,
    optionsY = 0,
    footerY = 0,
    btnX = 0, btnY = 0,
    -- scroll do texto
    textScroll   = 0,
    textFullH    = 0,         -- altura real do texto wrappado
    -- scroll das opções
    optScroll    = 0,
    maxOptScroll = 0,
}

local MAX_OPT_VISIBLE = 5

local fontSpeaker, fontBody, fontOption, fontBtn, fontHint

local function initFonts()
    if fontSpeaker then return end
    fontSpeaker = love.graphics.newFont(13)
    fontBody    = love.graphics.newFont(12)
    fontOption  = love.graphics.newFont(12)
    fontBtn     = love.graphics.newFont(12)
    fontHint    = love.graphics.newFont(10)
end

-- ─────────────────────────────────────────
-- Wrapping manual (LÖVE não devolve linhas)
-- ─────────────────────────────────────────

-- Quebra `text` em linhas que cabem em `maxW` pixels com `font`.
-- Respeita \n explícito.
local function wrapText(text, font, maxW)
    local lines = {}
    -- Primeiro divide nos \n explícitos
    for para in (text .. "\n"):gmatch("(.-)\n") do
        if para == "" then
            table.insert(lines, "")
        else
            -- Wrap dentro do parágrafo
            local words = {}
            for w in para:gmatch("%S+") do table.insert(words, w) end
            local current = ""
            for _, word in ipairs(words) do
                local test = current == "" and word or (current .. " " .. word)
                if font:getWidth(test) <= maxW then
                    current = test
                else
                    if current ~= "" then table.insert(lines, current) end
                    current = word
                end
            end
            if current ~= "" then table.insert(lines, current) end
        end
    end
    return lines
end

-- ─────────────────────────────────────────
-- Geometria
-- ─────────────────────────────────────────

local function recalcGeometry()
    initFonts()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- Mede o texto wrappado
    local textWrapW = W - PADDING * 2
    if s.portrait then textWrapW = textWrapW - PORTRAIT_W - PADDING end
    local lines     = wrapText(s.text, fontBody, textWrapW)
    s._lines        = lines
    s.textFullH     = #lines * LINE_H
    s.textH         = math.min(s.textFullH, MAX_TEXT_H)

    -- Número de opções visíveis
    local numOpts    = #s.options
    local visOpts    = math.min(numOpts, MAX_OPT_VISIBLE)
    s.maxOptScroll   = math.max(0, numOpts - MAX_OPT_VISIBLE)

    local optionsBlockH = numOpts > 0 and (PADDING / 2 + visOpts * OPTION_H) or 0

    s.totalH = HEADER_H
             + PADDING
             + s.textH
             + optionsBlockH
             + PADDING
             + FOOTER_H

    s.x       = math.floor(sw / 2 - W / 2)
    s.y       = math.floor(sh / 2 - s.totalH / 2)

    s.textY   = s.y + HEADER_H + PADDING
    s.optionsY = s.textY + s.textH + (numOpts > 0 and PADDING / 2 or 0)
    s.footerY  = s.optionsY + optionsBlockH
    s.btnX     = s.x + W - PADDING - BTN_W
    s.btnY     = s.footerY + (FOOTER_H - BTN_H) / 2
end

-- ─────────────────────────────────────────
-- Confirm / close
-- ─────────────────────────────────────────

local function doConfirm()
    local cb = s.onConfirm
    local opt = (#s.options > 0) and s.options[s.selectedIdx] or nil
    DialogueUI.close()
    if cb then cb(opt) end
end

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function DialogueUI.open(opts)
    assert(opts and opts.text, "DialogueUI.open: 'text' é obrigatório")
    initFonts()

    s.open        = true
    s.speaker     = opts.speaker  or nil
    s.text        = opts.text
    s.options     = opts.options  or {}
    s.portrait    = opts.portrait or nil
    s.onConfirm   = opts.onConfirm
    s.selectedIdx = 1
    s.textScroll  = 0
    s.optScroll   = 0

    recalcGeometry()
    config.Input.pushContext("dialogue")
end

function DialogueUI.close()
    if not s.open then return end
    s.open = false
    config.Input.popContext("dialogue")
end

function DialogueUI.isOpen() return s.open end

function DialogueUI.update(dt)
    -- reservado
end

-- ─────────────────────────────────────────
-- Input
-- ─────────────────────────────────────────

function DialogueUI.keypressed(key)
    if not s.open then return end

    -- Navegação entre opções
    if #s.options > 0 then
        if config.Input.state.ui_up or key == "up" then
            s.selectedIdx = math.max(1, s.selectedIdx - 1)
            -- Scroll das opções
            if s.selectedIdx <= s.optScroll then
                s.optScroll = s.selectedIdx - 1
            end
            return
        end
        if config.Input.state.ui_down or key == "down" then
            s.selectedIdx = math.min(#s.options, s.selectedIdx + 1)
            if s.selectedIdx > s.optScroll + MAX_OPT_VISIBLE then
                s.optScroll = s.selectedIdx - MAX_OPT_VISIBLE
            end
            return
        end
    end

    -- Scroll do texto com Page Up/Down
    if key == "pageup" then
        s.textScroll = math.max(0, s.textScroll - MAX_TEXT_H)
        return
    end
    if key == "pagedown" then
        local maxScroll = math.max(0, s.textFullH - MAX_TEXT_H)
        s.textScroll = math.min(maxScroll, s.textScroll + MAX_TEXT_H)
        return
    end

    if config.Input.state.ui_confirm or key == "return" or key == "kpenter" or key == "space" then
        doConfirm()
        return
    end

    -- Esc fecha sem callback (dismiss silencioso)
    if config.Input.state.ui_cancel or key == "escape" then
        DialogueUI.close()
        return
    end
end

function DialogueUI.mousepressed(mx, my, button)
    if not s.open then return end
    if button ~= 1 then return end

    -- Fora do modal → fecha
    if mx < s.x or mx > s.x + W
    or my < s.y or my > s.y + s.totalH then
        DialogueUI.close(); return
    end

    -- Botão principal (Continuar / confirmar)
    if mx >= s.btnX and mx <= s.btnX + BTN_W
    and my >= s.btnY and my <= s.btnY + BTN_H then
        doConfirm(); return
    end

    -- Clique em opção
    if #s.options > 0 then
        local visOpts = math.min(#s.options, MAX_OPT_VISIBLE)
        for i = 1, visOpts do
            local realIdx = i + s.optScroll
            if realIdx > #s.options then break end
            local rowY = s.optionsY + (i - 1) * OPTION_H
            if my >= rowY and my < rowY + OPTION_H
            and mx >= s.x and mx <= s.x + W then
                if s.selectedIdx == realIdx then
                    doConfirm()
                else
                    s.selectedIdx = realIdx
                end
                return
            end
        end
    end
end

function DialogueUI.wheelmoved(dx, dy)
    if not s.open then return end
    local mx, my = love.mouse.getPosition()

    -- Scroll sobre a área de texto
    if my >= s.textY and my < s.textY + s.textH then
        local maxScroll = math.max(0, s.textFullH - MAX_TEXT_H)
        s.textScroll = math.max(0, math.min(maxScroll, s.textScroll - dy * LINE_H * 3))
        return
    end

    -- Scroll sobre as opções
    if #s.options > 0 then
        local optBlock = s.optionsY + MAX_OPT_VISIBLE * OPTION_H
        if my >= s.optionsY and my < optBlock then
            s.optScroll = math.max(0, math.min(s.maxOptScroll, s.optScroll - dy))
        end
    end
end

-- ─────────────────────────────────────────
-- Draw helpers
-- ─────────────────────────────────────────

local function sc(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function rect(x, y, w, h, color, mode, r)
    sc(color)
    love.graphics.rectangle(mode or "fill", x, y, w, h, r or 3)
end

-- ─────────────────────────────────────────
-- Draw
-- ─────────────────────────────────────────

function DialogueUI.draw()
    if not s.open then return end
    initFonts()

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local mx, my = love.mouse.getPosition()

    -- Overlay escuro
    sc(C.overlay)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- ── Corpo do modal ──
    rect(s.x, s.y, W, s.totalH, C.bg, "fill", 4)
    rect(s.x, s.y, W, s.totalH, C.border, "line", 4)

    -- Acento superior âmbar
    sc(C.borderAccent)
    love.graphics.rectangle("fill", s.x + 1, s.y + 1, W - 2, 2, 4)

    -- ── Header (nome do falante) ──
    rect(s.x, s.y, W, HEADER_H, C.bgDark, "fill", 4)
    sc(C.border)
    love.graphics.rectangle("fill", s.x, s.y + HEADER_H - 1, W, 1)

    -- Ícone de diálogo (balão simples — duas linhas)
    local ix0 = s.x + PADDING
    local iy0 = s.y + math.floor(HEADER_H / 2) - 4
    sc(C.borderAccent)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", ix0, iy0, 10, 7, 2)
    love.graphics.line(ix0 + 2, iy0 + 7, ix0, iy0 + 10)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(fontSpeaker)
    sc(s.speaker and C.textActive or C.textMuted)
    local speakerLabel = s.speaker or "—"
    love.graphics.print(speakerLabel, s.x + PADDING + 16,
        s.y + math.floor(HEADER_H / 2 - fontSpeaker:getHeight() / 2))

    -- ── Área de texto ──
    local textAreaX = s.x + PADDING
    local textAreaW = W - PADDING * 2
    local textAreaY = s.textY
    local textAreaH = s.textH

    -- Portrait à esquerda, se houver
    if s.portrait then
        local ph = math.min(PORTRAIT_H, textAreaH)
        sc({1, 1, 1, 1})
        love.graphics.draw(s.portrait, textAreaX, textAreaY,
            0,
            PORTRAIT_W / s.portrait:getWidth(),
            ph / s.portrait:getHeight())
        -- Borda no portrait
        rect(textAreaX, textAreaY, PORTRAIT_W, ph, C.border, "line", 2)
        textAreaX = textAreaX + PORTRAIT_W + PADDING
        textAreaW = textAreaW - PORTRAIT_W - PADDING
    end

    -- Clipping da área de texto
    love.graphics.setScissor(textAreaX, textAreaY, textAreaW, textAreaH)

    love.graphics.setFont(fontBody)
    local lineY = textAreaY - math.floor(s.textScroll)
    for _, line in ipairs(s._lines or {}) do
        if line == "" then
            -- linha em branco (separador de parágrafo)
        else
            sc(C.textNormal)
            love.graphics.print(line, textAreaX, lineY)
        end
        lineY = lineY + LINE_H
    end

    love.graphics.setScissor()

    -- Scrollbar do texto (se necessário)
    if s.textFullH > MAX_TEXT_H then
        local maxScroll = s.textFullH - MAX_TEXT_H
        local ratio     = MAX_TEXT_H / s.textFullH
        local thumbH    = math.max(14, textAreaH * ratio)
        local thumbY    = textAreaY + (s.textScroll / maxScroll) * (textAreaH - thumbH)
        sc(C.bgDark)
        love.graphics.rectangle("fill", s.x + W - 6, textAreaY, 4, textAreaH)
        sc(C.border)
        love.graphics.rectangle("fill", s.x + W - 6, thumbY, 4, thumbH, 2)
    end

    -- Gradiente de fade na borda inferior do texto (quando há scroll)
    if s.textFullH > MAX_TEXT_H and s.textScroll < s.textFullH - MAX_TEXT_H then
        local fadeH = 20
        local fadeY = textAreaY + textAreaH - fadeH
        for i = 0, fadeH do
            local alpha = (i / fadeH) * 0.85
            love.graphics.setColor(C.bg[1], C.bg[2], C.bg[3], alpha)
            love.graphics.rectangle("fill", s.x + PADDING, fadeY + i, textAreaW, 1)
        end
    end

    -- ── Divisor antes das opções ──
    if #s.options > 0 then
        local divY = s.optionsY - 1
        sc(C.border)
        love.graphics.rectangle("fill", s.x, divY, W, 1)

        -- Linhas de opção
        local visOpts = math.min(#s.options, MAX_OPT_VISIBLE)
        for i = 1, visOpts do
            local realIdx = i + s.optScroll
            if realIdx > #s.options then break end
            local opt  = s.options[realIdx]
            local rowY = s.optionsY + (i - 1) * OPTION_H
            local isSel = s.selectedIdx == realIdx
            local isHov = mx >= s.x and mx <= s.x + W
                       and my >= rowY and my < rowY + OPTION_H

            -- Fundo da linha
            local bg = isSel and C.bgRowSel or (isHov and C.bgRowHover or C.bgRow)
            sc(bg)
            love.graphics.rectangle("fill", s.x, rowY, W, OPTION_H)

            -- Acento lateral
            if isSel then
                sc(C.borderAccent)
                love.graphics.rectangle("fill", s.x, rowY, 2, OPTION_H)
            end

            -- Número da opção
            love.graphics.setFont(fontHint)
            sc(isSel and C.borderAccent or C.textMuted)
            local numStr = tostring(realIdx) .. "."
            love.graphics.print(numStr, s.x + PADDING, rowY + math.floor(OPTION_H / 2 - fontHint:getHeight() / 2))

            -- Label da opção
            love.graphics.setFont(fontOption)
            sc(isSel and C.textActive or (isHov and C.textBright or C.textNormal))
            love.graphics.print(opt.label or "?",
                s.x + PADDING + 20,
                rowY + math.floor(OPTION_H / 2 - fontOption:getHeight() / 2))

            -- Divisor de linha
            sc(C.border)
            love.graphics.rectangle("fill", s.x, rowY + OPTION_H - 1, W, 1)
        end

        -- Scrollbar das opções
        if #s.options > MAX_OPT_VISIBLE then
            local trackH = visOpts * OPTION_H
            local ratio  = MAX_OPT_VISIBLE / #s.options
            local thumbH = math.max(12, trackH * ratio)
            local thumbY = s.optionsY + (s.optScroll / s.maxOptScroll) * (trackH - thumbH)
            sc(C.bgDark)
            love.graphics.rectangle("fill", s.x + W - 5, s.optionsY, 4, trackH)
            sc(C.border)
            love.graphics.rectangle("fill", s.x + W - 5, thumbY, 4, thumbH, 2)
        end
    end

    -- ── Footer ──
    sc(C.border)
    love.graphics.rectangle("fill", s.x, s.footerY, W, 1)

    -- Hint de teclado
    love.graphics.setFont(fontHint)
    sc(C.textMuted)
    local hint = #s.options > 0
        and "↑↓ navegar  ·  Enter confirma  ·  Esc fecha"
        or  "Enter / Espaço continua  ·  Esc fecha"
    love.graphics.print(hint,
        s.x + PADDING,
        s.btnY + math.floor(BTN_H / 2 - fontHint:getHeight() / 2))

    -- Botão principal
    local btnLabel = #s.options > 0 and "Confirmar" or "Continuar"
    local btnHov = mx >= s.btnX and mx <= s.btnX + BTN_W
                and my >= s.btnY and my <= s.btnY + BTN_H
    rect(s.btnX, s.btnY, BTN_W, BTN_H,
        btnHov and {0.20, 0.10, 0.02, 1} or C.bgDark, "fill", 3)
    rect(s.btnX, s.btnY, BTN_W, BTN_H,
        btnHov and C.borderAccent or C.border, "line", 3)
    if btnHov then
        sc(C.borderAccent)
        love.graphics.rectangle("fill", s.btnX, s.btnY, 2, BTN_H)
    end
    love.graphics.setFont(fontBtn)
    sc(btnHov and C.textActive or C.textNormal)
    love.graphics.print(btnLabel,
        s.btnX + math.floor(BTN_W / 2 - fontBtn:getWidth(btnLabel) / 2),
        s.btnY + math.floor(BTN_H / 2 - fontBtn:getHeight() / 2))

    love.graphics.setColor(1, 1, 1, 1)
end

return DialogueUI
