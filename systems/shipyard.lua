local Shipyard = {}

-- Set Flagship
function Shipyard.setFlagShip(player, fleet)
  if not fleet or fleet.flagShip then return end
  -- Troca flagship: desmarca a atual, marca a selecionada
  for _, e in ipairs(player.property.properties) do
      e.flagShip = false
  end
  fleet.flagShip = true
  return fleet
end
-- Retorna lista ordenada da frota do jogador
function Shipyard.getFleet(player)
  if not player or not player.property then return {} end
  local list = {}
  for _, property in pairs(player.property.properties) do
    if property.ship then
      table.insert(list, property)
    end
  end
  table.sort(list, function(a, b)
    if a.flagShip ~= b.flagShip then return a.flagShip end
    return (a.name or "") < (b.name or "")
  end)
  return list
end

-- Retorna lista ordenada do estoque da estação
function Shipyard.getStationStock(station)
    if not station then return {} end
    local data = config.Landables[station.name]
    local sy   = data and data.shipyard
    if not sy or not sy.stock then return {} end
    local list = {}
    for _, shipType in ipairs(sy.stock) do
        local def = config.Ships[shipType]
        if def then
            table.insert(list, { shipType = shipType, def = def })
        end
    end
    return list
end

-- Função auxiliar para calcular preço de revenda (70% do valor)
function Shipyard.getSellPrice(shipType)
    local def = config.Ships[shipType]
    return math.floor(def.price * 0.8)
end

function Shipyard.buyShip(player, shipType, customName)
  local def = config.Ships[shipType]

  if player.credits.amount < def.price then
      return false, "Insufficient credits!"
  end

  -- Cria a entidade da nave. 
  -- Note: x, y em (0,0) pois ela está "guardada" no player
  local newShip = { ship=true,
                    flagShip=false,
                    name=customName,
                    type=shipType,
                    cargo = {}
                  }
  player.credits.amount = player.credits.amount - def.price
  player.property:add(newShip)
  return true, "Ship bought"
end

function Shipyard.sellShip(player, shipEntity)
  --if shipEntity.isFlagShip then
  --    return false, "Can't sell flag ship."
  --end

  local price = Shipyard.getSellPrice(shipEntity.type)
  player.credits.amount = player.credits.amount + price
  player.property:remove(shipEntity)

  return true, "Ship sold"
end

return Shipyard
