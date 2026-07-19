local function dump(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    if type(t) ~= "table" then
        print(prefix .. tostring(t))
        return
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            dump(v, indent + 1)
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
        end
    end
end

return dump
