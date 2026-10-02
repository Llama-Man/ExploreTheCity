-- 月光百貨店, the Gekkō department store: a tower standing in the drop
-- just off the rooftop's courtyard-side edge, rising far above it, reached
-- by a bridge somebody threw together from the plant block to a smashed
-- window on its 9th floor.
--
-- Six tall floors are open, spread up the tower with one or two sealed
-- floors between each, round an atrium that runs up through them all
-- (boarded off on the sealed floors). Long escalators climb it in two
-- flights, turning on landings hung in the void. Each open floor is its
-- own department:
--   4F cosmetics, 6F women's fashion, 9F men's and shoes,
--   11F furniture and home, 14F toys,
--   16F the restaurant floor (where the bridge comes in),
--   19F the event hall, 22F books and stationery, 25F an art gallery.
-- Everything else is sealed off, dark behind its windows, and the
-- emergency stair climbs the whole height past landing after landing of
-- chained doors, up to the roof: an old department-store rooftop
-- amusement park (StoreRoofPark.lua), and the store's big sign turned to
-- face back across at the rooftop. The fittings on the sales floors are
-- in StoreFixtures.lua. Below 1F the tower drops away into the haze.

local BuildUtil = require(script.Parent.BuildUtil)
local TunnelProps = require(script.Parent.TunnelProps)
local Clutter = require(script.Parent.RooftopClutter)
local Rooftop = require(script.Parent.Rooftop)
local Fixtures = require(script.Parent.StoreFixtures)
local RoofPark = require(script.Parent.StoreRoofPark)
local Shacks = require(script.Parent.StoreShacks)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local Metal, Smooth, Concrete, Neon, Wood, Fabric, Glass, Plastic = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Neon, Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.Glass, Enum.Material.Plastic
local ellipsoid = TunnelProps.ellipsoid

local X0, X1, Z0, Z1 = 520, 660, 196, 286
local WALL_T = 1.2
-- The open floors (tall) and their departments; every other floor is
-- sealed (shorter). Floors are numbered as the store numbers them.
local OPEN_H, SEALED_H = 20, 15
local OPEN = {
	[4] = { name = "化粧品・婦人雑貨", kind = "cosmetics", floor = Enum.Material.Marble, color = Color3.fromRGB(226, 222, 212) },
	[6] = { name = "婦人服", kind = "womens", floor = Enum.Material.Plastic, color = Color3.fromRGB(200, 190, 176) },
	[9] = { name = "紳士服・靴", kind = "mens", floor = Enum.Material.Wood, color = Color3.fromRGB(150, 112, 76) },
	[11] = { name = "家具・生活用品", kind = "home", floor = Enum.Material.WoodPlanks, color = Color3.fromRGB(170, 132, 90) },
	[14] = { name = "おもちゃ", kind = "toys", floor = Enum.Material.Plastic, color = Color3.fromRGB(196, 206, 200) },
	[16] = { name = "レストラン街", kind = "restaurant", floor = Enum.Material.Plastic, color = Color3.fromRGB(214, 206, 190) },
	[19] = { name = "催事場", kind = "event", floor = Enum.Material.Plastic, color = Color3.fromRGB(190, 196, 204) },
	[22] = { name = "書籍・文具", kind = "books", floor = Enum.Material.WoodPlanks, color = Color3.fromRGB(150, 116, 80) },
	[25] = { name = "美術画廊", kind = "gallery", floor = Enum.Material.Marble, color = Color3.fromRGB(230, 228, 222) },
}
local OPEN_FLOORS = { 4, 6, 9, 11, 14, 16, 19, 22, 25 }
local LOWEST_OPEN, HIGHEST_OPEN = 4, 25
local BRIDGE_FLOOR, BRIDGE_Y = 16, 45
-- The whole store is built here and then moved DZ further out from the
-- rooftop; the bridges are built where it ends up.
local DZ = 40
-- The men's floor sits at tunnel depth: a pipe bridge comes in there
-- from a cave mouth in the crag's north face (Underground carves the way).
local LINK_FLOOR, LINK_X = 9, 576
-- Windows knocked through into shacks on the outside (StoreShacks): the
-- face, the floor, and where along the face (in build coordinates). The
-- first is the west boardwalk's; the rest are shacks on their own.
local WAY_INS = {
	{ face = "west", floor = 19, at = 262 },
	{ face = "east", floor = 11, at = 230, kind = "home" },
	{ face = "north", floor = 14, at = 560, kind = "storeroom" },
	{ face = "west", floor = 6, at = 222, kind = "workshop" },
	{ face = "south", floor = 22, at = 624, kind = "home" },
	{ face = "north", floor = 25, at = 600, kind = "radio" },
}
local TOP_FLOOR = 28
-- Floor heights, stacked up and down from the bridge floor.
local STACK = {}
do
	local function height(f)
		return if OPEN[f] then OPEN_H else SEALED_H
	end
	STACK[BRIDGE_FLOOR] = { y = BRIDGE_Y, h = height(BRIDGE_FLOOR) }
	for f = BRIDGE_FLOOR + 1, TOP_FLOOR + 1 do
		STACK[f] = { y = STACK[f - 1].y + STACK[f - 1].h, h = height(f) }
	end
	for f = BRIDGE_FLOOR - 1, 1, -1 do
		STACK[f] = { y = STACK[f + 1].y - height(f), h = height(f) }
	end
end
local function floorY(f)
	return STACK[f].y
end
local function floorH(f)
	return STACK[f].h
end
local ROOF = floorY(TOP_FLOOR + 1)
local HOLE = { x0 = 570, x1 = 612, z0 = 222, z1 = 260 } -- the atrium
local BAND_A, BAND_B = 231.5, 250.5 -- the two escalator lanes (z)
local TURN_X = 578 -- escalators turn on landings hung at this end
-- The emergency stair, in the north-east corner, the whole height.
local CORE = { x0 = 642, x1 = X1 - WALL_T / 2, z0 = 262, z1 = Z1 - WALL_T / 2 }
local CORE_DOOR_X = 646
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local FACADE = Color3.fromRGB(196, 184, 160)
local BAND = Color3.fromRGB(70, 66, 60)
local STEEL = Color3.fromRGB(110, 112, 114)
local DARK = Color3.fromRGB(40, 40, 42)

local DepartmentStore = {}
-- Where the rooftop's power line comes in, on the south face over the
-- boardwalk (PowerLines).
DepartmentStore.GRID_HOOK = Vector3.new(X0 + 40, floorY(BRIDGE_FLOOR) + 16, Z0 + DZ - 0.7)
DepartmentStore.LINK = { x = LINK_X, y = floorY(LINK_FLOOR), mouthZ = 184, boardwalkZ = Z0 + DZ - 17 }

-- ===== Helpers =====

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

local function label(parent, cframe, size, face, text, bg, fg, material, font)
	local plate = part(parent, "Sign", size, cframe, material or Smooth, bg)
	plate.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = font or Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = fg
	t.Text = text
	t.Parent = gui
	gui.Parent = plate
	return plate
end

-- Frame on the floor at `at`, facing `yaw`, for building fixtures in
-- (x across, -z the front).
local function frameAt(at, yaw)
	return CFrame.new(at) * CFrame.Angles(0, yaw, 0)
end

local function at(parent, name, cf, x, y, z, size, material, color)
	return part(parent, name, size, cf * CFrame.new(x, y, z), material, color)
end

-- ===== Fixtures (built on a floor frame, front towards -z) =====

local function fittingRooms(m, cf, rng)
	for k = -1, 1 do
		local x = k * 3.2
		for _, s in ipairs({ -1, 1 }) do
			at(m, "FittingWall", cf, x + s * 1.55, 3.5, -1.5, Vector3.new(0.12, 7, 3), Wood, Color3.fromRGB(230, 226, 216))
		end
		local curtain = at(m, "FittingCurtain", cf * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-2, 2))), x + rng:NextNumber(-0.6, 0.6), 3.6, -3, Vector3.new(rng:NextNumber(1.6, 3), 5.8, 0.1), Fabric, Color3.fromRGB(150, 40, 50))
		curtain.CanCollide = false
		local mirror = at(m, "FittingMirror", cf, x, 3.5, -0.1, Vector3.new(1.6, 4.5, 0.05), Glass, Color3.fromRGB(200, 208, 210))
		mirror.Reflectance = 0.5
	end
	cylinder(m, "CurtainRail", 9.6, 0.1, cf * CFrame.new(0, 6.6, -3), Metal, STEEL)
end

