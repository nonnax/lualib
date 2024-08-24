#!/usr/bin/env luajit
-- id$ nonnax sat aug 17 11:23:22 2024
-- https://github.com/nonnax
local support_resistance = {}
local functional = require("luatools/functional")

-- swing highs and lows detection
function support_resistance.detect_swing_highs_and_lows(data, window)
    local window = window or 5

    local function is_swing_high(i)
        local _, max_index = functional.find_max(data, function(dp) return dp.close end)
        return max_index == i
    end

    local function is_swing_low(i)
        local _, min_index = functional.find_min(data, function(dp) return dp.close end)
        return min_index == i
    end

    local support = functional.filter(data, function(_, i)
        return i > window and i <= #data - window and is_swing_low(i)
    end)

    local resistance = functional.filter(data, function(_, i)
        return i > window and i <= #data - window and is_swing_high(i)
    end)

    return support, resistance
end

-- pivot points calculation
function support_resistance.calculate_pivot_points(data)
    return functional.map(data, function(ohlc)
        local pivot = (ohlc.high + ohlc.low + ohlc.close) / 3
        local r1 = (2 * pivot) - ohlc.low
        local s1 = (2 * pivot) - ohlc.high
        local r2 = pivot + (ohlc.high - ohlc.low)
        local s2 = pivot - (ohlc.high - ohlc.low)
        return {
            datetime = ohlc.datetime,
            pivot = pivot,
            resistance = {r1 = r1, r2 = r2},
            support = {s1 = s1, s2 = s2}
        }
    end)
end

-- bollinger bands calculation
function support_resistance.calculate_bollinger_bands(data, period, stddev_mult)
    local period = period or 20
    local stddev_mult = stddev_mult or 2

    return functional.map(data, function(dp, i)
        if i < period then return nil end
        local sub_data = {unpack(data, i - period + 1, i)}
        local sma = functional.reduce(sub_data, function(sum, dp) return sum + dp.close end, 0) / period
        local variance_sum = functional.reduce(sub_data, function(sum, dp) return sum + (dp.close - sma) ^ 2 end, 0)
        local stddev = math.sqrt(variance_sum / period)

        return {
            timestamp = dp.datetime,
            sma = sma,
            upper_band = sma + stddev_mult * stddev,
            lower_band = sma - stddev_mult * stddev
        }
    end)
end

-- volume profile calculation
function support_resistance.calculate_volume_profile(data)
    local volume_profile = {}

    functional.map(data, function(dp)
        if not volume_profile[dp.close] then
            volume_profile[dp.close] = {volume = 0, datetimes = {}}
        end
        volume_profile[dp.close].volume = volume_profile[dp.close].volume + dp.volume
        table.insert(volume_profile[dp.close].datetimes, dp.datetime)
    end)

    return volume_profile
end

return support_resistance
