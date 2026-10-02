-- 屋上遊園地: the department store's rooftop amusement park, the tower's
-- crown, high above the city. You come up the emergency stair and out
-- under a lit entrance arch into:
--   a great truss Ferris wheel (the tallest thing for a long way, its
--     rim picked out in bulbs, one gondola fallen and smashed on the roof),
--   a carousel with a mirrored drum, a scalloped canopy and two rings of
--     painted horses,
--   a swing ride, its chairs hanging still on long chains,
--   a little dragon coaster on an elevated loop along the south edge,
--   a model steam train round the fountain,
--   the fountain itself, rainwater in its basin, the store's mascot moon
--     rabbit on top holding up a glowing crescent moon,
--   a row of coin rides under a striped awning, a hero-show stage,
--     snack and balloon carts, benches, lamp posts, a rooftop shrine,
--   festoons of bulbs strung on poles over all of it,
-- with weeds and puddles and trees seeded in the planters, and the
-- store's great sign along the south edge facing back at the school.
--
-- Built by DepartmentStore with the tower's geometry (Park.build).

local BuildUtil = require(script.Parent.BuildUtil)
local TunnelProps = require(script.Parent.TunnelProps)
local Clutter = require(script.Parent.RooftopClutter)
local Fixtures = require(script.Parent.StoreFixtures)

local part, cylinder, model, jitter, pick, darken, place = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken, BuildUtil.place
local rod, upright, deco, label = Fixtures.rod, Fixtures.upright, Fixtures.deco, Fixtures.label
local Metal, Smooth, Concrete, Neon, Wood, Fabric, Glass = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Neon, Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.Glass
local ellipsoid = TunnelProps.ellipsoid
local rgb = Color3.fromRGB

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local FACING_Z = CFrame.Angles(0, math.pi / 2, 0)
local STEEL = rgb(110, 112, 114)
local DARK = rgb(40, 40, 42)
local GOLD = rgb(206, 170, 80)
local WHITE = rgb(238, 236, 230)
local CREAM = rgb(240, 230, 210)
local RED = rgb(200, 56, 52)
local BULB_WARM = rgb(255, 214, 150)
local BULB_DEAD = rgb(150, 146, 136)
local PASTELS = { rgb(220, 110, 100), rgb(100, 160, 210), rgb(240, 206, 90), rgb(130, 196, 130), rgb(230, 160, 196), rgb(170, 140, 210) }

local Park = {}

local ROOF, G -- the roof level and the tower's geometry, set by build
local lightsLeft = 0 -- a budget of real lights across the whole park
local busy = {} -- circles {x, z, r} the rides occupy (kept clear of weeds)

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

local function occupy(x, z, r)
	table.insert(busy, { x = x, z = z, r = r })
end

-- A bulb, lit or long dead; a few of the lit ones cast real light.
local function bulb(parent, pos, size, litChance, rng, withLight)
	local lit = rng:NextNumber() < litChance
	local b = part(parent, "Bulb", Vector3.one * size, pos, if lit then Neon else Smooth, if lit then BULB_WARM else BULB_DEAD)
	b.Shape = Enum.PartType.Ball
	b.CanCollide = false
	if lit and withLight and lightsLeft > 0 then
		lightsLeft -= 1
		local light = Instance.new("PointLight")
		light.Range = 16
		light.Brightness = 1
		light.Color = BULB_WARM
		light.Parent = b
		if rng:NextNumber() < 0.3 then
			b:AddTag("FlickerLight")
		end
	end
	return b
end

-- ===== The Ferris wheel =====

-- One gondola, its cabin frame `cab` (centre of the cabin, upright).
local function gondola(w, cab, color, num)
	part(w, "GondolaLower", Vector3.new(3, 1.2, 2.8), cab * CFrame.new(0, -0.6, 0), Metal, color)
	part(w, "GondolaGlass", Vector3.new(2.9, 1.3, 2.7), cab * CFrame.new(0, 0.65, 0), Glass, rgb(70, 80, 86)).Transparency = 0.45
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(w, "GondolaPost", Vector3.new(0.18, 1.3, 0.18), cab * CFrame.new(sx * 1.42, 0.65, sz * 1.32), Metal, color)
		end
	end
	part(w, "GondolaRoof", Vector3.new(3.3, 0.35, 3.1), cab * CFrame.new(0, 1.45, 0), Metal, darken(color, 0.85))
	deco(ellipsoid(w, "GondolaCap", Vector3.new(2.4, 0.6, 2.2), cab * CFrame.new(0, 1.65, 0), Metal, darken(color, 0.85)))
	label(w, cab * CFrame.new(0, -0.6, -1.42), Vector3.new(0.9, 0.7, 0.04), Enum.NormalId.Front, tostring(num), WHITE, darken(color, 0.5))
end

