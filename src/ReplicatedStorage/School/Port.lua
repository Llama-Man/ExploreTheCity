-- The port (東港, "the east port"), at the far end of the chain of ships.
--
-- What holds the great chain's other end: a winch the size of a house, in
-- a winch house on the edge of a dead port's quay. The quay is a vast
-- concrete slab standing on a few colossal caissons out of the fog; on it,
-- the port that was, and the shipbreakers who came after:
--   the winch house   the chain comes in through its west wall and wraps
--                     round the drum; you come in with it, onto a gallery,
--                     and down stairs to the floor and out onto the quay
--   the yard          containers stacked in blocks, alleys between, some
--                     stacks fallen, some boxes open (loot in them), ladders
--                     up the ends to climb across the tops
--   the cranes        three ship-to-shore gantry cranes along the north
--                     edge: one sound (a ladder up to its girders), one with
--                     its boom snapped down over the edge into the fog, one
--                     listing on a buckled leg
--   the dry dock      a great pit in the quay, a ship on the keel blocks in
--                     it half cut away, its insides open; a goliath crane
--                     astride it. (Kept clear enough above: the oil rig will
--                     lie across it one day.)
--   the slipway       a tanker hauled up the slip, being broken: its bow cut
--                     off, chunks of hull, a propeller, sorted scrap, a winch
--   the rest          warehouses (open, stores in them), a rail siding with
--                     wagons (one off the rails), the harbour office tower
--                     (a lift to its control room), floodlights, bollards
--                     and fenders along the edges, mooring lines hanging
--
-- Built from SchoolGenerator after the chain of ships, with where the
-- chain ends (ChainOfShips.endPoint) and the top of its walk there.

local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local TunnelProps = require(script.Parent.TunnelProps)
local Pieces = require(script.Parent.CrossingPieces)
local Wind = require(script.Parent.Windblown)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local Metal, Rust, Plate, Smooth, Wood, Planks, Fabric, Neon, Glass, Concrete = Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.WoodPlanks, Enum.Material.Fabric, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Concrete
local rgb = Color3.fromRGB
local UP = Vector3.yAxis
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local TAU = math.pi * 2

local Port = {}

-- Where the great chain ends (ChainOfShips reads these): its x, and its
-- height there. The quay's top is 18 below that.
Port.CHAIN_END_X = 3230
Port.CHAIN_END_Y = 118

local DEEP = -600
local QUAY = rgb(150, 146, 138)
local DARK = rgb(34, 34, 36)
local RUST = rgb(116, 72, 44)
local STEEL = rgb(112, 116, 118)
local YELLOW = rgb(214, 170, 46)
local ROPE = rgb(170, 150, 110)
local CONTAINERS = { rgb(170, 60, 40), rgb(40, 90, 150), rgb(60, 120, 70), rgb(200, 150, 40), rgb(130, 130, 130), rgb(120, 60, 110), rgb(220, 220, 214), rgb(40, 110, 120) }
local LINES = { "KAIYO", "東洋海運", "NIPPON LINE", "ORIENT STAR", "大和汽船", "PACIFICA", "日の出海運", "NORDBAY" }
local CRANE_PAINT = { rgb(220, 120, 40), rgb(60, 100, 160), rgb(214, 170, 46) }

-- The quay (local x from its west edge, z from the chain's line; y from
-- its top): how far it runs, and where things are on it.
local W, ZN, ZS = 400, 230, -230
local DOCK = { x0 = 150, x1 = 330, z0 = -195, z1 = -110, depth = 50 }
local RAIL_Z = 132
local CRANE_Z = { 150, 215 } -- the gantry cranes' rails

-- ===== Bits =====

local lightsLeft = 0
local function light(p, range, color, brightness)
	if lightsLeft > 0 then
		lightsLeft -= 1
		local l = Instance.new("PointLight")
		l.Range = range
		l.Brightness = brightness or 1.1
		l.Color = color or rgb(255, 200, 150)
		l.Parent = p
	end
end

local function rod(parent, name, a, b, d, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	return cylinder(parent, name, len, d, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
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

local function ladder(parent, a, b, color)
	local t = Instance.new("TrussPart")
	t.Name = "Ladder"
	t.Anchored = true
	t.Size = Vector3.new(2, math.max(2, math.ceil((b - a).Magnitude / 2) * 2), 2)
	t.CFrame = CFrame.new((a + b) / 2)
	t.Material = Metal
	t.Color = color or YELLOW
	t.Parent = parent
	return t
end

-- A box between two corners.
local function slab(parent, name, a, b, material, color)
	local lo = Vector3.new(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z))
	local hi = Vector3.new(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z))
	return part(parent, name, hi - lo, (lo + hi) / 2, material, color)
end

-- Turn every part of `m` about the point `pivot` by `rot`.
local function turn(m, pivot, rot)
	local cf = CFrame.new(pivot) * rot * CFrame.new(-pivot)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = cf * d.CFrame
		end
	end
end

local function sparks(parent, pos)
	local src = hidden(part(parent, "Sparks", Vector3.new(0.6, 0.6, 0.6), pos, Smooth, DARK))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Rate = 12
	e.Lifetime = NumberRange.new(0.4, 0.9)
	e.Speed = NumberRange.new(6, 12)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Size = NumberSequence.new(0.25)
	e.Color = ColorSequence.new(rgb(255, 190, 90))
	e.LightEmission = 1
	e.Parent = src
	light(src, 10, rgb(255, 170, 80), 1.2)
end

-- A switchback stair from `top` (on an edge) down to height y0, flights
-- running along `run`, stepping out along `out`.
local function stairs(parent, top, out, run, y0, rng)
	local s = model(parent, "Stairs")
	local STEPS, RUN = 8, 1.4
	local L = STEPS * RUN
	local n = math.max(1, math.ceil((top.Y - y0) / 8))
	local rise = (top.Y - y0) / n
	local color = jitter(rgb(90, 96, 96), rng, 0.05)
	local function at(o, r, y)
		return Vector3.new(top.X, y, top.Z) + out * o + run * r
	end
	local function landing(r0, r1, y)
		local c = at(5.7, (r0 + r1) / 2, y - 0.3)
		part(s, "Landing", Vector3.new(11.4, 0.6, math.abs(r1 - r0)), CFrame.fromMatrix(c, out, UP), Plate, color)
	end
	landing(-3, 3, top.Y)
	local y = top.Y
	for k = 1, n do
		local odd = k % 2 == 1
		local lane = if odd then 2.8 else 8.6
		local r0 = if odd then 3 else 3 + L
		local dir = if odd then 1 else -1
		for i = 1, STEPS do
			part(s, "Step", Vector3.new(5.4, 0.5, RUN + 0.05), CFrame.fromMatrix(at(lane, r0 + dir * (i - 0.5) * RUN, y - i * rise / STEPS - 0.25), out, UP), Plate, color)
		end
		local edge = if odd then 0.2 else 11.2
		rod(s, "StairRail", at(edge, r0, y + 3.4), at(edge, r0 + dir * L, y - rise + 3.4), 0.2, Metal, YELLOW)
		y -= rise
		if odd then
			landing(3 + L, 3 + L + 5, y)
		else
			landing(-3, 3, y)
		end
	end
	for _, o in ipairs({ 0, 11.4 }) do
		for _, r in ipairs({ -3, 3 + L + 5 }) do
			rod(s, "StairPost", at(o, r, y0 - 1), at(o, r, top.Y + 4), 0.5, Metal, color)
		end
	end
	return s
end

-- ===== Containers =====

