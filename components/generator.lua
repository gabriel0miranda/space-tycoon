return function(maxOutput)
  return {
    maxOutput     = maxOutput,
    currentOutput = 0,
    routingMode   = "balanced" -- balanced, weaponPriority, shieldsOnly
  }
end
