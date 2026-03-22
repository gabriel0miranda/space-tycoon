local world = require('world')

local bullet = {}
bullet.body = love.physics.newBody(world, 200, 200, 'dynamic')
bullet.body:setMass(32)
bullet.body:setLinearVelocity(300, 300)
bullet.shape = love.physics.newCircleShape(0, 0, 3)
bullet.fixture = love.physics.newFixture(bullet.body, bullet.shape)
bullet.fixture:setRestitution(1)
bullet.fixture:setUserData(bullet)

return bullet
