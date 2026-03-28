local input = {}

local press_functions = {}
local release_functions = {}

input.inventory = false

input.fire_primary = false

input.left = false

input.right = false

input.up = false

input.down = false

input.rotateRight = false

input.rotateLeft = false

input.zoomIn = false

input.zoomOut = false

input.rcs = true

input.land = false

input.paused = false

input.launch = false

input.debug = false

input.weapon_type = 1

input.press = function(pressed_key)
  if press_functions[pressed_key] then
    press_functions[pressed_key]()
  end
end

input.release = function(released_key)
  if release_functions[released_key] then
    release_functions[released_key]()
  end
end

input.toggle_focus = function(focused)
  if not focused then
    input.paused = true
  end
end

press_functions.kp4 = function()
  input.left = true
end
press_functions.kp6 = function()
  input.right = true
end
press_functions.up = function()
  input.up = true
end
press_functions.down = function()
  input.down = true
end
press_functions.left = function()
  input.rotateLeft = true
end
press_functions.right = function()
  input.rotateRight = true
end
press_functions.kp0 = function()
  input.rcs = not input.rcs
end
press_functions["kp+"] = function()
  input.zoomIn = true
end
press_functions["kp-"] = function()
  input.zoomOut = true
end
press_functions["kpenter"] = function()
  input.land = true
end
press_functions["return"] = function()
  input.launch = true
end
press_functions.p = function()
  input.paused = not input.paused
end
press_functions.f1 = function()
  input.debug = not input.debug
end
press_functions.space = function()
  input.fire_primary = true
end
press_functions["1"] = function()
  input.weapon_type = 1
end
press_functions["2"] = function()
  input.weapon_type = 2
end
press_functions["3"] = function()
  input.weapon_type = 3
end
press_functions["4"] = function()
  input.weapon_type = 4
end
press_functions["i"] = function()
  input.inventory = not input.inventory
end
press_functions["escape"] = function()
  input.mainmenu = true
end


release_functions.kp4 = function()
  input.left = false
end
release_functions.kp6 = function()
  input.right = false
end
release_functions.up = function()
  input.up = false
end
release_functions.down = function()
  input.down = false
end
release_functions.left = function()
  input.rotateLeft = false
end
release_functions.right = function()
  input.rotateRight = false
end
release_functions["kp+"] = function()
  input.zoomIn = false
end
release_functions["kp-"] = function()
  input.zoomOut = false
end
release_functions["kpenter"] = function()
  input.land = false
end
release_functions["return"] = function()
  input.launch = false
end
release_functions.space = function()
  input.fire_primary = false
end
release_functions["escape"] = function()
  input.mainmenu = false
end


return input
