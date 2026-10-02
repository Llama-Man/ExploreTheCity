-- Kazami (風見, "watching the wind"): the town across the west crossing.
--
-- Before the fog rose, a power line crossed this valley on colossal
-- pylons, and a village stood under it. When the ground went, the people
-- went up the pylons, the only things left standing, and hung their town
-- off them: nothing here stands on anything below. What they live on is
-- the fog itself: huge nets under the decks comb the water out of it. What
-- they live by is the wind, which never stops up here: it turns their
-- turbines, flies the big ones on their tethers, dries their washing, and
-- it has its own shrine.
--
-- How it hangs:
--   the cranes     two pylons' lower arms run on out as jibs, stayed from
--                  their peaks; the big deck A hangs from one's east jib,
--                  and on their other sides, like counterweights, two
--                  smaller islands (the bath-house, a house)
--   the legs       the shrine's deck, C, stands on four great raking legs
--                  splayed out down into the fog, tied in pairs, and braced
--                  back to its pylon
--   the balance    the market deck, B, hangs from one end of a great beam
--                  pivoted in the tallest pylon, and a tank of the town's
--                  water hangs from the other end to balance it, a
--                  cogwheel turning slowly at the pivot
--   the sky beams  steel bridges between the pylons' gardens, walkable on
--                  top; islands hang under them, and a garden sits on one
-- Each hangs from a frame over it (cables up from its corners to the
-- hooks), so nothing stands under it and it floats. Two of the smaller
-- ones, under the sky beams, stand instead on one great strut each (an
-- old steel column, a brick chimney) braced out to their corners, with a
-- ladder down through a hatch to a ledge round the strut's head.
--
-- Three layers, and the pylons through all of them:
--   the undercroft (y 70 - 110) hung under the three big decks, down in
--               the damp: fog nets the size of houses, cisterns, pump
--               houses, pipes climbing to the town; boardwalks to the
--               pylons, dim green lamps. (LightingZones: the "damp".)
--   the town    (y 115 - 180) the decks: houses of one and two storeys,
--               the market (by the gate, where the crossing comes in), the
--               water tower, the wind shrine, the bath-house, the workshop;
--               rope bridges between them and the pylons.
--   the sky     (y 190 - 380) the pylons' gardens and the sky beams, the
--               turbines flying above (the big grey aerostats highest), the
--               cable cars between the pylons' arms, and on the tallest,
--               the lighthouse.
-- Stairs go down from each big deck to the undercroft; each pylon has
-- lifts (they carry you: Movers.client) from the undercroft to the town
-- to its garden, and ladders on up to its arms.
--
-- Built from WestCrossing.build. Returns the three big decks, where the
-- crossing's routes come in on their east sides; StiltTown.BLOCKS is the
-- rest of it nearest the crossing, for the routes to keep clear of.

local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local Shacks = require(script.Parent.StoreShacks)
local TunnelProps = require(script.Parent.TunnelProps)
local Pieces = require(script.Parent.CrossingPieces)
local Wind = require(script.Parent.Windblown)
local TownProps = require(script.Parent.TownProps)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local Metal, Rust, Plate, Smooth, Wood, Planks, Fabric, Neon, Glass, Concrete, Grass, Ground = Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.WoodPlanks, Enum.Material.Fabric, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Concrete, Enum.Material.LeafyGrass, Enum.Material.Ground
local rgb = Color3.fromRGB
local UP = Vector3.yAxis
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local TAU = math.pi * 2

local DEEP = -380 -- (stilts go down this far: well into the dark)
local STEEL = rgb(112, 116, 118)
local TIMBER = rgb(110, 84, 58)
local WET = rgb(62, 58, 50)
local ROPE = rgb(170, 150, 110)
local DARK = rgb(28, 28, 30)
local YELLOW = rgb(214, 170, 46)
local NETTING = rgb(200, 210, 206)
local DECKS = { rgb(140, 112, 80), rgb(120, 100, 76), rgb(150, 126, 92) }
local TIN = { rgb(130, 120, 110), rgb(150, 80, 60), rgb(80, 110, 120), rgb(120, 110, 70), rgb(70, 90, 80) }
local WALLS = { rgb(160, 130, 96), rgb(120, 100, 80), rgb(170, 160, 140), rgb(110, 120, 110), rgb(150, 150, 146), rgb(90, 104, 116) }
local CLOTHS = { rgb(60, 90, 150), rgb(180, 60, 50), rgb(220, 190, 80), rgb(70, 130, 90), rgb(230, 226, 214) }
local WASHING = { rgb(236, 232, 222), rgb(120, 150, 190), rgb(200, 120, 120), rgb(90, 90, 96), rgb(230, 200, 120) }
local NOREN = { rgb(40, 54, 100), rgb(160, 44, 38), rgb(228, 222, 206), rgb(50, 80, 70) }
local LAMP_DAMP = rgb(140, 220, 190)
local STOREY = 13 -- (a storey: the school's floors are 14.5 apart)

-- The islands of the town: where, how high, how big (half sizes); the
-- big three (A, B, C) are where the crossing comes in. `lift`: how high
-- over the deck the frame it hangs from is. Those hung under a sky beam
-- are put at its middle; F sits on top of one.
local ISLANDS = {
	A = { x = -610, z = -115, y = 128, hx = 30, hz = 30, arrive = true, plaza = "water", lift = 36 },
	B = { x = -640, z = 25, y = 146, hx = 30, hz = 30, arrive = true, plaza = "market", lift = 36 },
	C = { x = -625, z = 155, y = 164, hx = 30, hz = 30, arrive = true, plaza = "shrine", support = "legs", brace = "PC" },
	D = { x = -775, z = -115, y = 120, hx = 16, hz = 14, plaza = "bath", lift = 40 },
	E = { x = -717, z = -45, y = 136, hx = 14, hz = 14, plaza = "workshop", support = "steel", hatch = { 5.5, 0 } },
	F = { x = -773, z = 127, y = 210, hx = 12, hz = 8, plaza = "skygarden", onTop = true },
	G = { x = -788, z = 63, y = 150, hx = 12, hz = 12, homes = 2, lift = 34 },
	H = { x = -780, z = 155, y = 170, hx = 12, hz = 10, homes = 1, lift = 34 },
	K = { x = -720, z = 90, y = 158, hx = 9, hz = 9, homes = 1, support = "chimney", hatch = { 5.5, 0 } },
}
local ORDER = { "A", "B", "C", "D", "E", "F", "G", "H", "K" }

-- The pylons: where, how tall; the heights of their decks: the base down
-- in the undercroft, the landing at the town's level, the garden. `east`
-- and `west`: the islands their lower arms carry as cranes; `balance`:
-- the market's beam; `aero` and `kite`: which corners of the garden fly
-- a turbine.
local PYLONS = {
	{ key = "PA", x = -700, z = -115, top = 300, base = 80, landing = 140, garden = 195, east = "A", west = "D", aero = { 1, -1 } },
	{ key = "PB", x = -735, z = 25, top = 350, base = 92, landing = 152, garden = 245, light = true, balance = "B", kite = { -1, -1 } },
	{ key = "PC", x = -705, z = 155, top = 320, base = 106, landing = 168, garden = 215, west = "H", aero = { 1, -1 } },
	{ key = "PD", x = -840, z = 100, top = 280, base = 95, landing = 150, garden = 205, aero = { -1, -1 }, kite = { -1, 1 } },
}
-- The sky beams, garden to garden, and what hangs from (or sits on) each.
local SKY_BEAMS = { { "PA", "PB", "E" }, { "PB", "PC", "K" }, { "PB", "PD", "G" }, { "PD", "PC", "F" } }
local BALANCE_Y = 225 -- (the market's beam, through the tallest pylon)
local COUNTERWEIGHT_X = -830

-- The undercroft: a platform hung under each big deck (a rect, its
-- height), where its cisterns and pump house stand (from its middle), the
-- side its nets are strung along.
local LOWS = {
	A = { x0 = -640, x1 = -600, z0 = -140, z1 = -72, y = 73, nets = "E", tanks = { { 10, 14 }, { 12, -2 } }, shed = { -10, -20 } },
	B = { x0 = -686, x1 = -628, z0 = -18, z1 = 60, y = 91, nets = "N", tanks = { { 14, 10 }, { 14, -12 } }, shed = { -12, -14 } },
	C = { x0 = -670, x1 = -620, z0 = 112, z1 = 178, y = 109, nets = "N", tanks = { { 12, 6 } }, shed = { 2, -12 } },
}

-- Rope bridges between the islands and the pylons' landings (the town's
-- level), and boardwalks between the undercroft and the pylons' bases.
local BRIDGES = {
	{ "A", "PA" }, { "PA", "D" }, { "A", "E" }, { "E", "PA" }, { "B", "E" }, { "B", "PB" }, { "PB", "G" }, { "PD", "G" },
	{ "B", "K" }, { "K", "C" }, { "C", "PC" }, { "PC", "H" }, { "PD", "H" },
}
local LOW_BRIDGES = { { "A", "PA" }, { "B", "PB" }, { "C", "PC" } }

-- Stairs down from the big decks to their platforms below: where on the
-- edge they start, the way out from the deck, the way their flights run.
local STAIRS = {
	A = { at = Vector3.new(-610, 0, -85), side = "N", out = Vector3.new(0, 0, 1), run = Vector3.new(-1, 0, 0) },
	B = { at = Vector3.new(-635, 0, -5), side = "S", out = Vector3.new(0, 0, -1), run = Vector3.new(-1, 0, 0) },
	C = { at = Vector3.new(-625, 0, 125), side = "S", out = Vector3.new(0, 0, -1), run = Vector3.new(-1, 0, 0) },
}

-- A couple of old poles standing up out of the fog on their own: x, z, top.
local POLES = { { -690, 60, 200 }, { -800, -60, 170 } }

local StiltTown = {}
-- The market's deck: the crossing's cables anchor here.
local B0 = ISLANDS.B
StiltTown.GATE = { x0 = B0.x - B0.hx, x1 = B0.x + B0.hx, z0 = B0.z - B0.hz, z1 = B0.z + B0.hz, y = B0.y }
StiltTown.BLOCKS = {}

-- ===== Bits =====

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function deco(p)
	if p then
		p.CanCollide = false
		p.CastShadow = false
	end
	return p
end

local function hidden(p)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

local function marker(parent, pos)
	local p = hidden(part(parent, "LootSpot", Vector3.new(2, 2, 2), pos + UP, Smooth, rgb(255, 0, 0)))
	p:AddTag("LootSpot")
end

local lightsLeft = 0
local function light(p, range, color, brightness)
	if lightsLeft > 0 then
		lightsLeft -= 1
		local l = Instance.new("PointLight")
		l.Range = range
		l.Brightness = brightness or 1.1
		l.Color = color or rgb(255, 190, 120)
		l.Parent = p
	end
end

TownProps.light = light

-- A paper lantern (chochin), lit or not.
local function lantern(parent, pos, rng, lit)
	if lit == nil then
		lit = rng:NextNumber() < 0.6
	end
	local l = deco(ellipsoid(parent, "Lantern", Vector3.new(1.6, 2.2, 1.6), CFrame.new(pos), if lit then Neon else Fabric, if lit then rgb(255, 150, 90) else rgb(190, 60, 50)))
	deco(part(parent, "LanternCap", Vector3.new(1.2, 0.3, 1.2), pos + UP * 1.15, Smooth, DARK))
	if lit then
		light(l, 22)
	end
	return l
end

-- A dim lamp for the damp: a caged bulb on a post.
local function dampLamp(parent, pos)
	rod(parent, "LampPost", pos, pos + UP * 8, 0.4, Metal, darken(STEEL, 0.7))
	local b = deco(part(parent, "DampLamp", Vector3.new(0.9, 1.2, 0.9), pos + UP * 8.4, Neon, LAMP_DAMP))
	b.Transparency = 0.2
	light(b, 26, LAMP_DAMP, 0.7)
end

local function ladder(parent, a, b, color)
	local len = (b - a).Magnitude
	local t = Instance.new("TrussPart")
	t.Name = "Ladder"
	t.Anchored = true
	t.Size = Vector3.new(2, math.max(2, math.ceil(len / 2) * 2), 2)
	t.CFrame = CFrame.new((a + b) / 2)
	t.Material = Metal
	t.Color = color or rgb(150, 120, 60)
	t.Parent = parent
	return t
end

-- Keep clear of this (for the crossing's routes). Only what's anywhere
-- near their way in: they never go far out west.
local function box(cx, cy, cz, sx, sy, sz)
	if cx + sx / 2 > -730 then
		table.insert(StiltTown.BLOCKS, { c = Vector3.new(cx, cy, cz), s = Vector3.new(sx, sy, sz) })
	end
end

local function smoke(parent, pos, rate, size)
	local src = hidden(part(parent, "Smoke", Vector3.new(0.6, 0.2, 0.6), pos, Smooth, DARK))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = rate or 3
	e.Lifetime = NumberRange.new(4, 6)
	e.Speed = NumberRange.new(2, 3)
	e.Acceleration = Wind.DIR * 5 + UP * 0.5
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 1), NumberSequenceKeypoint.new(1, (size or 1) * 5) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	e.Parent = src
end

-- A fog net: tied top and bottom, billowing, see-through.
local function fogNet(parent, a, b, drop, face, rng)
	local net = Wind.cloth(parent, a, b, drop, face, rng, {
		name = "FogNet", color = NETTING, bottom = (a + b) / 2 - UP * drop, billow = 1.8, strip = 1.4, thick = 0.1,
	})
	for _, d in ipairs(net:GetChildren()) do
		if d:IsA("BasePart") then
			d.Transparency = 0.55
		end
	end
	return net
end

-- Rectangles of `r` ({x0,x1,z0,z1}) with the holes taken out.
local function minus(rects, hole)
	local out = {}
	for _, r in ipairs(rects) do
		if hole.x0 >= r.x1 or hole.x1 <= r.x0 or hole.z0 >= r.z1 or hole.z1 <= r.z0 then
			table.insert(out, r)
		else
			if hole.x0 > r.x0 then
				table.insert(out, { x0 = r.x0, x1 = hole.x0, z0 = r.z0, z1 = r.z1 })
			end
			if hole.x1 < r.x1 then
				table.insert(out, { x0 = hole.x1, x1 = r.x1, z0 = r.z0, z1 = r.z1 })
			end
			local x0, x1 = math.max(r.x0, hole.x0), math.min(r.x1, hole.x1)
			if hole.z0 > r.z0 then
				table.insert(out, { x0 = x0, x1 = x1, z0 = r.z0, z1 = hole.z0 })
			end
			if hole.z1 < r.z1 then
				table.insert(out, { x0 = x0, x1 = x1, z0 = hole.z1, z1 = r.z1 })
			end
		end
	end
	return out
end

-- A plank deck over a rectangle, holes cut out, a rim beam round it.
local function deck(m, r, y, holes, rng, material, color)
	local rects = { r }
	for _, h in ipairs(holes or {}) do
		rects = minus(rects, h)
	end
	color = color or jitter(pick(DECKS, rng), rng, 0.05)
	local parts = {}
	for _, q in ipairs(rects) do
		if q.x1 - q.x0 > 0.2 and q.z1 - q.z0 > 0.2 then
			table.insert(parts, part(m, "Deck", Vector3.new(q.x1 - q.x0, 0.8, q.z1 - q.z0), Vector3.new((q.x0 + q.x1) / 2, y - 0.4, (q.z0 + q.z1) / 2), material or Planks, color))
		end
	end
	for _, e in ipairs({ { r.x0, r.z0, r.x1, r.z0 }, { r.x0, r.z1, r.x1, r.z1 }, { r.x0, r.z0, r.x0, r.z1 }, { r.x1, r.z0, r.x1, r.z1 } }) do
		deco(rod(m, "RimBeam", Vector3.new(e[1], y - 1.4, e[2]), Vector3.new(e[3], y - 1.4, e[4]), 1.2, Wood, darken(TIMBER, 0.8)))
	end
	return parts
end

-- Rope-and-post rail from a to b (deck points).
local function rail(m, a, b, color)
	local n = math.max(1, math.floor((b - a).Magnitude / 5))
	local prev
	for k = 0, n do
		local q = a:Lerp(b, k / n)
		rod(m, "RailPost", q - UP * 0.4, q + UP * 3.6, 0.35, Wood, color or TIMBER)
		if prev then
			for _, y in ipairs({ 1.8, 3.4 }) do
				deco(rod(m, "RailRope", prev + UP * y, q + UP * y, 0.2, Fabric, ROPE))
			end
		end
		prev = q
	end
end

-- A sagging rope bridge from a to b (deck points); `damp` for the
-- boardwalks down in the undercroft.
local function bridge(parent, a, b, rng, damp)
	local m = model(parent, if damp then "Boardwalk" else "RopeBridge")
	local h = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	local side = Vector3.new(-h.Z, 0, h.X)
	local len = (b - a).Magnitude
	local sag = len * (if damp then 0.015 else 0.035)
	local function at(t)
		return a:Lerp(b, t) - UP * (sag * 4 * t * (1 - t))
	end
	local n = math.max(3, math.ceil(len / 1.3))
	local plankColor = if damp then WET else rgb(140, 112, 80)
	for i = 1, n do
		if i <= 2 or i >= n - 1 or rng:NextNumber() > 0.06 then
			local p0, p1 = at((i - 1) / n), at(i / n)
			part(m, "Plank", Vector3.new(6, 0.35, (p1 - p0).Magnitude * 0.9), CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, -0.18, 0), Wood, jitter(plankColor, rng, 0.12))
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		local prev = at(0) + side * s * 2.6 - UP * 0.5
		for i = 1, 12 do
			local p = at(i / 12) + side * s * 2.6 - UP * 0.5
			deco(rod(m, "Stringer", prev, p, 0.35, Fabric, darken(ROPE, 0.7)))
			prev = p
		end
		for _, e in ipairs({ a, b }) do
			rod(m, "BridgePost", e + side * s * 3.2 - UP * 1, e + side * s * 3.2 + UP * 5, 0.8, Wood, if damp then WET else TIMBER)
		end
		local prevR = at(0) + side * s * 3 + UP * 3.6
		for i = 1, 12 do
			local p = at(i / 12) + side * s * 3 + UP * 3.6
			rod(m, "RopeRail", prevR, p, 0.22, Fabric, ROPE)
			if i % 2 == 0 and i < 12 then
				deco(rod(m, "Suspender", p, at(i / 12) + side * s * 2.6 - UP * 0.4, 0.1, Fabric, ROPE))
			end
			prevR = p
		end
	end
	if damp then
		for _, t in ipairs({ 0.33, 0.66 }) do
			local p = at(t) + side * 3 + UP * 3.2
			local lamp = deco(part(m, "DampLamp", Vector3.new(0.7, 1, 0.7), p - UP * 0.8, Neon, LAMP_DAMP))
			lamp.Transparency = 0.25
			light(lamp, 18, LAMP_DAMP, 0.6)
		end
	elseif len > 30 then
		-- prayer flags over the longer ones
		local f0, f1 = a + side * 3.2 + UP * 9.4, b + side * 3.2 + UP * 9.4
		local count = math.floor(len / 3)
		local prev = f0
		for i = 1, count do
			local t = i / count
			local p = f0:Lerp(f1, t) - UP * (2.5 * 4 * t * (1 - t))
			deco(rod(m, "FlagLine", prev, p, 0.06, Fabric, rgb(210, 200, 180)))
			deco(part(m, "PrayerFlag", Vector3.new(0.05, 1.4, 1.1), CFrame.lookAt(p - UP * 0.7, p - UP * 0.7 + side), Fabric, pick({ rgb(60, 110, 190), rgb(240, 236, 226), rgb(200, 60, 50), rgb(90, 160, 80), rgb(240, 200, 60) }, rng)))
			prev = p
		end
		for _, e in ipairs({ a, b }) do
			rod(m, "FlagMast", e + side * 3.2 + UP * 5, e + side * 3.2 + UP * 9.6, 0.25, Wood, TIMBER)
		end
	end
	local c = (a + b) / 2
	box(c.X, c.Y + 3, c.Z, math.abs(b.X - a.X) + 9, 16, math.abs(b.Z - a.Z) + 9)
end

-- ===== Houses =====

-- A window on a wall's outside face (cf at the pane's middle, looking
-- out): a frame, the glass (lit or not) with shoji bars, a sill; or
-- closed up with a wooden shutter.
local function window(s, cf, pal, lit, shut)
	deco(part(s, "WindowFrame", Vector3.new(4.4, 4.8, 0.2), cf * CFrame.new(0, 0, -0.1), Wood, pal.frame))
	deco(part(s, "Sill", Vector3.new(4.9, 0.3, 0.7), cf * CFrame.new(0, -2.55, -0.3), Wood, pal.frame))
	if shut then
		deco(part(s, "Shutter", Vector3.new(3.8, 4.2, 0.15), cf * CFrame.new(0, 0, -0.23), Planks, darken(pal.wood, 0.85)))
		return
	end
	local pane = deco(part(s, "Window", Vector3.new(3.8, 4.2, 0.08), cf * CFrame.new(0, 0, -0.2), if lit then Neon else Glass, if lit then rgb(255, 196, 130) else rgb(50, 58, 62)))
	pane.Transparency = if lit then 0.45 else 0.15
	deco(part(s, "WindowBar", Vector3.new(0.14, 4.2, 0.08), cf * CFrame.new(0, 0, -0.27), Wood, pal.frame))
	deco(part(s, "WindowBar", Vector3.new(3.8, 0.14, 0.08), cf * CFrame.new(0, 0.5, -0.27), Wood, pal.frame))
end

local SHOPS = { "八百屋", "魚屋", "雑貨", "茶屋", "修理", "薬", "米", "古着", "水", "酒" }
local WOODS = { rgb(62, 50, 42), rgb(140, 100, 70), rgb(128, 122, 112), rgb(104, 80, 58) }

-- How an island builds: its timber, its walls (planks, or tin), its
-- roofs' tin and shape. Every house on it takes from this, so a street
-- hangs together: different houses, one way of building.
local function palette(rng)
	local wood = pick(WOODS, rng)
	return {
		wood = wood,
		frame = darken(wood, 0.55),
		walls = {
			{ Planks, jitter(wood, rng, 0.04) },
			{ Planks, jitter(pick(WALLS, rng), rng, 0.04) },
			{ Rust, pick(TIN, rng) },
		},
		tin = jitter(pick(TIN, rng), rng, 0.04),
		roof = if rng:NextNumber() < 0.65 then "gable" else "lean",
	}
end

