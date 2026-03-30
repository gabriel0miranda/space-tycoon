Entities = require('entities')
GameState = require('states/init')
Weapons = require("data/weapons")
input = require('input')
world = require('world')


love.load = function()
  love.mouse.setVisible(true)
  bigFont   = love.graphics.newFont(48)
  normalFont = love.graphics.newFont(24)
  smallFont  = love.graphics.newFont(14)
  ASTEROID_MIN_RADIUS = 2000
  ASTEROID_MAX_RADIUS = 4000
  GRAVITY_CONSTANT = 5000
  MAX_ORBIT_RADIUS = 6000
  MIN_DISTANCE = 1500
  GameState.register("mainmenu", require("states.mainmenu"))
  GameState.register("playing", require("states.playing"))
  GameState.register("landed", require("states.landed"))

  local rigidBody = {}
  rigidBody.body = love.physics.newBody(world, 400, 200, "dynamic")
  rigidBody.shape = love.physics.newPolygonShape(0, -25, 50, 0, 0, 25)
  rigidBody.fixture = love.physics.newFixture(rigidBody.body, rigidBody.shape)
  rigidBody.color = {255/255, 200/255, 48/255}
  rigidBody.body:setAngle(0)
  Entities.create("ship", {
    name = "Your Ship",
    rigidbody = require("components.rigidbody")(rigidBody.body,rigidBody.fixture),
    sprite = require("components.sprite")(rigidBody.color, rigidBody.shape,"Polygon"),
    movement = require("components.movement")(800,600,1200),
    weapon = require("components.weapon")(Weapons.laser),
    landedAt = nil,
    inertiaDampeners = true,
    rcs = true,
    mass = 1000,
    restitution = 0.75,
    inventory = require("components.inventory")(500),
  })

  require("managers.world_manager").systems = require("data.systems")

  GameState.switch("mainmenu")

end

love.focus = function(focused)
  input.toggle_focus(focused)
end

love.keypressed = function(pressed_key)
  GameState.keypressed(pressed_key)
  input.press(pressed_key)
end

love.keyreleased = function(released_key)
  GameState.keyreleased(released_key)
  input.release(released_key)
end

function love.mousepressed(x, y, button)
    GameState.mousepressed(x, y, button)
end

function love.wheelmoved(dx, dy)
    GameState.wheelmoved(dx, dy)
end

love.update = function(dt)
  GameState.update(dt)
end

love.draw = function()
  GameState.draw()
  if debugMode then
    love.graphics.print("State: "..GameState.current,10,10)
  end
end
