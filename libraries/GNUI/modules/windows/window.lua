--[[______   __
  / ____/ | / / by: GNamimates, Discord: "@gn8.", Youtube: @GNamimates
 / / __/  |/ / Optional Module for GNUI that adds Desktop windows into GNUI.
/ /_/ / /|  / 
\____/_/ |_/ link
DEPENDENCIES
- GNUI
- GNUI Elements Module
]]
---@diagnostic disable: assign-type-mismatch



local isAlt = false
keybinds:newKeybind("window alt drag","key.keyboard.left.alt",true):onPress(function ()isAlt = true end):onRelease(function ()isAlt = false end)

local cfg = require((...):match("^(.*.GNUI).*$").."/config") ---@module "libraries.GNUI.config"
local gnui = require(cfg.path.."main")                       ---@module "libraries.GNUI.main"
local gnui_elements = require(cfg.path.."modules.elements")  ---@module "libraries.GNUI.modules.elements"
local themes = require(cfg.path.."modules.themes")           ---@module "libraries.GNUI.modules.themes"

local eventLib = require("libraries.eventLib")


local BDS = 3 -- Border Drag Size
local screen = gnui.getScreenCanvas()


local active_window
local ACTIVE_WINDOW_CHANGED = eventLib.new()

---@param container GNUI.Container
---@param window GNUI.Window
---@param fun function
local function applyDrag(container,window,fun)
   container:setZmultiplier(-0.1)
   container.INPUT:register(function (event)
      if event.key == "key.mouse.left"then
         if event.isPressed then
            window.Canvas.MOUSE_POSITION_CHANGED:register(function (mouse_event)
               fun(mouse_event)
            end,"window_drag"..window.id)
         else window.Canvas.MOUSE_POSITION_CHANGED:remove("window_drag"..window.id) end
      end
   end)
end

local windows = {}

---@class GNUI.Window : GNUI.Container
---@field Theme GNUI.theme
---@field TitleLabel GNUI.Label
---@field Title string
---@field Titlebar GNUI.Container
---@field ClientArea GNUI.Container
---@field CloseButton GNUI.Button
---@field MinimizeButton GNUI.Button
---@field MaximizeButton GNUI.Button
---@field Icon Sprite
---@field isActive boolean
---@field isMaximized boolean
---@field isGrabbed boolean
---@field CLOSE_REQUESTED eventLib
local Window = {}
Window.__index = function (t,i)
   return rawget(t,i) or Window[i] or gnui.Container[i] or gnui.Element[i]
end
Window.__type = "GNUI.Element.Container.Window"
Window.ACTIVE_WINDOW_CHANGED = ACTIVE_WINDOW_CHANGED


