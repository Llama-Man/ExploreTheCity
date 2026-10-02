-- The things people leave about: Kazami's props (StiltTown.lua places
-- them). Each is { size = footprint (x across, z deep, as built facing
-- -Z), build = function(parent, cf, rng) }, cf at the middle of its
-- footprint on the deck, looking the way its front faces.
--
--   by a door    pots, plastic crates, gas bottles, a bicycle, umbrellas,
--                firewood, a rain barrel on a downpipe, a wind chime
--   out on deck  a vending machine, an oil-drum stove with stools round it,
--                benches, a jizo, a notice board, washing poles, drying
--                racks (persimmons, fish), a noodle cart, sake barrels, a
--                potted tree, an umbrella open to dry, a post box
--   on rails     a futon aired over them, a window box
--   underfoot    patched planks, a tin sheet nailed over a hole

local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local TunnelProps = require(script.Parent.TunnelProps)
local Wind = require(script.Parent.Windblown)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local Metal, Rust, Smooth, Wood, Planks, Fabric, Neon, Glass, Concrete, Grass, Plastic = Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.WoodPlanks, Enum.Material.Fabric, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Concrete, Enum.Material.LeafyGrass, Enum.Material.Plastic
local rgb = Color3.fromRGB
local UP = Vector3.yAxis
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local DARK = rgb(34, 34, 36)
local TIMBER = rgb(110, 84, 58)
local ROPE = rgb(170, 150, 110)
local VIVID = { rgb(200, 50, 44), rgb(230, 190, 50), rgb(60, 110, 190), rgb(70, 150, 80), rgb(236, 232, 222), rgb(230, 120, 40) }
local CRATES = { rgb(220, 180, 40), rgb(190, 50, 44), rgb(50, 90, 160), rgb(60, 130, 80) }

local Props = {}

-- (lights: StiltTown hands over what it can spare)
Props.light = function() end

local function deco(p)
	if p then
		p.CanCollide = false
		p.CastShadow = false
	end
	return p
end

