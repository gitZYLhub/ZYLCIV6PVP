-- Safe serializer for Detailed Map Tacks' PlayerConfiguration cache.
--
-- Upstream encoded Lua source and evaluated it at load time. ZYLPVPMOD stores
-- the same primitive/table data in a length-prefixed format instead. Old DMT
-- cache strings are ignored; the yield calculator rebuilds them from the
-- player's actual map pins on the next load.

local function EncodeValue(value, activeTables)
    local valueType = type(value);
    if valueType == "nil" then
        return "N";
    elseif valueType == "boolean" then
        return value and "B1" or "B0";
    elseif valueType == "number" then
        local text = tostring(value);
        return "D" .. #text .. ":" .. text;
    elseif valueType == "string" then
        return "S" .. #value .. ":" .. value;
    elseif valueType == "table" then
        if activeTables[value] then
            error("DMT cache cannot serialize recursive tables");
        end
        activeTables[value] = true;

        local entries = {};
        for key, childValue in pairs(value) do
            local encodedKey = EncodeValue(key, activeTables);
            local encodedValue = EncodeValue(childValue, activeTables);
            table.insert(entries, { Key = encodedKey, Value = encodedValue });
        end
        table.sort(entries, function(left, right) return left.Key < right.Key; end);

        local parts = {};
        for _, entry in ipairs(entries) do
            table.insert(parts, entry.Key);
            table.insert(parts, entry.Value);
        end
        activeTables[value] = nil;
        return "T" .. #entries .. ":" .. table.concat(parts);
    end

    error("DMT cache cannot serialize values of type " .. valueType);
end

local function ReadLength(data, index)
    local colon = string.find(data, ":", index, true);
    if colon == nil then error("Missing DMT cache length separator"); end
    local length = tonumber(string.sub(data, index, colon - 1));
    if length == nil or length < 0 or length % 1 ~= 0 then
        error("Invalid DMT cache length");
    end
    return length, colon + 1;
end

local DecodeValue;
DecodeValue = function(data, index)
    local tag = string.sub(data, index, index);
    if tag == "N" then
        return nil, index + 1;
    elseif tag == "B" then
        local flag = string.sub(data, index + 1, index + 1);
        if flag == "1" then return true, index + 2; end
        if flag == "0" then return false, index + 2; end
        error("Invalid DMT cache boolean");
    elseif tag == "D" or tag == "S" then
        local length, valueStart = ReadLength(data, index + 1);
        local valueEnd = valueStart + length - 1;
        if valueEnd > #data then error("Truncated DMT cache value"); end
        local text = string.sub(data, valueStart, valueEnd);
        if tag == "D" then
            local numberValue = tonumber(text);
            if numberValue == nil then error("Invalid DMT cache number"); end
            return numberValue, valueEnd + 1;
        end
        return text, valueEnd + 1;
    elseif tag == "T" then
        local count, nextIndex = ReadLength(data, index + 1);
        local result = {};
        for _ = 1, count do
            local key;
            key, nextIndex = DecodeValue(data, nextIndex);
            if key == nil then error("Nil DMT cache table key"); end
            local childValue;
            childValue, nextIndex = DecodeValue(data, nextIndex);
            result[key] = childValue;
        end
        return result, nextIndex;
    end

    error("Unknown DMT cache type tag");
end

function serialize(value)
    return EncodeValue(value, {});
end

function deserialize(data)
    if type(data) ~= "string" or #data == 0 then return nil; end
    local firstTag = string.sub(data, 1, 1);
    if firstTag ~= "N" and firstTag ~= "B" and firstTag ~= "D" and
            firstTag ~= "S" and firstTag ~= "T" then
        -- Cache written by upstream DMT's executable-source serializer.
        return nil;
    end

    local ok, value, nextIndex = pcall(DecodeValue, data, 1);
    if not ok or nextIndex ~= #data + 1 then
        print("DMT: ignored an invalid map-pin yield cache");
        return nil;
    end
    return value;
end
