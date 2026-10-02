-- Fixtures for the department store's sales floors. The lower floors
-- (cosmetics, women's, men's, home, toys) get brand
-- counters with tester trays and backlit walls, clothes that hang like
-- clothes on proper rails, round racks and folded stacks, mannequins that
-- are real figures (Roblox's own character rig, faceless, posed and
-- dressed), room sets on the furniture floor, teddy bears, boxed toys and
-- capsule-toy machines. Higher up: restaurant booths, a ramen counter
-- under its noren, cafe tables; regional-fair stalls and sale wagons in
-- the event hall; double-sided book gondolas, POP-carded new-book
-- tables and magazine racks; and the gallery's framed paintings under
-- picture lights, marble statues, vitrines of pottery and a great moon
-- hung in the atrium.
--
-- Anything with a PropLibrary kind (Mannequin, Sofa, Bed, Plush, Plant)
-- uses your own model instead if there's one in ServerStorage >
-- PropLibrary (see PropLibrary.lua).
--
-- Builders take a frame on the floor (x across, -z the front).

local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local TunnelProps = require(script.Parent.TunnelProps)
local PropLibrary = require(script.Parent.PropLibrary)

local part, cylinder, model, jitter, pick, darken, place = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken, BuildUtil.place
local Metal, Smooth, Wood, Fabric, Glass, Plastic, Neon, Leather = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.Glass, Enum.Material.Plastic, Enum.Material.Neon, Enum.Material.Leather
local ellipsoid = TunnelProps.ellipsoid

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local FACING_Z = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder's axis along z
local STEEL = Color3.fromRGB(110, 112, 114)
local CHROME = Color3.fromRGB(200, 202, 206)
local GOLD = Color3.fromRGB(196, 160, 80)
local DARK = Color3.fromRGB(40, 40, 42)
local WHITE = Color3.fromRGB(238, 236, 230)
local GLASS = Color3.fromRGB(214, 226, 228)

local BRANDS = { "LUNÉ", "月白", "KOHAKU", "MIRAI", "SORA", "HANA", "AOI", "shiro", "YUKI", "LUMIÈRE" }
local BRAND_LOOKS = {
	{ bg = Color3.fromRGB(22, 22, 24), fg = WHITE },
	{ bg = WHITE, fg = Color3.fromRGB(30, 30, 34) },
	{ bg = Color3.fromRGB(180, 36, 56), fg = WHITE },
	{ bg = Color3.fromRGB(226, 212, 192), fg = Color3.fromRGB(90, 60, 40) },
	{ bg = Color3.fromRGB(36, 56, 86), fg = Color3.fromRGB(230, 220, 190) },
	{ bg = Color3.fromRGB(236, 210, 214), fg = Color3.fromRGB(120, 50, 70) },
}
local LIPSTICK = { Color3.fromRGB(180, 20, 40), Color3.fromRGB(210, 60, 90), Color3.fromRGB(150, 40, 50), Color3.fromRGB(220, 120, 130), Color3.fromRGB(120, 30, 40), Color3.fromRGB(200, 90, 70) }
local PRODUCT = { WHITE, Color3.fromRGB(30, 30, 32), Color3.fromRGB(220, 200, 170), Color3.fromRGB(200, 170, 180), Color3.fromRGB(170, 190, 210), GOLD }
local WOODS = { Color3.fromRGB(150, 112, 76), Color3.fromRGB(110, 80, 56), Color3.fromRGB(196, 170, 130), Color3.fromRGB(70, 52, 40) }
local SOFA_FABRICS = { Color3.fromRGB(120, 60, 50), Color3.fromRGB(60, 80, 100), Color3.fromRGB(150, 140, 120), Color3.fromRGB(70, 90, 70), Color3.fromRGB(190, 180, 164) }
local RUGS = { Color3.fromRGB(150, 60, 50), Color3.fromRGB(190, 170, 130), Color3.fromRGB(70, 90, 110), Color3.fromRGB(120, 110, 100) }
local TOYS = { Color3.fromRGB(230, 60, 50), Color3.fromRGB(60, 120, 220), Color3.fromRGB(240, 200, 50), Color3.fromRGB(80, 180, 90), Color3.fromRGB(240, 140, 180), Color3.fromRGB(250, 250, 240) }
local FURS = { Color3.fromRGB(170, 120, 70), Color3.fromRGB(210, 180, 140), Color3.fromRGB(240, 236, 226), Color3.fromRGB(110, 76, 50), Color3.fromRGB(236, 170, 190), Color3.fromRGB(150, 180, 220) }
local SHOES = { Color3.fromRGB(30, 24, 20), Color3.fromRGB(90, 56, 34), Color3.fromRGB(140, 30, 30), Color3.fromRGB(230, 226, 216), Color3.fromRGB(40, 40, 44) }
local DENIM = Color3.fromRGB(58, 76, 112)

local Fixtures = {}

-- ===== Helpers =====

local function at(parent, name, cf, x, y, z, size, material, color)
	return part(parent, name, size, cf * CFrame.new(x, y, z), material, color)
end

-- Small stuff you shouldn't trip over.
local function deco(p)
	if p then
		p.CanCollide = false
	end
	return p
end

-- A cylinder standing upright, centred at (x, y, z) in cf.
local function upright(parent, name, h, d, cf, x, y, z, material, color)
	return cylinder(parent, name, h, d, cf * CFrame.new(x, y, z) * UPRIGHT, material, color)
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
Fixtures.label = label
Fixtures.rod, Fixtures.upright, Fixtures.deco, Fixtures.at = rod, upright, deco, at

-- A price card on a little acrylic stand.
local function priceCard(parent, cf, text)
	deco(at(parent, "CardFoot", cf, 0, 0.03, 0, Vector3.new(0.7, 0.06, 0.4), Glass, GLASS)).Transparency = 0.4
	label(parent, cf * CFrame.new(0, 0.36, 0) * CFrame.Angles(math.rad(-12), 0, 0), Vector3.new(0.9, 0.6, 0.04), Enum.NormalId.Front, text, WHITE, Color3.fromRGB(30, 30, 34))
end

-- A glass-shelved unit: back, sides, `levels` shelves. Returns the
-- shelves' frames (on each shelf's top surface, centred).
local function shelfFrame(b, cf, len, h, d, levels, color, material)
	at(b, "ShelfBack", cf, 0, h / 2, d / 2 - 0.05, Vector3.new(len, h, 0.1), material or Wood, color)
	for _, s in ipairs({ -1, 1 }) do
		at(b, "ShelfSide", cf, s * (len / 2 + 0.06), h / 2, 0, Vector3.new(0.12, h, d), material or Wood, color)
	end
	local tops = {}
	for level = 0, levels - 1 do
		local y = 0.3 + level * (h - 0.6) / math.max(1, levels - 1)
		at(b, "Shelf", cf, 0, y - 0.05, 0, Vector3.new(len, 0.1, d - 0.1), material or Wood, color)
		table.insert(tops, cf * CFrame.new(0, y, -0.05))
	end
	return tops
end

-- ===== Cosmetics =====

local function barStool(b, cf, rng)
	if rng:NextNumber() < 0.2 then
		-- knocked over
		cf = cf * CFrame.new(0, 0.65, 0) * CFrame.Angles(0, rng:NextNumber(0, 6), 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, -1.3, 0)
	end
	upright(b, "StoolFoot", 0.1, 1.4, cf, 0, 0.05, 0, Metal, CHROME)
	upright(b, "StoolPole", 2.2, 0.16, cf, 0, 1.2, 0, Metal, CHROME)
	upright(b, "StoolSeat", 0.35, 1.3, cf, 0, 2.45, 0, Leather, pick({ DARK, WHITE, Color3.fromRGB(150, 40, 50) }, rng))
end

-- A brand's counter: lacquered counter with a glass top and a light strip,
-- a stepped tester tray of lipsticks, a round mirror, stools in front,
-- and behind it the brand's own wall with its name and shelves of product.
function Fixtures.beautyCounter(m, cf, rng)
	local b = model(m, "BeautyCounter")
	local look = pick(BRAND_LOOKS, rng)
	at(b, "Kick", cf, 0, 0.15, 0, Vector3.new(5.4, 0.3, 2), Smooth, DARK)
	local counter = at(b, "Counter", cf, 0, 1.65, 0, Vector3.new(5.6, 2.7, 2.2), Smooth, look.bg)
	counter.Reflectance = 0.08
	local cracked = rng:NextNumber() < 0.15
	if not cracked then
		at(b, "CounterTop", cf, 0, 3.05, 0, Vector3.new(5.8, 0.1, 2.4), Glass, GLASS).Transparency = 0.35
	else
		for _ = 1, 4 do
			deco(at(b, "GlassShard", cf * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(-2.5, 2.5), 0.03, rng:NextNumber(-2.6, -1.4), Vector3.new(rng:NextNumber(0.3, 0.9), 0.04, rng:NextNumber(0.3, 0.7)), Glass, GLASS)).Transparency = 0.3
		end
	end
	deco(at(b, "LightStrip", cf, 0, 2.85, -1.13, Vector3.new(5.4, 0.08, 0.05), Neon, Color3.fromRGB(250, 244, 230)))
	-- The brand wall.
	local wall = at(b, "BrandWall", cf, 0, 3.6, 2.6, Vector3.new(5.6, 7.2, 0.4), Smooth, look.bg)
	wall.Reflectance = 0.05
	label(b, cf * CFrame.new(0, 6.4, 2.37), Vector3.new(4, 0.9, 0.05), Enum.NormalId.Front, pick(BRANDS, rng), look.bg, look.fg, Smooth, Enum.Font.Garamond)
	deco(at(b, "WallGlow", cf, 0, 5.85, 2.37, Vector3.new(4.6, 0.06, 0.05), Neon, Color3.fromRGB(250, 244, 230)))
	for _, y in ipairs({ 4.1, 5.1 }) do
		at(b, "WallShelf", cf, 0, y, 2.05, Vector3.new(5, 0.08, 0.7), Glass, GLASS).Transparency = 0.4
		for i = -2, 2 do
			if rng:NextNumber() < 0.85 then
				local h = rng:NextNumber(0.4, 0.75)
				local c = jitter(pick(PRODUCT, rng), rng, 0.08)
				if rng:NextNumber() < 0.5 then
					deco(upright(b, "Product", h, rng:NextNumber(0.25, 0.4), cf, i * 0.95, y + 0.04 + h / 2, 2.05, Smooth, c))
				else
					deco(at(b, "Product", cf, i * 0.95, y + 0.04 + h / 2, 2.05, Vector3.new(0.5, h, 0.35), Smooth, c))
				end
			end
		end
	end
	-- Tester tray and lipsticks.
	if not cracked then
		at(b, "TesterStep", cf, 0, 3.25, -0.2, Vector3.new(3.6, 0.3, 0.9), Glass, Color3.fromRGB(232, 236, 238)).Transparency = 0.2
		at(b, "TesterStep", cf, 0, 3.55, 0.15, Vector3.new(3.6, 0.3, 0.45), Glass, Color3.fromRGB(232, 236, 238)).Transparency = 0.2
		for _, row in ipairs({ { y = 3.4, z = -0.4 }, { y = 3.7, z = 0.15 } }) do
			for i = 0, 5 do
				if rng:NextNumber() < 0.85 then
					local x = -1.5 + i * 0.6
					local c = pick(LIPSTICK, rng)
					if rng:NextNumber() < 0.15 then
						deco(cylinder(b, "Lipstick", 0.35, 0.14, cf * CFrame.new(x, row.y + 0.07, row.z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, c))
					else
						deco(upright(b, "Lipstick", 0.35, 0.14, cf, x, row.y + 0.175, row.z, Smooth, c))
					end
				end
			end
		end
		deco(rod(b, "MirrorStem", (cf * CFrame.new(2.3, 3.1, 0.3)).Position, (cf * CFrame.new(2.3, 3.5, 0.3)).Position, 0.1, Metal, CHROME))
		local mirror = cylinder(b, "Mirror", 0.06, 1.1, cf * CFrame.new(2.3, 4, 0.3) * FACING_Z, Smooth, Color3.fromRGB(200, 206, 210))
		mirror.Reflectance = 0.6
		deco(mirror)
	end
	for _, x in ipairs({ -1.4, 1.4 }) do
		barStool(b, cf * CFrame.new(x + rng:NextNumber(-0.3, 0.3), 0, -2.2 + rng:NextNumber(-0.3, 0.2)), rng)
	end
end

-- A round, tiered perfume island: bottles round the lower tier and on
-- the riser, a glowing ring under the glass.
function Fixtures.perfumeIsland(m, cf, rng)
	local b = model(m, "PerfumeIsland")
	upright(b, "IslandBase", 0.4, 4.2, cf, 0, 0.2, 0, Smooth, DARK)
	upright(b, "IslandTier", 2.4, 3.4, cf, 0, 1.6, 0, Smooth, WHITE).Reflectance = 0.06
	deco(upright(b, "IslandGlow", 0.1, 3.45, cf, 0, 2.7, 0, Neon, Color3.fromRGB(250, 236, 210)))
	upright(b, "IslandTop", 0.12, 3.6, cf, 0, 2.86, 0, Glass, GLASS).Transparency = 0.3
	upright(b, "IslandRiser", 1.2, 1.4, cf, 0, 3.52, 0, Smooth, WHITE)
	upright(b, "RiserTop", 0.08, 1.6, cf, 0, 4.16, 0, Glass, GLASS).Transparency = 0.3
	local function bottle(x, yBase, z)
		local tint = pick({ Color3.fromRGB(230, 190, 120), Color3.fromRGB(190, 120, 200), Color3.fromRGB(120, 200, 220), Color3.fromRGB(240, 200, 210), Color3.fromRGB(200, 220, 190) }, rng)
		local w, h = rng:NextNumber(0.3, 0.45), rng:NextNumber(0.45, 0.7)
		local spin = CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		deco(part(b, "Perfume", Vector3.new(w, h, w * 0.6), cf * CFrame.new(x, yBase + h / 2, z) * spin, Glass, tint)).Transparency = 0.25
		deco(cylinder(b, "PerfumeCap", 0.16, rng:NextNumber(0.14, 0.22), cf * CFrame.new(x, yBase + h + 0.08, z) * UPRIGHT, Metal, pick({ GOLD, CHROME, DARK }, rng)))
	end
	for k = 0, 5 do
		if rng:NextNumber() < 0.85 then
			local a = k / 6 * math.pi * 2
			bottle(math.cos(a) * 1.3, 2.92, math.sin(a) * 1.3)
		end
	end
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + 0.5
		bottle(math.cos(a) * 0.4, 4.2, math.sin(a) * 0.4)
	end
end

-- ===== Clothes =====

-- One garment on a hanger, hanging from a rail at railY along x; seen
-- side-on it's a thin panel across the rail. style: "top", "dress",
-- "coat", "jacket".
local function garment(b, cf, x, railY, color, rng, style)
	local g = cf * CFrame.new(x, railY, 0) * CFrame.Angles(math.rad(rng:NextNumber(-3, 3)), 0, math.rad(rng:NextNumber(-3, 3)))
	local long = if style == "coat" then 3.4 elseif style == "dress" then 3 elseif style == "jacket" then 2.5 else 2.1
	local wide = if style == "jacket" or style == "coat" then 1.6 else 1.35
	deco(part(b, "Hanger", Vector3.new(0.08, 0.1, wide - 0.1), g * CFrame.new(0, -0.22, 0), Wood, Color3.fromRGB(150, 120, 86)))
	deco(part(b, "Shoulders", Vector3.new(0.16, 0.4, wide), g * CFrame.new(0, -0.47, 0), Fabric, color))
	deco(part(b, "Garment", Vector3.new(0.14, long - 0.4, wide - 0.15), g * CFrame.new(0, -0.67 - (long - 0.4) / 2, 0), Fabric, color))
	if style == "dress" then
		deco(part(b, "Hem", Vector3.new(0.15, 0.8, wide + 0.35), g * CFrame.new(0, -long - 0.1, 0), Fabric, color))
	elseif style == "jacket" and rng:NextNumber() < 0.7 then
		-- a shirt collar showing at the neck
		deco(part(b, "Collar", Vector3.new(0.18, 0.2, 0.5), g * CFrame.new(0, -0.32, -0.2), Smooth, WHITE))
	end
end

-- A straight rail on two chrome uprights, hung with one line in a couple
-- of colours; the odd thing dropped on the floor, a size divider.
function Fixtures.clothesRack(m, cf, rng, palette, style, len)
	local b = model(m, "ClothesRack")
	len = len or rng:NextNumber(4, 6)
	style = style or "top"
	local railY = if style == "coat" or style == "dress" then 5.4 else 4.8
	for _, s in ipairs({ -1, 1 }) do
		at(b, "RackFoot", cf, s * len / 2, 0.06, 0, Vector3.new(0.2, 0.12, 1.8), Metal, CHROME)
		upright(b, "RackUpright", railY, 0.14, cf, s * len / 2, railY / 2, 0, Metal, CHROME)
	end
	cylinder(b, "RackRail", len + 0.2, 0.12, cf * CFrame.new(0, railY, 0), Metal, CHROME)
	local main, alt = pick(palette, rng), pick(palette, rng)
	local spacing = 0.34
	local n = math.floor((len - 0.6) / spacing)
	for k = 0, n - 1 do
		if rng:NextNumber() < 0.78 then
			local c = if rng:NextNumber() < 0.65 then main else alt
			garment(b, cf, -len / 2 + 0.3 + k * spacing, railY, jitter(c, rng, 0.05), rng, style)
		end
	end
	if rng:NextNumber() < 0.5 then
		label(b, cf * CFrame.new(-len / 2 + 1.2, railY + 0.02, 0), Vector3.new(0.05, 0.7, 0.7), Enum.NormalId.Left, pick({ "S", "M", "L", "LL" }, rng), WHITE, DARK)
	end
	if rng:NextNumber() < 0.35 then
		deco(at(b, "DroppedGarment", cf * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rng:NextNumber(-1.5, 1.5), 0.06, rng:NextNumber(-1.8, -1), Vector3.new(1.4, 0.12, 2.2), Fabric, main))
		deco(at(b, "DroppedHanger", cf * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rng:NextNumber(-1.5, 1.5), 0.05, rng:NextNumber(1, 1.8), Vector3.new(1.3, 0.1, 0.08), Plastic, DARK))
	end
end

-- A round rack: garments hanging all the way round a ring on a centre pole.
function Fixtures.roundRack(m, cf, rng, palette, style)
	local b = model(m, "RoundRack")
	local r, railY = 1.9, if style == "dress" or style == "coat" then 5.2 else 4.6
	upright(b, "RackBase", 0.12, 1.6, cf, 0, 0.06, 0, Metal, CHROME)
	upright(b, "RackPole", railY, 0.2, cf, 0, railY / 2, 0, Metal, CHROME)
	local function ring(a)
		return (cf * CFrame.new(math.cos(a) * r, railY, math.sin(a) * r)).Position
	end
	for k = 0, 7 do
		rod(b, "RackRing", ring(k / 8 * math.pi * 2), ring((k + 1) / 8 * math.pi * 2), 0.1, Metal, CHROME)
	end
	for k = 0, 1 do
		rod(b, "RackSpoke", ring(k * math.pi), ring(k * math.pi + math.pi), 0.08, Metal, CHROME)
	end
	local main, alt = pick(palette, rng), pick(palette, rng)
	local n = 16
	for k = 0, n - 1 do
		if rng:NextNumber() < 0.72 then
			local a = k / n * math.pi * 2
			local g = cf * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, math.pi / 2 - a, 0)
			garment(b, g, 0, railY, jitter(if rng:NextNumber() < 0.6 then main else alt, rng, 0.05), rng, style)
		end
	end