-- The restaurant floor's plastic-food case: glass box, plates of
-- improbably perfect food, price tags.
local function foodCase(m, cf, rng)
	at(m, "CaseBase", cf, 0, 1.3, 0, Vector3.new(8, 2.6, 2.4), Wood, Color3.fromRGB(60, 44, 36))
	local g = at(m, "CaseGlass", cf, 0, 4.2, 0, Vector3.new(8, 3.2, 2.4), Glass, Color3.fromRGB(210, 222, 224))
	g.Transparency = 0.75
	at(m, "CaseTop", cf, 0, 5.9, 0, Vector3.new(8.2, 0.2, 2.6), Wood, Color3.fromRGB(60, 44, 36))
	for level = 0, 1 do
		local y = 2.7 + level * 1.5
		if level == 1 then
			at(m, "CaseShelf", cf, 0, y - 0.05, 0.2, Vector3.new(7.8, 0.08, 1.4), Glass, Color3.fromRGB(220, 230, 232)).Transparency = 0.4
		end
		for k = -3, 3 do
			local x = k * 1.1
			cylinder(m, "Dish", 0.1, 0.9, cf * CFrame.new(x, y + 0.05, 0.2) * UPRIGHT, Smooth, Color3.fromRGB(240, 238, 232))
			local roll = rng:NextNumber()
			if roll < 0.3 then
				ellipsoid(m, "Omurice", Vector3.new(0.7, 0.35, 0.45), cf * CFrame.new(x, y + 0.25, 0.2), Smooth, Color3.fromRGB(240, 200, 60))
			elseif roll < 0.6 then
				ellipsoid(m, "Noodles", Vector3.new(0.7, 0.3, 0.7), cf * CFrame.new(x, y + 0.2, 0.2), Smooth, Color3.fromRGB(200, 150, 80))
				part(m, "Garnish", Vector3.new(0.3, 0.05, 0.2), cf * CFrame.new(x + 0.1, y + 0.36, 0.1), Smooth, Color3.fromRGB(80, 160, 60))
			elseif roll < 0.8 then
				ellipsoid(m, "Parfait", Vector3.new(0.35, 0.7, 0.35), cf * CFrame.new(x, y + 0.45, 0.2), Glass, Color3.fromRGB(240, 180, 200)).Transparency = 0.2
			else
				at(m, "Curry", cf, x, y + 0.14, 0.2, Vector3.new(0.7, 0.12, 0.5), Smooth, Color3.fromRGB(150, 90, 30))
			end
			at(m, "PriceTag", cf, x, y + 0.08, -0.45, Vector3.new(0.6, 0.25, 0.04), Smooth, Color3.fromRGB(250, 250, 240)).CanCollide = false
		end
	end
end

-- ===== The building =====

-- Boxes covering the footprint [x0,x1]x[z0,z1] minus some rectangles
-- (the atrium, the stair core), merged along x within each z band.
local function fillAround(m, name, x0, x1, z0, z1, y0, y1, holes, material, color)
	local xs, zs = { x0, x1 }, { z0, z1 }
	for _, h in ipairs(holes) do
		table.insert(xs, math.clamp(h.x0, x0, x1))
		table.insert(xs, math.clamp(h.x1, x0, x1))
		table.insert(zs, math.clamp(h.z0, z0, z1))
		table.insert(zs, math.clamp(h.z1, z0, z1))
	end
	table.sort(xs)
	table.sort(zs)
	local function inHole(x, z)
		for _, h in ipairs(holes) do
			if x > h.x0 and x < h.x1 and z > h.z0 and z < h.z1 then
				return true
			end
		end
		return false
	end
	for j = 1, #zs - 1 do
		local za, zb = zs[j], zs[j + 1]
		if zb - za > 0.01 then
			local runStart
			for i = 1, #xs do
				local solid = i < #xs and xs[i + 1] - xs[i] > 0.01 and not inHole((xs[i] + xs[i + 1]) / 2, (za + zb) / 2)
				if solid and not runStart then
					runStart = xs[i]
				elseif not solid and runStart then
					box(m, name, runStart, xs[i], y0, y1, za, zb, material, color)
					runStart = nil
				end
			end
		end
	end
end

local SIDES = { { "X", Z0, -1 }, { "X", Z1, 1 }, { "Z", X0, -1 }, { "Z", X1, 1 } }
local function faceName(side)
	if side[1] == "X" then
		return if side[2] == Z0 then "south" else "north"
	end
	return if side[2] == X0 then "west" else "east"
end

local function sideSpan(side)
	return if side[1] == "X" then X0 else Z0, if side[1] == "X" then X1 else Z1
end

-- An open floor's outer walls: tall windows you can see out of (broken
-- here and there), sills, a dark band at the floor line; the bridge's
-- smashed way in on the bridge floor.
local function openWalls(m, f, rng)
	local y, h = floorY(f), floorH(f)
	local top = y + h - 1
	for _, side in ipairs(SIDES) do
		local a, b = sideSpan(side)
		local list = {}
		for c = a + 6, b - 6, 12 do
			table.insert(list, { center = c, width = 9, bottom = y + 4, top = y + 15 })
		end
		local face = faceName(side)
		local ways = {}
		if face == "south" and f == BRIDGE_FLOOR then
			table.insert(ways, Rooftop.BRIDGE.x)
		elseif face == "south" and f == LINK_FLOOR then
			table.insert(ways, LINK_X)
		end
		for _, w in ipairs(WAY_INS) do
			if w.face == face and w.floor == f then
				table.insert(ways, w.at)
			end
		end
		for _, wayIn in ipairs(ways) do
			for i = #list, 1, -1 do
				if math.abs(list[i].center - wayIn) < 10 then
					table.remove(list, i)
				end
			end
			table.insert(list, { center = wayIn, width = 9, bottom = y, top = y + 12, bridge = true })
		end
		BuildUtil.strip(m, {
			name = "StoreWall",
			axis = side[1],
			fixed = side[2],
			spanStart = a - WALL_T / 2,
			spanEnd = b + WALL_T / 2,
			bottom = y,
			top = top,
			thickness = WALL_T,
			openings = list,
			material = Concrete,
			color = jitter(FACADE, rng, 0.03),
		})
		for _, w in ipairs(list) do
			if not w.bridge then
				if rng:NextNumber() > 0.25 then
					local size, pos = BuildUtil.axisBox(side[1], w.width, w.top - w.bottom, 0.15, w.center, (w.bottom + w.top) / 2, side[2])
					part(m, "WindowGlass", size, pos, Glass, Color3.fromRGB(120, 140, 150)).Transparency = 0.55
				end
				local size, pos = BuildUtil.axisBox(side[1], w.width + 0.4, 0.3, WALL_T + 0.3, w.center, w.bottom - 0.15, side[2])
				part(m, "WindowSill", size, pos, Concrete, darken(FACADE, 0.85))
			end
		end
		local size, pos = BuildUtil.axisBox(side[1], b - a + 2, 1.4, 0.4, (a + b) / 2, top + 0.2, side[2] + side[3] * 0.75)
		part(m, "FloorBand", size, pos, Concrete, BAND)
	end
end

-- A sealed floor: ribbon windows all round, dark inside (black boxes sit
-- behind the glass, round the stair core and, within the open floors'
-- span, round the atrium, which is boarded off with hoardings).
local function sealedFloor(m, f, rng)
	local y, h = floorY(f), floorH(f)
	for _, side in ipairs(SIDES) do
		local a, b = sideSpan(side)
		local len, mid = b - a + WALL_T, (a + b) / 2
		local function band(name, y0, y1, material, color)
			local size, pos = BuildUtil.axisBox(side[1], len, y1 - y0, WALL_T, mid, (y0 + y1) / 2, side[2])
			return part(m, name, size, pos, material, color)
		end
		band("Spandrel", y, y + 4.5, Concrete, jitter(FACADE, rng, 0.03))
		band("RibbonGlass", y + 4.5, y + h - 1.6, Glass, Color3.fromRGB(40, 48, 54)).Reflectance = 0.2
		band("FloorBand", y + h - 1.6, y + h, Concrete, BAND)
		for c = a + 20, b - 10, 20 do
			local size, pos = BuildUtil.axisBox(side[1], 0.5, h - 6.1, WALL_T + 0.3, c, y + 4.5 + (h - 6.1) / 2, side[2])
			part(m, "Mullion", size, pos, Metal, darken(FACADE, 0.7))
		end
		if rng:NextNumber() < 0.3 then
			local c = rng:NextNumber(a + 6, b - 6)
			local size, pos = BuildUtil.axisBox(side[1], rng:NextNumber(4, 10), 8, 0.2, c, y + 9, side[2] + side[3] * (WALL_T / 2 + 0.1))
			part(m, "BoardedPane", size, pos, Wood, jitter(Color3.fromRGB(130, 104, 74), rng, 0.1))
		end
	end
	local holes = {}
	local inCoreSpan = f >= LOWEST_OPEN
	local inAtrium = f > LOWEST_OPEN and f < HIGHEST_OPEN
	if inCoreSpan then
		table.insert(holes, { x0 = CORE.x0 - 0.5, x1 = X1, z0 = CORE.z0 - 0.5, z1 = Z1 })
	end
	if inAtrium then
		table.insert(holes, { x0 = HOLE.x0 - 0.4, x1 = HOLE.x1 + 0.4, z0 = HOLE.z0 - 0.4, z1 = HOLE.z1 + 0.4 })
	end
	-- (Kept just clear of the slabs above and below, so no two faces share
	-- a plane and flicker.)
	fillAround(m, "SealedDark", X0 + 1.5, X1 - 1.5, Z0 + 1.5, Z1 - 1.5, y + 0.05, y + h - 1.05, holes, Smooth, Color3.fromRGB(14, 14, 16))
	if inAtrium then
		-- Hoardings round the atrium on this floor.
		local ply = Color3.fromRGB(170, 146, 110)
		for _, w in ipairs({ { HOLE.x0, HOLE.x1, HOLE.z0 - 0.4, HOLE.z0 }, { HOLE.x0, HOLE.x1, HOLE.z1, HOLE.z1 + 0.4 }, { HOLE.x0 - 0.4, HOLE.x0, HOLE.z0, HOLE.z1 }, { HOLE.x1, HOLE.x1 + 0.4, HOLE.z0, HOLE.z1 } }) do
			box(m, "Hoarding", w[1], w[2], y, y + h, w[3], w[4], Wood, jitter(ply, rng, 0.05))
		end
		if rng:NextNumber() < 0.7 then
			label(m, CFrame.new((HOLE.x0 + HOLE.x1) / 2, y + 7, HOLE.z0 + 0.05), Vector3.new(8, 2, 0.05), Enum.NormalId.Back, "工事中  立入禁止", Color3.fromRGB(240, 200, 50), Color3.fromRGB(30, 30, 32))
		end
	end
