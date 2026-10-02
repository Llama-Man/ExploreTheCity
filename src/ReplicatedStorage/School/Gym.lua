-- The gymnasium on the rock outcrop below the school's south side, with a
-- colossal flowering tree grown up through it.
--
-- The gym looks as if it was flung down here: it lies skewed and tipped on
-- a lumpy, overgrown outcrop, its west end sunk into heaped rock that has
-- burst in over the stage. Walls are breached, a roof bay has fallen in,
-- the floor is buckled and gapped, and ivy, weeds, bushes and saplings
-- have taken over. The ceremony it was set out for never finished: rows of
-- folding chairs still face the stage and its graduation banner.
--
-- Everything is built flat in a "gym frame" (as if it stood level at the
-- floor height), then the whole model is pivoted into its tipped pose.
-- The tree is planned in world space first, and converted into the gym
-- frame so walls and roof can open where it breaks through.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Architecture = require(script.Parent.Architecture)
local Clutter = require(script.Parent.RooftopClutter)
local BigTree = require(script.Parent.BigTree)
local GymSurrounds = require(script.Parent.GymSurrounds)
local RouteCheck = require(script.Parent.RouteCheck)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local Concrete, Metal, Wood, Smooth, Fabric = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.Wood, Enum.Material.SmoothPlastic, Enum.Material.Fabric
local Planks, Leafy = Enum.Material.WoodPlanks, Enum.Material.LeafyGrass

local terrain = workspace.Terrain
local ROCK, AIR, GRASS, GROUND = Enum.Material.Rock, Enum.Material.Air, Enum.Material.LeafyGrass, Enum.Material.Ground

local GYM = { x0 = 250, x1 = 420, z0 = -172, z1 = -62 }
local L, W = GYM.x1 - GYM.x0, GYM.z1 - GYM.z0
local ZC = (GYM.z0 + GYM.z1) / 2
local EAVE, RISE, WALL_T = 38, 16, 2
local STAGE_FRONT = GYM.x0 + 20
local NORTH_DOOR_X = GYM.x0 + 32 -- where the walkway from the school came in
local HOLE = Vector3.new(GYM.x0 + 78, 0, GYM.z1 - 30) -- trunk, in the gym frame (y = floor)
local HOLE_R = 20
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local STEEL = Color3.fromRGB(110, 112, 114)
local WALL_COLOR = Color3.fromRGB(150, 146, 138)
local FLOOR_WOOD = Color3.fromRGB(196, 158, 108)
local GREENS = {
	Color3.fromRGB(62, 92, 46),
	Color3.fromRGB(78, 106, 52),
	Color3.fromRGB(52, 78, 44),
	Color3.fromRGB(96, 114, 58),
}

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { terrain }

local Gym = {}

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

-- A flat slab spanning from a to b (its length), `width` across.
local function slab(parent, name, a, b, width, thickness, material, color)
	return part(parent, name, Vector3.new(width, thickness, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), material, color)
end

local function label(parent, cframe, size, face, text, font, textColor, bgColor)
	local plate = part(parent, "Sign", size, cframe, Smooth, bgColor)
	plate.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = font
	t.TextScaled = true
	t.TextColor3 = textColor
	t.Text = text
	t.Parent = gui
	gui.Parent = plate
	return plate
end

