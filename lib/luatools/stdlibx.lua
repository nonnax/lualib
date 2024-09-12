#!/usr/bin/env luajit

-- Id$ nonnax Fri Jul  5 16:30:06 2024
-- https://github.com/nonnax
-- require 'luatools'
-- require 'luatools/tablext'
lfs = require 'lfs'
table.unpack = unpack

-- global unpack_map
function unpack_map(h, keystr)
  -- return values for matching keys or false
  local vals={}
  for k in keystr:gmatch("%S+") do
    table.insert(vals, h[k] or false) -- using a `nil` substitute causes unpredictable table inserts
  end
  return unpack(vals)
end
-- alias
unpacks = unpack_map
table.unpacks = unpack_map
-------------------------------------------------------------------------------------
-- io ext
-------------------------------------------------------------------------------------
function io.exists(path)
  local file = io.open(path, "r")
  if file == nil then return false end
  file:close()
  return true
end

function io.readfile(path)
  local file = assert(io.open(path, "r"))
  local content = assert(file:read("*a"))
  file:close()
  return content
end

function io.readfile_safe(path, default)
  local res = default or ""
  if io.exists(path) then
    res = io.readfile(path)
  end
  return res
end

function io.writefile(path, content)
  local file = assert(io.open(path, "w"))
  assert(file:write(content))
  file:close()
end

function io.capture(cmd)
  local file = assert(io.popen(cmd, "r"))
  local stdout = assert(file:read("*a"))
  file:close()
  return stdout
end

-- alias
os.capture=io.capture

function io.filetime(path)
  local t = lfs.attributes(path, 'modification')
  return t
end

os.filetime = io.filetime


-- file utils

function io.readjson(path)
  local text = assert(io.readfile(path), 'file not found')
  return json.decode(text)
end

function io.readjson_safe(path, default)
  local res = default or {}
  if io.exists(path) then
    res = io.readjson(path)
  end
  return res
end

function io.writejson(f, db)
  io.writefile(f, json.encode(db))
end

-------------------------------------------------------------------------------------
-- os ext
-------------------------------------------------------------------------------------

function os.is_dir(path)
    -- lfs.attributes will error on a filename ending in '/'
    return path:sub(-1) == "/" or lfs.attributes(path, "mode") == "directory"
end
-- audio utils
function os.play(f)
    os.execute("play -q "..f)
end
-- alias
splay = os.play

-- ANSI escape codes for colors

-- time utils
-- Function to get the integer timestamp for 8 AM of the current day
function os.timeat(h, m, s)
    -- Get the current time
    local now = os.time()

    -- Get the current date as a table
    local dateTable = os.date("*t", now)

    -- Adjust the table to 8 AM
    dateTable.hour = h or 8
    dateTable.min = m or 0
    dateTable.sec = s or 0

    -- Convert the adjusted table back to a timestamp
    local startTime = os.time(dateTable)

    return startTime
end

-- get minutes passed since startTime
function os.elapsed_min(startTime)
  local elapsedMin=(os.time()-startTime)/60
  return elapsedMin
end
-- alias
os.elapsed_mins=os.elapsed_min

function os.timenow()
  return os.date("%x %X", os.time())
end

-- day subtraction
function os.today_minus(n)
  local t=os.time()
  local tt = os.date("*t", t)
  tt.day=tt.day-n
  return os.time(tt)
end

-- less is a standard os.time table
-- {hour = 9,min = 1,wday = 7,day = 18,month = 7,year = 2024,sec = 9,yday = 202,isdst = false}
function os.time_minus(less)
  local t=os.time()
  tt = os.date("*t", t)
  for k, v in pairs(less) do
   tt[k]=tt[k]-less[k]
  end
  return os.time(tt)
end

-- get hours and minutes difference
function os.difftimeHM(date1, date2)
    -- Get the difference in seconds
    local diffInSeconds = os.difftime(date2, date1)

    -- Convert seconds to hours and minutes
    local hours = math.floor(diffInSeconds / 3600)
    local minutes = math.floor((diffInSeconds % 3600) / 60)

    return hours, minutes
end

-- parse a datetime against a pattern
function os.timeparse(datetimeString, pattern)
    local pattern = pattern or "(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)"
    local month, day, year, hour, min, sec = datetimeString:match(pattern)
    local epochTime = os.time({
        year = tonumber(year) + 2000,  -- Assuming year is in 2-digit format
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    })
    return epochTime
end

function os.beep(freq, rep, dur, len, verbose)
  local env = {freq=freq or 4000, rep=rep or 1, dur=dur or 50, len=len or 20}
  local cmd="beep -f {freq} -r {rep} -d {dur} -l {len}" * env
  if verbose then print(cmd) end
  os.execute(cmd)
end

function os.raw_mode(on)
  local on = on or true
  if on then
    os.execute("stty -icanon") -- put TTY in raw mode
  else
    os.execute("stty icanon") -- at end of program, put TTY back to normal mode
  end
end

function os.normal_mode()
  os.execute("stty icanon") -- at end of program, put TTY back to normal mode
end

function os.cols()
  return tonumber(io.capture('tput cols'))
end

function os.rows()
  return tonumber(io.capture('tput lines'))
end

-------------------------------------------------------------------------------------
-- table ext
-------------------------------------------------------------------------------------
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
  table[k] = func
end
-------------------------------------------------------------------------------------
-- string ext
-------------------------------------------------------------------------------------

function string.split(s, sep)
	local sep = sep or "%s+"
	local result = {}
	local i, j = s:find(sep)
	while i ~= nil do
		table.insert(result, s:sub(1, i - 1))
		s = s:sub(j + 1) or ""
		i, j = s:find(sep)
	end
	table.insert(result, s)
	return result
