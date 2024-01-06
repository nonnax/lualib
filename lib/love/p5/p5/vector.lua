#!/usr/bin/env luvit
-- p5.Vector.lua

-- Constructor
function createVector(x, y, z)
    local vector = {x = x or 0, y = y or 0, z = z or 0}

    -- Methods
    function vector:mag()
        return math.sqrt(self.x^2 + self.y^2 + self.z^2)
    end

    function vector:magSq()
        return self.x^2 + self.y^2 + self.z^2
    end

    function vector:add(v)
        self.x = self.x + v.x
        self.y = self.y + v.y
        self.z = self.z + v.z
        return self
    end

    function vector:sub(v)
        self.x = self.x - v.x
        self.y = self.y - v.y
        self.z = self.z - v.z
        return self
    end

    function vector:mult(n)
        self.x = self.x * n
        self.y = self.y * n
        self.z = self.z * n
        return self
    end

    function vector:div(n)
        self.x = self.x / n
        self.y = self.y / n
        self.z = self.z / n
        return self
    end

    function vector:normalize()
        local mag = self:mag()
        if mag ~= 0 then
            self:div(mag)
        end
        return self
    end

    function vector:limit(max)
        local mSq = self:magSq()
        if mSq > max^2 then
            self:div(math.sqrt(mSq))
            self:mult(max)
        end
        return self
    end

    function vector:heading2D()
        return math.atan2(self.y, self.x)
    end

    function vector:rotate(a)
        local newHeading = self:heading2D() + a
        local mag = self:mag()
        self.x = math.cos(newHeading) * mag
        self.y = math.sin(newHeading) * mag
        return self
    end

    function vector:lerp(v, amt)
        local x = self.x + (v.x - self.x) * amt
        local y = self.y + (v.y - self.y) * amt
        local z = self.z + (v.z - self.z) * amt
        return createVector(x, y, z)
    end

    function vector:array()
        return {self.x, self.y, self.z}
    end

    function vector.__tostring(t)
        return string.format("(x=%.3f,y=%.3f,z=%.3f)", t.x, t.y, t.z)
    end
    vector.__index = vector
    return setmetatable(vector, vector)
end