local function chunk(parent, at, scale, rng, color)
	local sz = Vector3.new(rng:NextNumber(0.6, 2.2), rng:NextNumber(0.4, 1.4), rng:NextNumber(0.6, 2.2)) * scale
	part(parent, "Rubble", sz, CFrame.new(at + Vector3.new(0, sz.Y * 0.35, 0)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Concrete, jitter(color or WALL_COLOR, rng, 0.1))
end

-- Clutter builders from the rooftop, dropped in at a random scale.
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

-- Roof arch height at z (gym frame).
local function archY(F, z)
	local half = W / 2
	return F + EAVE + RISE * (1 - ((z - ZC) / half) ^ 2)
end

-- ===== The tree in the gym frame =====

local function toFrame(plan, M)
	local function conv(list)
		local out = table.create(#list)
		for i, p in ipairs(list) do
			out[i] = M:PointToObjectSpace(p)
		end
		return out
	end
	local lp = { trunk = { points = conv(plan.trunk.points), radii = plan.trunk.radii }, roots = {}, limbs = {} }
	for _, r in ipairs(plan.roots) do
		table.insert(lp.roots, { points = conv(r.points), radii = r.radii })
	end
	for _, l in ipairs(plan.limbs) do
		table.insert(lp.limbs, { points = conv(l.points), radii = l.radii })
	end
	return lp
end

local function segDist(p, a, b)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- Is `p` within `pad` of the trunk or any limb?
local function treeNear(lp, p, pad)
	local function scan(pts, radii)
		for k = 1, #pts - 1 do
			if segDist(p, pts[k], pts[k + 1]) < radii[k] + pad then
				return true
			end
		end
		return false
	end
	if scan(lp.trunk.points, lp.trunk.radii) then
		return true
	end
	for _, l in ipairs(lp.limbs) do
		if scan(l.points, l.radii) then
			return true
		end
	end
	return false
end

local function trunkAtHeight(lp, y)
	local pts = lp.trunk.points
	for k = 1, #pts - 1 do
		if pts[k].Y <= y and pts[k + 1].Y >= y then
			return pts[k]:Lerp(pts[k + 1], (y - pts[k].Y) / (pts[k + 1].Y - pts[k].Y))
		end
	end
	return pts[#pts]
end

-- ===== Rock =====

-- Heaps a lumpy, part-grassed top onto the outcrop, beds the gym into it
-- (burying its sunken west end), then clears the gym's inside, lets rock
-- burst in at the west corners, and opens a way to the tunnel mouth.
local function shapeRock(F, M, door, info, rng)
	local o = info.outcrop
	local bulkTop = F - 14
	local seed = rng:NextNumber(0, 1000)
	for x = o.x0 + 4, o.x1 - 6, 13 do
		for z = o.z0 + 4, o.z1 - 4, 13 do
			local n = math.noise(x / 70, z / 70, seed) * 1.4 + math.noise(x / 26, z / 26, seed + 9) * 0.6
			local edge = math.min(x - o.x0, o.x1 - x, z - o.z0, o.z1 - z)
			local top = F - 7 + n * 14 + rng:NextNumber(-2, 2) - math.max(0, 22 - edge) * 0.7
			local cx = x + rng:NextNumber(-5, 5)
			-- Never reaching past the crag face into the tunnels behind it.
			local r = math.min(rng:NextNumber(9, 16), o.x1 + 8 - cx)
			local c = Vector3.new(cx, top - r, z + rng:NextNumber(-5, 5))
			if c.Y > bulkTop then
				terrain:FillBlock(CFrame.new(c.X, (bulkTop + c.Y) / 2, c.Z), Vector3.new(r * 1.3, c.Y - bulkTop + 2, r * 1.3), ROCK)
			end
			local roll = rng:NextNumber()
			terrain:FillBall(c, r, if roll < 0.3 then GRASS elseif roll < 0.4 then GROUND else ROCK)
		end
	end
	GymSurrounds.shape(F, info, rng)
	-- Loose boulders.
	for _ = 1, 14 do
		local x, z = rng:NextNumber(o.x0 + 8, o.x1 - 20), rng:NextNumber(o.z0 + 8, o.z1 - 8)
		local hit = workspace:Raycast(Vector3.new(x, F + 120, z), Vector3.new(0, -250, 0), terrainOnly)
		if hit then
			terrain:FillBall(hit.Position + Vector3.new(0, rng:NextNumber(0, 4), 0), rng:NextNumber(5, 11), ROCK)
		end
	end
	task.wait()

	-- The bed it came to rest on (not under the sunken west end, which the
	-- heaped rock holds instead).
	terrain:FillBlock(M * CFrame.new((GYM.x0 + 30 + GYM.x1) / 2, F - 8, ZC), Vector3.new(L - 34, 14, W - 12), ROCK)
	for z = GYM.z0 - 8, GYM.z1 + 8, 9 do
		local roll = rng:NextNumber()
		terrain:FillBall(M * Vector3.new(GYM.x0 - rng:NextNumber(2, 12), F + rng:NextNumber(0, 12), z), rng:NextNumber(12, 20), if roll < 0.25 then GRASS else ROCK)
	end
	for x = GYM.x0, GYM.x0 + 110, 12 do
		terrain:FillBall(M * Vector3.new(x, F + rng:NextNumber(-8, 3), GYM.z0 - rng:NextNumber(5, 12)), rng:NextNumber(9, 15), if rng:NextNumber() < 0.3 then GRASS else ROCK)
	end

	-- Clear the inside.
	local h = EAVE + RISE + 6
	terrain:FillBlock(M * CFrame.new((GYM.x0 + GYM.x1) / 2, F - 1 + h / 2, ZC), Vector3.new(L - WALL_T - 0.5, h, W - WALL_T - 0.5), AIR)

	-- Rock bursting in at the west corners, over the stage.
	terrain:FillBall(M * Vector3.new(GYM.x0 + 9, F + 3, GYM.z0 + W * 0.26), rng:NextNumber(15, 19), ROCK)
	terrain:FillBall(M * Vector3.new(GYM.x0 + 5, F + 5, GYM.z1 - 15), rng:NextNumber(10, 13), ROCK)
	terrain:FillBall(M * Vector3.new(GYM.x0 + 16, F + 1, GYM.z0 + W * 0.3), rng:NextNumber(7, 10), GRASS)

	-- A way through from the east door to the tunnel mouth.
	local mouth = info.gymMouth
	-- (runs on a little way into the tunnel, in case the landslide spilled
	-- into it.)
	local len = mouth.X + 14 - door.X
	terrain:FillBlock(CFrame.new(door.X + len / 2, F - 3, door.Z), Vector3.new(len + 6, 6, 18), ROCK)
	terrain:FillBlock(CFrame.new(door.X + len / 2 + 1, F + 12, door.Z), Vector3.new(len + 2, 24, 14), AIR)
	task.wait()
end

-- ===== Shell =====

-- BuildUtil.strip needs openings that don't overlap; roots, breaches,
-- doors and windows can, so fuse overlapping ones into one bigger hole.
local function mergeOpenings(list)
	table.sort(list, function(a, b)
		return a.center - a.width / 2 < b.center - b.width / 2
	end)
	local out = {}
	for _, o in ipairs(list) do
		local last = out[#out]
		local s, e = o.center - o.width / 2, o.center + o.width / 2
		if last and s < last.center + last.width / 2 then
			local ls = last.center - last.width / 2
			local le = math.max(last.center + last.width / 2, e)
			last.center, last.width = (ls + le) / 2, le - ls
			last.bottom, last.top = math.min(last.bottom, o.bottom), math.max(last.top, o.top)
		else
			table.insert(out, { center = o.center, width = o.width, bottom = o.bottom, top = o.top })
		end
	end
	return out
end

-- Position on a wall: `along` the wall, height y, `off` out from its
-- centre plane (sign = which face).
local function onWall(axis, fixed, along, y, off)
	return if axis == "X" then Vector3.new(along, y, fixed + off) else Vector3.new(fixed + off, y, along)
end

-- Ivy: overlapping leafy plates climbing a wall face.
local function ivy(parent, axis, fixed, side, along, bottom, height, width, rng)
	for _ = 1, rng:NextInteger(3, 6) do
		local w = width * rng:NextNumber(0.4, 0.9)
		local h = height * rng:NextNumber(0.4, 1)
		local a = along + rng:NextNumber(-width, width) * 0.35
		local y = bottom + h / 2 + rng:NextNumber(0, height - h)
		local size = if axis == "X" then Vector3.new(w, h, 0.3) else Vector3.new(0.3, h, w)
		local leaf = part(parent, "Ivy", size, onWall(axis, fixed, a, y, side * (WALL_T / 2 + rng:NextNumber(0.15, 0.4))), Leafy, jitter(pick(GREENS, rng), rng, 0.12))
		leaf.CanCollide = false
		leaf.CastShadow = false
	end
end

local function walls(parent, F, lp, doorZ, rng)
	local frame = Color3.fromRGB(70, 66, 60)
	local g = GYM
	local function rootHoles(axis, fixed, a, b)
		local holes = {}
		for _, h in ipairs(BigTree.crossings(lp, axis, fixed, a, b)) do
			if h.y < F + EAVE then
				table.insert(holes, { center = h.along, width = h.radius * 2 + 5, bottom = math.max(F, h.y - h.radius - 2), top = h.y + h.radius + 3, root = true })
			end
		end
		return holes
	end
	local function clearOf(holes, center, width)
		for _, h in ipairs(holes) do
			if math.abs(h.center - center) < (h.width + width) / 2 + 1 then
				return false
			end
		end
		return true
	end

	local breaches = {
		south = { center = rng:NextNumber(g.x0 + 38, g.x0 + 48), width = rng:NextNumber(16, 24), bottom = F + rng:NextNumber(0, 3), top = F + EAVE + 1 },
		north = { center = rng:NextNumber(g.x1 - 26, g.x1 - 18), width = rng:NextNumber(14, 20), bottom = F, top = F + EAVE + 1 },
	}
	local sides = {
		{ axis = "X", fixed = g.z0, a = g.x0, b = g.x1, inward = 1, windows = true, breach = breaches.south },
		{ axis = "X", fixed = g.z1, a = g.x0, b = g.x1, inward = -1, windows = true, breach = breaches.north, door = { center = NORTH_DOOR_X, width = 8, height = 10 } },
		{ axis = "Z", fixed = g.x0, a = g.z0, b = g.z1, inward = 1 },
		{ axis = "Z", fixed = g.x1, a = g.z0, b = g.z1, inward = -1, door = { center = doorZ, width = 10, height = 12 } },
	}
	for _, s in ipairs(sides) do
		local holes = rootHoles(s.axis, s.fixed, s.a, s.b)
		local openings = table.clone(holes)
		if s.breach then
			table.insert(holes, s.breach)
			table.insert(openings, s.breach)
		end
		if s.door then
			table.insert(openings, { center = s.door.center, width = s.door.width, bottom = F, top = F + s.door.height })
		end
		local windows = {}
		if s.windows then
			for c = s.a + 14, s.b - 14, 14 do
				local byDoor = s.door and math.abs(c - s.door.center) < (s.door.width + 8) / 2 + 1
				if clearOf(holes, c, 8) and not byDoor then
					local w = { center = c, width = 8, bottom = F + 24, top = F + 33 }
					table.insert(openings, w)
					table.insert(windows, w)
				end
			end
		end
		BuildUtil.strip(parent, {
			name = "GymWall",
			axis = s.axis,
			fixed = s.fixed,
			spanStart = s.a - WALL_T / 2,
			spanEnd = s.b + WALL_T / 2,
			bottom = F,
			top = F + EAVE,
			thickness = WALL_T,
			openings = mergeOpenings(openings),
			material = Concrete,
			color = WALL_COLOR,
			rng = rng,
			jitter = 0.06,
		})
		for _, w in ipairs(windows) do
			Architecture.sashWindow(parent, s.axis, s.fixed, w.center, w.width, w.bottom, w.top, frame, rng, { broken = 0.6 })
		end

		-- Ragged teeth at the edges of every hole, and rubble spilled
		-- either side of it.
		for _, h in ipairs(holes) do
			for _, edge in ipairs({ -1, 1 }) do
				for _ = 1, rng:NextInteger(2, 4) do
					local th = rng:NextNumber(2, 8)
					local tw = rng:NextNumber(1, 3)
					local y = rng:NextNumber(h.bottom, math.max(h.bottom, math.min(h.top, F + EAVE) - th))
					local size = if s.axis == "X" then Vector3.new(tw, th, WALL_T) else Vector3.new(WALL_T, th, tw)
					part(parent, "BrokenEdge", size, CFrame.new(onWall(s.axis, s.fixed, h.center + edge * (h.width / 2 - tw / 2 + 0.2), y + th / 2, 0)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6))), Concrete, jitter(WALL_COLOR, rng, 0.08))
				end
			end
			local heap = if h.root then rng:NextInteger(5, 9) else rng:NextInteger(20, 34)
			for _ = 1, heap do
				local off = rng:NextNumber(-1, 1) ^ 3 * (if h.root then 5 else 12)
				local along = h.center + rng:NextNumber(-0.5, 0.5) * h.width
				local lift = if h.root then 0 else math.max(0, 4 - math.abs(off) * 0.4) * rng:NextNumber(0, 1)
				chunk(parent, onWall(s.axis, s.fixed, along, F + lift, off), if h.root then 1 else rng:NextNumber(1, 2.2), rng)
			end
			if not h.root then
				for _ = 1, rng:NextInteger(2, 3) do
					local along = h.center + rng:NextNumber(-0.4, 0.4) * h.width
					local off = s.inward * rng:NextNumber(3, 9) * pick({ 1, 1, -1 }, rng)
					local size = if s.axis == "X" then Vector3.new(rng:NextNumber(5, 9), rng:NextNumber(4, 7), WALL_T) else Vector3.new(WALL_T, rng:NextNumber(4, 7), rng:NextNumber(5, 9))
					part(parent, "FallenWall", size, CFrame.new(onWall(s.axis, s.fixed, along, F + size.Y * 0.3, off)) * CFrame.Angles(rng:NextNumber(-0.9, 0.9), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.9, 0.9)), Concrete, jitter(WALL_COLOR, rng, 0.08))
				end
			end
		end

		-- Ivy up both faces, thicker round the holes.
		for along = s.a + 4, s.b - 4, 9 do
			for _, side in ipairs({ -1, 1 }) do
				local nearHole = not clearOf(holes, along, 14)
				if rng:NextNumber() < (if nearHole then 0.85 else 0.4) then
					ivy(parent, s.axis, s.fixed, side, along, F, rng:NextNumber(8, if nearHole then 34 else 24), rng:NextNumber(6, 14), rng)
				end
			end
		end
	end

	-- Gables at the ends and above the proscenium, up under the arch.
	for _, x in ipairs({ g.x0, g.x1, STAGE_FRONT + 0.5 }) do
		for z = g.z0, g.z1 - 5, 5 do
			local top = archY(F, z + 2.5)
			box(parent, "Gable", x - WALL_T / 2, x + WALL_T / 2, F + EAVE, top, z, z + 5, Concrete, WALL_COLOR)
		end
	end
	label(parent, CFrame.new(g.x1 + 1.1, F + 16, doorZ) * CFrame.Angles(math.rad(7), 0, 0), Vector3.new(0.2, 3, 12), Enum.NormalId.Right, "体育館", Enum.Font.GothamBold, Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 214, 196))
