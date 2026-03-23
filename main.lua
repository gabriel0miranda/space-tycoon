local entities = require('entities')
local input = require('input')
local camera = require('camera')
local world = require('world')


local stars = {}
local asteroids = {}
local ship
local landables = {}
local entity_list = entities(20,1)
local camera1 = camera()

love.load = function()
  for _, entity in ipairs(entity_list) do
    local tag = entity:getTag()
    if tag == 'star' then
      table.insert(stars, entity)
    elseif tag == 'asteroid' then
      table.insert(asteroids, entity)
    end
    if tag == 'ship' then
      ship = entity
    end
    if tag == "planet" or tag == "station" then
      table.insert(landables,entity)
    end
    for _, star in ipairs(stars) do
      for _, entity in ipairs(landables) do
        local tag = entity:getTag()
        if tag == "station" or tag == "planet" then
          entity.orbitRadius = math.sqrt((entity.x - star.x)^2 + (entity.y - star.y)^2)
          entity.orbitAngle = math.atan2(entity.y - star.y, entity.x - star.x)
          entity.orbitSpeed = 0.0008
        end
      end
    end
  end
end

love.focus = function(focused)
  input.toggle_focus(focused)
end

love.keypressed = function(pressed_key)
  input.press(pressed_key)
end

love.keyreleased = function(released_key)
  input.release(released_key)
end

love.update = function(dt)
  if not input.paused then
    ship:update(dt)
    for _, entity in pairs(asteroids) do
      if entity.update then entity:update(dt) end
    end
    for _, entity in pairs(stars) do
      if entity.update then entity:update(dt) end
    end
    for _, entity in pairs(landables) do
      if entity.update then entity:update(ship,dt) end
    end
    camera1:follow(ship.body:getX(), ship.body:getY())
    camera1:update(dt)
    for _, star in ipairs(stars) do
      for _, asteroid in ipairs(asteroids) do
        star:gravitationalPull(asteroid)
      end
    end
    world:update(dt)
  end
end

love.draw = function()
  camera1:attach()
  for _, entity in pairs(asteroids) do
    if entity.draw then entity:draw() end
  end
  for _, entity in pairs(stars) do
    if entity.draw then entity:draw() end
  end
  for _, entity in ipairs(landables) do
    if entity.draw then entity:draw() end
  end
  ship:draw()
  camera1:detach()
  if ship.landedAt ~= nil then
    love.graphics.setColor(0,0,0,0.85)
    love.graphics.rectangle("fill",200,150,love.graphics.getWidth()-400,love.graphics.getHeight()-300)
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print("Docked at " .. ship.landedAt.name, 250, 180)

    love.graphics.print("Press Return to launch", 250, 260)

    if ship.landedAt:getTag() == "station" then
        love.graphics.print("• Trade • Repair • Missions • Market", 280, 320)
    else
        love.graphics.print("• Surface Info • Refuel • Talk to Locals • Missions", 280, 320)
    end
    if input.launch then
      ship:launch(ship.landedAt)
    end
  end

  love.graphics.print(
                      {{0.2,1,0.2,1},
                      "Ship mass:"..ship.mass..
                      "\nShip X:"..ship.body:getX()..
                      "\nShip Y:"..ship.body:getY()..
                      "\nShip angle:"..ship.body:getAngle()..
                      "\nShip angular velocity:"..ship.body:getAngularVelocity()..
                      "\nShip RCS:"..ship.rcs_text},
                      0,0,0,1,1)
end
