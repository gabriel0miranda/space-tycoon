local ShipyardUI = {}

local open = false
local selectedStationShip = nil
local selectedPlayerShip  = nil
local shipyardData = nil -- Referência à estação atual
local isNaming = false
local typedName = ""
local pendingBuyType = nil

local C = {
    bg          = {0.06, 0.03, 0.01, 0.97},
    bgRow       = {0.08, 0.04, 0.02, 1},
    border      = {0.3, 0.15, 0.05, 1},
    textActive  = {1, 0.8, 0.4, 1},
    textNormal  = {0.8, 0.7, 0.6, 1},
    textMuted   = {0.4, 0.3, 0.2, 1},
    accent      = {0.2, 0.5, 0.2, 1}
}

function ShipyardUI.draw(player, station)
  if not open then return end
  local shipyard = station.shipyard
  -- Overlay de fundo
  love.graphics.setColor(C.bg)
  love.graphics.rectangle("fill", 50, 50, love.graphics.getWidth()-100, love.graphics.getHeight()-150)
  local W = love.graphics.getWidth() - 100
  local colW = W / 3
  local startX = 50
  local startY = 80

  -- 1. PAINEL ESQUERDO: Naves na Estação
  love.graphics.setFont(config.normalFont)
  love.graphics.setColor(C.textActive)
  love.graphics.print("DISPONÍVEL NA ESTAÇÃO", startX + 10, startY - 25)
  for i, shipType in ipairs(shipyard.stock or {}) do
      local y = startY + (i-1) * 30
      local isSel = (selectedStationShip == shipType)
      love.graphics.setColor(isSel and C.accent or C.bgRow)
      love.graphics.rectangle("fill", startX + 5, y, colW - 10, 25)
      love.graphics.setColor(C.textNormal)
      love.graphics.print(shipType, startX + 15, y + 5)
      -- Botão invisível de clique (simplificado)
      if love.mouse.getX() > startX and love.mouse.getX() < startX + colW and
         love.mouse.getY() > y and love.mouse.getY() < y + 25 and love.mouse.isDown(1) then
          selectedStationShip = shipType
          selectedPlayerShip = nil
      end
  end

  -- 2. PAINEL CENTRAL: Detalhes da Selecionada
  local midX = startX + colW
  love.graphics.setColor(C.textActive)
  love.graphics.print("INFORMAÇÕES TÉCNICAS", midX + 10, startY - 25)
  local currentType = selectedStationShip or (selectedPlayerShip and selectedPlayerShip.sprite.shipType)
  if currentType then
    local def = config.Ships[currentType]
    love.graphics.setColor(C.textNormal)
    love.graphics.setFont(config.smallFont)
    love.graphics.print("Nome: " .. def.name, midX + 10, startY + 10)
    love.graphics.print("Preço: " .. def.price .. " cr", midX + 10, startY + 30)
    love.graphics.print("Carga: " .. def.cargo, midX + 10, startY + 50)
    love.graphics.print("Aceleração: " .. def.movement.linearAcceleration, midX + 10, startY + 70)
    -- Botão de Ação (Comprar/Vender)
    love.graphics.setColor(C.accent)
    love.graphics.rectangle("line", midX + 10, startY + 150, 100, 30)
    love.graphics.printf(selectedStationShip and "COMPRAR" or "VENDER", midX + 10, startY + 158, 100, "center")
    if love.mouse.getX() > midX + 10 and love.mouse.getX() < midX + 110 and
      love.mouse.getY() > startY + 150 and love.mouse.getY() < startY + 180 and love.mouse.isDown(1) then
      if selectedStationShip then
        -- Abre o prompt de nome ao invés de comprar direto
        isNaming = true
        typedName = ""
        pendingBuyType = selectedStationShip
        love.keyboard.setKeyRepeat(true) -- Permite segurar backspace
      --else
      --  -- Lógica de VENDER o selectedPlayerShip...
      end
    end
  end

  -- 3. PAINEL DIREITO: Frota do Jogador
  local rightX = startX + colW * 2
  love.graphics.setColor(C.textActive)
  love.graphics.setFont(config.normalFont)
  love.graphics.print("SUA FROTA", rightX + 10, startY - 25)
  local count = 0
  for name, shipEnt in pairs(player.property.properties) do
    local y = startY + (count) * 30
    local isSel = (selectedPlayerShip == shipEnt)
    love.graphics.setColor(isSel and C.accent or C.bgRow)
    love.graphics.rectangle("fill", rightX + 5, y, colW - 10, 25)
    love.graphics.setColor(shipEnt.isFlagShip and C.textActive or C.textNormal)
    local label = shipEnt.sprite.shipType .. (shipEnt.isFlagShip and " (Atual)" or "")
    love.graphics.print(label, rightX + 15, y + 5)
    if love.mouse.getX() > rightX and love.mouse.getX() < rightX + colW and
      love.mouse.getY() > y and love.mouse.getY() < y + 25 and love.mouse.isDown(1) then
        selectedPlayerShip = shipEnt
        selectedStationShip = nil
    end
    count = count + 1
  end
  if isNaming then
    -- Overlay escuro
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    -- Caixa de texto
    local boxW, boxH = 400, 150
    local boxX = (love.graphics.getWidth() - boxW) / 2
    local boxY = (love.graphics.getHeight() - boxH) / 2
    love.graphics.setColor(C.bgPanel)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH)
    love.graphics.setColor(C.border)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH)
    love.graphics.setColor(C.textActive)
    love.graphics.printf("DÊ UM NOME PARA SUA NOVA NAVE:", boxX, boxY + 30, boxW, "center")
    -- Campo de digitação
    love.graphics.setColor(0.1, 0.05, 0.02, 1)
    love.graphics.rectangle("fill", boxX + 50, boxY + 70, boxW - 100, 30)
    love.graphics.setColor(C.textNormal)
    love.graphics.printf(typedName .. "_", boxX + 50, boxY + 78, boxW - 100, "center")
    love.graphics.setColor(C.textMuted)
    love.graphics.printf("Pressione ENTER para confirmar ou ESC para cancelar", boxX, boxY + 120, boxW, "center")
  end
end

function ShipyardUI.open()
  config.Input.pushContext("shipyard")
  open = true
end

function ShipyardUI.close()
  config.Input.popContext("shipyard")
  open = false
end

function ShipyardUI.isOpen() return open end

function ShipyardUI.toggle()
  if ShipyardUI.isOpen() then
    ShipyardUI.close()
  elseif not ShipyardUI.isOpen() then
    ShipyardUI.open()
  end
end

function ShipyardUI.textinput(t)
    if isNaming then
        -- Limita o tamanho do nome para não quebrar a UI
        if string.len(typedName) < 20 then
            typedName = typedName .. t
        end
    end
end

function ShipyardUI.keypressed(key)
  if isNaming then
    if key == "backspace" then
      -- Remove o último caractere (versão simples)
      typedName = typedName:sub(1, -2)
    elseif key == "return" or key == "kpenter" then
      if string.len(typedName) > 0 then
        -- Confirma a compra
        Shipyard.buyShip(player, pendingBuyType, typedName)
        isNaming = false
        love.keyboard.setKeyRepeat(false)
      end
    elseif key == "escape" then
      -- Cancela
      isNaming = false
      love.keyboard.setKeyRepeat(false)
    end
    return true -- Retorna true para avisar que o input foi consumido
  end
  return false
end

return ShipyardUI
