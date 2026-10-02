-- Below the tunnels.
--
--   * The lower workings: an older, rougher mine level under the south
--     half of the maze, down a long timber stair (the incline) from one of
--     the maze's junctions. Older timbering, rails, flooded pits, most of
--     the lamps dead.
--   * From its far corner, behind a rockfall and some boards across a
--     crack, a narrow fissure runs west under the gym and comes out high
--     in the wall of the chasm: a vast shaft in the rock under the outcrop.
--     A timber stair clings to its wall in a spiral all the way down, lamps
--     strung along it into the dark, and an old cage hangs stuck in the
--     middle on its cables.
--   * At the bottom, through an old iron gate, the Deep: black basalt
--     tunnels under the crag, unlit and wet, with nothing kind in them.
--     Spawn points for what lives there later are marked with DeepSpawn
--     tags; a collapsed passage at its east end is where the way on to the
--     harbour will go (the HarbourLink part).
--
-- Built at the end of Underground.build (which hands over its carving and
-- dressing helpers). Everything sits in rock that's already there (the
-- crag, the outcrop under the gym) or, under the haze line, in more of it
-- added here; clear of the facility, its shaft to the hidden sea, and the
-- school.

local BuildUtil = require(script.Parent.BuildUtil)
local TunnelProps = require(script.Parent.TunnelProps)
local RouteCheck = require(script.Parent.RouteCheck)
local Fixtures = require(script.Parent.StoreFixtures)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local Metal, Wood, Smooth, Neon, Fabric = Enum.Material.Metal, Enum.Material.Wood, Enum.Material.SmoothPlastic, Enum.Material.Neon, Enum.Material.Fabric
local Corroded, Slate = Enum.Material.CorrodedMetal, Enum.Material.Slate
local rgb = Color3.fromRGB

local terrain = workspace.Terrain
local AIR, ROCK, WATER, BASALT = Enum.Material.Air, Enum.Material.Rock, Enum.Material.Water, Enum.Material.Basalt
local UP = Vector3.yAxis
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { terrain }
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local STEEL = rgb(96, 98, 100)
local RUST = rgb(116, 76, 48)
local TIMBER = rgb(96, 74, 52)
local OLD_TIMBER = rgb(74, 62, 50)
local DARK = rgb(30, 30, 32)
local BONE = rgb(206, 200, 184)
local WARM = rgb(255, 190, 120)

-- The lower workings: a grid under the maze's south half (x 486..636,
-- z -100..-10), floors about -118 to -140, well under the maze's floors.
local LOWER = { x0 = 486, z0 = -100, step = 30, nx = 6, nz = 4 }
local LOWER_R = 8
local RAMP_CELL = { 4, 4 } -- (576, -10): the foot of the incline
local FISSURE_CELL = { 1, 1 } -- (486, -100): the crack's in its west wall

-- The chasm, in the outcrop's rock under the gym.
local CH = { x = 330, z = -140, dome = -150, top = -140, bottom = -440 }

-- The Deep: a grid east from the chasm under the outcrop and the crag.
local DEEP = { x0 = 378, z0 = -178, step = 36, nx = 11, nz = 9 }
local DEEP_R = 7.5
local DEEP_ENTRY = { 1, 2 } -- (378, -142), just off the chasm floor

local TheDeep = {}

-- ===== Bits =====

local function key(i, j)
	return i .. "," .. j
end

local function gridXZ(g, i, j)
	return g.x0 + (i - 1) * g.step, g.z0 + (j - 1) * g.step
end

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

local function deco(p)
	if p then
		p.CanCollide = false
		p.CastShadow = false
	end
	return p
end

local function marker(parent, name, tag, pos)
	local p = part(parent, name, Vector3.new(2, 2, 2), pos + Vector3.new(0, 1, 0), Smooth, rgb(255, 0, 0))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p:AddTag(tag)
	return p
end

local lightsLeft = 0
local function light(p, range, brightness, color)
	if lightsLeft > 0 then
		lightsLeft -= 1
		local l = Instance.new("PointLight")
		l.Range = range
		l.Brightness = brightness
		l.Color = color
		l.Parent = p
	end
end

