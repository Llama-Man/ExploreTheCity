-- People live on the outside of the department store now, in shacks you
-- can walk into, some together and some on their own:
--   * a boardwalk hung off the south face level with the top bridge's
--     way in (16F): a tea house for travellers off the bridge and a
--     general store either side of it, a four-storey tower with stairs up
--     inside to a roof garden, and a laundry yard at the west end;
--   * a scaffold stair up the south-west corner to a second boardwalk on
--     the west face at 19F: a drying area, a greenhouse, a terrace, and a
--     shack knocked through into the store;
--   * a workshop on a short boardwalk at 9F, where the pipe bridge comes
--     in from the tunnels;
--   * lone shacks dotted round all four faces at other floors, each
--     reached through a window knocked out of the store behind it, with
--     its own porch, washing and a power run down the wall.
--
-- Built of corrugated sheet, plywood and old doors; gardens in planters
-- and a bathtub, rain barrels, solar panels, stovepipes, lanterns, cats;
-- power lines stolen off the bridge and strung between roofs, washing
-- everywhere, some of it strung out over the drop.
--
-- Each room has one or two LootSpot parts (invisible, tagged "LootSpot")
-- where chests can go later.
--
-- Built by DepartmentStore once the store is in place (StoreShacks.build).

local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local TunnelProps = require(script.Parent.TunnelProps)
local Fixtures = require(script.Parent.StoreFixtures)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local rod, upright, deco, label = Fixtures.rod, Fixtures.upright, Fixtures.deco, Fixtures.label
local Metal, Smooth, Wood, Fabric, Glass, Neon = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.Glass, Enum.Material.Neon
local Corroded, Plywood, Diamond = Enum.Material.CorrodedMetal, Enum.Material.WoodPlanks, Enum.Material.DiamondPlate
local ellipsoid = TunnelProps.ellipsoid
local rgb = Color3.fromRGB

local DARK = rgb(40, 40, 42)
local STEEL = rgb(110, 112, 114)
local RUST = rgb(116, 76, 48)
local CABLE = rgb(34, 34, 36)
local WARM = rgb(255, 206, 140)
local TIMBER = rgb(110, 84, 58)
local SHEET = { rgb(120, 110, 96), rgb(96, 110, 120), rgb(150, 80, 60), rgb(110, 124, 100), rgb(170, 160, 140), rgb(70, 90, 120), rgb(180, 170, 150) }
local PLY = { rgb(170, 140, 100), rgb(150, 120, 84), rgb(190, 164, 120) }
local CLOTHES = { rgb(230, 226, 214), rgb(200, 60, 60), rgb(60, 100, 170), rgb(240, 200, 70), rgb(90, 140, 90), rgb(230, 150, 180), rgb(60, 60, 66), rgb(160, 120, 80) }
local BRIGHT = { rgb(60, 120, 200), rgb(200, 60, 50), rgb(240, 200, 60), rgb(80, 160, 90) }

local StoreShacks = {}

local lightsLeft = 0

local function glow(p, range)
	if lightsLeft > 0 then
		lightsLeft -= 1
		local light = Instance.new("PointLight")
		light.Range = range or 14
		light.Brightness = 0.9
		light.Color = WARM
		light.Parent = p
	end
end

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

-- Where a chest can go later.
local function lootSpot(parent, cf)
	local p = part(parent, "LootSpot", Vector3.new(2, 2, 2), cf * CFrame.new(0, 1, 0), Smooth, rgb(255, 220, 0))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p:AddTag("LootSpot")
	return p
end

-- ===== Lines: cables, wires, washing =====

-- A cable or rope sagging from a to b, walk-through.
local function sagging(parent, name, a, b, sag, n, diameter, material, color)
	local points = {}
	local prev = a
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		deco(rod(parent, name, prev, p, diameter, material, color))
		table.insert(points, p)
		prev = p
	end
	return points
end

-- Two or three power cables slung together between a and b.
local function wires(parent, a, b, rng)
	local w = model(parent, "Wires")
	local len = (b - a).Magnitude
	for k = 1, rng:NextInteger(2, 3) do
		local off = Vector3.new(0, -(k - 1) * 0.3, 0)
		sagging(w, "Wire", a + off, b + off, len * rng:NextNumber(0.05, 0.09) + k * 0.2, math.clamp(math.floor(len / 4), 4, 16), 0.08, Smooth, CABLE)
	end
end

-- One thing hung on a washing line at p.
local function laundry(parent, p, along, rng)
	local cf = CFrame.lookAt(p, p + along:Cross(Vector3.yAxis))
	local c = pick(CLOTHES, rng)
	local roll = rng:NextNumber()
	if roll < 0.35 then
		deco(part(parent, "Shirt", Vector3.new(1.1, 1.3, 0.05), cf * CFrame.new(0, -0.7, 0), Fabric, c))
		for _, s in ipairs({ -1, 1 }) do
			deco(part(parent, "Sleeve", Vector3.new(0.6, 0.35, 0.05), cf * CFrame.new(s * 0.72, -0.25, 0) * CFrame.Angles(0, 0, s * -0.5), Fabric, c))
		end
	elseif roll < 0.55 then
		deco(part(parent, "Towel", Vector3.new(0.9, 1.5, 0.05), cf * CFrame.new(0, -0.75, 0), Fabric, c))
	elseif roll < 0.7 then
		deco(part(parent, "Sheet", Vector3.new(2.4, 2, 0.05), cf * CFrame.new(0, -1, 0), Fabric, pick({ rgb(236, 234, 226), rgb(200, 216, 230), rgb(230, 210, 200) }, rng)))
	elseif roll < 0.85 then
		for _, s in ipairs({ -1, 1 }) do
			deco(part(parent, "TrouserLeg", Vector3.new(0.45, 1.6, 0.05), cf * CFrame.new(s * 0.26, -0.8, 0), Fabric, c))
		end
	else
		for _, s in ipairs({ -1, 1 }) do
			deco(part(parent, "Sock", Vector3.new(0.22, 0.6, 0.05), cf * CFrame.new(s * 0.2, -0.3, 0), Fabric, c))
		end
	end
end

local function washingLine(parent, a, b, rng)
	local w = model(parent, "WashingLine")
	local len = (b - a).Magnitude
	local points = sagging(w, "Line", a, b, len * 0.05, math.clamp(math.floor(len / 1.6), 3, 20), 0.05, Fabric, rgb(220, 216, 200))
	local along = (b - a).Unit
	for i = 1, #points - 1 do
		if rng:NextNumber() < 0.7 then
			laundry(w, points[i], along, rng)
		end
	end
end

-- ===== Small things =====

local function cat(parent, cf, rng)
	local c = model(parent, "Cat")
	local fur = pick({ rgb(220, 140, 60), rgb(40, 40, 42), rgb(236, 232, 222), rgb(150, 130, 110) }, rng)
	deco(ellipsoid(c, "CatBody", Vector3.new(0.7, 0.55, 1.2), cf * CFrame.new(0, 0.28, 0), Fabric, fur))
	local head = cf * CFrame.new(0, 0.42, -0.62)
	deco(ellipsoid(c, "CatHead", Vector3.new(0.55, 0.48, 0.5), head, Fabric, fur))
	for _, s in ipairs({ -1, 1 }) do
		deco(ellipsoid(c, "CatEar", Vector3.new(0.14, 0.22, 0.08), head * CFrame.new(s * 0.16, 0.24, 0.05), Fabric, fur))
	end
	deco(rod(c, "CatTail", (cf * CFrame.new(0, 0.2, 0.55)).Position, (cf * CFrame.new(0.5, 0.1, 0.1)).Position, 0.14, Fabric, fur))
end

-- Vegetables in a box (or a bathtub): leaves, a few tomatoes.
local function garden(parent, cf, w, d, rng, tub)
	local g = model(parent, "Garden")
	if tub then
		part(g, "Bathtub", Vector3.new(w, 1.6, d), cf * CFrame.new(0, 0.8, 0), Smooth, rgb(236, 236, 230))
	else
		part(g, "Planter", Vector3.new(w, 1.2, d), cf * CFrame.new(0, 0.6, 0), Wood, pick(PLY, rng))
	end
	local top = if tub then 1.6 else 1.2
	part(g, "Soil", Vector3.new(w - 0.3, 0.1, d - 0.3), cf * CFrame.new(0, top - 0.02, 0), Enum.Material.Ground, rgb(60, 44, 32))
	for _ = 1, math.max(2, math.floor(w * d * 0.6)) do
		local x, z = rng:NextNumber(-w / 2 + 0.4, w / 2 - 0.4), rng:NextNumber(-d / 2 + 0.3, d / 2 - 0.3)
		local s = rng:NextNumber(0.5, 1)
		deco(ellipsoid(g, "Leaves", Vector3.new(s, s * 0.8, s), cf * CFrame.new(x, top + s * 0.3, z), Enum.Material.LeafyGrass, jitter(rgb(80, 130, 60), rng, 0.15)))
		if rng:NextNumber() < 0.3 then
			deco(ellipsoid(g, "Tomato", Vector3.one * 0.25, cf * CFrame.new(x + 0.2, top + s * 0.4, z - 0.2), Smooth, rgb(200, 40, 30)))
		end
	end
end

local function lantern(parent, cf, rng, lit)
	local l = deco(ellipsoid(parent, "Lantern", Vector3.new(0.8, 1.1, 0.8), cf, if lit then Neon else Fabric, if lit then rgb(240, 150, 90) else rgb(190, 60, 50)))
	deco(upright(parent, "LanternCap", 0.15, 0.5, cf, 0, 0.6, 0, Smooth, DARK))
	if lit then
		glow(l, 12)
	end
	return l
