

local SURFACE_MARGIN = 0
local RESOLUTION = 16
local ATLAS_RESOLUTION = 512
local keybind = keybinds:newKeybind("Draw","key.mouse.right")

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
   pos = ((pos - pos:floor()) * RESOLUTION):floor()
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
   atlasTexture:fill(uvPos.x,uvPos.y,RESOLUTION,RESOLUTION,vec(1,1,1,0))
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



function Surface:sync()
   local o = self.uvPos
   syncTexture:applyFunc(0,0,RESOLUTION,RESOLUTION,function (col, x, y)
      return atlasTexture:getPixel(o.x+x,o.y+y)
   end)
   
   local data = base64.decode(syncTexture:save())
   pings.syncSurface(data, self.side, self.surfacePos, self.slot, self.bID, self.uvPos, self.pos)
   return #data
end

function pings.syncSurface(data,side,surfacePos,nextFree,bID,uvPos,pos)
   local decompressed = base64.encode(data)
   syncTexture = textures:read("TextureSyncer",decompressed)
   if not hasSurface(pos,side) then
      makeSurfaceRaw(side,nextFree,uvPos,pos)
   end
   atlasTexture:applyFunc(uvPos.x,uvPos.y,RESOLUTION,RESOLUTION,function (col, x, y)
      return syncTexture:getPixel(x-uvPos.x,y-uvPos.y):mul(1,0,0,1)
   end)
   atlasTexture:update()
   syncPreview:setSprite(syncPreviewSprite:setTexture(syncTexture))
   
end




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
      local penPos = surface.uvPos:copy() + toSurfaceUV(pos,side)
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

setBrushRadius(4)

-->====================[ Drawing ]====================<--

events.WORLD_RENDER:register(function(dt)
   if player:isLoaded() then
      local pos = player:getPos(dt):add(0,player:getEyeHeight())
      local dir = player:getLookDir()
      
      local block,hit,side = raycast:block(pos, pos + dir * 20, "COLLIDER", "NONE")
      if block.id ~= "minecraft:air" then
         if keybind:isPressed() then
            for i = 1, #proxies, 1 do
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
               draw(hit+offset,side,vec(1,1,1))
            end
         end
      end
   end
   atlasTexture:update()
end)

-->========================================[ Syncing ]=========================================<--

local syncSize = 0
local syncThreshold = 900
local syncNext
local syncingCurrent ---@type Surface

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
      syncNext,syncingCurrent = next(slots,syncNext)
   end
   
   if syncingCurrent and syncSize < syncThreshold then
      local size = syncingCurrent:sync()
      syncSize = syncSize + size
      syncingCurrent = nil
   end
end)