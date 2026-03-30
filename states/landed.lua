local WorldManager = require("managers.world_manager")
local InventoryUI = require("ui.inventory_ui")

local Landed = {}

-- ─────────────────────────────────────────
-- Estado local
-- ─────────────────────────────────────────

local ship         = nil
local activePanel  = "trade"
local hoveredBtn   = nil

-- ─────────────────────────────────────────
-- Dados dos painéis
-- ─────────────────────────────────────────

local panels = {
    trade = {
        title = "Trading",
        scene = "station",
        text  = {
            "Esta estação orbital é um dos maiores entrepostos",
            "comerciais do sistema. Mercadores de dezenas de",
            "mundos trazem seus carregamentos aqui.",
            "",
            "Os preços flutuam conforme as frotas de mineração",
            "chegam dos cinturões de asteroides.",
        },
    },
    contracts = {
        title = "Contracts",
        scene = "contracts",
        text  = {
            "Contratos disponíveis no momento:",
            "",
            "[ URGENTE ] Entrega médica para Colônia Vega",
            "  Prazo: 5 dias · Pagamento: 8.400 cr",
            "",
            "[ PATRULHA ] Escolta de comboio pela Rota 7",
            "  Risco moderado · Pagamento: 12.000 cr",
            "",
            "[ EXPLORAÇÃO ] Mapeamento do setor Delta-9",
            "  Sem prazo · Pagamento: 5.200 cr",
        },
        textColors = {
            [3] = {0.48, 0.67, 0.87},
            [6] = {0.91, 0.75, 0.37},
            [9] = {0.54, 0.79, 0.48},
        },
    },
    bank = {
        title = "Bank",
        scene = "bank",
        text  = {
            "Banco Interestelar da Coalização · Kepler-7",
            "",
            "Saldo atual: 14.320 créditos",
            "Empréstimo ativo: 32.000 cr · 2,1% a.m.",
            "Próximo vencimento: 12 dias",
            "",
            "Serviços: transferências, empréstimos de capital,",
            "seguros de carga e seguro de casco (até classe M).",
        },
        textColors = {
            [3] = {0.48, 0.67, 0.87},
            [4] = {0.87, 0.43, 0.37},
        },
    },
    spaceport = {
        title = "Spaceport",
        scene = "station",
        text  = {
            "Baia 14-C · Acesso completo a combustível",
            "e manutenção básica disponível.",
            "",
            "Combustível:        87%",
            "Integridade do casco: 100%",
            "Status dos motores: Nominal",
            "",
            "Próxima janela de decolagem: aberta.",
        },
        textColors = {
            [4] = {0.54, 0.79, 0.48},
            [5] = {0.54, 0.79, 0.48},
            [6] = {0.54, 0.79, 0.48},
        },
    },
    shipyard = {
        title = "Shipyard",
        scene = "shipyard",
        text  = {
            "O estaleiro Kepler oferece naves usadas e um",
            "modelo novo em estoque.",
            "",
            "Naves disponíveis para compra ou troca.",
            "Avaliação da sua nave pode ser solicitada",
            "ao balcão principal.",
            "",
            "Em estoque: Hauler MK2, Scout Viper,",
            "Patrol Corvette (usado).",
        },
    },
    outfitter = {
        title = "Outfitter",
        scene = "station",
        text  = {
            "Equipamentos e extensões para sua nave.",
            "",
            "Estoque atual: sistemas de armas leves,",
            "scanners de mineração, drives de salto de",
            "curto alcance, blindagem reforçada classe 2.",
            "",
            "Descontos para membros da Guilda.",
            "Instalação inclusa no preço de todos os itens.",
        },
    },
    bar = {
        title = "Bar",
        scene = "bar",
        text  = {
            "Candidatos disponíveis:",
            "",
            "Mira Solano  · Engenheira de Propulsão",
            "  800 cr/semana",
            "Taro Vex     · Artilheiro experiente",
            "  650 cr/semana",
            "Dr. Halene   · Médica de bordo",
            "  700 cr/semana",
            "",
            "Tripulação atual: 1/6 slots ocupados.",
        },
        textColors = {
            [3] = {0.78, 0.81, 0.88},
            [5] = {0.78, 0.81, 0.88},
            [7] = {0.78, 0.81, 0.88},
        },
    },
    depart = {
        title = "Pronto para partir?",
        scene = "space",
        text  = {
            "Todos os sistemas verificados.",
            "Janela de decolagem aberta.",
            "",
            "Ao partir você deixará a zona de atracamento",
            "protegida. Conflitos foram relatados no setor.",
            "",
            "ATENÇÃO: empréstimo com vencimento em 12 dias.",
        },
        textColors = {
            [7] = {0.87, 0.43, 0.37},
        },
    },
}