-- A shipping container with its bottom middle at cf, long along cf's x:
-- shut (its doors at +x, lock bars, sometimes its line's name on its
-- side), or open (hollow, its doors swung wide: you can go in).
local CL, CW, CH = 44, 9, 9.6
local function container(parent, cf, rng, open)
	local c = model(parent, "Container")
	local color = jitter(pick(CONTAINERS, rng), rng, 0.06)
	local mat = if rng:NextNumber() < 0.3 then Rust else Metal
	if not open then
		part(c, "Box", Vector3.new(CL, CH, CW), cf * CFrame.new(0, CH / 2, 0), mat, color)
		deco(part(c, "Doors", Vector3.new(0.2, CH - 0.6, CW - 0.6), cf * CFrame.new(CL / 2 + 0.05, CH / 2, 0), Metal, darken(color, 0.8)))
		for _, z in ipairs({ -2.6, -1, 1, 2.6 }) do
			deco(part(c, "LockBar", Vector3.new(0.15, CH - 1, 0.15), cf * CFrame.new(CL / 2 + 0.2, CH / 2, z), Metal, darken(color, 0.6)))
		end
		if rng:NextNumber() < 0.2 then
			local sd = pick({ -1, 1 }, rng)
			label(c, cf * CFrame.new(0, CH * 0.6, sd * (CW / 2 + 0.05)) * CFrame.Angles(0, if sd > 0 then 0 else math.pi, 0) * CFrame.Angles(0, math.pi, 0), Vector3.new(CL * 0.5, 2.6, 0.05), Enum.NormalId.Front, pick(LINES, rng), color, rgb(240, 240, 236), Smooth, Enum.Font.GothamBlack).Transparency = 1
		end
	else
		part(c, "Floor", Vector3.new(CL, 0.4, CW), cf * CFrame.new(0, 0.2, 0), Wood, rgb(110, 90, 70))
		part(c, "Roof", Vector3.new(CL, 0.3, CW), cf * CFrame.new(0, CH - 0.15, 0), mat, color)
		for _, sd in ipairs({ -1, 1 }) do
			part(c, "Side", Vector3.new(CL, CH, 0.3), cf * CFrame.new(0, CH / 2, sd * (CW / 2 - 0.15)), mat, color)
			-- a door swung wide
			local hinge = cf * CFrame.new(CL / 2, 0, sd * (CW / 2))
			part(c, "Door", Vector3.new(CW / 2, CH - 0.6, 0.2), hinge * CFrame.Angles(0, sd * math.rad(100), 0) * CFrame.new(-CW / 4, CH / 2, 0), Metal, darken(color, 0.8))
		end
		part(c, "Back", Vector3.new(0.3, CH, CW), cf * CFrame.new(-CL / 2 + 0.15, CH / 2, 0), mat, color)
		if rng:NextNumber() < 0.6 then
			marker(c, (cf * CFrame.new(-CL / 2 + 4, 0.4, 0)).Position)
		end
		for _ = 1, rng:NextInteger(1, 4) do
			part(c, "Crate", Vector3.new(3, rng:NextNumber(2, 4), 3), cf * CFrame.new(rng:NextNumber(-CL / 2 + 3, 0), 1.5, rng:NextNumber(-2.4, 2.4)) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), Wood, jitter(rgb(150, 112, 70), rng, 0.1))
		end
	end
	return c
end

-- The yard: blocks of stacks, four rows by four bays, alleys between.
local function yard(parent, O, rng)
	local m = model(parent, "ContainerYard")
	local bays = { 64, 114, 164, 214 }
	local blocks = { -78, -26, 26, 78 }
	for bi, z0 in ipairs(blocks) do
		for row = 0, 3 do
			local z = z0 + CW / 2 + row * CW
			for xi, x0 in ipairs(bays) do
				local r = rng:NextNumber()
				local h = if r < 0.12 then 0 elseif r < 0.32 then 1 elseif r < 0.62 then 2 elseif r < 0.84 then 3 elseif r < 0.95 then 4 else 5
				local x = x0 + CL / 2
				for k = 0, h - 1 do
					local open = k == 0 and rng:NextNumber() < 0.12
					local cf = CFrame.new(O + Vector3.new(x + rng:NextNumber(-0.3, 0.3), k * CH, z)) * CFrame.Angles(0, rng:NextNumber(-0.012, 0.012), 0)
					container(m, cf, rng, open)
				end
				-- one fallen off the top, lying against the stack
				if h >= 3 and rng:NextNumber() < 0.12 and row == 3 then
					local cf = CFrame.new(O + Vector3.new(x, 0, z + CW + 4)) * CFrame.Angles(0, rng:NextNumber(-0.25, 0.25), 0) * CFrame.Angles(math.rad(-18), 0, 0)
					container(m, cf, rng, false)
				end
				-- a ladder up the end of some
				if h >= 2 and (xi == 1 or xi == 4) and row == 1 and rng:NextNumber() < 0.6 then
					local ex = if xi == 1 then x0 - 1.2 else x0 + CL + 1.2
					ladder(m, O + Vector3.new(ex, 0, z), O + Vector3.new(ex, h * CH + 3, z))
				end
			end
		end
		-- the block's number painted on the ground at its end
		label(m, CFrame.new(O + Vector3.new(bays[1] - 6, 0.06, z0 + 2 * CW)) * CFrame.Angles(math.pi / 2, 0, 0), Vector3.new(6, 6, 0.05), Enum.NormalId.Front, string.char(64 + bi), QUAY, YELLOW, Smooth, Enum.Font.GothamBlack).Transparency = 1
		if bi % 2 == 1 then
			-- a straddle carrier parked in the alley after this block
			local sc = CFrame.new(O + Vector3.new(bays[2] + CL + 2.5 + 0, 0, z0 + 4 * CW + 8))
			for _, sx in ipairs({ -5, 5 }) do
				for _, sz in ipairs({ -3, 3 }) do
					rod(m, "CarrierLeg", (sc * CFrame.new(sx, 1, sz)).Position, (sc * CFrame.new(sx, 16, sz)).Position, 0.9, Metal, YELLOW)
					cylinder(m, "CarrierWheel", 0.8, 2, sc * CFrame.new(sx, 1, sz) * CFrame.Angles(0, math.pi / 2, 0), Smooth, DARK)
				end
			end
			part(m, "CarrierTop", Vector3.new(12, 2, 8), sc * CFrame.new(0, 17, 0), Metal, YELLOW)
			part(m, "CarrierCab", Vector3.new(3, 3, 3), sc * CFrame.new(-4, 19.5, 0), Glass, rgb(60, 70, 76)).Transparency = 0.3
		end
	end
	-- a forklift or two about the alleys
	for _ = 1, 3 do
		local at = O + Vector3.new(rng:NextNumber(70, 250), 0, pick(blocks, rng) + 4 * CW + rng:NextNumber(4, 12))
		local f = CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0)
		local fm = model(m, "Forklift")
		part(fm, "ForkBody", Vector3.new(3.4, 2.4, 6), f * CFrame.new(0, 1.8, 0), Metal, rgb(220, 170, 40))
		part(fm, "ForkSeat", Vector3.new(2.4, 1, 2), f * CFrame.new(0, 3.4, 0.8), Smooth, DARK)
		for _, sx in ipairs({ -1.5, 1.5 }) do
			rod(fm, "ForkMast", (f * CFrame.new(sx, 0.6, -3.1)).Position, (f * CFrame.new(sx, 7, -3.1)).Position, 0.35, Metal, DARK)
			part(fm, "Fork", Vector3.new(0.4, 0.2, 3.6), f * CFrame.new(sx * 0.6, 0.4, -5), Metal, DARK)
			for _, z in ipairs({ -2, 2 }) do
				cylinder(fm, "Wheel", 0.8, 1.6, f * CFrame.new(sx * 1.2, 0.8, z), Smooth, DARK)
			end
		end
		for _, o in ipairs({ { -1.4, 1.8 }, { 1.4, 1.8 }, { -1.4, -1 }, { 1.4, -1 } }) do
			rod(fm, "CagePost", (f * CFrame.new(o[1], 3, o[2])).Position, (f * CFrame.new(o[1], 6.6, o[2])).Position, 0.2, Metal, DARK)
		end
		part(fm, "CageRoof", Vector3.new(3.2, 0.2, 3.2), f * CFrame.new(0, 6.7, 0.4), Metal, DARK)
	end
end

-- ===== Cranes =====

