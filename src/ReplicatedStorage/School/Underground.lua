-- What lies behind the bottom floor's east stairwell door: tunnels cut
-- into the rock the school is built against.
--
--   * A maze of rough cave passages (terrain carved out of the crag), with
--     dead ends and loops, drifting deeper the further it goes. Caverns,
--     flooded pits, timber supports, old mine rails, strings of work lamps
--     and clusters of glowing fungus.
--   * Three ways out of it:
--       - the facility entrance at the maze's far corner, where the tunnel
--         turns to steel and a vast straight incline of steps runs down
--         under the whole maze to a door in the courtyard wall
--         (Facility.lua);
--       - a cave mouth onto a rock outcrop below the school's south side,
--         where the gymnasium will stand;
--       - a cave mouth onto a ledge on the crag's far side, looking out
--         over the drop at the trawler's hanging anchor chain;
--       - a passage out through the crag's north face onto the pipe
--         bridge into the department store's 9th floor.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local TunnelRooms = require(script.Parent.TunnelRooms)
local TunnelProps = require(script.Parent.TunnelProps)
local Facility = require(script.Parent.Facility)
local RouteCheck = require(script.Parent.RouteCheck)
local DepartmentStore = require(script.Parent.DepartmentStore)
local TheDeep = require(script.Parent.TheDeep)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Concrete, Metal, Wood, Smooth = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.Wood, Enum.Material.SmoothPlastic

local terrain = workspace.Terrain
local AIR, ROCK, WATER = Enum.Material.Air, Enum.Material.Rock, Enum.Material.Water

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local STEEL = Color3.fromRGB(96, 98, 100)
local RUST_COLOR = Color3.fromRGB(116, 76, 48)

-- The bottom floor's east stairwell door, and the ground level there.
local ENTRY = Vector3.new(Config.TOTAL_LENGTH + Config.STAIRWELL_LENGTH + 0.5, Config.BOTTOM_Y - 1.2, 3.25)

-- The maze is a grid of cells; tunnels run between neighbouring cells.
local GRID = { x0 = 486, z0 = -100, step = 30, nx = 9, nz = 9 }
local TUNNEL_R = 7
local ENTRY_CELL = { 1, 4 }
local GYM_CELL = { 1, 1 }
local LEDGE_CELL = { 9, 5 }
-- The far corner from the entrance, so the facility's incline has room
-- to run all the way back under the maze to the courtyard door.
local FACILITY_CELL = { 9, 1 }
-- On the maze's north edge, under the department store's men's floor:
-- a passage runs out through the crag's north face to the store's pipe
-- bridge (DepartmentStore.LINK).
local STORE_CELL = { 4, 9 }
-- The junction the incline down to the lower workings leaves from
-- (TheDeep.lua): well away from the way in from the school.
local INCLINE_CELL = { 6, 2 }
local OUTCROP = { x0 = 244, x1 = 468, z0 = -200, z1 = -44 }

local Underground = {}

local function key(i, j)
	return i .. "," .. j
end

local function cellXZ(i, j)
	return GRID.x0 + (i - 1) * GRID.step, GRID.z0 + (j - 1) * GRID.step
end

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

-- Rounded down onto the terrain's 4-stud grid, so terrain surfaces land
-- where we expect.
local function onGrid(y)
	return math.floor(y / 4) * 4
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { terrain }

-- The actual carved floor / ceiling height near a point.
local function floorAt(p)
	local hit = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), terrainOnly)
	return if hit then hit.Position.Y else p.Y
end

local function ceilingAt(p)
	local hit = workspace:Raycast(p + Vector3.new(0, 2, 0), Vector3.new(0, 30, 0), terrainOnly)
	return if hit then hit.Position.Y else p.Y + 10
end

-- ===== Maze layout =====