end

-- Two display tables side by side (one taller) with folded stacks on
-- them; shirts get collars.
function Fixtures.displayTable(m, cf, rng, palette, shirts)
	local b = model(m, "DisplayTable")
	local wood = pick({ Color3.fromRGB(226, 218, 202), Color3.fromRGB(120, 88, 60), WHITE }, rng)
	local function tbl(x, w, d, h)
		at(b, "TableTop", cf, x, h - 0.1, 0, Vector3.new(w, 0.2, d), Wood, wood)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				at(b, "TableLeg", cf, x + sx * (w / 2 - 0.2), (h - 0.2) / 2, sz * (d / 2 - 0.2), Vector3.new(0.2, h - 0.2, 0.2), Wood, darken(wood, 0.8))
			end
		end
		return h
	end
	local function stacks(x0, x1, d, top)
		for x = x0 + 0.7, x1 - 0.6, 1.3 do
			for z = -d / 2 + 0.6, d / 2 - 0.5, 1.05 do
				if rng:NextNumber() < 0.85 then
					local c = jitter(pick(palette, rng), rng, 0.05)
					local y = top
					for _ = 1, rng:NextInteger(1, 5) do
						local fold = cf * CFrame.new(x + rng:NextNumber(-0.06, 0.06), y + 0.09, z) * CFrame.Angles(0, math.rad(rng:NextNumber(-5, 5)), 0)
						deco(part(b, "Folded", Vector3.new(1.1, 0.18, 0.85), fold, Fabric, c))
						y += 0.18
					end
					if shirts then
						deco(part(b, "Collar", Vector3.new(0.45, 0.06, 0.14), cf * CFrame.new(x, y + 0.03, z - 0.2), Smooth, if rng:NextNumber() < 0.5 then WHITE else c))
					end
				end
			end
		end
	end
	stacks(-3.4, 0.2, 3, tbl(-1.6, 3.6, 3, 2.6))
	stacks(0.8, 3.4, 2.2, tbl(2.1, 2.6, 2.2, 3.4))
	priceCard(b, cf * CFrame.new(-2.8, 2.6, -1.2), pick({ "¥3,900", "¥4,900", "¥2,990", "30%OFF" }, rng))
end

-- ===== Mannequins =====

local SKINS = { Color3.fromRGB(240, 238, 234), Color3.fromRGB(236, 232, 226), Color3.fromRGB(38, 38, 40), Color3.fromRGB(214, 200, 182) }
-- Joint rotations for the rig (see PropLibrary.pose).
local POSES = {
	{ LeftShoulder = CFrame.Angles(0, 0, -0.12), RightShoulder = CFrame.Angles(0, 0, 0.12) },
	{ RightShoulder = CFrame.Angles(0, 0, 0.55), RightElbow = CFrame.Angles(0, 0, -1.5), Neck = CFrame.Angles(0, 0.35, 0.06), LeftHip = CFrame.Angles(0, 0, -0.06) },
	{ LeftShoulder = CFrame.Angles(0.8, 0, -0.1), LeftElbow = CFrame.Angles(0.6, 0, 0), RightHip = CFrame.Angles(0.15, 0, 0.04), RightKnee = CFrame.Angles(-0.25, 0, 0), Neck = CFrame.Angles(-0.08, -0.3, 0) },
	{ LeftShoulder = CFrame.Angles(0, 0, -0.5), LeftElbow = CFrame.Angles(0, 0, 1.5), RightShoulder = CFrame.Angles(0, 0, 0.5), RightElbow = CFrame.Angles(0, 0, -1.5), LeftHip = CFrame.Angles(0, 0, -0.08), RightHip = CFrame.Angles(0, 0, 0.08) },
	{ Waist = CFrame.Angles(0, 0.15, 0), RightShoulder = CFrame.Angles(-0.25, 0, 0.1), LeftShoulder = CFrame.Angles(0.3, 0, -0.08), LeftElbow = CFrame.Angles(0.35, 0, 0), Neck = CFrame.Angles(0.1, 0.4, 0) },
}

local function paint(rig, names, color, material)
	for _, n in ipairs(names) do
		local p = rig:FindFirstChild(n)
		if p then
			p.Color = color
			p.Material = material
			p.Reflectance = 0
		end
	end
end

-- Colour a posed rig's body parts as clothes, and add what the body
-- can't show (a skirt, a shirt front and tie).
local function dress(rig, outfit, palette, rng)
	local a = jitter(pick(palette, rng), rng, 0.06)
	local c = jitter(pick(palette, rng), rng, 0.06)
	local torso, hips = rig:FindFirstChild("UpperTorso"), rig:FindFirstChild("LowerTorso")
	local skirt = false
	if outfit == "dress" then
		paint(rig, { "UpperTorso", "LowerTorso", "LeftUpperLeg", "RightUpperLeg" }, a, Fabric)
		if rng:NextNumber() < 0.5 then
			paint(rig, { "LeftUpperArm", "RightUpperArm" }, a, Fabric)
		end
		skirt = a
	elseif outfit == "blouse" then
		paint(rig, { "UpperTorso", "LeftUpperArm", "RightUpperArm" }, a, Fabric)
		if rng:NextNumber() < 0.5 then
			paint(rig, { "LeftLowerArm", "RightLowerArm" }, a, Fabric)
		end
		paint(rig, { "LowerTorso", "LeftUpperLeg", "RightUpperLeg" }, c, Fabric)
		if rng:NextNumber() < 0.5 then
			paint(rig, { "LeftLowerLeg", "RightLowerLeg" }, c, Fabric)
		else
			skirt = c
		end
	elseif outfit == "suit" then
		paint(rig, { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }, a, Fabric)
		paint(rig, { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }, darken(a, 0.92), Fabric)
		if torso then
			local front = torso.CFrame * CFrame.new(0, torso.Size.Y * 0.18, -torso.Size.Z / 2 - 0.02)
			deco(part(rig, "ShirtFront", Vector3.new(torso.Size.X * 0.28, torso.Size.Y * 0.55, 0.04), front, Smooth, WHITE))
			deco(part(rig, "Tie", Vector3.new(torso.Size.X * 0.09, torso.Size.Y * 0.5, 0.04), front * CFrame.new(0, -0.03, -0.03), Fabric, pick({ Color3.fromRGB(150, 30, 40), Color3.fromRGB(30, 50, 100), Color3.fromRGB(120, 110, 60) }, rng)))
		end
	elseif outfit == "casual" then
		paint(rig, { "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }, a, Fabric)
		paint(rig, { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }, jitter(DENIM, rng, 0.1), Fabric)
	end
	if outfit ~= "bare" then
		paint(rig, { "LeftFoot", "RightFoot" }, pick(SHOES, rng), Leather)
	end
	if skirt and hips then
		deco(ellipsoid(rig, "Skirt", Vector3.new(hips.Size.X * 1.3, 2.3, hips.Size.Z * 1.6), hips.CFrame * CFrame.new(0, -0.55, 0), Fabric, skirt))
	end
end

-- The old kind of mannequin: a dress form on a pole, for when the rig
-- can't be made.
local function dressForm(b, cf, rng, palette)
	local skin = pick(SKINS, rng)
	cylinder(b, "FormBase", 0.12, 1.4, cf * CFrame.new(0, 0.06, 0) * UPRIGHT, Metal, STEEL)
	cylinder(b, "FormPole", 2.2, 0.14, cf * CFrame.new(0, 1.2, 0) * UPRIGHT, Metal, STEEL)
	local cloth = pick(palette, rng)
	ellipsoid(b, "FormHips", Vector3.new(1.5, 1.2, 0.9), cf * CFrame.new(0, 2.8, 0), Smooth, if rng:NextNumber() < 0.6 then cloth else skin)
	ellipsoid(b, "FormTorso", Vector3.new(1.5, 2.2, 0.9), cf * CFrame.new(0, 4, 0), Fabric, cloth)
end

local function stand(b, cf)
	upright(b, "MannequinStand", 0.12, 1.7, cf, 0, 0.06, 0, Metal, CHROME)
	upright(b, "MannequinRod", 1.5, 0.12, cf, 0, 0.85, 0.35, Metal, CHROME)
end

-- A mannequin in an outfit ("dress", "blouse", "suit", "casual" or
-- "bare") from the palette, on a chrome stand. Some have lost their head
-- or an arm; some have toppled over (not when `steady`).
function Fixtures.mannequin(m, cf, rng, outfit, palette, steady)
	local b = model(m, "Mannequin")
	local fallen = not steady and rng:NextNumber() < 0.15
	local target = if fallen then cf * CFrame.new(0, 0.55, 2.4) * CFrame.Angles(math.rad(-90), 0, 0) else cf * CFrame.new(0, 0.12, 0)
	if not fallen then
		stand(b, cf)
	end
	if PropLibrary.place(b, "Mannequin", target, rng, rng:NextNumber(5.4, 6)) then
		return b
	end
	local rig = PropLibrary.rig()
	if not rig then
		dressForm(b, cf, rng, palette)
		return b
	end
	rig.Parent = b
	PropLibrary.pose(rig, if fallen then POSES[1] else pick(POSES, rng))
	local skin = pick(SKINS, rng)
	for _, n in ipairs(PropLibrary.BODY) do
		local p = rig:FindFirstChild(n)
		if p then
			p.Color = skin
			p.Material = Smooth
			p.Reflectance = 0.04
		end
	end
	dress(rig, outfit, palette, rng)
	local roll = rng:NextNumber()
	local lost = if roll < 0.2 then { "Head" } elseif roll < 0.28 then { "LeftUpperArm", "LeftLowerArm", "LeftHand" } elseif roll < 0.34 then { "RightUpperArm", "RightLowerArm", "RightHand" } else {}
	for _, n in ipairs(lost) do
		local p = rig:FindFirstChild(n)
		if p then
			p:Destroy()
		end
	end
	local hips = rig:FindFirstChild("LowerTorso")
	if hips then
		rig.WorldPivot = hips.CFrame
	end
	local ok, err = pcall(PropLibrary.fit, rig, target, nil)
	if not ok then
		warn("[StoreFixtures] mannequin: " .. tostring(err))
		rig:Destroy()
		dressForm(b, cf, rng, palette)
	end
	if fallen and rng:NextNumber() < 0.7 then
		-- its stand, knocked over beside it
		upright(b, "MannequinStand", 0.12, 1.7, cf, rng:NextNumber(-1.5, 1.5), 0.06, rng:NextNumber(-1, 0), Metal, CHROME)
	end
	return b
end

-- Two or three mannequins on a low plinth, a sign in front.
function Fixtures.mannequinGroup(m, cf, rng, outfits, palette)
	local b = model(m, "MannequinGroup")
	at(b, "Plinth", cf, 0, 0.3, 0, Vector3.new(6, 0.6, 3.4), Smooth, pick({ WHITE, DARK, Color3.fromRGB(200, 190, 170) }, rng)).Reflectance = 0.05
	local n = rng:NextInteger(2, 3)
	for k = 1, n do
		local x = (k - (n + 1) / 2) * 1.9
		Fixtures.mannequin(b, cf * CFrame.new(x, 0.6, rng:NextNumber(-0.4, 0.4)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), rng, pick(outfits, rng), palette, true)
	end
	label(b, cf * CFrame.new(0, 0.35, -1.75), Vector3.new(3, 0.5, 0.05), Enum.NormalId.Front, pick({ "NEW COLLECTION", "春夏コレクション", "秋冬の新作", "SPECIAL SELECTION" }, rng), DARK, WHITE)
end

-- ===== Men's =====

local function shoe(b, cf, color, heel)
	deco(part(b, "Sole", Vector3.new(0.34, 0.06, 0.95), cf * CFrame.new(0, 0.03, 0), Smooth, DARK))
	deco(ellipsoid(b, "ShoeUpper", Vector3.new(0.34, 0.36, 0.9), cf * CFrame.new(0, 0.2, 0.03), Leather, color))
	if heel then
		deco(part(b, "Heel", Vector3.new(0.12, 0.45, 0.14), cf * CFrame.new(0, 0.22, 0.4), Smooth, DARK))
	end
end

-- A wall of sloping shoe shelves, pairs set out on them.
function Fixtures.shoeWall(m, cf, rng, heels)
	local b = model(m, "ShoeWall")
	local len, h = 5.4, 6.4
	local wood = pick(WOODS, rng)
	at(b, "ShoeWallBack", cf, 0, h / 2, 0.8, Vector3.new(len, h, 0.2), Wood, wood)
	for _, s in ipairs({ -1, 1 }) do
		at(b, "ShoeWallSide", cf, s * (len / 2 + 0.06), h / 2, 0.2, Vector3.new(0.12, h, 1.4), Wood, darken(wood, 0.9))
	end
	for level = 0, 3 do
		local shelf = cf * CFrame.new(0, 0.6 + level * 1.4, 0.15) * CFrame.Angles(math.rad(-10), 0, 0)
		part(b, "ShoeShelf", Vector3.new(len - 0.1, 0.08, 1.2), shelf, Glass, GLASS).Transparency = 0.35
		for x = -len / 2 + 0.7, len / 2 - 0.6, 1.1 do
			if rng:NextNumber() < 0.75 then
				local c = pick(SHOES, rng)
				for _, dx in ipairs({ -0.2, 0.2 }) do
					shoe(b, shelf * CFrame.new(x + dx, 0.04, 0) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), c, heels)
				end
			end
		end
	end
end

-- A slanted glass case of ties.
function Fixtures.tieCase(m, cf, rng)
	local b = model(m, "TieCase")
	local wood = pick(WOODS, rng)
	at(b, "CaseBody", cf, 0, 1.4, 0, Vector3.new(4.4, 2.8, 2.2), Wood, wood)
	at(b, "CaseBack", cf, 0, 3.2, 1.05, Vector3.new(4.4, 0.8, 0.1), Wood, wood)
	local slope = cf * CFrame.new(0, 3.2, 0) * CFrame.Angles(math.rad(-18), 0, 0)
	part(b, "CaseTray", Vector3.new(4.2, 0.1, 2.2), slope, Fabric, Color3.fromRGB(30, 34, 50))
	for k = 0, 8 do
		if rng:NextNumber() < 0.85 then
			local c = jitter(pick({ Color3.fromRGB(150, 30, 40), Color3.fromRGB(30, 50, 100), Color3.fromRGB(120, 110, 60), Color3.fromRGB(60, 90, 60), Color3.fromRGB(90, 40, 90), Color3.fromRGB(180, 150, 90) }, rng), rng, 0.08)
			deco(part(b, "Tie", Vector3.new(0.3, 0.03, 1.6), slope * CFrame.new(-1.8 + k * 0.45, 0.07, 0.1), Fabric, c))
			deco(part(b, "TieKnot", Vector3.new(0.22, 0.08, 0.2), slope * CFrame.new(-1.8 + k * 0.45, 0.09, 0.95), Fabric, c))
		end
	end
	if rng:NextNumber() < 0.75 then
		part(b, "CaseLid", Vector3.new(4.3, 0.06, 2.2), slope * CFrame.new(0, 0.45, 0), Glass, GLASS).Transparency = 0.6
	end
end

-- A fitting bench with a low, tilted foot mirror.
function Fixtures.shoeBench(m, cf, rng)
	local b = model(m, "ShoeBench")
	at(b, "BenchBase", cf, 0, 0.45, 0, Vector3.new(5, 0.9, 1.4), Wood, pick(WOODS, rng))
	at(b, "BenchSeat", cf, 0, 1.05, 0, Vector3.new(5, 0.3, 1.6), Leather, Color3.fromRGB(60, 50, 44))
	for _, x in ipairs({ -1.6, 1.6 }) do
		at(b, "FootStool", cf, x, 0.35, -1.8, Vector3.new(0.9, 0.7, 0.9), Leather, Color3.fromRGB(60, 50, 44))
	end
	local mirror = part(b, "FootMirror", Vector3.new(1.4, 1.6, 0.08), cf * CFrame.new(0, 0.85, -2.6) * CFrame.Angles(math.rad(-15), 0, 0), Smooth, Color3.fromRGB(200, 206, 210))
	mirror.Reflectance = 0.6
	if rng:NextNumber() < 0.5 then
		shoe(b, cf * CFrame.new(rng:NextNumber(-2, 2), 0, -1) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), pick(SHOES, rng), false)
	end
