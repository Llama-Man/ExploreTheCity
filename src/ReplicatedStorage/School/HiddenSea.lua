-- The hidden sea, behind the vault door at the bottom of the facility.
--
-- Past the vault a round shaft corkscrews down through the rock to a short
-- tunnel, which comes out high on the wall of a vast flooded hall inside
-- the building's body, under the courtyard: a dark still sea between
-- colossal concrete pillars that hold up the courtyard far overhead.
-- You step out onto a platform in near darkness, with only a faint glow
-- coming up from the water, and then the floodlights come on, pillar by
-- pillar, marching away from you (VaultController does the switching).
--
-- In the water lies the rest of the whale's pod: a great skeleton on a
-- bank with its ribs breaking the surface, another on the seabed with its
-- calf, and a fishing boat sunk on its side with its mast still standing
-- out of the water. A long straight stair runs down the wall to a jetty
-- at the waterline.
--
-- The hall's walls, floor and ceiling are the building's body
-- (Megastructure leaves the void, per Config.SEA); this fills it.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local WhaleSkeleton = require(script.Parent.WhaleSkeleton)
local RouteCheck = require(script.Parent.RouteCheck)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Metal, Plate, Smooth, Concrete, Neon, Wood, Rust = Enum.Material.Metal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Neon, Enum.Material.Wood, Enum.Material.CorrodedMetal

local terrain = workspace.Terrain
local AIR, WATER, ROCK = Enum.Material.Air, Enum.Material.Water, Enum.Material.Rock
local S = Config.SEA

local STEEL = Color3.fromRGB(96, 98, 100)
local DARK = Color3.fromRGB(58, 60, 62)
local PILLAR = Color3.fromRGB(78, 80, 80)
local SAFETY_YELLOW = Color3.fromRGB(214, 176, 40)
local RUST_COLOR = Color3.fromRGB(116, 76, 48)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local SHAFT_R = 7

local HiddenSea = {}

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function lamp(parent, at, color, range, brightness, flicker)
	local bulb = part(parent, "Lamp", Vector3.new(0.8, 0.8, 0.8), at, Neon, color)
	bulb.Shape = Enum.PartType.Ball
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = bulb
	if flicker then
		bulb:AddTag("FlickerLight")
	end
	return bulb
end

-- A floodlight that stays dark until the reveal switches it on, in order
-- of distance from `origin` (VaultController reads the tag and order).
local function floodlight(parent, at, aim, origin)
	local housing = part(parent, "FloodHousing", Vector3.new(2.4, 1.6, 2.4), CFrame.lookAt(at, at + aim), Metal, DARK)
	housing.CanCollide = false
	local lens = part(parent, "FloodLens", Vector3.new(2, 1.3, 0.2), CFrame.lookAt(at + aim.Unit * 1.25, at + aim * 2), Smooth, Color3.fromRGB(70, 70, 68))
	lens.CanCollide = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 70
	light.Range = 80
	light.Brightness = 3
	light.Color = Color3.fromRGB(255, 240, 214)
	light.Enabled = false
	light.Parent = lens
	lens:AddTag("SeaLight")
	lens:SetAttribute("Order", (at - origin).Magnitude)
	return lens
end

-- ===== The way down =====

