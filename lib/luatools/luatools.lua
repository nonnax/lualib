#!/usr/bin/env luajit
-- Id$ nonnax Tue Jul  9 20:34:06 2024
-- https://github.com/nonnax
require 'lfs'


-- table print utils
function puts(...)
  for i, e in ipairs({...}) do
    print(json.encode(e))
  end
end

function dump(t, fx)
  assert(type(t)=='table', 'not a table')
  for k, v in pairs(t) do
    if type(v) == 'table' then
      print()
      dump(v)
    else
      if fx then
        fx(v, k)
      else
        print(k, v)
      end
    end
  end
  return t
end

-- helper for iterators w/ function arguments
function identity(e)
  return e
end

-- iterator with pre-processor
-- function imap(fx, data)
--   return coroutine.wrap(function()
--      for i, v in ipairs(data) do
--         coroutine.yield(i, fx(v))
--      end
--   end)
-- end
--
-- function ifilter(fx, data)
--   return coroutine.wrap(function()
--      for i, v in iter(data) do
--         local e = fx(v)
--         if e then coroutine.yield(i, e) end
--      end
--   end)
-- end

-- extra math from numbers.lua
-- iterators
-- auto-select safe iterator
function iter(t)
  if t[1] == nil then
    return pairs(t)
  end
  return ipairs(t)
end

-- ordered pairs map iterator
function opairs(t, o)
  if not o then -- return basic pairs
    return pairs(t)
  end
  return coroutine.wrap(
    function()
      for i, k in ipairs(o) do
        coroutine.yield(k, t[k])
      end
    end
  )
end

function unpack_map(h, keystr)
  -- return values for matching keys or false
  local vals={}
  for i, k in ipairs(keystr:split()) do
    table.insert(vals, h[k] or false) -- using `nil` causes unpredictable table inserts
  end
  return unpack(vals)
end

function destructure(t)
  -- return values for matching keys or false
  -- local t={a=1, b=2, c=3}
  -- local a, b = destructure(t){'a', 'b'}
  return function(idxs)
    local vals = {}
    for i, k in ipairs(idxs) do
      table.insert(vals, t[k] or false)
    end
    return unpack(vals)
  end
end

table.destructure=destructure


function is_map(t)
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


-- function subtable(h, ...)
--   -- return a subtable given a list of keys
--   local extract={}
--   for i, k in ipairs({...}) do
--     extract[k]=h[k]
--   end
--   return extract
-- end
--
-- table.subtable=subtable

function runif(cond, fx)
  local res
  if cond then
    res=fx()
  end
  return res
end



function numberf(number)
    -- Convert the number to a string
    if type(number) ~= 'number' then return number end
    local formatted = string.format("%0.2f", number)
    -- Split the integer part and the decimal part
    local integerPart, decimalPart = formatted:match("^(%-?%d+)(%.%d+)$")

    -- Add commas to the integer part
    integerPart = integerPart:reverse():gsub("(%d%d%d)", "%1,"):reverse()

    -- Remove a leading comma if it exists
    if integerPart:sub(1, 1) == "," then
        integerPart = integerPart:sub(2)
    end

    return integerPart .. decimalPart
end
-- function rescale(value, value_start, value_stop, to_start, to_stop)
--     return to_start + (to_stop - to_start) * ((value - value_start) / (value_stop - value_start))
-- end

-- return optimal fmt based on maxvalue and a default fmt string
function optimal_fmt(fmt, maxvalue)
  local fmt = fmt or "%.2f"
  local orig_fmt = fmt:match("[^%%]+")
  local width = string.format(fmt, maxvalue):len()
  return "%"..width..orig_fmt
end


require 'luatools/stdlibx'