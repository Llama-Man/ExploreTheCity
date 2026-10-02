-- Drives the day/night clock. Runs on the server only; ClockTime
-- replicates to every client, and each client's LightingZones script
-- turns the time (and where that player is) into the actual lighting.
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

local HOURS_PER_DAY = 24
local realSecondsPerInGameHour = (DayNightConfig.DAY_LENGTH_MINUTES * 60) / HOURS_PER_DAY

-- A high latitude keeps the sun low all day, so midday looks like late
-- afternoon instead of harsh overhead noon light.
Lighting.GeographicLatitude = DayNightConfig.GEOGRAPHIC_LATITUDE
Lighting.ClockTime = DayNightConfig.START_HOUR

-- Also expose current phase as an attribute so late-joining scripts/UI can
-- just read it once instead of waiting on the next transition event.
local wasNight = DayNightConfig.isNight(Lighting.ClockTime)
Lighting:SetAttribute("IsNight", wasNight)

game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
	Lighting.ClockTime = (Lighting.ClockTime + deltaTime / realSecondsPerInGameHour) % HOURS_PER_DAY
	local isNight = DayNightConfig.isNight(Lighting.ClockTime)
	if isNight ~= wasNight then
		wasNight = isNight
		Lighting:SetAttribute("IsNight", isNight)
		if isNight then
			nightStarted:Fire()
		else
			dayStarted:Fire()
		end
	end
end)