-- Cell floor heights sink with distance from the entrance, with some noise.
local function cellHeights(rng)
	local heights = {}
	local ex, ez = cellXZ(ENTRY_CELL[1], ENTRY_CELL[2])
	for i = 1, GRID.nx do
		for j = 1, GRID.nz do
			local x, z = cellXZ(i, j)
			local dist = math.sqrt((x - ex) ^ 2 + (z - ez) ^ 2)
			heights[key(i, j)] = math.clamp(ENTRY.Y - 0.18 * dist + rng:NextNumber(-5, 5), -100, ENTRY.Y)
		end
	end
	heights[key(ENTRY_CELL[1], ENTRY_CELL[2])] = ENTRY.Y
	-- The gym terrace and the ledge sit level with the cells they open off.
	heights[key(GYM_CELL[1], GYM_CELL[2])] = onGrid(heights[key(GYM_CELL[1], GYM_CELL[2])])
	heights[key(LEDGE_CELL[1], LEDGE_CELL[2])] = onGrid(heights[key(LEDGE_CELL[1], LEDGE_CELL[2])])
	heights[key(FACILITY_CELL[1], FACILITY_CELL[2])] = onGrid(heights[key(FACILITY_CELL[1], FACILITY_CELL[2])])
	heights[key(STORE_CELL[1], STORE_CELL[2])] = onGrid(DepartmentStore.LINK.y)
	-- The caves next to the facility sit level with it, so every tunnel
	-- reaches its blast doors at floor height rather than as a step of rock.
	local fh = heights[key(FACILITY_CELL[1], FACILITY_CELL[2])]
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local k = key(FACILITY_CELL[1] + d[1], FACILITY_CELL[2] + d[2])
		if heights[k] then
			heights[k] = fh
		end
	end
	return heights
end

-- Recursive backtracker over the cells, then a few extra
-- links for loops (only between cells at similar heights, so no tunnel is
-- too steep to walk).
local function mazeEdges(rng, heights)
	local cells = {}
	for i = 1, GRID.nx do
		for j = 1, GRID.nz do
			cells[key(i, j)] = { i = i, j = j }
		end
	end

	local edges, linked = {}, {}
	local function link(a, b)
		table.insert(edges, { a, b })
		linked[key(a.i, a.j) .. "|" .. key(b.i, b.j)] = true
		linked[key(b.i, b.j) .. "|" .. key(a.i, a.j)] = true
	end
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

	local start = cells[key(ENTRY_CELL[1], ENTRY_CELL[2])]
	local visited = { [key(start.i, start.j)] = true }
	local stack = { start }
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

	for _, c in pairs(cells) do
		for _, d in ipairs({ { 1, 0 }, { 0, 1 } }) do
			local n = cells[key(c.i + d[1], c.j + d[2])]
			if n and not linked[key(c.i, c.j) .. "|" .. key(n.i, n.j)] and rng:NextNumber() < 0.12 then
				if math.abs(heights[key(c.i, c.j)] - heights[key(n.i, n.j)]) < 8 then
					link(c, n)
				end
			end
		end
	end
	return cells, edges
end

-- ===== Carving =====

-- Hollow out a tunnel along a floor line from a to b.
local function carveTunnel(a, b, radius)
	local len = (b - a).Magnitude
	local steps = math.max(1, math.ceil(len / (radius * 0.45)))
	for k = 0, steps do
		terrain:FillBall(a:Lerp(b, k / steps) + Vector3.new(0, radius * 0.6, 0), radius, AIR)
	end
end

-- Lay a flat rock floor along the same line (the carved balls leave a
-- rounded trough otherwise).
local function flattenTunnel(a, b, radius)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local lower = Vector3.new(0, 2, 0)
	terrain:FillBlock(CFrame.lookAt((a + b) / 2 - lower, b - lower), Vector3.new(radius * 1.5, 4, (b - a).Magnitude + radius), ROCK)
end

-- ===== Tunnel dressing =====

local function workLamp(parent, at, rng)
	local roll = rng:NextNumber()
	if roll < 0.2 then
		return -- lamp long gone
	end
	local ceiling = ceilingAt(at)
	local lampY = math.max(at.Y + 5, ceiling - 1.4)
	cylinder(parent, "LampCable", ceiling - lampY + 0.5, 0.08, CFrame.new(at.X, (ceiling + lampY) / 2, at.Z) * UPRIGHT, Smooth, Color3.fromRGB(30, 30, 30))
	local dead = roll < 0.32
	local bulb = part(parent, "WorkLamp", Vector3.new(0.7, 0.7, 0.7), Vector3.new(at.X, lampY, at.Z), if dead then Smooth else Enum.Material.Neon, if dead then Color3.fromRGB(90, 86, 80) else Color3.fromRGB(255, 214, 150))
	bulb.Shape = Enum.PartType.Ball
	bulb.CanCollide = false
	part(parent, "LampCage", Vector3.new(0.9, 0.2, 0.9), Vector3.new(at.X, lampY + 0.45, at.Z), Metal, STEEL).CanCollide = false
	if not dead then
		local light = Instance.new("PointLight")
		light.Range = 20
		light.Brightness = 1.1
		light.Color = Color3.fromRGB(255, 200, 140)
		light.Parent = bulb
		if roll > 0.85 then
			bulb:AddTag("FlickerLight")
		end
	end
