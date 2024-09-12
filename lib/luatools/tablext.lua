#!/usr/bin/env luajit
-- id$ nonnax wed jul 10 10:29:28 2024
-- https://github.com/nonnax
-- define the table extension library
-- define the table extension library
-- method to iterate and apply a function to each element
-- function table.map(t, func)
--   local acc={}
--   for i, v in pairs(t) do
--       acc[i] = func(i, v)
--   end
--   return acc
-- end
tabtools = require 'luatools/tabletools'
require 'luatools/tabler'

table.unpack = unpack --luajit/lua 5.1

-- =======================================================
-- define a module for table extensions with a chainable interface
local table_extensions = {}
local data_convert = {}

-- helper function to create a chainable wrapper around a table
local function tablex(t)
    return setmetatable({ data = t }, {
        __index = function(self, key)
            return table_extensions[key] or data_convert[key] or table[key] or self.data[key]
        end,
        __newindex = function(self, key, value)
            self.data[key] = value
        end,
        __tostring = table.serialize
    })
end
--
-- my methods

function table_extensions:scale_map(rmin, rmax)
     local list=self.data
	 local min=math.min(table.unpack(list))
	 local max=math.max(table.unpack(list))
	 return tablex(list):map(function(v)
	  	local e = (rmax-rmin)*((v-min)/(max-min))+rmin
	  	return e
	 end)
end

function table_extensions:sort(fx)
     local list = self.data
     table.sort(list, fx)
     self.data = list
     return self
end


function table_extensions:merge(fx, ...)
  local buff = {}
  for _, t in ipairs({...}) do
    for i, v in ipairs(t) do
      table.insert(buff, fx(v))
    end
  end
  self.data = buff
  return self
end

-- table_extensions methods
function table_extensions:map(fn)
    local result = {}
    for i, v in iterator(self.data) do
        result[i] = fn(v, i)
    end
    self.data = result
    return self
end

function table_extensions:filter(fn)
    local result = {}
    for i, v in iterator(self.data) do
        if fn(v, i) then
            table.insert(result, v)
        end
    end
    self.data = result
    return self
end

function table_extensions:each(fn)
    for i, v in iterator(self.data) do
        fn(v, i)
    end
    return self
end

function table_extensions:reduce(fn, init)
    local acc = init
    for i, v in iterator(self.data) do
        acc = fn(acc, v, i)
    end
    if type(acc)=='table' then
        self.data=acc
        return self
    else
        return acc
    end
end

function table_extensions:find(fn)
    for i, v in iterator(self.data) do
        if fn(v, i) then
            return v
        end
    end
    return nil
end

function table_extensions:all(fn)
    for i, v in iterator(self.data) do
        if not fn(v, i) then
            return false
        end
    end
    return true
end

function table_extensions:any(fn)
    for i, v in iterator(self.data) do
        if fn(v, i) then
            return true
        end
    end
    return false
end

function table_extensions:count(fn)
    local count = 0
    for i, v in iterator(self.data) do
        if fn(v, i) then
            count = count + 1
        end
    end
    return count
end

function table_extensions:max(fn)
    local max_value = nil
    for i, v in iterator(self.data) do
        if not max_value or fn(v, max_value) then
            max_value = v
        end
    end
    return max_value
end

function table_extensions:min(fn)
    local min_value = nil
    for i, v in iterator(self.data) do
        if not min_value or fn(v, min_value) then
            min_value = v
        end
    end
    return min_value
end

function table_extensions:group_by(fn)
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

function table_extensions:partition(fn)
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

function table_extensions:each_slice(slice_size, fn)
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

function table_extensions:transpose(pad_value)
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

function table_extensions:zip(...)
    local args = { ... }
    local result = {}
    local min_length = #self.data
    for _, tbl in iterator(args) do
        if #tbl < min_length then
            min_length = #tbl
        end
    end
    for i = 1, min_length do
        local tuple = { self.data[i] }
        for _, tbl in iterator(args) do
            table.insert(tuple, tbl[i])
        end
        table.insert(result, tuple)
    end
    self.data = result
    return self
end

function table_extensions:flatten()
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

function table_extensions:filtermap(fn)
    local result = {}
    for i, v in iterator(self.data) do
        local mapped_value = fn(v, i)
        if mapped_value ~= nil then
            table.insert(result, mapped_value)
        end
    end
    self.data = result
    return self
end

-- data_convert methods

function table_extensions:rows_to_vectors(key)
    local vector = {}
    local rows = self.data
    for i, row in iterator(rows) do
        vector[i] = row[key]
    end
    return tablex(vector)
end

function table_extensions:vectors_to_rows(key)
    local rows = {}
    local vector = self.data
    for i, value in iterator(vector) do
        rows[i] = { [key] = value }
    end
    return tablex(rows)
end

function table_extensions:rows_to_matrix()
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

function table_extensions:matrix_to_rows()
    local rows = {}
    local matrix = self.data
    local num_rows = #matrix[next(matrix)] -- assume all vectors have the same length
    for i = 1, num_rows do
        local row = {}
        for key, vector in pairs(matrix) do
            row[key] = vector[i]
        end
        table.insert(rows, row)
    end
    return tablex(rows)
end

-- extend table_extensions with data_convert methods
-- for key, func in pairs(data_convert) do
--     table_extensions[key] = func
-- end

-- method to retrieve the resulting table
function table_extensions:to_table()
    return self.data
end

-- -- make tablex globally available
_G.tablex = tablex

return table_extensions
