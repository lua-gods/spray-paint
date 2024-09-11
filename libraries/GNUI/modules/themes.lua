---@alias GNUI.theme table<{variants:{default:fun(container:GNUI.any):GNUI.any}}>

---@type GNUI.theme
local theme_library = {}

for _, preset_path in pairs(listFiles(... .. ".theme.presets",true)) do
   local words = {}
   for word in preset_path:gmatch("[^%.]+") do
      words[#words+1] = word
   end
   if not theme_library[words[#words-1]] then -- create theme directory
      theme_library[words[#words-1]] = {}
   end
   
   local entries = require(preset_path)
   
   for element, element_themes in pairs(entries) do
      if not theme_library[words[#words-1]][element] then
         theme_library[words[#words-1]][element] = {}
      end
      for variant, variant_function in pairs(element_themes) do
         theme_library[words[#words-1]][element][variant] = variant_function
      end
   end
end

local api = {}

---Applies the theme to the element.  
---NOTE: Themes stack, so only apply once to avoid unexpected behavior.
---@param element GNUI.any
---@param theme string?
---@param variant string|"nothing"?
function api.applyTheme(element,variant,theme,...)
   if not theme then theme = "default" end
   if not variant then variant = "default" end
   local type = element.__type:match("%.([^%.]+)$")
   if not theme_library[theme] then
      error('Theme "' .. theme .. '" not found',2)
   end
   if not theme_library[theme][type] then
      error('Element "' .. type .. '" not found in theme "' .. theme .. '"',2)
   end
   if not theme_library[theme][type][variant] then
      variant = "nothing"
     -- error('Variant "' .. variant .. '" not found in element "' .. type .. '" in theme "' .. theme .. '"',2)
   end
   if variant == "nothing" then return end
   theme_library[theme][type][variant](element,...)
end

return api