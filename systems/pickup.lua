local Pickup = {}

function Pickup.update(dt, player, entities)
    local px, py = player.rigidbody.body:getX(), player.rigidbody.body:getY()

    for _, e in ipairs(entities) do
        if e then
            if e.drift and e.drift > 0 then
              e.x = e.x + (e.vx or 0) * dt
              e.y = e.y + (e.vy or 0) * dt
            end
            local dx = e.x - px
            local dy = e.y - py
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist < e.radius + 50 then
                local ok, _ = player.inventory:add(e.item, e.qty, config.Items[e.item].volume or 1)
                if ok then
                    config.Entities.remove(e)
                end
            end
        end
    end
end

return Pickup