end

-- Arched steel trusses with corrugated panels: a ragged hole where the
-- trunk came through, gaps wherever a limb pushes out, one bay fallen in
-- down to the floor, and a few panels hanging loose.
local function roof(parent, F, lp, rng)
	local g = GYM
	local segs = 10
	local zStep = W / segs
	local holeAt = trunkAtHeight(lp, F + EAVE + RISE * 0.7)
	local holeR = 26

	local trussXs = {}
	for x = g.x0, g.x1, 14 do
		table.insert(trussXs, x)
	end
	-- The collapsed bay: towards the east, clear of the tree, south half.
	local fallenBay
	for _ = 1, 10 do
		local i = rng:NextInteger(math.floor(#trussXs * 0.5), #trussXs - 2)
		local mid = Vector3.new((trussXs[i] + trussXs[i + 1]) / 2, F + EAVE, g.z0 + W * 0.2)
		if not treeNear(lp, mid, 12) then
			fallenBay = i
			break
		end
	end

	for idx, x in ipairs(trussXs) do
		local chords = {}
		for s = 0, segs - 1 do
			local z0, z1 = g.z0 + s * zStep, g.z0 + (s + 1) * zStep
			local a, b = Vector3.new(x, archY(F, z0), z0), Vector3.new(x, archY(F, z1), z1)
			local mid = (a + b) / 2
			local fallen = fallenBay ~= nil and idx == fallenBay + 1 and s < 4
			if not fallen and Vector3.new(mid.X - holeAt.X, 0, mid.Z - holeAt.Z).Magnitude > holeR * 0.7 and not treeNear(lp, mid, 2) then
				rod(parent, "TrussChord", a, b, 1.2, Metal, STEEL)
				rod(parent, "TrussWeb", a, Vector3.new(x, F + EAVE, (z0 + z1) / 2), 0.4, Metal, STEEL)
				table.insert(chords, mid)
			end
		end
		if not treeNear(lp, Vector3.new(x, F + EAVE, ZC), 1) then
			rod(parent, "TrussTie", Vector3.new(x, F + EAVE, g.z0), Vector3.new(x, F + EAVE, g.z1), 0.5, Metal, STEEL)
		end
		-- Creepers hanging from the trusses.
		for _, c in ipairs(chords) do
			if rng:NextNumber() < 0.35 then
				for _ = 1, rng:NextInteger(1, 3) do
					local len = rng:NextNumber(6, 26)
					local strand = part(parent, "Creeper", Vector3.new(0.3, len, 0.3), c + Vector3.new(rng:NextNumber(-1, 1), -len / 2, rng:NextNumber(-2, 2)), Leafy, jitter(pick(GREENS, rng), rng, 0.15))
					strand.CanCollide = false
				end
			end
		end
	end

	local panelColor = Color3.fromRGB(96, 100, 104)
	local dangling = 0
	for i = 1, #trussXs - 1 do
		local xa, xb = trussXs[i], trussXs[i + 1]
		for s = 0, segs - 1 do
			local z0, z1 = g.z0 + s * zStep, g.z0 + (s + 1) * zStep
			local a, b = Vector3.new((xa + xb) / 2, archY(F, z0) + 0.7, z0), Vector3.new((xa + xb) / 2, archY(F, z1) + 0.7, z1)
			local mid = (a + b) / 2
			local inHole = Vector3.new(mid.X - holeAt.X, 0, mid.Z - holeAt.Z).Magnitude < holeR + rng:NextNumber(-5, 5) or treeNear(lp, mid, 3)
			local size = Vector3.new(xb - xa + 0.2, 0.4, (b - a).Magnitude + 0.2)
			local cf = CFrame.lookAt(mid, b)
			if i == fallenBay and s < 4 then
				continue
			elseif inHole then
				if dangling < 7 and rng:NextNumber() < 0.3 then
					dangling += 1
					part(parent, "DanglingPanel", size, CFrame.new(a) * (cf - cf.Position) * CFrame.Angles(-math.rad(rng:NextNumber(50, 85)), 0, 0) * CFrame.new(0, 0, -size.Z / 2), Metal, jitter(panelColor, rng, 0.1))
				end
			elseif rng:NextNumber() > 0.08 then
				part(parent, "RoofPanel", size, cf, Metal, jitter(panelColor, rng, 0.08))
			end
		end
	end

	-- The fallen bay: roof sheets slumped from the eave down to the floor,
	-- a truss chord lying across them, rubble and weeds at the foot.
	if fallenBay then
		local xa, xb = trussXs[fallenBay], trussXs[fallenBay + 1]
		local xm = (xa + xb) / 2
		local top = Vector3.new(xm, F + EAVE - 1, g.z0 + 1.5)
		local knee = Vector3.new(xm + rng:NextNumber(-2, 2), F + rng:NextNumber(10, 16), g.z0 + rng:NextNumber(20, 26))
		local foot = Vector3.new(xm + rng:NextNumber(-3, 3), F + 0.6, knee.Z + rng:NextNumber(12, 18))
		slab(parent, "FallenRoof", top, knee, xb - xa, 0.5, Metal, jitter(panelColor, rng, 0.1))
		slab(parent, "FallenRoof", knee, foot, (xb - xa) * 0.9, 0.5, Metal, jitter(panelColor, rng, 0.1))
		rod(parent, "FallenTruss", Vector3.new(xb, F + EAVE, g.z0 + 1), Vector3.new(xb - rng:NextNumber(4, 10), F + 1, foot.Z - 4), 1.2, Metal, STEEL)
		for _ = 1, 16 do
			chunk(parent, foot + Vector3.new(rng:NextNumber(-8, 8), -0.6, rng:NextNumber(-6, 6)), rng:NextNumber(1, 2), rng)
		end
		for _ = 1, 4 do
			grow(parent, Clutter.weeds, foot + Vector3.new(rng:NextNumber(-8, 8), -0.4, rng:NextNumber(-6, 6)), rng:NextNumber(1, 1.8), rng)
		end
	end
end

-- ===== Floor =====

-- Wooden sport floor laid in short board runs: gapped, buckled, heaved up
-- round the trunk. Returns the gaps so weeds can grow through them.
local function floor(parent, F, rng)
	local g = GYM
	local gaps = {}
	box(parent, "GymSlab", g.x0, g.x1, F - 1.5, F, g.z0, g.z1, Concrete, Color3.fromRGB(96, 92, 86))
	local xi0, xi1 = g.x0 + WALL_T / 2, g.x1 - WALL_T / 2
	local zEnd = g.z1 - WALL_T / 2
	-- A couple of ridges where the floor has buckled.
	local ridges = {}
	for _ = 1, 2 do
		table.insert(ridges, { x = rng:NextNumber(g.x0 + 50, g.x1 - 20), width = rng:NextNumber(5, 9), height = rng:NextNumber(1.2, 3) })
	end

	local function run(a, b, z, zb)
		local x = a
		while x < b - 0.5 do
			local len = math.min(rng:NextNumber(8, 18), b - x)
			local cx, cz = x + len / 2, (z + zb) / 2
			local d = Vector3.new(cx - HOLE.X, 0, cz - HOLE.Z).Magnitude
			local nearTrunk = d < HOLE_R + 14
			local roll = rng:NextNumber()
			if roll < (if nearTrunk then 0.25 else 0.05) then
				table.insert(gaps, Vector3.new(cx, F, cz))
			else
				local lift, pitch, rollA = rng:NextNumber(-0.05, 0.12), math.rad(rng:NextNumber(-1.2, 1.2)), math.rad(rng:NextNumber(-0.8, 0.8))
				if nearTrunk then
					lift += (HOLE_R + 14 - d) * rng:NextNumber(0.05, 0.12)
					pitch += math.rad(rng:NextNumber(-14, 14))
					rollA += math.rad(rng:NextNumber(-8, 8))
				end
				for _, r in ipairs(ridges) do
					local off = math.abs(cx - r.x)
					if off < r.width + len / 2 then
						lift += r.height * math.max(0, 1 - off / (r.width + len / 2))
						pitch += math.rad(rng:NextNumber(-6, 6))
					end
				end
				if roll > 0.97 then
					pitch += math.rad(rng:NextNumber(8, 20)) * pick({ -1, 1 }, rng)
					lift += 0.8
				end
				part(parent, "FloorBoards", Vector3.new(len - 0.05, 0.4, zb - z), CFrame.new(cx, F + 0.2 + lift, cz) * CFrame.Angles(rollA, 0, pitch), Planks, jitter(FLOOR_WOOD, rng, 0.07))
			end
			x += len
		end
	end
	for z = g.z0 + WALL_T / 2, zEnd - 0.5, 3 do
		local zb = math.min(z + 2.95, zEnd)
		local dz = math.abs((z + zb) / 2 - HOLE.Z)
		if dz < HOLE_R then
			local dx = math.sqrt(HOLE_R * HOLE_R - dz * dz)
			run(xi0, HOLE.X - dx, z, zb)
			run(HOLE.X + dx, xi1, z, zb)
		else
			run(xi0, xi1, z, zb)
		end
	end
	-- Earth where the floor has gone, heaped up round the trunk.
	local hole = Vector3.new(HOLE.X, F, HOLE.Z)
	for _ = 1, 7 do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, HOLE_R * 0.8)
		local s = rng:NextNumber(10, 18)
		local mound = part(parent, "Earth", Vector3.new(s, s * 0.35, s), hole + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d), GROUND, jitter(Color3.fromRGB(70, 54, 40), rng, 0.1))
		mound.Shape = Enum.PartType.Ball
	end

	-- Court markings, worn away in places and missing over the hole.
	local function line(a, b, width, color)
		local len = (b - a).Magnitude
		local pieces = math.max(1, math.floor(len / 4))
		for k = 1, pieces do
			local p0, p1 = a:Lerp(b, (k - 1) / pieces), a:Lerp(b, k / pieces)
			local mid = (p0 + p1) / 2
			if Vector3.new(mid.X - hole.X, 0, mid.Z - hole.Z).Magnitude > HOLE_R + 6 and rng:NextNumber() > 0.18 then
				local y = F + 0.44
				local stripe = part(parent, "CourtLine", Vector3.new(width, 0.04, (p1 - p0).Magnitude + 0.05), CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(p1.X, y, p1.Z)), Smooth, color)
				stripe.Transparency = rng:NextNumber(0.2, 0.5)
				stripe.CanCollide = false
			end
		end
	end
	local function rect(c, hx, hz, width, color)
		local p = { c + Vector3.new(-hx, 0, -hz), c + Vector3.new(hx, 0, -hz), c + Vector3.new(hx, 0, hz), c + Vector3.new(-hx, 0, hz) }
		for k = 1, 4 do
			line(p[k], p[k % 4 + 1], width, color)
		end
	end
	local function circle(c, r, width, color, a0, a1)
		local n = 20
		for k = 0, n - 1 do
			local t0, t1 = a0 + (a1 - a0) * k / n, a0 + (a1 - a0) * (k + 1) / n
			line(c + Vector3.new(math.cos(t0) * r, 0, math.sin(t0) * r), c + Vector3.new(math.cos(t1) * r, 0, math.sin(t1) * r), width, color)
		end
	end
	local court = Vector3.new(g.x1 - 58, F, ZC)
	local white, green = Color3.fromRGB(236, 232, 220), Color3.fromRGB(70, 130, 80)
	rect(court, 50, 28, 0.6, white)
	line(court + Vector3.new(0, 0, -28), court + Vector3.new(0, 0, 28), 0.6, white)
	circle(court, 7.5, 0.6, white, 0, math.pi * 2)
	for _, s in ipairs({ -1, 1 }) do
		rect(court + Vector3.new(s * 42.5, 0, 0), 7.5, 10, 0.6, white)
		circle(court + Vector3.new(s * 44, 0, 0), 26, 0.6, white, if s == 1 then math.pi / 2 else -math.pi / 2, if s == 1 then math.pi * 1.5 else math.pi / 2)
	end
	rect(court, 38, 19, 0.5, green)
	for _, dx in ipairs({ -12.6, 0, 12.6 }) do
		line(court + Vector3.new(dx, 0, -19), court + Vector3.new(dx, 0, 19), 0.5, green)
	end
	return gaps
