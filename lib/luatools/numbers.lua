#!/usr/bin/env luajit
-- Id$ nonnax Sat Jul 20 15:53:11 2024
-- https://github.com/nonnax
local _M = {}

-- Define a closure object with custom metatable
-- Define a closure object with custom metatable
function _M.Fraction(value)
    local obj = { value = value }

    setmetatable(obj, {
        __add = function(lhs, rhs)
            return lhs.value + rhs / 100
        end,
        __sub = function(lhs, rhs)
            return lhs.value - rhs / 100
        end,
        __mul = function(lhs, rhs)
            return lhs.value * (1 + rhs / 100)
        end,
        __div = function(lhs, rhs)
            return lhs.value / (1 + rhs / 100)
        end,
        __tostring = function(obj)
            return tostring(obj.value)
        end,
    })

    return obj
end

function _M.Moneymath(price, units, amount)
  local valid_params = 0
  for i, v in ipairs({price, units, amount}) do
      if v > 0 then
        valid_params = valid_params + 1
      end
  end

  assert( valid_params > 1, 'function needs 2-3 non-zero arguments')

  local self={
    price = (price==0) and (amount/units) or price,
    units = (units==0) and (amount/price) or units,
    amount = (amount==0) and (units*price) or amount
  }
  local m={}
  m.__add = function(l, r)
     local price, amount, units = l.price + r.price, l.amount + r.amount, l.units + r.units
     return _M.Moneymath(price, units, amount)
  end
  m.__sub = function(l, r)
     local price, amount, units = l.price - r.price, l.amount - r.amount, l.units - r.units

     return _M.Moneymath(price, units, amount)
  end
  m.__mul = function(l, r)
     local price, amount = l.price * (1+r/100), l.amount * (1+r/100)
     return _M.Moneymath(price, units, amount)
  end
  m.__div = function(l, r)
     local price, amount = l.price / (1+r/100), l.amount / (1+r/100)
     return _M.Moneymath(price, units, amount)
  end
  m.__tostring = function()
    local fmt = "%.2f"
    if self.price < 1 then
      fmt =  "%.7f"
    end
    return string.format("Price: "..fmt.." Units: "..fmt.." Amount: %.2f", self.price, self.units, self.amount)
  end

  setmetatable(self, m)
  return self
end

-- Example usage
-- local value = FractionValue(5)
-- print("Original value:", value)  -- Output: 5
--
-- local resultAdd = value + 10  -- 5 + 0.1
-- print("After addition:", resultAdd)  -- Output: 5.1
--
-- local resultSub = value - 10  -- 5 - 0.1
-- print("After subtraction:", resultSub)  -- Output: 4.9
--
-- local resultMul = value * 10  -- 5 * 1.1
-- print("After multiplication:", resultMul)  -- Output: 5.5
--
-- local resultDiv = value / 10  -- 5 / 1.1
-- print("After division:", resultDiv)  -- Output: 4.5454545454545
return _M