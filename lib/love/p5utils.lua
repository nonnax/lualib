local utils = {}

function utils.constrain(n, low, high)
  return math.max(math.min(n, high), low)
end

function utils.map(n, start1, stop1, start2, stop2, withinBounds)
  local newval = ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
  if not withinBounds then
    return newval
  end
  if start2 < stop2 then
    return utils.constrain(newval, start2, stop2)
  else
    return utils.constrain(newval, stop2, start2)
  end
end

return utils
