#!/usr/bin/env luajit
-- Id$ nonnax Sun Aug  4 13:30:39 2024
-- https://github.com/nonnax
-- functional.lua

local Functional = {}

unpack = table.unpack or unpack

function Map(data)
  local self = {value = data}
  function self.map(self, fx, ...)
    return Map(fx(self.value, ...))
  end
  self._ = self.map
  return setmetatable(self, {
    __call=function(self) return self.value end
  })
end

local __old_print = print
-- print and return orig args
function print(...)
  __old_print(...)
  return ...
end

-- local function F.iter(t)
--     if type(t) == 'table' then
--       -- If property of 1 is empty then
--       -- F.iterate as a regular keyed table
--       if t[1] == nil then
--         return pairs(t)
--       end
--       return ipairs(t)
--     end
--     error('Expected table, got ' .. tostring(t))
-- end

function F.iter(t)
  return coroutine.wrap(function()
    -- iterate table
    for i=1, #t do
      coroutine.yield(i, t[i])
    end
    -- iterate over the object-like part
    for k, v in pairs(t) do
      if type(k) ~= "number" or k > #t then
        coroutine.yield(k, v)
      end
    end
  end)
end

--- Map function
-- Applies a function to each element of a table, returning a new table with the results
-- @param tbl table: The input table to map over
-- @param func function: The function to apply to each element
-- @return table: A new table with the mapped values

function Functional.map(tbl, func)
    local result = {}
    for i, v in F.iter(tbl) do
        result[i] = func(v, i)
    end
    return result
end


--- Reduce function
-- Reduces a table to a single value using a binary function
-- @param tbl table: The input table to reduce
-- @param func function: The binary function to apply
-- @param initial any: The initial accumulator value
-- @return any: The result of the reduction
function Functional.reduce(tbl, func, initial)
    local acc = initial
    for i, v in F.iter(tbl) do
        acc = func(acc, v, i)
    end
    return acc
end

--- Filter function
-- Filters elements of a table based on a predicate function
-- @param tbl table: The input table to filter
-- @param predicate function: The function to determine if an element should be included
-- @return table: A new table with only the elements that satisfy the predicate
function Functional.filter(tbl, predicate)
    local result = {}
    for i, v in F.iter(tbl) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

--- Filter map function
-- Filters elements of a table based on a predicate function and return mapped result
-- @param tbl table: The input table to filter
-- @param predicate function: The function to determine if an element should be included
-- @return table: A new table with return mapped result that satisfy the predicate
function Functional.filtermap(tbl, predicateFunc)
    local result = {}
    for i, v in F.iter(tbl) do
        local mappedValue = predicateFunc(v, i)
        if mappedValue ~= nil then
            table.insert(result, mappedValue)
        end
    end
    return result
end

-- A flatMap higher-order function applies a given function to each element of a `list` and then flattens the result into a single list.
-- This can be useful for scenarios where the function returns lists that need to be combined into one.
function Functional.flatmap(array, func)
    local result = {}
    for i, v in ipairs(array) do
        local mappedValue = func(v)
        if type(mappedValue) == "table" then
            for j = 1, #mappedValue do
                table.insert(result, mappedValue[j])
            end
        else
            table.insert(result, mappedValue)
        end
    end
    return result
end
--- Find function
-- Finds the first element in a table that satisfies a predicate function
-- @param tbl table: The input table to search
-- @param predicate function: The function to determine if an element satisfies the condition
-- @return any, number: The first element that satisfies the predicate and its index, or nil if not found
function Functional.find(tbl, predicate)
    for i, v in F.iter(tbl) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil
end

--- Every function
-- Checks if all elements in a table satisfy a predicate function
-- @param tbl table: The input table to check
-- @param predicate function: The function to determine if an element satisfies the condition
-- @return boolean: True if all elements satisfy the predicate, false otherwise
function Functional.every(tbl, predicate)
    for i, v in F.iter(tbl) do
        if not predicate(v, i) then
            return false
        end
    end
    return true
end

--- Some function
-- Checks if at least one element in a table satisfies a predicate function
-- @param tbl table: The input table to check
-- @param predicate function: The function to determine if an element satisfies the condition
-- @return boolean: True if at least one element satisfies the predicate, false otherwise
function Functional.some(tbl, predicate)
    for i, v in F.iter(tbl) do
        if predicate(v, i) then
            return true
        end
    end
    return false
end

--- Keys function
-- Extracts the keys from a dictionary table into a list
-- @param tbl table: The input dictionary table
-- @return table: A list of keys from the dictionary
function Functional.keys(tbl)
    local result = {}
    for key in pairs(tbl) do
        table.insert(result, key)
    end
    return result
end

--- Values function
-- Extracts the values from a dictionary table into a list
-- @param tbl table: The input dictionary table
-- @return table: A list of values from the dictionary
function Functional.values(tbl)
    local result = {}
    for _, value in pairs(tbl) do
        table.insert(result, value)
    end
    return result
end

