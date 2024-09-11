--[[______   __
  / ____/ | / / by: GNamimates | Discord: "@gn8." | Youtube: @GNamimates
 / / __/  |/ / Sprite Library, specifically made for GNUI and its needs.
/ /_/ / /|  /
\____/_/ |_/]]
local default_texture = textures["1x1white"] or textures:newTexture("1x1white",1,1):setPixel(0,0,vec(1,1,1))
local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local eventLib,utils = cfg.event, cfg.utils

local update = {}

---@class Sprite
---@field Texture Texture
---@field TEXTURE_CHANGED eventLib
---@field Modelpart ModelPart?
---@field MODELPART_CHANGED eventLib
---@field UV Vector4
---@field Size Vector2
---@field Position Vector2
---@field Color Vector3
---@field Alpha number
---@field Scale number
---@field DIMENSIONS_CHANGED eventLib
---@field RenderTasks table<any,SpriteTask>
---@field RenderType ModelPart.renderType
---@field BorderThickness Vector4
---@field BORDER_THICKNESS_CHANGED eventLib
---@field ExcludeMiddle boolean
---@field DepthOffset number
---@field Visible boolean
---@field id integer
---@field package _queue_update boolean
local Ninepatch = {}
Ninepatch.__index = Ninepatch
Ninepatch.__type = "Sprite"

local sprite_next_free = 0
---@return Sprite
function Ninepatch.new(obj)
   obj = obj or {}
   local new = {}
   setmetatable(new,Ninepatch)
   new.Texture = obj.Texture or default_texture
   new.TEXTURE_CHANGED = eventLib.new()
   new.MODELPART_CHANGED = eventLib.new()
   new.Position = obj.Position or vec(0,0)
   new.DepthOffset = 0
   new.UV = obj.UV or vec(0,0,1,1)
   new.Size = obj.Size or vec(0,0)
   new.Alpha = obj.Alpha or 1
   new.Color = obj.Color or vec(1,1,1)
   new.Scale = obj.Scale or 1
   new.DIMENSIONS_CHANGED = eventLib.new()
   new.RenderTasks = {}
   new.RenderType = obj.RenderType or "CUTOUT"
   new.BorderThickness = obj.BorderThickness or vec(0,0,0,0)
   new.BORDER_THICKNESS_CHANGED = eventLib.new()
   new.ExcludeMiddle = obj.ExcludeMiddle or false
   new.Visible = true
   new.id = sprite_next_free
   sprite_next_free = sprite_next_free + 1
   
   new.TEXTURE_CHANGED:register(function ()
      new:deleteRenderTasks()
      new:buildRenderTasks()
      new:update()
   end,cfg.internal_events_name)

   new.BORDER_THICKNESS_CHANGED:register(function ()
      new:deleteRenderTasks()
      new:buildRenderTasks()
   end,cfg.internal_events_name)
   
   new.DIMENSIONS_CHANGED:register(function ()
      new:update()
   end,cfg.internal_events_name)
   return new
end

---Sets the modelpart to parent to.
---@param part ModelPart
---@return Sprite
function Ninepatch:setModelpart(part)
   if self.Modelpart then
      self:deleteRenderTasks()
   end
   self.Modelpart = part
   self:buildRenderTasks()
   self.MODELPART_CHANGED:invoke(self.Modelpart)
   return self
end


---Sets the displayed image texture on the sprite.
---@param texture Texture
---@return Sprite
function Ninepatch:setTexture(texture)
   if type(texture) ~= "Texture" then error("Invalid texture, recived "..type(texture)..".",2) end
   self.Texture = texture
   local dim = texture:getDimensions()
   self.UV = vec(0,0,dim.x-1,dim.y-1)
   self.TEXTURE_CHANGED:invoke(self,self.Texture)
   return self
end

---Sets the position of the Sprite, relative to its parent.
---@param xpos number
---@param y number
---@return Sprite
function Ninepatch:setPos(xpos,y)
   self.Position = utils.figureOutVec2(xpos,y)
   self.DIMENSIONS_CHANGED:invoke(self,self.Position,self.Size)
   return self
end

---Tints the Sprite multiplicatively
---@overload fun(self : self, rgb : Vector3): Sprite
---@param r number
---@param g number
---@param b number
---@return Sprite
function Ninepatch:setColor(r,g,b)
   self.Color = utils.figureOutVec3(r,g,b)
   self.DIMENSIONS_CHANGED:invoke(self,self.Position,self.Size)
   return self
end


---@param a number
---@return Sprite
function Ninepatch:setOpacity(a)
   self.Alpha = math.clamp(a or 1,0,1)
   self.DIMENSIONS_CHANGED:invoke(self,self.Position,self.Size)
   return self
end

---Sets the size of the sprite duh.
---@param xpos number
---@param y number
---@return Sprite
function Ninepatch:setSize(xpos,y)
   self.Size = utils.figureOutVec2(xpos,y)
   self.DIMENSIONS_CHANGED:invoke(self,self.Position,self.Size)
   return self
