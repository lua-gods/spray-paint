local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local GNUI = require(cfg.path.."main")
local texture = textures["libraries.GNUI.modules.theme.textures.default_window"]

return {
   Window = {
      ---@param container GNUI.Window
      default = function (container)
         local sprite_border_normal = GNUI.newSprite():setTexture(texture):setUV(23,1,25,10):setBorderThickness(1,8,1,1)
         local sprite_border_active = GNUI.newSprite():setTexture(texture):setUV(1,23,5,27):setBorderThickness(2,2,2,2)
         container:setSprite(sprite_border_active)
         
         local sprite_titlebar_normal = GNUI.newSprite():setTexture(texture):setUV(23,1,25,10):setBorderThickness(1,8,1,1)
         local sprite_titlebar_active = GNUI.newSprite():setTexture(texture):setUV(1,17,5,21):setBorderThickness(2,2,2,2)
         container.Titlebar:setSprite(sprite_titlebar_active)
         container.Titlebar:setAnchor(0,0,1,0):setDimensions(1,1,-1,12)
         
         container.TitleLabel:setDefaultColor("#1e6f50")
         :setText("Unknown")
         :setAnchor(0,0,1,1):setDimensions(2,2,-2,-2)
         
         container.ClientArea:setDimensions(2,12,-2,-2):setAnchor(0,0,1,1)
         
         
         local close_button = container.CloseButton
         local sprite_close_normal = GNUI.newSprite():setTexture(texture):setUV(14,1,20,7)
         local sprite_close_highlight = GNUI.newSprite():setTexture(texture):setUV(14,9,20,15)
         close_button:setSprite(sprite_close_normal)
         close_button.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               close_button:setSprite(sprite_close_normal)
            else
               if hovered then
                  close_button:setSprite(sprite_close_highlight)
               else 
                  close_button:setSprite(sprite_close_normal)
               end 
            end
         end)
         close_button:setAnchor(1,0,1,0):setDimensions(-10,3,-3,10)
         
         local maximize_button = container.MaximizeButton
         local sprite_maximize_normal = GNUI.newSprite():setTexture(texture):setUV(8,1,14,7)
         local sprite_maximize_highlight = GNUI.newSprite():setTexture(texture):setUV(8,9,14,15)
         
         maximize_button:setSprite(sprite_maximize_normal)
         maximize_button.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               maximize_button:setSprite(sprite_maximize_normal)
            else
               if hovered then
                  maximize_button:setSprite(sprite_maximize_highlight)
               else 
                  maximize_button:setSprite(sprite_maximize_normal)
               end 
            end
         end)
         maximize_button:setAnchor(1,0,1,0):setDimensions(-17,3,-10,10)
         
         local sprite_normal = GNUI.newSprite():setTexture(texture):setUV(1,1,7,7)
         local sprite_highlight = GNUI.newSprite():setTexture(texture):setUV(1,9,7,15)
         
         local minimizeButton = container.MinimizeButton
         minimizeButton:setSprite(sprite_normal)
         minimizeButton.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               minimizeButton:setSprite(sprite_normal)
            else
               if hovered then
                  minimizeButton:setSprite(sprite_highlight)
               else 
                  minimizeButton:setSprite(sprite_normal)
               end 
            end
         end)
         minimizeButton:setAnchor(1,0,1,0):setDimensions(-24,3,-17,10)
      end,
   },
   Container = {
      ---@param container GNUI.Container
      window_border_drag = function (container)
         local sprite_border_normal = GNUI.newSprite():setTexture(texture):setUV(1,29,1,29)
         local sprite_border_active = GNUI.newSprite():setTexture(texture):setUV(3,29,3,29)
         container.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               container:setSprite(sprite_border_active)
            else
               if hovered then
                  container:setSprite(sprite_border_active)
               else 
                  container:setSprite(sprite_border_normal)
               end 
            end
         end)
         container:setSprite(sprite_border_normal)
      end
   },
   TextButton = {
      ---@param container GNUI.TextButton
      directory = function (container,isFile,type)
         local label = container.label
         
         local sprite_normal = GNUI.newSprite():setTexture(texture):setUV(13,17,13,18):setBorderThickness(0,0,0,1)
         local sprite_hovered = GNUI.newSprite():setTexture(texture):setUV(15,17,15,18):setBorderThickness(0,0,0,1)
         local sprite_pressed = GNUI.newSprite():setTexture(texture):setUV(17,17,17,18):setBorderThickness(0,0,0,1)
         
         local sprite_icon
         if isFile then
            if type == ".ogg" then
               sprite_icon = GNUI.newSprite():setTexture(texture):setUV(20,18,28,27) -- music
            elseif type == ".png" then
               sprite_icon = GNUI.newSprite():setTexture(texture):setUV(20,28,28,37) -- image
            elseif type == ".lua" then
               sprite_icon = GNUI.newSprite():setTexture(texture):setUV(20,38,28,47) -- lua
            else
               sprite_icon = GNUI.newSprite():setTexture(texture):setUV(20,0,28,9) -- file
            end
         else
            sprite_icon = GNUI.newSprite():setTexture(texture):setUV(20,9,28,18) -- folder
         end
         
         container:setSprite(sprite_normal)
         container.MOUSE_PRESSENCE_CHANGED:register(function (hovered,pressed)
            if pressed then
               container:setSprite(sprite_pressed)
            else
               if hovered then container:setSprite(sprite_hovered)
               else container:setSprite(sprite_normal)
               end 
            end
         end)
         
         container:addChild(GNUI.newContainer():setSprite(sprite_icon):setAnchor(0,0.5):setPos(4,-5):setSize(9,9))
         
         label:setAnchor(0,0,1,1)
         label:setDimensions(16,2,-2,-2)
         label:setDefaultColor('gray')
         label:setCanCaptureCursor(false)
         label:setAlign(0,0.5)
         container:setSystemMinimumSize(0,16)
      end,
   },
}
