
justLines=true--for debug drawing

--modules
LG = love.graphics
LM = love.math
LS = love.sound
LT = love.touch
LD = love.data
LF = love.filesystem
LS = love.system
LT = love.timer
Lm = love.mouse
LI = love.image
LF = love.font
LV = love.video
LE = love.event
LP = love.physics


--=========>> math

abs = math.abs

acos = math.acos

asin = math.asin

atan = math.atan

atan2 = math.atan2

ceil = math.ceil

cos = math.cos

deg = math.deg

exp = math.exp

floor = math.floor

log = math.log

log10 = math.log10

max = math.max

min = math.min

mod = math.mod

pow = math.pow

rad = math.rad

sin = math.sin

sqrt = math.sqrt

tan = math.tan

frexp = math.frexp

ldexp = math.ldexp

random = math.random

randomseed = math.randomseed

pi = math.pi

huge = math.huge


--==========>>>



--Colors to use

colors={

red={1,0,0},

orange = { 1,0 ,1 },

teal = { 0 ,1 ,1 },

white={1,1,1},

liWhite = { .5,.5,.5 },

blue={0,0,1},

liBlue={0,0,.5},

green={0,1,0},

liGreen = { 0,.1,0 },

yellow={1,1,0},

liYellow = {.5 ,.5 ,0 },

blank ={0,0,0,0},

black={0,0,0},



}

--======>> table

push = table.insert

remove = table.remove

format  = string.format

concat  = table.concat

join  = table.concat

sort    = table.sort


--=======lua functions

 -- type()
  --error(name .. ' must be a positive integer, but was ' .. tostring(value) .. '(' .. type(value) .. ')')
  --tostring(value)
  --assert()


  --======> screen

Width, Height =love.graphics.getDimensions()

--==========>>>>  by module


--graphics

--shape draw
circle = love.graphics.circle -- mode, x, y, radius
ellipse = love.graphics.ellipse -- mode, x, y, radius
draw = love.graphics.draw
line = love.graphics.line -- ( x1, y1, x2, y2, ...
rect = love.graphics.rectangle
polygon = love.graphics.polygon

--specks
newSpecks = love.graphics.newParticleSystem


newCanvas = love.graphics.newCanvas


--sprites
newQuad = love.graphics.newQuad

--canvs
setCanvas = love.graphics.setCanvas
setColor = love.graphics.setColor
setBackgroundColor = love.graphics.setBackgroundColor
getBackgroundColor = love.graphics.setColor


--font
newFont = love.graphics.newFont --filename, size
setNewFont =love.graphics.setNewFont
newImageFont = love.graphics.newImageFont -- filename, glyphs )
setFont = love.graphics.setFont -- font obj

--image
newImage = love.graphics.newImage


--text

gprint = love.graphics.print

gprintf = love.graphics.printf --coloredtext, font, x, y, limit, align, angle, sx, sy, ox, oy, kx, ky )


newText = love.graphics.newText  -- font, textstring

--index = Text:add( textstring, x, y, angle, sx, sy, ox, oy, kx, ky )
--index = Text:addf( coloredtext, wraplimit, align, x, y, angle, sx, sy, ox, oy, kx, ky )
  --text:clear()
  --Text:getHeight
--text:set( coloredtext )

--audio
newSource=love.audio.newSource
stop = love.audio.stop--stops curr played sources
setVol = love.audio.setVolume --( volume )


--timer
getFPS = love.timer.getFPS
getDelta=love.timer.getDelta
getTime = love.timer.getTime

--touch
getTouchPos = love.touch.getPosition  --( id )

--world
  --wWorld = love.physics.newWorld  windfield issue?

--random
Random = love.math.newRandomGenerator()
noise = love.math.noise
random = love.math.random


--box2d
newRect = love.physics.newRectangleShape
newCircle = love.physics.newCircleShape
newPoly = love.physics.newPolygonShape--(vertices )
newChain = love.physics.newChainShape--
newRect = love.physics.newRectangleShape--( x, y, width, height, angle )

--body:setSleepingAllowed( allowed )

 -- love.touchreleased  --( id, x, y, dx, dy, pressure )
  --love.touchmoved --( id, x, y, dx, dy, pressure )
  --love.touch.getTouches
  --love.touch.getPosition  --( id )


  --===sound


--volume	number	1.0 is max and 0.0 is off.


--Creates an identical copy of the Source in the stopped state.
--Static Sources will use significantly less memory and take much less time to be created if Source:clone is used to create them instead of love.audio.newSource, so this method should be preferred when making multiple Sources which play the same sound.

 --source = Source:clone()









function drawDebug()

    local obj

    if justLines ==false then

        obj ='fill'

    else obj ='line' end


     local bods = world:getBodies()

    for _, body in ipairs(bods) do

        local fix = body:getFixtures()

        for _, fixs in ipairs(fix) do

            if fixs:getShape():type() == 'PolygonShape' then



                drawPoly(obj, body:getWorldPoints(fixs:getShape():getPoints()))



            elseif fixs:getShape():type() == 'EdgeShape' or fixs:getShape():type() == 'ChainShape' then

                local points = {body:getWorldPoints(fixs:getShape():getPoints())}

                for i = 1, #points, 2 do

                    if i < #points-2 then line(points[i], points[i+1], points[i+2], points[i+3]) end
                end


            elseif fixs:getShape():type() == 'CircleShape' then

                local body_x, body_y = body:getPosition()

                local shape_x, shape_y = fixs:getShape():getPoint()

                local r = fixs:getShape():getRadius()

                     circle( obj, body_x + shape_x, body_y + shape_y, r, 360)
            end

        end

    end



end

