return function(faction,aggressive)
  return {
    state                   = "idle",
    target                  = nil,
    timer                   = 0,
    faction                 = faction,
    aggressive = aggressive,
  }
end
