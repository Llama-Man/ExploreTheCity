-- What surrounds the gym, and how it got down there.
--
-- The gym once stood up level with the school, joined to it by a covered
-- walkway. Part of the crag gave way and brought it down: a landslide of
-- rock, earth and rooftop wreckage now pours off the crag into the corner
-- between the crag and the school, banked up against the gym's east end.
-- The walkway hangs snapped from the school's bottom floor down to the
-- gym's north door, and someone has bolted a steel stair up the pool
-- block's face from the top of the slide, back up to the rooftops.
--
--   GymSurrounds.shape(F, info, rng)             terrain; before the gym's
--                                                inside is cleared
--   GymSurrounds.dress(parent, F, info, doorCF, rng)  parts, once the
--                                                terrain is final
-- `doorCF` is the gym's north door in world space, facing out.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Rooftop = require(script.Parent.Rooftop)
local Clutter = require(script.Parent.RooftopClutter)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Concrete, Metal, Rust, Wood, Plate = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.Wood, Enum.Material.DiamondPlate

local terrain = workspace.Terrain
local ROCK, GRASS, GROUND = Enum.Material.Rock, Enum.Material.LeafyGrass, Enum.Material.Ground
-- Terrain never crosses this z: it's a voxel boundary just outside the
-- school's south wall, so no rock leaks into the classrooms.
local SCHOOL_FACE = -44
local SLIDE_REACH = 95 -- how far out from the crag face the slide runs
local STEEL = Color3.fromRGB(110, 112, 114)
local RUST_COLOR = Color3.fromRGB(116, 76, 48)
local BLOCK_GREY = Color3.fromRGB(112, 108, 100)
local GREENS = {
	Color3.fromRGB(62, 92, 46),
	Color3.fromRGB(78, 106, 52),
	Color3.fromRGB(52, 78, 44),
	Color3.fromRGB(96, 114, 58),
}

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { terrain }

local GymSurrounds = {}

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function groundBelow(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY, z), Vector3.new(0, -400, 0), terrainOnly)
	return hit
end

-- ===== The landslide =====

function GymSurrounds.shape(F, info, rng)
	local o = info.outcrop
	local crag = Rooftop.CRAG
	local face = o.x1
	local top = crag.top - 3
	local bulkTop = F - 14
	local seed = rng:NextNumber(0, 1000)
	for x = face - SLIDE_REACH, face - 2, 8 do
		for z = o.z0 + 2, SCHOOL_FACE - 2, 8 do
			-- Concave profile: steep off the crag, flattening onto the outcrop.
			local t = math.clamp(1 - (face - x) / SLIDE_REACH, 0, 1)
			local y = F - 4 + (top - (F - 4)) * t ^ 1.6 + math.noise(x / 40, z / 40, seed) * 7
			if z < crag.z0 then
				y -= (crag.z0 - z) * 1.3 -- no crag to fall from past its south end
			end
			if z > -84 then
				y += (z + 84) * 0.35 -- banked up into the corner with the school
			end
			y = math.min(y, top + 2)
			if y > F - 2 then
				local cx = x + rng:NextNumber(-3, 3)
				-- Stop short of the tunnels just inside the crag face.
				local r = math.min(rng:NextNumber(6, 10), face + 8 - cx)
				local cz = math.min(z + rng:NextNumber(-3, 3), SCHOOL_FACE - r)
				local za = cz - 5
				local zb = if cz > SCHOOL_FACE - 16 then SCHOOL_FACE else cz + 5
				local colTop = y - r * 0.3
				if colTop > bulkTop then
					terrain:FillBlock(CFrame.new(cx, (bulkTop + colTop) / 2, (za + zb) / 2), Vector3.new(10, colTop - bulkTop, zb - za), ROCK)
				end
				local roll = rng:NextNumber()
				terrain:FillBall(Vector3.new(cx, y - r * 0.9, cz), r, if roll < 0.2 then GRASS elseif roll < 0.4 then GROUND else ROCK)
			end
		end
	end
	-- Big boulders that came down with it.
	for _ = 1, 12 do
		local x, z = face - rng:NextNumber(10, SLIDE_REACH * 0.8), rng:NextNumber(crag.z0, SCHOOL_FACE - 14)
		local hit = groundBelow(x, z, crag.top + 60)
		if hit then
			local r = rng:NextNumber(5, 10)
			terrain:FillBall(hit.Position + Vector3.new(0, r * 0.3, 0), r, ROCK)
		end
	end
