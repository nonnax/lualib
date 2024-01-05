#!/usr/bin/env luvit

local fun={}

function fun.push(fn)
	love.graphics.push()
	fn(call)
	love.graphics.pop()
end

return fun
