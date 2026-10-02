-- Props for the tunnels and the rooms off them: proper crates, barrels,
-- drums and supply heaps, lanterns and tools, and glowing fungus (domed
-- mushrooms with gills and spots, bracket fungi on the walls, drifting
-- spores and hanging tendrils).
--
-- Builders take a CFrame on the ground (y up) unless noted.

local BuildUtil = require(script.Parent.BuildUtil)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local Metal, Smooth, Wood, Neon, Fabric, Rust = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.Neon, Enum.Material.Fabric, Enum.Material.CorrodedMetal

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local STEEL = Color3.fromRGB(96, 98, 100)
local RUST_COLOR = Color3.fromRGB(116, 76, 48)
local CRATE_WOOD = { Color3.fromRGB(150, 118, 78), Color3.fromRGB(124, 96, 64), Color3.fromRGB(168, 140, 96) }

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }

local TunnelProps = {}

-- A part drawn as an ellipsoid filling its size (physics stays a box).
local function ellipsoid(parent, name, size, cf, material, color)
	local p = part(parent, name, size, cf, material, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end
TunnelProps.ellipsoid = ellipsoid

local function stencil(plate, face, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 0.4)
	t.Position = UDim2.fromScale(0, 0.3)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Arcade
	t.TextScaled = true
	t.TextColor3 = color
	t.TextTransparency = 0.25
	t.Text = text
	t.Parent = gui
	gui.Parent = plate
end

-- ===== Crates, barrels, drums =====

-- A slatted crate: a panelled box with battens along every edge, a brace
-- across the sides, a stencilled mark. `kind`: nil, "open" (lid off,
-- straw spilling) or "explosives".
function TunnelProps.crate(parent, cf, size, rng, kind)
	local m = model(parent, "Crate")
	local wood = jitter(pick(CRATE_WOOD, rng), rng, 0.06)
	local batten = darken(wood, 0.82)
	local s = size / 2
	local open = kind == "open"
	local body = part(m, "CrateBody", size - Vector3.new(0.12, if open then 0.3 else 0.12, 0.12), cf * CFrame.new(0, s.Y - (if open then 0.15 else 0), 0), Wood, wood)
	local t = 0.22
	-- Edge battens: four uprights, and rings top and bottom.
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "Batten", Vector3.new(t, size.Y, t), cf * CFrame.new(sx * (s.X - t / 2), s.Y, sz * (s.Z - t / 2)), Wood, batten)
		end
	end
	for _, y in ipairs(if open then { t / 2 } else { t / 2, size.Y - t / 2 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "Batten", Vector3.new(size.X, t, t), cf * CFrame.new(0, y, sz * (s.Z - t / 2)), Wood, batten)
		end
		for _, sx in ipairs({ -1, 1 }) do
			part(m, "Batten", Vector3.new(t, t, size.Z), cf * CFrame.new(sx * (s.X - t / 2), y, 0), Wood, batten)
		end
	end
	-- Plank seams and a diagonal brace on the two long faces.
	for _, sz in ipairs({ -1, 1 }) do
		for k = 1, 2 do
			part(m, "PlankSeam", Vector3.new(size.X - 0.3, 0.05, 0.04), cf * CFrame.new(0, size.Y * k / 3, sz * (s.Z + 0.01)), Wood, darken(wood, 0.6)).CanCollide = false
		end
		local diag = math.sqrt(size.X ^ 2 + size.Y ^ 2) - 0.4
		part(m, "Brace", Vector3.new(diag, t, 0.12), cf * CFrame.new(0, s.Y, sz * (s.Z + 0.03)) * CFrame.Angles(0, 0, math.atan2(size.Y, size.X) * (if sz > 0 then 1 else -1)), Wood, batten)
	end
	-- Stencil.
	local mark = if kind == "explosives" then "火気厳禁" else pick({ "第三坑", "資材", "No.7", "取扱注意", "B-2", "工具" }, rng)
	stencil(body, Enum.NormalId.Front, mark, if kind == "explosives" then Color3.fromRGB(180, 30, 26) else Color3.fromRGB(40, 32, 24))
	if kind == "explosives" then
		part(m, "DangerBand", Vector3.new(size.X + 0.05, 0.5, size.Z + 0.05), cf * CFrame.new(0, size.Y * 0.8, 0), Smooth, Color3.fromRGB(180, 30, 26))
	end
	if open then
		-- Lid leant against it, straw and whatever was packed in it.
		part(m, "CrateLid", Vector3.new(size.X, 0.2, size.Z), cf * CFrame.new(s.X + 0.6, s.Y * 0.9, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(70, 80))), Wood, wood)
		part(m, "Straw", Vector3.new(size.X - 0.4, 0.3, size.Z - 0.4), cf * CFrame.new(0, size.Y - 0.35, 0), Fabric, Color3.fromRGB(196, 170, 100))
		for _ = 1, rng:NextInteger(2, 4) do
			local bottle = cylinder(m, "Bottle", 0.9, 0.35, cf * CFrame.new(rng:NextNumber(-s.X + 0.6, s.X - 0.6), size.Y - 0.1, rng:NextNumber(-s.Z + 0.6, s.Z - 0.6)) * UPRIGHT, Enum.Material.Glass, pick({ Color3.fromRGB(70, 110, 60), Color3.fromRGB(120, 80, 40) }, rng))
			bottle.Transparency = 0.3
		end
	end
	return m
