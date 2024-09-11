---@diagnostic disable: assign-type-mismatch
-- The Base class for all buttons. does not contain any visual elements.

local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local gnui = require(cfg.path.."main")
local eventLib = cfg.event


---@class GNUI.Button : GNUI.Container
local Button = {}
Button.__index = function (t,i)
   return rawget(t,i) or Button[i] or gnui.Container[i] or gnui.Element[i]
end
Button.__type = "GNUI.Element.Container.Button"

---Creates a new button.
---@return GNUI.Button
function Button.new(variant,theme)
   variant = variant or "default"
   theme = theme or "default"
   ---@type GNUI.Button
   local new = gnui.newContainer()
   new.PRESSED = eventLib.new()
   new.BUTTON_DOWN = eventLib.new()
   new.BUTTON_UP = eventLib.new()
   setmetatable(new,Button)
   new.cache.was_pressed = false
   ---@param event GNUI.InputEvent
   new.INPUT:register(function (event)
      if event.key == "key.mouse.left" then
         if event.isPressed then new.BUTTON_DOWN:invoke()
         else new.BUTTON_UP:invoke() gnui.playSound("minecraft:ui.button.click",1,1) end
         if new.isCursorHovering then
            if not event.isPressed and new.cache.was_pressed then
               new.PRESSED:invoke()
            end
            new.cache.was_pressed = event.isPressed
         end
      end
   end,"_button")
   return new
end

return Button