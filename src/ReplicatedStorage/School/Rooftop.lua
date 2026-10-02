-- The rooftop reached from the top floor's east stairwell: a tight cluster
-- of building blocks at different heights, standing on a crag of rock and
-- joined by stairs, catwalks and ladders. A fishing trawler lies run
-- aground across the middle of it with its bow out over the drop; around
-- it a drained pool, a giant water tower, a radio mast, air-conditioning
-- plant, shipping containers, a billboard, and a tiny shrine on a pillar.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Ship = require(script.Parent.Ship)
local Clutter = require(script.Parent.RooftopClutter)
local CragFaces = require(script.Parent.CragFaces)

local part, cylinder, disc, model, place, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.disc, BuildUtil.model, BuildUtil.place, BuildUtil.jitter, BuildUtil.pick
local Concrete, Metal, Rust, Smooth = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.SmoothPlastic

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local RUST_COLOR = Color3.fromRGB(116, 76, 48)
local STEEL = Color3.fromRGB(120, 122, 124)
local LEVEL = Config.TOP_Y -- the top floor, where the stairwell lets out
local X0 = Config.TOTAL_LENGTH + Config.STAIRWELL_LENGTH + 0.5

-- The blocks: { name, x0, x1, z0, z1, top }.
local BLOCKS = {
	landing = { X0, X0 + 56, -40, 40, LEVEL },
	cradle = { X0 + 56, X0 + 256, -18, 58, LEVEL + 4 },
	pool = { X0 + 4, X0 + 136, -122, -44, LEVEL + 12 },
	mast = { X0 + 146, X0 + 246, -122, -34, LEVEL + 26 },
	tower = { X0 + 4, X0 + 96, 58, 164, LEVEL - 8 },
	plant = { X0 + 106, X0 + 260, 72, 164, LEVEL + 10 },
	shrine = { X0 + 262, X0 + 284, 104, 150, LEVEL + 43 },
}
-- Solid rock down to the courtyard's depth, so the tunnels and the
-- facility stair shaft (Underground.lua) can be cut into it.
local CRAG = { x0 = 468, x1 = 752, z0 = -124, z1 = 168, top = 20, bottom = Config.ROCK_BOTTOM - 80 }

local Rooftop = {}
Rooftop.BLOCKS = BLOCKS
Rooftop.CRAG = CRAG
-- Where the stair up from the landslide (GymSurrounds) lands on the pool
-- block; kept clear of clutter.
Rooftop.POOL_STAIR_LANDING = { x0 = X0 + 4, x1 = X0 + 14, z0 = -120, z1 = -104 }
-- Where the bridge to the department store (DepartmentStore.lua) leaves
-- the plant block's courtyard-side edge; kept clear of clutter.
Rooftop.BRIDGE = { x = 591, z = BLOCKS.plant[4], top = BLOCKS.plant[5] }

-- The trawler's pose: dumped across the cradle block, skewed and listing
-- hard to one side, her stern dug in and her bow hauled up off the roof by
-- the great chain from her stem.
local function shipPose(rng)
	local yaw = math.rad(rng:NextNumber(5, 9)) * pick({ -1, 1 }, rng)
	local list = math.rad(rng:NextNumber(6, 10)) * pick({ -1, 1 }, rng)
	local bowUp = math.rad(rng:NextNumber(12, 14))
	-- (pivoting on her stern, which rests on the cradle)
	return CFrame.new(X0 + 62 + rng:NextNumber(-3, 3), LEVEL + 2.5, 20 + rng:NextNumber(-3, 3)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(list, 0, bowUp) * CFrame.new(Ship.LENGTH / 2, 0, 0)
end

-- Where the hull meets the cradle: rubble crushed out along both sides, a
-- scraped trail behind the stern, and timber cribbing jammed under the
-- side that's lifted clear.
local function groundingDamage(parent, placement, cradle, rng)
	local top = cradle[5]
	local function onCradle(p)
		return p.X > cradle[1] + 1 and p.X < cradle[2] - 1 and p.Z > cradle[3] + 1 and p.Z < cradle[4] - 1
	end
	local grey = Color3.fromRGB(112, 108, 100)
	for _ = 1, 60 do
		local x = rng:NextNumber(-Ship.LENGTH / 2 + 6, Ship.LENGTH / 2 - 30)
		local side = pick({ -1, 1 }, rng)
		local p = placement:PointToWorldSpace(Vector3.new(x, 0, side * (Ship.BEAM / 2 + rng:NextNumber(-1, 6))))
		if onCradle(p) then
			local s = Vector3.new(rng:NextNumber(0.8, 3), rng:NextNumber(0.5, 1.8), rng:NextNumber(0.8, 3))
			part(parent, "GroundingRubble", s, CFrame.new(p.X, top + s.Y * 0.35, p.Z) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Concrete, jitter(grey, rng, 0.1))
		end
	end
	-- Scrape marks and slabs shoved up behind it.
	local sternMid = placement:PointToWorldSpace(Vector3.new(-Ship.LENGTH / 2, 0, 0))
	local back = placement:VectorToWorldSpace(Vector3.new(-1, 0, 0))
	back = Vector3.new(back.X, 0, back.Z).Unit
	for k = 1, 8 do
		local p = sternMid + back * rng:NextNumber(4, 40) + Vector3.new(0, 0, rng:NextNumber(-14, 14))
		if onCradle(p) then
			local slab = part(parent, "ShovedSlab", Vector3.new(rng:NextNumber(4, 9), 0.8, rng:NextNumber(3, 6)), CFrame.new(p.X, top + 0.6, p.Z) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 3), rng:NextNumber(-0.35, 0.35)), Concrete, jitter(grey, rng, 0.08))
			slab.Name = if k % 2 == 0 then "ShovedSlab" else "ScrapeMark"
		end
	end
	-- Raking shores: steel beams jammed up under her lifted belly.
	for _, x in ipairs({ -40, -10 }) do
		for _, side in ipairs({ -1, 1 }) do
			local hullPt = placement:PointToWorldSpace(Vector3.new(x, 1, side * (Ship.BEAM / 2 - 4)))
			local foot = Vector3.new(hullPt.X - 14, top, hullPt.Z + side * 10)
			if onCradle(foot) and hullPt.Y - top > 6 then
				local len = (hullPt - foot).Magnitude
				part(parent, "Shore", Vector3.new(1.6, 1.6, len), CFrame.lookAt((foot + hullPt) / 2, hullPt), Enum.Material.CorrodedMetal, jitter(RUST_COLOR, rng, 0.1))
				part(parent, "ShoreFoot", Vector3.new(4, 1, 4), CFrame.new(foot + Vector3.new(0, 0.5, 0)), Concrete, jitter(grey, rng, 0.1))
			end
		end
	end
	-- Cribbing under whichever side is lifted.
	for _, side in ipairs({ -1, 1 }) do
		for x = -Ship.LENGTH / 2 + 30, Ship.LENGTH / 2 - 60, 34 do
			local hull = placement:PointToWorldSpace(Vector3.new(x + rng:NextNumber(-6, 6), 0, side * (Ship.BEAM / 2 - 6)))
			local gap = hull.Y - top
			if gap > 1.2 and gap < 9 and onCradle(hull) then
				local layers = math.floor(gap / 1.2)
				for l = 0, layers - 1 do
					local along = if l % 2 == 0 then 0 else math.pi / 2
					part(parent, "Cribbing", Vector3.new(7, 1.2, 1.4), CFrame.new(hull.X, top + 0.6 + l * 1.2, hull.Z) * CFrame.Angles(0, along + rng:NextNumber(-0.15, 0.15), 0) * CFrame.new(0, 0, rng:NextNumber(-1.5, 1.5)), Enum.Material.Wood, jitter(Color3.fromRGB(96, 76, 54), rng, 0.1))
				end
			end
		end
	end
end

-- Footprints {x0, x1, z0, z1} already taken on the rooftop. Every feature
-- records its space here, and the clutter pass only fills what's left.
local occupied = {}

local function occupy(x0, x1, z0, z1)
	table.insert(occupied, { x0, x1, z0, z1 })
end

