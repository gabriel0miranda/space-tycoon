return function(capacity, cooldown)
  return {
    totalCapacity = capacity,
    currentCapacity = capacity,
    cooldown        = cooldown,
    currentCooldown = 0,
    disabled        = false
  }
end