-- A ship-to-shore gantry crane straddling the two rails at x: four legs,
-- the portal, the girders out over the edge and back, the A-frame with its
-- stays, the machinery house, the trolley and its spreader. mode: nil, or
-- "snapped" (the boom out over the water broken off at its hinge and hung
-- down into the fog), or "listing" (the whole of it leaning on a buckled
-- leg).
local function stsCrane(parent, O, x, rng, mode)
	local m = model(parent, "GantryCrane")
	local paint = pick(CRANE_PAINT, rng)
	local z0, z1 = CRANE_Z[1], CRANE_Z[2]
	local H = 52
	local function P(dx, y, z)
		return O + Vector3.new(x + dx, y, z)
	end
	for _, dx in ipairs({ -9, 9 }) do
		for _, z in ipairs({ z0, z1 }) do
			part(m, "Leg", Vector3.new(2.6, H, 2.6), P(dx, H / 2, z), Metal, paint)
			part(m, "Bogie", Vector3.new(4, 2, 7), P(dx, 1, z), Metal, DARK)
		end
		part(m, "PortalBeam", Vector3.new(2.6, 3.4, z1 - z0 + 2.6), P(dx, H - 1.7, (z0 + z1) / 2), Metal, paint)
		part(m, "SillBeam", Vector3.new(2, 2, z1 - z0), P(dx, 16, (z0 + z1) / 2), Metal, paint)
		deco(rod(m, "Brace", P(dx, 17, z0 + 1.3), P(dx, H - 3.4, (z0 + z1) / 2), 0.9, Metal, paint))
		deco(rod(m, "Brace", P(dx, 17, z1 - 1.3), P(dx, H - 3.4, (z0 + z1) / 2), 0.9, Metal, paint))
	end
	for _, z in ipairs({ z0, z1 }) do
		part(m, "CrossBeam", Vector3.new(20.6, 3, 2.6), P(0, H - 1.5, z), Metal, paint)
	end
	-- the girders: back over the quay, and out over the water
	local zBack, zHinge, zTip = z0 - 30, z1 + 12, z1 + 90
	for _, dx in ipairs({ -4, 4 }) do
		part(m, "BackGirder", Vector3.new(2.4, 4, zHinge - zBack), P(dx, H + 2, (zBack + zHinge) / 2), Metal, paint)
	end
	part(m, "GirderWalk", Vector3.new(3.4, 0.4, zHinge - zBack), P(0, H + 0.4, (zBack + zHinge) / 2), Plate, rgb(92, 92, 88))
	local boom = model(m, "Boom")
	for _, dx in ipairs({ -4, 4 }) do
		part(boom, "BoomGirder", Vector3.new(2.4, 4, zTip - zHinge), P(dx, H + 2, (zHinge + zTip) / 2), Metal, paint)
	end
	part(boom, "BoomWalk", Vector3.new(3.4, 0.4, zTip - zHinge), P(0, H + 0.4, (zHinge + zTip) / 2), Plate, rgb(92, 92, 88))
	for z = zHinge + 8, zTip - 4, 10 do
		deco(part(boom, "BoomTie", Vector3.new(10.4, 0.6, 0.6), P(0, H + 3.6, z), Metal, paint))
	end
	-- the trolley out on the boom, its cab, its spreader hanging
	local tz = zHinge + rng:NextNumber(20, 60)
	part(boom, "Trolley", Vector3.new(10, 3, 8), P(0, H - 1, tz), Metal, darken(paint, 0.85))
	part(boom, "Cab", Vector3.new(4, 4, 5), P(0, H - 5, tz - 1), Glass, rgb(60, 70, 76)).Transparency = 0.3
	local drop = rng:NextNumber(14, 34)
	for _, dx in ipairs({ -3, 3 }) do
		deco(rod(boom, "HoistRope", P(dx, H - 2.5, tz), P(dx, H - 2.5 - drop, tz), 0.2, Metal, DARK))
	end
	part(boom, "Spreader", Vector3.new(CL * 0.9, 1.4, 3), P(0, H - 3 - drop, tz), Metal, YELLOW)
	-- the A-frame and its stays
	local apex = P(0, H + 30, z0 + 10)
	for _, dx in ipairs({ -4, 4 }) do
		rod(m, "AFrame", P(dx, H + 4, z0 - 2), apex, 1.4, Metal, paint)
		rod(m, "AFrame", P(dx, H + 4, z0 + 22), apex, 1.4, Metal, paint)
		deco(rod(m, "Stay", apex, P(dx, H + 4, zBack + 2), 0.5, Metal, DARK))
	end
	local stays = model(boom, "Stays")
	for _, dx in ipairs({ -4, 4 }) do
		deco(rod(stays, "Stay", apex, P(dx, H + 4, zTip - 6), 0.5, Metal, DARK))
		deco(rod(stays, "Stay", apex, P(dx, H + 4, (zHinge + zTip) / 2), 0.5, Metal, DARK))
	end
	local beacon = deco(part(m, "Beacon", Vector3.new(1.2, 1.2, 1.2), apex + UP * 1.2, Neon, rgb(230, 40, 30)))
	beacon.Shape = Enum.PartType.Ball
	light(beacon, 20, rgb(255, 60, 40), 1.4)
	-- the machinery house on the back of it
	part(m, "MachineryHouse", Vector3.new(12, 8, 16), P(0, H + 8, zBack + 10), Metal, rgb(220, 218, 210))
	label(m, CFrame.lookAt(P(0, H + 9, zBack + 1.95), P(0, H + 9, zBack)), Vector3.new(10, 2.4, 0.05), Enum.NormalId.Front, pick({ "No.1", "No.2", "No.3", "東港 3", "KAIYO" }, rng), rgb(220, 218, 210), paint, Smooth, Enum.Font.GothamBlack)
	-- a ladder up a landside leg to the portal, and a flag on top
	ladder(m, P(-9, 0, z0 - 2.4), P(-9, H + 3, z0 - 2.4), rgb(220, 220, 214))
	Wind.flag(m, apex + UP * 2, 5, rng, { name = "Flag", height = 2.4, taper = 0.6, droop = 0.8, colors = { rgb(236, 232, 222), rgb(190, 40, 36) } })
	if mode == "snapped" then
		-- the boom broken at its hinge, hanging down over the edge
		turn(boom, P(0, H + 2, zHinge), CFrame.Angles(math.rad(70), 0, 0))
		for _ = 1, 4 do
			deco(part(m, "TornSteel", Vector3.new(rng:NextNumber(1, 3), rng:NextNumber(0.4, 1), rng:NextNumber(2, 5)), CFrame.new(P(rng:NextNumber(-5, 5), H + 2, zHinge - 1)) * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)), Metal, paint))
		end
	elseif mode == "listing" then
		-- one seaward leg buckled: the whole of it leans over that way
		turn(m, P(9, 0, z1), CFrame.Angles(math.rad(-7), 0, math.rad(-6)))
	end
	return m
end

-- The goliath crane astride the dry dock at x: two great legs each side,
-- the girder across, its crab, a hook hanging on chains.
local function goliath(parent, O, x, rng)
	local m = model(parent, "GoliathCrane")
	local paint = rgb(214, 170, 46)
	local zA, zB = DOCK.z0 - 14, DOCK.z1 + 14
	local H = 72
	for _, z in ipairs({ zA, zB }) do
		for _, dx in ipairs({ -10, 10 }) do
			rod(m, "GoliathLeg", O + Vector3.new(x + dx, 0, z), O + Vector3.new(x + dx * 0.3, H, z), 3.2, Metal, paint)
		end
		part(m, "GoliathSill", Vector3.new(26, 3, 6), O + Vector3.new(x, 1.5, z), Metal, DARK)
		for _, dx in ipairs({ -12, 12 }) do
			rod(m, "Rail", O + Vector3.new(DOCK.x0 - 10, 0.2, z + dx * 0.25), O + Vector3.new(DOCK.x1 + 10, 0.2, z + dx * 0.25), 0.5, Metal, STEEL)
		end
	end
	for _, dx in ipairs({ -3, 3 }) do
		part(m, "GoliathGirder", Vector3.new(3, 6, zB - zA + 8), O + Vector3.new(x + dx, H + 3, (zA + zB) / 2), Metal, paint)
	end
	part(m, "GoliathWalk", Vector3.new(9, 0.4, zB - zA + 8), O + Vector3.new(x, H + 6.2, (zA + zB) / 2), Plate, rgb(92, 92, 88))
	local cz = (zA + zB) / 2 + rng:NextNumber(-20, 20)
	part(m, "Crab", Vector3.new(10, 5, 9), O + Vector3.new(x, H + 8.5, cz), Metal, darken(paint, 0.85))
	local hookY = rng:NextNumber(20, 40)
	for _, dx in ipairs({ -1.5, 1.5 }) do
		deco(rod(m, "HookChain", O + Vector3.new(x + dx, H, cz), O + Vector3.new(x + dx, hookY + 3, cz), 0.5, Metal, DARK))
	end
	part(m, "HookBlock", Vector3.new(4, 4, 3), O + Vector3.new(x, hookY + 1, cz), Metal, YELLOW)
	part(m, "Hook", Vector3.new(1, 3, 2.6), O + Vector3.new(x, hookY - 2, cz), Metal, DARK)
	label(m, CFrame.lookAt(O + Vector3.new(x - 4.6, H + 3, (zA + zB) / 2), O + Vector3.new(x - 10, H + 3, (zA + zB) / 2)), Vector3.new(40, 4, 0.05), Enum.NormalId.Front, "東港造船所", paint, rgb(40, 40, 40), Smooth, Enum.Font.GothamBlack)
	ladder(m, O + Vector3.new(x - 12, 0, zA - 3), O + Vector3.new(x - 12, H + 8, zA - 3), rgb(220, 220, 214))
	local beacon = deco(part(m, "Beacon", Vector3.new(1.2, 1.2, 1.2), O + Vector3.new(x, H + 7, zA - 3), Neon, rgb(230, 40, 30)))
	beacon.Shape = Enum.PartType.Ball
	light(beacon, 16, rgb(255, 60, 40), 1.2)