end

-- ===== Home =====

local function floorLamp(b, cf, rng, lit)
	upright(b, "LampBase", 0.12, 1.1, cf, 0, 0.06, 0, Metal, DARK)
	upright(b, "LampPole", 5, 0.12, cf, 0, 2.6, 0, Metal, pick({ GOLD, DARK, CHROME }, rng))
	deco(upright(b, "LampShade", 1.2, 1.5, cf, 0, 5.5, 0, if lit then Neon else Fabric, if lit then Color3.fromRGB(250, 230, 190) else pick({ WHITE, Color3.fromRGB(226, 214, 190), Color3.fromRGB(190, 170, 140) }, rng)))
end

local function tableLamp(b, cf, rng)
	deco(upright(b, "LampBase", 0.7, 0.6, cf, 0, 0.35, 0, Smooth, pick({ WHITE, DARK, Color3.fromRGB(150, 110, 70), Color3.fromRGB(90, 120, 140) }, rng)))
	deco(upright(b, "LampStem", 0.5, 0.1, cf, 0, 0.95, 0, Metal, GOLD))
	deco(upright(b, "LampShade", 0.7, 1, cf, 0, 1.45, 0, Fabric, pick({ WHITE, Color3.fromRGB(226, 214, 190) }, rng)))
end

local function plant(b, cf, rng)
	if not PropLibrary.place(b, "Plant", cf, rng, rng:NextNumber(3.5, 5.5), 2.5) then
		Props.pottedPlant(b, cf.Position, rng, rng:NextNumber() < 0.4)
	end
end

-- A living room set on a rug: sofa with cushions, an armchair, a coffee
-- table with a vase and books, a floor lamp, a plant, a price.
function Fixtures.livingSet(m, cf, rng)
	local b = model(m, "LivingSet")
	local yaw = select(2, cf:ToEulerAnglesYXZ())
	local rug = pick(RUGS, rng)
	deco(at(b, "Rug", cf, 0, 0.03, -2.2, Vector3.new(7.5, 0.05, 5.5), Fabric, rug))
	deco(at(b, "RugBorder", cf, 0, 0.025, -2.2, Vector3.new(7.9, 0.04, 5.9), Fabric, darken(rug, 0.7)))
	if not PropLibrary.place(b, "Sofa", cf * CFrame.new(0, 0, 0.6), rng, nil, 6.5) then
		local fabric = pick(SOFA_FABRICS, rng)
		local at0 = (cf * CFrame.new(0, 0, 0.6)).Position
		place(Props.sofa(b, at0, fabric, Color3.fromRGB(90, 70, 50), 6.5), at0, Vector3.zero, yaw + math.pi / 2)
		for _, x in ipairs({ -2.1, 2.1 }) do
			deco(ellipsoid(b, "Cushion", Vector3.new(1.3, 1.2, 0.45), cf * CFrame.new(x + rng:NextNumber(-0.2, 0.2), 2.5, 1.2) * CFrame.Angles(math.rad(-15), 0, math.rad(rng:NextNumber(-12, 12))), Fabric, pick(SOFA_FABRICS, rng)))
		end
		local at1 = (cf * CFrame.new(3.4, 0, -2.4)).Position
		place(Props.sofa(b, at1, fabric, Color3.fromRGB(90, 70, 50), 3.2), at1, Vector3.zero, yaw + math.pi + rng:NextNumber(-0.3, 0.3))
	end
	local wood = pick(WOODS, rng)
	local at2 = (cf * CFrame.new(0, 0, -2.6)).Position
	place(Props.table(b, at2, Vector3.new(3.6, 1.4, 2), wood, wood), at2, Vector3.zero, yaw)
	deco(upright(b, "Vase", 0.9, 0.45, cf, -1, 1.85, -2.6, Smooth, pick({ WHITE, Color3.fromRGB(60, 90, 110), Color3.fromRGB(170, 90, 60) }, rng)))
	for k = 0, 1 do
		deco(at(b, "CoffeeTableBook", cf * CFrame.Angles(0, math.rad(rng:NextNumber(-10, 10)), 0), 0.7, 1.46 + k * 0.14, -2.6, Vector3.new(1.3, 0.14, 1), Smooth, pick({ Color3.fromRGB(150, 40, 40), Color3.fromRGB(230, 226, 210), Color3.fromRGB(40, 60, 90) }, rng)))
	end
	priceCard(b, cf * CFrame.new(1.2, 1.4, -3.1), pick({ "¥198,000", "¥298,000", "¥89,800", "展示品" }, rng))
	floorLamp(b, cf * CFrame.new(-3.8, 0, 1), rng, rng:NextNumber() < 0.2)
	plant(b, cf * CFrame.new(3.8, 0, 1.3), rng)
end

-- A made-up bed with bedside tables and lamps, a bench at its foot.
function Fixtures.bedroomSet(m, cf, rng)
	local b = model(m, "BedroomSet")
	local wood = pick(WOODS, rng)
	deco(at(b, "Rug", cf, 0, 0.03, -0.5, Vector3.new(7.4, 0.05, 7.4), Fabric, pick(RUGS, rng)))
	if not PropLibrary.place(b, "Bed", cf, rng, nil, 7) then
		at(b, "BedFrame", cf, 0, 0.6, 0, Vector3.new(4.6, 1.2, 6.6), Wood, wood)
		at(b, "Headboard", cf, 0, 2.2, 3.3, Vector3.new(4.8, 4.4, 0.3), Wood, darken(wood, 0.9))
		at(b, "Mattress", cf, 0, 1.55, 0, Vector3.new(4.3, 0.7, 6.3), Fabric, Color3.fromRGB(236, 232, 222))
		local cover = pick({ Color3.fromRGB(90, 110, 150), Color3.fromRGB(200, 170, 150), Color3.fromRGB(120, 140, 110), Color3.fromRGB(230, 226, 216) }, rng)
		deco(at(b, "Duvet", cf, 0, 2.0, -0.6, Vector3.new(4.45, 0.28, 5.1), Fabric, cover))
		deco(at(b, "DuvetFold", cf, 0, 2.18, 1.7, Vector3.new(4.55, 0.2, 0.7), Fabric, cover:Lerp(Color3.new(1, 1, 1), 0.4)))
		deco(at(b, "Throw", cf, 0, 2.2, -2.2, Vector3.new(4.6, 0.12, 1.3), Fabric, pick(RUGS, rng)))
		for _, s in ipairs({ -1, 1 }) do
			deco(ellipsoid(b, "Pillow", Vector3.new(1.8, 0.6, 1.1), cf * CFrame.new(s * 1.05, 2.1, 2.5) * CFrame.Angles(math.rad(-20), 0, 0), Fabric, Color3.fromRGB(240, 238, 232)))
		end
		if rng:NextNumber() < 0.6 then
			deco(ellipsoid(b, "Cushion", Vector3.new(1.2, 1, 0.4), cf * CFrame.new(0, 2.4, 2.1) * CFrame.Angles(math.rad(-20), 0, 0), Fabric, pick(SOFA_FABRICS, rng)))
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		local side = cf * CFrame.new(s * 3.2, 0, 2.5)
		at(b, "BedsideTable", side, 0, 0.8, 0, Vector3.new(1.4, 1.6, 1.3), Wood, wood)
		deco(at(b, "DrawerLine", side, 0, 1.05, -0.66, Vector3.new(1.2, 0.04, 0.03), Wood, darken(wood, 0.6)))
		tableLamp(b, side * CFrame.new(0, 1.6, 0.1), rng)
	end
	at(b, "BenchBase", cf, 0, 0.35, -4, Vector3.new(3.8, 0.7, 1), Wood, darken(wood, 0.8))
	at(b, "BenchCushion", cf, 0, 0.85, -4, Vector3.new(4, 0.3, 1.2), Fabric, pick(SOFA_FABRICS, rng))
	priceCard(b, cf * CFrame.new(1.6, 2.14, -2.8), pick({ "¥128,000", "¥248,000", "展示品限り" }, rng))
end

local function chair(b, cf, wood, rng)
	if rng:NextNumber() < 0.15 then
		cf = cf * CFrame.new(0, 0.2, 0.4) * CFrame.Angles(math.rad(-80), 0, 0) * CFrame.new(0, 0, 1)
	end
	at(b, "ChairSeat", cf, 0, 1.6, 0, Vector3.new(1.4, 0.2, 1.4), Wood, wood)
	at(b, "ChairBack", cf, 0, 2.6, 0.62, Vector3.new(1.4, 1.8, 0.15), Wood, wood)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			at(b, "ChairLeg", cf, sx * 0.58, 0.75, sz * 0.58, Vector3.new(0.15, 1.5, 0.15), Wood, darken(wood, 0.85))
		end
	end
end

