#!/usr/bin/env luajit

-- id$ nonnax fri aug 16 16:35:29 2024
-- https://github.com/nonnax

-- local functions
-- generic iterator that iterates over tables and/or objects

-- string lambda
-- local function __lambda(expr)
--     local args, body = expr:match("^%s*|?s*(.*)|(.*)") ---@type string, string
--     if body:match(";") then
--         local xs = body:split("[^;]+")
--         local head={}
--         for i=1,#xs-1 do
--            table.insert(head, xs[i]..";")
--         end
--         body = table.concat(head).." return "..xs[#xs]
--     end
--     if not body:match("return") then body = "return "..body end
--     return loadstring("return function("..args..") "..body.."; end")() ---@type function
-- end
local function __lambda(expr)
    local args, body = expr:match("^%s*|?%s*(.-)|%s*(.*)$") ---@type string, string

    -- Optimize the handling of multiple expressions in the body
    if body:find(";") then
        -- Split the body by semicolons
        local statements = {}
        for statement in body:gmatch("[^;]+") do
            statements[#statements + 1] = statement
        end
        -- Combine the body, ensuring the last statement is returned
        if #statements > 1 then
            body = table.concat(statements, ";", 1, #statements - 1) .. "; return " .. statements[#statements]
        end
    end

    -- Ensure the body has a return statement if it is missing
    if not body:find("return") then
        body = "return " .. body
    end

    -- Dynamically compile and return the lambda function
    return assert(loadstring("return function(" .. args .. ") " .. body .. "; end"))()
end


string_mt = getmetatable("")
string_mt.__unm = __lambda

-- top-level type-checker function factory
local function check_type(name)
    return function(value)
        return type(value) == name
    end
end


----------------------------------------------------
-- F.lua
-- functional lib
----------------------------------------------------
local F = {}


-- functor
function F.Map(data)
  local self = {value = data}
  function self:map(fx, ...)
    return Map(fx(self.value, ...))
  end
  self._ = self.map
  return setmetatable(self, {
    __call=function(self) return self.value end
  })
end

function F.iter(t)
  return coroutine.wrap(function()
    -- iterate table
    for i=1, #t do
      coroutine.yield(t[i], i)
    end
    -- Iterate over the object-like part
    for k, v in pairs(t) do
      if type(k) ~= "number" or k > #t then
        coroutine.yield(v, k)
      end
    end
  end)
end

function F.each(t, func)
  -- iterate table
  for i=1, #t do
    func(t[i], i)
  end
  -- Iterate over the object-like part
  for k, v in pairs(t) do
    if type(k) ~= "number" or k > #t then
      func(v, k)
    end
  end
  return t
end

-- print and return orig args
function F.print(v)
  print(v)
  return v
end

-- 1. map
function F.map(array, func)
    local result = {}
    for i, v in ipairs(array) do
        result[i] = func(v, i)
    end
    return result
end

-- 2. filter
function F.filter(array, predicate)
  local result = {}
  F.each(array, function(v, i)
    if predicate(v, i) then result[#result + 1] = v end
  end)
  return result
end

-- 3. reduce
function F.reduce(array, func, initial)
  local acc = initial
  F.each(array, function(v, i)
    acc = func(acc, v, i)
  end)
  return acc
end

-- 4. F.each

-- 5. flat_map
-- 5. flatMap (refactored with each)
function F.flatmap(array, func)
    local result = {}
    F.each(array, function(v, i)
        local mapped = func(v, i)
        for _, mv in ipairs(mapped) do
            result[#result + 1] = mv
        end
    end)
    return result
end

function F.flatrows(tbl, result)
  result = result or {} -- Initialize the result table if not provided

  for _, v in ipairs(tbl) do
    if type(v) == "table" then
      if #v == 0 then
        -- If the table is non-list (e.g., has named keys), add it to the result
        table.insert(result, v)
      else
        -- Otherwise, recursively process the nested table
        F.flatrows(v, result)
      end
    end
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
-- 7. partition (refactored with each)
function F.partition(array, predicate)
    local pass, fail = {}, {}
    F.each(array, function(v)
        if predicate(v) then
            pass[#pass + 1] = v
        else
            fail[#fail + 1] = v
        end
    end)
    return pass, fail
end
-- 16. find_index
function F.find_index(array, predicate)
  for i, v in ipairs(array) do if predicate(v, i) then return i end end
  return nil
end

-- 18. union
-- 8. union (refactored with each)
function F.union(array1, array2)
    local set = {}
    local result = {}
    local function addIfNotExists(v)
        if not set[v] then
            result[#result + 1] = v
            set[v] = true
        end
    end
    F.each(array1, addIfNotExists)
    F.each(array2, addIfNotExists)
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

--- Flatten function
-- Flattens a nested table into a single-level table
-- @param tbl table: The input nested table
-- @return table: A new table with the flattened values
function F.flatten(tbl)
    local result = {}
    local function flattenHelper(t)
        for v in iter(t) do
            if type(v) == "table" then
                flattenHelper(v)
            else
                table.insert(result, v)
            end
        end
    end
    flattenHelper(tbl)
    return result
end

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
-- function F.group_with(array, predicate)
--   local result = {}
--   local group = {array[1]}
--   for i = 2, #array do
--     if predicate(array[i - 1], array[i]) then
--       group[#group + 1] = array[i]
--     else
--       result[#result + 1] = group
--       group = {array[i]}
--     end
--   end
--   result[#result + 1] = group
--   return result
-- end

-- group_with: This function groups items based on a relationship between them,
-- typically defined by a user-provided predicate function.
-- Instead of extracting a key, group_with checks if two items should belong to
-- the same group based on the predicate.

function F.group_with(data, predicate)
    local grouped = {}
    local used = {}

    for i = 1, #data do
        if not used[i] then
            local group = {data[i]}
            used[i] = true
            for j = i + 1, #data do
                if not used[j] and predicate(data[i], data[j]) then
                    table.insert(group, data[j])
                    used[j] = true
                end
            end
            table.insert(grouped, group)
        end
    end

    return grouped
end

-- Example usage: Group consecutive numbers
-- local numbers = {1, 2, 2, 3, 4, 4, 5}
--
-- local grouped_with_consecutives = group_with(numbers, function(a, b)
--     return a == b
-- end)

-- Result:
-- grouped_with_consecutives = { {1}, {2, 2}, {3}, {4, 4}, {5} }


-- General-purpose group_by function
-- group_by: This function groups items based on a computed key derived from F.each item.
-- The key is usually extracted by a user-provided function.
-- It allows flexibility in determining what constitutes a group by defining how the key is computed.
function F.group_by(data, fx)
    local grouped = {}
    for _, entry in ipairs(data) do
        local key = fx(entry)
        grouped[key] = grouped[key] or {}
        table.insert(grouped[key], entry)
    end
    return grouped
end
-- Example usage: Group numbers by their parity (even or odd)
-- local numbers = {1, 2, 3, 4, 5, 6}

-- local grouped_by_parity = group_by(numbers, function(n)
--     return n % 2 == 0 and "even" or "odd"
-- end)

-- Result:
-- grouped_by_parity = { ["even"] = {2, 4, 6}, ["odd"] = {1, 3, 5} }

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
  -- params to handle insertions with index.
  -- i.e. table.insert(t, index, val)
  local params = {}
  -- copy to avoid mutation
  local copy = {unpack(t)}
  for _, x in ipairs({...}) do
    table.insert(params, x)
  end
  table.insert(copy, unpack(params))
  return copy
end

function F.sort(t, fx)
  local copy = {unpack(t)}
  table.sort(copy, fx)
  return copy
end

function F.contains(t, v)
  for _, x in ipairs(t) do
     if x==v then return x end
  end
end

-- function F.find(t, fx)
--   for i, x in ipairs(t) do
--      if fx(x) then
--       return x, i
--      end
--   end
-- end

-- 6. find (refactored with each)
function F.find(array, predicate)
    local found
    F.each(array, function(v, i)
        if not found and predicate(v, i) then
            found = {value = v, index = i}
        end
    end)
    return found and found.value, found and found.index
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
-- ruby alias
F.compact = F.reorder

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
    table.insert(res, fx(i) or i)
  end
  return res
end

function F.keys(t)
  local res={}
  for k, _v in pairs(t) do table.insert(res, k) end
  return res
end

function F.values(t)
  local res={}
  for _k, v in pairs(t) do table.insert(res, v) end
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

function F.is_object(t)
  if type(t) ~= "table" then
    return false
  end

  for k, _ in pairs(t) do
    if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
      return true
    end
  end

  return false
end

F.is_userdata = check_type("userdata")
F.is_table = check_type("table")
F.is_string = check_type("string")
F.is_function = check_type("function")
F.is_number = check_type("number")
F.is_boolean = check_type("boolean")
F.is_coroutine = check_type("thread")

local mtablex = {}
-- multiple value insert
-- can function like extend when used as mtablex.push(tab, unpack(another_tab))
function mtablex.push(t, ...)
  local args = {...}
  for i=1, #args do -- `for i, n` loop form handles sparse arrays well
     table.insert(t, args[i])
  end
  return t
end
-- sort and return
-- returns: table
function mtablex.sorted(t, fx)
  table.sort(t, fx)
  return t
end

-- delete and return
-- returns: table and value removed
function mtablex.delete(t, i)
  local v = table.remove(t, i)
  return t, v
end

-- update table object
for k, func in pairs(mtablex) do
  F[k] = F[k] or func
end

_G.F = F
return F
