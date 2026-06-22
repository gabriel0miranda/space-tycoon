local function randomPointOnOrbit(cx, cy, r, orbit_angle)
  if cx == nil or cy == nil or r == nil or orbit_angle == nil then return nil end
  local theta = love.math.random() * 2 * math.pi  -- ângulo aleatório na órbita

  -- Posição local na órbita (sem inclinação)
  local lx = math.cos(theta) * r
  local ly = math.sin(theta) * r

  -- Rotaciona pela inclinação da órbita
  local x = lx * math.cos(orbit_angle) - ly * math.sin(orbit_angle)
  local y = lx * math.sin(orbit_angle) + ly * math.cos(orbit_angle)

  print("Random point in orbit: "..cx+x.." and "..cy+y)
  return cx + x, cy + y
end

return function(star,landables)
  for _, landable in ipairs(landables or {}) do
    local landable_data = config.Landables[landable]
    local x,y = randomPointOnOrbit(star.x, star.y, landable_data.orbitRadius, landable_data.orbitAngle)
    if x ~= nil and y ~= nil then
      landable_data.x = x
      landable_data.y = y
    end
    local orbitRadius = landable.orbitRadius or math.sqrt((landable_data.x - star.x)^2 + (landable_data.y - star.y)^2)
    local orbitAngle = landable.orbitAngle or math.atan2(landable_data.y - star.y, landable_data.x - star.x)
    local sprite = config.SpriteComponent(landable_data.color,love.physics.newCircleShape(landable_data.x,landable_data.y,landable_data.radius),"Circle")
    local market = {
        generated = false,
        prices = {},
        capacity = landable_data.market and  landable_data.market.capacity or 0,
        stock = landable_data.market and landable_data.market.stock or {},
        demanded = landable_data.market and landable_data.market.demanded or {}
    }

    local shipyard = {
        generated = false,
        prices = {},
        stock = landable_data.shipyard and landable_data.shipyard.stock or {},
    }
    local orbitSpeed = landable_data.orbitSpeed or 0.0005
    config.Entities.create("landable",{
      name=landable,
      x=landable_data.x,
      y=landable_data.y,
      radius=landable_data.radius,
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

