local world = require('world')
local input = require('input')

return function(x_pos, y_pos, radius, name, type)
  local planet = {}
  planet.x = x_pos
  planet.y = y_pos
  planet.radius = radius
  planet.orbitAngle = 0
  planet.orbitSpeed = 0
  planet.orbitRadius = 0
  planet.name = name or "NO_INFO"
  planet.type = type or "NO_INFO"
  planet.color = {0,0,1}

  planet.draw = function(self)
    love.graphics.setColor(self.color)
    love.graphics.circle("fill",self.x,self.y,self.radius)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line",self.x,self.y,self.radius+6)
    love.graphics.setColor(1,1,1)
    love.graphics.print(self.name,self.x-80,self.y-self.radius-50,0,2,2)
  end

  planet.update = function(self,ship,dt)
    if self.orbitSpeed > 0 then
      self.orbitAngle = self.orbitAngle + self.orbitSpeed *dt
      self.x = 400 + self.orbitRadius * math.cos(self.orbitAngle)
      self.y = 300 + self.orbitRadius * math.sin(self.orbitAngle)
    end

    local sx, sy = ship.body:getX(),ship.body:getY()
    local dx = sx - self.x
    local dy = sy - self.y
    local dist = dx*dx + dy*dy

    if dist < (self.radius + 40)^2 and input.land then
      ship:landOn(self)
      input.land = false
    end
  end

  planet.getTag = function(self)
    return "planet"
  end

  return planet
end

