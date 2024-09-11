--[[______   __
  / ____/ | / / by: GNamimates, Discord: "@gn8.", Youtube: @GNamimates
 / / __/  |/ / a library to make http requests simpler.
/ /_/ / /|  / 
\____/_/ |_/ Source: https://github.com/lua-gods/GNs-Avatar-3/blob/main/libraries/httpRequest.lua]]
local lib = {}

---@class HTTPRequestQueue
---@field peprocessor function?
local wait = {}
wait.__index = wait

local next_free = 0

---@param url string
---@param request_body Buffer?
---@param success fun(result : any): any???
---@param fail fun(code : number): any???
---@return Future.HttpResponse
function lib.request(url,request_body,success,fail)
   next_free = next_free + 1
   local id = "http"..tostring(next_free)
   ---@type HttpRequestBuilder
   local request = net.http:request(url)
   if request_body then
      request:body(request_body)
   end
   local response = request:send()
   
   events.WORLD_TICK:register(function ()
      if response:isDone() then
         local result = response:getValue()
         local code = 404
         if result and result.getResponseCode then
            code = result:getResponseCode()
         end
         if code == 200 then
            if success then success(result) end
         else
            if fail then fail(code) end
         end
         events.WORLD_TICK:remove(id)
      end
   end,id)
   return response
end

function lib.requestTexture(url,buffer,name)
   return lib.request(url,buffer,function (result)
      local output_buffer = data:createBuffer()
      output_buffer:readFromStream(result:getData())
      output_buffer:setPosition(0)
      local base64 = output_buffer:readBase64()
      output_buffer:close()
      local success, output_result = pcall(function () return textures:read(name,base64) end)
      if success then
         return output_result
      end
   end)
end

function lib.requestJson(url,buffer)
   return lib.request(url,buffer,function (result)
      local output_buffer = data:createBuffer()
      output_buffer:readFromStream(result:getData())
      output_buffer:setPosition(0)
      local output = output_buffer:readString()
      output_buffer:close()
      return parseJson(output)
   end)
end

function lib.requestString(url,buffer)
   return lib.request(url,buffer,function (result)
      local output_buffer = data:createBuffer()
      output_buffer:readFromStream(result:getData())
      output_buffer:setPosition(0)
      local output = output_buffer:readString()
      output_buffer:close()
      return output
   end)
end

---@param func fun(result : any)
---@return HTTPRequestQueue
function wait:onFinish(func)
   self.finish = func
   return self
end

---@param func fun(code : integer)
---@return HTTPRequestQueue
function wait:onFail(func)
   self.fail = func
   return self
end

return lib