-- ─────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────

local L = {
    -- margem da tela inteira
    marginX = 60,
    marginY = 40,

    -- largura das colunas de botões
    btnW    = 110,
    btnH    = 32,
    btnGap  = 4,

    -- altura da cena (arte)
    sceneH  = 200,

    -- padding interno do painel central
    padX    = 14,
    padY    = 10,

    -- fonte
    lineH   = 16,
}

-- Botões da esquerda e da direita
local leftButtons = {
    { key = "trade",     label = "Trading"   },
    { key = "contracts",      label = "Contracts" },
    { key = "bank",      label = "Bank"      },
    { key = "spaceport", label = "Spaceport" },
}

local rightButtons = {
    { key = "shipyard",  label = "Shipyard"  },
    { key = "outfitter", label = "Outfitter" },
    { key = "bar",      label = "Bar" },
    { key = "depart",    label = "Depart",  danger = true },
}

-- ─────────────────────────────────────────
-- Cores
-- ─────────────────────────────────────────

local C = {
    bg          = {0.04, 0.05, 0.08, 1},
    bgPanel     = {0.06, 0.08, 0.13, 1},
    bgBtn       = {0.05, 0.07, 0.13, 1},
    bgBtnHover  = {0.10, 0.16, 0.25, 1},
    bgBtnActive = {0.06, 0.13, 0.25, 1},
    border      = {0.17, 0.21, 0.32, 1},
    borderAccent= {0.29, 0.54, 0.83, 1},
    borderDanger= {0.35, 0.17, 0.17, 1},
    textNormal  = {0.63, 0.69, 0.80, 1},
    textBright  = {0.78, 0.81, 0.88, 1},
    textMuted   = {0.29, 0.39, 0.55, 1},
    textActive  = {0.48, 0.69, 0.87, 1},
    textDanger  = {0.87, 0.43, 0.37, 1},
    sceneOverlay= {0.04, 0.05, 0.08, 0.45},
}

-- ─────────────────────────────────────────
-- Geometria calculada (preenchida no onEnter)
-- ─────────────────────────────────────────

local G = {}

local function recalcGeometry()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    G.x      = L.marginX
    G.y      = L.marginY
    G.w      = sw - L.marginX * 2
    G.h      = sh - L.marginY * 2

    -- Coluna de botões esquerda
    G.leftX  = G.x
    G.leftW  = L.btnW

    -- Coluna de botões direita
    G.rightX = G.x + G.w - L.btnW
    G.rightW = L.btnW

    -- Painel central
    G.centerX = G.leftX + G.leftW + 2
    G.centerW = G.rightX - G.centerX - 2

    -- Cena (arte)
    G.sceneX = G.x
    G.sceneY = G.y
    G.sceneW = G.w
    G.sceneH = L.sceneH

    -- Área de conteúdo (abaixo da cena)
    G.contentY = G.sceneY + G.sceneH + 2
    G.contentH = G.h - G.sceneH - 2

    -- Botões: posições Y
    G.leftBtnY  = {}
    G.rightBtnY = {}
    for i = 1, #leftButtons do
        G.leftBtnY[i]  = G.contentY + (i - 1) * (L.btnH + L.btnGap)
    end
    for i = 1, #rightButtons do
        G.rightBtnY[i] = G.contentY + (i - 1) * (L.btnH + L.btnGap)
    end

    -- Texto central começa aqui
    G.textX = G.centerX + L.padX
    G.textY = G.contentY + L.padY + 18  -- 18 = espaço para o título
end

-- ─────────────────────────────────────────
-- Desenho de cenas (arte procedural)
-- ─────────────────────────────────────────