end

---@param scale number
---@return Sprite
function Ninepatch:setScale(scale)
   self.Scale = scale
   self.BORDER_THICKNESS_CHANGED:invoke(self,self.BorderThickness)
   return self
end

-->====================[ Border ]====================<--

---Sets the top border thickness.
---@param units number?
---@return Sprite
function Ninepatch:setBorderThicknessTop(units)
   self.BorderThickness.y = units or 0
   self.BORDER_THICKNESS_CHANGED:invoke(self,self.BorderThickness)
   return self
end

---Sets the left border thickness.
---@param units number?
---@return Sprite
function Ninepatch:setBorderThicknessLeft(units)
   self.BorderThickness.x = units or 0
   self.BORDER_THICKNESS_CHANGED:invoke(self,self.BorderThickness)
   return self
end

---Sets the down border thickness.
---@param units number?
---@return Sprite
function Ninepatch:setBorderThicknessDown(units)
   self.BorderThickness.z = units or 0
   self.BORDER_THICKNESS_CHANGED:invoke(self,self.BorderThickness)
   return self
end

---Sets the right border thickness.
---@param units number?
---@return Sprite
function Ninepatch:setBorderThicknessRight(units)
   self.BorderThickness.w = units or 0
   self.BORDER_THICKNESS_CHANGED:invoke(self,self.BorderThickness)
   return self
end

---Sets the padding for all sides.
---@param left number?
---@param top number?
---@param right number?
---@param bottom number?
---@return Sprite
function Ninepatch:setBorderThickness(left,top,right,bottom)
   self.BorderThickness.x = left   or 0
   self.BorderThickness.y = top    or 0
   self.BorderThickness.z = right  or 0
   self.BorderThickness.w = bottom or 0
   self.BORDER_THICKNESS_CHANGED:invoke(self,self.BorderThickness)
   return self
end

---Sets the UV region of the sprite.
--- if x2 and y2 are missing, they will use x and y as a substitute
---@overload fun(self : Sprite, vec4 : Vector4): Sprite
---@param x number
---@param y number
---@param x2 number
---@param y2 number
---@return Sprite
function Ninepatch:setUV(x,y,x2,y2)
   self.UV = utils.figureOutVec4(x,y,x2 or x,y2 or y)
   self.DIMENSIONS_CHANGED:invoke(self.BorderThickness)
   return self
end

---Sets the render type of your sprite
---@param renderType ModelPart.renderType
---@return Sprite
function Ninepatch:setRenderType(renderType)
   self.RenderType = renderType
   self:deleteRenderTasks()
   self:buildRenderTasks()
   return self
end

---Set to true if you want a hole in the middle of your ninepatch
---@param toggle boolean
---@return Sprite
function Ninepatch:excludeMiddle(toggle)
   self.ExcludeMiddle = toggle
   return self
end

function Ninepatch:copy()
   local copy = {}
   for key, value in pairs(self) do
      if type(value):find("Vector") then
         value = value:copy()
      end
      copy[key] = value
   end
   return Ninepatch.new(copy)
end

function Ninepatch:setVisible(visibility)
   self.Visible = visibility
   self:update()
   return self
end

function Ninepatch:setDepthOffset(offset_units)
   self.DepthOffset = offset_units
   return self
end