local function ferrisWheel(m, c, R, rng)
	local w = model(m, "FerrisWheel")
	local frame = rgb(226, 224, 216)
	local hub = Vector3.new(c.X, ROOF + R + 6.5, c.Z)
	local HALF = 1.8 -- the two rims sit at z +-HALF
	occupy(c.X, c.Z, R * 0.6 + 2)
	-- A braced A-frame tower each side.
	for _, s in ipairs({ -1, 1 }) do
		local top = hub + Vector3.new(0, 0, s * (HALF + 1.6))
		local feet = {}
		for _, dx in ipairs({ -1, 1 }) do
			local foot = Vector3.new(c.X + dx * R * 0.6, ROOF, c.Z + s * (HALF + 4.5))
			table.insert(feet, foot)
			rod(w, "TowerLeg", foot, top, 1.1, Metal, frame)
			box(w, "TowerFoot", foot.X - 1.2, foot.X + 1.2, ROOF, ROOF + 0.5, foot.Z - 1.2, foot.Z + 1.2, Concrete, rgb(140, 136, 128))
		end
		for k = 1, 3 do
			local a, b = feet[1]:Lerp(top, k / 4), feet[2]:Lerp(top, k / 4)
			rod(w, "TowerBrace", a, b, 0.5, Metal, frame)
			rod(w, "TowerBrace", a, feet[2]:Lerp(top, (k + 1) / 4), 0.35, Metal, frame)
		end
	end
	cylinder(w, "Axle", (HALF + 1.8) * 2, 1.6, CFrame.new(hub) * FACING_Z, Metal, STEEL)
	-- The hub: a red plate with the store's crescent moon on it.
	cylinder(w, "HubPlate", 0.4, 6, CFrame.new(hub + Vector3.new(0, 0, -HALF - 0.6)) * FACING_Z, Metal, RED)
	cylinder(w, "HubMoon", 0.1, 4.2, CFrame.new(hub + Vector3.new(0, 0, -HALF - 0.85)) * FACING_Z, Neon, rgb(240, 226, 170))
	cylinder(w, "HubMoonShadow", 0.1, 3.8, CFrame.new(hub + Vector3.new(0.95, 0.4, -HALF - 0.92)) * FACING_Z, Metal, RED)
	-- Rims, an inner ring, the truss between them, spokes.
	local N, inner = 40, R * 0.7
	local outerPts, innerPts = {}, {}
	for _, s in ipairs({ -1, 1 }) do
		outerPts[s], innerPts[s] = {}, {}
		for k = 0, N - 1 do
			local a = k / N * math.pi * 2
			outerPts[s][k] = hub + Vector3.new(math.cos(a) * R, math.sin(a) * R, s * HALF)
		end
		for k = 0, N / 2 - 1 do
			local a = k / (N / 2) * math.pi * 2
			innerPts[s][k] = hub + Vector3.new(math.cos(a) * inner, math.sin(a) * inner, s * HALF)
		end
		for k = 0, N - 1 do
			rod(w, "Rim", outerPts[s][k], outerPts[s][(k + 1) % N], 0.55, Metal, frame)
		end
		for k = 0, N / 2 - 1 do
			rod(w, "InnerRim", innerPts[s][k], innerPts[s][(k + 1) % (N / 2)], 0.35, Metal, frame)
			rod(w, "Truss", innerPts[s][k], outerPts[s][2 * k], 0.25, Metal, frame)
			rod(w, "Truss", innerPts[s][k], outerPts[s][(2 * k + 2) % N], 0.25, Metal, frame)
			rod(w, "Spoke", hub + Vector3.new(0, 0, s * 0.9), innerPts[s][k], 0.22, Metal, frame)
		end
	end
	for k = 0, N / 2 - 1, 2 do
		rod(w, "CrossTie", innerPts[-1][k], innerPts[1][k], 0.25, Metal, frame)
	end
	-- Bulbs round the rim and out along every other spoke.
	for k = 0, N - 1 do
		local a = k / N * math.pi * 2
		bulb(w, hub + Vector3.new(math.cos(a) * (R + 0.35), math.sin(a) * (R + 0.35), -HALF - 0.3), 0.6, 0.4, rng, k % 8 == 0)
	end
	for k = 0, N / 2 - 1, 2 do
		local a = k / (N / 2) * math.pi * 2
		for t = 1, 3 do
			bulb(w, hub + Vector3.new(math.cos(a) * inner * t / 4, math.sin(a) * inner * t / 4, -HALF - 0.3), 0.45, 0.3, rng, false)
		end
	end
	-- Sixteen gondolas; one is missing, down on the roof.
	local turn = rng:NextNumber(0, math.pi * 2)
	local missing = rng:NextInteger(0, 15)
	for k = 0, 15 do
		local a = turn + k / 16 * math.pi * 2
		local pin = hub + Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
		rod(w, "GondolaPin", pin + Vector3.new(0, 0, -HALF), pin + Vector3.new(0, 0, HALF), 0.35, Metal, STEEL)
		if k ~= missing then
			local swing = CFrame.new(pin) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6)))
			local cab = swing * CFrame.new(0, -3.1, 0)
			for _, dx in ipairs({ -1.1, 1.1 }) do
				rod(w, "GondolaYoke", pin, (cab * CFrame.new(dx, 1.5, 0)).Position, 0.18, Metal, STEEL)
			end
			gondola(w, cab, jitter(pick(PASTELS, rng), rng, 0.05), k + 1)
		end
	end
	local wreck = CFrame.new(c.X + R * 0.75, ROOF + 1.2, c.Z + 11) * CFrame.Angles(math.rad(rng:NextNumber(-25, 25)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(60, 110)))
	gondola(w, wreck, darken(pick(PASTELS, rng), 0.8), missing + 1)
	for _ = 1, 6 do
		deco(part(w, "Debris", Vector3.new(rng:NextNumber(0.4, 1.4), 0.2, rng:NextNumber(0.4, 1.2)), CFrame.new(c.X + R * 0.75 + rng:NextNumber(-3, 3), ROOF + 0.1, c.Z + 11 + rng:NextNumber(-3, 3)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Glass, rgb(70, 80, 86))).Transparency = 0.3
	end
	occupy(c.X + R * 0.75, c.Z + 11, 3)
	-- The boarding platform under the wheel, with steps and a sign.
	box(w, "BoardingDeck", c.X - 6, c.X + 6, ROOF, ROOF + 1.6, c.Z - 3.2, c.Z + 3.2, Concrete, rgb(170, 166, 156))
	for k = 1, 3 do
		box(w, "BoardingStep", c.X - 2, c.X + 2, ROOF, ROOF + 1.6 - k * 0.4, c.Z - 3.2 - k * 0.8, c.Z - 3.2 - (k - 1) * 0.8, Concrete, rgb(170, 166, 156))
	end
	for _, s in ipairs({ -1, 1 }) do
		rod(w, "DeckRail", Vector3.new(c.X + s * 6, ROOF + 4.6, c.Z - 3.2), Vector3.new(c.X + s * 6, ROOF + 4.6, c.Z + 3.2), 0.2, Metal, STEEL)
		for _, z in ipairs({ -3.2, 0, 3.2 }) do
			rod(w, "DeckPost", Vector3.new(c.X + s * 6, ROOF + 1.6, c.Z + z), Vector3.new(c.X + s * 6, ROOF + 4.6, c.Z + z), 0.18, Metal, STEEL)
		end
	end
	box(w, "MotorHouse", c.X - 19, c.X - 14, ROOF, ROOF + 5, c.Z - 2.5, c.Z + 2.5, Metal, rgb(120, 130, 120))
	local sign = label(w, CFrame.new(c.X, ROOF + 3.4, c.Z - 6.6), Vector3.new(7, 1.8, 0.15), Enum.NormalId.Front, "観覧車  ¥300", RED, CREAM, Smooth, Enum.Font.GothamBlack)
	sign.CanCollide = true
	for _, dx in ipairs({ -3, 3 }) do
		rod(w, "SignLeg", Vector3.new(c.X + dx, ROOF, c.Z - 6.6), Vector3.new(c.X + dx, ROOF + 2.5, c.Z - 6.6), 0.15, Metal, STEEL)
	end
end

-- ===== The carousel =====

local function horse(car, cf, coat, rng)
	local mane = if coat.R > 0.7 then rgb(120, 90, 60) else rgb(236, 226, 200)
	local b = cf * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, 0)
	ellipsoid(car, "HorseBody", Vector3.new(1, 1.15, 2.6), b, Smooth, coat)
	ellipsoid(car, "HorseChest", Vector3.new(0.95, 1.1, 1.1), b * CFrame.new(0, 0.15, -0.95), Smooth, coat)
	local neck = b * CFrame.new(0, 0.85, -1.25) * CFrame.Angles(math.rad(-35), 0, 0)
	ellipsoid(car, "HorseNeck", Vector3.new(0.6, 1.5, 0.75), neck, Smooth, coat)
	ellipsoid(car, "HorseHead", Vector3.new(0.5, 0.55, 1.15), b * CFrame.new(0, 1.55, -1.8) * CFrame.Angles(math.rad(35), 0, 0), Smooth, coat)
	for _, s in ipairs({ -1, 1 }) do
		deco(ellipsoid(car, "HorseEar", Vector3.new(0.12, 0.35, 0.15), b * CFrame.new(s * 0.17, 2.02, -1.55), Smooth, coat))
	end
	deco(part(car, "Mane", Vector3.new(0.15, 1.5, 0.35), neck * CFrame.new(0, 0.1, 0.32), Smooth, mane))
	deco(rod(car, "Tail", (b * CFrame.new(0, 0.3, 1.3)).Position, (b * CFrame.new(0, -0.7, 1.9)).Position, 0.3, Smooth, mane))
	part(car, "Saddle", Vector3.new(1.06, 0.25, 0.9), b * CFrame.new(0, 0.58, 0.1), Smooth, rgb(170, 30, 40))
	deco(part(car, "SaddleCloth", Vector3.new(1.08, 0.7, 1.2), b * CFrame.new(0, 0.25, 0.1), Smooth, GOLD))
	for _, s in ipairs({ -1, 1 }) do
		local knee = b * CFrame.new(s * 0.25, -0.85, -1.5)
		deco(rod(car, "HorseLeg", (b * CFrame.new(s * 0.25, -0.3, -0.9)).Position, knee.Position, 0.22, Smooth, coat))
		deco(rod(car, "HorseLeg", knee.Position, (b * CFrame.new(s * 0.25, -1.45, -1.25)).Position, 0.2, Smooth, coat))
		local hock = b * CFrame.new(s * 0.25, -1, 1.35)
		deco(rod(car, "HorseLeg", (b * CFrame.new(s * 0.25, -0.3, 0.9)).Position, hock.Position, 0.24, Smooth, coat))
		deco(rod(car, "HorseLeg", hock.Position, (b * CFrame.new(s * 0.25, -1.5, 1.75)).Position, 0.2, Smooth, coat))
	end
end

local function carousel(m, c, rng)
	local car = model(m, "Carousel")
	local R = 9.5
	local base = CFrame.new(c)
	occupy(c.X, c.Z, R + 1.5)
	upright(car, "CarouselStep", 0.5, R * 2 + 2, base, 0, 0.25, 0, Concrete, rgb(150, 146, 136))
	upright(car, "CarouselDeck", 0.6, R * 2, base, 0, 0.8, 0, Wood, rgb(200, 170, 120))
	local deck = 1.1
	-- The centre drum, mirror panels in gold frames all round.
	local core = 3
	upright(car, "CarouselCore", 7.4, core * 2, base, 0, deck + 3.7, 0, Smooth, rgb(236, 220, 190))
	for k = 0, 7 do
		local panel = base * CFrame.new(0, deck + 3.7, 0) * CFrame.Angles(0, -k / 8 * math.pi * 2, 0) * CFrame.new(core + 0.05, 0, 0)
		deco(part(car, "MirrorFrame", Vector3.new(0.12, 4.2, 2.4), panel * CFrame.new(-0.02, 0, 0), Metal, GOLD))
		part(car, "CoreMirror", Vector3.new(0.1, 3.8, 2.1), panel, Smooth, rgb(190, 196, 200)).Reflectance = 0.5
	end
	-- The canopy: a striped peaked roof, rounding boards round its edge
	-- with a scalloped valance and bulbs, a gold finial and a flag.
	local roofY = deck + 7.4
	upright(car, "CanopyBase", 0.5, R * 2 + 1.2, base, 0, roofY + 0.25, 0, Wood, CREAM)
	for k = 0, 5 do
		upright(car, "Canopy", 0.6, (R * 2 + 1) * (1 - k * 0.16), base, 0, roofY + 0.8 + k * 0.55, 0, Fabric, if k % 2 == 0 then RED else CREAM)
	end
	local top = roofY + 0.8 + 6 * 0.55
	part(car, "Finial", Vector3.one * 1.2, base * CFrame.new(0, top + 0.4, 0), Metal, GOLD).Shape = Enum.PartType.Ball
	rod(car, "FlagPole", (base * CFrame.new(0, top + 0.9, 0)).Position, (base * CFrame.new(0, top + 3.4, 0)).Position, 0.12, Metal, GOLD)
	deco(part(car, "Flag", Vector3.new(1.6, 0.9, 0.05), base * CFrame.new(0.85, top + 2.9, 0), Fabric, RED))
	for k = 0, 15 do
		local out = base * CFrame.new(0, roofY - 0.4, 0) * CFrame.Angles(0, -k / 16 * math.pi * 2, 0) * CFrame.new(R + 0.65, 0, 0)
		part(car, "RoundingBoard", Vector3.new(0.2, 1.6, 3.7), out, Wood, if k % 2 == 0 then rgb(190, 56, 56) else rgb(56, 104, 156))
		deco(part(car, "BoardPainting", Vector3.new(0.05, 1, 2.4), out * CFrame.new(0.12, 0, 0), Smooth, pick(PASTELS, rng)))
		for _, dy in ipairs({ -0.85, 0.85 }) do
			deco(part(car, "BoardTrim", Vector3.new(0.24, 0.18, 3.8), out * CFrame.new(0, dy, 0), Metal, GOLD))
		end
		deco(ellipsoid(car, "Valance", Vector3.new(0.15, 1.2, 3.4), out * CFrame.new(0, -1.3, 0), Fabric, if k % 2 == 0 then CREAM else RED))
		bulb(car, (out * CFrame.new(0.25, 0, 1.6)).Position, 0.45, 0.45, rng, k % 8 == 0)
		bulb(car, (out * CFrame.new(0.2, -1.95, 0)).Position, 0.4, 0.45, rng, false)
	end
	-- Two rings of horses on gold poles, all facing the way it turned.
	local turn = rng:NextNumber(0, math.pi * 2)
	for _, ring in ipairs({ { r = R - 1.6, n = 10 }, { r = R - 4.4, n = 6 } }) do
		for k = 0, ring.n - 1 do
			local a = turn + k / ring.n * math.pi * 2 + (if ring.n == 6 then 0.3 else 0)
			local p = c + Vector3.new(math.cos(a) * ring.r, 0, math.sin(a) * ring.r)
			rod(car, "HorsePole", p + Vector3.new(0, deck, 0), p + Vector3.new(0, roofY, 0), 0.22, Metal, GOLD)
			local at = p + Vector3.new(0, deck + 2.6 + rng:NextNumber(0, 1.2), 0)
			local coat = pick({ WHITE, rgb(60, 50, 44), rgb(180, 130, 80), rgb(230, 200, 210), rgb(200, 216, 236) }, rng)
			horse(car, CFrame.lookAt(at, at + Vector3.new(-math.sin(a), 0, math.cos(a))), coat, rng)
		end
	end
	label(car, CFrame.new(c.X, ROOF + 3, c.Z - R - 1.6), Vector3.new(6, 1.4, 0.12), Enum.NormalId.Front, "メリーゴーランド", RED, CREAM, Smooth, Enum.Font.GothamBlack).CanCollide = true