end

-- ===== Inside =====

local function stage(parent, F, rng)
	local g = GYM
	local top = F + 5
	local sz0, sz1 = g.z0 + 8, g.z1 - 8
	local wood = Color3.fromRGB(150, 110, 70)
	box(parent, "Stage", g.x0 + 1, STAGE_FRONT, F, top, sz0, sz1, Planks, wood)
	box(parent, "StageApron", STAGE_FRONT - 0.3, STAGE_FRONT + 0.3, F, top + 0.2, sz0, sz1, Wood, Color3.fromRGB(90, 64, 42))
	local openZ0, openZ1 = sz0 + 6, sz1 - 6
	for _, z0 in ipairs({ openZ0, openZ1 - 6 }) do
		for k = 0, 4 do
			box(parent, "StageStep", STAGE_FRONT + 1 + k * 1.3, STAGE_FRONT + 1 + (k + 1) * 1.3, F, top - k, z0, z0 + 6, Wood, wood)
		end
	end

	local openTop = F + 26
	BuildUtil.strip(parent, {
		name = "Proscenium",
		axis = "Z",
		fixed = STAGE_FRONT + 0.5,
		spanStart = g.z0 + 1,
		spanEnd = g.z1 - 1,
		bottom = F,
		top = F + EAVE,
		thickness = 1,
		openings = { { center = (openZ0 + openZ1) / 2, width = openZ1 - openZ0, bottom = top, top = openTop } },
		material = Concrete,
		color = Color3.fromRGB(176, 168, 150),
	})

	-- Curtains, mostly torn: some pieces hang short, some have come down.
	local red = Color3.fromRGB(120, 30, 34)
	for _, side in ipairs({ { openZ0, 1 }, { openZ1, -1 } }) do
		for p = 0, 4 do
			local z = side[1] + side[2] * (p * 1.6 + 0.8)
			if rng:NextNumber() < 0.2 then
				part(parent, "FallenCurtain", Vector3.new(rng:NextNumber(4, 7), 0.6, rng:NextNumber(3, 6)), CFrame.new(STAGE_FRONT - rng:NextNumber(2, 7), top + 0.3, z) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.1, 0.1)), Fabric, jitter(red, rng, 0.06))
			else
				local drop = if rng:NextNumber() < 0.5 then rng:NextNumber(3, 14) else 0
				part(parent, "Curtain", Vector3.new(0.4 + (p % 2) * 0.3, openTop - top - drop, 1.7), Vector3.new(STAGE_FRONT - 1, (openTop + top + drop) / 2, z), Fabric, jitter(red, rng, 0.05))
			end
		end
	end
	local valance = box(parent, "Valance", STAGE_FRONT - 1.4, STAGE_FRONT - 0.6, openTop - 3, openTop, openZ0, openZ1, Fabric, darken(red, 0.85))
	valance.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(-3, 3)), 0, 0)

	local banner = label(parent, CFrame.new(STAGE_FRONT + 1.15, F + 31, (openZ0 + openZ1) / 2) * CFrame.Angles(math.rad(rng:NextNumber(3, 7)), 0, 0), Vector3.new(0.2, 5, 44), Enum.NormalId.Right, "卒業証書授与式", Enum.Font.Garamond, Color3.fromRGB(30, 28, 26), Color3.fromRGB(226, 220, 204))
	banner.Material = Fabric
	cylinder(parent, "ClockFace", 0.3, 4, CFrame.new(STAGE_FRONT + 1.2, F + 35.5, (openZ0 + openZ1) / 2), Smooth, Color3.fromRGB(236, 234, 224))
	cylinder(parent, "ClockRim", 0.2, 4.6, CFrame.new(STAGE_FRONT + 1.05, F + 35.5, (openZ0 + openZ1) / 2), Smooth, Color3.fromRGB(40, 40, 42))

	local mid = (sz0 + sz1) / 2
	local lectern = box(parent, "StageLectern", STAGE_FRONT - 7, STAGE_FRONT - 4.5, top, top + 3.8, mid - 1.8, mid + 1.8, Wood, Color3.fromRGB(110, 76, 48))
	lectern.CFrame *= CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0)
	for _, s in ipairs({ -1, 1 }) do
		local base = Vector3.new(STAGE_FRONT - 12, top, mid + s * 14)
		if s == 1 or rng:NextNumber() < 0.5 then
			rod(parent, "FlagPole", base, base + Vector3.new(0, 11, 0), 0.3, Metal, Color3.fromRGB(200, 170, 80))
			part(parent, "Flag", Vector3.new(0.1, 4, 6), base + Vector3.new(0, 8.5, s * 3), Fabric, if s == 1 then Color3.fromRGB(226, 222, 214) else Color3.fromRGB(60, 80, 130))
		else
			rod(parent, "FallenFlagPole", base + Vector3.new(0, 0.3, 0), base + Vector3.new(rng:NextNumber(4, 8), 0.3, s * rng:NextNumber(6, 9)), 0.3, Metal, Color3.fromRGB(200, 170, 80))
		end
	end
	-- Weeds pushing up through the stage boards.
	for _ = 1, rng:NextInteger(4, 7) do
		grow(parent, Clutter.weeds, Vector3.new(rng:NextNumber(g.x0 + 4, STAGE_FRONT - 2), top, rng:NextNumber(sz0 + 2, sz1 - 2)), rng:NextNumber(1, 1.6), rng)
	end
