local Playing = {}

local ship = nil

function Playing.onEnter(params)
  ship = config.Entities.with("ship")[1]
  config.InventoryUI.load()
  if params and params.resuming then
    print("Unfreezing")
    config.WorldManager:unfreeze()
  else
    config.WorldManager.loadSystem(config.WorldManager.currentSystemId)
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
  print("Exiting playing state")
end

function Playing.update(dt)
  if config.Input.paused then return end

  config.ShipMovementSystem.update(dt)
  config.GravityPullSystem.update(dt)
  config.LandableMovementSystem.update(dt)
  config.WeaponSystem.update(dt)
  config.PickupSystem.update(dt,ship,config.Entities.getByTag("floatsome"))
  config.ProjectileSystem.update(dt)

  -- config.Camera follow
  config.Camera:follow(ship.rigidbody.body:getX(), ship.rigidbody.body:getY())
  config.Camera:update(dt)

  -- Landing check
  for _, l in ipairs(config.Entities.with("landable")) do
    local sx, sy = ship.rigidbody.body:getX(), ship.rigidbody.body:getY()
    local dx = sx - l.x
    local dy = sy - l.y
    if dx*dx + dy*dy < (l.radius + 40)^2 and config.Input.land then
        ship.landedAt = l
        config.WorldManager:freeze()
        config.GameState.switch("landed")
        config.Input.land = false
        return
    end
  end

  if config.Input.escape then
    config.Input.escape = false
    config.GameState.switch("mainmenu")
  end
  if config.Input.inventory then
    config.InventoryUI.toggle(ship,{title = "Your Ship"} )
    config.Input.inventory = false
  end
  config.InventoryUI.update(dt)
  config.World:update(dt)
end

function Playing.draw()
  config.RenderingSystem.draw(config.Camera)
end

return Playing