end

-- The tower's shell: open floors, sealed floors, slabs, the roof, the
-- solid tower below, columns, and the great vertical sign on the corner.
local function shell(m, rng)
	local coreHole = { x0 = CORE.x0, x1 = X1, z0 = CORE.z0, z1 = Z1 }
	for _, f in ipairs(OPEN_FLOORS) do
		local y, h = floorY(f), floorH(f)
		local info = OPEN[f]
		-- Floor: the atrium open below it except on the lowest; the stair
		-- core open except on the lowest (where it starts).
		local floorHoles = if f == LOWEST_OPEN then {} else { HOLE, coreHole }
		fillAround(m, "FloorSlab", X0, X1, Z0, Z1, y - 1, y, floorHoles, info.floor, info.color)
		-- Ceiling: the atrium carries on up except over the highest.
		local ceilingHoles = if f == HIGHEST_OPEN then { coreHole } else { HOLE, coreHole }
		fillAround(m, "CeilingSlab", X0, X1, Z0, Z1, y + h - 1, y + h, ceilingHoles, Concrete, Color3.fromRGB(214, 210, 200))
		if f ~= LOWEST_OPEN then
			box(m, "SlabEdge", HOLE.x0 - 0.2, HOLE.x1 + 0.2, y - 1.6, y - 1, HOLE.z0 - 0.2, HOLE.z0, Smooth, FACADE)
			box(m, "SlabEdge", HOLE.x0 - 0.2, HOLE.x1 + 0.2, y - 1.6, y - 1, HOLE.z1, HOLE.z1 + 0.2, Smooth, FACADE)
		end
	end
	fillAround(m, "RoofSlab", X0, X1, Z0, Z1, ROOF - 1, ROOF, { coreHole }, Concrete, Color3.fromRGB(128, 124, 116))
	for f = 1, TOP_FLOOR do
		if OPEN[f] then
			openWalls(m, f, rng)
		else
			sealedFloor(m, f, rng)
		end
		if f % 4 == 0 then
			task.wait()
		end
	end
	-- Parapet round the roof.
	for _, s in ipairs({ { X0, X1, Z0 - 0.6, Z0 + 0.6 }, { X0, X1, Z1 - 0.6, Z1 + 0.6 }, { X0 - 0.6, X0 + 0.6, Z0, Z1 }, { X1 - 0.6, X1 + 0.6, Z0, Z1 } }) do
		box(m, "Parapet", s[1], s[2], ROOF, ROOF + 1.5, s[3], s[4], Concrete, FACADE)
	end
	-- Below 1F, the tower carries on down into the haze.
	local base = floorY(1)
	box(m, "Tower", X0 + 0.5, X1 - 0.5, -1900, base, Z0 + 0.5, Z1 - 0.5, Concrete, darken(FACADE, 0.8))
	for y = base - 16, -560, -15 do
		for _, side in ipairs(SIDES) do
			local a, b = sideSpan(side)
			local size, pos = BuildUtil.axisBox(side[1], b - a - 4, 6, 0.3, (a + b) / 2, y + 7, side[2] + side[3] * 0.1)
			part(m, "DarkWindows", size, pos, Glass, Color3.fromRGB(34, 40, 44))
		end
	end
	-- Columns on the open floors, clear of the atrium and the core.
	for _, x in ipairs({ 542, 565, 617, 640 }) do
		for _, z in ipairs({ 214, 241, 268 }) do
			if not (x > CORE.x0 - 2 and z > CORE.z0 - 2) then
				for _, f in ipairs(OPEN_FLOORS) do
					box(m, "Column", x - 1.2, x + 1.2, floorY(f), floorY(f) + floorH(f) - 1, z - 1.2, z + 1.2, Concrete, Color3.fromRGB(226, 222, 212))
				end
			end
		end
	end
	-- The vertical sign down the south-west corner, big enough to read from
	-- the school.
	local signTop, signBottom = floorY(27), floorY(18)
	for _, face in ipairs({ { cf = CFrame.new(X0 + 7, (signTop + signBottom) / 2, Z0 - 3), size = Vector3.new(7, signTop - signBottom, 1.2), normal = Enum.NormalId.Front }, { cf = CFrame.new(X0 - 3, (signTop + signBottom) / 2, Z0 + 7), size = Vector3.new(1.2, signTop - signBottom, 7), normal = Enum.NormalId.Left } }) do
		local board = label(m, face.cf, face.size, face.normal, "月\n光\n百\n貨\n店", Color3.fromRGB(236, 232, 222), Color3.fromRGB(190, 40, 40), Smooth, Enum.Font.GothamBlack)
		board.CanCollide = true
		for y = signBottom + 10, signTop - 10, 30 do
			rod(m, "SignBracket", (face.cf * CFrame.new(0, y - (signTop + signBottom) / 2, 0)).Position, Vector3.new(if face.normal == Enum.NormalId.Front then X0 + 7 else X0, y, if face.normal == Enum.NormalId.Front then Z0 else Z0 + 7), 0.5, Metal, STEEL)
		end
	end
end

-- Ceiling lights, a share of them still working.
local function ceilingLights(m, f, rng)
	local y = floorY(f) + floorH(f) - 1.15
	local k = 0
	for x = X0 + 12, X1 - 10, 18 do
		for z = Z0 + 10, Z1 - 8, 16 do
			local inCore = x > CORE.x0 - 2 and z > CORE.z0 - 2
			if not (x > HOLE.x0 and x < HOLE.x1 and z > HOLE.z0 and z < HOLE.z1) and not inCore then
				k += 1
				local lit = rng:NextNumber() > 0.4
				local panel = box(m, "CeilingLight", x - 2, x + 2, y, y + 0.15, z - 1, z + 1, if lit then Neon else Smooth, if lit then Color3.fromRGB(240, 238, 226) else Color3.fromRGB(150, 150, 146))
				panel.CanCollide = false
				if lit and k % 3 == 0 then
					local light = Instance.new("SurfaceLight")
					light.Face = Enum.NormalId.Bottom
					light.Range = 26
					light.Angle = 150
					light.Brightness = 1
					light.Color = Color3.fromRGB(240, 236, 220)
					light.Parent = panel
					if rng:NextNumber() < 0.2 then
						panel:AddTag("FlickerLight")
					end
				end
			end
		end
	end
end

-- An escalator from (xLow, yLow) up to (xHigh, yHigh) in the lane
-- centred on z.
local function escalator(m, xLow, yLow, xHigh, yHigh, z, rng)
	local n = math.ceil((yHigh - yLow) / 0.8)
	local dir = if xHigh > xLow then 1 else -1
	local run = math.abs(xHigh - xLow) / n
	local rise = (yHigh - yLow) / n
	for i = 1, n do
		local xa = xLow + dir * (i - 1) * run
		local xb = xLow + dir * i * run
		local top = yLow + i * rise
		box(m, "EscalatorStep", math.min(xa, xb), math.max(xa, xb) + 0.02, top - 1, top, z - 2.2, z + 2.2, Enum.Material.DiamondPlate, Color3.fromRGB(80, 82, 84))
		box(m, "StepEdge", if dir > 0 then xb - 0.25 else xb, if dir > 0 then xb else xb + 0.25, top, top + 0.04, z - 2.2, z + 2.2, Smooth, Color3.fromRGB(214, 176, 40))
	end
	local a, b = Vector3.new(xLow, yLow, z), Vector3.new(xHigh, yHigh, z)
	local frame = CFrame.lookAt((a + b) / 2, b)
	part(m, "EscalatorTruss", Vector3.new(5.4, 1.6, (b - a).Magnitude), frame * CFrame.new(0, -1.6, 0), Metal, Color3.fromRGB(190, 186, 176))
	for _, s in ipairs({ -1, 1 }) do
		local glass = part(m, "Balustrade", Vector3.new(0.15, 2.8, (b - a).Magnitude), frame * CFrame.new(s * 2.5, 1.4, 0), Glass, Color3.fromRGB(200, 214, 216))
		glass.Transparency = 0.6
		part(m, "Skirt", Vector3.new(0.2, 1, (b - a).Magnitude), frame * CFrame.new(s * 2.45, -0.3, 0), Metal, Color3.fromRGB(150, 150, 146))
		rod(m, "Handrail", a + Vector3.new(0, 3, s * 2.5), b + Vector3.new(0, 3, s * 2.5), 0.3, Enum.Material.Rubber, Color3.fromRGB(20, 20, 22))
	end
	for _, e in ipairs({ { xLow, yLow }, { xHigh, yHigh } }) do
		box(m, "CombPlate", e[1] - 1.2, e[1] + 1.2, e[2], e[2] + 0.06, z - 2.2, z + 2.2, Metal, STEEL)
	end
end

