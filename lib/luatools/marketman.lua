#!/usr/bin/env luajit

-- Id$ nonnax Thu Jul 11 18:06:04 2024
-- https://github.com/nonnax
-- Function to normalize values
function normalize_value(value, t)
  local min_value, max_value, scale_min, scale_max = unpack(t)
  return ((value - min_value) / (max_value - min_value)) *
           (scale_max - scale_min) + scale_min
end

-- -- Function to get the last n items from a table
-- function table.lastn(tbl, n)
--     local result = {}
--     for i = math.max(#tbl - n + 1, 1), #tbl do
--         table.insert(result, tbl[i])
--     end
--     return result
-- end

function timestamp_to_s(time)
  return os.date("%x %X", tonumber(time or 1) / 1000)
end

-- function table.remap_ohlc(t)
--   local data={}
--   for i, v in ipairs(t) do
--     local xtime=v[1]
--     v[1]=timestamp_to_s(xtime)
--
--     for j=2, #v do
--       v[j]=tonumber(v[j])
--     end
--     local ohlc = {datetime = v[1], open=v[2], high=v[3], low=v[4], close=v[5], volume=v[6]}
--     ohlc.__order  = {'datetime', 'open', 'high', 'low', 'close', 'volume'}
--     table.insert(data, ohlc)
--   end
--   return data
-- end

local function reduce_by(t, fx, init, col)
  local prod = function(acc, row) return fx(acc, row[col]) end
  return FP.reduce(t, prod, init)
end

function table.minmaxvol(ohlc_data)
  local min_low = reduce_by(ohlc_data, math.min, math.huge, 'low')
  local max_high = reduce_by(ohlc_data, math.max, -math.huge, 'high')
  local volume = FP.map(ohlc_data, function(r) return r.volume end)
  local max_volume = math.max(unpack(volume))
  local min_volume = math.min(unpack(volume))

  return min_low, max_high, max_volume, min_volume
end

-- Function to normalize OHLC data
function table.normalize_ohlc(ohlc_data, scale_min, scale_max)

  scale_min = scale_min or 1
  scale_max = scale_max or 20

  local min_low = reduce_by(ohlc_data, math.min, math.huge, 'low')
  local max_high = reduce_by(ohlc_data, math.max, -math.huge, 'high')
  local max_volume = reduce_by(ohlc_data, math.max, -math.huge, 'volume')

  local basis = {min_low, max_high, scale_min, scale_max}

  local normalized_data = {}

  for _, ohlc in ipairs(ohlc_data) do
    local normalized_ohlc = {
      open = normalize_value(ohlc.open, basis),
      high = normalize_value(ohlc.high, basis),
      low = normalize_value(ohlc.low, basis),
      close = normalize_value(ohlc.close, basis),
      volume = ohlc.volume, -- Keep volume as is for now, will be scaled during drawing
      datetime = ohlc.datetime -- Keep the datetime for display
    }
    table.insert(normalized_data, normalized_ohlc)
  end

  return normalized_data, min_low, max_high, max_volume
end

function table.min_max(...)
  function traverse(acc, ...)
    for i, v in ipairs({...}) do
      if type(v)=='table' then
        if #v > 0 then
          traverse(acc, unpack(v))
        end
      else
        table.insert(acc, v)
      end
    end
    local tmin, tmax = math.min(unpack(acc)), math.max(unpack(acc))
    return tmin, tmax
  end
  local min, max = traverse({}, ...)
  return min, max
end


function table.extent(...)
  local acc={}
  for i, v in ipairs({...}) do
    if type(v)=='table' then
      if #v > 0 then
        table.insert(acc, math.min(unpack(v)))
        table.insert(acc, math.max(unpack(v)))
      end
    else
      table.insert(acc, v)
    end
  end
  local tmin, tmax = math.min(unpack(acc)), math.max(unpack(acc))
  return tmin, tmax
end