-- Conservative box round a straight run (stairs, catwalks).
local function occupyRun(a, b, halfWidth)
	occupy(math.min(a.X, b.X) - halfWidth, math.max(a.X, b.X) + halfWidth, math.min(a.Z, b.Z) - halfWidth, math.max(a.Z, b.Z) + halfWidth)
end

local function isFree(x, z, r)
	for _, o in ipairs(occupied) do
		if x + r > o[1] and x - r < o[2] and z + r > o[3] and z - r < o[4] then
			return false
		end
	end
	return true
end

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

-- Cylinder rod between two points.
local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

-- Straight flight of concrete steps from `a` (lower) to `b` (higher), with
-- railings both sides.
local function stairs(parent, a, b, width)
	occupyRun(a, b, width / 2 + 2)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dir = flat.Unit
	local across = Vector3.new(-dir.Z, 0, dir.X)
	local rise = b.Y - a.Y
	local steps = math.max(1, math.ceil(math.abs(rise) / 0.9))
	local stepRise, stepRun = rise / steps, flat.Magnitude / steps
	for i = 1, steps do
		local top = a.Y + stepRise * i
		local at = a + dir * stepRun * (i - 0.5)
		local h = math.abs(stepRise) + 1.2
		local center = Vector3.new(at.X, top - h / 2, at.Z)
		part(parent, "Step", Vector3.new(width, h, stepRun + 0.05), CFrame.lookAt(center, center + dir), Concrete, Color3.fromRGB(128, 126, 118))
	end
	for _, s in ipairs({ -1, 1 }) do
		local off = across * s * (width / 2 - 0.2)
		rod(parent, "StairRail", a + off + Vector3.new(0, 3.2, 0), b + off + Vector3.new(0, 3.2, 0), 0.25, Metal, STEEL)
		rod(parent, "StairRailPost", a + off, a + off + Vector3.new(0, 3.2, 0), 0.2, Metal, STEEL)
		rod(parent, "StairRailPost", b + off, b + off + Vector3.new(0, 3.2, 0), 0.2, Metal, STEEL)
	end
end

-- A steel-plate walkway (flat or sloping) from a to b with railings and
-- legs down to `groundY` at each end.
-- A way up onto the ship from a to b: a catwalk if it's gentle, a stair
-- on legs if it's steep.
local catwalk
local function boarding(parent, a, b, width, groundY)
	local run = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
	if math.abs(b.Y - a.Y) / math.max(run, 1) < 0.35 then
		catwalk(parent, a, b, width, groundY)
		return
	end
	stairs(parent, a, b, width)
	for t = 0.25, 0.9, 0.25 do
		local p = a:Lerp(b, t)
		rod(parent, "StairLeg", p - Vector3.new(0, 1, 0), Vector3.new(p.X, groundY, p.Z), 0.8, Rust, RUST_COLOR)
	end
end

function catwalk(parent, a, b, width, groundY)
	occupyRun(a, b, width / 2 + 2)
	local dir = (b - a).Unit
	local flat = Vector3.new(dir.X, 0, dir.Z).Unit
	local across = Vector3.new(-flat.Z, 0, flat.X)
	local mid = (a + b) / 2
	part(parent, "Catwalk", Vector3.new(width, 0.4, (b - a).Magnitude + 0.5), CFrame.lookAt(mid - Vector3.new(0, 0.2, 0), b - Vector3.new(0, 0.2, 0)), Enum.Material.DiamondPlate, Color3.fromRGB(110, 106, 98))
	for _, s in ipairs({ -1, 1 }) do
		local off = across * s * (width / 2 - 0.15)
		rod(parent, "CatwalkRail", a + off + Vector3.new(0, 3.2, 0), b + off + Vector3.new(0, 3.2, 0), 0.25, Metal, STEEL)
		for _, p in ipairs({ a, mid, b }) do
			rod(parent, "CatwalkPost", p + off, p + off + Vector3.new(0, 3.2, 0), 0.2, Metal, STEEL)
		end
	end
	if groundY then
		rod(parent, "CatwalkLeg", mid, Vector3.new(mid.X, groundY, mid.Z), 0.8, Rust, RUST_COLOR)
	end
end

-- Chain-link fence from a to b (on the XZ plane) standing on `baseY`.
local function chainFence(parent, a, b, baseY, height, rng)
	local dir = b - a
	local panels = math.max(1, math.floor(dir.Magnitude / 10))
	local step = dir / panels
	for i = 0, panels do
		local p = a + step * i
		cylinder(parent, "FencePost", height, 0.35, CFrame.new(p.X, baseY + height / 2, p.Z) * UPRIGHT, Metal, STEEL)
		if i < panels then
			local mid = a + step * (i + 0.5)
			local frame = CFrame.lookAt(Vector3.new(mid.X, baseY + height / 2, mid.Z), Vector3.new(mid.X, baseY + height / 2, mid.Z) + dir)
			part(parent, "FenceRail", Vector3.new(0.2, 0.2, step.Magnitude), frame * CFrame.new(0, height / 2, 0), Metal, STEEL)
			local roll = rng:NextNumber()
			if roll > 0.12 then
				-- Sagging panels lean over, hinged at their bottom edge.
				local lean = if roll < 0.22 then CFrame.Angles(0, 0, math.rad(rng:NextNumber(10, 25))) else CFrame.identity
				local mesh = part(parent, "FenceMesh", Vector3.new(0.08, height - 0.4, step.Magnitude - 0.2), frame * CFrame.new(0, -height / 2, 0) * lean * CFrame.new(0, height / 2 - 0.2, 0), Metal, Color3.fromRGB(150, 152, 150))
				mesh.Transparency = 0.72
			end
		end
	end
end

-- ===== Ground =====

-- The rock the cluster stands on, over a concrete pillar vanishing into the
-- haze. The rock face is also what the bottom floor's east door opens onto.
-- The crag's north face (towards the courtyard's far corner and the
-- department store) and the top of its courtyard-side edge are what you
-- see of it from the school, so break them up: tall buttresses of rock
-- standing out from the face, lumpier stretches between, the north-west
-- corner rounded off in big masses, an uneven ridge along the top edges
-- with grass caught on it. (The tunnels are carved afterwards, so extra
-- rock inside the crag costs nothing.) Kept low under the store bridge.
local function sculptCrag(c, rng)
	local terrain = workspace.Terrain
	local seed = rng:NextNumber(0, 1000)
	local west = Config.TOTAL_LENGTH + Config.WING_THICKNESS
	local function rock()
		local roll = rng:NextNumber()
		return if roll < 0.2 then Enum.Material.Slate elseif roll < 0.32 then Enum.Material.Basalt else Enum.Material.Rock
	end
	local nextButtress = west + rng:NextNumber(10, 30)
	for x = west + 2, c.x1 - 4, 8 do
		local buttress = x >= nextButtress
		if buttress then
			nextButtress = x + rng:NextNumber(30, 55)
		end
		local y = -250 + rng:NextNumber(0, 20)
		while y < 16 do
			local r
			local out
			if buttress then
				r = rng:NextNumber(10, 16)
				out = rng:NextNumber(0.35, 0.7)
			else
				r = rng:NextNumber(5, 10) * (1 + 0.4 * math.noise(x / 40, y / 40, seed))
				out = rng:NextNumber(0.05, 0.45)
			end
			local cy = math.min(y, 20 - r * 0.6)
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-3, 3), cy, c.z1 + r * out), r, rock())
			y += r * rng:NextNumber(0.9, 1.4)
		end
	end
	-- The north-west corner, rounded off.
	for _ = 1, 6 do
		local r = rng:NextNumber(12, 20)
		terrain:FillBall(Vector3.new(west + 10 + rng:NextNumber(-2, 8), rng:NextNumber(-140, 20 - r), c.z1 + rng:NextNumber(-2, 4)), r, rock())
	end
	-- Ridges along the top of the north edge and the courtyard-side edge.
	local bridgeX = Rooftop.BRIDGE.x
	local function ridge(at)
		local nearBridge = math.abs(at.X - bridgeX) < 12 and at.Z > c.z1 - 10
		local r = rng:NextNumber(3.5, 7)
		local rise = (math.noise(at.X / 24, at.Z / 24, seed + 3) + 0.6) * 6
		if nearBridge then
			rise = math.min(rise, 3)
		end
		if rise > 0.5 then
			terrain:FillBall(at + Vector3.new(0, c.top + rise - r, 0), r, if rng:NextNumber() < 0.15 then Enum.Material.LeafyGrass else rock())
		end
	end
	for x = west + 2, c.x1 - 4, 6 do
		ridge(Vector3.new(x + rng:NextNumber(-2, 2), 0, c.z1 - rng:NextNumber(0, 3)))
	end
	for z = Config.COURTYARD_NEAR_Z + 4, c.z1, 6 do
		ridge(Vector3.new(west + rng:NextNumber(1, 4), 0, z + rng:NextNumber(-2, 2)))
	end
