-- stroke module com.ponywolf.ponysense

-- define module
local M = {}
local json = require "json"
local isWin = system.getInfo("platform") == "win32" 
local isMac = system.getInfo("platform") == "macos"
local isSimulator = "simulator" == system.getInfo( "environment" )

-- settings
local server, game, heartbeatDelay, heartbeatTimer
local verbose = false --true

-- ENDPOINT DECLARATIONS
--GS_ENDPOINT_GAME_METADATA = "/game_metadata"
--GS_ENDPOINT_GAME_EVENT = "/game_event"


-- icon colors
M.colors = {}
M.colors["ORANGE"] = 0
M.colors["GOLD"] = 1
M.colors["YELLOW"] = 2
M.colors["GREEN"] = 3
M.colors["TEAL"] = 4
M.colors["LIGHT_BLUE"] = 5
M.colors["BLUE"] = 6
M.colors["PURPLE"] = 7
M.colors["FUSCHIA"] = 8
M.colors["PINK"] = 9
M.colors["RED"] = 10
M.colors["SILVER"] = 11

if isSimulator then isWin = true end -- set for you own debugging purposes pc/mac

local function programData(filename)
  if isWin or isSimulator then 
    return (os.getenv("PROGRAMDATA") or "C:/ProgramData") .. "/SteelSeries/SteelSeries Engine 3/" .. filename or "temp.tmp"
  else 
    return "/Library/Application Support/SteelSeries Engine 3/" .. filename or "temp.tmp"
  end
end

local function split(inputstr, sep)
  sep = sep or ":"
  inputstr = inputstr or ""
  local tbl={}
  local i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    tbl[i] = str
    i = i + 1
  end
  return tbl
end

function M.RGB(r,g,b)
  return { red = r or 255, green = g or r or 255, blue = b or r or 255 }
end

function M.initialize(options)
  -- PC only module
  if not (isMac or isWin) then return false end

  -- open the file
  local file, errorString, data = io.open( programData("coreProps.json"), "r" )

  if not file then
    print( "File error: " .. errorString )
    return false
  else
    local contents = file:read( "*a" )
    data = json.decode(contents)
    --print(json.prettify(data))
    io.close( file )
  end
  server = "http://" .. (data.address or "localhost:49801")
  file = nil
  return server

end

local function networkListener( event )
  -- if we get a heartbeat, mirror that time
  if event and event.response and event.response:find("deinitialize_timer_length_ms") then
    local metadata = json.decode(event.response)
    if verbose then 
      print( "GAMESENSE: ", "Starting heartbeat..." )
    end    
    if not heartbeatTimer then
      heartbeatDelay = metadata["game_metadata"]["deinitialize_timer_length_ms"] or 15000
      heartbeatTimer = timer.performWithDelay(heartbeatDelay, M.heartbeat, -1)
    else
      if verbose then 
        print( "GAMESENSE: ", "Heartbeat already started" )
      end    
    end
  end

  -- verbose?
  if not verbose then return end

  -- errors
  if ( event.isError ) then
    event.response = event.response or "No error code"
    print( "GAMESENSE ERROR: ", event.response )
  else 
    event.response = event.response or "No response"
    print ( "GAMESENSE RESPONSE: ", event.response)
  end
end

function M.write(endpoint, data)

  local body = json.encode(data)
  local headers = {}
  headers["Content-Type"] = 'application/json'
  headers["Content-Length"] = #body

  local params = {}
  params.headers = headers
  params.bodyType = "text"
  params.body = body

  if verbose then print("GAMESENSE POST: ",json.encode(params)) end

  network.request( server .. endpoint, "POST", networkListener, params )
end

function M.addGame(name, displayName, developer, iconColor, heartbeat)
  local data = {
    ["game"] = name or "TEST_GAME",
    ["game_display_name"] = displayName or "My testing game",
    ["developer"] = developer or "My Game Studios",
    ["icon_color_id"] = iconColor or 0,
    ["deinitialize_timer_length_ms"] = heartbeat or 15000,
  }
  game = data.game
  M.write("/game_metadata", data)
end

function M.registerEvent(options)
  options = options or {}  
  local data = {
    ["game"] = game,
    ["event"] = options.event or "HEALTH",
    ["min_value"] = options.min or 0,
    ["max_value"] = options.max or 100,
    ["icon_id"] = options.icon or 1,
    ["value_optional"] = options.optional
  }
  M.write("/register_game_event", data)
end

function M.bindEvent(options)
  options = options or {}

  if options.handler then -- we only have one handler
    options.handler["device-type"] = options.handler.device or options.handler["device-type"]
    options.handlers = { options.handler } -- make it the first
  elseif options.handlers then -- we have multiple handlers
    for i = 1, #options.handlers do
      options.handlers[i]["device-type"] = options.handlers[i].device or options.handlers[i]["device-type"]
    end
  else -- no handlers
    print( "GAMESENSE ERROR: ", "You need at least one handler or mutiple handlers")
  end

  local data = {
    ["game"] = game,
    ["event"] = options.event,
    ["min_value"] = options.min or 0,
    ["max_value"] = options.max or 100,
    ["icon_id"] = options.icon or 1,
    ["handlers"] = options.handlers,
  }
  M.write("/bind_game_event", data)
end

function M.sendEventValue(event, value)
  options = options or {}
  local data = {
    ["game"] = game,
    ["event"] = event,
    ["data"] = { value = value },
  }
  M.write("/game_event", data)
end

function M.heartbeat()
  local data = {
    ["game"] = game,
  }
  M.write("/game_heartbeat", data)
  if verbose then print ("GAMESENSE:","Heartbeat") end
end

function M.removeEvent(event)
  local data = {
    ["game"] = game,
    ["event"] = event,
  }
  M.write("/remove_game_event", data)
end

function M.removeGame(event)
  local data = {
    ["game"] = game,
  }
  M.write("/remove_game", data)
end

-- return module
return M