-- A recursive-backtracker maze over the valid cells of a grid, then a few
-- extra links for loops between cells at similar heights.
local function maze(g, valid, start, heights, loops, rng)
	local cells = {}
	for i = 1, g.nx do
		for j = 1, g.nz do
			if valid(i, j) then
				cells[key(i, j)] = { i = i, j = j }
			end
		end
	end
	local edges, linked = {}, {}
	local function link(a, b)
		table.insert(edges, { a, b })
		linked[key(a.i, a.j) .. "|" .. key(b.i, b.j)] = true
		linked[key(b.i, b.j) .. "|" .. key(a.i, a.j)] = true
	end
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	local first = cells[key(start[1], start[2])]
	local visited = { [key(first.i, first.j)] = true }
	local stack = { first }
	while #stack > 0 do
		local cur = stack[#stack]
		local options = {}
		for _, d in ipairs(dirs) do
			local n = cells[key(cur.i + d[1], cur.j + d[2])]
			if n and not visited[key(n.i, n.j)] then
				table.insert(options, n)
			end
		end
		if #options == 0 then
			table.remove(stack)
		else
			local n = options[rng:NextInteger(1, #options)]
			visited[key(n.i, n.j)] = true
			link(cur, n)
			table.insert(stack, n)
		end
	end
	local sorted = {}
	for k in pairs(cells) do
		table.insert(sorted, k)
	end
	table.sort(sorted)
	for _, k in ipairs(sorted) do
		local c = cells[k]
		for _, d in ipairs({ { 1, 0 }, { 0, 1 } }) do
			local n = cells[key(c.i + d[1], c.j + d[2])]
			if n and not linked[key(c.i, c.j) .. "|" .. key(n.i, n.j)] and rng:NextNumber() < loops then
				if math.abs(heights[key(c.i, c.j)] - heights[key(n.i, n.j)]) < 8 then
					link(c, n)
				end
			end
		end
	end
	-- (Cells the backtracker never reached are dropped.)
	for k in pairs(cells) do
		if not visited[k] then
			cells[k] = nil
		end
	end
	return cells, edges
end

-- How many tunnels meet at each cell.
local function degrees(edges)
	local deg = {}
	for _, e in ipairs(edges) do
		for _, c in ipairs(e) do
			local k = key(c.i, c.j)
			deg[k] = (deg[k] or 0) + 1
		end
	end
	return deg
end

-- ===== The incline down from the maze =====

-- A long straight timber stair from `a` (a maze junction's floor) down to
-- `b` (the lower workings' floor), in its own drift, with timber sets over
-- it and a rope to hold.
local function incline(parent, T, a, b, rng)
	local m = model(parent, "Incline")
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dir = flat.Unit
	local start = a + dir * 5
	local horiz = (Vector3.new(b.X, 0, b.Z) - Vector3.new(start.X, 0, start.Z)).Magnitude
	local drop = start.Y - b.Y
	T.carveTunnel(start, b, 5.5)
	local across = Vector3.new(-dir.Z, 0, dir.X)
	local n = math.ceil(horiz)
	for i = 1, n do
		local p = Vector3.new(start.X, 0, start.Z) + dir * (horiz * (i - 0.5) / n)
		local top = start.Y - drop * i / n
		local c = Vector3.new(p.X, top - 1.5, p.Z)
		part(m, "Step", Vector3.new(4.8, 3, horiz / n + 0.06), CFrame.lookAt(c, c + dir), Wood, jitter(TIMBER, rng, 0.1))
		if i % 12 == 6 then
			T.timberFrame(m, Vector3.new(p.X, top, p.Z), dir)
		end
		if i % 28 == 14 then
			T.workLamp(m, Vector3.new(p.X, top, p.Z), rng)
		end
	end
	-- The rope along the wall.
	local prev
	for k = 0, 8 do
		local t = k / 8
		local p = start:Lerp(b, t) + across * 2.2 + UP * 3
		if prev then
			deco(rod(m, "HandRope", prev, p, 0.16, Fabric, rgb(170, 150, 110)))
		end
		rod(m, "RopePin", p, p + across * 1.4, 0.2, Metal, RUST)
		prev = p
	end
	-- A board at the top.
	local signAt = start + across * -3 + UP * 5.5
	label(m, CFrame.lookAt(signAt, signAt - dir), Vector3.new(3.4, 1.4, 0.15), Enum.NormalId.Front, "下部坑道 ↓", rgb(150, 120, 84), rgb(30, 26, 22), Wood, Enum.Font.PermanentMarker)
	RouteCheck.add("incline down", { start, b }, 2, 7)
end

-- ===== The lower workings =====

local function lowerWorkings(parent, T, rng)
	local heights = {}
	local rx, rz = gridXZ(LOWER, RAMP_CELL[1], RAMP_CELL[2])
	for i = 1, LOWER.nx do
		for j = 1, LOWER.nz do
			local x, z = gridXZ(LOWER, i, j)
			local dist = math.sqrt((x - rx) ^ 2 + (z - rz) ^ 2)
			heights[key(i, j)] = math.clamp(-122 - 0.06 * dist + rng:NextNumber(-3, 3), -140, -118)
		end
	end
	heights[key(RAMP_CELL[1], RAMP_CELL[2])] = -122
	heights[key(FISSURE_CELL[1], FISSURE_CELL[2])] = -128
	local cells, edges = maze(LOWER, function()
		return true
	end, RAMP_CELL, heights, 0.14, rng)
	local function point(c)
		local x, z = gridXZ(LOWER, c.i, c.j)
		return Vector3.new(x, heights[key(c.i, c.j)], z)
	end
	local special = { [key(RAMP_CELL[1], RAMP_CELL[2])] = true, [key(FISSURE_CELL[1], FISSURE_CELL[2])] = true }

	for _, e in ipairs(edges) do
		T.carveTunnel(point(e[1]), point(e[2]), LOWER_R)
	end
	local caverns = {}
	for k, c in pairs(cells) do
		local p = point(c)
		terrain:FillBall(p + Vector3.new(0, LOWER_R * 0.6, 0), LOWER_R + 1, AIR)
		if not special[k] and rng:NextNumber() < 0.24 then
			local r = rng:NextNumber(10, 13)
			terrain:FillBall(p + Vector3.new(0, r * 0.5, 0), r, AIR)
			caverns[k] = r
		end
	end
	for _, e in ipairs(edges) do
		T.flattenTunnel(point(e[1]), point(e[2]), LOWER_R)
	end
	local pits = {}
	for k, c in pairs(cells) do
		local p = point(c)
		terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, (caverns[k] or LOWER_R) - 1, ROCK)
		if not special[k] and rng:NextNumber() < 0.18 then
			terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, 5, AIR)
			terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2.6, 0)), 2.8, 5, WATER)
			pits[k] = true
		end
	end
	task.wait()

	-- Dressing: older and darker than the maze above.
	local m = model(parent, "LowerWorkings")
	for _, e in ipairs(edges) do
		local a, b = point(e[1]), point(e[2])
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
		local mid = (a + b) / 2
		if rng:NextNumber() < 0.5 then
			T.workLamp(m, Vector3.new(mid.X, T.floorAt(mid), mid.Z), rng)
		end
		for _, t in ipairs({ 0.3, 0.7 }) do
			if rng:NextNumber() < 0.4 then
				local p = a:Lerp(b, t)
				T.timberFrame(m, Vector3.new(p.X, T.floorAt(p), p.Z), along)
			end
		end
		if rng:NextNumber() < 0.35 and math.abs(b.Y - a.Y) < 4 then
			T.mineRails(m, a, b, rng)
		end
		RouteCheck.add("lower workings", { a, b }, 3, 7)
	end
	for k, c in pairs(cells) do
		if special[k] then
			continue
		end
		local p = point(c)
		local wallward = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector * ((caverns[k] or LOWER_R) - 2)
		local nearWall = p + wallward
		if rng:NextNumber() < 0.2 then
			T.fungus(m, Vector3.new(nearWall.X, T.floorAt(nearWall), nearWall.Z), wallward, rng)
		end
		if rng:NextNumber() < 0.4 then
			T.fallenRocks(m, Vector3.new(p.X, T.floorAt(p), p.Z) - wallward * 0.5, rng)
		end
		if not pits[k] and rng:NextNumber() < 0.35 then
			local spot = p - wallward * 0.6
			T.leftBehind(m, Vector3.new(spot.X, T.floorAt(spot), spot.Z), -wallward, rng)
		end
	end
	return point({ i = RAMP_CELL[1], j = RAMP_CELL[2] }), point({ i = FISSURE_CELL[1], j = FISSURE_CELL[2] })
end

-- ===== The chasm =====

local function chasmCentre(y)
	return Vector3.new(CH.x + 6 * math.sin(y / 47), y, CH.z + 6 * math.cos(y / 61))
end

