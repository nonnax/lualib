#!/usr/bin/env luajit
-- Id$ nonnax Tue Jul  9 20:34:06 2024
-- https://github.com/nonnax
require 'luatools/stdlibx'
json = require 'lunajson'
tablext = require 'luatools/tablext'
pretty_print = require 'luatools/pretty_print'
fun = require 'fun'
lfs = require 'lfs'
numbers = require 'luatools/numbers'
Moneymath = numbers.Moneymath
Fraction = numbers.Fraction
ohlc_lib = require 'ohlc/ohlc_lib'
require 'luatools/luatools'
draw = require 'luatools/drawing'
DC = require 'luatools/dataconv'
TC = require 'luatools/tradecalc'
FP = require 'luatools/FP'
-- require 'luax/mather'

