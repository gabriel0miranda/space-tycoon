local RandomChoice = function (t, filter)
  filter = filter or function() return true end
  local chosen = nil
  local count = 0

  for _, item in ipairs(t) do
    if filter(item) then
      count = count + 1
      if math.random(count) == 1 then
        chosen = item
      end
    end
  end

  return chosen
end

return RandomChoice