end

-- ===== Ships in pieces =====

-- A hull in its own frame (cf at the middle of its keel, bow toward +x):
-- bottom, sides (red below the waterline), transom, the main deck and two
-- decks below it, bulkheads; the house at the stern with its bridge and
-- funnel. o.cut: the hull ends open at x = o.cut (everything forward of it
-- gone, its insides showing, torn plates round the cut).
local function hull(parent, cf, L, Bm, D, rng, o)
	o = o or {}
	local m = model(parent, "Hull")
	local paint = pick({ rgb(40, 50, 70), rgb(30, 30, 34), rgb(110, 40, 36), rgb(50, 80, 64) }, rng)
	local x0 = -L / 2
	local x1 = o.cut or L / 2
	local len = x1 - x0
	local mid = (x0 + x1) / 2
	local T = 0.8
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	part(m, "Bottom", Vector3.new(len, T, Bm - 2), at(mid, T / 2, 0), Rust, rgb(120, 50, 40))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "Side", Vector3.new(len, D * 0.4, T), at(mid, D * 0.2, s * (Bm / 2 - T / 2)), Rust, rgb(140, 50, 40))
		part(m, "Side", Vector3.new(len, D * 0.6, T), at(mid, D * 0.7, s * (Bm / 2 - T / 2)), Metal, paint)
		deco(part(m, "Bilge", Vector3.new(len, T, 2.2), at(mid, 1.2, s * (Bm / 2 - 1.3)) * CFrame.Angles(s * 0.7, 0, 0), Rust, rgb(120, 50, 40)))
		deco(part(m, "Waterline", Vector3.new(len, 0.6, T + 0.1), at(mid, D * 0.4, s * (Bm / 2 - T / 2)), Smooth, rgb(236, 232, 222)))
		for _ = 1, 3 do
			deco(part(m, "RustRun", Vector3.new(rng:NextNumber(1, 3), rng:NextNumber(4, 10), T + 0.12), at(rng:NextNumber(x0 + 4, x1 - 4), D * 0.72, s * (Bm / 2 - T / 2)), Rust, RUST))
		end
	end
	part(m, "Transom", Vector3.new(T, D, Bm), at(x0 + T / 2, D / 2, 0), Metal, paint)
	label(m, at(x0 - 0.05, D * 0.75, 0) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(Bm * 0.6, 2.4, 0.05), Enum.NormalId.Front, pick({ "第十一大洋丸", "EASTERN PRIDE", "KAIYO MARU", "SAKURA", "ORIENT", "明星丸" }, rng), paint, rgb(236, 232, 222), Smooth, Enum.Font.GothamBold).Transparency = 1
	-- decks: the main deck (with hatches) and two below
	part(m, "Deck", Vector3.new(len, T, Bm - 2 * T), at(mid, D - T / 2, 0), Plate, rgb(96, 90, 80))
	for _, f in ipairs({ 0.36, 0.66 }) do
		part(m, "LowerDeck", Vector3.new(len, 0.5, Bm - 2 * T), at(mid, D * f, 0), Plate, rgb(80, 76, 70))
	end
	for x = x0 + 20, x1 - 6, 22 do
		part(m, "Bulkhead", Vector3.new(0.6, D - 1, Bm - 2 * T), at(x, D / 2, 0), Metal, rgb(90, 96, 96))
	end
	for x = x0 + 30, x1 - 12, 22 do
		part(m, "HatchCoaming", Vector3.new(12, 1.6, Bm * 0.5), at(x, D + 0.8, 0), Metal, darken(paint, 0.8))
	end
	-- (ladders down through the decks, near the stern)
	ladder(m, at(x0 + 10, 0.8, Bm / 2 - 3).Position, at(x0 + 10, D + 3, Bm / 2 - 3).Position, rgb(220, 220, 214))
	if o.cut then
		-- torn plates round the open end, and the frames standing past it
		for _ = 1, 12 do
			local y = rng:NextNumber(0, D)
			local z = pick({ -1, 1 }, rng) * (Bm / 2 - 0.4)
			deco(part(m, "TornPlate", Vector3.new(rng:NextNumber(1, 4), rng:NextNumber(1, 4), 0.5), at(x1 + rng:NextNumber(-0.5, 1.5), y, z) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.6, 0.6), rng:NextNumber(-0.4, 0.4)), Metal, paint))
		end
		for k = 1, o.frames or 0 do
			local fx = x1 + k * 7
			for _, s in ipairs({ -1, 1 }) do
				rod(m, "Frame", at(fx, 0.6, 0).Position, at(fx, 1.5, s * (Bm / 2 - 1)).Position, 0.7, Rust, RUST)
				rod(m, "Frame", at(fx, 1.5, s * (Bm / 2 - 1)).Position, at(fx, D - k * 1.5, s * (Bm / 2 - 0.4)).Position, 0.7, Rust, RUST)
			end
			part(m, "Keel", Vector3.new(7.2, 1, 1.4), at(fx - 3.5, 0.5, 0), Rust, RUST)
		end
		sparks(m, at(x1 + 0.5, D * 0.5, Bm / 2 - 1).Position)
	else
		part(m, "Bow", Vector3.new(T, D, Bm), at(x1 - T / 2, D / 2, 0), Metal, paint)
	end
	-- the house at the stern: stacked decks, the bridge, its wings, the funnel
	local hx = x0 + 12
	local hw, hd = Bm * 0.8, 16
	for k = 0, 3 do
		local lw = hw - k * 1.5
		local y = D + k * 5
		part(m, "House", Vector3.new(hd - k, 5, lw), at(hx, y + 2.5, 0), Metal, rgb(226, 222, 212))
		deco(part(m, "HouseWindows", Vector3.new(hd - k + 0.1, 1.2, lw + 0.1), at(hx, y + 3.2, 0), Glass, rgb(40, 46, 50)))
	end
	part(m, "Bridge", Vector3.new(hd - 3, 4, hw + 6), at(hx + 1, D + 22, 0), Metal, rgb(226, 222, 212))
	deco(part(m, "BridgeWindows", Vector3.new(hd - 2.9, 1.6, hw + 6.1), at(hx + 1, D + 22.6, 0), Glass, rgb(40, 46, 50)))
	local fun = pick({ rgb(190, 40, 36), rgb(40, 60, 120), rgb(214, 170, 46) }, rng)
	cylinder(m, "Funnel", 12, 6, at(hx - 4, D + 26, 0) * UPRIGHT, Metal, fun)
	cylinder(m, "FunnelTop", 2, 6.2, at(hx - 4, D + 31, 0) * UPRIGHT, Metal, DARK)
	marker(m, at(x0 + 14, D * 0.66 + 0.25, -Bm / 4).Position)
	marker(m, at(hx + 1, D + 20.3, 0).Position)
	return m
end

-- ===== The winch house, where the chain ends =====

