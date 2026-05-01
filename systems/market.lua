local Market = {}

-- Preço base global por item (fallback se a estação não definir)
local function getBasePrices()
  local basePrices = {}
  for _, item in pairs(config.Items) do
    basePrices[item.name] = item.basePrice
  end
  return basePrices
end

-- Gera o inventário e os preços de uma estação ao entrar nela
function Market.generateStock(station)
    local market = station.market
    if not market or market.generated then return end

    -- Inicializa o inventário se não existir
    if not station.inventory then
        station.inventory = config.InventoryComponent(market.capacity or 10000)
    end

    for _, entry in ipairs(market.stock or {}) do
        local qty = entry.min + math.floor(love.math.random() * (entry.max - entry.min))
        station.inventory:add(entry.item, qty)
    end

    -- Gera tabela de preços de compra e venda
    -- A estação compra mais caro os itens que ela valoriza (demanded)
    local prices = {}
    for item, basePrice in pairs(getBasePrices()) do
        local demand    = market.demanded and market.demanded[item] or 1.0
        local buyPrice  = math.floor(basePrice * demand * (0.9 + love.math.random() * 0.2))
        local sellPrice = math.floor(basePrice * 0.8 * (0.9 + love.math.random() * 0.2))
        prices[item] = {
            buy  = buyPrice,   -- preço que a estação paga ao jogador
            sell = sellPrice,  -- preço que a estação cobra do jogador
        }
    end

    station.market.prices = prices
    station.market.generated = true
end

-- Calcula o balanço de uma troca
-- offering: { {item, qty}, ... } — o que o jogador oferece
-- requesting: { {item, qty}, ... } — o que o jogador quer
-- Retorna: balanço em créditos (positivo = jogador recebe, negativo = jogador paga)
function Market.calculateBalance(station, offering, requesting)
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
function Market.executeTrade(station, ship, offering, requesting)
    local balance = Market.calculateBalance(station, offering, requesting)
    local player = config.Entities.getByTag("player")[1]

    -- Verifica se jogador tem créditos suficientes
    if balance < 0 and player.credits.amount < -balance then
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
        station.inventory:add(o.item, o.qty)
    end
    for _, r in ipairs(requesting) do
        station.inventory:remove(r.item, r.qty)
        ship.inventory:add(r.item, r.qty)
    end
    player.credits:add(balance)

    return true, balance
end

return Market
