#!/usr/bin/env luajit
-- id$ nonnax wed jul 31 16:14:33 2024
-- https://github.com/nonnax

-- function to calculate sma
-- Function to calculate Simple Moving Average (SMA)
function calculate_sma(data, period)
    local sma = {}

    if #data < period then
        error("Not enough data to calculate SMA. Required: " .. period .. ", available: " .. #data)
    end

    for i = period, #data do
        local sum = 0
        for j = i - period + 1, i do
            if data[j] then
                sum = sum + data[j]
            -- else
            --     error("Data at index " .. j .. " is nil.")
            end
        end
        sma[i] = sum / period
    end
    local first_sma = sma[period]
    -- fill the blanks from start
    for i = 1, period-1 do
        sma[i]=first_sma
    end

    return sma
end

-- function to calculate ema
function calculate_ema(data, period)
    local ema = {}
    local multiplier = 2 / (period + 1)
    local sma = 0

    -- calculate the simple moving average for the first period
    for i = 1, period do
        sma = sma + data[i]
    end
    sma = sma / period
    ema[period] = sma

    -- fill the blanks from start
    for i = 1, period-1 do
        ema[i]=sma
    end

    -- calculate ema for the rest of the data
    for i = period + 1, #data do
        ema[i] = ((data[i] - ema[i - 1]) * multiplier) + ema[i - 1]
    end

    return ema
end

-- function to calculate rsi
function calculate_rsi(data, period)
    local rsi = {}
    local gains = 0
    local losses = 0

    -- calculate initial average gains and losses
    for i = 2, period + 1 do
        local change = data[i] - data[i - 1]
        if change > 0 then
            gains = gains + change
        else
            losses = losses - change
        end
    end

    local average_gain = gains / period
    local average_loss = losses / period

    -- calculate rsi
    for i = period + 2, #data do
        local change = data[i] - data[i - 1]
        if change > 0 then
            gains = change
            losses = 0
        else
            gains = 0
            losses = -change
        end

        average_gain = ((average_gain * (period - 1)) + gains) / period
        average_loss = ((average_loss * (period - 1)) + losses) / period

        local rs = average_gain / average_loss
        rsi[i] = 100 - (100 / (1 + rs))
    end

    return rsi
end

-- function to calculate atr
-- function calculate_atr(high, low, close, period)
--     local atr = {}
--     local tr = {}
--
--     -- calculate true range (tr)
--     for i = 2, #high do
--         local high_low = high[i] - low[i]
--         local high_close = math.abs(high[i] - close[i - 1])
--         local low_close = math.abs(low[i] - close[i - 1])
--         tr[i] = math.max(high_low, high_close, low_close)
--     end
--
--     -- calculate atr
--     local initial_atr = 0
--     for i = 2, period + 1 do
--         initial_atr = initial_atr + tr[i]
--     end
--     initial_atr = initial_atr / period
--     atr[period + 1] = initial_atr
--
--     for i = period + 2, #tr do
--         atr[i] = ((atr[i - 1] * (period - 1)) + tr[i]) / period
--     end
--
--     return atr
-- end
-- function to calculate atr
function calculate_atr(high, low, close, period)
    local atr = {}
    local tr = {}
    local tr_sum = 0

    if #high < period + 1 or #low < period + 1 or #close < period + 1 then
        error("insufficient data to calculate atr")
    end

    -- calculate true range (tr)
    for i = 2, #high do
        if high[i] == nil or low[i] == nil or close[i] == nil then
            error("data contains nil values")
        end

        local high_low = high[i] - low[i]
        local high_close = math.abs(high[i] - close[i - 1])
        local low_close = math.abs(low[i] - close[i - 1])
        tr[i] = math.max(high_low, high_close, low_close)
    end

    -- calculate atr with explicit precision handling
    for i = 2, period + 1 do
        tr_sum = tr_sum + tr[i]
    end
    atr[period + 1] = tr_sum / period

    for i = period + 2, #tr do
        atr[i] = ((atr[i - 1] * (period - 1)) + tr[i]) / period
    end

    return atr
end

-- function to generate buy/sell signals
-- function to generate buy/sell signals
function generate_signals(close, short_ema, long_ema, rsi, atr)
    local signals = {}
    local position = nil -- track if we are in a buy or sell position

    for i = math.max(#short_ema, #long_ema, #rsi, #atr), #close do
        local stop_loss_multiplier = 5.0 -- increased multiplier to adjust for small atr values
        local stop_loss = atr[i] * stop_loss_multiplier

        -- debug output for checking calculations
        -- print(string.format("minute %d: close=%.4f, short_ema=%.4f, long_ema=%.4f, rsi=%.2f, atr=%.4f, stop_loss=%.4f",
            -- i, close[i], short_ema[i], long_ema[i], rsi[i], atr[i], stop_loss))

        -- check for buy signal
        if short_ema[i] > long_ema[i] and rsi[i] > 50 then
            if position ~= "buy" then
                -- correct stop-loss for buy: subtract atr from buy price
                table.insert(signals, {type = "buy", price = close[i], stop_loss = close[i] - stop_loss})
                position = "buy"
            end
        end

        -- check for sell signal
        if short_ema[i] < long_ema[i] and rsi[i] < 50 then
            if position ~= "sell" then
                -- correct stop-loss for sell: add atr to sell price
                table.insert(signals, {type = "sell", price = close[i], stop_loss = close[i] + stop_loss})
                position = "sell"
            end
        end
    end

    return signals
end

-- function to generate buy and sell signals based on atr and moving averages
function generate_trade_signals(close, short_ema, long_ema, rsi, high, low, atr, atr_multiplier)
    local signals = {}
    local position = nil -- track if we are in a buy or sell position
    local recent_high = close[1] -- track recent high for atr-based selling

    for i = math.max(#short_ema, #long_ema, #rsi, #atr), #close do
        -- update recent high
        if close[i] > recent_high then
            recent_high = close[i]
        end

        -- calculate stop-loss and sell trigger prices
        local stop_loss = atr[i] * atr_multiplier
        local sell_trigger = recent_high - stop_loss

        -- buy signal
        if short_ema[i] > long_ema[i] and rsi[i] > 50 then
            if position ~= "buy" then
                -- record buy signal
                table.insert(signals, {type = "buy", price = close[i], stop_loss = close[i] - stop_loss})
                position = "buy"
            end
        end

        -- sell signal
        if short_ema[i] < long_ema[i] and rsi[i] < 50 then
            if position ~= "sell" then
                -- record sell signal
                table.insert(signals, {type = "sell", price = close[i], sell_trigger = sell_trigger})
                position = "sell"
            end
        end

        -- if currently holding a buy position, check if it should be sold
        if position == "buy" and close[i] < sell_trigger then
            -- record sell signal based on atr-based trigger
            table.insert(signals, {type = "sell", price = close[i], sell_trigger = sell_trigger})
            position = "sell"
        end
    end

    return signals
end
