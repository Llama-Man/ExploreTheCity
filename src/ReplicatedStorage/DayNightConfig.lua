-- Shared config + constants for the day/night cycle.
-- Read by the server (which drives the clock) and the client lighting
-- script (LightingZones), plus anything that needs to know the phase
-- (e.g. enemy spawner, UI clock).

local DayNightConfig = {}

-- How many real-world minutes one full 24h in-game day takes.
DayNightConfig.DAY_LENGTH_MINUTES = 8

-- In-game clock hours (0-24) that mark the start of night and start of day.
DayNightConfig.NIGHT_START_HOUR = 20 -- 8 PM
DayNightConfig.DAY_START_HOUR = 6 -- 6 AM

DayNightConfig.START_HOUR = 15

-- How many in-game hours the fade between day and night takes.
DayNightConfig.TRANSITION_HOURS = 1

-- Higher = lower sun at midday. ~60 gives afternoon-like light at noon;
-- Roblox's default is 41.7.
DayNightConfig.GEOGRAPHIC_LATITUDE = 60

-- 0 = full day, 1 = full night: fades in over the hour after
-- NIGHT_START_HOUR and out over the hour before DAY_START_HOUR.
function DayNightConfig.nightBlend(clock)
	local T = DayNightConfig.TRANSITION_HOURS
	if clock >= DayNightConfig.NIGHT_START_HOUR then
		return math.clamp((clock - DayNightConfig.NIGHT_START_HOUR) / T, 0, 1)
	elseif clock < DayNightConfig.DAY_START_HOUR then
		return math.clamp((DayNightConfig.DAY_START_HOUR - clock) / T, 0, 1)
	end
	return 0
end

-- 0..1, peaking in the golden hour before dusk and just after dawn.
function DayNightConfig.warmBlend(clock)
	local dusk = 1 - math.abs(clock - (DayNightConfig.NIGHT_START_HOUR - 0.8)) / 1.6
	local dawn = 1 - math.abs(clock - (DayNightConfig.DAY_START_HOUR + 0.3)) / 1.1
	return math.clamp(math.max(dusk, dawn), 0, 1)
end

function DayNightConfig.isNight(clock)
	return clock >= DayNightConfig.NIGHT_START_HOUR or clock < DayNightConfig.DAY_START_HOUR
end

return DayNightConfig
