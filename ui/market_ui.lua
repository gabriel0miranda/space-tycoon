-- ui/market_ui.lua
-- Interface de mercado: o jogador vende itens à estação e compra itens da estação.
-- Preços de compra  = o que a ESTAÇÃO paga ao jogador (verde)
-- Preços de venda   = o que a ESTAÇÃO cobra do jogador (vermelho)
-- Itens com ★ são "demanded" — a estação paga mais por eles.

local MarketUI = {}

-- ─────────────────────────────────────────
-- Estado
-- ─────────────────────────────────────────

local open      = false
local ship      = nil
local station   = nil
local selected  = nil       -- item selecionado
local offering  = {}        -- { [item] = qty } — jogador vende
local requesting= {}        -- { [item] = qty } — jogador compra
local scroll    = 0         -- scroll da lista da estação
local msgTimer  = 0
local msg       = ""
local msgColor  = {1,1,1,1}

local MAX_VISIBLE = 8

-- ─────────────────────────────────────────
-- Cores (herda o tema marrom do landed)
-- ─────────────────────────────────────────

local C = {
    bg          = {0.06, 0.03, 0.01, 0.97},
    bgDark      = {0.04, 0.02, 0.01, 1},
    bgRow       = {0.08, 0.04, 0.02, 1},
    bgRowHover  = {0.12, 0.06, 0.02, 1},
    bgRowSel    = {0.16, 0.08, 0.02, 1},
    bgInput     = {0.04, 0.02, 0.01, 1},
    border      = {0.23, 0.13, 0.05, 1},
    borderAccent= {0.75, 0.38, 0.13, 1},
    textNormal  = {0.78, 0.62, 0.42, 1},
    textBright  = {0.92, 0.78, 0.58, 1},
    textMuted   = {0.38, 0.22, 0.10, 1},
    textActive  = {0.88, 0.60, 0.22, 1},
    textBuy     = {0.35, 0.72, 0.35, 1},  -- estação compra (verde)
    textSell    = {0.80, 0.35, 0.25, 1},  -- estação vende (vermelho)
    textDemand  = {0.95, 0.75, 0.20, 1},  -- item demandado (dourado)
    balPos      = {0.35, 0.72, 0.35, 1},
    balNeg      = {0.80, 0.35, 0.25, 1},
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local W, H       = 680, 480
local ROW_H      = 22
local COL_QTY    = 100
local COL_BUY    = 80
local COL_SELL   = 80
local PAD        = 12
local HEADER_H   = 24
local SECTION_H  = 18
local FOOTER_H   = 44

-- Posição centrada na tela (calculada no open)
local PX, PY = 0, 0

-- ─────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────

local function sc(c) love.graphics.setColor(c[1],c[2],c[3],c[4] or 1) end
local function rect(x,y,w,h,col,mode) sc(col); love.graphics.rectangle(mode or "fill",x,y,w,h,2) end

local function getStationItems()
    if not station or not station.inventory then return {} end
    local list = {}
    local demanded = station.market and station.market.demanded or {}
    for item, qty in pairs(station.inventory.items) do
        local price = station.market.prices and station.market.prices[item]
        table.insert(list, {
            item     = item,
            qty      = qty,
            buy      = price and price.buy  or 0,
            sell     = price and price.sell or 0,
            demanded = demanded[item] ~= nil,
        })
    end
    table.sort(list, function(a,b)
        if a.demanded ~= b.demanded then return a.demanded end
        return a.item < b.item
    end)
    return list
end

local function getShipItems()
    if not ship or not ship.inventory then return {} end
    local list = {}
    for item, qty in pairs(ship.inventory.items) do
        local price = station.market.prices and station.market.prices[item]
        table.insert(list, {
            item = item,
            qty  = qty,
            buy  = price and price.buy or 0,
        })
    end
    table.sort(list, function(a,b) return a.item < b.item end)
    return list
end

local function calcBalance()
  local offeringList  = {}
  local requestingList = {}
  for item, qty in pairs(offering)   do offeringList[#offeringList+1]     = {item=item, qty=qty} end
  for item, qty in pairs(requesting) do requestingList[#requestingList+1] = {item=item, qty=qty} end
  return config.MarketSystem.calculateBalance(station, offeringList, requestingList)
end

local function showMsg(text, color)
    msg      = text
    msgColor = color or C.textBright
    msgTimer = 2.5
end

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function MarketUI.open(shipEntity, stationEntity)
    config.Input.pushContext("market")
    ship      = shipEntity
    station   = stationEntity
    open      = true
    selected  = nil
    offering  = {}
    requesting= {}
    scroll    = 0
    msg       = ""
    msgTimer  = 0

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    PX = math.floor(sw / 2 - W / 2)
    PY = math.floor(sh / 2 - H / 2)
end

function MarketUI.close()
    config.Input.popContext("market")
    open = false
    ship = nil
    station = nil
end

function MarketUI.isOpen() return open end

-- ─────────────────────────────────────────
-- Update
-- ─────────────────────────────────────────

function MarketUI.update(dt)
    if not open then return end
    if config.Input.state.ui_cancel then
      MarketUI.close()
    end
    if msgTimer > 0 then msgTimer = msgTimer - dt end
end

-- ─────────────────────────────────────────
-- Input
-- ─────────────────────────────────────────

-- Retorna o rect de um botão +/- para um item numa lista
-- side: "offer" | "request"
local btnRects = {}  -- populado no draw

function MarketUI.keypressed(key)
end

function MarketUI.mousepressed(mx, my, button)
    if not open then return end
    if button ~= 1 then return end

    -- Botão fechar
    if mx >= PX + W - 22 and mx <= PX + W - 4 and my >= PY + 4 and my <= PY + 22 then
        MarketUI.close()
        return
    end

    -- Botão Confirmar
    local confirmX = PX + W / 2 - 50
    local confirmY = PY + H - FOOTER_H + 10
    if mx >= confirmX and mx <= confirmX + 100 and my >= confirmY and my <= confirmY + 24 then
        MarketUI.executeTrade()
        return
    end

    -- Botão Limpar
    local clearX = PX + W / 2 + 60
    if mx >= clearX and mx <= clearX + 70 and my >= confirmY and my <= confirmY + 24 then
        offering  = {}
        requesting= {}
        return
    end

    -- Clique em botões +/- das linhas
    for _, r in ipairs(btnRects) do
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            r.action()
            return
        end
    end
end

function MarketUI.wheelmoved(dx, dy)
    if not open then return end
    local items = getStationItems()
    local maxScroll = math.max(0, #items - MAX_VISIBLE)
    scroll = math.max(0, math.min(maxScroll, scroll - dy))
end

-- ─────────────────────────────────────────
-- Trade execution
-- ─────────────────────────────────────────

function MarketUI.executeTrade()
  local offeringList   = {}
  local requestingList = {}
  for item, qty in pairs(offering)   do offeringList[#offeringList+1]     = {item=item, qty=qty} end
  for item, qty in pairs(requesting) do requestingList[#requestingList+1] = {item=item, qty=qty} end

  local ok, result = config.MarketSystem.executeTrade(station, ship, offeringList, requestingList)
  if ok then
    local sign = result >= 0 and "+" or ""
    showMsg("Trade complete! " .. sign .. result .. " cr", result >= 0 and C.balPos or C.textBright)
    offering   = {}
    requesting = {}
  else
    showMsg(result, C.textSell)  -- result é a mensagem de erro quando ok=false
  end
end

-- ─────────────────────────────────────────
-- Draw helpers
-- ─────────────────────────────────────────

local function drawQtyBtn(x, y, label, action)
    table.insert(btnRects, { x=x, y=y, w=16, h=16, action=action })
    rect(x, y, 16, 16, C.bgDark)
    rect(x, y, 16, 16, C.border, "line")
    sc(C.textActive)
    love.graphics.setFont(config.smallFont)
    love.graphics.print(label, x + 4, y + 2)
end

local function drawRow(x, y, w, rowData, side, isHovered)
    -- side: "station" | "ship"
    local item     = rowData.item
    local stQty    = rowData.qty
    local offerQty = offering[item]   or 0
    local reqQty   = requesting[item] or 0

    local bg = isHovered and C.bgRowHover or C.bgRow
    rect(x, y, w, ROW_H, bg)

    -- Nome
    local nameColor = rowData.demanded and C.textDemand or C.textNormal
    sc(nameColor)
    love.graphics.setFont(config.smallFont)
    local label = rowData.demanded and (rowData.item .. " *") or rowData.item
    love.graphics.print(label, x + 6, y + 4)

    -- Quantidade em estoque
    sc(C.textMuted)
    love.graphics.printf(tostring(stQty), x + w - COL_SELL - COL_BUY - COL_QTY, y + 4, COL_QTY, "right")

    if side == "station" then
        -- Preço compra (estação paga ao jogador)
        sc(C.textBuy)
        love.graphics.printf(rowData.buy .. "cr", x + w - COL_SELL - COL_BUY, y + 4, COL_BUY - 4, "right")
        -- Preço venda (estação cobra do jogador)
        sc(C.textSell)
        love.graphics.printf(rowData.sell .. "cr", x + w - COL_SELL, y + 4, COL_SELL - 4, "right")

        -- Botão: jogador COMPRA da estação (requesting)
        local btnX = x + w - COL_SELL - COL_BUY - COL_QTY - 40
        if stQty > 0 then
            drawQtyBtn(btnX, y + 3, "+", function()
                requesting[item] = (requesting[item] or 0) + 1
                if requesting[item] > stQty then requesting[item] = stQty end
            end)
            drawQtyBtn(btnX + 18, y + 3, "-", function()
                requesting[item] = math.max(0, (requesting[item] or 0) - 1)
                if requesting[item] == 0 then requesting[item] = nil end
            end)
            if reqQty > 0 then
                sc(C.textActive)
                love.graphics.print("→" .. reqQty, btnX + 36, y + 4)
            end
        end

    else -- ship
        -- Preço que a estação paga
        sc(C.textBuy)
        love.graphics.printf(rowData.buy .. "cr", x + w - COL_BUY, y + 4, COL_BUY - 4, "right")

        -- Botão: jogador VENDE à estação (offering)
        local btnX = x + w - COL_BUY - 40
        drawQtyBtn(btnX, y + 3, "+", function()
            local shipQty = ship.inventory.items[item] or 0
            offering[item] = (offering[item] or 0) + 1
            if offering[item] > shipQty then offering[item] = shipQty end
        end)
        drawQtyBtn(btnX + 18, y + 3, "-", function()
            offering[item] = math.max(0, (offering[item] or 0) - 1)
            if offering[item] == 0 then offering[item] = nil end
        end)
        if offerQty > 0 then
            sc(C.textActive)
            love.graphics.print("→" .. offerQty, btnX + 36, y + 4)
        end
    end

    -- Linha separadora
    rect(x, y + ROW_H - 1, w, 1, {0.10, 0.05, 0.02, 1})
end

-- ─────────────────────────────────────────
-- Draw principal
-- ─────────────────────────────────────────

function MarketUI.draw()
    if not open then return end

    btnRects = {}  -- reseta hitboxes

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    -- Overlay escuro
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Painel principal
    rect(PX, PY, W, H, C.bg)
    rect(PX, PY, W, H, C.border, "line")

    -- ── Titlebar ──
    rect(PX, PY, W, HEADER_H, C.bgDark)
    sc(C.textActive)
    love.graphics.setFont(config.normalFont)
    love.graphics.print("Market · " .. (station and station.name or "?"), PX + PAD, PY + 4)

    -- Botão fechar
    rect(PX + W - 22, PY + 4, 18, 16, C.bgRow)
    rect(PX + W - 22, PY + 4, 18, 16, C.border, "line")
    sc(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("x", PX + W - 16, PY + 6)

    --rect(PX, PY + HEADER_H, W, 1, C.border)

    local curY = PY + HEADER_H + 4

    -- ── Cabeçalho da lista da estação ──
    local listW = W - PAD * 2
    local listX = PX + PAD

    rect(listX, curY, listW, SECTION_H, C.bgDark)
    sc(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("STATION STOCK", listX + 4, curY + 3)
    love.graphics.printf("QTY",  listX + listW - COL_SELL - COL_BUY - COL_QTY, curY + 3, COL_QTY,  "right")
    sc(C.textBuy)
    love.graphics.printf("BUYS", listX + listW - COL_SELL - COL_BUY, curY + 3, COL_BUY - 4, "right")
    sc(C.textSell)
    love.graphics.printf("SELLS", listX + listW - COL_SELL, curY + 3, COL_SELL - 4, "right")
    curY = curY + SECTION_H

    -- ── Lista da estação ──
    local stItems = getStationItems()
    local mx, my  = love.mouse.getPosition()

    for i = 1, math.min(MAX_VISIBLE, #stItems) do
        local idx  = i + math.floor(scroll)
        local item = stItems[idx]
        if not item then break end
        local ry   = curY + (i - 1) * ROW_H
        local hov  = mx >= listX and mx <= listX + listW and my >= ry and my < ry + ROW_H
        drawRow(listX, ry, listW, item, "station", hov)
    end

    -- Scrollbar da estação
    if #stItems > MAX_VISIBLE then
        local trackH = MAX_VISIBLE * ROW_H
        local thumbH = math.max(20, trackH * (MAX_VISIBLE / #stItems))
        local thumbY = curY + (scroll / (#stItems - MAX_VISIBLE)) * (trackH - thumbH)
        rect(listX + listW - 3, curY, 3, trackH, C.bgDark)
        rect(listX + listW - 3, thumbY, 3, thumbH, C.border)
    end

    curY = curY + MAX_VISIBLE * ROW_H + 4

    -- ── Divider ──
    rect(listX, curY, listW, 1, C.border)
    curY = curY + 4

    -- ── Lista do jogador ──
    local shipItems = getShipItems()
    rect(listX, curY, listW, SECTION_H, C.bgDark)
    sc(C.textMuted)
    love.graphics.print("YOUR CARGO", listX + 4, curY + 3)
    sc(C.textBuy)
    love.graphics.printf("SELL FOR", listX + listW - COL_BUY, curY + 3, COL_BUY - 4, "right")
    curY = curY + SECTION_H

    if #shipItems == 0 then
        sc(C.textMuted)
        love.graphics.print("(empty)", listX + 6, curY + 4)
        curY = curY + ROW_H
    else
        for _, item in ipairs(shipItems) do
            local ry  = curY
            local hov = mx >= listX and mx <= listX + listW and my >= ry and my < ry + ROW_H
            drawRow(listX, ry, listW, item, "ship", hov)
            curY = curY + ROW_H
        end
    end

    -- ── Footer ──
    local footerY = PY + H - FOOTER_H
    rect(PX, footerY, W, 1, C.border)
    rect(PX, footerY, W, FOOTER_H, C.bgDark)

    -- Balanço
    local balance = calcBalance()
    local balCol  = balance >= 0 and C.balPos or C.balNeg
    local sign    = balance >= 0 and "+" or ""
    sc(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("Balance:", PX + PAD, footerY + 14)
    sc(balCol)
    love.graphics.setFont(config.normalFont)
    love.graphics.print(sign .. balance .. " cr", PX + PAD + 56, footerY + 11)

    local player = config.Entities.getByTag("player")[1]
    -- Créditos do jogador
    if player and player.credits then
        sc(C.textMuted)
        love.graphics.setFont(config.smallFont)
        love.graphics.print("Credits: " .. player.credits.amount, PX + PAD + 160, footerY + 14)
    end

    -- Botão Confirmar
    local confirmX = PX + W / 2 - 50
    local confirmY = footerY + 10
    rect(confirmX, confirmY, 100, 24, {0.12, 0.06, 0.02, 1})
    rect(confirmX, confirmY, 100, 24, C.borderAccent, "line")
    sc(C.textActive)
    love.graphics.setFont(config.smallFont)
    love.graphics.printf("Confirm", confirmX, confirmY + 6, 100, "center")

    -- Botão Limpar
    local clearX = PX + W / 2 + 60
    rect(clearX, confirmY, 70, 24, C.bgRow)
    rect(clearX, confirmY, 70, 24, C.border, "line")
    sc(C.textMuted)
    love.graphics.printf("Clear", clearX, confirmY + 6, 70, "center")

    -- Nota sobre ★
    sc(C.textDemand)
    love.graphics.print("* = high demand (better price)", PX + W - 200, footerY + 14)

    -- Mensagem de feedback
    if msgTimer > 0 then
        sc(msgColor)
        love.graphics.setFont(config.smallFont)
        local tw = config.smallFont:getWidth(msg)
        love.graphics.print(msg, PX + W / 2 - tw / 2, footerY - 20)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return MarketUI
