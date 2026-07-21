local Market = {}

-- Preço base global por item (fallback)
local function getBasePrices()
  local basePrices = {}
  for item, data in pairs(config.Items) do
    basePrices[item] = data.basePrice
  end
  return basePrices
end

function Market.generateStock(trader)
  local market = {}
  if not trader.market then
    trader.market = {}
    trader.market.capacity = trader.inventory.capacity or 100
    trader.market.stock = {}
    for item, qty in pairs(trader.inventory.items) do
      table.insert(trader.market.stock,{item=item,min=qty,max=qty})
    end
  end
  market = trader.market
  if market.generated then return end

  -- Inicializa o inventário se não existir
  if not trader.inventory then
    trader.inventory = config.InventoryComponent(market.capacity or 10000)
  end

  for _, entry in ipairs(market.stock or {}) do
    local qty = entry.min + math.floor(love.math.random() * (entry.max - entry.min))
    trader.inventory:add(entry.item, qty)
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

  trader.market.prices = prices
  trader.market.generated = true
  if config.Input.state.debugFlag then
    config.DumpTable(market)
  end
end

-- Calcula o balanço de uma troca
-- offering: { {item, qty}, ... } — o que o jogador oferece
-- requesting: { {item, qty}, ... } — o que o jogador quer
-- Retorna: balanço em créditos (positivo = jogador recebe, negativo = jogador paga)
function Market.calculateBalance(trader, offering, requesting)
    local balance = 0
    for _, o in ipairs(offering) do
        local price = trader.market.prices and trader.market.prices[o.item]
        balance = balance + (price and price.buy or 0) * o.qty
    end
    for _, r in ipairs(requesting) do
        local price = trader.market.prices and trader.market.prices[r.item]
        balance = balance - (price and price.sell or 0) * r.qty
    end
    if config.Input.state.debugFlag then
      print("BALANCE: "..balance)
    end
    return balance
end

-- Executa a troca se válida
function Market.executeTrade(trader, ship, offering, requesting)
    local balance = Market.calculateBalance(trader, offering, requesting)
    local player = config.Entities.getByTag("player")[1]

    -- Verifica se jogador tem créditos suficientes
    if balance < 0 and player.credits.amount < -balance then
        return false, "Créditos insuficientes"
    end

    -- Verifica se estação tem os itens pedidos
    for _, r in ipairs(requesting) do
        if not trader.inventory:has(r.item, r.qty) then
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
        trader.inventory:add(o.item, o.qty)
    end
    for _, r in ipairs(requesting) do
        trader.inventory:remove(r.item, r.qty)
        ship.inventory:add(r.item, r.qty)
    end
    player.credits:add(balance)

    return true, balance
end

function Market.update()
end

return Market
