-- The sunken courtyard beyond the corridor windows: a deep shaft cut down
-- into the megastructure's roof (see Megastructure.lua), walled in by
-- bare, dark, streaked concrete on all four sides (the corridor's building
-- sits on the near wall), floored with cracked concrete slabs. Faded paint
-- marks out a full-size football pitch across the whole floor; rubble, oil
-- drums and puddles lie around, and a huge whale skeleton is curled up on
-- the pitch.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local WhaleSkeleton = require(script.Parent.WhaleSkeleton)
local Clutter = require(script.Parent.RooftopClutter)

local part, cylinder, disc, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.disc, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Concrete, Smooth, Rust, Wood = Enum.Material.Concrete, Enum.Material.SmoothPlastic, Enum.Material.CorrodedMetal, Enum.Material.Wood

local FLOOR = Config.COURTYARD_FLOOR
local X0, X1 = 0, Config.TOTAL_LENGTH
local Z0 = Config.COURTYARD_NEAR_Z
local Z1 = Z0 + Config.COURTYARD_DEPTH
local WALL_T = Config.WING_THICKNESS

local WALL_COLOR = Color3.fromRGB(84, 82, 77)
local POUR_LINE = Color3.fromRGB(66, 64, 60)
local STREAK_DARK = Color3.fromRGB(42, 40, 36)
local STREAK_RUST = Color3.fromRGB(108, 72, 44)
local SLAB_COLOR = Color3.fromRGB(96, 94, 88) -- loose concrete (rubble)
local FLOOR_COLOR = Color3.fromRGB(80, 78, 73)
local CRACK_COLOR = Color3.fromRGB(34, 32, 30)
local WHITE_PAINT = Color3.fromRGB(222, 220, 208)
local RUST_METAL = Color3.fromRGB(112, 74, 46)

local Courtyard = {}