-- From one open floor up to the next: up lane A to a landing hung at the
-- atrium's west end, round, and up lane B.
local function escalatorPair(m, fromF, toF, rng)
	local y0, y1 = floorY(fromF), floorY(toF)
	local mid = (y0 + y1) / 2
	escalator(m, HOLE.x1, y0, TURN_X, mid, BAND_A, rng)
	escalator(m, TURN_X, mid, HOLE.x1, y1, BAND_B, rng)
	local landing = model(m, "EscalatorLanding")
	box(landing, "LandingDeck", HOLE.x0 + 0.4, TURN_X + 1.2, mid - 0.8, mid, BAND_A - 3.2, BAND_B + 3.2, Enum.Material.DiamondPlate, Color3.fromRGB(80, 82, 84))
	box(landing, "LandingGirder", HOLE.x0 + 0.4, TURN_X + 1.2, mid - 2, mid - 0.8, BAND_A - 3.2, BAND_B + 3.2, Metal, Color3.fromRGB(190, 186, 176))
	for _, z in ipairs({ BAND_A - 3, BAND_B + 3 }) do
		rod(landing, "LandingRail", Vector3.new(HOLE.x0 + 0.6, mid + 3.2, z), Vector3.new(TURN_X + 1, mid + 3.2, z), 0.25, Metal, STEEL)
		rod(landing, "LandingHanger", Vector3.new(HOLE.x0 + 1, mid, z), Vector3.new(HOLE.x0 + 1, mid + 10, z), 0.2, Metal, STEEL)
	end
	rod(landing, "LandingRail", Vector3.new(TURN_X + 1, mid + 3.2, BAND_A + 2.8), Vector3.new(TURN_X + 1, mid + 3.2, BAND_B - 2.8), 0.25, Metal, STEEL)
end

-- Glass balustrade round the atrium edge on floor f, open where the
-- escalators arrive and leave.
local function atriumRail(m, f, gaps)
	local y = floorY(f)
	local function run(xa, za, xb, zb)
		local a, b = Vector3.new(xa, y, za), Vector3.new(xb, y, zb)
		if (b - a).Magnitude < 0.5 then
			return
		end
		local frame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 1.7, 0), b + Vector3.new(0, 1.7, 0))
		local glass = part(m, "AtriumGlass", Vector3.new(0.15, 3.2, (b - a).Magnitude), frame, Glass, Color3.fromRGB(200, 214, 216))
		glass.Transparency = 0.6
		rod(m, "AtriumRail", a + Vector3.new(0, 3.4, 0), b + Vector3.new(0, 3.4, 0), 0.25, Metal, STEEL)
	end
	run(HOLE.x0, HOLE.z0, HOLE.x1, HOLE.z0)
	run(HOLE.x0, HOLE.z1, HOLE.x1, HOLE.z1)
	for _, x in ipairs({ HOLE.x0, HOLE.x1 }) do
		local z = HOLE.z0
		local cuts = {}
		for _, g in ipairs(gaps) do
			if g.x == x then
				table.insert(cuts, g.z)
			end
		end
		table.sort(cuts)
		for _, c in ipairs(cuts) do
			run(x, z, x, c - 2.6)
			z = c + 2.6
		end
		run(x, z, x, HOLE.z1)
	end
end

-- Fixture spots on floor f: a loose grid over the sales floor, clear of
-- the atrium ring, columns, escalator landings, the bridge's way in and
-- the stair up.
local function spots(f, rng)
	local list = {}
	local function clear(x, z)
		if x > HOLE.x0 - 8 and x < HOLE.x1 + 8 and z > HOLE.z0 - 8 and z < HOLE.z1 + 8 then
			return false
		end
		for _, cx in ipairs({ 542, 565, 617, 640 }) do
			for _, cz in ipairs({ 214, 241, 268 }) do
				if math.abs(x - cx) < 4 and math.abs(z - cz) < 4 then
					return false
				end
			end
		end
		if f == BRIDGE_FLOOR and math.abs(x - Rooftop.BRIDGE.x) < 7 and z < HOLE.z0 then
			return false
		end
		if f == LINK_FLOOR and math.abs(x - LINK_X) < 7 and z < HOLE.z0 then
			return false
		end
		for _, w in ipairs(WAY_INS) do
			if w.floor == f then
				local along = if w.face == "south" or w.face == "north" then x else z
				local depth = if w.face == "south" then z - Z0 elseif w.face == "north" then Z1 - z elseif w.face == "west" then x - X0 else X1 - x
				if math.abs(along - w.at) < 7 and depth < 12 then
					return false
				end
			end
		end
		if x > CORE.x0 - 8 and z > CORE.z0 - 10 then
			return false
		end
		return true
	end
	for x = X0 + 8, X1 - 8, 11 do
		for z = Z0 + 8, Z1 - 8, 10 do
			local jx, jz = x + rng:NextNumber(-1, 1), z + rng:NextNumber(-1, 1)
			if clear(jx, jz) and rng:NextNumber() < 0.72 then
				table.insert(list, Vector3.new(jx, floorY(f), jz))
			end
		end
	end
	return list
end

-- Each floor's dressing: a walkway round the atrium in its own finish,
-- clad columns, banners hung from the ceiling (and the big teddy on the
-- toy floor).
local AISLE = {
	cosmetics = { Enum.Material.Marble, Color3.fromRGB(70, 66, 62) },
	womens = { Enum.Material.Carpet, Color3.fromRGB(150, 128, 120) },
	mens = { Enum.Material.Carpet, Color3.fromRGB(60, 56, 62) },
	home = { Enum.Material.WoodPlanks, Color3.fromRGB(120, 88, 60) },
	toys = { Enum.Material.Plastic, Color3.fromRGB(240, 200, 60) },
	restaurant = { Enum.Material.CeramicTiles, Color3.fromRGB(150, 60, 50) },
	event = { Enum.Material.Plastic, Color3.fromRGB(120, 124, 130) },
	books = { Enum.Material.Carpet, Color3.fromRGB(50, 80, 64) },
	gallery = { Enum.Material.Marble, Color3.fromRGB(200, 196, 188) },
}
local CLADDING = { cosmetics = "mirror", womens = "posters", mens = "panel", toys = "toys", event = "posters", books = "panel" }
local BANNERS = {
	cosmetics = { Color3.fromRGB(180, 36, 56), { "新色登場", "NEW COLOUR", "BEAUTY FAIR" } },
	womens = { Color3.fromRGB(40, 40, 44), { "春の新作", "SPRING", "SALE" } },
	mens = { Color3.fromRGB(30, 50, 90), { "SALE 30%OFF","スーツフェア", "BUSINESS" } },
	home = { Color3.fromRGB(110, 130, 90), { "暮らしフェア", "HOME", "新生活" } },
	toys = { Color3.fromRGB(60, 120, 220), { "おもちゃ大集合!", "TOYS", "夏休み" } },
	restaurant = { Color3.fromRGB(150, 30, 30), { "レストラン街", "味めぐり", "RESTAURANTS" } },
	event = { Color3.fromRGB(200, 120, 20), { "大北海道展", "催事場", "SALE" } },
	books = { Color3.fromRGB(40, 70, 60), { "読書週間", "新刊", "BOOKS" } },
	gallery = { Color3.fromRGB(30, 30, 34), { "特別展", "EXHIBITION", "月光コレクション" } },
}

local function dressFloor(m, f, rng)
	local kind = OPEN[f].kind
	local aisle = AISLE[kind]
	if not aisle then
		return
	end
	local y, h = floorY(f), floorH(f)
	local ax0, ax1, az0, az1 = HOLE.x0 - 6, HOLE.x1 + 6, HOLE.z0 - 6, HOLE.z1 + 6
	local ix0, ix1, iz0, iz1 = HOLE.x0 - 1, HOLE.x1 + 1, HOLE.z0 - 1, HOLE.z1 + 1
	for _, r in ipairs({ { ax0, ax1, az0, iz0 }, { ax0, ax1, iz1, az1 }, { ax0, ix0, iz0, iz1 }, { ix1, ax1, iz0, iz1 } }) do
		box(m, "Walkway", r[1], r[2], y - 0.02, y + 0.03, r[3], r[4], aisle[1], aisle[2])
	end
	local style = CLADDING[kind]
	if style then
		for _, x in ipairs({ 542, 565, 617, 640 }) do
			for _, z in ipairs({ 214, 241, 268 }) do
				if not (x > CORE.x0 - 2 and z > CORE.z0 - 2) then
					Fixtures.columnCladding(m, x, z, y, y + h - 1, style, rng)
				end
			end
		end
	end
	local banner = BANNERS[kind]
	local top = y + h - 1
	for _ = 1, 5 do
		local bx, bz = rng:NextNumber(X0 + 10, X1 - 14), rng:NextNumber(Z0 + 8, Z1 - 8)
		local inAtrium = bx > HOLE.x0 - 4 and bx < HOLE.x1 + 4 and bz > HOLE.z0 - 4 and bz < HOLE.z1 + 4
		if not inAtrium and not (bx > CORE.x0 - 4 and bz > CORE.z0 - 4) then
			local cf = CFrame.new(bx, top - 4.5, bz) * CFrame.Angles(0, math.rad(pick({ 0, 90 }, rng)), 0)
			local cloth = label(m, cf, Vector3.new(3.6, 6, 0.08), Enum.NormalId.Front, pick(banner[2], rng), jitter(banner[1], rng, 0.05), Color3.fromRGB(245, 242, 234), Fabric, Enum.Font.GothamBlack)
			local back = cloth:FindFirstChildOfClass("SurfaceGui"):Clone()
			back.Face = Enum.NormalId.Back
			back.Parent = cloth
			cylinder(m, "BannerBar", 3.8, 0.12, cf * CFrame.new(0, 3.05, 0), Metal, STEEL)
			for _, dx in ipairs({ -1.6, 1.6 }) do
				rod(m, "BannerWire", (cf * CFrame.new(dx, 3.1, 0)).Position, (cf * CFrame.new(dx, 4.5, 0)).Position, 0.05, Metal, STEEL)
			end
		end
	end
	if kind == "toys" then
		Fixtures.bigTeddy(m, CFrame.new(565, y, 219) * CFrame.Angles(0, math.rad(-135), 0), rng)
	end
