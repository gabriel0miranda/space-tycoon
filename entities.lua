local asteroid = require('entities/asteroid')
local star = require('entities/star')
local pause = require('entities/pause-text')
local ship = require('entities/ship')
local station = require('entities/station')
local planet = require('entities/planet')

local ASTEROID_MIN_RADIUS = 2000
local ASTEROID_MAX_RADIUS = 4000
local GRAVITY_CONSTANT = 5000

return function(asteroidNum, starNum)
  local entities = {}
  table.insert(entities,pause())
  table.insert(entities,star(400,300,10,50000))
  table.insert(entities,ship(400,400,100,200))
  table.insert(entities,station(1200, 600, 80, "Mining Depot", "mining"))
  table.insert(entities,station(-900, -400, 60, "Trading Station", "trading"))
  table.insert(entities,planet(200, -1100, 300, "Merle's Refuge", "rocky"))

  for _, entity in ipairs(entities) do
    local tag = entity:getTag()
    if tag == "station" or tag == "planet" then
      entity.orbitRadius = math.sqrt((entity.x - 400)^2 + (entity.y - 300)^2)
      entity.orbitAngle = math.atan2(entity.y - 300, entity.x - 400)
      entity.orbitSpeed = 0.0008
    end
  end


  for i = 1, asteroidNum do
    local theta = love.math.random() * 2 * math.pi
    local r_sq = ASTEROID_MIN_RADIUS^2 + love.math.random() * (ASTEROID_MAX_RADIUS^2 - ASTEROID_MIN_RADIUS^2)
    local r = ASTEROID_MIN_RADIUS + love.math.random() * (ASTEROID_MAX_RADIUS - ASTEROID_MIN_RADIUS)
    --local r = math.sqrt(r_sq)

    local x = 400 + r * math.cos(theta)
    local y = 300 + r * math.sin(theta)

    local GM = GRAVITY_CONSTANT * 50000
    local orbital_speed = math.sqrt(GM/r)

    local vx = -math.sin(theta) * orbital_speed
    local vy = math.cos(theta) * orbital_speed

    table.insert(entities,asteroid(x,y,vx,vy))
  end

  return entities
end