function Ninepatch:update()
   if not self._queue_update then
      self._queue_update = true
      update[#update+1] = self
   end
end

function Ninepatch:deleteRenderTasks()
   for _, task in pairs(self.RenderTasks) do
      self.Modelpart:removeTask(task:getName())
   end
   return self
end

function Ninepatch:free()
   self:deleteRenderTasks()
   return self
end

function Ninepatch:buildRenderTasks()
   if not self.Modelpart then return self end
   local b = self.BorderThickness
   local d = self.Texture:getDimensions()
   self.is_ninepatch = not (b.x == 0 and b.y == 0 and b.z == 0 and b.w == 0)
   if not self.is_ninepatch then -- not 9-Patch
      self.RenderTasks[1] = self.Modelpart:newSprite(self.id.."patch"):setTexture(self.Texture,d.x,d.y)
   else
      self.RenderTasks = {
         self.Modelpart:newSprite(self.id.."patch_tl" ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_t"  ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_tr" ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_ml" ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_m"  ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_mr" ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_bl" ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_b"  ):setTexture(self.Texture,d.x,d.y):setVisible(false),
         self.Modelpart:newSprite(self.id.."patch_br" ):setTexture(self.Texture,d.x,d.y):setVisible(false),
      }
   end
   self:update()
end

function Ninepatch:updateRenderTasks()
   if not self.Modelpart then return self end
   local res = self.Texture:getDimensions()
   local uv = self.UV:copy():add(0,0,1,1)
   local pos = vec(self.Position.x,self.Position.y,self.DepthOffset)
   if not self.is_ninepatch then
      self.RenderTasks[1]
      :setPos(pos)
      :setScale(self.Size.x/res.x,self.Size.y/res.y,0)
      :setColor(self.Color:augmented(self.Alpha))
      :setRenderType(self.RenderType)
      :setUVPixels(
         uv.x,
         uv.y
      ):region(
         uv.z-uv.x,
         uv.w-uv.y
      ):setVisible(self.Visible)
   else
      local sborder = self.BorderThickness*self.Scale --scaled border, used in rendering
      local border = self.BorderThickness             --border, used in UVs
      local size = self.Size
      local uvsize = vec(uv.z-uv.x,uv.w-uv.y)
      for _, task in pairs(self.RenderTasks) do
         task
         :setColor(self.Color:augmented(self.Alpha))
         :setRenderType(self.RenderType)
      end
      self.RenderTasks[1]
      :setPos(
         pos
      ):setScale(
         sborder.x/res.x,
         sborder.y/res.y,0
      ):setUVPixels(
         uv.x,
         uv.y
      ):region(
         border.x,
         border.y
      ):setVisible(self.Visible)
      
      self.RenderTasks[2]
      :setPos(
         pos.x-sborder.x,
         pos.y,
         pos.z
      ):setScale(
         (size.x-sborder.z-sborder.x)/res.x,
         sborder.y/res.y,0
      ):setUVPixels(
         uv.x+border.x,
         uv.y
      ):region(
         uvsize.x-border.x-border.z,
         border.y
      ):setVisible(self.Visible)

      self.RenderTasks[3]
      :setPos(
         pos.x-size.x+sborder.z,
         pos.y,
         pos.z
      ):setScale(
         sborder.z/res.x,sborder.y/res.y,0
      ):setUVPixels(
         uv.z-border.z,
         uv.y
      ):region(
         border.z,
         border.y
      ):setVisible(self.Visible)

      self.RenderTasks[4]
      :setPos(
         pos.x,
         pos.y-sborder.y,
         pos.z
      ):setScale(
         sborder.x/res.x,
         (size.y-sborder.y-sborder.w)/res.y,0
      ):setUVPixels(
         uv.x,
         uv.y+border.y
      ):region(
         border.x,
         uvsize.y-border.y-border.w
      ):setVisible(self.Visible)
      if not self.ExcludeMiddle then
         self.RenderTasks[5]
         :setPos(
            pos.x-sborder.x,
            pos.y-sborder.y,
            pos.z
         )
         :setScale(
            (size.x-sborder.x-sborder.z)/res.x,
            (size.y-sborder.y-sborder.w)/res.y,0
         ):setUVPixels(
            uv.x+border.x,
            uv.y+border.y
         ):region(
            uvsize.x-border.x-border.z,
            uvsize.y-border.y-border.w
         ):setVisible(self.Visible)
      else
         self.RenderTasks[5]:setVisible(false)
      end

      self.RenderTasks[6]
      :setPos(
         pos.x-size.x+sborder.z,
         pos.y-sborder.y,
         pos.z
      )
      :setScale(
         sborder.z/res.x,
         (size.y-sborder.y-sborder.w)/res.y,0
      ):setUVPixels(
         uv.z-border.z,
         uv.y+border.y
      ):region(
         border.z,
         uvsize.y-border.y-border.w
      ):setVisible(self.Visible)
      
      
      self.RenderTasks[7]
      :setPos(
         pos.x,
         pos.y-size.y+sborder.w,
         pos.z
      )
      :setScale(
         sborder.x/res.x,
         sborder.w/res.y,0
      ):setUVPixels(
         uv.x,
         uv.w-border.w
      ):region(
         border.x,
         border.w
      ):setVisible(self.Visible)

      self.RenderTasks[8]
      :setPos(
         pos.x-sborder.x,
         pos.y-size.y+sborder.w,
         pos.z
      ):setScale(
         (size.x-sborder.z-sborder.x)/res.x,
         sborder.w/res.y,0
      ):setUVPixels(
         uv.x+border.x,
         uv.w-border.w
      ):region(
         uvsize.x-border.x-border.z,
         border.w
      ):setVisible(self.Visible)

      self.RenderTasks[9]
      :setPos(
         pos.x-size.x+sborder.z,
         pos.y-size.y+sborder.w,
         pos.z
      ):setScale(
         sborder.z/res.x,
         sborder.w/res.y,0
      ):setUVPixels(
         uv.z-border.z,
         uv.w-border.w
      ):region(
         border.z,
         border.w
      ):setVisible(self.Visible)
   end
end

events.WORLD_TICK:register(function ()
   events.WORLD_RENDER:remove("GNUI_priority-last")
   events.WORLD_RENDER:register(function ()
      if #update > 0 then
         for i = 1, #update, 1 do
            update[i]:updateRenderTasks()
            update[i]._queue_update = nil
         end
         update = {}
      end
   end,"GNUI_priority-last")
end)

return Ninepatch