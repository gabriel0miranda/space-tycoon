local Playing = {}
local WorldManager = require("managers.world_manager")
local InventoryUI  = require("ui.inventory_ui")
local camera = require("camera")()

function Playing.onEnter(params)
  InventoryUI.load()
  if params and params.resuming then
    print("Unfreezing")
    WorldManager:unfreeze()
  else
    WorldManager.loadSystem(WorldManager.currentSystemId)
    print("Started playing")
    camera.x = 0
    camera.y = 0
    camera.scale = 0.2
    camera.rotation = 0
    camera.smoothSpeed = 8
    camera.targetX = 0
    camera.targetY = 0
  end
end

function Playing.onExit()
  print("Exiting playing state")
end

function Playing.update(dt)
  local ship = Entities.with("ship")[1]
  if input.paused then return end

  require("systems.ship_movement").update(dt)
  require("systems.gravity_pull").update(dt)
  require("systems.landable_movement").update(dt)
  require("systems.weapon_system").update(dt)
  require("systems.pickup").update(dt,ship,Entities.getByTag("ore"))
  require("systems.projectile_system").update(dt)

  -- Camera follow
  camera:follow(ship.rigidbody.body:getX(), ship.rigidbody.body:getY())
  camera:update(dt)

  -- Landing check
  for _, l in ipairs(Entities.with("landable")) do
    local sx, sy = ship.rigidbody.body:getX(), ship.rigidbody.body:getY()
    local dx = sx - l.x
    local dy = sy - l.y
    if dx*dx + dy*dy < (l.radius + 40)^2 and input.land then
        ship.landedAt = l
        WorldManager:freeze()
        GameState.switch("landed")
        input.land = false
        return
    end
  end

  if input.escape then
    GameState.switch("mainmenu")
  end
  if input.inventory then
    InventoryUI.toggle(ship,{title = "Your Ship"} )
    input.inventory = false
  end
  InventoryUI.update(dt)
  world:update(dt)
end

function Playing.draw()
  local Rendering = require("systems.rendering")
  Rendering.draw(camera)
end

return Playing