local function wedge(parent, name, size, cf, material, color)
	local p = Instance.new("WedgePart")
	p.Name, p.Anchored, p.Size, p.CFrame, p.Material, p.Color = name, true, size, cf, material, color
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The roof over a storey whose walls top out at `top` (rf: the storey's
-- floor middle, looking out of the front): a gable, pitched both ways, its
-- ends filled in and a ridge cap; or a lean-to, high at the front. Returns
-- the middle of it.
local function roof(s, rf, top, w, depth, kind, tin, gableMat, gableC)
	if kind == "gable" then
		local rise = math.tan(math.rad(24)) * depth / 2
		local ridge = (rf * CFrame.new(0, top + rise, 0)).Position
		for _, sz in ipairs({ -1, 1 }) do
			local eave = (rf * CFrame.new(0, top, sz * depth / 2)).Position
			local dir = (ridge - eave).Unit
			local mid = (eave + ridge) / 2 - dir * 0.6
			part(s, "Roof", Vector3.new(w + 1.6, 0.3, (ridge - eave).Magnitude + 1.3), CFrame.lookAt(mid, mid + dir, rf.UpVector) * CFrame.new(0, 0.3, 0), Rust, tin)
		end
		part(s, "Ridge", Vector3.new(w + 1.8, 0.5, 0.9), rf * CFrame.new(0, top + rise + 0.45, 0), Metal, darken(tin, 0.7))
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				-- (each half of a gable end: tall at the middle, nothing at the eave)
				wedge(s, "Gable", Vector3.new(0.5, rise, depth / 2), rf * CFrame.new(sx * (w / 2 - 0.25), top + rise / 2, sz * depth / 4) * (if sz > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity), gableMat, gableC)
			end
		end
		return ridge
	end
	local rise = math.tan(math.rad(12)) * depth
	local hi = (rf * CFrame.new(0, top + rise, -depth / 2)).Position
	local lo = (rf * CFrame.new(0, top, depth / 2)).Position
	local mid = (hi + lo) / 2
	part(s, "Roof", Vector3.new(w + 1.6, 0.3, (hi - lo).Magnitude + 2), CFrame.lookAt(mid, hi, rf.UpVector) * CFrame.new(0, 0.3, 0), Rust, tin)
	for _, sx in ipairs({ -1, 1 }) do
		wedge(s, "Gable", Vector3.new(0.5, rise, depth), rf * CFrame.new(sx * (w / 2 - 0.25), top + rise / 2, 0) * CFrame.Angles(0, math.pi, 0), gableMat, gableC)
	end
	part(s, "FrontStrip", Vector3.new(w, rise, 0.5), rf * CFrame.new(0, top + rise / 2, -depth / 2 + 0.25), gableMat, gableC)
	return mid
end

