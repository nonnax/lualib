#!/usr/bin/env luajit
-- Id$ nonnax Wed Jul 10 10:29:28 2024
-- https://github.com/nonnax
-- Define the table extension library
-- Define the table extension library
-- Method to iterate and apply a function to each element
-- function table.map(t, func)
--   local acc={}
--   for i, v in pairs(t) do
--       acc[i] = func(i, v)
--   end
--   return acc
-- end
table.unpack = unpack --luajit/lua 5.1

local function iterator(t)
    if #t == 0 then
        return pairs(t)
    else
        return ipairs(t)
    end
end

function table.serialize(tbl, indent)
    indent = indent or 0
    local result = {}
    local indentStr = string.rep("  ", indent)  -- Indentation for nested tables

    for k, v in iterator(tbl) do
        local keyStr = tostring(k)
        local valueStr

        if type(v) == "table" then
            -- Recursively serialize inner tables
            valueStr = table.serialize(v, indent + 1)
        else
            valueStr = tostring(v)
        end

        table.insert(result, indentStr .. keyStr .. ": " .. valueStr)
    end

    return "{\n" .. table.concat(result, ",\n") .. "\n" .. string.rep("  ", indent - 1) .. "}"
end


function tabler(t)
    -- Applies built-in table methods to the table 't'
    local self = {}

    -- Serialize function that handles nested tables
    local function serialize(tbl, indent)
        indent = indent or 0
        local result = {}
        local indentStr = string.rep("  ", indent)  -- Indentation for nested tables

        for k, v in iterator(tbl) do
            local keyStr = tostring(k)
            local valueStr

            if type(v) == "table" then
                -- Recursively serialize inner tables
                valueStr = serialize(v, indent + 1)
            else
                valueStr = tostring(v)
            end

            table.insert(result, indentStr .. keyStr .. ": " .. valueStr)
        end

        return "{\n" .. table.concat(result, ",\n") .. "\n" .. string.rep("  ", indent - 1) .. "}"
    end

    self.__tostring = table.serialize

    self.__index = function(tbl, k)
        -- Return a function that calls the built-in table method if it exists
        return function(t, ...)
            local func = table[k]
            if func then
                local ret = func(t, ...)
                if type(ret)=='table' then
                    return tabler(ret)
                end
                -- Handle special cases for specific methods
                if k == 'unpack' then
                    -- Return multiple values for unpack
                    return table.unpack(ret)
                elseif k == 'any' or k == 'all' then
                    -- Return a boolean value
                    return ret
                else
                    -- Return the result or the original table for chainable methods
                    return ret or tbl
                end
            else
                -- Print an error message for undefined methods
                print(k, ..., 'method not found')
                return nil
            end
        end
    end

    return setmetatable(t, self)
end

-- -- Example usage:
-- local t = tabler({1, 2, 3, 4})
--
-- -- Use a custom map function to apply a callback to each element
-- local doubled = t:map(function(x) return x * 2 end)
--
-- print(doubled)  -- Outputs: {1: 2, 2: 4, 3: 6, 4: 8}
--
-- -- The original table can still use other table methods
-- t:insert(5)
-- print(t)  -- Outputs: {1: 1, 2: 2, 3: 3, 4: 4, 5: 5}
--
-- local nestedTable = tabler({a = {x = 10, y = 20}, b = {z = 30}})
-- print(nestedTable)  -- Outputs the serialized nested table

-- returns a table of simple moving averages
function table.SMA(prices, period)
    local sma = {}
    local sum = 0
    for i = 1, period do
        sum = sum + prices[i]
    end
    table.insert(sma, sum / period)

    for i = period + 1, #prices do
        sum = sum - prices[i - period] + prices[i]
        table.insert(sma, sum / period)
    end

    return sma
end

function table.copy(t)
  local u={}
  for k, v in iterator(t) do
    u[k]=v
  end
  return u
end

