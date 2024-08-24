#!/usr/bin/env luajit
-- Id$ nonnax Fri Jul 19 09:59:27 2024
-- https://github.com/nonnax
require 'luatools'
-- BoxGrid.lua
local BoxGrid = {}

local max_height = 24    -- Maximum height for the chart (rows)
local max_width = 180    -- Maximum width for the chart (columns)
local BAR = '█'
local BAR2 = '▓'
local BAR3 = '▒'
local VBAR = '│'
green = "\27[32m"  -- ANSI escape code for green
red = "\27[31m"    -- ANSI escape code for red
reset = "\27[0m"   -- ANSI escape code to reset color
padding = 10


function draw_close(ohlcData)
    local max_height = 24    -- Maximum height for the chart (rows)
    local max_width = 180    -- Maximum width for the chart (columns)
    local BAR = '█'
    local BAR2 = '▓'
    local BAR3 = '▒'
    local VBAR = '│'
    green = "\27[32m"  -- ANSI escape code for green
    red = "\27[31m"    -- ANSI escape code for red
    reset = "\27[0m"   -- ANSI escape code to reset color

    -- Find the global high and low to scale the chart
    local maxVal, minVal = -math.huge, math.huge
    for _, candle in ipairs(ohlcData) do
        if candle.close > maxVal then maxVal = candle.close end
        if candle.close < minVal then minVal = candle.close end
    end

    -- Function to scale price to terminal height
    local function scale(price)
        return math.floor(((price - minVal) / (maxVal - minVal)) * (max_height - 1)) + 1
    end

    -- Create a buffer for the chart
    local chartBuffer = {}
    for i = 1, max_height do
        chartBuffer[i] = {}
        for j = 1, max_width do
            chartBuffer[i][j] = " "
        end
    end

    -- Plot each candlestick in the buffer
    for i, candle in ipairs(ohlcData) do
        local close = candle.close
        local open = i > 1 and ohlcData[i-1].close or close
        local color = close > open and green or red

        local scaledOpen = scale(open)
        local scaledClose = scale(close)

        local Low = math.min(scaledClose, scaledOpen)
        local High = math.max(scaledClose, scaledOpen)

        for y = Low, High do
            local col = math.floor(i * max_width / #ohlcData)
            -- if y == scaledOpen or y == scaledClose then
            if y == scaledClose then
                chartBuffer[max_height - y + 1][col] = color .. BAR .. reset
            else
                chartBuffer[max_height - y + 1][col] = color .. VBAR .. reset
            end
        end
    end

    -- Print the chart from the buffer
    for i = 1, max_height do
        local line = ""
        for j = 1, max_width do
            line = line .. chartBuffer[i][j]
        end
        print(line)
    end
end

-- BoxGrid.lua
local BoxGrid = {}

-- Create a new BoxGrid instance
function BoxGrid.new(xMinMax, yMinMax, widthHeight)
    xMin, xMax = unpack(xMinMax)
    yMin, yMax = unpack(yMinMax)
    yMid = yMin+yMax/2
    width, height = unpack(widthHeight)
    local self = {
        xMin = xMin,   -- Minimum value for x-axis
        xMax = xMax,   -- Maximum value for x-axis
        yMin = yMin,   -- Minimum value for y-axis
        yMax = yMax,   -- Maximum value for y-axis
        yMid = yMid,   -- Average value for y-axis
        width = width, -- Width of the grid
        height = height -- Height of the grid
    }

    -- Initialize grid as a table
    self.grid = {}
    for i = 1, self.width do
        self.grid[i] = {}
        for j = 1, self.height do
            self.grid[i][j] = nil
        end
    end

    -- Scale values to grid coordinates
    function self:scaleToGrid(xValue, yValue)
        local xIndex = math.floor((xValue - self.xMin) / (self.xMax - self.xMin) * (self.width - 1)) + 1
        local yIndex = math.floor((yValue - self.yMin) / (self.yMax - self.yMin) * (self.height - 1)) + 1
        return xIndex, yIndex
    end

    -- Set a value in the grid
    function self:setValue(xValue, yValue, value)
        local xIndex, yIndex = self:scaleToGrid(xValue, yValue)
        if xIndex >= 1 and xIndex <= self.width and yIndex >= 1 and yIndex <= self.height then
            self.grid[xIndex][yIndex] = value
        end
    end

    -- Get a value from the grid
    function self:getValue(xValue, yValue)
        local xIndex, yIndex = self:scaleToGrid(xValue, yValue)
        if xIndex >= 1 and xIndex <= self.width and yIndex >= 1 and yIndex <= self.height then
            return self.grid[xIndex][yIndex]
        else
            return nil
        end
    end

    -- Plot the grid as points on an ANSI terminal screen using a buffer
    function self:plot(func)
        local buffer = {}

        for j = self.height, 1, -1 do
            local line = {}
            for i = 1, self.width do
                color =  (self.grid[i][j] and self.grid[i][j] > yMid) and green or red
                if func then
                    color =  func(i, j, self) and green or red
                end
                if self.grid[i][j] then
                    table.insert(line, color..BAR..reset)
                else
                    table.insert(line, reset.." ")
                end
            end
            table.insert(buffer, table.concat(line))
        end

        -- Print the buffer
        for _, line in ipairs(buffer) do
            print(line)
        end
    end

    return self
end

-- BoxGrid.lua
local ColorGrid = {}

-- Define color codes
colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m"
}

