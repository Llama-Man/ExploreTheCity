-- Lays out the school: a stack of floors, each one long corridor running +X
-- with sash windows on the right and a row of rooms on the left, joined by
-- stairwells at both ends. Each room has a front and back sliding-door
-- opening off the corridor, a transom window between them, and big
-- curtained windows on its outer wall.
--
-- Rooms are mostly classrooms with special rooms mixed in (each special
-- style at most once or twice). Every room gets its own "mess" level around
-- SchoolConfig.DISUSE, so some rooms are far more neglected than others.
-- Room wood tone drifts gradually from one room to the next.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Architecture = require(script.Parent.Architecture)
local Courtyard = require(script.Parent.Courtyard)
local Megastructure = require(script.Parent.Megastructure)
local Rooftop = require(script.Parent.Rooftop)
local Stairwell = require(script.Parent.Stairwell)
local StairAnnex = require(script.Parent.StairAnnex)
local DepartmentStore = require(script.Parent.DepartmentStore)
local PowerLines = require(script.Parent.PowerLines)
local Kannon = require(script.Parent.Kannon)
local Ship = require(script.Parent.Ship)
local ChainOfShips = require(script.Parent.ChainOfShips)
local Port = require(script.Parent.Port)
local WestCrossing = require(script.Parent.WestCrossing)
local RouteCheck = require(script.Parent.RouteCheck)
local Underground = require(script.Parent.Underground)
local Gym = require(script.Parent.Gym)
local Furnishings = require(script.Parent.Furnishings)
local Props = require(script.Parent.Props)
local Weathering = require(script.Parent.Weathering)

local darken = BuildUtil.darken

local N, CW = Config.NUM_CLASSROOMS, Config.CLASSROOM_WIDTH
local H, T = Config.WALL_HEIGHT, Config.WALL_THICKNESS
local DOOR_W, DOOR_H = Config.DOOR_WIDTH, Config.DOOR_HEIGHT
local SILL, WINDOW_TOP = Config.SILL_HEIGHT, Config.WINDOW_TOP
local TOTAL = Config.TOTAL_LENGTH
local ZC_MIN, ZC_MAX, Z_FAR = Config.CORRIDOR_Z_MIN, Config.CORRIDOR_Z_MAX, Config.CLASSROOM_Z_FAR
local DISUSE = Config.DISUSE
local CORRIDOR_WOOD = Weathering.dusty(Config.CORRIDOR_WOOD, DISUSE)
local CORRIDOR_TRIM = darken(CORRIDOR_WOOD, 0.7)

local ROOM_KINDS = {
	{ kind = "classroom", weight = 4, max = math.huge },
	{ kind = "cleared", weight = 1, max = 2 },
	{ kind = "storage", weight = 1, max = 2 },
	{ kind = "lounge", weight = 0.8, max = 1 },
	{ kind = "music", weight = 0.8, max = 1 },
	{ kind = "science", weight = 0.8, max = 1 },
	{ kind = "art", weight = 0.8, max = 1 },
	{ kind = "library", weight = 0.6, max = 1 },
	{ kind = "infirmary", weight = 0.6, max = 1 },
}
local ROOM_LABELS = {
	cleared = "空き教室",
	storage = "準備室",
	lounge = "談話室",
	music = "音楽室",
	science = "理科室",
	art = "美術室",
	library = "図書室",
	infirmary = "保健室",
}

local SchoolGenerator = {}

-- Weighted pick that respects each kind's max count and never puts the
-- same special room type next to itself.
local function pickRoomKind(rng, used, previous)
	local options, total = {}, 0
	for _, entry in ipairs(ROOM_KINDS) do
		local allowed = (used[entry.kind] or 0) < entry.max and (entry.kind == "classroom" or entry.kind ~= previous)
		if allowed then
			table.insert(options, entry)
			total += entry.weight
		end
	end
	local roll = rng:NextNumber() * total
	for _, entry in ipairs(options) do
		roll -= entry.weight
		if roll <= 0 then
			return entry.kind
		end
	end
	return "classroom"
end

