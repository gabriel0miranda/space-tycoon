local itemData = require("data.items")
local InventoryUI = {}

-- Cores por categoria de item
local itemColors = {
    rare     = {0.91, 0.75, 0.37, 1},
    uncommon = {0.37, 0.72, 0.44, 1},
    danger   = {0.87, 0.43, 0.37, 1},
    default  = {0.78, 0.81, 0.88, 1},
}

-- Cores da UI
local colors = {
    bg          = {0.10, 0.12, 0.18, 1},
    bgDark      = {0.05, 0.07, 0.13, 1},
    bgHover     = {0.12, 0.16, 0.25, 1},
    bgSelected  = {0.10, 0.19, 0.33, 1},
    border      = {0.23, 0.29, 0.42, 1},
    borderAccent= {0.29, 0.54, 0.83, 1},
    textPrimary = {0.78, 0.81, 0.88, 1},
    textMuted   = {0.42, 0.53, 0.67, 1},
    headerBg    = {0.07, 0.09, 0.16, 1},
}

-- Estado interno: lista de painéis abertos
local panels = {}

-- Configurações de layout
local PANEL_WIDTH   = 320
local HEADER_H      = 28
local SHIPNAME_H    = 22
local ROW_H         = 20
local SECTION_HDR_H = 20
local DIVIDER_H     = 12
local FOOTER_H      = 30
local PADDING_X     = 8
local MAX_EXT_ROWS  = 9  -- máximo de linhas visíveis nas extensões (scroll)

-- Referência para a fonte (inicializada no load)
local fontSmall, fontNormal

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function InventoryUI.load()
    fontSmall  = love.graphics.newFont(10)
    fontNormal = love.graphics.newFont(12)
end

