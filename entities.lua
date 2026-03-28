local Entities = {}
Entities.all = {}

function Entities.add(entity)
  table.insert(Entities.all,entity)
  return entity
end

function Entities.remove(entity)
  for i = #Entities.all, 1, -1 do
    if Entities.all[i] == entity then
      table.remove(Entities.all, i)
      break
    end
  end
end

function Entities.clear()
  Entities.all = {}
end

function Entities.with(...)
  local required = {...}
  local result = {}
  for _, entity in ipairs(Entities.all) do
    local matches = true
    for _, req in ipairs(required) do
      if not (
        entity.tag == req or
        (entity.components and entity.components[req]) or
        entity[req] ~= nil
      ) then
          matches = false
          break
      end
    end
    if matches then
      table.insert(result, entity)
    end
  end
    return result
  end

function Entities.getByTag(tag)
  local result = {}
  for _, e in ipairs(Entities.all) do
    if e.tag == tag then
      table.insert(result, e)
    end
  end
  return result
end

function Entities.create(tag, data)
  local entity = data or {}
  entity.tag = tag
  Entities.add(entity)
  return entity
end

return Entities
