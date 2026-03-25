local MainMenu = {}

function MainMenu.onEnter()
  love.mouse.setVisible(true)
  print("Entered Main Menu")
end

function MainMenu.onExit()
  print("Exited main menu")
  love.mouse.setVisible(false)
end

function MainMenu.update(dt)
end

function MainMenu.draw()
  -- Dark space background
  love.graphics.setBackgroundColor(0.01, 0.01, 0.04)

  -- Title
  love.graphics.setFont(bigFont)          -- make sure you created this in love.load
  love.graphics.setColor(0.6, 0.9, 1.0)
  love.graphics.printf("VOID PILOT", 0, 160, love.graphics.getWidth(), "center")

  -- Subtitle / tagline (optional)
  love.graphics.setFont(normalFont)
  love.graphics.setColor(0.7, 0.7, 0.9)
  love.graphics.printf("A tiny space adventure", 0, 240, love.graphics.getWidth(), "center")

  -- Menu options
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(
    "1. New Game\n" ..
    "2. Continue\n" ..
    "3. Options\n" ..
    "4. Quit",
    0, 340, love.graphics.getWidth(), "center"
  )

  -- Footer
  love.graphics.setColor(0.4, 0.4, 0.5)
  love.graphics.setFont(smallFont)        -- optional small font
  love.graphics.printf("Version 0.1 • Press number or click", 
                       0, love.graphics.getHeight() - 50, 
                       love.graphics.getWidth(), "center")
end

function MainMenu.keypressed(key)
  if key == "1" or key == "return" then
    GameState.switch("playing")
  elseif key == "2" then
    love.grapics.setColor(1,1,1)
    love.graphics.print("LOAD NOT IMPLEMENTED YET",400,300)
  elseif key == "4" or key == "escape" then
    love.event.quit()
  end
end

return MainMenu
