--[[______   __
  / ____/ | / / by: GNamimates, Discord: "@gn8.", Youtube: @GNamimates
 / / __/  |/ / a library for base64 decoding/encoding
/ /_/ / /|  /
\____/_/ |_/ Source: https://github.com/lua-gods/GNs-Avatar-3/blob/main/libraries/base64inator.lua]]

local b = {}

local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function charToValue(char) local index = string.find(chars, char, 1, true) return index and (index - 1) end
local function valueToChar(value) return string.sub(chars, value + 1, value + 1) end

---Converts base64 to a string.
---@param base64 string
---@return string
function b.decode(base64)
    local result = {}
    local value = 0
    local bits = 0
    
    for i = 1, #base64 do
        local char = string.sub(base64, i, i)
        if char == "=" then break end -- ignore padding
        local char_value = charToValue(char)
        if char_value then
            value = bit32.bor(bit32.lshift(value, 6), char_value)
            bits = bits + 6
            while bits >= 8 do
                local byte_value = bit32.band(bit32.rshift(value, bits - 8), 0xFF) -- extract the highest 8 bits
                result[#result + 1] = string.char(byte_value)
                bits = bits - 8
            end
        end
    end
    return table.concat(result)
end

---Converts a string to base64.
---@param str string
---@return string
function b.encode(str)
    local result = {}
    local value = 0
    local bits = 0
    
    for i = 1, #str do
        local byte_value = string.byte(str, i, i)
        value = bit32.bor(bit32.lshift(value, 8), byte_value)
        bits = bits + 8
        while bits >= 6 do
            local char_value = bit32.band(bit32.rshift(value, bits - 6), 0x3F) -- extract the highest 6 bits
            result[#result + 1] = valueToChar(char_value)
            bits = bits - 6
        end
    end
    if bits > 0 then
        local char_value = bit32.band(bit32.lshift(value, 6 - bits), 0x3F)
        result[#result + 1] = valueToChar(char_value)
    end
    local padding = #str % 3
    if padding == 1 then
        result[#result + 1] = "=="
    elseif padding == 2 then
        result[#result + 1] = "="
    end
    return table.concat(result)
end

return b