end

-- ===== Wreckage from the rooftops =====

local function container(parent, cf, rng)
	local color = jitter(pick({ Color3.fromRGB(146, 62, 44), Color3.fromRGB(52, 86, 120), Color3.fromRGB(170, 120, 50), Color3.fromRGB(70, 100, 70) }, rng), rng, 0.08)
	local m = model(parent, "FallenContainer")
	part(m, "Container", Vector3.new(20, 8.5, 8), cf, Rust, color)
	for k = -4, 4 do
		part(m, "ContainerRib", Vector3.new(0.3, 8.7, 8.2), cf * CFrame.new(k * 2.2, 0, 0), Rust, BuildUtil.darken(color, 0.85))
	end
	-- Doors burst open at one end.
	part(m, "ContainerDoor", Vector3.new(0.3, 8, 3.8), cf * CFrame.new(10.2, 0, 3.9) * CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(0, 0, 1.9), Rust, color)
end

-- A chunk of rooftop block, coping and dark band still on it.
local function blockChunk(parent, at, normal, rng)
	local size = Vector3.new(rng:NextNumber(8, 22), rng:NextNumber(5, 12), rng:NextNumber(7, 16))
	local cf = CFrame.new(at + normal * size.Y * 0.2) * CFrame.Angles(rng:NextNumber(-0.7, 0.7), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.7, 0.7))
	local color = jitter(BLOCK_GREY, rng, 0.08)
	part(parent, "FallenBlock", size, cf, Concrete, color)
	part(parent, "FallenBand", Vector3.new(size.X + 0.3, 1.4, size.Z + 0.3), cf * CFrame.new(0, size.Y * rng:NextNumber(-0.3, 0.3), 0), Enum.Material.SmoothPlastic, Color3.fromRGB(30, 32, 34))
	part(parent, "FallenCoping", Vector3.new(size.X + 0.6, 0.5, size.Z + 0.6), cf * CFrame.new(0, size.Y / 2 + 0.25, 0), Concrete, Color3.fromRGB(130, 126, 118))
end

local function fallenLamp(parent, at, rng)
	local yaw = rng:NextNumber(0, math.pi * 2)
	local dir = Vector3.new(math.cos(yaw), rng:NextNumber(0.05, 0.25), math.sin(yaw))
	local tip = at + dir.Unit * 14
	rod(parent, "FallenLampPost", at, tip, 0.5, Metal, Color3.fromRGB(60, 64, 66))
	part(parent, "LampHead", Vector3.new(2.4, 0.8, 1.2), CFrame.lookAt(tip, tip + dir), Metal, Color3.fromRGB(60, 64, 66))
end

