#!/usr/bin/env luvit

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function each_line(str, fn)
   for line in str:gmatch("[^\r\n]+") do
      fn(line)
   end
end

local function split(str, _ch)
   local res = {}
   local ch = _ch or "%S+"
   for id in str:gmatch(ch) do
      res[#res+1]=id
   end
   return res
end

function is_rep(str, pat)
	return str:gsub(pat, "") == ""
end


local function __mod(str, t)
   if not t then
      return str
   elseif type(t) == "table" then
      return str:format(unpack(t))
   else
      return str:format(t)
   end
end

string.starts_with=starts_with
string.ends_with=ends_with
string.each_line=each_line
string.split=split
getmetatable("").__mod=__mod

