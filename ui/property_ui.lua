-- ui/property_ui.lua
-- Lê as propriedades do jogador via player.property.properties
-- Uso:
--   PropertyUI.toggle()
--   PropertyUI.update(dt)
--   PropertyUI.draw()
--   PropertyUI.mousepressed(mx, my, button)
--   PropertyUI.wheelmoved(dx, dy)

local PropertyUI = {}

local open        = false
local activeTab   = "all"
local selectedKey = nil
local scroll      = 0
local dragging    = false
local dragOffX    = 0
local dragOffY    = 0
local detailPane  = nil

local W          = 640
local H          = 440
local TITLEBAR_H = 28
local TABS_H     = 24
local COL_HDR_H  = 18
local ROW_H      = 22
local GROUP_H    = 20
local STATUS_H   = 20
local DETAIL_W   = 200
local MAX_ROWS   = 14
local PX, PY     = 0, 0

local C = {
    bg          = {0.06, 0.05, 0.03, 1},
    bgDark      = {0.04, 0.03, 0.02, 1},
    bgRow       = {0.06, 0.05, 0.03, 1},
    bgRowHover  = {0.10, 0.08, 0.03, 1},
    bgRowSel    = {0.13, 0.10, 0.03, 1},
    bgGroup     = {0.08, 0.06, 0.02, 1},
    bgDetail    = {0.05, 0.04, 0.02, 1},
    border      = {0.23, 0.18, 0.06, 1},
    borderAccent= {1.00, 0.78, 0.19, 1},
    textBright  = {1.00, 0.78, 0.19, 1},
    textNormal  = {0.78, 0.66, 0.29, 1},
    textMuted   = {0.35, 0.28, 0.10, 1},
    textActive  = {0.67, 0.47, 0.16, 1},
    dotGreen    = {0.23, 0.55, 0.23, 1},
    dotYellow   = {1.00, 0.78, 0.19, 1},
    dotRed      = {0.55, 0.18, 0.11, 1},
    statusBar   = {0.04, 0.03, 0.01, 1},
}

local TABS = {
    { key = "all",  label = "All"   },
    { key = "ship", label = "Ships" },
}

local DOT_COLOR = {
    active  = "dotGreen",
    docked  = "dotYellow",
    idle    = "dotYellow",
    damaged = "dotRed",
}

