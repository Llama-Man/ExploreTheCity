-- A rusted Japanese fishing trawler run aground on the rooftop, bow hanging
-- out over the drop and its anchor chain dangling into the haze. It's the
-- centrepiece of the rooftop and can be explored:
--
--   * the stern transom is torn open at hold level, leading into the
--     engine room;
--   * the engine room connects forward through a bulkhead door to the fish
--     hold, open to the sky through two cargo hatches (with ladders);
--   * a between-deck ("tween deck") runs above the hold, with crew bunks
--     aft, a breach in the side, and the chain locker up in the bow, where
--     a second breach looks straight down into the void;
--   * stairs climb from the tween deck up into a three-storey deckhouse:
--     mess and galley, crew cabins, and the bridge.
--
-- Built in local space (keel at y = 0, bow toward +X, centred on the
-- origin) and then pivoted into place as one model.

local BuildUtil = require(script.Parent.BuildUtil)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Rust, Metal, Smooth, Wood, Fabric = Enum.Material.CorrodedMetal, Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.Fabric

local L, B, D = 280, 52, 34 -- length, beam, hull depth
local SLICES = 28
local SLICE = L / SLICES
local WATERLINE = 11
local HOLD_Y, TWEEN_Y = 2, 15 -- floor tops inside the hull
local HOUSE_X0, HOUSE_X1, HOUSE_HALF = -128, -84, 18
local LEVEL_H = 10.4
local GANGWAY_X = 20 -- where the gangway meets the deck on the -Z side

local ANTIFOUL = Color3.fromRGB(116, 46, 36)
local HULL = Color3.fromRGB(62, 70, 76)
local INSIDE = Color3.fromRGB(84, 80, 72)
local DECK_COLOR = Color3.fromRGB(86, 78, 66)
local HOUSE = Color3.fromRGB(196, 190, 176)
local RUST = Color3.fromRGB(120, 72, 40)
local DARK = Color3.fromRGB(18, 18, 20)
local GLASS = Color3.fromRGB(150, 164, 160)
local function deco(p)
	if p then
		p.CanCollide = false
		p.CastShadow = false
	end
	return p
end
local PEELED = Color3.fromRGB(96, 104, 104) -- where the paint's come away

-- Holes cut through the decks. All x edges sit on slice boundaries.
local MAIN_HOLES = {
	{ x0 = -60, x1 = -40, z0 = -10, z1 = 10, hatch = true },
	{ x0 = 10, x1 = 30, z0 = -10, z1 = 10, hatch = true },
	{ x0 = -120, x1 = -90, z0 = 6, z1 = 12 }, -- stairs from the deckhouse down
}
local TWEEN_HOLES = {
	{ x0 = -60, x1 = -40, z0 = -10, z1 = 10 },
	{ x0 = 10, x1 = 30, z0 = -10, z1 = 10 },
	{ x0 = -120, x1 = -100, z0 = -14, z1 = -8 }, -- stairs down into the engine room
}
-- Openings torn in the side plating: {slice, side, bottom, top}.
local BREACHES = {
	{ 13, 1, TWEEN_Y, TWEEN_Y + 9 },
	{ 14, 1, TWEEN_Y, TWEEN_Y + 9 },
	{ 25, -1, TWEEN_Y, TWEEN_Y + 8 },
}

local Ship = {}

-- Hull width as a fraction of the beam along the length (u: 0 stern, 1 bow).
local function beamAt(u)
	if u > 0.75 then
		return 0.05 + 0.95 * math.cos((u - 0.75) / 0.25 * math.pi / 2) ^ 0.6
	elseif u < 0.08 then
		return 0.85 + 0.15 * u / 0.08
	end
	return 1
end

-- The keel sweeps up toward the bow.
local function keelAt(u)
	if u > 0.7 then
		return D * 0.55 * ((u - 0.7) / 0.3) ^ 1.5
	end
	return 0
end

local function slice(i)
	local x0 = -L / 2 + (i - 1) * SLICE
	local u = (i - 0.5) / SLICES
	return x0, x0 + SLICE, B * beamAt(u), keelAt(u)
end

local function beamAtX(x)
	return B * beamAt(math.clamp((x + L / 2) / L, 0, 1))
end

local function box(m, name, x0, x1, y0, y1, z0, z1, material, color)
	return part(m, name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), material, color)
end

-- Splits [lo, hi] around a set of {a, b} cuts and calls fn for each piece.
local function spans(lo, hi, cuts, fn)
	table.sort(cuts, function(p, q)
		return p[1] < q[1]
	end)
	local cursor = lo
	for _, c in ipairs(cuts) do
		if c[1] > cursor + 0.05 then
			fn(cursor, math.min(c[1], hi))
		end
		cursor = math.max(cursor, c[2])
	end
	if hi > cursor + 0.05 then
		fn(cursor, hi)
	end
end

-- A deck plate across every slice where `include(i, keel)` is true, with
-- rectangular holes cut out.
local function deckLevel(m, name, y, holes, color, include)
	for i = 1, SLICES do
		local x0, x1, w, kb = slice(i)
		if include(i, kb) then
			local cuts = {}
			for _, h in ipairs(holes) do
				if h.x0 < x1 - 0.01 and h.x1 > x0 + 0.01 then
					table.insert(cuts, { h.z0, h.z1 })
				end
			end
			spans(-w / 2 + 0.8, w / 2 - 0.8, cuts, function(za, zb)
				box(m, name, x0, x1 + 0.05, y - 0.8, y, za, zb, Rust, color)
			end)
		end
	end
end