local function debris(parent, F, info, rng)
	local o = info.outcrop
	local crag = Rooftop.CRAG
	local m = model(parent, "Landslide")
	local placed = 0
	for _ = 1, 80 do
		if placed >= 30 then
			break
		end
		local x, z = o.x1 - rng:NextNumber(6, SLIDE_REACH), rng:NextNumber(crag.z0 - 10, SCHOOL_FACE - 6)
		local onPath = math.abs(z - info.gymMouth.Z) < 12 and x > o.x1 - 60
		local hit = groundBelow(x, z, crag.top + 60)
		if hit and not onPath and hit.Position.Y > F + 3 then
			placed += 1
			local roll = rng:NextNumber()
			if roll < 0.4 then
				blockChunk(m, hit.Position, hit.Normal, rng)
			elseif roll < 0.55 then
				local cf = CFrame.new(hit.Position + hit.Normal * 2.5) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-1.2, 1.2))
				container(m, cf, rng)
			elseif roll < 0.7 then
				fallenLamp(m, hit.Position + Vector3.new(0, 0.4, 0), rng)
			elseif roll < 0.85 then
				-- A length of big pipe.
				local yaw = rng:NextNumber(0, math.pi * 2)
				local len = rng:NextNumber(10, 24)
				cylinder(m, "FallenPipe", len, rng:NextNumber(2, 4), CFrame.new(hit.Position + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, yaw, rng:NextNumber(-0.25, 0.25)), Rust, jitter(RUST_COLOR, rng, 0.1))
			else
				-- Twisted railing.
				local a = hit.Position + Vector3.new(0, 0.5, 0)
				local prev = a
				for _ = 1, 4 do
					local nxt = prev + Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(-0.5, 2), rng:NextNumber(-4, 4))
					rod(m, "BentRail", prev, nxt, 0.25, Metal, STEEL)
					prev = nxt
				end
			end
		end
	end

	-- A catwalk torn off the crag edge, hanging down the slide.
	for _ = 1, 2 do
		local z = rng:NextNumber(crag.z0 + 10, SCHOOL_FACE - 30)
		local a = Vector3.new(o.x1 + 1, crag.top + 0.3, z)
		local hit = groundBelow(o.x1 - rng:NextNumber(18, 30), z + rng:NextNumber(-8, 8), crag.top + 40)
		if hit then
			local b = hit.Position + Vector3.new(0, 0.4, 0)
			part(m, "HangingCatwalk", Vector3.new(5, 0.4, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12))), Plate, Color3.fromRGB(110, 106, 98))
			rod(m, "HangingRail", a + Vector3.new(0, 3, 2.4), b + Vector3.new(0, 2, 2.6), 0.25, Metal, STEEL)
		end
	end
end

-- ===== The stair back up =====

-- Steel stair from `a` (low) up to `b` (high), treads on stringers, legs
-- down to whatever terrain is below.
local function steelStair(parent, a, b, width)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dir = flat.Unit
	local across = Vector3.new(-dir.Z, 0, dir.X)
	local steps = math.ceil((b.Y - a.Y) / 0.9)
	local run, rise = flat.Magnitude / steps, (b.Y - a.Y) / steps
	for i = 1, steps do
		local at = a + dir * run * (i - 0.5) + Vector3.new(0, rise * i - 0.15, 0)
		part(parent, "Tread", Vector3.new(width, 0.3, run + 0.15), CFrame.lookAt(at, at + dir), Plate, Color3.fromRGB(104, 100, 94))
	end
	for _, s in ipairs({ -1, 1 }) do
		local off = across * s * (width / 2)
		rod(parent, "Stringer", a + off - Vector3.new(0, 0.6, 0), b + off - Vector3.new(0, 0.6, 0), 0.6, Rust, RUST_COLOR)
		rod(parent, "StairRail", a + off + Vector3.new(0, 3.2, 0), b + off + Vector3.new(0, 3.2, 0), 0.25, Metal, STEEL)
	end
	local len = flat.Magnitude
	for d = 4, len, 10 do
		local p = a + dir * d + Vector3.new(0, (b.Y - a.Y) * d / len, 0)
		for _, s in ipairs({ -1, 1 }) do
			local q = p + across * s * (width / 2)
			rod(parent, "StairRailPost", q, q + Vector3.new(0, 3.2, 0), 0.2, Metal, STEEL)
			local hit = groundBelow(q.X, q.Z, q.Y - 1)
			local footY = if hit then hit.Position.Y else q.Y - 40
			rod(parent, "StairLeg", q - Vector3.new(0, 0.8, 0), Vector3.new(q.X, footY, q.Z), 0.5, Rust, RUST_COLOR)
		end
	end
end

