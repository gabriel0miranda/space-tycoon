-- ─────────────────────────────────────────────────────────────────────────────
-- input.lua  —  Sistema de input com action resolver, context stack e gamepad
-- ─────────────────────────────────────────────────────────────────────────────
--
-- CONCEITOS
--
--   Action        String semântica que representa uma intenção do jogador.
--                 Ex: "ship_thrust", "ui_confirm", "ship_rcs_toggle".
--                 O resto do jogo só conhece actions, nunca teclas diretamente.
--
--   Binding       Par (dispositivo, código) → action.
--                 Ex: keyboard["w"] = "ship_thrust"
--                     gamepad["dpup"] = "ship_thrust"
--                 Pode ser alterado em runtime para remapeamento pelo jogador.
--
--   Action type   Cada action é declarada como:
--                   "hold"   – verdadeiro enquanto a tecla está pressionada.
--                              state[action] vira true no press, false no release.
--                   "pulse"  – dispara uma vez por press (toggle, weapon select…).
--                              state[action] fica true por um frame; consumido com
--                              input.consume(action) ou automaticamente no
--                              próximo input.beginFrame().
--                   "axis"   – valor contínuo [-1, 1] vindo de analógico ou teclas
--                              opostas. state[action] é um número.
--
--   Context       String que representa o "foco" atual da UI.
--                 Ex: "playing", "market", "inventory", "mainmenu".
--                 Apenas actions listadas em context_actions[ctx] são entregues
--                 enquanto esse contexto estiver ativo.
--                 A pilha permite sobreposição: market aberto sobre playing.
--
--   Context stack Pilha de contextos. O topo tem prioridade. Uma action não
--                 reconhecida pelo topo pode "borbulhar" (bubble=true) para o
--                 contexto abaixo, útil p/ "ui_cancel" funcionar em qualquer UI.
--
-- API PÚBLICA
--
--   input.pushContext(name)          Empurra contexto na pilha.
--   input.popContext(name)           Remove contexto pelo nome (qualquer posição).
--   input.clearContexts()            Esvazia a pilha.
--   input.currentContext()           Retorna o nome do topo (ou nil).
--
--   input.press(key)                 Chamado por love.keypressed.
--   input.release(key)               Chamado por love.keyreleased.
--   input.gamepadpress(btn)          Chamado por love.gamepadpressed.
--   input.gamepadrelease(btn)        Chamado por love.gamepadreleased.
--   input.gamepadaxis(axis, value)   Chamado por love.gamepadaxis.
--   input.beginFrame()               Chamado no início de love.update — limpa pulses.
--
--   input.consume(action)            Consome um pulse manualmente (evita que outro
--                                   sistema o leia no mesmo frame).
--   input.rebind(device, code, action) Remapeia um binding em runtime.
--                                   device: "keyboard" | "gamepad"
--
--   input.state                      Tabela flat lida pelos sistemas do jogo.
--                                   Mesma interface do input.lua anterior.
--
-- COMPATIBILIDADE COM O CÓDIGO EXISTENTE
--
--   Todos os campos de input.state do input.lua anterior continuam existindo
--   com os mesmos nomes. Código que lia input.state.thrust, input.state.rcs,
--   input.state.inventory, etc. funciona sem alteração.
--
-- ─────────────────────────────────────────────────────────────────────────────

local input = {}

-- ─────────────────────────────────────────
-- 1. DECLARAÇÃO DE ACTIONS
-- ─────────────────────────────────────────
-- Cada action precisa estar aqui para receber uma entrada em input.state.
-- "hold"  → boolean (true enquanto pressionado)
-- "pulse" → boolean (true por 1 frame, zerado em beginFrame)
-- "axis"  → number  (valor contínuo, padrão 0)

