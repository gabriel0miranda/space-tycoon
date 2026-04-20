local Entities = {}
Entities.all = {}

local byTag = {}

function Entities.add(entity)
  table.insert(Entities.all,entity)
  return entity
end

function Entities.remove(entity)
  for i = #Entities.all, 1, -1 do
    if Entities.all[i] == entity then
      if entity.rigidbody and entity.rigidbody.body and not entity.rigidbody.body:isDestroyed() then
        entity.rigidbody.body:destroy()
      end
      table.remove(Entities.all, i)
      break
    end
  end
  local list = byTag[entity.tag]
  if list then
    for i = #list, 1, -1 do
      if list[i] == entity then table.remove(list, i); break end
    end
  end
end

function Entities.clear()
  for _, e in ipairs(Entities.all) do
    if e.rigidbody and e.rigidbody.body and not e.rigidbody.body:isDestroyed() then
      e.rigidbody.body:destroy()
    end
  end
  Entities.all = {}
  byTag = {}
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
  return byTag[tag] or {}
end

function Entities.sortByLayer()
  local sorted = {}
  for _, e in ipairs(Entities.all) do
    sorted[#sorted + 1] = e
  end
  table.sort(sorted, function(a,b)
    return (a.layer or 0) < (b.layer or 0)
  end)
  Entities.all = sorted
end

function Entities.create(tag, data)
  local entity = data or {}
  entity.tag = tag
  Entities.add(entity)
  if not byTag[tag] then byTag[tag] = {} end
  byTag[tag][#byTag[tag]+1] = entity
  return entity
end

return Entities