end

-- ===== The swing ride =====

local function swingRide(m, c, rng)
	local s = model(m, "SwingRide")
	local H, R = 15, 8
	local base = CFrame.new(c)
	occupy(c.X, c.Z, R + 1.5)
	upright(s, "SwingBase", 1, 7, base, 0, 0.5, 0, Concrete, rgb(150, 146, 136))
	upright(s, "SwingTower", H, 1.8, base, 0, H / 2 + 1, 0, Metal, rgb(230, 226, 214))
	for k = 1, 3 do
		deco(upright(s, "TowerBand", 0.6, 1.9, base, 0, k * 4, 0, Metal, if k % 2 == 0 then RED else rgb(60, 120, 200)))
	end
	local topY = H + 1
	upright(s, "SwingCanopy", 0.8, R * 2 + 2, base, 0, topY, 0, Metal, rgb(60, 120, 200))
	upright(s, "SwingCanopyTop", 1.2, R + 2, base, 0, topY + 0.95, 0, Metal, CREAM)
	upright(s, "SwingCanopyCrown", 1, 3.5, base, 0, topY + 2, 0, Metal, GOLD)
	part(s, "Finial", Vector3.one, base * CFrame.new(0, topY + 3, 0), Metal, GOLD).Shape = Enum.PartType.Ball
	for k = 0, 15 do
		local out = base * CFrame.new(0, topY - 0.8, 0) * CFrame.Angles(0, -k / 16 * math.pi * 2, 0) * CFrame.new(R + 0.9, 0, 0)
		deco(ellipsoid(s, "Valance", Vector3.new(0.15, 1.4, 3.4), out, Fabric, if k % 2 == 0 then CREAM else RED))
		bulb(s, (out * CFrame.new(0.2, 0.7, 0)).Position, 0.45, 0.4, rng, k % 8 == 4)
	end
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local radial = Vector3.new(math.cos(a), 0, math.sin(a))
		local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
		local hang = c + radial * R + Vector3.new(0, topY - 0.4, 0)
		local color = pick(PASTELS, rng)
		if rng:NextNumber() < 0.15 then
			-- snapped: the chains dangle, the chair's on the roof
			for _, d in ipairs({ -0.6, 0.6 }) do
				rod(s, "SwingChain", hang + radial * d, hang + radial * d - Vector3.new(0, rng:NextNumber(2, 6), 0), 0.08, Metal, STEEL)
			end
			local down = c + radial * (R + rng:NextNumber(1, 3)) + Vector3.new(0, 0.5, 0)
			local chair = CFrame.lookAt(down, down + tangent) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, math.rad(rng:NextNumber(70, 100)))
			part(s, "SwingSeat", Vector3.new(1.4, 0.2, 1.3), chair, Metal, color)
			part(s, "SwingBack", Vector3.new(1.4, 1.3, 0.15), chair * CFrame.new(0, 0.65, 0.6), Metal, color)
		else
			local seat = c + radial * R + Vector3.new(0, 3.2, 0)
			local chair = CFrame.lookAt(seat, seat + tangent)
			for _, d in ipairs({ -0.6, 0.6 }) do
				rod(s, "SwingChain", hang + radial * d, seat + radial * d + Vector3.new(0, 0.1, 0), 0.08, Metal, STEEL)
			end
			part(s, "SwingSeat", Vector3.new(1.4, 0.2, 1.3), chair, Metal, color)
			part(s, "SwingBack", Vector3.new(1.4, 1.3, 0.15), chair * CFrame.new(0, 0.65, 0.6), Metal, color)
			deco(rod(s, "SwingBar", (chair * CFrame.new(-0.65, 0.8, -0.5)).Position, (chair * CFrame.new(0.65, 0.8, -0.5)).Position, 0.1, Metal, STEEL))
		end
	end
	label(s, CFrame.new(c.X, ROOF + 2.6, c.Z - 4), Vector3.new(4.4, 1.2, 0.12), Enum.NormalId.Front, "空中ブランコ", rgb(60, 120, 200), CREAM, Smooth, Enum.Font.GothamBlack).CanCollide = true
end

-- ===== The dragon coaster =====

-- A point along a stadium-shaped loop (two straights, two semicircles)
-- centred on (cx, cz): `half` the straights' half length, `r` the ends'
-- radius; u in 0..1 from the middle of the south straight, heading east.
local function stadium(cx, cz, half, r, u)
	local L1, L2 = 2 * half, math.pi * r
	local total = 2 * L1 + 2 * L2
	local s = (u * total + half) % total
	if s < L1 then
		return Vector3.new(cx - half + s, 0, cz - r)
	elseif s < L1 + L2 then
		local t = -math.pi / 2 + (s - L1) / r
		return Vector3.new(cx + half + math.cos(t) * r, 0, cz + math.sin(t) * r)
	elseif s < 2 * L1 + L2 then
		return Vector3.new(cx + half - (s - L1 - L2), 0, cz + r)
	end
	local t = math.pi / 2 + (s - 2 * L1 - L2) / r
	return Vector3.new(cx - half + math.cos(t) * r, 0, cz + math.sin(t) * r)
end