-- Round shaft from the vault down to the tunnel: steel wall panels (open
-- towards the vault at the top and towards the tunnel at the bottom), a
-- spiral stair round a central column.
local function shaft(parent, C, doorDir, rng)
	local m = model(parent, "VaultShaft")
	local top, bottom = C.Y, S.entryY
	local doorAng = math.atan2(doorDir.Z, doorDir.X)
	local westAng = math.pi
	local function angleOff(a, b)
		local d = (a - b) % (math.pi * 2)
		return math.min(d, math.pi * 2 - d)
	end
	-- Walls, in three bands.
	local panels = 24
	local width = 2 * math.pi * (SHAFT_R + 0.5) / panels + 0.25
	local bands = { { bottom - 1, bottom + 10, "bottom" }, { bottom + 10, top, "middle" }, { top, top + 14, "top" } }
	for k = 0, panels - 1 do
		local a = (k + 0.5) / panels * math.pi * 2
		local radial = Vector3.new(math.cos(a), 0, math.sin(a))
		local tangent = Vector3.new(-radial.Z, 0, radial.X)
		for _, band in ipairs(bands) do
			local open = (band[3] == "top" and angleOff(a, doorAng) < math.rad(62)) or (band[3] == "bottom" and angleOff(a, westAng) < math.rad(38))
			if not open then
				local h = band[2] - band[1]
				local pos = Vector3.new(C.X, (band[1] + band[2]) / 2, C.Z) + radial * (SHAFT_R + 0.5)
				part(m, "ShaftWall", Vector3.new(width, h, 1), CFrame.fromMatrix(pos, tangent, Vector3.yAxis), Metal, jitter(Color3.fromRGB(80, 84, 86), rng, 0.04))
			end
		end
	end
	-- Trim rings round the wall (hollow: segments hugging the wall face,
	-- leaving the stair clear).
	for _, y in ipairs({ bottom + 10, top - 14, top + 13.5 }) do
		for k = 0, panels - 1 do
			local a = (k + 0.5) / panels * math.pi * 2
			local radial = Vector3.new(math.cos(a), 0, math.sin(a))
			local tangent = Vector3.new(-radial.Z, 0, radial.X)
			part(m, "ShaftRing", Vector3.new(width, 0.6, 0.5), CFrame.fromMatrix(Vector3.new(C.X, y, C.Z) + radial * (SHAFT_R - 0.15), tangent, Vector3.yAxis), Metal, DARK)
		end
	end
	cylinder(m, "ShaftCap", 1, SHAFT_R * 2 + 2, CFrame.new(C.X, top + 14.5, C.Z) * UPRIGHT, Metal, DARK)
	cylinder(m, "ShaftFloor", 1, SHAFT_R * 2 + 1, CFrame.new(C.X, bottom - 0.5, C.Z) * UPRIGHT, Plate, STEEL)
	cylinder(m, "ShaftColumn", top + 14 - bottom, 2.6, CFrame.new(C.X, (top + 14 + bottom) / 2, C.Z) * UPRIGHT, Metal, Color3.fromRGB(70, 72, 74))

	-- The spiral: starts just past the top landing (which faces the door)
	-- and winds down round the column.
	local steps = 46
	local rise = (top - bottom) / steps
	local dAng = math.rad(16)
	local a0 = doorAng + math.rad(100)
	local prevRail
	for i = 1, steps do
		local a = a0 + (i - 1) * dAng
		local radial = Vector3.new(math.cos(a), 0, math.sin(a))
		local y = top - i * rise
		local cf = CFrame.fromMatrix(Vector3.new(C.X, y - 0.25, C.Z) + radial * 4.15, radial, Vector3.yAxis)
		part(m, "SpiralStep", Vector3.new(5.7, 0.5, 2.1), cf, Plate, STEEL)
		part(m, "StepNosing", Vector3.new(5.7, 0.06, 0.25), cf * CFrame.new(0, 0.28, 0.95), Smooth, SAFETY_YELLOW)
		local rail = Vector3.new(C.X, y + 3, C.Z) + radial * (SHAFT_R - 0.4)
		if prevRail then
			rod(m, "ShaftRail", prevRail, rail, 0.22, Metal, SAFETY_YELLOW)
		end
		prevRail = rail
	end
	for k = 0, 3 do
		local a = doorAng + math.rad(60 + k * 95)
		local y = top - 4 - k * 10
		lamp(m, Vector3.new(C.X, y, C.Z) + Vector3.new(math.cos(a), 0, math.sin(a)) * (SHAFT_R - 0.5), Color3.fromRGB(255, 196, 130), 16, 0.9, k == 2)
	end
end

