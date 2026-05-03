local Playing = {}

local playerFlagShip = nil
local armedEntities = {}
local landCooldown = 0

function Playing.onEnter(params)
  config.Input.pushContext("playing")
  playerFlagShip = config.Entities.with("isFlagShip")[1]
  armedEntities = config.Entities.with("weapon")
  config.InventoryUI.load()
  if params and params.resuming then
    landCooldown = 1.5
    print("Unfreezing")
    config.WorldManager:unfreeze()
  else
    local landCooldown = 0
    config.WorldManager.loadSystem(config.WorldManager.currentSystemId)
    playerFlagShip.inventory:add("Cocaine",12)
    print("Started playing")
    config.Camera.x = 0
    config.Camera.y = 0
    config.Camera.scale = 0.2
    config.Camera.rotation = 0
    config.Camera.smoothSpeed = 8
    config.Camera.targetX = 0
    config.Camera.targetY = 0
  end
end

function Playing.onExit()
  config.Input.popContext("playing")
  print("Exiting playing state")
end

local function obj_pos(obj)
  return obj.x, obj.y
end

local function obj_radius(obj)
  return obj.radius or 10
end

local function ast_pos(ast)
  return ast.rigidbody.body:getPosition()
end

local function ast_radius(ast)
  return (ast.sprite.shape and ast.sprite.shape:getRadius()) or 20
end

function Playing.update(dt)
  if landCooldown > 0 then
      landCooldown = landCooldown - dt
  end
  if config.Input.state.paused then return end
  if not playerFlagShip or not playerFlagShip.rigidbody or not playerFlagShip.rigidbody.body or playerFlagShip.rigidbody.body:isDestroyed() then return end

  local valid_asteroids = {}
  for _, ast in ipairs(config.Entities.getByTag("asteroid")) do
    if ast.rigidbody and ast.rigidbody.body and not ast.rigidbody.body:isDestroyed() then
      valid_asteroids[#valid_asteroids+1] = ast
    end
  end
  local ast_hash = config.SpatialHash.build(valid_asteroids,ast_pos,ast_radius,config.CELL_SIZE)

  local floatsome_hash = config.SpatialHash.build(config.Entities.getByTag("floatsome"),obj_pos,obj_radius,config.CELL_SIZE)

  config.NpcAISystem.update(playerFlagShip, dt)
  config.ShipMovementSystem.update(playerFlagShip, dt)
  config.GravityPullSystem.update(ast_hash, dt)
  config.LandableMovementSystem.update(dt)
  config.WeaponSystem.update(armedEntities, dt)
  config.PickupSystem.update(dt,playerFlagShip,floatsome_hash)
  config.ProjectileSystem.update(ast_hash, dt)

  -- config.Camera follow
  config.Camera:follow(playerFlagShip.rigidbody.body:getX(), playerFlagShip.rigidbody.body:getY())
  config.Camera:update(dt)

  -- Landing check
  for _, l in ipairs(config.Entities.getByTag("landable")) do
    local sx, sy = playerFlagShip.rigidbody.body:getX(), playerFlagShip.rigidbody.body:getY()
    local dx = sx - l.x
    local dy = sy - l.y
    if dx*dx + dy*dy < (l.radius + 40)^2 and config.Input.state.land and landCooldown <= 0 then
        playerFlagShip.landedAt = l
        config.WorldManager:freeze()
        config.GameState.switch("landed")
        config.Input.state.land = false
        return
    end
  end

  if config.Input.state.ui_mainmenu then
    config.GameState.switch("mainmenu")
  end

  if config.Input.state.ui_inventory then
    config.InventoryUI.toggle(playerFlagShip,{title = "Your Ship"} )
  end
  config.InventoryUI.update(dt)

  if config.Input.state.ui_properties then
    config.PropertyUI.toggle()
  end
  config.PropertyUI.update(dt)

  config.World:update(dt)
end

function Playing.keypressed(key)
    --if config.PropertyUI.isOpen() then
    --  config.PropertyUI.keypressed(key)
    --  return
    --end

    if config.InventoryUI.isOpen() then
      config.InventoryUI.keypressed(key)
      return
    end
end

function Playing.mousepressed(_, mx, my, button)
    if config.PropertyUI.isOpen() then
      config.PropertyUI.mousepressed(mx, my, button)
      return
    end

    if config.InventoryUI.isOpen() then
      config.InventoryUI.mousepressed(mx, my, button)
      return
    end
end

function Playing.wheelmoved(dx, dy)
    if config.PropertyUI.isOpen() then
      config.PropertyUI.wheelmoved(dx, dy)
      return
    end

    if config.InventoryUI.isOpen() then
      config.InventoryUI.wheelmoved(dx, dy)
      return
    end
end

function Playing.draw()
  config.RenderingSystem.draw(playerFlagShip, armedEntities, config.Camera)
end

return Playing
