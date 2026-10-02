-- The lighting, per player: it follows the time of day (the server runs
-- the clock) and where you are, blending smoothly between looks as you
-- move.
--   city        the grey, hazy megacity; golden at dusk and dawn, blue and
--               dark at night.
--   underground anywhere with rock overhead (the tunnels, the facility,
--               the maze): the haze turns dark so passages fade to black,
--               ambient light drops so lamps and glowing fungus do the
--               work, and bloom picks up the glow.
--   the deep    underground and far down (the bottom of the chasm and the
--               tunnels under it): darker still, colder, thicker, so
--               there's very little you can see past your own light.
--   sea         the hidden sea under the courtyard: deep teal haze.
--   the damp    Kazami's undercroft (StiltTown.lua), under the town's
--               decks out west: grey-green murk, the light dim and cold,
--               so the green lamps and your own light do the work.
--   the murk    the same, far down the pylons' legs towards the fog:
--               darker and thicker again.
--   the depths  below FOG_TOP the world fades out into black: a stack of
--               huge thin dark sheets, each darkening what's under it a
--               little more, over a black floor. They follow the camera
--               (so one sheet per layer covers everything), and they're
--               hidden when you're underground or at the hidden sea, which
--               reach below the line inside the rock. Fall into them and
--               the light goes too.
-- Presets are plain tables below; tweak numbers there.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DayNightConfig = require(ReplicatedStorage:WaitForChild("DayNightConfig"))
local SchoolConfig = require(ReplicatedStorage:WaitForChild("School"):WaitForChild("SchoolConfig"))

local rgb = Color3.fromRGB

local CITY_DAY = {
	Brightness = 1.4,
	Ambient = rgb(78, 72, 64),
	OutdoorAmbient = rgb(140, 140, 140),
	Exposure = -0.2,
	AtmDensity = 0.3,
	AtmOffset = 0.1,
	AtmColor = rgb(190, 184, 172),
	AtmDecay = rgb(96, 100, 110),
	AtmGlare = 0.2,
	AtmHaze = 1.8,
	CCBrightness = 0,
	CCContrast = 0.08,
	CCSaturation = -0.14,
	CCTint = rgb(248, 242, 230),
	BloomIntensity = 0.35,
	BloomSize = 24,
	BloomThreshold = 1.6,
	SunRays = 0.03,
}

local CITY_NIGHT = {
	Brightness = 0.8,
	Ambient = rgb(46, 48, 62),
	OutdoorAmbient = rgb(72, 78, 104),
	Exposure = 0.3,
	AtmDensity = 0.36,
	AtmOffset = 0.05,
	AtmColor = rgb(46, 50, 64),
	AtmDecay = rgb(24, 26, 36),
	AtmGlare = 0,
	AtmHaze = 1.4,
	CCContrast = 0.1,
	CCSaturation = -0.25,
	CCTint = rgb(214, 222, 242),
	BloomIntensity = 0.5,
	BloomSize = 28,
	BloomThreshold = 1.3,
	SunRays = 0,
}

-- Mixed in towards dusk and dawn (only these values change).
local GOLDEN = {
	AtmColor = rgb(214, 160, 118),
	AtmDecay = rgb(120, 92, 96),
	AtmGlare = 0.5,
	CCTint = rgb(255, 230, 204),
	SunRays = 0.08,
}

local UNDERGROUND = {
	Ambient = rgb(64, 60, 54),
	OutdoorAmbient = rgb(64, 60, 54),
	Exposure = 0,
	AtmDensity = 0.45,
	AtmOffset = 0,
	AtmColor = rgb(34, 32, 30),
	AtmDecay = rgb(18, 18, 20),
	AtmGlare = 0,
	AtmHaze = 0.6,
	CCContrast = 0.12,
	CCSaturation = -0.12,
	CCTint = rgb(240, 234, 224),
	BloomIntensity = 0.55,
	BloomSize = 22,
	BloomThreshold = 1.15,
	SunRays = 0,
}

-- Rock overhead and below this height: the Deep.
local DEEP_BELOW = -385
local THE_DEEP = {
	Ambient = rgb(36, 40, 48),
	OutdoorAmbient = rgb(36, 40, 48),
	Exposure = 0,
	AtmDensity = 0.62,
	AtmOffset = 0,
	AtmColor = rgb(14, 17, 20),
	AtmDecay = rgb(8, 10, 12),
	AtmGlare = 0,
	AtmHaze = 1.2,
	CCContrast = 0.18,
	CCSaturation = -0.35,
	CCTint = rgb(214, 224, 232),
	BloomIntensity = 0.7,
	BloomSize = 24,
	BloomThreshold = 1.05,
	SunRays = 0,
}