end

-- A wooden barrel with iron hoops.
function TunnelProps.barrel(parent, cf, rng)
	local m = model(parent, "Barrel")
	local wood = jitter(Color3.fromRGB(120, 86, 56), rng, 0.08)
	local h, d = 3.2, 2.3
	cylinder(m, "BarrelBody", h, d, cf * CFrame.new(0, h / 2, 0) * UPRIGHT, Wood, wood)
	cylinder(m, "BarrelBelly", h * 0.55, d + 0.2, cf * CFrame.new(0, h / 2, 0) * UPRIGHT, Wood, wood)
	for _, y in ipairs({ 0.35, h * 0.3, h * 0.7, h - 0.35 }) do
		cylinder(m, "Hoop", 0.2, (if y > 0.5 and y < h - 0.5 then d + 0.28 else d + 0.08), cf * CFrame.new(0, y, 0) * UPRIGHT, Metal, Color3.fromRGB(50, 48, 46))
	end
	cylinder(m, "BarrelHead", 0.06, d - 0.2, cf * CFrame.new(0, h + 0.01, 0) * UPRIGHT, Wood, darken(wood, 0.85))
	return m
end

-- A steel oil drum with rolling rims and a bung; some rusted through.
function TunnelProps.drum(parent, cf, rng)
	local m = model(parent, "Drum")
	local color = jitter(pick({ Color3.fromRGB(40, 70, 150), Color3.fromRGB(200, 160, 40), Color3.fromRGB(150, 40, 30), Color3.fromRGB(60, 100, 60), Color3.fromRGB(70, 72, 74) }, rng), rng, 0.06)
	local rusty = rng:NextNumber() < 0.4
	local h, d = 3.4, 2.2
	cylinder(m, "DrumBody", h, d, cf * CFrame.new(0, h / 2, 0) * UPRIGHT, if rusty then Rust else Metal, if rusty then color:Lerp(RUST_COLOR, 0.5) else color)
	-- (the end rims stand a little proud of the lids, so they don't fight)
	for _, y in ipairs({ -0.02, h / 3, h * 2 / 3, h + 0.02 }) do
		cylinder(m, "DrumRim", if y < 0 or y > h then 0.2 else 0.16, d + 0.1, cf * CFrame.new(0, y, 0) * UPRIGHT, Metal, darken(color, 0.75))
	end
	cylinder(m, "Bung", 0.15, 0.35, cf * CFrame.new(0.55, h + 0.16, 0.3) * UPRIGHT, Metal, STEEL)
	return m
end

-- A heap of supplies: crates stacked and askew, barrels, drums, sacks,
-- sometimes a tarp thrown over part of it.
function TunnelProps.supplyHeap(parent, at, rng, radius)
	radius = radius or 3
	local m = model(parent, "SupplyHeap")
	local yaw = rng:NextNumber(0, math.pi * 2)
	local base = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	local count = rng:NextInteger(2, 5)
	for k = 1, count do
		local off = Vector3.new(rng:NextNumber(-radius, radius), 0, rng:NextNumber(-radius, radius))
		local cf = base * CFrame.new(off) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0)
		local roll = rng:NextNumber()
		if roll < 0.5 then
			local size = Vector3.new(rng:NextNumber(2.4, 3.6), rng:NextNumber(1.8, 3), rng:NextNumber(2, 3))
			TunnelProps.crate(m, cf, size, rng, if rng:NextNumber() < 0.15 then "explosives" elseif rng:NextNumber() < 0.2 then "open" else nil)
			if rng:NextNumber() < 0.45 then
				local top = Vector3.new(rng:NextNumber(1.6, 2.6), rng:NextNumber(1.4, 2.2), rng:NextNumber(1.6, 2.4))
				TunnelProps.crate(m, cf * CFrame.new(rng:NextNumber(-0.3, 0.3), size.Y, rng:NextNumber(-0.3, 0.3)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), top, rng, nil)
			end
		elseif roll < 0.7 then
			TunnelProps.barrel(m, cf, rng)
		elseif roll < 0.88 then
			if rng:NextNumber() < 0.25 then
				TunnelProps.drum(m, cf * CFrame.new(0, 1.1, 0) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, -1.7, 0), rng)
			else
				TunnelProps.drum(m, cf, rng)
			end
		else
			for s = 0, rng:NextInteger(1, 3) do
				local sack = TunnelProps.ellipsoid(m, "Sack", Vector3.new(2.4, 1.3, 1.6), cf * CFrame.new(0, 0.6 + s * 0.9, 0) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2)), Fabric, jitter(Color3.fromRGB(170, 150, 110), rng, 0.08))
				sack.CanCollide = true
			end
		end
	end
	if rng:NextNumber() < 0.3 then
		local tarp = part(m, "Tarp", Vector3.new(radius * 1.6, 0.1, radius * 1.4), base * CFrame.new(0, 3.2, 0) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.3, 0.3)), Fabric, pick({ Color3.fromRGB(48, 84, 130), Color3.fromRGB(70, 96, 62), Color3.fromRGB(150, 140, 110) }, rng))
		tarp.CanCollide = false
	end
	return m