local function slab(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

local function overlay(p, transparency)
	p.Transparency = transparency
	p.CanCollide = false
	p.CastShadow = false
	return p
end

-- ===== Walls =====

-- Formwork pour lines, long water/rust streaks, cracks and grime on a bare
-- concrete wall. `face` is the wall surface; `normal` points into the pit.
-- Everything breaks around `openings` ({center, width, bottom, top}).
-- opts: pourEvery (studs between pour lines), streaks (density scale),
-- baseGrime / topGrime (false to leave those bands off).
local function wallSurface(parent, axis, face, normal, spanStart, spanEnd, yBottom, yTop, rng, openings, opts)
	openings = openings or {}
	opts = opts or {}
	local function box(name, along, height, depth, alongPos, y, offset, color)
		local size, pos = BuildUtil.axisBox(axis, along, height, depth, alongPos, y, face + normal * offset)
		return part(parent, name, size, pos, Smooth, color)
	end
	local function band(name, y0, y1, offset, color, transparency)
		BuildUtil.strip(parent, {
			name = name,
			axis = axis,
			fixed = face + normal * offset,
			spanStart = spanStart,
			spanEnd = spanEnd,
			bottom = y0,
			top = y1,
			thickness = 0.03,
			openings = openings,
			material = Smooth,
			color = color,
			transparency = transparency,
		})
	end
	local function hitsOpening(along, halfWidth, y0, y1)
		for _, o in ipairs(openings) do
			if math.abs(along - o.center) < o.width / 2 + halfWidth + 1 and y0 < o.top + 1 and y1 > o.bottom then
				return true
			end
		end
		return false
	end

	local length = spanEnd - spanStart

	local pourEvery = opts.pourEvery or 6
	local y = yBottom + pourEvery
	while y < yTop - 1 do
		band("PourLine", y - 0.125, y + 0.125, 0.02, POUR_LINE, 0.55)
		y += pourEvery
	end

	local streaks = math.floor(length / 12 * (opts.streaks or 1))
	for i = 1, streaks do
		local w, h = rng:NextNumber(1.5, 9), rng:NextNumber(15, 120)
		local top = rng:NextNumber(yBottom + h, yTop)
		local along = rng:NextNumber(spanStart + w, spanEnd - w)
		if not hitsOpening(along, w / 2, top - h, top) then
			local color = if rng:NextNumber() < 0.3 then STREAK_RUST else STREAK_DARK
			-- Each streak sits a hair further out than the last so overlaps don't flicker.
			overlay(box("WallStreak", w, h, 0.02, along, top - h / 2, 0.04 + i * 0.002, color), rng:NextNumber(0.72, 0.9))
		end
	end

	if opts.baseGrime ~= false then
		band("BaseGrime", yBottom, yBottom + 12, 0.03, Color3.fromRGB(38, 40, 34), 0.55)
	end
	if opts.topGrime ~= false then
		band("TopGrime", yTop - 6, yTop, 0.03, Color3.fromRGB(40, 38, 34), 0.6)
	end

	-- Zigzag cracks running down the wall.
	for _ = 1, rng:NextInteger(3, 8) do
		local along, cy = rng:NextNumber(spanStart + 5, spanEnd - 5), rng:NextNumber(yBottom + 20, yTop - 5)
		local heading = 0
		for _ = 1, rng:NextInteger(6, 14) do
			heading = math.clamp(heading + rng:NextNumber(-0.7, 0.7), -1, 1)
			local len = rng:NextNumber(2, 6)
			local dAlong, dy = math.sin(heading) * len, -math.cos(heading) * len
			local size, pos = BuildUtil.axisBox(axis, 0.2, len, 0.03, along + dAlong / 2, cy + dy / 2, face + normal * 0.09)
			local tilt = if axis == "X" then CFrame.Angles(0, 0, math.atan2(-dAlong, dy)) else CFrame.Angles(math.atan2(dAlong, dy), 0, 0)
			if not hitsOpening(along + dAlong / 2, 0.5, math.min(cy, cy + dy), math.max(cy, cy + dy)) then
				overlay(part(parent, "WallCrack", size, CFrame.new(pos) * tilt, Smooth, CRACK_COLOR), 0.2)
			end
			along += dAlong
			cy += dy
			if cy < yBottom + 1 then
				break
			end
		end
	end
end

-- ===== Floor =====

local function rubblePile(parent, c, rng, size)
	for _ = 1, rng:NextInteger(8, 16) do
		local s = Vector3.new(rng:NextNumber(1, 4), rng:NextNumber(0.6, 2.5), rng:NextNumber(1, 4)) * size
		local offset = Vector3.new(rng:NextNumber(-5, 5) * size, s.Y * 0.3 + rng:NextNumber(0, 1.5) * size, rng:NextNumber(-5, 5) * size)
		part(parent, "Rubble", s, CFrame.new(c + offset) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, math.pi), rng:NextNumber(-0.5, 0.5)), Concrete, jitter(SLAB_COLOR, rng, 0.15))
	end
	for _ = 1, rng:NextInteger(1, 4) do
		local at = c + Vector3.new(rng:NextNumber(-3, 3), 1.5, rng:NextNumber(-3, 3)) * size
		cylinder(parent, "Rebar", rng:NextNumber(4, 9) * size, 0.2, CFrame.new(at) * CFrame.Angles(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0, math.pi), rng:NextNumber(0.4, 1.2)), Rust, RUST_METAL)
	end
end

local function crack(parent, start, rng)
	local heading = rng:NextNumber(0, math.pi * 2)
	local at = start
	for _ = 1, rng:NextInteger(5, 16) do
		heading += rng:NextNumber(-0.6, 0.6)
		local len = rng:NextNumber(1.5, 4)
		local nextAt = at + Vector3.new(math.cos(heading) * len, 0, math.sin(heading) * len)
		if nextAt.X < X0 + 1 or nextAt.X > X1 - 1 or nextAt.Z < Z0 + 1 or nextAt.Z > Z1 - 1 then
			break
		end
		local mid = (at + nextAt) / 2
		overlay(part(parent, "FloorCrack", Vector3.new(0.18, 0.04, len + 0.1), CFrame.lookAt(Vector3.new(mid.X, FLOOR + 0.035, mid.Z), Vector3.new(nextAt.X, FLOOR + 0.035, nextAt.Z)), Smooth, CRACK_COLOR), 0.15)
		at = nextAt
	end
