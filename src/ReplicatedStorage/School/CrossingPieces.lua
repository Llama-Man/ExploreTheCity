-- The pieces the west crossing's routes are made of (WestCrossing.lua).
--
-- Every piece starts at a socket: a CFrame at floor level, looking the way
-- you're going. Its plan says where it would go (boxes it would take up,
-- so the routes can keep clear of each other and of the hubs) and where it
-- ends (the next socket); build() puts it there. Pieces hang from the
-- crossing's suspension cables (ctx.hang), so nothing stands on a pole into
-- the fog and nothing floats.
--
--   walkway   a plain catwalk: a breather
--   pipe      a big lagged pipe to walk along the top of
--   broken    a catwalk broken in three, gaps to jump, the middle sagging
--   beams     two I-beams zigzagging via a little plate
--   reels     cable reels hung on chains: stepping stones
--   cage      a cage on chains swinging across a gap: ride it over
--   gondola   a cradle running along a rail between two landings
--   lift      a cage lift up an open shaft to a higher landing
--   net       a cargo net to climb to a higher landing
--   zip       a zip line down to a lower landing
--   rope      a rope swinging over a gap
--   steam     a catwalk railed on one side only, with steam vents blasting
--             you toward the open side
--   crumble   a catwalk with rotten grating that gives way
--   drop      step off onto a catch platform well below
-- and the adaptive ones that finish a route at a hub: walkTo, zipTo; and
-- pivot, a junction plate for turning.

local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local Dress = require(script.Parent.CrossingDressing)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local Metal, Rust, Plate, Smooth, Wood, Fabric, Foil = Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.Foil
local rgb = Color3.fromRGB
local UP = Vector3.yAxis
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

-- The palette: galvanised steel, rust, deck grey, safety yellow.
local GALV = rgb(142, 146, 146)
local RUST = rgb(116, 76, 50)
local DECK = rgb(92, 92, 88)
local YELLOW = rgb(214, 170, 46)
local DARK = rgb(34, 34, 36)
local ROPE = rgb(170, 150, 110)
local PIPES = { rgb(120, 110, 96), rgb(96, 100, 96), rgb(130, 80, 50), rgb(70, 96, 110) }
local HANG, STAND = 3.1, 3.1 -- (Traversal.client: hanging under a cable; standing)

local Pieces = {}

-- ===== Geometry =====

-- A point `f` forward, `x` right, `y` up from socket S.
-- The numbers are set against Roblox's default character: walk speed 16,
-- jump height 7.2, so about half a second in the air and a flat running
-- jump of about 8.5 studs. A gap of 4 is a step; 6 wants a proper run-up;
-- 7 and more is a leap, and only going down.
local function P(S, x, y, f)
	return (S * CFrame.new(x, y, -f)).Position
end

-- A socket there, facing S's way (turned by `turn`).
local function socket(S, x, y, f, turn)
	return S * CFrame.new(x, y, -f) * CFrame.Angles(0, turn or 0, 0)
end

-- The space an oriented box takes: turned with it about the vertical (so
-- a diagonal piece doesn't claim a huge square), and its height range.
-- { c (centre, y = 0), r and l (its across and along, flat), ex and ez
-- (half extents along them), y0, y1 }.
local function box(cf, size, pad)
	pad = pad or 0
	local h = size / 2 + Vector3.one * pad
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude < 0.2 then
		look = Vector3.new(-cf.UpVector.X, 0, -cf.UpVector.Z)
	end
	look = if look.Magnitude < 0.05 then Vector3.new(0, 0, -1) else look.Unit
	local right = Vector3.new(-look.Z, 0, look.X)
	local c = cf.Position
	local ex, ez, y0, y1 = 0, 0, math.huge, -math.huge
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local p = cf * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)
				local d = p - c
				ex = math.max(ex, math.abs(d:Dot(right)))
				ez = math.max(ez, math.abs(d:Dot(look)))
				y0, y1 = math.min(y0, p.Y), math.max(y1, p.Y)
			end
		end
	end
	return { c = Vector3.new(c.X, 0, c.Z), r = right, l = look, ex = ex, ez = ez, y0 = y0, y1 = y1 }
end
Pieces.box = box

-- The walking space along a -> b (floor points), `w` wide, from a little
-- under to head height and more; the ends trimmed so pieces can meet.
local function corridor(a, b, w, below, above, trimStart, trimEnd)
	local len = (b - a).Magnitude
	if len < 3.2 then
		return box(CFrame.new((a + b) / 2), Vector3.new(w, below + above, w))
	end
	local dir = (b - a).Unit
	local a2, b2 = a + dir * (trimStart or 1.5), b - dir * (trimEnd or 1.5)
	local cf = CFrame.lookAt((a2 + b2) / 2, b2) * CFrame.new(0, (above - below) / 2, 0)
	return box(cf, Vector3.new(w, below + above, (b2 - a2).Magnitude))
end
Pieces.corridor = corridor

local function flat(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-4 then f.Unit else Vector3.new(-1, 0, 0)
end

-- ===== Building bits =====

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end
Pieces.rod = rod

local function deco(p)
	if p then
		p.CanCollide = false
		p.CastShadow = false
	end
	return p
end
Pieces.deco = deco

local function hidden(p)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

local function truss(parent, a, b, visible, color)
	local len = (b - a).Magnitude
	local t = Instance.new("TrussPart")
	t.Name = "Climb"
	t.Anchored = true
	t.Size = Vector3.new(2, math.max(2, math.ceil(len / 2) * 2), 2)
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	t.CFrame = CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(-math.pi / 2, 0, 0)
	t.Material = Metal
	t.Color = color or YELLOW
	if not visible then
		t.Transparency = 1
	end
	t.Parent = parent
	return t
end
Pieces.truss = truss

-- A run of chain from a to b, links you can see.
local function chain(parent, a, b)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local n = math.max(1, math.floor(len / 1.1))
	for i = 0, n - 1 do
		local p = a + dir * ((i + 0.5) * len / n)
		deco(part(parent, "Link", Vector3.new(0.5, 0.18, 1.2), CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, if i % 2 == 0 then 0 else math.pi / 2), Metal, DARK))
	end
end
Pieces.chain = chain

-- Handrails along a -> b (floor points) on one side `s` (-1 left, 1 right).
local function rail(ctx, m, a, b, s, color)
	local right = flat(b - a):Cross(UP)
	local off = right * s
	local len = (b - a).Magnitude
	local n = math.max(1, math.floor(len / 3.2))
	color = color or YELLOW
	local rng = ctx.rng
	for k = 0, n do
		local p = a:Lerp(b, k / n) + off
		rod(m, "RailPost", p, p + UP * 3.4, 0.2, Metal, if rng:NextNumber() < 0.2 then jitter(RUST, rng, 0.1) else jitter(color, rng, 0.08))
	end
	rod(m, "RailTop", a + off + UP * 3.3, b + off + UP * 3.3, 0.24, Metal, jitter(color, rng, 0.06))
	-- (some have lost their middle rail)
	if rng:NextNumber() < 0.8 then
		rod(m, "RailMid", a + off + UP * 1.7, b + off + UP * 1.7, 0.18, Metal, jitter(darken(color, 0.85), rng, 0.08))
	end
	deco(part(m, "ToeBoard", Vector3.new(0.1, 0.35, len), CFrame.lookAt((a + b) / 2 + off + UP * 0.18, b + off + UP * 0.18), Metal, color))
