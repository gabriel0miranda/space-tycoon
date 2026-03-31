config = require("config")

love.load = function()
  love.mouse.setVisible(true)
  config.GameState.register("mainmenu", config.MainmenuState)
  config.GameState.register("playing", config.PlayingState)
  config.GameState.register("landed", config.LandedState)

  local rigidBody = {}
  rigidBody.body = love.physics.newBody(config.World, 400, 200, "dynamic")
  rigidBody.shape = love.physics.newPolygonShape(0, -25, 50, 0, 0, 25)
  rigidBody.fixture = love.physics.newFixture(rigidBody.body, rigidBody.shape)
  rigidBody.color = {255/255, 200/255, 48/255}
  rigidBody.body:setAngle(0)
  config.Entities.create("ship", {
    name = "Your Ship",
    rigidbody = require("components.rigidbody")(rigidBody.body,rigidBody.fixture),
    sprite = require("components.sprite")(rigidBody.color, rigidBody.shape,"Polygon"),
    movement = require("components.movement")(800,600,1200),
    weapon = require("components.weapon")(config.Weapons.laser),
    landedAt = nil,
    inertiaDampeners = true,
    rcs = true,
    mass = 1000,
    restitution = 0.75,
    inventory = require("components.inventory")(500),
  })

  config.WorldManager.systems = config.Systems

  config.GameState.switch("mainmenu")

end

love.focus = function(focused)
  config.Input.toggle_focus(focused)
end

love.keypressed = function(pressed_key)
  config.GameState.keypressed(pressed_key)
  config.Input.press(pressed_key)
end

love.keyreleased = function(released_key)
  config.GameState.keyreleased(released_key)
  config.Input.release(released_key)
end

function love.mousepressed(x, y, button)
    config.GameState.mousepressed(x, y, button)
end

function love.wheelmoved(dx, dy)
    config.GameState.wheelmoved(dx, dy)
end

love.update = function(dt)
  config.GameState.update(dt)
end

love.draw = function()
  config.GameState.draw()
end
