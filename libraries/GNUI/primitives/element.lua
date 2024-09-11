local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local eventLib = cfg.event

local element_next_free = 0
---@class GNUI.Element # The base element of every GNUI element.
---@field name string                 # An optional property used to get the element by a name.
---@field id integer                  # A unique integer for this element. (next-free based).
---@field Visible boolean             # `true` to see.
---@field Parent GNUI.any             # the element's parents.
---@field Children table<any,GNUI.any># A list of the element's children.
---@field ChildIndex integer          # the element's place order on its parent.
---@field VISIBILITY_CHANGED eventLib # on change of visibility.
---@field CHILDREN_ADDED eventLib     # when a child is added. first parameter is the child added.
---@field CHILDREN_REMOVED eventLib   # when a child is removed. first parameter is the child removed.
---@field PARENT_CHANGED table        # when the parent changes.
---@field ON_FREE eventLib            # when the element is wiped from history.
---@field cache table
local Element = {}
Element.__index = Element
Element.__type = "GNUI.Element"

---Creates a new basic element.
---@generic self
---@param preset table?
---@return self
function Element.new(preset)
   local new = preset or {}
   new.id = element_next_free
   new.Visible = true
   new.cache = {final_visible = true}
   new.VISIBILITY_CHANGED = eventLib.new()
   new.Children = {}
   new.ChildIndex = 0
   new.CHILDREN_ADDED = eventLib.new()
   new.CHILDREN_REMOVED = eventLib.new()
   new.PARENT_CHANGED = eventLib.new()
   new.ON_FREE = eventLib.new()
   setmetatable(new,Element)
   element_next_free = element_next_free + 1
   return new
end

---Sets the visibility of the element and its children
---@param visible boolean
---@generic self
---@param self self
---@return self
function Element:setVisible(visible)
   ---@cast self GNUI.Element
   if self.Visible ~= visible then
      self.Visible = visible
      self.VISIBILITY_CHANGED:invoke(visible)
      for key, child in pairs(self.Children) do
         child:_updateVisibility()
      end
      if not self.Parent then
         self:_updateVisibility()
      end
   end
   return self
end

function Element:_updateVisibility()
   if self.Parent then
      self.cache.final_visible = self.Parent.Visible and self.Visible
   else
      self.cache.final_visible = self.Visible
   end
   return self
end

---Sets the name of the element. this is used to make it easier to find elements with getChild
---@param name string
---@generic self
---@param self self
---@return self
function Element:setName(name)
   ---@cast self GNUI.Element
   self.name = name
   return self
end

---@return string
function Element:getName()
   return self.name
end

---Gets a child by username
---@param name string
---@return GNUI.any
function Element:getChild(name)
   for _, child in pairs(self.Children) do
      if child.name and child.name == name then
         return child
      end
   end
   return self
end

function Element:getChildByIndex(index)
   return self.Children[index]
end

---@generic self
---@param self self
---@return self
function Element:updateChildrenOrder()
   ---@cast self GNUI.Element
   for i, c in pairs(self.Children) do
      c.ChildIndex = i
   end
   return self
end

---Adopts an element as its child.
---@param child GNUI.any
---@param index integer?
---@generic self
---@param self self
---@return self
function Element:addChild(child,index)
   ---@cast self GNUI.Container
   if not child then return self end
   if not type(child):find("^GNUI.") then
      error("invalid element given, recived: "..type(child),2)
   end
   if child.Parent then return self end
   table.insert(self.Children, index or #self.Children+1, child)
   if child.Parent ~= self then
      local old_parent = child.Parent
      child.Parent = self
      child.PARENT_CHANGED:invoke(self,old_parent)
      self.CHILDREN_ADDED:invoke(child)
   end
   self:updateChildrenIndex()
   return self
end

---Abandons the child into the street.
---@param child GNUI.Element
---@generic self
---@param self self
---@return self
function Element:removeChild(child)
   ---@cast self GNUI.Container
   if child.Parent == self then -- birth certificate check
      table.remove(self.Children, child.ChildIndex)
      child.ChildIndex = 0
      if child.Parent then
         local old_parent = child.Parent
         child.Parent = nil
         child.PARENT_CHANGED:invoke(nil,old_parent)
         self.CHILDREN_REMOVED:invoke(child)
      end
      self:updateChildrenIndex()
   else
      error("This container, is, not, the father", 2)
   end
   return self
end

---@return table<integer, GNUI.Container|GNUI.Element>
function Element:getChildren()
   return self.Children
end

---@generic self
---@param self self
---@return self
function Element:updateChildrenIndex()
   ---@cast self GNUI.Element
   for i = 1, #self.Children, 1 do
      local child = self.Children[i]
      child.ChildIndex = i
      if child.update then
         child:update()
      end
   end
   return self
end

---Sets the Child Index of the element.
---@param i any
function Element:setChildIndex(i)
   if self.Parent then
      i = math.clamp(i, 1, #self.Parent.Children)
      table.remove(self.Parent.Children, self.ChildIndex)
      table.insert(self.Parent.Children, i, self)
      self.Parent:updateChildrenIndex()
   end
end

---Frees all the data of the element. all thats left to do is to forget it ever existed.
function Element:free()
   if self.Parent then
      self.Parent:removeChild(self)
   end
   self.ON_FREE:invoke()
end

---Kills all the childrem, go startwars mode.
function Element:freeAllChildren()
   local children = {}
   for key, value in pairs(self:getChildren()) do
      children[key] = value
   end
   for key, value in pairs(children) do
      value:free()
   end
end

return Element