end

-- A timber set: two squared posts on sills, a cap beam, wedges driven in
-- over the cap, and knee braces into the corners.
local function timberFrame(parent, at, along)
	local across = Vector3.new(-along.Z, 0, along.X)
	local wood = Color3.fromRGB(96, 74, 52)
	local dark = Color3.fromRGB(70, 54, 40)
	local top = 8.5
	local frame = CFrame.fromMatrix(at, across, Vector3.yAxis)
	for _, s in ipairs({ -1, 1 }) do
		part(parent, "TimberSill", Vector3.new(1.6, 0.5, 1.6), frame * CFrame.new(s * 4.5, 0.25, 0), Wood, dark)
		part(parent, "TimberPost", Vector3.new(0.9, top, 0.9), frame * CFrame.new(s * 4.5, top / 2, 0) * CFrame.Angles(0, 0, s * math.rad(-3)), Wood, wood)
		part(parent, "TimberBrace", Vector3.new(0.5, 2.6, 0.5), frame * CFrame.new(s * 3.6, top - 1.3, 0) * CFrame.Angles(0, 0, s * math.rad(45)), Wood, wood)
	end
	part(parent, "TimberCap", Vector3.new(10.8, 1, 1), frame * CFrame.new(0, top + 0.4, 0), Wood, wood)
	for k = -2, 2 do
		part(parent, "TimberWedge", Vector3.new(0.6, 0.5, 1.4), frame * CFrame.new(k * 2, top + 1.15, 0), Wood, dark)
	end
end

local function mineRails(parent, a, b, rng)
	local dir = (b - a).Unit
	local flat = Vector3.new(dir.X, 0, dir.Z).Unit
	local across = Vector3.new(-flat.Z, 0, flat.X)
	local lift = Vector3.new(0, 0.2, 0)
	for _, s in ipairs({ -1, 1 }) do
		local off = across * s * 1.3 + lift + Vector3.new(0, 0.2, 0)
		part(parent, "Rail", Vector3.new(0.25, 0.25, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + off, b + off), Metal, RUST_COLOR)
	end
	local len = (b - a).Magnitude
	for d = 1, len - 1, 2.6 do
		local p = a + dir * d + lift
		part(parent, "Sleeper", Vector3.new(3.6, 0.25, 0.7), CFrame.lookAt(p, p + dir), Wood, jitter(Color3.fromRGB(86, 66, 48), rng, 0.1))
	end
	if rng:NextNumber() < 0.35 then
		local p = a:Lerp(b, rng:NextNumber(0.3, 0.7)) + Vector3.new(0, 1.6, 0)
		local cart = model(parent, "MineCart")
		part(cart, "CartBody", Vector3.new(3.2, 2.4, 4.2), CFrame.lookAt(p, p + dir), Enum.Material.CorrodedMetal, RUST_COLOR)
		for _, s in ipairs({ -1, 1 }) do
			for _, f in ipairs({ -1.4, 1.4 }) do
				cylinder(cart, "CartWheel", 0.3, 1, CFrame.lookAt(p, p + dir) * CFrame.new(s * 1.35, -1.2, f), Metal, STEEL)
			end
		end
	end
end

-- Glowing fungus growing at the foot of a tunnel wall: a cluster of
-- mushrooms on the floor, shelf fungi up the rock beside it, a few spores.
local function fungus(parent, at, wallward, rng)
	local palette = pick(TunnelProps.GLOWS, rng)
	local m = model(parent, "GlowFungus")
	TunnelProps.mushroomCluster(m, at, rng, rng:NextNumber(0.8, 1.5), palette)
	if rng:NextNumber() < 0.5 then
		TunnelProps.mushroomCluster(m, at + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), rng, rng:NextNumber(0.5, 0.9), palette)
	end
	local hit = TunnelProps.wallHit(at + Vector3.new(0, 2.5, 0), wallward, 10)
	if hit then
		TunnelProps.bracketFungus(m, hit.Position, hit.Normal, rng, palette)
	end
	TunnelProps.spores(m, at, 3, rng:NextInteger(4, 9), rng, palette)
end