local function winchHouse(parent, O, E, walkTop, rng)
	local m = model(parent, "WinchHouse")
	local H = 34
	local x0, x1, z0, z1 = 0, 44, -30, 30
	local function P(x, y, z)
		return O + Vector3.new(x, y, z)
	end
	local wall = rgb(130, 128, 120)
	-- walls: north and south whole, the east with its great door, the west
	-- with the hole the chain comes in by
	slab(m, "Wall", P(x0, 0, z0), P(x1, H, z0 + 1), Concrete, wall)
	slab(m, "Wall", P(x0, 0, z1 - 1), P(x1, H, z1), Concrete, wall)
	slab(m, "Wall", P(x1 - 1, 0, z0), P(x1, H, -10), Concrete, wall)
	slab(m, "Wall", P(x1 - 1, 0, 10), P(x1, H, z1), Concrete, wall)
	slab(m, "Wall", P(x1 - 1, 20, -10), P(x1, H, 10), Concrete, wall)
	slab(m, "Wall", P(x0, 0, z0), P(x0 + 1, 7, z1), Concrete, wall)
	slab(m, "Wall", P(x0, 7, z0), P(x0 + 1, H, -12), Concrete, wall)
	slab(m, "Wall", P(x0, 7, 12), P(x0 + 1, H, z1), Concrete, wall)
	slab(m, "Wall", P(x0, 31, -12), P(x0 + 1, H, 12), Concrete, wall)
	slab(m, "Roof", P(x0 - 1, H, z0 - 1), P(x1 + 1, H + 1.2, z1 + 1), Concrete, darken(wall, 0.85))
	for x = x0 + 6, x1 - 4, 9 do
		deco(part(m, "Rooflight", Vector3.new(4, 0.3, 30), P(x, H + 1.35, 0), Glass, rgb(170, 190, 190))).Transparency = 0.4
	end
	-- the great drum, and its frames
	local drumC = P(24, 14, 0)
	cylinder(m, "Drum", 30, 22, CFrame.new(drumC) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(60, 62, 64))
	for z = -12, 12, 3 do
		deco(cylinder(m, "ChainCoil", 2.2, 23.6, CFrame.new(drumC + Vector3.new(0, 0, z)) * CFrame.Angles(0, math.pi / 2, 0), Rust, jitter(RUST, rng, 0.08)))
	end
	for _, z in ipairs({ -16.5, 16.5 }) do
		cylinder(m, "DrumCheek", 1.4, 26, CFrame.new(drumC + Vector3.new(0, 0, z)) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(180, 60, 40))
		for _, dx in ipairs({ -9, 9 }) do
			rod(m, "DrumFrame", P(24 + dx, 0, z * 1.1), drumC + Vector3.new(0, 0, z * 1.1), 2, Metal, STEEL)
		end
	end
	-- the chain's last links, from the hole down onto the drum
	local enter = E
	local onto = drumC + Vector3.new(-9.5, 5.5, 0)
	local dir = (onto - enter).Unit
	local n = math.floor((onto - enter).Magnitude / 16)
	for i = 0, n do
		local p = enter + dir * (i * 16 + 8)
		local side = dir:Cross(UP).Unit
		local a = if i % 2 == 0 then side else side:Cross(dir).Unit
		for _, s in ipairs({ -1, 1 }) do
			rod(m, "Link", p + a * s * 5 - dir * 8, p + a * s * 5 + dir * 8, 3, Rust, jitter(RUST, rng, 0.08))
			rod(m, "Link", p + dir * s * 9.5 - a * 5, p + dir * s * 9.5 + a * 5, 3, Rust, jitter(RUST, rng, 0.08))
		end
	end
	-- a brake, a motor, the gauges on a panel
	part(m, "Motor", Vector3.new(8, 7, 7), P(36, 3.5, -18), Metal, rgb(70, 96, 90))
	cylinder(m, "BrakeDrum", 3, 9, CFrame.new(P(24, 14, -19)) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(160, 60, 40))
	part(m, "Panel", Vector3.new(0.6, 6, 8), P(42.5, 4, 17), Metal, rgb(90, 110, 100))
	for k = 0, 2 do
		deco(cylinder(m, "Gauge", 0.25, 1.2, CFrame.new(P(42.1, 5.4, 14.5 + k * 2.4)) * CFrame.Angles(0, 0, 0), Metal, rgb(236, 232, 222)))
	end
	-- you come in with the chain: a landing out to where the walk ends, a
	-- gallery inside along the west wall, stairs down to the floor
	local gy = walkTop.Y - O.Y
	slab(m, "Landing", Vector3.new(walkTop.X - 2, O.Y + gy - 0.5, O.Z - 5), P(1, gy, 5), Plate, rgb(92, 92, 88))
	for _, s in ipairs({ -1, 1 }) do
		rod(m, "LandingRail", Vector3.new(walkTop.X - 2, O.Y + gy + 3.4, O.Z + s * 5), P(0, gy + 3.4, s * 5), 0.2, Metal, YELLOW)
	end
	slab(m, "Gallery", P(1, gy - 0.5, -4), P(9, gy, 4), Plate, rgb(92, 92, 88))
	rod(m, "GalleryRail", P(9, gy + 3.4, -4), P(9, gy + 3.4, 4), 0.2, Metal, YELLOW)
	rod(m, "GalleryRail", P(1, gy + 3.4, 4), P(9, gy + 3.4, 4), 0.2, Metal, YELLOW)
	stairs(m, P(1, gy, -7), Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), O.Y, rng)
	-- the name over the great door, lamps inside
	label(m, CFrame.lookAt(P(x1 + 0.1, 25, 0), P(x1 + 2, 25, 0)), Vector3.new(18, 4, 0.1), Enum.NormalId.Front, "東港 繋留所", wall, rgb(40, 40, 40), Concrete, Enum.Font.GothamBlack)
	for _, z in ipairs({ -12, 12 }) do
		local b = deco(part(m, "HallLamp", Vector3.new(1.4, 0.8, 1.4), P(20, H - 3, z), Neon, rgb(255, 214, 160)))
		rod(m, "LampCord", P(20, H, z), P(20, H - 2.6, z), 0.1, Metal, DARK)
		light(b, 30, rgb(255, 214, 160), 1)
	end
	marker(m, P(38, 0, 12))
end

-- ===== Everything else =====

