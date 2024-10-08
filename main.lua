

local SURFACE_MARGIN = 0
local RESOLUTION = 16
local ATLAS_RESOLUTION = 2048

local keybind = keybinds:newKeybind("Draw","key.mouse.right",true)

local base64 = require("libraries.base64")
local GNUI = require("libraries.GNUI.main")
local screen = GNUI.getScreenCanvas()

local atlasTexture = textures:newTexture("graffiti",ATLAS_RESOLUTION,ATLAS_RESOLUTION)
local syncTexture = textures:newTexture("TextureSyncer",RESOLUTION,RESOLUTION)

local side2dir = {
   north = vec(0,0,-1),
   east = vec(1,0,0),
   south = vec(0,0,1),
   west = vec(-1,0,0),
   up = vec(0,1,0),
   down = vec(0,-1,0)
}

local surfaces = {
   north = {},
   east = {},
   south = {},
   west = {},
   up = {},
   down = {},
}

local invSide = {
   ["north"] = 1,
   ["east"] = 2,
   ["south"] = 3,
   ["west"] = 4,
   ["up"] = 5,
   ["down"] = 6,
}

local sside = {
   "north",
   "east",
   "south",
   "west",
   "up",
   "down",
}

local slots = {} ---@type table<integer,Surface>
local proxies = {}

local atlasPreview = GNUI.newContainer()
atlasPreview:setSize(64,64)
atlasPreview:setSprite(GNUI.newSprite():setTexture(atlasTexture))
screen:addChild(atlasPreview)

local syncPreview = GNUI.newContainer()
syncPreview:setSize(32,32):setPos(80,0)
local syncPreviewSprite = GNUI.newSprite():setTexture(syncTexture)
syncPreview:setSprite(syncPreviewSprite)
screen:addChild(syncPreview)

local model = models:newPart("Graffiti","WORLD"):setMatrix(matrices.mat4() * 0.99):setLight(15,0)


---@class Surface
---@field sprite SpriteTask
---@field slot integer
---@field side Entity.blockSide
---@field bID string
---@field surfacePos Vector3
---@field uvPos Vector2
---@field pos Vector3
local Surface = {}
Surface.__index = Surface

function Surface:setPixel()
   
end

function Surface:delete()
   self.sprite:remove()
   slots[self.slot] = nil
   surfaces[self.side][self.bID] = nil
   self = nil
end




---@param pos Vector3
---@param side Entity.blockSide
---@return Surface
local function getSurface(pos,side)
   local tpos = (pos * 16 + 0.5):floor() / 16
   local bpos = pos:floor()
   if side == "north" then return surfaces["north"][bpos.x..","..bpos.y..","..tpos.z]
   elseif side == "east" then return surfaces["east"][tpos.x..","..bpos.y..","..bpos.z]
   elseif side == "south" then return surfaces["south"][bpos.x..","..bpos.y..","..tpos.z]
   elseif side == "west" then return surfaces["west"][tpos.x..","..bpos.y..","..bpos.z]
   elseif side == "up" then return surfaces["up"][bpos.x..","..tpos.y..","..bpos.z]
   else return surfaces["down"][bpos.x..","..tpos.y..","..bpos.z]
   end
end

---@param pos Vector3
---@param side Entity.blockSide
local function hasSurface(pos,side)
   local tpos = (pos * 16 + 0.5):floor() / 16
   local bpos = pos:floor()
   if side == "north" then return surfaces["north"][bpos.x..","..bpos.y..","..tpos.z] and true or false
   elseif side == "east" then return surfaces["east"][tpos.x..","..bpos.y..","..bpos.z] and true or false
   elseif side == "south" then return surfaces["south"][bpos.x..","..bpos.y..","..tpos.z] and true or false
   elseif side == "west" then return surfaces["west"][tpos.x..","..bpos.y..","..bpos.z] and true or false
   elseif side == "up" then return surfaces["up"][bpos.x..","..tpos.y..","..bpos.z] and true or false
   else return surfaces["down"][bpos.x..","..tpos.y..","..bpos.z] and true or false
   end
end

---@param pos Vector3
---@param side Entity.blockSide
local function toSurfaceUV(pos,side)
   local o = RESOLUTION - 1
   pos = ((pos % 1) * RESOLUTION):floor()
   if side == "north" then return vec(pos.x,pos.y)
   elseif side == "east" then return vec(pos.z,pos.y)
   elseif side == "south" then return vec(o-pos.x,pos.y)
   elseif side == "west" then return vec(o-pos.z,pos.y)
   elseif side == "up" then return vec(pos.x,pos.z)
   else return vec(pos.z,pos.x)
   end
