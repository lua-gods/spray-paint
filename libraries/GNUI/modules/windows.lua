local api = {}

local cfg = require((...):match("^(.*.GNUI).*$").."/config")

local window = require(cfg.path.."modules.windows.window")
local fileDialog = require(cfg.path.."modules.windows.fileDialog")
api.Window = window
---@return GNUI.Window
function api.newWindow() return window.new() end

api.fileDialog = fileDialog
---@param screen GNUI.Container|GNUI.Canvas
---@param situation fileManagerType?
---@return GNUI.Window.FileManager
function api.newFileDialog(screen,situation)
   return fileDialog.new(screen,situation)
end

return api