-- Create a new BoxGrid instance
function ColorGrid.new(xMinMax, yMinMax, widthHeight)
    -- local BAR = '█'
    -- local BAR = '╹'
    -- local BAR = '▘'
    local BAR = '┃'
    local LINE = '━'
    local BAR = '▋'
    local BAR = '▍'
    -- local BAR = '┃'
    -- local BAR = '▘'
    -- local BAR = '▆'

    xMin, xMax = unpack(xMinMax)
    yMin, yMax = unpack(yMinMax)
    yMid = yMin+yMax/2
    width, height = unpack(widthHeight)

    local self = {
        xMin = xMin,   -- Minimum value for x-axis
        xMax = xMax,   -- Maximum value for x-axis
        yMin = yMin,   -- Minimum value for y-axis
        yMax = yMax,   -- Maximum value for y-axis
        width = width, -- Width of the grid
        height = height -- Height of the grid
    }

    -- Initialize grid as a table
    self.grid = {}
    for i = 1, self.width do
        self.grid[i] = {}
        for j = 1, self.height do
            self.grid[i][j] = nil
        end
    end

    -- Scale values to grid coordinates
    function self:scaleToGrid(xValue, yValue)
        local xIndex = math.floor((xValue - self.xMin) / (self.xMax - self.xMin) * (self.width - 1)) + 1
        local yIndex = math.floor((yValue - self.yMin) / (self.yMax - self.yMin) * (self.height - 1)) + 1
        return xIndex, yIndex
    end

    -- Insert scale values to grid coordinates with variable scales
    function self:insertValue(xValue, yValue, yMin, yMax, color)
        local xIndex = math.floor((xValue - self.xMin) / (xMax - self.xMin) * (self.width - 1)) + 1
        local yIndex = math.floor((yValue - yMin) / (yMax - yMin) * (self.height - 1)) + 1
        -- return xIndex, yIndex
        if xIndex >= 1 and xIndex <= self.width and yIndex >= 1 and yIndex <= self.height then
            self.grid[xIndex][yIndex] = color
        end
    end

    -- Set a value in the grid with a specific color
    function self:setValue(xValue, yValue, color)
        local xIndex, yIndex = self:scaleToGrid(xValue, yValue)
        if xIndex >= 1 and xIndex <= self.width and yIndex >= 1 and yIndex <= self.height then
            self.grid[xIndex][yIndex] = color
        end
    end

    -- Get a value from the grid
    function self:getValue(xValue, yValue)
        local xIndex, yIndex = self:scaleToGrid(xValue, yValue)
        if xIndex >= 1 and xIndex <= self.width and yIndex >= 1 and yIndex <= self.height then
            return self.grid[xIndex][yIndex]
        else
            return nil
        end
    end

    -- Plot the grid as points on an ANSI terminal screen using a buffer
    function self:plot(bar_ch)
        local buffer = {}
        local bar_ch = bar_ch or BAR

        for j = self.height, 1, -1 do
            local line = {}
            for i = 1, self.width do
                if self.grid[i][j] then
                    table.insert(line, colors[self.grid[i][j]] .. bar_ch .. colors.reset)
                else
                    table.insert(line, " ")
                end
            end
            table.insert(buffer, table.concat(line))
        end

        -- Print the buffer
        for _, line in ipairs(buffer) do
            print(line)
        end
    end

    return self
end

return ColorGrid


-- Explanation:
--
--     Initialization: The BoxGrid.new function creates a new BoxGrid instance with the given xMax, yMax, width, and height. It initializes a 2D table grid to represent the box grid.
--
--     Scaling: The scaleToGrid function scales given xValue and yValue to grid coordinates. It assumes that xValue is scaled based on xMax and yValue is scaled based on yMax.
--
--     Set and Get Values: The setValue function allows setting a value at a scaled grid coordinate, and the getValue function retrieves a value from a scaled grid coordinate.