end

local WHALE_CENTER = Vector3.new(X1 - 95, FLOOR, Z1 - 82)
local WHALE_CLEARANCE = 90

local function randomFloorPoint(rng, margin)
	return Vector3.new(rng:NextNumber(X0 + margin, X1 - margin), FLOOR, rng:NextNumber(Z0 + margin, Z1 - margin))
end

-- A floor point that isn't inside the whale skeleton.
local function openFloorPoint(rng, margin)
	local point
	repeat
		point = randomFloorPoint(rng, margin)
	until (point - WHALE_CENTER).Magnitude > WHALE_CLEARANCE
	return point
end

-- One continuous pour of the same plain dark concrete as the walls, with
-- cracks and a few puddles.
local function buildFloor(parent, rng)
	slab(parent, "YardFloor", X0, X1, FLOOR - 5, FLOOR, Z0, Z1, Concrete, FLOOR_COLOR)

	for _ = 1, rng:NextInteger(50, 80) do
		crack(parent, randomFloorPoint(rng, 3), rng)
	end
	for _ = 1, rng:NextInteger(6, 12) do
		local puddle = overlay(disc(parent, "Puddle", rng:NextNumber(4, 12), 0.04, randomFloorPoint(rng, 6) + Vector3.new(0, 0.08, 0), Smooth, Color3.fromRGB(38, 42, 44)), 0.15)
		puddle.Reflectance = 0.35
	end

	-- Rubble heaps where the walls have shed concrete, kept clear of the
	-- goals at the two ends.
	local midZ = (Z0 + Z1) / 2
	for _ = 1, rng:NextInteger(6, 10) do
		local side = rng:NextInteger(1, 4)
		local c
		if side <= 2 then
			local z = if side == 1 then Z0 + rng:NextNumber(4, 14) else Z1 - rng:NextNumber(4, 14)
			c = Vector3.new(rng:NextNumber(X0 + 10, X1 - 10), FLOOR, z)
		else
			local x = if side == 3 then X0 + rng:NextNumber(4, 10) else X1 - rng:NextNumber(4, 10)
			local z = if rng:NextNumber() < 0.5 then rng:NextNumber(Z0 + 10, midZ - 35) else rng:NextNumber(midZ + 35, Z1 - 10)
			c = Vector3.new(x, FLOOR, z)
		end
		local clearOfDoor = (c - Vector3.new(X1, FLOOR, Config.COURTYARD_DOOR_Z)).Magnitude > 22
		if (c - WHALE_CENTER).Magnitude > WHALE_CLEARANCE and clearOfDoor then
			rubblePile(parent, c, rng, rng:NextNumber(0.8, 1.6))
		end
	end

	-- Old oil drums, some knocked over.
	for _ = 1, rng:NextInteger(3, 6) do
		local at = openFloorPoint(rng, 15)
		local color = pick({ RUST_METAL, Color3.fromRGB(60, 70, 60), Color3.fromRGB(70, 50, 44) }, rng)
		if rng:NextNumber() < 0.4 then
			cylinder(parent, "OilDrum", 4, 2.6, CFrame.new(at + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), Rust, color)
		else
			cylinder(parent, "OilDrum", 4, 2.6, CFrame.new(at + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Rust, color)
		end
	end
end

-- ===== Worn markings =====

-- Painted stripe from a to b, broken into short pieces with some worn
-- away entirely and the rest faded to different degrees.
local function paint(parent, a, b, width, color, rng)
	local dir = b - a
	local pieces = math.max(1, math.floor(dir.Magnitude / 6))
	for i = 1, pieces do
		if rng:NextNumber() > 0.15 then
			local p0, p1 = a + dir * ((i - 1) / pieces), a + dir * (i / pieces)
			local mid = (p0 + p1) / 2
			local y = FLOOR + 0.03
			overlay(part(parent, "PaintLine", Vector3.new(width, 0.05, (p1 - p0).Magnitude + 0.05), CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(p1.X, y, p1.Z)), Smooth, color), rng:NextNumber(0.35, 0.7))
		end
	end