end

--- Creates a surface with precise data
---@param side Entity.blockSide
---@param nextFree integer
---@param uvPos Vector2
---@param pos Vector3
---@return Surface
local function makeSurfaceRaw(side,nextFree,uvPos,pos)
   local tpos = (pos * 16 + 0.5):floor() / 16
   local bpos = pos:floor()
   local sprite = model:newSprite(tostring(nextFree))
   
   local surfacePos
   if side == "north" then surfacePos = vec(bpos.x,bpos.y,tpos.z)
   elseif side == "east" then surfacePos = vec(tpos.x,bpos.y,bpos.z)
   elseif side == "south" then surfacePos = vec(bpos.x,bpos.y,tpos.z)
   elseif side == "west" then surfacePos = vec(tpos.x,bpos.y,bpos.z)
   elseif side == "up" then surfacePos = vec(bpos.x,tpos.y,bpos.z)
   else --[[down]] surfacePos = vec(bpos.x,tpos.y,bpos.z)
   end
   
   local bID = surfacePos.x .. "," .. surfacePos.y .. "," .. surfacePos.z
   sprite:setTexture(atlasTexture,ATLAS_RESOLUTION, ATLAS_RESOLUTION)
   sprite:setRenderType("CUTOUT_CULL")
   sprite:setUV(uvPos/ATLAS_RESOLUTION)
   sprite:setRegion(RESOLUTION, RESOLUTION)

   local scale = 16 / ATLAS_RESOLUTION

   if side == "north" then
sprite:scale(-scale,-scale,0):setPos(vec(bpos.x,bpos.y,tpos.z-SURFACE_MARGIN)*16)
   elseif side == "east" then sprite:scale(scale,-scale,0):setPos(vec(tpos.x+SURFACE_MARGIN,bpos.y,bpos.z)*16):setRot(0,90,0)
   elseif side == "south" then sprite:scale(scale,-scale,0):setPos(vec(bpos.x+1,bpos.y,tpos.z+SURFACE_MARGIN)*16)
   elseif side == "west" then sprite:scale(-scale,-scale,0):setPos(vec(tpos.x-SURFACE_MARGIN,bpos.y,bpos.z+1)*16):setRot(0,90,0)
   elseif side == "up" then sprite:scale(scale,scale,scale):setPos(vec(bpos.x,tpos.y+SURFACE_MARGIN,bpos.z)*16):setRot(90,180,0)
   else --[[down]] sprite:scale(scale,scale,-scale):setPos(vec(bpos.x,tpos.y-SURFACE_MARGIN,bpos.z)*16):setRot(90,90,180)
   end
   
   local surface = {
      sprite = sprite,
      slot = nextFree,
      side = side,
      surfacePos = surfacePos,
      bID = bID,
      uvPos = uvPos,
      pos = pos,
   }
   atlasTexture:fill(uvPos.x,uvPos.y,RESOLUTION,RESOLUTION,vec(0,0,0,0))
   atlasTexture:update()
   setmetatable(surface,Surface)
   slots[nextFree] = surface
   surfaces[side][bID] = surface
   return surface
end

local nextFree = 0
---@param pos Vector3
---@param side Entity.blockSide
local function makeSurface(pos,side)
   local tpos = (pos * 16 + 0.5):floor() / 16
   local bpos = pos:floor()
   local id,surfacePos
   local uvPos = vec(
      (nextFree*RESOLUTION)%ATLAS_RESOLUTION,
      math.floor(nextFree*RESOLUTION/ATLAS_RESOLUTION)*RESOLUTION)
      
   if nextFree >= (ATLAS_RESOLUTION/RESOLUTION)^2 then
      host:setActionbar("Out of graffiti slots")
      return
   end
   nextFree = nextFree + 1
   local sprite = model:newSprite(tostring(nextFree))
   sprite:setTexture(atlasTexture,ATLAS_RESOLUTION, ATLAS_RESOLUTION)
   sprite:setRenderType("CUTOUT_CULL")
   sprite:setUV(uvPos/ATLAS_RESOLUTION)
   sprite:setRegion(RESOLUTION, RESOLUTION)
   
   local surface = makeSurfaceRaw(side,nextFree,uvPos,pos)
   return surface
end

-->========================================[ Syncing ]=========================================<--