-- function table.merge(t, u)
--   local m=table.copy(t)
--   for k, v in pairs(u) do
--     m[k]=v
--   end
--   return m
-- end

function table.merge(fx, ...)
  local buff = {}
  for _, t in ipairs({...}) do
    for i, v in pairs(t) do
      table.insert(buff, fx(v))
    end
  end
  return buff
end


function table.reduce_map(fx, init, t, col)
    local prod=function(acc, tx)
        return fx(acc, tx[col])
    end
    return table.reduce(prod, t, init)
end

function table.reduce(t, fx, init)
	local acc = init or {}
	for key, value in iterator(t) do
		acc = fx(acc, key, value)
	end
	return acc
end

function table.pop(t)
    return table.remove(t)
end

function table.shift(t)
    return table.remove(t, 1)
end

-- require lua fun
function table.map_column(rows, k)
    local prod = function(acc, t)
      table.insert(acc, t[k])
      return acc
    end
    return fun.reduce(prod,{}, rows)
end

-- -- Method to iterate and apply a function to each element
function table.map(t, func)
  local acc={}
  for i, v in pairs(t) do
      acc[i] = func(v, i)
  end
  return tabler(acc)
end


function table.printmap(t, __order)
   local kwidth=0
   local vwidth=0
   for k, v in iterator(t) do
      kwidth=math.max(kwidth, k:len())
      vwidth=math.max(vwidth, tostring(v):len())
   end
   for k, v in opairs(t, __order) do
      local kfmt="% "..kwidth.."s"
      local vfmt="% "..vwidth.."s"
      print(string.format(kfmt.." "..vfmt, k, v))
   end
end


-- extract a map subset by keys
function table.slice(t, keys)
   local select={}
   for i, k in iterator(keys) do
     select[k]=t[k] or 0
   end
   return select
end