-- A dining table laid for four, with a runner and a vase of dried flowers.
function Fixtures.diningSet(m, cf, rng)
	local b = model(m, "DiningSet")
	local wood = pick(WOODS, rng)
	at(b, "DiningTop", cf, 0, 2.9, 0, Vector3.new(5, 0.25, 3), Wood, wood)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			at(b, "DiningLeg", cf, sx * 2.2, 1.39, sz * 1.2, Vector3.new(0.3, 2.78, 0.3), Wood, darken(wood, 0.85))
		end
	end
	deco(at(b, "TableRunner", cf, 0, 3.04, 0, Vector3.new(4.6, 0.03, 0.9), Fabric, pick(RUGS, rng)))
	for _, x in ipairs({ -1.2, 1.2 }) do
		for _, s in ipairs({ -1, 1 }) do
			chair(b, cf * CFrame.new(x + rng:NextNumber(-0.1, 0.1), 0, s * 2.1 + rng:NextNumber(0, 0.3) * s) * CFrame.Angles(0, if s < 0 then math.pi else 0, 0), wood, rng)
			deco(upright(b, "Plate", 0.06, 0.9, cf, x, 3.06, s * 0.95, Smooth, WHITE))
			deco(upright(b, "Glass", 0.4, 0.22, cf, x + 0.55, 3.22, s * 0.8, Glass, GLASS)).Transparency = 0.5
		end
	end
	deco(upright(b, "Vase", 0.8, 0.4, cf, 0, 3.43, 0, Smooth, pick({ WHITE, Color3.fromRGB(60, 90, 110) }, rng)))
	for k = 1, 3 do
		local tip = (cf * CFrame.new(rng:NextNumber(-0.5, 0.5), 4.6 + rng:NextNumber(0, 0.5), rng:NextNumber(-0.3, 0.3))).Position
		deco(rod(b, "DriedStem", (cf * CFrame.new(0, 3.7, 0)).Position, tip, 0.05, Wood, Color3.fromRGB(150, 120, 80)))
		deco(ellipsoid(b, "DriedFlower", Vector3.one * 0.25, CFrame.new(tip), Fabric, Color3.fromRGB(200, 170, 120)))
	end
end

-- A run of kitchen units on show: cupboards, worktop with a sink and a
-- hob, wall cupboards and a hood, a pot.
function Fixtures.kitchen(m, cf, rng)
	local b = model(m, "KitchenDisplay")
	local door = pick({ WHITE, Color3.fromRGB(150, 110, 80), Color3.fromRGB(90, 100, 90), Color3.fromRGB(170, 40, 40), Color3.fromRGB(60, 70, 90) }, rng)
	local len = 7
	at(b, "Plinth", cf, 0, 0.2, 0.3, Vector3.new(len - 0.2, 0.4, 2), Smooth, DARK)
	at(b, "Carcass", cf, 0, 1.7, 0.2, Vector3.new(len, 2.6, 2.2), Wood, WHITE)
	at(b, "Worktop", cf, 0, 3.1, 0.2, Vector3.new(len + 0.1, 0.2, 2.4), Enum.Material.Granite, pick({ Color3.fromRGB(60, 60, 64), Color3.fromRGB(220, 216, 206), Color3.fromRGB(120, 100, 80) }, rng))
	at(b, "Backboard", cf, 0, 5.7, 1.35, Vector3.new(len, 5, 0.2), Smooth, Color3.fromRGB(230, 228, 222))
	at(b, "WallCupboards", cf, 0, 7, 0.8, Vector3.new(len, 2, 0.9), Wood, WHITE)
	for k = 0, 3 do
		local x = -len / 2 + 0.875 + k * 1.75
		at(b, "CupboardDoor", cf, x, 1.7, -0.93, Vector3.new(1.65, 2.4, 0.06), Smooth, door)
		deco(at(b, "Handle", cf, x + 0.6, 2.6, -0.99, Vector3.new(0.08, 0.5, 0.06), Metal, CHROME))
		at(b, "WallDoor", cf, x, 7, 0.32, Vector3.new(1.65, 1.9, 0.06), Smooth, door)
	end
	at(b, "Sink", cf, -1.8, 3.1, 0.1, Vector3.new(1.6, 0.22, 1.2), Metal, CHROME)
	deco(rod(b, "Tap", (cf * CFrame.new(-1.8, 3.2, 0.95)).Position, (cf * CFrame.new(-1.8, 3.9, 0.95)).Position, 0.12, Metal, CHROME))
	deco(rod(b, "Spout", (cf * CFrame.new(-1.8, 3.9, 0.95)).Position, (cf * CFrame.new(-1.8, 3.9, 0.45)).Position, 0.1, Metal, CHROME))
	local hob = at(b, "Hob", cf, 1.6, 3.22, 0.1, Vector3.new(1.8, 0.04, 1.4), Glass, Color3.fromRGB(20, 20, 22))
	hob.Reflectance = 0.2
	for _, o in ipairs({ { 1.2, -0.25 }, { 2, -0.25 }, { 1.2, 0.45 }, { 2, 0.45 } }) do
		deco(upright(b, "HobRing", 0.02, 0.6, cf, o[1], 3.245, o[2], Smooth, Color3.fromRGB(70, 70, 74)))
	end
	at(b, "Hood", cf, 1.6, 5.6, 0.6, Vector3.new(2, 0.8, 1.3), Metal, CHROME)
	if rng:NextNumber() < 0.7 then
		deco(upright(b, "Pot", 0.6, 0.8, cf, 1.2, 3.54, -0.25, Metal, pick({ CHROME, Color3.fromRGB(180, 40, 30), DARK }, rng)))
	end
	label(b, cf * CFrame.new(-len / 2 + 1.2, 4.2, 1.24), Vector3.new(1.8, 0.8, 0.04), Enum.NormalId.Front, pick({ "システムキッチン", "¥680,000〜", "展示品" }, rng), WHITE, DARK)
end

-- A shelf of crockery: plate stacks, bowls, mugs, teapots, tumblers.
function Fixtures.crockeryShelf(m, cf, rng)
	local b = model(m, "CrockeryShelf")
	local tops = shelfFrame(b, cf, 5, 6, 1.6, 4, pick(WOODS, rng))
	local glaze = { WHITE, Color3.fromRGB(60, 90, 110), Color3.fromRGB(170, 120, 80), Color3.fromRGB(110, 130, 110), Color3.fromRGB(40, 40, 44), Color3.fromRGB(200, 180, 150) }
	for _, top in ipairs(tops) do
		for x = -2, 2, 1 do
			local roll = rng:NextNumber()
			local c = pick(glaze, rng)
			if roll < 0.3 then
				local h = rng:NextInteger(3, 8) * 0.08
				deco(upright(b, "PlateStack", h, 0.9, top, x, h / 2, 0, Smooth, c))
			elseif roll < 0.5 then
				for k = 0, 1 do
					deco(ellipsoid(b, "Bowl", Vector3.new(0.75, 0.35, 0.75), top * CFrame.new(x, 0.17 + k * 0.2, 0), Smooth, c))
				end
			elseif roll < 0.7 then
				for _, dx in ipairs({ -0.22, 0.22 }) do
					deco(upright(b, "Mug", 0.4, 0.34, top, x + dx, 0.2, rng:NextNumber(-0.2, 0.2), Smooth, c))
				end
			elseif roll < 0.82 then
				deco(ellipsoid(b, "Teapot", Vector3.new(0.7, 0.55, 0.6), top * CFrame.new(x, 0.28, 0), Smooth, c))
				deco(rod(b, "Spout", (top * CFrame.new(x + 0.25, 0.3, 0)).Position, (top * CFrame.new(x + 0.5, 0.5, 0)).Position, 0.08, Smooth, c))
			elseif roll < 0.92 then
				for _, dx in ipairs({ -0.3, 0, 0.3 }) do
					deco(upright(b, "Tumbler", 0.35, 0.22, top, x + dx, 0.18, 0, Glass, GLASS)).Transparency = 0.5
				end
			end
		end
	end
end

-- A lamp department corner: a plinth of table lamps and floor lamps
-- round it, one or two with the shade still glowing.
function Fixtures.lampCluster(m, cf, rng)
	local b = model(m, "LampCluster")
	at(b, "LampPlinth", cf, 0, 0.8, 0, Vector3.new(4.6, 1.6, 2.2), Smooth, WHITE)
	for _, x in ipairs({ -1.5, 0, 1.5 }) do
		if rng:NextNumber() < 0.85 then
			tableLamp(b, cf * CFrame.new(x, 1.6, 0), rng)
		end
	end
	for _, o in ipairs({ { -3.2, 0.8 }, { 3.2, 0.6 }, { 0, 2.2 } }) do
		if rng:NextNumber() < 0.8 then
			floorLamp(b, cf * CFrame.new(o[1], 0, o[2]), rng, rng:NextNumber() < 0.25)
		end
	end
end

-- ===== Toys =====

-- A teddy sitting at cf (bottom centre, facing -z), `s` its size;
-- `full` gives it a face, arms and legs.
local function teddy(b, cf, s, color, full)
	ellipsoid(b, "TeddyBody", Vector3.new(1, 1.1, 0.85) * s, cf * CFrame.new(0, 0.55 * s, 0), Fabric, color)
	local head = cf * CFrame.new(0, 1.35 * s, -0.05 * s)
	ellipsoid(b, "TeddyHead", Vector3.new(0.8, 0.75, 0.75) * s, head, Fabric, color)
	for _, e in ipairs({ -1, 1 }) do
		ellipsoid(b, "TeddyEar", Vector3.new(0.3, 0.3, 0.14) * s, head * CFrame.new(e * 0.3 * s, 0.33 * s, 0.05 * s), Fabric, darken(color, 0.9))
	end
	if full then
		ellipsoid(b, "TeddyMuzzle", Vector3.new(0.36, 0.26, 0.3) * s, head * CFrame.new(0, -0.1 * s, -0.3 * s), Fabric, color:Lerp(Color3.new(1, 1, 1), 0.35))
		ellipsoid(b, "TeddyNose", Vector3.new(0.12, 0.08, 0.08) * s, head * CFrame.new(0, -0.04 * s, -0.45 * s), Smooth, DARK)
		for _, e in ipairs({ -1, 1 }) do
			ellipsoid(b, "TeddyEye", Vector3.one * 0.08 * s, head * CFrame.new(e * 0.15 * s, 0.08 * s, -0.34 * s), Smooth, DARK)
			ellipsoid(b, "TeddyArm", Vector3.new(0.3, 0.6, 0.3) * s, cf * CFrame.new(e * 0.5 * s, 0.75 * s, -0.1 * s) * CFrame.Angles(0, 0, e * 0.4), Fabric, color)
			ellipsoid(b, "TeddyLeg", Vector3.new(0.34, 0.34, 0.6) * s, cf * CFrame.new(e * 0.28 * s, 0.17 * s, -0.35 * s), Fabric, color)
		end
	end
end

local function bunny(b, cf, s, color)
	ellipsoid(b, "BunnyBody", Vector3.new(0.8, 1, 0.75) * s, cf * CFrame.new(0, 0.5 * s, 0), Fabric, color)
	for _, e in ipairs({ -1, 1 }) do
		ellipsoid(b, "BunnyEar", Vector3.new(0.18, 0.6, 0.1) * s, cf * CFrame.new(e * 0.15 * s, 1.2 * s, 0) * CFrame.Angles(0, 0, e * -0.15), Fabric, color)
	end
end

-- Shelves of soft toys.
function Fixtures.plushShelf(m, cf, rng)
	local b = model(m, "PlushShelf")
	for _, top in ipairs(shelfFrame(b, cf, 5, 6, 1.6, 3, WHITE, Smooth)) do
		for x = -1.9, 1.9, 0.95 do
			if rng:NextNumber() < 0.8 then
				local spot = top * CFrame.new(x, 0, rng:NextNumber(-0.1, 0.1)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0)
				local c = pick(FURS, rng)
				local s = rng:NextNumber(0.55, 0.8)
				local holder = model(b, "Plush")
				if rng:NextNumber() < 0.7 then
					teddy(holder, spot, s, c, false)
				else
					bunny(holder, spot, s, c)
				end
				for _, p in ipairs(holder:GetChildren()) do
					deco(p)
				end
			end
		end
	end
	label(b, cf * CFrame.new(0, 6.3, 0.6), Vector3.new(4.6, 0.6, 0.1), Enum.NormalId.Front, pick({ "ぬいぐるみ", "SOFT TOYS", "人気No.1" }, rng), pick(TOYS, rng), WHITE)
end

-- Shelves of boxed toys, each box with a window and a coloured band.
function Fixtures.toyShelf(m, cf, rng)
	local b = model(m, "ToyShelf")
	for _, top in ipairs(shelfFrame(b, cf, 5.4, 6.2, 1.6, 4, Color3.fromRGB(230, 226, 216))) do
		local x = -2.5
		while x < 2.3 do
			local w = rng:NextNumber(0.7, 1.3)
			if x + w > 2.6 then
				break
			end
			if rng:NextNumber() < 0.85 then
				local h, d = rng:NextNumber(0.5, 1.1), rng:NextNumber(0.5, 0.9)
				local box = top * CFrame.new(x + w / 2, h / 2, 0.1 - (0.9 - d) / 2)
				local c = pick(TOYS, rng)
				deco(part(b, "ToyBox", Vector3.new(w - 0.06, h, d), box, Smooth, c))
				deco(part(b, "ToyWindow", Vector3.new((w - 0.06) * 0.7, h * 0.55, 0.04), box * CFrame.new(0, h * 0.08, -d / 2 - 0.02), Glass, GLASS)).Transparency = 0.45
				deco(part(b, "ToyBand", Vector3.new(w - 0.04, 0.14, d + 0.02), box * CFrame.new(0, -h / 2 + 0.12, 0), Smooth, pick({ WHITE, Color3.fromRGB(250, 220, 60), DARK }, rng)))
			end
			x += w
		end
	end
end

-- A bank of capsule-toy machines, two high.
function Fixtures.gachapon(m, cf, rng)
	local b = model(m, "Gachapon")
	local cols = rng:NextInteger(3, 4)
	at(b, "GachaStand", cf, 0, 0.4, 0, Vector3.new(cols * 1.5 + 0.2, 0.8, 1.5), Metal, DARK)
	for c = 0, cols - 1 do
		local x = (c - (cols - 1) / 2) * 1.5
		for row = 0, 1 do
			local y0 = 0.8 + row * 2.1
			at(b, "GachaBody", cf, x, y0 + 0.5, 0, Vector3.new(1.4, 1, 1.3), Smooth, pick(TOYS, rng))
			at(b, "GachaWindow", cf, x, y0 + 1.55, 0, Vector3.new(1.4, 1.1, 1.3), Glass, GLASS).Transparency = 0.6
			for k = 1, 3 do
				deco(ellipsoid(b, "Capsule", Vector3.one * 0.45, cf * CFrame.new(x + rng:NextNumber(-0.35, 0.35), y0 + 1.25 + (k - 1) * 0.25, rng:NextNumber(-0.3, 0.3)), Smooth, pick(TOYS, rng)))
			end
			label(b, cf * CFrame.new(x, y0 + 0.75, -0.68), Vector3.new(1.1, 0.4, 0.05), Enum.NormalId.Front, pick({ "¥100", "¥200", "¥300" }, rng), WHITE, DARK)
			deco(cylinder(b, "GachaKnob", 0.15, 0.5, cf * CFrame.new(x - 0.2, y0 + 0.3, -0.72) * FACING_Z, Metal, CHROME))
			deco(at(b, "GachaChute", cf, x + 0.4, y0 + 0.3, -0.67, Vector3.new(0.45, 0.35, 0.06), Smooth, DARK))
		end
	end
	at(b, "GachaTop", cf, 0, 5.1, 0, Vector3.new(cols * 1.5 + 0.2, 0.2, 1.5), Metal, DARK)