end

-- A catwalk from a to b: grating panels, channel stringers, crossbeams,
-- rails (o.rails: "both", "left", "right", "none"), rotten panels
-- (o.rotten[i]) that crumble, hung from the cables.
local function catwalk(ctx, m, a, b, o)
	o = o or {}
	local rng = ctx.rng
	local w = o.width or 4.6
	local len = (b - a).Magnitude
	local rot = CFrame.lookAt(a, b).Rotation
	local n = math.max(1, math.floor(len / 3))
	for i = 1, n do
		local c = a:Lerp(b, (i - 0.5) / n)
		local g = part(m, "Grating", Vector3.new(w, 0.35, len / n - 0.1), CFrame.new(c) * rot * CFrame.new(0, -0.175, 0), Plate, jitter(DECK, rng, 0.05))
		if o.rotten and o.rotten[i] then
			g.Material = Rust
			g.Color = jitter(RUST, rng, 0.12)
			g:AddTag("Crumble")
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		part(m, "Stringer", Vector3.new(0.3, 0.9, len), CFrame.new((a + b) / 2) * rot * CFrame.new(s * (w / 2 - 0.15), -0.65, 0), Metal, GALV)
	end
	for d = 2, len - 1, 5 do
		local c = a + (b - a).Unit * d
		deco(part(m, "Crossbeam", Vector3.new(w + 0.6, 0.35, 0.35), CFrame.new(c) * rot * CFrame.new(0, -1.1, 0), Metal, GALV))
	end
	local rails = o.rails or "both"
	if rails == "both" or rails == "left" then
		rail(ctx, m, a, b, -1 * (w / 2 - 0.1), o.railColor)
	end
	if rails == "both" or rails == "right" then
		rail(ctx, m, a, b, 1 * (w / 2 - 0.1), o.railColor)
	end
	if o.hang ~= false then
		local right = flat(b - a):Cross(UP)
		local s = if ctx.rng:NextNumber() < 0.5 then 1 else -1
		for d = math.min(3, len / 2), len - 1, 16 do
			local c = a + (b - a).Unit * d - UP * 1.1
			ctx.hang(m, c + right * s * (w / 2 + 0.2))
			s = -s
		end
	end
	if o.dress ~= false then
		Dress.catwalk(ctx, m, a, b, w, rails)
	end
end
Pieces.catwalk = catwalk

-- A landing plate from forward f0 to f1 off socket S, `w` wide, at height
-- y; rails down its sides (not its ends) if `railed`.
local function landing(ctx, m, S, f0, f1, w, y, railed)
	local a, b = P(S, 0, y, f0), P(S, 0, y, f1)
	catwalk(ctx, m, a, b, { width = w, rails = if railed then "both" else "none" })
	return a, b
end

-- A big pipe whose top runs along a -> b, lagged and flanged, hung in
-- saddles.
local function bigPipe(ctx, m, a, b, d)
	local rng = ctx.rng
	local color = pick(PIPES, rng)
	local off = UP * (d / 2)
	local dir = (b - a).Unit
	local len = (b - a).Magnitude
	rod(m, "Pipe", a - off, b - off, d, Metal, color)
	for k = 6, len - 3, 12 do
		local c = a + dir * k - off
		cylinder(m, "Flange", 0.6, d + 0.6, CFrame.lookAt(c, c + dir) * CFrame.Angles(0, math.pi / 2, 0), Metal, darken(color, 0.8))
	end
	for k = 2, len - 6, 11 do
		local l = math.min(rng:NextNumber(3, 6), len - k - 2)
		local c = a + dir * (k + l / 2) - off
		cylinder(m, "Lagging", l, d + 0.35, CFrame.lookAt(c, c + dir) * CFrame.Angles(0, math.pi / 2, 0), Foil, rgb(190, 192, 188))
	end
	local right = dir:Cross(UP).Unit
	for k = 4, len - 2, 8 do
		local c = a + dir * k - off
		deco(part(m, "Saddle", Vector3.new(d + 1, 0.6, 0.8), CFrame.lookAt(c - UP * (d / 2 + 0.3), c - UP * (d / 2 + 0.3) + dir), Metal, GALV))
		for _, s in ipairs({ -1, 1 }) do
			deco(rod(m, "SaddleStrap", c - UP * (d / 2 + 0.3) + right * s * (d / 2 + 0.4), c + right * s * (d / 2 + 0.4) + UP * 0.2, 0.2, Metal, GALV))
		end
		if math.floor(k / 8) % 2 == 0 then
			ctx.hang(m, c - UP * (d / 2 + 0.3) + right * (d / 2 + 0.5))
		end
	end
end

-- Make `m` one of Movers.client's moving things: its motion's attributes,
-- where it was built, and streamed in whole (a part arriving late would
-- otherwise be left out of place).
function Pieces.mover(m, attrs)
	for k, v in pairs(attrs) do
		m:SetAttribute(k, v)
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m:SetAttribute("Rest", m:GetPivot())
	m:AddTag("Mover")
	return m
end

-- ===== The pieces =====

local defs = {}

defs.walkway = function(S, ctx, rng)
	local len = rng:NextNumber(14, 26)
	local dy = rng:NextNumber(-0.1, 0.1) * len + (ctx.lean or 0) * len * 0.12
	local a, b = S.Position, P(S, 0, dy, len)
	return {
		exit = socket(S, 0, dy, len),
		boxes = { corridor(a, b, 7, 3, 9) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = "both" })
		end,
	}
end

defs.pipe = function(S, ctx, rng)
	local len = rng:NextNumber(16, 24)
	local dy = rng:NextNumber(-0.06, 0.06) * len
	local a, b = S.Position, P(S, 0, dy, len)
	local e = P(S, 0, dy, len + 4)
	return {
		exit = socket(S, 0, dy, len + 4),
		boxes = { corridor(a, e, 7, 6, 9) },
		build = function(m)
			bigPipe(ctx, m, a, b, 4.4)
			catwalk(ctx, m, b, e, { rails = "none", width = 5 })
		end,
	}
end

