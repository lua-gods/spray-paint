---@diagnostic disable: assign-type-mismatch
-- Serves as a way to create buttons with custom textures without having to make a theme for it.

local cfg = require((...):match("^(.*.GNUI).*$").."/config")

local gnui = require(cfg.path.."main")
local button = require(cfg.path.."modules.elements.button")

---@class GNUI.TextureButton : GNUI.Button
---@field sprite_pressed Sprite
---@field sprite_hover Sprite
---@field sprite_normal Sprite
local TextureButton = {}
TextureButton.__index = function (t,i)
   return rawget(t,i) or TextureButton[i] or button[i] or gnui.Container[i] or gnui.Element[i]
end
TextureButton.__type = "GNUI.Element.Container.Button.TextButton"

---Creates a new button.
---@param normal Sprite?
---@param pressed Sprite?
---@param hovered Sprite?
---@return GNUI.TextureButton
function TextureButton.new(normal,pressed,hovered)
   ---@type GNUI.TextureButton
   local new = button.new()
   new.sprite_normal = normal
   new.sprite_pressed = pressed
   new.sprite_hover = hovered
   setmetatable(new,TextureButton)
   return new
end


---Sets the sprite that displays when the button is pressed
---@param sprite Sprite?
---@return GNUI.TextureButton
function TextureButton:setSpriteNormal(sprite)
   self.sprite_normal = sprite
   return self
end

---Sets the sprite that displays when the button is hovered
---@param sprite Sprite?
---@return GNUI.TextureButton
function TextureButton:setSpriteHover(sprite)
   self.sprite_hover = sprite
   return self
end

---Sets the sprite that displays when the button is pressed
---@param sprite Sprite?
---@return GNUI.TextureButton
function TextureButton:setSpritePressed(sprite)
   self.sprite_pressed = sprite
   return self
end

return TextureButton