-- extract a list subset by indices
function table.slice_at(t, start, stop)
   local select={}
   local start = math.max(start + 1, 1)
   local stop =  stop or math.huge
   stop = math.min(#t, stop)
   for i = start, stop do
     table.insert(select, t[i])
   end
   return select
end

-- Function to get the last n items from a table
function table.lastn(tbl, n)
    local result = {}
    for i = math.max(#tbl - n + 1, 1), #tbl do
        table.insert(result, tbl[i])
    end
    return result
end

-- function to get max-col widths of table keys and values
-- useful to build format strings
function table.colwidths(t)
  local w={}
  for k, v in iterator(t) do
    w[k] = w[k] or 0
    w[k] = math.max(tostring(k):len(), tostring(v):len(), w[k])
  end
  return w
end

function table.keys(t)
  local all={}
  for k, v in t do
    all:insert(k)
  end
  return all
end

-- scale table values to another range of values `rmin` to `rmax`
-- math function
-- @return a new table
function table.scale_map(t, rmin, rmax)
	 local min=math.min(table.unpack(t))
	 local max=math.max(table.unpack(t))
	 return t:map(function(v)
	  	local e = (rmin+(rmax-rmin)*((v-min)/(max-min)))
	  	return math.round(e)
	 end)
end

-- function _MODULE.table.keys(t)
-- 	local result = {}
-- 	for key, value in pairs(t) do
-- 		_MODULE.table.insert(result, key)
-- 	end
-- 	return result
-- end

function table.numbersf(t, _fmt, _fmt2)
 local fmt = _fmt or "%0.2f"
 local fmt_low = "%0.7f"
 local fmt2 = _fmt or "%7s"
 local nt={}
 local save_fmt = fmt
 for k, v in iterator(t) do
   local n=v
   if tonumber(v) then
      -- two-passes sanitize number format
      if v < 1 then
        fmt = fmt_low
      else
        fmt = save_fmt
      end
      n = string.format(fmt, v)
      n = string.format(fmt2, n)
   end
   nt[k]=n
 end
 return nt
end

-- zip table values via function fx
-- tables are cut to match the shorter size
function table.zip(fx, a, b)
  local t={}
  local stop = math.min(#a, #b)
  for i=1, stop do
    fx(t, a[i], b[i])
  end
  return t
end

function table.zipmap(a, b)
  local func = function(t, k, v)
      t[k]=v
      return t
  end
  local z = table.zip(func, a, b)
  return z
end

function table.filter(t, func)
    local buff = {}
    for i, v in iterator(t) do
        if func(i, v) then
            buff[i]=v
        end
    end
    return tabler(buff)
end

function table.range(start, stop, step)
    local buff={}
    if not stop then
       start = 1
       stop = start
    end
    local step = step or 1
    for i=start,stop, step do
       table.insert(buff, i)
    end
    return buff
end

-- Function to return the index of the first non-nil value in a table
function table.first_index(data)
    for i, v in iterator(data) do
        if v ~= nil then
            return i
        end
    end
    return nil -- Return nil if no non-nil values are found
end


-- Function to query rows of tables based on patterns
function table.where(rows, patterns)
    -- Function to create a predicate based on patterns
    function curryfx(patterns)
        return function(row)
            for key, pattern in iterator(patterns) do
                if not row[key] or not string.match(row[key], pattern) then
                    return false
                end
            end
            return true
        end
    end

    local predicate = curryfx(patterns)
    return FP.filter(rows, predicate)
end

-- =======================================================

-- Define a module for table extensions with a chainable interface
local TableExtensions = {}
local DataConvert = {}

-- Helper function to create a chainable wrapper around a table
local function tablex(t)
    return setmetatable({ data = t }, {
        __index = function(self, key)
            return TableExtensions[key] or DataConvert[key] or table[key] or self.data[key]
        end,
        __newindex = function(self, key, value)
            self.data[key] = value
        end,
        __tostring = table.serialize
    })
end
--

-- my methods


function TableExtensions:scale_map(rmin, rmax)
     local list=self.data
	 local min=math.min(table.unpack(list))
	 local max=math.max(table.unpack(list))
	 return tablex(list):map(function(v)
	  	local e = (rmax-rmin)*((v-min)/(max-min))+rmin
	  	return e
	 end)
end

function TableExtensions:sort(fx)
     local list = self.data
     table.sort(list, fx)
     self.data = list
     return self
end


function TableExtensions:merge(fx, ...)
  local buff = {}
  for _, t in iterator({...}) do
    for i, v in pairs(t) do
      table.insert(buff, fx(v))
    end
  end
  self.data = buff
  return self
end

-- TableExtensions methods

function TableExtensions:map(fn)
    local result = {}
    for i, v in iterator(self.data) do
        result[i] = fn(v, i)
    end
    self.data = result
    return self
end

function TableExtensions:filter(fn)
    local result = {}
    for i, v in iterator(self.data) do
        if fn(v, i) then
            table.insert(result, v)
        end
    end
    self.data = result
    return self
end

function TableExtensions:each(fn)
    for i, v in iterator(self.data) do
        fn(v, i)
    end
    return self
end

function TableExtensions:reduce(fn, init)
    local acc = init
    for i, v in iterator(self.data) do
        acc = fn(acc, v, i)
    end
    return acc
end

function TableExtensions:find(fn)
    for i, v in iterator(self.data) do
        if fn(v, i) then
            return v
        end
    end
    return nil
end

function TableExtensions:all(fn)
    for i, v in iterator(self.data) do
        if not fn(v, i) then
            return false
        end
    end
    return true
end

function TableExtensions:any(fn)
    for i, v in iterator(self.data) do
        if fn(v, i) then
            return true
        end
    end
    return false
end

function TableExtensions:count(fn)
    local count = 0
    for i, v in iterator(self.data) do
        if fn(v, i) then
            count = count + 1
        end
    end
    return count
end

function TableExtensions:max(fn)
    local maxValue = nil
    for i, v in iterator(self.data) do
        if not maxValue or fn(v, maxValue) then
            maxValue = v
        end
    end
    return maxValue
end

function TableExtensions:min(fn)
    local minValue = nil
    for i, v in iterator(self.data) do
        if not minValue or fn(v, minValue) then
            minValue = v
        end
    end
    return minValue
end

function TableExtensions:group_by(fn)
    local result = {}
    for i, v in iterator(self.data) do
        local key = fn(v, i)
        if not result[key] then
            result[key] = {}
        end
        table.insert(result[key], v)
    end
    self.data = result
    return self
end

function TableExtensions:partition(fn)
    local truthy, falsy = {}, {}
    for i, v in iterator(self.data) do
        if fn(v, i) then
            table.insert(truthy, v)
        else
            table.insert(falsy, v)
        end
    end
    self.data = { truthy, falsy }
    return self
end

function TableExtensions:each_slice(slice_size, fn)
    local slice = {}
    for i, v in iterator(self.data) do
        table.insert(slice, v)
        if #slice == slice_size then
            fn(slice)
            slice = {}
        end
    end
    if #slice > 0 then
        fn(slice)
    end
    return self
end

function TableExtensions:transpose(pad_value)
    pad_value = pad_value or nil
    local max_length = 0
    for _, row in iterator(self.data) do
        if #row > max_length then
            max_length = #row
        end
    end
    for _, row in iterator(self.data) do
        while #row < max_length do
            table.insert(row, pad_value)
        end
    end
    local result = {}
    for col = 1, max_length do
        result[col] = {}
        for row = 1, #self.data do
            result[col][row] = self.data[row][col]
        end
    end
    self.data = result
    return self
end

function TableExtensions:zip(...)
    local args = { ... }
    local result = {}
    local minLength = #self.data
    for _, tbl in iterator(args) do
        if #tbl < minLength then
            minLength = #tbl
        end
    end
    for i = 1, minLength do
        local tuple = { self.data[i] }
        for _, tbl in iterator(args) do
            table.insert(tuple, tbl[i])
        end
        table.insert(result, tuple)
    end
    self.data = result
    return self
end

function TableExtensions:flatten()
    local result = {}
    local function flatten_helper(t)
        for _, v in iterator(t) do
            if type(v) == "table" then
                flatten_helper(v)
            else
                table.insert(result, v)
            end
        end
    end
    flatten_helper(self.data)
    self.data = result
    return self
end

function TableExtensions:filtermap(fn)
    local result = {}
    for i, v in iterator(self.data) do
        local mappedValue = fn(v, i)
        if mappedValue ~= nil then
            table.insert(result, mappedValue)
        end
    end
    self.data = result
    return self
end

-- DataConvert methods

function TableExtensions:rows_to_vectors(key)
    local vector = {}
    local rows = self.data
    for i, row in iterator(rows) do
        vector[i] = row[key]
    end
    return tablex(vector)
end

function TableExtensions:vectors_to_rows(key)
    local rows = {}
    local vector = self.data
    for i, value in iterator(vector) do
        rows[i] = { [key] = value }
    end
    return tablex(rows)
end

function TableExtensions:rows_to_matrix()
    local matrix = {}
    local rows = self.data
    for _, row in iterator(rows) do
        for key, value in pairs(row) do
            if not matrix[key] then
                matrix[key] = {}
            end
            table.insert(matrix[key], value)
        end
    end
    return tablex(matrix)
end

function TableExtensions:matrix_to_rows()
    local rows = {}
    local matrix = self.data
    local numRows = #matrix[next(matrix)] -- assume all vectors have the same length
    for i = 1, numRows do
        local row = {}
        for key, vector in pairs(matrix) do
            row[key] = vector[i]
        end
        table.insert(rows, row)
    end
    return tablex(rows)
end

-- Extend TableExtensions with DataConvert methods
-- for key, func in pairs(DataConvert) do
--     TableExtensions[key] = func
-- end

-- Method to retrieve the resulting table
function TableExtensions:to_table()
    return self.data
end

-- -- Make tablex globally available
_G.tablex = tablex

return TableExtensions