end

-- ===== Decks and rails =====

-- A rail along a straight edge from a to b (at deck level), posts and
-- two bars; solid, to stop you falling.
local function rail(parent, a, b)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local n = math.max(1, math.floor(len / 4))
	for k = 0, n do
		local p = a:Lerp(b, k / n)
		rod(parent, "RailPost", p, p + Vector3.new(0, 3.3, 0), 0.22, Wood, TIMBER)
	end
	for _, h in ipairs({ 1.6, 3.2 }) do
		rod(parent, "RailBar", a + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0), 0.18, Wood, TIMBER)
	end
end

-- A deck over [x0,x1] x [z0,z1] with its top at y, in panels of scrap
-- (plywood, plate, sheet) along its long side, on two joists.
local function deckArea(parent, x0, x1, z0, z1, y, rng)
	local alongX = (x1 - x0) >= (z1 - z0)
	local a, b = if alongX then x0 else z0, if alongX then x1 else z1
	local u = a
	while u < b - 0.05 do
		local n = math.min(b, u + rng:NextNumber(4, 9))
		if b - n < 2 then
			n = b
		end
		local roll = rng:NextNumber()
		local material = if roll < 0.55 then Plywood elseif roll < 0.8 then Diamond else Corroded
		local color = if material == Plywood then pick(PLY, rng) elseif material == Diamond then rgb(96, 98, 100) else pick(SHEET, rng)
		if alongX then
			box(parent, "Deck", u, n, y - 0.4, y, z0, z1, material, jitter(color, rng, 0.05))
		else
			box(parent, "Deck", x0, x1, y - 0.4, y, u, n, material, jitter(color, rng, 0.05))
		end
		u = n
	end
	for _, f in ipairs({ 0.2, 0.8 }) do
		if alongX then
			local z = z0 + (z1 - z0) * f
			box(parent, "Joist", x0, x1, y - 1.1, y - 0.4, z - 0.25, z + 0.25, Corroded, RUST)
		else
			local x = x0 + (x1 - x0) * f
			box(parent, "Joist", x - 0.25, x + 0.25, y - 1.1, y - 0.4, z0, z1, Corroded, RUST)
		end
	end
end

-- Struts under a deck's outer edge back to the wall, and cables from the
-- edge up to plates on the wall. `outer` and `wall` are points on the
-- outer edge and the wall at the same position along it.
local function braces(parent, outer, wall)
	rod(parent, "DeckStrut", outer - Vector3.new(0, 1, 0), wall - Vector3.new(0, 8, 0), 0.4, Corroded, RUST)
	deco(rod(parent, "DeckCable", outer + Vector3.new(0, 0.3, 0), wall + Vector3.new(0, 14, 0), 0.1, Metal, CABLE))
	part(parent, "WallPlate", Vector3.new(0.8, 0.8, 0.8), wall + Vector3.new(0, 14, 0), Metal, STEEL)
end

-- A tall pole on a deck's edge to hang lines from.
local function linePole(parent, p)
	rod(parent, "LinePole", p, p + Vector3.new(0, 9, 0), 0.3, Wood, TIMBER)
	return p + Vector3.new(0, 8.6, 0)
end

-- ===== Walls =====

-- One wall of mismatched panels: along local x at z = at (alongX), or
-- along local z at x = at, from a to b, h tall, with openings
-- {c, w, y0, y1} cut out of it.
local function wallRun(s, cf, alongX, at, a, b, h, openings, rng, glassy)
	table.sort(openings, function(p, q)
		return p.c < q.c
	end)
	local function piece(u0, u1, y0, y1)
		if u1 - u0 < 0.05 or y1 - y0 < 0.05 then
			return
		end
		local material, color
		if glassy then
			material, color = Glass, rgb(200, 220, 214)
		else
			local r = rng:NextNumber()
			material = if r < 0.5 then Corroded elseif r < 0.85 then Plywood else Metal
			color = if material == Plywood then pick(PLY, rng) else pick(SHEET, rng)
		end
		local mid, len = (u0 + u1) / 2, u1 - u0
		local size = if alongX then Vector3.new(len, y1 - y0, 0.2) else Vector3.new(0.2, y1 - y0, len)
		local at3 = if alongX then CFrame.new(mid, (y0 + y1) / 2, at) else CFrame.new(at, (y0 + y1) / 2, mid)
		local p = part(s, "Wall", size, cf * at3, material, jitter(color, rng, 0.05))
		if glassy then
			p.Transparency = 0.55
		end
	end
	local function solid(u0, u1, y0, y1)
		local u = u0
		while u < u1 - 0.05 do
			local n = math.min(u1, u + rng:NextNumber(3, 6))
			if u1 - n < 1.5 then
				n = u1
			end
			piece(u, n, y0, y1)
			u = n
		end
	end
	local u = a
	for _, o in ipairs(openings) do
		solid(u, o.c - o.w / 2, 0, h)
		solid(o.c - o.w / 2, o.c + o.w / 2, 0, o.y0)
		solid(o.c - o.w / 2, o.c + o.w / 2, o.y1, h)
		u = o.c + o.w / 2
	end
	solid(u, b, 0, h)
end

-- A window in an opening: the pane (glowing if lit), a sill and a head,
-- a curtain.
local function window(s, cf, alongX, at, o, rng, lit, inward)
	inward = inward or 1
	local size = if alongX then Vector3.new(o.w, o.y1 - o.y0, 0.08) else Vector3.new(0.08, o.y1 - o.y0, o.w)
	local c = if alongX then CFrame.new(o.c, (o.y0 + o.y1) / 2, at) else CFrame.new(at, (o.y0 + o.y1) / 2, o.c)
	local pane = part(s, "Window", size, cf * c, if lit then Neon else Glass, if lit then rgb(236, 190, 120) else rgb(70, 80, 86))
	pane.Transparency = if lit then 0.15 else 0.45
	for _, y in ipairs({ o.y0 - 0.1, o.y1 + 0.1 }) do
		local fs = if alongX then Vector3.new(o.w + 0.3, 0.2, 0.35) else Vector3.new(0.35, 0.2, o.w + 0.3)
		local fc = if alongX then CFrame.new(o.c, y, at) else CFrame.new(at, y, o.c)
		part(s, "WindowFrame", fs, cf * fc, Wood, rgb(90, 70, 50))
	end
	if rng:NextNumber() < 0.7 then
		local cs = if alongX then Vector3.new(o.w * 0.4, o.y1 - o.y0, 0.05) else Vector3.new(0.05, o.y1 - o.y0, o.w * 0.4)
		local cc = if alongX then CFrame.new(o.c - o.w * 0.28, (o.y0 + o.y1) / 2, at + inward * 0.2) else CFrame.new(at + inward * 0.2, (o.y0 + o.y1) / 2, o.c - o.w * 0.28)
		deco(part(s, "Curtain", cs, cf * cc, Fabric, pick(CLOTHES, rng)))
	end
	return pane
end

-- ===== Rooms =====
-- Each fills a room r = { cf, x0, x1, zf, zb, h, doorX } in its frame
-- (x across, zb the back, zf the front), keeping clear of the door at
-- doorX on the front.

local function put(s, r, name, size, x, y, z, material, color)
	return part(s, name, size, r.cf * CFrame.new(x, y, z), material, color)
end

-- The room's far side from the door (its x, and which way is inward).
local function farSide(r)
	local cx = (r.x0 + r.x1) / 2
	if r.doorX > cx then
		return r.x0, 1
	end
	return r.x1, -1
end

local function hangingBulb(s, r, rng)
	local at = r.cf * CFrame.new((r.x0 + r.x1) / 2, r.h - 1.6, (r.zf + r.zb) / 2)
	deco(rod(s, "BulbCord", (at * CFrame.new(0, 0.3, 0)).Position, (at * CFrame.new(0, 1.6, 0)).Position, 0.05, Smooth, DARK))
	local lit = rng:NextNumber() < 0.75
	local bulb = part(s, "Bulb", Vector3.one * 0.55, at, if lit then Neon else Glass, if lit then WARM else rgb(200, 200, 190))
	bulb.Shape = Enum.PartType.Ball
	bulb.CanCollide = false
	if lit then
		glow(bulb, 18)
	end
end

local ROOMS = {}