local function coaster(m, rng)
	local t = model(m, "DragonCoaster")
	local cx, cz, half, r = 590, 206, 21, 6
	local green = rgb(60, 150, 80)
	local function at(u)
		local p = stadium(cx, cz, half, r, u % 1)
		return p + Vector3.new(0, ROOF + 2.4 + 3.4 * (1 - math.cos(4 * math.pi * u)) / 2, 0)
	end
	local N = 72
	for i = 0, N - 1 do
		local a, b = at(i / N), at((i + 1) / N)
		local dir = (b - a).Unit
		local across = Vector3.new(-dir.Z, 0, dir.X).Unit
		for _, s in ipairs({ -0.8, 0.8 }) do
			rod(t, "CoasterRail", a + across * s, b + across * s, 0.24, Metal, RED)
		end
		if i % 2 == 0 then
			part(t, "CoasterTie", Vector3.new(2, 0.14, 0.4), CFrame.lookAt(a - Vector3.new(0, 0.18, 0), a - Vector3.new(0, 0.18, 0) + across), Metal, DARK)
		end
		if i % 4 == 0 then
			rod(t, "CoasterSupport", a - Vector3.new(0, 0.25, 0), Vector3.new(a.X, ROOF, a.Z), 0.45, Metal, rgb(230, 226, 214))
			box(t, "SupportFoot", a.X - 0.5, a.X + 0.5, ROOF, ROOF + 0.25, a.Z - 0.5, a.Z + 0.5, Metal, DARK)
		end
	end
	-- The train, stopped at the station: a dragon's head, three cars, a tail.
	for k = 0, 3 do
		local u = -k * 0.019
		local p, ahead = at(u), at(u + 0.005)
		local car = CFrame.lookAt(p + Vector3.new(0, 0.75, 0), ahead + Vector3.new(0, 0.75, 0))
		part(t, "CoasterCar", Vector3.new(1.9, 0.9, 2.1), car, Metal, green)
		deco(part(t, "CarSeat", Vector3.new(1.5, 0.15, 1.3), car * CFrame.new(0, 0.35, 0.1), Smooth, rgb(200, 180, 60)))
		deco(part(t, "CarBelly", Vector3.new(1.95, 0.3, 2.15), car * CFrame.new(0, -0.3, 0), Metal, rgb(240, 200, 60)))
		if k == 0 then
			local head = car * CFrame.new(0, 0.9, -1.5)
			ellipsoid(t, "DragonHead", Vector3.new(1.4, 1.2, 1.8), head, Smooth, green)
			ellipsoid(t, "DragonSnout", Vector3.new(1, 0.7, 0.9), head * CFrame.new(0, -0.2, -0.9), Smooth, green)
			for _, s in ipairs({ -1, 1 }) do
				deco(ellipsoid(t, "DragonEye", Vector3.one * 0.35, head * CFrame.new(s * 0.45, 0.3, -0.6), Smooth, WHITE))
				deco(ellipsoid(t, "DragonPupil", Vector3.one * 0.18, head * CFrame.new(s * 0.52, 0.32, -0.72), Smooth, DARK))
				deco(rod(t, "DragonHorn", (head * CFrame.new(s * 0.35, 0.5, 0.2)).Position, (head * CFrame.new(s * 0.55, 1.3, 0.7)).Position, 0.2, Smooth, rgb(240, 200, 60)))
			end
		elseif k == 3 then
			deco(rod(t, "DragonTail", (car * CFrame.new(0, 0.2, 1)).Position, (car * CFrame.new(0, 0.9, 2.4)).Position, 0.45, Smooth, green))
		end
	end
	-- The station inside the loop, a roof over it.
	local sx0, sx1, sz0, sz1 = cx - 7, cx + 3, cz - r + 1.4, cz - r + 4.4
	box(t, "StationDeck", sx0, sx1, ROOF, ROOF + 2.4, sz0, sz1, Concrete, rgb(170, 166, 156))
	for k = 1, 3 do
		box(t, "StationStep", sx0 - k * 0.8, sx0 - (k - 1) * 0.8, ROOF, ROOF + 2.4 - k * 0.6, sz0, sz1, Concrete, rgb(170, 166, 156))
	end
	for _, x in ipairs({ sx0 + 0.3, sx1 - 0.3 }) do
		rod(t, "StationPost", Vector3.new(x, ROOF + 2.4, sz1 - 0.3), Vector3.new(x, ROOF + 7.5, sz1 - 0.3), 0.25, Metal, STEEL)
	end
	box(t, "StationRoof", sx0 - 0.3, sx1 + 0.3, ROOF + 7.5, ROOF + 7.9, sz0 - 2.5, sz1, Metal, rgb(240, 200, 60))
	label(t, CFrame.new((sx0 + sx1) / 2, ROOF + 7, sz0 - 2.4), Vector3.new(6, 0.9, 0.1), Enum.NormalId.Front, "ドラゴンコースター", rgb(60, 150, 80), WHITE, Smooth, Enum.Font.GothamBlack)
	occupy(cx, cz, 10)
	occupy(cx - half, cz, 7)
	occupy(cx + half, cz, 7)
end

-- ===== The model train and the fountain =====

-- A point round a rounded rectangle; u in 0..1.
local function roundedRect(x0, x1, z0, z1, rc, u)
	local w, h = x1 - x0 - 2 * rc, z1 - z0 - 2 * rc
	local arc = math.pi / 2 * rc
	local total = 2 * w + 2 * h + 4 * arc
	local s = (u % 1) * total
	local legs = {
		{ w, function(d) return Vector3.new(x0 + rc + d, 0, z0) end },
		{ arc, function(d) local a = -math.pi / 2 + d / rc return Vector3.new(x1 - rc + math.cos(a) * rc, 0, z0 + rc + math.sin(a) * rc) end },
		{ h, function(d) return Vector3.new(x1, 0, z0 + rc + d) end },
		{ arc, function(d) local a = d / rc return Vector3.new(x1 - rc + math.cos(a) * rc, 0, z1 - rc + math.sin(a) * rc) end },
		{ w, function(d) return Vector3.new(x1 - rc - d, 0, z1) end },
		{ arc, function(d) local a = math.pi / 2 + d / rc return Vector3.new(x0 + rc + math.cos(a) * rc, 0, z1 - rc + math.sin(a) * rc) end },
		{ h, function(d) return Vector3.new(x0, 0, z1 - rc - d) end },
		{ arc, function(d) local a = math.pi + d / rc return Vector3.new(x0 + rc + math.cos(a) * rc, 0, z0 + rc + math.sin(a) * rc) end },
	}
	for _, leg in ipairs(legs) do
		if s <= leg[1] then
			return leg[2](s)
		end
		s -= leg[1]
	end
	return legs[1][2](0)
end

local function miniTrain(m, rng)
	local t = model(m, "MiniTrain")
	local H = G.HOLE
	local x0, x1, z0, z1, rc = H.x0 - 5, H.x1 + 5, H.z0 - 5, H.z1 + 5, 6
	local function at(u)
		return roundedRect(x0, x1, z0, z1, rc, u) + Vector3.new(0, ROOF, 0)
	end
	local N = 64
	for i = 0, N - 1 do
		local a, b = at(i / N), at((i + 1) / N)
		local dir = (b - a).Unit
		local across = Vector3.new(-dir.Z, 0, dir.X)
		for _, s in ipairs({ -0.8, 0.8 }) do
			rod(t, "TrackRail", a + across * s + Vector3.new(0, 0.3, 0), b + across * s + Vector3.new(0, 0.3, 0), 0.2, Metal, STEEL)
		end
		part(t, "TrackSleeper", Vector3.new(2.4, 0.2, 0.5), CFrame.lookAt(a + Vector3.new(0, 0.1, 0), a + Vector3.new(0, 0.1, 0) + across), Wood, rgb(110, 84, 58))
	end
	-- A little steam engine and two open cars, stopped on the south side.
	local u0 = rng:NextNumber(0.03, 0.12)
	local perimeter = 2 * (x1 - x0 + z1 - z0)
	for k = 0, 2 do
		local u = u0 - k * 5 / perimeter
		local p, ahead = at(u), at(u + 0.01)
		local cf = CFrame.lookAt(p + Vector3.new(0, 0.9, 0), ahead + Vector3.new(0, 0.9, 0))
		for _, dz in ipairs({ -1.2, 0, 1.2 }) do
			for _, s in ipairs({ -1, 1 }) do
				cylinder(t, "TrainWheel", 0.25, 0.9, cf * CFrame.new(s * 0.85, -0.2, dz), Metal, if k == 0 then RED else DARK)
			end
		end
		if k == 0 then
			part(t, "EngineFrame", Vector3.new(1.8, 0.4, 4.2), cf * CFrame.new(0, 0.2, 0), Metal, DARK)
			cylinder(t, "Boiler", 2.6, 1.5, cf * CFrame.new(0, 1.2, -0.6) * FACING_Z, Metal, rgb(40, 110, 60))
			part(t, "Cab", Vector3.new(1.9, 2.2, 1.4), cf * CFrame.new(0, 1.5, 1.3), Metal, rgb(40, 110, 60))
			part(t, "CabRoof", Vector3.new(2.2, 0.2, 1.8), cf * CFrame.new(0, 2.7, 1.3), Metal, DARK)
			upright(t, "Funnel", 1.2, 0.6, cf, 0, 2.4, -1.4, Metal, DARK)
			upright(t, "FunnelTop", 0.25, 0.85, cf, 0, 3.05, -1.4, Metal, DARK)
			upright(t, "Dome", 0.5, 0.6, cf, 0, 2.1, -0.3, Metal, GOLD)
			deco(ellipsoid(t, "Headlamp", Vector3.new(0.4, 0.4, 0.2), cf * CFrame.new(0, 1.4, -1.95), Neon, rgb(250, 240, 200)))
			part(t, "Cowcatcher", Vector3.new(1.6, 0.4, 0.5), cf * CFrame.new(0, 0, -2.2) * CFrame.Angles(math.rad(30), 0, 0), Metal, RED)
		else
			local color = pick(PASTELS, rng)
			part(t, "CarBody", Vector3.new(1.8, 0.9, 3.6), cf * CFrame.new(0, 0.55, 0), Metal, color)
			for _, dz in ipairs({ -0.8, 0.8 }) do
				deco(part(t, "CarBench", Vector3.new(1.5, 0.3, 0.5), cf * CFrame.new(0, 1.15, dz), Wood, rgb(150, 112, 76)))
			end
			for _, sx in ipairs({ -0.8, 0.8 }) do
				for _, sz in ipairs({ -1.6, 1.6 }) do
					deco(rod(t, "CarPost", (cf * CFrame.new(sx, 1, sz)).Position, (cf * CFrame.new(sx, 2.8, sz)).Position, 0.1, Metal, STEEL))
				end
			end
			part(t, "CarCanopy", Vector3.new(2, 0.15, 3.8), cf * CFrame.new(0, 2.85, 0), Fabric, if k == 1 then RED else CREAM)
		end
	end
	label(t, CFrame.new(x0 + 12, ROOF + 2.6, z0 - 2.4), Vector3.new(4.5, 1, 0.1), Enum.NormalId.Front, "こども汽車", rgb(40, 110, 60), WHITE, Smooth, Enum.Font.GothamBlack)
	rod(t, "SignPost", Vector3.new(x0 + 12, ROOF, z0 - 2.35), Vector3.new(x0 + 12, ROOF + 2.1, z0 - 2.35), 0.15, Metal, STEEL)
end