local function chasmR(y)
	return 36 + 6 * math.sin((y + 150) / 38) + 3 * math.sin(y / 17)
end

local function carveChasm(rng)
	-- Stacked slices for straight walls (balls would bulge up into the
	-- gym), a dome over the top, hollows in the walls here and there. The
	-- slices step by the terrain's 4-stud voxels and overlap well, or each
	-- partly-covered voxel keeps a thin skin of rock across the shaft.
	for y = CH.bottom + 2, CH.dome + 2, 4 do
		terrain:FillCylinder(CFrame.new(chasmCentre(y)), 12, chasmR(y), AIR)
	end
	terrain:FillBall(chasmCentre(CH.dome), chasmR(CH.dome), AIR)
	for _ = 1, 28 do
		local y = rng:NextNumber(CH.bottom + 12, CH.dome - 8)
		local a = rng:NextNumber(0, math.pi * 2)
		terrain:FillBall(chasmCentre(y) + Vector3.new(math.cos(a), 0, math.sin(a)) * (chasmR(y) + rng:NextNumber(2, 4)), rng:NextNumber(5, 9), AIR)
	end
	terrain:FillCylinder(CFrame.new(chasmCentre(CH.bottom - 2)), 4, chasmR(CH.bottom) + 8, BASALT)
end

-- The stair round the chasm wall, from the fissure's mouth at the top all
-- the way to the floor; landings on the way with what people left there.
-- Returns the top step.
local THETA0 = 0.35
local function stairPoint(y, theta)
	local c = chasmCentre(y)
	local rp = chasmR(y) - 3.5
	return Vector3.new(c.X + math.cos(theta) * rp, y, c.Z + math.sin(theta) * rp)
end

local function landing(m, pos, radial, tangent, kind, rng)
	local cf = CFrame.fromMatrix(pos, radial, UP)
	part(m, "Landing", Vector3.new(5.6, 0.6, 7), cf * CFrame.new(0.4, -0.3, 0), Wood, jitter(OLD_TIMBER, rng, 0.08))
	if kind == 1 then
		-- Someone camped here on the way down.
		deco(part(m, "Bedroll", Vector3.new(1.6, 0.4, 4), cf * CFrame.new(1.6, 0.2, 0.5), Fabric, rgb(90, 80, 60)))
		TunnelProps.lantern(m, cf * CFrame.new(1.8, 0, -2.6), rng, true)
		TunnelProps.supplyHeap(m, (cf * CFrame.new(1.4, 0, -1)).Position, rng, 1.2)
	elseif kind == 2 then
		-- A little stone figure, candles long out, and days scratched into
		-- the rock.
		local j = cf * CFrame.new(2.2, 0, 1.5)
		deco(ellipsoid(m, "Jizo", Vector3.new(0.9, 1.6, 0.8), j * CFrame.new(0, 0.8, 0), Slate, rgb(120, 120, 116)))
		deco(ellipsoid(m, "JizoHead", Vector3.new(0.7, 0.7, 0.7), j * CFrame.new(0, 1.9, 0), Slate, rgb(120, 120, 116)))
		deco(part(m, "Bib", Vector3.new(0.9, 0.6, 0.1), j * CFrame.new(-0.42, 1.3, 0) * CFrame.Angles(0, math.pi / 2, 0), Fabric, rgb(180, 40, 36)))
		for k = 0, 2 do
			deco(cylinder(m, "Candle", 0.4, 0.22, j * CFrame.new(-0.6, 0.2, -0.8 + k * 0.4) * UPRIGHT, Smooth, rgb(220, 214, 196)))
		end
		local hit = TunnelProps.wallHit(pos + UP * 3, radial, 14)
		if hit then
			local wall = CFrame.lookAt(hit.Position + hit.Normal * 0.05, hit.Position + hit.Normal)
			for k = 0, 13 do
				deco(part(m, "Tally", Vector3.new(0.08, 1.1, 0.05), wall * CFrame.new(-1.8 + k * 0.28, 0, 0) * CFrame.Angles(0, 0, if k % 5 == 4 then 1.2 else 0), Smooth, rgb(200, 196, 186)))
			end
		end
	else
		-- A warning, for anyone going on down, nailed to the rock.
		local hit = TunnelProps.wallHit(pos + UP * 2.6, radial, 14)
		local b = if hit then CFrame.lookAt(hit.Position + hit.Normal * 0.15, hit.Position + hit.Normal) else cf * CFrame.new(2.5, 2.6, 0) * CFrame.Angles(0, math.pi / 2, 0)
		label(m, b, Vector3.new(4, 2, 0.15), Enum.NormalId.Front, "引き返せ" .. string.char(10) .. "TURN BACK", rgb(120, 100, 76), rgb(170, 30, 26), Wood, Enum.Font.PermanentMarker)
		deco(rod(m, "BoardSpike", (b * CFrame.new(0, 0, -0.1)).Position, (b * CFrame.new(0, 0, 0.9)).Position, 0.15, Metal, RUST))
	end
end

