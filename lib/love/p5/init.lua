#!/usr/bin/env luvit

local path = ... .. '.'
local Vector=require(path .. 'p5.vector')
-- require(path .. 'p5.noise')
local p5=require(path .. 'p5.calculation')

-- require(... ..'/vector')
-- require(... ..'/noise')
-- require 'love/p5/vector'
-- require 'love/p5/calculation'
-- require 'love/p5/noise'
p5.Vector = Vector
return p5