end

local function crag(parent, rng)
	local terrain = workspace.Terrain
	local c = CRAG
	terrain:FillBlock(CFrame.new((c.x0 + c.x1) / 2, (c.bottom + c.top) / 2, (c.z0 + c.z1) / 2), Vector3.new(c.x1 - c.x0, c.top - c.bottom, c.z1 - c.z0), Enum.Material.Rock)
	-- Close the slot between the crag and the courtyard's end wall.
	local wallFace = Config.TOTAL_LENGTH + Config.WING_THICKNESS
	terrain:FillBlock(CFrame.new((wallFace + c.x0) / 2, (c.bottom + c.top) / 2, (Config.COURTYARD_NEAR_Z + c.z1) / 2), Vector3.new(c.x0 - wallFace, c.top - c.bottom, c.z1 - Config.COURTYARD_NEAR_Z), Enum.Material.Rock)
	-- Boulders bulging out of the sides so it isn't a clean box.
	for _ = 1, 24 do
		local side = rng:NextInteger(1, 3)
		local x, z
		if side == 1 then
			x, z = rng:NextNumber(c.x0 + 20, c.x1 - 40), c.z0 + rng:NextNumber(-6, 10)
		elseif side == 2 then
			x, z = rng:NextNumber(c.x0 + 20, c.x1 - 40), c.z1 + rng:NextNumber(-10, 6)
		else
			x, z = c.x1 + rng:NextNumber(-8, 6), if rng:NextNumber() < 0.5 then rng:NextNumber(c.z0, -30) else rng:NextNumber(80, c.z1)
		end
		terrain:FillBall(Vector3.new(x, rng:NextNumber(-100, 4), z), rng:NextNumber(10, 18), Enum.Material.Rock)
	end
	sculptCrag(c, rng)
	-- The south and east faces, the waterfall, the adits, the root of rock
	-- under it; a slim pillar of concrete below that, deep in the haze.
	CragFaces.build(parent, c, rng)
	local cx, cz = (c.x0 + c.x1) / 2, (c.z0 + c.z1) / 2
	box(parent, "CragPillar", cx - 30, cx + 30, -1900, c.bottom - 290, cz - 30, cz + 30, Concrete, Color3.fromRGB(78, 78, 76))
end

-- The rock comes up through the ground. The water tower's block barely
-- stands clear of the crag, so lumps and boulders heave up through it
-- (lower in under the tower itself), and the bare crag top between the
-- blocks gets knuckles of rock too. Lumps are recorded as occupied so the
-- clutter pass steers round them.
local function rockyGround(towerCenter, rng)
	local terrain = workspace.Terrain
	local seed = rng:NextNumber(0, 1000)
	local function material()
		local roll = rng:NextNumber()
		if roll < 0.08 then
			return Enum.Material.LeafyGrass
		elseif roll < 0.16 then
			return Enum.Material.Ground
		elseif roll < 0.4 then
			return Enum.Material.Slate
		elseif roll < 0.55 then
			return Enum.Material.Basalt
		end
		return Enum.Material.Rock
	end
	local W = BLOCKS.tower
	local function nearTower(x, z, r)
		return (Vector3.new(x, 0, z) - Vector3.new(towerCenter.X, 0, towerCenter.Z)).Magnitude < r
	end
	-- The water tower's block has no concrete under it: it's the top of an
	-- outcrop. Level ground in the middle (where the tower, the containers
	-- and the stairs stand), and round it an edge that wanders in and out,
	-- rolling down over the crag's rim instead of stopping in a straight
	-- line, with tors of rock heaped up along it.
	local cx, cz = (W[1] + W[2]) / 2, (W[3] + W[4]) / 2
	local hx, hz = (W[2] - W[1]) / 2, (W[4] - W[3]) / 2
	terrain:FillBlock(CFrame.new(cx, W[5] - 1.4, cz), Vector3.new(W[2] - W[1] - 16, 4, W[4] - W[3] - 16), Enum.Material.Rock)
	local function edgeDistance(x, z)
		-- signed: negative inside the block, positive outside it
		local ex, ez = math.abs(x - cx) - hx, math.abs(z - cz) - hz
		if ex > 0 or ez > 0 then
			return math.sqrt(math.max(ex, 0) ^ 2 + math.max(ez, 0) ^ 2)
		end
		return math.max(ex, ez)
	end
	for x = W[1] - 12, W[2] + 12, 4.5 do
		for z = W[3] - 12, W[4] + 12, 4.5 do
			local jx, jz = x + rng:NextNumber(-1.5, 1.5), z + rng:NextNumber(-1.5, 1.5)
			local e = edgeDistance(jx, jz) + math.noise(jx / 26, jz / 26, seed + 11) * 9 + math.noise(jx / 8, jz / 8, seed + 12) * 2.5
			if e > -10 and e < 12 then
				-- Level to just inside the edge, then rolling off ever steeper.
				local drop = if e < -3 then 0 else (e + 3) ^ 2 * 0.09
				local r = rng:NextNumber(4, 6.5)
				terrain:FillBall(Vector3.new(jx, W[5] + 0.3 - drop - r, jz), r, if drop > 6 and rng:NextNumber() < 0.5 then Enum.Material.Slate else material())
			end
		end
	end
	-- Bulges of rock out over the drop on the open sides (the courtyard
	-- side and the north), so the rim isn't a sheer box edge.
	for z = W[3] + 4, W[4] - 2, 7 do
		local r = rng:NextNumber(6, 11)
		terrain:FillBall(Vector3.new(CRAG.x0 - r * rng:NextNumber(0.1, 0.45), W[5] - r * rng:NextNumber(0.6, 1.3), z + rng:NextNumber(-2, 2)), r, material())
	end
	for x = W[1] + 4, W[2] - 2, 7 do
		local r = rng:NextNumber(6, 11)
		terrain:FillBall(Vector3.new(x + rng:NextNumber(-2, 2), W[5] - r * rng:NextNumber(0.6, 1.3), CRAG.z1 + r * rng:NextNumber(0.1, 0.45)), r, material())
	end
	-- Tors heaped along the edge, clear of the stairs and anything else
	-- standing there.
	local around = 2 * (W[2] - W[1]) + 2 * (W[4] - W[3])
	local t = rng:NextNumber(0, 10)
	while t < around do
		local x, z
		if t < W[2] - W[1] then
			x, z = W[1] + t, W[4]
		elseif t < (W[2] - W[1]) + (W[4] - W[3]) then
			x, z = W[2], W[4] - (t - (W[2] - W[1]))
		elseif t < 2 * (W[2] - W[1]) + (W[4] - W[3]) then
			x, z = W[2] - (t - (W[2] - W[1]) - (W[4] - W[3])), W[3]
		else
			x, z = W[1], W[3] + (t - 2 * (W[2] - W[1]) - (W[4] - W[3]))
		end
		-- a little way in from the edge
		local ix, iz = cx - x, cz - z
		local len = math.sqrt(ix * ix + iz * iz)
		x, z = x + ix / len * rng:NextNumber(2, 6), z + iz / len * rng:NextNumber(2, 6)
		if isFree(x, z, 5) and not nearTower(x, z, 26) then
			local pieces = rng:NextInteger(2, 4)
			for _ = 1, pieces do
				local r = rng:NextNumber(3, 7)
				local rise = rng:NextNumber(2, 8)
				terrain:FillBall(Vector3.new(x + rng:NextNumber(-3, 3), W[5] + rise - r, z + rng:NextNumber(-3, 3)), r, material())
			end
			if rng:NextNumber() < 0.5 then
				local size = Vector3.new(rng:NextNumber(3, 7), rng:NextNumber(3, 7), rng:NextNumber(2, 5))
				terrain:FillBlock(CFrame.new(x, W[5] + size.Y * 0.3, z) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, math.pi), rng:NextNumber(-0.5, 0.5)), size, Enum.Material.Slate)
			end
			occupy(x - 6, x + 6, z - 6, z + 6)
		end
		t += rng:NextNumber(8, 16)
	end
	-- Lumps heaving up through it: ridged noise for the big shapes, random
	-- jitter for the small ones. Low under the tower itself.
	for x = W[1] + 2.5, W[2] - 2.5, 4.5 do
		for z = W[3] + 2.5, W[4] - 2.5, 4.5 do
			local jx, jz = x + rng:NextNumber(-2, 2), z + rng:NextNumber(-2, 2)
			local r = rng:NextNumber(2.5, 6.5)
			local underTower = nearTower(jx, jz, 20)
			if underTower or isFree(jx, jz, r * 0.6) then
				local n = 1 - math.abs(math.noise(jx / 34, jz / 34, seed)) * 2
				local rise = n * 9 + math.noise(jx / 9, jz / 9, seed + 5) * 4 + rng:NextNumber(-1, 3)
				if underTower then
					rise = math.min(rise, 2.5)
				end
				if rise > 0.3 then
					terrain:FillBall(Vector3.new(jx, W[5] + rise - r, jz), r, material())
					if not underTower then
						occupy(jx - r * 0.6, jx + r * 0.6, jz - r * 0.6, jz + r * 0.6)
					end
				end
			end
		end
	end
	-- Angular slabs and boulders jutting out at odd angles.
	for _ = 1, 30 do
		local x, z = rng:NextNumber(W[1] + 4, W[2] - 4), rng:NextNumber(W[3] + 4, W[4] - 4)
		local size = Vector3.new(rng:NextNumber(3, 9), rng:NextNumber(2, 6), rng:NextNumber(3, 8))
		if not nearTower(x, z, 20) and isFree(x, z, math.max(size.X, size.Z) * 0.5) then
			local cf = CFrame.new(x, W[5] + size.Y * rng:NextNumber(0.1, 0.4), z) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, math.pi), rng:NextNumber(-0.6, 0.6))
			terrain:FillBlock(cf, size, if rng:NextNumber() < 0.5 then Enum.Material.Slate else Enum.Material.Rock)
			occupy(x - size.X * 0.5, x + size.X * 0.5, z - size.Z * 0.5, z + size.Z * 0.5)
		end
	end
	local function insideBlock(x, z, margin)
		for _, b in pairs(BLOCKS) do
			if x > b[1] - margin and x < b[2] + margin and z > b[3] - margin and z < b[4] + margin then
				return true
			end
		end
		return false
	end
	for _ = 1, 110 do
		local x, z = rng:NextNumber(CRAG.x0 + 3, CRAG.x1 - 3), rng:NextNumber(CRAG.z0 + 3, CRAG.z1 - 3)
		if not insideBlock(x, z, 2) and isFree(x, z, 3) then
			local r = rng:NextNumber(2.5, 6)
			terrain:FillBall(Vector3.new(x, CRAG.top + rng:NextNumber(0.5, 5) - r, z), r, material())
		end
	end