function Window.new()
   ---@type GNUI.Window
   local new = gnui.newContainer()
   new.type = "window"
   new.Title = ""
   new.isActive = false
   new.CLOSE_REQUESTED = eventLib.new()
   
   local titleBar = gnui.newContainer()
   new.Titlebar = titleBar
   new:addChild(titleBar)
   
   local label = gnui.newLabel()
   new.TitleLabel = label:setCanCaptureCursor(false)
   titleBar:addChild(label)
   
   local closeButton = gnui_elements.newButton("nothing")
   new.CloseButton = closeButton
   new:addChild(closeButton)
   
   local maximizeButton = gnui_elements.newButton("nothing")
   new.MaximizeButton = maximizeButton
   new:addChild(maximizeButton)
   
   local minimizeButton = gnui_elements.newButton("nothing")
   new.MinimizeButton = minimizeButton
   new:addChild(minimizeButton)
   
   new.ClientArea = gnui.newContainer():setAnchor(0,0,1,1)
   new:addChild(new.ClientArea)
   
   setmetatable(new,Window)
   themes.applyTheme(new)
   
   closeButton.PRESSED:register(function ()
      new.CLOSE_REQUESTED:invoke()
   end)
   new.CLOSE_REQUESTED:register(function ()
      new:close()
   end)
   
   local leftBorderDrag = gnui.newContainer()
   :setAnchor(0,0,0,1):setDimensions(0,BDS,BDS,-BDS)
   themes.applyTheme(leftBorderDrag,"window_border_drag")
   new:addChild(leftBorderDrag)
   applyDrag(leftBorderDrag,new,function (mouse_event)
      new:setDimensions(math.min(new.Dimensions.x + mouse_event.relative.x,new.Dimensions.z-new.SystemMinimumSize.x),new.Dimensions.y,new.Dimensions.z,new.Dimensions.w)
   end)
   
   local rightBorderDrag = gnui.newContainer()
   :setAnchor(1,0,1,1):setDimensions(-BDS,BDS,0,-BDS)
   themes.applyTheme(rightBorderDrag,"window_border_drag")
   new:addChild(rightBorderDrag)
   applyDrag(rightBorderDrag,new,function (mouse_event)
      new:setDimensions(new.Dimensions.x,new.Dimensions.y,math.max(new.Dimensions.z + mouse_event.relative.x,new.Dimensions.x+new.SystemMinimumSize.x),new.Dimensions.w)
   end)
   
   local topBorderDrag = gnui.newContainer()
   :setAnchor(0,0,1,0):setDimensions(BDS,0,-BDS,BDS)
   themes.applyTheme(topBorderDrag,"window_border_drag")
   new:addChild(topBorderDrag)
   applyDrag(topBorderDrag,new,function (mouse_event)
      new:setDimensions(new.Dimensions.x,math.min(new.Dimensions.y + mouse_event.relative.y,new.Dimensions.w-new.SystemMinimumSize.y),new.Dimensions.z,new.Dimensions.w)
   end)
   
   local bottomBorderDrag = gnui.newContainer()
   :setAnchor(0,1,1,1):setDimensions(BDS,-BDS,-BDS,0)
   themes.applyTheme(bottomBorderDrag,"window_border_drag")
   new:addChild(bottomBorderDrag)
   applyDrag(bottomBorderDrag,new,function (mouse_event)
      new:setDimensions(new.Dimensions.x,new.Dimensions.y,new.Dimensions.z,math.max(new.Dimensions.w + mouse_event.relative.y,new.Dimensions.y+new.SystemMinimumSize.y))
   end)
   
   local topRightCornerDrag = gnui.newContainer()
   :setAnchor(1,0):setDimensions(-BDS,0,0,BDS)
   themes.applyTheme(topRightCornerDrag,"window_border_drag")
   new:addChild(topRightCornerDrag)
   applyDrag(topRightCornerDrag,new,function (mouse_event)
      new:setDimensions(
         new.Dimensions.x,
         math.min(new.Dimensions.y + mouse_event.relative.y,new.Dimensions.w-new.SystemMinimumSize.y),
         math.max(new.Dimensions.z + mouse_event.relative.x,new.Dimensions.x+new.SystemMinimumSize.x),
         new.Dimensions.w)
   end)
   
   local bottomRightCornerDrag = gnui.newContainer()
   :setAnchor(1,1):setDimensions(-BDS,-BDS,0,0)
   themes.applyTheme(bottomRightCornerDrag,"window_border_drag")
   new:addChild(bottomRightCornerDrag)
   applyDrag(bottomRightCornerDrag,new,function (mouse_event)
      new:setDimensions(
         new.Dimensions.x,
         new.Dimensions.y,
         math.max(new.Dimensions.z + mouse_event.relative.x,new.Dimensions.x+new.SystemMinimumSize.x),
         math.max(new.Dimensions.w + mouse_event.relative.y,new.Dimensions.y+new.SystemMinimumSize.y))
   end)
   
   local bottomLeftCornerDrag = gnui.newContainer()
   :setAnchor(0,1):setDimensions(0,-BDS,BDS,0)
   themes.applyTheme(bottomLeftCornerDrag,"window_border_drag")
   new:addChild(bottomLeftCornerDrag)
   applyDrag(bottomLeftCornerDrag,new,function (mouse_event)
      new:setDimensions(
         math.min(new.Dimensions.x + mouse_event.relative.x,new.Dimensions.z-new.SystemMinimumSize.x),
         new.Dimensions.y,
         new.Dimensions.z,
         math.max(new.Dimensions.w + mouse_event.relative.y,new.Dimensions.y+new.SystemMinimumSize.y))
   end)
   
   local topLeftCornerDrag = gnui.newContainer()
   :setAnchor(0,0):setDimensions(0,0,BDS,BDS)
   themes.applyTheme(topLeftCornerDrag,"window_border_drag")
   new:addChild(topLeftCornerDrag)
   applyDrag(topLeftCornerDrag,new,function (mouse_event)
      new:setDimensions(
         math.min(new.Dimensions.x + mouse_event.relative.x,new.Dimensions.z-new.SystemMinimumSize.x),
         math.min(new.Dimensions.y + mouse_event.relative.y,new.Dimensions.w-new.SystemMinimumSize.y),
         new.Dimensions.z,
         new.Dimensions.w)
   end)
   
   local function setActive(a)
      leftBorderDrag:setVisible(a)
      rightBorderDrag:setVisible(a)
      topBorderDrag:setVisible(a)
      bottomBorderDrag:setVisible(a)
      topRightCornerDrag:setVisible(a)
      bottomRightCornerDrag:setVisible(a)
      bottomLeftCornerDrag:setVisible(a)
      topLeftCornerDrag:setVisible(a)
   end
   
   ACTIVE_WINDOW_CHANGED:register(function ()
      setActive(new.isActive)
      if new.isActive then
         new:setChildIndex(999)
      end
   end)
   setActive(false)
   
   new.isGrabbed = false
   local grab_canvas ---@type GNUI.Canvas
   ---@param event GNUI.InputEvent
   new.INPUT:register(function (event)
      if event.key == "key.mouse.left" and event.isPressed then
         new:setAsActiveWindow()
         return true
      end
   end)
   
   ---@param event GNUI.InputEvent
   new.Titlebar.INPUT:register(function (event)
      if event.key == "key.mouse.left"then
         new.isGrabbed = event.isPressed
         if event.isPressed then
            grab_canvas = new.Canvas
            ---@param mouse_event GNUI.InputEventMouseMotion
            new.Canvas.MOUSE_POSITION_CHANGED:register(function (mouse_event)
               new:setPos(new.Dimensions.xy+mouse_event.relative)
            end,"window_drag"..new.id)
         else
            if grab_canvas then
               grab_canvas.MOUSE_POSITION_CHANGED:remove("window_drag"..new.id)
            end
         end
      end
      return true
   end)
   
   -- alt controls
   ---@param event GNUI.InputEvent
   new.INPUT:register(function (event)
      if isAlt then
         if event.key == "key.mouse.left" then
            --if event.isPressed then
            --   new:setDimensions(new.Dimensions:copy():add(-5,-5,5,5))
            --   gnui.playSound("minecraft:entity.item.pickup",1,1)
            --else
            --   new:setDimensions(new.Dimensions:copy():add(5,5,-5,-5))
            --   gnui.playSound("minecraft:entity.item.pickup",1,1)
            --end
            titleBar.INPUT:invoke(event)
         end
         return true
      end
   end)
   
   windows[#windows+1] = new
   
   return new
end

function Window:setAsActiveWindow()
   if active_window ~= self then
      local old = active_window
      if active_window then
         active_window.isActive = false
      end
      active_window = self
      self.isActive = true
      ACTIVE_WINDOW_CHANGED:invoke(old,self)
   end
end


---Sets the title of the window.
---@param text string
---@return GNUI.Window
function Window:setTitle(text)
   self.TitleLabel:setText(text)
   return self
end

--- Adds a child to the client area of the window.
---@param child GNUI.any
---@param index integer?
---@return GNUI.Window
function Window:addElement(child,index)
   self.ClientArea:addChild(child,index)
   return self
end


---Deletes the window.
function Window:close()
   self:free()
end


function Window.clearActiveWindow()
   if active_window then
      active_window.isActive = false
   end
   ACTIVE_WINDOW_CHANGED:invoke(active_window,nil)
   active_window = nil
end


-->====================[ QOL Stuffs ]====================<--

---@param event GNUI.InputEvent
screen.INPUT:register(function (event)
   if event.key == "key.mouse.left" and event.isPressed then
      Window.clearActiveWindow()
   end
end)

screen.SIZE_CHANGED:register(function (screenSize,lastScreenSize)
   if lastScreenSize then
      local screenDiff = screenSize - lastScreenSize
      ---@param w GNUI.Window
      for _, w in pairs(windows) do
         local center = w.ContainmentRect.xy + w.Size / 2
         local anchor = (center / lastScreenSize * 3):floor() / 2
         w:setTitle(tostring(anchor))
         w:setPos(w.ContainmentRect.xy + screenDiff * anchor)
      end
   end
end)

return Window