function ROOMS.home(s, r, rng)
	local fx, sf = farSide(r)
	local cx, cz = (r.x0 + r.x1) / 2, (r.zf + r.zb) / 2
	-- A futon along the back, a quilt, a pillow.
	local fz = r.zb - 1.8
	put(s, r, "Futon", Vector3.new(6, 0.5, 3.4), fx + sf * 3.2, 0.25, fz, Fabric, rgb(222, 216, 200))
	deco(put(s, r, "Quilt", Vector3.new(4.4, 0.25, 3.5), fx + sf * 4, 0.6, fz, Fabric, pick(CLOTHES, rng)))
	deco(ellipsoid(s, "Pillow", Vector3.new(1.2, 0.5, 2), r.cf * CFrame.new(fx + sf * 0.9, 0.7, fz), Fabric, rgb(240, 238, 230)))
	-- A chest of drawers against the back on the near side.
	local tx = cx + sf * 4
	put(s, r, "Tansu", Vector3.new(3, 4.4, 1.6), tx, 2.2, r.zb - 0.9, Wood, rgb(110, 76, 50))
	for k = 1, 3 do
		deco(put(s, r, "DrawerLine", Vector3.new(2.8, 0.06, 0.05), tx, k * 1.1, r.zb - 1.72, Wood, rgb(60, 44, 30)))
	end
	deco(upright(s, "Radio", 0.8, 0.6, r.cf, tx - 0.6, 4.8, r.zb - 0.9, Smooth, rgb(60, 60, 64)))
	-- A low table with cushions, tea things.
	local tz = cz - 0.4
	upright(s, "Chabudai", 0.2, 3, r.cf, cx + sf * 0.8, 1.2, tz, Wood, rgb(130, 90, 60))
	upright(s, "ChabudaiLeg", 1.1, 0.4, r.cf, cx + sf * 0.8, 0.55, tz, Wood, rgb(90, 60, 40))
	for _, dz in ipairs({ -1.9, 1.9 }) do
		deco(put(s, r, "Zabuton", Vector3.new(1.6, 0.2, 1.6), cx + sf * 0.8, 0.1, tz + dz, Fabric, pick(CLOTHES, rng)))
	end
	deco(upright(s, "Teapot", 0.45, 0.5, r.cf, cx + sf * 0.5, 1.53, tz, Smooth, rgb(60, 90, 110)))
	deco(upright(s, "Cup", 0.3, 0.28, r.cf, cx + sf * 1.2, 1.45, tz + 0.4, Smooth, WARM))
	-- A stove in the far front corner, its pipe going up out of the roof.
	local sx, sz = fx + sf * 1.1, r.zf + 1.2
	put(s, r, "Stove", Vector3.new(1.4, 1.6, 1.4), sx, 0.8, sz, Metal, DARK)
	deco(upright(s, "Kettle", 0.5, 0.6, r.cf, sx, 1.85, sz, Metal, STEEL))
	deco(rod(s, "Stovepipe", (r.cf * CFrame.new(sx, 1.6, sz)).Position, (r.cf * CFrame.new(sx, r.h + 2.5, sz)).Position, 0.45, Metal, DARK))
	-- A shelf on the far wall with jars.
	put(s, r, "Shelf", Vector3.new(0.6, 0.12, 3), fx + sf * 0.4, 4.4, cz - 0.6, Wood, rgb(110, 80, 56))
	for k = 0, 3 do
		deco(upright(s, "Jar", rng:NextNumber(0.4, 0.8), 0.35, r.cf, fx + sf * 0.4, 4.8, cz - 1.7 + k * 0.7, Glass, pick({ rgb(220, 160, 60), rgb(160, 60, 40), rgb(120, 160, 90) }, rng)))
	end
	deco(put(s, r, "Calendar", Vector3.new(1, 1.3, 0.05), tx + 2.2, 4.6, r.zb - 0.15, Smooth, rgb(240, 236, 226)))
	lootSpot(s, r.cf * CFrame.new(fx + sf * 1.4, 0, r.zf + 3.2))
end

function ROOMS.workshop(s, r, rng)
	local fx, sf = farSide(r)
	local cx = (r.x0 + r.x1) / 2
	-- A long bench along the back, a pegboard of tools over it.
	local len = r.x1 - r.x0 - 2
	put(s, r, "Bench", Vector3.new(len, 0.3, 1.8), cx, 3.1, r.zb - 1, Wood, rgb(150, 112, 76))
	for _, x in ipairs({ cx - len / 2 + 0.3, cx + len / 2 - 0.3 }) do
		put(s, r, "BenchLeg", Vector3.new(0.3, 3, 1.6), x, 1.5, r.zb - 1, Wood, rgb(110, 80, 56))
	end
	put(s, r, "Pegboard", Vector3.new(len, 3, 0.1), cx, 5.4, r.zb - 0.1, Wood, rgb(190, 160, 120))
	for k = 0, 5 do
		local x = cx - len / 2 + 0.8 + k * (len - 1.6) / 5
		deco(rod(s, "Tool", (r.cf * CFrame.new(x, 6.4, r.zb - 0.25)).Position, (r.cf * CFrame.new(x + rng:NextNumber(-0.2, 0.2), 4.6, r.zb - 0.25)).Position, 0.14, Metal, pick({ STEEL, rgb(200, 60, 40), DARK }, rng)))
	end
	put(s, r, "Vice", Vector3.new(0.8, 0.6, 0.8), cx - len / 3, 3.55, r.zb - 1.4, Metal, rgb(60, 90, 120))
	deco(put(s, r, "Radio", Vector3.new(1.2, 0.8, 0.6), cx + len / 4, 3.65, r.zb - 0.9, Smooth, rgb(150, 60, 40)))
	for k = 0, 2 do
		deco(put(s, r, "Parts", Vector3.new(rng:NextNumber(0.4, 1), 0.3, rng:NextNumber(0.4, 0.8)), cx + rng:NextNumber(-len / 3, len / 3), 3.4, r.zb - 1 + rng:NextNumber(-0.4, 0.4), Metal, pick({ STEEL, RUST, DARK }, rng)))
	end
	-- A generator in the far front corner, fuel cans by it.
	local gx, gz = fx + sf * 1.5, r.zf + 1.2
	put(s, r, "Generator", Vector3.new(2.4, 1.6, 1.6), gx, 0.8, gz, Metal, rgb(220, 180, 40))
	cylinder(s, "GeneratorTank", 1.6, 1, r.cf * CFrame.new(gx, 2, gz), Metal, rgb(200, 60, 40))
	deco(rod(s, "Exhaust", (r.cf * CFrame.new(gx - sf * 0.8, 1.6, gz)).Position, (r.cf * CFrame.new(gx - sf * 0.8, 2.6, gz - 0.4)).Position, 0.2, Metal, DARK))
	for k = 0, 1 do
		put(s, r, "FuelCan", Vector3.new(0.7, 1, 0.5), fx + sf * (3.2 + k * 0.8), 0.5, r.zf + 0.8, Metal, rgb(200, 40, 30))
	end
	local crateZ = (r.zf + r.zb) / 2 - 0.6
	TunnelProps.crate(s, r.cf * CFrame.new(fx + sf * 4, 0, crateZ), Vector3.new(2.2, 2, 2.2), rng)
	for k = 0, 2 do
		put(s, r, "Battery", Vector3.new(1, 0.8, 0.7), fx + sf * 4, 2 + k * 0.8 + 0.4, crateZ, Smooth, DARK)
	end
	lootSpot(s, r.cf * CFrame.new(fx + sf * 1, 0, r.zb - 2.8))
end

function ROOMS.shop(s, r, rng)
	local fx, sf = farSide(r)
	-- Shelves of goods along the back.
	local len = r.x1 - r.x0 - 1
	local cx = (r.x0 + r.x1) / 2
	put(s, r, "ShelfBack", Vector3.new(len, 6, 0.15), cx, 3, r.zb - 0.1, Wood, rgb(150, 112, 76))
	for level = 0, 2 do
		local y = 0.8 + level * 1.8
		put(s, r, "Shelf", Vector3.new(len, 0.12, 1.4), cx, y, r.zb - 0.8, Wood, rgb(150, 112, 76))
		local x = cx - len / 2 + 0.5
		while x < cx + len / 2 - 0.6 do
			local w = rng:NextNumber(0.5, 1.1)
			if rng:NextNumber() < 0.8 then
				local h = rng:NextNumber(0.5, 1.3)
				if rng:NextNumber() < 0.4 then
					deco(upright(s, "Can", h, w * 0.8, r.cf, x + w / 2, y + 0.06 + h / 2, r.zb - 0.8, Metal, pick(BRIGHT, rng)))
				else
					deco(put(s, r, "Goods", Vector3.new(w - 0.1, h, 0.9), x + w / 2, y + 0.06 + h / 2, r.zb - 0.8, Smooth, jitter(pick({ rgb(200, 180, 140), rgb(230, 226, 214), rgb(200, 60, 50), rgb(60, 110, 170), rgb(240, 200, 70) }, rng), rng, 0.1)))
				end
			end
			x += w
		end
	end
	-- A counter across the far half of the room.
	local cz = r.zf + 3
	local cxa, cxb = fx, r.doorX - sf * 2.4
	local ca, cb = math.min(cxa, cxb), math.max(cxa, cxb)
	if cb - ca > 2 then
		put(s, r, "Counter", Vector3.new(cb - ca, 3.2, 1.4), (ca + cb) / 2, 1.6, cz, Wood, rgb(130, 96, 66))
		put(s, r, "CounterTop", Vector3.new(cb - ca + 0.2, 0.15, 1.6), (ca + cb) / 2, 3.28, cz, Wood, rgb(170, 130, 90))
		for k = 0, 2 do
			deco(upright(s, "SweetJar", 0.9, 0.7, r.cf, ca + 0.8 + k * 0.9, 3.8, cz, Glass, pick(BRIGHT, rng))).Transparency = 0.3
		end
		deco(put(s, r, "Abacus", Vector3.new(1.4, 0.15, 0.6), cb - 1, 3.43, cz, Wood, rgb(90, 60, 40)))
	end
	lootSpot(s, r.cf * CFrame.new(fx + sf * 1.5, 0, cz + 1.8))
end