local function warehouse(parent, O, x0, x1, z0, z1, rng)
	local m = model(parent, "Warehouse")
	local H = 20
	local wall = pick({ rgb(150, 140, 120), rgb(110, 120, 120), rgb(160, 110, 80) }, rng)
	local function P(x, y, z)
		return O + Vector3.new(x, y, z)
	end
	slab(m, "Wall", P(x0, 0, z0), P(x1, H, z0 + 0.8), Rust, wall)
	slab(m, "Wall", P(x0, 0, z0), P(x0 + 0.8, H, z1), Rust, wall)
	slab(m, "Wall", P(x1 - 0.8, 0, z0), P(x1, H, z1), Rust, wall)
	-- the front, onto the quay (z1): two great doors, one open
	local mid = (x0 + x1) / 2
	slab(m, "Wall", P(x0, 0, z1 - 0.8), P(mid - 14, H, z1), Rust, wall)
	slab(m, "Wall", P(mid + 14, 0, z1 - 0.8), P(x1, H, z1), Rust, wall)
	slab(m, "Wall", P(mid - 14, 14, z1 - 0.8), P(mid + 14, H, z1), Rust, wall)
	slab(m, "Wall", P(mid - 1, 0, z1 - 0.8), P(mid + 1, 14, z1), Rust, wall)
	slab(m, "ShutDoor", P(mid + 1, 0, z1 - 0.4), P(mid + 13, 13.6, z1 + 0.1), Metal, darken(wall, 0.7))
	slab(m, "Shutter", P(mid - 13, 12.6, z1 - 0.6), P(mid - 1, 13.8, z1 + 0.2), Metal, darken(wall, 0.6))
	-- a curved-looking roof: two pitches and a ridge vent
	local d = z1 - z0
	for _, s in ipairs({ -1, 1 }) do
		part(m, "Roof", Vector3.new(x1 - x0 + 2, 0.5, d / 2 + 1.6), CFrame.new(P(mid, H + 2.2, (z0 + z1) / 2 + s * d / 4)) * CFrame.Angles(s * 0.22, 0, 0), Rust, darken(wall, 0.8))
	end
	part(m, "RidgeVent", Vector3.new(x1 - x0 - 4, 1.4, 2), P(mid, H + 4.8, (z0 + z1) / 2), Metal, DARK)
	label(m, CFrame.lookAt(P(mid, 17, z1 + 0.1), P(mid, 17, z1 + 2)), Vector3.new(16, 3, 0.1), Enum.NormalId.Front, pick({ "第一倉庫", "第二倉庫", "第三倉庫", "冷蔵倉庫" }, rng), wall, rgb(240, 236, 226), Smooth, Enum.Font.GothamBlack)
	-- inside: racks, pallets, a forklift's worth of stores
	for x = x0 + 5, x1 - 8, 10 do
		part(m, "Racking", Vector3.new(7, 10, 3), P(x + 3.5, 5, z0 + 3), Metal, rgb(60, 90, 140))
		for k = 0, 2 do
			part(m, "Stores", Vector3.new(6, 2.4, 2.4), P(x + 3.5, 1.6 + k * 3.3, z0 + 3), Wood, jitter(rgb(150, 112, 70), rng, 0.12))
		end
	end
	for _ = 1, 5 do
		local p = P(rng:NextNumber(x0 + 5, x1 - 5), 0, rng:NextNumber(z0 + 9, z1 - 6))
		part(m, "Pallet", Vector3.new(4, 0.5, 4), p + UP * 0.25, Wood, rgb(170, 140, 100))
		part(m, "Sacks", Vector3.new(3.4, rng:NextNumber(1, 3), 3.4), p + UP * 1.5, Fabric, pick({ rgb(200, 190, 160), rgb(140, 120, 90) }, rng))
	end
	local b = deco(part(m, "Lamp", Vector3.new(1.4, 0.6, 1.4), P(mid, H - 2, (z0 + z1) / 2), Neon, rgb(255, 214, 160)))
	light(b, 34, rgb(255, 214, 160), 0.9)
	marker(m, P(x1 - 5, 0, z0 + 8))
end

local function officeTower(parent, O, x, z, rng)
	local m = model(parent, "HarbourOffice")
	local H = 62
	local function P(dx, y, dz)
		return O + Vector3.new(x + dx, y, z + dz)
	end
	part(m, "TowerCore", Vector3.new(12, H, 12), P(0, H / 2, 0), Concrete, rgb(170, 166, 156))
	for y = 8, H - 8, 9 do
		deco(part(m, "TowerWindows", Vector3.new(12.2, 2.4, 12.2), P(0, y, 0), Glass, rgb(40, 46, 50)))
	end
	-- the control room on top: glass all round, a balcony
	part(m, "ControlFloor", Vector3.new(20, 1, 20), P(0, H + 0.5, 0), Concrete, rgb(150, 146, 138))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "ControlGlass", Vector3.new(16, 7, 0.3), P(0, H + 4.5, s * 8), Glass, rgb(150, 180, 190)).Transparency = 0.5
		part(m, "ControlGlass", Vector3.new(0.3, 7, 16), P(s * 8, H + 4.5, 0), Glass, rgb(150, 180, 190)).Transparency = 0.5
		for _, t in ipairs({ -1, 1 }) do
			rod(m, "BalconyRail", P(s * 10, H + 1, t * 10), P(s * 10, H + 4.4, t * 10), 0.2, Metal, DARK)
		end
		rod(m, "BalconyRail", P(-10, H + 4.4, s * 10), P(10, H + 4.4, s * 10), 0.2, Metal, DARK)
	end
	part(m, "ControlRoof", Vector3.new(19, 0.8, 19), P(0, H + 8.4, 0), Concrete, rgb(120, 118, 112))
	rod(m, "BalconyRail", P(-10, H + 4.4, -10), P(-10, H + 4.4, 10), 0.2, Metal, DARK)
	part(m, "Console", Vector3.new(10, 3, 2), P(0, H + 2.5, 5.5), Metal, rgb(80, 90, 90))
	deco(part(m, "Screens", Vector3.new(9, 1.2, 0.2), P(0, H + 3.6, 4.4), Neon, rgb(120, 200, 170))).Transparency = 0.4
	rod(m, "Mast", P(0, H + 8.8, 0), P(0, H + 30, 0), 0.5, Metal, DARK)
	local b = deco(part(m, "MastLight", Vector3.new(1, 1, 1), P(0, H + 30.6, 0), Neon, rgb(230, 40, 30)))
	b.Shape = Enum.PartType.Ball
	light(b, 20, rgb(255, 60, 40), 1.2)
	cylinder(m, "Radar", 0.6, 7, CFrame.new(P(4, H + 10, 4)) * UPRIGHT, Metal, rgb(220, 220, 214))
	marker(m, P(-5, H + 1, -5))
	-- a lift up the side to the balcony (it carries you)
	local lx, lz = x + 13.5, z
	for _, o in ipairs({ { -3.2, -3.4 }, { 3.2, -3.4 }, { 3.2, 3.4 }, { -3.2, 3.4 } }) do
		rod(m, "ShaftPost", O + Vector3.new(lx + o[1], -1, lz + o[2]), O + Vector3.new(lx + o[1], H + 12, lz + o[2]), 0.4, Metal, STEEL)
	end
	part(m, "Headgear", Vector3.new(7, 1.2, 7.2), O + Vector3.new(lx, H + 12, lz), Metal, YELLOW)
	local car = model(m, "LiftCar")
	part(car, "CarFloor", Vector3.new(6, 0.4, 6.2), O + Vector3.new(lx, 0.15, lz), Plate, rgb(92, 92, 88))
	part(car, "CarRoof", Vector3.new(6, 0.3, 6.2), O + Vector3.new(lx, 9.8, lz), Metal, darken(YELLOW, 0.8))
	for _, sd in ipairs({ -1, 1 }) do
		part(car, "CarSide", Vector3.new(6, 9.4, 0.2), O + Vector3.new(lx, 5, lz + sd * 3), Metal, YELLOW).Transparency = 0.35
	end
	deco(rod(car, "CarCable", O + Vector3.new(lx, 10, lz), O + Vector3.new(lx, H + 12, lz), 0.2, Metal, DARK))
	local rise = H + 1
	Pieces.mover(car, { Motion = "slide", Delta = UP * rise, Period = 2 * (rise / 9) / (1 - 2 * 0.25), Dwell = 0.25, Phase = rng:NextNumber() })
	-- (the balcony reaches out to it)
	slab(m, "LiftLanding", O + Vector3.new(x + 10, H, z - 3.4), O + Vector3.new(x + 10.4, H + 1, z + 3.4), Concrete, rgb(150, 146, 138))
	part(m, "Sign", Vector3.new(0.2, 3, 12), P(6.15, 20, 0), Smooth, rgb(40, 60, 110))
	label(m, CFrame.lookAt(P(6.3, 20, 0), P(8, 20, 0)), Vector3.new(11, 2.6, 0.05), Enum.NormalId.Front, "港湾管理事務所", rgb(40, 60, 110), rgb(240, 240, 236), Smooth, Enum.Font.GothamBold).Transparency = 1
end

local function floodlight(parent, p, rng)
	local m = model(parent, "Floodlight")
	rod(m, "LightMast", p, p + UP * 46, 1.2, Metal, STEEL)
	part(m, "LightHead", Vector3.new(8, 1, 3), p + UP * 46.5, Metal, DARK)
	local lit = rng:NextNumber() < 0.6
	for k = -1, 1 do
		local lamp = deco(part(m, "Lamp", Vector3.new(2, 1.4, 0.4), CFrame.new(p + UP * 45.6 + Vector3.new(k * 2.6, 0, -1.2)) * CFrame.Angles(-0.6, 0, 0), if lit then Neon else Glass, rgb(255, 236, 200)))
		if lit and k == 0 then
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Bottom
			spot.Range = 60
			spot.Angle = 70
			spot.Brightness = 2
			spot.Color = rgb(255, 230, 190)
			spot.Parent = lamp
		end
	end
	ladder(m, p + Vector3.new(0, 0, 1.6), p + Vector3.new(0, 44, 1.6), rgb(150, 150, 146))
end