defs.broken = function(S, ctx, rng)
	local l1, l2, l3 = rng:NextNumber(5, 8), rng:NextNumber(5, 7), rng:NextNumber(6, 9)
	-- (down onto the middle is the long one; back up off it, shorter)
	local g1, g2 = rng:NextNumber(6, 7.4), rng:NextNumber(5.4, 6.4)
	local total = l1 + g1 + l2 + g2 + l3
	local sag = rng:NextNumber(1, 2)
	return {
		exit = socket(S, 0, 0, total),
		boxes = { corridor(S.Position, P(S, 0, 0, total), 7, 4, 9) },
		build = function(m)
			catwalk(ctx, m, S.Position, P(S, 0, 0, l1), { rails = "left" })
			-- the middle bit hangs lower on one side
			local a, b = P(S, 0, -sag, l1 + g1), P(S, 0, -sag, l1 + g1 + l2)
			local mm = model(m, "Sagging")
			catwalk(ctx, mm, a, b, { rails = "right", hang = false })
			mm:PivotTo(mm:GetPivot() * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-7, 7))))
			for _, p in ipairs({ a, b }) do
				chain(m, p + UP * 0.2, p + UP * 12)
				ctx.hang(m, p + UP * 12)
			end
			catwalk(ctx, m, P(S, 0, 0, l1 + g1 + l2 + g2), P(S, 0, 0, total), { rails = "right" })
			-- the torn ends of the grating, bent down
			for _, f in ipairs({ l1, l1 + g1 + l2 + g2 }) do
				deco(part(m, "TornGrating", Vector3.new(4, 0.3, 1.6), CFrame.lookAt(P(S, 0, -0.6, f + (if f == l1 then 0.7 else -0.7)), P(S, 0, -2, f + (if f == l1 then 1.6 else -1.6))), Plate, DECK))
			end
		end,
	}
end

defs.beams = function(S, ctx, rng)
	local f1, f2 = rng:NextNumber(10, 13), rng:NextNumber(10, 13)
	local side = pick({ -1, 1 }, rng) * math.tan(math.rad(rng:NextNumber(15, 25)))
	local dy = rng:NextNumber(-1, 1)
	local j = P(S, side * f1, dy / 2, f1 + 1.8)
	local e0 = P(S, 0, dy, f1 + f2 + 3.6)
	local plate0 = S.Position
	return {
		exit = socket(S, 0, dy, f1 + f2 + 7),
		boxes = { corridor(plate0, j, 6, 4, 9), corridor(j, e0, 6, 4, 9), corridor(e0, P(S, 0, dy, f1 + f2 + 7), 7, 3, 9) },
		build = function(m)
			local function beam(a, b)
				local cf = CFrame.lookAt((a + b) / 2, b)
				local len = (b - a).Magnitude
				part(m, "BeamTop", Vector3.new(1.1, 0.3, len), cf * CFrame.new(0, -0.15, 0), Rust, jitter(RUST, rng, 0.1))
				part(m, "BeamWeb", Vector3.new(0.3, 2.2, len), cf * CFrame.new(0, -1.4, 0), Rust, jitter(RUST, rng, 0.1))
				part(m, "BeamFoot", Vector3.new(1.1, 0.3, len), cf * CFrame.new(0, -2.65, 0), Rust, jitter(RUST, rng, 0.1))
				ctx.hang(m, (a + b) / 2 - UP * 2.8)
			end
			local jd = (j - plate0)
			beam(plate0, j - flat(jd) * 1.8)
			part(m, "BeamPlate", Vector3.new(3.6, 0.5, 3.6), CFrame.new(j - UP * 0.25) * CFrame.lookAt(Vector3.zero, flat(jd)).Rotation, Plate, jitter(DECK, rng, 0.05))
			chain(m, j + UP * 0.2, j + UP * 10)
			ctx.hang(m, j + UP * 10)
			beam(j + flat(e0 - j) * 1.8, e0)
			catwalk(ctx, m, e0, P(S, 0, dy, f1 + f2 + 7), { rails = "none", width = 4.6 })
		end,
	}
end

defs.reels = function(S, ctx, rng)
	local n = rng:NextInteger(4, 5)
	local f = 0
	local centres = {}
	local y = 0
	for i = 1, n do
		local ny = rng:NextNumber(-1.5, 1.5)
		local gap = rng:NextNumber(4.8, 6) - math.max(0, ny - y) * 0.5
		y = ny
		f += gap + 2.6
		table.insert(centres, { f = f, x = if i % 2 == 0 then rng:NextNumber(0.8, 1.8) else -rng:NextNumber(0.8, 1.8), y = y })
		f += 2.6
	end
	local endF = f + math.max(4.4, 5.4 - math.max(0, -y) * 0.5)
	return {
		exit = socket(S, 0, 0, endF + 5),
		boxes = { corridor(S.Position, P(S, 0, 0, endF + 5), 9, 5, 9) },
		build = function(m)
			for _, c in ipairs(centres) do
				local top = P(S, c.x, c.y, c.f)
				local rm = model(m, "CableReel")
				cylinder(rm, "Reel", 2.4, 5.2, CFrame.new(top - UP * 1.2) * UPRIGHT, Wood, jitter(rgb(120, 90, 60), rng, 0.08))
				for _, dy in ipairs({ -0.1, -2.3 }) do
					cylinder(rm, "ReelFlange", 0.3, 5.8, CFrame.new(top + UP * dy) * UPRIGHT, Wood, rgb(96, 70, 46))
				end
				cylinder(rm, "ReelCable", 1.6, 5.4, CFrame.new(top - UP * 1.2) * UPRIGHT, Smooth, DARK)
				local ring = top + UP * 9
				for k = 0, 2 do
					local a = k / 3 * math.pi * 2
					chain(rm, top + Vector3.new(math.cos(a) * 2.6, 0.2, math.sin(a) * 2.6), ring)
				end
				part(m, "ReelRing", Vector3.new(0.8, 0.8, 0.8), ring, Metal, DARK)
				ctx.hang(m, ring + UP * 0.4)
				-- swaying a little on its chains (you go with it)
				local sway = rng:NextNumber(0, math.pi)
				Pieces.mover(rm, { Motion = "swing", Pivot = ring, Axis = Vector3.new(math.cos(sway), 0, math.sin(sway)), Amp = math.rad(rng:NextNumber(4, 7)), Period = rng:NextNumber(2.6, 3.6), Phase = rng:NextNumber() })
			end
			catwalk(ctx, m, P(S, 0, 0, endF), P(S, 0, 0, endF + 5), { rails = "none" })
		end,
	}
end

defs.cage = function(S, ctx, rng)
	local gap = rng:NextNumber(24, 28)
	local la = 5
	local L = 26
	-- (at each end of its swing the cage stops 4.5 short of the landing)
	local off = gap / 2 - 7.5
	local amp = math.asin(off / L)
	local mid = la + gap / 2
	local pivot = P(S, 0, L * math.cos(amp), mid)
	local e = la + gap + 6
	return {
		exit = socket(S, 0, 0, e),
		boxes = { corridor(S.Position, P(S, 0, 0, e), 9, 5, 10) },
		build = function(m)
			landing(ctx, m, S, 0, la, 5, 0, true)
			landing(ctx, m, S, la + gap, e, 5, 0, true)
			-- the cage, hung from a block overhead
			local c = model(m, "SwingCage")
			local deck = P(S, 0, L * math.cos(amp) - L, mid)
			local rot = CFrame.lookAt(S.Position, P(S, 0, 0, 1)).Rotation
			local cf = CFrame.new(deck) * rot
			part(c, "CageFloor", Vector3.new(6, 0.4, 6), cf * CFrame.new(0, -0.2, 0), Plate, jitter(DECK, rng, 0.05))
			for _, s in ipairs({ -1, 1 }) do
				part(c, "CageSide", Vector3.new(0.2, 3.4, 6), cf * CFrame.new(s * 2.9, 1.7, 0), Metal, YELLOW).Transparency = 0.2
				for k = -2, 2 do
					deco(part(c, "CageBar", Vector3.new(0.12, 3.4, 0.12), cf * CFrame.new(s * 3, 1.7, k * 1.4), Metal, darken(YELLOW, 0.8)))
				end
			end
			for _, o in ipairs({ { -2.9, -2.9 }, { 2.9, -2.9 }, { 2.9, 2.9 }, { -2.9, 2.9 } }) do
				deco(rod(c, "CageChain", (cf * CFrame.new(o[1], 0, o[2])).Position, pivot, 0.2, Metal, DARK))
			end
			Pieces.mover(c, { Motion = "swing", Pivot = pivot, Axis = S.RightVector * -1, Amp = amp, Period = rng:NextNumber(4.2, 5.2), Phase = rng:NextNumber() })
			part(m, "PivotBlock", Vector3.new(2, 2, 2), pivot + UP, Metal, DARK)
			ctx.hang(m, pivot + UP * 2)
		end,
	}
