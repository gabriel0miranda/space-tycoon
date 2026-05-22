return function(capacity, cooldown)
  return {
    totalCapacity = capacity,
    currentCapacity = capacity,
    cooldown        = cooldown,
    currentCooldown = 0,
    active          = true
  }
end