local action_types = {
    -- Movimento da nave
    ship_thrust         = "hold",
    ship_brake          = "hold",
    ship_rotate_left    = "hold",
    ship_rotate_right   = "hold",
    ship_strafe_left    = "hold",
    ship_strafe_right   = "hold",
    ship_strafe_up      = "hold",
    ship_strafe_down    = "hold",

    -- Eixos analógicos (gamepad)
    ship_axis_x         = "axis",   -- joystick esquerdo horizontal
    ship_axis_y         = "axis",   -- joystick esquerdo vertical
    ship_axis_rotate    = "axis",   -- joystick direito horizontal

    -- Combate
    ship_fire           = "hold",
    ship_weapon_1       = "pulse",
    ship_weapon_2       = "pulse",
    ship_weapon_3       = "pulse",
    ship_weapon_4       = "pulse",

    -- Sistemas da nave
    ship_rcs_toggle     = "pulse",
    ship_land           = "hold",
    ship_launch         = "hold",

    -- Câmera
    camera_zoom_in      = "hold",
    camera_zoom_out     = "hold",

    -- UI / menus
    ui_confirm          = "pulse",
    ui_cancel           = "pulse",
    ui_up               = "pulse",
    ui_down             = "pulse",
    ui_left             = "pulse",
    ui_right            = "pulse",
    ui_inventory        = "pulse",
    ui_properties       = "pulse",
    ui_mainmenu         = "pulse",

    -- Meta
    meta_pause          = "pulse",
    meta_debug          = "pulse",
}

-- ─────────────────────────────────────────
-- 2. BINDINGS PADRÃO
-- ─────────────────────────────────────────
-- Remapeáveis em runtime via input.rebind().
-- Serializar/desserializar estas tabelas é suficiente para salvar controles.

local default_bindings = {

    keyboard = {
        -- Movimento
        ["w"]           = "ship_thrust",
        ["up"]          = "ship_thrust",
        ["s"]           = "ship_brake",
        ["down"]        = "ship_brake",
        ["a"]           = "ship_rotate_left",
        ["left"]        = "ship_rotate_left",
        ["d"]           = "ship_rotate_right",
        ["right"]       = "ship_rotate_right",
        ["kp4"]         = "ship_strafe_left",
        ["kp6"]         = "ship_strafe_right",
        ["kp8"]         = "ship_strafe_up",
        ["kp2"]         = "ship_strafe_down",

        -- Combate
        ["space"]       = "ship_fire",
        ["1"]           = "ship_weapon_1",
        ["2"]           = "ship_weapon_2",
        ["3"]           = "ship_weapon_3",
        ["4"]           = "ship_weapon_4",

        -- Sistemas
        ["r"]           = "ship_rcs_toggle",
        ["kp0"]         = "ship_rcs_toggle",
        ["return"]      = "ship_land",
        ["kpenter"]     = "ship_land",
        ["l"]           = "ship_launch",

        -- Câmera
        ["kp+"]         = "camera_zoom_in",
        ["+"]           = "camera_zoom_in",
        ["kp-"]         = "camera_zoom_out",
        ["-"]           = "camera_zoom_out",

        -- UI
        ["i"]           = "ui_inventory",
        ["o"]           = "ui_properties",
        ["escape"]      = "ui_cancel",
        ["f4"]          = "ui_mainmenu",

        -- Meta
        ["p"]           = "meta_pause",
        ["f1"]          = "meta_debug",
    },

    gamepad = {
        -- Botões de face (Xbox layout)
        ["a"]           = "ui_confirm",    -- A = confirmar em menus
        ["b"]           = "ui_cancel",     -- B = cancelar / fechar
        ["x"]           = "ship_fire",
        ["y"]           = "ship_rcs_toggle",

        -- Bumpers / triggers mapeados como botões digitais
        ["leftshoulder"]  = "ship_brake",
        ["rightshoulder"] = "ship_thrust",

        -- D-pad: movimento de UI quando em menus, strafe quando em jogo
        ["dpup"]        = "ui_up",
        ["dpdown"]      = "ui_down",
        ["dpleft"]      = "ui_left",
        ["dpright"]     = "ui_right",

        -- Botões centrais
        ["start"]       = "meta_pause",
        ["back"]        = "ui_mainmenu",

        -- Stick press
        ["leftstick"]   = "ship_land",
        ["rightstick"]  = "meta_debug",
    },

    -- Eixos analógicos do gamepad.
    -- Formato: { axis_name, threshold }  →  action
    -- threshold: valor mínimo (absoluto) para disparar uma "hold action" digital.
    gamepad_axis = {
        ["leftx"]   = { action = "ship_axis_x",      digital_neg = "ship_rotate_left",  digital_pos = "ship_rotate_right", threshold = 0.25 },
        ["lefty"]   = { action = "ship_axis_y",       digital_neg = "ship_thrust",       digital_pos = "ship_brake",        threshold = 0.25 },
        ["rightx"]  = { action = "ship_axis_rotate",  digital_neg = nil,                 digital_pos = nil,                 threshold = 0.25 },
        ["triggerleft"]  = { action = nil, digital_neg = nil, digital_pos = "ship_brake",   threshold = 0.15 },
        ["triggerright"] = { action = nil, digital_neg = nil, digital_pos = "ship_thrust",  threshold = 0.15 },
    },
}

