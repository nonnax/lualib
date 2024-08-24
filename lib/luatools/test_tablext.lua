#!/usr/bin/env luajit
-- Id$ nonnax Wed Jul 31 14:36:11 2024
-- https://github.com/nonnax
require 'luatools'

-- Example data
local rows = {
    {id = 1, name = "Alice", age = 30},
    {id = 2, name = "Bob", age = 25},
    {id = 3, name = "Charlie", age = 35}
}

-- Convert rows to vectors
local vectorA = tablex(rows)
    :rows_to_vectors("age")
    :to_table()

print(table.concat(vectorA, ", "))  -- Output: 30, 25, 35

-- Convert vectors to rows
local rowsFromVector = tablex(vectorA)
    :vectors_to_rows("age")
    :to_table()

for _, row in ipairs(rowsFromVector) do
    print(row.age)
end

-- Convert rows to matrix
local matrix = tablex(rows)
    :rows_to_matrix()
    :to_table()

-- Print matrix
for key, values in pairs(matrix) do
    print(key .. ": " .. tablex(values):concat(", "))
end
puts(matrix)

-- Convert matrix to rows
local convertedRows = tablex(matrix)
    :matrix_to_rows()
    :to_table()

for _, row in ipairs(convertedRows) do
    print(row.id, row.name, row.age)
end

puts(convertedRows)


a=tablex{1, 2, 3, 4, 5, 6, 7}

res=a:each_slice(3, function(v) puts(v) end):to_table()
puts(res)

api=require 'coinspro'
rows = api.candle('MEWPHP', 50)
res=
Map(rows)
.map(table.where, {datetime="18:"})
.value
print(tablex(res))