end

-- ===== Light and tools =====

-- A miner's lantern: frame, glass, handle; lit or not.
function TunnelProps.lantern(parent, cf, rng, lit)
	local m = model(parent, "Lantern")
	part(m, "LanternBase", Vector3.new(1, 0.25, 1), cf * CFrame.new(0, 0.12, 0), Metal, RUST_COLOR)
	part(m, "LanternTop", Vector3.new(0.9, 0.3, 0.9), cf * CFrame.new(0, 1.45, 0), Metal, RUST_COLOR)
	local glass = part(m, "LanternGlass", Vector3.new(0.75, 1.05, 0.75), cf * CFrame.new(0, 0.78, 0), Enum.Material.Glass, Color3.fromRGB(230, 220, 190))
	glass.Transparency = 0.5
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "LanternFrame", Vector3.new(0.08, 1.1, 0.08), cf * CFrame.new(sx * 0.4, 0.78, sz * 0.4), Metal, RUST_COLOR)
		end
	end
	part(m, "LanternHandle", Vector3.new(0.06, 0.5, 0.7), cf * CFrame.new(0, 1.85, 0), Metal, RUST_COLOR)
	if lit then
		local flame = part(m, "LanternFlame", Vector3.new(0.25, 0.4, 0.25), cf * CFrame.new(0, 0.75, 0), Neon, Color3.fromRGB(255, 190, 100))
		flame.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 14
		light.Brightness = 1.1
		light.Color = Color3.fromRGB(255, 180, 110)
		light.Parent = flame
		if rng:NextNumber() < 0.5 then
			flame:AddTag("FlickerLight")
		end
	end
	return m
end

function TunnelProps.pickaxe(parent, cf)
	local m = model(parent, "Pickaxe")
	cylinder(m, "Handle", 4.2, 0.25, cf * CFrame.new(0, 2.1, 0) * UPRIGHT, Wood, Color3.fromRGB(110, 84, 58))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "PickHead", Vector3.new(1.3, 0.25, 0.25), cf * CFrame.new(s * 0.6, 4.1 - 0.15, 0) * CFrame.Angles(0, 0, s * math.rad(-14)), Metal, STEEL)
	end
	return m