-- Tunnel from the foot of the shaft west through the wall, out onto the
-- platform high over the water.
local function tunnel(parent, C, rng)
	local m = model(parent, "SeaTunnel")
	local y, z = S.entryY, C.Z
	local x0, x1 = S.x1 - 1, C.X - SHAFT_R + 0.5
	box(m, "TunnelFloor", x0, x1, y - 1, y, z - 4, z + 4, Concrete, Color3.fromRGB(96, 94, 90))
	box(m, "TunnelCeiling", x0, x1, y + 10, y + 11, z - 5, z + 5, Concrete, Color3.fromRGB(70, 70, 68))
	for _, s in ipairs({ -1, 1 }) do
		box(m, "TunnelWall", x0, x1, y, y + 10, z + s * 4, z + s * 5, Concrete, Color3.fromRGB(84, 84, 80))
	end
	for x = x0 + 3, x1 - 1, 6 do
		box(m, "TunnelRib", x - 0.4, x + 0.4, y, y + 10, z - 4, z - 3.4, Metal, DARK)
		box(m, "TunnelRib", x - 0.4, x + 0.4, y, y + 10, z + 3.4, z + 4, Metal, DARK)
		box(m, "TunnelRib", x - 0.4, x + 0.4, y + 9.4, y + 10, z - 4, z + 4, Metal, DARK)
	end
	lamp(m, Vector3.new(x1 - 4, y + 9, z), Color3.fromRGB(255, 196, 130), 14, 0.7, false)
	lamp(m, Vector3.new((x0 + x1) / 2, y + 9, z), Color3.fromRGB(255, 196, 130), 14, 0.6, true)
	RouteCheck.add("vault tunnel", { Vector3.new(C.X, y, z), Vector3.new(S.x1 - 16, y, z) }, 3, 8)
end

-- The platform where the hall opens up in front of you, and the trigger
-- that brings the lights up.
local function platform(parent, C, rng)
	local m = model(parent, "SeaPlatform")
	local y, z = S.entryY, C.Z
	local x0, x1 = S.x1 - 20, S.x1
	box(m, "PlatformDeck", x0, x1, y - 0.6, y, z - 8, z + 8, Plate, STEEL)
	for k = 0, 9 do
		box(m, "HazardEdge", x0, x0 + 0.5, y, y + 0.05, z - 8 + k * 1.6, z - 7.2 + k * 1.6, Smooth, if k % 2 == 0 then SAFETY_YELLOW else Color3.fromRGB(26, 26, 28))
	end
	-- Struts back to the wall below.
	for _, s in ipairs({ -6, 6 }) do
		rod(m, "PlatformStrut", Vector3.new(x0 + 2, y - 0.6, z + s), Vector3.new(x1, y - 16, z + s), 0.9, Metal, DARK)
		box(m, "PlatformGirder", x0, x1, y - 1.6, y - 0.6, z + s - 0.4, z + s + 0.4, Metal, DARK)
	end
	-- Railing: along the front and the south side (the north side opens
	-- onto the stair down).
	local function railRun(a, b)
		rod(m, "Rail", a + Vector3.new(0, 3.4, 0), b + Vector3.new(0, 3.4, 0), 0.3, Metal, SAFETY_YELLOW)
		rod(m, "Rail", a + Vector3.new(0, 1.7, 0), b + Vector3.new(0, 1.7, 0), 0.2, Metal, SAFETY_YELLOW)
		local n = math.max(1, math.floor((b - a).Magnitude / 4))
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			rod(m, "RailPost", p, p + Vector3.new(0, 3.4, 0), 0.2, Metal, SAFETY_YELLOW)
		end
	end
	railRun(Vector3.new(x0 + 0.3, y, z - 7.7), Vector3.new(x0 + 0.3, y, z + 7.7))
	railRun(Vector3.new(x0 + 0.3, y, z - 7.7), Vector3.new(x1, y, z - 7.7))
	railRun(Vector3.new(x0 + 0.3, y, z + 7.7), Vector3.new(x1 - 7, y, z + 7.7))
	lamp(m, Vector3.new(x1 - 0.8, y + 8, z - 5), Color3.fromRGB(230, 50, 40), 18, 0.8, true)

	local trigger = part(m, "SeaRevealTrigger", Vector3.new(12, 8, 14), Vector3.new(x0 + 7, y + 4, z), Smooth, Color3.new(1, 1, 1))
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.CastShadow = false
	trigger:AddTag("SeaRevealTrigger")
end

