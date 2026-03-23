local world = require('world')
local MIN_DISTANCE = 800
local GRAVITY_CONSTANT = 5000

return function(xpos,ypos,radius,mass)
  local star = {}
  star.x = xpos
  star.y = ypos
  star.radius = radius
  star.body = love.physics.newBody(world, xpos, ypos, 'static')
  star.shape = love.physics.newCircleShape(radius)
  star.fixture = love.physics.newFixture(star.body, star.shape)
  star.mass = mass
  star.fixture:setUserData(star)

  star.draw = function(self)
    local starx, stary = star.body:getWorldCenter()
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", starx, stary ,star.shape:getRadius())
  end

  star.gravitationalPull = function(self,body)
    if not body or body.body:isDestroyed() then return end
    local sx, sy = self.body:getPosition()
    local ax, ay = body.body:getPosition()

    local dx = sx - ax
    local dy = sy - ay
    local distSq = dx*dx + dy*dy

    if distSq < MIN_DISTANCE * MIN_DISTANCE then
      return
    end

    local force = GRAVITY_CONSTANT * self.mass * body.body:getMass() / distSq

    local dist = math.sqrt(distSq)
    local fx = (dx/dist) * force
    local fy = (dy/dist) * force

    local pullStrength = force / 2000
    body.glow = math.min(1,pullStrength)
    body.body:applyForce(fx, fy)
  end

  star.getTag = function(self)
    return "star"
  end

  return star
end
