local Pickup = {}

function Pickup.update(dt, floatsome_hash)
  local ships = config.Entities.getByTag("ship")
  for _, ship in ipairs(ships) do
    local sx, sy = ship.rigidbody.body:getPosition()
    local sr = ship.rigidbody.fixture:getShape():getRadius()
    local candidates = config.SpatialHash.query(floatsome_hash,config.CELL_SIZE,sx,sy,sr+50) or {}

    for _, e in ipairs(candidates) do
      if e then
        if e.drift and e.drift > 0 then
          e.x = e.x + (e.vx or 0) * dt
          e.y = e.y + (e.vy or 0) * dt
        end
        local dx = e.x - sx
        local dy = e.y - sy
        local dist = math.sqrt(dx*dx + dy*dy)

        if dist < e.radius + 50 then
          local ok, _ = ship.inventory:add(e.item, e.qty)
          if ok then
            config.Entities.remove(e)
          end
        end
      end
    end
  end
end

return Pickup
