local stringUtils = {}

---Splits the text by a lua pattern.  
---ex. `("abcdef","bcd")` -> `{"a","bcd","ef"}`
---@param txt string
---@param pattern string
function stringUtils.split(txt,pattern)
   local chunks = {txt}
   local chunk_id = 0
   while chunk_id < #chunks do
      chunk_id = chunk_id + 1
      local chunk = chunks[chunk_id]
      local from, to = chunk:find(pattern)
      if not (from or to) then break end -- not found
      local pre,mid,suf = chunk:sub(1,from-1),chunk:sub(from,to),chunk:sub(to+1,-1)
      table.remove(chunks,chunk_id) -- remove the chunk that fragmented
      if #pre ~= 0 then table.insert(chunks,chunk_id, pre) chunk_id = chunk_id + 1 end
      table.insert(chunks,chunk_id, mid)
      if #suf ~= 0 then table.insert(chunks,chunk_id+1, suf) end
   end
   return chunks
end

return stringUtils