local function stairUp(parent, rng)
	local m = model(parent, "LandslideStair")
	local pool = Rooftop.BLOCKS.pool
	local land = Rooftop.POOL_STAIR_LANDING
	local crag = Rooftop.CRAG
	local x = pool[1] - 2.75
	local topY = pool[5] + 0.5
	local bottom = Vector3.new(x, crag.top, SCHOOL_FACE - 16)
	local top = Vector3.new(x, topY, land.z1 - 4)
	-- Platforms at each end.
	part(m, "StairPlatform", Vector3.new(7, 0.5, 8), Vector3.new(x, crag.top - 0.25, bottom.Z + 4), Plate, Color3.fromRGB(104, 100, 94))
	part(m, "StairPlatform", Vector3.new(7.5, 0.5, 8), Vector3.new(x + 0.4, topY - 0.25, top.Z - 4), Plate, Color3.fromRGB(104, 100, 94))
	for _, dz in ipairs({ -3.5, 3.5 }) do
		local p = Vector3.new(x - 3.3, crag.top, bottom.Z + 4 + dz)
		local hit = groundBelow(p.X, p.Z, p.Y - 1)
		rod(m, "StairLeg", p, Vector3.new(p.X, if hit then hit.Position.Y else p.Y - 40, p.Z), 0.6, Rust, RUST_COLOR)
	end
	steelStair(m, bottom, top, 5.5)
	-- Bolted to the block face with brackets.
	for z = top.Z + 6, bottom.Z - 6, 12 do
		local t = (z - bottom.Z) / (top.Z - bottom.Z)
		local y = bottom.Y + (top.Y - bottom.Y) * t - 1
		rod(m, "WallBracket", Vector3.new(pool[1] + 0.2, y + 2.5, z), Vector3.new(x + 2.4, y - 0.7, z), 0.4, Rust, RUST_COLOR)
	end
	-- A rough ramp of debris boards from the slide up onto the platform.
	local hit = groundBelow(x - rng:NextNumber(8, 12), bottom.Z + 6, crag.top + 30)
	if hit and hit.Position.Y < crag.top - 1 then
		local a, b = hit.Position + Vector3.new(0, 0.3, 0), Vector3.new(x - 3.5, crag.top, bottom.Z + 5)
		part(m, "DebrisBoards", Vector3.new(4, 0.5, (b - a).Magnitude + 1), CFrame.lookAt((a + b) / 2, b), Wood, Color3.fromRGB(110, 86, 60))
	end
end

-- ===== The broken walkway to the school =====

