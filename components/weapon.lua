return function(weapon_def)
  return {
    def      = weapon_def,   -- referência à definição
    timer    = 0,            -- cooldown atual
    firing   = false,        -- input externo seta isso
    angle    = 0,            -- direção de disparo (radianos)
  }
end