end

-- A building block with dark bands wrapped round it.
local function block(parent, b, rng)
	local color = jitter(Color3.fromRGB(112, 108, 100), rng, 0.08)
	box(parent, "RoofBlock", b[1], b[2], 0, b[5], b[3], b[4], Concrete, color)
	local y = b[5] - rng:NextNumber(5, 9)
	while y > 22 do
		box(parent, "BlockBand", b[1] - 0.4, b[2] + 0.4, y - 1.5, y + 1.5, b[3] - 0.4, b[4] + 0.4, Smooth, Color3.fromRGB(30, 32, 34))
		y -= rng:NextNumber(8, 12)
	end
	-- A thin parapet lip round the top edge.
	box(parent, "Coping", b[1] - 0.3, b[2] + 0.3, b[5], b[5] + 0.5, b[3] - 0.3, b[4] + 0.3, Concrete, Color3.fromRGB(130, 126, 118))
end

-- ===== Features =====

-- A drained school pool on a raised platform, fenced in, with steps up on
-- the west side.
local function pool(parent, c, baseY, rng)
	local m = model(parent, "RooftopPool")
	local PL, PW, depth, rim = 96, 44, 6, 8
	local top = baseY + 7
	local floorY = top - depth
	local halfL, halfW = PL / 2 + rim, PW / 2 + rim
	local walkColor = Color3.fromRGB(150, 146, 136)
	local tile = Color3.fromRGB(156, 182, 184)

	local function slab(name, cx, cz, sx, sz, y0, y1, material, color)
		return part(m, name, Vector3.new(sx, y1 - y0, sz), Vector3.new(c.X + cx, (y0 + y1) / 2, c.Z + cz), material, color)
	end
	slab("PoolSurround", 0, -(PW / 2 + rim / 2), PL + rim * 2, rim, baseY, top, Concrete, walkColor)
	slab("PoolSurround", 0, PW / 2 + rim / 2, PL + rim * 2, rim, baseY, top, Concrete, walkColor)
	slab("PoolSurround", -(PL / 2 + rim / 2), 0, rim, PW, baseY, top, Concrete, walkColor)
	slab("PoolSurround", PL / 2 + rim / 2, 0, rim, PW, baseY, top, Concrete, walkColor)
	slab("PoolBase", 0, 0, PL, PW, baseY, floorY, Concrete, walkColor)

	slab("PoolTiles", 0, 0, PL, PW, floorY, floorY + 0.15, Enum.Material.CeramicTiles, tile)
	for _, s in ipairs({ -1, 1 }) do
		slab("PoolTiles", 0, s * (PW / 2 - 0.1), PL, 0.2, floorY, top, Enum.Material.CeramicTiles, tile)
		slab("PoolTiles", s * (PL / 2 - 0.1), 0, 0.2, PW, floorY, top, Enum.Material.CeramicTiles, tile)
	end
	for _ = 1, rng:NextInteger(8, 16) do
		slab("MissingTiles", rng:NextNumber(-PL / 2 + 3, PL / 2 - 3), rng:NextNumber(-PW / 2 + 3, PW / 2 - 3), rng:NextNumber(1.5, 5), rng:NextNumber(1.5, 5), floorY + 0.15, floorY + 0.17, Concrete, Color3.fromRGB(96, 96, 92))
	end

	local lanes = 6
	for i = 1, lanes - 1 do
		local z = -PW / 2 + PW * i / lanes
		slab("LaneLine", 0, z, PL - 10, 0.8, floorY + 0.15, floorY + 0.19, Smooth, Color3.fromRGB(40, 60, 96))
		for _, s in ipairs({ -1, 1 }) do
			slab("LaneT", s * (PL / 2 - 5), z, 0.8, 3, floorY + 0.15, floorY + 0.19, Smooth, Color3.fromRGB(40, 60, 96))
		end
	end

	local puddleLen = rng:NextNumber(18, 32)
	local water = slab("StagnantWater", PL / 2 - puddleLen / 2 - 0.3, 0, puddleLen, PW - 0.6, floorY + 0.15, floorY + 0.55, Smooth, Color3.fromRGB(46, 62, 46))
	water.Transparency = 0.25
	water.Reflectance = 0.2
	water.CanCollide = false

	for i = 1, lanes do
		if rng:NextNumber() > 0.15 then
			local z = -PW / 2 + PW * (i - 0.5) / lanes
			part(m, "StartingBlock", Vector3.new(2.4, 2, 2.4), CFrame.new(c.X - PL / 2 - 1.6, top + 1, c.Z + z) * CFrame.Angles(0, 0, math.rad(-8)), Concrete, Color3.fromRGB(196, 194, 186))
		end
	end

	for _, s in ipairs({ -1, 1 }) do
		for _, lx in ipairs({ -PL / 4, PL / 4 }) do
			local wallZ = c.Z + s * (PW / 2 - 0.2)
			for _, off in ipairs({ -0.9, 0.9 }) do
				local x = c.X + lx + off
				rod(m, "LadderRail", Vector3.new(x, floorY + 0.2, wallZ - s * 0.6), Vector3.new(x, top + 2.5, wallZ - s * 0.6), 0.2, Metal, STEEL)
			end
			for y = floorY + 1, top - 1, 1.2 do
				part(m, "LadderRung", Vector3.new(1.8, 0.15, 0.4), Vector3.new(c.X + lx, y, wallZ - s * 0.6), Metal, STEEL)
			end
		end
	end

	local stepCount = 5
	local rise = (top - baseY) / stepCount
	for i = 1, stepCount do
		part(m, "PoolStep", Vector3.new(1.8, rise * (stepCount - i + 1), 10), Vector3.new(c.X - halfL - 0.9 - (i - 1) * 1.8, baseY + rise * (stepCount - i + 1) / 2, c.Z), Concrete, walkColor)
	end

	local corners = {
		Vector3.new(c.X - halfL + 0.5, 0, c.Z - halfW + 0.5),
		Vector3.new(c.X + halfL - 0.5, 0, c.Z - halfW + 0.5),
		Vector3.new(c.X + halfL - 0.5, 0, c.Z + halfW - 0.5),
		Vector3.new(c.X - halfL + 0.5, 0, c.Z + halfW - 0.5),
	}
	chainFence(m, corners[1], corners[2], top, 8, rng)
	chainFence(m, corners[2], corners[3], top, 8, rng)
	chainFence(m, corners[3], corners[4], top, 8, rng)
	chainFence(m, corners[4], Vector3.new(corners[4].X, 0, c.Z + 6), top, 8, rng)
	chainFence(m, Vector3.new(corners[1].X, 0, c.Z - 6), corners[1], top, 8, rng)

	part(m, "ChangingHut", Vector3.new(8, 8, 8), Vector3.new(c.X + halfL - 6, top + 4, c.Z + halfW - 6), Concrete, Color3.fromRGB(176, 170, 156))