-- Random walk in lightness/warmth around WOOD_BASE, so neighbouring rooms
-- are always close in tone. Dust pulls it slightly toward grey.
local function nextWoodTone(state, rng)
	local lr, wr = Config.WOOD_LIGHTNESS_RANGE, Config.WOOD_WARMTH_RANGE
	state.lightness = math.clamp(state.lightness + rng:NextNumber(-Config.WOOD_LIGHTNESS_STEP, Config.WOOD_LIGHTNESS_STEP), lr[1], lr[2])
	state.warmth = math.clamp(state.warmth + rng:NextNumber(-Config.WOOD_WARMTH_STEP, Config.WOOD_WARMTH_STEP), wr[1], wr[2])
	local base, l, w = Config.WOOD_BASE, state.lightness, state.warmth
	local color = Color3.new(math.clamp(base.R * l * (1 + w), 0, 1), math.clamp(base.G * l, 0, 1), math.clamp(base.B * l * (1 - w), 0, 1))
	return Weathering.dusty(color, DISUSE)
end

-- nil = empty doorway; otherwise the door's starting open fraction
-- (0 closed, 1 open, in between = left ajar).
local function rollDoor(rng)
	local roll = rng:NextNumber()
	if roll < 0.35 then
		return nil
	elseif roll < 0.6 then
		return 1
	elseif roll < 0.75 then
		return rng:NextNumber(0.2, 0.6)
	end
	return 0
end

local function rollLight(rng, mess)
	local roll = rng:NextNumber()
	if roll < 0.06 + mess * 0.18 then
		return "dead"
	elseif roll < 0.1 + mess * 0.26 then
		return "flicker"
	end
	return "on"
end