-- Abre um painel para uma entidade.
-- config: { title, x, y, readonly }
function InventoryUI.open(entity, config)
    -- Evita abrir o mesmo inventário duas vezes
    for _, p in ipairs(panels) do
        if p.entity == entity then return end
    end

    config = config or {}
    table.insert(panels, {
        entity      = entity,
        inventory   = entity.inventory,
        title       = config.title   or "Inventory",
        readonly    = config.readonly or false,
        x           = config.x       or (100 + (#panels * 340)),
        y           = config.y       or 80,
        selectedIdx = nil,
        extScroll   = 0,          -- offset de scroll das extensões
        dragging    = false,
        dragOffX    = 0,
        dragOffY    = 0,
    })
end

function InventoryUI.close(entity)
    for i, p in ipairs(panels) do
        if p.entity == entity then
            table.remove(panels, i)
            return
        end
    end
end

function InventoryUI.closeAll()
    panels = {}
end

function InventoryUI.isOpen(entity)
    for _, p in ipairs(panels) do
        if p.entity == entity then return true end
    end
    return false
end

function InventoryUI.toggle(entity, config)
    if InventoryUI.isOpen(entity) then
        love.mouse.setVisible(false)
        love.mouse.setRelativeMode(true)
        InventoryUI.close(entity)
    else
        love.mouse.setVisible(true)
        love.mouse.setRelativeMode(false)
        InventoryUI.open(entity, config)
    end
end

-- ─────────────────────────────────────────
-- Update / input
-- ─────────────────────────────────────────

function InventoryUI.update(dt)
    if love.mouse.isDown(1) then
        for _, p in ipairs(panels) do
            if p.dragging then
                local mx, my = love.mouse.getPosition()
                p.x = mx - p.dragOffX
                p.y = my - p.dragOffY
            end
        end
    else
        for _, p in ipairs(panels) do
            p.dragging = false
        end
    end
end

function InventoryUI.mousepressed(mx, my, button)
    -- Percorre de trás pra frente para dar prioridade ao painel do topo
    for i = #panels, 1, -1 do
        local p = panels[i]
        local pw, ph = getPanelSize(p)

        if mx >= p.x and mx <= p.x + pw and my >= p.y and my <= p.y + ph then
            -- Traz para o topo
            local panel = table.remove(panels, i)
            table.insert(panels, panel)

            if button == 1 then
                -- Clique no header → inicia drag
                if my >= p.y and my <= p.y + HEADER_H then
                    -- Botão de fechar (canto direito)
                    if mx >= p.x + pw - 22 and mx <= p.x + pw - 2 then
                        InventoryUI.close(p.entity)
                        return
                    end
                    p.dragging = true
                    p.dragOffX = mx - p.x
                    p.dragOffY = my - p.y
                    return
                end

                -- Clique nas linhas de goods
                local goodsY = p.y + HEADER_H + SHIPNAME_H + SECTION_HDR_H
                local inv = p.inventory
                local goods = getGoods(inv)
                for idx, _ in ipairs(goods) do
                    local rowY = goodsY + (idx - 1) * ROW_H
                    if my >= rowY and my < rowY + ROW_H then
                        p.selectedIdx = "goods_" .. idx
                        return
                    end
                end

                -- Clique nas linhas de extensões
                local extStartY = goodsY + #goods * ROW_H + DIVIDER_H + SECTION_HDR_H
                local exts = getExtensions(inv)
                local visibleExts = math.min(#exts, MAX_EXT_ROWS)
                for idx = 1, visibleExts do
                    local realIdx = idx + p.extScroll
                    if realIdx <= #exts then
                        local rowY = extStartY + (idx - 1) * ROW_H
                        if my >= rowY and my < rowY + ROW_H then
                            p.selectedIdx = "ext_" .. realIdx
                            return
                        end
                    end
                end
            end
            return
        end
    end
end

function InventoryUI.wheelmoved(dx, dy)
    local mx, my = love.mouse.getPosition()
    for i = #panels, 1, -1 do
        local p = panels[i]
        local pw, ph = getPanelSize(p)
        if mx >= p.x and mx <= p.x + pw and my >= p.y and my <= p.y + ph then
            local inv = p.inventory
            local exts = getExtensions(inv)
            local maxScroll = math.max(0, #exts - MAX_EXT_ROWS)
            p.extScroll = math.max(0, math.min(maxScroll, p.extScroll - dy))
            return
        end
    end
end

-- ─────────────────────────────────────────
-- Draw
-- ─────────────────────────────────────────

function InventoryUI.draw()
    for _, p in ipairs(panels) do
        drawPanel(p)
    end
end

-- ─────────────────────────────────────────
-- Funções internas
-- ─────────────────────────────────────────

function getGoods(inv)
    local list = {}
    for itemName, quantity in pairs(inv.items) do
        local meta = itemData[itemName] or {}
        if meta.category ~= "extension" then
            table.insert(list, {
                name   = itemName,
                amount = quantity,
                rarity = meta.rarity  or "default",
                volume = meta.volume  or "—",
            })
        end
    end
    return list
end

function getExtensions(inv)
    local list = {}
    for itemName, quantity in pairs(inv.items) do
        local meta = itemData[itemName] or {}
        if meta.category == "extension" then
            table.insert(list, {
                name   = itemName,
                amount = quantity,
            })
        end
    end
    return list
end

function getPanelSize(p)
    local inv = p.inventory
    local goods = getGoods(inv)
    local exts  = getExtensions(inv)
    local visibleExts = math.min(#exts, MAX_EXT_ROWS)

    local h = HEADER_H
             + SHIPNAME_H
             + SECTION_HDR_H
             + #goods * ROW_H
             + DIVIDER_H
             + SECTION_HDR_H
             + visibleExts * ROW_H
             + FOOTER_H

    return PANEL_WIDTH, h
end

function setColor(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

function drawRect(x, y, w, h, c, fill)
    setColor(c)
    if fill == false then
        love.graphics.rectangle("line", x, y, w, h)
    else
        love.graphics.rectangle("fill", x, y, w, h)
    end
end

function drawText(text, x, y, c, font)
    setColor(c)
    love.graphics.setFont(font or fontNormal)
    love.graphics.print(text, x, y)
end

function drawPanel(p)
    local inv = p.inventory
    if not inv then return end

    local goods = getGoods(inv)
    local exts  = getExtensions(inv)
    local pw, ph = getPanelSize(p)
    local x, y = math.floor(p.x), math.floor(p.y)

    -- Fundo principal
    drawRect(x, y, pw, ph, colors.bg)
    drawRect(x, y, pw, ph, colors.border, false)

    local curY = y

    -- ── Titlebar ──
    drawRect(x, curY, pw, HEADER_H, colors.bgDark)
    drawText(p.title, x + PADDING_X + 18, curY + 6, colors.textPrimary, fontNormal)
    -- Ícone caixinha
    setColor(colors.borderAccent)
    love.graphics.rectangle("fill", x + PADDING_X, curY + 8, 12, 10, 2)
    -- Botão fechar
    local btnX = x + pw - 20
    drawRect(btnX, curY + 6, 16, 16, colors.bgHover)
    drawRect(btnX, curY + 6, 16, 16, colors.border, false)
    drawText("×", btnX + 4, curY + 6, colors.textMuted, fontNormal)
    -- Linha inferior header
    drawRect(x, curY + HEADER_H - 1, pw, 1, colors.border)
    curY = curY + HEADER_H

    -- ── Nome da nave / entidade ──
    drawRect(x, curY, pw, SHIPNAME_H, colors.bgDark)
    local shipLabel = p.entity.name or "Unknown Vessel"
    setColor(colors.textMuted)
    love.graphics.setFont(fontSmall)
    local tw = love.graphics.getFont():getWidth(shipLabel)
    love.graphics.print(shipLabel, x + (pw - tw) / 2, curY + 5)
    drawRect(x, curY + SHIPNAME_H - 1, pw, 1, colors.border)
    curY = curY + SHIPNAME_H

    -- ── Cabeçalho de goods ──
    local capacityUsed = inv.capacityUsed or 0
    local capacity  = inv.capacity  or 0
    drawRect(x, curY, pw, SECTION_HDR_H, colors.headerBg)
    drawText("Goods — " .. capacityUsed .. "/" .. capacity .. " units",
             x + PADDING_X, curY + 3, colors.textMuted, fontSmall)
    drawText("Amount", x + pw - 100, curY + 3, colors.textMuted, fontSmall)
    drawText("Vol", x + pw - 46, curY + 3, colors.textMuted, fontSmall)
    drawRect(x, curY + SECTION_HDR_H - 1, pw, 1, {0.16, 0.21, 0.33, 1})
    curY = curY + SECTION_HDR_H

    -- ── Linhas de goods ──
    for idx, item in ipairs(goods) do
        local rowY = curY + (idx - 1) * ROW_H
        local isSelected = p.selectedIdx == "goods_" .. idx

        if isSelected then
            drawRect(x + 2, rowY, pw - 4, ROW_H, colors.bgSelected)
            drawRect(x, rowY, 2, ROW_H, colors.borderAccent)
        else
            local mx, my = love.mouse.getPosition()
            if mx >= x and mx <= x + pw and my >= rowY and my < rowY + ROW_H then
                drawRect(x, rowY, pw, ROW_H, colors.bgHover)
            end
        end

        local nameColor = itemColors[item.rarity] or itemColors.default
        drawText(item.name or "?", x + PADDING_X, rowY + 3, nameColor, fontNormal)
        drawText(tostring(item.amount or 1), x + pw - 96, rowY + 3, colors.textMuted, fontSmall)
        local volStr = (item.volume or "—")
        drawText(volStr, x + pw - 46, rowY + 3, colors.textMuted, fontSmall)

        drawRect(x, rowY + ROW_H - 1, pw, 1, {0.12, 0.15, 0.21, 1})
    end
    curY = curY + #goods * ROW_H

    -- ── Divisor ──
    drawRect(x, curY, pw, DIVIDER_H, colors.bgDark)
    drawRect(x, curY, pw, 1, colors.border)
    drawRect(x, curY + DIVIDER_H - 1, pw, 1, colors.border)
    -- triângulo decorativo
    setColor(colors.textMuted)
    love.graphics.polygon("fill",
        x + pw/2 - 5, curY + 3,
        x + pw/2 + 5, curY + 3,
        x + pw/2,     curY + DIVIDER_H - 3
    )
    curY = curY + DIVIDER_H

    -- ── Cabeçalho de extensões ──
    drawRect(x, curY, pw, SECTION_HDR_H, colors.headerBg)
    drawText("Installed Ship Extensions", x + PADDING_X, curY + 3, colors.textMuted, fontSmall)
    drawText("Amount", x + pw - 100, curY + 3, colors.textMuted, fontSmall)
    drawRect(x, curY + SECTION_HDR_H - 1, pw, 1, {0.16, 0.21, 0.33, 1})
    curY = curY + SECTION_HDR_H

    -- ── Linhas de extensões (com scroll) ──
    local visibleExts = math.min(#exts, MAX_EXT_ROWS)
    for i = 1, visibleExts do
        local realIdx = i + math.floor(p.extScroll)
        local item = exts[realIdx]
        if not item then break end

        local rowY = curY + (i - 1) * ROW_H
        local isSelected = p.selectedIdx == "ext_" .. realIdx

        if isSelected then
            drawRect(x + 2, rowY, pw - 4, ROW_H, colors.bgSelected)
            drawRect(x, rowY, 2, ROW_H, colors.borderAccent)
        else
            local mx, my = love.mouse.getPosition()
            if mx >= x and mx <= x + pw and my >= rowY and my < rowY + ROW_H then
                drawRect(x, rowY, pw, ROW_H, colors.bgHover)
            end
        end

        drawText(item.name or "?", x + PADDING_X, rowY + 3, colors.textPrimary, fontNormal)
        drawText(tostring(item.amount or 1), x + pw - 96, rowY + 3, colors.textMuted, fontSmall)
        drawRect(x, rowY + ROW_H - 1, pw, 1, {0.12, 0.15, 0.21, 1})
    end

    -- Indicador de scroll
    if #exts > MAX_EXT_ROWS then
        local scrollRatio = p.extScroll / (#exts - MAX_EXT_ROWS)
        local trackH = visibleExts * ROW_H
        local thumbH = math.max(20, trackH * (MAX_EXT_ROWS / #exts))
        local thumbY = curY + scrollRatio * (trackH - thumbH)
        drawRect(x + pw - 4, curY, 3, trackH, colors.bgDark)
        drawRect(x + pw - 4, thumbY, 3, thumbH, colors.border)
    end

    curY = curY + visibleExts * ROW_H

    -- ── Footer ──
    drawRect(x, curY, pw, FOOTER_H, colors.bgDark)
    drawRect(x, curY, pw, 1, colors.border)

    local freightLabel = "Freight  " .. capacityUsed .. "/" .. capacity
    drawText(freightLabel, x + PADDING_X, curY + 8, colors.textMuted, fontSmall)

    -- Reseta cor
    love.graphics.setColor(1, 1, 1, 1)
end

return InventoryUI