end

local function waterTower(parent, c, baseY, rng)
	local m = model(parent, "WaterTower")
	local legH, tankR, tankH, spread = 60, 24, 40, 18
	local tankColor = jitter(Color3.fromRGB(132, 118, 100), rng, 0.08)

	local corners = {}
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			table.insert(corners, Vector3.new(c.X + sx * spread, 0, c.Z + sz * spread))
		end
	end
	for _, p in ipairs(corners) do
		cylinder(m, "TowerLeg", legH, 2.8, CFrame.new(p.X, baseY + legH / 2, p.Z) * UPRIGHT, Rust, RUST_COLOR)
		part(m, "LegFooting", Vector3.new(5, 2, 5), Vector3.new(p.X, baseY + 1, p.Z), Concrete, Color3.fromRGB(120, 118, 110))
	end
	local order = { 1, 2, 4, 3 }
	for level = 0, 2 do
		local y0, y1 = baseY + 4 + level * 18, baseY + 22 + level * 18
		for i = 1, 4 do
			local a, b = corners[order[i]], corners[order[i % 4 + 1]]
			rod(m, "TowerBrace", Vector3.new(a.X, y1, a.Z), Vector3.new(b.X, y1, b.Z), 1, Rust, RUST_COLOR)
			rod(m, "TowerBrace", Vector3.new(a.X, y0, a.Z), Vector3.new(b.X, y1, b.Z), 0.8, Rust, RUST_COLOR)
		end
	end

	local tankY = baseY + legH + tankH / 2
	part(m, "TankFloor", Vector3.new(spread * 2 + 8, 1.2, spread * 2 + 8), Vector3.new(c.X, baseY + legH + 0.6, c.Z), Rust, RUST_COLOR)
	cylinder(m, "Tank", tankH, tankR * 2, CFrame.new(c.X, tankY, c.Z) * UPRIGHT, Rust, tankColor)
	local roofY = baseY + legH + tankH
	for i, tier in ipairs({ { tankR * 2 + 1, 1.2 }, { tankR * 1.5, 3 }, { tankR, 3 }, { tankR * 0.45, 2.5 }, { 2.5, 4 } }) do
		cylinder(m, "TankRoof", tier[2], tier[1], CFrame.new(c.X, roofY + tier[2] / 2, c.Z) * UPRIGHT, Rust, if i == 1 then RUST_COLOR else tankColor)
		roofY += tier[2] * 0.8
	end
	for _ = 1, rng:NextInteger(8, 14) do
		local a = rng:NextNumber(0, math.pi * 2)
		local h = rng:NextNumber(8, tankH - 2)
		local at = Vector3.new(c.X + math.cos(a) * (tankR + 0.05), tankY + tankH / 2 - h / 2, c.Z + math.sin(a) * (tankR + 0.05))
		local streak = part(m, "RustStreak", Vector3.new(rng:NextNumber(1, 4), h, 0.1), CFrame.lookAt(at, at + Vector3.new(math.cos(a), 0, math.sin(a))), Smooth, RUST_COLOR)
		streak.Transparency = 0.35
		streak.CanCollide = false
	end
	-- A climbable ladder up one leg to the tank walkway.
	local ladder = Instance.new("TrussPart")
	ladder.Name = "TowerLadder"
	ladder.Anchored = true
	ladder.Size = Vector3.new(2, legH, 2)
	ladder.Position = Vector3.new(c.X - spread - 2, baseY + legH / 2, c.Z)
	ladder.Material = Rust
	ladder.Color = RUST_COLOR
	ladder.Parent = m
end

-- Tapering lattice mast with red beacons.
local function radioMast(parent, c, baseY, height, rng)
	local m = model(parent, "RadioMast")
	local baseHalf, topHalf = 14, 2.5
	local color = Color3.fromRGB(150, 70, 56)
	part(m, "MastPad", Vector3.new(34, 2, 34), Vector3.new(c.X, baseY + 1, c.Z), Concrete, Color3.fromRGB(120, 118, 110))

	local function corner(sx, sz, y)
		local half = baseHalf + (topHalf - baseHalf) * ((y - baseY) / height)
		return Vector3.new(c.X + sx * half, y, c.Z + sz * half)
	end
	local signs = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }
	for _, s in ipairs(signs) do
		rod(m, "MastLeg", corner(s[1], s[2], baseY), corner(s[1], s[2], baseY + height), 1.6, Metal, color)
	end
	local levels = math.floor(height / 22)
	for k = 1, levels do
		local y0, y1 = baseY + (k - 1) * 22, baseY + k * 22
		for i = 1, 4 do
			local a, b = signs[i], signs[i % 4 + 1]
			rod(m, "MastBar", corner(a[1], a[2], y1), corner(b[1], b[2], y1), 0.6, Metal, color)
			local from, to = if k % 2 == 0 then a else b, if k % 2 == 0 then b else a
			rod(m, "MastBrace", corner(from[1], from[2], y0), corner(to[1], to[2], y1), 0.5, Metal, color)
		end
	end
	cylinder(m, "Whip", 40, 0.8, CFrame.new(c.X, baseY + height + 20, c.Z) * UPRIGHT, Metal, STEEL)

	for _, y in ipairs({ baseY + height * 0.5, baseY + height, baseY + height + 40 }) do
		local beacon = part(m, "Beacon", Vector3.new(2, 2, 2), Vector3.new(c.X, y + 1, c.Z), Enum.Material.Neon, Color3.fromRGB(255, 40, 30))
		beacon.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 50, 40)
		light.Range = 50
		light.Brightness = 2
		light.Parent = beacon
	end
end