end

-- Galleries along both long walls, each reached by a flight of stairs; a
-- stretch of the south one has come down.
local function galleries(parent, F, rng)
	local g = GYM
	local y = F + 14
	local x1 = g.x1 - WALL_T / 2
	local specs = {
		{ z0 = g.z1 - WALL_T / 2 - 5, z1 = g.z1 - WALL_T / 2, x0 = x1 - 47, stairFrom = x1 - 89, inner = g.z1 - WALL_T / 2 - 5, collapse = false },
		{ z0 = g.z0 + WALL_T / 2, z1 = g.z0 + WALL_T / 2 + 5, x0 = x1 - 67, stairFrom = x1 - 109, inner = g.z0 + WALL_T / 2 + 5, collapse = true },
	}
	for _, s in ipairs(specs) do
		local pieces = math.floor((x1 - s.x0) / 10)
		local fallen = if s.collapse then rng:NextInteger(2, pieces - 2) else -10
		local zm = (s.z0 + s.z1) / 2
		for k = 0, pieces - 1 do
			local xa, xb = s.x0 + k * 10, if k == pieces - 1 then x1 else s.x0 + (k + 1) * 10
			if k == fallen then
				-- Snapped off at one end, the other end down on the floor.
				local fa, fb = Vector3.new(xa, y - 0.4, zm), Vector3.new(xb - 1, F + 0.6, zm + (s.inner - zm) * 3)
				slab(parent, "FallenGallery", fa, fb, 5, 0.8, Wood, Color3.fromRGB(140, 104, 70))
				rod(parent, "FallenRail", fa + Vector3.new(0, 3, 2), fb + Vector3.new(0, 1, 3), 0.3, Metal, STEEL)
				for _ = 1, 6 do
					chunk(parent, fb + Vector3.new(rng:NextNumber(-4, 4), -0.6, rng:NextNumber(-3, 3)), 0.8, rng, Color3.fromRGB(140, 104, 70))
				end
			else
				local deck = box(parent, "Gallery", xa, xb, y - 0.8, y, s.z0, s.z1, Wood, jitter(Color3.fromRGB(140, 104, 70), rng, 0.05))
				if k == fallen - 1 or k == fallen + 1 then
					deck.CFrame *= CFrame.Angles(0, 0, math.rad(if k < fallen then -4 else 4))
				end
				if rng:NextNumber() > 0.1 then
					rod(parent, "GalleryRail", Vector3.new(xa, y + 3.2, s.inner), Vector3.new(xb, y + 3.2 + rng:NextNumber(-0.3, 0.3), s.inner), 0.3, Metal, STEEL)
				end
				for x = xa, xb - 1, 5 do
					rod(parent, "GalleryPost", Vector3.new(x, y, s.inner), Vector3.new(x + rng:NextNumber(-0.3, 0.3), y + 3.2, s.inner), 0.2, Metal, STEEL)
				end
				rod(parent, "GalleryBracket", Vector3.new(xa + 5, y - 5, (s.z0 + s.z1) / 2 + (if s.inner > s.z0 then -2 else 2)), Vector3.new(xa + 5, y - 0.8, s.inner), 0.5, Metal, STEEL)
			end
		end
		local steps = 18
		local run = (s.x0 - s.stairFrom) / steps
		for k = 1, steps do
			local top = F + 14 * k / steps
			box(parent, "GalleryStep", s.stairFrom + (k - 1) * run, s.stairFrom + k * run, top - 1.2, top, s.z0, s.z1, Wood, jitter(Color3.fromRGB(130, 96, 64), rng, 0.05))
		end
		rod(parent, "StairRail", Vector3.new(s.stairFrom, F + 3.2, s.inner), Vector3.new(s.x0, y + 3.2, s.inner), 0.3, Metal, STEEL)
	end