local SEA = {
	Ambient = rgb(18, 34, 42),
	OutdoorAmbient = rgb(18, 34, 42),
	Exposure = 0.1,
	AtmDensity = 0.38,
	AtmOffset = 0,
	AtmColor = rgb(24, 62, 74),
	AtmDecay = rgb(8, 26, 36),
	AtmGlare = 0,
	AtmHaze = 2.2,
	CCContrast = 0.1,
	CCSaturation = -0.02,
	CCTint = rgb(214, 238, 244),
	BloomIntensity = 0.7,
	BloomSize = 30,
	BloomThreshold = 1.1,
	SunRays = 0,
}

-- Kazami's undercroft: out west, below the town's decks.
local DAMP_ZONE = { x0 = -900, x1 = -575, z0 = -260, z1 = 320, y0 = -300, y1 = 116 }
local DAMP = {
	Ambient = rgb(44, 52, 50),
	OutdoorAmbient = rgb(58, 68, 66),
	Exposure = -0.15,
	AtmDensity = 0.5,
	AtmOffset = 0,
	AtmColor = rgb(92, 104, 100),
	AtmDecay = rgb(40, 48, 46),
	AtmGlare = 0,
	AtmHaze = 2.6,
	CCContrast = 0.1,
	CCSaturation = -0.3,
	CCTint = rgb(214, 232, 226),
	BloomIntensity = 0.6,
	BloomSize = 26,
	BloomThreshold = 1.15,
	SunRays = 0,
}

local MURK_BELOW = -120
local MURK = {
	Ambient = rgb(26, 32, 32),
	OutdoorAmbient = rgb(32, 40, 40),
	Exposure = -0.35,
	AtmDensity = 0.6,
	AtmColor = rgb(56, 66, 64),
	AtmDecay = rgb(22, 28, 28),
	AtmHaze = 3,
	CCSaturation = -0.4,
	CCTint = rgb(200, 220, 214),
	BloomIntensity = 0.75,
	BloomThreshold = 1.05,
}

-- Seconds to settle into a new zone's look.
local ZONE_FADE = 1.6

-- The depths: where the fade into black starts, how many sheets and how
-- far apart, how dark.
local FOG_TOP = -360
local FOG_LAYERS = 14
local FOG_SPACING = 5
local FOG_COLOR = rgb(10, 10, 13)
local FOG_SIZE = 2048

-- Down in the depths: black.
local DEPTHS = {
	Ambient = rgb(4, 4, 6),
	OutdoorAmbient = rgb(4, 4, 6),
	Exposure = -1.5,
	AtmDensity = 0.7,
	AtmOffset = 0,
	AtmColor = rgb(6, 6, 8),
	AtmDecay = rgb(2, 2, 3),
	AtmGlare = 0,
	AtmHaze = 3,
	SunRays = 0,
}

-- `a` with the values `b` has moved t of the way towards them.
local function mix(a, b, t)
	if t <= 0 then
		return a
	end
	local out = table.clone(a)
	for k, v in pairs(b) do
		local from = a[k]
		if from == nil then
			out[k] = v
		elseif typeof(v) == "Color3" then
			out[k] = from:Lerp(v, t)
		else
			out[k] = from + (v - from) * t
		end
	end
	return out
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
local UP = Vector3.new(0, 400, 0)

local function zoneAt(p)
	local S = SchoolConfig.SEA
	if p.X > S.x0 - 20 and p.X < S.x1 + 60 and p.Z > S.z0 - 20 and p.Z < S.z1 + 20 and p.Y < S.ceiling + 10 then
		return "sea"
	end
	local D = DAMP_ZONE
	if p.X > D.x0 and p.X < D.x1 and p.Z > D.z0 and p.Z < D.z1 and p.Y > D.y0 and p.Y < D.y1 then
		return if p.Y < MURK_BELOW then "murk" else "damp"
	end
	if workspace:Raycast(p, UP, terrainOnly) then
		return "underground"
	end
	return "city"
end

local atmosphere = Lighting:WaitForChild("Atmosphere")
local cc = Lighting:WaitForChild("SchoolColorCorrection")
local bloom = Lighting:WaitForChild("SchoolBloom")
local sunRays = Lighting:WaitForChild("SchoolSunRays")

local function apply(v)
	Lighting.Brightness = v.Brightness
	Lighting.Ambient = v.Ambient
	Lighting.OutdoorAmbient = v.OutdoorAmbient
	Lighting.ExposureCompensation = v.Exposure
	atmosphere.Density = v.AtmDensity
	atmosphere.Offset = v.AtmOffset
	atmosphere.Color = v.AtmColor
	atmosphere.Decay = v.AtmDecay
	atmosphere.Glare = v.AtmGlare
	atmosphere.Haze = v.AtmHaze
	cc.Brightness = v.CCBrightness
	cc.Contrast = v.CCContrast
	cc.Saturation = v.CCSaturation
	cc.TintColor = v.CCTint
	bloom.Intensity = v.BloomIntensity
	bloom.Size = v.BloomSize
	bloom.Threshold = v.BloomThreshold
	sunRays.Intensity = v.SunRays
	sunRays.Spread = 0.8