-- The store's mascot, a moon rabbit, holding up a crescent moon.
local function moonRabbit(f, cf, rng)
	local fur = rgb(236, 232, 222)
	ellipsoid(f, "RabbitBody", Vector3.new(2.4, 3, 2.2), cf * CFrame.new(0, 1.5, 0), Smooth, fur)
	ellipsoid(f, "RabbitBelly", Vector3.new(1.6, 2, 0.8), cf * CFrame.new(0, 1.4, -0.8), Smooth, rgb(250, 236, 230))
	local head = cf * CFrame.new(0, 3.6, -0.1)
	ellipsoid(f, "RabbitHead", Vector3.new(2.2, 2, 2), head, Smooth, fur)
	for _, s in ipairs({ -1, 1 }) do
		local ear = head * CFrame.new(s * 0.5, 1.9, 0.1) * CFrame.Angles(0, 0, s * -0.18)
		ellipsoid(f, "RabbitEar", Vector3.new(0.6, 2.6, 0.35), ear, Smooth, fur)
		deco(ellipsoid(f, "RabbitEarInner", Vector3.new(0.35, 2, 0.1), ear * CFrame.new(0, 0, -0.14), Smooth, rgb(240, 180, 190)))
		deco(ellipsoid(f, "RabbitEye", Vector3.new(0.3, 0.38, 0.12), head * CFrame.new(s * 0.45, 0.15, -0.95), Smooth, rgb(180, 30, 40)))
		deco(ellipsoid(f, "RabbitCheek", Vector3.new(0.4, 0.25, 0.1), head * CFrame.new(s * 0.65, -0.35, -0.9), Smooth, rgb(240, 170, 170)))
		ellipsoid(f, "RabbitArm", Vector3.new(0.55, 1.8, 0.55), cf * CFrame.new(s * 1.15, 3.4, -0.2) * CFrame.Angles(0, 0, s * -0.5), Smooth, fur)
		ellipsoid(f, "RabbitFoot", Vector3.new(0.8, 0.5, 1.3), cf * CFrame.new(s * 0.6, 0.25, -0.5), Smooth, fur)
	end
	-- The crescent, held overhead: a curve of glowing pieces.
	local moon = cf * CFrame.new(0, 6.9, -0.2)
	for k = 0, 8 do
		local a = math.rad(-120 + k * 30)
		local thick = 0.35 + 0.45 * math.cos(math.rad(-120 + k * 30) * 0.75)
		local p = deco(ellipsoid(f, "Crescent", Vector3.new(thick * 2, 0.9, thick * 1.2), moon * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.8, 0), Neon, rgb(240, 224, 150)))
		if k == 4 and lightsLeft > 0 then
			lightsLeft -= 1
			local light = Instance.new("PointLight")
			light.Range = 22
			light.Brightness = 1.2
			light.Color = rgb(240, 226, 170)
			light.Parent = p
		end
	end
end

local function fountain(m, c, rng)
	local f = model(m, "Fountain")
	local R = 13
	occupy(c.X, c.Z, R + 1)
	local stone = rgb(186, 182, 172)
	local n = 24
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * math.pi * 2
		local mid = c + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)
		local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
		local len = 2 * math.pi * R / n + 0.3
		part(f, "BasinWall", Vector3.new(1.2, 1.6, len), CFrame.lookAt(mid + Vector3.new(0, 0.8, 0), mid + Vector3.new(0, 0.8, 0) + tangent), Concrete, jitter(stone, rng, 0.03))
		part(f, "BasinCoping", Vector3.new(1.7, 0.25, len + 0.1), CFrame.lookAt(mid + Vector3.new(0, 1.72, 0), mid + Vector3.new(0, 1.72, 0) + tangent), Concrete, rgb(206, 202, 192))
	end
	upright(f, "BasinFloor", 0.3, R * 2, CFrame.new(c), 0, 0.15, 0, Enum.Material.CeramicTiles, rgb(110, 146, 156))
	local water = upright(f, "Rainwater", 0.1, R * 2 - 1.4, CFrame.new(c), 0, 0.55, 0, Glass, rgb(40, 70, 76))
	water.Transparency = 0.35
	water.Reflectance = 0.3
	water.CanCollide = false
	for _ = 1, 7 do
		local a, d = rng:NextNumber(0, 6.28), rng:NextNumber(4, R - 2)
		deco(upright(f, "LilyPad", 0.02, rng:NextNumber(0.8, 1.6), CFrame.new(c), math.cos(a) * d, 0.61, math.sin(a) * d, Smooth, rgb(70, 120, 60)))
	end
	-- The tiers.
	upright(f, "Pedestal", 3, 3.5, CFrame.new(c), 0, 1.8, 0, Concrete, stone)
	upright(f, "LowerBowl", 0.8, 9, CFrame.new(c), 0, 3.7, 0, Concrete, stone)
	upright(f, "LowerBowlLip", 0.3, 9.4, CFrame.new(c), 0, 4.2, 0, Concrete, rgb(206, 202, 192))
	upright(f, "Stem", 2.5, 1.6, CFrame.new(c), 0, 5.35, 0, Concrete, stone)
	upright(f, "UpperBowl", 0.6, 4.5, CFrame.new(c), 0, 6.9, 0, Concrete, stone)
	for _ = 1, 6 do
		local a = rng:NextNumber(0, 6.28)
		deco(ellipsoid(f, "Moss", Vector3.new(rng:NextNumber(0.8, 1.6), 0.35, rng:NextNumber(0.6, 1.2)), CFrame.new(c + Vector3.new(math.cos(a) * rng:NextNumber(2, 4.4), 4.4, math.sin(a) * rng:NextNumber(2, 4.4))), Enum.Material.LeafyGrass, rgb(80, 110, 60)))
		deco(part(f, "WaterStain", Vector3.new(0.4, rng:NextNumber(1, 2.4), 0.05), CFrame.new(c) * CFrame.Angles(0, a, 0) * CFrame.new(0, 2.4, -1.78), Smooth, rgb(120, 118, 108)))
	end
	moonRabbit(f, CFrame.new(c + Vector3.new(0, 7.2, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(150, 210)), 0), rng)
	local holder = model(f, "Growth")
	for _ = 1, 3 do
		local a, d = rng:NextNumber(0, 6.28), rng:NextNumber(5, R - 2)
		Clutter.weeds(holder, c + Vector3.new(math.cos(a) * d, 0.3, math.sin(a) * d), rng)
	end
end

-- ===== Smaller pieces =====

local function kiddieRide(m, c, rng)
	local ride = model(m, "KiddieRide")
	local kind = rng:NextInteger(1, 3)
	part(ride, "RideMat", Vector3.new(4.6, 0.05, 3.8), c + Vector3.new(0, 0.03, 0), Enum.Material.Rubber, pick({ rgb(200, 60, 50), rgb(60, 110, 180), rgb(60, 140, 80) }, rng))
	part(ride, "RidePlinth", Vector3.new(4, 1, 3), c + Vector3.new(0, 0.55, 0), Metal, rgb(220, 200, 60))
	part(ride, "CoinBox", Vector3.new(0.8, 1.4, 0.6), c + Vector3.new(1.6, 1.75, 1.2), Metal, rgb(200, 60, 50))
	local body = CFrame.new(c + Vector3.new(0, 2.45, 0))
	if kind == 1 then -- panda
		local w, k = rgb(240, 238, 232), rgb(30, 30, 32)
		ellipsoid(ride, "PandaBody", Vector3.new(1.8, 1.8, 2.8), body, Smooth, w)
		ellipsoid(ride, "PandaHead", Vector3.one * 1.6, body * CFrame.new(0, 0.9, -1.5), Smooth, w)
		for _, s in ipairs({ -1, 1 }) do
			ellipsoid(ride, "PandaEar", Vector3.one * 0.5, body * CFrame.new(s * 0.6, 1.7, -1.5), Smooth, k)
			ellipsoid(ride, "PandaEyePatch", Vector3.new(0.4, 0.5, 0.2), body * CFrame.new(s * 0.35, 1, -2.25), Smooth, k)
			for _, z in ipairs({ -0.8, 0.8 }) do
				ellipsoid(ride, "PandaLeg", Vector3.new(0.6, 1.2, 0.6), body * CFrame.new(s * 0.6, -0.9, z), Smooth, k)
			end
		end
	elseif kind == 2 then -- elephant
		local grey = rgb(150, 160, 190)
		ellipsoid(ride, "ElephantBody", Vector3.new(2, 1.9, 3), body, Smooth, grey)
		ellipsoid(ride, "ElephantHead", Vector3.one * 1.6, body * CFrame.new(0, 0.7, -1.6), Smooth, grey)
		rod(ride, "Trunk", (body * CFrame.new(0, 0.6, -2.3)).Position, (body * CFrame.new(0, -0.6, -2.8)).Position, 0.45, Smooth, grey)
		for _, s in ipairs({ -1, 1 }) do
			ellipsoid(ride, "ElephantEar", Vector3.new(0.2, 1.3, 1.1), body * CFrame.new(s * 0.9, 0.8, -1.4), Smooth, darken(grey, 0.9))
			for _, z in ipairs({ -0.8, 0.8 }) do
				cylinder(ride, "ElephantLeg", 1, 0.7, body * CFrame.new(s * 0.6, -0.9, z) * UPRIGHT, Smooth, grey)
			end
		end
	else -- a little car
		local paint = pick({ rgb(200, 60, 50), rgb(60, 120, 200) }, rng)
		part(ride, "CarBody", Vector3.new(2.2, 1.2, 3.6), body * CFrame.new(0, -0.4, 0), Smooth, paint)
		part(ride, "CarCabin", Vector3.new(2, 1, 1.6), body * CFrame.new(0, 0.6, 0.4), Smooth, paint)
		for _, s in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -1.2, 1.2 }) do
				cylinder(ride, "CarWheel", 0.4, 1, body * CFrame.new(s * 1.1, -1, z), Enum.Material.Rubber, rgb(28, 28, 30))
			end
		end
	end
	place(ride, c, Vector3.zero, rng:NextNumber(-0.3, 0.3))