-- A bollard on the quay's edge, sometimes a line off it into the fog.
local function bollard(parent, p, out, rng)
	cylinder(parent, "Bollard", 2.4, 2, CFrame.new(p + UP * 1.2) * UPRIGHT, Metal, rgb(50, 50, 52))
	cylinder(parent, "BollardCap", 0.6, 2.8, CFrame.new(p + UP * 2.6) * UPRIGHT, Metal, rgb(50, 50, 52))
	if rng:NextNumber() < 0.3 then
		deco(rod(parent, "MooringLine", p + UP * 2, p + out * 3 - UP * rng:NextNumber(20, 45), 0.5, Fabric, ROPE))
	end
	-- a tyre fender on the face below
	cylinder(parent, "Fender", 1.2, 3, CFrame.lookAt(p + out * 1.1 - UP * 3, p + out * 2 - UP * 3) * CFrame.Angles(0, math.pi / 2, 0), Smooth, DARK)
end

-- ===== Assembly =====

function Port.build(parent, E, walkTop, rng)
	if not E then
		return
	end
	lightsLeft = 60
	local root = model(parent, "Port")
	local O = Vector3.new(E.X + 6, E.Y - 18, E.Z)
	local function P(x, y, z)
		return O + Vector3.new(x, y, z)
	end

	-- the quay: a slab round the dry dock's pit, its edge, the caissons
	local qm = model(root, "Quay")
	for _, r in ipairs({
		{ 0, W, ZS, DOCK.z0 }, { 0, W, DOCK.z1, ZN }, { 0, DOCK.x0, DOCK.z0, DOCK.z1 }, { DOCK.x1, W, DOCK.z0, DOCK.z1 },
	}) do
		slab(qm, "QuaySlab", P(r[1], -6, r[3]), P(r[2], 0, r[4]), Concrete, jitter(QUAY, rng, 0.02))
	end
	for _, e in ipairs({ { 0, W, ZN - 1.2, ZN }, { 0, W, ZS, ZS + 1.2 }, { W - 1.2, W, ZS, ZN } }) do
		deco(slab(qm, "Cope", P(e[1], 0, e[3]), P(e[2], 0.5, e[4]), Concrete, rgb(200, 196, 186)))
	end
	for _, c in ipairs({ { 60, -150 }, { 60, 160 }, { 200, 0 }, { 340, 170 }, { 350, -40 }, { 120, 60 } }) do
		slab(qm, "Caisson", P(c[1] - 17, DEEP - O.Y, c[2] - 17), P(c[1] + 17, -6, c[2] + 17), Concrete, jitter(rgb(96, 96, 92), rng, 0.04))
		for y = -40, -200, -40 do
			deco(slab(qm, "CaissonStain", P(c[1] - 17.1, y - 6, c[2] - 17.1), P(c[1] + 17.1, y, c[2] + 17.1), Concrete, rgb(70, 72, 70)))
		end
	end
	-- lines painted, cracks, puddles
	for _, z in ipairs({ CRANE_Z[1] - 5, CRANE_Z[2] + 5, RAIL_Z - 6, RAIL_Z + 6 }) do
		deco(part(qm, "PaintedLine", Vector3.new(W - 20, 0.05, 0.6), P(W / 2, 0.03, z), Smooth, YELLOW))
	end
	for _ = 1, 25 do
		deco(part(qm, "Crack", Vector3.new(rng:NextNumber(4, 18), 0.05, 0.3), CFrame.new(P(rng:NextNumber(10, W - 10), 0.03, rng:NextNumber(ZS + 10, ZN - 10))) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0), Concrete, rgb(80, 80, 78)))
	end
	for _ = 1, 10 do
		local pd = deco(part(qm, "Puddle", Vector3.new(rng:NextNumber(3, 9), 0.05, rng:NextNumber(3, 7)), P(rng:NextNumber(10, W - 10), 0.03, rng:NextNumber(ZS + 10, ZN - 10)), Glass, rgb(40, 46, 50)))
		pd.Reflectance = 0.35
		pd.Transparency = 0.2
	end
	-- bollards along the open edges
	for x = 20, W - 10, 24 do
		bollard(qm, P(x, 0, ZN - 2.5), Vector3.new(0, 0, 1), rng)
		bollard(qm, P(x, 0, ZS + 2.5), Vector3.new(0, 0, -1), rng)
	end
	for z = ZS + 20, ZN - 20, 24 do
		bollard(qm, P(W - 2.5, 0, z), Vector3.new(1, 0, 0), rng)
	end
	task.wait()

	-- where the chain ends
	winchHouse(root, O, E, walkTop, rng)
	task.wait()

	-- the yard
	yard(root, O, rng)
	task.wait()

	-- the cranes along the north edge, on their rails
	local cm = model(root, "Cranes")
	for _, z in ipairs(CRANE_Z) do
		rod(cm, "CraneRail", P(10, 0.2, z), P(W - 10, 0.2, z), 0.6, Metal, STEEL)
	end
	stsCrane(cm, O, 95, rng, nil)
	stsCrane(cm, O, 200, rng, "snapped")
	stsCrane(cm, O, 305, rng, "listing")
	task.wait()

	-- the dry dock: the pit, its walls, the gate, keel blocks, the ship in
	-- it half cut away, stairs down, the goliath over it
	local dm = model(root, "DryDock")
	local fy = -DOCK.depth
	slab(dm, "DockFloor", P(DOCK.x0, fy - 3, DOCK.z0), P(DOCK.x1, fy, DOCK.z1), Concrete, rgb(110, 110, 106))
	slab(dm, "DockWall", P(DOCK.x0 - 3, fy - 3, DOCK.z0 - 3), P(DOCK.x1 + 3, -6, DOCK.z0), Concrete, rgb(120, 120, 116))
	slab(dm, "DockWall", P(DOCK.x0 - 3, fy - 3, DOCK.z1), P(DOCK.x1 + 3, -6, DOCK.z1 + 3), Concrete, rgb(120, 120, 116))
	slab(dm, "DockWall", P(DOCK.x0 - 3, fy - 3, DOCK.z0), P(DOCK.x0, -6, DOCK.z1), Concrete, rgb(120, 120, 116))
	-- the altars: steps down the long sides
	for k = 1, 3 do
		for _, s in ipairs({ -1, 1 }) do
			local zEdge = if s < 0 then DOCK.z0 else DOCK.z1
			slab(dm, "Altar", P(DOCK.x0, fy + k * 12 - 1.2, zEdge), P(DOCK.x1, fy + k * 12, zEdge - s * (4 - k) * 2.4), Concrete, rgb(130, 130, 126))
		end
	end
	-- the caisson gate at the east end
	slab(dm, "DockGate", P(DOCK.x1, fy - 3, DOCK.z0), P(DOCK.x1 + 4, 0, DOCK.z1), Metal, rgb(70, 76, 76))
	for z = DOCK.z0 + 6, DOCK.z1 - 6, 8 do
		deco(slab(dm, "GateRib", P(DOCK.x1 - 0.6, fy, z - 0.5), P(DOCK.x1, -1, z + 0.5), Metal, rgb(60, 66, 66)))
	end
	for x = DOCK.x0 + 12, DOCK.x1 - 12, 8 do
		slab(dm, "KeelBlock", P(x - 1.5, fy, (DOCK.z0 + DOCK.z1) / 2 - 2), P(x + 1.5, fy + 3.4, (DOCK.z0 + DOCK.z1) / 2 + 2), Concrete, rgb(140, 140, 136))
		deco(slab(dm, "KeelCap", P(x - 1.5, fy + 3.4, (DOCK.z0 + DOCK.z1) / 2 - 2), P(x + 1.5, fy + 4, (DOCK.z0 + DOCK.z1) / 2 + 2), Wood, rgb(120, 96, 70)))
	end
	local shipCF = CFrame.new(P(245, fy + 4, (DOCK.z0 + DOCK.z1) / 2))
	hull(dm, shipCF, 150, 30, 26, rng, { cut = 30, frames = 5 })
	-- the pieces already off her, on the dock floor
	for _ = 1, 6 do
		slab(dm, "CutPlate", P(0, 0, 0), P(rng:NextNumber(3, 8), 0.6, rng:NextNumber(3, 6)), Metal, RUST):PivotTo(CFrame.new(P(rng:NextNumber(DOCK.x1 - 50, DOCK.x1 - 8), fy + 0.3 + rng:NextNumber(0, 1.2), rng:NextNumber(DOCK.z0 + 8, DOCK.z1 - 8))) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0))
	end
	stairs(dm, P(DOCK.x0, 0, (DOCK.z0 + DOCK.z1) / 2 - 11), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), O.Y + fy, rng)
	goliath(root, O, 250, rng)
	task.wait()

	-- the slipway: a tanker hauled up it, being broken
	local sm = model(root, "Slipway")
	local slipTop, slipEnd = 285, W
	local drop = 18
	local slope = math.atan2(drop, slipEnd - slipTop)
	local slipCF = CFrame.new(P((slipTop + slipEnd) / 2, -drop / 2 - 1, 65)) * CFrame.Angles(0, 0, -slope)
	part(sm, "Slip", Vector3.new((slipEnd - slipTop) / math.cos(slope) + 2, 2, 80), slipCF, Concrete, rgb(120, 118, 112))
	for z = 35, 95, 12 do
		deco(part(sm, "SlipRail", Vector3.new((slipEnd - slipTop) / math.cos(slope), 0.4, 0.8), slipCF * CFrame.new(0, 1.1, z - 65), Metal, STEEL))
	end
	local tankerCF = CFrame.new(P(345, -drop / 2 + 1.5, 65)) * CFrame.Angles(0, math.pi, slope)
	hull(sm, tankerCF, 110, 32, 22, rng, { cut = 30, frames = 3 })
	-- the winch that hauled her up, its chain to her stern
	part(sm, "HaulWinch", Vector3.new(8, 6, 10), P(270, 3, 65), Metal, rgb(70, 96, 90))
	cylinder(sm, "WinchDrum", 8, 5, CFrame.new(P(270, 7, 65)) * CFrame.Angles(0, math.pi / 2, 0), Metal, RUST)
	for i = 0, 5 do
		deco(part(sm, "HaulLink", Vector3.new(4, 0.8, 1.6), CFrame.new(P(276 + i * 4, 3, 65)) * CFrame.Angles(if i % 2 == 0 then 0 else math.pi / 2, 0, 0), Rust, RUST))
	end
	-- her bow, cut off, lying on the quay; chunks of hull; a propeller
	local bowCF = CFrame.new(P(330, 0, -30)) * CFrame.Angles(0, 0.4, 0)
	part(sm, "BowChunk", Vector3.new(20, 18, 26), bowCF * CFrame.new(0, 9, 0), Metal, rgb(40, 50, 70))
	part(sm, "BowStem", Vector3.new(4, 18, 8), bowCF * CFrame.new(12, 9, 0), Metal, rgb(40, 50, 70))
	deco(part(sm, "BowRed", Vector3.new(20.2, 6, 26.2), bowCF * CFrame.new(0, 3, 0), Rust, rgb(140, 50, 40)))
	for _ = 1, 4 do
		local c = CFrame.new(P(rng:NextNumber(290, 380), 0, rng:NextNumber(-90, -50))) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0)
		part(sm, "HullChunk", Vector3.new(rng:NextNumber(8, 16), rng:NextNumber(5, 10), rng:NextNumber(4, 8)), c * CFrame.new(0, 3, 0) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, 0), Metal, pick({ rgb(40, 50, 70), rgb(140, 50, 40), rgb(96, 90, 80) }, rng))
	end
	local prop = model(sm, "Propeller")
	local pc = P(300, 7.4, 5)
	cylinder(prop, "PropHub", 3, 3.6, CFrame.new(pc) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(170, 140, 70))
	for k = 0, 3 do
		local a = k / 4 * TAU
		part(prop, "PropBlade", Vector3.new(0.6, 6.4, 3.6), CFrame.new(pc) * CFrame.Angles(0, 0, a) * CFrame.new(0, 3.6, 0) * CFrame.Angles(0, 0.4, 0), Metal, rgb(180, 150, 80))
	end
	turn(prop, pc, CFrame.Angles(0.2, 0, 0))
	-- scrap sorted in heaps, under tarps some of them; gas bottles
	for k = 0, 3 do
		local c = P(300 + k * 22, 0, -110)
		for _ = 1, 8 do
			part(sm, "Scrap", Vector3.new(rng:NextNumber(1, 5), rng:NextNumber(0.3, 1.2), rng:NextNumber(1, 5)), CFrame.new(c + Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(0.4, 3), rng:NextNumber(-5, 5))) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), pick({ Rust, Metal }, rng), pick({ RUST, rgb(96, 96, 92), rgb(40, 50, 70) }, rng))
		end
		if k % 2 == 0 then
			Wind.cloth(sm, c + Vector3.new(-6, 4, -5.5), c + Vector3.new(6, 4, -5.5), 3.5, Vector3.new(0, 0, -1), rng, { name = "Tarp", color = pick(Wind.TARPS, rng), tattered = true })
		end
	end
	for k = 0, 4 do
		cylinder(sm, "GasBottle", 3, 1.2, CFrame.new(P(282 + k * 1.4, 1.5, -60)) * UPRIGHT, Metal, pick({ rgb(60, 90, 150), rgb(190, 60, 44), rgb(60, 120, 70) }, rng))
	end
	sparks(sm, P(320, 12, 50))
	task.wait()

	-- the rest: warehouses, the rail siding, the office, floodlights
	local om = model(root, "Buildings")
	warehouse(om, O, 15, 72, ZS + 6, ZS + 38, rng)
	warehouse(om, O, 80, 138, ZS + 6, ZS + 38, rng)
	warehouse(om, O, 15, 72, -150, -118, rng)
	officeTower(om, O, 26, 70, rng)
	local rm = model(root, "Siding")
	for _, dz in ipairs({ -2.4, 2.4 }) do
		rod(rm, "Rail", P(15, 0.3, RAIL_Z + dz), P(W - 20, 0.3, RAIL_Z + dz), 0.4, Metal, STEEL)
	end
	for x = 16, W - 22, 4 do
		deco(part(rm, "Sleeper", Vector3.new(1.2, 0.3, 7), P(x, 0.15, RAIL_Z), Wood, rgb(80, 64, 50)))
	end
	for k = 0, 3 do
		local wx = 60 + k * 50
		local derailed = k == 3
		local wcf = CFrame.new(P(wx, 1.6, RAIL_Z + (if derailed then 6 else 0))) * (if derailed then CFrame.Angles(0.25, 0.15, 0) else CFrame.identity)
		local wm = model(rm, "Wagon")
		part(wm, "WagonBed", Vector3.new(46, 1.2, 8), wcf, Metal, rgb(70, 60, 50))
		for _, dx in ipairs({ -16, 16 }) do
			for _, dz in ipairs({ -2.4, 2.4 }) do
				cylinder(wm, "WagonWheel", 0.5, 2.2, wcf * CFrame.new(dx, -0.6, dz) * CFrame.Angles(0, math.pi / 2, 0), Metal, DARK)
			end
		end
		if rng:NextNumber() < 0.75 then
			container(wm, wcf * CFrame.new(0, 0.6, 0), rng, false)
		end
	end
	for _, f in ipairs({ { 48, -92 }, { 272, -92 }, { 48, 124 }, { 272, 124 }, { 145, -222 }, { 388, -100 }, { 388, 182 } }) do
		floodlight(om, P(f[1], 0, f[2]), rng)
	end
	-- a sign at the top of the quay, where you come in
	local sg = P(52, 0, -30)
	for _, dz in ipairs({ -5, 5 }) do
		rod(om, "SignPost", sg + Vector3.new(0, 0, dz), sg + Vector3.new(0, 11, dz), 0.4, Metal, STEEL)
	end
	part(om, "SignBoard", Vector3.new(0.4, 4, 12), sg + UP * 9, Smooth, rgb(40, 60, 110))
	label(om, CFrame.lookAt(sg + UP * 9 - Vector3.new(0.25, 0, 0), sg + UP * 9 - Vector3.new(2, 0, 0)), Vector3.new(11, 3.4, 0.05), Enum.NormalId.Front, "東港 第三埠頭", rgb(40, 60, 110), rgb(240, 240, 236), Smooth, Enum.Font.GothamBold).Transparency = 1
end

return Port
