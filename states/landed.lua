local Landed = {}

function Landed.onEnter()
  local ship = Entities.with("ship")[1]
  print("Docked at " .. (ship.landedAt and ship.landedAt.name or "unknown"))
  if ship.body then
    ship.body:setLinearVelocity(0, 0)
    ship.body:setAngularVelocity(0)
  end
end

function Landed.onExit()
  local ship = Entities.with("ship")[1]
  if ship.body then
    local angle = ship.body:getAngle()
    ship.body:applyLinearImpulse(
        math.cos(angle) * 400,
        math.sin(angle) * 400
    )
  end
  ship.landedAt = nil
  print("Launched into space")
end

function Landed.update(dt)
end

function Landed.draw()
  local ship = Entities.with("ship")[1]
  -- Semi-transparent menu background
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill",
    200, 150,
    love.graphics.getWidth() - 400,
    love.graphics.getHeight() - 300
  )

  love.graphics.setColor(0.9, 0.9, 1)

  -- Title
  love.graphics.setFont(bigFont)   -- make sure you created this in love.load
  love.graphics.print("Docked at " .. ship.landedAt.name, 250, 180)

  -- Instructions
  love.graphics.setFont(normalFont)
  love.graphics.print("Press ESC to launch", 250, 260)

  -- Content based on type
  if ship.landedAt.type == "station" then
    love.graphics.print("• Trade\n• Repair\n• Missions\n• Quit to Space", 280, 320)
  else
    love.graphics.print("• Surface Info\n• Refuel\n• Talk to Locals\n• Quit to Space", 280, 320)
  end

  -- Future: you can add menu selection with arrow keys here
end

function Landed.keypressed(key)
  if key == "escape" then
    GameState.switch("playing")
  end

  -- Example future menu navigation:
  -- if key == "1" then ... open trade menu, etc.
end

return Landed
