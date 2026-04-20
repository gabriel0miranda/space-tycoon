local Shipyard = {}

-- Preço base global por item (fallback se a estação não definir)
local function getBasePrices()
  local basePrices = {}
  for _, item in pairs(config.Ships) do
    basePrices[item.name] = item.price
  end
  return basePrices
end

-- Gera o inventário e os preços de uma estação ao entrar nela
function Shipyard.generateStock(station)
    local shipyard = station.shipyard
    if not shipyard or shipyard.generated then return end

    -- Gera tabela de preços de compra e venda
    -- A estação compra mais caro os itens que ela valoriza (demanded)
    local prices = {}
    for item, basePrice in pairs(getBasePrices()) do
        local buyPrice  = math.floor(basePrice * (0.9 + love.math.random() * 0.2))
        local sellPrice = math.floor(basePrice * 0.8 * (0.9 + love.math.random() * 0.2))
        prices[item] = {
            buy  = buyPrice,   -- preço que a estação paga ao jogador
            sell = sellPrice,  -- preço que a estação cobra do jogador
        }
    end

    station.shipyard.prices = prices
    station.shipyard.generated = true
end

-- Calcula o balanço de uma troca
-- offering: { {item, qty}, ... } — o que o jogador oferece
-- requesting: { {item, qty}, ... } — o que o jogador quer
-- Retorna: balanço em créditos (positivo = jogador recebe, negativo = jogador paga)
function Shipyard.calculateBalance(station, offering, requesting)
    local balance = 0
    for _, o in ipairs(offering) do
        local price = station.market.prices and station.market.prices[o.item]
        balance = balance + (price and price.buy or 0) * o.qty
    end
    for _, r in ipairs(requesting) do
        local price = station.market.prices and station.market.prices[r.item]
        balance = balance - (price and price.sell or 0) * r.qty
    end
    return balance
end

-- Executa a troca se válida
function Shipyard.executeTrade(station, ship, offering, requesting)
    local balance = Shipyard.calculateBalance(station, offering, requesting)

    -- Verifica se jogador tem créditos suficientes
    if balance < 0 and ship.credits.amount < -balance then
        return false, "Créditos insuficientes"
    end

    -- Verifica se estação tem os itens pedidos
    for _, r in ipairs(requesting) do
        if not station.inventory:has(r.item, r.qty) then
            return false, "Estação não tem " .. r.item
        end
    end

    -- Verifica se jogador tem os itens oferecidos
    for _, o in ipairs(offering) do
        if not ship.inventory:has(o.item, o.qty) then
            return false, "Você não tem " .. o.item
        end
    end

    -- Executa
    for _, o in ipairs(offering) do
        ship.inventory:remove(o.item, o.qty)
        station.inventory:add(o.item, o.qty, 1)
    end
    for _, r in ipairs(requesting) do
        station.inventory:remove(r.item, r.qty)
        ship.inventory:add(r.item, r.qty, 1)
    end
    ship.credits:add(balance)

    return true, balance
end

return Shipyard
