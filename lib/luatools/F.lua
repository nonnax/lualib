#!/usr/bin/env luajit

-- id$ nonnax fri aug 16 16:35:29 2024
-- https://github.com/nonnax

-- local functions

-- string lambda
local function __Lambda(expr)
    local args, body = expr:match("^%s*|?s*(.*)|(.*)") ---@type string, string
    if body:match(";") then
        local xs = body:split("[^;]+")
        local head={}
        for i=1,#xs-1 do
           head[#head+1]=xs[i]..";"
        end
        body = table.concat(head).." return "..xs[#xs]
    end
    if not body:match("return") then body = "return "..body end
    return loadstring("return function("..args..") "..body.."; end")() ---@type function
end

string_mt = getmetatable("")
string_mt.__unm = __Lambda

local function check_type(name)
    return function(value)
        return type(value) == name
    end
end

function Map(data)
  local self = {value = data}
  function self.tap(self, fx, ...)
    fx(self.value, ...)
    return Map(self.value)
  end
  function self.map(self, fx, ...)
    return Map(fx(self.value, ...))
  end
  self._ = self.map
  return setmetatable(self, {
    __call=function(self) return self.value end
  })
end

----------------------------------------------------
-- F.lua
-- functional lib
----------------------------------------------------
local F = {}

-- print and return orig args
function F.print(v)
  print(v)
  return v
end

local function each(array, func)
  if #array > 0 then
    for i=1, #array do
      local v = array[i]
      func(v, i)
    end
  else
    for k, v in pairs(array) do
      func(v, k)
    end
  end
  return array
end

-- 1. map
function F.map(array, func)
  local result = {}
  each(array, function(v, i)
    local v = array[i]
    result[i] = func(v, i)
  end)
  return result
end

-- 2. filter
function F.filter(array, predicate)
  local result = {}
  each(array, function(v, i)
    if predicate(v, i) then result[#result + 1] = v end
  end)
  return result
end

-- 3. reduce
function F.reduce(array, func, initial)
  local acc = initial
  each(array, function(v, i)
    local v = array[i]
    acc = func(acc, v, i)
  end)
  return acc
end

-- 4. each
F.each = each

-- 5. flat_map
function F.flat_map(array, func)
  local result = {}
  for i, v in ipairs(array) do
    local mapped = func(v, i)
    for _, mv in ipairs(mapped) do result[#result + 1] = mv end
  end
  return result
end

-- 7. compose
function F.compose(...)
  local functions = {...}
  return function(x)
    for i = #functions, 1, -1 do x = functions[i](x) end
    return x
  end
end

-- 7.1 flow
function F.flow(...)
  local functions = {...}
  return function(x)
    for i = 1, #functions do x = functions[i](x) end
    return x
  end
end

-- 8. curry
function F.curry(func, n)
  n = n or debug.getinfo(func, "u").nparams
  return function(...)
    local args = {...}
    if #args >= n then
      return func(table.unpack(args))
    else
      return F.curry(function(...)
        return func(table.unpack(args), ...)
      end, n - #args)
    end
  end
end

-- 9. partial
function F.partial(func, ...)
  local args = {...}
  return function(...)
    local new_args = {...}
    local final_args = {}
    for _, v in ipairs(args) do final_args[#final_args + 1] = v end
    for _, v in ipairs(new_args) do final_args[#final_args + 1] = v end
    return func(table.unpack(final_args))
  end
end

-- 10. memoize
function F.memoize(func)
  local cache = {}
  return function(...)
    local key = table.concat({...}, ",")
    if not cache[key] then cache[key] = func(...) end
    return cache[key]
  end
end

-- 11. chunk
function F.chunk(array, size)
  local result = {}
  for i = 1, #array, size do
    local chunk = {}
    for j = i, math.min(i + size - 1, #array) do chunk[#chunk + 1] = array[j] end
    result[#result + 1] = chunk
  end
  return result
end

-- 12. repeat_value
function F.repeat_value(value, n)
  local result = {}
  for i = 1, n do result[i] = value end
  return result
end

-- 13. take_while
function F.take_while(array, predicate)
  local result = {}
  for i, v in ipairs(array) do
    if not predicate(v, i) then break end
    result[#result + 1] = v
  end
  return result
end

-- 14. drop_while
function F.drop_while(array, predicate)
  local i = 1
  while i <= #array and predicate(array[i]) do i = i + 1 end
  local result = {}
  for j = i, #array do result[#result + 1] = array[j] end
  return result
end

-- 15. partition
function F.partition(array, predicate)
  local pass, fail = {}, {}
  for i, v in ipairs(array) do
    if predicate(v) then
      pass[#pass + 1] = v
    else
      fail[#fail + 1] = v
    end
  end
  return pass, fail
end

-- 16. find_index
function F.find_index(array, predicate)
  for i, v in ipairs(array) do if predicate(v, i) then return i end end
  return nil
end

-- 18. union
function F.union(array1, array2)
  local set = {}
  local result = {}
  for _, v in ipairs(array1) do
    if not set[v] then
      result[#result + 1] = v
      set[v] = true
    end
  end
  for _, v in ipairs(array2) do
    if not set[v] then
      result[#result + 1] = v
      set[v] = true
    end
  end
  return result
end

-- 19. intersection
function F.intersection(array1, array2)
  local set = {}
  for _, v in ipairs(array1) do set[v] = true end
  local result = {}
  for _, v in ipairs(array2) do if set[v] then result[#result + 1] = v end end
  return result
end

-- 20. difference
function F.difference(array1, array2)
  local set = {}
  for _, v in ipairs(array2) do set[v] = true end
  local result = {}
  for _, v in ipairs(array1) do if not set[v] then result[#result + 1] = v end end
  return result
end

-- 21. compose_n
function F.compose_n(...)
  local functions = {...}
  return function(x)
    for i = #functions, 1, -1 do x = functions[i](x) end
    return x
  end
end

-- 22. pipe (aka flow)
function F.pipe(...)
  local functions = {...}
  return function(x)
    for i = 1, #functions do x = functions[i](x) end
    return x
  end
end

-- 23. head
function F.head(array) return array[1] end

-- 24. tail
function F.tail(array)
  local result = {}
  for i = 2, #array do result[#result + 1] = array[i] end
  return result
end

-- 25. init
function F.init(array)
  local result = {}
  for i = 1, #array - 1 do result[#result + 1] = array[i] end
  return result
end

-- 26. last
function F.last(array) return array[#array] end

-- 27. flatten_deep
function F.flatten_deep(array)
  local result = {}
  for _, v in ipairs(array) do
    if type(v) == "table" then
      for _, inner in ipairs(F.flatten_deep(v)) do
        result[#result + 1] = inner
      end
    else
      result[#result + 1] = v
    end
  end
  return result
end

-- 28. scan
function F.scan(array, func, initial)
  local result = {initial}
  local acc = initial
  for i, v in ipairs(array) do
    acc = func(acc, v, i)
    result[#result + 1] = acc
  end
  return result
end

-- 29. group_with
function F.group_with(array, predicate)
  local result = {}
  local group = {array[1]}
  for i = 2, #array do
    if predicate(array[i - 1], array[i]) then
      group[#group + 1] = array[i]
    else
      result[#result + 1] = group
      group = {array[i]}
    end
  end
  result[#result + 1] = group
  return result
end

-- 30. transpose
function F.transpose(matrix)
  local result = {}
  for i = 1, #matrix[1] do
    result[i] = {}
    for j = 1, #matrix do result[i][j] = matrix[j][i] end
  end
  return result
end

-- find index of max and min with optional function to extract the comparison value
function F.find_max(tbl, value_func)
  local max_val = value_func and value_func(tbl[1]) or tbl[1]
  local max_index = 1
  for i = 2, #tbl do
    local val = value_func and value_func(tbl[i]) or tbl[i]
    if val > max_val then
      max_val = val
      max_index = i
    end
  end
  return max_val, max_index
end

function F.find_min(tbl, value_func)
  local min_val = value_func and value_func(tbl[1]) or tbl[1]
  local min_index = 1
  for i = 2, #tbl do
    local val = value_func and value_func(tbl[i]) or tbl[i]
    if val < min_val then
      min_val = val
      min_index = i
    end
  end
  return min_val, min_index
end

function F.flow_producer(f, g) return function(x) return g(f(x)) end end

function F.comp_producer(f, g) return function(x) return f(g(x)) end end

---------------------------------------------------------------
-- table parallel functions
---------------------------------------------------------------
function F.insert(t, ...)
  local params={}
  for _, x in ipairs({...}) do
    table.insert(params, x)
  end
  table.insert(t, unpack(params))
  return t
end

function F.sort(t, fx)
  table.sort(t, fx)
  return t
end

function F.contains(t, v)
  for _, x in ipairs(t) do
     if x==v then return x end
  end
end

function F.find(t, fx)
  for i, x in ipairs(t) do
     if fx(x) then
      return x, i
     end
  end
end

-- 6. find
-- function F.find(array, predicate)
--   for i, v in ipairs(array) do if predicate(v, i) then return v, i end end
--   return nil
-- end

function F.reverse(t)
  local res={}
  for i = #t, 1, -1 do
    table.insert(res, t[i])
  end
  return res
end

-- 17. reverse
-- function F.reverse(array)
--   local result = {}
--   for i = #array, 1, -1 do result[#result + 1] = array[i] end
--   return result
-- end

function F.reorder(t)
  local res={}
  for i=1, #t do
    local v = t[i]
    if v then
      table.insert(res, v)
    end
  end
  return res
end

function F.remove(t, ...)
  local params={}
  for _, x in ipairs({...}) do
    table.insert(params, x)
  end
  table.remove(t, unpack(params))
  return t
end

function F.slice(t, start, stop)
  local res={}
  for i=start, stop do
    table.insert(res, t[i])
  end
  return res
end

function F.range(start, stop)
  local res={}
  if not stop then
   stop = start
   start = 1
  end

  for i=start, stop do
    table.insert(res, i)
  end
  return res
end

function F.times(stop, fx)
  local res={}
  for i=1, stop do
    table.insert(res, fx(i))
  end
  return res
end

function F.keys(t)
  local res={}
  for k, v in pairs(t) do
    table.insert(res, k)
  end
  return res
end

F.add = function(n,m) return n + m end
F.sub = function(n,m) return n - m end
F.mul = function(n,m) return n * m end
F.div = function(n,m) return n / m end
F.gt  = function(n,m) return m > n end
F.lt  = function(n,m) return m < n end
F.eq  = function(n,m) return n == m end
F.le  = function(n,m) return n <= m end
F.ge  = function(n,m) return n >= m end
F.ne  = function(n,m) return n ~= m end

F.mod = math.mod
F.pow = math.pow

F.inc = function(v) return v + 1 end
F.dec = function(v) return v - 1 end
F.id = function(v) return v end
F.swap = function(a, b) return b, a end
F.const = function(x) return function() return x end end
---------------------------------------------------------------
-- validators
---------------------------------------------------------------

F.is_nil = function(object) return nil == object end
F.is_finite = function(value) return -huge < value and value < huge end
F.is_infinite = function(value) return not F.is_finite(value) end
F.is_nan = function(value) return value ~= value end
F.is_integer = function(value) return value % 1 == 0 end

F.is_userdata = check_type("userdata")
F.is_table = check_type("table")
F.is_string = check_type("string")
F.is_function = check_type("function")
F.is_number = check_type("number")
F.is_boolean = check_type("boolean")

return F
