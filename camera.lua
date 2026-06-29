return function()

  local camera = {}
  camera.x = 0
  camera.y = 0
  camera.scale = 1
  camera.rotation = 0
  camera.smoothSpeed = 8
  camera.targetX = 0
  camera.targetY = 0

  camera.follow = function(self,tx,ty)
    self.targetX = tx
    self.targetY = ty
  end

  camera.update = function(self,dt)
    if config.Input.state.zoomIn then
      self.scale = self.scale + 0.8 * dt
    end
    if config.Input.state.zoomOut then
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

  camera.toWorld = function(self, sx, sy)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- 1. Remove a translação do centro da tela
    local dx = sx - w / 2
    local dy = sy - h / 2
    -- 2. Remove o zoom
    dx = dx / self.scale
    dy = dy / self.scale
    -- 3. Remove a rotação (se houver)
    if self.rotation ~= 0 then
      local cos = math.cos(-self.rotation)
      local sin = math.sin(-self.rotation)
      dx, dy = dx * cos - dy * sin, dx * sin + dy * cos
    end
    -- 4. Adiciona a posição da câmera no mundo
    return dx + self.x, dy + self.y
  end

  camera.toScreen = function(self, wx, wy)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- 1. Remove posição da câmera
    local dx = wx - self.x
    local dy = wy - self.y
    -- 2. Aplica rotação
    if self.rotation ~= 0 then
      local cos = math.cos(self.rotation)
      local sin = math.sin(self.rotation)
      dx, dy = dx * cos - dy * sin, dx * sin + dy * cos
    end
    -- 3. Aplica zoom
    dx = dx * self.scale
    dy = dy * self.scale
    -- 4. Translada para o centro da tela
    return dx + w / 2, dy + h / 2
  end

  camera.detach = function(self)
    love.graphics.pop()
  end

  return camera
end
