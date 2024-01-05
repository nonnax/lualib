#!/usr/bin/env luvit

local canvas={}
local function atxy(x, y)
    local screenHeight = love.graphics.getHeight()
    return x, screenHeight - y
end

local function shape(fn,  mode, x, y, h, w, ...)
    local ax, ay = atxy(x, y)
    fn(mode, ax, ay, h, w, ...)
end

local function line(x1, y1, x2, y2, ...)
    local ax, ay = atxy(x1, y1)
    local bx, by = atxy(x2, y2)
    love.graphics.line(ax, ay, bx, by, ...)
end

local function _print(text, x1, y1, ...)
    local ax, ay = atxy(x1, y1)
    love.graphics.print(text, ax, ay, ...)
end

canvas.atxy=atxy
canvas.shape=shape
canvas.line=line
canvas.print=_print

return canvas
