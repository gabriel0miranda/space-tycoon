local world = require('world')

return function(x_pos, y_pos, vx, vy)
  local asteroid = {}
  local size = love.math.random(5,50)
  asteroid.body = love.physics.newBody(world, x_pos, y_pos, 'dynamic')
  asteroid.body:setMass((4/3)*math.pi*(size)^3)
  asteroid.body:setLinearVelocity(vx,vy)
  asteroid.shape = love.physics.newCircleShape(size)
  asteroid.fixture = love.physics.newFixture(asteroid.body, asteroid.shape)
  asteroid.fixture:setRestitution(0.3)
  asteroid.fixture:setUserData(asteroid)
  asteroid.glow = 0

  asteroid.draw = function(self)
    local entity_x, entity_y = asteroid.body:getWorldCenter()
    love.graphics.setColor(70/100 + self.glow * 20/100, 80/100, 59/100)
    love.graphics.circle('fill', entity_x, entity_y, asteroid.shape:getRadius())
  end

  asteroid.getTag = function(self)
    return "asteroid"
  end

  return asteroid
end