end

-- The row of coin rides under a striped awning.
local function kiddieRow(m, x0, z, rng)
	local row = model(m, "KiddieRow")
	for k = 0, 3 do
		kiddieRide(row, Vector3.new(x0 + k * 8, ROOF, z), rng)
	end
	local ax0, ax1 = x0 - 4, x0 + 28
	for _, x in ipairs({ ax0, ax1 }) do
		for _, dz in ipairs({ -3, 3 }) do
			rod(row, "AwningPost", Vector3.new(x, ROOF, z + dz), Vector3.new(x, ROOF + 7, z + dz), 0.25, Metal, STEEL)
		end
	end
	local strips = 8
	for k = 0, strips - 1 do
		local xa = ax0 + k * (ax1 - ax0) / strips
		deco(part(row, "Awning", Vector3.new((ax1 - ax0) / strips, 0.12, 7), CFrame.new(xa + (ax1 - ax0) / strips / 2, ROOF + 7.2, z) * CFrame.Angles(math.rad(-6), 0, 0), Fabric, if k % 2 == 0 then RED else CREAM))
	end
	label(row, CFrame.new((ax0 + ax1) / 2, ROOF + 6.4, z - 3.4), Vector3.new(10, 1.1, 0.1), Enum.NormalId.Front, "こどもの乗りもの  ¥100", rgb(240, 200, 60), rgb(120, 30, 30), Smooth, Enum.Font.GothamBlack)
	occupy((ax0 + ax1) / 2, z, 17)
end

local function stage(m, c, rng)
	local s = model(m, "Stage")
	local blue = rgb(60, 80, 140)
	box(s, "StageDeck", c.X - 6, c.X + 6, ROOF, ROOF + 2, c.Z - 5, c.Z + 5, Wood, rgb(150, 110, 70))
	box(s, "StageBack", c.X + 5.6, c.X + 6, ROOF + 2, ROOF + 10, c.Z - 5, c.Z + 5, Wood, blue)
	for _, dz in ipairs({ -5, 5 }) do
		box(s, "Proscenium", c.X - 6, c.X - 5, ROOF + 2, ROOF + 10, c.Z + dz - 0.5, c.Z + dz + 0.5, Wood, RED)
	end
	box(s, "StageHeader", c.X - 6.2, c.X - 5, ROOF + 10, ROOF + 12, c.Z - 5.5, c.Z + 5.5, Wood, RED)
	label(s, CFrame.new(c.X - 6.25, ROOF + 11, c.Z), Vector3.new(0.1, 1.6, 9), Enum.NormalId.Left, "ヒーローショー", rgb(240, 200, 60), rgb(40, 40, 60), Smooth, Enum.Font.GothamBlack)
	-- Curtains, one pulled down.
	for _, dz in ipairs({ -3.6, 3.6 }) do
		if dz < 0 or rng:NextNumber() < 0.6 then
			deco(part(s, "Curtain", Vector3.new(0.2, 8, 2.6), CFrame.new(c.X - 4.7, ROOF + 6, c.Z + dz), Fabric, rgb(150, 20, 40)))
		else
			deco(part(s, "FallenCurtain", Vector3.new(3, 0.3, 2.6), CFrame.new(c.X - 3.5, ROOF + 2.2, c.Z + dz) * CFrame.Angles(0, 0, math.rad(8)), Fabric, rgb(150, 20, 40)))
		end
	end
	-- A lighting bar with three cans.
	rod(s, "LightBar", Vector3.new(c.X - 4.5, ROOF + 9.6, c.Z - 4.5), Vector3.new(c.X - 4.5, ROOF + 9.6, c.Z + 4.5), 0.2, Metal, DARK)
	for _, dz in ipairs({ -3, 0, 3 }) do
		deco(cylinder(s, "StageCan", 0.8, 0.6, CFrame.new(c.X - 4.5, ROOF + 9.1, c.Z + dz) * CFrame.Angles(0, 0, math.rad(-60)), Metal, DARK))
	end
	-- A cardboard hero, fallen flat.
	deco(part(s, "HeroCutout", Vector3.new(2, 0.1, 4.5), CFrame.new(c.X - 1, ROOF + 2.06, c.Z + rng:NextNumber(-2, 2)) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), Smooth, pick({ RED, blue, rgb(60, 150, 80) }, rng)))
	for row = 0, 3 do
		local x = c.X - 10 - row * 3
		box(s, "Bench", x - 0.6, x + 0.6, ROOF + 1.5, ROOF + 1.8, c.Z - 4, c.Z + 4, Wood, rgb(120, 92, 62))
		box(s, "BenchBack", x - 0.9, x - 0.7, ROOF + 1.8, ROOF + 3.2, c.Z - 4, c.Z + 4, Wood, rgb(120, 92, 62))
		for _, dz in ipairs({ -3.5, 3.5 }) do
			box(s, "BenchLeg", x - 0.4, x + 0.4, ROOF, ROOF + 1.5, c.Z + dz - 0.2, c.Z + dz + 0.2, Metal, STEEL)
		end
	end
	occupy(c.X - 4, c.Z, 12)
end

local function rooftopShrine(m, c)
	local s = model(m, "RooftopShrine")
	local vermilion = rgb(200, 60, 40)
	box(s, "ShrineBase", c.X - 2, c.X + 2, ROOF, ROOF + 1.2, c.Z - 1.6, c.Z + 1.6, Concrete, rgb(150, 146, 136))
	box(s, "Hokora", c.X - 1.3, c.X + 1.3, ROOF + 1.2, ROOF + 4, c.Z - 1.1, c.Z + 1.1, Wood, rgb(110, 80, 56))
	box(s, "HokoraRoof", c.X - 1.8, c.X + 1.8, ROOF + 4, ROOF + 4.5, c.Z - 1.5, c.Z + 1.5, Wood, rgb(60, 50, 44))
	for _, dx in ipairs({ -1.8, 1.8 }) do
		cylinder(s, "ToriiPillar", 4.8, 0.35, CFrame.new(c.X + dx, ROOF + 2.4, c.Z + 3.5) * UPRIGHT, Smooth, vermilion)
	end
	box(s, "Kasagi", c.X - 2.6, c.X + 2.6, ROOF + 4.8, ROOF + 5.2, c.Z + 3.2, c.Z + 3.8, Smooth, vermilion)
	box(s, "Nuki", c.X - 2.1, c.X + 2.1, ROOF + 3.9, ROOF + 4.2, c.Z + 3.35, c.Z + 3.65, Smooth, vermilion)
	for _, dx in ipairs({ -1.4, 1.4 }) do
		ellipsoid(s, "Fox", Vector3.new(0.6, 1.1, 0.9), CFrame.new(c.X + dx, ROOF + 1.75, c.Z - 1.9), Concrete, rgb(200, 196, 186))
	end
	occupy(c.X, c.Z + 1, 5)
end

-- The entrance arch in front of the stair: "welcome" facing you as you
-- come up, "come again" on the way out, lined with bulbs.
local function entranceArch(m, c, rng)
	local a = model(m, "EntranceArch")
	local half = 7
	for _, s in ipairs({ -1, 1 }) do
		for k = 0, 4 do
			box(a, "ArchPillar", c.X + s * half - 0.7, c.X + s * half + 0.7, ROOF + k * 2, ROOF + (k + 1) * 2, c.Z - 0.7, c.Z + 0.7, Smooth, if k % 2 == 0 then RED else CREAM)
		end
		part(a, "PillarBall", Vector3.one * 1.6, Vector3.new(c.X + s * half, ROOF + 13.4, c.Z), Metal, GOLD).Shape = Enum.PartType.Ball
		for k = 0, 4 do
			bulb(a, Vector3.new(c.X + s * half, ROOF + 1 + k * 2, c.Z + 0.85), 0.4, 0.5, rng, false)
		end
	end
	local board = label(a, CFrame.new(c.X, ROOF + 11.4, c.Z), Vector3.new(half * 2 + 1.4, 2.8, 0.6), Enum.NormalId.Back, "ようこそ  屋上遊園地へ", rgb(240, 200, 60), rgb(200, 40, 40), Smooth, Enum.Font.GothamBlack)
	board.CanCollide = true
	local out = board:FindFirstChildOfClass("SurfaceGui"):Clone()
	out.Face = Enum.NormalId.Front
	out:FindFirstChildOfClass("TextLabel").Text = "またきてね"
	out.Parent = board
	for k = 0, 13 do
		local x = c.X - half + k * (half * 2) / 13
		for _, y in ipairs({ ROOF + 10, ROOF + 12.8 }) do
			for _, dz in ipairs({ -0.4, 0.4 }) do
				bulb(a, Vector3.new(x, y, c.Z + dz), 0.35, 0.5, rng, k == 6 and y > ROOF + 12 and dz > 0)
			end
		end
	end
	-- The ticket booth beside it.
	local t = Vector3.new(c.X + half + 3.5, ROOF, c.Z - 5)
	box(a, "BoothBody", t.X - 1.5, t.X + 1.5, ROOF, ROOF + 3, t.Z - 1.5, t.Z + 1.5, Wood, CREAM)
	box(a, "BoothUpper", t.X - 1.5, t.X + 1.5, ROOF + 3, ROOF + 4.8, t.Z + 0.4, t.Z + 1.5, Wood, CREAM)
	for _, dx in ipairs({ -1.4, 1.4 }) do
		box(a, "BoothUpper", t.X + dx - 0.1, t.X + dx + 0.1, ROOF + 3, ROOF + 4.8, t.Z - 1.5, t.Z + 0.4, Wood, CREAM)
	end
	part(a, "BoothWindow", Vector3.new(2.6, 1.8, 0.05), Vector3.new(t.X, ROOF + 3.9, t.Z - 1.4), Glass, rgb(70, 80, 86)).Transparency = 0.5
	box(a, "BoothRoof", t.X - 2, t.X + 2, ROOF + 4.8, ROOF + 5.2, t.Z - 2, t.Z + 2, Metal, RED)
	label(a, CFrame.new(t.X, ROOF + 5.8, t.Z - 1.6), Vector3.new(3.2, 0.9, 0.1), Enum.NormalId.Front, "きっぷうりば", rgb(240, 200, 60), rgb(120, 30, 30), Smooth, Enum.Font.GothamBlack)
	occupy(c.X, c.Z, 8)
	occupy(t.X, t.Z, 3)