end

-- A model railway on a green table: an oval of track, a train, trees.
function Fixtures.trainTable(m, cf, rng)
	local b = model(m, "TrainTable")
	at(b, "TrainTable", cf, 0, 1.4, 0, Vector3.new(7, 2.8, 4), Wood, Color3.fromRGB(80, 130, 80))
	local pts = {}
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		table.insert(pts, (cf * CFrame.new(math.cos(a) * 2.8, 2.84, math.sin(a) * 1.4)).Position)
	end
	for k = 1, #pts do
		deco(rod(b, "ToyTrack", pts[k], pts[k % #pts + 1], 0.12, Metal, STEEL))
	end
	for k = 0, 2 do
		local a = k * 0.45 + rng:NextNumber(0, 0.3)
		local car = CFrame.lookAt((cf * CFrame.new(math.cos(a) * 2.8, 3.15, math.sin(a) * 1.4)).Position, (cf * CFrame.new(math.cos(a + 0.2) * 2.8, 3.15, math.sin(a + 0.2) * 1.4)).Position)
		deco(part(b, "ToyCar", Vector3.new(0.6, 0.55, 0.9), car, Smooth, if k == 0 then Color3.fromRGB(30, 30, 34) else pick(TOYS, rng)))
		if k == 0 then
			deco(cylinder(b, "Chimney", 0.3, 0.2, car * CFrame.new(0, 0.4, -0.25) * UPRIGHT, Smooth, DARK))
		end
	end
	for _ = 1, 4 do
		local p = cf * CFrame.new(rng:NextNumber(-1.8, 1.8), 2.8, rng:NextNumber(-0.6, 0.6))
		deco(ellipsoid(b, "ToyTree", Vector3.new(0.5, 0.9, 0.5), p * CFrame.new(0, 0.45, 0), Smooth, Color3.fromRGB(50, 110, 50)))
	end
	deco(at(b, "ToyStation", cf, 0, 3.05, -1.9, Vector3.new(1.4, 0.5, 0.4), Smooth, Color3.fromRGB(200, 180, 150)))
end

-- A wire bargain bin heaped with soft toys.
function Fixtures.plushBin(m, cf, rng)
	local b = model(m, "PlushBin")
	local w, d, h = 4, 2.6, 1.8
	at(b, "BinBase", cf, 0, 0.15, 0, Vector3.new(w, 0.3, d), Metal, CHROME)
	for _, s in ipairs({ -1, 1 }) do
		at(b, "BinSide", cf, s * w / 2, h / 2, 0, Vector3.new(0.08, h, d), Metal, CHROME).Transparency = 0.5
		at(b, "BinSide", cf, 0, h / 2, s * d / 2, Vector3.new(w, h, 0.08), Metal, CHROME).Transparency = 0.5
	end
	for _ = 1, rng:NextInteger(5, 8) do
		local holder = model(b, "Plush")
		teddy(holder, cf * CFrame.new(rng:NextNumber(-1.4, 1.4), rng:NextNumber(0.3, 1.3), rng:NextNumber(-0.8, 0.8)) * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(0, 6), rng:NextNumber(-1, 1)), rng:NextNumber(0.5, 0.75), pick(FURS, rng), false)
		for _, p in ipairs(holder:GetChildren()) do
			deco(p)
		end
	end
	label(b, cf * CFrame.new(0, h + 0.5, -d / 2), Vector3.new(2.4, 0.7, 0.06), Enum.NormalId.Front, "ワゴンセール", Color3.fromRGB(230, 40, 40), WHITE)
end

-- The big teddy by the escalators (or your own Plush model).
function Fixtures.bigTeddy(m, cf, rng)
	local b = model(m, "BigTeddy")
	if PropLibrary.place(b, "Plush", cf, rng, 7, 6) then
		return
	end
	teddy(b, cf, 3.2, pick(FURS, rng), true)
	deco(ellipsoid(b, "Bow", Vector3.new(1.2, 0.5, 0.4), cf * CFrame.new(0, 3.55, -1.1), Fabric, Color3.fromRGB(200, 40, 50)))
end

-- ===== Every floor =====

-- A cash desk: counter, register, paper bags, a sign on a pole.
function Fixtures.cashDesk(m, cf, rng)
	local b = model(m, "CashDesk")
	at(b, "DeskBody", cf, 0, 1.6, 0, Vector3.new(5, 3.2, 2), Wood, Color3.fromRGB(226, 220, 208))
	at(b, "DeskTop", cf, 0, 3.3, 0, Vector3.new(5.2, 0.2, 2.2), Smooth, DARK)
	at(b, "Register", cf, -1.2, 3.65, 0.2, Vector3.new(1.4, 0.5, 1.2), Smooth, Color3.fromRGB(60, 60, 64))
	at(b, "RegisterScreen", cf * CFrame.new(-1.2, 4.3, 0.5) * CFrame.Angles(math.rad(20), 0, 0), 0, 0, 0, Vector3.new(1.1, 0.8, 0.1), Smooth, Color3.fromRGB(20, 22, 26))
	if rng:NextNumber() < 0.35 then
		deco(at(b, "OpenDrawer", cf, -1.2, 3.1, 1.4, Vector3.new(1.2, 0.3, 0.8), Metal, STEEL))
	end
	local bag = Color3.fromRGB(236, 230, 212)
	for k = 0, rng:NextInteger(1, 4) do
		deco(at(b, "PaperBag", cf * CFrame.Angles(0, math.rad(rng:NextNumber(-8, 8)), 0), 1.4, 3.43 + k * 0.06, -0.35, Vector3.new(1.4, 0.06, 0.9), Smooth, bag))
	end
	local standing = at(b, "ShoppingBag", cf, 1.7, 4.1, 0.6, Vector3.new(1, 1.4, 0.5), Smooth, bag)
	deco(standing)
	label(b, cf * CFrame.new(1.7, 4.1, 0.34), Vector3.new(0.7, 0.7, 0.02), Enum.NormalId.Front, "月", bag, Color3.fromRGB(190, 40, 40), Smooth, Enum.Font.GothamBlack)
	rod(b, "SignPole", (cf * CFrame.new(-2.3, 3.4, 0.8)).Position, (cf * CFrame.new(-2.3, 6.2, 0.8)).Position, 0.1, Metal, CHROME)
	label(b, cf * CFrame.new(-2.3, 6.6, 0.8), Vector3.new(2.2, 0.8, 0.08), Enum.NormalId.Front, "お会計", Color3.fromRGB(30, 34, 50), WHITE)
end

-- Cladding on a column: mirror (cosmetics), posters (fashion, toys) or
-- dark panelling (men's). Column centre (x, z), floor y, ceiling underside.
function Fixtures.columnCladding(m, x, z, y, ceiling, style, rng)
	local c = model(m, "ColumnCladding")
	part(c, "CladPlinth", Vector3.new(3.2, 0.5, 3.2), Vector3.new(x, y + 0.25, z), Smooth, DARK)
	local top = ceiling - 1.6
	if style == "mirror" then
		local p = part(c, "MirrorCladding", Vector3.new(2.9, top - (y + 0.5), 2.9), Vector3.new(x, (y + 0.5 + top) / 2, z), Smooth, Color3.fromRGB(184, 190, 194))
		p.Reflectance = 0.55
		part(c, "CladCap", Vector3.new(3.1, 0.3, 3.1), Vector3.new(x, top + 0.15, z), Metal, GOLD)
	elseif style == "panel" then
		part(c, "PanelCladding", Vector3.new(2.8, top - (y + 0.5), 2.8), Vector3.new(x, (y + 0.5 + top) / 2, z), Wood, Color3.fromRGB(70, 52, 40))
		part(c, "CladCap", Vector3.new(3, 0.3, 3), Vector3.new(x, top + 0.15, z), Metal, Color3.fromRGB(150, 130, 90))
	else
		part(c, "PosterCladding", Vector3.new(2.8, top - (y + 0.5), 2.8), Vector3.new(x, (y + 0.5 + top) / 2, z), Smooth, WHITE)
		local texts = if style == "toys" then { "たのしい!", "NEW!", "ゲーム", "人気No.1" } else { "NEW ARRIVAL", "春夏コレクション", "SALE", "秋の装い" }
		for k = 0, 3 do
			if rng:NextNumber() < 0.8 then
				local face = CFrame.new(x, y + 6, z) * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0, -1.43)
				label(c, face, Vector3.new(2, 3, 0.05), Enum.NormalId.Front, pick(texts, rng), pick(if style == "toys" then TOYS else { Color3.fromRGB(200, 60, 70), Color3.fromRGB(30, 30, 34), Color3.fromRGB(190, 150, 90), Color3.fromRGB(110, 150, 120) }, rng), WHITE, Smooth, Enum.Font.GothamBlack)
			end
		end
	end
end

-- ===== Restaurants =====

-- A family-restaurant booth: two high-backed vinyl benches facing over a
-- table, place settings, a condiment caddy and a menu.
function Fixtures.booth(m, cf, rng)
	local b = model(m, "Booth")
	local vinyl = pick({ Color3.fromRGB(150, 40, 40), Color3.fromRGB(60, 90, 80), Color3.fromRGB(170, 120, 60), Color3.fromRGB(60, 60, 90) }, rng)
	local wood = pick(WOODS, rng)
	at(b, "BoothTable", cf, 0, 2.9, 0, Vector3.new(4.2, 0.2, 2.6), Smooth, Color3.fromRGB(230, 226, 214))
	deco(at(b, "TableEdge", cf, 0, 2.78, 0, Vector3.new(4.3, 0.08, 2.7), Metal, CHROME))
	upright(b, "TablePost", 2.7, 0.4, cf, 0, 1.4, 0, Metal, CHROME)
	upright(b, "TableFoot", 0.1, 1.8, cf, 0, 0.05, 0, Metal, CHROME)
	for _, s in ipairs({ -1, 1 }) do
		local seat = cf * CFrame.new(0, 0, s * 2.4)
		at(b, "BenchBase", seat, 0, 0.8, 0, Vector3.new(4.4, 1.6, 1.8), Wood, wood)
		at(b, "BenchSeat", seat, 0, 1.8, -s * 0.05, Vector3.new(4.4, 0.4, 1.9), Leather, vinyl)
		at(b, "BenchBack", seat, 0, 3.5, s * 0.75, Vector3.new(4.4, 3, 0.5), Leather, vinyl)
		at(b, "BoothScreen", seat, 0, 2.7, s * 1.12, Vector3.new(4.6, 5.4, 0.2), Wood, darken(wood, 0.85))
		if rng:NextNumber() < 0.7 then
			deco(upright(b, "Plate", 0.06, 0.9, cf, rng:NextNumber(-0.8, 0.8), 3.03, s * 0.7, Smooth, WHITE))
		end
		deco(upright(b, "WaterGlass", 0.45, 0.3, cf, 1.5, 3.23, s * 0.6, Glass, GLASS)).Transparency = 0.5
	end
	-- Condiments at the wall end, a menu stood up.
	for k, c in ipairs({ Color3.fromRGB(40, 20, 16), Color3.fromRGB(150, 40, 30), WHITE }) do
		deco(upright(b, "Condiment", 0.55, 0.26, cf, -1.75, 3.28, -0.5 + k * 0.3, Glass, c))
	end
	deco(at(b, "NapkinBox", cf, -1.75, 3.2, 0.6, Vector3.new(0.4, 0.4, 0.5), Metal, CHROME))
	label(b, cf * CFrame.new(-1.2, 3.55, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.9, 1.1, 0.06), Enum.NormalId.Front, "MENU", Color3.fromRGB(120, 30, 30), Color3.fromRGB(250, 236, 200), Smooth, Enum.Font.Garamond)
end

-- A ramen counter: diners' stools along a wooden counter, a raised pass,
-- the kitchen behind with stockpots, menu tags on the wall, a noren
-- curtain hung across the front and a red lantern.
function Fixtures.ramenCounter(m, cf, rng)
	local b = model(m, "RamenCounter")
	local wood = Color3.fromRGB(150, 112, 76)
	at(b, "CounterBase", cf, 0, 1.6, 0, Vector3.new(7, 3.2, 1.4), Wood, darken(wood, 0.8))
	at(b, "CounterTop", cf, 0, 3.3, -0.1, Vector3.new(7.2, 0.2, 1.8), Wood, wood)
	at(b, "RaisedPass", cf, 0, 3.95, 0.45, Vector3.new(7.2, 0.15, 0.7), Wood, wood)
	for _, x in ipairs({ -3.3, 3.3 }) do
		at(b, "PassBracket", cf, x, 3.65, 0.45, Vector3.new(0.2, 0.5, 0.6), Wood, darken(wood, 0.8))
	end
	for k = -2, 2 do
		barStool(b, cf * CFrame.new(k * 1.4, 0, -1.7), rng)
		if rng:NextNumber() < 0.5 then
			deco(ellipsoid(b, "RamenBowl", Vector3.new(0.9, 0.5, 0.9), cf * CFrame.new(k * 1.4, 3.55, -0.5), Smooth, pick({ Color3.fromRGB(170, 40, 40), DARK, WHITE }, rng)))
			deco(at(b, "Chopsticks", cf, k * 1.4 + 0.6, 3.42, -0.5, Vector3.new(0.06, 0.04, 1), Wood, wood))
		end
		if k ~= 0 then
			deco(upright(b, "Condiment", 0.45, 0.22, cf, k * 1.4 + 0.3, 4.25, 0.45, Glass, pick({ Color3.fromRGB(40, 20, 16), Color3.fromRGB(180, 50, 30), WHITE }, rng)))
		end
	end
	at(b, "KitchenBench", cf, 0, 1.6, 2.6, Vector3.new(7, 3.2, 1.6), Metal, CHROME)
	deco(upright(b, "StockPot", 1.4, 1.6, cf, -2, 3.9, 2.6, Metal, CHROME))
	deco(upright(b, "StockPot", 1.1, 1.3, cf, -0.2, 3.75, 2.6, Metal, Color3.fromRGB(160, 160, 164)))
	for k = 0, 2 do
		deco(upright(b, "NoodleBasket", 0.6, 0.6, cf, 1.4 + k * 0.8, 3.5, 2.6, Metal, STEEL))
	end
	at(b, "KitchenWall", cf, 0, 4.5, 3.5, Vector3.new(7.4, 9, 0.2), Smooth, Color3.fromRGB(226, 220, 206))
	for k, item in ipairs({ "醤油\n¥650", "味噌\n¥700", "塩\n¥650", "餃子\n¥350", "炒飯\n¥600", "ビール\n¥500" }) do
		label(b, cf * CFrame.new(-3.1 + (k - 1) * 1.24, 6.4, 3.38), Vector3.new(0.9, 1.8, 0.04), Enum.NormalId.Front, item, Color3.fromRGB(240, 232, 210), DARK, Smooth, Enum.Font.GothamBold)
	end
	for _, s in ipairs({ -1, 1 }) do
		at(b, "NorenPost", cf, s * 3.5, 3.8, -0.95, Vector3.new(0.3, 7.6, 0.3), Wood, darken(wood, 0.7))
	end
	at(b, "NorenBeam", cf, 0, 7.75, -0.95, Vector3.new(7.4, 0.35, 0.35), Wood, darken(wood, 0.7))
	local norenColor = pick({ Color3.fromRGB(30, 30, 60), Color3.fromRGB(150, 30, 30), Color3.fromRGB(230, 226, 210) }, rng)
	local ink = if norenColor.R > 0.8 then DARK else WHITE
	local words = pick({ { "ら", "ー", "め", "ん" }, { "中", "華", "そ", "ば" }, { "う", "ど", "ん", "処" }, { "そ", "ば", "処", "" } }, rng)
	for k = 1, 4 do
		if rng:NextNumber() < 0.9 then
			label(b, cf * CFrame.new(-2.62 + (k - 1) * 1.75, 6.7, -1.18) * CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, 0), Vector3.new(1.65, 1.8, 0.05), Enum.NormalId.Front, words[k], norenColor, ink, Fabric, Enum.Font.GothamBlack)
		end
	end
	deco(ellipsoid(b, "Chochin", Vector3.new(1.1, 1.5, 1.1), cf * CFrame.new(4.1, 6.4, -1.2), Fabric, Color3.fromRGB(200, 40, 30)))
	deco(upright(b, "ChochinCap", 0.2, 0.7, cf, 4.1, 7.2, -1.2, Smooth, DARK))
end

local function bistroChair(b, cf, rng)
	if rng:NextNumber() < 0.15 then
		cf = cf * CFrame.new(0, 0.2, 0.4) * CFrame.Angles(math.rad(-80), 0, 0) * CFrame.new(0, 0, 1)
	end
	upright(b, "ChairSeat", 0.15, 1.4, cf, 0, 1.6, 0, Wood, Color3.fromRGB(110, 80, 56))
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			at(b, "ChairLeg", cf, sx * 0.45, 0.78, sz * 0.45, Vector3.new(0.1, 1.55, 0.1), Metal, DARK)
		end
		deco(rod(b, "ChairBack", (cf * CFrame.new(sx * 0.5, 1.6, 0.55)).Position, (cf * CFrame.new(sx * 0.45, 3.2, 0.62)).Position, 0.1, Metal, DARK))
	end
	deco(cylinder(b, "ChairBackRail", 1, 0.12, cf * CFrame.new(0, 3.1, 0.62), Metal, DARK))
end

-- A café table for two or three: marble top, bistro chairs, a parfait
-- and coffee cups.
function Fixtures.cafeTable(m, cf, rng)
	local b = model(m, "CafeTable")
	upright(b, "CafeFoot", 0.1, 1.6, cf, 0, 0.05, 0, Metal, DARK)
	upright(b, "CafePost", 2.7, 0.3, cf, 0, 1.45, 0, Metal, DARK)
	upright(b, "CafeTop", 0.15, 3, cf, 0, 2.88, 0, Enum.Material.Marble, WHITE)
	local n = rng:NextInteger(2, 3)
	for k = 0, n - 1 do
		bistroChair(b, cf * CFrame.Angles(0, k / n * math.pi * 2 + rng:NextNumber(-0.2, 0.2), 0) * CFrame.new(0, 0, 2.2), rng)
	end
	if rng:NextNumber() < 0.6 then
		deco(upright(b, "Parfait", 0.9, 0.35, cf, 0.4, 3.4, 0, Glass, GLASS)).Transparency = 0.3
		deco(ellipsoid(b, "Cream", Vector3.new(0.4, 0.35, 0.4), cf * CFrame.new(0.4, 3.95, 0), Smooth, Color3.fromRGB(250, 240, 230)))
		deco(ellipsoid(b, "Cherry", Vector3.one * 0.16, cf * CFrame.new(0.4, 4.15, 0), Smooth, Color3.fromRGB(200, 20, 30)))
	end
	for _, x in ipairs({ -0.5, -0.2 }) do
		if rng:NextNumber() < 0.6 then
			deco(upright(b, "Saucer", 0.04, 0.6, cf, x, 2.97, 0.6, Smooth, WHITE))
			deco(upright(b, "Cup", 0.3, 0.3, cf, x, 3.14, 0.6, Smooth, WHITE))
		end
	end
end

-- The drink bar: a counter with a drinks machine, cup towers, a sign.
function Fixtures.drinkBar(m, cf, rng)
	local b = model(m, "DrinkBar")
	at(b, "BarCounter", cf, 0, 1.6, 0, Vector3.new(5, 3.2, 2), Wood, Color3.fromRGB(200, 180, 150))
	at(b, "BarTop", cf, 0, 3.3, 0, Vector3.new(5.2, 0.2, 2.2), Smooth, DARK)
	at(b, "DrinkMachine", cf, -1, 4.6, 0.3, Vector3.new(2.4, 2.4, 1.4), Metal, CHROME)
	at(b, "MachineFace", cf, -1, 5, -0.43, Vector3.new(2.2, 1.2, 0.06), Neon, pick({ Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 200) }, rng))
	for k = 0, 3 do
		deco(upright(b, "Nozzle", 0.3, 0.2, cf, -1.8 + k * 0.55, 3.7, -0.2, Metal, DARK))
	end
	for _, x in ipairs({ 1, 1.6 }) do
		deco(upright(b, "CupTower", rng:NextNumber(0.8, 1.6), 0.4, cf, x, 3.4 + 0.4, 0.2, Plastic, WHITE))
	end
	label(b, cf * CFrame.new(0, 6.6, 0.5), Vector3.new(4, 0.9, 0.1), Enum.NormalId.Front, "ドリンクバー", Color3.fromRGB(240, 200, 60), Color3.fromRGB(120, 30, 30))
