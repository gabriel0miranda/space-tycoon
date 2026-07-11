local POPULATION_MARGIN = 12

return function (population)
  local totalNPCNumber = 0
  local popDensity = population or {["Hauler"]=0.001}
  for npc, pop in pairs(popDensity) do
    local npc_population = math.floor(pop*36000)
    local rng = love.math.newRandomGenerator(os.time())
    local npcCount = math.ceil(rng:random(npc_population*(1-(POPULATION_MARGIN/100)),npc_population))
    totalNPCNumber = totalNPCNumber + npcCount
    local currentNPCNumber = #config.Entities.getByTag("npc")
    for i=currentNPCNumber+1, currentNPCNumber + npcCount, 1 do
      local x, y = rng:random(-6000,6000), rng:random(-6000,6000)
      local shipType = config.NpcProfiles[npc].ship
      local shipName = shipType or config.NpcProfiles[npc].ship
      local def = config.Ships[shipType]
      local id = i
      local cargo = function()
        local volume = 0
        local currentCargo = {}
        for item, data in pairs(config.Items) do
          local moeda = rng:random(0,1)
          if moeda == 1 then
            local quantidade = rng:random(1,def.cargo/data.volume)
            volume = volume + quantidade*data.volume
            if volume < def.cargo then
              currentCargo[item] = quantidade
            end
          end
        end
        return currentCargo
      end

      config.Entities.create("npc", {
        profile = config.NpcProfiles[npc],
        name = npc,
        id = id,
        ai = config.AIComponent({
          state = "idle",           -- estado atual da FSM
          target = nil,             -- entidade alvo
          timer = 0,                -- timer genérico (patrol, cooldown)
          faction = config.NpcProfiles[npc].faction,
          aggressiveTowardsPlayer = config.NpcProfiles[npc].aggressiveTowardsPlayer
        }),
        ship = config.ShipEntity(x, y, id, false, shipName, shipType, nil, config.Ships[shipType].weapons, cargo())
      })
    end
  end
  if config.Input.state.debugFlag then
    print("NPCs criados: "..totalNPCNumber)
  end
end
