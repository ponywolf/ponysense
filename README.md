# ponysense
SteelSeries GameSense™ SDK Helper Library for Lua Game engines

GameSense™ is a framework in SteelSeries Engine that allows games & apps to send status updates to Engine, which can then drive illumination, haptic & OLED display capabilities of SteelSeries devices. One simple example would be displaying the player's health on the row of functions keys as a bargraph that gets shorter and changes from green to red as their health decreases -- even flashing when it gets critically low.

#### Initialize

Just initalize the Module to get started:

```
ponysense.addGame("SKIPCHASER", "SKIPCHASER", "Ponywolf", ponysense.colors.RED)
```

#### Handler(s)

Setup a handler (or multiple handlers):

```
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
```

#### Send Values

Push values to your handlers

```
ponysense.sendEventValue("HEALTH", player.health)
```