-- Long straight stair down the east wall from the platform to the jetty.
local function stairDown(parent, C, rng)
	local m = model(parent, "SeaStair")
	local x0, x1 = S.x1 - 6, S.x1
	local yTop, yEnd = S.entryY, S.water + 1.5
	local z0 = C.Z + 8
	local steps = math.floor(yTop - yEnd + 0.5)
	local rise = (yTop - yEnd) / steps
	local run = 1.2
	for i = 1, steps do
		local top = yTop - i * rise
		local za, zb = z0 + (i - 1) * run, z0 + i * run
		box(m, "Step", x0, x1, top - 1.4, top, za, zb + 0.02, Plate, jitter(STEEL, rng, 0.04))
		box(m, "StepNosing", x0, x1, top, top + 0.05, zb - 0.25, zb, Smooth, SAFETY_YELLOW)
	end
	local zEnd = z0 + steps * run
	local function at(zz, yy)
		return Vector3.new(x0 + 0.3, yy, zz)
	end
	rod(m, "StairRail", at(z0, yTop + 3.4), at(zEnd, yEnd + 3.4), 0.3, Metal, SAFETY_YELLOW)
	rod(m, "StairStringer", Vector3.new(x0, yTop - 1.6, z0), Vector3.new(x0, yEnd - 1.6, zEnd), 0.8, Metal, DARK)
	for i = 0, steps, 10 do
		local zz = z0 + i * run
		local yy = yTop - i * rise
		rod(m, "RailPost", at(zz, yy), at(zz, yy + 3.4), 0.2, Metal, SAFETY_YELLOW)
		rod(m, "WallBracket", Vector3.new(x0, yy - 1.5, zz), Vector3.new(x1, yy - 5, zz), 0.4, Metal, DARK)
	end
	RouteCheck.add("sea stair", { Vector3.new((x0 + x1) / 2, yTop, z0), Vector3.new((x0 + x1) / 2, yEnd, zEnd) }, 2, 7)
	return zEnd
end

-- A rowboat, the right way up (moored) or upside down (capsized).
local function rowboat(parent, cf, rng, capsized)
	local m = model(parent, "Rowboat")
	local color = jitter(pick({ Color3.fromRGB(60, 90, 120), Color3.fromRGB(150, 60, 44), Color3.fromRGB(200, 196, 180) }, rng), rng, 0.06)
	local flip = if capsized then CFrame.Angles(0, 0, math.pi) else CFrame.identity
	local base = cf * flip
	part(m, "BoatBottom", Vector3.new(11, 0.4, 3.4), base * CFrame.new(0, -0.9, 0), Wood, color)
	for _, s in ipairs({ -1, 1 }) do
		part(m, "BoatSide", Vector3.new(12, 1.8, 0.3), base * CFrame.new(0, 0, s * 1.9) * CFrame.Angles(s * math.rad(18), 0, 0), Wood, color)
	end
	part(m, "BoatBow", Vector3.new(0.3, 1.8, 3.6), base * CFrame.new(6, 0, 0), Wood, color)
	part(m, "BoatStern", Vector3.new(0.3, 1.8, 3.8), base * CFrame.new(-6, 0, 0), Wood, color)
	if not capsized then
		for _, x in ipairs({ -2.5, 1.5 }) do
			part(m, "BoatSeat", Vector3.new(1, 0.25, 3.6), base * CFrame.new(x, -0.1, 0), Wood, Color3.fromRGB(150, 120, 84))
		end
		part(m, "Oar", Vector3.new(7, 0.2, 0.4), base * CFrame.new(0, 0, 0.8) * CFrame.Angles(0, 0.2, 0.1), Wood, Color3.fromRGB(150, 120, 84))
	end
end

-- A small fishing boat sunk on its side, mast sticking out of the water.
local function sunkenBoat(parent, cf, rng)
	local m = model(parent, "SunkenBoat")
	local hull = jitter(Color3.fromRGB(56, 70, 84), rng, 0.08)
	part(m, "Keel", Vector3.new(40, 1.6, 2), cf * CFrame.new(0, -3.4, 0), Metal, RUST_COLOR)
	part(m, "HullBottom", Vector3.new(36, 0.8, 10), cf * CFrame.new(-1, -3, 0), Rust, hull)
	for _, s in ipairs({ -1, 1 }) do
		part(m, "HullSide", Vector3.new(38, 7, 0.8), cf * CFrame.new(-1, 0.4, s * 5.6) * CFrame.Angles(s * math.rad(12), 0, 0), Rust, hull)
		part(m, "BowSide", Vector3.new(9, 7, 0.8), cf * CFrame.new(21.5, 0.4, s * 2.8) * CFrame.Angles(s * math.rad(12), s * math.rad(-32), 0), Rust, hull)
	end
	part(m, "Transom", Vector3.new(0.8, 7, 12), cf * CFrame.new(-20, 0.4, 0), Rust, hull)
	part(m, "Deck", Vector3.new(24, 0.5, 11), cf * CFrame.new(-6, 3.8, 0), Wood, Color3.fromRGB(96, 80, 60))
	part(m, "Wheelhouse", Vector3.new(8, 6, 8), cf * CFrame.new(4, 7, 0), Metal, Color3.fromRGB(200, 196, 184))
	for _, s in ipairs({ -1, 1 }) do
		local w = part(m, "WheelhouseWindow", Vector3.new(6, 1.6, 0.1), cf * CFrame.new(4, 8.4, s * 4.02), Enum.Material.Glass, Color3.fromRGB(30, 40, 44))
		w.Transparency = 0.3
	end
	cylinder(m, "Mast", 44, 0.9, cf * CFrame.new(-8, 26, 0) * UPRIGHT, Metal, RUST_COLOR)
	cylinder(m, "Boom", 18, 0.5, cf * CFrame.new(-2, 16, 0) * CFrame.Angles(0, 0, math.rad(-20)), Metal, RUST_COLOR)
	part(m, "MastLight", Vector3.new(0.8, 0.8, 0.8), cf * CFrame.new(-8, 48, 0), Smooth, Color3.fromRGB(180, 50, 40))
