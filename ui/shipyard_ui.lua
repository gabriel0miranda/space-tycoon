-- ui/shipyard_ui.lua
-- Interface do estaleiro: compra e venda de naves.
-- Layout: painel esquerdo (estoque da estação) | centro (ficha técnica) | direito (frota do jogador)

local ShipyardUI = {}

-- ─────────────────────────────────────────
-- Estado
-- ─────────────────────────────────────────

local open               = false
local player             = nil
local station            = nil
local selectedStation    = nil   -- shipType string (compra)
local selectedFleet      = nil   -- entidade de nave (venda / set como flagship)
local msgTimer           = 0
local msg                = ""
local msgColor           = nil

-- ─────────────────────────────────────────
-- Cores (tema marrom — igual ao market_ui)
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
    textBuy     = {0.35, 0.72, 0.35, 1},
    textSell    = {0.80, 0.35, 0.25, 1},
    textDanger  = {0.80, 0.30, 0.20, 1},
    balPos      = {0.35, 0.72, 0.35, 1},
    balNeg      = {0.80, 0.35, 0.25, 1},
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local W         = 740
local H         = 460
local HEADER_H  = 26
local SECTION_H = 18
local ROW_H     = 24
local FOOTER_H  = 48
local PAD       = 12
local COL_L     = 210   -- largura coluna esquerda (estoque)
local COL_R     = 200   -- largura coluna direita  (frota)
-- coluna central ocupa o resto

local PX, PY = 0, 0     -- posição do painel (calculada no open)

-- Hitboxes de botões (populadas no draw)
local btnRects = {}

-- ─────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────