local function fallenRocks(parent, at, rng)
	for _ = 1, rng:NextInteger(3, 7) do
		local s = Vector3.new(rng:NextNumber(0.8, 3), rng:NextNumber(0.6, 2), rng:NextNumber(0.8, 3))
		part(parent, "FallenRock", s, CFrame.new(at + Vector3.new(rng:NextNumber(-3, 3), s.Y * 0.4, rng:NextNumber(-3, 3))) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Enum.Material.Slate, jitter(Color3.fromRGB(90, 88, 84), rng, 0.12))
	end
end

-- Whatever the miners left: a heap of supplies, a lantern, tools leant on
-- the rock, a drum, a chair from the school.
local function leftBehind(parent, at, wallward, rng)
	local roll = rng:NextNumber()
	local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	if roll < 0.4 then
		TunnelProps.supplyHeap(parent, at, rng, rng:NextNumber(1.5, 3))
	elseif roll < 0.55 then
		TunnelProps.lantern(parent, CFrame.new(at) * yaw, rng, rng:NextNumber() < 0.45)
	elseif roll < 0.72 then
		-- Tools leant against the wall.
		local hit = TunnelProps.wallHit(at + Vector3.new(0, 1, 0), wallward, 8)
		local base = if hit then hit.Position - wallward.Unit * 0.8 - Vector3.new(0, 1, 0) else at
		local lean = CFrame.lookAt(base, base + wallward) * CFrame.Angles(math.rad(-16), 0, 0)
		TunnelProps.pickaxe(parent, lean * CFrame.new(-0.7, 0, 0))
		if rng:NextNumber() < 0.6 then
			TunnelProps.shovel(parent, lean * CFrame.new(0.8, 0, 0))
		end
	elseif roll < 0.85 then
		TunnelProps.drum(parent, CFrame.new(at) * yaw, rng)
		if rng:NextNumber() < 0.5 then
			TunnelProps.drum(parent, CFrame.new(at + Vector3.new(2.3, 0, 0.4)) * yaw, rng)
		end
	else
		local chair = Props.studentChair(parent, at, Props.DESK_TOP_COLOR)
		Props.tipChair(chair, at, rng:NextNumber(0, math.pi * 2))
	end
end

-- A heavy timber frame round a cave mouth where a tunnel meets open air.
local function caveMouth(parent, at, along)
	timberFrame(parent, at, along)
	timberFrame(parent, at + along * 3, along)
end

-- ===== Assembly =====

