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
    ship.inventory:add("Cocaine",50,1)
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
  if config.Input.state.paused then return end

  local valid_asteroids = {}
  for _, ast in ipairs(config.Entities.with("asteroid")) do
    if ast.rigidbody and ast.rigidbody.body and not ast.rigidbody.body:isDestroyed() then
      valid_asteroids[#valid_asteroids+1] = ast
    end
  end
  local ast_hash = config.SpatialHash.build(valid_asteroids,ast_pos,ast_radius,config.CELL_SIZE)

  local floatsome_hash = config.SpatialHash.build(config.Entities.getByTag("floatsome"),obj_pos,obj_radius,config.CELL_SIZE)

  config.ShipMovementSystem.update(dt)
  config.NpcAISystem.update(dt)
  config.GravityPullSystem.update(dt)
  config.LandableMovementSystem.update(dt)
  config.WeaponSystem.update(dt)
  config.PickupSystem.update(dt,ship,floatsome_hash)
  config.ProjectileSystem.update(ast_hash, dt)

  -- config.Camera follow
  config.Camera:follow(ship.rigidbody.body:getX(), ship.rigidbody.body:getY())
  config.Camera:update(dt)

  -- Landing check
  for _, l in ipairs(config.Entities.with("landable")) do
    local sx, sy = ship.rigidbody.body:getX(), ship.rigidbody.body:getY()
    local dx = sx - l.x
    local dy = sy - l.y
    if dx*dx + dy*dy < (l.radius + 40)^2 and config.Input.state.land then
        ship.landedAt = l
        config.WorldManager:freeze()
        config.GameState.switch("landed")
        config.Input.state.land = false
        return
    end
  end

  if config.Input.state.escape then
    config.Input.state.escape = false
    config.GameState.switch("mainmenu")
  end
  if config.Input.state.inventory then
    config.InventoryUI.toggle(ship,{title = "Your Ship"} )
    config.Input.state.inventory = false
  end
  config.InventoryUI.update(dt)
  config.World:update(dt)
end

function Playing.draw()
  config.RenderingSystem.draw(config.Camera)
end

return Playing