local function sc(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function rect(x, y, w, h, col, mode)
    sc(col)
    love.graphics.rectangle(mode or "fill", x, y, w, h, 2)
end

local function txt(text, x, y, col, font)
    sc(col)
    love.graphics.setFont(font or config.smallFont)
    love.graphics.print(text, x, y)
end

local function pointIn(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function clampStr(s, maxLen)
    s = tostring(s)
    if #s <= maxLen then return s end
    return s:sub(1, maxLen - 2) .. ".."
end

local function getPlayer()
    return config.Entities.getByTag("player")[1]
end

local function buildRows()
    local player = getPlayer()
    if not player or not player.property then return {} end

    local ships = {}
    for _, entity in pairs(player.property.properties) do
        if activeTab == "all" or activeTab == "ship" then
            table.insert(ships, entity)
        end
    end

    table.sort(ships, function(a, b)
        if a.isFlagShip ~= b.isFlagShip then return a.isFlagShip end
        return (a.name or "") < (b.name or "")
    end)

    local rows = {}
    if #ships > 0 then
        table.insert(rows, { kind = "group", label = "Ships", count = #ships })
        table.insert(rows, { kind = "colhdr" })
        for i, e in ipairs(ships) do
            local status = "idle"
            if e.isFlagShip then status = "active"
            elseif e.landedAt then status = "docked" end

            local loc = "In space"
            if e.landedAt then
                loc = e.landedAt.name or "Docked"
            elseif e.rigidbody and e.rigidbody.body then
                local bx, by = e.rigidbody.body:getPosition()
                loc = string.format("%.0f, %.0f", bx, by)
            end
            if config.WorldManager and config.WorldManager.currentSystemId then
                local sys = config.WorldManager.systems[config.WorldManager.currentSystemId]
                if sys then loc = sys.name .. " · " .. loc end
            end

            local order = "Idle"
            if e.isFlagShip then order = "Player controlled" end
            if e.landedAt   then order = "Docked at " .. (e.landedAt.name or "?") end

            table.insert(rows, {
                kind     = "item",
                key      = "ship_" .. i,
                entity   = e,
                name     = e.name or "Unknown Ship",
                loc      = loc,
                order    = order,
                status   = status,
                flagship = e.isFlagShip or false,
            })
        end
    end
    return rows
end

function PropertyUI.open()
    config.Input.pushContext("property")
    open        = true
    scroll      = 0
    selectedKey = nil
    detailPane  = nil
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    PX = math.floor(sw / 2 - W / 2)
    PY = math.floor(sh / 2 - H / 2)
end

function PropertyUI.close()
    config.Input.popContext("property")
    open       = false
    detailPane = nil
end

function PropertyUI.toggle()
    if PropertyUI.isOpen() then
      love.mouse.setVisible(false)
      love.mouse.setRelativeMode(true)
      PropertyUI.close()
    else
      love.mouse.setVisible(true)
      love.mouse.setRelativeMode(false)
      PropertyUI.open()
    end
end

function PropertyUI.isOpen() return open end

function PropertyUI.update(dt)
    if not open then return end
    if love.mouse.isDown(1) and dragging then
        local mx, my = love.mouse.getPosition()
        PX = mx - dragOffX
        PY = my - dragOffY
    elseif not love.mouse.isDown(1) then
        dragging = false
    end
end

function PropertyUI.mousepressed(mx, my, button)
    if not open then return end
    if button ~= 1 then return end
    if not pointIn(mx, my, PX, PY, W, H) then return end

    if pointIn(mx, my, PX, PY, W, TITLEBAR_H) then
        if pointIn(mx, my, PX + W - 22, PY + 5, 16, 18) then
            PropertyUI.close(); return
        end
        dragging = true
        dragOffX = mx - PX
        dragOffY = my - PY
        return
    end

    local tabX = PX
    for _, tab in ipairs(TABS) do
        local tw = config.smallFont:getWidth(tab.label) + 24
        if pointIn(mx, my, tabX, PY + TITLEBAR_H, tw, TABS_H) then
            activeTab = tab.key; scroll = 0; selectedKey = nil; detailPane = nil; return
        end
        tabX = tabX + tw
    end

    local listW   = W - DETAIL_W - 1
    local listY   = PY + TITLEBAR_H + TABS_H
    local listH   = H - TITLEBAR_H - TABS_H - STATUS_H
    local rows    = buildRows()
    local curY    = listY
    local skipped = 0
    for _, row in ipairs(rows) do
        local rh = row.kind == "group" and GROUP_H or row.kind == "colhdr" and COL_HDR_H or ROW_H
        if skipped < math.floor(scroll) then
            skipped = skipped + 1
        else
            if curY + rh > listY + listH then break end
            if row.kind == "item" and pointIn(mx, my, PX, curY, listW, rh) then
                selectedKey = row.key; detailPane = row.entity; return
            end
            curY = curY + rh
        end
    end
end

function PropertyUI.wheelmoved(dx, dy)
    if not open then return end
    local mx, my = love.mouse.getPosition()
    if pointIn(mx, my, PX, PY, W, H) then
        scroll = math.max(0, scroll - dy)
    end
end

local function drawDetail(e, x, y, w, h)
    rect(x, y, w, h, C.bgDetail)
    rect(x, y, 1, h, C.border)
    if not e then
        sc(C.textMuted); love.graphics.setFont(config.smallFont)
        local lbl = "Select a ship"
        love.graphics.print(lbl, x + w/2 - config.smallFont:getWidth(lbl)/2, y + h/2 - 6)
        return
    end

    local curY = y + 10
    local PAD  = 10

    sc(C.textBright); love.graphics.setFont(config.normalFont)
    love.graphics.printf(e.name or "Unknown", x + PAD, curY, w - PAD*2, "left")
    curY = curY + 22

    if e.isFlagShip then
        rect(x + PAD, curY, w - PAD*2, 15, {0.12, 0.10, 0.02, 1})
        rect(x + PAD, curY, w - PAD*2, 15, C.border, "line")
        sc(C.textBright); love.graphics.setFont(config.smallFont)
        love.graphics.printf("FLAGSHIP", x + PAD, curY + 3, w - PAD*2, "center")
        curY = curY + 22
    end

    rect(x + PAD, curY, w - PAD*2, 1, C.border); curY = curY + 8

    local function row(label, value, valCol)
        sc(C.textMuted); love.graphics.setFont(config.smallFont)
        love.graphics.print(label, x + PAD, curY)
        sc(valCol or C.textNormal)
        love.graphics.printf(tostring(value), x + PAD, curY, w - PAD*2, "right")
        curY = curY + 16
    end

    local statusStr = e.isFlagShip and "Active" or (e.landedAt and "Docked" or "Idle")
    row("Status", statusStr, e.isFlagShip and C.dotGreen or C.textMuted)
    if e.inventory then row("Cargo", e.inventory.capacityUsed .. "/" .. e.inventory.capacity .. " u") end
    if e.weapon and e.weapon.def then row("Weapon", e.weapon.def.type or "?") end
    if e.landedAt then
        row("Docked at", clampStr(e.landedAt.name or "?", 16))
    elseif e.rigidbody and e.rigidbody.body then
        local bx, by = e.rigidbody.body:getPosition()
        row("Position", string.format("%.0f, %.0f", bx, by))
        local vx, vy = e.rigidbody.body:getLinearVelocity()
        row("Speed", string.format("%.0f u/s", math.sqrt(vx*vx + vy*vy)))
    end

    if e.inventory and next(e.inventory.items) then
        curY = curY + 4
        rect(x + PAD, curY, w - PAD*2, 1, C.border); curY = curY + 8
        sc(C.textMuted); love.graphics.setFont(config.smallFont)
        love.graphics.print("Cargo manifest:", x + PAD, curY); curY = curY + 14
        for item, qty in pairs(e.inventory.items) do
            if curY > y + h - 20 then sc(C.textMuted); love.graphics.print("...", x + PAD, curY); break end
            sc(C.textNormal); love.graphics.print(clampStr(item, 16), x + PAD, curY)
            sc(C.textMuted); love.graphics.printf(tostring(qty), x + PAD, curY, w - PAD*2, "right")
            curY = curY + 14
        end
    end
end

function PropertyUI.draw()
    if not open then return end
    local mx, my = love.mouse.getPosition()
    local listW  = W - DETAIL_W - 1
    local listY  = PY + TITLEBAR_H + TABS_H
    local listH  = H - TITLEBAR_H - TABS_H - STATUS_H

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    rect(PX, PY, W, H, C.bg)
    rect(PX, PY, W, H, C.border, "line")

    -- Titlebar
    rect(PX, PY, W, TITLEBAR_H, C.bgDark)
    rect(PX, PY + TITLEBAR_H - 1, W, 1, C.border)
    sc(C.textBright); love.graphics.setFont(config.normalFont)
    love.graphics.print("Property Owned", PX + 10, PY + 6)
    rect(PX + W - 22, PY + 5, 16, 18, C.bgDark)
    rect(PX + W - 22, PY + 5, 16, 18, C.border, "line")
    txt("x", PX + W - 17, PY + 7, C.textMuted)

    -- Tabs
    rect(PX, PY + TITLEBAR_H, W, TABS_H, C.bgDark)
    rect(PX, PY + TITLEBAR_H + TABS_H - 1, W, 1, C.border)
    local tabX = PX
    for _, tab in ipairs(TABS) do
        local tw   = config.smallFont:getWidth(tab.label) + 24
        local isAct= activeTab == tab.key
        local isHov= pointIn(mx, my, tabX, PY + TITLEBAR_H, tw, TABS_H)
        if isAct then
            rect(tabX, PY + TITLEBAR_H, tw, TABS_H, C.bgGroup)
            rect(tabX, PY + TITLEBAR_H + TABS_H - 2, tw, 2, C.borderAccent)
        elseif isHov then
            rect(tabX, PY + TITLEBAR_H, tw, TABS_H, C.bgRowHover)
        end
        local tcol = isAct and C.textBright or (isHov and C.textNormal or C.textMuted)
        txt(tab.label, tabX + 12, PY + TITLEBAR_H + 5, tcol)
        rect(tabX + tw - 1, PY + TITLEBAR_H + 4, 1, TABS_H - 8, C.border)
        tabX = tabX + tw
    end

    -- Lista com stencil
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", PX, listY, listW, listH)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    local rows    = buildRows()
    local curY    = listY
    local skipped = 0
    local COL1    = 180
    local COL2    = 150

    for _, row in ipairs(rows) do
        local rh = row.kind == "group" and GROUP_H or row.kind == "colhdr" and COL_HDR_H or ROW_H
        if skipped < math.floor(scroll) then
            skipped = skipped + 1
            goto continue
        end
        if curY >= listY + listH then break end

        if row.kind == "group" then
            rect(PX, curY, listW, GROUP_H, C.bgGroup)
            rect(PX, curY, listW, 1, C.border)
            rect(PX, curY + GROUP_H - 1, listW, 1, C.border)
            sc(C.textBright); love.graphics.setFont(config.smallFont)
            love.graphics.print(row.label, PX + 8, curY + 4)
            sc(C.textMuted)
            love.graphics.print(row.count .. " units", PX + 8 + config.smallFont:getWidth(row.label) + 8, curY + 4)

        elseif row.kind == "colhdr" then
            rect(PX, curY, listW, COL_HDR_H, C.bgDark)
            rect(PX, curY + COL_HDR_H - 1, listW, 1, C.border)
            txt("Name",          PX + 26,               curY + 3, C.textMuted)
            txt("Location",      PX + 26 + COL1,        curY + 3, C.textMuted)
            txt("Current Order", PX + 26 + COL1 + COL2, curY + 3, C.textMuted)

        elseif row.kind == "item" then
            local isSel = selectedKey == row.key
            local isHov = pointIn(mx, my, PX, curY, listW, ROW_H)
            local bg = isSel and C.bgRowSel or isHov and C.bgRowHover or C.bgRow
            rect(PX, curY, listW, ROW_H, bg)
            if isSel then rect(PX, curY, 2, ROW_H, C.borderAccent) end

            local dotCol = C[DOT_COLOR[row.status] or "dotYellow"]
            sc(dotCol); love.graphics.circle("fill", PX + 14, curY + ROW_H / 2, 3)

            txt(clampStr(row.name, 22), PX + 26, curY + 4, row.flagship and C.textBright or C.textNormal)
            txt(clampStr(row.loc or "—", 20), PX + 26 + COL1, curY + 4, C.textMuted)
            txt(clampStr(row.order or "—", 24), PX + 26 + COL1 + COL2, curY + 4,
                row.flagship and C.textActive or C.textMuted)
            rect(PX, curY + ROW_H - 1, listW, 1, C.bgGroup)
        end

        curY = curY + rh
        ::continue::
    end

    love.graphics.setStencilTest()

    -- Scrollbar
    local totalRows = #rows
    if totalRows > MAX_ROWS then
        local trackH    = listH
        local thumbH    = math.max(24, trackH * (MAX_ROWS / totalRows))
        local maxScroll = math.max(1, totalRows - MAX_ROWS)
        local thumbY    = listY + (scroll / maxScroll) * (trackH - thumbH)
        rect(PX + listW - 4, listY, 3, trackH, C.bgDark)
        rect(PX + listW - 4, thumbY, 3, thumbH, C.border)
    end

    -- Painel de detalhes
    drawDetail(detailPane, PX + listW + 1, listY, DETAIL_W, listH)

    -- Status bar
    local statY = PY + H - STATUS_H
    rect(PX, statY, W, 1, C.border)
    rect(PX, statY, W, STATUS_H, C.statusBar)
    local player = getPlayer()
    local total  = 0
    if player and player.property then
        for _ in pairs(player.property.properties) do total = total + 1 end
    end
    txt(total .. " PROPERTIES TOTAL", PX + 10, statY + 4, C.textMuted)
    if player and player.credits then
        local cr = "CREDITS: " .. player.credits.amount .. " CR"
        txt(cr, PX + W - config.smallFont:getWidth(cr) - 10, statY + 4, C.textMuted)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return PropertyUI