-- Straight flight of steps along X from (lowX, lowY) up to (highX, highY).
local function stair(m, lowX, lowY, highX, highY, z0, z1)
	local steps = math.max(1, math.floor((highY - lowY) / 0.8 + 0.5))
	local rise, run = (highY - lowY) / steps, (highX - lowX) / steps
	for i = 1, steps do
		local top = lowY + rise * i
		local xa, xb = lowX + run * (i - 1), lowX + run * i
		box(m, "ShipStep", math.min(xa, xb), math.max(xa, xb), top - rise - 0.6, top, z0, z1, Metal, INSIDE)
	end
end

local function bulb(m, position, flicker)
	local b = part(m, "Bulb", Vector3.new(0.6, 0.6, 0.6), position, Enum.Material.Neon, Color3.fromRGB(255, 226, 170))
	b.Shape = Enum.PartType.Ball
	b.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 0.9
	light.Color = Color3.fromRGB(255, 214, 160)
	light.Parent = b
	if flicker then
		b:AddTag("FlickerLight")
	end
end

-- ===== Hull =====

local function hull(m, rng)
	for i = 1, SLICES do
		local x0, x1, w, kb = slice(i)
		local xc = (x0 + x1) / 2
		box(m, "HullBottom", x0, x1 + 0.05, kb, kb + 1, -w / 2, w / 2, Rust, jitter(ANTIFOUL, rng, 0.08))

		local u0, u1 = (i - 1) / SLICES, i / SLICES
		local w0, w1 = B * beamAt(u0), B * beamAt(u1)
		for _, side in ipairs({ -1, 1 }) do
			local p0, p1 = Vector3.new(x0, 0, side * (w0 / 2 - 0.5)), Vector3.new(x1, 0, side * (w1 / 2 - 0.5))
			local len = (p1 - p0).Magnitude + 0.12
			local base = CFrame.lookAt((p0 + p1) / 2, p1)
			local function plate(ya, yb, color)
				part(m, "HullPlate", Vector3.new(1, yb - ya, len), base * CFrame.new(0, (ya + yb) / 2, 0), Rust, color)
			end
			local cuts = {}
			for _, br in ipairs(BREACHES) do
				if br[1] == i and br[2] == side then
					table.insert(cuts, { br[3], br[4] })
				end
			end
			local breached = #cuts > 0
			spans(kb, D, cuts, function(ya, yb)
				-- Antifouling red below the waterline, hull grey above.
				if ya < WATERLINE then
					plate(ya, math.min(yb, WATERLINE), jitter(ANTIFOUL, rng, 0.08))
				end
				if yb > WATERLINE then
					plate(math.max(ya, WATERLINE), yb, jitter(if rng:NextNumber() < 0.15 then PEELED else HULL, rng, 0.06))
				end
			end)
			local out = side * 0.55
			-- A black boot-top at the waterline, a rubbing strake along the
			-- deck edge.
			if WATERLINE > kb then
				deco(part(m, "BootTop", Vector3.new(0.12, 1.4, len), base * CFrame.new(out, WATERLINE + 0.4, 0), Smooth, Color3.fromRGB(30, 30, 32)))
			end
			part(m, "RubbingStrake", Vector3.new(1.4, 1.4, len), base * CFrame.new(side * 0.9, D - 1.6, 0), Rust, jitter(RUST, rng, 0.1))
			-- Portholes along the tween deck.
			if i >= 5 and i <= 24 and i % 2 == 0 and not breached then
				deco(cylinder(m, "PortholeRim", 0.25, 2.6, base * CFrame.new(side * 0.6, TWEEN_Y + 5, 0), Metal, Color3.fromRGB(120, 110, 90)))
				deco(cylinder(m, "Porthole", 0.3, 1.9, base * CFrame.new(side * 0.64, TWEEN_Y + 5, 0), Enum.Material.Glass, Color3.fromRGB(30, 36, 40)))
			end
			if rng:NextNumber() < 0.4 then
				local h = rng:NextNumber(6, D - WATERLINE)
				local streak = part(m, "RustStreak", Vector3.new(0.1, h, rng:NextNumber(0.8, 3)), base * CFrame.new(side * 0.56, D - h / 2, rng:NextNumber(-3, 3)), Smooth, RUST)
				streak.Transparency = 0.4
				streak.CanCollide = false
			end
			-- Deck-edge railing, left open where the gangway comes aboard and
			-- at the very bow, where the chain goes out over the stem.
			if not (side == -1 and GANGWAY_X >= x0 and GANGWAY_X < x1) and i < SLICES - 2 then
				part(m, "Rail", Vector3.new(0.3, 0.3, len), base * CFrame.new(0, D + 3.15, 0), Metal, HULL)
				part(m, "RailPost", Vector3.new(0.3, 3, 0.3), base * CFrame.new(0, D + 1.5, 0), Metal, HULL)
			end
		end
	end

	-- Stern transom, torn open at hold level.
	BuildUtil.strip(m, {
		name = "Transom",
		axis = "Z",
		fixed = -L / 2,
		spanStart = -B * 0.425,
		spanEnd = B * 0.425,
		bottom = 0,
		top = D,
		thickness = 1,
		openings = { { center = 0, width = 14, bottom = 1, top = 16 } },
		material = Rust,
		color = HULL,
	})
	cylinder(m, "Stem", D * 0.5, 2, CFrame.new(L / 2 - 0.5, D * 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Rust, HULL)

	-- Decks.
	deckLevel(m, "HoldFloor", HOLD_Y, {}, INSIDE, function(_, kb)
		return kb < HOLD_Y - 1
	end)
	deckLevel(m, "TweenDeck", TWEEN_Y, TWEEN_HOLES, INSIDE, function(_, kb)
		return kb < TWEEN_Y - 2
	end)
	deckLevel(m, "MainDeck", D, MAIN_HOLES, DECK_COLOR, function()
		return true
	end)

	-- Coamings round the cargo hatches.
	for _, h in ipairs(MAIN_HOLES) do
		if h.hatch then
			box(m, "Coaming", h.x0 - 0.5, h.x1 + 0.5, D, D + 2.5, h.z0 - 0.5, h.z0, Rust, jitter(HULL, rng, 0.06))
			box(m, "Coaming", h.x0 - 0.5, h.x1 + 0.5, D, D + 2.5, h.z1, h.z1 + 0.5, Rust, jitter(HULL, rng, 0.06))
			box(m, "Coaming", h.x0 - 0.5, h.x0, D, D + 2.5, h.z0, h.z1, Rust, jitter(HULL, rng, 0.06))
			box(m, "Coaming", h.x1, h.x1 + 0.5, D, D + 2.5, h.z0, h.z1, Rust, jitter(HULL, rng, 0.06))
			-- Ladder from the hold floor up to the deck.
			local ladder = Instance.new("TrussPart")
			ladder.Name = "HatchLadder"
			ladder.Anchored = true
			ladder.Size = Vector3.new(2, D + 2 - HOLD_Y, 2)
			ladder.Position = Vector3.new(h.x0 + 1.2, (HOLD_Y + D + 2) / 2, h.z0 + 1.2)
			ladder.Material = Rust
			ladder.Color = RUST
			ladder.Parent = m
		end
	end

	-- Watertight bulkheads with doors: engine room | hold, hold | forepeak.
	local function bulkhead(x, doors, bottom)
		local w = beamAtX(x)
		BuildUtil.strip(m, {
			name = "Bulkhead",
			axis = "Z",
			fixed = x,
			spanStart = -w / 2 + 0.8,
			spanEnd = w / 2 - 0.8,
			bottom = bottom,
			top = D - 0.8,
			thickness = 0.6,
			openings = doors,
			material = Rust,
			color = INSIDE,
		})
	end
	bulkhead(-90, {
		{ center = 0, width = 6, bottom = HOLD_Y, top = HOLD_Y + 8 },
		{ center = 2, width = 6, bottom = TWEEN_Y, top = TWEEN_Y + 8 },
	}, HOLD_Y - 0.8)
	bulkhead(70, { { center = 0, width = 6, bottom = TWEEN_Y, top = TWEEN_Y + 8 } }, keelAt((70 + L / 2) / L) + 1)

	stair(m, -114, TWEEN_Y, -90, D, 6.5, 11.5)
	stair(m, -116, HOLD_Y, -100, TWEEN_Y, -13.5, -8.5)
end

-- Faded kanji name on both sides of the bow.
local function nameplates(m)
	for _, side in ipairs({ -1, 1 }) do
		local x = -L / 2 + 0.84 * L
		local w = beamAtX(x)
		local plate = part(m, "NamePlate", Vector3.new(30, 6, 0.1), Vector3.new(x, D - 6, side * (w / 2 + 0.06)), Smooth, HULL)
		plate.CanCollide = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = if side == 1 then Enum.NormalId.Back else Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(214, 208, 190)
		label.TextTransparency = 0.25
		label.Text = "第八福丸"
		label.Parent = gui
		gui.Parent = plate
	end
	-- Draft marks up the stem and stern, and her home port on the transom.
	for _, x in ipairs({ -L / 2 + 6, L / 2 - 26 }) do
		for _, side in ipairs({ -1, 1 }) do
			local w = beamAtX(x)
			for k = 0, 3 do
				local mark = part(m, "DraftMark", Vector3.new(1.6, 1.2, 0.05), Vector3.new(x, 3 + k * 3, side * (w / 2 + 0.07)), Smooth, Color3.fromRGB(226, 222, 206))
				mark.CanCollide = false
			end
		end
	end
	local port = part(m, "HomePort", Vector3.new(0.05, 3, 16), Vector3.new(-L / 2 - 0.55, D - 5, 12), Smooth, HULL)
	port.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(214, 208, 190)
	t.TextTransparency = 0.3
	t.Text = "室戸  MUROTO"
	t.Parent = gui
	gui.Parent = port
end

-- ===== Below decks =====

local function engineRoom(m, rng)
	local y = HOLD_Y
	box(m, "EngineBlock", -130, -106, y, y + 7, 1, 11, Metal, Color3.fromRGB(60, 66, 62))
	for k = 0, 5 do
		box(m, "CylinderHead", -128 + k * 3.8, -125.4 + k * 3.8, y + 7, y + 9.5, 3, 9, Metal, Color3.fromRGB(70, 74, 70))
	end
	cylinder(m, "Flywheel", 1.2, 6, CFrame.new(-105, y + 4, 6), Metal, Color3.fromRGB(50, 52, 50))
	cylinder(m, "ExhaustPipe", D - y - 9, 1.8, CFrame.new(-118, (y + 9 + D) / 2, 10) * CFrame.Angles(0, 0, math.rad(90)), Rust, RUST)
	for _, pz in ipairs({ -18, 18 }) do
		cylinder(m, "Pipe", 44, 0.8, CFrame.new(-114, y + 10, pz * 0.95), Rust, jitter(RUST, rng, 0.1))
		cylinder(m, "Pipe", 44, 0.5, CFrame.new(-114, y + 11.2, pz * 0.95), Metal, Color3.fromRGB(90, 96, 92))
	end
	box(m, "ControlPanel", -94, -92, y, y + 6, -16, -11, Metal, Color3.fromRGB(80, 90, 84))
	for k = 0, 5 do
		local dial = cylinder(m, "Gauge", 0.1, 0.9, CFrame.new(-94.06, y + 3.5 + (k % 2) * 1.3, -15 + math.floor(k / 2) * 1.5), Smooth, Color3.fromRGB(226, 222, 206))
		dial.CanCollide = false
	end
	local oil = BuildUtil.disc(m, "OilSlick", 7, 0.05, Vector3.new(-100, y + 0.03, -3), Smooth, Color3.fromRGB(20, 20, 18))
	oil.Reflectance = 0.3
	oil.CanCollide = false
	for _ = 1, 3 do
		cylinder(m, "OilDrum", 3.6, 2.4, CFrame.new(rng:NextNumber(-134, -126), y + 1.8, rng:NextNumber(-16, -8)) * CFrame.Angles(0, 0, math.rad(90)), Rust, jitter(RUST, rng, 0.1))
	end
	bulb(m, Vector3.new(-112, TWEEN_Y - 1.4, -2), true)
end

local function fishHold(m, rng)
	local y = HOLD_Y
	local crate = { Color3.fromRGB(60, 96, 150), Color3.fromRGB(170, 70, 50), Color3.fromRGB(200, 196, 180) }
	for _ = 1, rng:NextInteger(14, 24) do
		local x = rng:NextNumber(-86, 66)
		local half = beamAtX(x) / 2 - 4
		local z = rng:NextNumber(-half, half)
		local inHatchShaft = math.abs(z) < 11 and ((x > -61 and x < -39) or (x > 9 and x < 31))
		if not inHatchShaft then
			local stack = rng:NextInteger(1, 3)
			local color = pick(crate, rng)
			for k = 1, stack do
				part(m, "FishCrate", Vector3.new(3, 1.6, 2.2), CFrame.new(x, y + 0.8 + (k - 1) * 1.6, z) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Smooth, jitter(color, rng, 0.08))
			end
		end
	end
	for _ = 1, rng:NextInteger(3, 6) do
		local x = rng:NextNumber(-80, 60)
		local net = part(m, "NetPile", Vector3.new(rng:NextNumber(6, 12), rng:NextNumber(2, 4), rng:NextNumber(5, 10)), CFrame.new(x, y + 1, rng:NextNumber(-14, 14)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Fabric, Color3.fromRGB(46, 70, 54))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = net
	end
	local water = part(m, "BilgeWater", Vector3.new(40, 0.3, 30), Vector3.new(-20, y + 0.15, 0), Smooth, Color3.fromRGB(34, 44, 38))
	water.Transparency = 0.2
	water.Reflectance = 0.25
	water.CanCollide = false
	bulb(m, Vector3.new(-10, TWEEN_Y - 1.4, 16), false)
end

local function tweenDeck(m, rng)
	local y = TWEEN_Y
	-- Crew bunks against the hull just forward of the engine room.
	for k = 0, 2 do
		local x0 = -86 + k * 7
		box(m, "BunkFrame", x0, x0 + 6, y, y + 0.4, 15, 22, Metal, Color3.fromRGB(80, 84, 86))
		box(m, "BunkFrame", x0, x0 + 6, y + 4.5, y + 4.9, 15, 22, Metal, Color3.fromRGB(80, 84, 86))
		box(m, "Mattress", x0 + 0.2, x0 + 5.8, y + 0.4, y + 1.1, 15.3, 21.7, Fabric, jitter(Color3.fromRGB(150, 140, 120), rng, 0.1))
		box(m, "Mattress", x0 + 0.2, x0 + 5.8, y + 4.9, y + 5.6, 15.3, 21.7, Fabric, jitter(Color3.fromRGB(150, 140, 120), rng, 0.1))
		for _, px in ipairs({ x0, x0 + 5.7 }) do
			box(m, "BunkPost", px, px + 0.3, y, y + 5.5, 15, 15.3, Metal, Color3.fromRGB(80, 84, 86))
		end
	end
	for _ = 1, rng:NextInteger(4, 8) do
		part(m, "Crate", Vector3.new(4, 3, 4), CFrame.new(rng:NextNumber(-30, 60), y + 1.5, rng:NextNumber(12, 18) * pick({ -1, 1 }, rng)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Wood, jitter(Color3.fromRGB(120, 94, 64), rng, 0.1))
	end
	bulb(m, Vector3.new(-60, D - 2, 16), rng:NextNumber() < 0.5)

	-- Chain locker in the bow: a heap of rusted chain.
	local heap = part(m, "ChainHeap", Vector3.new(14, 5, 12), Vector3.new(100, y + 2, 0), Rust, RUST)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = heap
end

-- ===== Deckhouse =====

-- Plate walls round one deckhouse storey, with door/window openings given
-- per wall as { center, width, bottom, top } (bottom/top relative to floor).
local function houseWalls(m, yFloor, height, openings)
	local function wall(axis, fixed, a, b, list)
		local abs = {}
		for _, o in ipairs(list or {}) do
			table.insert(abs, { center = o[1], width = o[2], bottom = yFloor + o[3], top = yFloor + o[4] })
		end
		BuildUtil.strip(m, {
			name = "DeckhouseWall",
			axis = axis,
			fixed = fixed,
			spanStart = a,
			spanEnd = b,
			bottom = yFloor,
			top = yFloor + height,
			thickness = 0.8,
			openings = abs,
			material = Rust,
			color = HOUSE,
		})
	end
	wall("X", -HOUSE_HALF, HOUSE_X0, HOUSE_X1, openings.south)
	wall("X", HOUSE_HALF, HOUSE_X0, HOUSE_X1, openings.north)
	wall("Z", HOUSE_X1, -HOUSE_HALF, HOUSE_HALF, openings.front)
	wall("Z", HOUSE_X0, -HOUSE_HALF, HOUSE_HALF, openings.aft)
end

-- Floor slab over the whole deckhouse with the stairwell cut out.
local function houseFloor(m, y, color)
	local hx0, hx1, hz0, hz1 = -108, -89, -17, -12
	box(m, "DeckhouseFloor", HOUSE_X0, HOUSE_X1, y - 0.8, y, -HOUSE_HALF, hz0, Rust, color)
	box(m, "DeckhouseFloor", HOUSE_X0, HOUSE_X1, y - 0.8, y, hz1, HOUSE_HALF, Rust, color)
	box(m, "DeckhouseFloor", HOUSE_X0, hx0, y - 0.8, y, hz0, hz1, Rust, color)
	box(m, "DeckhouseFloor", hx1, HOUSE_X1, y - 0.8, y, hz0, hz1, Rust, color)
end

local function glazing(m, axis, fixed, center, width, bottom, top, rng)
	local panes = math.max(1, math.floor(width / 3))
	local paneW = width / panes
	for k = 1, panes do
		if rng:NextNumber() > 0.4 then
			local c = center - width / 2 + paneW * (k - 0.5)
			local size, pos = BuildUtil.axisBox(axis, paneW - 0.2, top - bottom, 0.1, c, (bottom + top) / 2, fixed)
			local pane = part(m, "WindowGlass", size, pos, Enum.Material.Glass, jitter(GLASS, rng, 0.05))
			pane.Transparency = 0.5
		end
	end
end

local function deckhouse(m, rng)
	local y1, y2, y3 = D, D + LEVEL_H, D + LEVEL_H * 2
	local door, port = { 0, 5, 0, 8 }, function(c)
		return { c, 3, 4, 6.5 }
	end

	-- Level 1: mess and galley, doors on all four sides.
	houseWalls(m, y1, LEVEL_H, {
		south = { { -118, 5, 0, 8 }, port(-125.5), port(-94) },
		north = { { -104, 5, 0, 8 }, port(-120), port(-94) },
		front = { door, { -10, 3, 4, 6.5 }, { 10, 3, 4, 6.5 } },
		aft = { door },
	})
	-- Railing round the stair hole down to the tween deck, open at the top
	-- step (the +X end).
	for _, rz in ipairs({ 5.7, 12.3 }) do
		box(m, "StairRail", -120, -91, y1 + 3, y1 + 3.3, rz - 0.15, rz + 0.15, Metal, HULL)
		for _, px in ipairs({ -120, -110, -100, -91 }) do
			box(m, "StairRailPost", px - 0.15, px + 0.15, y1, y1 + 3, rz - 0.15, rz + 0.15, Metal, HULL)
		end
	end
	box(m, "StairRail", -120.3, -119.7, y1 + 3, y1 + 3.3, 5.7, 12.3, Metal, HULL)
	box(m, "MessTable", -122, -110, y1 + 3, y1 + 3.4, -8, -2, Wood, Color3.fromRGB(120, 92, 64))
	for _, bz in ipairs({ -10, 0 }) do
		box(m, "MessBench", -122, -110, y1 + 1.8, y1 + 2.2, bz, bz + 2, Wood, Color3.fromRGB(110, 84, 58))
	end
	box(m, "GalleyCounter", HOUSE_X0 + 0.4, HOUSE_X0 + 3.4, y1, y1 + 3.4, 2, 16, Metal, Color3.fromRGB(150, 150, 146))
	box(m, "Stove", HOUSE_X0 + 0.4, HOUSE_X0 + 3.4, y1 + 3.4, y1 + 3.8, 4, 8, Metal, DARK)
	box(m, "Fridge", HOUSE_X0 + 0.4, HOUSE_X0 + 4, y1, y1 + 7, -16, -12, Metal, Color3.fromRGB(196, 194, 184))
	bulb(m, Vector3.new(-106, y2 - 1.5, 0), rng:NextNumber() < 0.5)

	-- Level 2: crew cabins.
	houseFloor(m, y2, DECK_COLOR)
	houseWalls(m, y2, LEVEL_H, {
		south = { port(-120), port(-94) },
		north = { port(-120), port(-108), port(-94) },
		front = { { -8, 3, 4, 6.5 }, { 8, 3, 4, 6.5 } },
		aft = { { 0, 3, 4, 6.5 } },
	})
	for k = 0, 1 do
		local bz = 6 + k * 6
		box(m, "BunkFrame", HOUSE_X0 + 0.4, HOUSE_X0 + 7.4, y2, y2 + 0.4, bz, bz + 5, Metal, Color3.fromRGB(80, 84, 86))
		box(m, "BunkFrame", HOUSE_X0 + 0.4, HOUSE_X0 + 7.4, y2 + 4.5, y2 + 4.9, bz, bz + 5, Metal, Color3.fromRGB(80, 84, 86))
		box(m, "Mattress", HOUSE_X0 + 0.6, HOUSE_X0 + 7.2, y2 + 0.4, y2 + 1.1, bz + 0.2, bz + 4.8, Fabric, jitter(Color3.fromRGB(150, 140, 120), rng, 0.1))
		box(m, "Mattress", HOUSE_X0 + 0.6, HOUSE_X0 + 7.2, y2 + 4.9, y2 + 5.6, bz + 0.2, bz + 4.8, Fabric, jitter(Color3.fromRGB(150, 140, 120), rng, 0.1))
	end
	for k = 0, 3 do
		box(m, "Locker", -96 + k * 2.2, -94 + k * 2.2, y2, y2 + 7, HOUSE_HALF - 2.2, HOUSE_HALF - 0.4, Metal, jitter(Color3.fromRGB(110, 120, 116), rng, 0.08))
	end

	-- Bridge: windows all round, many panes gone.
	houseFloor(m, y3, DECK_COLOR)
	local bridgeH = 9
	houseWalls(m, y3, bridgeH, {
		south = { { -106, 36, 3.2, 7.6 } },
		north = { { -106, 36, 3.2, 7.6 } },
		front = { { 0, 32, 3.2, 7.6 } },
		aft = { { 0, 12, 3.2, 7.6 } },
	})
	glazing(m, "X", -HOUSE_HALF, -106, 36, y3 + 3.2, y3 + 7.6, rng)
	glazing(m, "X", HOUSE_HALF, -106, 36, y3 + 3.2, y3 + 7.6, rng)
	glazing(m, "Z", HOUSE_X1, 0, 32, y3 + 3.2, y3 + 7.6, rng)
	glazing(m, "Z", HOUSE_X0, 0, 12, y3 + 3.2, y3 + 7.6, rng)
	box(m, "BridgeRoof", HOUSE_X0 - 1, HOUSE_X1 + 2, y3 + bridgeH, y3 + bridgeH + 0.8, -HOUSE_HALF - 2, HOUSE_HALF + 2, Rust, HULL)

	box(m, "Console", HOUSE_X1 - 3, HOUSE_X1 - 0.4, y3, y3 + 3.4, -13, 13, Metal, Color3.fromRGB(70, 80, 78))
	for k = 0, 7 do
		local dial = cylinder(m, "Dial", 0.1, 0.8, CFrame.new(HOUSE_X1 - 3.06, y3 + 2.4, -10 + k * 2.8), Smooth, pick({ Color3.fromRGB(226, 222, 206), Color3.fromRGB(60, 150, 90), Color3.fromRGB(190, 60, 50) }, rng))
		dial.CanCollide = false
	end
	cylinder(m, "WheelPedestal", 3.2, 1, CFrame.new(-92, y3 + 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Metal, Color3.fromRGB(60, 60, 62))
	for k = 0, 9 do
		local a0, a1 = k / 10 * math.pi * 2, (k + 1) / 10 * math.pi * 2
		local p0 = Vector3.new(-92.6, y3 + 3.6 + math.sin(a0) * 1.4, math.cos(a0) * 1.4)
		local p1 = Vector3.new(-92.6, y3 + 3.6 + math.sin(a1) * 1.4, math.cos(a1) * 1.4)
		cylinder(m, "Wheel", (p1 - p0).Magnitude + 0.05, 0.22, CFrame.lookAt((p0 + p1) / 2, p1, Vector3.xAxis) * CFrame.Angles(0, math.pi / 2, 0), Wood, Color3.fromRGB(110, 76, 48))
	end
	box(m, "ChartTable", -118, -112, y3 + 3, y3 + 3.3, 6, 12, Wood, Color3.fromRGB(120, 92, 64))
	box(m, "CaptainChair", -97, -95, y3, y3 + 3.2, -5, -3, Fabric, Color3.fromRGB(70, 60, 54))
	for _ = 1, rng:NextInteger(6, 12) do
		local shard = part(m, "GlassShard", Vector3.new(rng:NextNumber(0.4, 1.2), 0.05, rng:NextNumber(0.4, 1.2)), CFrame.new(rng:NextNumber(-100, -86), y3 + 0.04, rng:NextNumber(-16, 16)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Enum.Material.Glass, GLASS)
		shard.Transparency = 0.4
		shard.CanCollide = false
	end

	-- Stairs between the storeys, along the south wall.
	stair(m, -106, y1, -91, y2, -16.5, -12.5)
	stair(m, -106, y2, -91, y3, -16.5, -12.5)

	-- Funnel and mast on the bridge roof.
	local roofY = y3 + bridgeH + 0.8
	cylinder(m, "Funnel", 18, 11, CFrame.new(-122, roofY + 9, 0) * CFrame.Angles(0, 0, math.rad(90)), Rust, jitter(HULL, rng, 0.05))
	cylinder(m, "FunnelBand", 3, 11.2, CFrame.new(-122, roofY + 15, 0) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(70, 96, 130))
	cylinder(m, "BridgeMast", 22, 1.4, CFrame.new(-100, roofY + 11, 0) * CFrame.Angles(0, 0, math.rad(90)), Metal, HULL)
	box(m, "Yardarm", -100.4, -99.6, roofY + 16, roofY + 16.8, -10, 10, Metal, HULL)
	part(m, "Radar", Vector3.new(2, 1, 9), CFrame.new(-100, roofY + 22.5, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Metal, HULL)

	-- Lifeboat hanging askew from its davit on the north side.
	local lifeboat = part(m, "Lifeboat", Vector3.new(18, 5, 6.5), CFrame.new(-106, y2 + 2, HOUSE_HALF + 5) * CFrame.Angles(math.rad(rng:NextNumber(8, 20)), 0, math.rad(rng:NextNumber(-10, 10))), Smooth, Color3.fromRGB(196, 96, 40))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = lifeboat
	box(m, "Davit", -106.4, -105.6, y2, y2 + 10, HOUSE_HALF + 0.4, HOUSE_HALF + 1.2, Metal, HULL)
end

-- ===== Main deck gear =====

local function deckGear(m, rng)
	local mastX = 50
	cylinder(m, "Foremast", 46, 2, CFrame.new(mastX, D + 23, 0) * CFrame.Angles(0, 0, math.rad(90)), Metal, HULL)
	box(m, "Crosstree", mastX - 0.5, mastX + 0.5, D + 38, D + 39, -9, 9, Metal, HULL)
	local boomBase, boomTip = Vector3.new(mastX + 1, D + 4, 0), Vector3.new(mastX + 44, D + 28, rng:NextNumber(-8, 8))
	cylinder(m, "DerrickBoom", (boomTip - boomBase).Magnitude, 1.3, CFrame.lookAt((boomBase + boomTip) / 2, boomTip) * CFrame.Angles(0, math.pi / 2, 0), Metal, HULL)

	for _, wx in ipairs({ -30, 38 }) do
		cylinder(m, "Winch", 6, 3, CFrame.new(wx, D + 2, 0) * CFrame.Angles(0, math.rad(90), 0), Rust, RUST)
	end
	for _, bx in ipairs({ -70, -5, 60, 95 }) do
		for _, s in ipairs({ -1, 1 }) do
			local z = s * (beamAtX(bx) / 2 - 3)
			cylinder(m, "Bollard", 2.4, 1.4, CFrame.new(bx, D + 1.2, z) * CFrame.Angles(0, 0, math.rad(90)), Metal, HULL)
		end
	end
	cylinder(m, "Windlass", 8, 3.4, CFrame.new(118, D + 2, 0) * CFrame.Angles(0, math.rad(90), 0), Rust, RUST)

	cylinder(m, "NetDrum", 14, 7, CFrame.new(-135, D + 4, 0) * CFrame.Angles(0, math.rad(90), 0), Rust, RUST)

	-- The stern gantry: an A-frame over the transom, the trawl doors hung
	-- off it.
	local gx = -L / 2 + 3
	for _, s in ipairs({ -1, 1 }) do
		local foot = Vector3.new(gx + 4, D, s * (B * 0.4 - 2))
		local top = Vector3.new(gx - 1, D + 26, s * (B * 0.3))
		cylinder(m, "GantryLeg", (top - foot).Magnitude, 1.8, CFrame.lookAt((foot + top) / 2, top) * CFrame.Angles(0, math.pi / 2, 0), Rust, jitter(Color3.fromRGB(190, 120, 40), rng, 0.08))
		local door = part(m, "TrawlDoor", Vector3.new(1, 7, 10), CFrame.new(gx - 2.5, D + 15, s * (B * 0.3 + 1.5)) * CFrame.Angles(math.rad(s * 6), 0, math.rad(rng:NextNumber(-6, 6))), Rust, jitter(RUST, rng, 0.1))
		door.CanCollide = false
		cylinder(m, "DoorChain", 8, 0.3, CFrame.new(gx - 2.3, D + 22.5, s * (B * 0.3 + 1.5)) * CFrame.Angles(0, 0, math.rad(90)), Metal, DARK)
	end
	cylinder(m, "GantryBeam", B * 0.6 + 2, 2, CFrame.new(gx - 1, D + 26, 0) * CFrame.Angles(0, math.rad(90), 0), Rust, Color3.fromRGB(190, 120, 40))
	cylinder(m, "GantryBlock", 1.6, 3, CFrame.new(gx - 1, D + 24.5, 0), Metal, DARK)
	-- Rudder and screw.
	box(m, "Rudder", -L / 2 - 6, -L / 2 - 1.5, 1, 14, -0.6, 0.6, Rust, jitter(ANTIFOUL, rng, 0.08))
	cylinder(m, "Shaft", 5, 1.2, CFrame.new(-L / 2 - 1, 7, 0), Metal, Color3.fromRGB(150, 120, 70))
	for k = 0, 3 do
		local blade = part(m, "PropBlade", Vector3.new(0.4, 5, 2), CFrame.new(-L / 2 - 1.2, 7, 0) * CFrame.Angles(k * math.pi / 2, 0, 0) * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0.4, 0), Metal, Color3.fromRGB(170, 130, 70))
		blade.CanCollide = false
	end
	-- Bilge keels.
	for _, s in ipairs({ -1, 1 }) do
		box(m, "BilgeKeel", -80, 60, 1.5, 2.3, s * (B / 2 - 3) - 0.3, s * (B / 2 - 3) + 0.3, Rust, jitter(ANTIFOUL, rng, 0.08))
	end

	-- Outrigger booms swung out either side of the foremast, stays down to
	-- the rail.
	for _, s in ipairs({ -1, 1 }) do
		local foot = Vector3.new(mastX, D + 6, s * 1.4)
		local tip = Vector3.new(mastX - 4, D + 22, s * (B / 2 + 22))
		cylinder(m, "Outrigger", (tip - foot).Magnitude, 1, CFrame.lookAt((foot + tip) / 2, tip) * CFrame.Angles(0, math.pi / 2, 0), Metal, HULL)
		local stay = cylinder(m, "OutriggerStay", (tip - Vector3.new(mastX, D + 36, 0)).Magnitude, 0.25, CFrame.lookAt((tip + Vector3.new(mastX, D + 36, 0)) / 2, tip) * CFrame.Angles(0, math.pi / 2, 0), Metal, DARK)
		stay.CanCollide = false
		local hang = cylinder(m, "OutriggerChain", 10, 0.3, CFrame.new(tip.X, tip.Y - 5, tip.Z) * CFrame.Angles(0, 0, math.rad(90)), Metal, DARK)
		hang.CanCollide = false
	end

	-- Squid lamps: strings of big bulbs from the foremast to the bow and
	-- back to the bridge; a few still work.
	local mastTop = Vector3.new(mastX, D + 38, 0)
	for _, far in ipairs({ Vector3.new(L / 2 - 12, D + 6, 0), Vector3.new(HOUSE_X1 + 2, D + LEVEL_H * 3 + 2, 0) }) do
		local wire = cylinder(m, "LampWire", (far - mastTop).Magnitude, 0.12, CFrame.lookAt((mastTop + far) / 2, far) * CFrame.Angles(0, math.pi / 2, 0), Smooth, DARK)
		wire.CanCollide = false
		for t = 0.1, 0.92, 0.09 do
			local p = mastTop:Lerp(far, t) - Vector3.new(0, 1, 0)
			local lit = rng:NextNumber() < 0.2
			local lamp = part(m, "SquidLamp", Vector3.new(1.3, 1.8, 1.3), p, if lit then Enum.Material.Neon else Enum.Material.Glass, if lit then Color3.fromRGB(255, 240, 200) else Color3.fromRGB(200, 204, 196))
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = lamp
			lamp.CanCollide = false
		end
	end

	-- Coiled ropes, fish boxes stacked by the hatches, life rings on the
	-- deckhouse.
	for _ = 1, 6 do
		local c = Vector3.new(rng:NextNumber(-70, 90), D + 0.4, rng:NextNumber(-B / 3, B / 3))
		local coil = cylinder(m, "RopeCoil", 0.8, rng:NextNumber(3, 4.5), CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90)), Fabric, Color3.fromRGB(170, 150, 110))
		coil.CanCollide = false
	end
	for _ = 1, 10 do
		local x = pick({ -64, -36, 6, 34 }, rng) + rng:NextNumber(-2, 2)
		local z = pick({ -1, 1 }, rng) * rng:NextNumber(12, 18)
		for k = 0, rng:NextInteger(0, 3) do
			part(m, "FishBox", Vector3.new(3, 1.4, 2.2), CFrame.new(x, D + 0.7 + k * 1.4, z) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), Smooth, pick({ Color3.fromRGB(60, 96, 150), Color3.fromRGB(170, 70, 50), Color3.fromRGB(200, 196, 180) }, rng))
		end
	end
	for _, pos in ipairs({ Vector3.new(HOUSE_X1 + 0.5, D + 5, 10), Vector3.new(-100, D + LEVEL_H + 5, HOUSE_HALF + 0.5), Vector3.new(-100, D + LEVEL_H + 5, -HOUSE_HALF - 0.5) }) do
		local facing = if math.abs(pos.Z) > HOUSE_HALF then 0 else math.pi / 2
		local ring = cylinder(m, "LifeRing", 0.6, 3.4, CFrame.new(pos) * CFrame.Angles(0, facing + math.pi / 2, 0), Smooth, Color3.fromRGB(230, 110, 40))
		ring.CanCollide = false
	end
	-- Searchlights and a torn flag on the bridge roof.
	local roofY = D + LEVEL_H * 2 + 9.8
	for _, z in ipairs({ -HOUSE_HALF + 2, HOUSE_HALF - 2 }) do
		cylinder(m, "Searchlight", 2, 2.2, CFrame.new(HOUSE_X1 - 1, roofY + 1.6, z), Metal, Color3.fromRGB(180, 180, 176))
		cylinder(m, "SearchlightPost", 1.2, 0.6, CFrame.new(HOUSE_X1 - 1, roofY + 0.6, z) * CFrame.Angles(0, 0, math.rad(90)), Metal, DARK)
	end
	cylinder(m, "FlagPole", 10, 0.3, CFrame.new(HOUSE_X0 + 1, roofY + 5, 0) * CFrame.Angles(0, 0, math.rad(90)), Metal, HULL)
	local flag = part(m, "Flag", Vector3.new(4, 2.6, 0.08), CFrame.new(HOUSE_X0 - 1, roofY + 8.6, 0) * CFrame.Angles(0, 0, math.rad(-8)), Fabric, Color3.fromRGB(200, 60, 50))
	flag.CanCollide = false
	for _ = 1, rng:NextInteger(8, 16) do
		local float = part(m, "NetFloat", Vector3.new(1.8, 1.8, 1.8), Vector3.new(rng:NextNumber(-80, 40), D + 0.9, rng:NextNumber(-B / 3, B / 3)), Smooth, Color3.fromRGB(214, 110, 40))
		float.Shape = Enum.PartType.Ball
	end
end

-- The chain off the windlass, along the foredeck and out over a roller on
-- the stem, where the great chain takes it (ChainOfShips.lua). Built in
-- the ship's frame; returns where the chain leaves her (local).
local CHAIN_OUT = Vector3.new(L / 2 + 6, D - 6, 0)
local function prowChain(m, rng)
	local roller = Vector3.new(L / 2 + 1, D + 1, 0)
	cylinder(m, "StemRoller", 4, 2.4, CFrame.new(roller - Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, math.rad(90), 0), Metal, DARK)
	box(m, "RollerCheek", L / 2 - 1, L / 2 + 2, D - 1, D + 0.4, -2.4, -2, Rust, RUST)
	box(m, "RollerCheek", L / 2 - 1, L / 2 + 2, D - 1, D + 0.4, 2, 2.4, Rust, RUST)
	local pts = { Vector3.new(118, D + 3.2, 0), Vector3.new(L / 2 - 2, D + 1.4, 0), roller + Vector3.new(0, 0.4, 0), CHAIN_OUT }
	for k = 1, #pts - 1 do
		local a, b = pts[k], pts[k + 1]
		local dir = (b - a).Unit
		local len = (b - a).Magnitude
		for d = 1.5, len, 2.6 do
			local p = a + dir * d
			local link = part(m, "ChainLink", Vector3.new(1.6, 0.6, 3.2), CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, if math.floor(d / 2.6) % 2 == 0 then 0 else math.pi / 2), Rust, jitter(RUST, rng, 0.1))
			link.CanCollide = false
		end
	end
end

-- `placement` is the CFrame for the midship keel point. Returns the model.
function Ship.build(parent, placement, rng)
	local m = model(parent, "BeachedShip")
	hull(m, rng)
	nameplates(m)
	engineRoom(m, rng)
	fishHold(m, rng)
	tweenDeck(m, rng)
	deckhouse(m, rng)
	deckGear(m, rng)
	prowChain(m, rng)
	m.WorldPivot = CFrame.identity
	m:PivotTo(placement)

	-- Where the great chain takes over, and a spot on the foredeck the walk
	-- out along it starts from.
	Ship.anchor = {
		crown = placement:PointToWorldSpace(CHAIN_OUT),
		deck = placement:PointToWorldSpace(Vector3.new(126, D, 0)),
	}
	return m
end

-- Local points the rooftop uses to connect walkways to the ship.
Ship.LENGTH, Ship.BEAM, Ship.DEPTH = L, B, D
Ship.TWEEN_Y, Ship.HOLD_Y = TWEEN_Y, HOLD_Y
Ship.GANGWAY_X = GANGWAY_X
Ship.SIDE_BREACH_X = -10 -- centre of the +Z breach at tween-deck level

return Ship