function ROOMS.teahouse(s, r, rng)
	local fx, sf = farSide(r)
	local cx = (r.x0 + r.x1) / 2
	-- A counter along the back: a kettle on a burner, cups, tea tins.
	local len = (r.x1 - r.x0) * 0.55
	local kx = fx + sf * (len / 2 + 0.4)
	put(s, r, "TeaCounter", Vector3.new(len, 3.2, 1.6), kx, 1.6, r.zb - 1, Wood, rgb(130, 96, 66))
	put(s, r, "TeaCounterTop", Vector3.new(len + 0.2, 0.15, 1.8), kx, 3.28, r.zb - 1, Wood, rgb(170, 130, 90))
	put(s, r, "Burner", Vector3.new(1, 0.3, 1), kx - sf * (len / 2 - 1), 3.5, r.zb - 1, Metal, DARK)
	deco(upright(s, "Kettle", 0.7, 0.8, r.cf, kx - sf * (len / 2 - 1), 4, r.zb - 1, Metal, STEEL))
	for k = 0, 4 do
		deco(upright(s, "TeaTin", 0.6, 0.45, r.cf, kx - len / 2 + 1.6 + k * 0.6, 3.66, r.zb - 1.4, Metal, pick(BRIGHT, rng)))
	end
	for k = 0, 3 do
		deco(upright(s, "Cup", 0.3, 0.3, r.cf, kx + len / 2 - 0.6 - k * 0.45, 3.5, r.zb - 0.6, Smooth, WARM))
	end
	-- Little tables with stools, keeping the door clear.
	local spots = { { cx - 3.5, r.zf + 2.5 }, { cx + 3.5, r.zf + 2.5 }, { cx, r.zf + 2.5 }, { cx + sf * 5, (r.zf + r.zb) / 2 } }
	local n = 0
	for _, p in ipairs(spots) do
		if math.abs(p[1] - r.doorX) > 2.8 and p[1] > r.x0 + 1.6 and p[1] < r.x1 - 1.6 and n < 3 then
			n += 1
			upright(s, "TeaTable", 0.15, 2.2, r.cf, p[1], 2.4, p[2], Wood, rgb(150, 112, 76))
			upright(s, "TeaTablePost", 2.3, 0.3, r.cf, p[1], 1.15, p[2], Metal, DARK)
			for _, dx in ipairs({ -1.5, 1.5 }) do
				upright(s, "TeaStool", 1.5, 1, r.cf, p[1] + dx, 0.75, p[2], Wood, rgb(110, 80, 56))
			end
			deco(upright(s, "Cup", 0.3, 0.3, r.cf, p[1] + 0.3, 2.62, p[2], Smooth, WARM))
		end
	end
	lantern(s, r.cf * CFrame.new(cx - 2, r.h - 1.6, (r.zf + r.zb) / 2), rng, true)
	lantern(s, r.cf * CFrame.new(cx + 2.5, r.h - 1.6, (r.zf + r.zb) / 2 + 1), rng, rng:NextNumber() < 0.5)
	lootSpot(s, r.cf * CFrame.new(fx + sf * 1.2, 0, r.zb - 3))
end

function ROOMS.storeroom(s, r, rng)
	local fx, sf = farSide(r)
	local cx = (r.x0 + r.x1) / 2
	for k = 0, 2 do
		local x = fx + sf * (1.5 + k * 2.6)
		TunnelProps.crate(s, r.cf * CFrame.new(x, 0, r.zb - 1.4), Vector3.new(2.4, 2.2, 2.4), rng)
		if rng:NextNumber() < 0.6 then
			TunnelProps.crate(s, r.cf * CFrame.new(x + rng:NextNumber(-0.2, 0.2), 2.2, r.zb - 1.4) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Vector3.new(2, 1.8, 2), rng)
		end
	end
	for k = 0, 1 do
		TunnelProps.barrel(s, r.cf * CFrame.new(fx + sf * 1.2, 0, r.zf + 1.3 + k * 1.8), rng)
	end
	TunnelProps.drum(s, r.cf * CFrame.new(cx + sf * 2, 0, r.zb - 4), rng)
	Props.cardboardStack(s, (r.cf * CFrame.new(cx + sf * 3, 0, r.zb - 1.6)).Position, rng, 3)
	-- Shelving on the far wall.
	put(s, r, "Rack", Vector3.new(1.4, 6, 0.15), fx + sf * 0.8, 3, (r.zf + r.zb) / 2 - 1.5, Metal, STEEL)
	lootSpot(s, r.cf * CFrame.new(fx + sf * 3.2, 0, r.zf + 1.6))
	lootSpot(s, r.cf * CFrame.new(cx + sf * 0.5, 0, r.zb - 4.2))
end

-- A radio room: a desk of radio sets under the window, a map, a
-- telescope at the window, a chair.
function ROOMS.radio(s, r, rng)
	local fx, sf = farSide(r)
	local cx = (r.x0 + r.x1) / 2
	local dz = r.zf + 1.2
	put(s, r, "Desk", Vector3.new(6, 0.25, 2), fx + sf * 3.4, 3, dz, Wood, rgb(120, 90, 60))
	for _, x in ipairs({ fx + sf * 0.8, fx + sf * 6 }) do
		put(s, r, "DeskLeg", Vector3.new(0.3, 2.9, 1.8), x, 1.45, dz, Wood, rgb(90, 66, 46))
	end
	for k = 0, 2 do
		local x = fx + sf * (1.6 + k * 1.7)
		put(s, r, "RadioSet", Vector3.new(1.5, 1.1 + k * 0.2, 1.1), x, 3.7 + k * 0.1, dz + 0.3, Metal, pick({ rgb(70, 80, 70), rgb(60, 60, 64), rgb(120, 110, 90) }, rng))
		deco(put(s, r, "Dial", Vector3.new(0.9, 0.4, 0.05), x, 3.8, dz - 0.27, Neon, rgb(240, 200, 120)))
	end
	deco(rod(s, "Mic", (r.cf * CFrame.new(fx + sf * 5.2, 3.1, dz - 0.3)).Position, (r.cf * CFrame.new(fx + sf * 5.2, 3.9, dz - 0.5)).Position, 0.08, Metal, DARK))
	upright(s, "Chair", 0.2, 1.4, r.cf, fx + sf * 3.4, 1.8, dz + 2, Wood, rgb(110, 80, 56))
	upright(s, "ChairPost", 1.7, 0.2, r.cf, fx + sf * 3.4, 0.85, dz + 2, Metal, DARK)
	-- A map pinned on the near wall area, a telescope on a tripod.
	deco(put(s, r, "Map", Vector3.new(0.05, 3, 4), fx + sf * 0.12, 5.2, dz + 2.5, Smooth, rgb(220, 206, 170)))
	for _ = 1, 4 do
		deco(put(s, r, "MapMark", Vector3.new(0.05, rng:NextNumber(0.3, 0.9), rng:NextNumber(0.4, 1.2)), fx + sf * 0.16, 5.2 + rng:NextNumber(-1, 1), dz + 2.5 + rng:NextNumber(-1.5, 1.5), Smooth, pick({ rgb(200, 40, 40), rgb(60, 110, 170), rgb(90, 140, 90) }, rng)))
	end
	local tx = cx - sf * 2
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		rod(s, "TripodLeg", (r.cf * CFrame.new(tx + math.cos(a) * 0.8, 0, r.zf + 1.5 + math.sin(a) * 0.8)).Position, (r.cf * CFrame.new(tx, 3.6, r.zf + 1.5)).Position, 0.12, Metal, DARK)
	end
	cylinder(s, "Telescope", 2.6, 0.45, CFrame.lookAt((r.cf * CFrame.new(tx, 4, r.zf + 1.2)).Position, (r.cf * CFrame.new(tx, 4.6, r.zf - 1)).Position) * CFrame.Angles(0, math.pi / 2, 0), Metal, rgb(196, 160, 80))
	lootSpot(s, r.cf * CFrame.new(cx + sf * 1.5, 0, r.zb - 1.2))
end

-- ===== A shack =====