end

function TunnelProps.shovel(parent, cf)
	local m = model(parent, "Shovel")
	cylinder(m, "Handle", 3.6, 0.22, cf * CFrame.new(0, 2.6, 0) * UPRIGHT, Wood, Color3.fromRGB(110, 84, 58))
	part(m, "Grip", Vector3.new(0.7, 0.15, 0.15), cf * CFrame.new(0, 4.45, 0), Wood, Color3.fromRGB(110, 84, 58))
	part(m, "Blade", Vector3.new(0.9, 1.2, 0.08), cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(8), 0, 0), Metal, STEEL)
	return m
end

-- ===== Fungus =====

local GLOWS = {
	{ cap = Color3.fromRGB(80, 220, 210), gill = Color3.fromRGB(30, 110, 110), spot = Color3.fromRGB(210, 255, 250) },
	{ cap = Color3.fromRGB(150, 230, 90), gill = Color3.fromRGB(70, 110, 40), spot = Color3.fromRGB(240, 255, 200) },
	{ cap = Color3.fromRGB(170, 110, 230), gill = Color3.fromRGB(80, 50, 120), spot = Color3.fromRGB(240, 210, 255) },
	{ cap = Color3.fromRGB(240, 150, 80), gill = Color3.fromRGB(120, 60, 30), spot = Color3.fromRGB(255, 230, 190) },
}
TunnelProps.GLOWS = GLOWS

-- One mushroom: a stem that bends as it rises, a domed cap with gills
-- underneath and pale spots on top. Returns the cap centre.
function TunnelProps.mushroom(parent, base, height, capD, palette, rng, opts)
	opts = opts or {}
	local lean = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * height * rng:NextNumber(0.05, 0.25)
	local stemD = math.max(0.15, capD * rng:NextNumber(0.14, 0.22))
	local prev = base
	local stemColor = Color3.fromRGB(222, 214, 196):Lerp(palette.cap, 0.15)
	local segments = if height > 3 then 3 else 1
	for k = 1, segments do
		local t = k / segments
		local p = base + Vector3.new(0, height * t, 0) + lean * t * t
		local len = (p - prev).Magnitude
		local d = stemD * (1.25 - 0.3 * t)
		local stem = cylinder(parent, "MushroomStem", len + d * 0.3, d, CFrame.lookAt((prev + p) / 2, p, Vector3.xAxis) * CFrame.Angles(0, math.pi / 2, 0), Smooth, stemColor)
		stem.CanCollide = opts.solid == true
		prev = p
	end
	local tilt = CFrame.Angles(lean.Z / height * 0.8, 0, -lean.X / height * 0.8)
	local capCF = CFrame.new(prev) * tilt
	local capH = capD * rng:NextNumber(0.32, 0.5)
	local cap = ellipsoid(parent, "MushroomCap", Vector3.new(capD, capH, capD), capCF * CFrame.new(0, capH * 0.3, 0), Neon, jitter(palette.cap, rng, 0.08))
	cap.Transparency = opts.capTransparency or 0.12
	cap.CanCollide = opts.solid == true
	cap.CastShadow = false
	local gills = cylinder(parent, "MushroomGills", 0.12, capD * 0.92, capCF * CFrame.new(0, 0.02, 0) * UPRIGHT, Smooth, palette.gill)
	gills.CanCollide = false
	if capD > 1.2 then
		for _ = 1, math.clamp(math.floor(capD * 0.8), 2, 9) do
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, capD * 0.32)
			local ds = capD * rng:NextNumber(0.05, 0.1)
			local spot = ellipsoid(parent, "CapSpot", Vector3.new(ds, ds * 0.35, ds), capCF * CFrame.new(math.cos(a) * r, capH * 0.3 + capH * 0.5 * math.sqrt(math.max(0, 1 - (r / (capD * 0.5)) ^ 2)), math.sin(a) * r), Smooth, palette.spot)
			spot.CanCollide = false
		end
	end
	return prev
end

