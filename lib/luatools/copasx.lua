#!/usr/bin/env luajit

-- Id$ nonnax Sat Jul 27 16:34:34 2024
-- https://github.com/nonnax
copas = require 'copas'
http = require 'copas.http'
json = require 'lunajson'

function copas_run(q, info, activate)
  -- info buffer to fill-up
  -- copas_fn activates the thread, use at the `end` of all copas_run(s)
  -- or instead simply call copas() at the end
  local function get(u, data)
    local body, status, headers, head = http.request(u)
    local stat, res = pcall(json.decode, body)
    if stat then for i, v in ipairs(res) do table.insert(data, v) end end
  end
  copas.addthread(get, q, info)
  copas()
end

copas_get = copas_run

function copas_getall(endpoints, t)
  -- local t={}
  local function get(u, data, symbol)
    local body, status, headers, head = http.request(u)

    local stat, res = pcall(json.decode, body)
    if stat then data[symbol] = res end
    copas.pause(1)
  end
  for symbol, url in pairs(endpoints) do
    copas.addthread(get, url, t, symbol)
  end
  copas()
end

function copas_add(urls, store)
  local function get(u, t)
    local body, err = http.request(u)
    table.insert(t, json.decode(body))
  end
  for i, u in pairs(urls) do
    copas.addthread(get, u, store)
  end
  -- copas()
end

copas.addurls = copas_add