end

local function paintArc(parent, center, radius, a0, a1, segments, width, color, rng)
	for i = 1, segments do
		local t0 = a0 + (a1 - a0) * (i - 1) / segments
		local t1 = a0 + (a1 - a0) * i / segments
		paint(parent, center + Vector3.new(math.cos(t0) * radius, 0, math.sin(t0) * radius), center + Vector3.new(math.cos(t1) * radius, 0, math.sin(t1) * radius), width, color, rng)
	end
end

local function paintRect(parent, c, halfX, halfZ, width, color, rng)
	local corners = {
		c + Vector3.new(-halfX, 0, -halfZ),
		c + Vector3.new(halfX, 0, -halfZ),
		c + Vector3.new(halfX, 0, halfZ),
		c + Vector3.new(-halfX, 0, halfZ),
	}
	for i = 1, 4 do
		paint(parent, corners[i], corners[i % 4 + 1], width, color, rng)
	end
end

local function paintSpot(parent, at, color)
	overlay(disc(parent, "PaintSpot", 1.2, 0.05, Vector3.new(at.X, FLOOR + 0.03, at.Z), Smooth, color), 0.4)
end

-- Rusty goal frame on the line at `goalX`, extending outward in direction
-- `s`; only rags of net left, and sometimes blown over.
local function goal(parent, goalX, cz, s, rng)
	local m = model(parent, "Goal")
	local width, height, depth = 28, 9.3, 8
	local upright = CFrame.Angles(0, 0, math.rad(90))
	local alongZ = CFrame.Angles(0, math.rad(90), 0)
	local frame = Color3.fromRGB(150, 120, 96)

	for _, side in ipairs({ -1, 1 }) do
		cylinder(m, "GoalPost", height, 0.45, CFrame.new(goalX, FLOOR + height / 2, cz + side * width / 2) * upright, Rust, frame)
		cylinder(m, "GoalBackPost", height, 0.3, CFrame.new(goalX + s * depth, FLOOR + height / 2, cz + side * width / 2) * upright, Rust, frame)
		cylinder(m, "GoalTopBar", depth, 0.3, CFrame.new(goalX + s * depth / 2, FLOOR + height, cz + side * width / 2), Rust, frame)
	end
	cylinder(m, "Crossbar", width, 0.45, CFrame.new(goalX, FLOOR + height, cz) * alongZ, Rust, frame)
	cylinder(m, "BackBar", width, 0.3, CFrame.new(goalX + s * depth, FLOOR + height, cz) * alongZ, Rust, frame)
	if rng:NextNumber() < 0.5 then
		local rag = rng:NextNumber(2, 6)
		overlay(part(m, "NetRag", Vector3.new(0.1, rng:NextNumber(1.5, 4), rag), Vector3.new(goalX + s * depth, FLOOR + height - 1.5, cz + rng:NextNumber(-width / 2 + rag, width / 2 - rag)), Enum.Material.Fabric, Color3.fromRGB(150, 148, 140)), 0.5)
	end

	if rng:NextNumber() < 0.4 then
		BuildUtil.placeTilted(m, Vector3.new(goalX, FLOOR, cz), 0.3, 0, CFrame.Angles(0, 0, -s * math.rad(84)))
	end
end

