local Floatsome = {}

function Floatsome.update(dt)
  for _, floatsome in ipairs(config.Entities.getByTag("floatsome")) do
    if floatsome.lifetime > 0 then
      floatsome.x = floatsome.x + floatsome.vx * dt
      floatsome.y = floatsome.y + floatsome.vy * dt
      floatsome.lifetime = floatsome.lifetime - dt
    else
      config.Entities.remove(floatsome)
    end
  end
end

return Floatsome