end

local function lampPost(m, p, rng)
	local l = model(m, "LampPost")
	upright(l, "LampBase", 0.8, 1, CFrame.new(p), 0, 0.4, 0, Metal, DARK)
	upright(l, "LampPole", 8, 0.3, CFrame.new(p), 0, 4.8, 0, Metal, DARK)
	for _, s in ipairs({ -1, 1 }) do
		rod(l, "LampArm", p + Vector3.new(0, 8.2, 0), p + Vector3.new(s * 1.4, 8.6, 0), 0.15, Metal, DARK)
		local globe = bulb(l, p + Vector3.new(s * 1.4, 8.2, 0), 1, 0.55, rng, s > 0)
		globe.Material = if globe.Material == Neon then Neon else Glass
	end
end

local function parkBench(m, cf, rng)
	local b = model(m, "ParkBench")
	local slat = rgb(140, 100, 64)
	for k = 0, 2 do
		part(b, "BenchSlat", Vector3.new(4.4, 0.15, 0.4), cf * CFrame.new(0, 1.55, -0.45 + k * 0.45), Wood, slat)
		part(b, "BackSlat", Vector3.new(4.4, 0.4, 0.12), cf * CFrame.new(0, 2.1 + k * 0.5, 0.75), Wood, slat)
	end
	for _, x in ipairs({ -1.9, 1.9 }) do
		part(b, "BenchIron", Vector3.new(0.2, 1.5, 1.5), cf * CFrame.new(x, 0.75, 0.1), Metal, DARK)
		part(b, "BenchIronBack", Vector3.new(0.2, 1.7, 0.15), cf * CFrame.new(x, 2.4, 0.82), Metal, DARK)
	end
end

local function planterTree(m, c, rng)
	local p = model(m, "Planter")
	box(p, "PlanterWall", c.X - 2.2, c.X + 2.2, ROOF, ROOF + 1.4, c.Z - 2.2, c.Z + 2.2, Concrete, rgb(170, 166, 156))
	box(p, "PlanterSoil", c.X - 1.9, c.X + 1.9, ROOF + 1.4, ROOF + 1.45, c.Z - 1.9, c.Z + 1.9, Enum.Material.Ground, rgb(60, 44, 32))
	Clutter.rooftopTree(p, c + Vector3.new(0, 1.45, 0), rng)
	occupy(c.X, c.Z, 3)
end

local function balloonCart(m, cf, rng)
	local b = model(m, "BalloonCart")
	part(b, "CartBody", Vector3.new(2.6, 1.6, 1.6), cf * CFrame.new(0, 1.6, 0), Wood, rgb(60, 120, 200))
	for _, s in ipairs({ -1, 1 }) do
		cylinder(b, "CartWheel", 0.2, 1.4, cf * CFrame.new(s * 1.35, 0.7, 0), Metal, RED)
	end
	rod(b, "UmbrellaPole", (cf * CFrame.new(0, 2.4, 0)).Position, (cf * CFrame.new(0, 6.2, 0)).Position, 0.12, Metal, STEEL)
	upright(b, "Umbrella", 0.4, 4, cf, 0, 6.3, 0, Fabric, RED)
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		local top = cf * CFrame.new(math.cos(a) * 1.2, 8 + rng:NextNumber(0, 1.5), math.sin(a) * 1.2)
		if rng:NextNumber() < 0.75 then
			deco(rod(b, "BalloonString", (cf * CFrame.new(0.9, 2.4, 0)).Position, top.Position - Vector3.new(0, 0.7, 0), 0.03, Fabric, WHITE))
			deco(ellipsoid(b, "Balloon", Vector3.new(1, 1.2, 1), top, Smooth, pick(PASTELS, rng))).Reflectance = 0.1
		else
			deco(ellipsoid(b, "DeadBalloon", Vector3.new(0.6, 0.2, 0.8), cf * CFrame.new(rng:NextNumber(-2, 2), 0.1, rng:NextNumber(-2, 2)), Smooth, pick(PASTELS, rng)))
		end
	end
	label(b, cf * CFrame.new(0, 1.6, -0.82), Vector3.new(2, 0.7, 0.04), Enum.NormalId.Front, "ふうせん", WHITE, rgb(60, 120, 200))
end

local function snackCart(m, cf, rng)
	local b = model(m, "SnackCart")
	part(b, "CartBody", Vector3.new(3.2, 2.4, 1.8), cf * CFrame.new(0, 1.6, 0), Metal, RED)
	part(b, "PopcornCase", Vector3.new(2.4, 1.6, 1.4), cf * CFrame.new(0, 3.6, 0), Glass, rgb(220, 226, 228)).Transparency = 0.6
	deco(part(b, "Popcorn", Vector3.new(2.2, 0.6, 1.2), cf * CFrame.new(0, 3.1, 0), Smooth, rgb(250, 230, 160)))
	part(b, "CartRoof", Vector3.new(3.6, 0.3, 2.2), cf * CFrame.new(0, 4.6, 0), Metal, CREAM)
	for _, s in ipairs({ -1, 1 }) do
		cylinder(b, "CartWheel", 0.2, 1.2, cf * CFrame.new(s * 1.2, 0.6, 1), Metal, DARK)
	end
	label(b, cf * CFrame.new(0, 5.2, 0), Vector3.new(3, 0.8, 0.1), Enum.NormalId.Front, "ポップコーン", CREAM, RED, Smooth, Enum.Font.GothamBlack)
end

local function vending(m, cf, rng)
	local v = model(m, "VendingMachine")
	local body = pick({ rgb(200, 60, 50), rgb(60, 110, 180), WHITE }, rng)
	part(v, "VendingBody", Vector3.new(3.4, 6, 2.4), cf * CFrame.new(0, 3, 0), Metal, body)
	local display = part(v, "VendingDisplay", Vector3.new(2.8, 2.6, 0.1), cf * CFrame.new(0, 4.2, -1.22), Glass, rgb(230, 236, 240))
	display.Transparency = 0.3
	for row = 0, 1 do
		for k = 0, 4 do
			deco(upright(v, "Can", 0.7, 0.35, cf, -1.1 + k * 0.55, 3.35 + row * 1.2, -1.05, Metal, pick(PASTELS, rng)))
		end
	end
	local lit = rng:NextNumber() < 0.5
	part(v, "VendingPanel", Vector3.new(2.8, 0.5, 0.06), cf * CFrame.new(0, 2.5, -1.23), if lit then Neon else Smooth, rgb(200, 230, 240))
	part(v, "VendingSlot", Vector3.new(2, 0.6, 0.1), cf * CFrame.new(0, 0.8, -1.22), Metal, DARK)
end

-- Bulbs strung between two points, sagging.
local function festoon(m, a, b, rng)
	local n = math.max(4, math.floor((b - a).Magnitude / 3))
	local sag = (b - a).Magnitude * 0.07
	local prev = a
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		deco(rod(m, "FestoonWire", prev, p, 0.06, Metal, DARK))
		if i < n then
			bulb(m, p - Vector3.new(0, 0.28, 0), 0.42, 0.55, rng, i == math.floor(n / 2) and rng:NextNumber() < 0.4)
		end
		prev = p
	end
end

