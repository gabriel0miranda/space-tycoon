local Rendering = {}

local function drawWorldLayer()
  -- Draw all entities that have a draw method
  for _, entity in ipairs(Entities.all) do
    if entity.draw then
      entity:draw()
    elseif entity.sprite then
      love.graphics.setColor(entity.sprite.color)
      if entity.sprite.shapeType == "Polygon" then
        love.graphics.polygon("fill",entity.rigidbody.body:getWorldPoints(entity.sprite.shape:getPoints()))
      elseif entity.sprite.shapeType == "Circle" then
        if entity.rigidbody then
          love.graphics.circle('fill', entity.rigidbody.body:getX(), entity.rigidbody.body:getY(), entity.sprite.shape:getRadius())
        else
          love.graphics.circle('fill', entity.x, entity.y, entity.sprite.shape:getRadius())
        end
      end
    end
  end
end

local function drawDebugOverlay()
  if not input.debug then return end
  local ship = Entities.with("ship")[1]
  love.graphics.setColor(0, 1, 0)
  love.graphics.setFont(smallFont)
  love.graphics.print(
    "Ship mass:"..ship.mass..
    "\nShip X:"..ship.rigidbody.body:getX()..
    "\nShip Y:"..ship.rigidbody.body:getY()..
    "\nShip angle:"..ship.rigidbody.body:getAngle()..
    "\nShip angular velocity:"..ship.rigidbody.body:getAngularVelocity()..
    "\nShip RCS:"..tostring(ship.rcs)
  )
end

function Rendering.draw(camera)
    camera:attach()
        drawWorldLayer()
        -- drawParallaxBackground()
        -- drawParticles()
        -- drawBullets()
    camera:detach()
    drawDebugOverlay()
end

return Rendering