-- Full-size pitch filling the courtyard floor, marked out in real
-- proportions (f = studs per metre of a 105m pitch).
local function footballPitch(parent, c, L, W, rng)
	local f = L / 105
	local lw = 0.9
	paintRect(parent, c, L / 2, W / 2, lw, WHITE_PAINT, rng)
	paint(parent, c + Vector3.new(0, 0, -W / 2), c + Vector3.new(0, 0, W / 2), lw, WHITE_PAINT, rng)
	paintArc(parent, c, 9.15 * f, 0, math.pi * 2, 40, lw, WHITE_PAINT, rng)
	paintSpot(parent, c, WHITE_PAINT)

	for _, s in ipairs({ -1, 1 }) do
		local gx = s * L / 2
		local boxDepth = 16.5 * f
		paintRect(parent, c + Vector3.new(gx - s * boxDepth / 2, 0, 0), boxDepth / 2, 20.15 * f, lw, WHITE_PAINT, rng)
		paintRect(parent, c + Vector3.new(gx - s * 2.75 * f, 0, 0), 2.75 * f, 9.15 * f, lw, WHITE_PAINT, rng)

		local penaltySpot = c + Vector3.new(gx - s * 11 * f, 0, 0)
		paintSpot(parent, penaltySpot, WHITE_PAINT)
		-- Only the part of the penalty arc outside the box is painted.
		local facing = if s == 1 then math.pi else 0
		local limit = math.acos(5.5 / 9.15)
		paintArc(parent, penaltySpot, 9.15 * f, facing - limit, facing + limit, 14, lw, WHITE_PAINT, rng)

		for _, sz in ipairs({ -1, 1 }) do
			local a0, a1 = math.atan2(0, -s), math.atan2(-sz, 0)
			if a0 - a1 > math.pi then
				a1 += math.pi * 2
			elseif a1 - a0 > math.pi then
				a1 -= math.pi * 2
			end
			paintArc(parent, c + Vector3.new(gx, 0, sz * W / 2), 1 * f, a0, a1, 4, lw, WHITE_PAINT, rng)
		end

		goal(parent, c.X + gx, c.Z, s, rng)
	end
end

-- ===== Uneven walls =====

-- A wall's run broken into segments of different heights: mostly drifting
-- up and down, now and then jumping. Returns { {a, b, top} }.
local function wallProfile(a, b, lo, hi, rng)
	local segs = {}
	local x = a
	local u = rng:NextNumber()
	while x < b - 0.1 do
		local w = math.min(rng:NextNumber(14, 46), b - x)
		if b - (x + w) < 10 then
			w = b - x
		end
		if rng:NextNumber() < 0.35 then
			u = rng:NextNumber()
		else
			u = math.clamp(u + rng:NextNumber(-0.28, 0.28), 0, 1)
		end
		table.insert(segs, { a = x, b = x + w, top = lo + (hi - lo) * u })
		x += w
	end
	return segs
end

-- The top of a wall segment: a concrete cap if it survived, otherwise a
-- broken edge of chunks and bent rebar; sometimes a shoulder stepped down
-- at one end.
local function segmentTop(parent, axis, fixed, thickness, s, rng)
	local len = s.b - s.a
	local mid = (s.a + s.b) / 2
	local function box(along, y, alongPos, h, offset, color)
		local size, pos = BuildUtil.axisBox(axis, along, h, thickness + 0.02, alongPos, y + h / 2, fixed + (offset or 0))
		return part(parent, "WallTop", size, pos, Concrete, color or jitter(WALL_COLOR, rng, 0.05))
	end
	if rng:NextNumber() < 0.45 then
		local size, pos = BuildUtil.axisBox(axis, len + 0.4, 1, thickness + 1, mid, s.top + 0.5, fixed)
		part(parent, "WallCap", size, pos, Concrete, Color3.fromRGB(78, 76, 72))
	else
		for _ = 1, rng:NextInteger(2, 5) do
			local w = rng:NextNumber(2, math.min(8, len * 0.4))
			local along = rng:NextNumber(s.a + w / 2, s.b - w / 2)
			local h = rng:NextNumber(1, 5)
			local chunk = box(w, s.top, along, h)
			chunk.CFrame *= CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))
		end
		for _ = 1, rng:NextInteger(2, 6) do
			local along = rng:NextNumber(s.a + 1, s.b - 1)
			local off = rng:NextNumber(-thickness / 2 + 1, thickness / 2 - 1)
			local base = if axis == "X" then Vector3.new(along, s.top, fixed + off) else Vector3.new(fixed + off, s.top, along)
			local len2 = rng:NextNumber(2, 6)
			cylinder(parent, "WallRebar", len2, 0.2, CFrame.new(base + Vector3.new(0, len2 / 2, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)) * CFrame.Angles(0, 0, math.rad(90)), Rust, RUST_METAL)
		end
	end
	if len > 24 and rng:NextNumber() < 0.35 then
		local w = rng:NextNumber(6, len * 0.4)
		local atEnd = if rng:NextNumber() < 0.5 then s.a + w / 2 else s.b - w / 2
		box(w, s.top, atEnd, rng:NextNumber(4, 14))
	end