end

defs.gondola = function(S, ctx, rng)
	local la = 5
	local dist = rng:NextNumber(26, 36)
	local dy = rng:NextNumber(-8, 10) + (ctx.lean or 0) * 6
	local e = la + dist + 6
	local startC = P(S, 0, 0, la + 3.3)
	local endC = P(S, 0, dy, la + dist - 3.3)
	return {
		exit = socket(S, 0, dy, e),
		boxes = { corridor(S.Position, P(S, 0, dy, e), 9, 4, 20) },
		build = function(m)
			landing(ctx, m, S, 0, la, 5, 0, true)
			landing(ctx, m, S, la + dist, e, 5, dy, true)
			-- the rail overhead
			local r0, r1 = startC + UP * 14, endC + UP * 14
			part(m, "Rail", Vector3.new(0.8, 1.2, (r1 - r0).Magnitude + 4), CFrame.lookAt((r0 + r1) / 2, r1), Metal, GALV)
			for _, p in ipairs({ r0, r1, (r0 + r1) / 2 }) do
				ctx.hang(m, p + UP * 0.6)
			end
			-- the cradle, its trolley and hangers
			local g = model(m, "Gondola")
			local rot = CFrame.lookAt(startC, startC + (endC - startC) * Vector3.new(1, 0, 1)).Rotation
			local cf = CFrame.new(startC) * rot
			part(g, "CradleFloor", Vector3.new(4.8, 0.4, 6), cf * CFrame.new(0, -0.2, 0), Plate, jitter(DECK, rng, 0.05))
			for _, s in ipairs({ -1, 1 }) do
				rod(g, "CradleRail", (cf * CFrame.new(s * 2.3, 3.2, -3)).Position, (cf * CFrame.new(s * 2.3, 3.2, 3)).Position, 0.2, Metal, YELLOW)
				for _, z in ipairs({ -3, 3 }) do
					rod(g, "CradlePost", (cf * CFrame.new(s * 2.3, 0, z)).Position, (cf * CFrame.new(s * 2.3, 3.3, z)).Position, 0.2, Metal, YELLOW)
				end
				deco(rod(g, "CradleCable", (cf * CFrame.new(s * 2.3, 3.3, 0)).Position, startC + UP * 13.2, 0.18, Metal, DARK))
			end
			part(g, "Trolley", Vector3.new(1.6, 1.2, 2.6), CFrame.new(startC + UP * 13) * rot, Metal, YELLOW)
			local travel = (endC - startC).Magnitude
			Pieces.mover(g, { Motion = "slide", Delta = endC - startC, Period = 2 * (travel / 12) / (1 - 2 * 0.18), Dwell = 0.18, Phase = rng:NextNumber() })
		end,
	}
end

defs.lift = function(S, ctx, rng)
	local rise = math.clamp(ctx.need or 24, 16, 30) + rng:NextNumber(-2, 2)
	local la = 6
	local shaft = la + 2.8
	local e = la + 5.6 + 6
	return {
		exit = socket(S, 0, rise, e),
		up = rise,
		boxes = { corridor(S.Position, P(S, 0, 0, la + 5.6), 8, 3, rise + 14), corridor(P(S, 0, rise, la + 5.6), P(S, 0, rise, e), 8, 3, 9) },
		build = function(m)
			landing(ctx, m, S, 0, la, 5, 0, true)
			landing(ctx, m, S, la + 5.6, e, 5, rise, true)
			local rot = CFrame.lookAt(S.Position, P(S, 0, 0, 1)).Rotation
			local base = CFrame.new(P(S, 0, 0, shaft)) * rot
			-- the shaft's frame, and the headgear on top
			for _, o in ipairs({ { -2.8, -2.8 }, { 2.8, -2.8 }, { 2.8, 2.8 }, { -2.8, 2.8 } }) do
				rod(m, "ShaftPost", (base * CFrame.new(o[1], -3, o[2])).Position, (base * CFrame.new(o[1], rise + 12, o[2])).Position, 0.45, Metal, GALV)
			end
			part(m, "Headgear", Vector3.new(6.4, 1.2, 6.4), base * CFrame.new(0, rise + 12, 0), Metal, YELLOW)
			cylinder(m, "Sheave", 0.6, 3, base * CFrame.new(0, rise + 13.4, 0) * CFrame.Angles(0, math.pi / 2, 0), Metal, DARK)
			for y = 4, rise + 8, 8 do
				for _, s in ipairs({ -1, 1 }) do
					deco(rod(m, "ShaftBrace", (base * CFrame.new(s * 2.8, y, -2.8)).Position, (base * CFrame.new(s * 2.8, y + 8, 2.8)).Position, 0.2, Metal, GALV))
				end
			end
			ctx.hang(m, (base * CFrame.new(-2.8, rise + 12.6, 0)).Position)
			ctx.hang(m, (base * CFrame.new(2.8, rise + 12.6, 0)).Position)
			-- the car
			local car = model(m, "LiftCar")
			part(car, "CarFloor", Vector3.new(5, 0.4, 5), base * CFrame.new(0, -0.2, 0), Plate, jitter(DECK, rng, 0.05))
			part(car, "CarRoof", Vector3.new(5, 0.3, 5), base * CFrame.new(0, 7.6, 0), Metal, darken(YELLOW, 0.8))
			for _, s in ipairs({ -1, 1 }) do
				part(car, "CarSide", Vector3.new(0.2, 7.4, 5), base * CFrame.new(s * 2.4, 3.8, 0), Metal, YELLOW).Transparency = 0.35
			end
			deco(rod(car, "CarCable", (base * CFrame.new(0, 7.8, 0)).Position, (base * CFrame.new(0, rise + 12, 0)).Position, 0.25, Metal, DARK))
			Pieces.mover(car, { Motion = "slide", Delta = UP * rise, Period = 2 * (rise / 10) / (1 - 2 * 0.2), Dwell = 0.2, Phase = rng:NextNumber() })
			label(m, (base * CFrame.new(-2.95, 5, 3.2)) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(2.4, 1.2, 0.05), Enum.NormalId.Back, "昇降機", YELLOW, DARK, Smooth, Enum.Font.GothamBlack)
		end,
	}