local function buildRoom(folders, index, kind, label, wood, rng)
	local xStart, xEnd = (index - 1) * CW, index * CW
	local trim = darken(wood, 0.62)
	local corridorTrim = CORRIDOR_TRIM
	local bounds = { x0 = xStart + T / 2, x1 = xEnd - T / 2, z0 = Z_FAR + T / 2, z1 = ZC_MIN - T / 2 }
	local mess = math.clamp(DISUSE * rng:NextNumber(0.5, 1.5), 0, 1)

	local roomFolder = Instance.new("Folder")
	roomFolder.Name = string.format("Room%02d_%s", index, kind)
	roomFolder.Parent = folders.Rooms

	Architecture.floorboards(roomFolder, bounds.x0, bounds.x1, bounds.z0, bounds.z1, wood, rng, mess * 0.03)
	Architecture.ceiling(roomFolder, xStart, xEnd, Z_FAR, ZC_MIN, 3, trim)

	-- Corridor-side wall: back door, front door (board end), transom between.
	local backDoor = xStart + Config.DOOR_INSET + DOOR_W / 2
	local frontDoor = xEnd - Config.DOOR_INSET - DOOR_W / 2
	local transomCenter = (backDoor + frontDoor) / 2
	local transomWidth = frontDoor - backDoor - DOOR_W - 3

	local doorOpenings = {
		{ center = backDoor, width = DOOR_W, bottom = 0, top = DOOR_H },
		{ center = frontDoor, width = DOOR_W, bottom = 0, top = DOOR_H },
	}
	local corridorWallOpenings = table.clone(doorOpenings)
	table.insert(corridorWallOpenings, { center = transomCenter, width = transomWidth, bottom = Config.TRANSOM_BOTTOM, top = Config.TRANSOM_TOP })

	Architecture.wall(folders.Structure, "X", ZC_MIN, xStart, xEnd, corridorWallOpenings)
	Architecture.sashWindow(folders.Structure, "X", ZC_MIN, transomCenter, transomWidth, Config.TRANSOM_BOTTOM, Config.TRANSOM_TOP, trim, rng, { rows = 0, sill = false })
	Architecture.wainscot(folders.Corridor, "X", ZC_MIN + T / 2, 1, xStart, xEnd, doorOpenings, CORRIDOR_WOOD, 3.5)
	Architecture.wainscot(roomFolder, "X", ZC_MIN - T / 2, -1, bounds.x0, bounds.x1, doorOpenings, wood)
	Weathering.wallWear(folders.Corridor, "X", ZC_MIN + T / 2, 1, xStart, xEnd, corridorWallOpenings, rng, DISUSE * 0.8)
	Weathering.wallWear(roomFolder, "X", ZC_MIN - T / 2, -1, bounds.x0, bounds.x1, corridorWallOpenings, rng, mess)

	for _, door in ipairs({ { center = backDoor, slide = 1 }, { center = frontDoor, slide = -1 } }) do
		Architecture.doorCasing(folders.Structure, "X", ZC_MIN, door.center, DOOR_W, DOOR_H, corridorTrim)
		Architecture.threshold(folders.Structure, "X", ZC_MIN, door.center, DOOR_W, corridorTrim)
		local openFraction = rollDoor(rng)
		if openFraction then
			Architecture.slidingDoor(folders.Structure, "X", ZC_MIN + T / 2 + 0.45, door.center, door.slide, openFraction, corridorTrim, wood)
		end
	end
	local signTilt = if rng:NextNumber() < DISUSE * 0.4 then math.rad(rng:NextNumber(-12, 12)) else 0
	Architecture.classSign(folders.Corridor, frontDoor, ZC_MIN + T / 2, label, signTilt)
	Furnishings.dressCorridorWall(folders.Corridor, backDoor + DOOR_W / 2 + 1, frontDoor - DOOR_W / 2 - 1, ZC_MIN + T / 2, rng)

	-- Outer wall with two big windows.
	local windows = {
		{ center = xStart + CW * 0.3, width = CW * 0.34, z = bounds.z0, inward = 1 },
		{ center = xStart + CW * 0.7, width = CW * 0.34, z = bounds.z0, inward = 1 },
	}
	local farOpenings = {}
	for _, w in ipairs(windows) do
		table.insert(farOpenings, { center = w.center, width = w.width, bottom = SILL, top = WINDOW_TOP })
	end
	Architecture.wall(folders.Structure, "X", Z_FAR, xStart, xEnd, farOpenings)
	for _, w in ipairs(windows) do
		Architecture.sashWindow(folders.Structure, "X", Z_FAR, w.center, w.width, SILL, WINDOW_TOP, trim, rng, { broken = mess * 0.08 })
	end
	Architecture.wainscot(roomFolder, "X", Z_FAR + T / 2, 1, bounds.x0, bounds.x1, {}, wood)
	Weathering.wallWear(roomFolder, "X", Z_FAR + T / 2, 1, bounds.x0, bounds.x1, farOpenings, rng, mess)

	-- Interior faces of the divider walls (the walls themselves are shared
	-- between neighbours and built once in generate).
	Architecture.wainscot(roomFolder, "Z", xStart + T / 2, 1, bounds.z0, bounds.z1, {}, wood)
	Architecture.wainscot(roomFolder, "Z", xEnd - T / 2, -1, bounds.z0, bounds.z1, {}, wood)
	Weathering.wallWear(roomFolder, "Z", xStart + T / 2, 1, bounds.z0, bounds.z1, {}, rng, mess)
	Weathering.wallWear(roomFolder, "Z", xEnd - T / 2, -1, bounds.z0, bounds.z1, {}, rng, mess)

	-- Lights sit between the ceiling beams (beams are at the thirds).
	for _, fx in ipairs({ 1 / 6, 1 / 2, 5 / 6 }) do
		for _, fz in ipairs({ 1 / 3, 2 / 3 }) do
			Architecture.ceilingLight(roomFolder, Vector3.new(xStart + CW * fx, H - 0.3, Z_FAR + (ZC_MIN - Z_FAR) * fz), rollLight(rng, mess))
		end
	end

	Furnishings.populateRoom(roomFolder, { kind = kind, bounds = bounds, wood = wood, trim = trim, windows = windows, mess = mess }, rng)
end

