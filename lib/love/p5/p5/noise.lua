#!/usr/bin/env luvit
-- noise.lua

-- Constants
NOISE_SCALE = 0.1

-- Perlin noise implementation
function noise(x, y, z)
    y = y or 0
    z = z or 0

    local X = math.floor(x) & 255
    local Y = math.floor(y) & 255
    local Z = math.floor(z) & 255

    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    local u = fade(x)
    local v = fade(y)
    local w = fade(z)

    local A = p[X] + Y
    local AA = p[A] + Z
    local AB = p[A + 1] + Z
    local B = p[X + 1] + Y
    local BA = p[B] + Z
    local BB = p[B + 1] + Z

    return lerp(w,
        lerp(v,
            lerp(u, grad(p[AA], x, y, z), grad(p[BA], x - 1, y, z)),
            lerp(u, grad(p[AB], x, y - 1, z), grad(p[BB], x - 1, y - 1, z))
        ),
        lerp(v,
            lerp(u, grad(p[AA + 1], x, y, z - 1), grad(p[BA + 1], x - 1, y, z - 1)),
            lerp(u, grad(p[AB + 1], x, y - 1, z - 1), grad(p[BB + 1], x - 1, y - 1, z - 1))
        )
    )
end

-- Initialization
local p = {}
for i = 0, 511 do
    p[i] = math.random(0, 255)
end

-- Utility functions
function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function lerp(t, a, b)
    return a + t * (b - a)
end

function grad(hash, x, y, z)
    local h = hash & 15
    local grad = 1 + (h & 7) -- Gradient value 1-8

    if (h & 8) ~= 0 then grad = -grad end -- Randomly invert half of them

    if h < 4 then
        return grad * x
    elseif h < 12 then
        return grad * y
    else
        return grad * z
    end
end
