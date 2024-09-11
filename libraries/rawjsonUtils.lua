--[[______   __
  / ____/ | / / by: GNamimates, Discord: "@gn8.", Youtube: @GNamimates
 / / __/  |/ / A library that makes it easier to deal with Minecraft's Raw Json Text format. (1.21 and lower)
/ /_/ / /|  / 
\____/_/ |_/ Source: https://github.com/lua-gods/GNs-Avatar-3/blob/main/libraries/rawjsonUtils.lua]]

local api = {}

function api.copyTable(tbl)
   local copy = {}
   for k,v in pairs(tbl) do
      if type(v) == "table" then
         copy[k] = api.copyTable(v)
      else
         copy[k] = v
      end
   end
   return copy
end

---@param component table
---@param pattern string?
---@param filter fun(component: table)
function api.filterPattern(component,pattern,filter)
   if not component then return end
   if component[1] then -- is an array
      for i = 1, #component, 1 do
         component[i] = api.filterPattern(component[i],pattern,filter)
      end
   else
      -- recursion
      if component.extra then
         api.filterPattern(component.extra,pattern,filter)
      end
      
      if type(component) == "string" then -- 1.20.3 fix
         component = {text=component}
      end
      -- component processing
      local a, b
      if pattern and component.text then
         a, b  = component.text:find(pattern)
      else
         a = 1
         b = -1
      end
      if a and not component.antiTamper and component.text then -- split found
         local ca,cb,cc = component.text:sub(1,a-1),component.text:sub(a,b),component.text:sub(b+1,-1)
         local ta,tb,tc = api.copyTable(component),api.copyTable(component),api.copyTable(component)
         ta.text = ca
         tb.text = cb
         tc.text = cc
         if filter then
            filter(tb)
         end
         for key, value in pairs(component) do
            component[key] = nil
         end
         component.extra = {{text=""},ta,tb,tc}
         component.text = ""
         api.filterPattern(tc,pattern,filter)
      end
   end
   return component
end

---@param component table
---@param func function
function api.recursiveLoopComponent(component,func)
   if not component then return end
   if component[1] then -- is an array
      for i = 1, #component, 1 do
         component[i] = api.recursiveLoopComponents(component[i])
      end
   else
      -- recursion
      if component.extra then
         api.recursiveLoopComponents(component.extra)
      end
      
      if type(component) == "string" then -- 1.20.3 fix
         component = {text=component}
      end
      -- component processing
      if func then
         func(component)
      end
   end
   return component
end

---@param component table
---@param prefix table
function api.insertPrefix(component,prefix)
   if not component then return end
   local copy = api.copyTable(component)
   for key, value in pairs(component) do
      component[key] = nil
   end
   component.extra = {prefix,copy}
   component.text = ""
   return component
end

function api.insertSuffix(component,suffix)
   if not component then return end
   for key, value in pairs(component) do
      component[key] = nil
   end
   component.extra = {api.copyTable(component),suffix}
   return component
end

---Gets the component at the given index
---@param component table
---@param index integer
function api.getIndexComponent(component,index)
   if not component then return end
   if component[1] then -- is an array
      for i = 1, #component, 1 do
         local returned = api.getIndexComponent(component[i],index)
         if returned then
            return returned
         end
      end
   else
      -- recursion
      if component.extra then
         local returned = api.getIndexComponent(component.extra,index)
         if returned then
            return returned
         end
      end
      
      if type(component) == "string" then -- 1.20.3 fix
         component = {text=component}
      end
      -- component processing
      index = index - 1
      if index == 0 then
         return component
      end
   end
end

return api