-- A house with its back to an edge: `cf` at the middle of its floor,
-- looking out of its front door. Built one way (the island's palette):
-- a dark timber frame (corner posts, a beam at each floor), walls of
-- planks or tin between; the door to one side under a little tin canopy,
-- a window in the rest of the front and in each side, lined up; an upper
-- storey jutting out over the front on brackets, sometimes, with a
-- balcony; a gable or a lean-to roof. o: palette, shop (an open front, a
-- counter, goods, a sign). Returns the middle of its roof, and where its
-- door is.
local function house(m, cf, w, d, storeys, rng, o)
	o = o or {}
	local pal = o.palette or palette(rng)
	local s = model(m, if o.shop then "Shop" else "House")
	local H, T = STOREY, 0.5
	local opt = pick({ pal.walls[1], pal.walls[1], pal.walls[2], pal.walls[3] }, rng)
	local mat, wallC = opt[1], opt[2]
	local lit = rng:NextNumber() < 0.5
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	part(s, "Floor", Vector3.new(w, 0.3, d), at(0, 0.15, 0), Wood, darken(pal.wood, 0.8))
	part(s, "Wall", Vector3.new(w, H, T), at(0, H / 2, d / 2 - T / 2), mat, wallC)
	for _, sd in ipairs({ -1, 1 }) do
		part(s, "Wall", Vector3.new(T, H, d), at(sd * (w / 2 - T / 2), H / 2, 0), mat, wallC)
	end
	-- the front: the door to one side (a shop's open front in the middle)
	local doorW = if o.shop then math.min(w - 4, 10) else 4.4
	local doorH = if o.shop then 9.5 else 9
	local doorX = if o.shop then 0 else pick({ -1, 1 }, rng) * (w / 2 - doorW / 2 - 2.2)
	local lw, rw = doorX - doorW / 2 + w / 2, w / 2 - (doorX + doorW / 2)
	if lw > 0.2 then
		part(s, "Wall", Vector3.new(lw, H, T), at(-w / 2 + lw / 2, H / 2, -d / 2 + T / 2), mat, wallC)
	end
	if rw > 0.2 then
		part(s, "Wall", Vector3.new(rw, H, T), at(w / 2 - rw / 2, H / 2, -d / 2 + T / 2), mat, wallC)
	end
	part(s, "Wall", Vector3.new(doorW, H - doorH, T), at(doorX, doorH + (H - doorH) / 2, -d / 2 + T / 2), mat, wallC)
	-- the frame: corner posts, a beam round the top of the storey, the
	-- door's own frame
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(s, "Post", Vector3.new(0.9, H, 0.9), at(sx * (w / 2 - 0.3), H / 2, sz * (d / 2 - 0.3)), Wood, pal.frame)
		end
	end
	part(s, "Beam", Vector3.new(w + 0.3, 0.8, 0.8), at(0, H - 0.4, -d / 2 + 0.25), Wood, pal.frame)
	for _, sd in ipairs({ -1, 1 }) do
		part(s, "Beam", Vector3.new(0.8, 0.8, d + 0.3), at(sd * (w / 2 - 0.25), H - 0.4, 0), Wood, pal.frame)
	end
	for _, sd in ipairs({ -1, 1 }) do
		part(s, "DoorPost", Vector3.new(0.5, doorH, 0.8), at(doorX + sd * (doorW / 2 + 0.25), doorH / 2, -d / 2 + 0.25), Wood, pal.frame)
	end
	part(s, "Lintel", Vector3.new(doorW + 1, 0.6, 0.8), at(doorX, doorH + 0.3, -d / 2 + 0.25), Wood, pal.frame)
	-- a little tin canopy over the door, on brackets
	if not o.shop then
		part(s, "Canopy", Vector3.new(doorW + 2.4, 0.2, 2.4), at(doorX, doorH + 1.4, -d / 2 - 1.1) * CFrame.Angles(-0.2, 0, 0), Rust, pal.tin)
		for _, sd in ipairs({ -1, 1 }) do
			deco(rod(s, "CanopyBracket", at(doorX + sd * (doorW / 2 + 0.9), doorH - 0.4, -d / 2).Position, at(doorX + sd * (doorW / 2 + 0.9), doorH + 1.1, -d / 2 - 2).Position, 0.2, Wood, pal.frame))
		end
	end
	-- windows, lined up: the rest of the front, and the middle of each side
	if not o.shop then
		local wx = if doorX < 0 then (doorX + doorW / 2 + w / 2) / 2 else (-w / 2 + doorX - doorW / 2) / 2
		if w - doorW - 2.2 >= 6 then
			window(s, at(wx, 5.6, -d / 2), pal, lit, rng:NextNumber() < 0.15)
		end
	end
	for _, sd in ipairs({ -1, 1 }) do
		if d >= 10 then
			window(s, at(sd * w / 2, 5.6, 0) * CFrame.Angles(0, -sd * math.pi / 2, 0), pal, lit, rng:NextNumber() < 0.25)
		end
	end
	-- the upper storey, jutting out over the front on brackets
	local top, depth, rf = H, d, cf
	local gMat, gC = mat, wallC
	if storeys >= 2 then
		local d2 = d + 2
		local up = cf * CFrame.new(0, H, -1)
		local opt2 = pick(pal.walls, rng)
		part(s, "Upper", Vector3.new(w, H - 0.8, d2), up * CFrame.new(0, (H - 0.8) / 2, 0), opt2[1], opt2[2])
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part(s, "Post", Vector3.new(0.9, H - 0.8, 0.9), up * CFrame.new(sx * (w / 2 - 0.3), (H - 0.8) / 2, sz * (d2 / 2 - 0.3)), Wood, pal.frame)
			end
			deco(rod(s, "Bracket", at(sx * (w / 2 - 1.5), H - 3, -d / 2).Position, (up * CFrame.new(sx * (w / 2 - 1.5), -0.3, -d2 / 2 + 0.3)).Position, 0.45, Wood, pal.frame))
		end
		for _, x in ipairs({ -w / 4, w / 4 }) do
			window(s, up * CFrame.new(x, 6, -d2 / 2), pal, rng:NextNumber() < 0.45, rng:NextNumber() < 0.15)
		end
		for _, sd in ipairs({ -1, 1 }) do
			window(s, up * CFrame.new(sd * w / 2, 6, 0) * CFrame.Angles(0, -sd * math.pi / 2, 0), pal, rng:NextNumber() < 0.4, rng:NextNumber() < 0.3)
		end
		-- a balcony, washing on it
		if rng:NextNumber() < 0.5 then
			local bw = math.min(w - 2, 8)
			local bc = up * CFrame.new(0, 0, -d2 / 2 - 1.3)
			part(s, "Balcony", Vector3.new(bw, 0.4, 2.6), bc * CFrame.new(0, 0.2, 0), Wood, pal.frame)
			rod(s, "BalconyRail", (bc * CFrame.new(-bw / 2, 3.4, -1.2)).Position, (bc * CFrame.new(bw / 2, 3.4, -1.2)).Position, 0.2, Wood, pal.frame)
			for _, x in ipairs({ -bw / 2, 0, bw / 2 }) do
				rod(s, "BalconyPost", (bc * CFrame.new(x, 0.4, -1.2)).Position, (bc * CFrame.new(x, 3.4, -1.2)).Position, 0.2, Wood, pal.frame)
			end
			local f = -bw / 2 + 0.6
			while f < bw / 2 - 1.4 do
				local ww = rng:NextNumber(1, 1.8)
				Wind.cloth(s, (bc * CFrame.new(f, 3.4, -1.3)).Position, (bc * CFrame.new(f + ww, 3.4, -1.3)).Position, rng:NextNumber(1.4, 2.6), cf.LookVector, rng, {
					name = "Laundry", color = pick(WASHING, rng), thick = 0.06, strip = 0.7,
				})
				f += ww + rng:NextNumber(0.4, 1.4)
			end
		end
		top, depth, rf = H - 0.8, d2, up
		gMat, gC = opt2[1], opt2[2]
	end
	-- the roof: the island's shape (a narrow one always a lean-to)
	local roofC = roof(s, rf, top, w, depth, if w < 12 then "lean" else pal.roof, pal.tin, gMat, gC)
	if rng:NextNumber() < 0.45 then
		local pipe = (rf * CFrame.new(w / 2 - 1.8, top, depth / 2 - 1.8)).Position
		rod(s, "Stovepipe", pipe, pipe + UP * (depth * 0.25 + 3), 0.8, Metal, DARK)
		if rng:NextNumber() < 0.4 then
			smoke(s, pipe + UP * (depth * 0.25 + 3.2), 2, 1)
		end
	end
	-- inside (downstairs)
	local inside = cf
	if o.shop then
		part(s, "Counter", Vector3.new(doorW - 1, 3.4, 1.6), inside * CFrame.new(0, 1.7, -d / 2 + 2.4), Wood, rgb(130, 96, 64))
		part(s, "Shelves", Vector3.new(w - 2, 7, 1.4), inside * CFrame.new(0, 3.5, d / 2 - 1.4), Wood, darken(TIMBER, 0.9))
		for k = 1, 10 do
			deco(part(s, "Goods", Vector3.new(rng:NextNumber(0.6, 1.4), rng:NextNumber(0.6, 1.4), 0.8), inside * CFrame.new(rng:NextNumber(-w / 2 + 2, w / 2 - 2), 1.6 + (k % 3) * 2.2, d / 2 - 1.6), Smooth, pick({ rgb(200, 120, 60), rgb(90, 130, 90), rgb(220, 210, 180), rgb(160, 60, 50), rgb(60, 90, 140) }, rng)))
		end
		deco(part(s, "Shutter", Vector3.new(doorW, 1, 0.6), inside * CFrame.new(0, doorH - 0.3, -d / 2 + 0.6), Rust, rgb(120, 124, 120)))
		-- the sign across the whole front
		label(s, inside * CFrame.new(0, doorH + 1.7, -d / 2 - 0.12), Vector3.new(w - 1.2, 2, 0.12), Enum.NormalId.Front, pick(SHOPS, rng), pick({ rgb(236, 232, 222), rgb(40, 50, 80), rgb(160, 44, 38) }, rng), pick({ rgb(30, 30, 30), rgb(240, 236, 226) }, rng), Wood, Enum.Font.GothamBlack)
		lantern(s, (inside * CFrame.new(0, doorH - 1.6, -d / 2 + 3)).Position, rng)
		if rng:NextNumber() < 0.5 then
			marker(s, (inside * CFrame.new(w / 2 - 2, 0.3, 0)).Position)
		end
	else
		local far = if doorX > 0 then -1 else 1
		part(s, "Futon", Vector3.new(math.min(6, w - 3), 0.5, 3.2), inside * CFrame.new(far * (w / 2 - 3.6), 0.55, d / 2 - 2.4), Fabric, pick(CLOTHS, rng))
		part(s, "Chabudai", Vector3.new(3.4, 0.3, 2.4), inside * CFrame.new(0, 1.4, 0), Wood, rgb(120, 84, 56))
		part(s, "ChabudaiLeg", Vector3.new(2.6, 1.1, 1.6), inside * CFrame.new(0, 0.7, 0), Wood, darken(rgb(120, 84, 56), 0.8))
		part(s, "Tansu", Vector3.new(1.8, 5, 3.4), inside * CFrame.new(-far * (w / 2 - 1.5), 2.6, d / 2 - 3), Wood, rgb(140, 100, 64))
		local bulb = deco(part(s, "Bulb", Vector3.new(0.6, 0.8, 0.6), inside * CFrame.new(0, H - 2, 0), if lit then Neon else Glass, rgb(255, 200, 140)))
		if lit then
			light(bulb, 16)
		end
		if rng:NextNumber() < 0.4 then
			marker(s, (inside * CFrame.new(far * (w / 2 - 2), 0.3, -d / 2 + 2.4)).Position)
		end
		-- noren in the door, a lantern by it
		if rng:NextNumber() < 0.5 then
			local nc = pick(NOREN, rng)
			local y = doorH - 0.2
			for _, k in ipairs({ -1, 1 }) do
				local x0 = doorX + (if k < 0 then -doorW / 2 + 0.1 else 0.05)
				Wind.cloth(s, (inside * CFrame.new(x0, y, -d / 2 - 0.3)).Position, (inside * CFrame.new(x0 + doorW / 2 - 0.15, y, -d / 2 - 0.3)).Position, 3.2, cf.LookVector, rng, { name = "Noren", color = nc, strip = 0.8, thick = 0.08, stiff = 0.2 })
			end
		end
		if rng:NextNumber() < 0.5 then
			lantern(s, (inside * CFrame.new(doorX - pick({ -1, 1 }, rng) * (doorW / 2 + 1.1), 7.4, -d / 2 - 0.9)).Position, rng)
		end
	end
	-- an air-con box on a side wall, towards the back
	if rng:NextNumber() < 0.35 then
		part(s, "AirCon", Vector3.new(1.4, 2.2, 3.2), inside * CFrame.new(pick({ -1, 1 }, rng) * (w / 2 + 0.75), 3.4, d / 2 - 2.4), Smooth, rgb(220, 218, 210))
	end
	return roofC, { cf = cf, w = w, d = d, doorX = doorX, doorW = doorW, shop = o.shop, storeys = storeys }
end

-- ===== Things in the town =====

-- A raised bed: soil and whatever's growing.
local function bed(m, cf, w, d, rng)
	part(m, "Bed", Vector3.new(w, 2.2, d), cf * CFrame.new(0, 1.1, 0), Planks, jitter(rgb(120, 94, 64), rng, 0.08))
	part(m, "Soil", Vector3.new(w - 0.5, 0.2, d - 0.5), cf * CFrame.new(0, 2.15, 0), Ground, rgb(60, 44, 32))
	local crop = rng:NextInteger(1, 3)
	for x = -w / 2 + 0.9, w / 2 - 0.9, 1.4 do
		for z = -d / 2 + 0.9, d / 2 - 0.9, 1.5 do
			local p = cf * CFrame.new(x, 2.2, z)
			if crop == 1 then
				local sz = rng:NextNumber(0.9, 1.4)
				deco(ellipsoid(m, "Cabbage", Vector3.new(sz, sz * 0.8, sz), p * CFrame.new(0, sz * 0.35, 0), Grass, jitter(rgb(110, 160, 80), rng, 0.1)))
			elseif crop == 2 then
				deco(rod(m, "Stake", p.Position, p.Position + UP * 3, 0.12, Wood, TIMBER))
				deco(ellipsoid(m, "Vine", Vector3.new(1, 2.4, 1), p * CFrame.new(0, 1.6, 0), Grass, jitter(rgb(70, 120, 60), rng, 0.15)))
				if rng:NextNumber() < 0.5 then
					deco(ellipsoid(m, "Tomato", Vector3.new(0.4, 0.4, 0.4), p * CFrame.new(0.4, 1.4, 0), Smooth, rgb(200, 50, 40)))
				end
			else
				deco(ellipsoid(m, "Leaves", Vector3.new(0.7, 1.4, 0.7), p * CFrame.new(0, 0.7, 0), Grass, jitter(rgb(90, 140, 60), rng, 0.15)))
			end
		end
	end
end

-- A pinwheel (kazaguruma) on a stick, turning in the wind.
local function pinwheel(m, base, rng)
	local stick = base + UP * rng:NextNumber(2.2, 3.4)
	deco(rod(m, "PinStick", base, stick, 0.1, Wood, rgb(200, 190, 160)))
	local w = model(m, "Pinwheel")
	local c = stick - Wind.DIR * 0.15
	local face = CFrame.lookAt(c, c - Wind.DIR)
	local color = pick({ rgb(220, 60, 60), rgb(240, 200, 60), rgb(80, 150, 220), rgb(240, 236, 226), rgb(90, 180, 110) }, rng)
	for k = 0, 3 do
		part(w, "Vane", Vector3.new(0.7, 0.7, 0.04), face * CFrame.Angles(0, 0, k * math.pi / 2) * CFrame.new(0.35, 0.35, 0) * CFrame.Angles(0, 0.35, math.pi / 4), Smooth, if k % 2 == 0 then color else rgb(240, 236, 226))
	end
	Wind.spin(w, c, -Wind.DIR, rng:NextNumber(5, 9), rng)
end

-- A carp streamer (koinobori): a windsock of a fish.
local function carp(m, at, len, color, rng)
	return Wind.flag(m, at, len, rng, {
		name = "Koinobori", sock = true, height = len * 0.3, taper = 0.4, segs = 6, stiff = 0.25, droop = 0.9,
		colors = { color, color, darken(color, 0.8), color, darken(color, 0.8), rgb(236, 232, 222) },
	})
end

-- A floating wind turbine: a fat inflated ring with a rotor in it,
-- flying on three tethers from a winch at `anchor`, `height` above it,
-- leaning with the wind.
local function kite(m, anchor, height, rng)
	part(m, "WinchBase", Vector3.new(4.4, 0.6, 4.4), anchor + UP * 0.3, Metal, DARK)
	cylinder(m, "Winch", 3, 2.8, CFrame.fromMatrix(anchor + UP * 2, Vector3.new(-Wind.DIR.Z, 0, Wind.DIR.X), UP), Metal, YELLOW)
	local k = model(m, "FloatingTurbine")
	local c = anchor + UP * height
	local axis = Wind.DIR
	local across = Vector3.new(-axis.Z, 0, axis.X)
	local R = rng:NextNumber(9, 12)
	local tube = R * 0.4
	local body = pick({ rgb(236, 232, 222), rgb(214, 206, 188) }, rng)
	local band = pick({ rgb(220, 100, 40), rgb(60, 90, 150), rgb(180, 50, 44) }, rng)
	-- the ring: a tube of short round segments, each a little long so they
	-- close up (round, so nothing lies flat on anything else)
	local N = 16
	for i = 0, N - 1 do
		local a0, a1 = i / N * TAU, (i + 1) / N * TAU
		local p0 = c + (across * math.cos(a0) + UP * math.sin(a0)) * R
		local p1 = c + (across * math.cos(a1) + UP * math.sin(a1)) * R
		cylinder(k, "Shroud", (p1 - p0).Magnitude + tube * 0.45, tube, CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.Angles(0, math.pi / 2, 0), Fabric, if i % 4 == 0 then band else body)
	end
	local hub = ellipsoid(k, "RotorHub", Vector3.new(2.4, 2.4, 4), CFrame.lookAt(c, c - axis), Smooth, DARK)
	hub:SetAttribute("Rotor", true)
	local bl = R - tube / 2 - 1.4
	for b = 0, 2 do
		local a = b / 3 * TAU
		local dir = across * math.cos(a) + UP * math.sin(a)
		local blade = part(k, "Blade", Vector3.new(0.35, bl, 1.6), CFrame.fromMatrix(c + dir * (bl / 2 + 1), axis, dir) * CFrame.Angles(0, 0.35, 0), Smooth, rgb(230, 230, 226))
		blade:SetAttribute("Rotor", true)
	end
	local topY = R + tube / 2
	part(k, "Fin", Vector3.new(0.3, 4, 4.4), CFrame.lookAt(c + UP * (topY + 1) + axis * 2, c + UP * (topY + 1) + axis * 3), Fabric, band)
	local beacon = part(k, "Beacon", Vector3.new(1, 1, 1), c + UP * (topY + 0.3) - axis * 1.5, Neon, rgb(230, 40, 30))
	beacon.Shape = Enum.PartType.Ball
	for _, a in ipairs({ -math.pi / 2, -math.pi / 2 + 0.9, -math.pi / 2 - 0.9 }) do
		local ring = c + (across * math.cos(a) + UP * math.sin(a)) * (R - tube / 2)
		rod(k, "Tether", anchor + UP * 3.4, ring, 0.25, Metal, DARK)
	end
	Wind.kite(k, anchor + UP * 3.4, 0.34, c, axis, 2.2, rng)
	box(c.X + height * 0.3, c.Y, c.Z, 2 * R + height * 0.7, 2 * R + 14, 2 * R + 12)
end

-- The big industrial kind, flying high over the rest: a long grey
-- aerostat, fins at its tail, a rotor on its nose, a pod slung under it,
-- two heavy tethers down to a big winch.
local function aerostat(m, anchor, height, rng)
	part(m, "WinchFrame", Vector3.new(7, 3, 6), CFrame.lookAt(anchor + UP * 1.5, anchor + UP * 1.5 + Wind.DIR), Metal, DARK)
	cylinder(m, "WinchDrum", 5.4, 3.6, CFrame.fromMatrix(anchor + UP * 4.2, Vector3.new(-Wind.DIR.Z, 0, Wind.DIR.X), UP), Metal, YELLOW)
	label(m, CFrame.lookAt(anchor + UP * 1.5 - Wind.DIR * 3.05, anchor + UP * 1.5 - Wind.DIR * 4), Vector3.new(4, 1.4, 0.1), Enum.NormalId.Front, "高圧注意", YELLOW, DARK, Smooth, Enum.Font.GothamBlack)
	local k = model(m, "Aerostat")
	local c = anchor + UP * height
	local axis = Wind.DIR -- (the tail's way)
	local L, D = rng:NextNumber(54, 64), rng:NextNumber(17, 20)
	local hull = pick({ rgb(150, 150, 140), rgb(170, 162, 136), rgb(126, 132, 126) }, rng)
	local rot = CFrame.fromMatrix(c, axis, UP)
	ellipsoid(k, "Hull", Vector3.new(L, D, D), rot, Fabric, hull)
	for _, f in ipairs({ -0.3, 0, 0.3 }) do
		local x = f * L
		local r = (D / 2) * math.sqrt(1 - (2 * x / L) ^ 2)
		cylinder(k, "HullBand", 0.9, 2 * r + 0.3, rot * CFrame.new(x, 0, 0), Metal, darken(hull, 0.65))
	end
	-- fins at the tail: up and to either side
	for _, v in ipairs({ UP, Vector3.new(-axis.Z, 0, axis.X), Vector3.new(axis.Z, 0, -axis.X) }) do
		part(k, "Fin", Vector3.new(11, 9, 0.5), CFrame.fromMatrix(c + axis * (L / 2 - 7) + v * (D / 2 + 2.6), axis, v), Metal, darken(hull, 0.85))
	end
	-- the rotor on its nose
	local nose = c - axis * (L / 2 + 1.2)
	local hub = ellipsoid(k, "RotorHub", Vector3.new(3.4, 3.4, 5), CFrame.lookAt(nose, nose - axis), Smooth, DARK)
	hub:SetAttribute("Rotor", true)
	local bl = D * 0.85
	for b = 0, 2 do
		local a = b / 3 * TAU
		local dir = Vector3.new(-axis.Z, 0, axis.X) * math.cos(a) + UP * math.sin(a)
		local blade = part(k, "Blade", Vector3.new(0.5, bl, 2.4), CFrame.fromMatrix(nose + dir * (bl / 2 + 1.4), axis, dir) * CFrame.Angles(0, 0.3, 0), Smooth, rgb(220, 220, 214))
		blade:SetAttribute("Rotor", true)
	end
	-- the pod under it, and its lights
	local pod = rot * CFrame.new(0, -(D / 2 + 2.2), 0)
	part(k, "Pod", Vector3.new(12, 4, 5), pod, Metal, rgb(70, 74, 72))
	for _, s in ipairs({ -1, 1 }) do
		local win = part(k, "PodWindow", Vector3.new(9, 1.2, 0.2), pod * CFrame.new(0, 0.6, s * 2.55), Neon, rgb(255, 200, 130))
		win.Transparency = 0.45
		rod(k, "PodStrut", (pod * CFrame.new(s * 4, 2, 0)).Position, (rot * CFrame.new(s * 5, -(D / 2) * 0.9, 0)).Position, 0.5, Metal, DARK)
	end
	local beacon = part(k, "Beacon", Vector3.new(1.2, 1.2, 1.2), (rot * CFrame.new(0, D / 2 + 0.3, 0)).Position, Neon, rgb(230, 40, 30))
	beacon.Shape = Enum.PartType.Ball
	light(beacon, 30, rgb(255, 60, 40), 1.4)
	for _, f in ipairs({ -0.25, 0.25 }) do
		rod(k, "Tether", anchor + UP * 4.2, (rot * CFrame.new(f * L, -(D / 2) * 0.95, 0)).Position, 0.55, Metal, DARK)
	end
	Wind.kite(k, anchor + UP * 4.2, 0.22, nose, axis, 1.2, rng)
	box(c.X + height * 0.25, c.Y, c.Z, L + height * 0.6, D + 20, L)
end

-- A switchback stair down from a deck's edge at `top` (on the edge), out
-- along `out` (away from the deck), its flights running along `run`, to
-- height y0.
local function stairTower(m, top, out, run, y0, rng)
	local s = model(m, "StairTower")
	local STEPS, RUN = 8, 1.4
	local L = STEPS * RUN
	local n = math.max(1, math.ceil((top.Y - y0) / 8))
	local rise = (top.Y - y0) / n
	local color = jitter(TIMBER, rng, 0.06)
	local function at(o, r, y)
		return Vector3.new(top.X, y, top.Z) + out * o + run * r
	end
	local function slab(o0, o1, r0, r1, y)
		local c = at((o0 + o1) / 2, (r0 + r1) / 2, y - 0.3)
		part(s, "Landing", Vector3.new(math.abs(o1 - o0), 0.6, math.abs(r1 - r0)), CFrame.fromMatrix(c, out, UP), Wood, color)
	end
	slab(0, 11.4, -3, 3, top.Y)
	local y = top.Y
	for k = 1, n do
		local odd = k % 2 == 1
		local lane = if odd then 2.8 else 8.6
		local r0 = if odd then 3 else 3 + L
		local dir = if odd then 1 else -1
		for i = 1, STEPS do
			local c = at(lane, r0 + dir * (i - 0.5) * RUN, y - i * rise / STEPS - 0.3)
			part(s, "Step", Vector3.new(5.4, 0.6, RUN + 0.05), CFrame.fromMatrix(c, out, UP), Wood, color)
		end
		local edge = if odd then 0.1 else 11.3
		local p0, p1 = at(edge, r0, y), at(edge, r0 + dir * L, y - rise)
		deco(rod(s, "Stringer", p0 - UP * 0.8, p1 - UP * 0.8, 0.5, Wood, darken(color, 0.8)))
		rod(s, "StairRail", p0 + UP * 3.4, p1 + UP * 3.4, 0.2, Fabric, ROPE)
		y -= rise
		if odd then
			slab(0, 11.4, 3 + L, 3 + L + 5, y)
		else
			slab(0, 11.4, -3, 3, y)
		end
	end
	for _, o in ipairs({ 0, 11.4 }) do
		for _, r in ipairs({ -3, 3 + L + 5 }) do
			rod(s, "TowerPost", at(o, r, y0 - 2), at(o, r, top.Y + 4), 0.7, Wood, darken(color, 0.85))
		end
	end
	lantern(s, at(11.4, -3, top.Y + 4.6), rng, true)
	local c = at(5.7, (L + 5) / 2, (top.Y + y0) / 2)
	box(c.X, c.Y, c.Z, math.abs(out.X) * 12 + math.abs(run.X) * (L + 12), top.Y - y0 + 10, math.abs(out.Z) * 12 + math.abs(run.Z) * (L + 12))
end

-- A lift: a car in an open frame from y0 up to y1 (it carries you).
local function lift(m, x, z, y0, y1, rng)
	local lm = model(m, "Lift")
	for _, o in ipairs({ { -3.2, -3.4 }, { 3.2, -3.4 }, { 3.2, 3.4 }, { -3.2, 3.4 } }) do
		rod(lm, "ShaftPost", Vector3.new(x + o[1], y0 - 2, z + o[2]), Vector3.new(x + o[1], y1 + 12, z + o[2]), 0.4, Metal, STEEL)
	end
	part(lm, "Headgear", Vector3.new(7, 1.2, 7.2), Vector3.new(x, y1 + 12, z), Metal, YELLOW)
	cylinder(lm, "Sheave", 0.6, 3, CFrame.new(x, y1 + 13.4, z), Metal, DARK)
	local car = model(lm, "LiftCar")
	part(car, "CarFloor", Vector3.new(6, 0.4, 6.2), Vector3.new(x, y0 - 0.05, z), Plate, rgb(92, 92, 88))
	part(car, "CarRoof", Vector3.new(6, 0.3, 6.2), Vector3.new(x, y0 + 9.6, z), Metal, darken(YELLOW, 0.8))
	for _, sd in ipairs({ -1, 1 }) do
		part(car, "CarSide", Vector3.new(0.2, 9.4, 6.2), Vector3.new(x + sd * 2.9, y0 + 4.8, z), Metal, YELLOW).Transparency = 0.35
	end
	deco(rod(car, "CarCable", Vector3.new(x, y0 + 9.8, z), Vector3.new(x, y1 + 12, z), 0.22, Metal, DARK))
	lantern(car, Vector3.new(x, y0 + 8.4, z), rng, true)
	local rise = y1 - y0
	Pieces.mover(car, { Motion = "slide", Delta = UP * rise, Period = 2 * (rise / 9) / (1 - 2 * 0.25), Dwell = 0.25, Phase = rng:NextNumber() })
	box(x, (y0 + y1) / 2, z, 8, rise + 20, 8)
end

-- ===== The pylons =====

local function hw(P, y)
	if y < P.top - 80 then
		return 24 + (12 - 24) * (y + 100) / (P.top - 80 + 100)
	end
	return 12 + (3.5 - 12) * (y - (P.top - 80)) / 80
end

local function blinker(parent, pos, rng)
	local b = part(parent, "WarningLight", Vector3.new(1, 1, 1), pos, Neon, rgb(230, 40, 30))
	b.Shape = Enum.PartType.Ball
	b.CanCollide = false
	b:SetAttribute("Period", 1.6)
	b:SetAttribute("On", 0.45)
	b:SetAttribute("Offset", rng:NextNumber())
	b:AddTag("Blink")
	light(b, 14, rgb(255, 60, 40), 1.4)
end

local function pylon(m, P, rng)
	local color = jitter(STEEL, rng, 0.05)
	local nodes = { -300, P.top - 80, P.top }
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local function at(y)
				local w = hw(P, y)
				return Vector3.new(P.x + sx * w, y, P.z + sz * w)
			end
			rod(m, "Leg", Vector3.new(P.x + sx * 34, -700, P.z + sz * 34), at(nodes[1]), 2.2, Metal, color)
			rod(m, "Leg", at(nodes[1]), at(nodes[2]), 1.8, Metal, color)
			rod(m, "Leg", at(nodes[2]), at(nodes[3]), 1.2, Metal, color)
		end
	end
	local y = -260
	while y < P.top - 6 do
		local step = if y < P.top - 80 then 18 else 10
		local w0, w1 = hw(P, y), hw(P, y + step)
		local c0 = { Vector3.new(-w0, y, -w0), Vector3.new(w0, y, -w0), Vector3.new(w0, y, w0), Vector3.new(-w0, y, w0) }
		local c1 = { Vector3.new(-w1, y + step, -w1), Vector3.new(w1, y + step, -w1), Vector3.new(w1, y + step, w1), Vector3.new(-w1, y + step, w1) }
		local o = Vector3.new(P.x, 0, P.z)
		for i = 1, 4 do
			local j = i % 4 + 1
			deco(rod(m, "Ring", o + c0[i], o + c0[j], 0.6, Metal, color))
			deco(rod(m, "Diagonal", o + c0[i], o + c1[j], 0.45, Metal, color))
			deco(rod(m, "Diagonal", o + c0[j], o + c1[i], 0.45, Metal, color))
		end
		y += step
	end
	-- the cross-arms, along x; insulators at their tips
	P.arms = {}
	for n, spec in ipairs({ { P.top - 80, 34 }, { P.top - 50, 26 } }) do
		local ay, half = spec[1], spec[2]
		for _, sz in ipairs({ -1.5, 1.5 }) do
			for _, yy in ipairs({ ay, ay - 3 }) do
				rod(m, "ArmChord", Vector3.new(P.x - half, yy, P.z + sz), Vector3.new(P.x + half, yy, P.z + sz), 0.6, Metal, color)
			end
		end
		for x = -half, half - 3, 3 do
			deco(rod(m, "ArmLace", Vector3.new(P.x + x, ay - 3, P.z - 1.5), Vector3.new(P.x + x + 3, ay, P.z + 1.5), 0.25, Metal, color))
		end
		for _, sx in ipairs({ -1, 1 }) do
			local tip = Vector3.new(P.x + sx * half, ay - 3, P.z)
			for d = 0, 4 do
				deco(cylinder(m, "Insulator", 0.3, 1.4, CFrame.new(tip - UP * (0.8 + d * 0.8)) * UPRIGHT, Glass, rgb(120, 150, 150)))
			end
			rod(m, "InsulatorRod", tip, tip - UP * 5, 0.2, Metal, DARK)
			table.insert(P.arms, { n = n, sx = sx, tip = tip - UP * 5 })
			blinker(m, Vector3.new(P.x + sx * half, ay + 0.9, P.z), rng)
			-- the lower arm run on out as a crane's jib, stayed from the peak
			local reach = n == 1 and P.reach and P.reach[sx]
			if reach then
				local x0 = P.x + sx * half
				local len = math.abs(reach - x0) + 1
				for _, sz in ipairs({ -1.5, 1.5 }) do
					for _, yy in ipairs({ ay, ay - 3 }) do
						rod(m, "JibChord", Vector3.new(x0, yy, P.z + sz), Vector3.new(x0 + sx * len, yy, P.z + sz), 0.7, Metal, color)
					end
				end
				for d = 0, len - 3, 3 do
					local x = x0 + sx * d
					deco(rod(m, "JibLace", Vector3.new(x, ay - 3, P.z - 1.5), Vector3.new(x + sx * 3, ay, P.z + 1.5), 0.25, Metal, color))
				end
				part(m, "JibEnd", Vector3.new(1.4, 4, 4), Vector3.new(x0 + sx * len, ay - 1.5, P.z), Metal, YELLOW)
				blinker(m, Vector3.new(x0 + sx * len, ay + 1, P.z), rng)
				for _, f in ipairs({ 0.5, 1 }) do
					local at = Vector3.new(x0 + sx * len * f, ay, P.z)
					for _, sz in ipairs({ -1.5, 1.5 }) do
						rod(m, "Stay", Vector3.new(P.x, P.top + 8, P.z + sz), at + Vector3.new(0, 0, sz), 0.4, Metal, DARK)
					end
				end
				box(x0 + sx * len / 2, ay - 1.5, P.z, len, 5, 5)
			end
		end
	end
	if not P.light then
		rod(m, "Peak", Vector3.new(P.x, P.top, P.z), Vector3.new(P.x, P.top + 10, P.z), 0.9, Metal, color)
		blinker(m, Vector3.new(P.x, P.top + 10.8, P.z), rng)
	end
	box(P.x, (P.base - 20 + P.garden + 10) / 2, P.z, 2 * hw(P, P.base) + 6, P.garden - P.base + 30, 2 * hw(P, P.base) + 6)
	box(P.x, P.top - 50, P.z, 90, 80, 10)
end

-- A square deck inside a pylon's legs at height y (holes for lifts);
-- `pad` beyond the legs (less than 0: inside them).
local function pylonDeck(m, P, y, pad, holes, rng, material, color)
	local h = hw(P, y) + pad
	deck(m, { x0 = P.x - h, x1 = P.x + h, z0 = P.z - h, z1 = P.z + h }, y, holes, rng, material, color)
	return h
end

local function liftHole(P, dx)
	return { x0 = P.x + dx - 3.1, x1 = P.x + dx + 3.1, z0 = P.z - 3.3, z1 = P.z + 3.3 }
end

-- The old conductors, pylon to pylon, and off the ends into the fog.
local function conductors(parent)
	local m = model(parent, "Conductors")
	local function cable(a, b, sag)
		local n = math.clamp(math.floor((b - a).Magnitude / 8), 6, 30)
		local prev = a
		for i = 1, n do
			local t = i / n
			local p = a:Lerp(b, t) - UP * (sag * 4 * t * (1 - t))
			deco(rod(m, "Conductor", prev, p, 0.7, Metal, rgb(60, 60, 62)))
			prev = p
		end
	end
	for k = 1, 2 do
		for i, arm in ipairs(PYLONS[k].arms) do
			local other = PYLONS[k + 1].arms[i]
			cable(arm.tip, other.tip, (other.tip - arm.tip).Magnitude * 0.07)
		end
	end
	-- (off the ends: away west and north, clear of the town)
	for i, arm in ipairs(PYLONS[1].arms) do
		cable(arm.tip, arm.tip + Vector3.new(-170, -230 - i * 15, -60), 30)
	end
	for i, arm in ipairs(PYLONS[3].arms) do
		cable(arm.tip, arm.tip + Vector3.new(-50, -230 - i * 15, 170), 30)
	end
end

-- A pylon's own layers: its base down in the damp (a pump, the intake
-- down into the fog, nets across its faces), its landing at the town's
-- level, its garden; lifts between; a ladder from the garden to the arm;
-- the walk out along the arm to cable-car stations at its tips.
local function pylonLayers(m, P, rng)
	-- the base
	local bh = pylonDeck(m, P, P.base, -1, {}, rng, Planks, WET)
	part(m, "PumpMotor", Vector3.new(5, 4, 3.4), Vector3.new(P.x + 6, P.base + 2, P.z - 6), Metal, rgb(70, 96, 90))
	local fw = model(m, "Flywheel")
	local fc = CFrame.new(P.x + 6, P.base + 3, P.z - 3.8) * CFrame.Angles(0, math.pi / 2, 0)
	cylinder(fw, "Flywheel", 0.8, 4, fc, Metal, DARK)
	part(fw, "FlywheelSpoke", Vector3.new(0.9, 3.6, 0.5), fc * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(200, 60, 40))
	Wind.spin(fw, fc.Position, Vector3.zAxis, 2.5, rng)
	for k = 0, 1 do
		local g = Vector3.new(P.x + 4.9 + k * 1.3, P.base + 4.5, P.z - 4.25)
		deco(cylinder(m, "Gauge", 0.25, 0.9, CFrame.lookAt(g, g + Vector3.zAxis) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(236, 232, 222)))
		deco(part(m, "GaugeNeedle", Vector3.new(0.06, 0.35, 0.05), CFrame.new(g + Vector3.new(0, 0.05, 0.15)) * CFrame.Angles(0, 0, rng:NextNumber(-1, 1)), Smooth, rgb(200, 40, 30)))
	end
	deco(cylinder(m, "ValveWheel", 0.25, 1.8, CFrame.new(P.x + 6.9, P.base + 8, P.z - 6), Metal, rgb(200, 50, 40)))
	for k = 0, 2 do
		deco(cylinder(m, "PipeFlange", 0.4, 1.8, CFrame.new(P.x + 6, P.base + 12 + k * 14, P.z - 6) * UPRIGHT, Metal, rgb(60, 76, 84)))
	end
	rod(m, "Intake", Vector3.new(P.x + 8, P.base + 2, P.z - 8), Vector3.new(P.x + 8, -300, P.z - 8), 2, Metal, rgb(80, 100, 110))
	rod(m, "Riser", Vector3.new(P.x + 6, P.base + 4, P.z - 6), Vector3.new(P.x + 6, P.landing - 1, P.z - 6), 1.2, Metal, rgb(80, 100, 110))
	for _, o in ipairs({ { -1, -1 }, { 1, 1 } }) do
		dampLamp(m, Vector3.new(P.x + o[1] * (bh - 2), P.base, P.z + o[2] * (bh - 2)))
	end
	-- nets across two of its faces, billowing
	local nh = hw(P, P.base + 8)
	for _, sz in ipairs({ -1, 1 }) do
		fogNet(m, Vector3.new(P.x - nh + 1.5, P.base + 16, P.z + sz * nh), Vector3.new(P.x + nh - 1.5, P.base + 16, P.z + sz * nh), 13, Vector3.new(0, 0, sz), rng)
	end
	-- the landing: the town's level
	pylonDeck(m, P, P.landing, -1, { liftHole(P, -3.5) }, rng, Planks, jitter(pick(DECKS, rng), rng, 0.05))
	lantern(m, Vector3.new(P.x + 8, P.landing + 7, P.z + 8), rng, true)
	label(m, CFrame.new(P.x - 6, P.landing + 4, P.z + 6) * CFrame.Angles(0, math.pi / 4, 0), Vector3.new(3.2, 1.6, 0.1), Enum.NormalId.Front, "昇降機", YELLOW, DARK, Smooth, Enum.Font.GothamBlack)
	lift(m, P.x - 3.5, P.z, P.base + 0.15, P.landing + 0.15, rng)
	-- the garden: big beds round a ring out beyond the legs
	local gh = pylonDeck(m, P, P.garden, 10, { liftHole(P, 3.5) }, rng)
	lift(m, P.x + 3.5, P.z, P.landing + 0.15, P.garden + 0.15, rng)
	for _, sz in ipairs({ -1, 1 }) do
		for k = -1, 1 do
			bed(m, CFrame.new(P.x + k * 10, P.garden, P.z + sz * (gh - 3)), 8, 3.6, rng)
		end
	end
	for k = -1, 1, 2 do
		bed(m, CFrame.new(P.x + gh - 3, P.garden, P.z + k * 8) * CFrame.Angles(0, math.pi / 2, 0), 7, 3.6, rng)
	end
	-- a glasshouse on the west side
	local gc = CFrame.new(P.x - gh + 5, P.garden, P.z)
	for _, e in ipairs({ -5, 5 }) do
		deco(part(m, "Glasshouse", Vector3.new(8, 7, 0.15), gc * CFrame.new(0, 3.5, e), Glass, rgb(170, 200, 190))).Transparency = 0.6
	end
	deco(part(m, "Glasshouse", Vector3.new(0.15, 7, 10), gc * CFrame.new(-4, 3.5, 0), Glass, rgb(170, 200, 190))).Transparency = 0.6
	deco(part(m, "GlassRoof", Vector3.new(8.6, 0.15, 10.6), gc * CFrame.new(0, 7.3, 0) * CFrame.Angles(0, 0, 0.12), Glass, rgb(170, 200, 190))).Transparency = 0.55
	for _, o in ipairs({ { -4, -5 }, { 4, -5 }, { 4, 5 }, { -4, 5 } }) do
		rod(m, "GlassFrame", (gc * CFrame.new(o[1], 0, o[2])).Position, (gc * CFrame.new(o[1], 7.3, o[2])).Position, 0.2, Metal, rgb(220, 220, 214))
	end
	for k = -1, 1, 2 do
		bed(m, gc * CFrame.new(0, 0, k * 2.4), 6, 2, rng)
	end
	cylinder(m, "WaterTank", 6, 4.4, CFrame.new(P.x + gh - 3, P.garden + 3, P.z + gh - 3) * UPRIGHT, Metal, rgb(90, 120, 140))
	-- (its rails come later, with gaps where the sky beams come in)
	if P.aero then
		aerostat(m, Vector3.new(P.x + P.aero[1] * (gh - 5), P.garden, P.z + P.aero[2] * (gh - 5)), rng:NextNumber(135, 155), rng)
	end
	if P.kite then
		kite(m, Vector3.new(P.x + P.kite[1] * (gh - 4), P.garden, P.z + P.kite[2] * (gh - 4)), rng:NextNumber(40, 55), rng)
	end
	-- up to the arm
	local armY = P.top - 80 + 1.2
	ladder(m, Vector3.new(P.x, P.garden, P.z - 11.2), Vector3.new(P.x, armY + 3, P.z - 11.2))
	part(m, "ArmLanding", Vector3.new(3.4, 0.5, 8.6), Vector3.new(P.x, armY - 0.25, P.z - 6), Plate, rgb(92, 92, 88))
	part(m, "ArmWalk", Vector3.new(68, 0.4, 3), Vector3.new(P.x, armY - 0.2, P.z), Planks, jitter(TIMBER, rng, 0.06))
	P.stations = {}
	for _, sx in ipairs({ -1, 1 }) do
		local c = Vector3.new(P.x + sx * 37, armY, P.z)
		deck(m, { x0 = c.X - 3.5, x1 = c.X + 3.5, z0 = c.Z - 3.5, z1 = c.Z + 3.5 }, armY, {}, rng, Plate, rgb(92, 92, 88))
		P.stations[sx] = c
		for _, dz in ipairs({ -3.5, 3.5 }) do
			rod(m, "Gantry", c + Vector3.new(sx * 3, 0, dz), c + Vector3.new(sx * 3, 14, dz), 0.55, Metal, YELLOW)
		end
		part(m, "GantryBeam", Vector3.new(0.9, 0.9, 8), c + Vector3.new(sx * 3, 14, 0), Metal, YELLOW)
		rail(m, c + Vector3.new(sx * 3.5, 0, -3.5), c + Vector3.new(sx * 3.5, 0, 3.5))
		Wind.windsock(m, c + Vector3.new(sx * 3, 14, 4), rng)
		local sign = c + Vector3.new(sx * 2.4, 12.6, 0)
		label(m, CFrame.lookAt(sign, sign - Vector3.new(sx, 0, 0)), Vector3.new(5, 1.3, 0.1), Enum.NormalId.Front, "空中索道", rgb(236, 226, 196), rgb(160, 30, 26), Wood, Enum.Font.GothamBlack)
		lantern(m, c + Vector3.new(sx * 3, 11.6, -3), rng, true)
	end
end

-- A cable car between two stations (it carries you).
local function cableCar(parent, a, b, rng)
	local m = model(parent, "CableCar")
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	local startC = a + d * 6.4
	local endC = b - d * 6.4
	rod(m, "HaulCable", a + UP * 14, b + UP * 14, 0.45, Metal, DARK)
	local cab = model(m, "Cabin")
	local cf = CFrame.lookAt(startC, startC + d)
	part(cab, "CabinFloor", Vector3.new(6.4, 0.4, 8.4), cf * CFrame.new(0, -0.2, 0), Plate, rgb(92, 92, 88))
	part(cab, "CabinRoof", Vector3.new(6.8, 0.4, 8.8), cf * CFrame.new(0, 9.4, 0), Metal, rgb(180, 60, 44))
	for _, s in ipairs({ -1, 1 }) do
		part(cab, "CabinSide", Vector3.new(0.2, 3.6, 8.4), cf * CFrame.new(s * 3.1, 1.8, 0), Metal, rgb(200, 190, 170))
		deco(part(cab, "CabinGlass", Vector3.new(0.1, 5, 8), cf * CFrame.new(s * 3.12, 6.1, 0), Glass, rgb(150, 170, 176))).Transparency = 0.5
		for _, z in ipairs({ -4.1, 4.1 }) do
			rod(cab, "CabinPost", (cf * CFrame.new(s * 3.1, 0, z)).Position, (cf * CFrame.new(s * 3.1, 9.2, z)).Position, 0.3, Metal, DARK)
		end
	end
	deco(rod(cab, "Hanger", (cf * CFrame.new(0, 9.6, 0)).Position, startC + UP * 13.8, 0.35, Metal, DARK))
	part(cab, "Grip", Vector3.new(1.2, 1.2, 2.8), startC + UP * 14, Metal, YELLOW)
	lantern(cab, (cf * CFrame.new(0, 8.2, 0)).Position, rng, true)
	local travel = (endC - startC).Magnitude
	Pieces.mover(cab, { Motion = "slide", Delta = endC - startC, Period = 2 * (travel / 10) / (1 - 2 * 0.2), Dwell = 0.2, Phase = rng:NextNumber() })
	local c = (a + b) / 2
	box(c.X, c.Y + 4, c.Z, math.abs(b.X - a.X) + 10, math.abs(b.Y - a.Y) + 22, math.abs(b.Z - a.Z) + 10)
end

-- The lighthouse, on the tallest pylon's peak (風見灯台). From the bottom:
--   the service room   an octagon of riveted steel, white with a red band,
--                      portholes, a door with its nameplate
--   the gallery        round it all on red brackets, a railing with ball
--                      finials; on it a fog bell, a foghorn, a telescope, a
--                      lifebuoy, a flag
--   the lantern room   glass all round, barred with diagonal astragals, red
--                      mullions, vents in its base; a red dome ribbed in
--                      iron, a ventilator ball, a weathervane, a lightning
--                      rod
--   the lens           a great beehive Fresnel lens of glass prisms in
--                      brass, bullseyes either side, the lamp in it, all
--                      turning on its clockwork, two beams out over the fog
-- The way up: off the lower arm's walk, a ladder to a platform on the
-- upper arm, then a long caged ladder out in the open to the gallery.
local function lighthouse(m, P, rng)
	local x, z = P.x, P.z
	local F0 = P.top - 2
	local armY = P.top - 80 + 1.2
	local arm2 = P.top - 50 + 0.6
	local RED, WHITE, BRASS, IRON = rgb(178, 44, 36), rgb(232, 228, 216), rgb(196, 160, 72), rgb(40, 42, 44)
	local C = Vector3.new(x, 0, z)
	local function ring(r, a, y)
		return Vector3.new(x + math.cos(a) * r, y, z + math.sin(a) * r)
	end
	-- the way up
	part(m, "ArmStep", Vector3.new(3.4, 0.5, 4.6), Vector3.new(x + 3.4, armY - 0.25, z + 3.6), Plate, rgb(92, 92, 88))
	ladder(m, Vector3.new(x + 3.4, armY, z + 5), Vector3.new(x + 3.4, arm2 + 3, z + 5))
	part(m, "ArmPlatform", Vector3.new(4.4, 0.5, 12.3), Vector3.new(x, arm2 - 0.25, z + 5.65), Plate, rgb(92, 92, 88))
	rail(m, Vector3.new(x - 2.2, arm2, z - 0.5), Vector3.new(x - 2.2, arm2, z + 11.8))
	local LZ = z + 12.8
	ladder(m, Vector3.new(x, arm2, LZ), Vector3.new(x, F0 + 12, LZ), RED)
	-- (its cage: hoops round the back of it, the climb up the front)
	for y = arm2 + 7, F0 + 7.5, 2.6 do
		for _, sx in ipairs({ -1, 1 }) do
			deco(rod(m, "CageHoop", Vector3.new(x + sx * 1.5, y, LZ), Vector3.new(x + sx * 1.5, y, LZ + 1.8), 0.12, Metal, RED))
		end
		deco(rod(m, "CageHoop", Vector3.new(x - 1.5, y, LZ + 1.8), Vector3.new(x + 1.5, y, LZ + 1.8), 0.12, Metal, RED))
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco(rod(m, "CageRail", Vector3.new(x + sx * 1.5, arm2 + 7, LZ + 1.8), Vector3.new(x + sx * 1.5, F0 + 7.5, LZ + 1.8), 0.12, Metal, RED))
	end

	-- the service room
	cylinder(m, "ServiceFloor", 1, 16, CFrame.new(x, F0 - 0.5, z) * UPRIGHT, Plate, rgb(92, 92, 88))
	for k = 0, 7 do
		local a = k / 8 * TAU
		local c = ring(6.6, a, F0 + 4.5)
		local face = CFrame.lookAt(c, Vector3.new(x, F0 + 4.5, z))
		part(m, "ServiceWall", Vector3.new(5.6, 9, 0.5), face, Metal, WHITE)
		deco(part(m, "ServiceBand", Vector3.new(5.7, 1.4, 0.56), face * CFrame.new(0, 3.5, 0), Metal, RED))
		deco(part(m, "Plinth", Vector3.new(5.7, 0.8, 0.6), face * CFrame.new(0, -4.1, 0), Metal, darken(WHITE, 0.7)))
		for _, sy in ipairs({ -1.2, 1.6 }) do
			deco(part(m, "Seam", Vector3.new(5.7, 0.12, 0.54), face * CFrame.new(0, sy, 0), Metal, darken(WHITE, 0.85)))
		end
		if k == 0 then
			-- the door, and its nameplate
			deco(part(m, "Door", Vector3.new(2.8, 6.2, 0.15), face * CFrame.new(0, -1.2, 0.3), Metal, rgb(70, 76, 80)))
			deco(part(m, "DoorKnob", Vector3.new(0.3, 0.3, 0.3), face * CFrame.new(-1, -1.4, 0.42), Metal, BRASS))
			label(m, face * CFrame.new(0, 2.5, 0.34) * CFrame.Angles(0, math.pi, 0), Vector3.new(3.4, 0.9, 0.06), Enum.NormalId.Front, "風見灯台", BRASS, rgb(40, 30, 20), Metal, Enum.Font.GothamBold)
		elseif k % 2 == 1 then
			local ph = face * CFrame.new(0, 0.6, 0.3)
			local lit = rng:NextNumber() < 0.6
			deco(cylinder(m, "PortholeRim", 0.3, 1.9, ph * CFrame.Angles(0, math.pi / 2, 0), Metal, BRASS))
			local glass = deco(cylinder(m, "Porthole", 0.34, 1.4, ph * CFrame.Angles(0, math.pi / 2, 0), if lit then Neon else Glass, if lit then rgb(255, 196, 130) else rgb(50, 58, 62)))
			glass.Transparency = if lit then 0.3 else 0.1
		end
	end

	-- the gallery, on brackets, railed
	local GR = 10
	cylinder(m, "Gallery", 0.8, GR * 2, CFrame.new(x, F0 + 8.6, z) * UPRIGHT, Plate, rgb(92, 92, 88))
	cylinder(m, "GalleryEdge", 0.5, GR * 2 + 0.4, CFrame.new(x, F0 + 8.3, z) * UPRIGHT, Metal, RED)
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * TAU
		rod(m, "GalleryBracket", ring(6.9, a, F0 + 3.6), ring(9.6, a, F0 + 8.1), 0.5, Metal, RED)
	end
	local prev
	for k = 0, 24 do
		local a = k / 24 * TAU
		local p0 = ring(GR - 0.3, a, F0 + 9)
		local open = math.abs(math.sin(a) - 1) < 0.05
		if not open then
			rod(m, "GalleryPost", p0, p0 + UP * 3.6, 0.22, Metal, IRON)
			if k % 2 == 0 then
				local ball = deco(part(m, "Finial", Vector3.new(0.5, 0.5, 0.5), p0 + UP * 3.85, Metal, BRASS))
				ball.Shape = Enum.PartType.Ball
			end
		end
		if prev and not open and not prev.open then
			rod(m, "GalleryRail", prev.p + UP * 3.5, p0 + UP * 3.5, 0.2, Metal, IRON)
			deco(rod(m, "GalleryRail", prev.p + UP * 1.8, p0 + UP * 1.8, 0.14, Metal, IRON))
		end
		prev = { p = p0, open = open }
	end

	-- the lantern room
	local LR = 5.6
	cylinder(m, "LanternBase", 1.2, LR * 2 + 0.8, CFrame.new(x, F0 + 9.6, z) * UPRIGHT, Metal, RED)
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * TAU
		local v = ring(LR + 0.45, a, F0 + 9.6)
		deco(part(m, "Vent", Vector3.new(1.2, 0.5, 0.15), CFrame.lookAt(v, Vector3.new(x, F0 + 9.6, z)), Metal, IRON))
	end
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * TAU
		local pc = ring(LR, a, F0 + 14.4)
		local face = CFrame.lookAt(pc, Vector3.new(x, F0 + 14.4, z))
		if k ~= 1 then
			part(m, "LanternGlass", Vector3.new(4.3, 8.4, 0.2), face, Glass, rgb(196, 218, 224)).Transparency = 0.72
			-- diagonal astragals, crossing
			for _, sd in ipairs({ -1, 1 }) do
				deco(rod(m, "Astragal", (face * CFrame.new(-2.1 * sd, -4.1, 0.15)).Position, (face * CFrame.new(2.1 * sd, 4.1, 0.15)).Position, 0.12, Metal, IRON))
			end
			deco(rod(m, "GlazingBar", (face * CFrame.new(-2.1, 0, 0.15)).Position, (face * CFrame.new(2.1, 0, 0.15)).Position, 0.12, Metal, IRON))
		end
		local mp = ring(LR * 1.02, k / 8 * TAU, 0)
		rod(m, "Mullion", mp + UP * (F0 + 10.1), mp + UP * (F0 + 18.7), 0.34, Metal, RED)
	end
	cylinder(m, "LanternRing", 0.8, LR * 2 + 1, CFrame.new(x, F0 + 18.8, z) * UPRIGHT, Metal, RED)
	cylinder(m, "Gutter", 0.35, LR * 2 + 1.6, CFrame.new(x, F0 + 19.2, z) * UPRIGHT, Metal, IRON)
	-- the dome, ribbed
	ellipsoid(m, "Dome", Vector3.new(LR * 2 + 0.6, 7, LR * 2 + 0.6), CFrame.new(x, F0 + 19.2, z), Metal, RED)
	for k = 0, 7 do
		local a = k / 8 * TAU
		local p1, p2 = ring(LR + 0.35, a, F0 + 19.3), ring(3.8, a, F0 + 22.05)
		deco(rod(m, "DomeRib", p1, p2, 0.2, Metal, IRON))
		deco(rod(m, "DomeRib", p2, C + UP * (F0 + 22.8), 0.2, Metal, IRON))
	end
	local vent = part(m, "VentBall", Vector3.new(2, 2, 2), Vector3.new(x, F0 + 23.4, z), Metal, IRON)
	vent.Shape = Enum.PartType.Ball
	cylinder(m, "VentCap", 0.3, 2.6, CFrame.new(x, F0 + 24.5, z) * UPRIGHT, Metal, IRON)
	rod(m, "LightningRod", Vector3.new(x, F0 + 24.6, z), Vector3.new(x, F0 + 31, z), 0.2, Metal, BRASS)
	-- the weathervane: an arrow into the wind, the four points under it
	local vy = Vector3.new(x, F0 + 27.8, z)
	part(m, "VaneArrow", Vector3.new(0.2, 0.2, 4), CFrame.lookAt(vy, vy - Wind.DIR), Metal, BRASS)
	part(m, "VaneTail", Vector3.new(0.08, 1.4, 1.4), CFrame.lookAt(vy + Wind.DIR * 1.8, vy + Wind.DIR * 3), Metal, BRASS)
	for k = 0, 3 do
		local a = k / 4 * TAU
		deco(rod(m, "VanePoint", vy - UP * 1.2, vy - UP * 1.2 + Vector3.new(math.cos(a), 0, math.sin(a)) * 1.6, 0.1, Metal, BRASS))
	end
	blinker(m, Vector3.new(x, F0 + 31.6, z), rng)
	rod(m, "SockArm", Vector3.new(x, F0 + 26, z), Vector3.new(x, F0 + 26, z) - Vector3.new(-Wind.DIR.Z, 0, Wind.DIR.X) * 2.5, 0.2, Metal, DARK)
	Wind.windsock(m, Vector3.new(x, F0 + 26, z) - Vector3.new(-Wind.DIR.Z, 0, Wind.DIR.X) * 2.5, rng)

	-- the lens: a beehive of glass prisms in brass, bullseyes either side,
	-- turning on the clockwork
	cylinder(m, "LensPedestal", 3.2, 2.6, CFrame.new(x, F0 + 11.2, z) * UPRIGHT, Metal, rgb(60, 70, 60))
	deco(cylinder(m, "ClockworkGear", 0.3, 3, CFrame.new(x, F0 + 12.1, z) * UPRIGHT, Metal, BRASS))
	for k = 0, 3 do
		local a = k / 4 * TAU
		deco(rod(m, "PedestalFoot", ring(1.2, a, F0 + 10.2), ring(2.2, a, F0 + 9.3), 0.25, Metal, IRON))
	end
	local lens = model(m, "Lens")
	local c = Vector3.new(x, F0 + 15.4, z)
	local profile = { 2.6, 3.4, 3.9, 4.2, 4.2, 3.9, 3.4, 2.6 }
	for k, d in ipairs(profile) do
		local y = c.Y + (k - 4.5) * 0.75
		local prism = cylinder(lens, "Prism", 0.6, d, CFrame.new(x, y, z) * UPRIGHT, Glass, rgb(220, 236, 230))
		prism.Transparency = 0.35
		prism.CanCollide = false
		deco(cylinder(lens, "PrismFrame", 0.12, d + 0.1, CFrame.new(x, y + 0.37, z) * UPRIGHT, Metal, BRASS))
	end
	for k = 0, 5 do
		local a = k / 6 * TAU
		deco(rod(lens, "LensRib", ring(2.16, a, c.Y - 3.1), ring(2.16, a, c.Y + 3.1), 0.12, Metal, BRASS))
	end
	for _, sx in ipairs({ -1, 1 }) do
		local bc = c + Vector3.new(sx * 2.25, 0, 0)
		local eye = deco(cylinder(lens, "Bullseye", 0.2, 2.4, CFrame.new(bc), Neon, rgb(255, 244, 214)))
		eye.Transparency = 0.25
		deco(cylinder(lens, "BullseyeRing", 0.24, 1.5, CFrame.new(bc + Vector3.new(sx * 0.05, 0, 0)), Metal, BRASS)).Transparency = 0.5
	end
	local core = part(lens, "LensCore", Vector3.new(1.4, 1.4, 1.4), c, Neon, rgb(255, 238, 190))
	core.Shape = Enum.PartType.Ball
	core.CanCollide = false
	local halo = deco(ellipsoid(lens, "Halo", Vector3.new(5, 6, 5), CFrame.new(c), Neon, rgb(255, 236, 190)))
	halo.Transparency = 0.9
	for _, sx in ipairs({ -1, 1 }) do
		local beam = deco(part(lens, "Beam", Vector3.new(130, 3, 3), CFrame.new(c + Vector3.new(sx * 67, 0, 0)), Neon, rgb(255, 236, 190)))
		beam.Transparency = 0.86
		local glow = deco(part(lens, "BeamGlow", Vector3.new(90, 7, 7), CFrame.new(c + Vector3.new(sx * 47, 0, 0)), Neon, rgb(255, 236, 190)))
		glow.Transparency = 0.95
		local emit = hidden(part(lens, "BeamSource", Vector3.new(0.4, 0.4, 0.4), c + Vector3.new(sx * 1, 0, 0), Smooth, DARK))
		local spot = Instance.new("SpotLight")
		spot.Range = 60
		spot.Angle = 18
		spot.Brightness = 5
		spot.Face = if sx > 0 then Enum.NormalId.Right else Enum.NormalId.Left
		spot.Color = rgb(255, 230, 180)
		spot.Parent = emit
	end
	light(core, 28, rgb(255, 220, 160), 1.8)
	Pieces.mover(lens, { Motion = "rotate", Pivot = c, Axis = UP, Speed = 0.6, Phase = 0 })

	-- the keeper's things, in the lantern room
	part(m, "LogDesk", Vector3.new(1.8, 2.6, 1.1), Vector3.new(x - 3.4, F0 + 10.3 + 0.2, z + 2.3), Wood, rgb(120, 84, 56))
	deco(part(m, "LogBook", Vector3.new(0.9, 0.12, 0.7), Vector3.new(x - 3.4, F0 + 11.95, z + 2.3), Smooth, rgb(236, 230, 210)))
	for k = 0, 1 do
		deco(cylinder(m, "OilCan", 1.2, 0.8, CFrame.new(x - 2.8 + k * 0.9, F0 + 10.8, z - 3.4) * UPRIGHT, Metal, rgb(180, 40, 36)))
	end
	marker(m, Vector3.new(x - 3, F0 + 9.6, z - 2.5))

	-- on the gallery: a fog bell, a foghorn, a telescope, a lifebuoy, a flag
	local function onGallery(deg, r)
		local a = math.rad(deg)
		local p0 = ring(r, a, F0 + 9)
		return CFrame.lookAt(p0, Vector3.new(x + math.cos(a) * 20, F0 + 9, z + math.sin(a) * 20))
	end
	local bellAt = onGallery(200, 8.6)
	rod(m, "BellPost", bellAt.Position, (bellAt * CFrame.new(0, 5, 0)).Position, 0.3, Metal, IRON)
	rod(m, "BellArm", (bellAt * CFrame.new(0, 4.8, 0)).Position, (bellAt * CFrame.new(0, 4.8, -1.4)).Position, 0.2, Metal, IRON)
	ellipsoid(m, "FogBell", Vector3.new(1.4, 1.6, 1.4), bellAt * CFrame.new(0, 3.8, -1.4), Metal, BRASS)
	deco(rod(m, "BellRope", (bellAt * CFrame.new(0, 3, -1.4)).Position, (bellAt * CFrame.new(0.3, 1.2, -1.2)).Position, 0.08, Fabric, rgb(210, 190, 140)))
	local hornAt = onGallery(330, 8.2)
	rod(m, "HornStand", hornAt.Position, (hornAt * CFrame.new(0, 2.6, 0)).Position, 0.3, Metal, IRON)
	cylinder(m, "Foghorn", 3, 0.8, hornAt * CFrame.new(0, 2.8, -1.3) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(60, 60, 60))
	ellipsoid(m, "HornMouth", Vector3.new(2, 2, 0.8), hornAt * CFrame.new(0, 2.8, -2.9), Metal, rgb(60, 60, 60))
	local scopeAt = onGallery(290, 8.4)
	for k = 0, 2 do
		local a = k / 3 * TAU
		deco(rod(m, "TripodLeg", (scopeAt * CFrame.new(math.cos(a) * 0.8, 0, math.sin(a) * 0.8)).Position, (scopeAt * CFrame.new(0, 3, 0)).Position, 0.12, Wood, TIMBER))
	end
	part(m, "Telescope", Vector3.new(0.55, 0.55, 3), scopeAt * CFrame.new(0, 3.3, -0.6) * CFrame.Angles(0.15, 0, 0), Metal, BRASS)
	local buoy = onGallery(150, 9.95) * CFrame.new(0, 2.2, 0)
	for k = 0, 7 do
		local a0, a1 = k / 8 * TAU, (k + 1) / 8 * TAU
		deco(rod(m, "Lifebuoy", (buoy * CFrame.new(math.cos(a0) * 0.9, math.sin(a0) * 0.9, 0)).Position, (buoy * CFrame.new(math.cos(a1) * 0.9, math.sin(a1) * 0.9, 0)).Position, 0.42, Fabric, if k % 2 == 0 then RED else WHITE))
	end
	local flagAt = onGallery(240, 9.4)
	rod(m, "FlagPole", flagAt.Position, flagAt.Position + UP * 8, 0.2, Metal, IRON)
	Wind.flag(m, flagAt.Position + UP * 7.7, 3.4, rng, { name = "Flag", height = 2, taper = 0.7, droop = 0.8, colors = { WHITE, RED, WHITE } })
end

-- ===== Perches: platforms on the pylons' legs, from just over the fog up =====
-- Each pylon has a stack of platforms wrapped round one of its legs, from
-- its base down towards the fog (ladders between), and the tallest two a
-- lookout high up between their arms. What's on a platform goes by how
-- high it is:
--   deep    (below -160) fog nets, lines let down into the fog off booms
--           with lamps on the ends, traps
--   damp    (to 0) mushroom logs, a cistern piped up the leg, wash tubs
--   work    (to 110) a workbench, crates, a smokehouse
--   home    (to 190) a bench, pots, a drying rack
--   garden  (to 260) a bed, beehives, a chicken coop
--   wind    (above, and the lookouts) an anemometer, a bench and a
--           telescope, a windsock
local PERCHES = {
	PA = { corner = { -1, -1 }, heights = { 44, 6, -38, -84, -132, -182, -232, -282 }, lookout = true },
	PB = { corner = { -1, -1 }, heights = { 56, 16, -34, -86 } },
	PC = { corner = { -1, 1 }, heights = { 70, 30, -16, -64, -114, -166, -218, -270 }, lookout = true },
	PD = { corner = { -1, -1 }, heights = { 60, 22, -26 } },
}

local function band(y)
	if y < -160 then
		return "deep"
	elseif y < 0 then
		return "damp"
	elseif y < 110 then
		return "work"
	elseif y < 190 then
		return "home"
	elseif y < 260 then
		return "garden"
	end
	return "wind"
end

-- A leg's half-spread at y (below the lattice's bottom node, the legs run
-- on out to their feet).
local function hwAt(P, y)
	if y >= -300 then
		return hw(P, y)
	end
	local a = hw(P, -300)
	return a + (34 - a) * (-300 - y) / 400
end

-- A platform wrapped round a pylon's leg (corner sx, sz) at height y: 20
-- square, reaching in past the leg and out beyond it, on brackets from
-- the leg below, railed round. Returns w(u, v, dy): a point on it, u and
-- v out from the leg.
local function perch(m, P, y, sx, sz, holes, rng, wet)
	local h = hwAt(P, y)
	local O = Vector3.new(P.x + sx * h, y, P.z + sz * h)
	local U, V = Vector3.new(sx, 0, 0), Vector3.new(0, 0, sz)
	local function w(u, v, dy)
		return O + U * u + V * v + UP * (dy or 0)
	end
	local a, b = w(-7, -7), w(13, 13)
	deck(m, { x0 = math.min(a.X, b.X), x1 = math.max(a.X, b.X), z0 = math.min(a.Z, b.Z), z1 = math.max(a.Z, b.Z) }, y, holes, rng, Planks, if wet then WET else nil)
	local hl = hwAt(P, y - 14)
	local foot = Vector3.new(P.x + sx * hl, y - 14, P.z + sz * hl)
	for _, q in ipairs({ { 13, -7 }, { 13, 13 }, { -7, 13 } }) do
		rod(m, "Bracket", foot, w(q[1], q[2], -1.3), 0.9, Metal, darken(STEEL, 0.8))
	end
	local cs = { w(-7, -7), w(13, -7), w(13, 13), w(-7, 13) }
	for k = 1, 4 do
		rail(m, cs[k], cs[k % 4 + 1])
	end
	box((a.X + b.X) / 2, y + 2, (a.Z + b.Z) / 2, 22, 14, 22)
	return w, U, V
end

-- What's on a platform, by its band, and no two alike: three spots on it
-- (clear of the leg and the ladders): A along one side, B along the
-- other, C in the far corner; a lamp between. Each spot has a choice of
-- things for its band.
local function fillPerch(m, kind, w, U, V, rng)
	local function spot(u, v)
		local p, c = w(u, v), w(3, 3)
		return CFrame.lookAt(p, Vector3.new(c.X, p.Y, c.Z))
	end
	local A, Bs, Cs = spot(9.5, -2.5), spot(-2.5, 9.5), spot(10, 10)
	local lampAt = w(12, 4.5)
	local LOW, GARDEN, MORE, OPEN, STOOP = TownProps.LOW, TownProps.GARDEN, TownProps.MORE, TownProps.OPEN, TownProps.STOOP_KINDS
	local function either(a, b)
		return if rng:NextNumber() < 0.5 then a else b
	end
	local function lampPost()
		rod(m, "LampPost", lampAt, lampAt + UP * 6, 0.3, Wood, TIMBER)
		lantern(m, lampAt + UP * 5, rng, true)
	end
	if kind == "deep" then
		-- a fog net along the outer side, dripping
		local n0, n1 = w(-6, 13), w(6, 13)
		for _, q in ipairs({ n0, n1 }) do
			rod(m, "NetPole", q, q + UP * 11, 0.4, Wood, darken(WET, 0.9))
		end
		fogNet(m, n0 + UP * 10.5, n1 + UP * 10.5, 8.5, V, rng)
		-- a line let down into the fog off a boom, a lamp on its end
		local base = w(10, 10)
		cylinder(m, "LineWinch", 2, 1.6, CFrame.fromMatrix(base + UP * 1.2, (U - V).Unit, UP), Metal, rgb(90, 96, 92))
		local tip = w(16, 16, 5.5)
		rod(m, "Boom", base + UP * 2, tip, 0.35, Wood, TIMBER)
		local line = model(m, "FogLine")
		local len = rng:NextNumber(18, 34)
		rod(line, "Line", tip, tip - UP * len, 0.06, Fabric, ROPE)
		local lamp = part(line, "LineLamp", Vector3.new(0.7, 1, 0.7), tip - UP * (len + 0.5), Neon, LAMP_DAMP)
		light(lamp, 16, LAMP_DAMP, 0.8)
		Wind.sway(line, tip, 0.05, rng, rng:NextNumber(3, 5))
		either(LOW.eelTraps, LOW.ropes).build(m, A, rng)
		either(MORE.shelter, LOW.buckets).build(m, Bs, rng)
		dampLamp(m, lampAt)
		for k = 1, 3 do
			deco(ellipsoid(m, "Algae", Vector3.new(2.6, rng:NextNumber(2, 4), 2.6), CFrame.new(w(0, 0, k * 2.2)), Grass, jitter(rgb(50, 80, 50), rng, 0.15)))
		end
	elseif kind == "damp" then
		if rng:NextNumber() < 0.5 then
			-- mushroom logs, leaning in a row
			for k = 0, 2 do
				local b0 = (A * CFrame.new(-1.4 + k * 1.4, 0, 0.9)).Position
				local t0 = (A * CFrame.new(-1.4 + k * 1.4, 3.6, -0.5)).Position
				rod(m, "MushroomLog", b0, t0, 0.8, Wood, rgb(90, 70, 50))
				for j = 1, 3 do
					deco(ellipsoid(m, "Mushroom", Vector3.new(0.8, 0.28, 0.8), CFrame.new(b0:Lerp(t0, j / 4) - A.LookVector * 0.45), Smooth, pick({ rgb(210, 190, 160), rgb(160, 120, 80), rgb(236, 232, 222) }, rng)))
				end
			end
		else
			LOW.filters.build(m, A, rng)
		end
		if rng:NextNumber() < 0.5 then
			-- a cistern, piped up the leg
			cylinder(m, "Cistern", 5, 4, CFrame.new(Bs.Position + UP * 2.5) * UPRIGHT, Metal, jitter(rgb(70, 90, 96), rng, 0.08))
			rod(m, "CisternPipe", Bs.Position + UP * 5, w(0.9, 0.9, 30), 0.6, Metal, rgb(80, 100, 110))
		else
			LOW.waterShrine.build(m, Bs, rng)
		end
		if rng:NextNumber() < 0.5 then
			-- a wash tub, steaming
			local tub = cylinder(m, "WashTub", 1.6, 3.2, CFrame.new(Cs.Position + UP * 0.8) * UPRIGHT, Wood, rgb(150, 112, 70))
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/smoke_main.dds"
			e.Rate = 3
			e.Lifetime = NumberRange.new(2, 3)
			e.Speed = NumberRange.new(0.6, 1.2)
			e.EmissionDirection = Enum.NormalId.Right
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
			e.Parent = tub
			deco(part(m, "Washboard", Vector3.new(1.2, 2, 0.15), Cs * CFrame.new(1.8, 1, 0) * CFrame.Angles(0.3, 0, 0), Wood, rgb(170, 140, 100)))
		else
			either(LOW.eelTraps, LOW.buckets).build(m, Cs, rng)
		end
		dampLamp(m, lampAt)
	elseif kind == "work" then
		if rng:NextNumber() < 0.5 then
			part(m, "Workbench", Vector3.new(4.4, 3, 1.8), A * CFrame.new(0, 1.5, 0), Wood, rgb(110, 84, 58))
			part(m, "Vice", Vector3.new(0.7, 0.7, 0.9), A * CFrame.new(-1.6, 3.35, 0), Metal, rgb(60, 90, 140))
			deco(part(m, "Saw", Vector3.new(2, 0.6, 0.05), A * CFrame.new(0.8, 3.3, 0.3) * CFrame.Angles(0, 0, 0.1), Metal, rgb(180, 180, 176)))
		else
			MORE.forge.build(m, A, rng)
		end
		either(OPEN.crates, MORE.radio).build(m, Bs, rng)
		if rng:NextNumber() < 0.5 then
			part(m, "Smokehouse", Vector3.new(4, 5.5, 4), Cs * CFrame.new(0, 2.75, 0), Planks, rgb(80, 64, 50))
			part(m, "SmokehouseRoof", Vector3.new(4.8, 0.3, 4.8), Cs * CFrame.new(0, 5.7, 0) * CFrame.Angles(0.15, 0, 0), Rust, pick(TIN, rng))
			smoke(m, (Cs * CFrame.new(0, 6.2, 0)).Position, 3, 1)
		else
			MORE.shelter.build(m, Cs, rng)
		end
		lampPost()
	elseif kind == "home" then
		either(OPEN.bench, OPEN.parasol).build(m, A, rng)
		either(STOOP.pots, STOOP.firewood).build(m, Bs, rng)
		either(OPEN.drying, MORE.shelter).build(m, Cs, rng)
		lampPost()
	elseif kind == "garden" then
		if rng:NextNumber() < 0.5 then
			bed(m, A, 5, 2.4, rng)
		else
			GARDEN.seedRack.build(m, A, rng)
		end
		either(GARDEN.hives, GARDEN.waterButt).build(m, Bs, rng)
		if rng:NextNumber() < 0.5 then
			part(m, "Coop", Vector3.new(3.4, 2.8, 2.6), Cs * CFrame.new(0, 2, 0.6), Planks, rgb(170, 140, 100))
			for _, sd in ipairs({ -1, 1 }) do
				rod(m, "CoopLeg", (Cs * CFrame.new(sd * 1.5, 0, 0.6)).Position, (Cs * CFrame.new(sd * 1.5, 0.7, 0.6)).Position, 0.2, Wood, TIMBER)
			end
			part(m, "CoopRoof", Vector3.new(4, 0.25, 3.2), Cs * CFrame.new(0, 3.5, 0.6) * CFrame.Angles(0.2, 0, 0), Rust, pick(TIN, rng))
			for _ = 1, 3 do
				local c = Cs * CFrame.new(rng:NextNumber(-1.6, 1.6), 0, rng:NextNumber(-2.2, -1))
				deco(ellipsoid(m, "Chicken", Vector3.new(0.6, 0.6, 0.9), c * CFrame.new(0, 0.4, 0) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Smooth, pick({ rgb(236, 232, 222), rgb(150, 90, 50) }, rng)))
			end
		else
			GARDEN.gardenShrine.build(m, Cs, rng)
		end
	else
		-- an anemometer, spinning
		rod(m, "AnemoMast", A.Position, A.Position + UP * 6, 0.2, Metal, DARK)
		local an = model(m, "Anemometer")
		local c = A.Position + UP * 6.2
		for k = 0, 2 do
			local a = k / 3 * TAU
			local arm = c + Vector3.new(math.cos(a), 0, math.sin(a)) * 1.2
			rod(an, "AnemoArm", c, arm, 0.1, Metal, DARK)
			local cup = part(an, "AnemoCup", Vector3.new(0.5, 0.5, 0.5), arm, Metal, rgb(220, 220, 214))
			cup.Shape = Enum.PartType.Ball
		end
		Wind.spin(an, c, UP, 6, rng)
		either(OPEN.bench, MORE.radio).build(m, Bs, rng)
		part(m, "Telescope", Vector3.new(0.5, 0.5, 2.6), Bs * CFrame.new(2.6, 3.2, -1.6) * CFrame.Angles(0.25, 0.4, 0), Metal, rgb(170, 140, 60))
		rod(m, "TelescopeLeg", (Bs * CFrame.new(2.6, 0, -1.6)).Position, (Bs * CFrame.new(2.6, 3, -1.6)).Position, 0.15, Metal, DARK)
		rod(m, "SockPole", Cs.Position, Cs.Position + UP * 7, 0.25, Metal, rgb(142, 146, 146))
		Wind.windsock(m, Cs.Position + UP * 7, rng)
	end
end

-- A pylon's stack of platforms: from its base down (a ladder from the base
-- deck's corner to the first, then from each to the next), and a lookout
-- up between its arms (a ladder up from the arm's walk).
local function perches(parent, P, rng)
	local spec = PERCHES[P.key]
	if not spec then
		return
	end
	local m = model(parent, "Perches")
	local sx, sz = spec.corner[1], spec.corner[2]
	local ladders = {}
	local prevY = P.base
	for i, y in ipairs(spec.heights) do
		local W = if i == 1 then hwAt(P, P.base) + 0.5 else hwAt(P, y) + 4.5
		local zW = if i == 1 then hwAt(P, P.base) - 3 else W
		ladders[i] = { top = prevY, bottom = y, x = P.x + sx * W, z = P.z + sz * zW }
		prevY = y
	end
	for i, y in ipairs(spec.heights) do
		local holes = {}
		local L = ladders[i + 1]
		if L then
			table.insert(holes, { x0 = L.x - 1.2, x1 = L.x + 1.2, z0 = L.z - 1.2, z1 = L.z + 1.2 })
		end
		local kind = band(y)
		local w, U, V = perch(m, P, y, sx, sz, holes, rng, kind == "deep" or kind == "damp")
		fillPerch(m, kind, w, U, V, rng)
		task.wait()
	end
	for _, L in ipairs(ladders) do
		ladder(m, Vector3.new(L.x, L.bottom, L.z), Vector3.new(L.x, L.top + 3, L.z))
	end
	-- the lookout, between the arms
	if spec.lookout then
		local y = P.top - 65
		local armY = P.top - 80 + 1.2
		local lx, lz = P.x + sx * 8, P.z + sz * 4
		local w, U, V = perch(m, P, y, sx, sz, { { x0 = lx - 1.2, x1 = lx + 1.2, z0 = lz - 1.2, z1 = lz + 1.2 } }, rng, false)
		fillPerch(m, "wind", w, U, V, rng)
		part(m, "ArmStep", Vector3.new(3, 0.5, 3), Vector3.new(lx, armY - 0.25, P.z + sz * 2.8), Plate, rgb(92, 92, 88))
		ladder(m, Vector3.new(lx, armY, lz), Vector3.new(lx, y + 3, lz))
	end
end

-- ===== The islands =====

-- Where on island I's edge a bridge towards (tx, tz) starts: the point,
-- the side, and how far along the side (from its middle).
local function edgePoint(I, tx, tz)
	local dx, dz = tx - I.x, tz - I.z
	if math.abs(dx) / I.hx > math.abs(dz) / I.hz then
		local mg = math.min(6, I.hz - 3)
		local along = math.clamp(tz - I.z, -I.hz + mg, I.hz - mg)
		local sx = if dx > 0 then 1 else -1
		return Vector3.new(I.x + sx * I.hx, I.y, I.z + along), if sx > 0 then "E" else "W", along
	end
	local mg = math.min(6, I.hx - 3)
	local along = math.clamp(tx - I.x, -I.hx + mg, I.hx - mg)
	local sz = if dz > 0 then 1 else -1
	return Vector3.new(I.x + along, I.y, I.z + sz * I.hz), if sz > 0 then "N" else "S", along
end

local function gap(I, side, from, to)
	I.gaps[side] = I.gaps[side] or {}
	table.insert(I.gaps[side], { from, to })
end

-- Each side's frame: its middle on the edge, the way along it, the way
-- in, and half its length.
local function sideFrame(I, side)
	if side == "N" then
		return Vector3.new(I.x, I.y, I.z + I.hz), Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), I.hx
	elseif side == "S" then
		return Vector3.new(I.x, I.y, I.z - I.hz), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), I.hx
	elseif side == "E" then
		return Vector3.new(I.x + I.hx, I.y, I.z), Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), I.hz
	end
	return Vector3.new(I.x - I.hx, I.y, I.z), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), I.hz