-- A shack standing on a deck against the wall. `cf` is on the deck at the
-- wall, the shack's back-middle; x along the wall, -z out from it.
-- opts: kind (a ROOMS key), doorX, lit, backDoor, sign, solar, antenna,
-- barrel, garden, name.
local function shack(parent, cf, w, d, h, rng, opts)
	local s = model(parent, opts.name or "Shack")
	local doorX = opts.doorX or (if rng:NextNumber() < 0.5 then -1 else 1) * rng:NextNumber(0, w / 2 - 3)
	local doorW, doorH = 3.4, 7.6
	-- Floorboards over the deck.
	part(s, "Floorboards", Vector3.new(w - 0.4, 0.1, d - 0.4), cf * CFrame.new(0, 0.05, -d / 2), Plywood, pick(PLY, rng))
	-- Walls: front with the door and windows, sides with a window each,
	-- the back against the building (with a way through if backDoor).
	local front = { { c = doorX, w = doorW, y0 = 0, y1 = doorH } }
	local winSpots = {}
	for _, x in ipairs({ -w / 2 + 2.6, w / 2 - 2.6, 0 }) do
		if math.abs(x - doorX) > doorW / 2 + 1.9 and #winSpots < (if w > 15 then 2 else 1) then
			local o = { c = x, w = 3, y0 = 3, y1 = 6 }
			table.insert(front, o)
			table.insert(winSpots, o)
		end
	end
	wallRun(s, cf, true, -d + 0.1, -w / 2, w / 2, h, front, rng, opts.glassy)
	local sideWins = {}
	for _, side in ipairs({ -1, 1 }) do
		local o = { c = -d / 2, w = 2.6, y0 = 3.2, y1 = 5.8 }
		local list = if rng:NextNumber() < 0.6 then { o } else {}
		wallRun(s, cf, false, side * (w / 2 - 0.1), -d + 0.2, 0, h, list, rng, opts.glassy)
		if #list > 0 then
			table.insert(sideWins, { side = side, o = o })
		end
	end
	wallRun(s, cf, true, -0.1, -w / 2 + 0.2, w / 2 - 0.2, h, if opts.backDoor then { { c = 0, w = 4, y0 = 0, y1 = 8 } } else {}, rng, opts.glassy)
	local lit = opts.lit
	if not opts.glassy then
		for i, o in ipairs(winSpots) do
			window(s, cf, true, -d + 0.1, o, rng, lit and i == 1)
		end
		for _, sw in ipairs(sideWins) do
			window(s, cf, false, sw.side * (w / 2 - 0.1), sw.o, rng, false, -sw.side)
		end
	end
	-- The door, from somewhere else, swung open inward.
	local doorColor = pick({ rgb(150, 118, 80), rgb(70, 110, 90), rgb(180, 60, 50), rgb(210, 206, 196), rgb(60, 80, 120) }, rng)
	local hinge = cf * CFrame.new(doorX - doorW / 2 + 0.1, doorH / 2, -d + 0.35)
	part(s, "Door", Vector3.new(doorW - 0.2, doorH - 0.1, 0.15), hinge * CFrame.Angles(0, math.rad(-rng:NextNumber(70, 100)), 0) * CFrame.new(doorW / 2 - 0.1, 0, 0), Wood, doorColor)
	part(s, "DoorHead", Vector3.new(doorW + 0.6, 0.3, 0.4), cf * CFrame.new(doorX, doorH + 0.15, -d + 0.1), Wood, rgb(90, 70, 50))
	-- The roof: a sheet sloping down to the front, overhanging it, rafters
	-- under it.
	local slope = math.rad(7)
	local roofLen = d + 1.6
	local roof = cf * CFrame.new(0, h + 0.3, -roofLen / 2 + 0.3) * CFrame.Angles(-slope, 0, 0)
	part(s, "Roof", Vector3.new(w + 0.8, 0.2, roofLen), roof, if opts.glassy then Glass else Corroded, if opts.glassy then rgb(200, 220, 214) else pick(SHEET, rng)).Transparency = if opts.glassy then 0.5 else 0
	for k = -2, 2 do
		deco(part(s, "RoofRib", Vector3.new(0.12, 0.1, roofLen), roof * CFrame.new(k * w / 5, 0.14, 0), Corroded, rgb(90, 84, 76)))
	end
	for _, z in ipairs({ -d / 3, -2 * d / 3 }) do
		part(s, "Rafter", Vector3.new(w - 0.4, 0.4, 0.4), cf * CFrame.new(0, h - 0.2, z), Wood, TIMBER)
	end
	-- Inside.
	local room = { cf = cf, x0 = -w / 2 + 0.4, x1 = w / 2 - 0.4, zf = -d + 0.4, zb = -0.4, h = h, doorX = doorX }
	if opts.kind and ROOMS[opts.kind] then
		ROOMS[opts.kind](s, room, rng)
	elseif opts.kind == "greenhouse" then
		for _, z in ipairs({ -1.6, -d + 2.4 }) do
			garden(s, cf * CFrame.new(0, 0, z), w - 3, 1.4, rng, false)
		end
		lootSpot(s, cf * CFrame.new(w / 2 - 1.8, 0, -d / 2))
	end
	hangingBulb(s, room, rng)
	-- Outside the door: a lantern, a sign over it, a plant or a garden, a
	-- barrel under the roof's edge.
	lantern(s, cf * CFrame.new(doorX + doorW / 2 + 0.7, doorH - 0.6, -d - 0.5), rng, lit or opts.kind == "teahouse")
	if opts.sign then
		label(s, cf * CFrame.new(doorX, doorH + 1.2, -d - 0.05), Vector3.new(math.min(w - 1, 6), 1.3, 0.12), Enum.NormalId.Front, opts.sign, pick({ rgb(240, 226, 196), rgb(40, 60, 90), rgb(150, 40, 40) }, rng), pick({ rgb(40, 30, 24), rgb(250, 240, 220) }, rng), Wood, Enum.Font.IndieFlower)
	end
	if opts.kind == "teahouse" then
		for k = 0, 2 do
			deco(part(s, "Noren", Vector3.new(doorW / 3 - 0.08, 1.6, 0.05), cf * CFrame.new(doorX - doorW / 3 + k * doorW / 3, doorH - 0.8, -d - 0.12), Fabric, rgb(40, 60, 90)))
		end
	end
	local outX = (if doorX > 0 then -1 else 1) * (w / 2 - 1.2)
	if opts.garden ~= false and rng:NextNumber() < 0.7 then
		garden(s, cf * CFrame.new(outX, 0, -d - 0.9), 2.4, 1, rng, false)
	end
	if opts.barrel ~= false and rng:NextNumber() < 0.7 then
		local bx = outX + (if outX > 0 then -2 else 2)
		upright(s, "RainBarrel", 2, 1.3, cf, bx, 1, -d - 0.9, Corroded, pick({ rgb(60, 110, 170), rgb(170, 60, 40) }, rng))
		deco(rod(s, "Downpipe", (cf * CFrame.new(bx, 2, -d - 0.9)).Position, (roof * CFrame.new(bx, 0, roofLen / 2 - 0.4)).Position, 0.2, Metal, STEEL))
	end
	-- On the roof.
	if opts.solar or rng:NextNumber() < 0.35 then
		local p = cf * CFrame.new(-w / 5, h + 1.3, -d * 0.45) * CFrame.Angles(math.rad(-25), 0, 0)
		part(s, "SolarPanel", Vector3.new(3, 0.1, 1.8), p, Glass, rgb(30, 44, 80)).Reflectance = 0.25
	end
	if opts.antenna or rng:NextNumber() < 0.3 then
		deco(rod(s, "Antenna", (cf * CFrame.new(w / 2 - 0.8, h + 0.4, -0.8)).Position, (cf * CFrame.new(w / 2 - 0.8, h + 6, -0.8)).Position, 0.1, Metal, STEEL))
		for k = 0, 2 do
			deco(rod(s, "AntennaBar", (cf * CFrame.new(w / 2 - 1.6 + k * 0.1, h + 3.4 + k * 0.8, -0.8)).Position, (cf * CFrame.new(w / 2 + 0 - k * 0.1, h + 3.4 + k * 0.8, -0.8)).Position, 0.06, Metal, STEEL))
		end
	end
	if rng:NextNumber() < 0.4 then
		put(s, { cf = cf }, "AirCon", Vector3.new(0.9, 1.4, 1.8), (if outX > 0 then 1 else -1) * (w / 2 + 0.45), h - 2, -d / 2, Metal, rgb(220, 220, 214))
	end
	return {
		model = s,
		roofFront = function(x)
			return (roof * CFrame.new(x, 0.2, -roofLen / 2 + 0.2)).Position
		end,
		roofTop = (cf * CFrame.new(0, h + 1, -1)).Position,
		cf = cf,
	}
end

-- ===== The tower =====

