local Shipyard = {}

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
  local newShip = config.ShipEntity(0, 0, player.name, false, customName, shipType)
  player.credits.amount = player.credits.amount - def.price
  player.property:add(newShip)
  return true, "Ship bought"
end

function Shipyard.sellShip(player, shipEntity)
  --if shipEntity.isFlagShip then
  --    return false, "Can't sell flag ship."
  --end

  local price = Shipyard.getSellPrice(shipEntity.sprite.shipType)
  player.credits.amount = player.credits.amount + price
  player.property:remove(shipEntity)

  return true, "Ship sold"
end

return Shipyard