end

-- The floor guide by the top of the escalators: every open floor, this
-- one marked.
local function floorGuide(m, f)
	local y = floorY(f)
	local lines = { "フロアガイド  FLOOR GUIDE", "R   屋上遊園地" }
	for k = #OPEN_FLOORS, 1, -1 do
		local g = OPEN_FLOORS[k]
		table.insert(lines, string.format("%s%dF   %s", if g == f then "▶ " else "", g, OPEN[g].name))
	end
	table.insert(lines, "（その他の階は閉鎖中）")
	local board = label(m, CFrame.new(617, y + 4.6, 263.5), Vector3.new(5, 6.4, 0.3), Enum.NormalId.Front, table.concat(lines, string.char(10)), Color3.fromRGB(30, 34, 50), Color3.fromRGB(240, 236, 220), Smooth, Enum.Font.Gotham)
	board.CanCollide = true
	local text = board:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Size = UDim2.fromScale(0.9, 0.92)
	text.Position = UDim2.fromScale(0.05, 0.04)
	for _, dx in ipairs({ -2, 2 }) do
		box(m, "GuidePost", 617 + dx - 0.12, 617 + dx + 0.12, y, y + 1.4, 263.38, 263.62, Metal, STEEL)
	end
end

-- What's on each floor.
local function furnish(m, f, rng)
	local yawOf = function()
		return math.rad(pick({ 0, 90, 180, 270 }, rng) + rng:NextNumber(-6, 6))
	end
	local y = floorY(f)
	for _, p in ipairs(spots(f, rng)) do
		Fixtures.furnish(m, OPEN[f].kind, frameAt(p, yawOf()), rng)
	end
	dressFloor(m, f, rng)
	floorGuide(m, f)
	-- Fixed pieces: fitting rooms on the women's floor; plastic-food cases
	-- by the restaurants; the moon hung in the atrium under the gallery.
	if OPEN[f].kind == "gallery" then
		Fixtures.hangingMoon(m, Vector3.new((HOLE.x0 + HOLE.x1) / 2, y + 1, (HOLE.z0 + HOLE.z1) / 2), 5.5, y + floorH(f) - 1, rng)
	elseif OPEN[f].kind == "womens" then
		fittingRooms(m, frameAt(Vector3.new(X1 - 3, y, 232), math.rad(90)), rng)
	elseif OPEN[f].kind == "restaurant" then
		for _, spot in ipairs({ { 630, "お食事処" }, { 552, "甘味処" } }) do
			foodCase(m, frameAt(Vector3.new(spot[1], y, HOLE.z0 - 5), 0), rng)
			label(m, CFrame.new(spot[1], y + 7.5, HOLE.z0 - 5.2), Vector3.new(8, 1.6, 0.1), Enum.NormalId.Front, spot[2], Color3.fromRGB(120, 30, 30), Color3.fromRGB(250, 240, 220))
		end
	end
	-- Department sign hung by the escalators.
	local fh = floorH(f)
	local sign = label(m, CFrame.new((HOLE.x0 + HOLE.x1) / 2, y + fh - 4, HOLE.z0 - 0.3), Vector3.new(14, 2.2, 0.15), Enum.NormalId.Front, string.format("%dF  %s", f, OPEN[f].name), Color3.fromRGB(30, 34, 50), Color3.fromRGB(240, 236, 220))
	sign.Material = Smooth
	for _, dx in ipairs({ -6, 6 }) do
		rod(m, "SignHanger", Vector3.new((HOLE.x0 + HOLE.x1) / 2 + dx, y + fh - 2.9, HOLE.z0 - 0.3), Vector3.new((HOLE.x0 + HOLE.x1) / 2 + dx, y + fh - 1, HOLE.z0 - 0.3), 0.08, Metal, STEEL)
	end
	-- Decay: fallen ceiling tiles, puddles under broken windows, papers,
	-- weeds where the rain gets in.
	for _ = 1, rng:NextInteger(3, 7) do
		part(m, "FallenCeilingTile", Vector3.new(4, 0.15, 2), CFrame.new(rng:NextNumber(X0 + 4, X1 - 4), y + 0.2, rng:NextNumber(Z0 + 4, Z1 - 4)) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2)), Smooth, Color3.fromRGB(220, 216, 206))
	end
	for _ = 1, rng:NextInteger(2, 5) do
		local edge = pick({ { rng:NextNumber(X0 + 4, X1 - 4), Z0 + 3 }, { rng:NextNumber(X0 + 4, X1 - 4), Z1 - 3 }, { X0 + 3, rng:NextNumber(Z0 + 4, Z1 - 4) }, { X1 - 3, rng:NextNumber(Z0 + 4, Z1 - 4) } }, rng)
		local c = Vector3.new(edge[1], y, edge[2])
		local holder = model(m, "Growth")
		if rng:NextNumber() < 0.5 then
			Clutter.puddle(holder, c, rng)
		else
			Clutter.weeds(holder, c, rng)
		end
	end
end

-- The emergency stair, the tower's whole height from the lowest open
-- floor to the roof: switchback flights inside a concrete core, a landing
-- at every floor with its number on the wall. The open floors' doors
-- stand open; every sealed floor's is chained and boarded, a few forced
-- and hanging open onto the dark.
local function stairCore(m, rng)
	local c = model(m, "EmergencyStair")
	local grey = Color3.fromRGB(150, 146, 136)
	local y0 = floorY(LOWEST_OPEN)
	local laneA, laneB = { CORE.x0 + 1, CORE.x0 + 7.5 }, { CORE.x0 + 9.5, CORE.x1 }
	local south, north = { CORE.z0 + 0.6, CORE.z0 + 4 }, { CORE.z1 - 4.4, CORE.z1 }
	-- The wall on the core's west side, the whole height.
	box(c, "CoreWall", CORE.x0 - 0.4, CORE.x0 + 0.4, y0, ROOF + 9, CORE.z0, Z1, Concrete, grey)
	-- The south wall floor by floor, each piece with its own doorway (one
	-- strip can't hold doorways stacked above each other).
	for f = LOWEST_OPEN, TOP_FLOOR + 1 do
		local y = floorY(f)
		local top = if f == TOP_FLOOR + 1 then ROOF + 9 else y + floorH(f)
		BuildUtil.strip(c, { name = "CoreWall", axis = "X", fixed = CORE.z0, spanStart = CORE.x0 - 0.4, spanEnd = X1, bottom = y, top = top, thickness = 0.8, openings = { { center = CORE_DOOR_X, width = 4, bottom = y, top = y + 8 } }, material = Concrete, color = grey })
	end
	-- Above the roof the core is the stair house.
	box(c, "StairHouse", CORE.x0, X1 + 0.6, ROOF, ROOF + 9, Z1 - 0.6, Z1 + 0.6, Concrete, FACADE)
	box(c, "StairHouse", X1 - 0.6, X1 + 0.6, ROOF, ROOF + 9, CORE.z0, Z1, Concrete, FACADE)
	box(c, "StairHouseRoof", CORE.x0 - 1, X1 + 1, ROOF + 9, ROOF + 9.6, CORE.z0 - 1, Z1 + 1, Concrete, darken(FACADE, 0.8))
	-- The last landing, at roof level.
	box(c, "Landing", CORE.x0 + 0.4, CORE.x1, ROOF - 0.8, ROOF, south[1], south[2], Concrete, grey)
	for f = LOWEST_OPEN, TOP_FLOOR do
		local y, h = floorY(f), floorH(f)
		local half = h / 2
		box(c, "Landing", CORE.x0 + 0.4, CORE.x1, y - 0.8, y, south[1], south[2], Concrete, grey)
		box(c, "Landing", CORE.x0 + 0.4, CORE.x1, y + half - 0.8, y + half, north[1], north[2], Concrete, grey)
		local steps = math.ceil(half / 0.75)
		local run = (north[1] - south[2]) / steps
		for i = 1, steps do
			local topA = y + i * half / steps
			box(c, "StairStep", laneA[1], laneA[2], topA - 0.8, topA, south[2] + (i - 1) * run, south[2] + i * run + 0.02, Concrete, grey)
			local topB = y + half + i * half / steps
			box(c, "StairStep", laneB[1], laneB[2], topB - 0.8, topB, north[1] - i * run - 0.02, north[1] - (i - 1) * run, Concrete, grey)
		end
		rod(c, "StairRail", Vector3.new(laneA[2] + 0.4, y + 3, south[2]), Vector3.new(laneA[2] + 0.4, y + half + 3, north[1]), 0.2, Metal, STEEL)
		rod(c, "StairRail", Vector3.new(laneB[1] - 0.4, y + half + 3, north[1]), Vector3.new(laneB[1] - 0.4, y + h + 3, south[2]), 0.2, Metal, STEEL)
		label(c, CFrame.new(CORE_DOOR_X + 6, y + 5.5, CORE.z0 + 0.45), Vector3.new(3, 1.8, 0.1), Enum.NormalId.Back, string.format("%dF", f), if OPEN[f] then Color3.fromRGB(40, 140, 70) else Color3.fromRGB(226, 222, 206), if OPEN[f] then Color3.fromRGB(236, 250, 236) else Color3.fromRGB(40, 40, 44))
		if rng:NextNumber() < 0.6 then
			local lamp = part(c, "StairLamp", Vector3.new(1.2, 0.4, 0.3), Vector3.new(CORE.x0 + 9, y + 7.5, CORE.z0 + 0.55), Neon, Color3.fromRGB(240, 236, 214))
			lamp.CanCollide = false
			local light = Instance.new("PointLight")
			light.Range = 14
			light.Brightness = 0.8
			light.Color = Color3.fromRGB(240, 230, 200)
			light.Parent = lamp
			if rng:NextNumber() < 0.25 then
				lamp:AddTag("FlickerLight")
			end
		end
		if not OPEN[f] then
			local doorCF = CFrame.new(CORE_DOOR_X, y + 4, CORE.z0)
			if rng:NextNumber() < 0.2 then
				part(c, "ForcedDoor", Vector3.new(4, 7.8, 0.25), doorCF * CFrame.new(-2, 0, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(60, 100)), 0) * CFrame.new(2, 0, 0), Metal, Color3.fromRGB(110, 112, 108))
			else
				part(c, "SealedDoor", Vector3.new(4, 7.8, 0.25), doorCF, Metal, Color3.fromRGB(110, 112, 108))
				for k = 0, 1 do
					part(c, "DoorBoard", Vector3.new(5, 0.6, 0.2), doorCF * CFrame.new(0, -1 + k * 2.5, 0.25) * CFrame.Angles(0, 0, math.rad(if k == 0 then 18 else -18)), Wood, jitter(Color3.fromRGB(130, 104, 74), rng, 0.1))
				end
				label(c, doorCF * CFrame.new(0, 2.4, 0.4), Vector3.new(2.4, 0.8, 0.05), Enum.NormalId.Back, "閉鎖", Color3.fromRGB(200, 40, 34), Color3.fromRGB(240, 236, 226))
			end
		else
			label(c, CFrame.new(CORE_DOOR_X, y + 9.2, CORE.z0 - 0.45), Vector3.new(5, 1, 0.1), Enum.NormalId.Front, "非常階段", Color3.fromRGB(40, 140, 70), Color3.fromRGB(236, 250, 236))
		end
	end
