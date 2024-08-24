#!/usr/bin/env luajit
-- Id$ nonnax Sat Jul 27 16:34:34 2024
-- https://github.com/nonnax
copas = require 'copas'
http = require 'copas.http'

function copas_run(q, info, activate)
    -- info buffer to fill-up
    -- copas_fn activates the thread, use at the `end` of all copas_run(s)
    -- or instead simply call copas() at the end
    local function get(data, q)
        local body, status, headers, head = http.request(q)
        local stat, res = pcall(json.decode, body)
        if stat then
            table.insert(data, res)
        end
    end
    copas.addthread(get,info,q)
    if activate then copas() end
end

function copas_add(endpoints, t)
    local t={}
    local function get(u, data, symbol)
        local body, status, headers, head = http.request(u)

        local stat, res = pcall(json.decode, body)
        if stat then
            data[symbol]=res
        end
        copas.pause(1)
    end
    for symbol, url in pairs(endpoints) do
        copas.addthread(get, url, t, symbol)
    end
    return t
end

copas.addurls=copas_add