local function descent(parent, rng)
	local m = model(parent, "ChasmStair")
	local RUN, RISE = 1.1, 0.72
	local LANDINGS = { [130] = 1, [260] = 2, [390] = 3 }
	local theta, y = THETA0, CH.top
	local i = 0
	local top = stairPoint(y, theta)
	-- A ledge of planks where the fissure comes out.
	local tr = Vector3.new(math.cos(theta), 0, math.sin(theta))
	part(m, "TopLedge", Vector3.new(6, 0.6, 6), CFrame.fromMatrix(top - UP * 0.3 + tr * 0.6, tr, UP), Wood, jitter(OLD_TIMBER, rng, 0.08))
	terrain:FillBall(top + UP * 3.4 + tr * 1.5, 5, AIR)
	local prevPost
	local flat = 0
	while y > CH.bottom + RISE do
		i += 1
		local c = chasmCentre(y)
		local rp = chasmR(y) - 3.5
		theta += RUN / rp
		if LANDINGS[i] then
			flat = 7
		end
		if flat > 0 then
			flat -= 1
		else
			y = math.max(CH.bottom, y - RISE)
		end
		local radial = Vector3.new(math.cos(theta), 0, math.sin(theta))
		local tangent = Vector3.new(-math.sin(theta), 0, math.cos(theta))
		local pos = Vector3.new(c.X, y, c.Z) + radial * rp
		-- Room to walk: cut the wall back behind the step and over it.
		if i % 3 == 0 then
			terrain:FillBall(pos + UP * 3.4 + radial * 0.6, 4.3, AIR)
		end
		part(m, "Step", Vector3.new(4.6, 0.5, RUN + 0.2), CFrame.fromMatrix(pos - UP * 0.25, radial, UP), Wood, jitter(if rng:NextNumber() < 0.2 then OLD_TIMBER else TIMBER, rng, 0.08))
		if i % 3 == 0 then
			deco(rod(m, "Bracket", pos - UP * 0.5 - radial * 1.8, pos - UP * 2.6 + radial * 2.8, 0.3, Wood, OLD_TIMBER))
		end
		-- The rail on the drop side.
		if i % 4 == 0 then
			local post = pos - radial * 2.1
			rod(m, "RailPost", post - UP * 0.4, post + UP * 3.4, 0.24, Wood, TIMBER)
			if prevPost then
				for _, h in ipairs({ 1.7, 3.2 }) do
					rod(m, "RailBar", prevPost + UP * h, post + UP * h, 0.18, Wood, TIMBER)
				end
			end
			prevPost = post
			-- Lamps on the rail posts, lit and dead, down into the dark.
			if i % 24 == 0 then
				rod(m, "LampPole", post + UP * 3.4, post + UP * 5.4, 0.12, Metal, STEEL)
				local lit = rng:NextNumber() < 0.6
				local bulb = part(m, "Lamp", Vector3.new(0.8, 0.8, 0.8), post + UP * 5.2 - radial * 0.6, if lit then Neon else Smooth, if lit then WARM else rgb(80, 76, 70))
				bulb.Shape = Enum.PartType.Ball
				bulb.CanCollide = false
				if lit then
					light(bulb, 24, 1.3, rgb(255, 196, 130))
				end
			end
		end
		if LANDINGS[i] then
			landing(m, pos, radial, tangent, LANDINGS[i], rng)
			terrain:FillBall(pos + UP * 3.4 + radial * 2.5, 5.5, AIR)
		end
	end
	-- The last flight comes down onto the floor; a rail post to finish.
	return top, m
end