end

-- ===== The event hall =====

-- A regional fair stall (物産展): a counter under a banner with the
-- region's name, a short noren, gift boxes and produce, stock behind.
function Fixtures.fairStall(m, cf, rng)
	local b = model(m, "FairStall")
	local region = pick({ { "北海道物産展", Color3.fromRGB(40, 90, 160) }, { "京都 老舗の味", Color3.fromRGB(120, 40, 90) }, { "九州うまいもの市", Color3.fromRGB(180, 60, 30) }, { "信州そば祭り", Color3.fromRGB(70, 110, 60) }, { "沖縄フェア", Color3.fromRGB(30, 150, 160) } }, rng)
	local wood = pick(WOODS, rng)
	at(b, "StallCounter", cf, 0, 1.5, 0, Vector3.new(6, 3, 2), Wood, Color3.fromRGB(236, 232, 222))
	at(b, "StallSkirt", cf, 0, 1.4, -1.03, Vector3.new(6.02, 2.4, 0.05), Fabric, region[2])
	at(b, "StallTop", cf, 0, 3.1, 0, Vector3.new(6.2, 0.2, 2.2), Wood, wood)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			at(b, "StallPost", cf, sx * 2.9, 4, sz * 0.9, Vector3.new(0.25, 8, 0.25), Wood, darken(wood, 0.8))
		end
	end
	label(b, cf * CFrame.new(0, 7.3, -1.12), Vector3.new(6.4, 1.3, 0.15), Enum.NormalId.Front, region[1], region[2], WHITE, Smooth, Enum.Font.GothamBlack)
	for k = 0, 3 do
		deco(at(b, "StallNoren", cf, -2.25 + k * 1.5, 6.15, -1.1, Vector3.new(1.42, 0.9, 0.05), Fabric, darken(region[2], 0.85)))
	end
	for _ = 1, rng:NextInteger(3, 6) do
		local w = rng:NextNumber(0.8, 1.2)
		local gift = cf * CFrame.new(rng:NextNumber(-2.4, 2.4), 3.2 + 0.3, rng:NextNumber(-0.5, 0.5)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0)
		local paper = pick({ WHITE, Color3.fromRGB(200, 60, 60), Color3.fromRGB(230, 200, 140), Color3.fromRGB(60, 90, 140) }, rng)
		deco(part(b, "GiftBox", Vector3.new(w, 0.6, 0.8), gift, Smooth, paper))
		deco(part(b, "Ribbon", Vector3.new(0.14, 0.62, 0.82), gift, Fabric, pick({ GOLD, Color3.fromRGB(200, 30, 40) }, rng)))
	end
	Props.cardboardStack(b, (cf * CFrame.new(rng:NextNumber(-2, 2), 0, 2.4)).Position, rng, 4)
	rod(b, "FlagPole", (cf * CFrame.new(3.3, 0, -1.4)).Position, (cf * CFrame.new(3.3, 5, -1.4)).Position, 0.1, Metal, STEEL)
	label(b, cf * CFrame.new(3.3, 4.2, -1.4), Vector3.new(0.9, 1.6, 0.05), Enum.NormalId.Front, "特\n価", Color3.fromRGB(240, 220, 60), Color3.fromRGB(200, 30, 30), Fabric, Enum.Font.GothamBlack)
end

-- A wire sale wagon on castors, heaped with boxed goods.
function Fixtures.saleWagon(m, cf, rng)
	local b = model(m, "SaleWagon")
	local w, d, h = 4.4, 2.6, 1.6
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			deco(cylinder(b, "Castor", 0.2, 0.5, cf * CFrame.new(sx * (w / 2 - 0.3), 0.25, sz * (d / 2 - 0.3)), Enum.Material.Rubber, DARK))
			at(b, "WagonLeg", cf, sx * (w / 2 - 0.1), 1.3, sz * (d / 2 - 0.1), Vector3.new(0.12, 2.1, 0.12), Metal, CHROME)
		end
	end
	at(b, "WagonBase", cf, 0, 2.3, 0, Vector3.new(w, 0.1, d), Metal, CHROME)
	for _, s in ipairs({ -1, 1 }) do
		at(b, "WagonSide", cf, s * w / 2, 2.3 + h / 2, 0, Vector3.new(0.06, h, d), Metal, CHROME).Transparency = 0.55
		at(b, "WagonSide", cf, 0, 2.3 + h / 2, s * d / 2, Vector3.new(w, h, 0.06), Metal, CHROME).Transparency = 0.55
	end
	for _ = 1, rng:NextInteger(6, 10) do
		local s = Vector3.new(rng:NextNumber(0.6, 1.4), rng:NextNumber(0.3, 0.9), rng:NextNumber(0.5, 1.1))
		deco(part(b, "SaleGoods", s, cf * CFrame.new(rng:NextNumber(-1.5, 1.5), 2.4 + s.Y / 2 + rng:NextNumber(0, 0.8), rng:NextNumber(-0.7, 0.7)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)), Smooth, pick(TOYS, rng)))
	end
	label(b, cf * CFrame.new(0, 2.3 + h + 0.5, -d / 2), Vector3.new(2.6, 0.7, 0.06), Enum.NormalId.Front, pick({ "ワゴンセール", "全品半額", "¥500均一" }, rng), Color3.fromRGB(230, 40, 40), WHITE)
end

-- Folding chairs stacked for an event that never started, tables leant
-- against them.
function Fixtures.chairStack(m, cf, rng)
	local b = model(m, "ChairStack")
	local grey = Color3.fromRGB(90, 92, 96)
	for k = 0, rng:NextInteger(4, 8) do
		local c = cf * CFrame.new(rng:NextNumber(-0.05, 0.05), k * 0.28, k * 0.06) * CFrame.Angles(0, math.rad(rng:NextNumber(-3, 3)), 0)
		at(b, "FoldingSeat", c, 0, 1.6, 0, Vector3.new(1.4, 0.1, 1.3), Metal, grey)
		at(b, "FoldingBack", c, 0, 2.7, 0.7, Vector3.new(1.4, 1, 0.1), Metal, grey)
		deco(at(b, "FoldingLegs", c, 0, 0.8, 0, Vector3.new(1.3, 1.6, 0.08), Metal, darken(grey, 0.8))).Transparency = 0.6
	end
	for k = 0, 1 do
		local lean = cf * CFrame.new(2.2 + k * 0.4, 0, 0) * CFrame.Angles(0, 0, math.rad(-12))
		at(b, "FoldedTable", lean, 0, 2.2, 0, Vector3.new(0.2, 4.4, 3), Wood, Color3.fromRGB(200, 186, 160))
	end
end

-- ===== Books =====

local BOOKS = { Color3.fromRGB(150, 40, 40), Color3.fromRGB(40, 60, 110), Color3.fromRGB(230, 226, 210), Color3.fromRGB(60, 90, 60), Color3.fromRGB(190, 150, 70), Color3.fromRGB(40, 40, 44), Color3.fromRGB(200, 120, 60), Color3.fromRGB(120, 80, 120) }
local GENRES = { "文芸", "新書", "文庫", "漫画", "実用書", "旅行", "児童書", "ビジネス", "料理", "美術" }

-- A row of books along x from `base` (on the shelf, spines to -z), a few
-- books to a part to keep counts down.
local function bookRun(b, base, len, rng)
	local x = -len / 2
	while x < len / 2 - 0.25 do
		local w = rng:NextNumber(0.25, 0.9)
		if x + w > len / 2 then
			break
		end
		if rng:NextNumber() < 0.88 then
			local h = rng:NextNumber(0.8, 1.15)
			local lean = if rng:NextNumber() < 0.06 then math.rad(rng:NextNumber(-14, 14)) else 0
			deco(part(b, "Books", Vector3.new(w - 0.03, h, rng:NextNumber(0.75, 0.9)), base * CFrame.new(x + w / 2, h / 2, 0) * CFrame.Angles(0, 0, lean), Smooth, jitter(pick(BOOKS, rng), rng, 0.08)))
		end
		x += w
	end
end

-- A double-sided bookstore gondola, shelves both sides, genre headers.
function Fixtures.bookGondola(m, cf, rng)
	local b = model(m, "BookGondola")
	local len, h = 5.6, 5.4
	local wood = pick({ Color3.fromRGB(200, 180, 150), Color3.fromRGB(120, 90, 60), Color3.fromRGB(230, 226, 216) }, rng)
	at(b, "GondolaSpine", cf, 0, h / 2, 0, Vector3.new(len, h, 0.2), Wood, wood)
	at(b, "GondolaKick", cf, 0, 0.2, 0, Vector3.new(len, 0.4, 2.4), Wood, darken(wood, 0.7))
	for _, s in ipairs({ -1, 1 }) do
		at(b, "GondolaEnd", cf, s * (len / 2 + 0.07), h / 2, 0, Vector3.new(0.14, h, 2.4), Wood, darken(wood, 0.9))
	end
	for _, s in ipairs({ -1, 1 }) do
		local side = cf * CFrame.new(0, 0, s * 0.65) * (if s > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity)
		for level = 0, 2 do
			local y = 0.4 + level * 1.6
			if level > 0 then
				at(b, "GondolaShelf", side, 0, y - 0.04, 0, Vector3.new(len, 0.08, 1.05), Wood, wood)
			end
			if rng:NextNumber() < 0.92 then
				bookRun(b, side * CFrame.new(0, y, -0.05), len - 0.2, rng)
			end
		end
	end
	local header = label(b, cf * CFrame.new(0, h + 0.45, 0), Vector3.new(len, 0.8, 0.15), Enum.NormalId.Front, pick(GENRES, rng), Color3.fromRGB(40, 60, 50), WHITE)
	local back = header:FindFirstChildOfClass("SurfaceGui"):Clone()
	back.Face = Enum.NormalId.Back
	back:FindFirstChildOfClass("TextLabel").Text = pick(GENRES, rng)
	back.Parent = header
	if rng:NextNumber() < 0.3 then
		for _ = 1, rng:NextInteger(2, 5) do
			deco(at(b, "FallenBook", cf * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(-2.5, 2.5), 0.1, rng:NextNumber(-2.4, -1.6), Vector3.new(0.9, 0.2, 1.2), Smooth, pick(BOOKS, rng)))
		end
	end
