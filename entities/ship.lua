local world = require('world')
local input = require('input')

return function(xpos,ypos,linearAcceleration,angularAcceleration)
  local ship = {}
  ship.x = xpos
  ship.y = ypos
  ship.mass = 100
  ship.linearAcceleration = linearAcceleration
  ship.angularAcceleration = angularAcceleration
  ship.strafeAcceleration = angularAcceleration/2
  ship.body = love.physics.newBody(world, xpos, ypos, 'dynamic')
  ship.body.setMass(ship.body, 100)
  ship.body.setAngle(ship.body,0)
  ship.rcsStrenght = 0.4
  ship.rcsMaxStrenght = 300
  ship.landedAt = nil
  ship.shape = love.physics.newPolygonShape(0, -25, 50, 0, 0, 25)
  ship.fixture = love.physics.newFixture(ship.body, ship.shape)
  ship.fixture:setRestitution(0.75)
  ship.fixture:setUserData(ship)
  ship.rcs_text = "true"

  ship.draw = function(self)
    if input.rcs == false then
      ship.rcs_text = "false"
    else
      ship.rcs_text = "true"
    end
    love.graphics.setColor(255/255, 200/255, 48/255)
    love.graphics.polygon('fill', self.body:getWorldPoints(self.shape:getPoints()))
  end

  ship.update = function(self,dt)
    local angle = self.body:getAngle()
    local fx = math.cos(angle)
    local fy = math.sin(angle)
    local lx = math.sin(angle)
    local ly = -math.cos(angle)
    local thrust = self.linearAcceleration * dt * 60
    local strafe = self.strafeAcceleration * dt * 60
    local torque = self.angularAcceleration * dt * 60

    if input.left then
      self.body:applyForce(lx * strafe, ly * strafe)
    elseif input.right then
      self.body:applyForce(-lx * strafe, -ly * strafe)
    end
    if input.up then
      self.body:applyForce(fx * thrust, fy * thrust)
    elseif input.down then
      self.body:applyForce(-fx * thrust, -fy * thrust)
    end
    if input.rotateLeft then
      self.body:applyTorque(-torque)
    elseif input.rotateRight then
      self.body:applyTorque(torque)
    elseif input.rcs then
      local I_approx = self.body:getMass() * (5*5 / 2)
      self.body:applyAngularImpulse(-I_approx * self.body:getAngularVelocity())
    end

    if input.rcs then
      local vx, vy = self.body:getLinearVelocity()
      local oposeX = -vx * self.rcsStrenght
      local oposeY = -vy * self.rcsStrenght
      local mag = math.sqrt(oposeX^2 + oposeY^2)
      if mag > self.rcsMaxStrenght then
        local scale = self.rcsMaxStrenght / mag
        oposeX = oposeX * scale
        oposeY = oposeY * scale
      end
      self.body:applyForce(oposeX, oposeY)
    end
  end

  ship.landOn = function(self, landable)
    self.landedAt = landable
    self.body:setLinearVelocity(0,0)
    input.paused = true
    print("Landed on "..landable.name.."!")
  end

  ship.launch = function(self, landable)
    local angle = math.rad(love.math.random(360))
    local fx = math.cos(angle)
    local fy = math.sin(angle)
    local lx = math.sin(angle)
    local ly = -math.cos(angle)
    local thrust = self.linearAcceleration * 2
    self.landedAt = nil
    input.paused = false
    self.body:setAngle(angle)
    self.body:setPosition(love.math.random(-landable.radius,landable.radius)+landable.x,love.math.random(-landable.radius,landable.radius)+landable.y)
    self.body:setLinearVelocity(fx * thrust, fy * thrust)
    print("Launched from "..landable.name.."!")
  end

  ship.getTag = function(self)
    return "ship"
  end

  return ship
end