-- Four storeys of shack stacked up, stairs inside up the back, a roof
-- garden on top. `cf` as for a shack; the door is on the -x side at the
-- front (towards the rest of the boardwalk).
local function tower(parent, cf, rng)
	local t = model(parent, "ShackTower")
	local W, D, H, FLOORS = 18, 14, 9, 4
	local half = W / 2
	local stripA, stripB = { -1, -4 }, { -4, -7 } -- z bands of the two stair lanes (back)
	local kinds = { "storeroom", "home", "workshop", "radio" }
	local function hole(k) -- the opening in floor k (1-based) for the flight coming up from k-1
		local strip = if (k - 1) % 2 == 1 then stripA else stripB
		local up = (k - 1) % 2 == 1 -- flight k-1 runs +x (in strip A) or -x (in strip B)
		return { strip = strip, x0 = if up then -2 else -6, x1 = if up then 6 else 2 }
	end
	for k = 1, FLOORS + 1 do
		local y = (k - 1) * H
		local fcf = cf * CFrame.new(0, y, 0)
		-- The floor (the deck under the ground floor), with the stair hole.
		if k > 1 then
			local hl = hole(k)
			local sz0, sz1 = math.min(hl.strip[1], hl.strip[2]), math.max(hl.strip[1], hl.strip[2])
			local function slab(xa, xb, za, zb)
				if xb - xa > 0.05 and zb - za > 0.05 then
					part(t, "TowerFloor", Vector3.new(xb - xa, 0.4, zb - za), fcf * CFrame.new((xa + xb) / 2, -0.2, (za + zb) / 2), Plywood, pick(PLY, rng))
				end
			end
			slab(-half, half, -D, sz0)
			slab(-half, half, sz1, 0)
			slab(-half, hl.x0, sz0, sz1)
			slab(hl.x1, half, sz0, sz1)
			-- A rail round the hole's open sides.
			local zEdge = if hl.strip == stripA then stripA[2] else stripB[2]
			rail(t, (fcf * CFrame.new(hl.x0, 0, zEdge)).Position, (fcf * CFrame.new(hl.x1, 0, zEdge)).Position)
			if hl.strip == stripB then
				rail(t, (fcf * CFrame.new(hl.x0, 0, stripB[1])).Position, (fcf * CFrame.new(hl.x1, 0, stripB[1])).Position)
			end
			local xEnd = if hl.x0 == -2 then -2 else 2
			rail(t, (fcf * CFrame.new(xEnd, 0, sz0)).Position, (fcf * CFrame.new(xEnd, 0, sz1)).Position)
		end
		if k <= FLOORS then
			-- Walls: windows front and back of the far side, the door on the
			-- ground floor's near side.
			local front = { { c = -3, w = 3, y0 = 2.8, y1 = 5.8 }, { c = 4, w = 3, y0 = 2.8, y1 = 5.8 } }
			local WH = H - 0.4
			wallRun(t, fcf, true, -D + 0.1, -half, half, WH, front, rng)
			for i, o in ipairs(front) do
				window(t, fcf, true, -D + 0.1, o, rng, (k == 2 and i == 1) or (k == 4 and i == 2))
			end
			local nearOpen = if k == 1 then { { c = -D + 2.6, w = 3.4, y0 = 0, y1 = 7.6 } } else { { c = -D + 3, w = 2.6, y0 = 3, y1 = 5.8 } }
			wallRun(t, fcf, false, -half + 0.1, -D + 0.2, 0, WH, nearOpen, rng)
			if k > 1 then
				window(t, fcf, false, -half + 0.1, nearOpen[1], rng, false, 1)
			end
			local farOpen = { { c = -D + 3, w = 2.6, y0 = 3, y1 = 5.8 } }
			wallRun(t, fcf, false, half - 0.1, -D + 0.2, 0, WH, farOpen, rng)
			window(t, fcf, false, half - 0.1, farOpen[1], rng, k == 3, -1)
			wallRun(t, fcf, true, -0.1, -half + 0.2, half - 0.2, WH, {}, rng)
			-- A band of sheet at each floor line outside.
			part(t, "FloorBand", Vector3.new(W + 0.4, 0.5, 0.4), fcf * CFrame.new(0, H - 0.25, -D - 0.1), Corroded, pick(SHEET, rng))
			-- The flight up to the next floor, in its lane.
			local up = k % 2 == 1
			local strip = if up then stripA else stripB
			local zc = (strip[1] + strip[2]) / 2
			local n = 12
			for i = 1, n do
				local xa = if up then -6 + (i - 1) else 6 - i
				local top = i * H / n
				part(t, "Step", Vector3.new(1.02, 0.3, 2.9), fcf * CFrame.new(xa + 0.5, top - 0.15, zc), Wood, rgb(150, 112, 76))
			end
			for _, z in ipairs({ strip[1] - 0.1, strip[2] + 0.1 }) do
				rod(t, "Stringer", (fcf * CFrame.new(if up then -6 else 6, 0, z)).Position, (fcf * CFrame.new(if up then 6 else -6, H, z)).Position, 0.3, Wood, TIMBER)
			end
			-- The room in front of the stairs.
			local room = { cf = fcf, x0 = -half + 0.5, x1 = half - 0.5, zf = -D + 0.5, zb = -7.4, h = H, doorX = -half + 1 }
			ROOMS[kinds[k]](t, room, rng)
			hangingBulb(t, room, rng)
		end
	end
	-- The roof: a garden with a water tank, panels and an aerial, railed.
	local rcf = cf * CFrame.new(0, FLOORS * H, 0)
	for _, e in ipairs({ { -half + 0.2, -D + 0.2, half - 0.2, -D + 0.2 }, { -half + 0.2, -D + 0.2, -half + 0.2, -0.3 }, { half - 0.2, -D + 0.2, half - 0.2, -0.3 } }) do
		rail(t, (rcf * CFrame.new(e[1], 0, e[2])).Position, (rcf * CFrame.new(e[3], 0, e[4])).Position)
	end
	garden(t, rcf * CFrame.new(-4, 0, -D + 1.6), 5, 1.4, rng, false)
	garden(t, rcf * CFrame.new(4, 0, -D + 1.6) * CFrame.Angles(0, 0.05, 0), 3, 1.4, rng, true)
	upright(t, "WaterTank", 3, 3, rcf, half - 2.4, 2.5, -2, Smooth, rgb(60, 110, 170))
	for _, dx in ipairs({ -1, 1 }) do
		for _, dz in ipairs({ -1, 1 }) do
			rod(t, "TankLeg", (rcf * CFrame.new(half - 2.4 + dx, 0, -2 + dz)).Position, (rcf * CFrame.new(half - 2.4 + dx, 1, -2 + dz)).Position, 0.2, Metal, STEEL)
		end
	end
	for k = 0, 1 do
		local p = rcf * CFrame.new(-half + 2.4 + k * 3.4, 1.4, -1.8) * CFrame.Angles(math.rad(-25), 0, 0)
		part(t, "SolarPanel", Vector3.new(3, 0.1, 1.8), p, Glass, rgb(30, 44, 80)).Reflectance = 0.25
	end
	local mast = (rcf * CFrame.new(-half + 1, 0, -D + 1)).Position
	rod(t, "Mast", mast, mast + Vector3.new(0, 9, 0), 0.25, Metal, STEEL)
	upright(t, "RoofChair", 0.2, 1.4, rcf, 1, 1.8, -D + 4, Smooth, pick(BRIGHT, rng))
	upright(t, "RoofChairPost", 1.7, 0.2, rcf, 1, 0.85, -D + 4, Metal, DARK)
	cat(t, rcf * CFrame.new(-1.5, 0, -D + 4.5) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng)
	return {
		mastTop = mast + Vector3.new(0, 8.6, 0),
		sideHook = (cf * CFrame.new(-half - 0.1, H + 6.5, -D + 1)).Position,
		roofEdge = (cf * CFrame.new(half - 1, FLOORS * H + 3.2, -D + 0.4)).Position,
	}
end

-- ===== The scaffold stair up the south-west corner =====

-- Five flights between y0 and y0 + 50 in two lanes (x0..x0+4 north-going,
-- x0+4..x0+8 south-going) between zS and zN, landings off each end.
local function cornerStair(parent, x0, zS, zN, y0, rng)
	local c = model(parent, "CornerStair")
	local xA0, xA1, xB0, xB1 = x0, x0 + 4, x0 + 4, x0 + 8
	local rise, n = 10, 14
	local run = (zN - zS) / n
	for k = 1, 5 do
		local yb = y0 + (k - 1) * rise
		local north = k % 2 == 1
		local xa, xb = if north then xA0 else xB0, if north then xA1 else xB1
		for i = 1, n do
			local top = yb + i * rise / n
			local za = if north then zS + (i - 1) * run else zN - i * run
			local zb = if north then math.min(zN, zS + i * run + 0.02) else zN - (i - 1) * run
			box(c, "Step", xa, xb, top - 0.3, top, za, zb, Wood, jitter(rgb(150, 112, 76), rng, 0.08))
		end
		-- Rails either side of the flight, following it up.
		local a = Vector3.new(0, yb, if north then zS else zN)
		local b = Vector3.new(0, yb + rise, if north then zN else zS)
		for _, x in ipairs({ xa + 0.15, xb - 0.15 }) do
			for _, h in ipairs({ 1.6, 3.2 }) do
				rod(c, "StairRail", Vector3.new(x, a.Y + h, a.Z), Vector3.new(x, b.Y + h, b.Z), 0.18, Wood, TIMBER)
			end
			rod(c, "StairPost", Vector3.new(x, (a.Y + b.Y) / 2, (a.Z + b.Z) / 2), Vector3.new(x, (a.Y + b.Y) / 2 + 3.3, (a.Z + b.Z) / 2), 0.2, Wood, TIMBER)
		end
		-- The landing at the top of the flight.
		local ly = yb + rise
		if north then
			box(c, "Landing", xA0, xB1, ly - 0.4, ly, zN, zN + 5, Diamond, rgb(96, 98, 100))
			if k < 5 then
				rail(c, Vector3.new(xA0, ly, zN + 4.85), Vector3.new(xB1, ly, zN + 4.85))
			else
				rail(c, Vector3.new(xA0, ly, zN + 4.85), Vector3.new(xA1, ly, zN + 4.85))
			end
			rail(c, Vector3.new(xA0 + 0.15, ly, zN), Vector3.new(xA0 + 0.15, ly, zN + 5))
			rail(c, Vector3.new(xB1 - 0.15, ly, zN), Vector3.new(xB1 - 0.15, ly, zN + 5))
		else
			box(c, "Landing", xA0, xB1, ly - 0.4, ly, zS - 4, zS, Diamond, rgb(96, 98, 100))
			rail(c, Vector3.new(xA0, ly, zS - 3.85), Vector3.new(xB1, ly, zS - 3.85))
			rail(c, Vector3.new(xA0 + 0.15, ly, zS - 4), Vector3.new(xA0 + 0.15, ly, zS))
			rail(c, Vector3.new(xB1 - 0.15, ly, zS - 4), Vector3.new(xB1 - 0.15, ly, zS))
		end
	end
	-- The scaffold it hangs in.
	local top = y0 + 5 * rise + 4
	for _, x in ipairs({ xA0 - 0.3, xB1 + 0.3 }) do
		for _, z in ipairs({ zS - 4.3, zN + 5.3 }) do
			rod(c, "ScaffoldPost", Vector3.new(x, y0 - 12, z), Vector3.new(x, top, z), 0.4, Metal, STEEL)
		end
		for y = y0 - 8, top, 10 do
			deco(rod(c, "ScaffoldBrace", Vector3.new(x, y, zS - 4.3), Vector3.new(x, y + 10, zN + 5.3), 0.25, Metal, STEEL))
		end
	end
	return c
end

-- ===== Building on a face =====

