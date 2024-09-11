---@diagnostic disable: assign-type-mismatch
-- Serves as a way to create buttons with text within them

local cfg = require((...):match("^(.*.GNUI).*$").."/config")
local gnui = require(cfg.path.."main")
local themes = require(cfg.path.."modules.themes")
local button = require(cfg.path.."modules.elements.button")

---@class GNUI.TextButton : GNUI.Button
---@field label GNUI.Label
local TextButton = {}
TextButton.__index = function (t,i)
   return rawget(t,i) or TextButton[i] or button[i] or gnui.Container[i] or gnui.Element[i]
end
TextButton.__type = "GNUI.Element.Container.Button.TextButton"

---Creates a new button.
---@return GNUI.TextButton
function TextButton.new(variant,theme)
   variant = variant or "default"
   theme = theme or "default"
   ---@type GNUI.TextButton
   local new = button.new()
   local label = gnui.newLabel()
   new.label = label
   new:addChild(label)
   setmetatable(new,TextButton)
   themes.applyTheme(new,variant,theme)
   return new
end

---Sets the text of this label, accepts raw json as a table
---@param text string|table
---@generic self
---@param self self
---@return self
function TextButton:setText(text)
   ---@cast self GNUI.TextButton
   self.label:setText(text)
   return self
end

---Gets the text of this label
---@return string|table
function TextButton:getText()
   return self.label.Text
end

return TextButton