--[[██╗██╗██████╗░███████╗
  ░██╔╝██║██╔══██╗██╔════╝
  ██╔╝░██║██████╔╝██████╗░
  ███████║██╔═══╝░╚════██╗
  ╚════██║██║░░░░░██████╔╝
  ░░░░░╚═╝╚═╝░░░░░╚═════]]
---@class File
---@field path string
local File = {}
File.__index = File

---@param path string
function File.new(path)
    local self = setmetatable({}, File)
    self.path = path
    return self
end

---@param path string
---@return File[]
function File.dir(path)
    if not path or not file:allowed() or not file:exists(path) then return {} end
    local list = {}
    local files = file:list(path) or {}
    for i = 1, #files do
        list[#list + 1] = File.new(path .. "/" .. files[i])
    end
    return list
end

---@return boolean
function File:exists()
    return file:exists(self.path)
end

---@return string
function File:readString()
    if not self:exists() then return "" end
    return file:readString(self.path)
end

---@return string
function File:readByteArray()
    if not self:exists() then return "" end
    local dat = file:openReadStream(self.path)
    local available = dat:available()
    local buf = data:createBuffer(available)
    buf:readFromStream(dat, available)
    buf:setPosition(0)
    local str = buf:readByteArray(available)
    dat:close()
    buf:close()
    return str
end

---@return string
function File:readBase64()
    if not self:exists() then return "" end
    local dat = file:openReadStream(self.path)
    local available = dat:available()
    local buf = data:createBuffer(available)
    buf:readFromStream(dat, available)
    buf:setPosition(0)
    local str = buf:readBase64(available)
    dat:close()
    buf:close()
    return str
end

---@return number
function File:__len()
    if not self:exists() then return 0 end
    local dat = file:openReadStream(self.path)
    local available = dat:available()
    dat:close()
    return available
end

return File