-- The facility: where the tunnels turn to steel.
--
-- At the far corner of the tunnel maze the rock gives way to a steel
-- entrance room, its blast doors jammed half open. A stair well drops
-- through its floor to the head of an immense straight incline: two
-- hundred-odd steps of steel plate running dead straight down through the
-- rock, under the whole maze, in a ribbed hall lit by strip lights (a lot
-- of them dead). An inclined lift runs beside the steps; its car has come
-- off partway down. At the bottom, a tall hall with a checkpoint and
-- lockers and three ways on: a sealed vault door and a jammed loading
-- shutter (for later), and a doorway into a maze of rooms and corridors
-- (FacilityMaze.lua) whose fire exit leads out to the courtyard door.
--
-- Everything is built in the facility's own frame, then pivoted into
-- place: origin on the floor at the maze cell it opens off, +X pointing
-- (level) toward the courtyard door, Y up.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local FacilityMaze = require(script.Parent.FacilityMaze)
local RouteCheck = require(script.Parent.RouteCheck)
local HiddenSea = require(script.Parent.HiddenSea)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Metal, Plate, Smooth, Concrete, Rust, Neon, Wood = Enum.Material.Metal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.CorrodedMetal, Enum.Material.Neon, Enum.Material.Wood

local terrain = workspace.Terrain
local AIR = Enum.Material.Air

local STEEL = Color3.fromRGB(96, 98, 100)
local WALL = Color3.fromRGB(84, 88, 90)
local DARK = Color3.fromRGB(58, 60, 62)
local SAFETY_YELLOW = Color3.fromRGB(214, 176, 40)
local HAZARD_BLACK = Color3.fromRGB(26, 26, 28)
local LAMP_WHITE = Color3.fromRGB(226, 234, 222)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local VEST = 14 -- the entrance room is 2 * VEST square
local VEST_H = 14
local WELL = 10 -- the stair well through its floor is 2 * WELL square
local WELL_DEPTH = 34 -- keeps the incline below the tunnel maze
local HEAD_X = 14 -- top step of the incline
local STAIR_Z = 18 -- the steps span z -STAIR_Z..STAIR_Z
local BAY_Z0, BAY_Z1 = 18, 26 -- the inclined lift beside them
local WALL_Z0, WALL_Z1 = -18.5, 26.5
local SEG = 12 -- rib spacing down the incline
local HALL_Z0, HALL_Z1 = -26, 30
local HALL_H = 72
local HALL_LEN = 40 -- hall floor beyond the foot of the steps
local CONN = 28 -- from the hall's end wall to the courtyard door
-- The vault door in the hall's end wall (centre z, and radius), with the
-- shaft down to the hidden sea just behind it.
local VAULT_Z, VAULT_R = 14, 9
-- The maze beside the bottom hall (see FacilityMaze.build).
local MAZE = { x0 = 150, z0 = -30, cols = 10, rows = 4, fireX = 322, exitMinZ = -72 }

local Facility = {}

-- ===== Helpers (all in the facility frame) =====

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

-- A flat panel from a to b (its length), `width` across, `thickness` thick.
local function slab(parent, name, a, b, width, thickness, material, color)
	return part(parent, name, Vector3.new(width, thickness, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), material, color)
end

local function wall(parent, name, axis, fixed, a, b, y0, y1, openings, color)
	BuildUtil.strip(parent, {
		name = name,
		axis = axis,
		fixed = fixed,
		spanStart = a,
		spanEnd = b,
		bottom = y0,
		top = y1,
		thickness = 1,
		openings = openings,
		material = Metal,
		color = color or WALL,
	})
end

local function sign(parent, cframe, size, text, face, color, textColor, font)
	local plate = part(parent, "Sign", size, cframe, Smooth, color)
	plate.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui
	gui.Parent = plate
	return plate
end

-- Strip light; about a fifth are dead and some of the rest flicker.
local function lightStrip(parent, cframe, size, face, range, rng)
	local roll = rng:NextNumber()
	local lit = roll > 0.22
	local strip = part(parent, "LightStrip", size, cframe, if lit then Neon else Smooth, if lit then LAMP_WHITE else Color3.fromRGB(80, 82, 80))
	strip.CanCollide = false
	if lit then
		local light = Instance.new("SurfaceLight")
		light.Face = face
		light.Range = range
		light.Angle = 150
		light.Brightness = 1.1
		light.Color = Color3.fromRGB(220, 232, 214)
		light.Parent = strip
		if roll < 0.4 then
			strip:AddTag("FlickerLight")
		end
	end
	return strip
end

local function beacon(parent, at)
	local b = part(parent, "EmergencyBeacon", Vector3.new(0.8, 0.8, 0.8), at, Neon, Color3.fromRGB(230, 40, 30))
	b.Shape = Enum.PartType.Ball
	b.CanCollide = false
	local red = Instance.new("PointLight")
	red.Color = Color3.fromRGB(255, 50, 40)
	red.Range = 18
	red.Brightness = 1.3
	red.Parent = b
	b:AddTag("FlickerLight")
end

local function faceFor(axis, outward)
	if axis == "X" then
		return if outward > 0 then Enum.NormalId.Back else Enum.NormalId.Front
	end
	return if outward > 0 then Enum.NormalId.Right else Enum.NormalId.Left
end

-- ===== The entrance room and stair well =====

