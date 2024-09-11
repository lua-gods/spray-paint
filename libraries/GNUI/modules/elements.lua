local api = {}
-- Toggle each chunk of snippet depending on which you remove from the module folder

local cfg = require((...):match("^(.*.GNUI).*$").."/config")

-->====================[ Button ]====================<--
local button = require(cfg.path.."modules.elements.button")
---@param variant string|"default"|"nothing"?
---@param theme string?
---@return GNUI.Button
api.newButton = function(variant,theme) return button.new(variant,theme) end
api.Button = button




-->====================[ Stack ]====================<--
local stack = require(cfg.path.."modules.elements.stack")
api.newStack = function() return stack.new() end
api.Stack = stack




-->====================[ TextButton ]====================<--
local text_button = require(cfg.path.."modules.elements.textButton")
---@param variant string|"default"|"nothing"?
---@param theme string?
---@return GNUI.TextButton
api.newTextButton = function(variant,theme) return text_button.new(variant,theme) end
api.TextButton = text_button




-->====================[ TextureButton ]====================<--
local texture_button = require(cfg.path.."modules.elements.textureButton")
---@param normal Sprite?
---@param pressed Sprite?
---@param hovered Sprite?
---@return GNUI.TextureButton
api.newTextureButton = function(normal,pressed,hovered)
   return texture_button.new(normal,pressed,hovered)
end
api.TextureButton = texture_button




-->====================[ SingleSpriteButton ]====================<--
local single_texture_button = require(cfg.path.."modules.elements.singleSpriteButton")
---@param sprite Sprite?
---@return GNUI.SingleSpriteButton
api.newSingleSpriteButton = function(sprite)
   return single_texture_button.new(sprite)
end
api.SingleTextureButton = single_texture_button




--->====================[ TextInputButton ]====================<--
local text_input_button = require(cfg.path.."modules.elements.textInputField")
---@param variant string|"default"|"nothing"?
---@param theme string?
---@return GNUI.TextInputField
api.newTextInputField = function(variant,theme) return text_input_button.new(variant,theme) end
api.TextInputField = text_input_button




-->====================[ ScrollbarButton ]====================<--
local scrollbar_button = require(cfg.path.."modules.elements.ScrollbarButton")
---@param variant string|"default"|"nothing"?
---@param theme string?
---@return GNUI.ScrollbarButton
api.newScrollbarButton = function(variant,theme) return scrollbar_button.new(variant,theme) end
api.ScrollbarButton = scrollbar_button

return api