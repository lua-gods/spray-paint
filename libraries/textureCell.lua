---@class TextureCell.Cell
---@field textureCell TextureCell
---@field id integer
---@field size Vector2
---@field pos Vector2
---@field uv Vector4
local Cell = {}

---@param tc TextureCell
---@param pos Vector2
---@param size Vector2
---@param id integer
---@return TextureCell.Cell
function Cell.new(tc,pos,size,id)
   local self = {
      id = id,
      textureCell = tc,
      size = size,
      pos = pos,
      uv = vec(pos.x,pos.y,pos.x+size.y,pos.y+size.y)
   }
   return self
end


---@param model ModelPart
function Cell:newSpriteTask(model)
   return model:newSprite("CellSprite"..self.textureCell.id..":"..self.id)
end


local nf = 0
---@class TextureCell
---@field id integer
---@field texture Texture
---@field cellSize Vector2
---@field cells TextureCell.Cell[][]
local TextureCell = {}


---@param cellSize Vector2
---@return TextureCell
function TextureCell.new(cellSize)
   nf = nf + 1
   local self = {
      id = nf,
      texture = textures:newTexture("textureCell#"..nf,2048,2048),
      cellSize = cellSize,
      cells = {}
   }
   return self
end


---@param size Vector2
---@return table
function TextureCell:newCell(size)
   local i = #self.cells + 1
   local pos = vec(
      (((i/self.cellSize.x) % 2048) * self.cellSize.x),
      math.floor((i/self.cellSize.x) / 2048) * self.cellSize.y
   )
   local cell = Cell.new(self, pos, vec(math.clamp(size.x,1,self.cellSize.x),math.clamp(size.y,1,self.cellSize.y)), i)
   self.cells[i] = cell
   return cell
end

return TextureCell