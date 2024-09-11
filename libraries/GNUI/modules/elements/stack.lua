---@diagnostic disable: assign-type-mismatch

local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local gnui = require(cfg.path.."main")

local container = gnui.Container
local element = gnui.Element

---@class GNUI.Stack : GNUI.Container
---@field is_horizontal boolean
---@field Margin number
local Stack = {}

Stack.__index = function (t,i)
   return rawget(t,"parent_class") and rawget(t._parent_class,i) or rawget(t,i) or Stack[i] or container[i] or element[i]
end
Stack.__type = "GNUI.Element.Container.Stack"

function Stack.new()
   ---@type GNUI.Stack
   local new = container.new()
   new._parent_class = Stack
   new.is_horizontal = false
   new.Margin = 1
   ---@param child GNUI.any
   new.CHILDREN_ADDED:register(function (child)
      child.SIZE_CHANGED:register(function (size)
         new:update()
      end,"stack"..new.id)
      new:update()
   end)
   
   ---@param child GNUI.any
   new.CHILDREN_REMOVED:register(function (child)
      child.SIZE_CHANGED:remove("stack"..new.id)
      new:update()
   end)
   return new
end

function Stack:_update()
   local sizes = {}
   for i, child in pairs(self.Children) do
      local min = child:getMinimumSize()
      sizes[i] = min
   end
   if self.is_horizontal then
      local x = 0
      for i, child in pairs(self.Children) do
         child:setDimensions(x,0,x+sizes[i].x,0):setAnchor(0,0,0,1)
         x = x + sizes[i].x + self.Margin
      end
      self:setSystemMinimumSize(x,0)
   else
      local y = 0
      for i, child in pairs(self.Children) do
         child:setDimensions(0,y,0,y+sizes[i].y):setAnchor(0,0,1,0)
         y = y + sizes[i].y + self.Margin
      end
      self:setSystemMinimumSize(0,y)
   end
   container._update(self)
end

---if given true, the stack will be horizontal. Vertical if otherwise.
---@param is_horizontal boolean
---@return GNUI.Stack
function Stack:setIsHorizontal(is_horizontal)
   if self.is_horizontal ~= is_horizontal then
      self.is_horizontal = is_horizontal
      self:update()
   end
   return self
end

return Stack