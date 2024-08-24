#!/usr/bin/env luajit
-- Id$ nonnax Sun Jul 21 12:08:00 2024
-- https://github.com/nonnax
local _D={}
RED = "\27[31m"
GREEN = "\27[32m"
RESET = "\27[0m"

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

ansi={}
ansi.FULLBLOCK = '█'
ansi.HALFBLOCK = '▋'
ansi.BAR = '▍'
ansi.VBAR = "┃"
ansi.ULBLOCK = '▘'
ansi.WICK = '│'

function drawVerticalBars(values, maxHeight, formatFunc, colorfx)
    -- Determine the maximum and minimum values to normalize the heights
    if not formatFunc then
       function formatFunc(value)
            return string.format("%05.2f", value)
       end
    end
    local maxValue = math.max(unpack(values))
    local minValue = math.min(unpack(values))
    local avgValue = 0
    for _, value in ipairs(values) do
        avgValue = avgValue + value
    end
    avgValue = avgValue / #values

    if maxValue == 0 then maxValue = 1 end -- To avoid division by zero

    -- Create a grid to hold the drawing characters
    local height = maxHeight
    local width = #values
    local grid = {}

    -- Initialize the grid with spaces
    for y = 1, height do
        grid[y] = {}
        for x = 1, width do
            grid[y][x] = ' '
        end
    end

    -- -- Fill in the grid with bars
    -- for x, value in ipairs(values) do
    --     local scaledHeight = math.floor((value / maxValue) * height)
    --     for y = 1, scaledHeight do
    --         grid[height - y + 1][x] = '#'
    --     end
    -- end

    -- Fill in the grid with bars
    for x, value in ipairs(values) do
        local scaledHeight = math.floor((value / maxValue) * height)
        local color = "\27[37m" -- Default to white if no color is provided
        if colorfx then
            color=colorfx(value)
        end
        for y = 1, scaledHeight do
            grid[height - y + 1][x] = color .. '#' .. "\27[0m"
        end
    end

    -- Define the scale function for the y-axis
    local function scaleY(value)
        return math.floor(height - (value / maxValue) * height) + 1
    end

    -- Use the format function to determine the width of the y-axis labels
    local yAxisLabelWidth = math.max(
        string.len(formatFunc(maxValue)),
        string.len(formatFunc(avgValue)),
        string.len(formatFunc(minValue)),
        string.len(formatFunc(0))
    )

    -- Print the grid with y-axis labels
    for y = 1, height do
        -- Determine the value for this row
        local currentValue = maxValue - (y - 1) * (maxValue / height)
        local label = ""
        if y == scaleY(maxValue) then
            label = formatFunc(maxValue)
        elseif y == scaleY(minValue) then
            label = formatFunc(minValue)
        elseif y == scaleY(avgValue) then
            label = formatFunc(avgValue)
        else
            label = string.rep(" ", yAxisLabelWidth)
        end
        io.write(label)
        for x = 1, width do
            io.write(grid[y][x])
        end
        io.write("\n")
    end

    -- Print the x-axis labels
    io.write(string.rep(" ", yAxisLabelWidth))  -- Space for the y-axis labels
    for x = 1, width do
        io.write(string.format("%-1d", (x-1)%9+1))  -- x-axis labels (1 to 9 repeatedly)
    end
    io.write("\n")
end


_D.draw_vbars=drawVerticalBars

-- return _D

-- require 'luatools'
-- BoxGrid.lua

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


function _D.draw_close(ohlcData)
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

-- Create a new BoxGrid instance
function _D.BBoxGrid(xMinMax, yMinMax, widthHeight)
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
-- local ColorGrid = {}

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
function _D.BoxGrid(xMinMax, yMinMax, widthHeight)
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
    function self:plot(bar_char)
        local buffer = {}
        local bar_char = bar_char or BAR

        for j = self.height, 1, -1 do
            local line = {}
            for i = 1, self.width do
                if self.grid[i][j] then
                    table.insert(line, colors[self.grid[i][j]] .. bar_char .. colors.reset)
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

-- return ColorGrid

return _D


-- Explanation:
--
--     Initialization: The BoxGrid.new function creates a new BoxGrid instance with the
-- given xMax, yMax, width, and height. -- It initializes a 2D table grid to represent the box grid.
--
--     Scaling: The scaleToGrid function scales given xValue and yValue to grid coordinates.
-- It assumes that xValue is scaled based on xMax and yValue is scaled based on yMax.
--
--     Set and Get Values: The setValue function allows setting a value at a scaled
-- grid coordinate, and the getValue function retrieves a value from a scaled grid coordinate.