local ExplosionSystem = {}

function ExplosionSystem.update(dt)
  for _, explosion in ipairs(config.Entities.getByTag("explosion")) do
    if explosion.duration and explosion.duration <= 0 then
      config.Entities.remove(explosion)
    else
      explosion.duration = explosion.duration - dt
    end
  end
end

return ExplosionSystem
