local GameState = {
  current = "mainmenu",
  data = {}
}

local stateModules = {}

function GameState.register(name, module)
  stateModules[name] = module
end

function GameState.switch(newState, extraData)
  local old = stateModules[GameState.current]
  if old and old.onExit then old.onExit() end

  GameState.current = newState
  GameState.data = extraData or {}

  local new = stateModules[newState]
  if new and new.onEnter then new.onEnter(extraData) end
end

function GameState.update(dt)
  local state = stateModules[GameState.current]
  if state and state.update then
    state.update(dt)
  end
end

function GameState.draw()
  local state = stateModules[GameState.current]
  if state and state.draw then
    state.draw()
  end
end

function GameState.keypressed(key)
  local state = stateModules[GameState.current]
  if state and state.keypressed then
    state.keypressed(key)
  end
end

function GameState.keyreleased(key)
  local state = stateModules[GameState.current]
  if state and state.keyreleased then
    state.keyreleased(key)
  end
end

return GameState