end

-- One wall as a run of uneven segments: the solid wall itself, the
-- surface weathering (once along the whole wall below the lowest top, then
-- lighter per segment above it), the broken tops.
local function unevenWall(parent, name, axis, fixed, thickness, face, normal, a, b, segs, rng, openings)
	local lowest = math.huge
	for _, s in ipairs(segs) do
		lowest = math.min(lowest, s.top)
		BuildUtil.strip(parent, {
			name = name,
			axis = axis,
			fixed = fixed,
			spanStart = s.a,
			spanEnd = s.b,
			bottom = FLOOR - 5,
			top = s.top,
			thickness = thickness,
			openings = openings or {},
			material = Concrete,
			color = jitter(WALL_COLOR, rng, 0.03),
		})
		segmentTop(parent, axis, fixed, thickness, s, rng)
	end
	wallSurface(parent, axis, face, normal, a, b, FLOOR, lowest, rng, openings, { topGrime = false })
	for _, s in ipairs(segs) do
		if s.top - lowest > 8 then
			wallSurface(parent, axis, face, normal, s.a, s.b, lowest, s.top, rng, nil, { pourEvery = 10, streaks = 0.5, baseGrime = false })
		end
	end
end

-- Where the far end wall is low, the crag's rock face shows above it:
-- bulge that face out into crags and ledges, with things growing on them.
local function cragFace(parent, segs, rng)
	local terrain = workspace.Terrain
	local faceX = X1 + WALL_T
	for _, s in ipairs(segs) do
		if s.a < 166 then
			for z = math.max(s.a, Z0 + 2), math.min(s.b, 166), 6 do
				local y = s.top + rng:NextNumber(-3, 4)
				while y < 22 do
					local r = rng:NextNumber(4, 10)
					terrain:FillBall(Vector3.new(faceX + r * rng:NextNumber(0.2, 0.7), y, z + rng:NextNumber(-3, 3)), r, if rng:NextNumber() < 0.15 then Enum.Material.Slate else Enum.Material.Rock)
					y += r * rng:NextNumber(0.9, 1.6)
				end
				-- A ledge now and then, grass and a bush on it.
				if rng:NextNumber() < 0.25 then
					local ly = rng:NextNumber(s.top + 4, 16)
					terrain:FillBall(Vector3.new(faceX + 1, ly, z), rng:NextNumber(3, 5), Enum.Material.LeafyGrass)
					local holder = model(parent, "CragGrowth")
					local grow = if rng:NextNumber() < 0.6 then Clutter.bush else Clutter.weeds
					grow(holder, Vector3.new(faceX - 1.5, ly + 3, z), rng)
				end
			end
		end
	end
end