end

-- A flat table of new books face up in stacks, with hand-written POP
-- cards stuck in them.
function Fixtures.bookTable(m, cf, rng)
	local b = model(m, "BookTable")
	local wood = pick(WOODS, rng)
	at(b, "TableBody", cf, 0, 1.3, 0, Vector3.new(6, 2.6, 3.2), Wood, wood)
	at(b, "TableTop", cf, 0, 2.65, 0, Vector3.new(6.2, 0.1, 3.4), Wood, darken(wood, 1.1))
	for x = -2.2, 2.2, 1.45 do
		for _, z in ipairs({ -0.75, 0.75 }) do
			if rng:NextNumber() < 0.9 then
				local y = 2.7
				local cover = pick(BOOKS, rng)
				for _ = 1, rng:NextInteger(2, 6) do
					deco(part(b, "BookStack", Vector3.new(1.05, 0.14, 1.35), cf * CFrame.new(x + rng:NextNumber(-0.04, 0.04), y + 0.07, z) * CFrame.Angles(0, math.rad(rng:NextNumber(-4, 4)), 0), Smooth, cover))
					y += 0.14
				end
				if rng:NextNumber() < 0.35 then
					label(b, cf * CFrame.new(x, y + 0.45, z - 0.55) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(1, 0.8, 0.03), Enum.NormalId.Front, pick({ "店長\nイチオシ!", "話題の本", "映像化!", "泣ける…", "新刊" }, rng), Color3.fromRGB(250, 240, 120), Color3.fromRGB(200, 30, 30), Smooth, Enum.Font.GothamBold)
				end
			end
		end
	end
end

-- A sloped magazine rack, covers facing out.
function Fixtures.magazineRack(m, cf, rng)
	local b = model(m, "MagazineRack")
	at(b, "RackBack", cf, 0, 2.8, 0.7, Vector3.new(5, 5.6, 0.15), Metal, STEEL)
	for _, s in ipairs({ -1, 1 }) do
		at(b, "RackSide", cf, s * 2.55, 2.8, 0.2, Vector3.new(0.1, 5.6, 1.1), Metal, STEEL)
	end
	for level = 0, 3 do
		local tier = cf * CFrame.new(0, 0.9 + level * 1.3, 0.25) * CFrame.Angles(math.rad(12), 0, 0)
		deco(at(b, "RackLip", tier, 0, -0.5, -0.1, Vector3.new(4.9, 0.12, 0.2), Metal, STEEL))
		for k = 0, 4 do
			if rng:NextNumber() < 0.85 then
				local cover = at(b, "Magazine", tier, -2 + k * 0.98, 0.05, 0, Vector3.new(0.85, 1.15, 0.05), Smooth, jitter(pick(TOYS, rng), rng, 0.2))
				deco(cover)
				if rng:NextNumber() < 0.5 then
					deco(at(b, "MagazineTitle", tier, -2 + k * 0.98, 0.45, -0.035, Vector3.new(0.8, 0.22, 0.02), Smooth, WHITE))
				end
			end
		end
	end
end

-- The stationery counter: a glass case of pens, pen cups and notebooks
-- on top, a globe.
function Fixtures.stationery(m, cf, rng)
	local b = model(m, "Stationery")
	at(b, "CaseBase", cf, 0, 1.1, 0, Vector3.new(5, 2.2, 2), Wood, Color3.fromRGB(60, 44, 36))
	at(b, "CaseGlass", cf, 0, 2.75, 0, Vector3.new(5, 1.1, 2), Glass, GLASS).Transparency = 0.7
	at(b, "CaseTop", cf, 0, 3.33, 0, Vector3.new(5.1, 0.06, 2.1), Glass, GLASS).Transparency = 0.5
	for row = 0, 2 do
		for k = 0, 7 do
			if rng:NextNumber() < 0.8 then
				deco(cylinder(b, "Pen", 0.9, 0.08, cf * CFrame.new(-2 + k * 0.55, 2.28, -0.5 + row * 0.5) * CFrame.Angles(0, math.rad(90 + rng:NextNumber(-8, 8)), 0), Smooth, pick({ DARK, Color3.fromRGB(30, 50, 120), Color3.fromRGB(150, 30, 30), GOLD, CHROME }, rng)))
			end
		end
	end
	for k = 0, 1 do
		deco(upright(b, "PenCup", 0.6, 0.5, cf, -1.8 + k * 0.8, 3.66, 0.3, Plastic, pick(TOYS, rng)))
	end
	for k = 0, 2 do
		deco(at(b, "Notebook", cf, 0 + k * 0.1, 3.42 + k * 0.1, -0.1, Vector3.new(1, 0.1, 1.4), Smooth, pick(TOYS, rng)))
	end
	upright(b, "GlobeStand", 0.8, 0.14, cf, 1.8, 3.76, 0.2, Metal, GOLD)
	ellipsoid(b, "Globe", Vector3.one * 1.3, cf * CFrame.new(1.8, 4.8, 0.2) * CFrame.Angles(0, 0, math.rad(23)), Smooth, Color3.fromRGB(70, 110, 160))
	for _ = 1, 3 do
		deco(ellipsoid(b, "GlobeLand", Vector3.new(0.5, 0.4, 0.3), cf * CFrame.new(1.8, 4.8, 0.2) * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(0, 6), 0) * CFrame.new(0, 0, -0.52), Smooth, Color3.fromRGB(110, 150, 80)))
	end
end

-- A reading corner: two armchairs, a side table with a lamp and an open
-- book, a rug.
function Fixtures.readingNook(m, cf, rng)
	local b = model(m, "ReadingNook")
	local yaw = select(2, cf:ToEulerAnglesYXZ())
	deco(at(b, "Rug", cf, 0, 0.03, 0, Vector3.new(7, 0.05, 5), Fabric, pick(RUGS, rng)))
	local fabric = pick(SOFA_FABRICS, rng)
	for _, s in ipairs({ -1, 1 }) do
		local p = (cf * CFrame.new(s * 2.4, 0, 0)).Position
		place(Props.sofa(b, p, fabric, Color3.fromRGB(90, 70, 50), 3.2), p, Vector3.zero, yaw + (if s > 0 then math.pi else 0) + rng:NextNumber(-0.25, 0.25))
	end
	local p = (cf * CFrame.new(0, 0, 1.6)).Position
	place(Props.table(b, p, Vector3.new(1.6, 2, 1.6), pick(WOODS, rng), DARK), p, Vector3.zero, yaw)
	tableLamp(b, cf * CFrame.new(0.3, 2, 1.8), rng)
	deco(at(b, "OpenBook", cf * CFrame.Angles(0, 0, math.rad(4)), -0.3, 2.06, 1.4, Vector3.new(0.9, 0.06, 0.65), Smooth, Color3.fromRGB(240, 236, 224)))
end

-- ===== The gallery =====

-- Paint a composition onto a canvas: `face` is a frame on the canvas's
-- surface (x across, y up, -z out of the picture), w x h its size. Each
-- layer sits a hair further out than the last so none of them flicker.
local function composition(b, face, w, h, rng)
	local depth = 0
	local function layer(x, y, sx, sy, color, round)
		depth += 0.012
		local p = if round then cylinder(b, "Paint", 0.02, math.min(sx, sy), face * CFrame.new(x, y, -depth) * FACING_Z, Smooth, color) else part(b, "Paint", Vector3.new(sx, sy, 0.02), face * CFrame.new(x, y, -depth), Smooth, color)
		deco(p)
	end
	local kind = rng:NextInteger(1, 4)
	if kind == 1 then -- a landscape: sky, a mountain, a sun, the ground
		layer(0, h * 0.2, w, h * 0.6, pick({ Color3.fromRGB(150, 180, 210), Color3.fromRGB(220, 170, 130), Color3.fromRGB(60, 70, 100) }, rng))
		layer(rng:NextNumber(-w / 4, w / 4), h * 0.25, h * 0.2, h * 0.2, Color3.fromRGB(250, 230, 180), true)
		layer(rng:NextNumber(-w / 5, w / 5), -h * 0.05, w * 0.5, h * 0.25, pick({ Color3.fromRGB(80, 90, 110), Color3.fromRGB(110, 100, 90) }, rng))
		layer(0, -h * 0.3, w, h * 0.4, pick({ Color3.fromRGB(80, 110, 60), Color3.fromRGB(150, 130, 80), Color3.fromRGB(40, 70, 90) }, rng))
	elseif kind == 2 then -- abstract: bold blocks and a circle
		layer(0, 0, w, h, pick({ WHITE, Color3.fromRGB(230, 220, 190), Color3.fromRGB(30, 30, 34) }, rng))
		for _ = 1, rng:NextInteger(2, 4) do
			layer(rng:NextNumber(-w / 3, w / 3), rng:NextNumber(-h / 3, h / 3), rng:NextNumber(w * 0.15, w * 0.5), rng:NextNumber(h * 0.1, h * 0.5), pick({ Color3.fromRGB(200, 40, 40), Color3.fromRGB(30, 60, 150), Color3.fromRGB(240, 200, 40), DARK }, rng), rng:NextNumber() < 0.3)
		end
	elseif kind == 3 then -- a portrait: dark ground, a head and shoulders
		layer(0, 0, w, h, pick({ Color3.fromRGB(40, 36, 32), Color3.fromRGB(60, 50, 40), Color3.fromRGB(30, 40, 50) }, rng))
		layer(0, -h * 0.3, w * 0.7, h * 0.35, pick({ Color3.fromRGB(30, 30, 40), Color3.fromRGB(120, 40, 40), Color3.fromRGB(60, 80, 60) }, rng))
		depth += 0.012
		deco(ellipsoid(b, "Paint", Vector3.new(w * 0.28, h * 0.36, 0.03), face * CFrame.new(0, h * 0.08, -depth), Smooth, pick({ Color3.fromRGB(220, 190, 160), Color3.fromRGB(200, 170, 140) }, rng)))
	else -- a night sea under the moon
		layer(0, h * 0.15, w, h * 0.7, Color3.fromRGB(20, 26, 50))
		layer(w * 0.2, h * 0.3, h * 0.18, h * 0.18, Color3.fromRGB(240, 236, 200), true)
		layer(0, -h * 0.3, w, h * 0.4, Color3.fromRGB(20, 40, 60))
		layer(w * 0.2, -h * 0.25, w * 0.08, h * 0.3, Color3.fromRGB(200, 200, 170))
	end
end

-- A framed picture hung on a wall frame `wall` (on the wall surface,
-- -z out of it): moulding, a white mat, the painting (or an empty frame
-- where one's been taken), a card beside it.
local function picture(b, wall, w, h, rng, lit)
	local frameColor = pick({ Color3.fromRGB(180, 150, 80), Color3.fromRGB(40, 32, 26), Color3.fromRGB(200, 196, 186) }, rng)
	part(b, "PictureFrame", Vector3.new(w + 0.8, h + 0.8, 0.25), wall * CFrame.new(0, 0, -0.125), Wood, frameColor)
	part(b, "PictureMat", Vector3.new(w + 0.3, h + 0.3, 0.05), wall * CFrame.new(0, 0, -0.27), Smooth, Color3.fromRGB(244, 242, 236))
	local face = wall * CFrame.new(0, 0, -0.295)
	if rng:NextNumber() < 0.88 then
		composition(b, face, w, h, rng)
	else
		label(b, wall * CFrame.new(0, 0, -0.32), Vector3.new(w * 0.7, h * 0.25, 0.03), Enum.NormalId.Front, "作品貸出中", Color3.fromRGB(244, 242, 236), Color3.fromRGB(90, 90, 94), Smooth, Enum.Font.Gotham)
	end
	label(b, wall * CFrame.new(w / 2 + 1.1, -h / 2 + 0.4, -0.03), Vector3.new(0.9, 0.6, 0.04), Enum.NormalId.Front, pick({ "無題", "月夜", "港", "母", "No.7", "風景", "静物" }, rng), Color3.fromRGB(250, 250, 244), DARK, Smooth, Enum.Font.Gotham)
	-- A picture light on an arm above.
	deco(rod(b, "LightArm", (wall * CFrame.new(0, h / 2 + 0.5, 0)).Position, (wall * CFrame.new(0, h / 2 + 0.9, -0.9)).Position, 0.08, Metal, GOLD))
	local lamp = deco(cylinder(b, "PictureLight", w * 0.5, 0.3, wall * CFrame.new(0, h / 2 + 0.9, -0.95), Metal, GOLD))
	if lit then
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 70
		light.Range = h + 3
		light.Brightness = 1.2
		light.Color = Color3.fromRGB(255, 236, 206)
		light.Parent = lamp
	end
end

-- A freestanding gallery wall with a picture on each face.
function Fixtures.galleryWall(m, cf, rng)
	local b = model(m, "GalleryWall")
	local W, H, T = 9, 10, 0.8
	at(b, "GalleryWall", cf, 0, H / 2, 0, Vector3.new(W, H, T), Smooth, Color3.fromRGB(238, 236, 230))
	at(b, "WallPlinth", cf, 0, 0.2, 0, Vector3.new(W + 0.1, 0.4, T + 0.1), Smooth, Color3.fromRGB(60, 60, 62))
	for _, s in ipairs({ -1, 1 }) do
		local wall = cf * CFrame.new(0, 5.2, s * T / 2) * (if s > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity)
		if rng:NextNumber() < 0.08 then
			-- fallen off its hooks, leaning against the wall
			local w, h = rng:NextNumber(3, 5), rng:NextNumber(2.5, 4)
			picture(b, cf * CFrame.new(rng:NextNumber(-2, 2), h / 2 + 0.5, s * (T / 2 + 0.6)) * (if s > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity) * CFrame.Angles(math.rad(-10), 0, 0), w, h, rng, false)
		else
			picture(b, wall, rng:NextNumber(3.2, 5.6), rng:NextNumber(2.6, 4.4), rng, rng:NextNumber() < 0.3)
		end
	end
end

-- A statue: the figure cast in marble (or bronze) on a tall plinth, a
-- brass rope round it.
function Fixtures.statue(m, cf, rng)
	local b = model(m, "Statue")
	local stone = pick({ { Enum.Material.Marble, Color3.fromRGB(232, 230, 222) }, { Enum.Material.Metal, Color3.fromRGB(120, 90, 50) }, { Enum.Material.Slate, Color3.fromRGB(70, 70, 72) } }, rng)
	at(b, "StatuePlinth", cf, 0, 1.6, 0, Vector3.new(2.8, 3.2, 2.8), Enum.Material.Marble, Color3.fromRGB(210, 206, 196))
	at(b, "PlinthCap", cf, 0, 3.3, 0, Vector3.new(3.1, 0.2, 3.1), Enum.Material.Marble, Color3.fromRGB(190, 186, 176))
	local rig = PropLibrary.rig()
	if rig then
		rig.Parent = b
		PropLibrary.pose(rig, pick({
			{ RightShoulder = CFrame.Angles(2.4, 0, 0.2), RightElbow = CFrame.Angles(0.4, 0, 0), Neck = CFrame.Angles(0.35, 0, 0), LeftHip = CFrame.Angles(0.1, 0, 0), LeftKnee = CFrame.Angles(-0.3, 0, 0) },
			{ LeftShoulder = CFrame.Angles(0.3, 0, -0.1), LeftElbow = CFrame.Angles(1.6, 0, 0), Neck = CFrame.Angles(-0.35, 0.2, 0), Waist = CFrame.Angles(0.15, 0, 0), RightKnee = CFrame.Angles(-0.2, 0, 0) },
			{ LeftShoulder = CFrame.Angles(0, 0, -1.3), RightShoulder = CFrame.Angles(0, 0, 1.3), Neck = CFrame.Angles(0.2, 0, 0) },
			{ RightShoulder = CFrame.Angles(0.9, 0, 0.3), RightElbow = CFrame.Angles(1.8, 0, 0), Neck = CFrame.Angles(-0.2, -0.4, 0.1), LeftHip = CFrame.Angles(-0.12, 0, 0), Waist = CFrame.Angles(0, 0.25, 0.05) },
		}, rng))
		for _, p in ipairs(rig:GetChildren()) do
			if p:IsA("BasePart") then
				p.Material = stone[1]
				p.Color = stone[2]
			end
		end
		if rng:NextNumber() < 0.3 then
			local arm = rig:FindFirstChild(pick({ "LeftLowerArm", "RightLowerArm" }, rng))
			if arm then
				arm:Destroy()
			end
		end
		local hips = rig:FindFirstChild("LowerTorso")
		if hips then
			rig.WorldPivot = hips.CFrame
		end
		if not pcall(PropLibrary.fit, rig, cf * CFrame.new(0, 3.4, 0) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), 0), rng:NextNumber(6, 7.5)) then
			rig:Destroy()
		end
	else
		ellipsoid(b, "Sculpture", Vector3.new(1.8, 4.5, 1.6), cf * CFrame.new(0, 5.6, 0), stone[1], stone[2])
	end
	-- Stanchions and a velvet rope.
	local posts = {}
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		local p = cf * CFrame.new(math.cos(a) * 3, 0, math.sin(a) * 3)
		upright(b, "StanchionBase", 0.12, 0.8, p, 0, 0.06, 0, Metal, GOLD)
		upright(b, "Stanchion", 3, 0.16, p, 0, 1.5, 0, Metal, GOLD)
		table.insert(posts, (p * CFrame.new(0, 2.9, 0)).Position)
	end
	for k = 1, 4 do
		if k ~= 4 or rng:NextNumber() < 0.5 then
			local a, c = posts[k], posts[k % 4 + 1]
			local mid = (a + c) / 2 - Vector3.new(0, 0.5, 0)
			deco(rod(b, "Rope", a, mid, 0.14, Fabric, Color3.fromRGB(150, 20, 40)))
			deco(rod(b, "Rope", mid, c, 0.14, Fabric, Color3.fromRGB(150, 20, 40)))
		end
	end
