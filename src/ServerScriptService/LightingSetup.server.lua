local Lighting = game:GetService("Lighting")

-- The fixed parts of the lighting. Everything that changes with the time
-- of day or with where you are (brightness, ambient, the haze, colour
-- grading, bloom, sun rays) is set every frame on each client by
-- StarterPlayerScripts/LightingZones; this just makes sure the pieces
-- exist.
--
-- Lighting.Technology isn't script-writable; set it to Future in Studio's
-- Properties panel (Explorer > Lighting) and it saves with the place.
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.25

local function ensure(className, name)
	local existing = Lighting:FindFirstChild(name) or (className == "Atmosphere" and Lighting:FindFirstChildOfClass("Atmosphere"))
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

-- Haze so the megacity's towers fade with distance and the drops below
-- the roof edge vanish into nothing. (When an Atmosphere exists, Roblox
-- ignores the old FogEnd setting.)
ensure("Atmosphere", "Atmosphere")
ensure("BloomEffect", "SchoolBloom")
ensure("ColorCorrectionEffect", "SchoolColorCorrection")
ensure("SunRaysEffect", "SchoolSunRays")

-- A low, heavy overcast to go with the rain: dynamic clouds, lit by the
-- sun as it moves.
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover = 0.78
clouds.Density = 0.6
clouds.Color = Color3.fromRGB(176, 176, 182)
clouds.Parent = workspace.Terrain