-- ─────────────────────────────────────────
-- 3. CONTEXTOS E SUAS ACTIONS PERMITIDAS
-- ─────────────────────────────────────────
-- Um contexto só entrega as actions listadas aqui ao estado.
-- bubble = true  →  se a action NÃO estiver na lista do contexto, passa para baixo
--                   na pilha (útil para ui_cancel funcionar em todos os menus).

local context_defs = {

    playing = {
        bubble = false,   -- contexto base: nada passa para baixo
        actions = {
            ship_thrust=true, ship_brake=true,
            ship_rotate_left=true, ship_rotate_right=true,
            ship_strafe_left=true, ship_strafe_right=true,
            ship_strafe_up=true, ship_strafe_down=true,
            ship_axis_x=true, ship_axis_y=true, ship_axis_rotate=true,
            ship_fire=true,
            ship_weapon_1=true, ship_weapon_2=true,
            ship_weapon_3=true, ship_weapon_4=true,
            ship_rcs_toggle=true, ship_land=true, ship_launch=true,
            camera_zoom_in=true, camera_zoom_out=true,
            ui_inventory=true, ui_properties=true, ui_mainmenu=true,
            meta_pause=true, meta_debug=true,
        },
    },

    -- Menus de UI sobreposta (inventário, market, shipyard…)
    -- bubble=true: ações de voo que o menu não usa passam para "playing" abaixo
    inventory = {
        bubble = true,
        actions = {
            ui_confirm=true, ui_cancel=true,
            ui_up=true, ui_down=true, ui_left=true, ui_right=true,
            ui_inventory=true,
            meta_debug=true,
        },
    },

    property = {
        bubble = true,
        actions = {
            ui_confirm=true, ui_cancel=true,
            ui_up=true, ui_down=true, ui_left=true, ui_right=true,
            ui_inventory=true,
            meta_debug=true,
        },
    },

    market = {
        bubble = true,
        actions = {
            ui_confirm=true, ui_cancel=true,
            ui_up=true, ui_down=true, ui_left=true, ui_right=true,
            meta_debug=true,
        },
    },

    shipyard = {
        bubble = true,
        actions = {
            ui_confirm=true, ui_cancel=true,
            ui_up=true, ui_down=true,
            meta_debug=true,
        },
    },

    textinput = {
        bubble = false,   -- bloqueia tudo: o modal é dono total do teclado
        actions = {
            ui_cancel  = true,   -- Esc ainda fecha o modal
            ui_confirm = true,   -- Enter ainda confirma
        },
    },

    landed = {
        bubble = false,
        actions = {
            ui_confirm=true, ui_cancel=true,
            ui_up=true, ui_down=true, ui_left=true, ui_right=true,
            ui_inventory=true,
            meta_debug=true,
        },
    },

    mainmenu = {
        bubble = false,
        actions = {
            ui_confirm=true, ui_cancel=true,
            ui_up=true, ui_down=true,
            meta_debug=true,
        },
    },

    select = {
        bubble = false,   -- modal dono total do teclado
        actions = {
            ui_confirm = true,
            ui_cancel  = true,
            ui_up      = true,
            ui_down    = true,
        },
    },

    -- Tela de remapeamento de controles: consome TUDO para capturar qualquer tecla
    controls = {
        bubble = false,
        actions = {},   -- preenchido dinamicamente — veja input.beginCapture()
        capture_all = true,
    },
}

