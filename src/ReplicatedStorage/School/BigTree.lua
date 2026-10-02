-- A colossal tree, planned first and built second so whatever it grows
-- through (the gym) can open up holes where its roots and trunk pass.
--
--   plan = BigTree.plan(rng, opts)  -- every trunk/root/limb as polylines
--   BigTree.build(parent, plan, rng)
--
-- opts:
--   spine        control points the trunk curves through, base first
--   baseRadius, topRadius
--   ground       y of the ground around the base
--   groundBounds {x0, x1, z0, z1} of solid ground; roots that run off it
--                hang down over the edge
--   hugZ         z of a building face the tree leans on; some limbs run
--                along it and some roots climb it
--   hugX         {min, max} x span of that face
--   groundAt     optional function(x, z) -> ground y, for uneven ground
--                (the roots follow it); defaults to `ground`
--   limbs        optional { count = {min,max}, reach = {min,max},
--                rise = {min,max}, from = {min,max} } for the spreading
--                limbs; `from` is how far up the trunk they start (0..1)
--   lush         foliage density/size multiplier (1 = sparse, 2 = heavy)
--   blossom      fraction of foliage in flower (0..1)
--   crown        size of the foliage mass on the very top

local BuildUtil = require(script.Parent.BuildUtil)

local part, cylinder, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.jitter, BuildUtil.pick

local BARK = Color3.fromRGB(78, 66, 54)
local MOSSY = Color3.fromRGB(72, 84, 52)
local GREENS = {
	Color3.fromRGB(62, 92, 46),
	Color3.fromRGB(78, 106, 52),
	Color3.fromRGB(52, 78, 44),
	Color3.fromRGB(96, 114, 58),
}

local BLOSSOMS = {
	Color3.fromRGB(236, 190, 200),
	Color3.fromRGB(244, 218, 222),
	Color3.fromRGB(226, 170, 186),
}

local BigTree = {}