-- A doorway in a wall of the entrance room, blast doors jammed half open
-- (just wide enough to squeeze through), hazard stripes, warning sign.
local function blastDoorway(m, axis, fixed, along, outward, rng)
	local function at(a, y, off)
		return if axis == "X" then Vector3.new(a, y, fixed + off) else Vector3.new(fixed + off, y, a)
	end
	local function size(a, y, t)
		return if axis == "X" then Vector3.new(a, y, t) else Vector3.new(t, y, a)
	end
	local doorColor = Color3.fromRGB(110, 112, 108)
	local gapL, gapR = rng:NextNumber(-1.9, -1.2), rng:NextNumber(1.6, 2.4)
	part(m, "BlastDoor", size(4.8, 9, 1.2), at(along + gapL - 2.4, 4.5, 0), Metal, doorColor)
	part(m, "BlastDoor", size(4.8, 9, 1.2), at(along + gapR + 2.4, 4.5, 0), Metal, doorColor)
	for k = 0, 7 do
		local a = along - 4.5 + k * 9 / 8
		for _, side in ipairs({ -1, 1 }) do
			part(m, "HazardStripe", size(9 / 8, 1, 0.1), at(a + 9 / 16, 9.5, side * 0.56), Smooth, if k % 2 == 0 then SAFETY_YELLOW else HAZARD_BLACK)
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		part(m, "DoorJamb", size(0.6, 10, 1.4), at(along + s * 4.3, 5, 0), Metal, DARK)
	end
	sign(m, CFrame.new(at(along + 6.8, 5.5, outward * 0.56)), size(3.4, 1.6, 0.1), "立入禁止", faceFor(axis, outward), Color3.fromRGB(200, 40, 34), Color3.fromRGB(240, 236, 226))
	beacon(m, at(along, 10.6, -outward * 0.9))
end

-- The steel room at the top, with the well through its floor.
-- `doors` = { {axis, fixed, along, outward} } where tunnels arrive.
local function entrance(m, doors, rng)
	local openings = {}
	for _, d in ipairs(doors) do
		local k = d.axis .. d.fixed
		openings[k] = openings[k] or {}
		table.insert(openings[k], { center = d.along, width = 8, bottom = 0, top = 9 })
	end
	for _, w in ipairs({ { "X", -VEST }, { "X", VEST }, { "Z", -VEST }, { "Z", VEST } }) do
		wall(m, "EntranceWall", w[1], w[2], -VEST - 0.5, VEST + 0.5, 0, VEST_H, openings[w[1] .. w[2]] or {})
	end
	for _, d in ipairs(doors) do
		blastDoorway(m, d.axis, d.fixed, d.along, d.outward, rng)
	end
	box(m, "EntranceCeiling", -VEST - 0.5, VEST + 0.5, VEST_H, VEST_H + 1, -VEST - 0.5, VEST + 0.5, Metal, DARK)
	-- Walkway round the well.
	box(m, "Walkway", -VEST, VEST, -1, 0, WELL, VEST, Plate, STEEL)
	box(m, "Walkway", -VEST, VEST, -1, 0, -VEST, -WELL, Plate, STEEL)
	box(m, "Walkway", -VEST, -WELL, -1, 0, -WELL, WELL, Plate, STEEL)
	box(m, "Walkway", WELL, VEST, -1, 0, -WELL, WELL, Plate, STEEL)
	-- Railing round the well, open where the stairs start (back half of
	-- the +Z edge).
	local function rail(a, b)
		rod(m, "WellRail", a + Vector3.new(0, 3.2, 0), b + Vector3.new(0, 3.2, 0), 0.25, Metal, SAFETY_YELLOW)
		rod(m, "WellRail", a + Vector3.new(0, 1.6, 0), b + Vector3.new(0, 1.6, 0), 0.2, Metal, SAFETY_YELLOW)
		for _, p in ipairs({ a, b }) do
			rod(m, "WellRailPost", p, p + Vector3.new(0, 3.2, 0), 0.2, Metal, SAFETY_YELLOW)
		end
	end
	rail(Vector3.new(-WELL, 0, -WELL), Vector3.new(WELL, 0, -WELL))
	rail(Vector3.new(-WELL, 0, -WELL), Vector3.new(-WELL, 0, WELL))
	rail(Vector3.new(WELL, 0, -WELL), Vector3.new(WELL, 0, WELL))
	rail(Vector3.new(-0.5, 0, WELL), Vector3.new(WELL, 0, WELL))

	for _, x in ipairs({ -7, 7 }) do
		lightStrip(m, CFrame.new(x, VEST_H - 0.2, 0), Vector3.new(0.8, 0.3, 14), Enum.NormalId.Bottom, 20, rng)
	end
	for _, z in ipairs({ -VEST + 1.5, VEST - 1.5 }) do
		cylinder(m, "CeilingPipe", VEST * 2, 0.9, CFrame.new(0, VEST_H - 1.2, z), Metal, STEEL)
	end
	-- A few things left in the corners.
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		if rng:NextNumber() < 0.6 then
			local at = Vector3.new(c[1] * (VEST - 2), 0, c[2] * (VEST - 2))
			part(m, "Crate", Vector3.new(2.6, 2.6, 2.6), CFrame.new(at + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), Metal, jitter(Color3.fromRGB(70, 90, 70), rng, 0.1))
		end
	end
	sign(m, CFrame.new(WELL + 0.2, 7, 0), Vector3.new(0.1, 1.8, 10), "第三搬送路", Enum.NormalId.Left, DARK, SAFETY_YELLOW)
end