local function sc(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function rect(x, y, w, h, col, mode)
    sc(col)
    love.graphics.rectangle(mode or "fill", x, y, w, h, 2)
end

local function addBtn(x, y, w, h, action)
    table.insert(btnRects, {x=x, y=y, w=w, h=h, action=action})
end

local function showMsg(text, color)
    msg      = text
    msgColor = color or C.textBright
    msgTimer = 3.0
end

-- Retorna lista ordenada do estoque da estação
local function getStationStock()
    if not station then return {} end
    local data = config.Landables[station.name]
    local sy   = data and data.shipyard
    if not sy or not sy.stock then return {} end
    local list = {}
    for _, shipType in ipairs(sy.stock) do
        local def = config.Ships[shipType]
        if def then
            table.insert(list, { shipType = shipType, def = def })
        end
    end
    return list
end

-- Retorna lista ordenada da frota do jogador
local function getFleet()
    if not player or not player.property then return {} end
    local list = {}
    for _, shipEnt in pairs(player.property.properties) do
        table.insert(list, shipEnt)
    end
    table.sort(list, function(a, b)
        if a.isFlagShip ~= b.isFlagShip then return a.isFlagShip end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

-- Ficha técnica de um shipType (string)
local function getDetails(shipType)
    if not shipType then return nil end
    return config.Ships[shipType]
end

-- ─────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────

function ShipyardUI.open(playerEntity, stationEntity)
    player        = playerEntity
    station       = stationEntity
    open          = true
    selectedStation = nil
    selectedFleet   = nil
    msg           = ""
    msgTimer      = 0
    config.Input.pushContext("shipyard")

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    PX = math.floor(sw / 2 - W / 2)
    PY = math.floor(sh / 2 - H / 2)
end

function ShipyardUI.close()
    open    = false
    player  = nil
    station = nil
    config.Input.popContext("shipyard")
end

function ShipyardUI.isOpen() return open end

function ShipyardUI.toggle(playerEntity, stationEntity)
    if open then
        ShipyardUI.close()
    else
        ShipyardUI.open(playerEntity, stationEntity)
    end
end

-- ─────────────────────────────────────────
-- Update
-- ─────────────────────────────────────────

function ShipyardUI.update(dt)
    if not open then return end
    if config.Input.state.ui_cancel then
        ShipyardUI.close()
        return
    end
    if msgTimer > 0 then msgTimer = msgTimer - dt end
    config.TextInputUI.update(dt)
end

-- ─────────────────────────────────────────
-- Ações
-- ─────────────────────────────────────────

local function doBuy()
    if not selectedStation then return end
    local def = getDetails(selectedStation)
    if not def then return end

    config.TextInputUI.open({
        title       = "Nome da Nave",
        placeholder = def.name .. "...",
        maxLength   = 32,
        validate    = function(text)
            if text == "" then return false, "O nome não pode estar vazio." end
            return true
        end,
        onConfirm = function(name)
            local ok, err = config.ShipyardSystem.buyShip(player, selectedStation, name)
            if ok then
                showMsg("Nave adquirida: " .. name, C.balPos)
                selectedStation = nil
            else
                showMsg(err or "Erro ao comprar.", C.textSell)
            end
        end,
    })
end

local function doSell()
    if not selectedFleet then return end
    if selectedFleet.isFlagShip then
        showMsg("Não é possível vender a nave atual.", C.textDanger)
        return
    end
    local shipType = selectedFleet.sprite and selectedFleet.sprite.shipType
    local price    = shipType and config.ShipyardSystem.getSellPrice(shipType) or 0
    local name     = selectedFleet.name or shipType or "?"

    -- Confirmação via TextInputUI pedindo o nome da nave como senha de confirmação
    config.TextInputUI.open({
        title       = "Confirmar venda: " .. name,
        placeholder = "Digite o nome da nave para confirmar",
        maxLength   = 32,
        validate    = function(text)
            if text ~= name then
                return false, "Nome incorreto. Operação cancelada."
            end
            return true
        end,
        onConfirm = function(_)
            local ok, err = config.ShipyardSystem.sellShip(player, selectedFleet)
            if ok then
                showMsg("Nave vendida por " .. price .. " cr.", C.balPos)
                selectedFleet = nil
            else
                showMsg(err or "Erro ao vender.", C.textSell)
            end
        end,
    })
end

local function doSetFlagship()
    if not selectedFleet or selectedFleet.isFlagShip then return end
    -- Troca flagship: desmarca a atual, marca a selecionada
    for _, e in ipairs(config.Entities.with("isFlagShip")) do
        e.isFlagShip = false
    end
    selectedFleet.isFlagShip = true
    showMsg("Nave ativa alterada para: " .. (selectedFleet.name or "?"), C.textActive)
end

-- ─────────────────────────────────────────
-- Input
-- ─────────────────────────────────────────

function ShipyardUI.keypressed(key)
    if config.TextInputUI.isOpen() then
        config.TextInputUI.keypressed(key)
        return
    end
end

function ShipyardUI.mousepressed(mx, my, button)
    if not open then return end

    if config.TextInputUI.isOpen() then
        config.TextInputUI.mousepressed(mx, my, button)
        return
    end

    if button ~= 1 then return end

    -- Botão fechar
    if mx >= PX + W - 22 and mx <= PX + W - 4
    and my >= PY + 4     and my <= PY + 22 then
        ShipyardUI.close()
        return
    end

    -- Hitboxes geradas no draw
    for _, r in ipairs(btnRects) do
        if mx >= r.x and mx <= r.x + r.w
        and my >= r.y and my <= r.y + r.h then
            r.action()
            return
        end
    end
end

function ShipyardUI.wheelmoved(dx, dy)
    -- reservado para scroll futuro de listas longas
end

-- ─────────────────────────────────────────
-- Draw helpers
-- ─────────────────────────────────────────

-- Botão de ação no footer
local function drawActionBtn(x, y, w, h, label, color, borderColor, action)
    local mx, my = love.mouse.getPosition()
    local hov = mx >= x and mx <= x + w and my >= y and my <= y + h
    rect(x, y, w, h, hov and {color[1]+0.04, color[2]+0.02, color[3], 1} or color)
    rect(x, y, w, h, hov and (borderColor or C.borderAccent) or C.border, "line")
    if hov then
        sc(borderColor or C.borderAccent)
        love.graphics.rectangle("fill", x, y, 2, h)
    end
    sc(hov and C.textBright or C.textNormal)
    love.graphics.setFont(config.smallFont)
    love.graphics.printf(label, x, y + h / 2 - config.smallFont:getHeight() / 2, w, "center")
    addBtn(x, y, w, h, action)
end

-- Linha de nave no painel esquerdo (estoque)
local function drawStockRow(x, y, w, shipType, def, isSelected)
    local mx, my = love.mouse.getPosition()
    local hov = mx >= x and mx <= x + w and my >= y and my < y + ROW_H

    local bg = isSelected and C.bgRowSel or (hov and C.bgRowHover or C.bgRow)
    rect(x, y, w, ROW_H, bg)

    if isSelected then
        sc(C.borderAccent)
        love.graphics.rectangle("fill", x, y, 2, ROW_H)
    end

    sc(isSelected and C.textActive or C.textNormal)
    love.graphics.setFont(config.smallFont)
    love.graphics.print(def.name or shipType, x + 8, y + 5)

    sc(C.textBuy)
    love.graphics.printf(def.price .. " cr", x, y + 5, w - 6, "right")

    rect(x, y + ROW_H - 1, w, 1, {0.10, 0.05, 0.02, 1})

    addBtn(x, y, w, ROW_H, function()
        selectedStation = shipType
        selectedFleet   = nil
    end)
end

-- Linha de nave no painel direito (frota)
local function drawFleetRow(x, y, w, shipEnt, isSelected)
    local mx, my = love.mouse.getPosition()
    local hov = mx >= x and mx <= x + w and my >= y and my < y + ROW_H

    local bg = isSelected and C.bgRowSel or (hov and C.bgRowHover or C.bgRow)
    rect(x, y, w, ROW_H, bg)

    if isSelected then
        sc(C.borderAccent)
        love.graphics.rectangle("fill", x, y, 2, ROW_H)
    end

    local shipType = shipEnt.sprite and shipEnt.sprite.shipType or "?"
    local def      = config.Ships[shipType]
    local label    = shipEnt.name or (def and def.name) or shipType

    sc(shipEnt.isFlagShip and C.textActive or (isSelected and C.textBright or C.textNormal))
    love.graphics.setFont(config.smallFont)
    love.graphics.print(label, x + 8, y + 5)

    if shipEnt.isFlagShip then
        sc(C.textMuted)
        love.graphics.printf("ativa", x, y + 5, w - 6, "right")
    elseif def then
        sc(C.textSell)
        love.graphics.printf(config.ShipyardSystem.getSellPrice(shipType) .. " cr", x, y + 5, w - 6, "right")
    end

    rect(x, y + ROW_H - 1, w, 1, {0.10, 0.05, 0.02, 1})

    addBtn(x, y, w, ROW_H, function()
        selectedFleet   = shipEnt
        selectedStation = nil
    end)
end

-- Painel central: ficha técnica
local function drawDetails(x, y, w, h)
    rect(x, y, w, h, C.bgDark)
    rect(x, y, w, h, C.border, "line")

    local shipType = selectedStation
                  or (selectedFleet and selectedFleet.sprite and selectedFleet.sprite.shipType)
    local def      = shipType and config.Ships[shipType]

    love.graphics.setFont(config.smallFont)

    if not def then
        sc(C.textMuted)
        love.graphics.printf("Selecione uma nave", x, y + h / 2 - 7, w, "center")
        return
    end

    local curY = y + PAD

    -- Nome em destaque
    sc(C.textActive)
    love.graphics.setFont(config.normalFont)
    local title = def.name or shipType
    love.graphics.printf(title, x + PAD, curY, w - PAD * 2, "left")
    curY = curY + config.normalFont:getHeight() + 6

    -- Linha separadora
    rect(x + PAD, curY, w - PAD * 2, 1, C.border)
    curY = curY + 8

    love.graphics.setFont(config.smallFont)

    local function stat(label, value, valColor)
        sc(C.textMuted)
        love.graphics.print(label, x + PAD, curY)
        sc(valColor or C.textNormal)
        love.graphics.printf(tostring(value), x + PAD, curY, w - PAD * 2, "right")
        curY = curY + 18
    end

    local mov = def.movement or {}
    stat("Preço",              (def.price or "?") .. " cr",  C.textBuy)
    stat("Revenda",            config.ShipyardSystem.getSellPrice(shipType) .. " cr", C.textSell)
    stat("Carga (t)",          def.cargo          or "?")
    stat("Aceleração",         mov.linearAcceleration or "?")
    stat("Strafe",             mov.strafeAcceleration or "?")
    stat("Vel. angular",       mov.angularAcceleration or "?")
    stat("Amort. linear",      mov.linearDamping  or "?")
    stat("Armamentos",         def.hardpoints     or "—")

    -- Descrição (se existir)
    if def.description then
        curY = curY + 4
        rect(x + PAD, curY, w - PAD * 2, 1, C.border)
        curY = curY + 8
        sc(C.textMuted)
        love.graphics.printf(def.description, x + PAD, curY, w - PAD * 2, "left")
    end
end

-- ─────────────────────────────────────────
-- Draw principal
-- ─────────────────────────────────────────

function ShipyardUI.draw(playerEntity, stationEntity)
    if not open then return end

    -- Aceita override de entidades (compatível com chamada from landed)
    if playerEntity  then player  = playerEntity  end
    if stationEntity then station = stationEntity end

    btnRects = {}

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Painel principal
    rect(PX, PY, W, H, C.bg)
    rect(PX, PY, W, H, C.border, "line")

    -- Acento superior
    sc(C.borderAccent)
    love.graphics.rectangle("fill", PX + 1, PY + 1, W - 2, 2, 2)

    -- ── Titlebar ──
    rect(PX, PY, W, HEADER_H, C.bgDark)
    sc(C.textActive)
    love.graphics.setFont(config.normalFont)
    love.graphics.print("Shipyard · " .. (station and station.name or "?"), PX + PAD, PY + 4)

    -- Botão fechar
    rect(PX + W - 22, PY + 4, 18, 16, C.bgRow)
    rect(PX + W - 22, PY + 4, 18, 16, C.border, "line")
    sc(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("x", PX + W - 16, PY + 6)

    local bodyY = PY + HEADER_H + 4
    local bodyH = H - HEADER_H - FOOTER_H - 4
    local mx, my = love.mouse.getPosition()

    -- ─────────────────────────────────────────
    -- COLUNA ESQUERDA — Estoque da estação
    -- ─────────────────────────────────────────
    local lx = PX + PAD
    local lw = COL_L

    rect(lx, bodyY, lw, SECTION_H, C.bgDark)
    sc(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("DISPONÍVEL", lx + 4, bodyY + 3)
    sc(C.textBuy)
    love.graphics.printf("PREÇO", lx, bodyY + 3, lw - 6, "right")

    local stockY = bodyY + SECTION_H
    local stock  = getStationStock()

    if #stock == 0 then
        sc(C.textMuted)
        love.graphics.print("(sem estoque)", lx + 6, stockY + 6)
    else
        for i, entry in ipairs(stock) do
            drawStockRow(lx, stockY + (i - 1) * ROW_H, lw, entry.shipType, entry.def,
                         selectedStation == entry.shipType)
        end
    end

    -- ─────────────────────────────────────────
    -- COLUNA CENTRAL — Ficha técnica
    -- ─────────────────────────────────────────
    local cx = lx + lw + PAD
    local cw = W - COL_L - COL_R - PAD * 4
    drawDetails(cx, bodyY, cw, bodyH)

    -- ─────────────────────────────────────────
    -- COLUNA DIREITA — Frota do jogador
    -- ─────────────────────────────────────────
    local rx = cx + cw + PAD
    local rw = COL_R

    rect(rx, bodyY, rw, SECTION_H, C.bgDark)
    sc(C.textMuted)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("SUA FROTA", rx + 4, bodyY + 3)

    local fleetY = bodyY + SECTION_H
    local fleet  = getFleet()

    if #fleet == 0 then
        sc(C.textMuted)
        love.graphics.print("(vazia)", rx + 6, fleetY + 6)
    else
        for i, shipEnt in ipairs(fleet) do
            drawFleetRow(rx, fleetY + (i - 1) * ROW_H, rw, shipEnt,
                         selectedFleet == shipEnt)
        end
    end

    -- ─────────────────────────────────────────
    -- FOOTER
    -- ─────────────────────────────────────────
    local footerY = PY + H - FOOTER_H
    rect(PX, footerY, W, 1, C.border)
    rect(PX, footerY, W, FOOTER_H, C.bgDark)

    -- Créditos do jogador
    if player and player.credits then
        sc(C.textMuted)
        love.graphics.setFont(config.smallFont)
        love.graphics.print("Créditos:", PX + PAD, footerY + 14)
        sc(C.textBright)
        love.graphics.setFont(config.normalFont)
        love.graphics.print(player.credits.amount .. " cr", PX + PAD + 62, footerY + 11)
    end

    -- Botões de ação (direita do footer)
    local btnH   = 28
    local btnY   = footerY + (FOOTER_H - btnH) / 2
    local btnX   = PX + W - PAD

    -- Botão Vender (só ativo se tiver frota selecionada não-flagship)
    if selectedFleet and not selectedFleet.isFlagShip then
        btnX = btnX - 90
        drawActionBtn(btnX, btnY, 86, btnH, "Vender", {0.12,0.04,0.02,1}, C.textSell, doSell)
    end

    -- Botão Definir como Ativa (só se frota selecionada não for flagship)
    if selectedFleet and not selectedFleet.isFlagShip then
        btnX = btnX - 110
        drawActionBtn(btnX, btnY, 106, btnH, "Definir Ativa", C.bgRow, C.borderAccent, doSetFlagship)
    end

    -- Botão Comprar (só ativo se estiver no estoque)
    if selectedStation then
        local buyX = PX + W - PAD - 90
        -- reposiciona se os outros botões não apareceram
        if not (selectedFleet and not selectedFleet.isFlagShip) then
            drawActionBtn(buyX, btnY, 86, btnH, "Comprar", {0.08,0.04,0.01,1}, C.borderAccent, doBuy)
        else
            -- não exibe comprar e vender ao mesmo tempo (seleções são mutuamente exclusivas)
        end
    end

    -- Mensagem de feedback
    if msgTimer > 0 then
        sc(msgColor or C.textBright)
        love.graphics.setFont(config.smallFont)
        local tw = config.smallFont:getWidth(msg)
        love.graphics.print(msg, PX + W / 2 - tw / 2, footerY - 20)
    end

    -- TextInputUI por cima de tudo
    config.TextInputUI.draw()

    love.graphics.setColor(1, 1, 1, 1)
end

return ShipyardUI