end

defs.net = function(S, ctx, rng)
	local rise = math.clamp(ctx.need or 20, 14, 26) + rng:NextNumber(-2, 2)
	local la = 6
	local e = la + 1.4 + 7
	return {
		exit = socket(S, 0, rise, e),
		up = rise,
		boxes = { corridor(S.Position, P(S, 0, 0, la + 1.4), 8, 3, rise + 6), corridor(P(S, 0, rise, la + 1.4), P(S, 0, rise, e), 8, 3, 9) },
		build = function(m)
			landing(ctx, m, S, 0, la, 5, 0, true)
			landing(ctx, m, S, la + 1.4, e, 5, rise, true)
			local f = la + 0.7
			truss(m, P(S, 0, 0, f), P(S, 0, rise + 3, f), false)
			-- the net over it: ropes both ways
			for x = -2.2, 2.2, 0.73 do
				deco(rod(m, "NetRope", P(S, x, 0.2, f), P(S, x, rise + 0.4, f), 0.14, Fabric, ROPE))
			end
			for y = 0.8, rise, 0.9 do
				deco(rod(m, "NetRope", P(S, -2.3, y, f), P(S, 2.3, y, f), 0.12, Fabric, ROPE))
			end
		end,
	}
end

defs.zip = function(S, ctx, rng)
	local len = rng:NextNumber(40, 70)
	local drop = -math.clamp(ctx.need and -ctx.need or len * 0.25, len * 0.14, len * 0.42)
	local e = 6 + len + 9
	local from = P(S, 0, 0, 3.5)
	local to = P(S, 0, drop, 6 + len + 4.5)
	local ca, cb = from + UP * (HANG + STAND), to + UP * (HANG + STAND)
	return {
		exit = socket(S, 0, drop, e),
		down = drop,
		boxes = { corridor(S.Position, P(S, 0, 0, 6), 8, 3, 9), corridor(ca - UP * 7, cb - UP * 7, 4, 0.5, 7.5), corridor(P(S, 0, drop, 6 + len), P(S, 0, drop, e), 11, 3, 9) },
		build = function(m)
			landing(ctx, m, S, 0, 6, 6, 0, true)
			landing(ctx, m, S, 6 + len, e, 9, drop, false)
			local zm = model(m, "ZipLine")
			local d = (cb - ca).Unit
			local fl = flat(d)
			rod(zm, "ZipCable", ca - fl * 3, cb + fl * 3, 0.35, Metal, DARK)
			for _, pp in ipairs({ { from - fl * 3, ca - fl * 3 }, { to + fl * 3, cb + fl * 3 } }) do
				rod(zm, "ZipMast", pp[1], pp[2] + UP * 2, 0.7, Metal, GALV)
			end
			local handle = part(zm, "ZipHandle", Vector3.new(0.6, 1.4, 0.6), ca + d * 1.5 - UP, Metal, YELLOW)
			handle.CanCollide = false
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Zip"
			prompt.ObjectText = "Zip line"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = handle
			zm:SetAttribute("From", ca)
			zm:SetAttribute("To", cb)
			zm:AddTag("ZipLine")
			ctx.hang(zm, ca + UP * 2)
		end,
	}
end

defs.rope = function(S, ctx, rng)
	local la = 5
	local gap = rng:NextNumber(21, 25)
	local e = la + gap + 6
	local ropeLen = 24
	local amp = math.asin(math.clamp((gap / 2 + 0.5) / ropeLen, 0.1, 0.85))
	local handY = STAND + 0.6
	local pivot = P(S, 0, handY + ropeLen * math.cos(amp), la + gap / 2)
	return {
		exit = socket(S, 0, 0, e),
		boxes = { corridor(S.Position, P(S, 0, 0, e), 8, 5, 30) },
		build = function(m)
			landing(ctx, m, S, 0, la, 5, 0, true)
			landing(ctx, m, S, la + gap, e, 5, 0, true)
			local r = model(m, "SwingRope")
			deco(rod(r, "Rope", pivot, pivot - UP * ropeLen, 0.45, Fabric, ROPE))
			deco(part(r, "RopeKnot", Vector3.new(1, 1.3, 1), pivot - UP * (ropeLen - 0.3), Fabric, darken(ROPE, 0.8)))
			r:SetAttribute("Pivot", pivot)
			r:SetAttribute("Length", ropeLen)
			r:SetAttribute("Dir", flat(S.LookVector))
			r:SetAttribute("Amp", amp)
			r:SetAttribute("Period", 2 * math.pi * math.sqrt(ropeLen / workspace.Gravity))
			r.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			r:SetAttribute("Rest", r:GetPivot())
			r:AddTag("SwingRope")
			part(m, "RopeBlock", Vector3.new(1.8, 1.8, 1.8), pivot + UP * 0.9, Metal, DARK)
			ctx.hang(m, pivot + UP * 1.8)
		end,
	}
end

defs.steam = function(S, ctx, rng)
	local len = rng:NextNumber(22, 30)
	local side = pick({ -1, 1 }, rng) -- the railed side, where the pipes and vents are
	local a, b = S.Position, P(S, 0, 0, len)
	return {
		exit = socket(S, 0, 0, len),
		boxes = { corridor(a, b, 10, 3, 9) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = if side < 0 then "left" else "right" })
			local color = pick(PIPES, rng)
			local p0, p1 = P(S, side * 3.6, 1.2, 0.5), P(S, side * 3.6, 1.2, len - 0.5)
			rod(m, "SteamMain", p0, p1, 1.8, Metal, color)
			local n = math.max(2, math.floor(len / 9))
			for k = 1, n do
				local f = len * k / (n + 1)
				local vent = P(S, side * 2.8, 1.2, f)
				local toward = S.RightVector * -side
				cylinder(m, "Vent", 1.2, 1.2, CFrame.lookAt(vent, vent + toward) * CFrame.Angles(0, math.pi / 2, 0), Metal, darken(color, 0.7))
				local jet = hidden(part(m, "SteamJet", Vector3.new(4, 7, 7), CFrame.lookAt(P(S, 0, 3, f), P(S, 0, 3, f) + toward), Smooth, DARK))
				jet:SetAttribute("Period", rng:NextNumber(2.8, 4))
				jet:SetAttribute("OnTime", 1.1)
				jet:SetAttribute("Offset", rng:NextNumber(0, 4))
				jet:SetAttribute("Push", toward * 55 + UP * 14)
				jet:AddTag("SteamJet")
				local em = Instance.new("ParticleEmitter")
				em.Texture = "rbxasset://textures/particles/smoke_main.dds"
				em.Rate = 0
				em.Lifetime = NumberRange.new(0.5, 0.9)
				em.Speed = NumberRange.new(26, 36)
				em.SpreadAngle = Vector2.new(10, 10)
				em.EmissionDirection = Enum.NormalId.Front
				em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 6) })
				em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
				em.Color = ColorSequence.new(rgb(240, 240, 240))
				em.Parent = jet
				label(m, CFrame.lookAt(P(S, side * 3.7, 3, f), P(S, side * 3.7, 3, f) + toward), Vector3.new(2.4, 0.8, 0.05), Enum.NormalId.Front, "蒸気 注意", YELLOW, DARK, Smooth, Enum.Font.GothamBlack)
			end
		end,
	}