local function hvacUnit(parent, c, rng)
	local m = model(parent, "AirConditioner")
	local size = Vector3.new(rng:NextNumber(12, 20), rng:NextNumber(7, 11), rng:NextNumber(10, 16))
	local color = jitter(Color3.fromRGB(150, 152, 148), rng, 0.08)
	part(m, "UnitBody", size, c + Vector3.new(0, size.Y / 2, 0), Metal, color)
	local fanD = math.min(size.X, size.Z) * 0.7
	cylinder(m, "FanShroud", 1.2, fanD, CFrame.new(c + Vector3.new(0, size.Y + 0.6, 0)) * UPRIGHT, Metal, color)
	cylinder(m, "FanGrille", 0.1, fanD - 0.8, CFrame.new(c + Vector3.new(0, size.Y + 1.22, 0)) * UPRIGHT, Smooth, Color3.fromRGB(30, 30, 32))
	for i = -2, 2 do
		part(m, "Grille", Vector3.new(0.2, 0.1, fanD - 1), c + Vector3.new(i * fanD / 6, size.Y + 1.3, 0), Metal, color)
	end
	for i = 1, 5 do
		part(m, "SideVent", Vector3.new(0.1, 0.3, size.Z * 0.7), c + Vector3.new(size.X / 2 + 0.05, size.Y * (0.15 + i * 0.12), 0), Smooth, Color3.fromRGB(40, 40, 42))
	end
	return m
end

-- Vending machine facing -X. Sometimes, impossibly, still lit.
local function vendingMachine(parent, c, rng)
	local m = model(parent, "VendingMachine")
	local body = pick({ Color3.fromRGB(214, 210, 200), Color3.fromRGB(170, 40, 36), Color3.fromRGB(40, 80, 150) }, rng)
	part(m, "MachineBody", Vector3.new(3, 7.5, 4), c + Vector3.new(0, 3.75, 0), Metal, jitter(body, rng, 0.08))
	local lit = rng:NextNumber() < 0.5
	local window = part(m, "DisplayWindow", Vector3.new(0.1, 3.4, 3.4), c + Vector3.new(-1.55, 5.2, 0), if lit then Enum.Material.Neon else Smooth, if lit then Color3.fromRGB(210, 226, 236) else Color3.fromRGB(34, 36, 40))
	window.Transparency = if lit then 0.2 else 0
	for row = 0, 1 do
		for col = 0, 5 do
			part(m, "Drink", Vector3.new(0.3, 0.8, 0.4), c + Vector3.new(-1.6, 4.3 + row * 1.6, -1.3 + col * 0.52), Smooth, pick({ Color3.fromRGB(200, 40, 40), Color3.fromRGB(40, 120, 60), Color3.fromRGB(230, 190, 60), Color3.fromRGB(60, 90, 170) }, rng))
		end
	end
	part(m, "DispenserSlot", Vector3.new(0.2, 0.9, 2.6), c + Vector3.new(-1.55, 1.2, 0), Smooth, Color3.fromRGB(20, 20, 22))
	if lit then
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Left
		light.Range = 12
		light.Brightness = 1.2
		light.Color = Color3.fromRGB(210, 230, 255)
		light.Parent = window
		m:AddTag("FlickerLight")
	end
	return m
end

-- A tiny rooftop shrine: vermilion torii, a small wooden hokora and a pair
-- of stone lanterns. Deliberately small against everything else.
local function shrine(parent, c, baseY, rng)
	local m = model(parent, "RooftopShrine")
	local vermilion = Color3.fromRGB(176, 62, 44)
	local stone = Color3.fromRGB(128, 126, 118)
	local toriiX = c.X - 7
	for _, s in ipairs({ -1, 1 }) do
		cylinder(m, "ToriiPillar", 10, 1, CFrame.new(toriiX, baseY + 5, c.Z + s * 4) * UPRIGHT, Enum.Material.Wood, vermilion)
	end
	part(m, "Kasagi", Vector3.new(1.4, 1, 12.5), Vector3.new(toriiX, baseY + 10.5, c.Z), Enum.Material.Wood, Color3.fromRGB(40, 34, 30))
	part(m, "Nuki", Vector3.new(0.7, 0.7, 10), Vector3.new(toriiX, baseY + 8.3, c.Z), Enum.Material.Wood, vermilion)

	part(m, "HokoraBase", Vector3.new(4.5, 1.5, 4.5), Vector3.new(c.X + 4, baseY + 0.75, c.Z), Concrete, stone)
	part(m, "Hokora", Vector3.new(3, 3, 3), Vector3.new(c.X + 4, baseY + 3, c.Z), Enum.Material.Wood, Color3.fromRGB(120, 90, 62))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "HokoraRoof", Vector3.new(4.2, 0.3, 2.6), CFrame.new(c.X + 4, baseY + 5.1, c.Z + s * 1.0) * CFrame.Angles(s * math.rad(-30), 0, 0), Enum.Material.Wood, Color3.fromRGB(60, 50, 44))
	end
	for _, s in ipairs({ -1, 1 }) do
		local at = Vector3.new(c.X - 2, baseY, c.Z + s * 5)
		local lantern = model(m, "StoneLantern")
		part(lantern, "LanternBase", Vector3.new(1.4, 0.6, 1.4), at + Vector3.new(0, 0.3, 0), Concrete, stone)
		cylinder(lantern, "LanternPost", 2.6, 0.6, CFrame.new(at + Vector3.new(0, 1.9, 0)) * UPRIGHT, Concrete, stone)
		part(lantern, "LanternBox", Vector3.new(1.2, 1.1, 1.2), at + Vector3.new(0, 3.75, 0), Concrete, stone)
		part(lantern, "LanternCap", Vector3.new(1.8, 0.4, 1.8), at + Vector3.new(0, 4.5, 0), Concrete, stone)
		if s == 1 and rng:NextNumber() < 0.5 then
			BuildUtil.placeTilted(lantern, at, 0.9, rng:NextNumber(0, math.pi * 2), CFrame.Angles(0, 0, math.rad(90)))
		end
	end
end

-- 40ft shipping container, doors on the +X end.
local function container(parent, cframe, rng)
	local m = model(parent, "ShippingContainer")
	local color = jitter(pick({ Color3.fromRGB(150, 50, 40), Color3.fromRGB(40, 90, 120), Color3.fromRGB(180, 140, 50), Color3.fromRGB(70, 100, 70) }, rng), rng, 0.08)
	part(m, "ContainerBody", Vector3.new(36, 8.5, 8), CFrame.identity, Rust, color)
	for k = -8, 8 do
		part(m, "Corrugation", Vector3.new(0.5, 7.8, 8.2), CFrame.new(k * 2, 0, 0), Rust, BuildUtil.darken(color, 0.85))
	end
	part(m, "ContainerDoors", Vector3.new(0.2, 8, 7.6), CFrame.new(18.05, 0, 0), Rust, BuildUtil.darken(color, 0.8))
	m.WorldPivot = CFrame.identity
	m:PivotTo(cframe)
	return m
end

-- Street-style lamp; some long dead.
local function lampPost(parent, at, rng)
	occupy(at.X - 1.5, at.X + 4, at.Z - 1.5, at.Z + 1.5)
	cylinder(parent, "LampPost", 12, 0.6, CFrame.new(at + Vector3.new(0, 6, 0)) * UPRIGHT, Metal, Color3.fromRGB(60, 60, 62))
	part(parent, "LampArm", Vector3.new(3, 0.4, 0.4), at + Vector3.new(1.3, 11.8, 0), Metal, Color3.fromRGB(60, 60, 62))
	local lit = rng:NextNumber() < 0.6
	local head = part(parent, "LampHead", Vector3.new(1.6, 0.6, 1), at + Vector3.new(2.6, 11.4, 0), if lit then Enum.Material.Neon else Smooth, if lit then Color3.fromRGB(255, 220, 170) else Color3.fromRGB(80, 80, 78))
	if lit then
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 100
		light.Range = 30
		light.Brightness = 1.5
		light.Color = Color3.fromRGB(255, 214, 160)
		light.Parent = head
		if rng:NextNumber() < 0.3 then
			head:AddTag("FlickerLight")
		end
	end
end