local function drawSceneStation()
    local cx = G.sceneX + G.sceneW / 2
    local cy = G.sceneY + G.sceneH / 2

    -- Fundo estrelado
    love.graphics.setColor(0.04, 0.05, 0.10)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)

    -- Estrelas
    love.graphics.setColor(0.55, 0.65, 0.80, 0.5)
    local stars = {{40,30},{200,20},{310,55},{80,150},{260,160},{500,40},{420,130},{150,170}}
    for _, s in ipairs(stars) do
        love.graphics.circle("fill", G.sceneX + s[1], G.sceneY + s[2], 1.5)
    end

    -- Planeta ao fundo (distante)
    love.graphics.setColor(0.10, 0.08, 0.18)
    love.graphics.circle("fill", G.sceneX + 80, G.sceneY + 60, 38)
    love.graphics.setColor(0.18, 0.13, 0.30, 0.6)
    love.graphics.circle("fill", G.sceneX + 80, G.sceneY + 60, 34)

    -- Anel da estação (horizontal)
    love.graphics.setColor(0.16, 0.24, 0.40)
    love.graphics.rectangle("fill", cx - 70, cy - 5, 140, 10, 2)

    -- Corpo central
    love.graphics.setColor(0.10, 0.16, 0.28)
    love.graphics.rectangle("fill", cx - 16, cy - 40, 32, 80, 3)

    -- Núcleo
    love.graphics.setColor(0.07, 0.11, 0.20)
    love.graphics.circle("fill", cx, cy, 22)
    love.graphics.setColor(0.29, 0.54, 0.83, 0.4)
    love.graphics.circle("line", cx, cy, 22)

    -- Braços laterais
    love.graphics.setColor(0.10, 0.17, 0.28)
    love.graphics.rectangle("fill", cx - 110, cy - 4, 50, 8, 1)
    love.graphics.rectangle("fill", cx + 60,  cy - 4, 50, 8, 1)

    -- Luzes da estação
    love.graphics.setColor(0.48, 0.67, 0.87, 0.8)
    love.graphics.circle("fill", cx - 105, cy, 2)
    love.graphics.circle("fill", cx + 105, cy, 2)
    love.graphics.circle("fill", cx, cy - 38, 2)
end

local function drawScenecontracts()
    love.graphics.setColor(0.04, 0.05, 0.10)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)

    local bx = G.sceneX + G.sceneW / 2 - 100
    local by = G.sceneY + 35

    -- Quadro de missões
    love.graphics.setColor(0.06, 0.09, 0.16)
    love.graphics.rectangle("fill", bx, by, 200, 130, 2)
    love.graphics.setColor(0.17, 0.21, 0.32)
    love.graphics.rectangle("line", bx, by, 200, 130, 2)

    -- Header
    love.graphics.setColor(0.07, 0.11, 0.18)
    love.graphics.rectangle("fill", bx, by, 200, 18, 2)
    love.graphics.setColor(0.29, 0.41, 0.60)
    love.graphics.print("QUADRO DE MISSÕES", bx + 8, by + 4, 0, 0.85, 0.85)

    -- Linhas de missão
    local missionColors = {
        {0.29, 0.54, 0.83},
        {0.91, 0.75, 0.37},
        {0.33, 0.67, 0.33},
    }
    local labels = {"URGENTE · Entrega médica Vega", "PATRULHA · Escolta Rota 7", "EXPLORAÇÃO · Delta-9"}
    for i, mc in ipairs(missionColors) do
        local ry = by + 24 + (i - 1) * 28
        love.graphics.setColor(mc[1], mc[2], mc[3], 0.15)
        love.graphics.rectangle("fill", bx + 6, ry, 188, 20, 1)
        love.graphics.setColor(mc[1], mc[2], mc[3])
        love.graphics.rectangle("fill", bx + 6, ry, 3, 20)
        love.graphics.setColor(mc[1], mc[2], mc[3], 0.85)
        love.graphics.print(labels[i], bx + 14, ry + 5, 0, 0.85, 0.85)
    end
end

