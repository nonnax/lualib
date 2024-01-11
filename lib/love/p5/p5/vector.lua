#!/usr/bin/env luvit
-- p5.Vector.lua

-- Constants
HALF_PI = math.pi / 2
TWO_PI = 2 * math.pi

local function Vector(x, y, z)
    local self = {}
    self.__index = self

    function self.new(x, y, z)
        local self = setmetatable({}, self)
        self.x = x or 0
        self.y = y or 0
        self.z = z or nil
        return self
    end

    function self:mag()
        return math.sqrt(self.x^2 + self.y^2 + self.z^2)
    end
    self.getmag = self.mag

    function self:setmag(n)
        self:normalize()
        self:mult(n)
        return self.new(self.x, self.y)
    end

    function self:magSq()
        return self.x^2 + self.y^2 + self.z^2
    end

    function self:add(v)
        self.x = self.x + v.x
        self.y = self.y + v.y
        self.z = self.z + v.z
        return self
    end

    function self:sub(v)
        self.x = self.x - v.x
        self.y = self.y - v.y
        self.z = self.z - v.z
        return self
    end

    function self:mult(n)
        self.x = self.x * n
        self.y = self.y * n
        self.z = self.z * n
        return self
    end

    function self:div(n)
        self.x = self.x / n
        self.y = self.y / n
        self.z = self.z / n
        return self
    end

    function self:clone(n)
        return self.new(self.x, self.y, self.z)
    end

    function self:normalize()
        local mag = self:mag()
        if mag ~= 0 then
            self:div(mag)
        end
        return self
    end
    self.norm = self.normalize

    function self:limit(max)
        local magSq = self:magSq()
        if magSq > max^2 then
            self:div(math.sqrt(magSq))
            self:mult(max)
        end
        return self
    end

    function self:dist(v)
        local dx = self.x - v.x
        local dy = self.y - v.y
        local dz = self.z - v.z
        return math.sqrt(dx^2 + dy^2 + dz^2)
    end

    function self:angleBetween(v)
        local dotProduct = self.x * v.x + self.y * v.y + self.z * v.z
        return math.acos(dotProduct / (self:mag() * v:mag()))
    end

    -- get the heading (direction) of a vector
    function self.heading(v)
      return -math.atan2(v.y, v.x)
    end

    function self:dot(v)
        return self.x * v.x + self.y * v.y + self.z * v.z
    end

    function self:cross(v)
        local x = self.y * v.z - self.z * v.y
        local y = self.z * v.x - self.x * v.z
        local z = self.x * v.y - self.y * v.x
        return self.new(x, y, z)
    end

    function self:lerp(v, amt)
        local x = self.x + (v.x - self.x) * amt
        local y = self.y + (v.y - self.y) * amt
        local z = self.z + (v.z - self.z) * amt
        return self.new(x, y, z)
    end

    -- Random 2D self
    function self.random2D()
        local angle = math.random() * TWO_PI
        return self.new(math.cos(angle), math.sin(angle))
    end
    self.random = random2D

    -- Random 3D self
    function self.random3D()
        local angle1 = math.random() * TWO_PI
        local angle2 = math.random() * TWO_PI
        local x = math.sin(angle1) * math.cos(angle2)
        local y = math.sin(angle1) * math.sin(angle2)
        local z = math.cos(angle1)
        return self.new(x, y, z)
    end

    function self.__tostring(t)
      -- self.__tostring = function(v) return string.format("(%f,%f,%f)", v.x, v.y, v.z) end
      if t.z then
          return string.format("Vector(%.1f,%.1f,%.1f)",t.x,t.y,t.z)
      else
          return string.format("Vector(%.1f,%.1f)",t.x,t.y)
      end
    end

    function self.__unm(v)
      return self.new(-v.x, -v.y)
    end

    function self.__eq(v1,v2)
      return v1.x == v2.x and v1.y == v2.y
    end

    -- makes a new vector from an angle in radians
    function self.fromAngle(theta)
      local angle = theta or 0
      return self.new(math.cos(angle), math.sin(angle))
    end

    return self.new(x, y, z)
end

return Vector