-- A mine cage hung on its rope from the sheave at `top`, its roof at
-- `roofY`: angle-iron frame, chequer-plate floor, mesh sides, a folding
-- gate half drawn across the front, chains up from the corners to the
-- rope. Tagged to swing gently (SwingingThings.client.lua moves it).
local CAGE_IRON = rgb(92, 70, 52)
local function mineCage(parent, name, top, roofY, rng)
	local m = model(parent, name)
	local W, D, H = 6, 7, 8
	local base = CFrame.new(top.X, roofY - H, top.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	part(m, "CageFloor", Vector3.new(W, 0.4, D), at(0, 0.2, 0), Enum.Material.DiamondPlate, rgb(86, 88, 88))
	part(m, "CageRoof", Vector3.new(W + 0.4, 0.3, D + 0.4), at(0, H + 0.15, 0), Corroded, RUST)
	for _, dx in ipairs({ -W / 2, W / 2 }) do
		for _, dz in ipairs({ -D / 2, D / 2 }) do
			part(m, "CagePost", Vector3.new(0.4, H, 0.4), at(dx, H / 2, dz), Corroded, CAGE_IRON)
		end
	end
	for _, hy in ipairs({ 0.55, H / 2, H - 0.25 }) do
		for _, dz in ipairs({ -D / 2, D / 2 }) do
			part(m, "CageRail", Vector3.new(W, 0.3, 0.3), at(0, hy, dz), Corroded, CAGE_IRON)
		end
		for _, dx in ipairs({ -W / 2, W / 2 }) do
			part(m, "CageRail", Vector3.new(0.3, 0.3, D), at(dx, hy, 0), Corroded, CAGE_IRON)
		end
	end
	-- Mesh on the two long sides and the back.
	for _, sx in ipairs({ -1, 1 }) do
		for z = -D / 2 + 0.5, D / 2 - 0.4, 0.5 do
			deco(part(m, "Mesh", Vector3.new(0.06, H - 1, 0.06), at(sx * W / 2, H / 2, z), Metal, STEEL))
		end
		for y = 1.1, H - 0.8, 0.6 do
			deco(part(m, "Mesh", Vector3.new(0.06, 0.06, D - 0.4), at(sx * W / 2, y, 0), Metal, STEEL))
		end
	end
	for x = -W / 2 + 0.5, W / 2 - 0.4, 0.5 do
		deco(part(m, "Mesh", Vector3.new(0.06, H - 1, 0.06), at(x, H / 2, D / 2), Metal, STEEL))
	end
	for y = 1.1, H - 0.8, 0.6 do
		deco(part(m, "Mesh", Vector3.new(W - 0.4, 0.06, 0.06), at(0, y, D / 2), Metal, STEEL))
	end
	-- The folding gate across the front, drawn half shut.
	local g0, g1 = -W / 2 + 0.3, 0.4
	local n = 6
	for k = 0, n - 1 do
		local xa = g0 + (g1 - g0) * k / n
		local xb = g0 + (g1 - g0) * (k + 1) / n
		deco(rod(m, "GateLattice", at(xa, 0.7, -D / 2 - 0.1).Position, at(xb, H - 0.7, -D / 2 - 0.1).Position, 0.08, Metal, STEEL))
		deco(rod(m, "GateLattice", at(xb, 0.7, -D / 2 - 0.1).Position, at(xa, H - 0.7, -D / 2 - 0.1).Position, 0.08, Metal, STEEL))
		deco(rod(m, "GateBar", at(xa, 0.5, -D / 2 - 0.15).Position, at(xa, H - 0.5, -D / 2 - 0.15).Position, 0.14, Metal, CAGE_IRON))
	end
	-- Guide shoes on the sides, a dead lamp on the roof.
	for _, sx in ipairs({ -1, 1 }) do
		for _, y in ipairs({ 1, H - 1 }) do
			part(m, "GuideShoe", Vector3.new(0.6, 1.2, 1.2), at(sx * (W / 2 + 0.35), y, 0), Metal, DARK)
		end
	end
	deco(part(m, "RoofLamp", Vector3.new(0.7, 0.7, 0.7), at(1.8, H + 0.65, 2), Enum.Material.Glass, rgb(70, 70, 66)))
	-- Inside: a tipped bucket, a tool box.
	deco(cylinder(m, "Bucket", 1.4, 1.2, at(1.2, 0.95, 1.8) * CFrame.Angles(0, 0.5, 0), Metal, rgb(120, 110, 90)))
	deco(part(m, "ToolBox", Vector3.new(1.6, 0.8, 0.8), at(-1.6, 0.8, 2.4), Metal, rgb(150, 40, 34)))
	-- The bridle: chains up from the roof corners to a shackle, the rope up
	-- from there to the sheave.
	local shackle = at(0, H + 4, 0).Position
	for _, dx in ipairs({ -W / 2 + 0.3, W / 2 - 0.3 }) do
		for _, dz in ipairs({ -D / 2 + 0.3, D / 2 - 0.3 }) do
			deco(rod(m, "Chain", at(dx, H + 0.3, dz).Position, shackle, 0.14, Metal, DARK))
		end
	end
	deco(part(m, "Shackle", Vector3.new(0.8, 1, 0.5), shackle + UP * 0.3, Corroded, RUST))
	deco(rod(m, "HoistRope", shackle + UP * 0.8, top, 0.3, Metal, DARK))
	m.WorldPivot = CFrame.new(top)
	m:SetAttribute("SwingPivot", top)
	m:SetAttribute("SwingDegrees", 0.9 + rng:NextNumber(0, 0.5))
	-- (a real pendulum's period for its length)
	m:SetAttribute("SwingPeriod", 2 * math.pi * math.sqrt((top.Y - roofY) / workspace.Gravity))
	m:AddTag("Swing")
	return m
end

-- A kibble: the round iron bucket the shaft sinkers rode, on a chain.
local function kibble(parent, name, top, rimY, rng)
	local m = model(parent, name)
	local c = Vector3.new(top.X, rimY, top.Z)
	cylinder(m, "Kibble", 4.6, 4.4, CFrame.new(c - UP * 2.3) * UPRIGHT, Corroded, RUST)
	cylinder(m, "KibbleInside", 0.2, 3.9, CFrame.new(c - UP * 0.4) * UPRIGHT, Smooth, DARK)
	cylinder(m, "KibbleRim", 0.4, 4.7, CFrame.new(c - UP * 0.2) * UPRIGHT, Corroded, CAGE_IRON)
	local tip = c + UP * 4.2
	for _, s in ipairs({ -1, 1 }) do
		deco(rod(m, "Bail", c + Vector3.new(s * 2.3, -0.4, 0), tip, 0.25, Metal, CAGE_IRON))
	end
	deco(rod(m, "HoistChain", tip, top, 0.24, Metal, DARK))
	m.WorldPivot = CFrame.new(top)
	m:SetAttribute("SwingPivot", top)
	m:SetAttribute("SwingDegrees", 1.2 + rng:NextNumber(0, 0.4))
	m:SetAttribute("SwingPeriod", 2 * math.pi * math.sqrt((top.Y - rimY) / workspace.Gravity))
	m:AddTag("Swing")
	return m
end

-- The headframe over the chasm, its two sheaves, and what hangs off them:
-- a cage stuck a third of the way down, a kibble lower still.
local function cage(parent, rng)
	local m = model(parent, "ChasmHeadframe")
	local by = CH.dome + 22
	local c = chasmCentre(by)
	local half = math.sqrt(math.max(0, chasmR(CH.dome) ^ 2 - 22 ^ 2)) + 3
	part(m, "Headframe", Vector3.new(half * 2, 2.4, 1.8), CFrame.new(c), Corroded, RUST)
	part(m, "HeadframeFlange", Vector3.new(half * 2, 0.4, 3), CFrame.new(c - UP * 1.2), Corroded, RUST)
	for _, s in ipairs({ -1, 1 }) do
		deco(rod(m, "Strut", c + Vector3.new(s * half * 0.5, -1, 0), c + Vector3.new(s * (half - 1), -12, 0), 0.9, Corroded, RUST))
	end
	local tops = {}
	for k, dx in ipairs({ -6, 6 }) do
		local sc = c + Vector3.new(dx, -3, 0)
		cylinder(m, "Sheave", 0.8, 5, CFrame.new(sc) * CFrame.Angles(0, math.pi / 2, 0), Metal, STEEL)
		part(m, "SheaveHanger", Vector3.new(0.4, 3, 1.6), CFrame.new(sc + UP * 1.5 + Vector3.new(0, 0, 0.6)), Metal, DARK)
		tops[k] = sc - UP * 2.4
	end
	mineCage(parent, "MineCage", tops[1], -250, rng)
	kibble(parent, "Kibble", tops[2], -352, rng)
	-- A third rope, snapped, hanging free.
	deco(rod(m, "SnappedCable", c - UP * 3 + Vector3.new(0, 0, 1.2), c + Vector3.new(1.5, -90, 1.8), 0.22, Metal, DARK))
end

-- The chasm floor: rubble, a black pool, bones, a low mist, and the old
-- gate into the Deep.
local function chasmFloor(parent, toDeep, rng)
	local m = model(parent, "ChasmFloor")
	local c = chasmCentre(CH.bottom)
	local r = chasmR(CH.bottom)
	for _ = 1, 26 do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(4, r - 3)
		local s = Vector3.new(rng:NextNumber(1, 5), rng:NextNumber(0.8, 3), rng:NextNumber(1, 5))
		part(m, "Rubble", s, CFrame.new(c + Vector3.new(math.cos(a) * d, s.Y * 0.35, math.sin(a) * d)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Slate, jitter(rgb(62, 62, 64), rng, 0.12))
	end
	-- Planks from a flight that came down.
	for _ = 1, 8 do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(r * 0.4, r - 4)
		part(m, "FallenStep", Vector3.new(4.6, 0.5, 1.2), CFrame.new(c + Vector3.new(math.cos(a) * d, 0.5, math.sin(a) * d)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)), Wood, OLD_TIMBER)
	end
	local pa = rng:NextNumber(0, math.pi * 2)
	local pool = c + Vector3.new(math.cos(pa), 0, math.sin(pa)) * (r * 0.45)
	terrain:FillCylinder(CFrame.new(pool - UP * 1.5), 3, 9, AIR)
	terrain:FillCylinder(CFrame.new(pool - UP * 2.2), 1.8, 9, WATER)
	for _ = 1, 3 do
		local b = c + Vector3.new(rng:NextNumber(-r * 0.6, r * 0.6), 0, rng:NextNumber(-r * 0.6, r * 0.6))
		TheDeep.bones(m, b, rng)
	end
	-- Mist lying on the floor.
	local mist = part(m, "Mist", Vector3.new(r * 1.6, 1, r * 1.6), c + UP * 0.5, Smooth, rgb(0, 0, 0))
	mist.Transparency = 1
	mist.CanCollide = false
	mist.CanQuery = false
	mist.CanTouch = false
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 5
	e.Lifetime = NumberRange.new(9, 14)
	e.Speed = NumberRange.new(0.2, 0.8)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 22) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(70, 76, 84))
	e.Acceleration = Vector3.new(0, 0.1, 0)
	e.Parent = mist
	-- The gate, in the mouth of the way on.
	local d = Vector3.new(toDeep.X - c.X, 0, toDeep.Z - c.Z).Unit
	local g = c + d * (r - 1)
	local frame = CFrame.lookAt(g, g + d)
	for _, s in ipairs({ -1, 1 }) do
		part(m, "GatePost", Vector3.new(0.8, 9, 0.8), frame * CFrame.new(s * 4.4, 4.5, 0), Corroded, RUST)
	end
	part(m, "GateLintel", Vector3.new(9.6, 0.8, 0.8), frame * CFrame.new(0, 9.2, 0), Corroded, RUST)
	-- One leaf hanging open on its hinge, the other gone.
	local leaf = frame * CFrame.new(-4, 0, 0) * CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(2, 0, 0)
	part(m, "GateRail", Vector3.new(4, 0.3, 0.3), leaf * CFrame.new(0, 7.6, 0), Metal, RUST)
	part(m, "GateRail", Vector3.new(4, 0.3, 0.3), leaf * CFrame.new(0, 1, 0), Metal, RUST)
	for k = -3, 3 do
		rod(m, "GateBar", (leaf * CFrame.new(k * 0.55, 0.4, 0)).Position, (leaf * CFrame.new(k * 0.55, 8, 0)).Position, 0.16, Metal, RUST)
	end
	label(m, frame * CFrame.new(4.4, 6, -0.45), Vector3.new(1, 3.4, 0.05), Enum.NormalId.Front, "立入禁止", rgb(210, 200, 170), rgb(150, 30, 26), Smooth, Enum.Font.GothamBold)
	return m
