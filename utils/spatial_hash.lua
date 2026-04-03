local SpatialHash = {}

function SpatialHash.build(entities_iter, get_pos, get_radius, cell_size)
  local cells = {}

  for _, obj in ipairs(entities_iter) do
    local x, y = get_pos(obj)
    local r = get_radius(obj)

    local cx_min = math.floor((x - r) / cell_size)
    local cx_max = math.floor((x + r) / cell_size)
    local cy_min = math.floor((y - r) / cell_size)
    local cy_max = math.floor((y + r) / cell_size)

    for cx = cx_min, cx_max do
      for cy = cy_min, cy_max do
        local k = cx .. "," .. cy
        if not cells[k] then cells[k] = {} end
        table.insert(cells[k], obj)
      end
    end
  end

  return cells
end

function SpatialHash.query(cells, cell_size, x, y, r)
  if not cells then return {} end
  local cx_min = math.floor((x - r) / cell_size)
  local cx_max = math.floor((x + r) / cell_size)
  local cy_min = math.floor((y - r) / cell_size)
  local cy_max = math.floor((y + r) / cell_size)

  local results, seen = {}, {}

  for cx = cx_min, cx_max do
    for cy = cy_min, cy_max do
      local cell = cells[cx .. "," .. cy]
      if cell then
        for _, obj in ipairs(cell) do
          if not seen[obj] then
            seen[obj] = true
            results[#results + 1] = obj
          end
        end
      end
    end
  end

  return results
end

return SpatialHash