end

defs.crumble = function(S, ctx, rng)
	local len = rng:NextNumber(16, 24)
	local a, b = S.Position, P(S, 0, 0, len)
	local n = math.max(1, math.floor(len / 3))
	local rotten = {}
	for i = 2, n - 1 do
		rotten[i] = rng:NextNumber() < 0.75
	end
	return {
		exit = socket(S, 0, 0, len),
		boxes = { corridor(a, b, 7, 3, 9) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = pick({ "left", "right", "none" }, rng), rotten = rotten, railColor = RUST })
		end,
	}
end

defs.drop = function(S, ctx, rng)
	local drop = -rng:NextNumber(10, 15)
	-- (falling that far you carry about 11 studs out: this is a leap)
	local gap = rng:NextNumber(5, 7.5)
	local e = 4 + gap + 9
	return {
		exit = socket(S, 0, drop, e),
		down = drop,
		boxes = { corridor(S.Position, P(S, 0, 0, 4), 7, 3, 9), corridor(P(S, 0, drop, 4), P(S, 0, drop, e), 11, 3, 9 - drop) },
		build = function(m)
			landing(ctx, m, S, 0, 4, 5, 0, true)
			landing(ctx, m, S, 4 + gap, e, 9, drop, false)
			-- a net round the catch platform's far side
			for _, x in ipairs({ -4.6, 4.6 }) do
				deco(rod(m, "NetEdge", P(S, x, drop + 0.3, 4 + gap), P(S, x, drop + 2.5, e), 0.12, Fabric, ROPE))
			end
			label(m, CFrame.lookAt(P(S, 0, 0.05, 3), P(S, 0, 1.05, 3)), Vector3.new(3, 1.2, 0.05), Enum.NormalId.Front, "↓", YELLOW, DARK, Smooth, Enum.Font.GothamBlack).Transparency = 1
		end,
	}
end

-- ===== More: things that move, push and vanish =====

-- A spinner: a round platform with a paddle sweeping round it, waist high
-- (jump it as it comes, or it flings you off), sometimes two platforms
-- turning opposite ways.
defs.spinner = function(S, ctx, rng)
	local double = rng:NextNumber() < 0.35
	local r = 8
	local e = 4 + (if double then 4 * r + 3 else 2 * r) + 4
	return {
		exit = socket(S, 0, 0, e),
		boxes = { corridor(S.Position, P(S, 0, 0, e), 2 * r + 2, 3, 9) },
		build = function(m)
			landing(ctx, m, S, 0, 4, 5, 0, true)
			local f = 4 + r
			for k = 1, if double then 2 else 1 do
				local c = P(S, 0, 0, f)
				cylinder(m, "Turntable", 1, 2 * r, CFrame.new(c - UP * 0.5) * UPRIGHT, Plate, jitter(DECK, ctx.rng, 0.05))
				cylinder(m, "TurntableRim", 1.4, 2 * r + 0.6, CFrame.new(c - UP * 1.2) * UPRIGHT, Metal, GALV)
				for a = 0, 2 do
					local ang = a / 3 * math.pi * 2 + 0.5
					ctx.hang(m, c + Vector3.new(math.cos(ang) * (r + 0.3), -1.2, math.sin(ang) * (r + 0.3)))
				end
				local sp = model(m, "Sweeper")
				cylinder(sp, "Hub", 4.6, 2.6, CFrame.new(c + UP * 2.3) * UPRIGHT, Metal, DARK)
				local dirs = if rng:NextNumber() < 0.5 then { 0 } else { 0, math.pi }
				for _, a in ipairs(dirs) do
					local tip = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (r - 0.4)
					local mid = (c + tip) / 2 + UP * 2
					local along = CFrame.lookAt(mid, tip + UP * 2)
					local paddle = part(sp, "Paddle", Vector3.new(0.8, 3.2, r - 1.6), along * CFrame.new(0, 0, -0.4), Metal, YELLOW)
					paddle:AddTag("Knock")
					for d = -(r - 1.6) / 2 + 1, (r - 1.6) / 2 - 1, 1.8 do
						deco(part(sp, "Stripe", Vector3.new(0.9, 3.2, 0.7), along * CFrame.new(0, 0, -0.4 + d), Smooth, DARK))
					end
				end
				Pieces.mover(sp, { Motion = "rotate", Pivot = c, Axis = UP, Speed = (if k == 1 then 1 else -1) * rng:NextNumber(1.3, 2), Phase = rng:NextNumber() })
				f += 2 * r + 3
				if double and k == 1 then
					landing(ctx, m, S, 4 + 2 * r, 4 + 2 * r + 3, 4, 0, false)
				end
			end
			landing(ctx, m, S, e - 4, e, 5, 0, true)
		end,
	}
end

-- Stepping plates over a gap in two sets that take turns to be there.
defs.blink = function(S, ctx, rng)
	local n = rng:NextInteger(4, 6)
	local step = rng:NextNumber(8.6, 9.4) -- (plates 3.4 across: gaps of 5 to 6)
	local e = 5 + n * step + 1 + 5
	local period = rng:NextNumber(3, 3.8)
	return {
		exit = socket(S, 0, 0, e),
		boxes = { corridor(S.Position, P(S, 0, 0, e), 9, 4, 9) },
		build = function(m)
			landing(ctx, m, S, 0, 5, 5, 0, true)
			for i = 1, n do
				local c = P(S, if i % 2 == 0 then 1.2 else -1.2, rng:NextNumber(-0.8, 0.8), 5 + i * step - step / 2 + 1)
				local set = i % 2
				local plate = part(m, "BlinkPlate", Vector3.new(3.4, 0.5, 3.4), CFrame.new(c - UP * 0.25) * S.Rotation, Plate, if set == 0 then rgb(90, 150, 170) else rgb(200, 120, 60))
				plate.Material = Enum.Material.Neon
				plate.Transparency = 0.15
				plate.CanCollide = true
				for _, p in ipairs({ plate }) do
					p:SetAttribute("Period", period)
					p:SetAttribute("On", 0.6)
					p:SetAttribute("Offset", set * 0.5)
					p:AddTag("Blink")
				end
				deco(rod(m, "PlateWire", c + UP * 0.1, c + UP * 12, 0.08, Metal, DARK))
				ctx.hang(m, c + UP * 12)
			end
			landing(ctx, m, S, e - 5, e, 5, 0, true)
		end,
	}
end

