local gnui = require("libraries.GNUI.main")
local texture = textures["libraries.GNUI.modules.theme.textures.element_default"]

---@type GNUI.theme
return {
   TextButton = {
      ---@param container GNUI.TextButton
      default = function (container)
         local label = container.label
         
         local sprite_normal = gnui.newSprite():setTexture(texture):setUV(9,2,13,8):setBorderThickness(2,2,2,4)
         local sprite_hovered = gnui.newSprite():setTexture(texture):setUV(15,2,19,8):setBorderThickness(2,2,2,4)
         local sprite_pressed = gnui.newSprite():setTexture(texture):setUV(21,2,25,8):setBorderThickness(2,4,2,2)
         
         container:setSprite(sprite_normal)
         container.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               container:setSprite(sprite_pressed)
               label:setDimensions(2,6,-2,-2)
            else
               if hovered then container:setSprite(sprite_hovered)
               else container:setSprite(sprite_normal)
               end label:setDimensions(2,2,-2,-2)
            end
         end)
         
         label:setAnchor(0,0,1,1)
         label:setDimensions(2,2,-2,-2)
         label:setText("Text")
         label:setDefaultColor('black')
         label:setCanCaptureCursor(false)
         label:setAlign(0.5,0.5)
         container:setSystemMinimumSize(0,16)
      end,
   },
   TextInputField = {
      ---@param container GNUI.TextInputField
      default = function (container)
         container.Label:setDimensions(3,2,-3,-2)
         container:setSystemMinimumSize(8,12)
         
         local sprite_normal = gnui.newSprite():setTexture(texture):setUV(9,25,13,29):setBorderThickness(2,2,2,2)
         local sprite_hovered = gnui.newSprite():setTexture(texture):setUV(15,25,19,29):setBorderThickness(2,2,2,2)
         local sprite_pressed = gnui.newSprite():setTexture(texture):setUV(21,25,25,29):setBorderThickness(2,2,2,2)
         
         container:setSprite(sprite_normal)
         container.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               container:setSprite(sprite_pressed)
            else
               if hovered or container.editing then container:setSprite(sprite_hovered)
               else container:setSprite(sprite_normal)
               end 
            end
            if math.max(#container.ConfirmedText,#container.PotentialText) > 0 then
               container.Label:setDefaultColor("white")
            else
               container.Label:setDefaultColor("#5c5c5c")
            end
         end)
      end
   },
   Container = {
      ---@param container GNUI.Container
      solid = function (container)
         local sprite = gnui.newSprite():setTexture(texture):setUV(1,32,3,34):setBorderThickness(2,2,2,2)
         container:setSprite(sprite)
      end
   },
   ScrollbarButton = {
      ---@param container GNUI.ScrollbarButton
      default = function (container)
         local trackSprite = gnui.newSprite():setTexture(texture):setUV(35,18,39,22):setBorderThickness(2,2,2,2)
         container:setSprite(trackSprite)
         
         local scrollbarSprite = gnui.newSprite():setTexture(texture):setUV(23,17,27,22):setBorderThickness(2,2,2,3)
         container.Scrollbar:setSprite(scrollbarSprite)
      end
   }
}