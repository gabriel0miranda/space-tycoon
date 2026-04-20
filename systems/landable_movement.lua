local LandableMovement = {}

function LandableMovement.update(dt)
  local starList = config.Entities.getByTag("star")
  local landableList = config.Entities.getByTag("landable")
  for _, landable in ipairs(landableList) do
    if not landable.toSystem then
      if landable.orbitSpeed > 0 then
        landable.orbitAngle = landable.orbitAngle + landable.orbitSpeed *dt
        landable.x = starList[1].x + landable.orbitRadius * math.cos(landable.orbitAngle)
        landable.y = starList[1].y + landable.orbitRadius * math.sin(landable.orbitAngle)
      end
    end
  end
end

return LandableMovement