--- Flatten function
-- Flattens a nested table into a single-level table
-- @param tbl table: The input nested table
-- @return table: A new table with the flattened values
function Functional.flatten(tbl)
    local result = {}
    local function flattenHelper(t)
        for _, v in F.iter(t) do
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

--- Zip function
-- Combines multiple tables into a single table of tables
-- @param ... table: Variable number of input tables to zip
-- @return table: A new table with zipped values
function Functional.zip(...)
    local result = {}
    local tables = {...}
    local length = #tables[1] -- assumes all tables have the same length
    for i = 1, length do
        local tuple = {}
        for _, t in ipairs(tables) do
            table.insert(tuple, t[i])
        end
        table.insert(result, tuple)
    end
    return result
end

--- Unzip function
-- Splits a table of tuples into multiple tables
-- @param tbl table: The input table of tuples
-- @return table: A list of tables extracted from tuples
function Functional.unzip(tbl)
    local result = {}
    local length = #tbl[1] -- assumes all tuples have the same length
    for i = 1, length do
        result[i] = {}
    end
    for _, tuple in F.iter(tbl) do
        for j, value in ipairs(tuple) do
            table.insert(result[j], value)
        end
    end
    return result
end

--- Compose function
-- Composes multiple functions into a single function
-- @param ... function: Variable number of functions to compose
-- @return function: A new function that is the composition of the input functions
function Functional.compose(...)
    local funcs = {...}
    return function(...)
        local result = ...
        for i = #funcs, 1, -1 do
            result = funcs[i](result)
        end
        return result
    end
end

--- Flow function
-- Creates a new function that is the composition of multiple functions applied in sequence
-- @param ... function: Variable number of functions to flow
-- @return function: A new function that applies the input functions in sequence
function Functional.flow(...)
    local funcs = {...}
    return function(...)
        local result = ...
        for i = 1, #funcs do
            result = funcs[i](result)
        end
        return result
    end
end

--- Partial function
-- Creates a new function with pre-applied arguments
-- @param func function: The function to partially apply arguments to
-- @param ... any: Variable number of arguments to pre-apply
-- @return function: A new function with pre-applied arguments
function Functional.partial(func, ...)
    local args = {...}
    return function(...)
        local newArgs = {...}
        for i, v in ipairs(newArgs) do
            table.insert(args, v)
        end
        return func(table.unpack(args))
    end
end

--- Curry function
-- Curries a function to allow partial application of arguments
-- @param func function: The function to curry
-- @return function: A curried version of the input function
function Functional.curry(func)
    local function curryHelper(argList, n)
        n = n or debug.getinfo(func, "u").nparams
        return function(...)
            local newArgs = {...}
            for _, v in ipairs(newArgs) do
                table.insert(argList, v)
            end
            if #argList >= n then
                return func(table.unpack(argList))
            else
                return curryHelper(argList, n)
            end
        end
    end
    return curryHelper({})
end


function Functional.group_by(tbl, keyFunc)
    local groups = {}
    for i, v in ipairs(tbl) do
        local key = keyFunc(v)
        if not groups[key] then
            groups[key] = {}
        end
        table.insert(groups[key], v)
    end
    return groups
end

function Functional.partition(tbl, predicateFunc)
    local partitions = {
        [true]={},
        [false]={}
    }
    for _, v in F.iter(tbl) do
        table.insert(partitions[ predicateFunc(v) == true ], v)
    end

    return partitions
end

function Functional.each_slice(tbl, size)
    local slices = {}
    local sliceStart = 1

    while sliceStart <= #tbl do
        local sliceEnd = math.min(sliceStart + size - 1, #tbl)
        local slice = {}
        for i = sliceStart, sliceEnd do
            table.insert(slice, tbl[i])
        end
        table.insert(slices, slice)
        sliceStart = sliceEnd + 1
    end

    return slices
end

function Functional.first(tbl, n)
    local n = n or 1
    local result = {}
    for i = 1, math.min(n, #tbl) do
        table.insert(result, tbl[i])
    end
    return result
end

function Functional.last(tbl, n)
    local n = n or 1
    local result = {}
    for i = math.max(1, #tbl - n + 1), #tbl do
        table.insert(result, tbl[i])
    end
    return result
end

function Functional.insert(tbl, v)
    -- local params = Functional.filter({idx, v}, -[[ x | x ~= nil ]])
    -- table.insert(tbl, unpack(params))
    table.insert(tbl, v)
    return tbl
end

function Functional.sort(tbl, fx)
    table.sort(tbl, fx)
    return tbl
end

function Functional.remove(tbl, n)
    table.remove(tbl, n)
    return tbl
end

function Functional.once(fx, gx)
    local done=false
    return function(...)
        if not done then
            done = true
            return fx(...)
        else
            if gx then return gx(...) end
        end
    end
end

function Functional.times(stop, fx)
    local result = {}
    for i = 1, stop do
        table.insert(result, fx(i))
    end
    return result
end

-----------------------------------------------------------
--- make functions available globally for small codebases
-----------------------------------------------------------
function Functional.global()
    for name, fx in pairs(Functional) do
        _G[name]=fx
    end
end

return Functional
