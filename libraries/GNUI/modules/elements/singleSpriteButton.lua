---@diagnostic disable: assign-type-mismatch
-- Serves as a way to create buttons with custom textures without having to make a theme for it.

local cfg = require((...):match("^(.*.GNUI).*$").."/config")

local gnui = require(cfg.path.."main")
local button = require(cfg.path.."modules.elements.button")

---@class GNUI.SingleSpriteButton : GNUI.Button
---@field Sprite Sprite
local SSB = {}
SSB.__index = function (t,i)
   return rawget(t,i) or SSB[i] or button[i] or gnui.Container[i] or gnui.Element[i]
end
SSB.__type = "GNUI.Element.Container.Button.SingleSpriteButton"

local setSprite = gnui.Container.setSprite

---Creates a new button.
---@param sprite Sprite
---@return GNUI.SingleSpriteButton
function SSB.new(sprite)
   ---@type GNUI.SingleSpriteButton
   local new = button.new()
   setmetatable(new,SSB)
   if sprite then
      new:setSprite(sprite)
   end
   ---@param hovered boolean
   ---@param pressed boolean
   new.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
      if new.sprite then
         if pressed then
            setSprite(new,new.sprite_pressed)
         else
            if hovered then
               setSprite(new,new.sprite_hover)
            else
               setSprite(new,new.sprite_normal)
            end
         end
      end
   end)
   return new
end


---Sets the texture being used for the button.
---@param sprite Sprite
---@return GNUI.SingleSpriteButton
function SSB:setSprite(sprite)
   if type(sprite) ~= "Sprite" then
      error("argument 1 expected 'Sprite', got "..type(sprite),2)
   end
   self.sprite = sprite
   if sprite then
      self.sprite_pressed = sprite:copy():setColor(0.5,0.5,0.5)
      self.sprite_hover = sprite:copy():setColor(0.9,0.9,0.9)
      self.sprite_normal = sprite:copy():setColor(1,1,1)
   else
      
      if self.sprite_pressed then
         self.sprite_pressed:free() self.sprite_pressed = nil
      end
      if self.sprite_hover then
         self.sprite_hover:free() self.sprite_hover = nil
      end
      if self.sprite_normal then
         self.sprite_normal:free() self.sprite_normal = nil
      end
   end
   setSprite(self,self.sprite)
   return self
end


return SSB