local input = {
    -- Estados
    state = {
        thrust = false, brake = false, left = false, right = false,
        up = false, down = false, land = false,
        rotateLeft = false, rotateRight = false,
        fire_primary = false, rcs = true, paused = false,
        weapon_type = 1, inventory = false, zoomIn = false,
        zoomOut = false, launch = false, debugFlag = false,
        properties = false
    },
    --
    -- Mapeamento: Tecla -> Ação contínua (segurar)
    bindings_hold = {
        ["up"] = "thrust", ["down"] = "brake",
        ["w"] = "thrust", ["s"] = "brake",
        ["left"] = "rotateLeft", ["right"] = "rotateRight",
        ["a"] = "rotateLeft", ["d"] = "rotateRight",
        ["kp4"] = "left", ["kp6"] = "right",
        ["kp8"] = "up", ["kp2"] = "down",
        ["kp+"] = "zoomIn", ["kp-"] = "zoomOut",
        ["+"] = "zoomIn", ["-"] = "zoomOut",
        ["space"] = "fire_primary",
        ["kpenter"] = "land",
        ["return"] = "land",
        ["l"] = "launch",
    },
    --
    -- Mapeamento: Tecla -> Ação de toggle (apertar uma vez)
    bindings_toggle = {
        ["kp0"] = function(s) s.rcs = not s.rcs end,
        ["r"] = function(s) s.rcs = not s.rcs end,
        ["escape"] = function(s) s.paused = not s.paused end,
        ["1"] = function(s) s.weapon_type = 1 end,
        ["2"] = function(s) s.weapon_type = 2 end,
        ["3"] = function(s) s.weapon_type = 3 end,
        ["4"] = function(s) s.weapon_type = 4 end,
        ["i"] = function(s) s.inventory = not s.inventory end,
        ["p"] = function(s) s.properties = not s.properties end,
        ["f1"] = function(s) s.debugFlag = not s.debugFlag end,
    }
}

function input.press(key)
    local hold_action = input.bindings_hold[key]
    if hold_action then
        if input.state.debugFlag then
          print("Pressed "..key)
        end
        input.state[hold_action] = true
    end

    local toggle_action = input.bindings_toggle[key]
    if toggle_action then
        if input.state.debugFlag then
          print("Toggled "..key)
        end
        toggle_action(input.state)
    end
end

function input.release(key)
    local hold_action = input.bindings_hold[key]
    if hold_action then
        if input.state.debugFlag then
          print("Released "..key)
        end
        input.state[hold_action] = false
    end
end

return input