end

-- ===== The hall =====

function HiddenSea.build(parent, C, doorDir, rng)
	local root = model(parent, "HiddenSea")
	local origin = Vector3.new(S.x1 - 10, S.entryY + 3, C.Z) -- where you first see it

	-- ---- Terrain: the way down, then the sea ----
	terrain:FillBlock(CFrame.new(C.X, (S.entryY - 2 + C.Y + 16) / 2, C.Z), Vector3.new(SHAFT_R * 2 + 6, C.Y + 18 - S.entryY, SHAFT_R * 2 + 6), AIR)
	terrain:FillBlock(CFrame.new((S.x1 + C.X) / 2, S.entryY + 6, C.Z), Vector3.new(C.X - S.x1 + 4, 16, 16), AIR)

	-- Water over a rock bed, the bed lumpy with sand and mud, a deep trench
	-- down the middle, a bank for the big whale to lie on.
	local seed = rng:NextNumber(0, 1000)
	terrain:FillBlock(CFrame.new((S.x0 + S.x1) / 2, (S.bed - 60 + S.water) / 2, (S.z0 + S.z1) / 2), Vector3.new(S.x1 - S.x0, S.water - (S.bed - 60), S.z1 - S.z0), WATER)
	terrain:FillBlock(CFrame.new((S.x0 + S.x1) / 2, (S.floor + S.bed - 40) / 2, (S.z0 + S.z1) / 2), Vector3.new(S.x1 - S.x0, S.bed - 40 - S.floor, S.z1 - S.z0), ROCK)
	local trenchZ = (S.z0 + S.z1) / 2 + 20
	for x = S.x0 + 6, S.x1 - 6, 13 do
		for z = S.z0 + 6, S.z1 - 6, 13 do
			local h = S.bed + math.noise(x / 60, z / 60, seed) * 7 + rng:NextNumber(-2, 2)
			local trench = math.max(0, 1 - math.abs(z - trenchZ) / 40)
			h -= trench * 40
			local r = rng:NextNumber(8, 13)
			local c = Vector3.new(x + rng:NextNumber(-4, 4), h - r, z + rng:NextNumber(-4, 4))
			terrain:FillBlock(CFrame.new(c.X, (S.bed - 40 + c.Y) / 2, c.Z), Vector3.new(r * 1.3, math.max(1, c.Y - (S.bed - 40)), r * 1.3), ROCK)
			local roll = rng:NextNumber()
			terrain:FillBall(c, r, if roll < 0.45 then Enum.Material.Sand elseif roll < 0.7 then Enum.Material.Mud else ROCK)
		end
	end
	task.wait()

	-- ---- The pod ----
	local whales = {
		{ at = Vector3.new(250, S.water - 16, 110), scale = 1.1 }, -- on the bank, ribs out of the water
		{ at = Vector3.new(130, S.bed - 1, 232), scale = 0.9 },
		{ at = Vector3.new(196, S.bed - 1, 266), scale = 0.5 }, -- the calf
	}
	local wreckAt = Vector3.new(80, S.bed + 2, 120)
	for k, w in ipairs(whales) do
		-- Level ground under each (the bank rises out of the trench).
		local r = 58 * w.scale
		terrain:FillCylinder(CFrame.new(w.at - Vector3.new(0, 10, 0)), 20, r, Enum.Material.Sand)
		terrain:FillBlock(CFrame.new(w.at + Vector3.new(0, 6, 0)), Vector3.new(r * 2, 12, r * 2), WATER)
		WhaleSkeleton.build(root, w.at, rng, {
			scale = w.scale,
			phase = rng:NextNumber(0, math.pi * 2),
			sweep = math.rad(rng:NextNumber(110, 170)),
		})
		task.wait()
		-- A faint glow from the deep around each, to see by before the
		-- lights come up; and specks of something living on the bones.
		lamp(root, w.at + Vector3.new(rng:NextNumber(-10, 10), 4, rng:NextNumber(-10, 10)), Color3.fromRGB(70, 200, 210), 50 * w.scale + 20, 1.1, false).Transparency = 0.6
		for _ = 1, math.floor(18 * w.scale) do
			local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(4, r)
			local speck = part(root, "Glow", Vector3.one * rng:NextNumber(0.3, 0.9), w.at + Vector3.new(math.cos(a) * d, rng:NextNumber(0.2, 2), math.sin(a) * d), Neon, pick({ Color3.fromRGB(80, 230, 220), Color3.fromRGB(120, 255, 170), Color3.fromRGB(60, 160, 255) }, rng))
			speck.Shape = Enum.PartType.Ball
			speck.CanCollide = false
			speck.Transparency = 0.3
		end
	end
	-- Lying over on its side, mast still clearing the surface.
	sunkenBoat(root, CFrame.new(wreckAt + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(20, 60)), 0) * CFrame.Angles(math.rad(35), 0, math.rad(8)), rng)

	-- ---- Pillars, beams, lights ----
	local xs, zs = { 80, 150, 220, 290, 360 }, { 75, 135, 195, 255 }
	local function clearOfPod(x, z)
		for _, w in ipairs(whales) do
			if (Vector3.new(x, 0, z) - Vector3.new(w.at.X, 0, w.at.Z)).Magnitude < 58 * w.scale + 14 then
				return false
			end
		end
		return (Vector3.new(x, 0, z) - Vector3.new(wreckAt.X, 0, wreckAt.Z)).Magnitude > 30
	end
	for _, z in ipairs(zs) do
		box(root, "CeilingBeam", S.x0, S.x1, S.ceiling - 8, S.ceiling, z - 5, z + 5, Concrete, PILLAR)
	end
	for _, x in ipairs(xs) do
		for _, z in ipairs(zs) do
			if clearOfPod(x, z) then
				local pillar = jitter(PILLAR, rng, 0.05)
				box(root, "SeaPillar", x - 8, x + 8, S.floor, S.ceiling - 8, z - 8, z + 8, Concrete, pillar)
				for _, y in ipairs({ -390, -440, -490 }) do
					box(root, "PillarBand", x - 8.3, x + 8.3, y - 0.8, y + 0.8, z - 8.3, z + 8.3, Concrete, Color3.fromRGB(46, 48, 48))
				end
				-- Tide mark: where the water has stood for years.
				box(root, "Tidemark", x - 8.2, x + 8.2, S.water - 3, S.water + rng:NextNumber(6, 12), z - 8.2, z + 8.2, Concrete, Color3.fromRGB(44, 58, 52))
				for _, face in ipairs({ -1, 1 }) do
					floodlight(root, Vector3.new(x + face * 9.4, -392, z), Vector3.new(face, -0.9, 0), origin)
				end
			end
		end
	end
	-- Floods high on the far walls, last to come on.
	for _, z in ipairs({ 90, 165, 240 }) do
		floodlight(root, Vector3.new(S.x0 + 1.5, -380, z), Vector3.new(1, -0.5, 0), origin)
	end
	for _, x in ipairs({ 120, 260 }) do
		floodlight(root, Vector3.new(x, -380, S.z0 + 1.5), Vector3.new(0, -0.6, 1), origin)
		floodlight(root, Vector3.new(x, -380, S.z1 - 1.5), Vector3.new(0, -0.6, -1), origin)
	end

	-- Chains hanging from the beams down into the water.
	for _ = 1, 7 do
		local x, z = rng:NextNumber(S.x0 + 30, S.x1 - 40), pick(zs, rng) + rng:NextNumber(-3, 3)
		local bottom = S.water - rng:NextNumber(-20, 10)
		rod(root, "HangingChain", Vector3.new(x, S.ceiling - 8, z), Vector3.new(x + rng:NextNumber(-2, 2), bottom, z + rng:NextNumber(-2, 2)), 0.6, Rust, RUST_COLOR)
		if bottom > S.water then
			part(root, "ChainHook", Vector3.new(1.6, 2.4, 0.4), Vector3.new(x, bottom - 1, z), Rust, RUST_COLOR)
		end
	end

	-- Flotsam.
	for _ = 1, 10 do
		local p = Vector3.new(rng:NextNumber(S.x0 + 20, S.x1 - 30), S.water + 0.1, rng:NextNumber(S.z0 + 20, S.z1 - 20))
		if rng:NextNumber() < 0.6 then
			part(root, "FloatingPlank", Vector3.new(rng:NextNumber(4, 9), 0.4, 1), CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Wood, jitter(Color3.fromRGB(110, 90, 66), rng, 0.1))
		else
			cylinder(root, "FloatingDrum", 3, 2, CFrame.new(p + Vector3.new(0, 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(1.2, 1.9)), Metal, pick({ Color3.fromRGB(40, 70, 150), Color3.fromRGB(200, 160, 40), Color3.fromRGB(150, 40, 30) }, rng))
		end
	end
	local buoy = part(root, "Buoy", Vector3.new(3, 3, 3), Vector3.new(320, S.water + 0.6, 210), Smooth, Color3.fromRGB(200, 50, 40))
	buoy.Shape = Enum.PartType.Ball
	rod(root, "BuoyPole", Vector3.new(320, S.water + 1.5, 210), Vector3.new(320, S.water + 6, 210), 0.3, Metal, STEEL)

	-- ---- The way down and in ----
	shaft(root, C, doorDir, rng)
	tunnel(root, C, rng)
	platform(root, C, rng)
	local zEnd = stairDown(root, C, rng)

	-- Jetty at the foot of the stair, out along the waterline.
	local jetty = model(root, "Jetty")
	local jz0, jz1, jy = zEnd - 1, zEnd + 7, S.water + 1.5
	for k = 0, 9 do
		local xa = S.x1 - k * 8
		box(jetty, "JettyDeck", xa - 8, xa, jy - 0.5, jy, jz0, jz1, Wood, jitter(Color3.fromRGB(110, 90, 66), rng, 0.08))
		for _, z in ipairs({ jz0 + 0.5, jz1 - 0.5 }) do
			cylinder(jetty, "JettyPile", jy - S.bed + 8, 0.9, CFrame.new(xa - 8, (jy + S.bed - 8) / 2, z) * UPRIGHT, Wood, Color3.fromRGB(70, 58, 44))
		end
	end
	for _, x in ipairs({ S.x1 - 30, S.x1 - 62 }) do
		cylinder(jetty, "Bollard", 1.2, 1.2, CFrame.new(x, jy + 0.6, jz1 - 0.8) * UPRIGHT, Metal, DARK)
	end
	rowboat(jetty, CFrame.new(S.x1 - 46, S.water + 0.9, jz1 + 3.5) * CFrame.Angles(0, math.rad(rng:NextNumber(-8, 8)), math.rad(rng:NextNumber(-3, 3))), rng, false)
	rod(jetty, "MooringLine", Vector3.new(S.x1 - 46 + 6, S.water + 1.2, jz1 + 3), Vector3.new(S.x1 - 30, jy + 1, jz1 - 0.8), 0.15, Enum.Material.Fabric, Color3.fromRGB(190, 180, 150))
	rowboat(root, CFrame.new(300, S.water + 0.7, 150) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rng, true)
	-- A lamp post at the jetty's end: the last light on.
	rod(jetty, "JettyLampPost", Vector3.new(S.x1 - 78, jy, jz0 + 1), Vector3.new(S.x1 - 78, jy + 10, jz0 + 1), 0.4, Metal, DARK)
	floodlight(jetty, Vector3.new(S.x1 - 78, jy + 10.5, jz0 + 1), Vector3.new(-0.3, -1, 0.2), origin + Vector3.new(0, 0, -400))

	-- ---- The water ----
	terrain.WaterColor = Color3.fromRGB(16, 52, 58)
	terrain.WaterTransparency = 0.85
	terrain.WaterReflectance = 0.55
	terrain.WaterWaveSize = 0.05
	terrain.WaterWaveSpeed = 2
end

return HiddenSea
