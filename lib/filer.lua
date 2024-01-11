#!/usr/bin/env luvit
-- _G.require = require
-- fs=require 'fs'
io=require 'io'

function script_path(f)
		 local f = f or ""
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")..f
end

local function file_exists(name)
		-- return fs.existsSync(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

io.exists=file_exists

local function Filer(name, data, err)
	local data = data or ""
	local self = {
		value = data,
		err   = err
	}

 local function itself(x)	return x end

	function self.read(fn)
		-- update data if exists
		local fn=fn or itself
		local err
		if file_exists(name) then
				local f=io.open(name)
				data=fn( f:read("*a") )
				f:close()
		end
		return Filer(name, data, err)
	end

	function self.write(newdata, fn)
				local fn = fn or itself
		  local newdata = newdata or data
		  local f=io.open(name, 'w')
				local res=f:write(fn(newdata))
				f:close()
	 		return Filer(name, newdata, res)
	end

 function self.map(fn)
 	return Filer(name, fn(data))
 end

 function self.self(fn)
 	fn(data)
 	return Filer(name, data)
 end

	self.__index = self
	return setmetatable({},self)
end

return Filer
