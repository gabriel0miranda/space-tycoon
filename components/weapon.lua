return function(weapons)
  for i, weapon in ipairs(weapons) do
    weapons[i] = {
      def       = config.Weapons[weapon],
      capacitor = {
                   max = config.Weapons[weapon].capacitor,
                   current = 0,
                   },
      angle = 0,
      firing    = false,
    }
  end
  return weapons
end