-- A cluster of mushrooms of mixed sizes round a point, with one light.
function TunnelProps.mushroomCluster(parent, at, rng, scale, palette)
	scale = scale or 1
	palette = palette or pick(GLOWS, rng)
	local m = model(parent, "MushroomCluster")
	local count = rng:NextInteger(4, 10)
	for k = 1, count do
		local big = k == 1
		local size = (if big then rng:NextNumber(1.4, 2.4) else rng:NextNumber(0.3, 1.3)) * scale
		local off = if big then Vector3.zero else Vector3.new(rng:NextNumber(-1.8, 1.8), 0, rng:NextNumber(-1.8, 1.8)) * scale
		TunnelProps.mushroom(m, at + off, size * rng:NextNumber(0.7, 1.4), size, palette, rng)
	end
	local glow = part(m, "ClusterGlow", Vector3.new(0.2, 0.2, 0.2), at + Vector3.new(0, 1.2 * scale, 0), Smooth, palette.cap)
	glow.Transparency = 1
	glow.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = 10 + 6 * scale
	light.Brightness = 1.2
	light.Color = palette.cap
	light.Parent = glow
	return m
end

-- Shelf fungi stacked on a wall at `at`, sticking out along `normal`.
function TunnelProps.bracketFungus(parent, at, normal, rng, palette)
	palette = palette or pick(GLOWS, rng)
	local m = model(parent, "BracketFungus")
	local flat = Vector3.new(normal.X, 0, normal.Z)
	if flat.Magnitude < 0.1 then
		return m
	end
	flat = flat.Unit
	for k = 0, rng:NextInteger(2, 5) do
		local w = rng:NextNumber(1.2, 3.2)
		local p = at + Vector3.new(rng:NextNumber(-0.8, 0.8), k * rng:NextNumber(0.7, 1.2), rng:NextNumber(-0.8, 0.8)) + flat * w * 0.25
		local shelf = ellipsoid(m, "BracketShelf", Vector3.new(w, w * 0.22, w * 0.9), CFrame.lookAt(p, p + flat) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, 0), Neon, jitter(palette.cap, rng, 0.1))
		shelf.Transparency = 0.15
		shelf.CanCollide = false
	end
	return m
end

-- Motes of light drifting in the air round a point.
function TunnelProps.spores(parent, center, radius, count, rng, palette)
	palette = palette or pick(GLOWS, rng)
	for _ = 1, count do
		local p = center + Vector3.new(rng:NextNumber(-radius, radius), rng:NextNumber(0, radius * 0.7), rng:NextNumber(-radius, radius))
		local mote = part(parent, "Spore", Vector3.one * rng:NextNumber(0.1, 0.28), p, Neon, palette.spot)
		mote.Shape = Enum.PartType.Ball
		mote.CanCollide = false
		mote.CastShadow = false
		mote.Transparency = rng:NextNumber(0.1, 0.5)
	end
end

-- Glowing tendrils hanging from the rock above `at` (found by ray).
function TunnelProps.tendrils(parent, at, count, rng, palette)
	palette = palette or pick(GLOWS, rng)
	for _ = 1, count do
		local from = at + Vector3.new(rng:NextNumber(-6, 6), 0, rng:NextNumber(-6, 6))
		local hit = workspace:Raycast(from, Vector3.new(0, 40, 0), terrainOnly)
		if hit then
			local len = rng:NextNumber(2, 8)
			local top = hit.Position
			local strand = cylinder(parent, "Tendril", len, rng:NextNumber(0.08, 0.18), CFrame.new(top - Vector3.new(0, len / 2, 0)) * UPRIGHT, Neon, jitter(palette.cap, rng, 0.1))
			strand.CanCollide = false
			strand.Transparency = 0.25
			local bead = part(parent, "TendrilBead", Vector3.one * 0.35, top - Vector3.new(0, len, 0), Neon, palette.spot)
			bead.Shape = Enum.PartType.Ball
			bead.CanCollide = false
		end
	end
end

-- Where the cave wall is, from `from` looking along `dir` (terrain only).
function TunnelProps.wallHit(from, dir, reach)
	return workspace:Raycast(from, dir.Unit * (reach or 30), terrainOnly)
end

function TunnelProps.floorAt(p, above)
	local hit = workspace:Raycast(p + Vector3.new(0, above or 6, 0), Vector3.new(0, -((above or 6) + 12), 0), terrainOnly)
	return if hit then hit.Position else p
end

return TunnelProps
