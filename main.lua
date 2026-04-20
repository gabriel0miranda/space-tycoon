config = require("config")

love.load = function()
  love.mouse.setVisible(true)
  config.GameState.register("mainmenu", config.MainmenuState)
  config.GameState.register("playing", config.PlayingState)
  config.GameState.register("landed", config.LandedState)

  config.PlayerEntity("NewPlayer")

  config.WorldManager.systems = config.Systems

  config.GameState.switch("mainmenu")

end

love.focus = function(focused)
  if not focused then
    config.Input.state.paused = true
  end
end

love.keypressed = function(pressed_key)
  config.GameState.keypressed(pressed_key)
  config.Input.press(pressed_key)
end

love.keyreleased = function(released_key)
  config.GameState.keyreleased(released_key)
  config.Input.release(released_key)
end

function love.mousepressed(x, y, button)
    config.GameState.mousepressed(x, y, button)
end

function love.wheelmoved(dx, dy)
    config.GameState.wheelmoved(dx, dy)
end

love.update = function(dt)
  config.GameState.update(dt)
end

love.draw = function()
  config.GameState.draw()
end