-- Conveyor belts dragging you sideways, turn and turn about, no rails.
defs.conveyor = function(S, ctx, rng)
	local n = rng:NextInteger(3, 4)
	local seg = rng:NextNumber(6, 8)
	local len = n * seg
	return {
		exit = socket(S, 0, 0, len + 3),
		boxes = { corridor(S.Position, P(S, 0, 0, len + 3), 9, 3, 9) },
		build = function(m)
			local speed = rng:NextNumber(11, 15)
			for i = 1, n do
				local a, b = P(S, 0, 0, (i - 1) * seg + 0.1), P(S, 0, 0, i * seg - 0.1)
				local cf = CFrame.lookAt((a + b) / 2, b)
				local dir = if i % 2 == 0 then 1 else -1
				local belt = part(m, "Belt", Vector3.new(5, 0.5, seg - 0.2), cf * CFrame.new(0, -0.25, 0), Enum.Material.Fabric, rgb(38, 38, 40))
				belt.AssemblyLinearVelocity = S.RightVector * dir * speed
				for _, s in ipairs({ -1, 1 }) do
					cylinder(m, "Roller", seg, 0.9, cf * CFrame.new(s * 2.6, -0.4, 0) * CFrame.Angles(0, math.pi / 2, 0), Metal, GALV)
				end
				for k = -1, 1 do
					label(m, cf * CFrame.new(0, 0.02, k * seg / 3) * CFrame.Angles(math.rad(-90), 0, 0), Vector3.new(4, 1.4, 0.02), Enum.NormalId.Front, if dir > 0 then "> > >" else "< < <", DARK, YELLOW, Smooth, Enum.Font.GothamBlack).Transparency = 1
				end
				ctx.hang(m, (cf * CFrame.new(if i % 2 == 0 then 2.8 else -2.8, -0.8, 0)).Position)
			end
			catwalk(ctx, m, P(S, 0, 0, len), P(S, 0, 0, len + 3), { rails = "none" })
		end,
	}
end

-- Big fans on one side, gusting across a walk railed only on their side.
defs.fans = function(S, ctx, rng)
	local len = rng:NextNumber(24, 30)
	local side = pick({ -1, 1 }, rng)
	local a, b = S.Position, P(S, 0, 0, len)
	return {
		exit = socket(S, 0, 0, len),
		boxes = { corridor(a, b, 10 + 12, 3, 12) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = if side < 0 then "left" else "right" })
			local across = S.RightVector * -side
			local period = rng:NextNumber(4.5, 6)
			for k, f in ipairs({ len * 0.3, len * 0.72 }) do
				local c = P(S, side * 8, 4.2, f)
				local housing = CFrame.lookAt(c, c + across)
				cylinder(m, "FanHousing", 2.4, 10, housing * CFrame.Angles(0, math.pi / 2, 0), Metal, GALV)
				cylinder(m, "FanMotor", 2.4, 2.4, housing * CFrame.new(0, 0, 2) * CFrame.Angles(0, math.pi / 2, 0), Metal, DARK)
				for g = -4, 4, 1 do
					deco(part(m, "Grille", Vector3.new(0.12, 9, 0.12), housing * CFrame.new(g, 0, -1.3), Metal, DARK))
				end
				local blades = model(m, "FanBlades")
				for bl = 0, 3 do
					deco(part(blades, "Blade", Vector3.new(1.4, 4.2, 0.2), housing * CFrame.Angles(0, 0, bl * math.pi / 2) * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0.4, 0), Metal, rgb(170, 60, 40)))
				end
				Pieces.mover(blades, { Motion = "rotate", Pivot = c, Axis = across, Speed = 14, Phase = rng:NextNumber() })
				ctx.hang(m, c + UP * 5)
				local zone = hidden(part(m, "SteamJet", Vector3.new(7, 8, 9), CFrame.lookAt(P(S, 0, 3, f), P(S, 0, 3, f) + across), Smooth, DARK))
				zone:SetAttribute("Mode", "wind")
				zone:SetAttribute("Period", period)
				zone:SetAttribute("OnTime", period * 0.55)
				zone:SetAttribute("Offset", k * 0.4)
				zone:SetAttribute("Push", across * 95)
				zone:AddTag("SteamJet")
				local em = Instance.new("ParticleEmitter")
				em.Texture = "rbxasset://textures/particles/smoke_main.dds"
				em.Rate = 0
				em.Lifetime = NumberRange.new(0.6, 1)
				em.Speed = NumberRange.new(30, 40)
				em.EmissionDirection = Enum.NormalId.Front
				em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2) })
				em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1) })
				em.Parent = zone
			end
		end,
	}
end

-- A spring pad that fires you up onto a ledge above.
defs.bounce = function(S, ctx, rng)
	local rise = math.clamp(ctx.need or 16, 12, 20) + rng:NextNumber(-1, 1)
	local gap = rng:NextNumber(7, 9)
	local la = 6
	local e = la + gap + 7
	local pad = P(S, 0, 0, 3.4)
	local land = P(S, 0, rise, la + gap + 2.5)
	local g = workspace.Gravity
	-- (the apex half as high again as it strictly needs: in play the
	-- character loses more than the sums say)
	local vy = math.sqrt(2 * g * (rise + 5) * 1.5)
	local tFlight = (vy + math.sqrt(vy * vy - 2 * g * rise)) / g
	local run = Vector3.new(land.X - pad.X, 0, land.Z - pad.Z)
	local launch = run.Unit * (run.Magnitude / tFlight) + UP * vy
	return {
		exit = socket(S, 0, rise, e),
		up = rise,
		boxes = { corridor(S.Position, P(S, 0, 0, la), 8, 3, rise + 12), corridor(P(S, 0, rise, la + gap), P(S, 0, rise, e), 8, 3, 9) },
		build = function(m)
			landing(ctx, m, S, 0, la, 5, 0, true)
			landing(ctx, m, S, la + gap, e, 6, rise, true)
			local padPart = part(m, "SpringPad", Vector3.new(3, 0.5, 3), CFrame.new(pad + UP * 0.25) * S.Rotation, Smooth, YELLOW)
			padPart:SetAttribute("Launch", launch)
			padPart:AddTag("Bounce")
			for k = -1, 1 do
				deco(part(m, "PadStripe", Vector3.new(0.5, 0.52, 3.02), CFrame.new(pad + UP * 0.25) * S.Rotation * CFrame.new(k * 1, 0, 0), Smooth, DARK))
			end
			for _, s in ipairs({ -1, 1 }) do
				deco(cylinder(m, "Spring", 0.5, 0.8, CFrame.new(pad + S.RightVector * s * 1.1 - UP * 0.2) * UPRIGHT, Metal, GALV))
			end
			label(m, CFrame.lookAt(P(S, 0, 0.05, 1.2), P(S, 0, 1.05, 1.2)), Vector3.new(2.6, 1.2, 0.05), Enum.NormalId.Front, "↑", YELLOW, DARK, Smooth, Enum.Font.GothamBlack).Transparency = 1
		end,
	}
end