local syncSize = 0
local syncThreshold = 900
local syncNext
local syncingCurrent ---@type Surface
local priority = {}
local inversePriority = {}

local timeSinceSync = 0
local lastSystemTime = client:getSystemTime()
events.WORLD_RENDER:register(function ()
   local systemTime = client:getSystemTime()
   local delta = (systemTime - lastSystemTime) / 1000
   lastSystemTime = systemTime
   
   timeSinceSync = timeSinceSync + delta
   if timeSinceSync > 1 then
      timeSinceSync = 0
      syncSize = 0
   end
   
   if not syncingCurrent then
      if #priority > 0 then
         syncingCurrent = table.remove(priority)
         syncingCurrent:removePriority()
      else
         syncNext,syncingCurrent = next(slots,syncNext)
      end
   end
   
   if syncingCurrent and syncSize < syncThreshold then
      local size = syncingCurrent:sync()
      syncSize = syncSize + size
      syncingCurrent = nil
   end
end)

local function updatePriority()
   inversePriority = {}
   for key, value in pairs(priority) do
      inversePriority[value.slot] = key
   end
end

function Surface:makePriority()
   if inversePriority[self.slot] then
      table.remove(priority,inversePriority[self.slot])
   end
   table.insert(priority,1,self)
   updatePriority()
end

function Surface:removePriority()
   if inversePriority[self.slot] then
      table.remove(priority,inversePriority[self.slot])
   end
   updatePriority()
end

function Surface:sync()
   local o = self.uvPos
   syncTexture:applyFunc(0,0,RESOLUTION,RESOLUTION,function (col, x, y)
      return atlasTexture:getPixel(o.x+x,o.y+y)
   end)
   
   local data = base64.decode(syncTexture:save())
   pings.syncSurface(data, invSide[self.side], self.slot, self.uvPos.x,self.uvPos.y, self.pos)
   return #data
end

function pings.syncSurface(data,side,nextFree,uvX,uvY,pos)
   side = sside[side]
   local decompressed = base64.encode(data)
   syncTexture = textures:read("TextureSyncer",decompressed)
   if not hasSurface(pos,side) then
      makeSurfaceRaw(side,nextFree,vec(uvX,uvY),pos)
   end
   getSurface(pos,side).sprite:setRenderType("TRANSLUCENT_CULL"):setColor(1,1,1)
   if not host:isHost() then
      atlasTexture:applyFunc(uvX,uvY,RESOLUTION,RESOLUTION,function (col, x, y)
         return syncTexture:getPixel(x-uvX,y-uvY)
      end)
      atlasTexture:update()
   end
   syncPreview:setSprite(syncPreviewSprite:setTexture(syncTexture))
   
end


-->========================================[ Drawing ]=========================================<--
local penColor = vec(1,1,1)
local penSize = 1

---@param pos Vector3
---@param side Entity.blockSide
---@param color Vector4|Vector3
local function draw(pos,side,color)
   local dir = side2dir[side] / 16
   local block, hit = raycast:block(pos+dir,pos-dir,"COLLIDER")
   local diff = (hit-(pos+dir))
   if not (math.abs(diff.x) == 0.0625 or math.abs(diff.y) == 0.0625 or math.abs(diff.z) == 0.0625) then
      return
   end
      if not hasSurface(pos,side) then
      makeSurface(pos,side)
   end
   local surface = getSurface(pos,side)
   if surface then
      if priority[1] ~= surface.slot then
         surface:makePriority()
      end
      surface.sprite:setRenderType("TRANSLUCENT_CULL"):setColor(0.9,0.9,0.9)
      local penPos = surface.uvPos + toSurfaceUV(pos,side)
      atlasTexture:setPixel(penPos.x,penPos.y,color)
   end
end

-->====================[ Brush ]====================<--

local function setBrushRadius(radius)
   proxies = {}
   local i = 0
   local r = radius * (RESOLUTION/16)
   for x = -r, r, 1 do
      for y = -r, r, 1 do
         local pos = vec(x,y)
         if pos:length() < r then
            i = i + 1
            proxies[i] = pos/RESOLUTION
         end
      end
   end
end


