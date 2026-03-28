local InventoryUI = require("ui.inventory_ui")
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

local function drawProjectiles()
  for _, proj in ipairs(Entities.with("projectile")) do
    love.graphics.setColor(proj.color)
    if proj.projType == "missile" then
      -- Míssil: um retângulo orientado na direção do movimento
      local angle = math.atan2(proj.vy, proj.vx)
      love.graphics.push()
        love.graphics.translate(proj.x, proj.y)
        love.graphics.rotate(angle)
        love.graphics.rectangle("fill", -proj.size * 2, -proj.size / 2, proj.size * 4, proj.size)
      love.graphics.pop()
    else
      -- Laser/bala: círculo simples
      love.graphics.circle("fill", proj.x, proj.y, proj.size)
    end
  end
end

local function drawDrillEffect()
  local armed = Entities.with("weapon")
  for _, e in ipairs(armed) do
    local weapon = e.weapon
    if weapon.def.type == "drill" and weapon.firing and weapon.timer > 0 then
      local x, y = e.rigidbody.body:getPosition()
      local tx = x + math.cos(weapon.angle) * weapon.def.range
      local ty = y + math.sin(weapon.angle) * weapon.def.range
      -- Pulsa com base no cooldown restante
      local alpha = weapon.timer / weapon.def.cooldown
      love.graphics.setColor(weapon.def.color[1], weapon.def.color[2], weapon.def.color[3], alpha)
      love.graphics.setLineWidth(3)
      love.graphics.line(x, y, tx, ty)
      love.graphics.circle("fill", tx, ty, weapon.def.size * alpha)
      love.graphics.setLineWidth(1)
    end
  end
end

local function drawInventory()
  InventoryUI.draw()
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
    "\nShip RCS:"..tostring(ship.rcs)..
    "\nShip weapon:"..ship.weapon.def.type
  )
end

function Rendering.draw(camera)
    camera:attach()
        drawWorldLayer()
        -- drawParallaxBackground()
        drawProjectiles()
        drawDrillEffect()
    camera:detach()
    drawInventory()
    drawDebugOverlay()
end


return Rendering