-- A big rusted billboard frame on the edge of the mast block, facing out
-- over the drop.
local function billboard(parent, c, baseY, rng)
	local m = model(parent, "Billboard")
	local w, h, legH = 64, 26, 14
	for _, dx in ipairs({ -w / 3, 0, w / 3 }) do
		rod(m, "BillboardLeg", Vector3.new(c.X + dx, baseY, c.Z), Vector3.new(c.X + dx, baseY + legH + h, c.Z), 1.4, Rust, RUST_COLOR)
		rod(m, "BillboardBrace", Vector3.new(c.X + dx, baseY, c.Z + 10), Vector3.new(c.X + dx, baseY + legH + h * 0.6, c.Z), 0.8, Rust, RUST_COLOR)
	end
	local panel = part(m, "BillboardPanel", Vector3.new(w, h, 0.6), Vector3.new(c.X, baseY + legH + h / 2, c.Z - 1), Smooth, Color3.fromRGB(196, 186, 160))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 12
	local band = Instance.new("Frame")
	band.Size = UDim2.fromScale(1, 0.35)
	band.Position = UDim2.fromScale(0, 0.62)
	band.BorderSizePixel = 0
	band.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
	band.BackgroundTransparency = 0.3
	band.Parent = gui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.5)
	label.Position = UDim2.fromScale(0.05, 0.08)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(170, 40, 36)
	label.TextTransparency = 0.3
	label.Text = "海鳴りサイダー"
	label.Parent = gui
	gui.Parent = panel
	-- Torn: a few panels of the board missing.
	for _ = 1, rng:NextInteger(2, 5) do
		local hole = part(m, "TornPanel", Vector3.new(rng:NextNumber(4, 10), rng:NextNumber(3, 8), 0.7), Vector3.new(c.X + rng:NextNumber(-w / 2 + 6, w / 2 - 6), baseY + legH + rng:NextNumber(4, h - 4), c.Z - 1), Smooth, Color3.fromRGB(30, 30, 30))
		hole.CanCollide = false
	end
end

-- ===== Assembly =====

local function isRectFree(x0, x1, z0, z1)
	for _, o in ipairs(occupied) do
		if x1 > o[1] and x0 < o[2] and z1 > o[3] and z0 < o[4] then
			return false
		end
	end
	return true
end

-- Twin pipes on low supports running along one edge of a block, if that
-- edge is clear.
local function pipeRun(parent, b, rng)
	local z = if rng:NextNumber() < 0.5 then b[3] + 2.5 else b[4] - 2.5
	local xa, xb = b[1] + 4, b[2] - 4
	if xb - xa < 20 or not isRectFree(xa, xb, z - 1.5, z + 1.5) then
		return
	end
	occupy(xa, xb, z - 1.5, z + 1.5)
	for _, dz in ipairs({ -0.6, 0.6 }) do
		cylinder(parent, "Pipe", xb - xa, rng:NextNumber(0.6, 1.1), CFrame.new((xa + xb) / 2, b[5] + 1.6, z + dz), Rust, jitter(RUST_COLOR, rng, 0.1))
	end
	local x = xa + 2
	while x < xb - 1 do
		box(parent, "PipeSupport", x - 0.2, x + 0.2, b[5], b[5] + 1.2, z - 1.2, z + 1.2, Metal, STEEL)
		x += 8
	end
end

-- Clutter keeps its own looser record: pieces may crowd right up against
-- (or slightly into) each other, but never onto paths or features.
local clutterTaken = {}

local function clutterFree(x, z, r)
	for _, o in ipairs(clutterTaken) do
		if x + r > o[1] and x - r < o[2] and z + r > o[3] and z - r < o[4] then
			return false
		end
	end
	return true
end

local function pickClutter(rng, bigBoost)
	local function weight(e)
		return if e.big then e.weight * bigBoost else e.weight
	end
	local total = 0
	for _, e in ipairs(Clutter) do
		total += weight(e)
	end
	local roll = rng:NextNumber() * total
	for _, e in ipairs(Clutter) do
		roll -= weight(e)
		if roll <= 0 then
			return e
		end
	end
	return Clutter[1]
end

