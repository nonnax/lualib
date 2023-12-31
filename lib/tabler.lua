#!/usr/bin/env luvit
--- function tabler(tableT).
-- returns a tableT copy which can access table methods via dot `.` operator
-- all standard table functions are accessible this way.
-- ex:.
-- `table.insert(tableT, elem)` simply becomes `tableT.insert(elem)`.
--
-- note:.
-- 	table.iter(t) is useful as it does not discriminate between lists (indexed array) and maps (dict/hash).
--  ex.
-- 	for ki, v in tableT.iter() do.
-- 		 print(ki, v).
-- 	end.
--
-- tabler-table methods are `chainable`, except where the return value is atomic, like, pop() or shift(), etc.
--
-- ex. tabler(list).insert(555).map(function(k, v) return v*100 end).insert(30).
--
-- @param tableT optional initial table .
-- @return on success: a tabler-table or atomic/multi value (returns of pop() or shift(), etc).
-- @return on fail: returns the original table, and a false flag.
-- @author nonnax@https://github.com/nonnax
function serialize(tbl, indent)
    indent = indent or 1
    local indentStr = string.rep("  ", indent)
    local result = "{\n"

    for key, value in pairs(tbl) do
        -- local keyStr = type(key) == "number" and "[" .. key .. "]" or '["' .. key .. '"]'
        local keyStr = tostring(key)
        local valueType = type(value)

        if valueType == "table" then
            result = result .. indentStr .. keyStr .. " = " .. serialize(value, indent + 1) .. ",\n"
        elseif valueType == "string" then
            result = result .. indentStr .. keyStr .. ' = "' .. value .. '",\n'
        else
            result = result .. indentStr .. keyStr .. " = " .. tostring(value) .. ",\n"
        end
    end

    result = result .. string.rep("  ", indent - 1) .. "}"
    return result
end

local function tabler(t)
	  local self = getmetatable(t) or {}
	  self.__tostring=serialize

	  self.__index = function(t, k)
		 	return function(...)
		 		 if table[k] then
		 		 		local ret=table[k](t, ...)
		 		 		-- special case for multi-valued returns
		 		 		-- and no extra args
		 		 		if k=='unpack' then
		 		 			 return table.unpack( table.pack(table[k](t)) )
		 		 		elseif k=='any' or k=='all' then
		 		 		-- returns boolean
		 		 			 return ret
 		 	 		else
 		 	 			 return ret or t
 		 	 		end
		 		 else
		 		 	 -- just return orig table, and a false flag
		 		 	 -- return t, false
		 		 	 p(k, ..., 'not found')
		 		 	 return nil
		 		 end
		 	end
	 end
	 return setmetatable(t, self)
end


---
function table.filter(t, fn)
	 local tmp={}
	 table.foreachi(t, function(i, v)
	 	  if fn(v, i) then table.insert(tmp, v) end
	 end)
	 return tabler(tmp)
end

---
function table.mapi(t, fn)
	 local tmp={}
	 table.foreachi(t, function(i, v)
	 	  table.insert(tmp, fn(v, i))
	 end)
	 return tabler(tmp)
end

---
function table.map(t, fn)
	 local tmp={}
	 table.foreach(t, function(k, v)
	 	  table.insert(tmp, fn(v, k))
	 end)
	 return tabler(tmp)
end

---
function table.reduce(t, fn, init)
	 local acc=init or {}

	 for k, v in pairs(t) do
	 		acc=fn(acc, v, k)
	 end

	 if type(acc)=='table' then
	 		return tabler(acc)
	 else
	 		return acc
	 end
end

--- utils
function table.keys(t)
	local _keys = {}
	local n = 0
	for k, v in pairs(t) do
	  n = n + 1
	  _keys[n]=k
	end
	return tabler(_keys)
end

---
function table.values(t)
	local _values = {}
	local n = 0
	for k, v in pairs(t) do
	  n = n + 1
	  _values[n]=v
	end
	return tabler(_values)
end

