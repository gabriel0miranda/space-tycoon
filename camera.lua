return function()

  local camera = {}
  camera.x = 0
  camera.y = 0
  camera.scale = 0.2
  camera.rotation = 0
  camera.smoothSpeed = 8
  camera.targetX = 0
  camera.targetY = 0

  camera.follow = function(self,tx,ty)
    self.targetX = tx
    self.targetY = ty
  end

  camera.update = function(self,dt)
    if config.Input.zoomIn then
      self.scale = self.scale + 0.8 * dt
    end
    if config.Input.zoomOut then
      self.scale = self.scale - 0.8 * dt
    end
    self.scale = math.max(0.1, math.min(3.0, self.scale))
    self.x = self.x + (self.targetX - self.x) * self.smoothSpeed * dt
    self.y = self.y + (self.targetY - self.y) * self.smoothSpeed * dt
  end

  camera.attach = function(self)
    love.graphics.push()
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.translate(w/2, h/2)
    love.graphics.scale(self.scale,self.scale)
    love.graphics.rotate(self.rotation)
    love.graphics.translate(-self.x,-self.y)
  end

  camera.detach = function(self)
    love.graphics.pop()
  end

  return camera
end
