local DEFAULT_VARIANCE = 12

local function resolveCategoryWeight(profile, categoryWeights)
  local weight = 1
  local matched = false

  for fieldName, rule in pairs(categoryWeights) do
    local fieldValue = profile[fieldName]

    if type(rule) == "number" then
      if fieldValue == true then
        weight = weight * rule
        matched = true
      end
    elseif type(rule) == "table" then
      if fieldValue ~= nil and rule[fieldValue] ~= nil then
        weight = weight * rule[fieldValue]
        matched = true
      end
    end
  end

  return weight, matched
end

return function (populationConfig)
  populationConfig = populationConfig or {}
  local weights = populationConfig.weights or {}
  local categoryWeights = populationConfig.categoryWeights or {}
  local variance = populationConfig.variance or DEFAULT_VARIANCE

  local rng = love.math.newRandomGenerator(os.time()) -- seed única, fora do loop

  local totalNPCNumber = 0

  for npcType, profile in pairs(config.NpcProfiles) do
    local base = profile.baseDensity or 0

    if base > 0 then
      local weight
      if weights[npcType] ~= nil then
        weight = weights[npcType]
      else
        local categoryWeight, matched = resolveCategoryWeight(profile, categoryWeights)
        weight = matched and categoryWeight or 0
      end

      local finalDensity = base * weight
      local npc_population = math.floor(finalDensity * 36000)

      if npc_population > 0 then
        local npcCount = math.ceil(rng:random(npc_population * (1 - (variance/100)), npc_population))
        totalNPCNumber = totalNPCNumber + npcCount

        local currentNPCNumber = #config.Entities.getByTag("npc")
        for i = currentNPCNumber+1, currentNPCNumber + npcCount, 1 do
          local x, y = rng:random(-6000, 6000), rng:random(-6000, 6000)
          local shipType = profile.ship
          local def = config.Ships[shipType]
          local id = i

          local cargo = function()
            local volume = 0
            local currentCargo = {}
            for item, data in pairs(config.Items) do
              local moeda = rng:random(0, 1)
              if moeda == 1 then
                local quantidade = rng:random(1, def.cargo / data.volume)
                volume = volume + quantidade * data.volume
                if volume < def.cargo then
                  currentCargo[item] = quantidade
                end
              end
            end
            return currentCargo
          end

          config.Entities.create("npc", {
            profile = profile,
            name = npcType,
            id = id,
            ai = config.AIComponent({
              state = "idle",
              target = nil,
              timer = 0,
              faction = profile.faction,
              aggressive = profile.aggressive
            }),
            ship = config.ShipEntity(x, y, id, false, shipType, shipType, nil, def.weapons, cargo())
          })
        end
      end
    end
  end

  if config.Input.state.debugFlag then
    print("NPCs criados: " .. totalNPCNumber)
  end
end