local function buildCorridor(folders, rng)
	local wood, trim = CORRIDOR_WOOD, CORRIDOR_TRIM
	local mess = DISUSE * 0.8
	local bounds = { x0 = T / 2, x1 = TOTAL - T / 2, z0 = ZC_MIN + T / 2, z1 = ZC_MAX - T / 2 }

	Architecture.floorboards(folders.Corridor, bounds.x0, bounds.x1, bounds.z0, bounds.z1, wood, rng, mess * 0.015)
	Architecture.ceiling(folders.Corridor, 0, TOTAL, ZC_MIN, ZC_MAX, N * 2, trim)

	-- Window wall: timber posts every half-room, a window between each pair.
	local openings, windows = {}, {}
	for k = 0, N * 2 - 1 do
		local s, e = k * CW / 2 + 0.6, (k + 1) * CW / 2 - 0.6
		table.insert(openings, { center = (s + e) / 2, width = e - s, bottom = SILL, top = WINDOW_TOP })
		table.insert(windows, { center = (s + e) / 2, width = e - s, z = bounds.z1, inward = -1 })
	end
	Architecture.wall(folders.Structure, "X", ZC_MAX, 0, TOTAL, openings)
	for _, o in ipairs(openings) do
		Architecture.sashWindow(folders.Structure, "X", ZC_MAX, o.center, o.width, o.bottom, o.top, trim, rng, { broken = mess * 0.05 })
	end
	for k = 0, N * 2 do
		Architecture.post(folders.Structure, "X", ZC_MAX, k * CW / 2, trim)
	end
	Architecture.wainscot(folders.Corridor, "X", ZC_MAX - T / 2, -1, 0, TOTAL, {}, wood, 3.5)
	Weathering.wallWear(folders.Corridor, "X", ZC_MAX - T / 2, -1, 0, TOTAL, openings, rng, mess)

	for k = 0, N * 2 - 1 do
		Architecture.ceilingLight(folders.Corridor, Vector3.new(CW / 4 + k * CW / 2, H - 0.3, 0), rollLight(rng, mess))
		if rng:NextNumber() < 0.2 then
			local plantPos = Vector3.new(k * CW / 2 + rng:NextNumber(3, CW / 2 - 3), 0, bounds.z1 - 1.3)
			Props.pottedPlant(folders.Corridor, plantPos, rng, rng:NextNumber() < mess)
		end
	end

	-- Doorways at both ends onto the stairwell landings.
	local doorway = { { center = 0, width = 9, bottom = 0, top = DOOR_H + 0.5 } }
	for _, e in ipairs({ { x = 0, dir = -1 }, { x = TOTAL, dir = 1 } }) do
		Architecture.wall(folders.Structure, "Z", e.x, ZC_MIN, ZC_MAX, doorway)
		Architecture.doorCasing(folders.Structure, "Z", e.x, 0, 9, DOOR_H + 0.5, trim)
		Architecture.threshold(folders.Structure, "Z", e.x, 0, 9, trim)
		Architecture.wainscot(folders.Corridor, "Z", e.x - e.dir * T / 2, -e.dir, bounds.z0, bounds.z1, doorway, wood)
	end

	Weathering.floor(folders.Corridor, bounds, rng, mess, windows)
	Weathering.cobwebs(folders.Corridor, bounds, rng, mess)
end