-- Switchback flights down the well: four flights, landings at each end.
local function well(m, rng)
	local D = WELL_DEPTH
	local r = D / 4
	local steps = 10
	wall(m, "WellWall", "X", -WELL - 0.5, -WELL, WELL, -D - 1, 0, {})
	wall(m, "WellWall", "X", WELL + 0.5, -WELL, WELL, -D - 1, 0, {})
	wall(m, "WellWall", "Z", -WELL - 0.5, -WELL - 1, WELL + 1, -D - 1, 0, {})
	-- The +X side is open at the bottom onto the incline; the head of the
	-- incline hall (Facility.build) closes it below that.
	wall(m, "WellWall", "Z", WELL + 0.5, -WELL - 1, WELL + 1, -9, 0, {})
	box(m, "WellFloor", -WELL, WELL, -D - 1, -D, -WELL, WELL, Plate, STEEL)

	local back, front = { -WELL + 0.5, -0.5 }, { 0.5, WELL - 0.5 }
	local function flight(xr, zFrom, zTo, yFrom)
		local run = (zTo - zFrom) / steps
		for s = 1, steps do
			local top = yFrom - s * (r / steps)
			local za, zb = zFrom + (s - 1) * run, zFrom + s * run
			box(m, "WellStep", xr[1], xr[2], top - 1.2, top, math.min(za, zb), math.max(za, zb), Plate, STEEL)
			box(m, "StepNosing", xr[1], xr[2], top, top + 0.05, if run < 0 then zb else zb - 0.3, if run < 0 then zb + 0.3 else zb, Smooth, SAFETY_YELLOW)
		end
		local inner = if xr[1] < 0 then xr[2] - 0.2 else xr[1] + 0.2
		rod(m, "WellFlightRail", Vector3.new(inner, yFrom + 3.2, zFrom), Vector3.new(inner, yFrom - r + 3.2, zTo), 0.25, Metal, SAFETY_YELLOW)
	end
	box(m, "WellLanding", back[1], back[2], -1, 0, 6, WELL, Plate, STEEL)
	flight(back, 6, -6, 0)
	box(m, "WellLanding", -WELL, WELL, -r - 1, -r, -WELL, -6, Plate, STEEL)
	flight(front, -6, 6, -r)
	box(m, "WellLanding", -WELL, WELL, -2 * r - 1, -2 * r, 6, WELL, Plate, STEEL)
	flight(back, 6, -6, -2 * r)
	box(m, "WellLanding", -WELL, WELL, -3 * r - 1, -3 * r, -WELL, -6, Plate, STEEL)
	flight(front, -6, 6, -3 * r)

	for k = 0, 3 do
		local y = -k * r - 2
		lightStrip(m, CFrame.new(-WELL - 0.1, y + 6, 0), Vector3.new(0.3, 0.6, 6), Enum.NormalId.Right, 16, rng)
	end
end

-- ===== Assembly =====