---
function table.pop(t)
	 return tabler(t).remove(#t)
end

---
function table.shift(t)
	 return tabler(t).remove(1)
end

--- returns a table {head, tail}
-- head, tail = t.head().unpack() to get separate values
function table.head(t)
	 return tabler{t[1], t.slice(2)}
end

function table.prepend(t, v)
	 tabler(t).insert(1, v)
	 return tabler(t)
end

--- slices a list into n-sized lists
function table.slices(t, n)
	 local tmp = tabler{}
	 local sub = tabler{}
	 t.foreachi(function(i, e)
	 		sub.insert(e)
	 		if (i%n)==0 then
	 			tmp[#tmp+1]=sub
	 			sub=tabler{}
	 		end
	 end)
	 if #sub>0 then
	 	tmp.insert(sub) --trailing slice
	 end
	 return tabler(tmp)
end

---
function table.to_h(tpair)
		local k, v = tpair[1], tpair[2]
		return tabler({[tostring(k)]=v})
end

---
-- optional function 'fn'
-- if `t` length is odd, any excess is truncated
function table.each_pair(t, fn)
	 local tmp = tabler{}
	 local sub = tabler{}

	 t.foreachi(function(i, e)
	 		sub.insert(e)
	 		if (i%2)==0 then
	 		 local k, v = table.unpack(sub)
	 			tmp[#tmp+1]=(fn and fn(k, v)) or tabler(sub).to_h()
	 			sub=tabler{}
	 		end
	 end)

	 return tabler(tmp)
end
---
function table.merge_pairs(t)
	local t=tabler(t)
	local union={}
	t.foreach(function(i, e)
		tabler(e).foreach(function(k, v)
				union[k]=v
		end)
	end)
	return tabler(union)
end

-- helper function for table.flatten and table.zip
local	function flatten(item, result )
	local result = result or {}  --  create if empty
	if type( item ) == 'table' then
	 for k, v in pairs( item ) do
	     flatten( v, result )
	 end
	else
		 result[#result+1] = item
	end
	return result
end

---
function table.flatten(t)
  return tabler(flatten(t))
end

---
function table.zip(t, b)
	 local a=tabler(t)
		local res=a.mapi(function(i,v) return {v, b[i]} end )
		 .mapi(function(i,v) return flatten(v) end )
		return tabler(res)
end

---
function table.slice(t, start, stop, step)
  local sliced = {}
  for i = start or 1, stop or #t, step or 1 do
    sliced[#sliced+1] = t[i]
  end
  return tabler(sliced)
end

---
-- duplicate of function table.mergei(t, tb)
-- function table.extendi(t, t2)
-- 	local union=tabler(t)
-- 	for i, v in ipairs(t2) do
-- 		 union.insert(v)
-- 	end
-- 	return tabler(union)
-- end

---
function table.self(t, fn)
	return tabler(fn(t))
end

---
-- generic merge. works with lists/maps *unordered*
function table.merge(t, tb)
	 local tb_keys = tabler(tb).keys()
	 local buffer=t
	 for _, k in pairs(tb_keys) do
	 		buffer[k]=tb_keys[k]
	 end
	 return tabler(buffer)
end

---
function table.mergei(t, tb)
	 local buffer=t
	 for i, v in ipairs(tb) do
	 		table.insert(buffer, v)
	 end
	 return tabler(buffer)
end

---
-- generic iterator. works with lists/maps *unordered*
function table.iter(t)
	 local keys = tabler(t).keys()
  return coroutine.wrap(function()
	  for _, v in ipairs(keys) do
	    coroutine.yield(v, t[v])
	  end
  end)
end

---
-- query a list of maps by matching a query table treated as partial matching of string values per key. `all` query values must match.
-- @return a subset of matched table values.
function table.where(t, q)
		local q, t = tabler(q), tabler(t)
	 local qkeys = tabler(q).keys()

		return t.filter(function(_k, v)
			 local found = {}
			 qkeys.foreachi(function(_i, qk)
			 		if tostring(v[qk]):match(tostring(q[qk])) then found[#found+1] = qk end
			 end)
			 if #found == #qkeys then return true end
		end)

end

-- scale table values to a numerical unit
-- math function
-- @return a new table
function table.scale(t, unit)
	 local min=math.min(table.unpack(t))
	 local max=math.max(table.unpack(t))

	 return tabler(t).map(function(i, v)
	 	return ((v-min)/(max-min))*unit
	 end)

end

-- filter and map values
-- @return new values if true
function table.filtermap(t, fn)
	 local res={}
	 local insert=table.insert -- faster?

	 for i, v in ipairs(t) do
	 	 		local e=fn(v, i)
	 	 		if e and e ~= false and type(e) ~= 'nil' then
	 	 			 insert(res, e)
	 	 		end
	 end
	 return res
end

-- pass all tests via predicate
-- @return boolean
function table.all(t, fn)
	 local hits=0
	 for i, v in ipairs(t) do
	 	 		if fn(v,i) == true then hits=hits+1	end
	 end
	 return hits==#t
end

-- pass at least one test via predicate
-- @return boolean
function table.any(t, fn)
	 local hits=0
	 for i, v in ipairs(t) do
	 	 		if fn(v, i) == true then hits=hits+1	end
	 end
	 return hits>0
end

-- recursive clone
-- @return a new table copy
function table.clone(t)
	 local copy=tabler{}
		for k, v in pairs(t) do
		  if type(v)=='table' then
		  	  copy[k]=table.clone(v)
		  else
			 		 copy[k]=v
			 end
		end
		return copy
end


-- util
-- @return table on `n-size` with `init` values
function table.times(t, n, init)
	 local res={}
		for i=1, n do
			 res[#res+1]=init or i
		end
		t=res
		return res
end

function table.range(t, start, stop, step)
		 local insert=table.insert
		 local res={}
		 if stop == nil then
		 		stop  = start
		 		start = start and nil
		 end
			for i = start or 1, stop or 10, step or 1 do
					res[#res+1]=i
			end
			t=res
			return res
end


return tabler