end

local function storeroom(parent, F, rng)
	local g = GYM
	local xi1, zi0 = g.x1 - WALL_T / 2, g.z0 + WALL_T / 2
	local x0, z1 = xi1 - 21, zi0 + 21
	local doorZ = zi0 + 11
	local h = 11
	BuildUtil.strip(parent, { name = "StoreWall", axis = "Z", fixed = x0, spanStart = zi0, spanEnd = z1, bottom = F, top = F + h, thickness = 0.8, openings = { { center = doorZ, width = 5, bottom = F, top = F + 8 } }, material = Concrete, color = WALL_COLOR })
	box(parent, "StoreWall", x0, xi1, F, F + h, z1 - 0.4, z1 + 0.4, Concrete, WALL_COLOR)
	box(parent, "StoreRoof", x0, xi1, F + h, F + h + 0.5, zi0, z1 + 0.4, Concrete, WALL_COLOR)
	label(parent, CFrame.new(x0 - 0.45, F + 9, doorZ), Vector3.new(0.1, 1.2, 5), Enum.NormalId.Left, "体育倉庫", Enum.Font.GothamBold, Color3.fromRGB(40, 40, 44), Color3.fromRGB(226, 222, 206))

	local mx, mz = x0 + 4, zi0 + 2
	for k = 0, 4 do
		local mat = box(parent, "Mat", mx, mx + 10, F + k * 1.1, F + (k + 1) * 1.1, mz, mz + 5, Fabric, pick({ Color3.fromRGB(50, 80, 140), Color3.fromRGB(60, 110, 70) }, rng))
		mat.CFrame *= CFrame.Angles(0, math.rad(rng:NextNumber(-6, 6)), 0)
	end
	local vx, vz = x0 + 6, zi0 + 12
	for k = 0, 4 do
		local inset = k * 0.25
		box(parent, "VaultingBox", vx + inset, vx + 6 - inset, F + k * 1.2, F + (k + 1) * 1.2, vz + inset, vz + 6 - inset, Wood, Color3.fromRGB(170, 130, 86))
	end
	box(parent, "BallCart", xi1 - 6, xi1 - 1, F, F + 4, vz, vz + 6, Metal, STEEL)
	for _ = 1, 8 do
		local ball = part(parent, "Ball", Vector3.one * 1.6, Vector3.new(rng:NextNumber(xi1 - 5.2, xi1 - 1.8), F + 4 + rng:NextNumber(0, 1.2), rng:NextNumber(vz + 0.8, vz + 5.2)), Smooth, pick({ Color3.fromRGB(210, 110, 40), Color3.fromRGB(226, 222, 210) }, rng))
		ball.Shape = Enum.PartType.Ball
	end
	for _ = 1, rng:NextInteger(8, 14) do
		local ball = part(parent, "Ball", Vector3.one * 1.6, Vector3.new(rng:NextNumber(STAGE_FRONT + 10, g.x1 - 30), F + 1.2, rng:NextNumber(g.z0 + 8, g.z1 - 8)), Smooth, pick({ Color3.fromRGB(210, 110, 40), Color3.fromRGB(226, 222, 210) }, rng))
		ball.Shape = Enum.PartType.Ball
		ball:SetAttribute("Loose", true)
	end
end

local function hoop(parent, at, facing, rng)
	local backboard = at + facing * 4
	rod(parent, "HoopArm", at, backboard + Vector3.new(0, 1.5, 0), 0.5, Metal, STEEL)
	if rng:NextNumber() > 0.35 then
		local bb = part(parent, "Backboard", Vector3.new(4.6, 3.2, 0.2), CFrame.lookAt(backboard + Vector3.new(0, 1.5, 0), backboard + Vector3.new(0, 1.5, 0) + facing) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-8, 8))), Smooth, Color3.fromRGB(226, 230, 232))
		bb.Transparency = 0.2
	end
	local rim = backboard + facing * 1.2 - Vector3.new(0, rng:NextNumber(0, 0.6), 0)
	for k = 0, 9 do
		local a0, a1 = k / 10 * math.pi * 2, (k + 1) / 10 * math.pi * 2
		rod(parent, "Rim", rim + Vector3.new(math.cos(a0) * 0.8, 0, math.sin(a0) * 0.8), rim + Vector3.new(math.cos(a1) * 0.8, 0, math.sin(a1) * 0.8), 0.12, Metal, Color3.fromRGB(200, 90, 40))
	end
end