-- One complete floor (corridor, rooms, structure), built at y = 0 inside a
-- model that's then lifted to its height. Classrooms are numbered by floor
-- (the 4th floor's are 4-1, 4-2, ...).
local function buildFloor(root, f, woodState, rng)
	local floorModel = Instance.new("Model")
	floorModel.Name = string.format("Floor%d", f)
	floorModel.Parent = root

	local folders = {}
	for _, name in ipairs({ "Structure", "Corridor", "Rooms" }) do
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = floorModel
		folders[name] = folder
	end

	Architecture.floorShell(folders.Structure, -T / 2, TOTAL + T / 2, Z_FAR - T / 2, ZC_MAX + T / 2, f == 1, f == Config.FLOORS)
	buildCorridor(folders, rng)

	-- Divider walls between rooms, with exposed posts where they meet the
	-- corridor and outer walls.
	for i = 0, N do
		Architecture.wall(folders.Structure, "Z", i * CW, Z_FAR, ZC_MIN, {})
		Architecture.post(folders.Structure, "X", ZC_MIN, i * CW, CORRIDOR_TRIM)
		Architecture.post(folders.Structure, "X", Z_FAR, i * CW, CORRIDOR_TRIM)
	end

	local used, previous = {}, nil
	local classNumber = 0
	for i = 1, N do
		local kind = pickRoomKind(rng, used, previous)
		used[kind] = (used[kind] or 0) + 1
		previous = kind

		local label = ROOM_LABELS[kind]
		if kind == "classroom" then
			classNumber += 1
			label = string.format("%d-%d", f, classNumber)
		end
		buildRoom(folders, i, kind, label, nextWoodTone(woodState, rng), rng)
		-- Spread the work over frames; a whole school at once would stall
		-- the server.
		task.wait()
	end

	floorModel.WorldPivot = CFrame.identity
	floorModel:PivotTo(CFrame.new(0, Config.floorY(f), 0))
end

-- Builds the whole map. Returns the root folder and how long each stage
-- took, as { {name, seconds} } in build order.
function SchoolGenerator.generate()
	local rng = Random.new()
	local root = Instance.new("Folder")
	root.Name = "GeneratedSchool"
	local timings = {}
	local stageStart = os.clock()
	local function stage(name)
		local now = os.clock()
		table.insert(timings, { name, now - stageStart })
		stageStart = now
	end

	local woodState = { lightness = 1, warmth = 0 }
	for f = 1, Config.FLOORS do
		buildFloor(root, f, woodState, rng)
	end
	stage("School floors")

	local function section(name)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = root
		return folder
	end

	-- Stairwells at both ends. The east one opens onto rock at the bottom
	-- and out onto the rooftop at the top.
	local stairs = section("Stairwells")
	local lightState = function(r)
		return rollLight(r, DISUSE)
	end
	local annexDoor = { s = StairAnnex.DOOR_S, width = StairAnnex.DOOR_W, height = StairAnnex.DOOR_H }
	Stairwell.build(stairs, 0, -1, { rng = rng, lightState = lightState, annexDoor = annexDoor, westBreach = true })
	Stairwell.build(stairs, TOTAL, 1, { rng = rng, lightState = lightState, bottomDoor = true, topExit = true, annexDoor = annexDoor })
	-- Toilet blocks fill the space beside each stairwell out to the south
	-- face, where there'd otherwise be an open shaft down the building.
	StairAnnex.build(stairs, 0, -1, rng)
	StairAnnex.build(stairs, TOTAL, 1, rng)
	stage("Stairwells + toilets")
	task.wait()

	-- The school is the top of a colossal building; the courtyard is a shaft
	-- cut into it, and the rooftop sits on a crag past the east stairwell.
	-- The city is the skyline, so with streaming on it stays loaded however
	-- far away the player is (it's only a few dozen big parts).
	local mega = Instance.new("Model")
	mega.Name = "Megastructure"
	pcall(function()
		mega.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	mega.Parent = root
	Megastructure.build(mega, rng)
	stage("Megastructure")
	task.wait()
	Courtyard.build(section("Courtyard"), rng)
	stage("Courtyard")
	task.wait()
	Rooftop.build(section("Rooftop"), rng)
	stage("Rooftop")
	task.wait()
	-- The department store off the rooftop's courtyard-side edge.
	DepartmentStore.build(section("DepartmentStore"), rng)
	stage("Department store")
	task.wait()
	PowerLines.build(section("PowerLines"), rng, DepartmentStore.GRID_HOOK)
	stage("Power lines")
	-- Tunnels are carved out of the rock the rooftop built, so this comes after.
	local site = Underground.build(section("Underground"), rng)
	stage("Underground + facility")
	task.wait()
	Gym.build(section("Gymnasium"), site, rng)
	stage("Gymnasium")
	task.wait()
	-- The statue past the gym; her hand finds the rock the gym heaped up.
	Kannon.build(section("Kannon"), rng)
	stage("Kannon + station")

	ChainOfShips.build(section("ChainOfShips"), Ship.anchor, site.ledge, rng)
	stage("Chain of ships")

	-- What holds the chain's other end: the port.
	Port.build(section("Port"), ChainOfShips.endPoint, ChainOfShips.walkTop, rng)
	stage("Port")

	WestCrossing.build(section("WestCrossing"), rng)
	stage("West crossing + stilt town")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CorridorSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 1, 6)
	local spawnPos = Vector3.new(4, 0.5, 0)
	spawn.CFrame = CFrame.new(spawnPos, spawnPos + Vector3.new(1, 0, 0))
	spawn.Parent = root

	root.Parent = workspace
	stage("Parenting to workspace")
	-- Last of all, make sure nothing has ended up blocking the passages.
	local routesChecked, routeReport = RouteCheck.run()
	stage("Route check")
	return root, timings, routesChecked, routeReport
end

return SchoolGenerator