end

-- If a..b (along a side) runs into a gap: where past it to try next.
local function blocked(I, side, a, b)
	for _, g in ipairs(I.gaps[side] or {}) do
		if b > g[1] - 1 and a < g[2] + 1 then
			return g[2] + 1
		end
	end
	return nil
end

-- Houses along one side, backs to the edge, clear of the gaps. Returns
-- their roofs.
local function houseRow(m, I, side, rng, o)
	local mid, along, inward, half = sideFrame(I, side)
	local corner = if side == "E" or side == "W" then 16 else 1
	local pos, stop = -half + corner, half - corner
	local roofs = {}
	I.occ[side] = I.occ[side] or {}
	while pos < stop - 8 do
		local w = rng:NextNumber(14, 19)
		local d = rng:NextNumber(12, 14.5)
		if pos + w > stop then
			w = stop - pos
		end
		local skip = blocked(I, side, pos, pos + w)
		if skip then
			pos = skip
		elseif w < 11 then
			break
		else
			local at = mid + along * (pos + w / 2) + inward * (d / 2)
			local storeys = if rng:NextNumber() < o.tall then 2 else 1
			local roofC, info = house(m, CFrame.lookAt(at, at + inward), w, d, storeys, rng, { shop = o.shops and rng:NextNumber() < 0.6, palette = I.palette })
			table.insert(roofs, roofC)
			table.insert(I.houses, info)
			table.insert(I.occ[side], { pos, pos + w })
			box(at.X, at.Y + 14, at.Z, math.abs(along.X) * w + math.abs(inward.X) * d + 2, 30, math.abs(along.Z) * w + math.abs(inward.Z) * d + 2)
			pos += w + rng:NextNumber(2, 3)
		end
	end
	return roofs
