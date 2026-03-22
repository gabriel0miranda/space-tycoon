local world = require('world')
local input = require('input')

return function(xpos,ypos,linearAcceleration,angularAcceleration)
  local ship = {}
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

  ship.draw = function(self)
    local rcs_text
    if input.rcs == true then
      rcs_text = "true"
    else
      rcs_text = "false"
    end
    love.graphics.setColor(131, 192, 240)
    love.graphics.polygon('line', self.body:getWorldPoints(self.shape:getPoints()))
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
    ship.body:setLinearVelocity(0,0)
    print("Landed on "..landable.name.."!")
  end

  ship.getTag = function(self)
    return "ship"
  end

  return ship
end