end

-- ===== The bridge =====

-- Thrown together from whatever was to hand: two steel beams, a deck of
-- mismatched planks and an old door, scaffold-tube posts with cable for a
-- handrail, stays from a post bolted to the store's wall, sandbags at the
-- rooftop end.
-- Thin stuff you should be able to walk through (cables, ropes, bunting).
local function thin(p)
	if p then
		p.CanCollide = false
	end
	return p
end

-- A rope or cable sagging from a to b, in `n` pieces.
local function sagging(parent, name, a, b, sag, n, diameter, material, color)
	local points = {}
	local prev = a
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		thin(rod(parent, name, prev, p, diameter, material, color))
		table.insert(points, p)
		prev = p
	end
	return points
end

local function trolley(parent, cf, rng)
	local t = model(parent, "ShoppingTrolley")
	local wire = Color3.fromRGB(180, 182, 186)
	local basket = part(t, "TrolleyBasket", Vector3.new(1.8, 1.4, 2.6), cf * CFrame.new(0, 2, 0), Metal, wire)
	basket.Transparency = 0.6
	part(t, "TrolleyBase", Vector3.new(1.4, 0.15, 2.2), cf * CFrame.new(0, 0.9, 0.1), Metal, wire)
	thin(rod(t, "TrolleyHandle", (cf * CFrame.new(-0.9, 2.9, 1.5)).Position, (cf * CFrame.new(0.9, 2.9, 1.5)).Position, 0.15, Plastic, Color3.fromRGB(200, 40, 40)))
	for _, sx in ipairs({ -0.6, 0.6 }) do
		for _, sz in ipairs({ -1, 1 }) do
			thin(rod(t, "TrolleyLeg", (cf * CFrame.new(sx, 1.3, sz)).Position, (cf * CFrame.new(sx, 0.35, sz)).Position, 0.1, Metal, wire))
			cylinder(t, "TrolleyWheel", 0.15, 0.5, cf * CFrame.new(sx, 0.25, sz), Enum.Material.Rubber, DARK)
		end
	end
	return t
end