function Underground.build(parent, rng)
	local heights = cellHeights(rng)
	local cells, edges = mazeEdges(rng, heights)
	local function point(c)
		local x, z = cellXZ(c.i, c.j)
		return Vector3.new(x, heights[key(c.i, c.j)], z)
	end
	local function cellPoint(ij)
		return point({ i = ij[1], j = ij[2] })
	end

	-- The outcrop the gym lies on, just below the school's south side: a
	-- spur of rock slumped against the school's substructure and the crag,
	-- its open sides sloping out and down into the haze rather than
	-- dropping sheer. Gym heaps a lumpy top onto it around the gym.
	local gymFloor = heights[key(GYM_CELL[1], GYM_CELL[2])]
	local o = OUTCROP
	local bulkTop = gymFloor - 14
	local SPREAD = 0.45
	local y, x0, z0 = bulkTop, o.x0, o.z0
	while y > Config.ROCK_BOTTOM - 100 do
		local ext = (bulkTop - y) * SPREAD
		x0, z0 = o.x0 - ext, o.z0 - ext
		local yb = y - 30
		terrain:FillBlock(CFrame.new((x0 + o.x1) / 2, (y + yb) / 2, (z0 + o.z1) / 2), Vector3.new(o.x1 - x0, y - yb, o.z1 - z0), ROCK)
		-- Past the crag's south end the east side slopes away too.
		local cragZ0 = -124
		terrain:FillBlock(CFrame.new(o.x1 + ext * 0.6 / 2, (y + yb) / 2, (z0 + cragZ0) / 2), Vector3.new(ext * 0.6 + 0.1, y - yb, cragZ0 - z0), ROCK)
		-- Lumps all along the slopes so they read as rock, not steps.
		for z = z0, o.z1 - 10, 20 do
			terrain:FillBall(Vector3.new(x0 + rng:NextNumber(-6, 4), y - rng:NextNumber(0, 30), z + rng:NextNumber(-6, 6)), rng:NextNumber(12, 22), ROCK)
		end
		for x = x0, o.x1 + ext * 0.6, 20 do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-6, 6), y - rng:NextNumber(0, 30), z0 + rng:NextNumber(-6, 4)), rng:NextNumber(12, 22), ROCK)
		end
		y = yb
	end
	box(parent, "OutcropPillar", x0 + 30, o.x1, -1900, y + 12, z0 + 30, o.z1, Concrete, Color3.fromRGB(78, 78, 76))

	-- A narrow ledge on the crag's far side.
	local ledgeStart = cellPoint(LEDGE_CELL)
	local ledgeY = ledgeStart.Y
	terrain:FillBlock(CFrame.new(762, ledgeY - 8, ledgeStart.Z), Vector3.new(24, 16, 36), ROCK)
	for _ = 1, 5 do
		terrain:FillBall(Vector3.new(rng:NextNumber(752, 768), ledgeY - rng:NextNumber(10, 22), ledgeStart.Z + rng:NextNumber(-14, 14)), rng:NextNumber(6, 10), ROCK)
	end
	task.wait()

	-- Carve every tunnel, cavern and special passage first...
	local runs = {}
	for _, e in ipairs(edges) do
		table.insert(runs, { point(e[1]), point(e[2]), TUNNEL_R })
	end
	local entryCell = cellPoint(ENTRY_CELL)
	-- Starts a little way out from the stairwell wall so its rock floor
	-- doesn't poke into the stairwell.
	table.insert(runs, { ENTRY + Vector3.new(3, 0, 0), Vector3.new(ENTRY.X + 8, ENTRY.Y, ENTRY.Z), 4.5 })
	table.insert(runs, { Vector3.new(ENTRY.X + 8, ENTRY.Y, ENTRY.Z), entryCell, TUNNEL_R })
	local gymCell = cellPoint(GYM_CELL)
	local gymMouth = Vector3.new(o.x1 - 8, gymFloor, gymCell.Z)
	table.insert(runs, { gymCell, gymMouth, TUNNEL_R })
	local ledgeMouth = Vector3.new(760, ledgeY, ledgeStart.Z)
	table.insert(runs, { ledgeStart, ledgeMouth, TUNNEL_R })
	local storeCell = cellPoint(STORE_CELL)
	-- (Carried well out past the face: the crag's buttresses bulge out
	-- over it here and there.)
	local storeMouth = Vector3.new(storeCell.X, storeCell.Y, DepartmentStore.LINK.mouthZ + 16)
	table.insert(runs, { storeCell, storeMouth, TUNNEL_R })
	local facilityKey = key(FACILITY_CELL[1], FACILITY_CELL[2])

	-- Some junctions become rooms of their own, one of each type.
	local special = {
		[key(ENTRY_CELL[1], ENTRY_CELL[2])] = true,
		[facilityKey] = true,
		[key(GYM_CELL[1], GYM_CELL[2])] = true,
		[key(LEDGE_CELL[1], LEDGE_CELL[2])] = true,
		[key(STORE_CELL[1], STORE_CELL[2])] = true,
		[key(INCLINE_CELL[1], INCLINE_CELL[2])] = true,
	}
	local candidates = {}
	for k in pairs(cells) do
		if not special[k] then
			table.insert(candidates, k)
		end
	end
	table.sort(candidates)
	local roomAt = {}
	for _, roomType in ipairs(TunnelRooms.TYPES) do
		if #candidates == 0 then
			break
		end
		local k = table.remove(candidates, rng:NextInteger(1, #candidates))
		roomAt[k] = roomType
	end

	for _, run in ipairs(runs) do
		carveTunnel(run[1], run[2], run[3])
	end
	local caverns = {}
	for k, c in pairs(cells) do
		local p = point(c)
		terrain:FillBall(p + Vector3.new(0, TUNNEL_R * 0.6, 0), TUNNEL_R + 1, AIR)
		if not special[k] and not roomAt[k] and rng:NextNumber() < 0.22 then
			local r = rng:NextNumber(10, 15)
			terrain:FillBall(p + Vector3.new(0, r * 0.5, 0), r, AIR)
			caverns[k] = r
		end
	end
	task.wait()

	-- ...then lay flat floors, and sink a few flooded pits.
	for _, run in ipairs(runs) do
		flattenTunnel(run[1], run[2], run[3])
	end
	for k, c in pairs(cells) do
		local p = point(c)
		terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, (caverns[k] or TUNNEL_R) - 1, ROCK)
	end
	for k, roomType in pairs(roomAt) do
		TunnelRooms[roomType].carve(point(cells[k]), rng)
	end
	for k, c in pairs(cells) do
		if not special[k] and not roomAt[k] and rng:NextNumber() < 0.15 then
			local p = point(c)
			terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, 5, AIR)
			terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2.6, 0)), 2.8, 5, WATER)
		end
	end
	task.wait()

	-- Dress the tunnels.
	local tunnels = model(parent, "Tunnels")
	local facilityLinks = {}
	for _, e in ipairs(edges) do
		local a, b = point(e[1]), point(e[2])
		local ka, kb = key(e[1].i, e[1].j), key(e[2].i, e[2].j)
		if ka == facilityKey or kb == facilityKey then
			-- Left bare: the facility's entrance room fills this junction.
			table.insert(facilityLinks, if ka == facilityKey then b else a)
			continue
		end
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
		local mid = (a + b) / 2
		workLamp(tunnels, Vector3.new(mid.X, floorAt(mid), mid.Z), rng)
		if rng:NextNumber() < 0.25 then
			local p = a:Lerp(b, rng:NextNumber(0.25, 0.75))
			timberFrame(tunnels, Vector3.new(p.X, floorAt(p), p.Z), along)
		end
		if rng:NextNumber() < 0.2 and math.abs(b.Y - a.Y) < 4 then
			mineRails(tunnels, a, b, rng)
		end
	end
	for k, roomType in pairs(roomAt) do
		TunnelRooms[roomType].furnish(tunnels, point(cells[k]), rng)
	end
	for k, c in pairs(cells) do
		if roomAt[k] or k == facilityKey then
			continue
		end
		local p = point(c)
		local wallward = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector * ((caverns[k] or TUNNEL_R) - 2)
		local nearWall = p + wallward
		if rng:NextNumber() < 0.3 then
			fungus(tunnels, Vector3.new(nearWall.X, floorAt(nearWall), nearWall.Z), wallward, rng)
		end
		if rng:NextNumber() < 0.3 then
			fallenRocks(tunnels, Vector3.new(p.X, floorAt(p), p.Z) - wallward * 0.5, rng)
		end
		if rng:NextNumber() < 0.25 then
			local spot = p - wallward * 0.6
			leftBehind(tunnels, Vector3.new(spot.X, floorAt(spot), spot.Z), -wallward, rng)
		end
	end
	caveMouth(tunnels, Vector3.new(o.x1 - 2, gymFloor, gymCell.Z), Vector3.new(-1, 0, 0))
	caveMouth(tunnels, Vector3.new(ledgeMouth.X - 10, ledgeY, ledgeMouth.Z), Vector3.new(1, 0, 0))
	caveMouth(tunnels, Vector3.new(storeCell.X, storeCell.Y, DepartmentStore.LINK.mouthZ - 14), Vector3.new(0, 0, 1))
	workLamp(tunnels, Vector3.new(ENTRY.X + 6, ENTRY.Y, ENTRY.Z), rng)
	task.wait()

	-- The facility: entrance room, the incline down, the way out.
	Facility.build(parent, cellPoint(FACILITY_CELL), facilityLinks, rng)

	-- Below it all: the lower workings, the chasm, the Deep.
	TheDeep.build(parent, {
		carveTunnel = carveTunnel,
		flattenTunnel = flattenTunnel,
		floorAt = floorAt,
		ceilingAt = ceilingAt,
		workLamp = workLamp,
		timberFrame = timberFrame,
		mineRails = mineRails,
		fungus = fungus,
		fallenRocks = fallenRocks,
		leftBehind = leftBehind,
	}, cellPoint(INCLINE_CELL), rng)
	task.wait()

	-- Every tunnel must stay walkable, whatever gets built across it later.
	for _, run in ipairs(runs) do
		RouteCheck.add(string.format("tunnel (%.0f, %.0f) to (%.0f, %.0f)", run[1].X, run[1].Z, run[2].X, run[2].Z), { run[1], run[2] }, 3.5, 8)
	end

	-- Where the gym goes: the terrace height and the tunnel mouth facing it.
	return { gymFloor = gymFloor, gymMouth = Vector3.new(o.x1, gymFloor, gymCell.Z), outcrop = OUTCROP, ledge = Vector3.new(774, ledgeY, ledgeStart.Z) }
end

return Underground