end

-- ===== The Deep =====

-- A few bones, and sometimes a skull.
function TheDeep.bones(parent, at, rng)
	for _ = 1, rng:NextInteger(3, 7) do
		local len = rng:NextNumber(0.8, 2.2)
		deco(part(parent, "Bone", Vector3.new(0.22, 0.22, len), CFrame.new(at + Vector3.new(rng:NextNumber(-1.5, 1.5), 0.12, rng:NextNumber(-1.5, 1.5))) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, jitter(BONE, rng, 0.06)))
	end
	if rng:NextNumber() < 0.5 then
		local s = CFrame.new(at + Vector3.new(rng:NextNumber(-1, 1), 0.4, rng:NextNumber(-1, 1))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), 0)
		deco(ellipsoid(parent, "Skull", Vector3.new(0.75, 0.8, 0.95), s, Smooth, BONE))
		for _, dx in ipairs({ -0.17, 0.17 }) do
			deco(ellipsoid(parent, "EyeSocket", Vector3.new(0.2, 0.2, 0.1), s * CFrame.new(dx, 0.05, -0.44), Smooth, DARK))
		end
	end
end

-- Pale, faintly glowing fungus: the only light down here.
local PALE = rgb(170, 200, 210)
local function paleFungus(parent, at, rng)
	local g = model(parent, "PaleFungus")
	for _ = 1, rng:NextInteger(4, 9) do
		local h = rng:NextNumber(0.3, 1.1)
		local p = at + Vector3.new(rng:NextNumber(-1.4, 1.4), 0, rng:NextNumber(-1.4, 1.4))
		deco(cylinder(g, "Stalk", h, 0.12, CFrame.new(p + UP * h / 2) * UPRIGHT, Smooth, rgb(190, 196, 190)))
		deco(ellipsoid(g, "Cap", Vector3.new(0.5, 0.2, 0.5) * rng:NextNumber(0.8, 1.6), CFrame.new(p + UP * h), Neon, jitter(PALE, rng, 0.08))).Transparency = 0.2
	end
	local core = g:FindFirstChild("Cap")
	if core then
		light(core, 11, 0.45, rgb(150, 190, 210))
	end
end

-- Scoring on the wall: something's claws, or someone's tool.
local function scratches(parent, at, wallward, rng)
	local hit = TunnelProps.wallHit(at + UP * rng:NextNumber(2, 4), wallward, 12)
	if not hit then
		return
	end
	local n = hit.Normal
	local side = n:Cross(UP)
	if side.Magnitude < 0.1 then
		return
	end
	side = side.Unit
	local base = hit.Position + n * 0.08
	local slant = rng:NextNumber(-0.6, 0.6)
	for k = 0, 3 do
		local c = base + side * (k * 0.35) + UP * (k * 0.05)
		deco(part(parent, "Scratch", Vector3.new(0.08, rng:NextNumber(1.8, 2.8), 0.06), CFrame.lookAt(c, c + n) * CFrame.Angles(0, 0, slant), Smooth, rgb(150, 146, 140)))
	end
end

-- Water dripping from the roof at `at`.
local function drip(parent, at)
	local hit = workspace:Raycast(at + UP * 2, UP * 20, terrainOnly)
	if not hit then
		return
	end
	local src = part(parent, "Drip", Vector3.new(1, 0.2, 1), hit.Position - UP * 0.3, Smooth, rgb(0, 0, 0))
	src.Transparency = 1
	src.CanCollide = false
	src.CanQuery = false
	src.CanTouch = false
	local e = Instance.new("ParticleEmitter")
	e.Rate = 2
	e.Lifetime = NumberRange.new(1, 1.4)
	e.Speed = NumberRange.new(0, 0.5)
	e.Acceleration = Vector3.new(0, -40, 0)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Size = NumberSequence.new(0.12)
	e.Transparency = NumberSequence.new(0.3)
	e.Color = ColorSequence.new(rgb(170, 190, 200))
	e.LightEmission = 0.3
	e.Parent = src
end