-- A covered walkway section between floor points a and b: floor slab,
-- posts both sides, roof. `damage` 0..1 knocks posts and roof about.
local function walkwaySection(parent, a, b, up, damage, rng)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local frame = CFrame.lookAt((a + b) / 2, b, up)
	local right = frame.RightVector
	local floorColor = Color3.fromRGB(128, 124, 116)
	part(parent, "WalkwayFloor", Vector3.new(8, 0.7, len + 0.3), frame * CFrame.new(0, -0.35, 0), Concrete, jitter(floorColor, rng, 0.05))
	local roofTop = 9.5
	local posts = math.max(1, math.floor(len / 6))
	for k = 0, posts do
		local p = a:Lerp(b, k / posts)
		for _, s in ipairs({ -1, 1 }) do
			local base = p + right * s * 3.8
			if rng:NextNumber() > damage * 0.4 then
				local lean = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * damage * 2.5
				rod(parent, "WalkwayPost", base, base + up * roofTop + lean, 0.35, Metal, STEEL)
			end
		end
	end
	-- Roof: whole if undamaged, else in pieces, some slid off to the side.
	local pieces = math.max(1, math.floor(len / 5))
	for k = 0, pieces - 1 do
		local p0, p1 = a:Lerp(b, k / pieces), a:Lerp(b, (k + 1) / pieces)
		local mid = (p0 + p1) / 2 + up * roofTop
		local roll = rng:NextNumber()
		if roll > damage * 0.7 then
			part(parent, "WalkwayRoof", Vector3.new(10, 0.35, (p1 - p0).Magnitude + 0.2), CFrame.lookAt(mid, mid + (p1 - p0), up) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-4, 4) * damage)), Metal, Color3.fromRGB(92, 98, 100))
		elseif roll > damage * 0.35 then
			local fall = (p0 + p1) / 2 + right * pick({ -1, 1 }, rng) * rng:NextNumber(7, 11)
			local hit = groundBelow(fall.X, fall.Z, fall.Y + 10)
			if hit then
				part(parent, "FallenWalkwayRoof", Vector3.new(10, 0.35, (p1 - p0).Magnitude), CFrame.new(hit.Position + Vector3.new(0, 1, 0)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Metal, Color3.fromRGB(92, 98, 100))
			end
		end
	end
	-- Low side rails.
	for _, s in ipairs({ -1, 1 }) do
		if rng:NextNumber() > damage * 0.5 then
			rod(parent, "WalkwayRail", a + right * s * 3.8 + up * 3, b + right * s * 3.8 + up * 3, 0.2, Metal, STEEL)
		end
	end
end

local function walkway(parent, F, doorCF, rng)
	local m = model(parent, "BrokenWalkway")
	local wallZ = Config.CLASSROOM_Z_FAR - Config.WALL_THICKNESS / 2
	local floorY = Config.floorY(1)
	local gymDoor = doorCF.Position
	local x = gymDoor.X + rng:NextNumber(-3, 3)

	-- Boarded-up doorway on the school wall where it used to join.
	local dark = Color3.fromRGB(70, 56, 42)
	part(m, "BoardedFrame", Vector3.new(0.6, 9.4, 0.5), Vector3.new(x - 3.3, floorY + 4.7, wallZ - 0.25), Wood, dark)
	part(m, "BoardedFrame", Vector3.new(0.6, 9.4, 0.5), Vector3.new(x + 3.3, floorY + 4.7, wallZ - 0.25), Wood, dark)
	part(m, "BoardedFrame", Vector3.new(7.2, 0.6, 0.5), Vector3.new(x, floorY + 9.4, wallZ - 0.25), Wood, dark)
	for k = 0, 6 do
		part(m, "Board", Vector3.new(7, 0.9, 0.3), CFrame.new(x, floorY + 1 + k * 1.3, wallZ - 0.6) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-10, 10))), Wood, jitter(Color3.fromRGB(128, 100, 70), rng, 0.1))
	end

	-- School-side stub, snapped off and sagging.
	local a0 = Vector3.new(x, floorY, wallZ - 0.4)
	local a1 = Vector3.new(x, floorY - 1.2, wallZ - 8)
	walkwaySection(m, a0, a1, Vector3.yAxis, 0.2, rng)
	for _ = 1, 5 do
		rod(m, "Rebar", a1 + Vector3.new(rng:NextNumber(-3.5, 3.5), -0.3, 0), a1 + Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(-2.5, 0.5), -rng:NextNumber(1.5, 3.5)), 0.15, Rust, RUST_COLOR)
	end

	-- Gym-side stub, tipped with the gym.
	local up = doorCF.UpVector
	local g0 = gymDoor
	local g1 = (doorCF * CFrame.new(0, 0, -7)).Position
	walkwaySection(m, g0, g1, up, 0.3, rng)

	-- The fallen span between them: dropped, slewed, knocked about.
	local s0 = a1 + Vector3.new(rng:NextNumber(-1.5, 1.5), -2.2, -1.2)
	walkwaySection(m, s0, g1 + up * 0.2, (Vector3.yAxis + up).Unit, 0.8, rng)
	for _ = 1, 10 do
		local p = s0:Lerp(g1, rng:NextNumber(0, 1)) + Vector3.new(rng:NextNumber(-7, 7), 0, rng:NextNumber(-3, 3))
		local hit = groundBelow(p.X, p.Z, p.Y + 4)
		if hit then
			local s = Vector3.new(rng:NextNumber(0.6, 2), rng:NextNumber(0.4, 1.2), rng:NextNumber(0.6, 2))
			part(m, "WalkwayRubble", s, CFrame.new(hit.Position + Vector3.new(0, s.Y * 0.35, 0)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Concrete, jitter(Color3.fromRGB(128, 124, 116), rng, 0.1))
		end
	end
end

-- ===== The corner against the stairwell =====

local function grow(parent, builder, at, scale, rng)
	local holder = model(parent, "Growth")
	builder(holder, at, rng)
	if #holder:GetDescendants() == 0 then
		holder:Destroy()
		return
	end
	holder.WorldPivot = CFrame.new(at)
	holder:ScaleTo(scale)
	holder:PivotTo(CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
end

-- Scaffold tower up the school wall: poles, ledgers, part-boarded decks,
-- tarps flapping off the outside, and a ladder up the middle.
local function scaffold(parent, x0, x1, zWall, depth, top, rng)
	local m = model(parent, "Scaffold")
	local rows = { zWall - 0.8, zWall - depth }
	local lowest = top
	for x = x0, x1, 6 do
		for _, z in ipairs(rows) do
			local hit = groundBelow(x, z, top + 10)
			local base = if hit then hit.Position.Y else top - 60
			lowest = math.min(lowest, base)
			rod(m, "ScaffoldPole", Vector3.new(x, base, z), Vector3.new(x, top, z), 0.35, Metal, STEEL)
		end
	end
	for y = lowest + 6, top, 6.5 do
		for _, z in ipairs(rows) do
			rod(m, "ScaffoldLedger", Vector3.new(x0, y, z), Vector3.new(x1, y, z), 0.3, Metal, STEEL)
		end
		for x = x0, x1, 6 do
			rod(m, "ScaffoldTransom", Vector3.new(x, y, rows[1]), Vector3.new(x, y, rows[2]), 0.25, Metal, STEEL)
		end
		for x = x0, x1 - 6, 6 do
			if rng:NextNumber() < 0.7 then
				local board = part(m, "ScaffoldBoard", Vector3.new(6, 0.3, depth - 1.2), Vector3.new(x + 3, y + 0.3, (rows[1] + rows[2]) / 2), Wood, jitter(Color3.fromRGB(128, 100, 70), rng, 0.1))
				if rng:NextNumber() < 0.15 then
					board.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), 0, math.rad(rng:NextNumber(-25, 25)))
				end
			end
		end
	end
	-- Cross bracing on the outside face.
	for x = x0, x1 - 6, 12 do
		rod(m, "ScaffoldBrace", Vector3.new(x, lowest + 2, rows[2]), Vector3.new(x + 6, math.min(top, lowest + 20), rows[2]), 0.25, Metal, STEEL)
	end
	for _ = 1, rng:NextInteger(2, 3) do
		local x = rng:NextNumber(x0 + 3, x1 - 3)
		local h = rng:NextNumber(6, 14)
		local y = rng:NextNumber(lowest + h, top)
		local tarp = part(m, "Tarp", Vector3.new(rng:NextNumber(5, 8), h, 0.1), CFrame.new(x, y - h / 2, rows[2] - 0.3) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-6, 6))), Enum.Material.Fabric, pick({ Color3.fromRGB(48, 84, 130), Color3.fromRGB(70, 96, 62), Color3.fromRGB(150, 70, 44) }, rng))
		tarp.Transparency = 0.15
		tarp.CanCollide = false
	end
	local ladder = Instance.new("TrussPart")
	ladder.Name = "ScaffoldLadder"
	ladder.Anchored = true
	ladder.Size = Vector3.new(2, top - lowest, 2)
	ladder.Position = Vector3.new(x0 + 3, (top + lowest) / 2, (rows[1] + rows[2]) / 2)
	ladder.Material = Rust
	ladder.Color = RUST_COLOR
	ladder.Parent = m