end

-- An abstract sculpture: a ring, a stack of stones, or a twisting tower.
function Fixtures.sculpture(m, cf, rng)
	local b = model(m, "Sculpture")
	at(b, "SculpturePlinth", cf, 0, 0.6, 0, Vector3.new(3.4, 1.2, 3.4), Smooth, Color3.fromRGB(236, 234, 228))
	local mat = pick({ { Enum.Material.Metal, CHROME }, { Enum.Material.Metal, Color3.fromRGB(150, 110, 60) }, { Enum.Material.Marble, WHITE }, { Enum.Material.Slate, Color3.fromRGB(60, 58, 56) } }, rng)
	local kind = rng:NextInteger(1, 3)
	if kind == 1 then
		local r, n = 2.3, 14
		for k = 0, n - 1 do
			local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
			rod(b, "Ring", (cf * CFrame.new(math.cos(a0) * r, 3.6 + math.sin(a0) * r, 0)).Position, (cf * CFrame.new(math.cos(a1) * r, 3.6 + math.sin(a1) * r, 0)).Position, 0.7, mat[1], mat[2])
		end
	elseif kind == 2 then
		local y = 1.2
		for _ = 1, rng:NextInteger(3, 5) do
			local s = Vector3.new(rng:NextNumber(1.2, 2.4), rng:NextNumber(0.7, 1.2), rng:NextNumber(1.1, 2))
			ellipsoid(b, "Stone", s, cf * CFrame.new(rng:NextNumber(-0.2, 0.2), y + s.Y / 2 - 0.1, rng:NextNumber(-0.2, 0.2)) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.15, 0.15)), mat[1], mat[2])
			y += s.Y - 0.2
		end
	else
		for k = 0, 6 do
			at(b, "Twist", cf * CFrame.Angles(0, k * 0.28, 0), 0, 1.6 + k * 0.85, 0, Vector3.new(1.8 - k * 0.12, 0.8, 1.8 - k * 0.12), mat[1], mat[2])
		end
	end
end

-- A glass vitrine on a plinth with a pot in it.
function Fixtures.vitrine(m, cf, rng)
	local b = model(m, "Vitrine")
	at(b, "VitrinePlinth", cf, 0, 1.7, 0, Vector3.new(2.4, 3.4, 2.4), Smooth, Color3.fromRGB(236, 234, 228))
	local glaze = pick({ Color3.fromRGB(60, 90, 110), Color3.fromRGB(170, 120, 80), Color3.fromRGB(220, 216, 200), Color3.fromRGB(40, 40, 44), Color3.fromRGB(150, 40, 30) }, rng)
	ellipsoid(b, "PotBelly", Vector3.new(1.3, 1.2, 1.3), cf * CFrame.new(0, 4.1, 0), Smooth, glaze)
	upright(b, "PotNeck", 0.6, 0.55, cf, 0, 4.9, 0, Smooth, glaze)
	upright(b, "PotLip", 0.12, 0.75, cf, 0, 5.22, 0, Smooth, glaze)
	if rng:NextNumber() < 0.85 then
		at(b, "VitrineGlass", cf, 0, 4.9, 0, Vector3.new(2.2, 3, 2.2), Glass, GLASS).Transparency = 0.8
	else
		for _ = 1, 5 do
			deco(at(b, "GlassShard", cf * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(-2, 2), 0.03, rng:NextNumber(-2, 2), Vector3.new(rng:NextNumber(0.3, 1), 0.04, rng:NextNumber(0.3, 0.8)), Glass, GLASS)).Transparency = 0.4
		end
	end
	label(b, cf * CFrame.new(0, 2.6, -1.23), Vector3.new(1.4, 0.6, 0.03), Enum.NormalId.Front, pick({ "伊万里", "備前", "青磁", "楽焼", "九谷" }, rng), Color3.fromRGB(250, 250, 244), DARK, Smooth, Enum.Font.Gotham)
end

-- A long leather gallery bench.
function Fixtures.galleryBench(m, cf, rng)
	local b = model(m, "GalleryBench")
	at(b, "BenchCushion", cf, 0, 1.55, 0, Vector3.new(6, 0.5, 1.8), Leather, pick({ DARK, Color3.fromRGB(110, 70, 50) }, rng))
	at(b, "BenchFrame", cf, 0, 1.2, 0, Vector3.new(6.1, 0.2, 1.9), Metal, CHROME)
	for _, x in ipairs({ -2.7, 2.7 }) do
		at(b, "BenchLeg", cf, x, 0.55, 0, Vector3.new(0.2, 1.1, 1.7), Metal, CHROME)
	end
end

-- The moon: a great pale sphere hung on cables in the atrium below the
-- gallery, lit from within, cratered.
function Fixtures.hangingMoon(m, center, radius, ceiling, rng)
	local b = model(m, "HangingMoon")
	local moon = part(b, "Moon", Vector3.one * radius * 2, center, Neon, Color3.fromRGB(176, 172, 150))
	moon.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 1.4
	light.Color = Color3.fromRGB(230, 226, 200)
	light.Parent = moon
	for _ = 1, 9 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
		local s = rng:NextNumber(0.12, 0.3) * radius
		deco(ellipsoid(b, "Crater", Vector3.new(s * 2, s * 2, s * 0.5), CFrame.lookAt(center + dir * (radius - s * 0.12), center + dir * radius * 2), Smooth, Color3.fromRGB(150, 146, 128)))
	end
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		local top = Vector3.new(center.X + math.cos(a) * radius * 0.5, ceiling, center.Z + math.sin(a) * radius * 0.5)
		rod(b, "MoonCable", top, center + Vector3.new(math.cos(a) * radius * 0.5, radius * 0.86, math.sin(a) * radius * 0.5), 0.08, Metal, STEEL)
	end
end

-- ===== What goes on each floor =====

local WOMENS = { Color3.fromRGB(200, 60, 70), Color3.fromRGB(230, 220, 200), Color3.fromRGB(60, 80, 130), Color3.fromRGB(40, 40, 44), Color3.fromRGB(190, 150, 90), Color3.fromRGB(110, 150, 120), Color3.fromRGB(220, 170, 190), Color3.fromRGB(240, 238, 230) }
local SUITS = { Color3.fromRGB(40, 42, 50), Color3.fromRGB(60, 62, 70), Color3.fromRGB(90, 80, 70), Color3.fromRGB(30, 34, 44), Color3.fromRGB(110, 100, 86) }
local SHIRTS = { WHITE, Color3.fromRGB(180, 200, 230), Color3.fromRGB(230, 220, 200), Color3.fromRGB(200, 200, 204), Color3.fromRGB(220, 180, 180) }
Fixtures.WOMENS, Fixtures.SUITS = WOMENS, SUITS

-- Put one fixture at a spot on a floor of this kind; false if the kind
-- isn't one this knows.
function Fixtures.furnish(m, kind, cf, rng)
	local roll = rng:NextNumber()
	if kind == "cosmetics" then
		if roll < 0.55 then
			Fixtures.beautyCounter(m, cf, rng)
		elseif roll < 0.76 then
			Fixtures.perfumeIsland(m, cf, rng)
		elseif roll < 0.9 then
			Fixtures.mannequinGroup(m, cf, rng, { "blouse", "dress" }, WOMENS)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "womens" then
		local style = pick({ "top", "dress", "coat", "top" }, rng)
		if roll < 0.26 then
			Fixtures.clothesRack(m, cf, rng, WOMENS, style)
		elseif roll < 0.46 then
			Fixtures.roundRack(m, cf, rng, WOMENS, style)
		elseif roll < 0.6 then
			Fixtures.displayTable(m, cf, rng, WOMENS, false)
		elseif roll < 0.76 then
			Fixtures.mannequinGroup(m, cf, rng, { "dress", "blouse", "casual" }, WOMENS)
		elseif roll < 0.86 then
			Fixtures.mannequin(m, cf, rng, pick({ "dress", "blouse", "casual", "bare" }, rng), WOMENS)
		elseif roll < 0.94 then
			Fixtures.shoeWall(m, cf, rng, true)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "mens" then
		if roll < 0.28 then
			Fixtures.clothesRack(m, cf, rng, SUITS, if rng:NextNumber() < 0.75 then "jacket" else "coat")
		elseif roll < 0.42 then
			Fixtures.displayTable(m, cf, rng, SHIRTS, true)
		elseif roll < 0.58 then
			Fixtures.shoeWall(m, cf, rng, false)
		elseif roll < 0.68 then
			Fixtures.tieCase(m, cf, rng)
		elseif roll < 0.84 then
			if rng:NextNumber() < 0.5 then
				Fixtures.mannequinGroup(m, cf, rng, { "suit", "suit", "casual" }, SUITS)
			else
				Fixtures.mannequin(m, cf, rng, "suit", SUITS)
			end
		elseif roll < 0.93 then
			Fixtures.shoeBench(m, cf, rng)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "home" then
		if roll < 0.24 then
			Fixtures.livingSet(m, cf, rng)
		elseif roll < 0.42 then
			Fixtures.bedroomSet(m, cf, rng)
		elseif roll < 0.54 then
			Fixtures.kitchen(m, cf, rng)
		elseif roll < 0.68 then
			Fixtures.diningSet(m, cf, rng)
		elseif roll < 0.82 then
			Fixtures.crockeryShelf(m, cf, rng)
		elseif roll < 0.93 then
			Fixtures.lampCluster(m, cf, rng)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "toys" then
		if roll < 0.26 then
			Fixtures.plushShelf(m, cf, rng)
		elseif roll < 0.48 then
			Fixtures.toyShelf(m, cf, rng)
		elseif roll < 0.62 then
			Fixtures.gachapon(m, cf, rng)
		elseif roll < 0.74 then
			Fixtures.trainTable(m, cf, rng)
		elseif roll < 0.9 then
			Fixtures.plushBin(m, cf, rng)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "restaurant" then
		if roll < 0.3 then
			Fixtures.booth(m, cf, rng)
		elseif roll < 0.45 then
			Fixtures.ramenCounter(m, cf, rng)
		elseif roll < 0.7 then
			Fixtures.cafeTable(m, cf, rng)
		elseif roll < 0.85 then
			Fixtures.diningSet(m, cf, rng)
		elseif roll < 0.93 then
			Fixtures.drinkBar(m, cf, rng)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "event" then
		if roll < 0.3 then
			Fixtures.fairStall(m, cf, rng)
		elseif roll < 0.5 then
			Fixtures.saleWagon(m, cf, rng)
		elseif roll < 0.65 then
			Fixtures.clothesRack(m, cf, rng, WOMENS, pick({ "top", "dress", "coat" }, rng))
		elseif roll < 0.77 then
			Fixtures.mannequinGroup(m, cf, rng, { "dress", "blouse", "casual", "suit" }, WOMENS)
		elseif roll < 0.87 then
			Fixtures.chairStack(m, cf, rng)
		elseif roll < 0.95 then
			Fixtures.displayTable(m, cf, rng, WOMENS, false)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "books" then
		if roll < 0.45 then
			Fixtures.bookGondola(m, cf, rng)
		elseif roll < 0.65 then
			Fixtures.bookTable(m, cf, rng)
		elseif roll < 0.77 then
			Fixtures.magazineRack(m, cf, rng)
		elseif roll < 0.85 then
			Fixtures.stationery(m, cf, rng)
		elseif roll < 0.93 then
			Fixtures.readingNook(m, cf, rng)
		else
			Fixtures.cashDesk(m, cf, rng)
		end
	elseif kind == "gallery" then
		if roll < 0.4 then
			Fixtures.galleryWall(m, cf, rng)
		elseif roll < 0.58 then
			Fixtures.statue(m, cf, rng)
		elseif roll < 0.72 then
			Fixtures.sculpture(m, cf, rng)
		elseif roll < 0.86 then
			Fixtures.vitrine(m, cf, rng)
		elseif roll < 0.94 then
			Fixtures.galleryBench(m, cf, rng)
		end
	else
		return false
	end
	return true
end

return Fixtures
