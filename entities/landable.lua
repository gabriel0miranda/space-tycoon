return function(star,landables)
  for _, landable in ipairs(landables or {}) do
    local orbitRadius = math.sqrt((config.Landables[landable].x - star.x)^2 + (config.Landables[landable].y - star.y)^2)
    local orbitAngle = math.atan2(config.Landables[landable].y - star.y, config.Landables[landable].x - star.x)
    local sprite = config.SpriteComponent(config.Landables[landable].color,love.physics.newCircleShape(config.Landables[landable].x,config.Landables[landable].y,config.Landables[landable].radius),"Circle")
    local market = {
        generated = false,
        prices = {},
        capacity = config.Landables[landable].market and  config.Landables[landable].market.capacity or 0,
        stock = config.Landables[landable].market and config.Landables[landable].market.stock or {},
        demanded = config.Landables[landable].market and config.Landables[landable].market.demanded or {}
    }

    local shipyard = {
        generated = false,
        prices = {},
        stock = config.Landables[landable].shipyard and config.Landables[landable].shipyard.stock or {},
    }
    local orbitSpeed = 0.0008
    config.Entities.create("landable",{
      name=landable,
      x=config.Landables[landable].x,
      y=config.Landables[landable].y,
      radius=config.Landables[landable].radius,
      sprite=sprite,
      market=market,
      shipyard=shipyard,
      orbitRadius=orbitRadius,
      orbitAngle=orbitAngle,
      orbitSpeed=orbitSpeed,
      layer = 0
    })
  end
end