local function drawSceneBank()
    love.graphics.setColor(0.04, 0.05, 0.10)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)

    local bx = G.sceneX + G.sceneW / 2 - 90
    local by = G.sceneY + 50

    -- Card do banco
    love.graphics.setColor(0.06, 0.09, 0.16)
    love.graphics.rectangle("fill", bx, by, 180, 100, 3)
    love.graphics.setColor(0.17, 0.21, 0.32)
    love.graphics.rectangle("line", bx, by, 180, 100, 3)

    love.graphics.setColor(0.07, 0.11, 0.18)
    love.graphics.rectangle("fill", bx, by, 180, 18, 3)
    love.graphics.setColor(0.29, 0.41, 0.60)
    love.graphics.print("BANCO INTERESTELAR", bx + 8, by + 4, 0, 0.85, 0.85)

    love.graphics.setColor(0.29, 0.54, 0.83)
    love.graphics.print("14.320 cr", bx + 10, by + 30)
    love.graphics.setColor(0.45, 0.55, 0.70)
    love.graphics.print("saldo disponível", bx + 10, by + 48, 0, 0.85, 0.85)

    -- Barra de dívida
    love.graphics.setColor(0.12, 0.15, 0.22)
    love.graphics.rectangle("fill", bx + 10, by + 68, 160, 8, 2)
    love.graphics.setColor(0.87, 0.43, 0.37, 0.7)
    love.graphics.rectangle("fill", bx + 10, by + 68, 55, 8, 2)
    love.graphics.setColor(0.55, 0.35, 0.32)
    love.graphics.print("débito: 32.000 cr", bx + 10, by + 80, 0, 0.80, 0.80)
end

local function drawSceneShipyard()
    love.graphics.setColor(0.04, 0.05, 0.10)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)

    -- Chão da doca
    love.graphics.setColor(0.04, 0.06, 0.10)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY + G.sceneH - 50, G.sceneW, 50)
    love.graphics.setColor(0.10, 0.14, 0.22)
    love.graphics.rectangle("line", G.sceneX, G.sceneY + G.sceneH - 50, G.sceneW, 1)

    -- Naves em exposição
    local ships = {
        { x = G.sceneX + 100, label = "Hauler MK2",    color = {0.17, 0.21, 0.32} },
        { x = G.sceneX + G.sceneW/2 - 30, label = "Scout Viper", color = {0.10, 0.19, 0.33} },
        { x = G.sceneX + G.sceneW - 130, label = "Corvette",     color = {0.15, 0.18, 0.28} },
    }
    for _, s in ipairs(ships) do
        -- Corpo da nave
        love.graphics.setColor(s.color)
        love.graphics.polygon("fill",
            s.x,      G.sceneY + G.sceneH - 80,
            s.x - 30, G.sceneY + G.sceneH - 50,
            s.x + 30, G.sceneY + G.sceneH - 50
        )
        love.graphics.setColor(0.29, 0.54, 0.83, 0.4)
        love.graphics.polygon("line",
            s.x,      G.sceneY + G.sceneH - 80,
            s.x - 30, G.sceneY + G.sceneH - 50,
            s.x + 30, G.sceneY + G.sceneH - 50
        )
        -- Label
        love.graphics.setColor(0.29, 0.41, 0.60)
        love.graphics.print(s.label, s.x - 28, G.sceneY + G.sceneH - 42, 0, 0.82, 0.82)
    end
end

local function drawScenebar()
    love.graphics.setColor(0.04, 0.05, 0.10)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)

    local names  = {"Mira Solano", "Taro Vex", "Dr. Halene"}
    local roles  = {"Engenheira", "Artilheiro", "Médica"}
    local active = {false, true, false}
    local cx     = G.sceneX + G.sceneW / 2
    local positions = { cx - 110, cx, cx + 110 }

    for i, px in ipairs(positions) do
        local py = G.sceneY + G.sceneH / 2 - 20
        local border = active[i] and {0.29, 0.54, 0.83} or {0.17, 0.21, 0.32}

        -- Silhueta
        love.graphics.setColor(0.07, 0.10, 0.16)
        love.graphics.circle("fill", px, py, 28)
        love.graphics.setColor(border)
        love.graphics.circle("line", px, py, 28)

        -- Cabeça
        love.graphics.setColor(0.10, 0.14, 0.22)
        love.graphics.circle("fill", px, py - 8, 12)

        -- Nome
        love.graphics.setColor(active[i] and {0.48, 0.67, 0.87} or {0.45, 0.55, 0.70})
        love.graphics.print(names[i], px - 32, py + 35, 0, 0.82, 0.82)
        love.graphics.setColor(0.30, 0.39, 0.52)
        love.graphics.print(roles[i], px - 20, py + 50, 0, 0.80, 0.80)
    end
end