-- ─────────────────────────────────────────
-- 4. ESTADO INTERNO
-- ─────────────────────────────────────────

-- Bindings ativos (cópia dos defaults; modificados por input.rebind)
local bindings = {
    keyboard    = {},
    gamepad     = {},
    gamepad_axis= {},
}

-- Pilha de contextos (strings). O último elemento é o topo.
local context_stack = {}

-- Tabela de estado das actions (lida pelo resto do jogo)
-- Inicializa todos os campos declarados em action_types
input.state = {}
for action, atype in pairs(action_types) do
    if atype == "axis" then
        input.state[action] = 0
    else
        input.state[action] = false
    end
end

-- Campos legados mantidos para compatibilidade com código existente
-- Eles são aliases atualizados em sync_legacy_state()
input.state.thrust       = false
input.state.brake        = false
input.state.left         = false
input.state.right        = false
input.state.up           = false
input.state.down         = false
input.state.land         = false
input.state.rotateLeft   = false
input.state.rotateRight  = false
input.state.fire_primary = false
input.state.rcs          = true   -- começa ligado, igual ao original
input.state.paused       = false
input.state.weapon_type  = 1
input.state.inventory    = false
input.state.zoomIn       = false
input.state.zoomOut      = false
input.state.launch       = false
input.state.debugFlag    = false
input.state.properties   = false
input.state.mainmenu     = false
input.state.exit         = false

-- Pulses que foram disparados neste frame
local active_pulses = {}
-- Pulses do frame anterior — estes sim são zerados no próximo beginFrame
local last_pulses   = {}

-- Eixos analógicos ativos por nome de eixo (estado raw do gamepad)
local axis_values = {}

-- Modo de captura de tecla para remapeamento
local capture_callback = nil   -- function(device, code) quando em modo captura

-- ─────────────────────────────────────────
-- 5. INICIALIZAÇÃO
-- ─────────────────────────────────────────

local function deep_copy_bindings()
    for k, v in pairs(default_bindings.keyboard) do
        bindings.keyboard[k] = v
    end
    for k, v in pairs(default_bindings.gamepad) do
        bindings.gamepad[k] = v
    end
    for k, v in pairs(default_bindings.gamepad_axis) do
        bindings.gamepad_axis[k] = {
            action      = v.action,
            digital_neg = v.digital_neg,
            digital_pos = v.digital_pos,
            threshold   = v.threshold,
        }
    end
end

deep_copy_bindings()

-- ─────────────────────────────────────────
-- 6. UTILITÁRIOS INTERNOS
-- ─────────────────────────────────────────