end

-- A fallen rooftop water tank, legs snapped off beside it.
local function fallenTank(parent, at, rng)
	local m = model(parent, "FallenTank")
	local cf = CFrame.new(at + Vector3.new(0, 5, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.2, 0.2))
	local color = jitter(Color3.fromRGB(150, 150, 142), rng, 0.08)
	cylinder(m, "TankBody", 18, 12, cf, Metal, color)
	cylinder(m, "TankBand", 0.6, 12.4, cf * CFrame.new(-5, 0, 0), Rust, RUST_COLOR)
	cylinder(m, "TankBand", 0.6, 12.4, cf * CFrame.new(5, 0, 0), Rust, RUST_COLOR)
	for _ = 1, 3 do
		local p = at + Vector3.new(rng:NextNumber(-12, 12), 0.5, rng:NextNumber(-12, 12))
		rod(m, "TankLeg", p, p + Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(0.5, 3), rng:NextNumber(-8, 8)), 0.8, Rust, RUST_COLOR)
	end
end

-- A small rooftop shed come down in a heap: walls leaning, roof slid off.
local function collapsedShed(parent, at, rng)
	local m = model(parent, "CollapsedShed")
	local base = CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local wallColor = jitter(Color3.fromRGB(150, 146, 136), rng, 0.08)
	part(m, "ShedWall", Vector3.new(10, 7, 0.5), base * CFrame.new(0, 2.5, -4) * CFrame.Angles(math.rad(rng:NextNumber(30, 60)), 0, 0), Concrete, wallColor)
	part(m, "ShedWall", Vector3.new(0.5, 7, 8), base * CFrame.new(5, 3, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-25, -10))), Concrete, wallColor)
	part(m, "ShedRoof", Vector3.new(12, 0.3, 10), base * CFrame.new(-2, 3, 1) * CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), 0, math.rad(rng:NextNumber(15, 30))), Metal, Color3.fromRGB(92, 98, 100))
	part(m, "ShedDoor", Vector3.new(3, 6.5, 0.3), base * CFrame.new(-4, 0.4, 3) * CFrame.Angles(math.rad(88), rng:NextNumber(0, 1), 0), Metal, Color3.fromRGB(70, 96, 110))