local function drawSceneSpace()
    love.graphics.setColor(0.02, 0.03, 0.07)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY, G.sceneW, G.sceneH)

    -- Estrelas
    love.graphics.setColor(0.55, 0.65, 0.80, 0.5)
    local stars = {{50,30},{200,20},{310,55},{80,150},{260,160},{450,40},{420,130},{150,170},{370,90},{500,160}}
    for _, s in ipairs(stars) do
        love.graphics.circle("fill", G.sceneX + s[1], G.sceneY + s[2], 1.5)
    end

    -- Destino distante
    local cx = G.sceneX + G.sceneW / 2
    local cy = G.sceneY + G.sceneH / 2
    love.graphics.setColor(0.10, 0.08, 0.18)
    love.graphics.circle("fill", cx, cy, 28)
    love.graphics.setColor(0.18, 0.13, 0.30, 0.5)
    love.graphics.circle("fill", cx, cy, 20)

    -- Anel de órbita
    love.graphics.setColor(0.17, 0.13, 0.30, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.ellipse("line", cx, cy, 44, 8)
    love.graphics.setLineWidth(1)

    -- Vetor de decolagem
    love.graphics.setColor(0.29, 0.54, 0.83, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(cx - 160, cy + 60, cx - 40, cy + 10)
    love.graphics.setLineWidth(1)

    -- Texto de saída
    love.graphics.setColor(0.29, 0.41, 0.60)
    love.graphics.print("VETOR DE DECOLAGEM ATIVO", G.sceneX + 10, G.sceneY + G.sceneH - 20, 0, 0.80, 0.80)
end

local sceneDrawers = {
    station  = drawSceneStation,
    contracts     = drawScenecontracts,
    bank     = drawSceneBank,
    shipyard = drawSceneShipyard,
    bar     = drawScenebar,
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
    local bg     = isActive  and C.bgBtnActive
                or isHovered and C.bgBtnHover
                or C.bgBtn

    local border = isDanger  and C.borderDanger
                or isActive  and C.borderAccent
                or C.border

    local text   = isDanger  and C.textDanger
                or isActive  and C.textActive
                or C.textNormal

    drawRect(x, y, w, h, bg)
    drawRect(x, y, w, h, border, "line")

    if isActive and not isDanger then
        drawRect(x, y, 2, h, C.borderAccent)
    end

    setColor(text)
    love.graphics.setFont(smallFont)
    love.graphics.print(label, x + 10, y + h / 2 - 6)
end

-- ─────────────────────────────────────────
-- Hitboxes dos botões (para clique/hover)
-- ─────────────────────────────────────────

local function getButtonRects()
    local rects = {}
    for i, btn in ipairs(leftButtons) do
        rects[btn.key] = {
            x = G.leftX,
            y = G.leftBtnY[i],
            w = L.btnW,
            h = L.btnH,
        }
    end
    for i, btn in ipairs(rightButtons) do
        rects[btn.key] = {
            x = G.rightX,
            y = G.rightBtnY[i],
            w = L.btnW,
            h = L.btnH,
        }
    end
    return rects
end

local function pointInRect(px, py, r)
    return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

-- ─────────────────────────────────────────
-- Gamestate hooks
-- ─────────────────────────────────────────

function Landed.onEnter()
    love.mouse.setVisible(true)
    love.mouse.setRelativeMode(false)
    ship = Entities.with("ship")[1]

    if ship.landedAt.toSystem then
      local targetSystem = ship.landedAt.toSystem
      local currentSystemName = WorldManager.systems[WorldManager.currentSystemId].name
      WorldManager.loadSystem(targetSystem)
      local entries = WorldManager.systems[targetSystem].wormholes
      local entryX = 0
      local entryY = 0
      for _, entry in ipairs(entries) do
        if entry.name == "To "..currentSystemName then
          entryX = entry.x
          entryY = entry.y
        end
      end
      ship.rigidbody.body:setPosition(entryX, entryY)
      ship.rigidbody.body:setLinearVelocity(0,0)
      GameState.switch("playing")
    else
      activePanel = "trade"
      recalcGeometry()

      print("Docked at " .. (ship.landedAt and ship.landedAt.name or "unknown"))

      if ship.rigidbody and ship.rigidbody.body then
          ship.rigidbody.body:setLinearVelocity(0, 0)
          ship.rigidbody.body:setAngularVelocity(0)
      end
    end
end

function Landed.onExit()
    love.mouse.setVisible(false)
    love.mouse.setRelativeMode(true)
    if ship.rigidbody and ship.rigidbody.body then
        local angle = ship.rigidbody.body:getAngle()
        ship.rigidbody.body:applyLinearImpulse(
            math.cos(angle) * 400,
            math.sin(angle) * 400
        )
    end
    ship.landedAt = nil
    ship = nil
    InventoryUI.closeAll()
    print("Launched into space")
end

function Landed.update(dt)
    InventoryUI.update(dt)

    if input.inventory then
        InventoryUI.toggle(ship, { title = "Freight Bay" })
        input.inventory = false
    end

    -- Hover dos botões
    local mx, my = love.mouse.getPosition()
    local rects  = getButtonRects()
    hoveredBtn   = nil
    for key, r in pairs(rects) do
        if pointInRect(mx, my, r) then
            hoveredBtn = key
            break
        end
    end

    if input.escape or activePanel == "depart" and input.launch then
        GameState.switch("playing", { resuming = true })
    end
end

function Landed.mousepressed(_, mx, my, button)
    InventoryUI.mousepressed(mx, my, button)


    if button == 1 then
        local rects = getButtonRects()
        for key, r in pairs(rects) do
            if pointInRect(mx, my, r) then
                activePanel = key
                return
            end
        end
    end
end

function Landed.wheelmoved(dx, dy)
    InventoryUI.wheelmoved(dx, dy)
end

function Landed.draw()
    local panel = panels[activePanel]

    -- Fundo geral
    drawRect(G.x, G.y, G.w, G.h, C.bg)
    drawRect(G.x, G.y, G.w, G.h, C.border, "line")

    -- ── Cena ──
    local drawer = sceneDrawers[panel.scene] or drawSceneStation
    drawer()

    -- Overlay suave na base da cena
    setColor(C.sceneOverlay)
    love.graphics.rectangle("fill", G.sceneX, G.sceneY + G.sceneH - 30, G.sceneW, 30)

    -- Nome do local (canto inferior da cena)
    setColor(C.textBright)
    love.graphics.setFont(smallFont)
    love.graphics.print(
        ship and ship.landedAt and ship.landedAt.name or "Estação Desconhecida",
        G.sceneX + 10,
        G.sceneY + G.sceneH - 20
    )

    -- Separador cena / conteúdo
    drawRect(G.x, G.sceneY + G.sceneH, G.w, 2, C.border)

    -- ── Botões esquerda ──
    for i, btn in ipairs(leftButtons) do
        drawButton(
            G.leftX, G.leftBtnY[i], L.btnW, L.btnH,
            btn.label,
            activePanel == btn.key,
            hoveredBtn  == btn.key,
            false
        )
    end

    -- ── Botões direita ──
    for i, btn in ipairs(rightButtons) do
        drawButton(
            G.rightX, G.rightBtnY[i], L.btnW, L.btnH,
            btn.label,
            activePanel == btn.key,
            hoveredBtn  == btn.key,
            btn.danger or false
        )
    end

    -- ── Painel central ──
    drawRect(G.centerX, G.contentY, G.centerW, G.contentH, C.bgPanel)
    drawRect(G.centerX, G.contentY, G.centerW, G.contentH, C.border, "line")

    -- Título do painel
    setColor(C.textActive)
    love.graphics.setFont(normalFont)
    love.graphics.print(panel.title, G.centerX + L.padX, G.contentY + L.padY)

    -- Linha abaixo do título
    drawRect(G.centerX + L.padX, G.contentY + L.padY + 18, G.centerW - L.padX * 2, 1, C.border)

    -- Texto do painel
    love.graphics.setFont(smallFont)
    for j, line in ipairs(panel.text) do
        local color = (panel.textColors and panel.textColors[j]) or C.textNormal
        setColor(color)
        love.graphics.print(line, G.textX, G.textY + (j - 1) * L.lineH)
    end

    -- ── Barra de status ──
    local statusY = G.y + G.h - 18
    drawRect(G.x, statusY, G.w, 18, {0.03, 0.04, 0.07, 1})
    drawRect(G.x, statusY, G.w, 1, C.border)
    setColor(C.textMuted)
    love.graphics.setFont(smallFont)
    local locName = ship and ship.landedAt and ship.landedAt.name or "?"
    love.graphics.print("ATRACADO · " .. string.upper(locName), G.x + 10, statusY + 3)

    if ship and ship.inventory then
        local used = ship.inventory.weight   or 0
        local cap  = ship.inventory.capacity or 0
        love.graphics.print("CARGA: " .. used .. "/" .. cap, G.x + G.w - 120, statusY + 3)
    end

    -- ── Inventory UI por cima de tudo ──
    InventoryUI.draw()

    -- Reseta cor
    love.graphics.setColor(1, 1, 1, 1)
end

return Landed
