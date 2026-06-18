local begin_contact_callback = function(fixture_a, fixture_b, contact)
end

local end_contact_callback = function(fixture_a, fixture_b, contact)
end

local pre_solve_callback = function(fixture_a, fixture_b, contact)
end

local post_solve_callback = function(fixture_a, fixture_b, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
    local a = fixture_a:getUserData()
    local b = fixture_b:getUserData()
    if not a or not b then return end

    local isShipAst = (a.tag == "ship" and b.tag == "asteroid")
    local isAstShip = (a.tag == "asteroid" and b.tag == "ship")
    if not isShipAst and not isAstShip then return end

    -- O impulso normal é a "força" real da batida — já incorpora massa e velocidade
    -- Dois pontos de contato são possíveis (normal_impulse1 e 2), soma os dois
    local totalImpulse = normal_impulse1 + (normal_impulse2 or 0)

    -- Limiar mínimo: ignora roçadas suaves (ajuste ao gosto)
    local threshold = 50
    if totalImpulse < threshold then return end

    local ship = isShipAst and a or b

    -- Escala o dano pelo impulso — divida por uma constante para tunar a severidade
    local damage = totalImpulse / 50

    config.DamageSystem.apply(ship, damage * 0.5, damage)  -- colisão bate mais no casco
end

local world = love.physics.newWorld(0, 0)

world:setCallbacks(
  begin_contact_callback,
  nil, --end_contact_callback
  nil, --pre_solve_callback
  post_solve_callback
)

return world