-- A frame on face `face` of the store (one of info.faces), `along` the
-- face and at height y, a stud out from it: x along the face, -z out.
local function faceFrame(info, face, along, y)
	local f = info.faces[face]
	if face == "south" then
		return CFrame.new(along, y, f - 1)
	elseif face == "north" then
		return CFrame.new(along, y, f + 1) * CFrame.Angles(0, math.pi, 0)
	elseif face == "west" then
		return CFrame.new(f - 1, y, along) * CFrame.Angles(0, math.pi / 2, 0)
	end
	return CFrame.new(f + 1, y, along) * CFrame.Angles(0, -math.pi / 2, 0)
end

-- A deck W wide and D deep out from the face at frame F, railed round
-- its open sides, braced back to the wall.
local function faceDeck(parent, F, W, D, rng)
	local u = -W / 2
	while u < W / 2 - 0.05 do
		local n = math.min(W / 2, u + rng:NextNumber(4, 8))
		if W / 2 - n < 2 then
			n = W / 2
		end
		local roll = rng:NextNumber()
		local material = if roll < 0.55 then Plywood elseif roll < 0.8 then Diamond else Corroded
		local color = if material == Plywood then pick(PLY, rng) elseif material == Diamond then rgb(96, 98, 100) else pick(SHEET, rng)
		part(parent, "Deck", Vector3.new(n - u, 0.4, D), F * CFrame.new((u + n) / 2, -0.2, -D / 2), material, jitter(color, rng, 0.05))
		u = n
	end
	for _, x in ipairs({ -W / 2 + 1, W / 2 - 1 }) do
		part(parent, "Joist", Vector3.new(0.5, 0.7, D), F * CFrame.new(x, -0.75, -D / 2), Corroded, RUST)
	end
	local function at(x, y, z)
		return (F * CFrame.new(x, y, z)).Position
	end
	rail(parent, at(-W / 2, 0, -D + 0.2), at(W / 2, 0, -D + 0.2))
	rail(parent, at(-W / 2 + 0.2, 0, -D), at(-W / 2 + 0.2, 0, -0.2))
	rail(parent, at(W / 2 - 0.2, 0, -D), at(W / 2 - 0.2, 0, -0.2))
	for _, x in ipairs({ -W / 2 + 1, 0, W / 2 - 1 }) do
		braces(parent, at(x, -0.4, -D + 0.3), at(x, -0.4, 0.4))
	end
end

-- Power run down the facade from high up to a shack's roof: two cables
-- pinned to the wall with clips every so often.
local function facadeRun(parent, F, x, yTop, yBottom)
	local r = model(parent, "FacadeCables")
	for _, dx in ipairs({ 0, 0.35 }) do
		deco(rod(r, "Cable", (F * CFrame.new(x + dx, yTop, 0.3)).Position, (F * CFrame.new(x + dx, yBottom, 0.3)).Position, 0.1, Smooth, CABLE))
	end
	for y = yBottom + 4, yTop - 2, 14 do
		deco(part(r, "Clip", Vector3.new(0.9, 0.25, 0.3), F * CFrame.new(x + 0.18, y, 0.3), Metal, STEEL))
	end
end

-- A hook on the wall for a washing line.
local function wallHook(parent, F, x, y)
	local p = (F * CFrame.new(x, y, 0.35)).Position
	deco(part(parent, "Hook", Vector3.new(0.3, 0.3, 0.5), CFrame.new(p), Metal, STEEL))
	return p
end

-- A lone shack on a face, its back knocked through into the store: a
-- deck with a porch, washing, a garden, its own power run up the wall.
local function loneShack(parent, info, way, rng, i)
	local F = faceFrame(info, way.face, way.at, way.y)
	local m = model(parent, "LoneShack" .. i)
	local w = rng:NextInteger(14, 17)
	local d = 10
	local W, D = w + 7, d + 5
	faceDeck(m, F, W, D, rng)
	-- The threshold into the store.
	part(m, "Threshold", Vector3.new(4, 0.3, 2.4), F * CFrame.new(0, -0.1, 0.9), Wood, rgb(130, 104, 74))
	local sh = shack(m, F * CFrame.new(-1.5, 0, 0), w, d, 10, rng, { kind = way.kind, backDoor = true, doorX = rng:NextNumber(-w / 2 + 3.5, w / 2 - 3.5), lit = rng:NextNumber() < 0.7, name = "Shack" })
	-- The porch round the side: a pole for the washing, a hook on the wall.
	local pole = linePole(m, (F * CFrame.new(W / 2 - 1, 0, -D + 1)).Position)
	local hook = wallHook(m, F, W / 2 - 1, 8.6)
	washingLine(m, pole, hook, rng)
	washingLine(m, pole, sh.roofFront(w / 2 - 2.5), rng)
	washingLine(m, (F * CFrame.new(-W / 2 + 0.6, 8, -D + 0.6)).Position, pole, rng)
	rod(m, "LinePole", (F * CFrame.new(-W / 2 + 0.6, 0, -D + 0.6)).Position, (F * CFrame.new(-W / 2 + 0.6, 8.4, -D + 0.6)).Position, 0.3, Wood, TIMBER)
	garden(m, F * CFrame.new(W / 2 - 1.3, 0, -D / 2 + 1) * CFrame.Angles(0, math.pi / 2, 0), 3, 1.2, rng, rng:NextNumber() < 0.4)
	if rng:NextNumber() < 0.6 then
		cat(m, F * CFrame.new(rng:NextNumber(-w / 3, w / 3), 10.8, -d / 2) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng)
	end
	-- Its power, run down the wall from the roof park.
	facadeRun(m, F, -1.5 - w / 2 - 0.8, info.roof - 2 - way.y, 10.6)
end

-- ===== Assembly =====