end

function string:rtrim(ch)
 local ch = ch or "%s+"
 return (self:gsub(ch.."$",""))
end

function string:ltrim(ch)
 local ch = ch or "%s+"
 return (self:gsub("^"..ch,""))
end

function string:trim(ch)
 return (self:ltrim(ch):rtrim(ch))
end

local function L(expr)
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

-- Function to perform string interpolation
local function interpolate(str, subs)
    table.foreach(subs, function(k, v)
        str = str:gsub(string.format('{%s}', k), tostring(v))  -- Ensure the value is a string
    end)
    return str
end


local pad = {}

-- Left padding: Adds padding to the left of the string
function pad.lpad(text, width, char)
    char = char or " "
    local length = #text
    if length >= width then
        return text
    end

    return string.rep(char, width - length) .. text
end

-- Right padding: Adds padding to the right of the string
function pad.rpad(text, width, char)
    char = char or " "
    local length = #text
    if length >= width then
        return text
    end

    return text .. string.rep(char, width - length)
end

-- Center padding: Adds padding to both sides of the string
function pad.center(text, width, char)
    char = char or " "
    local length = #text
    if length >= width then
        return text
    end

    local total_padding = width - length
    local left_padding = math.floor(total_padding / 2)
    local right_padding = total_padding - left_padding

    return string.rep(char, left_padding) .. text .. string.rep(char, right_padding)
end

-- merge pad functions into string object
for k, v in pairs(pad) do
  string[k] = v
end

-- string utils

local function format(str, subs)
    return string.format(str, unpack(subs))
end


local function matchformat(pattern, t)
    local values={}
    local pattern_copy=pattern
    for k in string.gmatch(pattern, "%b{}") do
      pattern_copy=pattern_copy:gsub(k, "")
      k = k:gsub("[{}]","")
      table.insert(values, t[k])

    end
    return string.format(pattern_copy, unpack(values))
end

-- return optimal fmt based on maxvalue and a default fmt string
function optimal_fmt(fmt, maxvalue)
  local fmt = fmt or "%.2f"
  local orig_fmt = fmt:match("[^%%]+")
  local width = string.format(fmt, maxvalue):len()
  return "%"..width..orig_fmt
end


mt=getmetatable("")

string_mt=getmetatable("")
string_mt.__unm=L
string_mt.__mod = interpolate
-- string_mt.__mod = format
string_mt.__div = matchformat
-- update string object
setmetatable(string, string_mt)


-------------------------------------------------------------------------------------
-- math ext
-------------------------------------------------------------------------------------
math.randomseed(os.time())

-- math utils
function math.to_degrees(rad)
 -- Converts radians to a Gosu-compatible angle using the formula self * 180.0 / Math::PI + 90
  local deg = rad * 180/math.pi + 90
  return deg
end

function math.between(value, start, stop)
    return value >= start and value <= stop
end


function math.minmax(...)
  local min = math.min(...)
  local max = math.max(...)
  return min, max
end

-- Function to rescale values
-- function math.rescale(value, old_min, old_max, new_min, new_max)
--     oldRange = (old_max - old_min)
--     newRange = (new_max - new_min)
--     newValue = (((value - old_min) * newRange) / oldRange) + new_min
--     -- when ranges min == 0 simply becomes:
--     -- newValue = (value * new_max) / old_max
--     -- return to_start + (new_max - new_min) * ((value - old_min) / (old_max - old_min))
--     return newValue
-- end

-- rescales a value into a new range
function math.scale(value, old_min, old_max, scale_min, scale_max)
    local old_ratio = (value - old_min) / (old_max - old_min)
    local scale_range = scale_max - scale_min

    return old_ratio * scale_range + scale_min
end

math.rescale = math.scale

function math.clamp(n, low, high)
    return math.max(low, math.min(n, high))
end

function math.round(number, decimal_places)
    local decimal_places = decimal_places  or 2
    local multiplier = 10^decimal_places
    return math.floor(number * multiplier + 0.5) / multiplier
end

function math.delta(a, b)
   return b/a-1
end

----------------------------------------------------
-- table ext
----------------------------------------------------
-- accepts multi-table args, incompatible with Functor mapping
function table.extent(...)
  local acc={}
  for i, v in ipairs({...}) do
    if type(v)=='table' then
      if #v > 0 then
        table.insert(acc, math.min(unpack(v)))
        table.insert(acc, math.max(unpack(v)))
      end
    else
      table.insert(acc, v)
    end
  end
  local tmin, tmax = math.min(unpack(acc)), math.max(unpack(acc))
  return tmin, tmax
end

----------------------------------------------------
-- F.lua
-- functional lib
----------------------------------------------------
-- local functions

-- top-level type-checker function factory
local function check_type(name)
    return function(value)
        return type(value) == name
    end
end

-- functor
function Map(data)
  local self = {value = data}
  function self:map(fx, ...)
    return Map(fx(self.value, ...))
  end
  self._ = self.map
  return setmetatable(self, {
    __call=function(self) return self.value end
  })
end

local F = {}

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
    local v = array[i]
    result[i] = func(v, i)
  end
  return result
end

-- 2. filter
function F.filter(array, predicate)
  local result = {}
  for i, v in ipairs(array) do
    if predicate(v, i) then result[#result + 1] = v end
  end
  return result
end

-- 3. reduce
function F.reduce(array, func, initial)
  local acc = initial
  for i, v in ipairs(array) do
    local v = array[i]
    acc = func(acc, v, i)
  end
  return acc
end

-- make F global
_G.F = F