end

-- Rails along whatever of each side's edge is left open (not the gaps,
-- not the backs of houses).
local function edgeRails(m, I)
	for _, side in ipairs({ "N", "S", "E", "W" }) do
		local mid, along, _, half = sideFrame(I, side)
		local spans = {}
		for _, g in ipairs(I.gaps[side] or {}) do
			table.insert(spans, g)
		end
		for _, g in ipairs(I.occ[side] or {}) do
			table.insert(spans, g)
		end
		table.sort(spans, function(a, b)
			return a[1] < b[1]
		end)
		I.rails = I.rails or {}
		local function run(a, b)
			rail(m, mid + along * a, mid + along * b)
			table.insert(I.rails, { a = mid + along * a, b = mid + along * b, side = side })
		end
		local pos = -half + 0.4
		for _, g in ipairs(spans) do
			if g[1] - 0.6 > pos + 2.5 then
				run(pos, g[1] - 0.6)
			end
			pos = math.max(pos, g[2] + 0.6)
		end
		if half - 0.4 > pos + 2.5 then
			run(pos, half - 0.4)
		end
	end
end

-- Hang island I from `hooks` (points overhead): a frame `lift` over the
-- deck, a little bigger than it; cables up from the frame's corners to
-- the nearest hook, and down from them to lugs off the deck's corners.
-- (All out past the deck's edges, clear of what's on it.)
local function hang(m, I, hooks, lift)
	local hm = model(m, "Hangers")
	local y = I.y + lift
	local ex, ez = I.hx + 3, I.hz + 3
	local corners = {
		Vector3.new(I.x - ex, y, I.z - ez), Vector3.new(I.x + ex, y, I.z - ez),
		Vector3.new(I.x + ex, y, I.z + ez), Vector3.new(I.x - ex, y, I.z + ez),
	}
	for k = 1, 4 do
		deco(rod(hm, "Frame", corners[k], corners[k % 4 + 1], 1.3, Metal, darken(STEEL, 0.75)))
	end
	for _, h in ipairs(hooks) do
		deco(part(hm, "HookBlock", Vector3.new(2, 2.4, 2), h - UP * 1.2, Metal, YELLOW))
	end
	for _, c in ipairs(corners) do
		local best, bd = hooks[1], math.huge
		for _, h in ipairs(hooks) do
			local dd = Vector3.new(h.X - c.X, 0, h.Z - c.Z).Magnitude
			if dd < bd then
				best, bd = h, dd
			end
		end
		deco(rod(hm, "Cable", best - UP * 2.4, c, 0.6, Metal, DARK))
		local foot = Vector3.new(c.X, I.y - 1.2, c.Z)
		deco(rod(hm, "Hanger", c, foot, 0.6, Metal, DARK))
		local corner = Vector3.new(I.x + math.sign(c.X - I.x) * (I.hx - 0.5), I.y - 1.2, I.z + math.sign(c.Z - I.z) * (I.hz - 0.5))
		deco(rod(hm, "Lug", foot, corner, 1, Metal, darken(STEEL, 0.75)))
		deco(part(hm, "Shackle", Vector3.new(1.1, 1.1, 1.1), foot, Metal, DARK))
		deco(part(hm, "Shackle", Vector3.new(1.3, 1.3, 1.3), c, Metal, DARK))
		box(c.X, (I.y + y) / 2, c.Z, 3, lift + 4, 3)
	end
	box(I.x, y, I.z, 2 * ex + 2, 3, 2 * ez + 2)
end

-- A sky beam: a walkway on top of a deep steel truss, from one garden's
-- edge to another's (not through a garden sitting on it). Returns a
-- hook(t) for hanging things under it.
local function skyBeam(parent, a, b, rng, onTop)
	local m = model(parent, "SkyBeam")
	local flatd = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	local side = Vector3.new(-flatd.Z, 0, flatd.X)
	local len = (b - a).Magnitude
	local DEPTH = 6
	local color = jitter(STEEL, rng, 0.05)
	local spans = { { 0, 1 } }
	if onTop then
		local t0, t1
		if math.abs(b.X - a.X) > math.abs(b.Z - a.Z) then
			t0, t1 = (onTop.x - onTop.hx - a.X) / (b.X - a.X), (onTop.x + onTop.hx - a.X) / (b.X - a.X)
		else
			t0, t1 = (onTop.z - onTop.hz - a.Z) / (b.Z - a.Z), (onTop.z + onTop.hz - a.Z) / (b.Z - a.Z)
		end
		t0, t1 = math.min(t0, t1), math.max(t0, t1)
		spans = { { 0, t0 }, { t1, 1 } }
	end
	local function inSpans(t)
		for _, sp in ipairs(spans) do
			if t >= sp[1] - 1e-3 and t <= sp[2] + 1e-3 then
				return true
			end
		end
		return false
	end
	for _, sp in ipairs(spans) do
		local p0, p1 = a:Lerp(b, sp[1]), a:Lerp(b, sp[2])
		if (p1 - p0).Magnitude > 0.5 then
			part(m, "Walkway", Vector3.new(4.6, 0.4, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, -0.2, 0), Planks, jitter(TIMBER, rng, 0.06))
			for _, sd in ipairs({ -1, 1 }) do
				rod(m, "Handrail", p0 + side * sd * 2.5 + UP * 3.4, p1 + side * sd * 2.5 + UP * 3.4, 0.22, Metal, DARK)
			end
		end
	end
	local n = math.max(2, math.floor(len / 8))
	for _, sd in ipairs({ -1, 1 }) do
		local o = side * sd * 2.5
		rod(m, "TopChord", a + o - UP * 0.6, b + o - UP * 0.6, 0.7, Metal, color)
		rod(m, "BottomChord", a + o - UP * DEPTH, b + o - UP * DEPTH, 0.7, Metal, color)
		for i = 0, n do
			local t = i / n
			local p = a:Lerp(b, t) + o
			deco(rod(m, "Post", p - UP * DEPTH, p + (if inSpans(t) then UP * 3.4 else -UP * 0.6), 0.3, Metal, color))
			if i < n then
				deco(rod(m, "Diagonal", p - UP * DEPTH, a:Lerp(b, (i + 1) / n) + o - UP * 0.6, 0.3, Metal, color))
			end
		end
	end
	for i = 0, n, 2 do
		local p = a:Lerp(b, i / n) - UP * DEPTH
		deco(rod(m, "Tie", p - side * 2.5, p + side * 2.5, 0.3, Metal, color))
	end
	-- lanterns hung off the handrails, a flower box or two on them
	local k = 0
	for t = 0.18, 0.86, 0.22 do
		k += 1
		if inSpans(t) then
			local sd = if k % 2 == 0 then 1 else -1
			local top = a:Lerp(b, t) + side * sd * 2.5 + UP * 3.4
			deco(rod(m, "LanternArm", top, top + side * sd * 0.9, 0.08, Metal, DARK))
			lantern(m, top + side * sd * 0.9 - UP * 1.5, rng)
			if rng:NextNumber() < 0.55 and inSpans(t + 0.08) then
				TownProps.flowerBox(m, a:Lerp(b, t + 0.08) - side * sd * 2.5 + UP * 3.5, flatd, -side * sd, rng)
			end
		end
	end
	local c = (a + b) / 2
	box(c.X, c.Y - 1, c.Z, math.abs(b.X - a.X) + 8, math.abs(b.Y - a.Y) + 12, math.abs(b.Z - a.Z) + 8)
	return {
		hook = function(t)
			return a:Lerp(b, t) - UP * DEPTH
		end,
	}
end