local function rod(parent, name, a, b, d, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	return cylinder(parent, name, len, d, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function at(cf, x, y, z)
	return (cf * CFrame.new(x, y, z)).Position
end

local function plant(parent, p, rng, s)
	s = s or 1
	part(parent, "Pot", Vector3.new(1 * s, 1 * s, 1 * s), p + UP * 0.5 * s, Enum.Material.Slate, jitter(rgb(150, 90, 60), rng, 0.1))
	deco(ellipsoid(parent, "Plant", Vector3.new(1.5 * s, 1.3 * s, 1.5 * s), CFrame.new(p + UP * 1.45 * s), Grass, jitter(rgb(80, 130, 60), rng, 0.15)))
	if rng:NextNumber() < 0.35 then
		for _ = 1, 3 do
			deco(ellipsoid(parent, "Flower", Vector3.new(0.35, 0.35, 0.35), CFrame.new(p + Vector3.new(rng:NextNumber(-0.5, 0.5) * s, 1.9 * s, rng:NextNumber(-0.5, 0.5) * s)), Smooth, pick({ rgb(220, 60, 80), rgb(240, 200, 60), rgb(240, 236, 230), rgb(150, 90, 200) }, rng)))
		end
	end
end

-- ===== By a door =====

local S = {}

S.pots = { size = Vector3.new(2.6, 0, 1.2), build = function(p, cf, rng)
	for k = 0, rng:NextInteger(1, 2) do
		plant(p, at(cf, -0.8 + k * 0.9, 0, rng:NextNumber(-0.2, 0.2)), rng, rng:NextNumber(0.7, 1))
	end
end }

S.crates = { size = Vector3.new(2, 0, 2.6), build = function(p, cf, rng)
	local n = rng:NextInteger(1, 3)
	for k = 0, n - 1 do
		local c = cf * CFrame.new(rng:NextNumber(-0.15, 0.15), 0.55 + k * 1.12, 0) * CFrame.Angles(0, rng:NextNumber(-0.12, 0.12), 0)
		local color = pick(CRATES, rng)
		part(p, "Crate", Vector3.new(1.6, 1.1, 2.2), c, Plastic, color)
		deco(part(p, "CrateInside", Vector3.new(1.3, 0.12, 1.9), c * CFrame.new(0, 0.5, 0), Plastic, darken(color, 0.55)))
	end
	if rng:NextNumber() < 0.5 then
		for k = 0, 2 do
			deco(cylinder(p, "Bottle", 0.7, 0.32, CFrame.new(at(cf, -0.4 + k * 0.4, n * 1.12 + 0.35, rng:NextNumber(-0.5, 0.5))) * UPRIGHT, Glass, rgb(70, 110, 60)))
		end
	end
end }

S.gas = { size = Vector3.new(2.4, 0, 1.4), build = function(p, cf, rng)
	local color = pick({ rgb(200, 200, 196), rgb(60, 90, 150), rgb(190, 60, 44) }, rng)
	for _, x in ipairs({ -0.6, 0.6 }) do
		cylinder(p, "GasBottle", 2.6, 1.1, CFrame.new(at(cf, x, 1.3, 0)) * UPRIGHT, Metal, color)
		deco(cylinder(p, "GasCap", 0.4, 0.5, CFrame.new(at(cf, x, 2.8, 0)) * UPRIGHT, Metal, rgb(180, 160, 60)))
	end
	deco(rod(p, "GasChain", at(cf, -1.2, 1.8, 0.3), at(cf, 1.2, 1.8, 0.3), 0.08, Metal, DARK))
	label(p, cf * CFrame.new(-0.6, 1.2, -0.56), Vector3.new(0.7, 0.5, 0.02), Enum.NormalId.Front, "LP", rgb(236, 232, 222), rgb(190, 40, 30), Smooth, Enum.Font.GothamBlack)
end }

S.bicycle = { size = Vector3.new(5.4, 0, 1.8), build = function(p, cf, rng)
	-- side on to the wall (it runs along x), leaning on its stand
	local b = model(p, "Bicycle")
	local lean = cf * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, math.rad(if rng:NextNumber() < 0.5 then 10 else -10))
	local color = pick({ rgb(40, 40, 44), rgb(180, 40, 40), rgb(60, 100, 160), rgb(220, 220, 214), rgb(90, 140, 90) }, rng)
	local function q(x, y, z)
		return (lean * CFrame.new(x, y, z)).Position
	end
	for _, z in ipairs({ -1.8, 1.8 }) do
		cylinder(b, "Tyre", 0.28, 2.8, lean * CFrame.new(0, 1.4, z), Smooth, DARK)
		deco(cylinder(b, "Rim", 0.3, 2.2, lean * CFrame.new(0, 1.4, z), Metal, rgb(170, 170, 170)))
	end
	for _, s in ipairs({
		{ q(0, 1.4, 1.8), q(0, 1.55, 0.3) }, { q(0, 1.55, 0.3), q(0, 2.9, -1.1) }, { q(0, 1.55, 0.3), q(0, 3.1, 0.6) },
		{ q(0, 2.8, 0.55), q(0, 2.9, -1.1) }, { q(0, 2.8, 0.55), q(0, 1.4, 1.8) }, { q(0, 3.1, -1.2), q(0, 1.4, -1.8) },
	}) do
		rod(b, "Frame", s[1], s[2], 0.18, Metal, color)
	end
	rod(b, "Bars", q(-0.9, 3.4, -1.2), q(0.9, 3.4, -1.2), 0.15, Metal, DARK)
	part(b, "Saddle", Vector3.new(0.5, 0.22, 1), lean * CFrame.new(0, 3.25, 0.6), Smooth, DARK)
	if rng:NextNumber() < 0.6 then
		part(b, "Basket", Vector3.new(1.2, 0.8, 1), lean * CFrame.new(0, 3, -2.1), Metal, rgb(150, 150, 146))
	end
	for _, d in ipairs(b:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end
end }

S.umbrellas = { size = Vector3.new(1.2, 0, 1.2), build = function(p, cf, rng)
	part(p, "UmbrellaStand", Vector3.new(0.9, 1.4, 0.9), at(cf, 0, 0.7, 0), Metal, rgb(120, 124, 120))
	for _ = 1, rng:NextInteger(2, 3) do
		local base = at(cf, rng:NextNumber(-0.2, 0.2), 0.3, rng:NextNumber(-0.2, 0.2))
		local tip = base + Vector3.new(rng:NextNumber(-0.5, 0.5), 3, rng:NextNumber(-0.5, 0.5))
		local color = pick({ rgb(240, 240, 236), rgb(40, 50, 90), rgb(180, 40, 40), rgb(230, 200, 60) }, rng)
		deco(rod(p, "Umbrella", base, tip, 0.4, Fabric, color))
		deco(rod(p, "Handle", tip, tip + UP * 0.4, 0.12, Wood, TIMBER))
	end
end }

S.firewood = { size = Vector3.new(3.2, 0, 1.4), build = function(p, cf, rng)
	for row = 0, 2 do
		for k = 0, 2 - (if row == 2 then 1 else 0) do
			cylinder(p, "Log", 1.3, 0.6, cf * CFrame.new(-1.1 + k * 0.7 + row * 0.35, 0.3 + row * 0.55, 0) * CFrame.Angles(0, math.pi / 2, 0), Wood, jitter(rgb(120, 90, 60), rng, 0.12))
		end
	end
	if rng:NextNumber() < 0.5 then
		deco(part(p, "WoodTarp", Vector3.new(3.4, 0.08, 1.6), cf * CFrame.new(0, 1.75, 0) * CFrame.Angles(0.12, 0, 0), Fabric, pick(Wind.TARPS, rng)))
	end
end }

S.barrel = { size = Vector3.new(2.2, 0, 2.2), build = function(p, cf, rng, o)
	local color = pick({ rgb(60, 110, 170), rgb(70, 120, 80), rgb(120, 110, 90) }, rng)
	cylinder(p, "RainBarrel", 2.8, 2, CFrame.new(at(cf, 0, 1.4, 0)) * UPRIGHT, Plastic, color)
	deco(cylinder(p, "BarrelRim", 0.2, 2.1, CFrame.new(at(cf, 0, 2.85, 0)) * UPRIGHT, Plastic, darken(color, 0.7)))
	if o and o.eave then
		-- the downpipe off the gutter
		local top = at(cf, 0, o.eave, 1)
		rod(p, "Downpipe", at(cf, 0, 3.1, 0.4), top, 0.4, Metal, rgb(150, 150, 146))
		rod(p, "Gutter", top + (cf.RightVector * -2), top + (cf.RightVector * 2), 0.5, Metal, rgb(150, 150, 146))
	end
end }

S.chime = { size = Vector3.new(0.8, 0, 0.8), overhead = true, build = function(p, cf, rng, o)
	-- a wind chime (furin) under the eave, by the door
	local y = (o and o.eave or 12) - 1.2
	local top = at(cf, 0, y, -0.7)
	rod(p, "ChimeBracket", top, at(cf, 0, y + 0.2, 0), 0.1, Metal, DARK)
	local ch = model(p, "WindChime")
	rod(ch, "ChimeString", top, top - UP * 0.5, 0.04, Fabric, rgb(220, 60, 50))
	ellipsoid(ch, "ChimeBell", Vector3.new(0.6, 0.55, 0.6), CFrame.new(top - UP * 0.75), Glass, pick({ rgb(200, 230, 240), rgb(240, 220, 220) }, rng)).Transparency = 0.3
	rod(ch, "ChimeTongue", top - UP * 0.8, top - UP * 1.3, 0.04, Fabric, rgb(220, 60, 50))
	part(ch, "Tanzaku", Vector3.new(0.35, 0.9, 0.03), top - UP * 1.8, Smooth, pick({ rgb(240, 236, 226), rgb(220, 200, 100), rgb(200, 120, 160) }, rng))
	Wind.sway(ch, top, 0.35, rng, rng:NextNumber(1.2, 1.8))
end }

Props.STOOP = { "pots", "pots", "crates", "gas", "bicycle", "umbrellas", "firewood", "barrel", "chime", "chime" }

-- ===== Out on the deck =====

local O = {}

O.vending = { size = Vector3.new(4.4, 0, 3.2), build = function(p, cf, rng)
	local m = model(p, "VendingMachine")
	local body = pick({ rgb(232, 232, 228), rgb(180, 40, 40), rgb(40, 80, 160), rgb(40, 120, 70) }, rng)
	part(m, "VendingBody", Vector3.new(4.2, 7, 3), cf * CFrame.new(0, 3.5, 0), Smooth, body)
	local lit = rng:NextNumber() < 0.7
	local win = part(m, "VendingWindow", Vector3.new(3.6, 3.4, 0.1), cf * CFrame.new(0, 4.7, -1.52), if lit then Neon else Glass, rgb(220, 235, 250))
	win.Transparency = if lit then 0.35 else 0.4
	for row = 0, 1 do
		for k = 0, 4 do
			deco(part(m, "Can", Vector3.new(0.5, 1, 0.12), cf * CFrame.new(-1.4 + k * 0.7, 3.9 + row * 1.6, -1.64), Smooth, pick(VIVID, rng)))
		end
	end
	deco(part(m, "Buttons", Vector3.new(3.6, 0.3, 0.12), cf * CFrame.new(0, 3.1, -1.58), Neon, rgb(255, 120, 60)))
	part(m, "Tray", Vector3.new(3, 0.9, 0.4), cf * CFrame.new(0, 1, -1.6), Smooth, DARK)
	label(m, cf * CFrame.new(0, 6.6, -1.56), Vector3.new(4, 0.7, 0.05), Enum.NormalId.Front, pick({ "つめた～い", "COLD DRINKS", "自動販売機", "あったか～い" }, rng), darken(body, 0.8), rgb(240, 240, 240), Smooth, Enum.Font.GothamBlack)
	if lit then
		Props.light(win, 14, rgb(220, 235, 255), 0.8)
	end
	-- a bin beside it
	cylinder(m, "Bin", 1.8, 1.2, CFrame.new(at(cf, 2.9, 0.9, -0.6)) * UPRIGHT, Metal, rgb(90, 110, 100))
end }

O.stove = { size = Vector3.new(7, 0, 7), build = function(p, cf, rng)
	local c = at(cf, 0, 0, 0)
	cylinder(p, "Drum", 3, 2.1, CFrame.new(c + UP * 1.5) * UPRIGHT, Rust, rgb(110, 70, 50))
	deco(part(p, "Grill", Vector3.new(2, 0.1, 2), c + UP * 3.05, Metal, DARK))
	local glow = deco(part(p, "Embers", Vector3.new(1.4, 0.4, 1.4), c + UP * 2.8, Neon, rgb(255, 120, 40)))
	Props.light(glow, 16, rgb(255, 150, 80), 1.2)
	cylinder(p, "Kettle", 0.9, 1, CFrame.new(c + UP * 3.6) * UPRIGHT, Metal, rgb(60, 60, 60))
	local src = part(p, "Smoke", Vector3.new(0.6, 0.2, 0.6), c + UP * 3.4, Smooth, DARK)
	src.Transparency, src.CanCollide, src.CanQuery, src.CanTouch = 1, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 3
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(1.5, 2.5)
	e.Acceleration = Wind.DIR * 4 + UP * 0.4
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	e.Parent = src
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local sp = c + Vector3.new(math.cos(a) * 2.8, 0, math.sin(a) * 2.8)
		if k == 0 then
			part(p, "Stool", Vector3.new(1.6, 1.1, 2.2), CFrame.new(sp + UP * 0.55) * CFrame.Angles(0, a, 0), Plastic, pick(CRATES, rng))
		else
			cylinder(p, "Stool", 1.5, 1.3, CFrame.new(sp + UP * 0.75) * UPRIGHT, Wood, rgb(130, 100, 70))
		end
	end
end }

O.bench = { size = Vector3.new(5.2, 0, 2), build = function(p, cf, rng)
	local color = jitter(rgb(120, 90, 60), rng, 0.1)
	part(p, "BenchSeat", Vector3.new(5, 0.3, 1.4), cf * CFrame.new(0, 1.65, 0), Wood, color)
	part(p, "BenchBack", Vector3.new(5, 1.1, 0.25), cf * CFrame.new(0, 2.6, 0.7) * CFrame.Angles(-0.12, 0, 0), Wood, color)
	for _, x in ipairs({ -2, 2 }) do
		part(p, "BenchLeg", Vector3.new(0.4, 1.5, 1.3), cf * CFrame.new(x, 0.75, 0), Metal, DARK)
	end
	if rng:NextNumber() < 0.4 then
		deco(cylinder(p, "Cup", 0.5, 0.45, CFrame.new(at(cf, 1.4, 2.05, 0)) * UPRIGHT, Smooth, rgb(230, 226, 214)))
	end
end }

O.jizo = { size = Vector3.new(2.4, 0, 2.4), build = function(p, cf, rng)
	part(p, "JizoBase", Vector3.new(2, 0.9, 2), cf * CFrame.new(0, 0.45, 0), Concrete, rgb(140, 138, 130))
	ellipsoid(p, "JizoBody", Vector3.new(1.2, 2.2, 1.1), cf * CFrame.new(0, 2, 0), Concrete, rgb(150, 150, 144))
	local head = part(p, "JizoHead", Vector3.new(0.9, 0.9, 0.9), cf * CFrame.new(0, 3.5, 0), Concrete, rgb(156, 156, 150))
	head.Shape = Enum.PartType.Ball
	deco(part(p, "Bib", Vector3.new(1, 0.8, 0.12), cf * CFrame.new(0, 2.6, -0.52) * CFrame.Angles(-0.25, 0, 0), Fabric, rgb(200, 40, 36)))
	deco(ellipsoid(p, "Cap", Vector3.new(0.95, 0.45, 0.95), cf * CFrame.new(0, 3.95, 0), Fabric, rgb(200, 40, 36)))
	deco(cylinder(p, "Offering", 0.3, 0.5, CFrame.new(at(cf, 0.5, 0.95, -0.6)) * UPRIGHT, Smooth, rgb(236, 232, 222)))
	for _, x in ipairs({ -0.7, 0.7 }) do
		deco(cylinder(p, "Vase", 0.6, 0.3, CFrame.new(at(cf, x, 1.2, -0.7)) * UPRIGHT, Smooth, rgb(60, 80, 70)))
		deco(ellipsoid(p, "Flowers", Vector3.new(0.5, 0.6, 0.5), CFrame.new(at(cf, x, 1.7, -0.7)), Smooth, pick({ rgb(240, 200, 60), rgb(220, 60, 80), rgb(240, 236, 230) }, rng)))
	end
	-- a pinwheel stuck in beside him
	local stick = at(cf, -0.9, 0, 0.4)
	deco(rod(p, "PinStick", stick, stick + UP * 2.6, 0.08, Wood, rgb(200, 190, 160)))
end }

O.notice = { size = Vector3.new(4.2, 0, 1.4), build = function(p, cf, rng)
	for _, x in ipairs({ -1.8, 1.8 }) do
		rod(p, "NoticePost", at(cf, x, 0, 0), at(cf, x, 6.4, 0), 0.35, Wood, TIMBER)
	end
	part(p, "NoticeBoard", Vector3.new(4, 3, 0.3), cf * CFrame.new(0, 4.2, 0), Wood, rgb(120, 94, 64))
	part(p, "NoticeRoof", Vector3.new(4.8, 0.2, 1.2), cf * CFrame.new(0, 6.1, 0) * CFrame.Angles(0.2, 0, 0), Rust, rgb(80, 90, 90))
	local posters = { "尋ね人", "水の配給", "集会", "注意", "猫さがし", "求む", "修理します", "風の日" }
	for k = 0, 3 do
		local x, y = -1.1 + (k % 2) * 2.2 + rng:NextNumber(-0.2, 0.2), 4.9 - math.floor(k / 2) * 1.4
		label(p, cf * CFrame.new(x, y, -0.17) * CFrame.Angles(0, 0, rng:NextNumber(-0.08, 0.08)), Vector3.new(1.5, 1.1, 0.02), Enum.NormalId.Front, pick(posters, rng), pick({ rgb(240, 236, 222), rgb(240, 220, 160), rgb(220, 230, 240) }, rng), pick({ rgb(30, 30, 30), rgb(160, 30, 30) }, rng), Smooth, Enum.Font.GothamBold)
	end
end }

O.washing = { size = Vector3.new(8, 0, 2.4), build = function(p, cf, rng)
	for _, x in ipairs({ -3.6, 3.6 }) do
		rod(p, "WashPost", at(cf, x, 0, 0), at(cf, x, 6.4, 0), 0.3, Metal, rgb(150, 150, 146))
		rod(p, "WashArm", at(cf, x, 6.2, -0.7), at(cf, x, 6.2, 0.7), 0.2, Metal, rgb(150, 150, 146))
		part(p, "WashFoot", Vector3.new(1.2, 0.5, 1.2), at(cf, x, 0.25, 0), Concrete, rgb(140, 138, 130))
	end
	for _, z in ipairs({ -0.6, 0.6 }) do
		rod(p, "WashPole", at(cf, -3.8, 6.3, z), at(cf, 3.8, 6.3, z), 0.2, Wood, rgb(190, 170, 110))
		local f = -3.2
		while f < 2.8 do
			local w = rng:NextNumber(1, 2)
			Wind.cloth(p, at(cf, f, 6.2, z), at(cf, f + w, 6.2, z), rng:NextNumber(1.6, 3), cf.RightVector:Cross(UP), rng, {
				name = "Laundry", color = pick({ rgb(236, 232, 222), rgb(120, 150, 190), rgb(200, 120, 120), rgb(90, 90, 96), rgb(230, 200, 120), rgb(160, 200, 170) }, rng), thick = 0.06, strip = 0.7,
			})
			f += w + rng:NextNumber(0.4, 1.2)
		end
	end
end }

O.drying = { size = Vector3.new(4.4, 0, 1.6), build = function(p, cf, rng)
	local fish = rng:NextNumber() < 0.4
	for _, x in ipairs({ -2, 2 }) do
		rod(p, "RackPost", at(cf, x, 0, 0), at(cf, x, 5.6, 0), 0.25, Wood, TIMBER)
	end
	rod(p, "RackBar", at(cf, -2.1, 5.4, 0), at(cf, 2.1, 5.4, 0), 0.2, Wood, TIMBER)
	for k = 0, 4 do
		local x = -1.6 + k * 0.8
		deco(rod(p, "RackString", at(cf, x, 5.4, 0), at(cf, x, 3, 0), 0.04, Fabric, ROPE))
		for j = 0, 3 do
			if fish then
				deco(part(p, "DriedFish", Vector3.new(0.12, 0.8, 0.35), at(cf, x, 4.9 - j * 0.6, 0), Smooth, rgb(150, 140, 110)))
			else
				local b = deco(part(p, "Persimmon", Vector3.new(0.4, 0.45, 0.4), at(cf, x, 4.9 - j * 0.6, 0), Smooth, rgb(200, 110, 40)))
				b.Shape = Enum.PartType.Ball
			end
		end
	end
end }

O.yatai = { size = Vector3.new(6.4, 0, 5.4), build = function(p, cf, rng)
	local y = model(p, "Yatai")
	part(y, "CartBody", Vector3.new(5.4, 2.4, 2.8), cf * CFrame.new(0, 2.2, 0.6), Wood, rgb(130, 90, 56))
	part(y, "CartCounter", Vector3.new(5.8, 0.25, 1.2), cf * CFrame.new(0, 3.5, -0.9), Wood, rgb(150, 110, 70))
	for _, x in ipairs({ -1.8, 1.8 }) do
		cylinder(y, "CartWheel", 0.35, 2.6, cf * CFrame.new(x, 1.3, 2.1), Wood, rgb(90, 66, 44))
	end
	for _, x in ipairs({ -2.6, 2.6 }) do
		rod(y, "CartPost", at(cf, x, 3.4, 1.8), at(cf, x, 7.4, 1.8), 0.25, Wood, TIMBER)
		rod(y, "CartPost", at(cf, x, 3.4, -0.4), at(cf, x, 7.2, -0.4), 0.25, Wood, TIMBER)
	end
	part(y, "CartRoof", Vector3.new(6.4, 0.25, 3.4), cf * CFrame.new(0, 7.5, 0.6) * CFrame.Angles(-0.15, 0, 0), Rust, rgb(90, 60, 50))
	Wind.cloth(y, at(cf, -2.7, 7.1, -0.7), at(cf, 2.7, 7.1, -0.7), 1.6, cf.LookVector, rng, { name = "Noren", color = rgb(160, 44, 38), strip = 0.8, stiff = 0.2 })
	local pot = cylinder(y, "Pot", 1.2, 1.6, CFrame.new(at(cf, -1.4, 3.6 + 0.6, 0.6)) * UPRIGHT, Metal, rgb(160, 160, 156))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 4
	e.Lifetime = NumberRange.new(1.5, 2.5)
	e.Speed = NumberRange.new(1, 2)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	e.EmissionDirection = Enum.NormalId.Right
	e.Parent = pot
	local lan = ellipsoid(y, "Lantern", Vector3.new(1.4, 2, 1.4), cf * CFrame.new(2.2, 6.2, -0.9), Neon, rgb(255, 140, 80))
	lan.CanCollide = false
	Props.light(lan, 18, rgb(255, 160, 100), 1)
	label(y, cf * CFrame.new(0, 6.2, -0.75), Vector3.new(3, 0.9, 0.05), Enum.NormalId.Front, pick({ "ラーメン", "おでん", "やきとり", "そば" }, rng), rgb(236, 226, 196), rgb(160, 30, 26), Wood, Enum.Font.GothamBlack)
	for _, x in ipairs({ -1.6, 0, 1.6 }) do
		cylinder(p, "Stool", 1.8, 1.1, CFrame.new(at(cf, x, 0.9, -2.2)) * UPRIGHT, Wood, rgb(130, 100, 70))
	end
	for k = 0, 1 do
		deco(cylinder(y, "Bowl", 0.35, 0.9, CFrame.new(at(cf, -0.6 + k * 1.4, 3.8, -0.9)) * UPRIGHT, Smooth, rgb(236, 232, 222)))
	end
end }

O.sake = { size = Vector3.new(4.2, 0, 2.4), build = function(p, cf, rng)
	for k = 0, 2 do
		local x = -1.3 + k * 1.3
		local c = CFrame.new(at(cf, x, 1.05, 0)) * UPRIGHT
		cylinder(p, "Taru", 2.1, 1.9, c, Wood, rgb(200, 170, 120))
		deco(cylinder(p, "TaruWrap", 1.2, 1.98, c, Fabric, rgb(220, 206, 170)))
		label(p, CFrame.lookAt(at(cf, x, 1.1, -1), at(cf, x, 1.1, -2)), Vector3.new(0.8, 0.8, 0.02), Enum.NormalId.Front, "酒", rgb(220, 206, 170), pick({ rgb(160, 30, 30), rgb(30, 40, 90) }, rng), Fabric, Enum.Font.GothamBlack).Transparency = 1
	end
	cylinder(p, "Taru", 2.1, 1.9, CFrame.new(at(cf, -0.65, 3.15, 0)) * UPRIGHT, Wood, rgb(200, 170, 120))
end }

O.tree = { size = Vector3.new(2.6, 0, 2.6), build = function(p, cf, rng)
	part(p, "BigPot", Vector3.new(2.2, 1.6, 2.2), cf * CFrame.new(0, 0.8, 0), Enum.Material.Slate, jitter(rgb(110, 80, 60), rng, 0.1))
	local h = rng:NextNumber(3.5, 5.5)
	rod(p, "Trunk", at(cf, 0, 1.6, 0), at(cf, rng:NextNumber(-0.4, 0.4), 1.6 + h, rng:NextNumber(-0.4, 0.4)), 0.4, Wood, rgb(90, 70, 50))
	for _ = 1, 3 do
		deco(ellipsoid(p, "Leaves", Vector3.new(rng:NextNumber(2, 3), rng:NextNumber(1.4, 2.2), rng:NextNumber(2, 3)), CFrame.new(at(cf, rng:NextNumber(-0.7, 0.7), 1.6 + h + rng:NextNumber(-0.5, 0.6), rng:NextNumber(-0.7, 0.7))), Grass, jitter(rgb(70, 120, 60), rng, 0.15)))
	end
end }

O.parasol = { size = Vector3.new(3.4, 0, 3.4), build = function(p, cf, rng)
	-- an umbrella open, left to dry
	local c = cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(rng:NextNumber(0.6, 1), rng:NextNumber(0, 6), 0)
	deco(ellipsoid(p, "OpenUmbrella", Vector3.new(3.2, 1.1, 3.2), c, Fabric, pick({ rgb(60, 110, 190), rgb(200, 50, 44), rgb(240, 236, 226), rgb(230, 190, 50) }, rng)))
	deco(rod(p, "UmbrellaShaft", (c * CFrame.new(0, 0.4, 0)).Position, (c * CFrame.new(0, -1.8, 0)).Position, 0.1, Metal, DARK))
end }

O.post = { size = Vector3.new(1.6, 0, 1.6), build = function(p, cf, rng)
	cylinder(p, "PostBox", 3.2, 1.3, CFrame.new(at(cf, 0, 1.6, 0)) * UPRIGHT, Smooth, rgb(200, 40, 36))
	deco(ellipsoid(p, "PostCap", Vector3.new(1.45, 0.6, 1.45), CFrame.new(at(cf, 0, 3.25, 0)), Smooth, rgb(190, 36, 32)))
	deco(part(p, "Slot", Vector3.new(0.8, 0.12, 0.1), cf * CFrame.new(0, 2.6, -0.64), Smooth, DARK))
	label(p, cf * CFrame.new(0, 1.9, -0.66), Vector3.new(0.7, 0.7, 0.02), Enum.NormalId.Front, "〒", rgb(200, 40, 36), rgb(240, 240, 236), Smooth, Enum.Font.GothamBlack).Transparency = 1
end }

O.crates = { size = Vector3.new(4, 0, 3), build = function(p, cf, rng)
	for k = 0, rng:NextInteger(2, 4) do
		local c = cf * CFrame.new(-1 + (k % 2) * 2, 0.55 + math.floor(k / 2) * 1.12, rng:NextNumber(-0.3, 0.3)) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0)
		local color = pick(CRATES, rng)
		part(p, "Crate", Vector3.new(1.6, 1.1, 2.2), c, Plastic, color)
		deco(part(p, "CrateInside", Vector3.new(1.3, 0.12, 1.9), c * CFrame.new(0, 0.5, 0), Plastic, darken(color, 0.55)))
	end
end }

Props.OPEN = O
Props.STOOP_KINDS = S

-- ===== On rails =====

-- A futon aired over a rail at `top` (the rail's top), hanging out over
-- `out` (flat) and in.
function Props.futon(p, top, along, out, rng)
	local color = pick({ rgb(220, 120, 130), rgb(120, 160, 210), rgb(240, 236, 226), rgb(230, 200, 120), rgb(150, 190, 150) }, rng)
	local w = 3.2
	for _, s in ipairs({ -1, 1 }) do
		local c = top + out * s * 0.45 - UP * 1.05
		deco(part(p, "Futon", Vector3.new(w, 2.2, 0.35), CFrame.fromMatrix(c, along, UP) * CFrame.Angles(s * 0.15, 0, 0), Fabric, color))
	end
	deco(part(p, "FutonFold", Vector3.new(w, 0.4, 1.1), CFrame.fromMatrix(top + UP * 0.05, along, UP), Fabric, darken(color, 0.9)))
	for _, x in ipairs({ -1, 1 }) do
		deco(part(p, "Peg", Vector3.new(0.2, 0.5, 0.6), top + along * x + UP * 0.2, Plastic, pick(VIVID, rng)))
	end
end

-- A window box of flowers hung on the inside of a rail.
function Props.flowerBox(p, top, along, out, rng)
	local c = top - out * 0.55 - UP * 0.4
	part(p, "FlowerBox", Vector3.new(2.6, 0.8, 0.8), CFrame.fromMatrix(c, along, UP), Wood, rgb(120, 90, 60))
	for k = 0, 4 do
		deco(ellipsoid(p, "Flower", Vector3.new(0.5, 0.5, 0.5), CFrame.new(c + along * (-1 + k * 0.5) + UP * 0.6), Smooth, pick({ rgb(220, 60, 80), rgb(240, 200, 60), rgb(240, 236, 230), rgb(150, 90, 200), rgb(240, 130, 60) }, rng)))
	end
end

-- ===== Underfoot =====

-- A patch on the deck: planks of another colour, or a tin sheet.
function Props.patch(p, pos, rng)
	local rot = CFrame.Angles(0, (rng:NextInteger(0, 1)) * math.pi / 2 + rng:NextNumber(-0.05, 0.05), 0)
	if rng:NextNumber() < 0.7 then
		deco(part(p, "PlankPatch", Vector3.new(rng:NextNumber(1.2, 2.4), 0.06, rng:NextNumber(3, 7)), CFrame.new(pos + UP * 0.03) * rot, Wood, jitter(pick({ rgb(160, 130, 96), rgb(96, 76, 56), rgb(130, 110, 90) }, rng), rng, 0.08)))
	else
		deco(part(p, "TinPatch", Vector3.new(rng:NextNumber(2, 3.5), 0.06, rng:NextNumber(2, 3.5)), CFrame.new(pos + UP * 0.03) * rot, Rust, jitter(rgb(120, 110, 100), rng, 0.1)))
	end
end

-- ===== Down in the damp =====
-- (the fog's harvest, and those who work it)

local WETWOOD = rgb(70, 62, 52)
local LOW = {}

-- A net stretched on a frame for mending, floats along its foot, a stool
-- and a basket.
LOW.netMending = { size = Vector3.new(6.4, 0, 3), build = function(p, cf, rng)
	for _, x in ipairs({ -3, 3 }) do
		rod(p, "NetFramePost", at(cf, x, 0, 0.6), at(cf, x, 5.6, 0.6), 0.3, Wood, WETWOOD)
	end
	rod(p, "NetFrameBar", at(cf, -3.1, 5.4, 0.6), at(cf, 3.1, 5.4, 0.6), 0.25, Wood, WETWOOD)
	local net = deco(part(p, "MendingNet", Vector3.new(5.6, 4.4, 0.08), cf * CFrame.new(0, 3.1, 0.6), Fabric, rgb(190, 200, 196)))
	net.Transparency = 0.5
	for k = 0, 5 do
		local b = deco(part(p, "Float", Vector3.new(0.45, 0.45, 0.45), at(cf, -2.5 + k, 0.9, 0.6), Smooth, rgb(220, 110, 40)))
		b.Shape = Enum.PartType.Ball
	end
	cylinder(p, "Stool", 1.4, 1.1, CFrame.new(at(cf, 0.8, 0.7, -1)) * UPRIGHT, Wood, rgb(120, 96, 70))
	cylinder(p, "Basket", 1.2, 1.5, CFrame.new(at(cf, -1.8, 0.6, -1)) * UPRIGHT, Fabric, rgb(170, 150, 110))
	for k = 0, 2 do
		local b = deco(part(p, "Float", Vector3.new(0.45, 0.45, 0.45), at(cf, -1.8 + (k - 1) * 0.35, 1.35, -1), Smooth, pick({ rgb(220, 110, 40), rgb(70, 140, 110) }, rng)))
		b.Shape = Enum.PartType.Ball
	end
end }

-- A skiff, right way up on trestles, being mended; its oars leant by it.
LOW.boat = { size = Vector3.new(9.4, 0, 4), build = function(p, cf, rng)
	for _, x in ipairs({ -2.6, 2.6 }) do
		part(p, "Trestle", Vector3.new(0.4, 1.6, 3.4), cf * CFrame.new(x, 0.8, 0), Wood, WETWOOD)
	end
	local hull = pick({ rgb(90, 110, 120), rgb(150, 70, 50), rgb(200, 196, 180) }, rng)
	local c = cf * CFrame.new(0, 2.6, 0)
	ellipsoid(p, "Hull", Vector3.new(9, 2.4, 3.4), c, Wood, hull)
	-- (hollow: a darker skin just inside, standing a touch higher)
	deco(ellipsoid(p, "HullInside", Vector3.new(8.4, 1.6, 2.9), c * CFrame.new(0, 0.55, 0), Wood, darken(hull, 0.55)))
	deco(part(p, "Thwart", Vector3.new(0.5, 0.2, 2.8), c * CFrame.new(0.6, 0.9, 0), Wood, WETWOOD))
	for _, z in ipairs({ -1.6, -1.2 }) do
		deco(rod(p, "Oar", at(cf, 4.6, 0.1, z), at(cf, 3.6, 5.2, z), 0.2, Wood, rgb(150, 120, 80)))
	end
end }

-- Water filters: barrels of charcoal and sand, one over another, piped.
LOW.filters = { size = Vector3.new(4.4, 0, 2.6), build = function(p, cf, rng)
	part(p, "FilterStand", Vector3.new(4.2, 2.4, 2.2), cf * CFrame.new(0, 1.2, 0), Wood, WETWOOD)
	for _, x in ipairs({ -1.05, 1.05 }) do
		cylinder(p, "FilterBarrel", 2.8, 1.9, CFrame.new(at(cf, x, 3.8, 0)) * UPRIGHT, Plastic, pick({ rgb(60, 110, 170), rgb(220, 220, 214) }, rng))
		cylinder(p, "Tap", 0.6, 0.3, cf * CFrame.new(x, 2.8, -1) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(170, 140, 60))
		deco(cylinder(p, "Jug", 1.1, 0.9, CFrame.new(at(cf, x, 0.55, -1.4)) * UPRIGHT, Plastic, rgb(230, 230, 226)))
	end
	rod(p, "FilterPipe", at(cf, -1.05, 5.3, 0), at(cf, 1.05, 5.3, 0), 0.3, Metal, rgb(150, 150, 146))
	label(p, cf * CFrame.new(0, 1.6, -1.12), Vector3.new(1.6, 0.8, 0.02), Enum.NormalId.Front, "濾過", rgb(236, 232, 222), rgb(40, 60, 120), Smooth, Enum.Font.GothamBlack)
end }

-- The water's shrine (suijin): a little hokora on a stone, a green lamp,
-- a bowl of water, paper streamers.
LOW.waterShrine = { size = Vector3.new(2.8, 0, 2.8), build = function(p, cf, rng)
	part(p, "ShrineStone", Vector3.new(2.4, 1, 2.2), cf * CFrame.new(0, 0.5, 0), Concrete, rgb(110, 116, 110))
	part(p, "Hokora", Vector3.new(1.8, 2, 1.6), cf * CFrame.new(0, 2, 0.1), Wood, rgb(100, 76, 56))
	part(p, "HokoraRoof", Vector3.new(2.4, 0.25, 2.2), cf * CFrame.new(0, 3.1, 0.1) * CFrame.Angles(-0.15, 0, 0), Metal, rgb(60, 90, 80))
	deco(rod(p, "Shimenawa", at(cf, -1, 2.8, -0.75), at(cf, 1, 2.8, -0.75), 0.18, Fabric, rgb(210, 190, 140)))
	for _, x in ipairs({ -0.5, 0.5 }) do
		deco(part(p, "Shide", Vector3.new(0.2, 0.6, 0.04), at(cf, x, 2.4, -0.78), Smooth, rgb(240, 240, 236)))
	end
	deco(cylinder(p, "WaterBowl", 0.25, 0.7, CFrame.new(at(cf, 0, 1.12, -0.7)) * UPRIGHT, Smooth, rgb(236, 232, 222)))
	local lamp = deco(part(p, "ShrineLamp", Vector3.new(0.5, 0.7, 0.5), at(cf, 0.9, 1.4, -0.7), Neon, rgb(140, 220, 190)))
	Props.light(lamp, 12, rgb(140, 220, 190), 0.7)
end }

-- Rope in coils, and a bucket.
LOW.ropes = { size = Vector3.new(2.6, 0, 2.6), build = function(p, cf, rng)
	for k = 0, rng:NextInteger(1, 2) do
		local c = at(cf, -0.5 + k * 0.9, 0.25 + k * 0.5, rng:NextNumber(-0.3, 0.3))
		cylinder(p, "RopeCoil", 0.5, 1.8 - k * 0.3, CFrame.new(c) * UPRIGHT, Fabric, jitter(rgb(170, 150, 110), rng, 0.1))
		deco(cylinder(p, "CoilHole", 0.52, 0.8 - k * 0.15, CFrame.new(c) * UPRIGHT, Fabric, rgb(60, 50, 40)))
	end
	cylinder(p, "Bucket", 1, 0.9, CFrame.new(at(cf, 0.9, 0.5, 0.7)) * UPRIGHT, Metal, rgb(120, 124, 120))
end }

-- Buckets stacked, and a hose in a coil.
LOW.buckets = { size = Vector3.new(2.6, 0, 2), build = function(p, cf, rng)
	for k = 0, 3 do
		cylinder(p, "Bucket", 1, 1, CFrame.new(at(cf, -0.6, 0.5 + k * 0.35, 0)) * UPRIGHT, Plastic, pick({ rgb(60, 110, 170), rgb(220, 180, 40), rgb(190, 60, 44) }, rng))
	end
	cylinder(p, "Hose", 0.4, 1.6, CFrame.new(at(cf, 0.8, 0.2, 0.2)) * UPRIGHT, Plastic, rgb(60, 130, 70))
	deco(cylinder(p, "HoseHole", 0.42, 0.8, CFrame.new(at(cf, 0.8, 0.2, 0.2)) * UPRIGHT, Plastic, rgb(40, 40, 40)))
end }

-- Glass floats strung between two posts to dry.
LOW.floats = { size = Vector3.new(6.4, 0, 1.2), build = function(p, cf, rng)
	for _, x in ipairs({ -3, 3 }) do
		rod(p, "FloatPost", at(cf, x, 0, 0), at(cf, x, 5, 0), 0.25, Wood, WETWOOD)
	end
	local prev = at(cf, -3, 4.6, 0)
	for k = 1, 8 do
		local t = k / 9
		local q = at(cf, -3 + 6 * t, 4.6 - 1.2 * 4 * t * (1 - t), 0)
		deco(rod(p, "FloatLine", prev, q, 0.05, Fabric, rgb(170, 150, 110)))
		local b = deco(part(p, "GlassFloat", Vector3.new(0.7, 0.7, 0.7), q - UP * 0.45, Glass, pick({ rgb(90, 170, 150), rgb(70, 110, 170), rgb(170, 190, 110) }, rng)))
		b.Shape = Enum.PartType.Ball
		b.Transparency = 0.3
		prev = q
	end
	deco(rod(p, "FloatLine", prev, at(cf, 3, 4.6, 0), 0.05, Fabric, rgb(170, 150, 110)))
end }

-- A rack of fog nets hung up to dry, lifting in the draught.
LOW.dryingNets = { size = Vector3.new(6.4, 0, 1.4), build = function(p, cf, rng)
	for _, x in ipairs({ -3, 3 }) do
		rod(p, "RackPost", at(cf, x, 0, 0), at(cf, x, 7.4, 0), 0.3, Wood, WETWOOD)
	end
	rod(p, "RackBar", at(cf, -3.1, 7.2, 0), at(cf, 3.1, 7.2, 0), 0.25, Wood, WETWOOD)
	for _, x in ipairs({ -2.8, 0.1 }) do
		local net = Wind.cloth(p, at(cf, x, 7.1, 0), at(cf, x + 2.6, 7.1, 0), rng:NextNumber(4, 6), cf.LookVector, rng, { name = "DryingNet", color = rgb(196, 206, 202), strip = 1, thick = 0.06 })
		for _, d in ipairs(net:GetChildren()) do
			if d:IsA("BasePart") then
				d.Transparency = 0.5
			end
		end
	end
end }

-- Eel traps (for whatever lives in the fog): long wicker tubes, stacked.
LOW.eelTraps = { size = Vector3.new(3.2, 0, 2.2), build = function(p, cf, rng)
	for k = 0, 2 do
		local row = if k < 2 then 0 else 1
		local x = if k < 2 then -0.6 + k * 1.2 else 0
		cylinder(p, "EelTrap", 3, 1.1, cf * CFrame.new(x, 0.55 + row * 1, 0) * CFrame.Angles(0, math.pi / 2, 0), Fabric, jitter(rgb(160, 140, 100), rng, 0.1))
		deco(cylinder(p, "TrapMouth", 0.2, 0.9, cf * CFrame.new(x, 0.55 + row * 1, -1.52) * CFrame.Angles(0, math.pi / 2, 0), Fabric, rgb(60, 50, 40)))
	end
end }

Props.LOW = LOW

-- ===== Up in the gardens =====

local GARDEN = {}

-- A pergola: four posts, slats over, a vine over those, gourds hanging, a
-- bench under it.
GARDEN.pergola = { size = Vector3.new(5.4, 0, 4.4), build = function(p, cf, rng)
	for _, x in ipairs({ -2.5, 2.5 }) do
		for _, z in ipairs({ -2, 2 }) do
			rod(p, "PergolaPost", at(cf, x, 0, z), at(cf, x, 7, z), 0.35, Wood, TIMBER)
		end
	end
	for x = -2.4, 2.4, 0.8 do
		deco(part(p, "PergolaSlat", Vector3.new(0.2, 0.25, 4.8), cf * CFrame.new(x, 7.1, 0), Wood, TIMBER))
	end
	for _ = 1, 5 do
		deco(ellipsoid(p, "Vine", Vector3.new(rng:NextNumber(1.6, 2.6), 0.8, rng:NextNumber(1.6, 2.6)), CFrame.new(at(cf, rng:NextNumber(-2, 2), 7.5, rng:NextNumber(-1.6, 1.6))), Grass, jitter(rgb(80, 130, 60), rng, 0.15)))
	end
	for _ = 1, 3 do
		local g = at(cf, rng:NextNumber(-2, 2), 6.3, rng:NextNumber(-1.5, 1.5))
		deco(ellipsoid(p, "Gourd", Vector3.new(0.6, 1, 0.6), CFrame.new(g), Smooth, pick({ rgb(200, 180, 90), rgb(110, 150, 70) }, rng)))
	end
	part(p, "BenchSeat", Vector3.new(3.6, 0.3, 1.1), cf * CFrame.new(0, 1.5, 1.2), Wood, rgb(120, 90, 60))
	for _, x in ipairs({ -1.4, 1.4 }) do
		part(p, "BenchLeg", Vector3.new(0.3, 1.4, 1), cf * CFrame.new(x, 0.7, 1.2), Wood, rgb(100, 76, 52))
	end
end }

-- Compost bins, slatted, heaped, a fork stuck in one.
GARDEN.compost = { size = Vector3.new(4.6, 0, 2.2), build = function(p, cf, rng)
	for _, x in ipairs({ -1.15, 1.15 }) do
		part(p, "CompostBin", Vector3.new(2.1, 2, 2), cf * CFrame.new(x, 1, 0), Planks, jitter(rgb(110, 84, 58), rng, 0.1))
		deco(ellipsoid(p, "Compost", Vector3.new(1.8, 0.8, 1.7), cf * CFrame.new(x, 2, 0), Enum.Material.Ground, rgb(60, 44, 32)))
	end
	deco(rod(p, "Fork", at(cf, 1.3, 1.8, 0.2), at(cf, 1.6, 4.4, 0.5), 0.12, Wood, TIMBER))
end }

-- A wheelbarrow of soil.
GARDEN.barrow = { size = Vector3.new(3.6, 0, 1.8), build = function(p, cf, rng)
	part(p, "BarrowTray", Vector3.new(2.2, 0.9, 1.6), cf * CFrame.new(-0.3, 1.1, 0) * CFrame.Angles(0, 0, 0.1), Metal, pick({ rgb(60, 110, 70), rgb(190, 60, 44), rgb(60, 90, 150) }, rng))
	deco(ellipsoid(p, "BarrowSoil", Vector3.new(1.9, 0.6, 1.3), cf * CFrame.new(-0.3, 1.6, 0), Enum.Material.Ground, rgb(60, 44, 32)))
	cylinder(p, "BarrowWheel", 0.3, 1.1, cf * CFrame.new(-1.6, 0.55, 0) * CFrame.Angles(0, math.pi / 2, 0), Smooth, DARK)
	for _, z in ipairs({ -0.6, 0.6 }) do
		rod(p, "BarrowHandle", at(cf, -1.2, 0.9, z), at(cf, 1.7, 1.3, z), 0.14, Wood, TIMBER)
		rod(p, "BarrowLeg", at(cf, 0.6, 0, z), at(cf, 0.6, 0.9, z), 0.12, Metal, DARK)
	end
end }

-- Seed trays on a stepped rack.
GARDEN.seedRack = { size = Vector3.new(4.2, 0, 1.8), build = function(p, cf, rng)
	for k = 0, 2 do
		part(p, "RackShelf", Vector3.new(4, 0.2, 0.9), cf * CFrame.new(0, 0.9 + k * 1, 0.5 - k * 0.45), Wood, TIMBER)
		for j = 0, 3 do
			local tray = cf * CFrame.new(-1.5 + j, 1.05 + k * 1, 0.5 - k * 0.45)
			deco(part(p, "SeedTray", Vector3.new(0.9, 0.12, 0.8), tray, Plastic, DARK))
			deco(ellipsoid(p, "Seedlings", Vector3.new(0.8, 0.3, 0.7), tray * CFrame.new(0, 0.18, 0), Grass, jitter(rgb(110, 170, 80), rng, 0.1)))
		end
	end
	for _, x in ipairs({ -2, 2 }) do
		rod(p, "RackSide", at(cf, x, 0, 0.8), at(cf, x, 3.1, -0.6), 0.2, Wood, TIMBER)
	end
end }

-- A tool shed: a door, tools leant on it.
GARDEN.toolShed = { size = Vector3.new(4.6, 0, 3.6), build = function(p, cf, rng)
	local c = pick({ rgb(110, 130, 110), rgb(150, 110, 80), rgb(120, 120, 130) }, rng)
	part(p, "Shed", Vector3.new(4.2, 5, 3.2), cf * CFrame.new(0, 2.5, 0.2), Planks, c)
	part(p, "ShedRoof", Vector3.new(4.8, 0.25, 3.9), cf * CFrame.new(0, 5.2, 0.2) * CFrame.Angles(-0.18, 0, 0), Rust, rgb(90, 90, 86))
	deco(part(p, "ShedDoor", Vector3.new(1.8, 4, 0.12), cf * CFrame.new(-0.6, 2.1, -1.44), Planks, darken(c, 0.8)))
	for k = 0, 2 do
		deco(rod(p, "Tool", at(cf, 0.8 + k * 0.4, 0, -1.5), at(cf, 0.7 + k * 0.4, 4, -1.7), 0.12, Wood, TIMBER))
	end
	deco(part(p, "Spade", Vector3.new(0.7, 0.9, 0.08), at(cf, 0.8, 0.5, -1.55), Metal, rgb(150, 150, 146)))
end }

-- A little Inari shrine: red, two white foxes.
GARDEN.gardenShrine = { size = Vector3.new(2.8, 0, 2.6), build = function(p, cf, rng)
	part(p, "ShrineStone", Vector3.new(2.4, 0.8, 2.2), cf * CFrame.new(0, 0.4, 0.2), Concrete, rgb(140, 138, 130))
	part(p, "Hokora", Vector3.new(1.6, 1.8, 1.4), cf * CFrame.new(0, 1.7, 0.4), Smooth, rgb(200, 50, 40))
	part(p, "HokoraRoof", Vector3.new(2.2, 0.25, 2), cf * CFrame.new(0, 2.7, 0.4) * CFrame.Angles(-0.15, 0, 0), Metal, rgb(60, 60, 60))
	for _, x in ipairs({ -0.8, 0.8 }) do
		deco(ellipsoid(p, "Fox", Vector3.new(0.45, 0.9, 0.6), cf * CFrame.new(x, 1.25, -0.6), Smooth, rgb(236, 232, 222)))
		deco(part(p, "FoxBib", Vector3.new(0.4, 0.25, 0.05), cf * CFrame.new(x, 1.2, -0.92), Fabric, rgb(200, 40, 36)))
	end
	for _, x in ipairs({ -0.45, 0.45 }) do
		deco(rod(p, "Torii", at(cf, x, 0.8, -1.1), at(cf, x, 2.3, -1.1), 0.12, Smooth, rgb(200, 50, 40)))
	end
	deco(part(p, "ToriiTop", Vector3.new(1.2, 0.14, 0.14), at(cf, 0, 2.3, -1.1), Smooth, rgb(40, 40, 40)))
end }

-- A water butt with a tap, a watering can by it.
GARDEN.waterButt = { size = Vector3.new(2.8, 0, 2.4), build = function(p, cf, rng)
	part(p, "ButtStand", Vector3.new(2, 1, 2), cf * CFrame.new(-0.3, 0.5, 0), Wood, TIMBER)
	cylinder(p, "WaterButt", 3, 2, CFrame.new(at(cf, -0.3, 2.5, 0)) * UPRIGHT, Plastic, pick({ rgb(70, 110, 70), rgb(60, 90, 140) }, rng))
	cylinder(p, "Tap", 0.5, 0.25, cf * CFrame.new(-0.3, 1.4, -1.05) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(170, 140, 60))
	local can = cf * CFrame.new(1, 0.5, -0.4)
	cylinder(p, "WateringCan", 1, 0.9, CFrame.new(can.Position) * UPRIGHT, Metal, rgb(90, 140, 110))
	deco(rod(p, "Spout", (can * CFrame.new(0.3, 0.2, 0)).Position, (can * CFrame.new(1, 0.7, 0)).Position, 0.12, Metal, rgb(90, 140, 110)))
end }

-- Beehives, stacked boxes with lids.
GARDEN.hives = { size = Vector3.new(4, 0, 2), build = function(p, cf, rng)
	for k = 0, 1 do
		local c = cf * CFrame.new(-1.1 + k * 2.2, 0, 0)
		for j = 0, 2 do
			part(p, "Hive", Vector3.new(1.6, 0.8, 1.6), c * CFrame.new(0, 0.4 + j * 0.82, 0), Wood, pick({ rgb(236, 232, 222), rgb(230, 200, 90) }, rng))
		end
		part(p, "HiveLid", Vector3.new(1.9, 0.25, 1.9), c * CFrame.new(0, 2.6, 0), Metal, rgb(150, 150, 146))
	end
end }

Props.GARDEN = GARDEN

-- ===== Here and there (the pylons' platforms) =====

local MORE = {}

-- A lean-to shelter against the wind: three sides and a roof, a bench in
-- it, a lantern.
MORE.shelter = { size = Vector3.new(5, 0, 4.2), build = function(p, cf, rng)
	local c = pick({ rgb(110, 90, 70), rgb(90, 104, 110), rgb(130, 120, 100) }, rng)
	local mat = pick({ Planks, Rust }, rng)
	part(p, "ShelterBack", Vector3.new(4.8, 6, 0.3), cf * CFrame.new(0, 3, 1.9), mat, c)
	for _, x in ipairs({ -2.3, 2.3 }) do
		part(p, "ShelterSide", Vector3.new(0.3, 6, 4), cf * CFrame.new(x, 3, 0), mat, c)
	end
	part(p, "ShelterRoof", Vector3.new(5.4, 0.25, 4.8), cf * CFrame.new(0, 6.3, 0) * CFrame.Angles(0.18, 0, 0), Rust, rgb(90, 90, 86))
	part(p, "ShelterBench", Vector3.new(4.2, 0.3, 1.2), cf * CFrame.new(0, 1.5, 1.1), Wood, rgb(120, 90, 60))
	deco(part(p, "ShelterBenchFront", Vector3.new(4.2, 1.4, 0.2), cf * CFrame.new(0, 0.75, 0.55), Wood, rgb(100, 76, 52)))
	local l = deco(ellipsoid(p, "Lantern", Vector3.new(1.2, 1.6, 1.2), cf * CFrame.new(1.6, 5, 0.2), Neon, rgb(255, 150, 90)))
	Props.light(l, 14)
end }

-- A forge: a brick hearth glowing, a hood, an anvil on its block, a
-- quench tub.
MORE.forge = { size = Vector3.new(5, 0, 3.4), build = function(p, cf, rng)
	part(p, "Hearth", Vector3.new(2.6, 2.4, 2.4), cf * CFrame.new(-1.1, 1.2, 0.3), Enum.Material.Brick, rgb(110, 60, 46))
	local coals = deco(part(p, "Coals", Vector3.new(1.8, 0.3, 1.6), cf * CFrame.new(-1.1, 2.5, 0.3), Neon, rgb(255, 110, 40)))
	Props.light(coals, 14, rgb(255, 130, 60), 1.3)
	part(p, "Hood", Vector3.new(2.8, 1.2, 2.6), cf * CFrame.new(-1.1, 4.6, 0.3), Metal, rgb(60, 60, 60))
	rod(p, "Flue", at(cf, -1.1, 5.2, 0.3), at(cf, -1.1, 8.6, 0.3), 0.8, Metal, rgb(60, 60, 60))
	for _, x in ipairs({ -2.2, 0 }) do
		deco(rod(p, "HoodLeg", at(cf, x, 2.4, -0.8), at(cf, x, 4, -0.8), 0.15, Metal, DARK))
	end
	part(p, "AnvilBlock", Vector3.new(1, 1.4, 1), cf * CFrame.new(1.4, 0.7, -0.4), Wood, rgb(90, 66, 44))
	part(p, "Anvil", Vector3.new(1.6, 0.6, 0.6), cf * CFrame.new(1.4, 1.7, -0.4), Metal, rgb(50, 50, 52))
	cylinder(p, "Quench", 1.2, 1.4, CFrame.new(at(cf, 2, 0.6, 1)) * UPRIGHT, Wood, rgb(110, 84, 58))
	deco(rod(p, "Tongs", at(cf, 1.9, 1.2, 1), at(cf, 1.6, 2.4, 0.9), 0.08, Metal, DARK))
end }

-- A radio: a set on a table, headphones, an aerial run up behind.
MORE.radio = { size = Vector3.new(3.4, 0, 2.2), build = function(p, cf, rng)
	part(p, "RadioTable", Vector3.new(3, 2.6, 1.6), cf * CFrame.new(0, 1.3, 0), Wood, rgb(110, 84, 58))
	part(p, "RadioSet", Vector3.new(1.8, 1, 1), cf * CFrame.new(-0.3, 3.1, 0.1), Metal, rgb(70, 76, 70))
	local dial = deco(part(p, "Dial", Vector3.new(0.9, 0.35, 0.05), cf * CFrame.new(-0.3, 3.2, -0.42), Neon, rgb(255, 190, 90)))
	dial.Transparency = 0.2
	deco(cylinder(p, "Headphones", 0.2, 0.7, cf * CFrame.new(0.9, 2.75, -0.1), Smooth, DARK))
	rod(p, "Aerial", at(cf, 1.2, 2.6, 0.6), at(cf, 1.4, 11, 0.8), 0.12, Metal, DARK)
	deco(part(p, "Stool", Vector3.new(1, 1.6, 1), cf * CFrame.new(0, 0.8, -1.3), Wood, rgb(120, 96, 70)))
end }

Props.MORE = MORE

return Props
