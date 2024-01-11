#!/usr/bin/env luvit
-- calculation.lua

-- Constants
HALF_PI = math.pi / 2
TWO_PI = 2 * math.pi

local p5={}
-- Functions
function p5.dist(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx^2 + dy^2)
end

function p5.distSq(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx^2 + dy^2
end

function p5.radians(degrees)
    return degrees * (math.pi / 180)
end

function p5.degrees(radians)
    return radians * (180 / math.pi)
end

function p5.sq(n)
    return n^2
end

function p5.constrain(n, low, high)
    return math.max(low, math.min(n, high))
end

function p5.map(value, start1, stop1, start2, stop2)
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
end

function p5.norm(value, start, stop)
    return (value - start) / (stop - start)
end

function p5.lerp(start, stop, amt)
    return start + (stop - start) * amt
end

function p5.mag(x, y)
    return math.sqrt(x^2 + y^2)
end

function p5.magSq(x, y)
    return x^2 + y^2
end

function p5.random(...)
    local args = {...}
    local numArgs = #args

    if numArgs == 0 then
        return math.random()
    elseif numArgs == 1 then
        return math.random(args[1])
    elseif numArgs == 2 then
        return math.random(args[1], args[2])
    else
        error("Invalid number of arguments for random function.")
    end
end

function p5.randomSeed(seed)
    math.randomseed(seed)
end

function p5.noise(...)
    -- Implement noise function p5.if needed
    -- Placeholder for now
    return math.random()
end

return p5
