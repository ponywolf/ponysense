-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Example of usage 

display.setDefault( "background", 0.333 )

local ponysense = require "com.ponywolf.ponysense"

if ponysense.initialize() then
  ponysense.addGame("SKIPCHASER", "SKIPCHASER", "Ponywolf", ponysense.colors.RED)
  ponysense.registerEvent({ event = "HEALTH"}) -- optional

  -- This example uses the function keys to make a health bar that can be updated 
  -- with ponysense.sendEventValue()
  -- See more handler examples at https://github.com/SteelSeries/gamesense-sdk/blob/master/doc/api/json-handlers-color.md
  
  local healthHandler = {
    device = "keyboard",
    zone = "function-keys",
    color = { 
      gradient =  { 
        zero = ponysense.RGB(255,0,0),
        hundred = ponysense.RGB(0,255,0),
      }
    },
    mode = "percent",
  }
  ponysense.bindEvent({ event = "HEALTH", handler = healthHandler})
else
  print("WARNING: Can't Find GameSense installation")
end

local function updateHealth()
  ponysense.sendEventValue("HEALTH", math.random(1,99))
end

-- update health on a 1/2 second timer
timer.performWithDelay(500, updateHealth, -1)


-- That's about it, enjoy