-- info: faces (the store's four face coordinates), X0 (the west face),
-- wallZ (the south face), bridgeX, bridgeY (the 16F way in), linkX, linkY
-- (the 9F way in), westY, westDoorZ (19F's west way in), wayIns (the lone
-- shacks' ways in: face, y, at, kind), bridgeTower (the top of the
-- bridge's rooftop scaffold), bridgeMasts, cragAnchor (a point in the
-- crag's face by the pipe bridge), cornerSign (a point on the big
-- vertical sign), roof (the store's roof level).
function StoreShacks.build(parent, info, rng)
	lightsLeft = 14
	local m = model(parent, "FacadeVillage")
	local wz = info.wallZ - 1 -- decks stop a stud short of the facade
	local faceZ = info.wallZ - 0.6
	local faceX = info.X0 - 0.6

	-- ----- The south boardwalk at 16F: the tower, the tea house and the
	-- general store round the bridge, a laundry yard at the west end -----
	local y = info.bridgeY
	local sx0, sx1, sz0 = info.X0 - 17, info.bridgeX + 25, wz - 16
	local gap0, gap1 = info.bridgeX - 3, info.bridgeX + 3 -- the bridge comes through here
	local south = model(m, "SouthBoardwalk")
	deckArea(south, sx0, gap0, sz0, wz, y, rng)
	deckArea(south, gap1, sx1, sz0, wz, y, rng)
	rail(south, Vector3.new(sx0, y, sz0 + 0.2), Vector3.new(gap0, y, sz0 + 0.2))
	rail(south, Vector3.new(gap1, y, sz0 + 0.2), Vector3.new(sx1, y, sz0 + 0.2))
	rail(south, Vector3.new(sx1 - 0.2, y, sz0), Vector3.new(sx1 - 0.2, y, wz))
	rail(south, Vector3.new(sx0 + 0.2, y, sz0), Vector3.new(sx0 + 0.2, y, wz - 6.3)) -- up to the corner stair
	rail(south, Vector3.new(sx0, y, wz - 0.2), Vector3.new(info.X0 - 0.6, y, wz - 0.2)) -- past the corner
	for x = info.X0 + 4, sx1 - 2, 11 do
		if x < gap0 - 1 or x > gap1 + 1 then
			braces(south, Vector3.new(x, y - 0.4, sz0 + 0.3), Vector3.new(x, y - 0.4, faceZ))
		end
	end
	local towerInfo = tower(south, CFrame.new(info.X0 + 29, y, wz), rng)
	local tea = shack(south, CFrame.new(info.bridgeX - 18.5, y, wz), 22, 10, 10, rng, { kind = "teahouse", name = "TeaHouse", sign = "茶屋 月見", lit = true, doorX = rng:NextNumber(-6, 6) })
	local store = shack(south, CFrame.new(info.bridgeX + 14, y, wz), 16, 10, 10, rng, { kind = "shop", name = "GeneralStore", sign = "よろず屋", lit = true, doorX = rng:NextNumber(-4, 4) })
	task.wait()
	for k = 0, 2 do
		TunnelProps.crate(south, CFrame.new(info.bridgeX + 8 + k * 2.6, y, wz - 12.2), Vector3.new(2.2, 1.2, 1.6), rng, "open")
	end
	local benchX = info.bridgeX - 26
	box(south, "Bench", benchX - 2.5, benchX + 2.5, y + 1.3, y + 1.6, wz - 12.8, wz - 11.8, Wood, rgb(150, 112, 76))
	for _, dx in ipairs({ -2.1, 2.1 }) do
		box(south, "BenchLeg", benchX + dx - 0.2, benchX + dx + 0.2, y, y + 1.3, wz - 12.7, wz - 11.9, Wood, TIMBER)
	end
	-- The laundry yard between the corner and the tower: poles, lines to
	-- the wall and between the poles, a bathtub garden, a stool.
	local yard = {}
	for _, p in ipairs({ { info.X0 + 1, sz0 + 0.6 }, { info.X0 + 10, sz0 + 0.6 }, { info.X0 + 18, sz0 + 0.6 }, { info.X0 + 6, wz - 7 } }) do
		table.insert(yard, linePole(south, Vector3.new(p[1], y, p[2])))
	end
	for _, x in ipairs({ info.X0 + 3, info.X0 + 12, info.X0 + 18 }) do
		table.insert(yard, Vector3.new(x, y + 8.6, faceZ - 0.35))
		deco(part(south, "Hook", Vector3.new(0.3, 0.3, 0.5), Vector3.new(x, y + 8.6, faceZ - 0.25), Metal, STEEL))
	end
	for _, pair in ipairs({ { 1, 2 }, { 2, 3 }, { 1, 4 }, { 4, 5 }, { 2, 6 }, { 3, 7 }, { 4, 6 } }) do
		washingLine(south, yard[pair[1]], yard[pair[2]], rng)
	end
	washingLine(south, yard[3], towerInfo.sideHook, rng)
	garden(south, CFrame.new(info.X0 + 14, y, wz - 3), 1.6, 2.6, rng, true)
	upright(south, "Stool", 1.4, 1.1, CFrame.new(info.X0 + 9, y, wz - 4), 0, 0.7, 0, Smooth, pick(BRIGHT, rng))

	-- ----- The corner stair, up to the west boardwalk at 19F: a drying
	-- area, the greenhouse, a terrace, the way in -----
	local wy = info.westY
	local stairX0 = sx0
	local zS, zN = wz - 6.3, wz + 7
	local stair = cornerStair(m, stairX0, zS, zN, y, rng)
	-- Lines strung from the scaffold across to the store's wall.
	for _, h in ipairs({ 14, 34 }) do
		washingLine(stair, Vector3.new(stairX0 + 8.3, y + h, zN + 5.3), Vector3.new(faceX - 0.35, y + h + 1, zN + 9), rng)
	end
	local west = model(m, "WestBoardwalk")
	local wx0, wx1 = stairX0 + 4, info.X0 - 1
	local wzA, wzB = zN + 5, info.wallZ + 78
	deckArea(west, wx0, wx1, wzA, wzB, wy, rng)
	rail(west, Vector3.new(wx0 + 0.2, wy, wzA), Vector3.new(wx0 + 0.2, wy, wzB))
	rail(west, Vector3.new(wx0, wy, wzB - 0.2), Vector3.new(wx1, wy, wzB - 0.2))
	rail(west, Vector3.new(stairX0 + 8, wy, wzA + 0.2), Vector3.new(wx1, wy, wzA + 0.2))
	for z = wzA + 4, wzB - 2, 11 do
		braces(west, Vector3.new(wx0 + 0.3, wy - 0.4, z), Vector3.new(faceX, wy - 0.4, z))
	end
	local function westShack(zc, w, kind, opts)
		opts = opts or {}
		opts.kind = kind
		return shack(west, CFrame.new(wx1, wy, zc) * CFrame.Angles(0, math.pi / 2, 0), w, 8, 9.5, rng, opts)
	end
	-- The drying area at the top of the stair.
	local dry = {}
	for _, z in ipairs({ wzA + 3, wzA + 11, wzA + 18 }) do
		table.insert(dry, linePole(west, Vector3.new(wx0 + 0.6, wy, z)))
		table.insert(dry, Vector3.new(faceX - 0.35, wy + 8.6, z + 1))
		deco(part(west, "Hook", Vector3.new(0.5, 0.3, 0.3), Vector3.new(faceX - 0.25, wy + 8.6, z + 1), Metal, STEEL))
	end
	for _, pair in ipairs({ { 1, 2 }, { 3, 4 }, { 5, 6 }, { 1, 3 }, { 3, 5 } }) do
		washingLine(west, dry[pair[1]], dry[pair[2]], rng)
	end
	local W2 = westShack(wzA + 27, 16, "greenhouse", { name = "Greenhouse", glassy = true, garden = false, barrel = false })
	local door = info.westDoorZ
	local W3 = westShack(door, 14, nil, { name = "WayIn", backDoor = true, doorX = 3, sign = "月光 19F" })
	local w3cf = CFrame.new(wx1, wy, door) * CFrame.Angles(0, math.pi / 2, 0)
	for _, x in ipairs({ -5, 5.2 }) do
		TunnelProps.crate(west, w3cf * CFrame.new(x, 0, -2), Vector3.new(2.2, 2, 2.2), rng)
	end
	TunnelProps.barrel(west, w3cf * CFrame.new(-5, 0, -5.2), rng)
	lootSpot(west, w3cf * CFrame.new(-4.8, 0, -4.6 + 1.6))
	box(west, "Threshold", wx1 - 0.2, info.X0 + 0.8, wy - 0.3, wy + 0.05, door - 2, door + 2, Wood, rgb(130, 104, 74))
	local tz = (wzA + 35 + door - 7) / 2
	garden(west, CFrame.new(wx1 - 2, wy, tz - 3.5) * CFrame.Angles(0, math.pi / 2, 0), 3, 1.4, rng, false)
	garden(west, CFrame.new(wx1 - 2, wy, tz + 3.2) * CFrame.Angles(0, math.pi / 2, 0), 2.6, 1.4, rng, true)
	upright(west, "WaterTank", 3.4, 2.8, CFrame.new(wx1 - 2, wy, tz - 0.4), 0, 1.7, 0, Smooth, rgb(60, 110, 170))
	upright(west, "TerraceTable", 0.15, 2.4, CFrame.new(wx0 + 3, wy, tz), 0, 2.4, 0, Wood, rgb(150, 112, 76))
	upright(west, "TerraceTablePost", 2.3, 0.3, CFrame.new(wx0 + 3, wy, tz), 0, 1.15, 0, Metal, DARK)
	for _, dz in ipairs({ -1.8, 1.8 }) do
		upright(west, "TerraceStool", 1.5, 1.1, CFrame.new(wx0 + 3, wy, tz + dz), 0, 0.75, 0, Smooth, pick(BRIGHT, rng))
	end
	cat(west, CFrame.new(wx0 + 3, wy + 2.5, tz + 0.3) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng)
	local terracePole = linePole(west, Vector3.new(wx0 + 0.6, wy, tz))
	washingLine(west, terracePole, W2.roofFront(-5), rng)
	washingLine(west, terracePole, W3.roofFront(4), rng)

	-- ----- The 9F boardwalk by the pipe bridge: one workshop, a garden -----
	local ly = info.linkY
	local nine = model(m, "NineBoardwalk")
	local nx0, nx1 = info.linkX + 2.4, info.linkX + 30
	deckArea(nine, nx0, nx1, sz0, wz, ly, rng)
	rail(nine, Vector3.new(nx0, ly, sz0 + 0.2), Vector3.new(nx1, ly, sz0 + 0.2))
	rail(nine, Vector3.new(nx1 - 0.2, ly, sz0), Vector3.new(nx1 - 0.2, ly, wz))
	for x = nx0 + 6, nx1 - 2, 11 do
		braces(nine, Vector3.new(x, ly - 0.4, sz0 + 0.3), Vector3.new(x, ly - 0.4, faceZ))
	end
	local N2 = shack(nine, CFrame.new(info.linkX + 19, ly, wz), 18, 10, 10, rng, { kind = "workshop", name = "PumpWorks", sign = "ポンプ屋", lit = true })
	garden(nine, CFrame.new(info.linkX + 5.5, ly, wz - 4), 2.4, 3.4, rng, false)
	local ninePole = linePole(nine, Vector3.new(info.linkX + 4, ly, sz0 + 0.8))
	washingLine(nine, ninePole, N2.roofFront(-6), rng)
	washingLine(nine, ninePole, Vector3.new(info.linkX + 3, ly + 8.6, faceZ - 0.35), rng)

	-- ----- Lone shacks round the store -----
	for i, way in ipairs(info.wayIns) do
		loneShack(m, info, way, rng, i)
		task.wait()
	end

	-- ----- Wires -----
	wires(m, info.bridgeTower, tea.roofTop, rng)
	wires(m, info.bridgeTower + Vector3.new(0, -0.6, 0), store.roofTop, rng)
	wires(m, tea.roofTop, towerInfo.mastTop, rng)
	wires(m, towerInfo.mastTop, info.cornerSign, rng)
	wires(m, W2.roofTop, W3.roofTop, rng)
	wires(m, W2.roofTop, info.cornerSign + Vector3.new(0, 4, 0), rng)
	wires(m, N2.roofTop, info.cragAnchor, rng)

	-- ----- More washing, out in the open -----
	-- From the bridge's masts out to the tea house and the store.
	washingLine(m, info.bridgeMasts[1], tea.roofFront(9), rng)
	washingLine(m, info.bridgeMasts[2], store.roofFront(-6), rng)
	-- A long line from the tower's roof out over the drop to the bridge's
	-- rooftop scaffold.
	washingLine(m, towerInfo.roofEdge, info.bridgeTower - Vector3.new(6.8, 1, 0), rng)
	-- Tea house to general store, high over the bridge end.
	washingLine(m, tea.roofFront(10), store.roofFront(-7), rng)
end

-- For others to use (the squatters in the Kannon station).
StoreShacks.washingLine, StoreShacks.wires, StoreShacks.cat, StoreShacks.garden = washingLine, wires, cat, garden

return StoreShacks
