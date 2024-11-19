local methods = {}

local function toString(value)
    local dataType = typeof(value)

    if dataType == "userdata" or dataType == "table" then
        local mt = getMetatable(value)
        local __tostring = mt and rawget(mt, "__tostring")

        if not mt or (mt and not __tostring) then 
            return tostring(value) 
        end

        rawset(mt, "__tostring", nil)
        
        value = tostring(value):gsub((dataType == "userdata" and "userdata: ") or "table: ", '')
        
        rawset(mt, "__tostring", __tostring)

        return value 
    elseif type(value) == "userdata" then
        return userdataValue(value) -- Assuming userdataValue is defined elsewhere
    elseif dataType == "function" then
        local closureName = getInfo(value).name or '' -- Assuming getInfo is defined elsewhere
        return (closureName == '' and "Unnamed function") or closureName
    else
        return tostring(value)
    end
end

local gsubCharacters = {
    ["\""] = "\\\"",
    ["\\"] = "\\\\",
    ["\0"] = "\\0",
    ["\n"] = "\\n",
    ["\t"] = "\\t",
    ["\f"] = "\\f",
    ["\r"] = "\\r",
    ["\v"] = "\\v",
    ["\a"] = "\\a",
    ["\b"] = "\\b"
}

local function dataToString(data, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep("  ", indentLevel)
    local dataType = type(data)

    if dataType == "string" then
        return '"' .. data:gsub("[%c%z\\\"]", gsubCharacters) .. '"'
    elseif dataType == "table" then
        local str = "{\n"
        for k, v in pairs(data) do
            str = str .. indent .. "  " .. dataToString(k, indentLevel + 1) .. " = " .. dataToString(v, indentLevel + 1) .. ",\n"
        end
        return str .. indent .. "}"
    elseif dataType == "userdata" then
        if typeof(data) == "Instance" then
            local instanceStr = getInstancePath(data) .. " {\n" -- Assuming getInstancePath is defined elsewhere
            for _, child in ipairs(data:GetChildren()) do
                instanceStr = instanceStr .. indent .. "  " .. dataToString(child, indentLevel + 1) .. ",\n"
            end
            for _, prop in ipairs(data:GetProperties()) do
                local propValue = data[prop.Name]
                instanceStr = instanceStr .. indent .. "  " .. prop.Name .. " = " .. dataToString(propValue, indentLevel + 1) .. ",\n"
            end
            return instanceStr .. indent .. "}"
        end
        return userdataValue(data) -- Assuming userdataValue is defined elsewhere
    end

    return tostring(data)
end

local function toUnicode(string)
    local codepoints = "utf8.char("
    
    for _i, v in utf8.codes(string) do
        codepoints = codepoints .. v .. ', '
    end
    
    return codepoints:sub(1, -3) .. ')'
end

methods.toString = toString
methods.dataToString = dataToString
methods.toUnicode = toUnicode
return methods