local function catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- A smooth curve through control points, `perSpan` samples between each.
local function smoothPath(ctrl, perSpan)
	local points = {}
	for i = 1, #ctrl - 1 do
		local p0, p1 = ctrl[math.max(1, i - 1)], ctrl[i]
		local p2, p3 = ctrl[i + 1], ctrl[math.min(#ctrl, i + 2)]
		for s = 0, perSpan - 1 do
			table.insert(points, catmull(p0, p1, p2, p3, s / perSpan))
		end
	end
	table.insert(points, ctrl[#ctrl])
	return points
end

local function taper(count, r0, r1, curve)
	local radii = {}
	for k = 1, count do
		radii[k] = r0 + (r1 - r0) * ((k - 1) / math.max(1, count - 1)) ^ (curve or 1)
	end
	return radii
end

local function randomTurn(rng, amount)
	return Vector3.new(rng:NextNumber(-amount, amount), rng:NextNumber(-amount * 0.6, amount * 0.6), rng:NextNumber(-amount, amount))
end

-- A wandering limb: starts at `start` heading `dir`, bending by `pull`
-- each step.
local function wander(rng, start, dir, length, steps, pull, jitterAmount)
	local points = { start }
	local at, heading = start, dir.Unit
	for _ = 1, steps do
		heading = (heading + pull + randomTurn(rng, jitterAmount)).Unit
		at += heading * (length / steps)
		table.insert(points, at)
	end
	return points
end

function BigTree.plan(rng, opts)
	local plan = { trunk = nil, roots = {}, limbs = {}, foliage = {}, vines = {} }
	local ground = opts.ground
	local gb = opts.groundBounds
	local groundAt = opts.groundAt or function()
		return ground
	end
	local lush = opts.lush or 1
	plan.blossom = opts.blossom or 0
	plan.lush = lush

	-- Trunk, flared at the base.
	local trunkPoints = smoothPath(opts.spine, 4)
	local trunkRadii = taper(#trunkPoints, opts.baseRadius, opts.topRadius, 0.7)
	trunkRadii[1] *= 1.35
	trunkRadii[2] *= 1.15
	plan.trunk = { points = trunkPoints, radii = trunkRadii }
	local base = trunkPoints[1]

	local function trunkAt(t)
		local idx = math.clamp(math.floor(t * (#trunkPoints - 1)) + 1, 1, #trunkPoints)
		return trunkPoints[idx], trunkRadii[idx]
	end

	-- Roots: sprawling across the ground, spilling over its edges, and a
	-- couple climbing the building the tree leans on.
	local rootCount = 11
	for i = 1, rootCount do
		local a = (i - 0.5) / rootCount * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local towardFace = opts.hugZ and out.Z > 0.55 and i % 2 == 0
		local len = rng:NextNumber(35, 80)
		local steps = 9
		local r0 = opts.baseRadius * rng:NextNumber(0.35, 0.5)
		local start = Vector3.new(base.X, 0, base.Z) + out * opts.baseRadius * 0.8
		local at = Vector3.new(start.X, groundAt(start.X, start.Z), start.Z)
		local points = { at + Vector3.new(0, r0 * 0.9, 0) }
		local heading = out
		local climbing = false
		for k = 1, steps do
			heading = (heading + Vector3.new(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3))).Unit
			local r = r0 * (1 - k / (steps + 2))
			if towardFace and at.Z > opts.hugZ - 4 then
				climbing = true
			end
			if climbing then
				at = Vector3.new(at.X + rng:NextNumber(-2, 2), at.Y + len / steps, opts.hugZ - 2 - r)
			else
				at += heading * (len / steps)
				local offGround = at.X < gb.x0 or at.X > gb.x1 or at.Z < gb.z0 or at.Z > gb.z1
				if offGround then
					at = Vector3.new(at.X, at.Y - len / steps * 1.3, at.Z)
				else
					at = Vector3.new(at.X, groundAt(at.X, at.Z) + r * 0.55, at.Z)
				end
			end
			table.insert(points, at)
		end
		table.insert(plan.roots, { points = points, radii = taper(#points, r0, 0.7) })
	end

	-- Limbs hugging the building face: out toward it, then along it.
	if opts.hugZ then
		for k = 1, rng:NextInteger(3, 4) do
			local p, r = trunkAt(rng:NextNumber(0.35, 0.75))
			local side = if k % 2 == 0 then 1 else -1
			local z = opts.hugZ - 6
			local reach = rng:NextNumber(55, 95)
			local ctrl = { p, Vector3.new(p.X + side * 10, p.Y + 3, (p.Z + z) / 2) }
			local n = 5
			for s = 1, n do
				local x = p.X + side * (14 + reach * s / n)
				x = math.clamp(x, opts.hugX[1], opts.hugX[2])
				table.insert(ctrl, Vector3.new(x, p.Y + rng:NextNumber(-5, 5) - s * 1.2, z + rng:NextNumber(-1.5, 1.5)))
			end
			local points = smoothPath(ctrl, 2)
			table.insert(plan.limbs, { points = points, radii = taper(#points, r * 0.45, 1.2), hug = true })
		end
	end

	-- Limbs spreading out and up from the upper trunk, away from the face,
	-- spaced round the trunk so the crown fills out evenly-ish.
	local lc = opts.limbs or {}
	local count = rng:NextInteger(table.unpack(lc.count or { 5, 7 }))
	local reach, rise, from = lc.reach or { 40, 75 }, lc.rise or { 0.3, 0.8 }, lc.from or { 0.55, 0.95 }
	local a0 = rng:NextNumber(0, math.pi * 2)
	for i = 1, count do
		local p, r = trunkAt(rng:NextNumber(from[1], from[2]))
		local a = a0 + i / count * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local dir = Vector3.new(math.cos(a), rng:NextNumber(rise[1], rise[2]), math.sin(a))
		if opts.hugZ and dir.Z > 0 then
			dir = Vector3.new(dir.X, dir.Y, -dir.Z * 0.5)
		end
		local points = wander(rng, p, dir, rng:NextNumber(reach[1], reach[2]), 7, Vector3.new(0, 0.05, 0), 0.25)
		table.insert(plan.limbs, { points = points, radii = taper(#points, r * 0.5, 1) })
	end
	-- A few reaching straight up out of the crown.
	local top, topR = trunkAt(1)
	for _ = 1, 3 do
		local points = wander(rng, top, Vector3.new(rng:NextNumber(-0.5, 0.5), 1, rng:NextNumber(-0.5, 0.2)), rng:NextNumber(20, 35), 4, Vector3.zero, 0.3)
		table.insert(plan.limbs, { points = points, radii = taper(#points, topR * 0.8, 0.8) })
	end

	-- Twigs off every limb, then foliage at the tips and along the limbs.
	local function addFoliage(at, size, hug)
		if hug and opts.hugZ then
			at = Vector3.new(at.X, at.Y, math.min(at.Z - 5, opts.hugZ - size / 2 - 2))
		end
		table.insert(plan.foliage, { at = at, size = size })
	end
	local twigs = {}
	for _, limb in ipairs(plan.limbs) do
		local n = #limb.points
		for _ = 1, rng:NextInteger(1, 2 + math.floor(lush)) do
			local idx = rng:NextInteger(math.max(2, math.floor(n / 3)), n - 1)
			local from = limb.points[idx]
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.2, 1), rng:NextNumber(-1, if limb.hug then -0.2 else 1))
			local points = wander(rng, from, dir, rng:NextNumber(10, 22), 3, Vector3.new(0, 0.1, 0), 0.3)
			table.insert(twigs, { points = points, radii = taper(#points, math.max(0.8, limb.radii[idx] * 0.5), 0.4), hug = limb.hug })
		end
		local grow = math.sqrt(lush)
		addFoliage(limb.points[n], rng:NextNumber(16, 26) * grow, limb.hug)
		for idx = if lush > 1 then 2 else 3, n - 1, if lush > 1 then 2 else 3 do
			if rng:NextNumber() < math.min(0.95, 0.6 * lush) then
				addFoliage(limb.points[idx] + Vector3.new(0, rng:NextNumber(2, 6), 0), rng:NextNumber(10, 18) * grow, limb.hug)
			end
		end
		-- Creepers hanging from the limbs.
		for idx = 2, n, 2 do
			if rng:NextNumber() < 0.35 * lush then
				table.insert(plan.vines, { at = limb.points[idx], length = rng:NextNumber(8, 30) * grow })
			end
		end
	end
	for _, twig in ipairs(twigs) do
		table.insert(plan.limbs, twig)
		addFoliage(twig.points[#twig.points], rng:NextNumber(10, 18) * math.sqrt(lush), twig.hug)
	end
	addFoliage(top + Vector3.new(0, 10, 0), opts.crown or 34, false)

	return plan
end

-- Tapered polyline as cylinder segments with ball joints so it reads as
-- one smooth, bending shape.
local function buildPolyline(parent, name, points, radii, color, rng)
	for k = 1, #points - 1 do
		local a, b = points[k], points[k + 1]
		local len = (b - a).Magnitude
		if len > 0.05 then
			local d = (radii[k] + radii[k + 1])
			local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
			cylinder(parent, name, len + d * 0.15, d, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), Enum.Material.Wood, jitter(color, rng, 0.08))
		end
		if radii[k] > 1.2 then
			local joint = part(parent, name .. "Joint", Vector3.one * radii[k] * 2, a, Enum.Material.Wood, jitter(color, rng, 0.08))
			joint.Shape = Enum.PartType.Ball
		end
	end
end

function BigTree.build(parent, plan, rng)
	local m = BuildUtil.model(parent, "BigTree")
	buildPolyline(m, "Trunk", plan.trunk.points, plan.trunk.radii, BARK, rng)
	for _, root in ipairs(plan.roots) do
		buildPolyline(m, "Root", root.points, root.radii, BARK:Lerp(MOSSY, rng:NextNumber(0, 0.5)), rng)
	end
	for _, limb in ipairs(plan.limbs) do
		buildPolyline(m, "Limb", limb.points, limb.radii, BARK, rng)
	end

	for _, f in ipairs(plan.foliage) do
		local lush = plan.lush or 1
		for _ = 1, rng:NextInteger(3, math.floor(6 * lush)) do
			local s = f.size * rng:NextNumber(0.45, 0.8)
			local offset = Vector3.new(rng:NextNumber(-0.45, 0.45), rng:NextNumber(-0.25, 0.3), rng:NextNumber(-0.45, 0.45)) * f.size
			local flower = rng:NextNumber() < (plan.blossom or 0)
			local color = if flower then pick(BLOSSOMS, rng) else pick(GREENS, rng)
			local ball = part(m, if flower then "Blossom" else "Foliage", Vector3.one * s, f.at + offset, Enum.Material.LeafyGrass, jitter(color, rng, 0.08))
			ball.Shape = Enum.PartType.Ball
			ball.CanCollide = false
			ball.CastShadow = true
		end
	end

	for _, v in ipairs(plan.vines) do
		for _ = 1, rng:NextInteger(2, 4) do
			local len = v.length * rng:NextNumber(0.6, 1)
			local strand = part(m, "Creeper", Vector3.new(0.3, len, 0.3), v.at + Vector3.new(rng:NextNumber(-1.5, 1.5), -len / 2, rng:NextNumber(-1.5, 1.5)), Enum.Material.LeafyGrass, jitter(pick(GREENS, rng), rng, 0.15))
			strand.CanCollide = false
		end
	end
	return m
end

-- Every place a root or limb line crosses a vertical wall plane, as
-- { along, y, radius }. `axis` "X" = a wall at fixed z running along x.
function BigTree.crossings(plan, axis, fixed, spanStart, spanEnd)
	local hits = {}
	local function scan(points, radii)
		for k = 1, #points - 1 do
			local a, b = points[k], points[k + 1]
			local ca, cb = if axis == "X" then a.Z else a.X, if axis == "X" then b.Z else b.X
			if (ca - fixed) * (cb - fixed) < 0 then
				local t = (fixed - ca) / (cb - ca)
				local p = a:Lerp(b, t)
				local along = if axis == "X" then p.X else p.Z
				if along > spanStart and along < spanEnd then
					table.insert(hits, { along = along, y = p.Y, radius = radii[k] })
				end
			end
		end
	end
	for _, root in ipairs(plan.roots) do
		scan(root.points, root.radii)
	end
	for _, limb in ipairs(plan.limbs) do
		scan(limb.points, limb.radii)
	end
	scan(plan.trunk.points, plan.trunk.radii)
	return hits
end

return BigTree
