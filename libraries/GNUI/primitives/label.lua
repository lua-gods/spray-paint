---@diagnostic disable: assign-type-mismatch, undefined-field
local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local evnt = cfg.event

local container = require(cfg.path.."primitives.container")
local element = require(cfg.path.."primitives.element")

local dot = "."
local dot_length = client.getTextWidth(dot)
---Calculates text length along with its spaces as well.  
---accepts raw json component as well, if the given text is a table.
---This is a workaround for keeping the whitespace while getting the length because Minecraft trims them off.
---@param text string|table
---@return integer
local function getlen(text)
   local t = type(text)
   if t == "string" then
      return client.getTextWidth(dot..text..dot) - dot_length * 2
   else
      local og = text.text
      text.text = text.text:gsub(" ","||")
      local l = client.getTextWidth(toJson(text))
      text.text = og
      return l
   end
end

---@alias TextEffect string
---| "NONE"
---| "OUTLINE"
---| "SHADOW"

---@class GNUI.Label : GNUI.Container # A special type of container that can do text rendering, separated into its own class to avoid massive lag spikes when making too many contaiers.
---@field Text string|table               # The text that will be displayed on the label, for raw json, pass a table instead of a string json.
---@field TextData table                  # Baked data of the text.
---@field TextEffect TextEffect           # Determins the effects applied to the label.
---@field LineHeight number               # the distance between each line, defaults to 10.
---@field WrapText boolean                # Does nothing at the moment. but should send the text to the next line once the word is over the container's boundaries
---@field RenderTasks table<any,TextTask> # every render task used for rendering text
---@field Align Vector2                   # Determins where to fall on to when displaying the text (`0`-`1`, left-right, up-down)
---@field AutoWarp boolean                # The flag that tells if the text should auto warp to the next line
---@field FontScale number                # Scales the text in the container.
---@field DefaultColor string             # The color of the text.
---@field clipText boolean                # The flag that tells if the tetx should clip
---@field private _TextChanged boolean    
---@field TEXT_CHANGED eventLib           # Triggered when the text is changed.
local L = {}
L.__index = function (t,i)
   return rawget(t,i) or L[i] or container[i] or element[i]
end
L.__type = "GNUI.Element.Container.Label"

---Creates a new label, which is just a container but can render text, separated into its own class for optimization.
---@return GNUI.Label
function L.new()
   ---@type GNUI.Label
   local new = container.new()
   new.Text = ""
   new.TextEffect = "NONE"
   new.LineHeight = 8
   new.WrapText = false
   new.TextData = {}
   new.Align = vec(0,0)
   new.DefaultColor = "white"
   new.RenderTasks = {}
   new.FontScale = 1
   new._TextChanged = false
   new.ClipText = false
   new.TEXT_CHANGED = evnt.new()
   
   new.TEXT_CHANGED:register(function ()
      new
      :_bakeWords()
      :_deleteRenderTasks()
      :_buildRenderTasks()
      :_updateRenderTasks()
   end)

   new.SIZE_CHANGED:register(function ()
      new:_updateRenderTasks()
   end)

   new.PARENT_CHANGED:register(function ()
      if not new.Parent then
         new:_deleteRenderTasks()
      end
      new.TEXT_CHANGED:invoke(new.Text)
   end)
   setmetatable(new,L)
   return new
end

---Sets the text for the label to display.
---@generic self
---@param self self
---@param text string|table # For raw json text, use a table instead.
---@return self
function L:setText(text)
   local t = type(text)
   if t == "table" then
      if not text[1] then -- convert to array
         text = {text}
      end
      self.Text = text
   else
      self.Text = text or ""
   end
   self._TextChanged = true
   self.TEXT_CHANGED:invoke(self.Text)
   return self
end

---NOTE: Does not work yet.  
---determins whenever to allow word warping or not.
---@generic self
---@param self self
---@param wrap boolean
---@return self
function L:setWrapText(wrap)
   self.WrapText = wrap
   self:_updateRenderTasks()
   return self
end

---Sets how the text is anchored to the container.  
--- horizontal or vertical by default is 0, making them clump up at the top left
---@generic self
---@param self self
---@param horizontal number? # left 0 <-> 1 right
---@param vertical number?   #up 0 <-> 1 down  
---@return self
function L:setAlign(horizontal,vertical)
   self.Align = vec(horizontal or 0,vertical or 0)
   self:_updateRenderTasks()
   return self
end

---Sets the font scale for all text thats by this container.
---@param scale number # defaults to `1`
---@generic self
---@param self self
---@return self
function L:setFontScale(scale)
   ---@cast self GNUI.Label
   self.FontScale = scale or 1
   self:_updateRenderTasks()
   return self
end

---Determins the effect used for the label.  
---NONE, OUTLINE or SHADOW.
---@generic self
---@param self self
---@param effect TextEffect
---@return self
function L:setTextEffect(effect)
   self.TextEffect = effect
   self:_deleteRenderTasks()
   self:_buildRenderTasks()
   self:_updateRenderTasks()
   return self