-- The bridge from the rooftop's plant block to the smashed 16F window:
-- somebody's suspension bridge of scavenged stuff. A scaffold tower on
-- the rooftop and two masts bolted to the store's facade carry sagging
-- main cables; hangers drop from them to a deck of steel beams and
-- planks patched with an old door, a pallet and a sheet of roofing. Rope
-- handrails, bunting, paper lanterns, a tarp windbreak, an abandoned
-- trolley, signs at each end. Everything thin (cables, ropes, bunting)
-- can be walked through.
local function bridge(parent, rng)
	local b = model(parent, "StoreBridge")
	local B = Rooftop.BRIDGE
	local wallZ = Z0 + DZ
	local startP = Vector3.new(B.x, B.top, B.z - 2)
	local endP = Vector3.new(B.x, floorY(BRIDGE_FLOOR), wallZ + 1)
	local dir = (endP - startP).Unit
	local len = (endP - startP).Magnitude
	local frame = CFrame.lookAt(startP, endP)
	local right = frame.RightVector
	local back = Vector3.new(-dir.X, 0, -dir.Z).Unit
	local rust = Color3.fromRGB(116, 76, 48)
	local steel = Color3.fromRGB(120, 122, 124)
	local cableColor = Color3.fromRGB(56, 56, 58)
	local rope = Color3.fromRGB(150, 130, 96)
	local Corroded = Enum.Material.CorrodedMetal

	-- The deck.
	for _, s in ipairs({ -2.4, 2.4 }) do
		part(b, "BridgeBeam", Vector3.new(0.6, 1.2, len + 1), frame * CFrame.new(s, -0.8, -len / 2), Corroded, rust)
	end
	for k = 1, 10 do
		part(b, "CrossBeam", Vector3.new(5.4, 0.4, 0.4), frame * CFrame.new(0, -1.25, -len * k / 11), Corroded, rust)
	end
	local d = 0.6
	local patched = {}
	while d < len - 0.6 do
		local roll = rng:NextNumber()
		local middle = d > 8 and d < len - 10
		if middle and roll < 0.06 and not patched.door then
			patched.door = true
			part(b, "DoorPlank", Vector3.new(5.6, 0.3, 3.4), frame * CFrame.new(0, -0.1, -(d + 1.7)), Wood, Color3.fromRGB(150, 118, 80))
			thin(part(b, "DoorWindow", Vector3.new(1.2, 0.05, 1.6), frame * CFrame.new(1.4, 0.07, -(d + 1.7)), Glass, Color3.fromRGB(150, 170, 176)))
			d += 3.5
		elseif middle and roll < 0.12 and not patched.pallet then
			patched.pallet = true
			for k = 0, 4 do
				part(b, "PalletSlat", Vector3.new(5.6, 0.25, 0.5), frame * CFrame.new(0, -0.12, -(d + 0.35 + k * 0.75)), Wood, Color3.fromRGB(170, 140, 96))
			end
			d += 3.8
		elseif middle and roll < 0.17 and not patched.sheet then
			patched.sheet = true
			part(b, "RoofingSheet", Vector3.new(5.8, 0.12, 4), frame * CFrame.new(0, -0.05, -(d + 2)) * CFrame.Angles(0, math.rad(rng:NextNumber(-3, 3)), 0), Corroded, Color3.fromRGB(130, 120, 100))
			d += 4.1
		else
			local w = rng:NextNumber(0.8, 1.4)
			local warp = if rng:NextNumber() < 0.06 then CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), 0, 0) else CFrame.identity
			part(b, "BridgePlank", Vector3.new(rng:NextNumber(5.2, 6.4), 0.25, w - 0.1), frame * CFrame.new(rng:NextNumber(-0.3, 0.3), -0.12, -(d + w / 2)) * CFrame.Angles(0, math.rad(rng:NextNumber(-4, 4)), 0) * warp, Wood, jitter(Color3.fromRGB(130, 104, 74), rng, 0.15))
			d += w
		end
	end

	-- The rooftop tower: a scaffold of tubes straddling the bridge's start,
	-- held back by stays to concrete blocks.
	local towerH = 20
	local feet = {}
	for _, s in ipairs({ -3.4, 3.4 }) do
		for _, bk in ipairs({ 0, 3 }) do
			local f = startP + right * s + back * bk
			table.insert(feet, f)
			rod(b, "ScaffoldTube", f, f + Vector3.new(0, towerH, 0), 0.35, Metal, steel)
			part(b, "ScaffoldFoot", Vector3.new(0.9, 0.2, 0.9), f + Vector3.new(0, 0.1, 0), Metal, DARK)
		end
	end
	for _, y in ipairs({ 6.5, 13, 19.5 }) do
		local up = Vector3.new(0, y, 0)
		for _, pair in ipairs({ { 1, 2 }, { 3, 4 }, { 1, 3 }, { 2, 4 } }) do
			thin(rod(b, "ScaffoldLedger", feet[pair[1]] + up, feet[pair[2]] + up, 0.25, Metal, steel))
		end
	end
	for _, pair in ipairs({ { 1, 2 }, { 3, 4 } }) do
		thin(rod(b, "ScaffoldBrace", feet[pair[1]] + Vector3.new(0, 0.5, 0), feet[pair[2]] + Vector3.new(0, 13, 0), 0.2, Metal, steel))
	end
	local towerTop = {}
	for i, s in ipairs({ -3.4, 3.4 }) do
		towerTop[i] = startP + right * s + Vector3.new(0, towerH, 0)
		local anchor = startP + right * s * 1.3 + back * 11
		part(b, "StayBlock", Vector3.new(2, 1.4, 2), anchor + Vector3.new(0, 0.7, 0), Concrete, Color3.fromRGB(150, 146, 136))
		thin(rod(b, "Backstay", towerTop[i], anchor + Vector3.new(0, 1.4, 0), 0.14, Metal, cableColor))
	end
	label(b, CFrame.new(startP + right * 3.4 + back * 1.5 + Vector3.new(0, 8, 0)) * CFrame.Angles(0, math.rad(180), 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-5, 5))), Vector3.new(2.6, 1.8, 0.1), Enum.NormalId.Front, "キケン\n一人ずつ", Color3.fromRGB(240, 200, 40), Color3.fromRGB(30, 26, 22), Wood, Enum.Font.IndieFlower)

	-- Masts bolted up the store's facade either side of the window.
	local mastTop = {}
	for i, s in ipairs({ -3.4, 3.4 }) do
		local foot = Vector3.new(B.x + s, endP.Y - 2, wallZ - 0.9)
		mastTop[i] = foot + Vector3.new(0, 24, 0)
		rod(b, "StoreMast", foot, mastTop[i], 0.6, Metal, steel)
		for _, h in ipairs({ 3, 12, 21 }) do
			thin(rod(b, "MastBracket", foot + Vector3.new(0, h, 0), foot + Vector3.new(0, h, 0.7), 0.3, Metal, rust))
		end
	end

	-- Main cables, sagging to just above the handrails, hangers down to
	-- the deck, bunting along one of them, lanterns on the other.
	local n = 16
	local colors = { Color3.fromRGB(200, 50, 50), Color3.fromRGB(240, 200, 60), Color3.fromRGB(60, 120, 200), Color3.fromRGB(80, 160, 90), Color3.fromRGB(240, 236, 226) }
	local lanternLights = 2
	for i, s in ipairs({ -3.4, 3.4 }) do
		local a, c = towerTop[i], mastTop[i]
		local sag = (a.Y + c.Y) / 2 - ((startP.Y + endP.Y) / 2 + 5)
		local points = sagging(b, "MainCable", a, c, sag, n, 0.25, Metal, cableColor)
		for k = 1, n - 1 do
			local p = points[k]
			local deck = startP:Lerp(endP, k / n) + right * (s * 0.75) - Vector3.new(0, 0.3, 0)
			thin(rod(b, "Hanger", p, deck, 0.08, Metal, cableColor))
			if i == 1 and k % 2 == 0 then
				local q = points[k]:Lerp(points[k + 1], 0.5)
				local flag = part(b, "Bunting", Vector3.new(0.9, 0.9, 0.05), CFrame.lookAt(q, q + right) * CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, math.rad(45)), Fabric, pick(colors, rng))
				thin(flag)
			end
			if i == 2 and k % 3 == 0 then
				local lit = rng:NextNumber() < 0.6
				local lantern = ellipsoid(b, "Lantern", Vector3.new(1, 1.3, 1), CFrame.new(p - Vector3.new(0, 1.6, 0)), if lit then Neon else Fabric, if lit then Color3.fromRGB(230, 90, 60) else Color3.fromRGB(190, 60, 50))
				thin(lantern)
				thin(rod(b, "LanternCord", p, p - Vector3.new(0, 0.9, 0), 0.05, Fabric, DARK))
				if lit and lanternLights > 0 then
					lanternLights -= 1
					local light = Instance.new("PointLight")
					light.Range = 14
					light.Brightness = 0.8
					light.Color = Color3.fromRGB(255, 170, 120)
					light.Parent = lantern
				end
			end
		end
	end

	-- Posts, rope handrails, a tarp lashed along part of one side.
	local posts = 9
	local postAt = {}
	for k = 0, posts - 1 do
		local p = startP + dir * (len * k / (posts - 1))
		postAt[k] = p
		for _, s in ipairs({ -2.8, 2.8 }) do
			local q = p + right * s
			rod(b, "BridgePost", q - Vector3.new(0, 0.5, 0), q + Vector3.new(0, 3.6, 0), 0.25, Metal, steel)
			if rng:NextNumber() < 0.2 then
				thin(part(b, "Rag", Vector3.new(0.4, 0.9, 0.05), CFrame.new(q + Vector3.new(0, 3.1, 0)), Fabric, pick(colors, rng)))
			end
		end
	end
	for k = 0, posts - 2 do
		for _, s in ipairs({ -2.8, 2.8 }) do
			for _, y in ipairs({ 1.8, 3.5 }) do
				local off = right * s + Vector3.new(0, y, 0)
				sagging(b, "RopeRail", postAt[k] + off, postAt[k + 1] + off, 0.35, 3, 0.12, Fabric, rope)
			end
		end
	end
	local t0, t1 = 3, 5
	local tarpA, tarpB = postAt[t0] + right * 2.9, postAt[t1] + right * 2.9
	local tarp = part(b, "Tarp", Vector3.new(0.05, 3, (tarpB - tarpA).Magnitude), CFrame.lookAt((tarpA + tarpB) / 2 + Vector3.new(0, 1.9, 0), tarpB + Vector3.new(0, 1.9, 0)), Fabric, Color3.fromRGB(50, 90, 150))
	thin(tarp)

	-- Somebody's trolley, abandoned halfway.
	trolley(b, frame * CFrame.new(-1.3, 0, -len * 0.62) * CFrame.Angles(0, math.rad(rng:NextNumber(-40, 40)), 0), rng)

	-- Sandbags and a hand-painted sign at the rooftop end.
	for k = 0, 5 do
		local bag = ellipsoid(b, "Sandbag", Vector3.new(2, 0.8, 1.2), CFrame.new(startP + right * (if k % 2 == 0 then -3.9 else 3.9) + Vector3.new(0, 0.4 + math.floor(k / 2) * 0.7, rng:NextNumber(-0.5, 0.5))), Fabric, jitter(Color3.fromRGB(170, 150, 110), rng, 0.08))
		bag.CanCollide = true
	end
	local board = label(b, CFrame.new(startP + right * 3.6 + Vector3.new(0, 3.4, 0)) * CFrame.Angles(0, math.rad(180), math.rad(rng:NextNumber(-6, 6))), Vector3.new(3.4, 1.4, 0.15), Enum.NormalId.Front, "月光 →", Color3.fromRGB(150, 118, 80), Color3.fromRGB(30, 26, 22), Wood, Enum.Font.IndieFlower)
	board.CanCollide = false
	-- Painted on the facade over the way in.
	label(b, CFrame.new(B.x, endP.Y + 13.5, wallZ - 0.65), Vector3.new(6, 1.6, 0.05), Enum.NormalId.Front, "16F 入口", Color3.fromRGB(196, 184, 160), Color3.fromRGB(160, 30, 30), Smooth, Enum.Font.IndieFlower)
	-- Broken glass around the smashed window.
	for _ = 1, 10 do
		local shard = part(b, "GlassShard", Vector3.new(rng:NextNumber(0.3, 1.2), 0.05, rng:NextNumber(0.3, 1)), CFrame.new(B.x + rng:NextNumber(-5, 5), endP.Y + 0.05, wallZ + rng:NextNumber(1, 6)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Glass, Color3.fromRGB(150, 170, 176))
		shard.Transparency = 0.4
		shard.CanCollide = false
	end
end

-- The way in from the tunnels: a pipe bridge from a cave mouth in the
-- crag's north face across the drop to a hole knocked through the 9F
-- wall. Steel grating between channel stringers, tube handrails, two
-- big pipes running alongside on brackets, hung from cables anchored in
-- the rock and the facade, work lamps, a gate left open, a sign.
local function tunnelLink(parent, rng)
	local b = model(parent, "TunnelLink")
	local L = DepartmentStore.LINK
	local wallZ = Z0 + DZ
	local y = floorY(LINK_FLOOR)
	local startP = Vector3.new(LINK_X, math.floor(y / 4) * 4, L.mouthZ - 8)
	local endP = Vector3.new(LINK_X, y, wallZ + 1)
	local dir = (endP - startP).Unit
	local len = (endP - startP).Magnitude
	local frame = CFrame.lookAt(startP, endP)
	local right = frame.RightVector
	local steel = Color3.fromRGB(96, 98, 100)
	local rust = Color3.fromRGB(116, 76, 48)
	local yellow = Color3.fromRGB(220, 180, 40)
	local Corroded = Enum.Material.CorrodedMetal
	-- Grating in sections, one of them buckled.
	local sections = math.ceil(len / 6)
	local buckled = rng:NextInteger(3, sections - 2)
	for k = 0, sections - 1 do
		local a, c = k * len / sections, (k + 1) * len / sections
		local cf = frame * CFrame.new(0, -0.15, -(a + c) / 2)
		if k == buckled then
			cf = cf * CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, math.rad(rng:NextNumber(-5, 5)))
		end
		part(b, "Grating", Vector3.new(4.4, 0.3, c - a - 0.06), cf, Enum.Material.DiamondPlate, jitter(Color3.fromRGB(90, 92, 94), rng, 0.05))
	end
	for _, s in ipairs({ -2.4, 2.4 }) do
		part(b, "Stringer", Vector3.new(0.4, 1, len + 2), frame * CFrame.new(s, -0.6, -len / 2), Corroded, rust)
	end
	-- Handrails.
	local posts = math.floor(len / 5)
	local postAt = {}
	-- (The east rail, s = -2.3, stops where the 9F boardwalk begins.)
	local eastStop = len - (wallZ - L.boardwalkZ)
	for k = 0, posts do
		postAt[k] = startP + dir * (len * k / posts)
		for _, s in ipairs({ -2.3, 2.3 }) do
			if s > 0 or len * k / posts <= eastStop + 0.1 then
				local q = postAt[k] + right * s
				rod(b, "RailPost", q, q + Vector3.new(0, 3.4, 0), 0.2, Metal, yellow)
			end
		end
	end
	for _, s in ipairs({ -2.3, 2.3 }) do
		for _, h in ipairs({ 1.7, 3.4 }) do
			local off = right * s + Vector3.new(0, h, 0)
			rod(b, "HandRail", startP + off, (if s > 0 then endP else startP + dir * eastStop) + off, 0.18, Metal, yellow)
		end
	end
	-- The pipes, on brackets off the right-hand stringer, into the rock
	-- at one end and through the wall at the other.
	for _, pipe in ipairs({ { d = 2.2, up = -0.6, out = 4.2, color = Color3.fromRGB(70, 90, 110) }, { d = 1.4, up = 1.6, out = 4, color = Color3.fromRGB(150, 60, 40) } }) do
		local a = startP - dir * 6 + right * pipe.out + Vector3.new(0, pipe.up, 0)
		local c = endP + dir * 2 + right * pipe.out + Vector3.new(0, pipe.up, 0)
		rod(b, "Pipe", a, c, pipe.d, Corroded, pipe.color)
		local plen = (c - a).Magnitude
		for dd = 6, plen - 4, 8 do
			local p = a + (c - a).Unit * dd
			rod(b, "PipeFlange", p - dir * 0.25, p + dir * 0.25, pipe.d + 0.4, Metal, darken(pipe.color, 0.8))
		end
	end
	for k = 1, posts - 1, 2 do
		local p = postAt[k]
		thin(rod(b, "PipeBracket", p + right * 2.4 - Vector3.new(0, 0.9, 0), p + right * 4.4 - Vector3.new(0, 0.9, 0), 0.25, Metal, steel))
	end
	local valve = startP + dir * len * 0.4 + right * 4 + Vector3.new(0, 2.8, 0)
	thin(rod(b, "ValveStem", valve - Vector3.new(0, 0.5, 0), valve, 0.2, Metal, steel))
	thin(cylinder(b, "ValveWheel", 0.15, 1.2, CFrame.new(valve) * CFrame.Angles(0, 0, math.rad(90)), Metal, Color3.fromRGB(200, 40, 30)))
	-- Hung from cables anchored up in the rock and on the facade.
	for _, s in ipairs({ -2.4, 2.4 }) do
		local rock = Vector3.new(LINK_X + s * 1.4, startP.Y + 18, L.mouthZ - 6)
		local wall = Vector3.new(LINK_X + s * 1.4, y + 16, wallZ - 0.8)
		part(b, "AnchorPlate", Vector3.new(1.2, 1.2, 0.3), wall, Metal, steel)
		for _, t in ipairs({ 0.33, 0.66 }) do
			local deck = startP:Lerp(endP, t) + right * s - Vector3.new(0, 0.6, 0)
			thin(rod(b, "HangCable", if t < 0.5 then rock else wall, deck, 0.12, Metal, Color3.fromRGB(56, 56, 58)))
		end
	end
	-- Struts from below at each end.
	for _, s in ipairs({ -2.4, 2.4 }) do
		rod(b, "Strut", Vector3.new(LINK_X + s, startP.Y - 12, L.mouthZ - 4), startP + dir * 9 + right * s - Vector3.new(0, 1, 0), 0.6, Corroded, rust)
		rod(b, "Strut", Vector3.new(LINK_X + s, y - 11, wallZ - 0.8), endP - dir * 10 + right * s - Vector3.new(0, 1, 0), 0.6, Corroded, rust)
	end
	-- Work lamps on two posts.
	for _, k in ipairs({ math.floor(posts * 0.3), math.floor(posts * 0.75) }) do
		local q = postAt[k] + right * 2.3 + Vector3.new(0, 3.4, 0)
		thin(rod(b, "LampArm", q, q + Vector3.new(0, 1.6, 0) - right * 0.8, 0.12, Metal, steel))
		local lamp = part(b, "WorkLamp", Vector3.new(0.6, 0.8, 0.6), CFrame.new(q + Vector3.new(0, 1.3, 0) - right * 0.9), Neon, Color3.fromRGB(250, 226, 170))
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 18
		light.Brightness = 1
		light.Color = Color3.fromRGB(250, 226, 170)
		light.Parent = lamp
		if rng:NextNumber() < 0.4 then
			lamp:AddTag("FlickerLight")
		end
	end
	-- A mesh gate at the tunnel end, left swung open; a sign.
	local hinge = startP + right * -2.3
	local gate = part(b, "Gate", Vector3.new(0.1, 3.4, 4.4), CFrame.new(hinge + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, math.rad(100), 0) * CFrame.new(0, 0, -2.2), Metal, Color3.fromRGB(150, 152, 150))
	gate.Transparency = 0.6
	label(b, CFrame.new(startP + right * 2.3 + dir * 1.5 + Vector3.new(0, 4.4, 0)) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(3.6, 1.2, 0.1), Enum.NormalId.Front, "連絡通路 → 月光百貨店 9F", Color3.fromRGB(40, 140, 70), Color3.fromRGB(236, 250, 236))
	-- The hole knocked through the wall: broken concrete round it.
	for _ = 1, 8 do
		local s = Vector3.new(rng:NextNumber(0.6, 1.8), rng:NextNumber(0.4, 1.2), rng:NextNumber(0.6, 1.6))
		part(b, "Rubble", s, CFrame.new(LINK_X + pick({ -1, 1 }, rng) * rng:NextNumber(2.6, 4.5), y + s.Y / 2, wallZ + rng:NextNumber(1, 4)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)), Concrete, jitter(FACADE, rng, 0.1))
	end
