#!/usr/bin/env luajit
-- Id$ nonnax Fri Jul 12 18:31:23 2024
-- https://github.com/nonnax

-- pretty_print.lua
local function print_table(list_of_maps, __order, noheader)
    -- Collect all keys
    local keys = {}
    for _, map in ipairs(list_of_maps) do
        for k in pairs(map) do
            keys[k] = true
        end
    end

    keys = __order or table.keys(keys) -- Convert to a list

    -- Determine the maximum width for each column
    local col_widths = {}
    for _, key in ipairs(keys) do
        col_widths[key] = #key
    end

    for _, map in ipairs(list_of_maps) do
        for _, key in ipairs(keys) do
            local value = tostring(map[key] or "")
            if #value > col_widths[key] then
                col_widths[key] = #value
            end
        end
    end

    if not noheader then
        -- Print the header row
        for _, key in ipairs(keys) do
            io.write(string.format("%" .. col_widths[key] .. "s  ", key))
        end
        io.write("\n")


        -- Print the separator
        for _, key in ipairs(keys) do
            io.write(string.rep("-", col_widths[key]) .. "  ")
        end
    end

    io.write("\n")

    -- Print each row of values
    for _, map in ipairs(list_of_maps) do
        for _, key in ipairs(keys) do
            local value = tostring(map[key] or "")
            io.write(string.format("%" .. col_widths[key] .. "s  ", value))
        end
        io.write("\n")
    end
end

-- util.lua
local function table_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

table.keys = table_keys
table.print = print_table

return {
    print_table = print_table,
    table_keys = table_keys
}
