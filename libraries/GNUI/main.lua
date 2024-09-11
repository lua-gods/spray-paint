--[[______   __
  / ____/ | / / By: GNamimates
 / / __/  |/ / GNUI v2.0.0
/ /_/ / /|  / A high level UI library for figura.
\____/_/ |_/ Stable Release: https://github.com/lua-gods/GNUI, Unstable Pre-release: https://github.com/lua-gods/GNs-Avatar-3/blob/main/libraries/gnui.lua]]

--[[ NOTES
Everything is in one file to make sure it is possible to load this script from a config file, 
allowing me to put as much as I want without worrying about storage space.
]]

local cfg = require(....."/config")
---@class GNUI

local api = {path = cfg.path}
---@alias GNUI.any GNUI.Element|GNUI.Container|GNUI.Label|GNUI.AnchorPoint|GNUI.Canvas

local u = require(cfg.path.."/utils")
local l = require(cfg.path.."/primitives.label")
local s = require(cfg.path.."/spriteLib")
local ca = require(cfg.path.."/primitives/canvas")
local e = require(cfg.path.."/primitives/element")
local co = require(cfg.path.."/primitives/container")
local a = require(cfg.path.."/primitives/anchor")

---@return GNUI.AnchorPoint
api.newPointAnchor = function ()return a.new()end

---@return GNUI.Container
api.newContainer = function ()return co.new() end

---@param autoInputs boolean # true when the canvas should capture the inputs from the screen.
---@return unknown
api.newCanvas = function (autoInputs)return ca.new(autoInputs) end
api.newLabel = function ()return l.new() end

---@param texture Texture?
---@return Sprite
api.newSprite = function (texture)
  return s.new()
end

api.utils = u

api.Container = co
api.Anchor = a
api.Element = e
api.Canvas = ca
api.Sprite = s
api.Label = l

local screenCanvas
---Gets a canvas for the screen. Quick startup for putting UI elements onto the screen.
---@return GNUI.Canvas
function api.getScreenCanvas()
  if not screenCanvas then
    screenCanvas = api.newCanvas(true)
    models:addChild(screenCanvas.ModelPart)
    screenCanvas.ModelPart:setParentType("HUD")
  
    local lastWindowSize = vec(0,0)
    events.WORLD_RENDER:register(function (delta)
      local windowSize = client:getScaledWindowSize()
      
      if windowSize.x ~= lastWindowSize.x
      or windowSize.y ~= lastWindowSize.y then
        lastWindowSize = windowSize
        screenCanvas:setDimensions(0,0,windowSize.x,windowSize.y)
      end
    end)
    screenCanvas:setDimensions(0,0,client:getScaledWindowSize().x,client:getScaledWindowSize().y)
  end
  return screenCanvas
end

---@param sound Minecraft.soundID
---@param pitch number
---@param volume number
function api.playSound(sound,pitch,volume)
  sounds[sound]:pos(client:getCameraPos():add(client:getCameraDir())):pitch(pitch or 1):volume(volume or 1):attenuation(9999):play()
end

return api