end
function DepartmentStore.build(parent, rng)
	local m = model(parent, "DepartmentStore")
	shell(m, rng)
	task.wait()
	-- Escalators up the atrium from each open floor to the next: they
	-- leave every floor on lane A and arrive on lane B, both at the east
	-- edge.
	for k = 1, #OPEN_FLOORS - 1 do
		escalatorPair(m, OPEN_FLOORS[k], OPEN_FLOORS[k + 1], rng)
	end
	for k, f in ipairs(OPEN_FLOORS) do
		local gaps = {}
		if k > 1 then
			table.insert(gaps, { x = HOLE.x1, z = BAND_B })
		end
		if k < #OPEN_FLOORS then
			table.insert(gaps, { x = HOLE.x1, z = BAND_A })
		end
		if f ~= LOWEST_OPEN then
			atriumRail(m, f, gaps)
		end
	end
	-- On the lowest open floor the way down is shuttered off.
	local yLow = floorY(LOWEST_OPEN)
	local sx = HOLE.x0 + 8
	for k = 0, 9 do
		box(m, "Shutter", sx - 0.15, sx + 0.15, yLow, yLow + 7, BAND_B - 3 + k * 0.6, BAND_B - 2.7 + k * 0.6, Metal, Color3.fromRGB(120, 122, 116))
	end
	box(m, "ShutterRail", sx - 0.4, sx + 0.4, yLow + 7, yLow + 7.6, BAND_B - 3.2, BAND_B + 3.2, Metal, DARK)
	label(m, CFrame.new(sx - 0.3, yLow + 5, BAND_B), Vector3.new(0.1, 1.4, 4.4), Enum.NormalId.Left, "3F以下 閉鎖", Color3.fromRGB(200, 40, 34), Color3.fromRGB(240, 236, 226))
	for _, f in ipairs(OPEN_FLOORS) do
		ceilingLights(m, f, rng)
		furnish(m, f, rng)
		task.wait()
	end
	stairCore(m, rng)
	RoofPark.build(m, { ROOF = ROOF, X0 = X0, X1 = X1, Z0 = Z0, Z1 = Z1, HOLE = HOLE, CORE = CORE, CORE_DOOR_X = CORE_DOOR_X }, rng)
	task.wait()
	m:PivotTo(m:GetPivot() + Vector3.new(0, 0, DZ))
	bridge(parent, rng)
	tunnelLink(parent, rng)
	task.wait()
	local B = Rooftop.BRIDGE
	Shacks.build(parent, {
		wallZ = Z0 + DZ,
		X0 = X0,
		bridgeX = B.x,
		bridgeY = floorY(BRIDGE_FLOOR),
		linkX = LINK_X,
		linkY = floorY(LINK_FLOOR),
		westY = floorY(WAY_INS[1].floor),
		westDoorZ = WAY_INS[1].at + DZ,
		wayIns = (function()
			local list = {}
			for i = 2, #WAY_INS do
				local w = WAY_INS[i]
				local along = if w.face == "south" or w.face == "north" then w.at else w.at + DZ
				table.insert(list, { face = w.face, y = floorY(w.floor), at = along, kind = w.kind })
			end
			return list
		end)(),
		faces = { south = Z0 + DZ, north = Z1 + DZ, west = X0, east = X1 },
		bridgeTower = Vector3.new(B.x + 3.4, B.top + 19.5, B.z - 2),
		bridgeMasts = { Vector3.new(B.x - 3.4, floorY(BRIDGE_FLOOR) + 12, Z0 + DZ - 0.9), Vector3.new(B.x + 3.4, floorY(BRIDGE_FLOOR) + 12, Z0 + DZ - 0.9) },
		cragAnchor = Vector3.new(LINK_X + 6, floorY(LINK_FLOOR) + 14, DepartmentStore.LINK.mouthZ - 6),
		cornerSign = Vector3.new(X0 - 3, floorY(21) + 20, Z0 + DZ + 7),
		roof = ROOF,
	}, rng)
end

return DepartmentStore