local function foldingChair(parent, at)
	local grey = Color3.fromRGB(120, 124, 126)
	local chair = model(parent, "FoldingChair")
	part(chair, "ChairSeat", Vector3.new(2, 0.2, 2), at + Vector3.new(0, 2, 0), Metal, grey)
	part(chair, "ChairBack", Vector3.new(0.2, 1.6, 2), at + Vector3.new(1, 3.1, 0), Metal, grey)
	for _, s in ipairs({ -1, 1 }) do
		rod(chair, "ChairLeg", at + Vector3.new(-0.9, 0, s * 0.9), at + Vector3.new(0.9, 2.2, s * 0.9), 0.15, Metal, darken(grey, 0.7))
		rod(chair, "ChairLeg", at + Vector3.new(0.9, 0, s * 0.9), at + Vector3.new(1, 3.9, s * 0.9), 0.15, Metal, darken(grey, 0.7))
	end
	return chair
end

-- Rows of folding chairs facing the stage, thrown about: gaps, tipped
-- chairs, a few heaped together, and none left near the tree.
local function ceremonyChairs(parent, F, rng)
	local trunk = Vector3.new(HOLE.X, F, HOLE.Z)
	for row = 0, 7 do
		local x = STAGE_FRONT + 12 + row * 5
		for z = GYM.z0 + 14, GYM.z1 - 14, 3 do
			local at = Vector3.new(x, F + 0.4, z)
			local aisle = math.abs(z - ZC) < 3
			local nearTree = (at - trunk).Magnitude < HOLE_R + 8
			if not aisle and not nearTree and rng:NextNumber() > 0.2 then
				local chair = foldingChair(parent, at)
				local shove = Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
				if rng:NextNumber() < 0.3 then
					BuildUtil.placeTilted(chair, at + shove * 3, 1, rng:NextNumber(0, math.pi * 2), CFrame.Angles(0, 0, math.rad(pick({ 90, -90, 180 }, rng))))
				else
					BuildUtil.place(chair, at, shove, math.rad(rng:NextNumber(-25, 25)))
				end
			end
		end
	end
	-- Heaps of chairs, as if swept aside.
	for _ = 1, 3 do
		local c = Vector3.new(rng:NextNumber(STAGE_FRONT + 55, GYM.x1 - 30), F + 0.4, rng:NextNumber(GYM.z0 + 10, GYM.z1 - 10))
		if (c - trunk).Magnitude > HOLE_R + 10 then
			for k = 1, rng:NextInteger(6, 12) do
				local chair = foldingChair(parent, c)
				BuildUtil.placeTilted(chair, c + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), 0.8 + k * 0.35, rng:NextNumber(0, math.pi * 2), CFrame.Angles(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5)))
			end
		end
	end
end

local function highBayLights(parent, F, rng)
	for x = GYM.x0 + 35, GYM.x1 - 7, 28 do
		for _, z in ipairs({ ZC - 20, ZC + 20 }) do
			local at = Vector3.new(x, F + EAVE - 2.5, z)
			local roll = rng:NextNumber()
			if roll < 0.2 then
				-- Come down: a snapped hanger and the lamp smashed below.
				rod(parent, "LampHanger", Vector3.new(x, F + EAVE, z), Vector3.new(x + rng:NextNumber(-1, 1), F + EAVE - rng:NextNumber(3, 8), z), 0.15, Metal, STEEL)
				cylinder(parent, "FallenLamp", 1.5, 3, CFrame.new(x + rng:NextNumber(-3, 3), F + 1.6, z + rng:NextNumber(-3, 3)) * CFrame.Angles(rng:NextNumber(0, 3), 0, rng:NextNumber(0.3, 1.2)), Metal, Color3.fromRGB(80, 84, 86))
			else
				rod(parent, "LampHanger", at, Vector3.new(x, F + EAVE, z), 0.15, Metal, STEEL)
				cylinder(parent, "LampShade", 1.5, 3, CFrame.new(at) * UPRIGHT, Metal, Color3.fromRGB(80, 84, 86))
				local lit = roll > 0.5
				local lens = part(parent, "LampLens", Vector3.new(0.2, 2.4, 2.4), CFrame.new(at - Vector3.new(0, 0.8, 0)) * UPRIGHT, if lit then Enum.Material.Neon else Smooth, if lit then Color3.fromRGB(246, 238, 216) else Color3.fromRGB(90, 90, 88))
				lens.Shape = Enum.PartType.Cylinder
				lens.CanCollide = false
				if lit then
					local light = Instance.new("SpotLight")
					light.Face = Enum.NormalId.Left
					light.Angle = 110
					light.Range = 45
					light.Brightness = 1.2
					light.Color = Color3.fromRGB(255, 236, 206)
					light.Parent = lens
					if roll < 0.7 then
						lens:AddTag("FlickerLight")
					end
				end
			end
		end
	end
end

-- Plants inside: thick under the roof hole, along the wall feet, in the
-- floor's gaps, and a few saplings where the light gets in.
local function overgrowth(parent, F, lp, gaps, doorZ, rng)
	local holeAt = trunkAtHeight(lp, F + EAVE)
	local function inside(at, pad)
		return at.X > STAGE_FRONT + 2 and at.X < GYM.x1 - pad and at.Z > GYM.z0 + pad and at.Z < GYM.z1 - pad
	end
	for _ = 1, rng:NextInteger(30, 42) do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(HOLE_R - 4, HOLE_R + 30) * rng:NextNumber(0.6, 1)
		local at = Vector3.new(holeAt.X + math.cos(a) * d, F + 0.4, holeAt.Z + math.sin(a) * d)
		if inside(at, 3) then
			local roll = rng:NextNumber()
			if roll < 0.45 then
				grow(parent, Clutter.weeds, at, rng:NextNumber(1, 2.2), rng)
			elseif roll < 0.75 then
				grow(parent, Clutter.bush, at, rng:NextNumber(1, 2.6), rng)
			elseif roll < 0.88 then
				grow(parent, Clutter.rooftopTree, at, rng:NextNumber(1, 1.8), rng)
			else
				grow(parent, Clutter.puddle, at, rng:NextNumber(1, 2.5), rng)
			end
		end
	end
	for _, gap in ipairs(gaps) do
		if rng:NextNumber() < 0.7 then
			grow(parent, Clutter.weeds, gap, rng:NextNumber(0.9, 1.6), rng)
		end
	end
	-- Along the wall feet.
	for _ = 1, 40 do
		local side = rng:NextInteger(1, 3)
		local at
		if side == 1 then
			at = Vector3.new(rng:NextNumber(STAGE_FRONT + 4, GYM.x1 - 4), F + 0.4, GYM.z0 + rng:NextNumber(2, 4))
		elseif side == 2 then
			at = Vector3.new(rng:NextNumber(STAGE_FRONT + 4, GYM.x1 - 4), F + 0.4, GYM.z1 - rng:NextNumber(2, 4))
		else
			at = Vector3.new(GYM.x1 - rng:NextNumber(2, 4), F + 0.4, rng:NextNumber(GYM.z0 + 4, GYM.z1 - 4))
			if math.abs(at.Z - doorZ) < 9 then
				continue
			end
		end
		grow(parent, if rng:NextNumber() < 0.7 then Clutter.weeds else Clutter.bush, at, rng:NextNumber(0.9, 1.8), rng)
	end
	-- Puddles where the roof leaks.
	for _ = 1, rng:NextInteger(6, 10) do
		local at = Vector3.new(rng:NextNumber(STAGE_FRONT + 10, GYM.x1 - 10), F + 0.45, rng:NextNumber(GYM.z0 + 8, GYM.z1 - 8))
		grow(parent, Clutter.puddle, at, rng:NextNumber(1, 2.2), rng)
	end
end

-- ===== Outside =====

