-- Drives the day/night cycle. Runs on the server only; Lighting property
-- changes made here replicate to every client automatically.
--
-- Other systems (enemy spawner, base defenses, UI) should not poll Lighting
-- themselves -- listen for the NightStarted / DayStarted BindableEvents this
-- script fires under ReplicatedStorage, so they react at the exact moment
-- the phase flips instead of guessing from ClockTime.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DayNightConfig = require(ReplicatedStorage:WaitForChild("DayNightConfig"))

local nightStarted = Instance.new("BindableEvent")
nightStarted.Name = "NightStarted"
nightStarted.Parent = ReplicatedStorage

local dayStarted = Instance.new("BindableEvent")
dayStarted.Name = "DayStarted"
dayStarted.Parent = ReplicatedStorage

-- Also expose current phase as an attribute so late-joining scripts/UI can
-- just read it once instead of waiting on the next transition event.
Lighting:SetAttribute("IsNight", false)

local HOURS_PER_DAY = 24
local realSecondsPerInGameHour = (DayNightConfig.DAY_LENGTH_MINUTES * 60) / HOURS_PER_DAY

local function lerpColor3(a: Color3, b: Color3, t: number): Color3
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Smoothly blends Lighting properties toward night the closer the clock is
-- to the middle of the night window (and back toward day outside it), so
-- the transition doesn't pop instantly at the exact hour boundary.
local TRANSITION_HOURS = 1 -- how many in-game hours the fade takes

local function applyLighting(clockTime: number)
	local isNight = clockTime >= DayNightConfig.NIGHT_START_HOUR or clockTime < DayNightConfig.DAY_START_HOUR

	local t = 0 -- 0 = fully day, 1 = fully night
	if clockTime >= DayNightConfig.NIGHT_START_HOUR then
		t = math.clamp((clockTime - DayNightConfig.NIGHT_START_HOUR) / TRANSITION_HOURS, 0, 1)
	elseif clockTime < DayNightConfig.DAY_START_HOUR then
		local sinceMidnight = clockTime
		t = 1 - math.clamp(sinceMidnight / TRANSITION_HOURS, 0, 1)
		if clockTime >= DayNightConfig.DAY_START_HOUR - TRANSITION_HOURS then
			t = 0
		end
	end

	local day = DayNightConfig.DAY_LIGHTING
	local night = DayNightConfig.NIGHT_LIGHTING

	Lighting.Brightness = lerpNumber(day.Brightness, night.Brightness, t)
	Lighting.Ambient = lerpColor3(day.Ambient, night.Ambient, t)
	Lighting.OutdoorAmbient = lerpColor3(day.OutdoorAmbient, night.OutdoorAmbient, t)
	Lighting.FogEnd = lerpNumber(day.FogEnd, night.FogEnd, t)

	return isNight
end

local wasNight = false

local function onHeartbeat(deltaTime: number)
	local hoursPerSecond = 1 / realSecondsPerInGameHour
	Lighting.ClockTime = (Lighting.ClockTime + deltaTime * hoursPerSecond) % HOURS_PER_DAY

	local isNight = applyLighting(Lighting.ClockTime)

	if isNight ~= wasNight then
		wasNight = isNight
		Lighting:SetAttribute("IsNight", isNight)
		if isNight then
			nightStarted:Fire()
		else
			dayStarted:Fire()
		end
	end
end

-- Start at a fixed point so playtesting is consistent (mid-morning).
Lighting.ClockTime = 8
wasNight = applyLighting(Lighting.ClockTime)
Lighting:SetAttribute("IsNight", wasNight)

game:GetService("RunService").Heartbeat:Connect(onHeartbeat)