local function deepWorkings(parent, T, fromChasm, rng)
	local function valid(i, j)
		local x, z = gridXZ(DEEP, i, j)
		if x < 468 then
			return z <= -70 -- under the outcrop, clear of the school
		end
		if x < 500 and z > 0 then
			return false -- the hidden sea's lighting starts about here
		end
		return z >= -106 and z <= 110
	end
	local heights = {}
	for i = 1, DEEP.nx do
		for j = 1, DEEP.nz do
			local x = gridXZ(DEEP, i, j)
			if x < 468 then
				-- (the outcrop's concrete pillar tops out not far below)
				heights[key(i, j)] = -440 + rng:NextNumber(-2, 1)
			else
				heights[key(i, j)] = math.clamp(-447 - 0.1 * (x - 468) + rng:NextNumber(-4, 4), -500, -444)
			end
		end
	end
	heights[key(DEEP_ENTRY[1], DEEP_ENTRY[2])] = CH.bottom
	local cells, edges = maze(DEEP, valid, DEEP_ENTRY, heights, 0.1, rng)
	local function point(c)
		local x, z = gridXZ(DEEP, c.i, c.j)
		return Vector3.new(x, heights[key(c.i, c.j)], z)
	end
	local entry = point({ i = DEEP_ENTRY[1], j = DEEP_ENTRY[2] })

	-- The way in from the chasm floor.
	local floorC = chasmCentre(CH.bottom)
	T.carveTunnel(Vector3.new(floorC.X, CH.bottom, floorC.Z), entry, DEEP_R + 0.5)
	for _, e in ipairs(edges) do
		T.carveTunnel(point(e[1]), point(e[2]), DEEP_R)
	end
	local caverns = {}
	for k, c in pairs(cells) do
		local p = point(c)
		terrain:FillBall(p + Vector3.new(0, DEEP_R * 0.6, 0), DEEP_R + 1.5, AIR)
		if rng:NextNumber() < 0.16 then
			local r = rng:NextNumber(11, 15)
			terrain:FillBall(p + Vector3.new(rng:NextNumber(-3, 3), r * 0.45, rng:NextNumber(-3, 3)), r, AIR)
			caverns[k] = r
		end
	end
	-- The collapsed way on at the east end, towards the harbour.
	local eastmost
	for _, c in pairs(cells) do
		local p = point(c)
		if not eastmost or p.X > eastmost.X or (p.X == eastmost.X and math.abs(p.Z) < math.abs(eastmost.Z)) then
			eastmost = p
		end
	end
	local stubEnd = eastmost + Vector3.new(6, 0, 0)
	T.carveTunnel(eastmost, stubEnd, DEEP_R - 1)
	task.wait()
	T.flattenTunnel(Vector3.new(floorC.X, CH.bottom, floorC.Z), entry, DEEP_R + 0.5)
	for _, e in ipairs(edges) do
		T.flattenTunnel(point(e[1]), point(e[2]), DEEP_R)
	end
	T.flattenTunnel(eastmost, stubEnd, DEEP_R - 1)
	local pools = {}
	for k, c in pairs(cells) do
		local p = point(c)
		terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, (caverns[k] or DEEP_R) - 1, BASALT)
		if k ~= key(DEEP_ENTRY[1], DEEP_ENTRY[2]) and rng:NextNumber() < 0.12 then
			-- Black water, deeper than it looks.
			terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 3, 0)), 6, 5.5, AIR)
			terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 3.6, 0)), 4.8, 5.5, WATER)
			pools[k] = true
		end
	end
	task.wait()

	-- Dressing: almost nothing kind.
	local m = model(parent, "TheDeep")
	local deg = degrees(edges)
	RouteCheck.add("into the deep", { Vector3.new(floorC.X, CH.bottom, floorC.Z), entry }, 3, 8)
	for _, e in ipairs(edges) do
		local a, b = point(e[1]), point(e[2])
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
		local mid = (a + b) / 2
		local roll = rng:NextNumber()
		if roll < 0.12 then
			-- A lamp cable from a long time ago, the bulb smashed.
			local ceil = T.ceilingAt(mid)
			deco(rod(m, "DeadCable", Vector3.new(mid.X, ceil, mid.Z), Vector3.new(mid.X + 0.4, ceil - rng:NextNumber(2, 5), mid.Z), 0.08, Smooth, DARK))
		elseif roll < 0.3 then
			-- A timber set that gave way.
			local p = a:Lerp(b, rng:NextNumber(0.3, 0.7))
			local across = Vector3.new(-along.Z, 0, along.X)
			local f = Vector3.new(p.X, T.floorAt(p), p.Z)
			part(m, "RottenPost", Vector3.new(0.9, 8, 0.9), CFrame.new(f + across * 4.4 + UP * 3.9) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12))), Wood, OLD_TIMBER)
			part(m, "FallenCap", Vector3.new(10.5, 1, 1), CFrame.new(f + UP * 0.9 - along * 1.2) * CFrame.lookAt(Vector3.zero, across).Rotation * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-20, 20))), Wood, OLD_TIMBER)
		end
		if rng:NextNumber() < 0.2 then
			drip(m, a:Lerp(b, rng:NextNumber(0.2, 0.8)) + UP * 2)
		end
		RouteCheck.add("the deep", { a, b }, 3, 8)
	end
	for k, c in pairs(cells) do
		local p = point(c)
		local f = Vector3.new(p.X, T.floorAt(p), p.Z)
		local wallward = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector * ((caverns[k] or DEEP_R) - 1.5)
		if k == key(DEEP_ENTRY[1], DEEP_ENTRY[2]) then
			continue
		end
		if rng:NextNumber() < 0.22 then
			local w = p + wallward * 0.9
			paleFungus(m, Vector3.new(w.X, T.floorAt(w), w.Z), rng)
		end
		if rng:NextNumber() < 0.3 then
			scratches(m, f, wallward, rng)
		end
		if not pools[k] and rng:NextNumber() < 0.16 then
			TheDeep.bones(m, f - wallward * 0.4, rng)
		end
		if rng:NextNumber() < 0.14 then
			TunnelProps.tendrils(m, f + UP * 2, rng:NextInteger(3, 6), rng, { cap = rgb(150, 170, 176), spot = rgb(200, 220, 226) })
		end
		if rng:NextNumber() < 0.1 then
			-- Something someone dropped running.
			local roll = rng:NextNumber()
			local q = f - wallward * 0.5
			if roll < 0.4 then
				TunnelProps.lantern(m, CFrame.new(q) * CFrame.Angles(0, 0, math.rad(90)), rng, false)
			elseif roll < 0.7 then
				deco(part(m, "Backpack", Vector3.new(1.6, 2, 1), CFrame.new(q + UP * 0.5) * CFrame.Angles(math.rad(80), rng:NextNumber(0, 3), 0), Fabric, pick({ rgb(60, 80, 60), rgb(120, 40, 36), rgb(40, 50, 80) }, rng)))
			else
				deco(part(m, "Shoe", Vector3.new(0.5, 0.4, 1.1), CFrame.new(q + UP * 0.2) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, rgb(40, 40, 42)))
			end
		end
		-- Where things will come from, one day; and the odd find in a dead
		-- end.
		if (deg[k] or 0) >= 3 or rng:NextNumber() < 0.3 then
			marker(m, "DeepSpawn", "DeepSpawn", f)
		end
		if (deg[k] or 0) == 1 and rng:NextNumber() < 0.5 then
			marker(m, "LootSpot", "LootSpot", f - wallward * 0.5)
		end
	end
	-- A chalked warning or two near the way in.
	local near = entry + Vector3.new(10, 0, 0)
	local hit = TunnelProps.wallHit(Vector3.new(near.X, T.floorAt(near) + 3.5, near.Z), Vector3.new(0, 0, 1), 12)
	if hit then
		local cf = CFrame.lookAt(hit.Position + hit.Normal * 0.1, hit.Position + hit.Normal * 2)
		label(m, cf * CFrame.Angles(0, math.pi, 0), Vector3.new(5, 1.6, 0.02), Enum.NormalId.Front, "灯りを消すな", DARK, rgb(214, 210, 200), Smooth, Enum.Font.PatrickHand).Transparency = 1
	end
	-- The east end: the roof down, cold air coming through the rubble.
	local stub = model(m, "HarbourWay")
	for _ = 1, 12 do
		local s = Vector3.new(rng:NextNumber(1.5, 4), rng:NextNumber(1, 3.5), rng:NextNumber(1.5, 4))
		part(stub, "Rubble", s, CFrame.new(stubEnd + Vector3.new(rng:NextNumber(-3, 1), s.Y * 0.4 + rng:NextNumber(0, 5), rng:NextNumber(-4, 4))) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 3), rng:NextNumber(-0.6, 0.6)), Slate, jitter(rgb(50, 50, 54), rng, 0.1))
	end
	local link = marker(stub, "HarbourLink", "HarbourLink", stubEnd)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 2
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(1.5, 3)
	e.EmissionDirection = Enum.NormalId.Left
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(120, 130, 140))
	e.Parent = link