-- The store's great sign, on a lattice frame at the south edge of the
-- roof, turned to face back across at the rooftop and the school; bulbs
-- round each letter.
local function bigSign(m, rng)
	local s = model(m, "StoreSign")
	local text = { "月", "光", "百", "貨", "店" }
	local w, h = 11, 11
	local x0 = (G.X0 + G.X1) / 2 - #text * w / 2
	local z = G.Z0 + 1.5
	for k = 0, #text do
		local x = x0 + k * w
		rod(s, "SignFrame", Vector3.new(x, ROOF, z), Vector3.new(x, ROOF + h + 4, z), 0.6, Metal, STEEL)
		if k < #text then
			rod(s, "SignBrace", Vector3.new(x, ROOF + 1, z), Vector3.new(x + w, ROOF + h + 3, z), 0.3, Metal, STEEL)
		end
	end
	for _, y in ipairs({ ROOF + 1, ROOF + h + 3.5 }) do
		rod(s, "SignFrame", Vector3.new(x0, y, z), Vector3.new(x0 + #text * w, y, z), 0.5, Metal, STEEL)
	end
	for k, ch in ipairs(text) do
		local lit = rng:NextNumber() > 0.3
		local cx = x0 + (k - 0.5) * w
		local plate = label(s, CFrame.new(cx, ROOF + 2 + h / 2, z - 0.6), Vector3.new(w - 1.2, h - 1, 0.4), Enum.NormalId.Front, ch, rgb(240, 236, 226), if lit then rgb(200, 40, 40) else rgb(130, 90, 90), Smooth, Enum.Font.GothamBlack)
		plate.CanCollide = true
		if lit then
			local glow = Instance.new("SurfaceLight")
			glow.Face = Enum.NormalId.Front
			glow.Range = 14
			glow.Brightness = 0.8
			glow.Color = rgb(255, 120, 110)
			glow.Parent = plate
			if rng:NextNumber() < 0.3 then
				plate:AddTag("FlickerLight")
			end
		end
		for j = 0, 9 do
			local t = j / 10
			local edge = if t < 0.25 then Vector2.new(-0.5 + t * 4, 0.5) elseif t < 0.5 then Vector2.new(0.5, 0.5 - (t - 0.25) * 4) elseif t < 0.75 then Vector2.new(0.5 - (t - 0.5) * 4, -0.5) else Vector2.new(-0.5, -0.5 + (t - 0.75) * 4)
			bulb(s, Vector3.new(cx + edge.X * (w - 1.2), ROOF + 2 + h / 2 + edge.Y * (h - 1), z - 0.95), 0.4, if lit then 0.6 else 0.1, rng, false)
		end
	end
end

local function roofFence(m)
	local h = 8
	local X0, X1, Z0, Z1 = G.X0, G.X1, G.Z0, G.Z1
	for _, side in ipairs({ { Vector3.new(X0 + 1, 0, Z0 + 1), Vector3.new(X1 - 1, 0, Z0 + 1) }, { Vector3.new(X1 - 1, 0, Z0 + 1), Vector3.new(X1 - 1, 0, Z1 - 1) }, { Vector3.new(X1 - 1, 0, Z1 - 1), Vector3.new(X0 + 1, 0, Z1 - 1) }, { Vector3.new(X0 + 1, 0, Z1 - 1), Vector3.new(X0 + 1, 0, Z0 + 1) } }) do
		local a, b = side[1] + Vector3.new(0, ROOF, 0), side[2] + Vector3.new(0, ROOF, 0)
		local n = math.max(1, math.floor((b - a).Magnitude / 10))
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			cylinder(m, "FencePost", h, 0.35, CFrame.new(p + Vector3.new(0, h / 2, 0)) * UPRIGHT, Metal, STEEL)
		end
		rod(m, "FenceRail", a + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0), 0.2, Metal, STEEL)
		local mesh = part(m, "FenceMesh", Vector3.new(0.08, h - 0.4, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + Vector3.new(0, h / 2, 0), b + Vector3.new(0, h / 2, 0)), Metal, rgb(150, 152, 150))
		mesh.Transparency = 0.72
	end
end

-- Ivy climbing the fence here and there.
local function fenceIvy(m, rng)
	local X0, X1, Z0, Z1 = G.X0, G.X1, G.Z0, G.Z1
	for _ = 1, 14 do
		local side = rng:NextInteger(1, 4)
		local p = if side == 1 then Vector3.new(rng:NextNumber(X0 + 4, X1 - 20), ROOF, Z0 + 1.3) elseif side == 2 then Vector3.new(X1 - 1.3, ROOF, rng:NextNumber(Z0 + 4, G.CORE.z0 - 2)) elseif side == 3 then Vector3.new(rng:NextNumber(X0 + 4, G.CORE.x0 - 2), ROOF, Z1 - 1.3) else Vector3.new(X0 + 1.3, ROOF, rng:NextNumber(Z0 + 4, Z1 - 4))
		local h = rng:NextNumber(2, 7)
		for k = 0, math.floor(h / 1.2) do
			deco(ellipsoid(m, "Ivy", Vector3.new(rng:NextNumber(1.2, 2.4), rng:NextNumber(1, 1.8), 0.7), CFrame.new(p + Vector3.new(rng:NextNumber(-0.6, 0.6), 0.6 + k * 1.2, 0)), Enum.Material.LeafyGrass, jitter(rgb(70, 104, 54), rng, 0.15)))
		end
	end
end

function Park.build(parent, geometry, rng)
	G = geometry
	ROOF = geometry.ROOF
	lightsLeft = 22
	busy = {}
	local park = model(parent, "RooftopPark")
	local H = G.HOLE
	local centre = Vector3.new((H.x0 + H.x1) / 2, ROOF, (H.z0 + H.z1) / 2)
	occupy(G.CORE.x0 + 9, G.CORE.z0 + 12, 13) -- the stair house
	roofFence(park)
	fenceIvy(park, rng)
	fountain(park, centre, rng)
	miniTrain(park, rng)
	task.wait()
	ferrisWheel(park, Vector3.new(546, ROOF, 268), 21, rng)
	task.wait()
	carousel(park, Vector3.new(634, ROOF, 236), rng)
	swingRide(park, Vector3.new(545, ROOF, 226), rng)
	coaster(park, rng)
	task.wait()
	stage(park, Vector3.new(645, ROOF, 208), rng)
	rooftopShrine(park, Vector3.new(527, ROOF, 205))
	kiddieRow(park, 578, 278, rng)
	entranceArch(park, Vector3.new(G.CORE_DOOR_X, ROOF, G.CORE.z0 - 6), rng)
	for k = 0, 1 do
		vending(park, CFrame.new(523.5, ROOF, 238 + k * 4) * CFrame.Angles(0, math.rad(-90), 0), rng)
	end
	occupy(523.5, 240, 4)
	balloonCart(park, CFrame.new(612, ROOF, 250) * CFrame.Angles(0, math.rad(rng:NextNumber(-30, 30)), 0), rng)
	snackCart(park, CFrame.new(575, ROOF, 232) * CFrame.Angles(0, math.rad(90 + rng:NextNumber(-20, 20)), 0), rng)
	occupy(612, 250, 3)
	occupy(575, 232, 3)
	-- Planted trees, benches, lamps.
	for _, p in ipairs({ { 524, 281 }, { 655, 200 }, { 612, 281 }, { 524, 250 } }) do
		planterTree(park, Vector3.new(p[1], ROOF, p[2]), rng)
	end
	for _, b in ipairs({ { 560, 250, 0 }, { 622, 222, 90 }, { 600, 268, 180 }, { 558, 214, 180 }, { 650, 252, 90 } }) do
		parkBench(park, CFrame.new(b[1], ROOF, b[2]) * CFrame.Angles(0, math.rad(b[3]), 0), rng)
		occupy(b[1], b[2], 2.5)
	end
	-- Festoon poles in a ring round the middle, strung pole to pole.
	local poles = { Vector3.new(622, ROOF, 256), Vector3.new(600, ROOF, 272), Vector3.new(572, ROOF, 272), Vector3.new(531, ROOF, 247), Vector3.new(530, ROOF, 214), Vector3.new(557, ROOF, 211), Vector3.new(622, ROOF, 214), Vector3.new(655, ROOF, 236) }
	for k, p in ipairs(poles) do
		rod(park, "FestoonPole", p, p + Vector3.new(0, 12, 0), 0.35, Metal, DARK)
		part(park, "PoleCap", Vector3.one * 0.6, p + Vector3.new(0, 12.2, 0), Metal, GOLD).Shape = Enum.PartType.Ball
		festoon(park, p + Vector3.new(0, 11.8, 0), poles[k % #poles + 1] + Vector3.new(0, 11.8, 0), rng)
		if k % 2 == 0 then
			festoon(park, p + Vector3.new(0, 11.8, 0), centre + Vector3.new(0, 16, 0), rng)
		end
		occupy(p.X, p.Z, 1)
	end
	for _, p in ipairs({ Vector3.new(572, ROOF, 222), Vector3.new(610, ROOF, 222), Vector3.new(572, ROOF, 260), Vector3.new(610, ROOF, 260), Vector3.new(640, ROOF, 262) }) do
		lampPost(park, p, rng)
		occupy(p.X, p.Z, 1.5)
	end
	bigSign(park, rng)
	-- Weeds, puddles, bushes wherever the rides aren't.
	local function free(x, z)
		for _, b in ipairs(busy) do
			if (x - b.x) ^ 2 + (z - b.z) ^ 2 < b.r * b.r then
				return false
			end
		end
		return true
	end
	for _ = 1, 40 do
		local c = Vector3.new(rng:NextNumber(G.X0 + 4, G.X1 - 4), ROOF, rng:NextNumber(G.Z0 + 4, G.Z1 - 4))
		if free(c.X, c.Z) then
			local holder = model(park, "Growth")
			local roll = rng:NextNumber()
			if roll < 0.45 then
				Clutter.weeds(holder, c, rng)
			elseif roll < 0.8 then
				Clutter.puddle(holder, c, rng)
			else
				Clutter.bush(holder, c, rng)
			end
		end
	end
end

return Park