end

-- The fog sheets (made here, on this player's machine only).
local fogFolder = Instance.new("Folder")
fogFolder.Name = "DepthFog"
fogFolder.Parent = workspace
local fog = {}
local function sheet(y, transparency, size)
	local p = Instance.new("Part")
	p.Name = "FogSheet"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = FOG_COLOR
	p.Size = Vector3.new(size, 0.2, size)
	p.Transparency = transparency
	p.Position = Vector3.new(0, y, 0)
	p.Parent = fogFolder
	table.insert(fog, { part = p, y = y, transparency = transparency })
end
for i = 0, FOG_LAYERS - 1 do
	local t = i / (FOG_LAYERS - 1)
	sheet(FOG_TOP - i * FOG_SPACING, 0.93 - 0.35 * t, FOG_SIZE)
end
-- The floor under it all, wide enough to reach the haze.
local floorY = FOG_TOP - FOG_LAYERS * FOG_SPACING - 4
for dx = -1, 1 do
	for dz = -1, 1 do
		sheet(floorY, 0, FOG_SIZE)
		fog[#fog].offset = Vector3.new(dx * FOG_SIZE, 0, dz * FOG_SIZE)
	end
end
local fogShown = true
local function showFog(on)
	if on ~= fogShown then
		fogShown = on
		for _, f in ipairs(fog) do
			f.part.Transparency = if on then f.transparency else 1
		end
	end
end

-- Your own light: a soft warm glow that goes with you, coming up as it
-- gets dark (at night, underground, strongest in the Deep), so you can
-- always see the ground around you. Only you see yours.
local CARRIED_RANGE = 15
local carried
local function carriedLight()
	local char = Players.LocalPlayer.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return nil
	end
	if not carried or carried.Parent ~= head then
		carried = Instance.new("PointLight")
		carried.Name = "CarriedLight"
		carried.Range = CARRIED_RANGE
		carried.Shadows = false
		carried.Color = rgb(255, 216, 176)
		carried.Brightness = 0
		carried.Parent = head
	end
	return carried
end

local camera = workspace.CurrentCamera
local zone = "city"
local weight = { underground = 0, deep = 0, sea = 0, depths = 0, damp = 0, murk = 0 }
local sinceCheck = math.huge

RunService.RenderStepped:Connect(function(dt)
	camera = workspace.CurrentCamera
	sinceCheck += dt
	if sinceCheck > 0.25 and camera then
		sinceCheck = 0
		zone = zoneAt(camera.Focus.Position)
		if zone == "city" and camera.CFrame.Position.Y < floorY + 20 then
			zone = "depths"
		elseif zone == "underground" and camera.CFrame.Position.Y < DEEP_BELOW then
			zone = "deep"
		end
		showFog(zone == "city" or zone == "depths" or zone == "damp" or zone == "murk")
	end
	if camera then
		-- Keep the sheets under the camera (snapped, so they don't shimmer).
		local c = camera.CFrame.Position
		local sx, sz = math.floor(c.X / 64) * 64, math.floor(c.Z / 64) * 64
		for _, f in ipairs(fog) do
			local o = f.offset or Vector3.zero
			f.part.Position = Vector3.new(sx + o.X, f.y, sz + o.Z)
		end
	end
	for name, w in pairs(weight) do
		-- (The Deep sits on top of the underground look.)
		local target = if zone == name or (name == "underground" and zone == "deep") or (name == "damp" and zone == "murk") then 1 else 0
		weight[name] = if w < target then math.min(target, w + dt / ZONE_FADE) else math.max(target, w - dt / ZONE_FADE)
	end
	local clock = Lighting.ClockTime
	local v = mix(CITY_DAY, CITY_NIGHT, DayNightConfig.nightBlend(clock))
	v = mix(v, GOLDEN, DayNightConfig.warmBlend(clock) * 0.7 * (1 - DayNightConfig.nightBlend(clock)))
	v = mix(v, UNDERGROUND, weight.underground)
	v = mix(v, THE_DEEP, weight.deep)
	v = mix(v, SEA, weight.sea)
	v = mix(v, DAMP, weight.damp)
	v = mix(v, MURK, weight.murk)
	v = mix(v, DEPTHS, weight.depths)
	apply(v)
	local l = carriedLight()
	if l then
		local outside = DayNightConfig.nightBlend(clock) * 0.6 * (1 - weight.underground - weight.sea)
		l.Brightness = math.max(outside, weight.underground * 0.9 + weight.deep * 0.5, weight.sea * 0.6, weight.damp * 0.7 + weight.murk * 0.3)
	end
end)