end

---Sets the default color for the label, uses the same format as raw json text.
---@generic self
---@param self self
---@return self
---@param hex_or_name string
function L:setDefaultColor(hex_or_name)
   ---@cast self GNUI.Label
   self.DefaultColor = hex_or_name
   self:_deleteRenderTasks()
   self:_bakeWords()
   self:_buildRenderTasks()
   self:_updateRenderTasks()
   return self
end

---Sets the flag if the word chunks should clip on the label or not.
---@param toggle boolean
---@generic self
---@param self self
---@return self
function L:setClipText(toggle)
   ---@cast self GNUI.Label
   self.clipText = toggle
   return self
end

---Flattens the json components into one long array of components. by merging the `extra` tag in components into the base array.
---@param json table
---@return table
local function flattenComponents(json)
   local lines = {}
   local content = {}
   local content_length = 0
   local l = 0
   if json.extra then
      json = {json}
   end
   for _, comp in pairs(json) do
      if comp.text and (comp.text ~= "") then
         for line in string.gmatch(comp.text,"[^\n]*") do -- separate each line
            content_length = 0
            for word in string.gmatch(line,"[%s]*[%S]+[%s]*") do -- split words
               local prop = {}
               -- only append used data in labels
               prop.font = comp.font
               prop.bold = comp.bold
               prop.italic = comp.italic
               prop.color = comp.color
               l = 0
               prop.text = word
               if prop.font then
                  l = client.getTextWidth(toJson(prop))
               else
                  l = getlen(prop)
               end
               prop.text = word
               prop.length = l
               content_length = content_length + l
               content[#content+1] = prop
            end
            if tostring(comp.text):find("\n") then -- check if this component even has a new line
               lines[#lines+1] = {content = content,length = content_length}
               content = {}
            end
         end
      end
      if comp.extra then
         for _, line in pairs(flattenComponents(comp.extra)) do
            for _, data in pairs(line.content) do
               content[#content+1] = data
               content_length = content_length + line.length
            end
         end
      end
   end
   lines[#lines+1] = {content = content,length = content_length}
   return lines
end

---@param from string|table
---@return table # TextData
function L:parseText(from)
   local lines = {}
   local t = type(from)
   if t == "table" then
      lines = flattenComponents(from)
   elseif t == "string" then
      for line in string.gmatch(from,"[^\n]*") do -- separate each line
         local compose = {}
         for word in string.gmatch(line,"[%S]+[%s]*") do -- split words
            local l = getlen(word)
            compose[#compose+1] = {text=word,length=l,color=self.DefaultColor}
         end
         local l = getlen(line)
         lines[#lines+1] = {length=l,content=compose}
      end
   end
   return lines
end


---@return self
function L:_bakeWords()
   self.TextData = self:parseText(self.Text)
   self._TextChanged = true
   return self
end


---@return self
function L:_buildRenderTasks()
   local i = 0
   if self.TextData then
      for _, lines in pairs(self.TextData) do
         for _, component in pairs(lines.content) do
            if component.text then
               i = i + 1
               local task = self.ModelPart:newText("word" .. i):setText(toJson(component))
               if self.TextEffect == "OUTLINE" then
                  task:setOutline(true)
               elseif  self.TextEffect == "SHADOW" then
                  task:setShadow(true)
               end
               self.RenderTasks[i] = task
            end
         end
      end
   end
   return self
end


---@generic self
---@param self self
---@return self
function L:_updateRenderTasks() -- NOTE: WrapText is not compatible with custom alignment yet.
   local i = 0
   local size = self.ContainmentRect.xy - self.ContainmentRect.zw -- inverted for optimization
   local pos = vec(0,self.LineHeight)
   local scale = self.FontScale * self.AccumulatedScaleFactor
   if #self.TextData == 0 then return self end
   local offset = vec(
      0,
      (size.y / scale)  * self.Align.y + #self.TextData * self.LineHeight * self.Align.y)
   for _, line in pairs(self.TextData) do
      pos.y = pos.y - self.LineHeight
      pos.x = 0
      offset.x = (size.x / scale) * self.Align.x + line.length * self.Align.x
      for c, component in pairs(line.content) do
         i = i + 1
         if self.WrapText and (pos.x - component.length < size.x / scale)  then
            pos.y = pos.y - self.LineHeight
            pos.x = 0
         end
         local task = self.RenderTasks[i]
         if (pos.x - component.length > size.x / scale) and (pos.y > 0 and pos.y < size.y) or not self.clipText then
            task
            :setPos(pos.xy_:add(offset.x,offset.y) * scale)
            :setScale(scale,scale,scale)
            :setVisible(true)
         else
            task:setVisible(false)
         end
         pos.x = pos.x - component.length
      end
   end
   return self
end

---@return self
function L:_deleteRenderTasks()
   if self.RenderTasks then
      for key, task in pairs(self.RenderTasks) do
         self.ModelPart:removeTask(task:getName())
      end
   end
   return self
end

return L