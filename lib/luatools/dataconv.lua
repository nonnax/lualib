#!/usr/bin/env luajit
-- Id$ nonnax Sun Aug  4 13:10:22 2024
-- https://github.com/nonnax
-- data_convert.lua
-- require 'luatools/FP'
FP=require 'luatools/FP'

local DataConvert = {}

-- Convert rows of dictionaries to vectors based on a specific key
function DataConvert.rows_to_vectors(rows, key)
    return FP.map(rows, function(row)
        return row[key]
    end)
end

-- Convert vectors to rows of dictionaries with a specified key
function DataConvert.vectors_to_rows(vector, key)
    return FP.map(vector, function(value)
        return { [key] = value }
    end)
end

-- Convert rows of dictionaries to a matrix (list of vectors by keys)
function DataConvert.rows_to_matrix(rows)
    local keys = FP.keys(rows[1])
    return FP.reduce(keys, function(matrix, key)
        matrix[key] = DataConvert.rows_to_vectors(rows, key)
        return matrix
    end, {})
end

--- Converts a matrix to rows of dictionaries
-- Assumes that the matrix is represented as a table of columns with keys as column names
-- @param matrix table: A table where each key is a column name and each value is a table of column values
-- @return table: A table of rows represented as dictionaries
function DataConvert.matrix_to_rows(matrix)
    -- Extract keys from the matrix
    local keys = FP.keys(matrix)

    -- Assume all vectors have the same length
    local numRows = #matrix[keys[1]]

    -- Create an index table to iterate over using map
    local indices = {}
    for i = 1, numRows do
        indices[i] = i
    end

    -- Map over the indices to construct rows
    return FP.map(indices, function(i)
        return FP.reduce(keys, function(row, key)
            row[key] = matrix[key][i]
            return row
        end, {})
    end)
end

local data_convert={}
DataConvert.__index = DataConvert
setmetatable(data_convert, DataConvert)

function data_convert.global()
    for name, func in pairs(DataConvert) do
        _G[name]=func
    end
end


return data_convert