-- Pushers: steel blocks shoved out across the walk from one side, again
-- and again; nothing on the far side to stop you going over.
defs.pistons = function(S, ctx, rng)
	local len = rng:NextNumber(24, 30)
	local side = pick({ -1, 1 }, rng)
	local a, b = S.Position, P(S, 0, 0, len)
	return {
		exit = socket(S, 0, 0, len),
		boxes = { corridor(a, b, 24, 3, 9) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = "none" })
			local n = math.floor(len / 8)
			for k = 1, n do
				local f = len * k / (n + 1)
				local home = P(S, side * 6, 1.8, f)
				local across = S.RightVector * -side
				part(m, "PistonHousing", Vector3.new(4, 4.4, 4.4), CFrame.lookAt(P(S, side * 9, 1.8, f), P(S, side * 9, 1.8, f) + across), Metal, GALV)
				ctx.hang(m, P(S, side * 9, 4, f))
				local pm = model(m, "Pusher")
				local ram = part(pm, "Ram", Vector3.new(3.6, 3.6, 3.6), CFrame.lookAt(home, home + across), Metal, YELLOW)
				ram:AddTag("Knock")
				deco(part(pm, "RamFace", Vector3.new(3.7, 3.7, 0.2), CFrame.lookAt(home, home + across) * CFrame.new(0, 0, -1.85), Smooth, DARK))
				rod(pm, "RamRod", home - across * 1.8, home - across * 5, 1.2, Metal, rgb(200, 200, 196))
				Pieces.mover(pm, { Motion = "slide", Delta = across * 7.5, Period = rng:NextNumber(2.2, 3), Dwell = 0.3, Phase = k * 0.37 })
			end
		end,
	}
end

-- Heavy hooks on chains, swinging across the walk.
defs.hooks = function(S, ctx, rng)
	local len = rng:NextNumber(24, 30)
	local a, b = S.Position, P(S, 0, 0, len)
	return {
		exit = socket(S, 0, 0, len),
		boxes = { corridor(a, b, 26, 3, 24) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = "none" })
			for k, f in ipairs({ len * 0.34, len * 0.7 }) do
				local pivot = P(S, 0, 20, f)
				local hm = model(m, "SwingHook")
				local bottom = P(S, 0, 2.6, f)
				chain(hm, pivot, bottom + UP * 1.6)
				local block = part(hm, "HookBlock", Vector3.new(2.6, 3.4, 2.6), CFrame.new(bottom + UP * 0.2) * S.Rotation, Metal, YELLOW)
				block:AddTag("Knock")
				local hk = part(hm, "Hook", Vector3.new(0.9, 2.2, 2), CFrame.new(bottom - UP * 2) * S.Rotation, Metal, DARK)
				hk:AddTag("Knock")
				Pieces.mover(hm, { Motion = "swing", Pivot = pivot, Axis = flat(S.LookVector), Amp = math.rad(rng:NextNumber(38, 50)), Period = rng:NextNumber(2.8, 3.6), Phase = k * 0.5 + rng:NextNumber(0, 0.2) })
				part(m, "HookPulley", Vector3.new(1.6, 1.6, 1.6), pivot + UP * 0.8, Metal, DARK)
				ctx.hang(m, pivot + UP * 1.6)
			end
		end,
	}
end

Pieces.defs = defs

-- What each is for: `level` pieces go across (weighted), `up` climb,
-- `down` descend.
Pieces.LEVEL = {
	walkway = 0.8, pipe = 1.5, broken = 1.5, beams = 1.2, reels = 1.5, cage = 1.5, gondola = 1.2, rope = 1.2, steam = 1.5, crumble = 1.2,
	spinner = 1.6, blink = 1.5, conveyor = 1.4, fans = 1.4, pistons = 1.5, hooks = 1.5,
}
Pieces.UP = { lift = 2, net = 1.6, bounce = 1.8, gondola = 0.6 }
Pieces.DOWN = { zip = 2, drop = 1.5, gondola = 0.5 }

-- ===== Adaptive: turning, and finishing at a hub =====

-- A junction plate turning towards `target` (by at most 45 degrees).
function Pieces.pivot(S, target, ctx)
	local want = flat(target - S.Position)
	local look = flat(S.LookVector)
	local ang = math.atan2(look:Cross(want).Y, look:Dot(want))
	if math.abs(ang) < math.rad(8) then
		return nil
	end
	ang = math.clamp(ang, -math.rad(45), math.rad(45))
	local c = P(S, 0, 0, 3.5)
	local cf = CFrame.new(c) * S.Rotation * CFrame.Angles(0, ang, 0)
	local exit = cf * CFrame.new(0, 0, -3.5)
	return {
		exit = exit,
		boxes = { box(CFrame.new(c + UP * 3), Vector3.new(4, 9, 4)) },
		build = function(m)
			part(m, "JunctionPlate", Vector3.new(7.4, 0.5, 7.4), CFrame.new(c - UP * 0.25) * S.Rotation, Plate, jitter(DECK, ctx.rng, 0.05))
			part(m, "JunctionFrame", Vector3.new(7.8, 0.8, 7.8), CFrame.new(c - UP * 0.9) * S.Rotation, Metal, GALV)
			for _, o in ipairs({ { -3.6, -3.6 }, { 3.6, 3.6 } }) do
				ctx.hang(m, (CFrame.new(c) * S.Rotation * CFrame.new(o[1], -0.9, o[2])).Position)
			end
		end,
	}
end

-- A plain walkway straight on to `T` (a hub's socket), if it's in reach.
function Pieces.walkTo(S, T, ctx)
	local a, b = S.Position, T.Position
	local run = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
	if run < 3 or run > 70 or math.abs(b.Y - a.Y) > run * 0.22 then
		return nil
	end
	if flat(S.LookVector):Dot(flat(b - a)) < math.cos(math.rad(30)) then
		return nil
	end
	return {
		exit = T,
		boxes = { corridor(a, b, 7, 3, 9, 1.5, 4.5) },
		build = function(m)
			catwalk(ctx, m, a, b, { rails = "both" })
		end,
	}
end

-- A zip line straight down to `T`, if it's low and far enough.
function Pieces.zipTo(S, T, ctx)
	local from = P(S, 0, 0, 3.5)
	local to = T.Position + flat(T.LookVector) * 4
	local run = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
	local slope = (to.Y - from.Y) / math.max(run, 1)
	if run < 30 or run > 130 or slope > -0.12 or slope < -0.5 then
		return nil
	end
	if flat(S.LookVector):Dot(flat(to - from)) < math.cos(math.rad(30)) then
		return nil
	end
	local ca, cb = from + UP * (HANG + STAND), to + UP * (HANG + STAND)
	return {
		exit = T,
		boxes = { corridor(S.Position, P(S, 0, 0, 6), 8, 3, 9), corridor(ca - UP * 7, cb - UP * 7, 4, 0.5, 7.5, 1.5, 6) },
		build = function(m)
			landing(ctx, m, S, 0, 6, 6, 0, true)
			local zm = model(m, "ZipLine")
			local d = (cb - ca).Unit
			local fl = flat(d)
			rod(zm, "ZipCable", ca - fl * 3, cb + fl * 2, 0.35, Metal, DARK)
			rod(zm, "ZipMast", from - fl * 3, ca - fl * 3 + UP * 2, 0.7, Metal, GALV)
			local handle = part(zm, "ZipHandle", Vector3.new(0.6, 1.4, 0.6), ca + d * 1.5 - UP, Metal, YELLOW)
			handle.CanCollide = false
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Zip"
			prompt.ObjectText = "Zip line"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = handle
			zm:SetAttribute("From", ca)
			zm:SetAttribute("To", cb)
			zm:AddTag("ZipLine")
			ctx.hang(zm, ca + UP * 2)
		end,
	}
end

return Pieces