end

-- Somebody has been living up here: a tarp lean-to, a bedroll, crates,
-- a fire in a drum.
local function camp(parent, at, rng)
	local m = model(parent, "Camp")
	local base = CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	for _, x in ipairs({ -3, 3 }) do
		rod(m, "CampPole", (base * CFrame.new(x, 0, -2)).Position, (base * CFrame.new(x, 5, -2)).Position, 0.3, Wood, Color3.fromRGB(96, 76, 54))
	end
	local tarp = part(m, "CampTarp", Vector3.new(7.5, 0.1, 6.5), base * CFrame.new(0, 3, 0.4) * CFrame.Angles(math.rad(-38), 0, 0), Enum.Material.Fabric, Color3.fromRGB(48, 84, 130))
	tarp.CanCollide = false
	part(m, "Bedroll", Vector3.new(2.4, 0.5, 5.5), base * CFrame.new(-1.5, 0.25, 0.5), Enum.Material.Fabric, Color3.fromRGB(90, 70, 60))
	for k = 1, rng:NextInteger(2, 4) do
		part(m, "CampCrate", Vector3.new(2, 1.6, 1.6), base * CFrame.new(2.5, 0.8, -2 + k * 1.8) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), Wood, jitter(Color3.fromRGB(128, 100, 70), rng, 0.1))
	end
	local drum = base * CFrame.new(1, 0, 5)
	cylinder(m, "FireDrum", 3.4, 2.4, drum * CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Rust, RUST_COLOR)
	local fire = part(m, "Fire", Vector3.new(1.6, 0.8, 1.6), drum * CFrame.new(0, 3.5, 0), Enum.Material.Neon, Color3.fromRGB(255, 130, 40))
	fire.Shape = Enum.PartType.Ball
	fire.CanCollide = false
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 150, 70)
	glow.Range = 18
	glow.Brightness = 1.6
	glow.Parent = fire
	fire:AddTag("FlickerLight")
end