-- Fills a block unevenly: a few hotspots where clutter piles up tight,
-- the odd straggler elsewhere, and bare stretches in between. Each piece
-- is built at normal size, then scaled - usually modestly, occasionally a
-- lot - and turned to a random heading.
--
-- opts.bigBoost makes the big pieces that many times more common, and
-- opts.sizeSkew (default 2.5) controls how rarely pieces are scaled up;
-- lower means big sizes come up more often.
local function scatter(parent, b, rng, opts)
	opts = opts or {}
	local bigBoost, sizeSkew = opts.bigBoost or 1, opts.sizeSkew or 2.5
	local area = (b[2] - b[1]) * (b[4] - b[3])
	local busyness = rng:NextNumber(0.6, 1.5)

	local spots, spotWeight = {}, 0
	for _ = 1, rng:NextInteger(2, 5) do
		local spot = { x = rng:NextNumber(b[1], b[2]), z = rng:NextNumber(b[3], b[4]), r = rng:NextNumber(8, 30), w = rng:NextNumber(0.5, 1.5) }
		table.insert(spots, spot)
		spotWeight += spot.w
	end

	for _ = 1, math.floor(area / 90 * busyness) do
		local e = pickClutter(rng, bigBoost)
		local scale = e.min + (e.max - e.min) * rng:NextNumber() ^ sizeSkew
		local r = e.radius * scale

		for _ = 1, 8 do
			local x, z
			if rng:NextNumber() < 0.85 then
				local roll, spot = rng:NextNumber() * spotWeight, spots[1]
				for _, s in ipairs(spots) do
					roll -= s.w
					if roll <= 0 then
						spot = s
						break
					end
				end
				local a, d = rng:NextNumber(0, math.pi * 2), spot.r * rng:NextNumber() ^ 1.6
				x, z = spot.x + math.cos(a) * d, spot.z + math.sin(a) * d
			else
				x, z = rng:NextNumber(b[1], b[2]), rng:NextNumber(b[3], b[4])
			end

			local margin = math.min(r * 0.6, 4)
			local onBlock = x > b[1] + margin and x < b[2] - margin and z > b[3] + margin and z < b[4] - margin
			if onBlock and isFree(x, z, r * 0.8) and clutterFree(x, z, r * 0.35) then
				table.insert(clutterTaken, { x - r * 0.6, x + r * 0.6, z - r * 0.6, z + r * 0.6 })
				local c = Vector3.new(x, b[5], z)
				local holder = model(parent, "Clutter")
				e.build(holder, c, rng)
				holder.WorldPivot = CFrame.new(c)
				if scale ~= 1 then
					holder:ScaleTo(scale)
				end
				holder:PivotTo(CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				break
			end
		end
	end
end

-- Creepers hanging down the outside of a block from its top edge.
local function vines(parent, b, rng)
	local edges = {
		{ axis = "X", fixed = b[3], normal = -1, a = b[1], z = b[2] },
		{ axis = "X", fixed = b[4], normal = 1, a = b[1], z = b[2] },
		{ axis = "Z", fixed = b[1], normal = -1, a = b[3], z = b[4] },
		{ axis = "Z", fixed = b[2], normal = 1, a = b[3], z = b[4] },
	}
	for _, edge in ipairs(edges) do
		local along = edge.a + rng:NextNumber(2, 10)
		while along < edge.z - 2 do
			if rng:NextNumber() < 0.35 then
				for _ = 1, rng:NextInteger(3, 7) do
					local len = rng:NextNumber(4, math.min(28, b[5] - 22))
					local pos = along + rng:NextNumber(-2, 2)
					local size, center = BuildUtil.axisBox(edge.axis, rng:NextNumber(0.25, 0.6), len, 0.15, pos, b[5] - len / 2 + 0.3, edge.fixed + edge.normal * 0.15)
					local strand = part(parent, "Vine", size, center, Enum.Material.LeafyGrass, jitter(Color3.fromRGB(62, 86, 46), rng, 0.15))
					strand.CanCollide = false
				end
			end
			along += rng:NextNumber(6, 18)
		end
	end
end

function Rooftop.build(parent, rng)
	local B = BLOCKS
	occupied = {}
	crag(parent, rng)
	for _, b in pairs(B) do
		if b ~= B.tower then -- (the water tower stands on rock; see rockyGround)
			block(parent, b, rng)
		end
	end
	-- Keep the stairwell door and the landslide stair's landing clear.
	occupy(X0 - 1, X0 + 12, -12, 5)
	local sl = Rooftop.POOL_STAIR_LANDING
	occupy(sl.x0, sl.x1, sl.z0, sl.z1)
	occupy(Rooftop.BRIDGE.x - 7, Rooftop.BRIDGE.x + 7, Rooftop.BRIDGE.z - 16, Rooftop.BRIDGE.z + 1)

	-- Stairs and catwalks tying the blocks together.
	local L, P, W, H, M, S = B.landing, B.pool, B.tower, B.plant, B.mast, B.shrine
	stairs(parent, Vector3.new(X0 + 24, L[5], -24), Vector3.new(X0 + 24, P[5], P[4]), 8)
	stairs(parent, Vector3.new(X0 + 34, W[5], W[3]), Vector3.new(X0 + 34, L[5], L[4]), 8)
	stairs(parent, Vector3.new(X0 + 44, L[5], -12), Vector3.new(B.cradle[1] + 2, B.cradle[5], -12), 6)
	stairs(parent, Vector3.new(X0 + 70, W[5], 110), Vector3.new(H[1], H[5], 110), 8)
	stairs(parent, Vector3.new(X0 + 134, B.cradle[5], B.cradle[4]), Vector3.new(X0 + 134, H[5], H[3]), 8)
	stairs(parent, Vector3.new(P[2] - 4, P[5], -80), Vector3.new(M[1] + 1, M[5], -80), 7)

	-- A climbable ladder up the side of the shrine's pillar.
	local ladder = Instance.new("TrussPart")
	ladder.Name = "ShrineLadder"
	ladder.Anchored = true
	ladder.Size = Vector3.new(2, S[5] - H[5], 2)
	ladder.Position = Vector3.new(S[1] - 1, (S[5] + H[5]) / 2, 127)
	ladder.Material = Rust
	ladder.Color = RUST_COLOR
	ladder.Parent = parent
	occupy(S[1] - 3, S[2], S[3], S[4])

	-- By the stairwell door.
	for i, z in ipairs({ -18, -22.5 }) do
		local c = Vector3.new(X0 + 8, L[5], z)
		place(vendingMachine(parent, c, rng), c, Vector3.zero, math.rad((i - 1.5) * 4))
	end
	occupy(X0 + 5, X0 + 11, -25, -15)
	lampPost(parent, Vector3.new(X0 + 14, L[5], 30), rng)
	lampPost(parent, Vector3.new(X0 + 48, L[5], -34), rng)

	local poolCenter = Vector3.new(X0 + 72, P[5], -83)
	pool(parent, poolCenter, P[5], rng)
	occupy(poolCenter.X - 66, poolCenter.X + 56, poolCenter.Z - 30, poolCenter.Z + 30)
	local towerCenter = Vector3.new(X0 + 46, W[5], 112)
	waterTower(parent, towerCenter, W[5], rng)
	occupy(towerCenter.X - 24, towerCenter.X + 24, towerCenter.Z - 24, towerCenter.Z + 24)
	local mastCenter = Vector3.new(X0 + 196, M[5], -78)
	radioMast(parent, mastCenter, M[5], 380, rng)
	occupy(mastCenter.X - 18, mastCenter.X + 18, mastCenter.Z - 18, mastCenter.Z + 18)
	billboard(parent, Vector3.new(X0 + 196, 0, M[3] + 2), M[5], rng)
	occupy(X0 + 162, X0 + 230, M[3], M[3] + 14)
	shrine(parent, Vector3.new(S[1] + 12, S[5], 127), S[5], rng)

	rod(parent, "Duct", Vector3.new(H[1] + 20, H[5] + 4, 90), Vector3.new(H[2] - 10, H[5] + 4, 90), 3.5, Metal, STEEL)
	occupy(H[1] + 18, H[2] - 8, 87, 93)
	for _ = 1, rng:NextInteger(6, 9) do
		for _ = 1, 10 do
			local c = Vector3.new(rng:NextNumber(H[1] + 24, H[2] - 14), H[5], rng:NextNumber(H[3] + 14, H[4] - 12))
			if isFree(c.X, c.Z, 11) then
				occupy(c.X - 11, c.X + 11, c.Z - 9, c.Z + 9)
				place(hvacUnit(parent, c, rng), c, Vector3.zero, math.rad(rng:NextNumber(-5, 5)))
				break
			end
		end
	end
	lampPost(parent, Vector3.new(H[1] + 8, H[5], 150), rng)

	-- Shipping containers: stacked on the water tower block, and spilled
	-- beside the ship.
	for k = 0, rng:NextInteger(1, 2) do
		container(parent, CFrame.new(X0 + 82, W[5] + 4.25 + k * 8.5, 80) * CFrame.Angles(0, math.rad(90 + rng:NextNumber(-3, 3)), 0), rng)
	end
	occupy(X0 + 76, X0 + 88, 60, 100)
	container(parent, CFrame.new(B.cradle[1] + 150, B.cradle[5] + 4.25, 52) * CFrame.Angles(0, math.rad(rng:NextNumber(-6, 6)), 0), rng)
	occupy(B.cradle[1] + 130, B.cradle[1] + 170, 46, 58)
	container(parent, CFrame.new(B.cradle[1] + 110, B.cradle[5] + 3.6, 53) * CFrame.Angles(math.rad(80), math.rad(rng:NextNumber(-10, 10)), 0), rng)
	occupy(B.cradle[1] + 88, B.cradle[1] + 132, 46, 58)

	-- The trawler, and the ways aboard: a ramp up to the torn stern, a
	-- gangway up the -Z side to the deck, and a catwalk across from the
	-- plant block to the breach in its side. Built before the clutter so
	-- nothing lands in their way.
	local shipPlacement = shipPose(rng)
	local hx0, hx1, hz0, hz1 = math.huge, -math.huge, math.huge, -math.huge
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local c = shipPlacement:PointToWorldSpace(Vector3.new(sx * Ship.LENGTH / 2, 0, sz * Ship.BEAM / 2))
			hx0, hx1, hz0, hz1 = math.min(hx0, c.X), math.max(hx1, c.X), math.min(hz0, c.Z), math.max(hz1, c.Z)
		end
	end
	occupy(hx0 - 4, hx1 + 4, hz0 - 4, hz1 + 4)
	Ship.build(parent, shipPlacement, rng)
	groundingDamage(parent, shipPlacement, B.cradle, rng)
	local function onShip(x, y, z)
		return shipPlacement:PointToWorldSpace(Vector3.new(x, y, z))
	end
	local sternBreach = onShip(-Ship.LENGTH / 2 - 0.6, Ship.HOLD_Y - 0.5, 0)
	catwalk(parent, Vector3.new(X0 + 36, L[5], sternBreach.Z), sternBreach, 10, L[5])
	local gangwayTop = onShip(Ship.GANGWAY_X, Ship.DEPTH, -Ship.BEAM / 2 - 0.8)
	boarding(parent, Vector3.new(math.max(B.cradle[1] + 4, gangwayTop.X - 110), B.cradle[5], gangwayTop.Z - 12), gangwayTop, 6, B.cradle[5])
	local sideBreach = onShip(Ship.SIDE_BREACH_X, Ship.TWEEN_Y, Ship.BEAM / 2 + 0.8)
	boarding(parent, Vector3.new(math.max(H[1] + 6, sideBreach.X - 60), H[5], H[3] + 3), sideBreach, 7, H[5])

	rockyGround(towerCenter, rng)

	-- Pipe runs along block edges, creepers down their sides, then clutter
	-- in whatever space is left.
	clutterTaken = {}
	for _, b in ipairs({ B.landing, B.cradle, B.pool, B.mast, B.tower }) do
		pipeRun(parent, b, rng)
		scatter(parent, b, rng)
		task.wait()
	end
	-- The plant block below the shrine gets a heavier, more industrial mix.
	pipeRun(parent, B.plant, rng)
	scatter(parent, B.plant, rng, { bigBoost = 5, sizeSkew = 1.3 })
	for _, b in pairs(B) do
		vines(parent, b, rng)
	end
end

return Rooftop
