return function(wormholes)
  for _, data in ipairs(wormholes or {}) do
    data.sprite = config.SpriteComponent({0.5, 0.8, 1}, love.physics.newCircleShape(data.x, data.y, 120), "Circle")
    data.radius = 100
    data.layer = 0
    config.Entities.create("landable", data)
  end
end

