-- The west crossing: out of a hole torn in the far wall of the school's
-- west stairwell on the top floor, and across the drop to the stilt town
-- (StiltTown.lua).
--
-- Four hubs stand out of the fog on the way over: squat concrete piers
-- (or one with a water tank on top), each with a steel deck round it low
-- down and a concrete top higher up, a caged ladder between, and a mast
-- above. Between each pair of hubs, and from the school to the first and
-- the last to the town, two heavy cables sag; everything between hangs
-- from them.
--
-- Routes run hub to hub: a low one from the hole in the wall along the
-- low decks, a high one from the girder above it along the tops, and two
-- that cross over from one to the other, arriving at different platforms
-- of the town. And a third way, from the broken west end of the Kannon's
-- railway far below, climbing through four hubs of its own (S1 to S4) to
-- the town's southern side: the long way up. Each leg is a chain of parkour pieces (CrossingPieces.lua)
-- planned from one hub to the next, turning towards it on junction plates
-- as it goes, climbing or dropping where it needs to, each piece checked
-- clear of everything else before it's placed; if a leg can't be made,
-- it's planned again.
--
-- The moves (zip lines, ropes, crumbling, steam) run in Traversal.client;
-- the moving platforms (cages, gondolas, lifts) in Movers.client, which
-- carries you along with them.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local TunnelProps = require(script.Parent.TunnelProps)
local StiltTown = require(script.Parent.StiltTown)
local Pieces = require(script.Parent.CrossingPieces)
local Dress = require(script.Parent.CrossingDressing)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local rod, deco, box, truss = Pieces.rod, Pieces.deco, Pieces.box, Pieces.truss
local Metal, Rust, Plate, Smooth, Concrete, Neon, Glass = Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Neon, Enum.Material.Glass
local rgb = Color3.fromRGB
local UP = Vector3.yAxis
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local WEST = Vector3.new(-1, 0, 0)

local GALV = rgb(142, 146, 146)
local CONCRETE = rgb(150, 146, 138)
local YELLOW = rgb(214, 170, 46)
local DARK = rgb(34, 34, 36)
local SODIUM = rgb(255, 176, 90)
local DEEP = -700

local FACE_X = -Config.STAIRWELL_LENGTH - 0.5
local HOLE_Y = Config.TOP_Y
local ROOF_Y = Config.TOP_Y + Config.WALL_HEIGHT + 1.7

local WestCrossing = {}

-- ===== Keeping clear =====

local taken = {}

-- Do two of CrossingPieces' boxes overlap (with `pad` to spare)? Height
-- ranges first, then the separating-axis test on their four sides.
local function overlaps(a, b, pad)
	pad = pad or 0
	if a.y1 + pad < b.y0 or b.y1 + pad < a.y0 then
		return false
	end
	local d = b.c - a.c
	for _, n in ipairs({ a.r, a.l, b.r, b.l }) do
		local ra = a.ex * math.abs(a.r:Dot(n)) + a.ez * math.abs(a.l:Dot(n))
		local rb = b.ex * math.abs(b.r:Dot(n)) + b.ez * math.abs(b.l:Dot(n))
		if math.abs(d:Dot(n)) > ra + rb + pad then
			return false
		end
	end
	return true
end

local function freeOf(boxes, extra)
	for _, b in ipairs(boxes) do
		for _, t in ipairs(taken) do
			if overlaps(b, t, 0.5) then
				return false
			end
		end
		for _, t in ipairs(extra or {}) do
			if overlaps(b, t, 0.5) then
				return false
			end
		end
	end
	return true
end

-- ===== The cables everything hangs from =====

