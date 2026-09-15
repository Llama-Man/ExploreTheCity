-- Shared config + constants for the day/night cycle.
-- Read by the server (which drives the cycle) and any client/server script
-- that needs to know current phase (e.g. enemy spawner, UI clock).

local DayNightConfig = {}

-- How many real-world minutes one full 24h in-game day takes.
DayNightConfig.DAY_LENGTH_MINUTES = 8

-- In-game clock hours (0-24) that mark the start of night and start of day.
DayNightConfig.NIGHT_START_HOUR = 20 -- 8 PM
DayNightConfig.DAY_START_HOUR = 6 -- 6 AM

-- Lighting presets blended between over the transition.
DayNightConfig.DAY_LIGHTING = {
	Brightness = 2,
	Ambient = Color3.fromRGB(140, 140, 140),
	OutdoorAmbient = Color3.fromRGB(140, 140, 140),
	FogEnd = 100000,
}

DayNightConfig.NIGHT_LIGHTING = {
	Brightness = 0.5,
	Ambient = Color3.fromRGB(20, 20, 35),
	OutdoorAmbient = Color3.fromRGB(20, 20, 35),
	FogEnd = 300,
}

return DayNightConfig
