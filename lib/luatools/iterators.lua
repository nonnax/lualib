#!/usr/bin/env luajit

-- Id$ nonnax Tue Aug 13 17:40:26 2024
-- https://github.com/nonnax
-- Iterator library using coroutine.wrap for higher-order functions
local iterators = {}

-- Iterator to determine the correct iterator function (pairs/ipairs) based on the input table
function iterators.iter(t)
  if type(t) == "table" then
    if #t > 0 then
      return ipairs(t)
    else
      return pairs(t)
    end
  else
    error("Input must be a table")
  end
end

-- Filtermap iterator: applies a predicate function to filter elements and map them to a new value
function iterators.filtermap(predicate, t)
  return coroutine.wrap(function()
    for k, v in iterators.iter(t) do
      local include, mappedValue = predicate(v)
      if include then coroutine.yield(k, mappedValue) end
    end
  end)
end

-- Map iterator: applies a transformation function to each element
function iterators.map(transform, t)
  return coroutine.wrap(function()
    for k, v in iterators.iter(t) do coroutine.yield(k, transform(v)) end
  end)
end

-- Filter iterator: filters elements based on a predicate function
function iterators.filter(predicate, t)
  return coroutine.wrap(function()
    for k, v in iterators.iter(t) do
      if predicate(v) then coroutine.yield(k, v) end
    end
  end)
end

-- Slice iterator: yields chunks of a specified size from the table
function iterators.slice(t, chunksize)
  return coroutine.wrap(function()
    local chunk = {}
    local count = 0
    local i = 0

    for _, v in iterators.iter(t) do
      table.insert(chunk, v)
      count = count + 1
      if count == chunksize then
        i = i + 1
        coroutine.yield(chunk, i)
        chunk = {}
        count = 0
      end
    end

    if #chunk > 0 then
      coroutine.yield(chunk, i+1) -- Yield the remaining elements if any
    end
  end)
end

function iterators.ireverse(t)
  return coroutine.wrap(function()
    for i=#t, 1, -1 do
      coroutine.yield(#t-i+1, t[i])
    end
  end)
end


-- Each_cons iterator: yields consecutive chunks of a specified size from the table
function iterators.each_cons(t, chunksize)
    return coroutine.wrap(function()
        for i = 1, #t - chunksize + 1 do
            local chunk = {}
            for j = i, i + chunksize - 1 do
                table.insert(chunk, t[j])
            end
            coroutine.yield(chunk)
        end
    end)
end

function iterators.each_page(num_pages, chunk_size)
   local data = {}
   local chunk_size = chunk_size - 2
   for i=1, num_pages do
    table.insert(data, i)
   end
   return coroutine.wrap(function()
      for chunk in i.each_cons(data, chunk_size) do
        if chunk[1]>1 then
           table.insert(chunk, 1, chunk[1]-1)
        else
           table.insert(chunk, 1, 1)
        end

        if chunk[#chunk] < #data then
           table.insert(chunk, chunk[1]+1)
        else
           table.insert(chunk, #data)
        end

        coroutine.yield(chunk)
      end
   end)
end



-- Example usage:
-- local t = {1, 2, 3, 4, 5, 6, 7, 8}
-- for chunk in iterators.slice(t, 3) do
--     print(table.concat(chunk, ", "))
-- end

return iterators
