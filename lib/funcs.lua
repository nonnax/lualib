#!/usr/bin/env luvit

local module ={}

local function mapper(e)
	 local self={ value=e }
	 function self.map(fn, ...)
	 	 return mapper(fn(e, ...))
	 end
	 function self.tap(fn)
	 	 fn(e)
	 		return mapper(e)
	 end
	 return self
end

local function reduce(fn, i, tab)
	local e = i
	for k, v in pairs(tab)	do
		e = fn(e, v, k)
	end
	return e
end

local function filter(fn, tab)
	local e = {}
	for k, v in pairs(tab)	do
		local ret = fn(v, k)
		if ret then e[#e+1] = v end
	end
	return e
end

local function filtermap(fn, tab)
	local e = {}
	for k, v in pairs(tab)	do
		local ret = fn(v, k)
		if ret then e[#e+1] = ret end
	end
	return e
end

local function group(fn, tab)
	local e = {}
	for k, v in pairs(tab)	do
	 local x = fn(v, k)
		e[x] = e[x] or {}
		table.insert(e[x], v)
	end
	return e
end

local function map(fn, tab)
	local e = {}
	for k, v in pairs(tab)	do
		e[#e+1] = fn(v, k)
	end
	return e
end

local function zip(a, b)
	local e = {}
	for k, v in pairs(a)	do
		e[#e+1] = v
		e[#e+1] = b[k]
	end
	return e
end

local function zap(a, b)
	local e = {}
	for k, v in pairs(a)	do
		e[v] = b[k]
	end
	return e
end

local function comp(f, g)
	return function (...) return f(g(...)) end
end

local function flow(f, g)
	return function (...) return g(f(...)) end
end

local function pipe(...)
	local f = function (...) return ... end
	for i, g in pairs({...}) do
			f = flow(f, g)
	end
	return f
end

local function any(fn, t)
	 local res={}
		res=filter(fn, t)
		return #res > 0
end

local function all(fn, t)
	 local res={}
		res=filter(fn, t)
		return #res ==  #t
end

-- identity func, just return x
function it(x)
  return x
end


module.mapper	=	mapper
module.pipe			=	pipe
module.map			=	map
module.reduce	=	reduce
module.group	=	group
module.filter	=	filter
module.filtermap	=	filtermap
module.any		=	any
module.all		=	all
module.comp			=	comp
module.flow			=	flow
module.zip			=	zip
module.zap			=	zap
module.it			=	it

-- math funcs
module.add = function(i, v)	return i+v end
module.sub = function(i, v)	return i-v end
module.mul = function(i, v)	return i*v end
module.div = function(i, v)	return i/v end
module.mod = function(i, v)	return i%v end
module.deg = math.deg
module.rad = math.rad
module.sin = math.sin
module.cos = math.cos
module.tan = math.tan
module.atan = math.atan

-- string funcs
local function split_on(pat)
   return function(str)
    local res = {}
   	for l in str:gmatch(pat) do
   		res[#res+1]=l
   	end
   	return res
   end
end

module.split_on	=	split_on

-- table.insert does not return the table
local function push(t, e)
	table.insert(t, e)
	return t
end

local function pop(t)
	table.remove(t, #t)
	return t
end

local function shift(t)
	table.remove(t, 1)
	return t
end

local function pop1(t)
	return table.remove(t, #t)
end

local function shift1(t)
	return table.remove(t, 1)
end

local function keys(t)
	 local keys={}
	 for k, v in pairs(t) do keys[#keys+1]=k end
	 return keys
end


module.push	=	push
module.pop		=	pop
module.shift	=	shift
module.shift1	=	shift1
module.pop1		=	pop1
module.keys		=	keys

return module