-- The near wall, under the school: the school's courtyard face carried on
-- down it floor after floor to the courtyard, though there's nothing
-- behind: plaster, storey bands, the corridor's big windows. It gets
-- grimier and darker the further down it goes; some windows are broken
-- black, some boarded, a very few faintly lit.
local function schoolFacade(parent, rng)
	-- Only so many floors of it, then the building's bare concrete.
	local floors = rng:NextInteger(8, 11)
	local m = model(parent, "SchoolFacade")
	local face = Z0 + 0.05
	local SP = Config.FLOOR_SPACING
	local sill, top = Config.SILL_HEIGHT, Config.WINDOW_TOP
	local plaster = Config.PLASTER_COLOR
	local frameColor = Color3.fromRGB(96, 72, 50)
	local cw = Config.CLASSROOM_WIDTH
	local k = 1
	while true do
		local y = Config.BOTTOM_Y - k * SP
		if y + sill < FLOOR + 1 or k > floors then
			break
		end
		local depth = math.min(1, k / 18)
		local wall = plaster:Lerp(WALL_COLOR, 0.25 + depth * 0.6)
		part(m, "FacadePlaster", Vector3.new(X1 - X0, SP - 1.4, 0.1), Vector3.new((X0 + X1) / 2, y + (SP - 1.4) / 2, face), Enum.Material.Plaster, jitter(wall, rng, 0.03))
		part(m, "StoreyBand", Vector3.new(X1 - X0, 1.4, 0.6), Vector3.new((X0 + X1) / 2, y + SP - 0.7, face + 0.25), Concrete, Color3.fromRGB(128, 124, 116):Lerp(WALL_COLOR, depth * 0.7))
		for w = 0, Config.NUM_CLASSROOMS * 2 - 1 do
			local a, b = w * cw / 2 + 0.6, (w + 1) * cw / 2 - 0.6
			local c, width = (a + b) / 2, b - a
			local h = top - sill
			local cy = y + sill + h / 2
			part(m, "WindowFrame", Vector3.new(width, h, 0.1), Vector3.new(c, cy, face + 0.06), Wood, frameColor:Lerp(WALL_COLOR, depth * 0.5))
			local roll = rng:NextNumber()
			if roll < 0.08 + depth * 0.1 then
				part(m, "BrokenWindow", Vector3.new(width - 0.8, h - 0.8, 0.1), Vector3.new(c, cy, face + 0.12), Smooth, Color3.fromRGB(12, 12, 14))
			elseif roll < 0.13 + depth * 0.15 then
				for p = 0, 2 do
					part(m, "BoardedWindow", Vector3.new(width - 0.6, (h - 1) / 3 - 0.2, 0.25), CFrame.new(c, y + sill + 0.6 + (p + 0.5) * (h - 1) / 3, face + 0.2) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-3, 3))), Wood, jitter(Color3.fromRGB(120, 96, 66), rng, 0.1))
				end
			else
				local lit = roll > 0.985
				local glass = part(m, "WindowGlass", Vector3.new(width - 0.8, h - 0.8, 0.1), Vector3.new(c, cy, face + 0.12), if lit then Enum.Material.Neon else Enum.Material.Glass, if lit then Color3.fromRGB(120, 100, 60) else Color3.fromRGB(28, 34, 38):Lerp(Color3.fromRGB(60, 62, 58), rng:NextNumber(0, 0.4)))
				glass.Reflectance = if lit then 0 else 0.15
				part(m, "SashStile", Vector3.new(0.35, h - 0.8, 0.15), Vector3.new(c, cy, face + 0.16), Wood, frameColor)
				part(m, "Muntin", Vector3.new(width - 0.8, 0.25, 0.15), Vector3.new(c, cy + h * 0.12, face + 0.16), Wood, frameColor)
			end
		end
		k += 1
	end
	-- A heavy ledge where the facade stops and the concrete takes over.
	local bottom = Config.BOTTOM_Y - (k - 1) * SP
	part(m, "FacadeLedge", Vector3.new(X1 - X0, 1.8, 1.4), Vector3.new((X0 + X1) / 2, bottom - 0.9, face + 0.65), Concrete, Color3.fromRGB(110, 106, 98))
	-- Water staining and creepers coming down it.
	for _ = 1, 40 do
		local w, h = rng:NextNumber(2, 10), rng:NextNumber(20, 140)
		local x = rng:NextNumber(X0 + w, X1 - w)
		local topY = rng:NextNumber(FLOOR + h, Config.BOTTOM_Y - 2)
		local streak = part(m, "FacadeStreak", Vector3.new(w, h, 0.03), Vector3.new(x, topY - h / 2, face + 0.3 + rng:NextNumber(0, 0.02)), Smooth, if rng:NextNumber() < 0.3 then STREAK_RUST else STREAK_DARK)
		overlay(streak, rng:NextNumber(0.72, 0.88))
	end
	for _ = 1, 18 do
		local x = rng:NextNumber(X0 + 4, X1 - 4)
		local topY = rng:NextNumber(FLOOR + 40, Config.BOTTOM_Y - 2)
		for _ = 1, rng:NextInteger(2, 5) do
			local h = rng:NextNumber(6, 30)
			local leaf = part(m, "Creeper", Vector3.new(rng:NextNumber(1.5, 4), h, 0.3), Vector3.new(x + rng:NextNumber(-3, 3), topY - h / 2 - rng:NextNumber(0, 6), face + 0.35), Enum.Material.LeafyGrass, jitter(Color3.fromRGB(70, 96, 52), rng, 0.12))
			leaf.CanCollide = false
			leaf.CastShadow = false
		end
	end
	return bottom
