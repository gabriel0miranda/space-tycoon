local Mining = {}

local STAGES = 4

function Mining.damage(asteroid, damage)
    local mineable = asteroid.mineable
    if not mineable then return end

    mineable.health = mineable.health - damage

    -- Reduz escala visual proporcionalmente
    local pct = math.max(0, mineable.health / mineable.max_health)
    local currentStage = math.ceil(pct * STAGES)
    if currentStage ~= mineable.stage then
      mineable.stage = currentStage
      local visualPct = currentStage / STAGES
      local newRadius = mineable.originalRadius * visualPct
      asteroid.sprite.shape:setRadius(newRadius)
      -- Recria o fixture para a hitbox bater com o visual
      asteroid.rigidbody.fixture:destroy()
      asteroid.rigidbody.fixture = love.physics.newFixture(asteroid.rigidbody.body, asteroid.sprite.shape)
      asteroid.rigidbody.body:setMass(asteroid.mineable.originalMass)
      asteroid.rigidbody.fixture:setRestitution(0.3)
    end

    -- Dropa uma parte dos minérios proporcionalmente ao dano
    Mining.drop_loot(asteroid, damage / mineable.max_health)

    if mineable.health <= 0 then
        Mining.destroy(asteroid)
    end
end

function Mining.drop_loot(asteroid, fraction)
    for _, entry in ipairs(asteroid.mineable.loot_table) do
        local qty = math.random(entry.min, entry.max)
        qty = math.max(1, math.floor(qty * fraction))
        local radius = math.max(5,math.floor(qty))
        local color = entry.item == "Iron Ore" and {208/255, 207/255, 203/255} or {123/255, 28/255, 41/255}
        -- Cria entidade de minério flutuando na posição do asteroide
        local avx, avy = asteroid.rigidbody.body:getLinearVelocity()
        local angle = love.math.random() * 2 * math.pi
        local speed = love.math.random(10, 40)
        local offset = asteroid.mineable.originalRadius * 0.5
        local ore = Entities.create("ore", {
          type = entry.item,
          qty = qty,
          volume = require("data.items")[entry.item].volume or 1,
          x = asteroid.rigidbody.body:getX() + math.cos(angle)*offset,
          y = asteroid.rigidbody.body:getY() + math.cos(angle)*offset,
          vx = avx + math.cos(angle) * speed,
          vy = avy + math.sin(angle) * speed,
          radius = radius,
          sprite = require("components.sprite")(color,
            love.physics.newCircleShape(radius),
            "Circle"
            )
          }
        )
        table.insert(asteroid.mineable.debris, ore)
    end
end

function Mining.destroy(asteroid)
    -- Remove o asteroide e deixa todo o loot restante
    Mining.drop_loot(asteroid, 1.0)
    Entities.remove(asteroid)
end

return Mining
