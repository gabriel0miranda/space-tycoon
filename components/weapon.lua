return function(weapons)
  local shipWeapons = {}
  for i, weapon in pairs(weapons) do
    shipWeapons[i] = {
      def       = config.Weapons[weapon],
      capacitor = {
                   max = config.Weapons[weapon].capacitorCharge or 0,
                   current = 0,
                   drain   = config.Weapons[weapon].capacitorDrain or 0
                   },
      angle = 0,
      cooldown = config.Weapons[weapon].cooldown or 0,
      firing    = false,
    }
  end
  return shipWeapons
end
