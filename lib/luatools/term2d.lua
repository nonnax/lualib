#!/usr/bin/env luajit

-- id$ nonnax fri jul 19 09:59:27 2024
-- https://github.com/nonnax
require 'luatools'
-- box_grid.lua
local Colorgrid = {}

-- already in luatools
-- function math.scale(v, vmin, vmax, scalemin, scalemax)
-- function io.cols()

-- create a new box_grid instance

function Colorgrid.new(params)

  local self = {
    width = params.width or io.cols(), -- width of the grid
    height = params.height or 50, -- height of the grid
    dot = params.dot or '┃',
    vbar = '┃',
    bar  = '█',
    wick = "│",
    dash = params.dash or "┈"
  }

  -- initialize grid as a table
  self.grid = {}
  for x = 1, self.width do
    self.grid[x] = {}
    for y = 1, self.height do self.grid[x][y] = nil end
  end

  function self:scale_y(y, ymin, ymax)
    return math.floor(math.scale(y, ymin, ymax, self.height, 1))
  end

  function self:scale_x(x, xmin, xmax)
    return math.floor(math.scale(x, xmin, xmax, 1, self.width))
  end

  function self:is_valid_indexes(xi, yi)
    return xi >= 1 and xi <= self.width and
           yi >= 1 and yi <= self.height
  end

  -- scale values to grid coordinates
  function self:scale_to_grid(x_value, y_value)
    local xi = self:scale_x(x_value, self.x_min, self.x_max)
    local yi = self:scale_y(y_value, self.y_min, self.y_max)
    return xi, yi
  end

  -- set a value in the grid with a specific color
  function self:point(xi, yi, color, dot)
    local xi, yi = math.floor(xi), math.floor(yi)
    if self:is_valid_indexes(xi, yi) then
      self.grid[xi][yi] = {color=color, dot = dot or self.dot}
    end
  end

  -- get a value from the grid
  function self:get_value(x_value, y_value)
    local xi, yi = self:scale_to_grid(x_value, y_value)
    if self:valid_indexes(xi, yi) then
      return self.grid[xi][yi]
    else
      return nil
    end
  end


  function self:line(x1, y1, x2, y2, color, dot)
      -- Initialize the differences and steps
      local dx = math.abs(x2 - x1)
      local dy = math.abs(y2 - y1)
      local sx = x1 < x2 and 1 or -1
      local sy = y1 < y2 and 1 or -1
      local err = dx - dy
      local color = color or 'white'

      while true do
          -- Set the current point on the grid with the specified color
          -- self:pixel(x1, y1, color)
          self:point(x1, y1, color, dot)

          -- Check if the line has reached the end point
          if x1 == x2 and y1 == y2 then break end

          -- Calculate error for the next step
          local e2 = 2 * err
          if e2 > -dy then
              err = err - dy
              x1 = x1 + sx
          end
          if e2 < dx then
              err = err + dx
              y1 = y1 + sy
          end
      end
  end

  function self:pixel(x, y, color, dot)
      -- Ensure the coordinates are within the grid's bounds
      -- unlike point, pixel uses math.ceil
      local x, y = math.ceil(x), math.ceil(y)
      if self:is_valid_indexes(x, y) then
          self.grid[x][y] = {color=color, dot=dot or self.dot}
      end
  end

  -- plot the grid as points on an ansi terminal screen using a buffer
  function self:draw(fx)
    local buffer = {}
    for j = self.height, 1, -1 do
      local line = {}
      for i = 1, self.width do
        if self.grid[i][j] then
          local point = self.grid[i][j]
          table.insert(line, colors[point.color] .. point.dot .. colors.reset)
        else
          table.insert(line, self.dash)
        end
      end
      table.insert(buffer, table.concat(line))
    end
    -- print the buffer
    for i, line in ipairs(buffer) do
      if fx then
        fx(line, i)
      else
        print(line)
      end
    end
  end

  return self
end

return Colorgrid

-- explanation:
--
--  initialization: the box_grid.new function creates a new box_grid instance with the given x_max, y_max, width, and height. it initializes a 2d table grid to represent the box grid.
--  scaling: the scale_to_grid function scales given x_value and y_value to grid coordinates. it assumes that x_value is scaled based on x_max and y_value is scaled based on y_max.
--  set and get values: the set_value function allows setting a value at a scaled grid coordinate, and the get_value function retrieves a value from a scaled grid coordinate.
