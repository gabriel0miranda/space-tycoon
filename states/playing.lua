local Playing = {}

local playerFlagShip = nil
local armedEntities = {}
local generatorEntities = {}
local landCooldown = 0
local mouseFadeTimer = 5

function Playing.onEnter(params)
  config.Input.pushContext("playing")
  config.InventoryUI.load()
  if params and params.resuming then
    landCooldown = 1.5
    print("Unfreezing")
    config.WorldManager:unfreeze()
    playerFlagShip = config.Entities.with("isFlagShip")[1]
    armedEntities = config.Entities.with("weapons")
    generatorEntities = config.Entities.with("generator")
  else
    landCooldown = 1.5
    playerFlagShip = config.Entities.with("isFlagShip")[1]
    armedEntities = config.Entities.with("weapons")
    generatorEntities = config.Entities.with("generator")
    if playerFlagShip.landedAt then
        config.WorldManager:freeze()
        config.GameState.switch("landed")
    end
    print("Entered space")
    mouseFadeTimer = config.MOUSE_FADE_TIMER
    config.Camera.x = playerFlagShip.rigidbody.body:getX()
    config.Camera.y = playerFlagShip.rigidbody.body:getY()
    config.Camera.scale = 0.2
    config.Camera.rotation = 0
    config.Camera.smoothSpeed = 8
    config.Camera.targetX = playerFlagShip.rigidbody.body:getX()
    config.Camera.targetY = playerFlagShip.rigidbody.body:getY()
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

local function rigidbody_pos(entity)
  return entity.rigidbody.body:getPosition()
end

local function shape_radius(entity)
  return (entity.sprite.shape and entity.sprite.shape:getRadius()) or 20
end

function Playing.update(dt)
  if landCooldown > 0 then
      landCooldown = landCooldown - dt
  end

  if mouseFadeTimer > 0 then
    mouseFadeTimer = mouseFadeTimer - dt
  elseif mouseFadeTimer <= 0 then
    love.mouse.setVisible(false)
    love.mouse.setRelativeMode(true)
  end

  if config.Input.state.paused then return end
  if not playerFlagShip or not playerFlagShip.rigidbody or not playerFlagShip.rigidbody.body or playerFlagShip.rigidbody.body:isDestroyed() then return end

  local ast_hash = config.SpatialHash.build(config.Entities.getByTag("asteroid"),rigidbody_pos,shape_radius,config.CELL_SIZE)

  local floatsome_hash = config.SpatialHash.build(config.Entities.getByTag("floatsome"),obj_pos,obj_radius,config.CELL_SIZE)

  local ship_hash = config.SpatialHash.build(config.Entities.getByTag("ship"),rigidbody_pos,shape_radius,config.CELL_SIZE)

  config.TargetingSystem.update(playerFlagShip,dt)
  config.ShipMovementSystem.update(playerFlagShip, dt)
  config.NpcAISystem.update(playerFlagShip, floatsome_hash, dt)
  config.GravityPullSystem.update(dt)
  config.LandableMovementSystem.update(dt)
  config.EnergySystem.update(generatorEntities,dt)
  config.WeaponSystem.update(armedEntities, dt)
  config.PickupSystem.update(dt,floatsome_hash)
  config.ProjectileSystem.update(ship_hash,ast_hash,dt)
  config.LaserSystem.update(dt)
  config.PulseSystem.update(ship_hash,ast_hash,dt)
  config.MineSystem.update(ship_hash,ast_hash,dt)
  config.ExplosionSystem.update(dt)
  config.DamageSystem.update(dt)
  config.FloatsomeSystem.update(dt)

  if not playerFlagShip or not playerFlagShip.rigidbody or not playerFlagShip.rigidbody.body or playerFlagShip.rigidbody.body:isDestroyed() then
    config.GameState.switch("dead")
    return
  end
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

  if config.Input.state.ui_properties then
    config.PropertyUI.toggle()
  end

  if config.InventoryUI.isOpen() then
    config.InventoryUI.update(dt)
  end
  if config.MarketUI.isOpen() then
    config.MarketUI.update(dt)
  end
  if config.SelectUI.isOpen() then
    config.SelectUI.update(dt)
  end
  if config.DialogueUI.isOpen() then
    config.DialogueUI.update(dt)
  end
  if config.PropertyUI.isOpen() then
    config.PropertyUI.update(dt)
  end
  if config.CommunicationSystem.isOpen() then
    config.CommunicationUI.update(dt)
  end

  if config.Input.state.ui_comm and config.TargetingSystem.current then
    config.CommunicationUI.openComm(playerFlagShip)
  end
  config.CommunicationSystem.update(playerFlagShip,dt)

  config.World:update(dt)
end

function Playing.keypressed(key)
  if config.PropertyUI.isOpen() then
    config.PropertyUI.keypressed(key)
    return
  end

  if config.InventoryUI.isOpen() then
    config.InventoryUI.keypressed(key)
    return
  end

  if config.CommunicationSystem.isOpen() then
    config.CommunicationUI.keypressed(key)
    return
  end
  if config.MarketUI.isOpen() then
    config.MarketUI.keypressed(key)
    return
  end
  config.TargetingSystem.keypressed(key)
end

function Playing.mousemoved(x,y,dx,dy,istouch)
  love.mouse.setVisible(true)
  love.mouse.setRelativeMode(false)
  mouseFadeTimer = config.MOUSE_FADE_TIMER
end

function Playing.mousepressed(mx, my, button)
  if config.PropertyUI.isOpen() then
    config.PropertyUI.mousepressed(mx, my, button)
    return
  end

  if config.InventoryUI.isOpen() then
    config.InventoryUI.mousepressed(mx, my, button)
    return
  end

  if config.CommunicationSystem.isOpen() then
    config.CommunicationUI.mousepressed(mx, my, button)
    return
  end

  if config.MarketUI.isOpen() then
    config.MarketUI.mousepressed(mx, my, button)
    return
  end
  config.TargetingSystem.mousepressed(mx, my, button)
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

  if config.CommunicationSystem.isOpen() then
    config.CommunicationUI.wheelmoved(dx, dy)
    return
  end

  if config.MarketUI.isOpen() then
    config.MarketUI.wheelmoved(dx, dy)
    return
  end
end

function Playing.draw()
  config.RenderingSystem.draw(playerFlagShip, config.Camera)
end

return Playing