-- The balance: a great beam through the tallest pylon on a bearing, the
-- market deck hung from its east end, a tank of the town's water from
-- its west end to balance it; a cogwheel turning at the pivot, a pipe
-- running along it. Returns the hooks for the market.
local function balance(parent, P, I, rng)
	local m = model(parent, "Balance")
	local color = jitter(STEEL, rng, 0.05)
	local z, y = P.z + 8, BALANCE_Y
	local x0, x1 = COUNTERWEIGHT_X, I.x + I.hx - 1
	for _, sz in ipairs({ -3, 3 }) do
		for _, dy in ipairs({ 0, -6 }) do
			rod(m, "BeamChord", Vector3.new(x0, y + dy, z + sz), Vector3.new(x1, y + dy, z + sz), 0.9, Metal, color)
		end
		for x = x0, x1 - 6, 6 do
			deco(rod(m, "BeamPost", Vector3.new(x, y - 6, z + sz), Vector3.new(x, y, z + sz), 0.35, Metal, color))
			deco(rod(m, "BeamLace", Vector3.new(x, y - 6, z + sz), Vector3.new(x + 6, y, z + sz), 0.35, Metal, color))
		end
	end
	for x = x0, x1, 12 do
		deco(rod(m, "BeamTie", Vector3.new(x, y, z - 3), Vector3.new(x, y, z + 3), 0.35, Metal, color))
	end
	for _, x in ipairs({ x0, x1 }) do
		part(m, "BeamEnd", Vector3.new(1.4, 7, 7), Vector3.new(x, y - 3, z), Metal, YELLOW)
	end
	-- the pivot: a great bearing, braced into the pylon's legs
	local pv = Vector3.new(P.x, y - 3, z)
	cylinder(m, "Bearing", 9, 7, CFrame.new(pv) * CFrame.Angles(0, math.pi / 2, 0), Metal, darken(STEEL, 0.6))
	local w = hw(P, y)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			rod(m, "BearingBrace", pv + Vector3.new(sx * 3, 0, sz * 4.5), Vector3.new(P.x + sx * w, y - 3, P.z + sz * w), 0.8, Metal, color)
		end
	end
	-- the cogwheel beside it, turning
	local cog = model(m, "Cogwheel")
	local cc = pv + Vector3.new(0, 0, -6.4)
	local wheel = CFrame.new(cc) * CFrame.Angles(0, math.pi / 2, 0)
	cylinder(cog, "CogDisc", 0.8, 13, wheel, Metal, rgb(150, 120, 60))
	cylinder(cog, "CogHub", 1.4, 3, wheel, Metal, DARK)
	for k = 0, 15 do
		local a = k / 16 * TAU
		deco(part(cog, "Tooth", Vector3.new(1.2, 1.4, 0.8), CFrame.new(cc + Vector3.new(math.cos(a) * 6.8, math.sin(a) * 6.8, 0)) * CFrame.Angles(0, 0, a), Metal, rgb(130, 104, 52)))
	end
	for k = 0, 2 do
		local a = k / 3 * TAU
		deco(part(cog, "Spoke", Vector3.new(0.9, 11, 0.9), CFrame.new(cc) * CFrame.Angles(0, 0, a) , Metal, rgb(120, 96, 48)))
	end
	Wind.spin(cog, cc, Vector3.zAxis, 0.3, rng)
	-- the counterweight: the town's water
	local tc = Vector3.new(x0 + 5, y - 38, z)
	cylinder(m, "Counterweight", 18, 22, CFrame.new(tc) * UPRIGHT, Metal, rgb(84, 112, 128))
	cylinder(m, "CounterweightRim", 0.8, 23, CFrame.new(tc + UP * 9.2) * UPRIGHT, Rust, rgb(96, 70, 52))
	for yy = -6, 6, 6 do
		deco(cylinder(m, "Hoop", 0.6, 22.4, CFrame.new(tc + UP * yy) * UPRIGHT, Rust, rgb(96, 70, 52)))
	end
	label(m, CFrame.lookAt(tc + Vector3.new(0, 0, -11.25), tc + Vector3.new(0, 0, -12)), Vector3.new(8, 8, 0.1), Enum.NormalId.Front, "水", rgb(84, 112, 128), rgb(236, 232, 222), Smooth, Enum.Font.GothamBlack).Transparency = 1
	for k = 0, 3 do
		local a = k / 4 * TAU + math.pi / 4
		local rim = tc + UP * 9 + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)
		rod(m, "TankChain", rim, Vector3.new(x0 + 5 + math.cos(a) * 2.5, y - 6, z + math.sin(a) * 2.5), 0.6, Metal, DARK)
	end
	-- a pipe from it along the beam, to the market
	rod(m, "WaterPipe", tc + UP * 9, Vector3.new(x0 + 5, y - 6.8, z - 3.8), 1, Metal, rgb(80, 100, 110))
	rod(m, "WaterPipe", Vector3.new(x0 + 5, y - 6.8, z - 3.8), Vector3.new(I.x - 10, y - 6.8, z - 3.8), 1, Metal, rgb(80, 100, 110))
	box((x0 + x1) / 2, y - 3, z, math.abs(x1 - x0) + 4, 10, 9)
	box(tc.X, tc.Y, tc.Z, 24, 20, 24)
	return { Vector3.new(I.x - I.hx + 3, y - 6, z), Vector3.new(I.x + I.hx - 3, y - 6, z) }
end

-- What an island that stands (rather than hangs) stands on: one great
-- strut up out of the fog, an old steel column or a brick chimney, a
-- steel collar round its head and four struts out to the deck's corners;
-- a ledge round it under the deck, and a ladder up to a hatch.
local function support(m, I, rng)
	if I.support == "legs" then
		-- four great raking legs, splayed out north and south down into the
		-- fog, from under the deck (in from its corners)
		local sm = model(m, "Legs")
		local legs = {}
		local color = jitter(rgb(96, 74, 58), rng, 0.06)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local top = Vector3.new(I.x + sx * (I.hx - 6), I.y - 1.6, I.z + sz * (I.hz - 3))
				local foot = Vector3.new(top.X, DEEP, top.Z + sz * (top.Y - DEEP) * 0.35)
				rod(sm, "Leg", foot, top, 3.4, Rust, color)
				part(sm, "LegShoe", Vector3.new(4.6, 1.6, 4.6), top - UP * 0.2, Metal, darken(STEEL, 0.7))
				for k = 1, 3 do
					local p = top:Lerp(foot, k * 0.04)
					deco(cylinder(sm, "LegBand", 0.7, 3.9, CFrame.lookAt(p, foot) * CFrame.Angles(0, math.pi / 2, 0), Metal, darken(STEEL, 0.6)))
				end
				legs[sx .. "," .. sz] = { top = top, foot = foot }
				local mid = top:Lerp(foot, 0.08)
				box(mid.X, mid.Y, mid.Z, 5, 90, 30)
			end
		end
		local function at(l, y)
			return l.top:Lerp(l.foot, (l.top.Y - y) / (l.top.Y - l.foot.Y))
		end
		-- each pair (the north ones, the south ones) tied and crossed
		for _, sz in ipairs({ -1, 1 }) do
			local a, b = legs["-1," .. sz], legs["1," .. sz]
			local y1 = I.y - 34
			rod(sm, "LegTie", at(a, y1), at(b, y1), 1.4, Metal, STEEL)
			deco(rod(sm, "LegCross", at(a, I.y - 3), at(b, y1), 0.9, Metal, STEEL))
			deco(rod(sm, "LegCross", at(b, I.y - 3), at(a, y1), 0.9, Metal, STEEL))
		end
		for _, sx in ipairs({ -1, 1 }) do
			deco(rod(sm, "Girder", legs[sx .. ",-1"].top - UP * 0.3, legs[sx .. ",1"].top - UP * 0.3, 1.4, Metal, darken(STEEL, 0.75)))
		end
		-- and braced back to its pylon
		for _, P in ipairs(PYLONS) do
			if P.key == I.brace then
				local y0 = I.y - 26
				local side = if I.x > P.x then 1 else -1
				for _, dz in ipairs({ -10, 10 }) do
					rod(sm, "PylonBrace", Vector3.new(P.x + side * hw(P, y0), y0, P.z + dz), Vector3.new(I.x - side * (I.hx - 1), I.y - 1.8, I.z + dz), 1.6, Metal, STEEL)
				end
			end
		end
		return
	end
	local brick = I.support == "chimney"
	local d = if brick then 9 else 4.4
	local c = Vector3.new(I.x, 0, I.z)
	local sm = model(m, "Strut")
	if brick then
		cylinder(sm, "Chimney", I.y - 2 - DEEP, d, CFrame.new(c.X, (I.y - 2 + DEEP) / 2, c.Z) * UPRIGHT, Enum.Material.Brick, jitter(rgb(112, 62, 48), rng, 0.06))
		for y = I.y - 70, I.y - 30, 14 do
			deco(cylinder(sm, "ChimneyBand", 0.8, d + 0.4, CFrame.new(c.X, y, c.Z) * UPRIGHT, Metal, DARK))
		end
	else
		cylinder(sm, "Column", I.y - 2 - DEEP, d, CFrame.new(c.X, (I.y - 2 + DEEP) / 2, c.Z) * UPRIGHT, Rust, jitter(rgb(96, 74, 58), rng, 0.08))
		for y = I.y - 60, I.y - 30, 12 do
			deco(cylinder(sm, "ColumnFlange", 0.6, d + 1, CFrame.new(c.X, y, c.Z) * UPRIGHT, Metal, darken(STEEL, 0.7)))
		end
	end
	cylinder(sm, "Collar", 1.6, d + 4, CFrame.new(c.X, I.y - 2.4, c.Z) * UPRIGHT, Metal, darken(STEEL, 0.8))
	-- the struts, from lower down the column out to the corners
	local low = I.y - 22
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			rod(sm, "Strut", Vector3.new(c.X + sx * d * 0.35, low + 1.5, c.Z + sz * d * 0.35), Vector3.new(I.x + sx * (I.hx - 2), I.y - 1.6, I.z + sz * (I.hz - 2)), 1.2, Metal, STEEL)
		end
	end
	for _, dz in ipairs({ -1, 1 }) do
		deco(rod(sm, "Girder", Vector3.new(I.x - I.hx + 1, I.y - 1.9, I.z + dz * (I.hz - 2)), Vector3.new(I.x + I.hx - 1, I.y - 1.9, I.z + dz * (I.hz - 2)), 1.2, Metal, darken(STEEL, 0.75)))
	end
	-- the ledge round the column where the struts meet it, and the way down
	local r = d / 2 + 5
	deck(sm, { x0 = c.X - r, x1 = c.X + r, z0 = c.Z - r, z1 = c.Z + r }, low, { { x0 = c.X - d / 2, x1 = c.X + d / 2, z0 = c.Z - d / 2, z1 = c.Z + d / 2 } }, rng, Plate, rgb(92, 92, 88))
	for _, e in ipairs({ { -r, -r, r, -r }, { r, -r, r, r }, { r, r, -r, r }, { -r, r, -r, -r } }) do
		rail(sm, Vector3.new(c.X + e[1], low, c.Z + e[2]), Vector3.new(c.X + e[3], low, c.Z + e[4]))
	end
	local hx, hz = I.x + I.hatch[1], I.z + I.hatch[2]
	ladder(sm, Vector3.new(hx, low, hz), Vector3.new(hx, I.y + 2, hz))
	part(sm, "HatchRim", Vector3.new(3, 0.3, 0.4), Vector3.new(hx, I.y + 0.15, hz - 1.4), Metal, YELLOW)
	part(sm, "HatchLid", Vector3.new(2.6, 0.2, 2.6), CFrame.new(hx, I.y + 1.3, hz - 1.6) * CFrame.Angles(math.rad(80), 0, 0), Metal, rgb(90, 96, 92))
	dampLamp(sm, Vector3.new(c.X - r + 1.2, low, c.Z - r + 1.2))
	marker(sm, Vector3.new(c.X + r - 2, low, c.Z - r + 2))
end

-- ===== The things about the place =====