end

-- ===== The fissure =====

-- From the lower workings' corner cell west under the gym to the top of
-- the chasm stair: narrow, twisting, a squeeze in places. Boarded across
-- at the start, with a rockfall half in front of it; a draught gives it
-- away.
local function fissure(parent, T, fromCell, toTop, rng)
	local m = model(parent, "Fissure")
	local y0 = fromCell.Y
	local pts = {
		fromCell + Vector3.new(-6, 0, 0),
		Vector3.new(462, y0 - 1, -104),
		Vector3.new(446, y0 - 3, -97),
		Vector3.new(428, y0 - 5, -108),
		Vector3.new(410, y0 - 8, -117),
		Vector3.new(392, y0 - 10, -126),
		Vector3.new(374, toTop.Y, -131),
	}
	-- The last stretch runs straight out onto the top step.
	table.insert(pts, toTop + (Vector3.new(toTop.X, 0, toTop.Z) - Vector3.new(chasmCentre(toTop.Y).X, 0, chasmCentre(toTop.Y).Z)).Unit * 2)
	for k = 1, #pts - 1 do
		T.carveTunnel(pts[k], pts[k + 1], 5.5)
	end
	for k = 1, #pts - 1 do
		T.flattenTunnel(pts[k], pts[k + 1], 5.5)
	end
	RouteCheck.add("fissure", pts, 2.2, 7, true)
	-- Boards across the crack, leaving a gap on one side.
	local a, b = pts[1], pts[2]
	local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	local across = Vector3.new(-dir.Z, 0, dir.X)
	local at = a + dir * 3
	for k, h in ipairs({ 1.4, 3.1, 4.8 }) do
		local c = at + across * -3.2 + UP * h
		part(m, "Board", Vector3.new(4.2, 0.5, 0.2), CFrame.lookAt(c, c + dir) * CFrame.Angles(0, 0, math.rad(if k == 2 then 12 else rng:NextNumber(-6, 6))), Wood, jitter(OLD_TIMBER, rng, 0.1))
	end
	part(m, "BrokenBoard", Vector3.new(3.6, 0.5, 0.2), CFrame.new(at + across * 2.5 + UP * 0.3) * CFrame.lookAt(Vector3.zero, dir).Rotation * CFrame.Angles(math.rad(80), 0, 0.3), Wood, OLD_TIMBER)
	T.fallenRocks(m, a - dir * 3 + across * -3, rng)
	-- The draught, pulling dust in.
	local d = part(m, "Draught", Vector3.new(6, 5, 0.2), CFrame.lookAt(a - dir * 2 + UP * 2.5, a + dir * 2 + UP * 2.5), Smooth, rgb(0, 0, 0))
	d.Transparency = 1
	d.CanCollide = false
	d.CanQuery = false
	d.CanTouch = false
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 3
	e.Lifetime = NumberRange.new(1.5, 2.5)
	e.Speed = NumberRange.new(2, 4)
	e.EmissionDirection = Enum.NormalId.Front
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(160, 150, 136))
	e.Parent = d
	-- Halfway along, rock come down into it.
	T.fallenRocks(m, pts[4], rng)
end

-- ===== Assembly =====

-- `T`: Underground's carving and dressing helpers. `rampTop`: the floor
-- of the maze junction the incline leaves from.
function TheDeep.build(parent, T, rampTop, rng)
	lightsLeft = 16
	-- The lower workings are cut in a different bed of rock: yellow-brown
	-- sandstone under the grey of the maze (it starts just under the
	-- maze's lowest floors).
	terrain:FillBlock(CFrame.new(561, -127, -55), Vector3.new(182, 46, 122), Enum.Material.Sandstone)
	-- Black rock for the Deep, under the crag and under the outcrop (before
	-- anything's carved down there).
	terrain:FillBlock(CFrame.new(610, -472, 22), Vector3.new(284, 96, 292), BASALT)
	terrain:FillBlock(CFrame.new(385, -447, -128), Vector3.new(170, 46, 144), BASALT)
	local rampFoot, fissureCell = lowerWorkings(parent, T, rng)
	incline(parent, T, rampTop, rampFoot, rng)
	task.wait()
	carveChasm(rng)
	local top, stair = descent(parent, rng)
	fissure(parent, T, fissureCell, top, rng)
	task.wait()
	deepWorkings(parent, T, top, rng)
	chasmFloor(stair, (function()
		local x, z = gridXZ(DEEP, DEEP_ENTRY[1], DEEP_ENTRY[2])
		return Vector3.new(x, CH.bottom, z)
	end)(), rng)
	cage(parent, rng)
end

return TheDeep