local lastHit
local function brush(pos,side)
   for i = 1, #proxies, 1 do -- rotate brush to face the surface
      local offset = proxies[i]
      if side == "north" then
         offset = offset.xy_:mul(-1,1)
      elseif side == "east" then
         offset = offset._yx:mul(0,1,-1)
      elseif side == "south" then
         offset = offset.xy_
      elseif side == "west" then
         offset = offset._yx
      elseif side == "up" then
         offset = offset.x_y:mul(1,0,1)
      else
         offset = offset.x_y:mul(1,0,1)
      end
      local count = math.max(math.floor(((lastHit or pos)-pos):length()*RESOLUTION/2),1)
      if lastHit ~= pos then
         for i = 1, 1, 1 do
            draw(math.lerp((lastHit or pos),pos,i/count)+offset,side,penColor)
         end
      end
   end
   lastHit = pos
end

-->====================[ Drawing ]====================<--

if not host:isHost() then return end

keybind.release = function () lastHit = nil end
events.WORLD_RENDER:register(function(dt)
   if player:isLoaded() and keybind:isPressed() then
      if host:isChatOpen() then
         local mat = matrices.mat4()
         local crot = client:getCameraRot()
         local res = client:getWindowSize()
         local mpos = ((client:getMousePos() / res.xy) - 0.5) * vec(res.x / res.y,1) * 2
         local FOV = client:getFOV()/90
         mat:rotateX(crot.x):rotateY(-crot.y)
         mat:translate(client:getCameraPos())
         local block,hit,side = raycast:block(
         mat.c4.xyz,
         mat.c4.xyz + (mat.c3.xyz 
         - mat.c2.xyz * FOV * mpos.y
         - mat.c1.xyz * FOV * mpos.x) * 20
         , "COLLIDER", "NONE")
         brush(hit,side)
      else
         local pos = player:getPos(dt):add(0,player:getEyeHeight())
         local dir = player:getLookDir()
         local block,hit,side = raycast:block(pos, pos + dir * 20, "COLLIDER", "NONE")
         brush(hit,side)
      end
   end
   atlasTexture:update()
end)

-->========================================[ User Interface ]=========================================<--

local colors = {
   "#131313",
   "#1b1b1b",
   "#272727",
   "#3d3d3d",
   "#5d5d5d",
   "#858585",
   "#b4b4b4",
   "#ffffff",
   "#c7cfdd",
   "#92a1b9",
   "#657392",
   "#424c6e",
   "#2a2f4e",
   "#1a1932",
   "#0e071b",
   "#1c121c",
   "#391f21",
   "#5d2c28",
   "#8a4836",
   "#bf6f4a",
   "#e69c69",
   "#f6ca9f",
   "#f9e6cf",
   "#edab50",
   "#e07438",
   "#c64524",
   "#8e251d",
   "#ff5000",
   "#ed7614",
   "#ffa214",
   "#ffc825",
   "#ffeb57",
   "#d3fc7e",
   "#99e65f",
   "#5ac54f",
   "#33984b",
   "#1e6f50",
   "#134c4c",
   "#0c2e44",
   "#00396d",
   "#0069aa",
   "#0098dc",
   "#00cdf9",
   "#0cf1ff",
   "#94fdff",
   "#fdd2ed",
   "#f389f5",
   "#db3ffd",
   "#7a09fa",
   "#3003d9",
   "#0c0293",
   "#03193f",
   "#3b1443",
   "#622461",
   "#93388f",
   "#ca52c9",
   "#c85086",
   "#f68187",
   "#f5555d",
   "#ea323c",
   "#c42430",
   "#891e2b",
   "#571c27",
   }

local page = action_wheel:newPage("Colors")

local index = 1
local actionPicker = page:newAction()
local actionSize = page:newAction()
local actionEraser = page:newAction()

local function pickerScroll(dir)
   index = (index - 1 + dir) % #colors + 1
   penColor = vectors.hexToRGB(colors[index])
   actionPicker:setTitle(toJson({text="Brush Color: ||||||||||||",color=colors[index]}))
end

local function sizeScroll(dir)
   penSize = math.clamp(penSize + dir, 1, 16)
   setBrushRadius(penSize)
   actionSize:setTitle(toJson({text="Brush Size: "..penSize}))
end

pickerScroll(0)
sizeScroll(0)
actionPicker:onScroll(pickerScroll):setItem("minecraft:brush"):onLeftClick(function () pickerScroll(0) end)
actionSize:onScroll(sizeScroll):setItem("minecraft:slime_ball")
actionEraser:onLeftClick(function ()
   actionPicker:setTitle(toJson({text="Return to Color: ||||||||||||",color=colors[index]}))
   penColor = vec(0,0,0,0)
end):setTitle("Eraser Mode"):setItem("minecraft:brick")

action_wheel:setPage(page)