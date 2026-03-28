local GravityPull = {}

function GravityPull.update(dt)
  local starsList = Entities.with("star")
  local asteroidsList = Entities.with("asteroid")
  for _, star in ipairs(starsList) do
    for _, ast in ipairs(asteroidsList) do
      if not ast.rigidbody or not ast.rigidbody.body or ast.rigidbody.body:isDestroyed() then
        goto continue
      end
      local sx, sy = star.x, star.y
      local ax, ay = ast.rigidbody.body:getPosition()

      local dx = sx - ax
      local dy = sy - ay
      local distSq = dx*dx + dy*dy

      if distSq < MIN_DISTANCE * MIN_DISTANCE then
        goto continue
      end

      local force = GRAVITY_CONSTANT * star.mass * ast.rigidbody.body:getMass() / distSq

      local dist = math.sqrt(distSq)
      local fx = (dx/dist) * force
      local fy = (dy/dist) * force

      local pullStrength = force / 2000
      ast.glow = math.min(1,pullStrength)
      ast.rigidbody.body:applyForce(fx, fy)

      local distFromStar = dist
      if distFromStar > MAX_ORBIT_RADIUS then
        local excess = distFromStar - MAX_ORBIT_RADIUS
        local returnForce = excess * ast.rigidbody.body:getMass()
        local returnFX = (dx / dist) * returnForce
        local returnFY = (dy / dist) * returnForce
        ast.rigidbody.body:applyForce(returnFX, returnFY)
        -- Optional: add a tiny bit of drag when they're far out
        local vx, vy = ast.rigidbody.body:getLinearVelocity()
        ast.rigidbody.body:applyForce(-vx * 0.4, -vy * 0.4)
      end
      ::continue::
    end
  end
end

return GravityPull