end

-- ===== Assembly =====

function Courtyard.build(parent, rng)
	local midX, midZ = (X0 + X1) / 2, (Z0 + Z1) / 2

	-- The corridor's building stands on the near wall, and its face carries
	-- on down it to the floor. The other three walls are runs of uneven
	-- segments; the far end wall, with the crag and the department store
	-- behind it, is kept low, and the crag's rock shows above it.
	local schoolBase = Config.BOTTOM_Y - 0.6
	slab(parent, "NearWall", X0, X1, FLOOR - 5, schoolBase, Config.CORRIDOR_Z_MAX - 12, Z0, Concrete, WALL_COLOR)
	local facadeBottom = schoolFacade(parent, rng)
	wallSurface(parent, "X", Z0, 1, X0, X1, FLOOR, facadeBottom - 1.8, rng)
	task.wait()

	local R = Config.COURTYARD_WALLS
	unevenWall(parent, "FarWall", "X", Z1 + WALL_T / 2, WALL_T, Z1, -1, X0, X1, wallProfile(X0 - WALL_T, X1 + WALL_T, R.low, R.high, rng), rng)
	unevenWall(parent, "NearEndWall", "Z", X0 - WALL_T / 2, WALL_T, X0, 1, Z0, Z1, wallProfile(Z0, Z1, R.low, R.high, rng), rng)
	-- The far end wall has a doorway at floor level: the way in from the
	-- facility's fire exit (Facility.lua).
	local door = { center = Config.COURTYARD_DOOR_Z, width = Config.COURTYARD_DOOR_WIDTH, bottom = FLOOR, top = FLOOR + Config.COURTYARD_DOOR_HEIGHT }
	local farEndSegs = wallProfile(Z0, Z1, R.low, R.farEndHigh, rng)
	unevenWall(parent, "FarEndWall", "Z", X1 + WALL_T / 2, WALL_T, X1, -1, Z0, Z1, farEndSegs, rng, { door })
	cragFace(parent, farEndSegs, rng)
	task.wait()
	local doorFrame = Color3.fromRGB(70, 72, 74)
	slab(parent, "DoorFrame", X1 - 0.4, X1 + 0.6, FLOOR, door.top + 0.8, door.center - door.width / 2 - 0.8, door.center - door.width / 2, Enum.Material.Metal, doorFrame)
	slab(parent, "DoorFrame", X1 - 0.4, X1 + 0.6, FLOOR, door.top + 0.8, door.center + door.width / 2, door.center + door.width / 2 + 0.8, Enum.Material.Metal, doorFrame)
	slab(parent, "DoorFrame", X1 - 0.4, X1 + 0.6, door.top, door.top + 0.8, door.center - door.width / 2, door.center + door.width / 2, Enum.Material.Metal, doorFrame)


	buildFloor(parent, rng)
	-- The pitch fills the floor, leaving a 20-stud margin to the walls.
	footballPitch(parent, Vector3.new(midX, FLOOR, midZ), (X1 - X0) - 40, (Z1 - Z0) - 40, rng)

	-- Lying loosely curled toward the far right corner as seen from the
	-- spawn, with the skull reaching back out across the pitch.
	WhaleSkeleton.build(parent, WHALE_CENTER, rng, {
		scale = 2.3,
		phase = math.rad(-90 + rng:NextNumber(-12, 12)),
		sweep = math.rad(rng:NextNumber(230, 260)),
		looseArc = { math.rad(120), math.rad(330) },
	})
end

return Courtyard
