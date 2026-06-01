return function(weapons)
  local shipWeapons = {}
  for i, weapon in pairs(weapons) do
    print("WEAPON: "..weapon)
    shipWeapons[i] = {
      def       = config.Weapons[weapon],
      capacitor = {
                   max = config.Weapons[weapon].capacitorCharge,
                   current = 0,
                   },
      angle = 0,
      firing    = false,
    }
  end
  return shipWeapons
end
