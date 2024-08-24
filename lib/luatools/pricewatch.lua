#!/usr/bin/env luajit
-- Id$ nonnax Wed Jul 17 10:06:41 2024
-- https://github.com/nonnax
api = require 'coinspro'

local M = {}
local f = '/home/nonnax/love/sandbox/trading/atrpricechart/pricewatch.json'
local db = {}

if not io.exists(f) then
  io.writejson(f, db)
else
  db = io.readjson(f)
end

local function add(t)
   local symbol=t.symbol
   db[symbol]=t.symbol
   local select=table.slice(t, {'price', 'units', 'profit'})
   db[symbol]=select
   print('in add', symbol)
   puts(db)
   io.writejson(f, db)
end

function check_or_add(symbol)
  if not db[symbol] then
    local t = {symbol=symbol, price=0, units=1, profit=200}
    add(t)
  end
end

function get(symbol)
  check_or_add(symbol)
  return db[symbol]
end

local function target_sell_price(symbol, market_price)
   check_or_add(symbol)

   local user_price, units, target_profit = unpack_map(db[symbol], 'price', 'units', 'profit' )

   -- print('orig', make_profit_of(target_profit, units, user_price))

   return make_profit_of(target_profit, units, market_price)
end

M.target_sell_price=target_sell_price
M.add=add
M.get=get

return M