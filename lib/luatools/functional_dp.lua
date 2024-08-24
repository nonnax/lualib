#!/usr/bin/env luajit
-- Id$ nonnax Fri Aug 16 17:24:07 2024
-- https://github.com/nonnax
-- functional.lua

local functional = {}

-- Functor: Implement map
function functional.Functor(value)
    return {
        value = value,
        map = function(self, f)
            return functional.Functor(f(self.value))
        end
    }
end

-- Applicative Functor: Apply functions in context
function functional.Applicative(value)
    return {
        value = value,
        apply = function(self, applicativeFun)
            return functional.Applicative(applicativeFun.value(self.value))
        end,
        map = function(self, f)
            return self:apply(function(x) return functional.Functor(f(x)).value end)
        end
    }
end

-- Monad: Bind and chain computations
function functional.Monad(value)
    return {
        value = value,
        bind = function(self, f)
            return f(self.value)
        end,
        map = function(self, f)
            return self:bind(function(x) return functional.Monad(f(x)) end)
        end
    }
end

-- Lazy Evaluation: Create lazy values
function functional.Lazy(fn)
    local computed = false
    local value
    return {
        get = function()
            if not computed then
                value = fn()
                computed = true
            end
            return value
        end
    }
end

-- Currying: Transform function to take arguments one at a time
function functional.curry(f)
    local function curried(...)
        local args = { ... }
        local function next(...)
            local new_args = { table.unpack(args), ... }
            if #new_args >= select('#', f) then
                return f(table.unpack(new_args))
            else
                return curried(table.unpack(new_args))
            end
        end
        return next
    end
    return curried
end

-- Partial Application: Fix some arguments of a function
function functional.partial(f, ...)
    local partial_args = { ... }
    return function(...)
        local full_args = { table.unpack(partial_args), ... }
        return f(table.unpack(full_args))
    end
end

-- Memoization: Cache function results
function functional.memoize(f)
    local cache = {}
    return function(...)
        local args = { ... }
        local key = table.concat(args, ",")
        if not cache[key] then
            cache[key] = f(table.unpack(args))
        end
        return cache[key]
    end
end

-- Identity Monad: Wrap a value in a context
function functional.Identity(value)
    return {
        value = value,
        map = function(self, f)
            return functional.Identity(f(self.value))
        end,
        bind = function(self, f)
            return f(self.value)
        end
    }
end

-- Maybe Monad: Handle optional values
function functional.Maybe(value)
    local function isNothing(v)
        return v == nil or v == functional.Nothing
    end

    local Nothing = {}
    local Just = function(v) return { value = v } end

    local self = {
        value = value
    }

    return {
        isNothing = function() return isNothing(self.value) end,
        map = function(self, f)
            if isNothing(self.value) then
                return functional.Maybe(Nothing)
            else
                return functional.Maybe(f(self.value))
            end
        end,
        bind = function(self, f)
            if isNothing(self.value) then
                return functional.Maybe(Nothing)
            else
                return f(self.value)
            end
        end
    }
end

-- Expose Nothing as a constant
functional.Nothing = {}

return functional