-- (what's taken on a deck: rects {x0, x1, z0, z1})
local function blockRect(I, x0, x1, z0, z1)
	table.insert(I.blocks, { math.min(x0, x1), math.max(x0, x1), math.min(z0, z1), math.max(z0, z1) })
end

local function localRect(cf, x0, x1, z0, z1)
	local ax, bx, az, bz = math.huge, -math.huge, math.huge, -math.huge
	for _, q in ipairs({ { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } }) do
		local p = (cf * CFrame.new(q[1], 0, q[2])).Position
		ax, bx, az, bz = math.min(ax, p.X), math.max(bx, p.X), math.min(az, p.Z), math.max(bz, p.Z)
	end
	return ax, bx, az, bz
end

local function isFree(I, x0, x1, z0, z1)
	if x0 < I.x - I.hx + 0.4 or x1 > I.x + I.hx - 0.4 or z0 < I.z - I.hz + 0.4 or z1 > I.z + I.hz - 0.4 then
		return false
	end
	for _, b in ipairs(I.blocks) do
		if x0 < b[2] and x1 > b[1] and z0 < b[4] and z1 > b[3] then
			return false
		end
	end
	return true
end

-- Put a prop at cf (on the deck, facing its way) if there's room for it.
local function put(parent, I, def, cf, rng, o)
	local s = def.size
	local x0, x1, z0, z1 = localRect(cf, -s.X / 2 - 0.4, s.X / 2 + 0.4, -s.Z / 2 - 0.4, s.Z / 2 + 0.4)
	if not def.overhead and not isFree(I, x0, x1, z0, z1) then
		return false
	end
	def.build(parent, cf, rng, o)
	if not def.overhead then
		blockRect(I, x0, x1, z0, z1)
	end
	return true
end

local function shuffle(list, rng)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

-- Scatter things from `pool` (in the order of `names`) over deck R, each
-- where there's room, facing into the middle; `edge` ones only near the
-- edges.
local function scatter(parent, R, pool, names, rng, edge)
	local cells = {}
	for x = R.x - R.hx + 2.5, R.x + R.hx - 2.5, 2.5 do
		for z = R.z - R.hz + 2.5, R.z + R.hz - 2.5, 2.5 do
			table.insert(cells, Vector3.new(x, R.y, z))
		end
	end
	shuffle(cells, rng)
	for _, name in ipairs(names) do
		local def = pool[name]
		for _, c in ipairs(cells) do
			local e = math.min(R.hx - math.abs(c.X - R.x), R.hz - math.abs(c.Z - R.z))
			if not (edge and edge[name]) or e < 7 then
				local to = Vector3.new(R.x - c.X, 0, R.z - c.Z)
				local face = if math.abs(to.X) > math.abs(to.Z) then Vector3.new(math.sign(to.X), 0, 0) else Vector3.new(0, 0, if to.Z == 0 then -1 else math.sign(to.Z))
				if put(parent, R, def, CFrame.lookAt(c, c + face), rng) then
					break
				end
			end
		end
	end
end

-- Dress a deck: things by the doors, things out on the deck (at its
-- edges mostly, the middle left to walk), futons over the rails, window
-- boxes, patches underfoot. Keeps clear of the doors, the bridges' and
-- stairs' ways in, where the crossing comes in, and what's already there.
local function dress(m, I, rng)
	local dm = model(m, "Props")
	for side, list in pairs(I.gaps) do
		local mid, along, inward = sideFrame(I, side)
		for _, g in ipairs(list) do
			local a = mid + along * (g[1] - 1)
			local b = mid + along * (g[2] + 1) + inward * 9
			blockRect(I, a.X, b.X, a.Z, b.Z)
		end
	end
	if I.hatch then
		blockRect(I, I.x + I.hatch[1] - 2, I.x + I.hatch[1] + 2, I.z + I.hatch[2] - 2, I.z + I.hatch[2] + 2)
	end
	for _, h in ipairs(I.houses) do
		blockRect(I, localRect(h.cf, -h.w / 2, h.w / 2, -h.d / 2, h.d / 2))
		blockRect(I, localRect(h.cf, h.doorX - h.doorW / 2 - 0.8, h.doorX + h.doorW / 2 + 0.8, -h.d / 2 - 6, -h.d / 2))
	end
	-- by the doors
	local eave = STOREY - 0.6
	for _, h in ipairs(I.houses) do
		if rng:NextNumber() < 0.35 then
			put(dm, I, TownProps.STOOP_KINDS.barrel, h.cf * CFrame.new(pick({ -1, 1 }, rng) * (h.w / 2 - 1.3), 0, -h.d / 2 - 1.4), rng, { eave = eave })
		end
		for _ = 1, rng:NextInteger(1, 3) do
			local kind = TownProps.STOOP_KINDS[pick(TownProps.STOOP, rng)]
			if kind.overhead then
				if not h.shop then
					-- (towards the middle of the front, clear of the door's canopy)
					local toward = if h.doorX > 0 then -1 else 1
					put(dm, I, kind, h.cf * CFrame.new(h.doorX + toward * (h.doorW / 2 + 2.6), 0, -h.d / 2), rng, { eave = eave })
				end
			else
				local x = rng:NextNumber(-h.w / 2 + kind.size.X / 2 + 0.3, h.w / 2 - kind.size.X / 2 - 0.3)
				put(dm, I, kind, h.cf * CFrame.new(x, 0, -h.d / 2 - kind.size.Z / 2 - 0.5), rng, { eave = eave })
			end
		end
	end
	-- out on the deck
	local want
	if I.arrive then
		want = { "vending", "vending", "stove", "bench", "bench", "jizo", "notice", "washing", "drying", "tree", "tree", "parasol", "post", "crates", "sake" }
		if I.yatai then
			table.insert(want, 1, "yatai")
		end
	else
		want = { "bench", "tree", "drying", "crates", "washing" }
	end
	local EDGE = { vending = true, notice = true, sake = true, crates = true, tree = true, post = true }
	local cells = {}
	for x = I.x - I.hx + 3, I.x + I.hx - 3, 3 do
		for z = I.z - I.hz + 3, I.z + I.hz - 3, 3 do
			table.insert(cells, Vector3.new(x, I.y, z))
		end
	end
	shuffle(cells, rng)
	for _, name in ipairs(want) do
		local def = TownProps.OPEN[name]
		for _, c in ipairs(cells) do
			local edge = math.min(I.hx - math.abs(c.X - I.x), I.hz - math.abs(c.Z - I.z))
			if not EDGE[name] or edge < 8 then
				-- facing into the deck
				local to = Vector3.new(I.x - c.X, 0, I.z - c.Z)
				local face = if math.abs(to.X) > math.abs(to.Z) then Vector3.new(math.sign(to.X), 0, 0) else Vector3.new(0, 0, if to.Z == 0 then -1 else math.sign(to.Z))
				if put(dm, I, def, CFrame.lookAt(c, c + face), rng) then
					break
				end
			end
		end
	end
	-- futons over the rails, window boxes on them
	if I.rails and #I.rails > 0 then
		for k = 1, if I.arrive then 4 else 2 do
			local r = I.rails[rng:NextInteger(1, #I.rails)]
			local len = (r.b - r.a).Magnitude
			if len > 5 then
				local along = (r.b - r.a).Unit
				local _, _, inward = sideFrame(I, r.side)
				local top = r.a:Lerp(r.b, rng:NextNumber(2.2 / len, 1 - 2.2 / len)) + UP * 3.5
				if k % 2 == 1 then
					TownProps.futon(dm, top, along, -inward, rng)
				else
					TownProps.flowerBox(dm, top - UP * 0.2, along, -inward, rng)
				end
			end
		end
	end
	-- patches underfoot
	for _ = 1, if I.arrive then 12 else 4 do
		TownProps.patch(dm, Vector3.new(I.x + rng:NextNumber(-I.hx + 3, I.hx - 3), I.y, I.z + rng:NextNumber(-I.hz + 3, I.hz - 3)), rng)
	end
end

-- Dress a pylon's garden and its base, round what's there already.
local function dressPylon(parent, P, rng)
	local m = model(parent, "PylonProps")
	-- the garden: round the beds, the glasshouse, the tank, the winches,
	-- clear of the legs and where the sky beams come in
	local G = P.g
	G.blocks = {}
	local gh = G.hx
	local inner = hw(P, P.garden) + 1.5
	blockRect(G, P.x - inner, P.x + inner, P.z - inner, P.z + inner)
	for _, sz in ipairs({ -1, 1 }) do
		for k = -1, 1 do
			blockRect(G, P.x + k * 10 - 4.4, P.x + k * 10 + 4.4, P.z + sz * (gh - 3) - 2.2, P.z + sz * (gh - 3) + 2.2)
		end
	end
	for k = -1, 1, 2 do
		blockRect(G, P.x + gh - 5.2, P.x + gh - 0.8, P.z + k * 8 - 3.9, P.z + k * 8 + 3.9)
	end
	blockRect(G, P.x - gh + 0.5, P.x - gh + 9.5, P.z - 5.5, P.z + 5.5)
	blockRect(G, P.x + gh - 6, P.x + gh, P.z + gh - 6, P.z + gh)
	if P.aero then
		local c = Vector3.new(P.x + P.aero[1] * (gh - 5), 0, P.z + P.aero[2] * (gh - 5))
		blockRect(G, c.X - 5, c.X + 5, c.Z - 5, c.Z + 5)
	end
	if P.kite then
		local c = Vector3.new(P.x + P.kite[1] * (gh - 4), 0, P.z + P.kite[2] * (gh - 4))
		blockRect(G, c.X - 3.5, c.X + 3.5, c.Z - 3.5, c.Z + 3.5)
	end
	for side, list in pairs(G.gaps) do
		local mid, along, inward = sideFrame(G, side)
		for _, g in ipairs(list) do
			local a = mid + along * (g[1] - 1)
			local b = mid + along * (g[2] + 1) + inward * 9
			blockRect(G, a.X, b.X, a.Z, b.Z)
		end
	end
	scatter(m, G, TownProps.GARDEN, shuffle({ "pergola", "compost", "barrow", "seedRack", "toolShed", "gardenShrine", "waterButt", "hives" }, rng), rng)
	-- the base: round the lift, the pump, the lamps, the ladder down, and
	-- where the boardwalk comes in
	local bh = hw(P, P.base) - 1
	local Bd = { x = P.x, z = P.z, hx = bh, hz = bh, y = P.base, blocks = {} }
	blockRect(Bd, P.x - 7.5, P.x + 0.5, P.z - 4, P.z + 4)
	blockRect(Bd, P.x + 2, P.x + 10.5, P.z - 10.5, P.z - 1.5)
	for _, o in ipairs({ { -1, -1 }, { 1, 1 } }) do
		local c = Vector3.new(P.x + o[1] * (bh - 2), 0, P.z + o[2] * (bh - 2))
		blockRect(Bd, c.X - 1.5, c.X + 1.5, c.Z - 1.5, c.Z + 1.5)
	end
	local spec = PERCHES[P.key]
	if spec then
		local c = Vector3.new(P.x + spec.corner[1] * (bh - 1), 0, P.z + spec.corner[2] * (hw(P, P.base) - 3))
		blockRect(Bd, c.X - 3.5, c.X + 3.5, c.Z - 3.5, c.Z + 3.5)
	end
	for _, pair in ipairs(LOW_BRIDGES) do
		if pair[2] == P.key then
			local L = LOWS[pair[1]]
			local pe = edgePoint(Bd, (L.x0 + L.x1) / 2, (L.z0 + L.z1) / 2)
			blockRect(Bd, pe.X - 5, pe.X + 5, pe.Z - 5, pe.Z + 5)
		end
	end
	scatter(m, Bd, TownProps.LOW, shuffle({ "filters", "ropes", "waterShrine", "buckets", "eelTraps" }, rng), rng)
end

-- ===== What's in the middle of each =====

local PLAZAS = {}

-- The water tower: a big tank on legs, the fog's water pumped up to it
-- from below; a trough and taps under it, a garden on its roof, and a
-- turbine flying from that.
function PLAZAS.water(m, I, rng)
	local c = Vector3.new(I.x + 4, I.y, I.z)
	I.blocks = I.blocks or {}
	table.insert(I.blocks, { c.X - 16, c.X + 9.5, c.Z - 9, c.Z + 9 })
	for _, o in ipairs({ { -6, -6 }, { 6, -6 }, { 6, 6 }, { -6, 6 } }) do
		rod(m, "TowerLeg", c + Vector3.new(o[1], 0, o[2]), c + Vector3.new(o[1] * 0.85, 16, o[2] * 0.85), 1.2, Metal, STEEL)
	end
	for _, o in ipairs({ { -6, -6, 6, 6 }, { 6, -6, -6, 6 } }) do
		deco(rod(m, "TowerBrace", c + Vector3.new(o[1], 1, o[2]), c + Vector3.new(o[3] * 0.85, 15, o[4] * 0.85), 0.4, Metal, STEEL))
	end
	cylinder(m, "WaterTank", 12, 15, CFrame.new(c + UP * 22) * UPRIGHT, Metal, rgb(84, 112, 128))
	cylinder(m, "TankRoof", 0.6, 16, CFrame.new(c + UP * 28.3) * UPRIGHT, Metal, darken(rgb(84, 112, 128), 0.8))
	label(m, CFrame.lookAt(c + UP * 22 + Vector3.new(7.55, 0, 0), c + UP * 22 + Vector3.new(9, 0, 0)), Vector3.new(5, 5, 0.1), Enum.NormalId.Front, "水", rgb(84, 112, 128), rgb(236, 232, 222), Smooth, Enum.Font.GothamBlack).Transparency = 1
	rod(m, "Riser", c + Vector3.new(-3, 16, 3), Vector3.new(c.X - 3, LOWS.A.y + 2, c.Z + 3), 1.4, Metal, rgb(80, 100, 110))
	ladder(m, c + Vector3.new(7.9, 0, -3), c + Vector3.new(7.9, 29.6, -3))
	-- the trough and taps
	part(m, "Trough", Vector3.new(8, 2.4, 2.4), c + Vector3.new(-10, 1.2, 0), Concrete, rgb(150, 146, 138))
	local water = part(m, "TroughWater", Vector3.new(7.4, 0.1, 1.8), c + Vector3.new(-10, 2.2, 0), Glass, rgb(110, 150, 160))
	water.Transparency = 0.3
	for k = -1, 1 do
		rod(m, "Tap", c + Vector3.new(-10 + k * 2.4, 2.4, 1.2), c + Vector3.new(-10 + k * 2.4, 5, 1.2), 0.3, Metal, rgb(170, 140, 60))
	end
	for k = 0, 3 do
		deco(cylinder(m, "Bucket", 1.1, 1, CFrame.new(c + Vector3.new(-14 + k * 1.4, 0.55, -2.4 + (k % 2) * 0.6)) * UPRIGHT, Metal, pick({ rgb(120, 124, 120), rgb(60, 90, 140), rgb(180, 60, 50) }, rng)))
	end
	-- the garden on its roof
	local r0 = c + UP * 28.6
	for k = -1, 1, 2 do
		bed(m, CFrame.new(r0 + Vector3.new(0, 0, k * 3)), 9, 2.4, rng)
	end
	local prev
	for k = 0, 16 do
		local a = k / 16 * TAU
		local p = r0 + Vector3.new(math.cos(a) * 7.6, 0, math.sin(a) * 7.6)
		-- (open where the ladder comes up)
		local open = math.abs(a - TAU * 0.95) < 0.3
		if prev and not open then
			rod(m, "TankRail", prev + UP * 3.4, p + UP * 3.4, 0.18, Metal, DARK)
		end
		if not open then
			rod(m, "TankRailPost", p, p + UP * 3.4, 0.15, Metal, DARK)
		end
		prev = if open then nil else p
	end
	lantern(m, c + Vector3.new(-6, 12, -6), rng, true)
	box(c.X, I.y + 20, c.Z, 20, 40, 20)
end

-- The market, in by the gate: stalls in two rows, lanterns strung over
-- them, carp flying; the gate on the east side, where the crossing comes
-- in.
function PLAZAS.market(m, I, rng)
	table.insert(I.blocks, { I.x - 13, I.x + 18, I.z - 12, I.z + 12 })
	table.insert(I.blocks, { I.x + 20, I.x + 24, I.z - 13, I.z - 9 })
	for _, z in ipairs({ I.z - 8, I.z + 8 }) do
		for k = 0, 2 do
			local c = Vector3.new(I.x - 8 + k * 10, I.y, z)
			local cloth = pick(CLOTHS, rng)
			part(m, "StallCounter", Vector3.new(7, 3.6, 2.4), c + UP * 1.8, Wood, rgb(130, 96, 64))
			for _, sx in ipairs({ -3.4, 3.4 }) do
				for _, sz in ipairs({ -2.4, 2.4 }) do
					rod(m, "StallPole", c + Vector3.new(sx, 0, sz), c + Vector3.new(sx, 10, sz), 0.3, Wood, TIMBER)
				end
			end
			deco(part(m, "Awning", Vector3.new(8, 0.15, 6), CFrame.new(c + UP * 10.2) * CFrame.Angles(math.rad(8), 0, 0), Fabric, cloth))
			Wind.cloth(m, c + Vector3.new(-4, 9.8, -3.2), c + Vector3.new(4, 9.8, -3.2), 1.4, Vector3.new(0, 0, -1), rng, { name = "AwningFringe", color = cloth, strip = 0.7, thick = 0.08 })
			for j = 0, 4 do
				deco(part(m, "Goods", Vector3.new(1.1, rng:NextNumber(0.6, 1.2), 1.1), c + Vector3.new(-2.6 + j * 1.3, 4, 0), Smooth, pick({ rgb(200, 120, 60), rgb(90, 130, 90), rgb(220, 210, 180), rgb(160, 60, 50) }, rng)))
			end
			part(m, "Crate", Vector3.new(2, 1.6, 2), c + Vector3.new(4.6, 0.8, 1.6), Wood, jitter(rgb(150, 112, 70), rng, 0.1))
		end
		-- a string of lanterns over each row
		local a, b = Vector3.new(I.x - 13, I.y + 12.5, z), Vector3.new(I.x + 17, I.y + 12.5, z)
		deco(rod(m, "LanternString", a, b, 0.08, Fabric, rgb(60, 50, 40)))
		for k = 1, 8 do
			local p = a:Lerp(b, k / 9) - UP * (1.2 * 4 * (k / 9) * (1 - k / 9))
			lantern(m, p - UP * 1.4, rng, k % 3 == 0)
		end
		for _, e in ipairs({ a, b }) do
			rod(m, "StringPole", Vector3.new(e.X, I.y, e.Z), e + UP * 0.3, 0.35, Wood, TIMBER)
		end
	end
	-- carp streamers on a tall pole
	local pole = Vector3.new(I.x + 22, I.y, I.z - 11)
	rod(m, "CarpPole", pole, pole + UP * 26, 0.5, Wood, rgb(200, 190, 160))
	for k, color in ipairs({ rgb(30, 30, 34), rgb(190, 50, 44), rgb(60, 90, 160) }) do
		carp(m, pole + UP * (24 - k * 5), 8 - k, color, rng)
	end
	box(pole.X + 4, I.y + 18, pole.Z, 12, 20, 6)
	-- the gate: two great posts either side of where the routes come in
	local gx = I.x + I.hx - 1
	for _, s in ipairs({ -1, 1 }) do
		rod(m, "GatePost", Vector3.new(gx, I.y - 1, I.z + s * 15.5), Vector3.new(gx, I.y + 16, I.z + s * 15.5), 1.6, Wood, rgb(150, 50, 36))
		lantern(m, Vector3.new(gx - 1.4, I.y + 9, I.z + s * 15.5), rng, true)
	end
	part(m, "GateBeam", Vector3.new(1.6, 1.6, 36), Vector3.new(gx, I.y + 16.4, I.z), Wood, rgb(40, 34, 30))
	part(m, "GateBeam", Vector3.new(1.2, 1, 32), Vector3.new(gx, I.y + 14, I.z), Wood, rgb(150, 50, 36))
	label(m, CFrame.lookAt(Vector3.new(gx + 0.7, I.y + 14, I.z - 7), Vector3.new(gx + 2, I.y + 14, I.z - 7)), Vector3.new(6, 2.6, 0.1), Enum.NormalId.Front, "風見", rgb(236, 226, 196), rgb(40, 34, 30), Wood, Enum.Font.GothamBlack)
	for _, s in ipairs({ -1, 1 }) do
		Wind.banner(m, Vector3.new(gx + 0.9, I.y + 13, I.z + s * 11 - 2), Vector3.new(gx + 0.9, I.y + 13, I.z + s * 11 + 2), 7, Vector3.new(1, 0, 0), rng, pick(NOREN, rng))
	end
	box(gx, I.y + 16, I.z, 3, 4, 34)
	for _, s in ipairs({ -1, 1 }) do
		box(gx, I.y + 8, I.z + s * 15.5, 3, 18, 3)
	end
	marker(m, Vector3.new(I.x - 3, I.y, I.z + 1))
end

-- The wind's shrine: a torii facing east over the fog, the shrine at the
-- back, pinwheels everywhere, stone lanterns, ema boards, a weathervane
-- and carp streamers.
function PLAZAS.shrine(m, I, rng)
	table.insert(I.blocks, { I.x - 18, I.x + 8, I.z - 13.5, I.z + 13.5 })
	local red = rgb(200, 60, 40)
	local tc = Vector3.new(I.x + 6, I.y, I.z)
	for _, s in ipairs({ -1, 1 }) do
		cylinder(m, "ToriiPillar", 15, 1.3, CFrame.new(tc + Vector3.new(0, 7.5, s * 6)) * UPRIGHT, Smooth, red)
	end
	part(m, "Kasagi", Vector3.new(1.6, 1, 16), tc + UP * 15.4, Smooth, DARK)
	part(m, "Kasagi2", Vector3.new(1.4, 0.8, 14.4), tc + UP * 14.5, Smooth, red)
	part(m, "Nuki", Vector3.new(0.9, 0.8, 13), tc + UP * 12.2, Smooth, red)
	label(m, CFrame.new(tc + UP * 13.4 + Vector3.new(0.5, 0, 0)) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(4.4, 1.6, 0.1), Enum.NormalId.Back, "風見神社", rgb(240, 226, 196), rgb(120, 30, 30), Wood, Enum.Font.GothamBold)
	-- the shrine
	local hc = CFrame.lookAt(Vector3.new(I.x - 8, I.y, I.z), Vector3.new(I.x, I.y, I.z))
	part(m, "ShrineBase", Vector3.new(9, 1.2, 8), hc * CFrame.new(0, 0.6, 0), Concrete, rgb(150, 146, 138))
	part(m, "Hokora", Vector3.new(6, 6.4, 5), hc * CFrame.new(0, 4.4, 0.5), Wood, rgb(120, 84, 56))
	part(m, "HokoraRoof", Vector3.new(8, 0.5, 7.4), hc * CFrame.new(0, 7.9, 0.3) * CFrame.Angles(-0.12, 0, 0), Rust, rgb(70, 90, 80))
	part(m, "HokoraDoor", Vector3.new(3, 4, 0.2), hc * CFrame.new(0, 3.8, -2), Wood, rgb(60, 40, 30))
	deco(ellipsoid(m, "Bell", Vector3.new(1, 1.2, 1), hc * CFrame.new(0, 6.8, -2.6), Metal, rgb(200, 170, 70)))
	deco(rod(m, "BellRope", (hc * CFrame.new(0, 6.2, -2.6)).Position, (hc * CFrame.new(0, 2, -2.8)).Position, 0.25, Fabric, rgb(220, 60, 50)))
	part(m, "Offertory", Vector3.new(3.4, 2, 1.6), hc * CFrame.new(0, 2.2, -3.6), Wood, rgb(90, 64, 44))
	marker(m, (hc * CFrame.new(3, 1.2, 1)).Position)
	-- stone lanterns up the path
	for _, s in ipairs({ -1, 1 }) do
		for k = 0, 1 do
			local p = Vector3.new(I.x - 2 + k * 8, I.y, I.z + s * 4.5)
			part(m, "ToroBase", Vector3.new(1.4, 3, 1.4), p + UP * 1.5, Concrete, rgb(140, 138, 130))
			part(m, "ToroLamp", Vector3.new(1.8, 1.4, 1.8), p + UP * 3.7, Concrete, rgb(150, 148, 140))
			part(m, "ToroCap", Vector3.new(2.4, 0.6, 2.4), p + UP * 4.7, Concrete, rgb(130, 128, 120))
			if k == 0 then
				local glow = deco(part(m, "ToroGlow", Vector3.new(1, 0.8, 1.9), p + UP * 3.7, Neon, rgb(255, 180, 110)))
				light(glow, 14)
			end
		end
	end
	-- pinwheels: dozens, along the path and round the shrine
	for _ = 1, 26 do
		pinwheel(m, Vector3.new(I.x + rng:NextNumber(-14, 4), I.y, I.z + pick({ -1, 1 }, rng) * rng:NextNumber(6.5, 11)), rng)
	end
	-- ema: prayer boards on a rack
	local ema = Vector3.new(I.x - 4, I.y, I.z + 12)
	for _, s in ipairs({ -3, 3 }) do
		rod(m, "EmaPost", ema + Vector3.new(s, 0, 0), ema + Vector3.new(s, 5, 0), 0.3, Wood, TIMBER)
	end
	rod(m, "EmaBar", ema + Vector3.new(-3, 4.6, 0), ema + Vector3.new(3, 4.6, 0), 0.2, Wood, TIMBER)
	for k = 0, 9 do
		local p = ema + Vector3.new(-2.6 + (k % 5) * 1.3, 4 - math.floor(k / 5) * 1.3, 0.2)
		deco(part(m, "Ema", Vector3.new(1.1, 0.8, 0.1), CFrame.new(p) * CFrame.Angles(0, 0, rng:NextNumber(-0.1, 0.1)), Wood, rgb(200, 170, 120)))
	end
	-- the weathervane (pointing into the wind) and the carp
	local vp = Vector3.new(I.x - 16, I.y, I.z - 12)
	rod(m, "VaneMast", vp, vp + UP * 22, 0.5, Metal, DARK)
	local vy = vp + UP * 22
	part(m, "VaneArrow", Vector3.new(0.2, 0.2, 5), CFrame.lookAt(vy, vy - Wind.DIR), Metal, DARK)
	part(m, "VaneTail", Vector3.new(0.1, 1.6, 1.6), CFrame.lookAt(vy + Wind.DIR * 2.4, vy + Wind.DIR * 3), Metal, DARK)
	for k, color in ipairs({ rgb(30, 30, 34), rgb(190, 50, 44), rgb(60, 90, 160) }) do
		carp(m, vp + UP * (20 - k * 4.5), 8.5 - k, color, rng)
	end
	box(tc.X, I.y + 8, tc.Z, 4, 18, 16)
end

-- The bath-house (sento): the big building on its own island, the
-- chimney smoking, the baths steaming; a turbine flying from its roof.
function PLAZAS.bath(m, I, rng)
	table.insert(I.blocks, { I.x - 13, I.x + 10, I.z - 12, I.z + 12 })
	local cf = CFrame.lookAt(Vector3.new(I.x - 3, I.y, I.z), Vector3.new(I.x + 10, I.y, I.z))
	local b = model(m, "BathHouse")
	local W, D, Hh = 22, 18, 15
	local wall = rgb(120, 90, 64)
	part(b, "BathFloor", Vector3.new(W, 0.3, D), cf * CFrame.new(0, 0.15, 0), Wood, rgb(150, 126, 92))
	part(b, "BathWall", Vector3.new(W, Hh, 0.6), cf * CFrame.new(0, Hh / 2, D / 2), Planks, wall)
	for _, s in ipairs({ -1, 1 }) do
		part(b, "BathWall", Vector3.new(0.6, Hh, D), cf * CFrame.new(s * W / 2, Hh / 2, 0), Planks, wall)
		part(b, "BathWall", Vector3.new(W / 2 - 3, Hh, 0.6), cf * CFrame.new(s * (W / 4 + 1.5), Hh / 2, -D / 2), Planks, wall)
	end
	part(b, "BathWall", Vector3.new(6, Hh - 9.5, 0.6), cf * CFrame.new(0, 9.5 + (Hh - 9.5) / 2, -D / 2), Planks, wall)
	for _, s in ipairs({ -1, 1 }) do
		part(b, "BathRoof", Vector3.new(W + 2, 0.5, D / 2 + 1.6), cf * CFrame.new(0, Hh + 1.6, s * (D / 4 + 0.2)) * CFrame.Angles(s * 0.32, 0, 0), Rust, rgb(60, 72, 84))
	end
	part(b, "Ridge", Vector3.new(W + 2.4, 0.8, 0.8), cf * CFrame.new(0, Hh + 3.1, 0), Metal, DARK)
	label(b, cf * CFrame.new(0, 11.5, -D / 2 - 0.35), Vector3.new(4, 4, 0.1), Enum.NormalId.Front, "ゆ", rgb(40, 54, 100), rgb(240, 236, 226), Fabric, Enum.Font.GothamBlack)
	for _, k in ipairs({ -1, 1 }) do
		Wind.cloth(b, (cf * CFrame.new(k * 1.5 - 1.45, 9.3, -D / 2 - 0.4)).Position, (cf * CFrame.new(k * 1.5 + 1.45, 9.3, -D / 2 - 0.4)).Position, 3.6, cf.LookVector, rng, { name = "Noren", color = if k < 0 then rgb(40, 54, 100) else rgb(160, 44, 38), strip = 0.9, stiff = 0.2 })
	end
	-- inside: two baths, the partition, stools and buckets
	part(b, "Partition", Vector3.new(0.4, 7, D - 4), cf * CFrame.new(0, 3.5, 1), Wood, rgb(150, 120, 90))
	for _, s in ipairs({ -1, 1 }) do
		local tb = cf * CFrame.new(s * 5.5, 0, 4)
		part(b, "Tub", Vector3.new(7, 2.4, 6), tb * CFrame.new(0, 1.2, 0), Enum.Material.Slate, rgb(90, 110, 120))
		local water = part(b, "BathWater", Vector3.new(6.2, 0.2, 5.2), tb * CFrame.new(0, 2.2, 0), Glass, rgb(120, 170, 190))
		water.Transparency = 0.3
		water.CanCollide = false
		local src = hidden(part(b, "BathSteam", Vector3.new(5, 0.2, 4), tb * CFrame.new(0, 2.4, 0), Smooth, DARK))
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Rate = 4
		e.Lifetime = NumberRange.new(2, 3)
		e.Speed = NumberRange.new(0.5, 1)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
		e.Parent = src
		for k = 0, 2 do
			part(b, "Stool", Vector3.new(1.2, 1, 1.2), tb * CFrame.new(-2 + k * 2, 0.5, -5), Wood, rgb(170, 140, 100))
			deco(cylinder(b, "Bucket", 0.9, 1, CFrame.new((tb * CFrame.new(-2 + k * 2, 1.45, -5)).Position) * UPRIGHT, Wood, rgb(190, 160, 110)))
		end
	end
	local bulb = deco(part(b, "Bulb", Vector3.new(0.8, 1, 0.8), cf * CFrame.new(0, Hh - 2, 0), Neon, rgb(255, 200, 140)))
	light(bulb, 26)
	marker(b, (cf * CFrame.new(-8, 0.3, -6)).Position)
	-- the chimney, smoking
	local ch = (cf * CFrame.new(W / 2 - 3, 0, D / 2 - 3)).Position
	cylinder(b, "BathChimney", 36, 2.4, CFrame.new(ch + UP * 18) * UPRIGHT, Concrete, rgb(120, 116, 108))
	for y = 8, 32, 8 do
		deco(cylinder(b, "ChimneyBand", 0.6, 2.7, CFrame.new(ch + UP * y) * UPRIGHT, Metal, DARK))
	end
	smoke(b, ch + UP * 36.4, 6, 2)
end

-- The workshop: an open shed, a bench, a generator's flywheel turning,
-- scrap, gas bottles, a hoist hanging from a beam.
function PLAZAS.workshop(m, I, rng)
	table.insert(I.blocks, { I.x - 10, I.x + 4, I.z - 10, I.z + 10 })
	local cf = CFrame.lookAt(Vector3.new(I.x - 3, I.y, I.z), Vector3.new(I.x + 10, I.y, I.z))
	local W, D, Hh = 18, 12, 12
	for _, o in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
		rod(m, "ShedPost", (cf * CFrame.new(o[1] * W / 2, 0, o[2] * D / 2)).Position, (cf * CFrame.new(o[1] * W / 2, Hh, o[2] * D / 2)).Position, 0.8, Metal, STEEL)
	end
	part(m, "ShedBack", Vector3.new(W, Hh, 0.4), cf * CFrame.new(0, Hh / 2, D / 2), Rust, pick(TIN, rng))
	part(m, "ShedRoof", Vector3.new(W + 2, 0.4, D + 2), cf * CFrame.new(0, Hh + 0.8, 0) * CFrame.Angles(0.1, 0, 0), Rust, pick(TIN, rng))
	part(m, "Bench", Vector3.new(8, 3.2, 2.4), cf * CFrame.new(-3, 1.6, D / 2 - 2), Wood, rgb(110, 84, 58))
	part(m, "Vice", Vector3.new(0.8, 0.8, 1), cf * CFrame.new(-6, 3.6, D / 2 - 2), Metal, rgb(60, 90, 140))
	part(m, "Generator", Vector3.new(4, 3.4, 3), cf * CFrame.new(5, 1.7, D / 2 - 2.5), Metal, rgb(70, 110, 80))
	local fw = model(m, "Flywheel")
	local fc = cf * CFrame.new(7.3, 2.2, D / 2 - 2.5)
	cylinder(fw, "Wheel", 0.6, 3, fc, Metal, DARK)
	part(fw, "Spoke", Vector3.new(0.7, 2.8, 0.3), fc * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(200, 60, 40))
	Wind.spin(fw, fc.Position, fc.RightVector, 6, rng)
	for _ = 1, 6 do
		part(m, "Scrap", Vector3.new(rng:NextNumber(1, 3), rng:NextNumber(0.3, 1.2), rng:NextNumber(1, 3)), cf * CFrame.new(rng:NextNumber(-8, 8), 0.5, rng:NextNumber(-4, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), 0), Rust, jitter(rgb(110, 80, 60), rng, 0.2))
	end
	for k = 0, 2 do
		cylinder(m, "GasBottle", 3.4, 1.2, CFrame.new((cf * CFrame.new(-W / 2 + 1.2 + k * 1.3, 1.7, D / 2 - 1)).Position) * UPRIGHT, Metal, pick({ rgb(60, 90, 140), rgb(200, 60, 40), rgb(60, 120, 70) }, rng))
	end
	part(m, "HoistBeam", Vector3.new(W, 0.8, 0.8), cf * CFrame.new(0, Hh - 1, -D / 2 + 1), Metal, YELLOW)
	local h = model(m, "Hoist")
	local top = (cf * CFrame.new(2, Hh - 1.4, -D / 2 + 1)).Position
	rod(h, "HoistChain", top, top - UP * 6, 0.2, Metal, DARK)
	part(h, "HoistHook", Vector3.new(0.6, 1.2, 0.6), top - UP * 6.6, Metal, YELLOW)
	Wind.sway(h, top, 0.05, rng)
	lantern(m, (cf * CFrame.new(0, Hh - 2, 0)).Position, rng, true)
	marker(m, (cf * CFrame.new(-6, 0, 2)).Position)
end

-- The garden on the sky beam: planters either side of the way along the
-- beam, beans up a trellis, a scarecrow, a turbine flying from a corner.
function PLAZAS.skygarden(m, I, rng)
	for _, sz in ipairs({ -1, 1 }) do
		for _, dx in ipairs({ -6, 5 }) do
			bed(m, CFrame.new(I.x + dx, I.y, I.z + sz * 5.4), 8, 2.6, rng)
		end
	end
	for x = -10, -6, 2 do
		deco(rod(m, "Trellis", Vector3.new(I.x + x, I.y, I.z + I.hz - 0.8), Vector3.new(I.x + x, I.y + 6, I.z + I.hz - 0.8), 0.15, Wood, TIMBER))
		deco(ellipsoid(m, "Beans", Vector3.new(1.4, 4.4, 1), CFrame.new(I.x + x, I.y + 3, I.z + I.hz - 0.8), Grass, jitter(rgb(80, 130, 60), rng, 0.1)))
	end
	local sc = Vector3.new(I.x + 10, I.y, I.z + 5.5)
	rod(m, "Scarecrow", sc, sc + UP * 6, 0.25, Wood, TIMBER)
	rod(m, "ScarecrowArms", sc + UP * 4.4 + Vector3.new(0, 0, -2), sc + UP * 4.4 + Vector3.new(0, 0, 2), 0.2, Wood, TIMBER)
	deco(ellipsoid(m, "ScarecrowHead", Vector3.new(1.2, 1.4, 1.2), CFrame.new(sc + UP * 6.2), Fabric, rgb(220, 200, 160)))
	Wind.cloth(m, sc + UP * 4.6 + Vector3.new(0.2, 0, -1.8), sc + UP * 4.6 + Vector3.new(0.2, 0, 1.8), 3, Vector3.new(1, 0, 0), rng, { name = "ScarecrowCoat", color = pick(CLOTHS, rng), tattered = true, strip = 0.8 })
	part(m, "ToolBox", Vector3.new(3, 2, 2), Vector3.new(I.x - 10, I.y + 1, I.z - 6.6), Wood, rgb(120, 100, 76))
	kite(m, Vector3.new(I.x + 9.5, I.y, I.z - 5.5), rng:NextNumber(45, 60), rng)
	marker(m, Vector3.new(I.x - 10, I.y, I.z + 5.5))
end

-- ===== The undercroft =====

local function undercroft(m, key, rng)
	local L = LOWS[key]
	local I = ISLANDS[key]
	local lm = model(m, "Undercroft")
	for _, d in ipairs(deck(lm, { x0 = L.x0, x1 = L.x1, z0 = L.z0, z1 = L.z1 }, L.y, {}, rng, Planks, WET)) do
		d.Reflectance = 0.06
	end
	local cx, cz = (L.x0 + L.x1) / 2, (L.z0 + L.z1) / 2
	-- hung from the deck above on four long chains (where they both are),
	-- and big beams under it
	local x0, x1 = math.max(L.x0, I.x - I.hx) + 1, math.min(L.x1, I.x + I.hx) - 1
	local z0, z1 = math.max(L.z0, I.z - I.hz) + 1, math.min(L.z1, I.z + I.hz) - 1
	for _, o in ipairs({ { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } }) do
		deco(rod(lm, "HangChain", Vector3.new(o[1], L.y - 1, o[2]), Vector3.new(o[1], I.y - 1, o[2]), 0.7, Metal, DARK))
		deco(part(lm, "Shackle", Vector3.new(1.2, 1.2, 1.2), Vector3.new(o[1], L.y - 1, o[2]), Metal, DARK))
	end
	for _, z in ipairs({ z0, z1 }) do
		deco(rod(lm, "UnderBeam", Vector3.new(L.x0, L.y - 1.6, z), Vector3.new(L.x1, L.y - 1.6, z), 1.2, Metal, darken(STEEL, 0.7)))
	end
	for _ = 1, 4 do
		deco(ellipsoid(lm, "Algae", Vector3.new(rng:NextNumber(2, 5), 0.3, rng:NextNumber(2, 5)), CFrame.new(rng:NextNumber(L.x0 + 3, L.x1 - 3), L.y + 0.05, rng:NextNumber(L.z0 + 3, L.z1 - 3)), Grass, jitter(rgb(50, 80, 50), rng, 0.15)))
	end
	-- cisterns
	for _, t in ipairs(L.tanks) do
		local p = Vector3.new(cx + t[1], L.y, cz + t[2])
		cylinder(lm, "Cistern", 14, 12, CFrame.new(p + UP * 7) * UPRIGHT, Metal, jitter(rgb(70, 90, 96), rng, 0.08))
		cylinder(lm, "CisternRim", 0.6, 12.6, CFrame.new(p + UP * 14.2) * UPRIGHT, Rust, rgb(96, 70, 52))
		for y = 3, 12, 4.5 do
			deco(cylinder(lm, "CisternHoop", 0.4, 12.3, CFrame.new(p + UP * y) * UPRIGHT, Rust, rgb(96, 70, 52)))
		end
		deco(part(lm, "RustStain", Vector3.new(0.1, 6, 2), p + UP * 5 + Vector3.new(6.05, 0, 0), Rust, rgb(96, 70, 52)))
		ladder(lm, p + Vector3.new(0, 0, -6.4), p + Vector3.new(0, 14.6, -6.4))
		rod(lm, "CisternPipe", p + UP * 13 + Vector3.new(2, 0, 2), Vector3.new(p.X + 2, I.y - 1.2, p.Z + 2), 1, Metal, rgb(80, 100, 110))
	end
	-- the pump house
	local sp = CFrame.lookAt(Vector3.new(cx + L.shed[1], L.y, cz + L.shed[2]), Vector3.new(cx, L.y, cz))
	part(lm, "PumpHouse", Vector3.new(10, 9, 0.5), sp * CFrame.new(0, 4.5, 4), Rust, pick(TIN, rng))
	for _, s in ipairs({ -1, 1 }) do
		part(lm, "PumpHouse", Vector3.new(0.5, 9, 8), sp * CFrame.new(s * 5, 4.5, 0), Rust, pick(TIN, rng))
	end
	part(lm, "PumpRoof", Vector3.new(11, 0.4, 9), sp * CFrame.new(0, 9.2, 0), Rust, rgb(70, 80, 80))
	part(lm, "Pump", Vector3.new(3.4, 3, 2.6), sp * CFrame.new(-1.5, 1.5, 1.6), Metal, rgb(70, 96, 90))
	local fw = model(lm, "PumpWheel")
	local fc = sp * CFrame.new(1.4, 2.4, 1.6)
	cylinder(fw, "Wheel", 0.5, 3.6, fc, Metal, DARK)
	part(fw, "Spoke", Vector3.new(0.6, 3.2, 0.3), fc * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(170, 140, 60))
	Wind.spin(fw, fc.Position, fc.RightVector, 3, rng)
	local rp = (sp * CFrame.new(-1.5, 3, 1.6)).Position
	rod(lm, "PumpRiser", rp, Vector3.new(rp.X, I.y - 1, rp.Z), 1.2, Metal, rgb(80, 100, 110))
	marker(lm, (sp * CFrame.new(3, 0, 2)).Position)
	-- fog nets out along one side, billowing, dripping into gutters
	local side = L.nets
	local run, a0, a1, off
	if side == "W" or side == "E" then
		local x = if side == "W" then L.x0 + 0.8 else L.x1 - 0.8
		run, a0, a1, off = Vector3.new(0, 0, 1), Vector3.new(x, L.y, L.z0 + 3), Vector3.new(x, L.y, L.z1 - 3), Vector3.new(if side == "W" then -1 else 1, 0, 0)
	else
		local z = if side == "S" then L.z0 + 0.8 else L.z1 - 0.8
		run, a0, a1, off = Vector3.new(1, 0, 0), Vector3.new(L.x0 + 3, L.y, z), Vector3.new(L.x1 - 3, L.y, z), Vector3.new(0, 0, if side == "S" then -1 else 1)
	end
	local len = (a1 - a0).Magnitude
	local nNets = math.max(1, math.floor(len / 20))
	local nw = len / nNets
	for k = 0, nNets do
		rod(lm, "NetPole", a0 + run * (k * nw), a0 + run * (k * nw) + UP * 17, 0.6, Wood, darken(WET, 0.9))
	end
	for k = 0, nNets - 1 do
		local p0, p1 = a0 + run * (k * nw + 0.5), a0 + run * ((k + 1) * nw - 0.5)
		fogNet(lm, p0 + UP * 16, p1 + UP * 16, 13.6, off, rng)
		local g = (p0 + p1) / 2 + UP * 1.4
		part(lm, "Gutter", Vector3.new(0.8, 0.6, nw - 1), CFrame.lookAt(g, g + run), Metal, rgb(90, 96, 96))
		local drip = hidden(part(lm, "Drip", Vector3.new(0.2, 0.2, nw - 2), CFrame.lookAt(g + UP * 12, g + UP * 12 + run), Smooth, DARK))
		local e = Instance.new("ParticleEmitter")
		e.Rate = 10
		e.Lifetime = NumberRange.new(1.2, 1.6)
		e.Speed = NumberRange.new(0, 0.2)
		e.Acceleration = Vector3.new(0, -14, 0)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.Size = NumberSequence.new(0.12)
		e.Color = ColorSequence.new(rgb(190, 210, 220))
		e.Parent = drip
	end
	-- puddles, lamps, the mist hanging in it all
	for _ = 1, 5 do
		local p = Vector3.new(rng:NextNumber(L.x0 + 3, L.x1 - 3), L.y + 0.02, rng:NextNumber(L.z0 + 3, L.z1 - 3))
		local pd = deco(part(lm, "Puddle", Vector3.new(rng:NextNumber(2, 5), 0.04, rng:NextNumber(1.5, 4)), p, Glass, rgb(40, 48, 52)))
		pd.Reflectance = 0.3
		pd.Transparency = 0.2
	end
	dampLamp(lm, Vector3.new(L.x0 + 4, L.y, L.z1 - 4))
	dampLamp(lm, Vector3.new(L.x1 - 4, L.y, L.z0 + 4))
	local mist = hidden(part(lm, "Mist", Vector3.new(L.x1 - L.x0, 6, L.z1 - L.z0), Vector3.new(cx, L.y + 4, cz), Smooth, DARK))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 2
	e.Lifetime = NumberRange.new(10, 14)
	e.Speed = NumberRange.new(0.3, 0.8)
	e.Acceleration = Wind.DIR * 0.3
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 18) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.86), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(170, 186, 182))
	e.Parent = mist
	-- and the rest of the fog's harvest, wherever there's room
	local R = { x = cx, z = cz, hx = (L.x1 - L.x0) / 2, hz = (L.z1 - L.z0) / 2, y = L.y, blocks = {} }
	for _, t in ipairs(L.tanks) do
		blockRect(R, cx + t[1] - 6.8, cx + t[1] + 6.8, cz + t[2] - 6.8, cz + t[2] + 6.8)
	end
	blockRect(R, localRect(sp, -6, 6, -5, 5))
	if L.nets == "W" then
		blockRect(R, L.x0, L.x0 + 3.5, L.z0, L.z1)
	elseif L.nets == "E" then
		blockRect(R, L.x1 - 3.5, L.x1, L.z0, L.z1)
	elseif L.nets == "S" then
		blockRect(R, L.x0, L.x1, L.z0, L.z0 + 3.5)
	else
		blockRect(R, L.x0, L.x1, L.z1 - 3.5, L.z1)
	end
	local S = STAIRS[key]
	local ax, bx, az, bz = math.huge, -math.huge, math.huge, -math.huge
	for _, o in ipairs({ 0, 11.4 }) do
		for _, r in ipairs({ -3, 19.2 }) do
			local q = S.at + S.out * o + S.run * r
			ax, bx, az, bz = math.min(ax, q.X), math.max(bx, q.X), math.min(az, q.Z), math.max(bz, q.Z)
		end
	end
	blockRect(R, ax - 1, bx + 1, az - 1, bz + 1)
	for _, o in ipairs({ { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } }) do
		blockRect(R, o[1] - 1.6, o[1] + 1.6, o[2] - 1.6, o[2] + 1.6)
	end
	for _, o in ipairs({ { L.x0 + 4, L.z1 - 4 }, { L.x1 - 4, L.z0 + 4 } }) do
		blockRect(R, o[1] - 1.5, o[1] + 1.5, o[2] - 1.5, o[2] + 1.5)
	end
	for _, pair in ipairs(LOW_BRIDGES) do
		if pair[1] == key then
			for _, P in ipairs(PYLONS) do
				if P.key == pair[2] then
					local pe = edgePoint(R, P.x, P.z)
					blockRect(R, pe.X - 5, pe.X + 5, pe.Z - 5, pe.Z + 5)
				end
			end
		end
	end
	if key == "A" then
		blockRect(R, I.x - 1, I.x + 3, I.z + 1, I.z + 5)
	end
	scatter(lm, R, TownProps.LOW, shuffle({ "netMending", "boat", "dryingNets", "filters", "waterShrine", "floats", "ropes", "eelTraps", "buckets", "ropes" }, rng), rng, { floats = true, dryingNets = true, filters = true })
	box(cx, (L.y - 20 + I.y - 5) / 2, cz, L.x1 - L.x0, I.y - 5 - (L.y - 20), L.z1 - L.z0)
end

-- An old pole standing up out of the fog: a crossbar, insulators, maybe a
-- bird's nest, a loose wire dangling.
local function oldPole(m, p, top, rng)
	local base = Vector3.new(p.X + rng:NextNumber(-4, 4), DEEP, p.Z + rng:NextNumber(-4, 4))
	local tip = Vector3.new(p.X, top, p.Z)
	local steel = rng:NextNumber() < 0.5
	rod(m, "OldPole", base, tip, if steel then 1.2 else 1.6, if steel then Rust else Wood, if steel then rgb(96, 70, 52) else darken(TIMBER, 0.7))
	local lean = (tip - base).Unit
	local across = lean:Cross(UP).Unit
	local bar = tip - lean * 2
	rod(m, "CrossBar", bar - across * 3, bar + across * 3, 0.5, Wood, darken(TIMBER, 0.8))
	for _, s in ipairs({ -2.4, 0, 2.4 }) do
		deco(cylinder(m, "Insulator", 0.8, 0.5, CFrame.new(bar + across * s + UP * 0.6) * UPRIGHT, Glass, rgb(120, 150, 150)))
	end
	if rng:NextNumber() < 0.5 then
		deco(ellipsoid(m, "Nest", Vector3.new(2, 0.9, 2), CFrame.new(tip + UP * 0.4), Grass, rgb(110, 90, 60)))
	end
	local wm = model(m, "LooseWire")
	local w0 = bar + across * 2.4
	rod(wm, "Wire", w0, w0 - UP * rng:NextNumber(8, 16), 0.12, Metal, DARK)
	Wind.sway(wm, w0, 0.12, rng)
end

-- ===== Assembly =====

function StiltTown.build(parent, rng)
	lightsLeft = 175
	StiltTown.BLOCKS = {}
	local root = model(parent, "Kazami")
	for _, I in pairs(ISLANDS) do
		I.gaps, I.occ, I.blocks, I.houses, I.rails = {}, {}, {}, {}, {}
		I.palette = palette(rng)
	end
	ISLANDS.A.yatai, ISLANDS.C.yatai = true, true
	local pyl = {}
	for _, P in ipairs(PYLONS) do
		pyl[P.key] = P
		-- (its landing, as somewhere to bridge to; its garden, for the beams)
		local h = hw(P, P.landing) - 1
		P.hx, P.hz, P.y = h, h, P.landing
		P.gaps, P.occ = {}, {}
		local gh = hw(P, P.garden) + 10
		P.g = { x = P.x, z = P.z, hx = gh, hz = gh, y = P.garden, gaps = {}, occ = {} }
		-- how far its lower arm reaches as a crane, each way
		P.reach = {}
		if P.east then
			P.reach[1] = ISLANDS[P.east].x + ISLANDS[P.east].hx - 3
		end
		if P.west then
			P.reach[-1] = ISLANDS[P.west].x - ISLANDS[P.west].hx + 3
		end
	end
	local function spot(key)
		return ISLANDS[key] or pyl[key]
	end

	-- the pylons and their layers
	for _, P in ipairs(PYLONS) do
		local m = model(root, "Pylon")
		pylon(m, P, rng)
		task.wait()
		pylonLayers(m, P, rng)
		if P.light then
			lighthouse(m, P, rng)
		end
		task.wait()
	end
	conductors(root)
	cableCar(root, PYLONS[1].stations[1], PYLONS[2].stations[1], rng)
	cableCar(root, PYLONS[2].stations[-1], PYLONS[3].stations[-1], rng)
	-- the platforms on the pylons' legs, from the fog up
	for _, P in ipairs(PYLONS) do
		perches(root, P, rng)
	end

	-- what everything hangs from: the cranes' hooks, the balance, the sky
	-- beams between the gardens
	local hooks = {}
	for _, P in ipairs(PYLONS) do
		for _, key in ipairs({ P.east or false, P.west or false }) do
			if key then
				local I = ISLANDS[key]
				local y = P.top - 80 - 3
				hooks[key] = { Vector3.new(I.x - I.hx + 3, y, P.z), Vector3.new(I.x + I.hx - 3, y, P.z) }
			end
		end
		if P.balance then
			hooks[P.balance] = balance(root, P, ISLANDS[P.balance], rng)
		end
	end
	local sm = model(root, "SkyBeams")
	for _, sb in ipairs(SKY_BEAMS) do
		local a, b = pyl[sb[1]], pyl[sb[2]]
		local pa, sa, ta = edgePoint(a.g, b.x, b.z)
		local pb, sb2, tb = edgePoint(b.g, a.x, a.z)
		gap(a.g, sa, ta - 3.5, ta + 3.5)
		gap(b.g, sb2, tb - 3.5, tb + 3.5)
		local I = ISLANDS[sb[3]]
		local mid = (pa + pb) / 2
		I.x, I.z = mid.X, mid.Z
		if I.onTop then
			I.y = mid.Y
			-- (the beam runs in and out through its sides)
			local along = if math.abs(pb.X - pa.X) > math.abs(pb.Z - pa.Z) then { "W", "E" } else { "S", "N" }
			for _, sd in ipairs(along) do
				gap(I, sd, -6.5, 6.5)
			end
		end
		local beam = skyBeam(sm, pa, pb, rng, if I.onTop then I else nil)
		if not I.onTop then
			hooks[sb[3]] = { beam.hook(0.5) }
		end
	end
	for _, P in ipairs(PYLONS) do
		edgeRails(root, P.g)
		dressPylon(root, P, rng)
		task.wait()
	end

	-- where the bridges and the stairs meet the islands' edges, and where
	-- the crossing comes in: all kept clear
	local spans = {}
	for _, pair in ipairs(BRIDGES) do
		local a, b = spot(pair[1]), spot(pair[2])
		local pa, sa, ta = edgePoint(a, b.x, b.z)
		local pb, sb, tb = edgePoint(b, a.x, a.z)
		gap(a, sa, ta - 4, ta + 4)
		gap(b, sb, tb - 4, tb + 4)
		table.insert(spans, { pa, pb })
	end
	for key, S in pairs(STAIRS) do
		local I = ISLANDS[key]
		local _, along = sideFrame(I, S.side)
		local t = (S.at - Vector3.new(I.x, 0, I.z)):Dot(along)
		gap(I, S.side, t - 4, t + 4)
	end
	for _, key in ipairs({ "A", "B", "C" }) do
		gap(ISLANDS[key], "E", -16, 16)
	end
	gap(ISLANDS.A, "S", -9, 9) -- (the way up from the south)

	-- the islands: deck, houses round the edge, what's in the middle, and
	-- what they hang by
	for _, key in ipairs(ORDER) do
		local I = ISLANDS[key]
		local m = model(root, "Island" .. key)
		local holes = {}
		if I.hatch then
			table.insert(holes, { x0 = I.x + I.hatch[1] - 1.2, x1 = I.x + I.hatch[1] + 1.2, z0 = I.z + I.hatch[2] - 1.2, z1 = I.z + I.hatch[2] + 1.2 })
		end
		deck(m, { x0 = I.x - I.hx, x1 = I.x + I.hx, z0 = I.z - I.hz, z1 = I.z + I.hz }, I.y, holes, rng)
		if I.arrive then
			for _, side in ipairs({ "N", "S", "W", "E" }) do
				houseRow(m, I, side, rng, { shops = key == "B", tall = 0.55 })
			end
			for _ = 1, 3 do
				pinwheel(m, Vector3.new(I.x + rng:NextNumber(-12, 12), I.y, I.z + rng:NextNumber(-12, 12)), rng)
			end
		elseif I.homes then
			-- one house, or two (at opposite ends of the west and north)
			for k, side in ipairs({ "W", "N" }) do
				if k <= I.homes then
					local mid, along, inward, half = sideFrame(I, side)
					local w = math.min(I.hx * 2 - 4, rng:NextNumber(13, 17))
					local d = math.min(I.hz * 2 - 5, rng:NextNumber(11, 13))
					local off = 0
					if I.homes == 2 then
						off = (if side == "W" then -1 else 1) * (half - w / 2 - 1)
					end
					local skip = blocked(I, side, off - w / 2, off + w / 2)
					if skip then
						off = math.min(skip + w / 2, half - w / 2 - 0.5)
					end
					local at = mid + along * off + inward * (d / 2)
					local _, info = house(m, CFrame.lookAt(at, at + inward), w, d, if rng:NextNumber() < 0.6 then 2 else 1, rng, { palette = I.palette })
					table.insert(I.houses, info)
					I.occ[side] = I.occ[side] or {}
					table.insert(I.occ[side], { off - w / 2, off + w / 2 })
				end
			end
			bed(m, CFrame.new(I.x + I.hx - 4, I.y, I.z - I.hz + 3), 5, 2.4, rng)
			table.insert(I.blocks, { I.x + I.hx - 7, I.x + I.hx, I.z - I.hz, I.z - I.hz + 7 })
			pinwheel(m, Vector3.new(I.x + I.hx - 1.5, I.y, I.z - I.hz + 5.5), rng)
			if rng:NextNumber() < 0.5 then
				Shacks.cat(m, CFrame.new(I.x + rng:NextNumber(-3, 3), I.y, I.z + rng:NextNumber(-3, 3)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng)
			end
		end
		if I.plaza then
			PLAZAS[I.plaza](m, I, rng)
		end
		if I.support then
			support(m, I, rng)
		elseif hooks[key] then
			hang(m, I, hooks[key], I.lift)
		end
		edgeRails(m, I)
		if not I.onTop then
			dress(m, I, rng)
		end
		task.wait()
	end

	-- the bridges between them
	local bm = model(root, "Bridges")
	for _, s in ipairs(spans) do
		bridge(bm, s[1], s[2], rng)
	end

	-- the undercroft: platforms hung under the big decks, the stairs down
	-- to them, boardwalks to the pylons' bases
	local um = model(root, "Undercroft")
	for key, S in pairs(STAIRS) do
		undercroft(um, key, rng)
		stairTower(um, Vector3.new(S.at.X, ISLANDS[key].y, S.at.Z), S.out, S.run, LOWS[key].y, rng)
		task.wait()
	end
	local function low(key)
		local L = LOWS[key]
		if L then
			return { x = (L.x0 + L.x1) / 2, z = (L.z0 + L.z1) / 2, hx = (L.x1 - L.x0) / 2, hz = (L.z1 - L.z0) / 2, y = L.y }
		end
		local P = pyl[key]
		local h = hw(P, P.base) - 1
		return { x = P.x, z = P.z, hx = h, hz = h, y = P.base }
	end
	for _, pair in ipairs(LOW_BRIDGES) do
		local a, b = low(pair[1]), low(pair[2])
		bridge(um, (edgePoint(a, b.x, b.z)), (edgePoint(b, a.x, a.z)), rng, true)
	end

	-- a couple of old poles standing out of the fog on their own
	local pm = model(root, "OldPoles")
	for _, p in ipairs(POLES) do
		oldPole(pm, Vector3.new(p[1], 0, p[2]), p[3], rng)
	end

	-- the big decks are where the crossing's routes come in
	local plats = {}
	for _, key in ipairs({ "A", "B", "C" }) do
		local I = ISLANDS[key]
		table.insert(plats, { x0 = I.x - I.hx, x1 = I.x + I.hx, z0 = I.z - I.hz, z1 = I.z + I.hz, y = I.y, arrive = true })
	end
	return plats
end

return StiltTown