-- Retorna o contexto do topo da pilha (ou nil)
local function top_context()
    return context_stack[#context_stack]
end

-- Verifica se uma action deve ser entregue dado o estado atual da pilha.
-- Retorna true se pelo menos um contexto na pilha aceitar a action.
local function action_allowed(action)
    for i = #context_stack, 1, -1 do
        local ctx_name = context_stack[i]
        local def = context_defs[ctx_name]
        if def then
            if def.capture_all then
                return true   -- modo captura aceita tudo
            end
            if def.actions[action] then
                return true
            end
            if not def.bubble then
                return false  -- bloqueado; não borbulha
            end
            -- bubble=true: continua descendo na pilha
        end
    end
    return false
end

-- Entrega uma action hold (press ou release).
-- Releases sempre passam independente de contexto: se o contexto mudar enquanto
-- uma tecla está pressionada (ex: switch de state no mesmo frame do press),
-- o release precisa chegar para que o hold não fique preso em true para sempre.
local function deliver_hold(action, is_press)
    if action_types[action] ~= "hold" then return end
    if is_press and not action_allowed(action) then return end
    input.state[action] = is_press
end

-- Entrega uma action pulse
local function deliver_pulse(action)
    if action_types[action] ~= "pulse" then return end
    if not action_allowed(action) then return end
    input.state[action] = true
    active_pulses[action] = true
end

-- Entrega valor de eixo
local function deliver_axis(action, value)
    if action_types[action] ~= "axis" then return end
    if not action_allowed(action) then return end
    input.state[action] = value
end

-- Atualiza os campos legados a partir das actions novas
local function sync_legacy_state()
    local s = input.state

    -- Hold aliases
    s.thrust       = s.ship_thrust
    s.brake        = s.ship_brake
    s.rotateLeft   = s.ship_rotate_left
    s.rotateRight  = s.ship_rotate_right
    s.left         = s.ship_strafe_left
    s.right        = s.ship_strafe_right
    s.up           = s.ship_strafe_up
    s.down         = s.ship_strafe_down
    s.fire_primary = s.ship_fire
    s.land         = s.ship_land
    s.launch       = s.ship_launch
    s.zoomIn       = s.camera_zoom_in
    s.zoomOut      = s.camera_zoom_out

    -- Pulse aliases (são true por 1 frame; toggles resolvidos aqui)
    if s.ship_rcs_toggle then
        s.rcs = not s.rcs
    end
    if s.meta_pause then
        s.paused = not s.paused
    end
    if s.meta_debug then
        s.debugFlag = not s.debugFlag
    end

    -- weapon_type: escolhido pelo primeiro pulse ativo
    if s.ship_weapon_1 then s.weapon_type = 1 end
    if s.ship_weapon_2 then s.weapon_type = 2 end
    if s.ship_weapon_3 then s.weapon_type = 3 end
    if s.ship_weapon_4 then s.weapon_type = 4 end

    -- Pulses de UI mapeados para os campos legados de 1 frame
    s.inventory  = s.ui_inventory
    s.properties = s.ui_properties
    s.mainmenu   = s.ui_mainmenu
end

-- ─────────────────────────────────────────
-- 7. API PÚBLICA — CONTEXTOS
-- ─────────────────────────────────────────

function input.pushContext(name)
    -- Evita duplicata consecutiva
    if top_context() == name then return end
    table.insert(context_stack, name)
    if input.state.debugFlag then
        print("[input] pushContext: " .. name .. "  stack: " .. table.concat(context_stack, " > "))
    end
end

-- Remove um contexto pelo nome (qualquer posição na pilha)
function input.popContext(name)
    for i = #context_stack, 1, -1 do
        if context_stack[i] == name then
            table.remove(context_stack, i)
            break
        end
    end
    if input.state.debugFlag then
        print("[input] popContext: " .. tostring(name) .. "  stack: " .. table.concat(context_stack, " > "))
    end
end

function input.clearContexts()
    context_stack = {}
end

function input.currentContext()
    return top_context()
end

-- ─────────────────────────────────────────
-- 8. API PÚBLICA — FRAME LIFECYCLE
-- ─────────────────────────────────────────

-- Deve ser chamado no INÍCIO de love.update(dt), antes de qualquer leitura.
-- Zera os pulses do frame ANTERIOR, expõe os do frame atual, sincroniza legado.
--
-- Ordem correta:
--   1. Zera last_pulses  (disparados no frame anterior, já foram lidos)
--   2. Promove active_pulses → last_pulses  (os do frame atual ficam vivos)
--   3. Sincroniza campos legados a partir dos pulses agora ativos
--
-- Assim um pulse disparado em love.keypressed fica true durante todo o update
-- do mesmo frame, e é zerado só no beginFrame seguinte.
function input.beginFrame()
    -- 1. Zera o que disparou no frame anterior
    for action in pairs(last_pulses) do
        input.state[action] = false
    end
    input.state.inventory  = false
    input.state.properties = false
    input.state.mainmenu   = false
    input.state.exit       = false

    -- 2. Promove: active_pulses do frame atual vira last_pulses para o próximo
    last_pulses   = active_pulses
    active_pulses = {}

    -- 3. Sincroniza legado a partir dos pulses agora ativos (recém promovidos)
    sync_legacy_state()
end

-- Consome um pulse explicitamente (evita que dois sistemas o leiam)
function input.consume(action)
    if active_pulses[action] then
        input.state[action] = false
        active_pulses[action] = nil
    end
end

-- ─────────────────────────────────────────
-- 9. API PÚBLICA — EVENTOS DE TECLADO
-- ─────────────────────────────────────────

function input.press(key)
    -- Modo captura: entrega a tecla diretamente ao callback e sai
    if capture_callback then
        capture_callback("keyboard", key)
        return
    end

    local action = bindings.keyboard[key]
    if not action then return end

    if input.state.debugFlag then
        print("[input] key press: " .. key .. " → " .. action)
    end

    local atype = action_types[action]
    if atype == "hold" then
        deliver_hold(action, true)
    elseif atype == "pulse" then
        deliver_pulse(action)
    end
end

function input.release(key)
    local action = bindings.keyboard[key]
    if not action then return end

    if input.state.debugFlag then
        print("[input] key release: " .. key .. " → " .. action)
    end

    if action_types[action] == "hold" then
        deliver_hold(action, false)
    end
end

-- ─────────────────────────────────────────
-- 10. API PÚBLICA — EVENTOS DE GAMEPAD
-- ─────────────────────────────────────────

function input.gamepadpress(btn)
    if capture_callback then
        capture_callback("gamepad", btn)
        return
    end

    local action = bindings.gamepad[btn]
    if not action then return end

    if input.state.debugFlag then
        print("[input] gamepad press: " .. btn .. " → " .. action)
    end

    local atype = action_types[action]
    if atype == "hold" then
        deliver_hold(action, true)
    elseif atype == "pulse" then
        deliver_pulse(action)
    end
end

function input.gamepadrelease(btn)
    local action = bindings.gamepad[btn]
    if not action then return end

    if action_types[action] == "hold" then
        deliver_hold(action, false)
    end
end

-- Chamado por love.gamepadaxis(joystick, axis, value)
-- value está no range [-1, 1] para sticks e [0, 1] para triggers
function input.gamepadaxis(axis, value)
    local def = bindings.gamepad_axis[axis]
    if not def then return end

    -- Atualiza o valor raw do eixo
    axis_values[axis] = value

    -- Entrega o eixo analógico (se mapeado)
    if def.action then
        deliver_axis(def.action, value)
    end

    -- Entrega versão digital (hold) a partir do threshold.
    -- Usa deliver_hold diretamente: quando o eixo volta ao centro (release),
    -- a correção em deliver_hold garante que o false sempre passe.
    local thr = def.threshold or 0.25

    if def.digital_neg then
        deliver_hold(def.digital_neg, value < -thr)
    end
    if def.digital_pos then
        deliver_hold(def.digital_pos, value > thr)
    end
end

-- Retorna o valor raw de um eixo (útil para movimento analógico suave)
function input.getAxis(axis)
    return axis_values[axis] or 0
end

-- ─────────────────────────────────────────
-- 11. API PÚBLICA — REMAPEAMENTO
-- ─────────────────────────────────────────

-- Remapeia um código de dispositivo para uma action.
-- device: "keyboard" | "gamepad"
-- code:   string da tecla/botão (ex: "w", "a", "leftshoulder")
-- action: string de action (deve existir em action_types), ou nil para remover
function input.rebind(device, code, action)
    assert(device == "keyboard" or device == "gamepad",
           "input.rebind: device deve ser 'keyboard' ou 'gamepad'")
    if action ~= nil then
        assert(action_types[action],
               "input.rebind: action desconhecida: " .. tostring(action))
    end

    -- Remove binding anterior do mesmo código
    bindings[device][code] = nil

    -- Remove qualquer outro código que aponte para a mesma action no mesmo device
    -- (evita duplicata — opcional; comente se quiser permitir múltiplos códigos)
    if action then
        for k, v in pairs(bindings[device]) do
            if v == action then
                bindings[device][k] = nil
                break
            end
        end
        bindings[device][code] = action
    end

    if input.state.debugFlag then
        print("[input] rebind: " .. device .. "[" .. code .. "] = " .. tostring(action))
    end
end

-- Retorna o primeiro código de teclado mapeado para uma action, ou nil
function input.getKeyboardBinding(action)
    for code, act in pairs(bindings.keyboard) do
        if act == action then return code end
    end
    return nil
end

-- Retorna o primeiro botão de gamepad mapeado para uma action, ou nil
function input.getGamepadBinding(action)
    for code, act in pairs(bindings.gamepad) do
        if act == action then return code end
    end
    return nil
end

-- Retorna cópia dos bindings ativos (para serializar / exibir na tela de controles)
function input.getBindings()
    local out = { keyboard = {}, gamepad = {}, gamepad_axis = {} }
    for k, v in pairs(bindings.keyboard)    do out.keyboard[k]    = v end
    for k, v in pairs(bindings.gamepad)     do out.gamepad[k]     = v end
    for k, v in pairs(bindings.gamepad_axis) do
        out.gamepad_axis[k] = {
            action      = v.action,
            digital_neg = v.digital_neg,
            digital_pos = v.digital_pos,
            threshold   = v.threshold,
        }
    end
    return out
end

-- Restaura os bindings para os defaults de fábrica
function input.resetBindings()
    bindings = { keyboard = {}, gamepad = {}, gamepad_axis = {} }
    deep_copy_bindings()
end

-- ─────────────────────────────────────────
-- 12. API PÚBLICA — CAPTURA DE TECLA
-- ─────────────────────────────────────────
-- Para a tela de remapeamento. Coloca o sistema em modo captura:
-- o próximo press de teclado ou gamepad chama callback(device, code)
-- e sai do modo captura automaticamente.
--
-- Uso:
--   input.beginCapture(function(device, code)
--       input.rebind(device, code, "ship_thrust")
--   end)

function input.beginCapture(callback)
    capture_callback = callback
    input.pushContext("controls")
end

function input.endCapture()
    capture_callback = nil
    input.popContext("controls")
end

function input.isCapturing()
    return capture_callback ~= nil
end

-- ─────────────────────────────────────────
-- 13. LISTA DE ACTIONS PARA A UI DE CONTROLES
-- ─────────────────────────────────────────
-- Retorna uma lista ordenada de { action, label, group } para exibir
-- na tela de configuração de controles do mainmenu.

input.action_labels = {
    -- { action, label legível, grupo }
    { "ship_thrust",       "Acelerar",             "Nave" },
    { "ship_brake",        "Frear",                "Nave" },
    { "ship_rotate_left",  "Girar esquerda",       "Nave" },
    { "ship_rotate_right", "Girar direita",        "Nave" },
    { "ship_strafe_left",  "Mover esquerda",       "Nave" },
    { "ship_strafe_right", "Mover direita",        "Nave" },
    { "ship_strafe_up",    "Mover frente",         "Nave" },
    { "ship_strafe_down",  "Mover atrás",          "Nave" },
    { "ship_fire",         "Atirar",               "Combate" },
    { "ship_weapon_1",     "Arma 1",               "Combate" },
    { "ship_weapon_2",     "Arma 2",               "Combate" },
    { "ship_weapon_3",     "Arma 3",               "Combate" },
    { "ship_weapon_4",     "Arma 4",               "Combate" },
    { "ship_rcs_toggle",   "Toggle RCS",           "Sistemas" },
    { "ship_land",         "Pousar",               "Sistemas" },
    { "ship_launch",       "Decolar",              "Sistemas" },
    { "camera_zoom_in",    "Zoom in",              "Câmera" },
    { "camera_zoom_out",   "Zoom out",             "Câmera" },
    { "ui_inventory",      "Inventário",           "Interface" },
    { "ui_properties",     "Propriedades",         "Interface" },
    { "ui_mainmenu",       "Menu principal",       "Interface" },
    { "meta_pause",        "Pausar",               "Sistema" },
    { "meta_debug",        "Debug",                "Sistema" },
}

-- ─────────────────────────────────────────
-- 14. INTEGRAÇÃO COM LOVE2D  (main.lua)
-- ─────────────────────────────────────────
--
-- No main.lua, adicione/ajuste:
--
--   love.update = function(dt)
--     input.beginFrame()          -- <-- NOVO: antes de tudo no update
--     config.GameState.update(dt)
--   end
--
--   love.keypressed = function(key)
--     config.GameState.keypressed(key)
--     config.Input.press(key)
--   end
--
--   love.keyreleased = function(released_key)
--     config.GameState.keyreleased(released_key)
--     config.Input.release(released_key)
--   end
--
--   -- NOVO: suporte a gamepad
--   function love.gamepadpressed(joystick, button)
--     config.Input.gamepadpress(button)
--   end
--
--   function love.gamepadreleased(joystick, button)
--     config.Input.gamepadrelease(button)
--   end
--
--   function love.gamepadaxis(joystick, axis, value)
--     config.Input.gamepadaxis(axis, value)
--   end
--
-- ─────────────────────────────────────────
-- 15. INTEGRAÇÃO COM OS GAME STATES
-- ─────────────────────────────────────────
--
-- playing.lua — onEnter:
--   config.Input.pushContext("playing")
--
-- playing.lua — onExit:
--   config.Input.popContext("playing")
--
-- landed.lua — onEnter:
--   config.Input.pushContext("landed")
--
-- landed.lua — onExit:
--   config.Input.popContext("landed")
--
-- mainmenu.lua — onEnter:
--   config.Input.pushContext("mainmenu")
--
-- mainmenu.lua — onExit:
--   config.Input.popContext("mainmenu")
--
-- inventory_ui.lua — open():
--   config.Input.pushContext("inventory")
--
-- inventory_ui.lua — close():
--   config.Input.popContext("inventory")
--
-- market_ui.lua — open():
--   config.Input.pushContext("market")
--
-- market_ui.lua — close():
--   config.Input.popContext("market")
--
-- ─────────────────────────────────────────
-- 16. LEITURA DAS ACTIONS NOS SISTEMAS
-- ─────────────────────────────────────────
--
-- Código ANTIGO (ainda funciona via aliases legados):
--   if config.Input.state.thrust then ... end
--   if config.Input.state.inventory then ... end
--
-- Código NOVO (preferível em código novo):
--   if config.Input.state.ship_thrust then ... end
--   if config.Input.state.ui_inventory then ... end
--
-- Para movimento analógico suave (ex: no ShipMovementSystem):
--   local ax = config.Input.getAxis("leftx")   -- [-1, 1]
--   local ay = config.Input.getAxis("lefty")
--   -- combine com o digital se o gamepad não estiver conectado:
--   if math.abs(ax) < 0.1 then
--       ax = (config.Input.state.ship_rotate_right and 1 or 0)
--          - (config.Input.state.ship_rotate_left  and 1 or 0)
--   end
--
-- ─────────────────────────────────────────

return input
