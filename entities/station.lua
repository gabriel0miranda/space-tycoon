local world = require('world')
local input = require('input')

return function(x_pos, y_pos, radius, name, type)
  local station = {}
  station.x = x_pos
  station.y = y_pos
  station.radius = radius
  station.orbitAngle = 0
  station.orbitSpeed = 0
  station.orbitRadius = 0
  station.name = name or "NO_INFO"
  station.type = type or "NO_INFO"
  station.color = {1,0,0}

  station.draw = function(self)
    love.graphics.setColor(self.color)
    love.graphics.circle("fill",self.x,self.y,self.radius)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line",self.x,self.y,self.radius+6)
    love.graphics.setColor(1,1,1)
    love.graphics.print(self.name,self.x-80,self.y-self.radius-50,0,2,2)
  end

  station.update = function(self,ship,dt)
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

  station.getTag = function(self)
    return "station"
  end

  return station
end