local spans = {}
local hangers = {} -- (where hangers are already, so they're not crowded)

local function cablePoint(sp, t, s)
	local a, b = sp.a, sp.b
	local side = Vector3.new(-(b - a).Unit.Z, 0, (b - a).Unit.X).Unit
	local p = a:Lerp(b, t) + side * s * 7
	return p - UP * (sp.sag * 4 * t * (1 - t))
end

-- A hanger from `p` up to the nearest cable above it (if there is one).
local function hang(m, p)
	local best, bd, bt, bs
	for _, sp in ipairs(spans) do
		local a, b = Vector3.new(sp.a.X, 0, sp.a.Z), Vector3.new(sp.b.X, 0, sp.b.Z)
		local ab = b - a
		local t = math.clamp((Vector3.new(p.X, 0, p.Z) - a):Dot(ab) / ab:Dot(ab), 0, 1)
		for _, s in ipairs({ -1, 1 }) do
			local c = cablePoint(sp, t, s)
			local d = Vector3.new(c.X - p.X, 0, c.Z - p.Z).Magnitude
			if not bd or d < bd then
				best, bd, bt, bs = sp, d, t, s
			end
		end
	end
	if not best then
		return
	end
	local c = cablePoint(best, bt, bs)
	if c.Y - p.Y < 4 then
		return
	end
	-- Not too many: one near enough to another will do (and the long ones
	-- down to the low pieces, the ones that clutter the sky, fewer still).
	local gap = if c.Y - p.Y > 40 then 18 else 8
	for _, q in ipairs(hangers) do
		if (q - p).Magnitude < gap then
			return
		end
	end
	table.insert(hangers, p)
	deco(rod(m, "Hanger", p, c, 0.22, Metal, GALV))
	deco(part(m, "HangerClamp", Vector3.new(0.6, 0.6, 0.6), p, Metal, DARK))
end

local function drawCables(parent, rng)
	local m = model(parent, "Cables")
	for _, sp in ipairs(spans) do
		for _, s in ipairs({ -1, 1 }) do
			local n = 24
			local prev = cablePoint(sp, 0, s)
			for i = 1, n do
				local p = cablePoint(sp, i / n, s)
				deco(rod(m, "Cable", prev, p, 0.9, Metal, rgb(58, 58, 60)))
				prev = p
			end
		end
		-- things caught on them
		for _ = 1, rng:NextInteger(1, 3) do
			Dress.cable(m, cablePoint(sp, rng:NextNumber(0.15, 0.85), pick({ -1, 1 }, rng)), rng)
		end
	end
end

-- ===== Hubs =====

-- A pier: a concrete column out of the fog, a steel deck round it low
-- down, a concrete top, a caged ladder between, a mast (or a water tank)
-- on top to take the cables. Sockets on every side of both decks.
local function hub(parent, name, x, z, low, high, kind, rng)
	local m = model(parent, "Hub")
	local h = { x = x, z = z, low = low, high = high, kind = kind, used = {}, model = m }
	-- the column, weathered in bands, moss, a big number
	part(m, "Column", Vector3.new(12, high - 2 - DEEP, 12), Vector3.new(x, (high - 2 + DEEP) / 2, z), Concrete, jitter(CONCRETE, rng, 0.04))
	for y = low - 60, high - 6, 9 do
		if rng:NextNumber() < 0.5 then
			deco(part(m, "Stain", Vector3.new(12.1, rng:NextNumber(1, 4), 12.1), Vector3.new(x, y, z), Concrete, darken(CONCRETE, rng:NextNumber(0.75, 0.9))))
		end
	end
	for _ = 1, 10 do
		local side = pick({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }, rng)
		local p = Vector3.new(x, rng:NextNumber(low - 50, high - 4), z) + side * 6.05 + Vector3.new(side.Z, 0, side.X) * rng:NextNumber(-4, 4)
		deco(ellipsoid(m, "Moss", Vector3.new(rng:NextNumber(2, 5), rng:NextNumber(3, 7), 0.6), CFrame.lookAt(p, p + side), Enum.Material.LeafyGrass, jitter(rgb(80, 110, 60), rng, 0.15)))
	end
	label(m, CFrame.new(x + 6.05, low + 12, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(7, 5, 0.05), Enum.NormalId.Back, name, CONCRETE, rgb(230, 226, 214), Smooth, Enum.Font.GothamBlack).Transparency = 1
	-- the low deck: a steel ring round the column on brackets
	local R = 11
	for _, e in ipairs({ { 0, -8.5, 22, 5 }, { 0, 8.5, 22, 5 }, { -8.5, 0, 5, 12 }, { 8.5, 0, 5, 12 } }) do
		part(m, "LowDeck", Vector3.new(e[3], 0.5, e[4]), Vector3.new(x + e[1], low - 0.25, z + e[2]), Plate, jitter(rgb(92, 92, 88), rng, 0.05))
	end
	part(m, "LowDeckFrame", Vector3.new(22.6, 0.8, 22.6), Vector3.new(x, low - 0.9, z), Metal, GALV).Transparency = 0
	for _, d in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
		for _, s in ipairs({ -1, 1 }) do
			local across = Vector3.new(d.Z, 0, d.X) * s * 4
			local a = Vector3.new(x, low - 7, z) + d * 6 + across
			local b = Vector3.new(x, low - 1.2, z) + d * (R - 0.5) + across
			deco(rod(m, "Bracket", a, b, 0.7, Metal, GALV))
		end
	end
	-- the concrete top, a steel lip round it
	part(m, "Top", Vector3.new(20, 2, 20), Vector3.new(x, high - 1, z), Concrete, jitter(CONCRETE, rng, 0.03))
	for _, e in ipairs({ { 0, -10.5, 22, 1 }, { 0, 10.5, 22, 1 }, { -10.5, 0, 1, 20 }, { 10.5, 0, 1, 20 } }) do
		part(m, "TopLip", Vector3.new(e[3], 0.5, e[4]), Vector3.new(x + e[1], high - 0.25, z + e[2]), Plate, rgb(92, 92, 88))
	end
	-- the caged ladder between, on the south side
	local lz = z - R - 0.3
	truss(m, Vector3.new(x + 3, low, lz), Vector3.new(x + 3, high + 3, lz), true, YELLOW)
	for y = low + 7, high, 2.2 do
		for _, s in ipairs({ -1, 1 }) do
			deco(rod(m, "Hoop", Vector3.new(x + 3 + s * 1.6, y, lz), Vector3.new(x + 3 + s * 1.6, y, lz - 1.8), 0.14, Metal, YELLOW))
		end
		deco(rod(m, "Hoop", Vector3.new(x + 1.4, y, lz - 1.8), Vector3.new(x + 4.6, y, lz - 1.8), 0.14, Metal, YELLOW))
	end
	-- a hut on the top, a lamp
	part(m, "Hut", Vector3.new(6, 6, 5), Vector3.new(x - 5, high + 3, z + 5.5), Rust, pick({ rgb(120, 110, 96), rgb(90, 110, 120), rgb(150, 70, 50) }, rng))
	part(m, "HutRoof", Vector3.new(6.6, 0.3, 5.6), Vector3.new(x - 5, high + 6.2, z + 5.5), Metal, DARK)
	-- the mast, or a water tank, to hang the cables from
	local anchorY
	if kind == "tank" then
		for _, o in ipairs({ { -4, -4 }, { 4, -4 }, { 4, 4 }, { -4, 4 } }) do
			rod(m, "TankLeg", Vector3.new(x + o[1], high, z + o[2]), Vector3.new(x + o[1] * 0.8, high + 14, z + o[2] * 0.8), 1, Rust, rgb(116, 76, 50))
		end
		local tc = pick({ rgb(90, 120, 140), rgb(160, 150, 130) }, rng)
		cylinder(m, "Tank", 12, 14, CFrame.new(x, high + 20, z) * UPRIGHT, Metal, tc)
		cylinder(m, "TankRoof", 1, 15, CFrame.new(x, high + 26.5, z) * UPRIGHT, Metal, darken(tc, 0.8))
		label(m, CFrame.new(x + 7.05, high + 20, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(6, 3, 0.05), Enum.NormalId.Back, "給水", tc, rgb(236, 232, 222), Smooth, Enum.Font.GothamBlack).Transparency = 1
		anchorY = high + 26
	else
		for _, o in ipairs({ { -2.5, -2.5 }, { 2.5, -2.5 }, { 2.5, 2.5 }, { -2.5, 2.5 } }) do
			rod(m, "MastLeg", Vector3.new(x + o[1], high, z + o[2]), Vector3.new(x + o[1] * 0.4, high + 40, z + o[2] * 0.4), 0.6, Metal, GALV)
		end
		for y = high + 4, high + 36, 6 do
			local f = 1 - 0.6 * (y - high) / 40
			for k, o in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
				local n = ({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } })[k % 4 + 1]
				deco(rod(m, "MastBrace", Vector3.new(x + o[1] * 2.5 * f, y, z + o[2] * 2.5 * f), Vector3.new(x + n[1] * 2.5 * f, y + 6, z + n[2] * 2.5 * f), 0.25, Metal, GALV))
			end
		end
		local beacon = deco(part(m, "Beacon", Vector3.new(1, 1, 1), Vector3.new(x, high + 41, z), Neon, rgb(220, 60, 40)))
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = rgb(255, 80, 60), 16, 1
		l.Parent = beacon
		anchorY = high + 36
	end
	part(m, "CableAnchor", Vector3.new(3, 2, 3), Vector3.new(x, anchorY, z), Metal, DARK)
	h.anchor = Vector3.new(x, anchorY, z)
	-- sodium lamps on each deck, to find them by
	for _, y in ipairs({ low, high }) do
		local p = Vector3.new(x + 8, y, z + 8)
		rod(m, "LampPost", p, p + UP * 7, 0.35, Metal, GALV)
		local b = deco(part(m, "Lamp", Vector3.new(1.4, 0.8, 1.4), p + UP * 7.2, Neon, SODIUM))
		local pl = Instance.new("PointLight")
		pl.Color, pl.Range, pl.Brightness = SODIUM, 26, 1.3
		pl.Parent = b
	end
	-- sockets: [deck][side] = CFrame at the edge, looking outwards
	local function sock(y, d, zo, halfW)
		local p = Vector3.new(x, y, z) + d * (halfW - 0.3) + Vector3.new(0, 0, zo)
		return CFrame.lookAt(p, p + d)
	end
	h.sockets = {
		low = { W = sock(low, WEST, -5, R), E = sock(low, -WEST, -5, R), N = sock(low, Vector3.new(0, 0, 1), 0, R), S = sock(low, Vector3.new(0, 0, -1), 0, R) },
		high = { W = sock(high, WEST, 5, R), E = sock(high, -WEST, 5, R), N = sock(high, Vector3.new(0, 0, 1), 0, R), S = sock(high, Vector3.new(0, 0, -1), 0, R) },
	}
	-- (N/S ones keep off the ladder on the south side)
	h.sockets.low.S = sock(low, Vector3.new(0, 0, -1), 0, R) * CFrame.new(-5, 0, 0)
	h.sockets.high.S = sock(high, Vector3.new(0, 0, -1), 0, R) * CFrame.new(-5, 0, 0)
	table.insert(taken, box(CFrame.new(x, (low - 12 + high + 45) / 2, z), Vector3.new(22, high + 45 - (low - 12), 22)))
	Dress.hub(h, rng)
	return h
end

-- An arriving socket: at that edge, looking into the hub.
local function arrive(cf)
	return CFrame.lookAt(cf.Position, cf.Position - cf.LookVector)
end

-- Rails round a hub's decks, gaps where routes come and go.
local function hubRails(h)
	local m = h.model
	for _, deck in ipairs({ "low", "high" }) do
		local y = if deck == "low" then h.low else h.high
		local half = 10.9
		local gaps = {}
		for key in pairs(h.used) do
			local d, sd = key:match("(%a+)%.(%a)")
			if d == deck then
				table.insert(gaps, h.sockets[d][sd].Position)
			end
		end
		table.insert(gaps, Vector3.new(h.x + 3, y, h.z - half)) -- the ladder
		local corners = { Vector3.new(h.x - half, y, h.z - half), Vector3.new(h.x + half, y, h.z - half), Vector3.new(h.x + half, y, h.z + half), Vector3.new(h.x - half, y, h.z + half) }
		for k = 1, 4 do
			local a, b = corners[k], corners[k % 4 + 1]
			local n = math.floor((b - a).Magnitude / 2)
			local prev = nil
			for j = 0, n do
				local p = a:Lerp(b, j / n)
				local open = false
				for _, g in ipairs(gaps) do
					if (Vector3.new(g.X, 0, g.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude < 3.4 then
						open = true
					end
				end
				if open then
					prev = nil
				else
					if deck == "high" then
						if prev then
							part(m, "Parapet", Vector3.new(0.8, 1.2, (p - prev).Magnitude + 0.8), CFrame.lookAt((p + prev) / 2 + UP * 0.6, p + UP * 0.6), Concrete, CONCRETE)
						end
					else
						rod(m, "RailPost", p, p + UP * 3.4, 0.2, Metal, YELLOW)
						if prev then
							rod(m, "RailTop", prev + UP * 3.3, p + UP * 3.3, 0.24, Metal, YELLOW)
							rod(m, "RailMid", prev + UP * 1.7, p + UP * 1.7, 0.18, Metal, YELLOW)
						end
					end
					prev = p
				end
			end
		end
	end
end

-- ===== Routes =====

local function weighted(pool, rng, avoid)
	local total = 0
	for k, w in pairs(pool) do
		total += if k == avoid then w * 0.15 else w
	end
	local r = rng:NextNumber(0, total)
	local names = {}
	for k in pairs(pool) do
		table.insert(names, k)
	end
	table.sort(names)
	for _, k in ipairs(names) do
		local w = if k == avoid then pool[k] * 0.15 else pool[k]
		r -= w
		if r <= 0 then
			return k
		end
	end
	return names[1]
end

local function flatDist(a, b)
	return Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
end

-- Plan a chain of pieces from socket S to arriving socket T. Returns the
-- plans (not built yet), or nil if it couldn't.
local function planLeg(S, T, ctx, rng)
	local plans, held = {}, {}
	local function take(plan)
		table.insert(plans, plan)
		for _, b in ipairs(plan.boxes) do
			table.insert(held, b)
		end
	end
	local cur, last = S, nil
	local wobble = rng:NextNumber(-24, 24)
	local across = Vector3.new(-T.LookVector.Z, 0, T.LookVector.X)
	for _ = 1, 16 do
		local fin = Pieces.walkTo(cur, T, ctx) or Pieces.zipTo(cur, T, ctx)
		if fin and freeOf(fin.boxes, held) then
			take(fin)
			return plans
		end
		-- steer for a point out in front of the target, so the last stretch
		-- comes in straight (and off to one side a bit, differently each try)
		local far = flatDist(cur.Position, T.Position)
		local aim = if far < 24 then T.Position else T.Position - T.LookVector * 14 + across * wobble * math.min(1, (far - 24) / 60)
		local pv = Pieces.pivot(cur, aim, ctx)
		if pv and freeOf(pv.boxes, held) then
			take(pv)
			cur = pv.exit
			fin = Pieces.walkTo(cur, T, ctx) or Pieces.zipTo(cur, T, ctx)
			if fin and freeOf(fin.boxes, held) then
				take(fin)
				return plans
			end
		end
		local dy = T.Position.Y - cur.Position.Y
		local run = flatDist(cur.Position, T.Position)
		local pool = Pieces.LEVEL
		if dy > 16 or (dy > 8 and run < dy * 4) then
			pool = Pieces.UP
		elseif dy < -16 or (dy < -8 and run < -dy * 4) then
			pool = Pieces.DOWN
		end
		ctx.need = dy
		ctx.lean = math.clamp(dy / math.max(run, 1) * 4, -1, 1)
		local chosen
		for try = 1, 24 do
			local kind = weighted(if try <= 16 then pool else Pieces.LEVEL, rng, last)
			local plan = Pieces.defs[kind](cur, ctx, rng)
			if plan and freeOf(plan.boxes, held) then
				local after = plan.exit.Position
				local run2 = flatDist(after, T.Position)
				local dy2 = T.Position.Y - after.Y
				local ok
				if pool == Pieces.UP then
					ok = math.abs(dy2) < math.abs(dy) - 6 and run2 > 6
				elseif pool == Pieces.DOWN then
					ok = math.abs(dy2) < math.abs(dy) - 4 and run2 > 6
				else
					ok = run2 < run - 8 and run2 > 8
				end
				if ok then
					chosen = plan
					last = kind
					break
				end
			end
		end
		if not chosen then
			return nil
		end
		take(chosen)
		cur = chosen.exit
	end
	return nil
end

local function buildLeg(parent, name, plans)
	local m = model(parent, name)
	for _, plan in ipairs(plans) do
		plan.build(model(m, "Piece"))
		for _, b in ipairs(plan.boxes) do
			table.insert(taken, b)
		end
	end
	return m
end

-- ===== The start: the hole in the wall =====

local function breach(parent, rng)
	local m = model(parent, "WestBreach")
	part(m, "BrokenSlab", Vector3.new(9, 1.2, 10), CFrame.new(FACE_X - 4, HOLE_Y - 0.6, 0) * CFrame.Angles(0, 0, math.rad(-3)), Concrete, rgb(140, 138, 130))
	for _ = 1, 8 do
		local zz = rng:NextNumber(-4.5, 4.5)
		local a = Vector3.new(FACE_X - 8.4, HOLE_Y - 0.7, zz)
		deco(rod(m, "Rebar", a, a + Vector3.new(-rng:NextNumber(1, 3), rng:NextNumber(-2, 1), rng:NextNumber(-1, 1)), 0.2, Rust, rgb(116, 76, 50)))
	end
	local gz = 4.2
	truss(m, Vector3.new(FACE_X - 1.4, HOLE_Y, gz - 2.5), Vector3.new(FACE_X - 1.4, ROOF_Y + 2, gz - 2.5), true, rgb(110, 110, 104))
	part(m, "Girder", Vector3.new(12, 1.2, 2.6), Vector3.new(FACE_X - 6, ROOF_Y - 0.4, gz), Rust, rgb(116, 76, 50))
	label(m, CFrame.new(FACE_X + 0.3, HOLE_Y + 11, -5) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(5, 1.5, 0.1), Enum.NormalId.Front, "この先 危険", rgb(236, 232, 222), rgb(170, 30, 26), Smooth, Enum.Font.PermanentMarker).Transparency = 1
	-- the cables' anchor on the stairwell roof
	for _, o in ipairs({ { 2, -4 }, { 2, 4 }, { 8, 0 } }) do
		rod(m, "AnchorMast", Vector3.new(FACE_X + o[1], ROOF_Y, o[2]), Vector3.new(FACE_X + 3, ROOF_Y + 32, 0), 0.8, Metal, GALV)
	end
	part(m, "CableAnchor", Vector3.new(3, 2, 3), Vector3.new(FACE_X + 3, ROOF_Y + 32, 0), Metal, DARK)
	local slab = CFrame.lookAt(Vector3.new(FACE_X - 8.4, HOLE_Y, 0), Vector3.new(FACE_X - 9.4, HOLE_Y, 0))
	local girder = CFrame.lookAt(Vector3.new(FACE_X - 11.8, ROOF_Y + 0.2, gz), Vector3.new(FACE_X - 12.8, ROOF_Y + 0.2, gz))
	table.insert(taken, box(CFrame.new(FACE_X + 10, 0, 0), Vector3.new(20, 400, 120)))
	return slab, girder, Vector3.new(FACE_X + 3, ROOF_Y + 32, 0)
end

-- ===== Assembly =====

function WestCrossing.build(parent, rng)
	taken, spans, hangers = {}, {}, {}
	local plats = StiltTown.build(parent, rng)
	local root = model(parent, "WestCrossing")
	local slab, girder, schoolAnchor = breach(root, rng)

	-- The town's platforms keep their space; the nearest ones are where
	-- routes arrive.
	local arrivals = {}
	for _, p in ipairs(plats) do
		table.insert(taken, box(CFrame.new((p.x0 + p.x1) / 2, p.y + 4, (p.z0 + p.z1) / 2), Vector3.new(p.x1 - p.x0 - 3, 20, p.z1 - p.z0 - 3)))
		if p.arrive then
			table.insert(arrivals, p)
		end
	end
	-- (and the town's pylons, bridges and cable cars keep theirs)
	for _, b in ipairs(StiltTown.BLOCKS) do
		table.insert(taken, box(CFrame.new(b.c), b.s))
	end
	table.sort(arrivals, function(a, b)
		return a.x1 > b.x1
	end)
	local function townSocket(k)
		local p = arrivals[math.clamp(k, 1, #arrivals)]
		local z = math.clamp((p.z0 + p.z1) / 2 + (k - 1.5) * 6, p.z0 + 5, p.z1 - 5)
		return CFrame.lookAt(Vector3.new(p.x1 - 0.3, p.y, z), Vector3.new(p.x1 - 1.3, p.y, z)), p
	end

	-- The hubs, stepping up and out, side to side.
	local hubs = {}
	local zSide = pick({ -1, 1 }, rng)
	local lows = { 34, 52, 70, 88 }
	for i = 1, 4 do
		local x = -125 - (i - 1) * 105 + rng:NextNumber(-8, 8)
		local z = zSide * rng:NextNumber(25, 55)
		zSide = -zSide
		local low = lows[i] + rng:NextNumber(-4, 4)
		local high = low + rng:NextNumber(28, 34)
		table.insert(hubs, hub(root, "W" .. i, x, z, low, high, if i == 3 then "tank" else "pier", rng))
		task.wait()
	end
	-- The cables: school to the first hub, hub to hub, the last to the town.
	local _, gatePlat = townSocket(1)
	local townAnchor = Vector3.new(StiltTown.GATE.x1 - 8, StiltTown.GATE.y + 30, (StiltTown.GATE.z0 + StiltTown.GATE.z1) / 2)
	local mastM = model(root, "TownMast")
	rod(mastM, "TownMast", Vector3.new(townAnchor.X, StiltTown.GATE.y, townAnchor.Z), townAnchor, 1, Metal, GALV)
	local anchors = { schoolAnchor }
	for _, h in ipairs(hubs) do
		table.insert(anchors, h.anchor)
	end
	table.insert(anchors, townAnchor)
	for k = 1, #anchors - 1 do
		table.insert(spans, { a = anchors[k], b = anchors[k + 1], sag = (anchors[k + 1] - anchors[k]).Magnitude * 0.1 })
	end

	-- The south way: from the railway's broken end, up through its own hubs.
	local VIADUCT_END = Vector3.new(94, -108, -360) -- (Kannon: the west end, broken off)
	table.insert(taken, box(CFrame.new(315, -105, -362), Vector3.new(510, 40, 20)))
	table.insert(taken, box(CFrame.new(330, 0, -360), Vector3.new(240, 900, 240)))
	local south = {}
	local sLows = { -75, -25, 25, 75 }
	local sx = { 5, -115, -235, -355 }
	local sz = { -300, -330, -290, -235 }
	for i = 1, 4 do
		local low = sLows[i] + rng:NextNumber(-4, 4)
		table.insert(south, hub(root, "S" .. i, sx[i] + rng:NextNumber(-8, 8), sz[i] + rng:NextNumber(-12, 12), low, low + rng:NextNumber(28, 32), if i == 2 then "tank" else "pier", rng))
		task.wait()
	end
	local viaductStart = CFrame.lookAt(VIADUCT_END + Vector3.new(10, 0, 9.2), VIADUCT_END + Vector3.new(10, 0, 10.2))
	local vm = model(root, "ViaductMast")
	local vAnchor = VIADUCT_END + Vector3.new(22, 26, 10)
	rod(vm, "Mast", VIADUCT_END + Vector3.new(22, 0, 10), vAnchor, 1, Metal, GALV)
	part(vm, "CableAnchor", Vector3.new(2.4, 1.6, 2.4), vAnchor, Metal, DARK)
	-- the southern platform of the town they come up to
	local southPlat, southK = nil, 1
	for k, p in ipairs(arrivals) do
		if not southPlat or (p.z0 + p.z1) < (southPlat.z0 + southPlat.z1) then
			southPlat, southK = p, k
		end
	end
	local sAnchor = Vector3.new((southPlat.x0 + southPlat.x1) / 2 + 8, southPlat.y + 28, southPlat.z0 + 6)
	rod(vm, "TownMast", Vector3.new(sAnchor.X, southPlat.y, sAnchor.Z), sAnchor, 1, Metal, GALV)
	local sAnchors = { vAnchor }
	for _, h in ipairs(south) do
		table.insert(sAnchors, h.anchor)
	end
	table.insert(sAnchors, sAnchor)
	for k = 1, #sAnchors - 1 do
		table.insert(spans, { a = sAnchors[k], b = sAnchors[k + 1], sag = (sAnchors[k + 1] - sAnchors[k]).Magnitude * 0.1 })
	end
	drawCables(root, rng)

	local ctx = { rng = rng, hang = hang }
	-- The legs.
	local legs = {}
	local function leg(name, fromCF, fromKey, toHub, deck, side, toTown)
		table.insert(legs, { name = name, S = fromCF, fromKey = fromKey, hub = toHub, deck = deck, side = side, town = toTown })
	end
	-- (per span, the high one first: the low one's tall pieces, a rope's
	-- pivot, a gondola's rail, would otherwise poke up into its way)
	leg("High1", girder, nil, hubs[1], "high", "E")
	leg("Low1", slab, nil, hubs[1], "low", "E")
	for i = 1, 3 do
		leg("High" .. (i + 1), hubs[i].sockets.high.W, { hubs[i], "high.W" }, hubs[i + 1], "high", "E")
		leg("Low" .. (i + 1), hubs[i].sockets.low.W, { hubs[i], "low.W" }, hubs[i + 1], "low", "E")
	end
	leg("HighTown", hubs[4].sockets.high.W, { hubs[4], "high.W" }, nil, nil, nil, 2)
	leg("LowTown", hubs[4].sockets.low.W, { hubs[4], "low.W" }, nil, nil, nil, 1)
	-- the crossovers
	local sa = if hubs[2].z < hubs[1].z then "S" else "N"
	leg("Cross1", hubs[1].sockets.high[sa], { hubs[1], "high." .. sa }, hubs[2], "low", if sa == "S" then "N" else "S")
	local sb = if hubs[4].z < hubs[3].z then "S" else "N"
	leg("Cross2", hubs[3].sockets.low[sb], { hubs[3], "low." .. sb }, hubs[4], "high", if sb == "S" then "N" else "S")
	-- the south way: off each hub's top, into the next one's low deck
	leg("South1", viaductStart, nil, south[1], "low", "E")
	for i = 1, 3 do
		leg("South" .. (i + 1), south[i].sockets.high.W, { south[i], "high.W" }, south[i + 1], "low", "E")
	end
	leg("SouthTown", south[4].sockets.high.W, { south[4], "high.W" }, nil, nil, nil, southK)
	-- (it comes up to the southern pylon's deck from the south: its east
	-- side is the low route's)
	legs[#legs].target = CFrame.lookAt(Vector3.new((southPlat.x0 + southPlat.x1) / 2, southPlat.y, southPlat.z0 + 0.3), Vector3.new((southPlat.x0 + southPlat.x1) / 2, southPlat.y, southPlat.z0 + 1.3))

	local made, failed = 0, {}
	for _, L in ipairs(legs) do
		local targets, key = {}, nil
		if L.target then
			table.insert(targets, L.target)
		end
		if L.town then
			table.insert(targets, (townSocket(L.town)))
			for k = 1, #arrivals do
				if k ~= L.town then
					table.insert(targets, (townSocket(k)))
				end
			end
		else
			table.insert(targets, arrive(L.hub.sockets[L.deck][L.side]))
			key = L.deck .. "." .. L.side
		end
		local plans
		for _, T in ipairs(targets) do
			for _ = 1, 20 do
				task.wait() -- (it's a lot of checking; let the server breathe)
				plans = planLeg(L.S, T, ctx, rng)
				if plans then
					break
				end
			end
			if plans then
				break
			end
		end
		if plans then
			buildLeg(root, L.name, plans)
			made += 1
			if L.fromKey then
				L.fromKey[1].used[L.fromKey[2]] = true
			end
			if key then
				L.hub.used[key] = true
			end
		else
			table.insert(failed, L.name)
		end
		task.wait()
	end
	for _, h in ipairs(hubs) do
		hubRails(h)
	end
	for _, h in ipairs(south) do
		hubRails(h)
	end
	print(string.format("[WestCrossing] %d of %d legs built%s", made, #legs, if #failed > 0 then " (couldn't make: " .. table.concat(failed, ", ") .. ")" else ""))
end

return WestCrossing
