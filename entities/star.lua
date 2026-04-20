return function(starX,starY,starMass,starRadius,starColor)
  config.Entities.create("star", {
    x = starX or 0,
    y = starY or 0,
    mass = starMass or 50000,
    radius = starRadius or 30,
    sprite = config.SpriteComponent(starColor,love.physics.newCircleShape(starRadius or 30), "Circle"),
    layer = 0
  })
end