-- `cell` is the maze cell's floor point in world space; `links` the world
-- positions of the maze cells whose tunnels arrive at it.
function Facility.build(parent, cell, links, rng)
	local wallFace = Config.TOTAL_LENGTH + Config.WING_THICKNESS
	local doorWorld = Vector3.new(wallFace, Config.COURTYARD_FLOOR, Config.COURTYARD_DOOR_Z)
	local flat = Vector3.new(doorWorld.X - cell.X, 0, doorWorld.Z - cell.Z)
	local L = CFrame.fromMatrix(cell, flat.Unit, Vector3.yAxis)

	-- The incline: from the foot of the well down to the bottom hall floor.
	local toDoor = flat.Magnitude
	local xEnd = toDoor - CONN
	local xFoot = xEnd - HALL_LEN
	local yTop = -WELL_DEPTH
	local yBot = Config.COURTYARD_FLOOR - cell.Y
	local run, rise = xFoot - HEAD_X, yTop - yBot
	local n = math.floor(rise + 0.5)
	local stepRise, stepRun = rise / n, run / n
	local tanT = rise / run
	local cosT = math.cos(math.atan(tanT))
	local function pitch(x)
		return yTop - (x - HEAD_X) * tanT
	end
	-- Vertical clearance over the steps: low at the top (the maze is just
	-- above), opening right up further down.
	local function clearance(x)
		return math.min(22 + 0.35 * (x - HEAD_X), 60)
	end
	-- The bottom hall starts where the incline's ceiling meets its height.
	local xH0 = xFoot - (HALL_H - 60) / tanT

	local m = model(parent, "Facility")

	-- ---- Terrain: hollow it all out first ----
	-- Everything here sits at an angle to the terrain's 4-stud voxel grid,
	-- and a carve only half-covering a voxel leaves that voxel part full,
	-- which smooth terrain draws as a blob of rock. So every carve is
	-- generous: a few studs wider than the walls, leaving the part-full
	-- voxels hidden behind them.
	local function carve(cf, size)
		terrain:FillBlock(L * cf, size, AIR)
	end
	carve(CFrame.new(0, VEST_H / 2 + 1, 0), Vector3.new(VEST * 2 + 8, VEST_H + 5, VEST * 2 + 8))
	carve(CFrame.new(0, -WELL_DEPTH / 2, 0), Vector3.new(WELL * 2 + 8, WELL_DEPTH + 6, WELL * 2 + 8))
	carve(CFrame.new((WELL + HEAD_X) / 2, yTop + 12, (WALL_Z0 + WALL_Z1) / 2), Vector3.new(HEAD_X - WELL + 8, 28, WALL_Z1 - WALL_Z0 + 10))
	local x = HEAD_X
	while x < xH0 + SEG do
		local x1 = x + SEG
		local V = clearance(x1)
		local A, B = Vector3.new(x - 1, pitch(x - 1), 4), Vector3.new(x1 + 1, pitch(x1 + 1), 4)
		local frame = CFrame.lookAt((A + B) / 2, B)
		carve(frame * CFrame.new(0, ((V + 5) / 2 - 3) * cosT, 0), Vector3.new(WALL_Z1 - WALL_Z0 + 10, (V + 5) * cosT, (B - A).Magnitude))
		x = x1
	end
	carve(CFrame.new((xH0 + xEnd) / 2, yBot + HALL_H / 2, (HALL_Z0 + HALL_Z1) / 2), Vector3.new(xEnd - xH0 + 6, HALL_H + 5, HALL_Z1 - HALL_Z0 + 6))
	-- The maze door is in the hall's -Z wall, into the maze's top row; the
	-- loading shutter in the +Z wall, with a dark pocket behind it.
	local mazeCol = math.floor((xH0 + 12 - MAZE.x0) / 16)
	local mazeDoorX = MAZE.x0 + mazeCol * 16 + 8
	local shutterX = xFoot + 30
	carve(CFrame.new(mazeDoorX, yBot + 6, (HALL_Z0 + MAZE.z0) / 2), Vector3.new(14, 13, 10))
	carve(CFrame.new(shutterX, yBot + 7, HALL_Z1 + 5), Vector3.new(16, 14, 10))
	task.wait()

	-- ---- Top: entrance room and well ----
	local doors = {}
	for _, p in ipairs(links) do
		local v = L:VectorToObjectSpace(Vector3.new(p.X - cell.X, 0, p.Z - cell.Z)).Unit
		local tx = if math.abs(v.X) > 1e-3 then VEST / math.abs(v.X) else math.huge
		local tz = if math.abs(v.Z) > 1e-3 then VEST / math.abs(v.Z) else math.huge
		local hit = v * math.min(tx, tz)
		if tx <= tz then
			table.insert(doors, { axis = "Z", fixed = math.sign(v.X) * VEST, along = math.clamp(hit.Z, -VEST + 6, VEST - 6), outward = math.sign(v.X) })
		else
			table.insert(doors, { axis = "X", fixed = math.sign(v.Z) * VEST, along = math.clamp(hit.X, -VEST + 6, VEST - 6), outward = math.sign(v.Z) })
		end
	end
	entrance(m, doors, rng)
	-- A flat, clear approach outside each blast door, joining the tunnel.
	for _, d in ipairs(doors) do
		local outward = if d.axis == "X" then Vector3.new(0, 0, d.outward) else Vector3.new(d.outward, 0, 0)
		local doorAt = if d.axis == "X" then Vector3.new(d.along, 0, d.fixed) else Vector3.new(d.fixed, 0, d.along)
		local a, b = doorAt + outward * 0.5, doorAt + outward * 20
		local floorCF = CFrame.lookAt((a + b) / 2 - Vector3.new(0, 2, 0), b - Vector3.new(0, 2, 0))
		terrain:FillBlock(L * floorCF, Vector3.new(10, 4, 19.5), Enum.Material.Rock)
		terrain:FillBlock(L * (floorCF + Vector3.new(0, 7, 0)), Vector3.new(14, 10, 19.5), AIR)
		RouteCheck.add("facility entrance approach", { L:PointToWorldSpace(doorAt - outward * 3), L:PointToWorldSpace(b) }, 3.5, 8)
	end
	well(m, rng)

	-- ---- The head of the incline ----
	local headCeil = yTop + clearance(HEAD_X)
	box(m, "HeadLanding", WELL, HEAD_X, yTop - 1, yTop, WALL_Z0, WALL_Z1, Plate, STEEL)
	box(m, "HeadCeiling", WELL - 0.5, HEAD_X, headCeil, headCeil + 1, WALL_Z0 - 1, WALL_Z1 + 1, Metal, DARK)
	wall(m, "HeadWall", "Z", WELL + 0.5, WALL_Z0 - 1, WALL_Z1 + 1, yTop - 1, headCeil, { { center = 0, width = WELL * 2, bottom = yTop, top = yTop + 18 } })
	for _, z in ipairs({ WALL_Z0 - 0.5, WALL_Z1 + 0.5 }) do
		box(m, "HeadSide", WELL, HEAD_X, yTop - 1, headCeil, z - 0.5, z + 0.5, Metal, WALL)
	end

	-- ---- The incline: walls, ceiling and ribs, segment by segment ----
	x = HEAD_X
	local ribCount = 0
	while x < xH0 - 0.01 do
		local x1 = math.min(x + SEG, xH0)
		local V, Vn = clearance(x), clearance(x1)
		local wallColor = jitter(WALL, rng, 0.06)
		for _, z in ipairs({ WALL_Z0 - 0.5, WALL_Z1 + 0.5 }) do
			box(m, "InclineWall", x, x1, pitch(x1) - 3, pitch(x) + V + 1, z - 0.5, z + 0.5, Metal, wallColor)
		end
		if rng:NextNumber() > 0.1 then
			slab(m, "InclineCeiling", Vector3.new(x, pitch(x) + V + 0.5, (WALL_Z0 + WALL_Z1) / 2), Vector3.new(x1, pitch(x1) + V + 0.5, (WALL_Z0 + WALL_Z1) / 2), WALL_Z1 - WALL_Z0 + 2, 1, Metal, jitter(DARK, rng, 0.08))
		end
		-- Rib across the hall at the lower end, covering the step up in
		-- the ceiling to the next segment.
		if x1 < xH0 - 0.01 then
			ribCount += 1
			local py = pitch(x1)
			local ribTop = py + math.max(V, Vn) + 0.8
			for _, z in ipairs({ WALL_Z0 + 0.6, WALL_Z1 - 0.6 }) do
				box(m, "Rib", x1 - 0.6, x1 + 0.6, py - 2, ribTop, z - 0.6, z + 0.6, Metal, DARK)
			end
			box(m, "RibBeam", x1 - 0.6, x1 + 0.6, py + V - 1.6, ribTop, WALL_Z0, WALL_Z1, Metal, DARK)
			lightStrip(m, CFrame.new(x1, py + V - 1.75, 0), Vector3.new(0.8, 0.3, 26), Enum.NormalId.Bottom, 32, rng)
			if ribCount % 3 == 0 then
				beacon(m, Vector3.new(x1 - 0.8, py + 10, WALL_Z0 + 1.4))
			end
			-- Pipe brackets.
			box(m, "PipeBracket", x1 - 0.2, x1 + 0.2, py + 13, py + 18.5, WALL_Z0 + 0.5, WALL_Z0 + 2.4, Metal, DARK)
		end
		x = x1
	end

	-- Pipes and a cable tray down the -Z wall, the whole way.
	for k = 0, 2 do
		local off = 14 + k * 1.6
		rod(m, "InclinePipe", Vector3.new(HEAD_X, pitch(HEAD_X) + off, WALL_Z0 + 1.2 + k * 0.3), Vector3.new(xH0, pitch(xH0) + off, WALL_Z0 + 1.2 + k * 0.3), 0.9 + k * 0.2, if k == 1 then Rust else Metal, if k == 1 then Color3.fromRGB(116, 76, 48) else STEEL)
	end
	slab(m, "CableTray", Vector3.new(HEAD_X, pitch(HEAD_X) + 11, WALL_Z0 + 1.4), Vector3.new(xH0, pitch(xH0) + 11, WALL_Z0 + 1.4), 1.6, 0.3, Metal, DARK)

	-- ---- The steps ----
	for i = 1, n do
		local xa, xb = HEAD_X + (i - 1) * stepRun, HEAD_X + i * stepRun
		local top = yTop - i * stepRise
		local bottom = if xa >= xH0 then yBot - 1 else top - 2.4
		local tread = box(m, "Step", xa, xb + 0.02, bottom, top, -STAIR_Z, STAIR_Z, Plate, jitter(STEEL, rng, 0.04))
		if rng:NextNumber() < 0.015 then
			tread.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(-3, 3)), 0, math.rad(rng:NextNumber(-2, 2)))
		end
		if rng:NextNumber() > 0.06 then
			box(m, "StepNosing", xb - 0.35, xb, top, top + 0.06, -STAIR_Z, STAIR_Z, Smooth, SAFETY_YELLOW)
		end
		-- Level numbers down the wall.
		if i % 30 == 0 then
			sign(m, CFrame.new((xa + xb) / 2, top + 7, WALL_Z0 + 0.1), Vector3.new(5, 2.6, 0.1), string.format("B%d", math.floor(i / 30)), Enum.NormalId.Back, DARK, SAFETY_YELLOW)
		end
	end
	local function treadTop(xp)
		local i = math.clamp(math.ceil((xp - HEAD_X) / stepRun), 1, n)
		return yTop - i * stepRise
	end
	-- Handrails: both edges and down the middle.
	for _, z in ipairs({ -STAIR_Z + 0.6, 0, STAIR_Z - 0.6 }) do
		rod(m, "Handrail", Vector3.new(HEAD_X, yTop + 3.2, z), Vector3.new(xFoot, yBot + 3.2, z), 0.3, Metal, SAFETY_YELLOW)
		for xp = HEAD_X + 2, xFoot - 1, 10 do
			rod(m, "HandrailPost", Vector3.new(xp, treadTop(xp), z), Vector3.new(xp, pitch(xp) + 3.2, z), 0.22, Metal, SAFETY_YELLOW)
		end
	end
	-- Warning signs at the head.
	sign(m, CFrame.new(HEAD_X + 16, pitch(HEAD_X + 16) + clearance(HEAD_X + 16) - 5, 0), Vector3.new(0.2, 3, 18), "中庭 ↓", Enum.NormalId.Left, DARK, LAMP_WHITE)
	sign(m, CFrame.new(HEAD_X + 0.5, yTop + 0.03, 0), Vector3.new(1.2, 0.05, 30), "足元注意", Enum.NormalId.Top, SAFETY_YELLOW, HAZARD_BLACK)

	-- ---- The inclined lift ----
	local bayMid = (BAY_Z0 + BAY_Z1) / 2
	slab(m, "LiftIncline", Vector3.new(HEAD_X, pitch(HEAD_X) - 0.9, bayMid), Vector3.new(xFoot, yBot - 0.9, bayMid), BAY_Z1 - BAY_Z0, 1, Concrete, Color3.fromRGB(96, 94, 90))
	for _, z in ipairs({ bayMid - 2, bayMid + 2 }) do
		rod(m, "LiftRail", Vector3.new(HEAD_X, yTop - 0.1, z), Vector3.new(xFoot, yBot - 0.1, z), 0.4, Metal, STEEL)
	end
	for xp = HEAD_X + 1, xFoot - 1, 6 do
		box(m, "Sleeper", xp - 0.4, xp + 0.4, pitch(xp) - 0.55, pitch(xp) - 0.25, BAY_Z0 + 0.8, BAY_Z1 - 0.8, Wood, Color3.fromRGB(80, 66, 52))
	end
	-- The car, come off its rails partway down, its cable snapped.
	local xc = HEAD_X + run * rng:NextNumber(0.35, 0.6)
	local carCF = CFrame.new(xc, pitch(xc) + 4.2, bayMid + rng:NextNumber(-0.6, 0.6)) * CFrame.Angles(math.rad(rng:NextNumber(-7, 7)), math.rad(rng:NextNumber(-5, 5)), -math.atan(tanT))
	local carColor = jitter(Color3.fromRGB(176, 170, 150), rng, 0.05)
	part(m, "LiftCar", Vector3.new(11, 7.5, 7), carCF, Metal, carColor)
	part(m, "LiftCarStripe", Vector3.new(11.1, 0.8, 7.1), carCF * CFrame.new(0, -1.5, 0), Smooth, SAFETY_YELLOW)
	for _, s in ipairs({ -1, 1 }) do
		local window = part(m, "LiftWindow", Vector3.new(8, 2.4, 0.1), carCF * CFrame.new(0, 1.4, s * 3.52), Enum.Material.Glass, Color3.fromRGB(40, 48, 50))
		window.Transparency = 0.35
	end
	local hitch = (carCF * CFrame.new(-5.6, 1.5, 0)).Position
	rod(m, "LiftCable", hitch, Vector3.new(xc - 26, pitch(xc - 26) + 0.4, bayMid), 0.3, Metal, Color3.fromRGB(50, 50, 48))

	-- ---- Damage down the incline ----
	for _ = 1, 7 do
		local xp = rng:NextNumber(HEAD_X + 20, xH0 - 10)
		local top = treadTop(xp)
		part(m, "FallenCeilingPanel", Vector3.new(rng:NextNumber(6, 12), 0.8, rng:NextNumber(6, 12)), CFrame.new(xp, top + 1.2, rng:NextNumber(-12, 12)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), -math.atan(tanT) + rng:NextNumber(-0.25, 0.25)), Metal, jitter(DARK, rng, 0.1))
	end
	for _ = 1, 8 do
		local xp = rng:NextNumber(HEAD_X + 8, xFoot - 4)
		part(m, "Crate", Vector3.new(3, 3, 3), CFrame.new(xp, treadTop(xp) + 1.5, rng:NextNumber(-15, 15)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4)), Metal, jitter(Color3.fromRGB(70, 90, 70), rng, 0.1))
	end
	for _ = 1, 10 do
		local xp = rng:NextNumber(HEAD_X, xH0 - 12)
		local streak = box(m, "WaterStreak", xp, xp + rng:NextNumber(1.5, 4), pitch(xp) - 2, pitch(xp) + clearance(xp) - 1, WALL_Z1 - 0.1, WALL_Z1 + 0.05, Smooth, Color3.fromRGB(46, 50, 50))
		streak.Transparency = 0.4
		streak.CanCollide = false
	end

	-- ---- The bottom hall ----
	local floorY, ceilY = yBot, yBot + HALL_H
	box(m, "HallFloor", xH0, xEnd, floorY - 1, floorY, HALL_Z0, HALL_Z1, Concrete, Color3.fromRGB(92, 92, 90))
	box(m, "HallCeiling", xH0, xEnd, ceilY, ceilY + 1, HALL_Z0, HALL_Z1, Metal, DARK)
	wall(m, "HallWall", "Z", xH0, HALL_Z0, HALL_Z1, floorY, ceilY, { { center = (WALL_Z0 + WALL_Z1) / 2, width = WALL_Z1 - WALL_Z0 + 1, bottom = pitch(xH0) - 2.4, top = ceilY } })
	wall(m, "HallWall", "Z", xEnd, HALL_Z0, HALL_Z1, floorY, ceilY, { { center = VAULT_Z, width = 14, bottom = floorY, top = floorY + 15 } })
	wall(m, "HallWall", "X", HALL_Z0, xH0, xEnd, floorY, ceilY, { { center = mazeDoorX, width = 6, bottom = floorY, top = floorY + 8 } })
	wall(m, "HallWall", "X", HALL_Z1, xH0, xEnd, floorY, ceilY, { { center = shutterX, width = 12, bottom = floorY, top = floorY + 12 } })

	-- Short passage from the maze door to the maze's first cell.
	box(m, "MazeDoorFloor", mazeDoorX - 3, mazeDoorX + 3, floorY - 1, floorY, MAZE.z0, HALL_Z0, Plate, STEEL)
	box(m, "MazeDoorCeiling", mazeDoorX - 3.8, mazeDoorX + 3.8, floorY + 8, floorY + 9, MAZE.z0, HALL_Z0, Metal, DARK)
	for _, s in ipairs({ -1, 1 }) do
		box(m, "MazeDoorWall", mazeDoorX + s * 3.4 - 0.4, mazeDoorX + s * 3.4 + 0.4, floorY, floorY + 8, MAZE.z0, HALL_Z0, Metal, WALL)
	end
	sign(m, CFrame.new(mazeDoorX, floorY + 9.2, HALL_Z0 + 0.6), Vector3.new(4, 1.4, 0.12), "非常口", Enum.NormalId.Back, Color3.fromRGB(40, 140, 70), Color3.fromRGB(236, 250, 236))

	-- The loading shutter, jammed just off the floor: too low to get under.
	for k = 0, 12 do
		local slat = box(m, "ShutterSlat", shutterX - 6, shutterX + 6, floorY + 1.2 + k * 0.86, floorY + 2 + k * 0.86, HALL_Z1 - 0.3, HALL_Z1 + 0.1, Metal, jitter(Color3.fromRGB(120, 122, 116), rng, 0.04))
		if k < 3 and rng:NextNumber() < 0.5 then
			slat.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, 0)
		end
	end
	box(m, "ShutterBox", shutterX - 6.5, shutterX + 6.5, floorY + 12, floorY + 13.5, HALL_Z1 - 1.2, HALL_Z1, Metal, DARK)
	for k = 0, 9 do
		box(m, "HazardStripe", shutterX - 6.5 + k * 1.3, shutterX - 5.2 + k * 1.3, floorY + 13.5, floorY + 14.3, HALL_Z1 - 0.6, HALL_Z1 - 0.5, Smooth, if k % 2 == 0 then SAFETY_YELLOW else HAZARD_BLACK)
	end
	sign(m, CFrame.new(shutterX, floorY + 16, HALL_Z1 - 0.6), Vector3.new(6, 1.8, 0.12), "搬入口", Enum.NormalId.Front, DARK, SAFETY_YELLOW)
	-- The lift incline's end, and its buffer stop.
	box(m, "LiftBuffer", xFoot - 1, xFoot + 1, floorY, floorY + 3, BAY_Z0 + 1, BAY_Z1 - 1, Metal, SAFETY_YELLOW)
	box(m, "LiftPlinth", xH0, xFoot, floorY, floorY + 0.1, BAY_Z0, BAY_Z1, Concrete, Color3.fromRGB(96, 94, 90))

	-- Hanging lamps.
	for _, lx in ipairs({ xFoot - 6, xFoot + 12, xFoot + 30 }) do
		for _, lz in ipairs({ -12, 16 }) do
			local at = Vector3.new(lx, ceilY - 14, lz)
			rod(m, "LampHanger", at, Vector3.new(lx, ceilY, lz), 0.2, Metal, STEEL)
			cylinder(m, "LampShade", 1.6, 3.6, CFrame.new(at) * UPRIGHT, Metal, DARK)
			local lit = rng:NextNumber() > 0.25
			local lens = part(m, "LampLens", Vector3.new(0.2, 3, 3), CFrame.new(at - Vector3.new(0, 0.9, 0)) * UPRIGHT, if lit then Neon else Smooth, if lit then LAMP_WHITE else Color3.fromRGB(90, 90, 88))
			lens.Shape = Enum.PartType.Cylinder
			lens.CanCollide = false
			if lit then
				local light = Instance.new("SpotLight")
				light.Face = Enum.NormalId.Left
				light.Angle = 120
				light.Range = 60
				light.Brightness = 1.4
				light.Color = Color3.fromRGB(236, 240, 226)
				light.Parent = lens
				if rng:NextNumber() < 0.3 then
					lens:AddTag("FlickerLight")
				end
			end
		end
	end

	-- Walkway lines from the foot of the steps to the way out.
	for _, z in ipairs({ -4.5, 4.5 }) do
		box(m, "FloorLine", xFoot + 1, xEnd - 1, floorY, floorY + 0.04, z - 0.3, z + 0.3, Smooth, SAFETY_YELLOW)
	end
	for k = 0, 17 do
		box(m, "HazardFloor", xFoot + 0.2, xFoot + 1.4, floorY, floorY + 0.05, -STAIR_Z + k * 2, -STAIR_Z + k * 2 + 1, Smooth, SAFETY_YELLOW)
	end

	-- Checkpoint: a row of turnstiles and a glass booth.
	local tx = xFoot + 16
	for k = -2, 1 do
		local z = k * 4 + 2
		box(m, "Turnstile", tx - 1, tx + 1, floorY, floorY + 3.2, z - 0.6, z + 0.6, Metal, STEEL)
		if rng:NextNumber() < 0.7 then
			rod(m, "TurnstileArm", Vector3.new(tx, floorY + 2.8, z + 0.6), Vector3.new(tx + rng:NextNumber(-0.5, 0.5), floorY + 2.8 - rng:NextNumber(0, 1.5), z + 3), 0.18, Metal, Color3.fromRGB(180, 180, 176))
		end
	end
	local bz0, bz1 = 12, 22
	for _, c in ipairs({ { tx - 4, bz0 }, { tx + 4, bz0 }, { tx - 4, bz1 }, { tx + 4, bz1 } }) do
		box(m, "BoothPost", c[1] - 0.25, c[1] + 0.25, floorY, floorY + 8, c[2] - 0.25, c[2] + 0.25, Metal, DARK)
	end
	box(m, "BoothRoof", tx - 4.3, tx + 4.3, floorY + 8, floorY + 8.5, bz0 - 0.3, bz1 + 0.3, Metal, DARK)
	for _, g in ipairs({ { tx - 4, tx + 4, bz0, bz0 }, { tx - 4, tx - 4, bz0, bz1 }, { tx + 4, tx + 4, bz0, bz1 } }) do
		if rng:NextNumber() > 0.3 then
			local glass = box(m, "BoothGlass", g[1] - 0.05, g[2] + 0.05, floorY + 3, floorY + 8, g[3] - 0.05, g[4] + 0.05, Enum.Material.Glass, Color3.fromRGB(150, 170, 170))
			glass.Transparency = 0.6
		end
	end
	box(m, "BoothDesk", tx - 3.5, tx + 3.5, floorY, floorY + 3.3, bz0 + 0.4, bz0 + 2.4, Metal, Color3.fromRGB(120, 122, 118))
	local screen = part(m, "BoothScreen", Vector3.new(1.6, 1.3, 0.05), Vector3.new(tx, floorY + 4.1, bz0 + 1.4), Neon, Color3.fromRGB(60, 150, 80))
	screen.Transparency = 0.3
	local chair = Props.studentChair(m, Vector3.new(tx + 1, floorY, bz0 + 4.5), Color3.fromRGB(70, 70, 72))
	if rng:NextNumber() < 0.5 then
		Props.tipChair(chair, Vector3.new(tx + 1, floorY, bz0 + 4.5), rng:NextNumber(0, math.pi * 2))
	end

	-- Lockers and benches along the walls.
	for k = 0, 9 do
		local lx = xFoot + 2 + k * 1.3
		local locker = box(m, "Locker", lx, lx + 1.25, floorY, floorY + 7, HALL_Z1 - 2, HALL_Z1 - 0.5, Metal, jitter(Color3.fromRGB(90, 110, 100), rng, 0.08))
		if rng:NextNumber() < 0.15 then
			locker.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, 0)
		end
	end
	for k = 0, 1 do
		local bx = xFoot + 6 + k * 9
		box(m, "Bench", bx, bx + 6, floorY + 1.6, floorY + 2, HALL_Z0 + 1, HALL_Z0 + 2.6, Wood, Color3.fromRGB(110, 84, 58))
		for _, e in ipairs({ bx + 0.5, bx + 5.5 }) do
			box(m, "BenchLeg", e - 0.2, e + 0.2, floorY, floorY + 1.6, HALL_Z0 + 1.2, HALL_Z0 + 2.4, Metal, DARK)
		end
	end
	-- Pallets and crates in the space beside the steps.
	for _ = 1, rng:NextInteger(5, 9) do
		local cx, cz = rng:NextNumber(xH0 + 2, xFoot + 4), rng:NextNumber(HALL_Z0 + 2, -STAIR_Z - 2)
		local s = rng:NextNumber(2.5, 4)
		if math.abs(cx - mazeDoorX) < 6 then
			continue
		end
		part(m, "Crate", Vector3.new(s, s, s), CFrame.new(cx, floorY + s / 2, cz) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), Metal, jitter(Color3.fromRGB(70, 90, 70), rng, 0.1))
	end

	-- The vault door on the end wall, facing the steps. Hold E to open it:
	-- VaultController spins the handwheel, draws the bolts and swings it
	-- out on its hinge. Behind it, the shaft down to the hidden sea.
	local vz, vy, vr = VAULT_Z, floorY + 10, VAULT_R
	local face = xEnd - 0.5
	for k = 0, 19 do
		local a = (k + 0.5) / 20 * math.pi * 2
		local radial = Vector3.new(0, math.sin(a), math.cos(a))
		part(m, "VaultRing", Vector3.new(1.2, 2.2, 3.3), CFrame.fromMatrix(Vector3.new(face - 0.6, vy, vz) + radial * (vr + 1.1), Vector3.xAxis, radial), Metal, SAFETY_YELLOW)
	end
	local door = model(m, "VaultDoor")
	local doorColor = Color3.fromRGB(120, 122, 118)
	local disc = cylinder(door, "Door", 1.8, vr * 2, CFrame.new(face - 1.4, vy, vz), Metal, doorColor)
	cylinder(door, "DoorPanel", 0.3, vr * 2 - 4, CFrame.new(face - 2.4, vy, vz), Metal, Color3.fromRGB(104, 106, 102))
	cylinder(door, "Hub", 1.4, 4.4, CFrame.new(face - 3, vy, vz), Metal, DARK)
	local wheel = model(door, "Wheel")
	for k = 0, 2 do
		part(wheel, "WheelPart", Vector3.new(0.35, 7.6, 0.45), CFrame.new(face - 3.9, vy, vz) * CFrame.Angles(k * math.pi / 3, 0, 0), Metal, Color3.fromRGB(170, 40, 34))
	end
	for k = 0, 15 do
		local a = (k + 0.5) / 16 * math.pi * 2
		local radial = Vector3.new(0, math.sin(a), math.cos(a))
		part(wheel, "WheelPart", Vector3.new(0.4, 0.45, 1.6), CFrame.fromMatrix(Vector3.new(face - 3.9, vy, vz) + radial * 3.7, Vector3.xAxis, radial), Metal, Color3.fromRGB(170, 40, 34))
	end
	for k = 0, 11 do
		local a = (k + 0.5) / 12 * math.pi * 2
		local radial = Vector3.new(0, math.sin(a), math.cos(a))
		cylinder(door, "Bolt", 2.4, 0.9, CFrame.fromMatrix(Vector3.new(face - 1.4, vy, vz) + radial * (vr - 0.3), radial, Vector3.xAxis), Metal, STEEL)
	end
	-- Hinged on the -z side, so it swings open away from the loading
	-- shutter on the hall's +z wall.
	local hinge = part(door, "Hinge", Vector3.new(1.8, 14, 1.8), Vector3.new(face - 1.4, vy, vz - vr - 0.6), Metal, DARK)
	for _, dy in ipairs({ -4.5, 4.5 }) do
		part(door, "HingeArm", Vector3.new(1.2, 1.6, 3), Vector3.new(face - 1.4, vy + dy, vz - vr + 1), Metal, DARK)
		box(m, "HingeKnuckle", face - 2.4, face, vy + dy + 1, vy + dy + 2.4, vz - vr - 1.6, vz - vr + 0.2, Metal, DARK)
	end
	door.PrimaryPart = hinge
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Vault door"
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = disc
	door:AddTag("VaultDoor")
	sign(m, CFrame.new(face - 0.1, floorY + 24.5, vz), Vector3.new(0.1, 2.4, 10), "第四区画 — 封鎖", Enum.NormalId.Left, Color3.fromRGB(200, 40, 34), Color3.fromRGB(240, 236, 226))
	beacon(m, Vector3.new(xEnd - 1, floorY + 20, vz + 13))
	-- Behind the door: a short throat to the shaft, and the landing at the
	-- shaft's top (the shaft itself is HiddenSea's).
	box(m, "VaultThreshold", face, xEnd + 7.5, floorY - 1, floorY, vz - 7.5, vz + 7.5, Plate, STEEL)
	for _, s in ipairs({ -1, 1 }) do
		box(m, "VaultThroat", xEnd + 0.5, xEnd + 4.8, floorY, floorY + 15, vz + s * 7 - 0.5, vz + s * 7 + 0.5, Metal, WALL)
	end
	box(m, "VaultThroat", xEnd + 0.5, xEnd + 4.8, floorY + 15, floorY + 16, vz - 7.5, vz + 7.5, Metal, DARK)

	-- The maze, and its fire exit.
	local fireEnd = FacilityMaze.build(m, {
		L = L,
		floorY = yBot,
		x0 = MAZE.x0,
		z0 = MAZE.z0,
		cols = MAZE.cols,
		rows = MAZE.rows,
		entranceCol = mazeCol,
		fireX = MAZE.fireX,
		exitMinZ = MAZE.exitMinZ,
	}, rng)
	for _ = 1, 3 do
		local d = rng:NextNumber(3, 7)
		local puddle = BuildUtil.disc(m, "Puddle", d, 0.04, Vector3.new(rng:NextNumber(xFoot + 4, xEnd - 4), floorY + 0.03, rng:NextNumber(HALL_Z0 + 4, HALL_Z1 - 4)), Smooth, Color3.fromRGB(40, 46, 48))
		puddle.Transparency = 0.15
		puddle.Reflectance = 0.4
		puddle.CanCollide = false
	end

	m.WorldPivot = CFrame.identity
	m:PivotTo(L)
	door:SetAttribute("Outward", L:VectorToWorldSpace(Vector3.new(-1, 0, 0)))
	task.wait()

	-- Behind the vault: the hidden sea.
	HiddenSea.build(parent, L:PointToWorldSpace(Vector3.new(xEnd + 7.5, yBot, VAULT_Z)), L:VectorToWorldSpace(Vector3.new(-1, 0, 0)), rng)
	task.wait()

	-- ---- Out to the courtyard door (world space) ----
	local out = model(parent, "FacilityPassage")
	local floorW = Config.COURTYARD_FLOOR
	local doorZ = Config.COURTYARD_DOOR_Z
	local stubEnd = Vector3.new(wallFace + 10, floorW, doorZ)
	local hallExit = L:PointToWorldSpace(fireEnd)
	terrain:FillBlock(CFrame.new(wallFace + 6, floorW + 6.5, doorZ), Vector3.new(16, 16, 16), AIR)
	local frame = CFrame.lookAt((stubEnd + hallExit) / 2, hallExit)
	local len = (hallExit - stubEnd).Magnitude
	terrain:FillBlock(frame * CFrame.new(0, 6.5, 0), Vector3.new(18, 16, len + 10), AIR)

	local function tube(cf, length)
		part(out, "PassageFloor", Vector3.new(8, 1, length), cf * CFrame.new(0, -0.5, 0), Plate, STEEL)
		part(out, "PassageCeiling", Vector3.new(10, 1, length), cf * CFrame.new(0, 10.5, 0), Metal, DARK)
		for _, s in ipairs({ -1, 1 }) do
			part(out, "PassageWall", Vector3.new(1, 10, length), cf * CFrame.new(s * 4.5, 5, 0), Metal, WALL)
		end
		lightStrip(out, cf * CFrame.new(0, 9.85, 0), Vector3.new(0.8, 0.3, math.min(6, length * 0.6)), Enum.NormalId.Bottom, 16, rng)
	end
	tube(CFrame.lookAt(Vector3.new(wallFace + 5, floorW, doorZ), stubEnd), 10.5)
	tube(frame, len + 3)
	RouteCheck.add("courtyard door and passage", { Vector3.new(Config.TOTAL_LENGTH - 2, floorW, doorZ), Vector3.new(wallFace + 5, floorW, doorZ), stubEnd, hallExit }, 3, 9, true)
	RouteCheck.add("facility incline", { L:PointToWorldSpace(Vector3.new(0, yTop, 0)), L:PointToWorldSpace(Vector3.new(HEAD_X, yTop, 0)), L:PointToWorldSpace(Vector3.new(xFoot, yBot, 0)), L:PointToWorldSpace(Vector3.new(xEnd - 2, yBot, 0)) }, 12, 14)
end

return Facility