local function cornerNest(parent, rng)
	local m = model(parent, "StairwellCorner")
	local crag = Rooftop.CRAG
	local wallZ = Config.CLASSROOM_Z_FAR - Config.WALL_THICKNESS / 2
	local stairX0 = Config.TOTAL_LENGTH
	local roofY = Config.TOP_Y + 12

	scaffold(m, stairX0 + 2, stairX0 + 20, wallZ - 0.3, 6, roofY - 4, rng)

	-- Ivy and broken drainpipes down the school wall above the slide.
	for x = stairX0 - 70, stairX0 + 24, 5 do
		local hit = groundBelow(x, wallZ - 2, roofY)
		if hit and rng:NextNumber() < 0.7 then
			local y0 = hit.Position.Y
			for _ = 1, rng:NextInteger(2, 5) do
				local h = rng:NextNumber(4, 18)
				local leaf = part(m, "Ivy", Vector3.new(rng:NextNumber(2, 6), h, 0.3), Vector3.new(x + rng:NextNumber(-2, 2), y0 + h / 2 + rng:NextNumber(0, 10), wallZ - 0.25), Enum.Material.LeafyGrass, jitter(pick(GREENS, rng), rng, 0.12))
				leaf.CanCollide = false
				leaf.CastShadow = false
			end
		end
	end
	for _, x in ipairs({ stairX0 - 52, stairX0 - 18, stairX0 + 24 }) do
		local hit = groundBelow(x, wallZ - 1.5, roofY)
		if hit then
			local breakY = hit.Position.Y + rng:NextNumber(6, 20)
			rod(m, "Drainpipe", Vector3.new(x, roofY, wallZ - 0.9), Vector3.new(x, breakY, wallZ - 0.9), 0.8, Rust, RUST_COLOR)
			local fallen = hit.Position + Vector3.new(rng:NextNumber(-4, 4), 0.5, -rng:NextNumber(2, 5))
			rod(m, "FallenDrainpipe", fallen, fallen + Vector3.new(rng:NextNumber(-6, 6), 0.3, -rng:NextNumber(2, 5)), 0.8, Rust, RUST_COLOR)
		end
	end

	-- The heavy wreckage and the camp, on the slide's upper slopes.
	local function spot(x0, x1, z0, z1)
		for _ = 1, 12 do
			local hit = groundBelow(rng:NextNumber(x0, x1), rng:NextNumber(z0, z1), roofY)
			if hit and hit.Normal.Y > 0.55 then
				return hit.Position
			end
		end
		return nil
	end
	local tankAt = spot(stairX0 - 40, stairX0 - 10, wallZ - 34, wallZ - 16)
	if tankAt then
		fallenTank(m, tankAt, rng)
	end
	local shedAt = spot(stairX0 - 70, stairX0 - 45, wallZ - 30, wallZ - 10)
	if shedAt then
		collapsedShed(m, shedAt, rng)
	end
	local campAt = spot(stairX0 + 4, stairX0 + 18, wallZ - 26, wallZ - 12)
	if campAt then
		camp(m, campAt, rng)
	end

	-- Thick growth over all of it.
	for _ = 1, 40 do
		local p = spot(stairX0 - 80, crag.x0 - 2, wallZ - 44, wallZ - 3)
		if p then
			local roll = rng:NextNumber()
			if roll < 0.35 then
				grow(m, Clutter.weeds, p, rng:NextNumber(1.2, 2.4), rng)
			elseif roll < 0.65 then
				grow(m, Clutter.bush, p, rng:NextNumber(1.3, 3), rng)
			elseif roll < 0.85 then
				grow(m, Clutter.rooftopTree, p, rng:NextNumber(1.2, 2.6), rng)
			else
				grow(m, Clutter.mossyMound, p, rng:NextNumber(1, 1.8), rng)
			end
		end
	end
	-- Weeds and rubble along the strip of crag top beside the steel stair.
	for z = crag.z0 + 6, wallZ - 20, 7 do
		local hit = groundBelow(crag.x0 + 1.2, z, crag.top + 5)
		if hit and rng:NextNumber() < 0.75 then
			grow(m, if rng:NextNumber() < 0.6 then Clutter.weeds else Clutter.rubble, hit.Position, rng:NextNumber(0.8, 1.3), rng)
		end
	end
end

function GymSurrounds.dress(parent, F, info, doorCF, rng)
	debris(parent, F, info, rng)
	task.wait()
	stairUp(parent, rng)
	walkway(parent, F, doorCF, rng)
	task.wait()
	cornerNest(parent, rng)
end

return GymSurrounds
