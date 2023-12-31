#!/usr/bin/env luvit
require 'stringer'
fn=require 'funcs'
-- Simple cooperative thread scheduler

local threads = {}

function threads:spawn(func)
  local thread = coroutine.create(func)
  fn.push(self, thread)
end

-- iterate over spawns with optional callback
function threads:scheduler(_cb)
  local cb = _cb or fn.it -- identity func just forwards arg
  while #self > 0 do
    local currentThread = fn.shift1(self)
    local status, res = coroutine.resume(cb(currentThread))
    if coroutine.status(currentThread) ~= "dead" then
      fn.push(self, currentThread)
    end
  end
end

function threads:alive()
  return #self==0
end

function threads:empty()
  return #self==0
end

function threads:yield()
  return coroutine.yield()
end

threads.__index=threads

return setmetatable({}, threads)