-- Greenery over the lumpy rock round the gym, bunched into thickets.
local function outsideGreenery(parent, F, M, info, rng)
	local o = info.outcrop
	local spots = {}
	for _ = 1, 7 do
		table.insert(spots, Vector3.new(rng:NextNumber(o.x0 + 10, o.x1 - 20), 0, rng:NextNumber(o.z0 + 10, o.z1 - 6)))
	end
	for _ = 1, 110 do
		local x, z
		if rng:NextNumber() < 0.75 then
			local c = pick(spots, rng)
			x, z = c.X + rng:NextNumber(-22, 22), c.Z + rng:NextNumber(-22, 22)
		else
			x, z = rng:NextNumber(o.x0 + 4, o.x1 - 10), rng:NextNumber(o.z0 + 4, o.z1 - 4)
		end
		local lp = M:PointToObjectSpace(Vector3.new(x, F, z))
		local inGym = lp.X > GYM.x0 - 2 and lp.X < GYM.x1 + 2 and lp.Z > GYM.z0 - 2 and lp.Z < GYM.z1 + 2
		local onPath = x > GYM.x1 - 4 and math.abs(z - info.gymMouth.Z) < 14
		if not inGym and not onPath then
			local hit = workspace:Raycast(Vector3.new(x, F + 140, z), Vector3.new(0, -280, 0), terrainOnly)
			if hit and hit.Normal.Y > 0.5 then
				local roll = rng:NextNumber()
				local at = hit.Position
				if roll < 0.35 then
					grow(parent, Clutter.weeds, at, rng:NextNumber(1.2, 2.5), rng)
				elseif roll < 0.7 then
					grow(parent, Clutter.bush, at, rng:NextNumber(1.4, 3.5), rng)
				elseif roll < 0.88 then
					grow(parent, Clutter.rooftopTree, at, rng:NextNumber(1.3, 3), rng)
				else
					grow(parent, Clutter.mossyMound, at, rng:NextNumber(1, 2), rng)
				end
			end
		end
	end
end

-- ===== Assembly =====

-- info = { gymFloor, gymMouth, outcrop } from Underground.build.
function Gym.build(parent, info, rng)
	local F = info.gymFloor
	local doorZ = info.gymMouth.Z

	-- The pose it landed in: pivoted about the east door (so that stays
	-- level with the tunnel), skewed away from the school, west end tipped
	-- down into the rock and the south side sagging.
	local C = Vector3.new(GYM.x1, F, doorZ)
	local G = CFrame.new(C) * CFrame.Angles(0, math.rad(-9 + rng:NextNumber(-2, 2)), 0) * CFrame.Angles(math.rad(-4 + rng:NextNumber(-1, 1)), 0, math.rad(6 + rng:NextNumber(-1, 1)))
	local M = G * CFrame.new(-C)

	shapeRock(F, M, C, info, rng)

	-- Plan the tree in world space, then bring it into the gym frame.
	local up = M.UpVector
	local floorOrigin = M * Vector3.new(GYM.x0, F + 0.4, ZC)
	local function groundAt(x, z)
		local lp = M:PointToObjectSpace(Vector3.new(x, F, z))
		if lp.X > GYM.x0 and lp.X < GYM.x1 and lp.Z > GYM.z0 and lp.Z < GYM.z1 then
			return floorOrigin.Y - (up.X * (x - floorOrigin.X) + up.Z * (z - floorOrigin.Z)) / up.Y
		end
		local hit = workspace:Raycast(Vector3.new(x, F + 140, z), Vector3.new(0, -280, 0), terrainOnly)
		return if hit then hit.Position.Y else F - 14
	end
	local base = M * Vector3.new(HOLE.X, F, HOLE.Z)
	local plan = BigTree.plan(rng, {
		spine = {
			base + Vector3.new(0, -4, 0),
			base + Vector3.new(1, 16, 3),
			base + Vector3.new(-1, 36, 9),
			base + Vector3.new(-4, 56, 15),
			base + Vector3.new(-7, 74, 19),
			base + Vector3.new(-9, 88, 18),
		},
		baseRadius = 12.5,
		topRadius = 5.5,
		ground = F,
		groundAt = groundAt,
		groundBounds = info.outcrop,
		hugZ = Config.CLASSROOM_Z_FAR - Config.WALL_THICKNESS / 2,
		hugX = { 20, Config.TOTAL_LENGTH - 10 },
		limbs = { count = { 10, 13 }, reach = { 50, 90 }, rise = { 0.05, 0.45 }, from = { 0.45, 0.95 } },
		lush = 2,
		blossom = 0.22,
		crown = 46,
	})
	local lp = toFrame(plan, M)

	local shell = model(parent, "Gymnasium")
	local gaps = floor(shell, F, rng)
	walls(shell, F, lp, doorZ, rng)
	roof(shell, F, lp, rng)
	task.wait()
	stage(shell, F, rng)
	galleries(shell, F, rng)
	storeroom(shell, F, rng)
	local courtX = GYM.x1 - 58
	hoop(shell, Vector3.new(GYM.x1 - 1, F + 10, ZC), Vector3.new(-1, 0, 0), rng)
	hoop(shell, Vector3.new(courtX - 20, F + 10, GYM.z1 - 1), Vector3.new(0, 0, -1), rng)
	hoop(shell, Vector3.new(courtX - 20, F + 10, GYM.z0 + 1), Vector3.new(0, 0, 1), rng)
	ceremonyChairs(shell, F, rng)
	highBayLights(shell, F, rng)
	overgrowth(shell, F, lp, gaps, doorZ, rng)
	task.wait()

	-- Tip it into place, then let the loose balls roll where they will.
	shell.WorldPivot = CFrame.new(C)
	shell:PivotTo(G)
	for _, d in ipairs(shell:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("Loose") then
			d.Anchored = false
		end
	end

	outsideGreenery(parent, F, M, info, rng)
	task.wait()
	local northDoor = Vector3.new(NORTH_DOOR_X, F, GYM.z1)
	GymSurrounds.dress(parent, F, info, M * CFrame.lookAt(northDoor, northDoor + Vector3.zAxis), rng)
	task.wait()
	BigTree.build(parent, plan, rng)

	-- Whatever else landed there, nothing may block the way in from the
	-- tunnels: clear the passage from the east door to the tunnel mouth.
	-- (The map isn't in the workspace until generation finishes, so spatial
	-- queries find nothing yet; test each part's bounding box instead.)
	local reach = info.gymMouth.X + 14 - C.X
	local center = Vector3.new(C.X + reach / 2 + 1, F + 8, doorZ)
	local half = Vector3.new(reach - 2, 13, 11) / 2
	for _, p in ipairs(parent:GetDescendants()) do
		if p:IsA("BasePart") and not p:IsDescendantOf(shell) then
			local cf, s = p.CFrame, p.Size / 2
			local r, u, b = cf.RightVector, cf.UpVector, cf.LookVector
			local ext = Vector3.new(
				math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(b.X) * s.Z,
				math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(b.Y) * s.Z,
				math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(b.Z) * s.Z
			)
			local d = p.Position - center
			if math.abs(d.X) < half.X + ext.X and math.abs(d.Y) < half.Y + ext.Y and math.abs(d.Z) < half.Z + ext.Z then
				p:Destroy()
			end
		end
	end
	RouteCheck.add("gym passage (east door to tunnel)", { Vector3.new(C.X - 3, F, doorZ), Vector3.new(info.gymMouth.X + 14, F, doorZ) }, 4.5, 10)
end

return Gym
