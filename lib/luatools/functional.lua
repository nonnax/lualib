#!/usr/bin/env luajit
-- Id$ nonnax Fri Aug 16 16:35:29 2024
-- https://github.com/nonnax
-- functional.lua
local functional = {}

-- 1. map
function functional.map(array, func)
    local result = {}
    for i, v in ipairs(array) do
        result[i] = func(v, i)
    end
    return result
end

-- 2. filter
function functional.filter(array, predicate)
    local result = {}
    for i, v in ipairs(array) do
        if predicate(v, i) then
            result[#result + 1] = v
        end
    end
    return result
end

-- 3. reduce
function functional.reduce(array, func, initial)
    local acc = initial
    for i, v in ipairs(array) do
        acc = func(acc, v, i)
    end
    return acc
end

-- 4. each
function functional.each(array, func)
    for i, v in ipairs(array) do
        func(v, i)
    end
end

-- 5. flatMap
function functional.flatMap(array, func)
    local result = {}
    for i, v in ipairs(array) do
        local mapped = func(v, i)
        for _, mv in ipairs(mapped) do
            result[#result + 1] = mv
        end
    end
    return result
end

-- 6. find
function functional.find(array, predicate)
    for i, v in ipairs(array) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil
end

-- 7. compose
function functional.compose(...)
    local functions = {...}
    return function(x)
        for i = #functions, 1, -1 do
            x = functions[i](x)
        end
        return x
    end
end

-- 7.1 flow
function functional.flow(...)
    local functions = {...}
    return function(x)
        for i = 1, #functions do
            x = functions[i](x)
        end
        return x
    end
end

-- 8. curry
function functional.curry(func, n)
    n = n or debug.getinfo(func, "u").nparams
    return function(...)
        local args = {...}
        if #args >= n then
            return func(table.unpack(args))
        else
            return functional.curry(function(...)
                return func(table.unpack(args), ...)
            end, n - #args)
        end
    end
end

-- 9. partial
function functional.partial(func, ...)
    local args = {...}
    return function(...)
        local newArgs = {...}
        local finalArgs = {}
        for _, v in ipairs(args) do
            finalArgs[#finalArgs + 1] = v
        end
        for _, v in ipairs(newArgs) do
            finalArgs[#finalArgs + 1] = v
        end
        return func(table.unpack(finalArgs))
    end
end

-- 10. memoize
function functional.memoize(func)
    local cache = {}
    return function(...)
        local key = table.concat({...}, ",")
        if not cache[key] then
            cache[key] = func(...)
        end
        return cache[key]
    end
end

-- 11. chunk
function functional.chunk(array, size)
    local result = {}
    for i = 1, #array, size do
        local chunk = {}
        for j = i, math.min(i + size - 1, #array) do
            chunk[#chunk + 1] = array[j]
        end
        result[#result + 1] = chunk
    end
    return result
end

-- 12. repeatValue
function functional.repeatValue(value, n)
    local result = {}
    for i = 1, n do
        result[i] = value
    end
    return result
end

-- 13. takeWhile
function functional.takeWhile(array, predicate)
    local result = {}
    for i, v in ipairs(array) do
        if not predicate(v, i) then break end
        result[#result + 1] = v
    end
    return result
end

-- 14. dropWhile
function functional.dropWhile(array, predicate)
    local i = 1
    while i <= #array and predicate(array[i]) do
        i = i + 1
    end
    local result = {}
    for j = i, #array do
        result[#result + 1] = array[j]
    end
    return result
end

-- 15. partition
function functional.partition(array, predicate)
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

-- 16. findIndex
function functional.findIndex(array, predicate)
    for i, v in ipairs(array) do
        if predicate(v, i) then
            return i
        end
    end
    return nil
end

-- 17. reverse
function functional.reverse(array)
    local result = {}
    for i = #array, 1, -1 do
        result[#result + 1] = array[i]
    end
    return result
end

-- 18. union
function functional.union(array1, array2)
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
function functional.intersection(array1, array2)
    local set = {}
    for _, v in ipairs(array1) do
        set[v] = true
    end
    local result = {}
    for _, v in ipairs(array2) do
        if set[v] then
            result[#result + 1] = v
        end
    end
    return result
end

-- 20. difference
function functional.difference(array1, array2)
    local set = {}
    for _, v in ipairs(array2) do
        set[v] = true
    end
    local result = {}
    for _, v in ipairs(array1) do
        if not set[v] then
            result[#result + 1] = v
        end
    end
    return result
end

-- 21. composeN
function functional.composeN(...)
    local functions = {...}
    return function(x)
        for i = #functions, 1, -1 do
            x = functions[i](x)
        end
        return x
    end
end

-- 22. pipe (aka flow)
function functional.pipe(...)
    local functions = {...}
    return function(x)
        for i = 1, #functions do
            x = functions[i](x)
        end
        return x
    end
end

-- 23. head
function functional.head(array)
    return array[1]
end

-- 24. tail
function functional.tail(array)
    local result = {}
    for i = 2, #array do
        result[#result + 1] = array[i]
    end
    return result
end

-- 25. init
function functional.init(array)
    local result = {}
    for i = 1, #array - 1 do
        result[#result + 1] = array[i]
    end
    return result
end

-- 26. last
function functional.last(array)
    return array[#array]
end

-- 27. flattenDeep
function functional.flattenDeep(array)
    local result = {}
    for _, v in ipairs(array) do
        if type(v) == "table" then
            for _, inner in ipairs(functional.flattenDeep(v)) do
                result[#result + 1] = inner
            end
        else
            result[#result + 1] = v
        end
    end
    return result
end

-- 28. scan
function functional.scan(array, func, initial)
    local result = {initial}
    local acc = initial
    for i, v in ipairs(array) do
        acc = func(acc, v, i)
        result[#result + 1] = acc
    end
    return result
end

-- 29. groupWith
function functional.groupWith(array, predicate)
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
function functional.transpose(matrix)
    local result = {}
    for i = 1, #matrix[1] do
        result[i] = {}
        for j = 1, #matrix do
            result[i][j] = matrix[j][i]
        end
    end
    return result
end


-- Find index of max and min with optional function to extract the comparison value
function functional.find_max(tbl, value_func)
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

function functional.find_min(tbl, value_func)
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

function functional.flow_producer(f, g)
  return function(x)
    return g(f(x))
  end
end

function functional.comp_producer(f, g)
  return function(x)
    return f(g(x))
  end
end


return functional
