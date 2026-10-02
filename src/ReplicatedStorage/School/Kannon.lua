-- The Kannon: a colossal statue of the goddess of mercy standing in the
-- haze past the gym, leaning forward over it as if the rock under her
-- gave way, a flame-edged aureole wide behind her.
--
-- She stands on a lotus throne on the roof of a great octagonal stone
-- hall, raised on a pillar out of the haze. A railway viaduct runs
-- through the middle of the hall, and the hall is the station: two broad
-- platforms either side of the track, a commuter train stranded there,
-- a market on one platform and camps on the other. A pilgrims' bridge
-- with torii at both ends comes across from the gym to the way in; stairs
-- climb from the platform to the roof terrace round the lotus, a stair
-- tower onto the lotus, and a scaffold up beside her, with a balcony
-- against her robe halfway and, at the top, a jib out to a cradle hung
-- in front of her face.
--
-- The statue itself: put a sculpted statue model in ServerStorage >
-- PropLibrary > Kannon (e.g. the white standing Guanyin on the Creator
-- Store) and it's used, scaled to 420 studs; give it a FacingDegrees
-- attribute if she comes out facing the wrong way. Set its MeshParts'
-- CollisionFidelity to PreciseConvexDecomposition in Studio if you want
-- her solid; otherwise she's left walk-through. With no model there, a
-- stand-in built from panels takes her place.
--
-- Built after the gym (the bridge finds the rock the gym heaped up).

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local TunnelProps = require(script.Parent.TunnelProps)
local Clutter = require(script.Parent.RooftopClutter)
local Fixtures = require(script.Parent.StoreFixtures)
local PropLibrary = require(script.Parent.PropLibrary)
local Shacks = require(script.Parent.StoreShacks)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local rod, upright, deco, label = Fixtures.rod, Fixtures.upright, Fixtures.deco, Fixtures.label
local Metal, Smooth, Concrete, Neon, Wood, Fabric, Glass = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Neon, Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.Glass
local Plywood, Corroded, Diamond = Enum.Material.WoodPlanks, Enum.Material.CorrodedMetal, Enum.Material.DiamondPlate
local ellipsoid = TunnelProps.ellipsoid
local rgb = Color3.fromRGB

local Kannon = {}

-- Where she stands; the station's levels.
local SX, SZ = 330, -360
Kannon.CENTER = Vector3.new(SX, 0, SZ)
local RAIL = -108 -- the track bed through the pedestal
local PLATFORM = -104.8
-- The stand-in statue is built with its feet here, then stood on the
-- lotus (its outline below is in these coordinates).
local FEET = -386
local THICK = 3
local STONE = rgb(150, 150, 140) -- weathered grey
local STATUE_STONE = rgb(126, 126, 118) -- darker still for her
local TIMBER = rgb(110, 84, 58)
local STEEL = rgb(110, 112, 114)
local DARK = rgb(40, 40, 42)
local WARM = rgb(255, 206, 140)

-- The robe's outline, bottom to top: { y, half-width (x), half-depth (z) }.
local PROFILE = {
	{ FEET, 54, 42 }, { -330, 47, 38 }, { -250, 42, 34 }, { -170, 45, 36 }, { -100, 40, 31 },
	{ -30, 43, 33 }, { 14, 49, 32 }, { 34, 46, 29 }, { 44, 34, 24 }, { 50, 17, 16 }, { 64, 15, 15 },
}
local HEAD = { cy = 88, half = 30, rx = 25, rz = 27 }

local function radii(y)
	if y <= PROFILE[1][1] then
		return PROFILE[1][2], PROFILE[1][3]
	end
	for i = 1, #PROFILE - 1 do
		local a, b = PROFILE[i], PROFILE[i + 1]
		if y <= b[1] then
			local t = (y - a[1]) / (b[1] - a[1])
			t = t * t * (3 - 2 * t)
			return a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t
		end
	end
	return PROFILE[#PROFILE][2], PROFILE[#PROFILE][3]
end

local function headRadii(y)
	local u = math.clamp((y - HEAD.cy) / HEAD.half, -1, 1)
	local k = math.sqrt(1 - u * u)
	return math.max(HEAD.rx * k, 14), math.max(HEAD.rz * k, 14)
end

local function surface(a, y, rx, rz)
	return Vector3.new(SX + math.cos(a) * rx, y, SZ + math.sin(a) * rz)
end

local lightsLeft = 0
local function glow(p, range, color)
	if lightsLeft > 0 then
		lightsLeft -= 1
		local l = Instance.new("PointLight")
		l.Range = range or 16
		l.Brightness = 1
		l.Color = color or WARM
		l.Parent = p
	end
end

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	xa, xb = math.min(xa, xb), math.max(xa, xb)
	ya, yb = math.min(ya, yb), math.max(ya, yb)
	za, zb = math.min(za, zb), math.max(za, zb)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

local function lootSpot(parent, pos)
	local p = part(parent, "LootSpot", Vector3.new(2, 2, 2), pos + Vector3.new(0, 1, 0), Smooth, rgb(255, 220, 0))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p:AddTag("LootSpot")
end

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

-- The stone's colour: greener and darker low down, with some variety.
local function stoneAt(y, rng)
	local t = math.clamp((y - FEET) / 400, 0, 1)
	return jitter(rgb(104, 110, 98):Lerp(STONE, t), rng, 0.04)
end

local A = 108 -- the octagon's apothem
local SIDE = 2 * A * math.tan(math.pi / 8)
local DRUM_BOTTOM = -210
local ROOF = -74 -- top of the hall's roof, the terrace round the lotus (about the gym's level)
local LOTUS_TOP = -40 -- where she stands
local HALL = rgb(184, 180, 168)

-- ===== The shell =====

-- One ring of the shell between y0 and y1 (radii r0 at the bottom, r1 at
-- the top) in n panels, leaving out any that skip(a, y0, y1) says.
local function ring(parent, y0, y1, r0x, r0z, r1x, r1z, n, skip, rng)
	local da = math.pi * 2 / n
	for k = 0, n - 1 do
		local a = k * da
		if not skip(a, y0, y1, k) then
			local ym = (y0 + y1) / 2
			local rxm, rzm = (r0x + r1x) / 2, (r0z + r1z) / 2
			local p0, p1 = surface(a, y0, r0x, r0z), surface(a, y1, r1x, r1z)
			local left, right = surface(a - da / 2, ym, rxm, rzm), surface(a + da / 2, ym, rxm, rzm)
			local tx = (right - left).Unit
			local uy = p1 - p0
			uy = (uy - tx * uy:Dot(tx)).Unit
			local out = Vector3.new(math.cos(a) / rxm, 0, math.sin(a) / rzm).Unit
			local centre = (p0 + p1) / 2 - out * (THICK / 2)
			local cf = CFrame.fromMatrix(centre, tx, uy)
			part(parent, "Shell", Vector3.new((right - left).Magnitude + 0.6, (p1 - p0).Magnitude + 0.3, THICK), cf, Concrete, stoneAt(ym, rng))
		end
	end
end

local function nearAngle(a, target, width)
	local d = math.abs((a - target + math.pi) % (math.pi * 2) - math.pi)
	return d < width
end

local function body(parent, rng)
	local shell = model(parent, "Shell")
	local n = 28
	local function skip(a, y0, y1)
		return y0 > -300 and y0 < 10 and rng:NextNumber() < 0.012 -- cracks
	end
	local y = FEET
	local bands = 0
	while y < 64 - 0.1 do
		local y1 = y + 10
		local r0x, r0z = radii(y)
		local r1x, r1z = radii(y1)
		ring(shell, y, y1, r0x, r0z, r1x, r1z, n, skip, rng)
		y = y1
		bands += 1
		if bands % 6 == 0 then
			task.wait()
		end
	end
	-- The head.
	local head = model(parent, "Head")
	local function headSkip()
		return false
	end
	for hy = 64, 112, 6 do
		local r0x, r0z = headRadii(hy)
		local r1x, r1z = headRadii(hy + 6)
		ring(head, hy, hy + 6, r0x, r0z, r1x, r1z, 24, headSkip, rng)
	end
	cylinder(head, "HeadTop", 1.5, 28, CFrame.new(SX, 118.2, SZ) * CFrame.Angles(0, 0, math.rad(90)), Concrete, stoneAt(118, rng))
	-- The face.
	local function front(y, out)
		local _, rz = headRadii(y)
		return SZ + rz + (out or 0)
	end
	ellipsoid(head, "Nose", Vector3.new(6, 12, 7), CFrame.new(SX, 85, front(85, 1)), Concrete, STONE)
	ellipsoid(head, "UpperLip", Vector3.new(7, 1.6, 2.5), CFrame.new(SX, 77.6, front(77.6, 0.6)), Concrete, STONE)
	ellipsoid(head, "LowerLip", Vector3.new(6, 1.8, 2.5), CFrame.new(SX, 75.8, front(75.8, 0.5)), Concrete, STONE)
	for _, s in ipairs({ -1, 1 }) do
		for j = -1, 1 do
			local a = math.pi / 2 - s * (0.52 + j * 0.13)
			local rx, rz = headRadii(92 + (1 - math.abs(j)) * 0.6)
			local p = surface(a, 92 + (1 - math.abs(j)) * 0.6, rx + 0.5, rz + 0.5)
			ellipsoid(head, "Brow", Vector3.new(4, 1, 1.5), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))), Concrete, darken(STONE, 0.9))
		end
		local lid = surface(math.pi / 2 - s * 0.52, 88.8, HEAD.rx * 0.95, HEAD.rz * 0.95 + 0.6)
		ellipsoid(head, "Eyelid", Vector3.new(7.5, 1.4, 2), CFrame.lookAt(lid, lid + Vector3.new(0, 0, 1)), Concrete, STONE)
		local eye = surface(math.pi / 2 - s * 0.52, 86, HEAD.rx * 0.98, HEAD.rz * 0.98)
		ellipsoid(head, "Eye", Vector3.new(6.5, 2, 1.2), CFrame.lookAt(eye, eye + Vector3.new(0, 0, 1)), Concrete, darken(STONE, 0.82))
		ellipsoid(head, "Ear", Vector3.new(4, 24, 8), CFrame.new(SX + s * (HEAD.rx + 1), 82, SZ + 2), Concrete, STONE)
	end
	part(head, "Urna", Vector3.one * 2, Vector3.new(SX, 97, front(97, 0.5)), Concrete, darken(STONE, 0.85)).Shape = Enum.PartType.Ball
	-- A crown of petals, a seated Buddha at its front, the topknot.
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local p = surface(a, 108, HEAD.rx * 0.82 + 1, HEAD.rz * 0.82 + 1)
		ellipsoid(head, "CrownPetal", Vector3.new(7, 10, 1.5), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0.3, math.sin(a))), Concrete, stoneAt(108, rng))
	end
	local seat = Vector3.new(SX, 110, front(108, 2))
	ellipsoid(head, "CrownBuddha", Vector3.new(3.4, 3, 2.6), CFrame.new(seat), Concrete, STONE)
	ellipsoid(head, "CrownBuddhaHead", Vector3.new(1.8, 2, 1.8), CFrame.new(seat + Vector3.new(0, 2.4, 0)), Concrete, STONE)
	ellipsoid(head, "Topknot", Vector3.new(16, 14, 16), CFrame.new(SX, 121, SZ), Concrete, stoneAt(121, rng))
	-- Folds in the robe: long ridges down her front and sides.
	local folds = model(parent, "Folds")
	for k = 0, 9 do
		local a = (k + 0.5) / 10 * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		if not nearAngle(a, 0, 0.3) and not nearAngle(a, math.pi, 0.3) then
			local fy = FEET + 4
			while fy < 10 do
				local fy1 = math.min(fy + 55, 14)
				local rx0, rz0 = radii(fy)
				local rx1, rz1 = radii(fy1)
				local p0 = surface(a, fy, rx0 + 0.6, rz0 + 0.6)
				local p1 = surface(a, fy1, rx1 + 0.6, rz1 + 0.6)
				do
					part(folds, "Fold", Vector3.new(2.6, (p1 - p0).Magnitude, 2), CFrame.lookAt((p0 + p1) / 2, p1, Vector3.new(math.cos(a), 0, math.sin(a))) * CFrame.Angles(math.rad(90), 0, 0), Concrete, stoneAt(fy, rng))
				end
				fy = fy1
			end
		end
	end
end

-- ===== The train =====

local function car(parent, cx, livery, cab, rng)
	local c = model(parent, "TrainCar")
	local ft = PLATFORM
	local H = 11
	local x0, x1 = cx - 19, cx + 19
	local W = 4.8
	local body = rgb(214, 216, 212)
	box(c, "Underframe", x0, x1, ft - 1.6, ft - 0.2, -W + 0.2 + SZ, W - 0.2 + SZ, Metal, DARK)
	box(c, "CarFloor", x0 + 0.2, x1 - 0.2, ft - 0.2, ft, -W + 0.3 + SZ, W - 0.3 + SZ, Smooth, rgb(150, 146, 136))
	for _, bx in ipairs({ x0 + 6, x1 - 6 }) do
		box(c, "Bogie", bx - 3, bx + 3, RAIL + 0.6, ft - 1.6, SZ - 3, SZ + 3, Metal, rgb(50, 50, 52))
		for _, dx in ipairs({ -2, 2 }) do
			cylinder(c, "Wheel", 6, 1.8, CFrame.new(bx + dx, RAIL + 1.3, SZ) * CFrame.Angles(0, math.pi / 2, 0), Metal, DARK)
		end
	end
	-- Sides: the platform side with its doors standing open, the other with
	-- its doors shut.
	local doors = { cx - 13, cx - 4.5, cx + 4.5, cx + 13 }
	local wins = { { cx - 16.8, 2.2 }, { cx - 8.75, 3.6 }, { cx, 4.4 }, { cx + 8.75, 3.6 }, { cx + 16.8, 2.2 } }
	for _, side in ipairs({ 1, -1 }) do
		local openings = {}
		for _, w in ipairs(wins) do
			table.insert(openings, { center = w[1], width = w[2], bottom = ft + 3.6, top = ft + 7.4 })
		end
		if side == 1 then
			for _, d in ipairs(doors) do
				table.insert(openings, { center = d, width = 3.8, bottom = ft, top = ft + 8.4 })
			end
		end
		BuildUtil.strip(c, { name = "CarSide", axis = "X", fixed = SZ + side * (W - 0.1), spanStart = x0, spanEnd = x1, bottom = ft, top = ft + H, thickness = 0.2, openings = openings, material = Metal, color = body })
		for _, w in ipairs(wins) do
			if side == -1 or rng:NextNumber() < 0.6 then
				local g = box(c, "CarWindow", w[1] - w[2] / 2, w[1] + w[2] / 2, ft + 3.6, ft + 7.4, SZ + side * (W - 0.14), SZ + side * (W - 0.06), Glass, rgb(70, 80, 86))
				g.Transparency = 0.5
			end
		end
		if side == -1 then
			for _, d in ipairs(doors) do
				box(c, "ShutDoor", d - 1.9, d + 1.9, ft, ft + 8.4, SZ - W - 0.05, SZ - W + 0.1, Metal, darken(body, 0.9))
			end
		end
		-- The livery stripe, broken round the open doors.
		local xs = { x0 }
		if side == 1 then
			for _, d in ipairs(doors) do
				table.insert(xs, d - 1.9)
				table.insert(xs, d + 1.9)
			end
		end
		table.insert(xs, x1)
		for k = 1, #xs - 1, 2 do
			if xs[k + 1] - xs[k] > 0.2 then
				box(c, "Stripe", xs[k], xs[k + 1], ft + 1.8, ft + 2.8, SZ + side * (W + 0.02), SZ + side * (W + 0.12), Smooth, livery)
			end
		end
	end
	-- Ends: gangways through between cars, a cab at the ends of the train.
	for _, e in ipairs({ { x = x0, outward = -1 }, { x = x1, outward = 1 } }) do
		local isCab = cab == e.outward
		local openings = if isCab then { { center = SZ, width = 5, bottom = ft + 4, top = ft + 8 } } else { { center = SZ, width = 3.2, bottom = ft, top = ft + 8 } }
		BuildUtil.strip(c, { name = "CarEnd", axis = "Z", fixed = e.x - e.outward * 0.1, spanStart = SZ - W, spanEnd = SZ + W, bottom = ft, top = ft + H, thickness = 0.2, openings = openings, material = Metal, color = body })
		if isCab then
			local g = box(c, "CabWindow", e.x - 0.14, e.x - 0.06, ft + 4, ft + 8, SZ - 2.5, SZ + 2.5, Glass, rgb(70, 80, 86))
			g.Transparency = 0.4
			box(c, "CabDesk", e.x - e.outward * 3, e.x - e.outward * 0.3, ft, ft + 3.4, SZ - 4, SZ + 4, Metal, rgb(60, 64, 70))
			for _, s in ipairs({ -1, 1 }) do
				deco(part(c, "Headlight", Vector3.new(0.3, 0.8, 1.2), Vector3.new(e.x + e.outward * 0.15, ft + 2.2, SZ + s * 3.2), Glass, rgb(230, 226, 200)))
			end
			label(c, CFrame.new(e.x + e.outward * 0.15, ft + 9.2, SZ) * CFrame.Angles(0, if e.outward > 0 then math.rad(-90) else math.rad(90), 0), Vector3.new(5, 1.2, 0.1), Enum.NormalId.Front, "回送", DARK, rgb(250, 160, 60))
		else
			box(c, "Gangway", e.x - 0.1 * e.outward, e.x + e.outward * 0.9, ft, ft + 8.6, SZ - 2, SZ + 2, Fabric, DARK).Transparency = 0.2
		end
	end
	box(c, "CarRoof", x0, x1, ft + H, ft + H + 0.6, SZ - W, SZ + W, Metal, rgb(150, 150, 146))
	-- Grime low down and graffiti on the side away from the platform, rust
	-- streaking from the roof.
	box(c, "Grime", x0, x1, ft - 1.6, ft + 1.6, SZ - W - 0.03, SZ - W - 0.1, Smooth, rgb(90, 80, 66)).Transparency = 0.3
	for _ = 1, 2 do
		label(c, CFrame.new(cx + rng:NextNumber(-12, 12), ft + rng:NextNumber(4.5, 6), SZ - W - 0.14) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6))), Vector3.new(rng:NextNumber(7, 11), 2.6, 0.03), Enum.NormalId.Front, pick({ "LOST", "月光", "帰れない", "KANNON LINE", "まだ", "YOU WERE HERE" }, rng), body, pick({ rgb(200, 40, 60), rgb(40, 60, 200), rgb(30, 30, 30), rgb(240, 200, 40) }, rng), Smooth, Enum.Font.PermanentMarker).Transparency = 1
	end
	for _ = 1, 4 do
		for _, side in ipairs({ 1, -1 }) do
			deco(box(c, "RustStreak", cx + rng:NextNumber(-17, 17), cx + rng:NextNumber(-17, 17) + 0.5, ft + rng:NextNumber(6, 9), ft + H - 0.2, SZ + side * (W + 0.04), SZ + side * (W + 0.08), Smooth, rgb(120, 80, 50))).Transparency = 0.4
		end
	end
	for _, dx in ipairs({ -8, 8 }) do
		box(c, "AirCon", cx + dx - 2.5, cx + dx + 2.5, ft + H + 0.6, ft + H + 1.8, SZ - 2.2, SZ + 2.2, Metal, rgb(190, 192, 190))
	end
	-- Inside: long seats, hand straps, poles, the lights.
	local between = { { x0 + 0.5, doors[1] - 2.1 }, { doors[1] + 2.1, doors[2] - 2.1 }, { doors[2] + 2.1, doors[3] - 2.1 }, { doors[3] + 2.1, doors[4] - 2.1 }, { doors[4] + 2.1, x1 - 0.5 } }
	local seat = pick({ rgb(60, 90, 150), rgb(150, 60, 60), rgb(70, 120, 90) }, rng)
	for _, b in ipairs(between) do
		for _, side in ipairs({ 1, -1 }) do
			box(c, "Seat", b[1], b[2], ft, ft + 1.8, SZ + side * (W - 1.6), SZ + side * (W - 0.3), Fabric, seat)
			box(c, "SeatBack", b[1], b[2], ft + 1.8, ft + 4, SZ + side * (W - 0.6), SZ + side * (W - 0.25), Fabric, seat)
		end
	end
	for _, side in ipairs({ 1, -1 }) do
		deco(rod(c, "StrapRail", Vector3.new(x0 + 1, ft + 9.4, SZ + side * 2.6), Vector3.new(x1 - 1, ft + 9.4, SZ + side * 2.6), 0.14, Metal, STEEL))
		for x = x0 + 2, x1 - 2, 2.2 do
			if rng:NextNumber() < 0.85 then
				deco(rod(c, "Strap", Vector3.new(x, ft + 9.4, SZ + side * 2.6), Vector3.new(x, ft + 8.3, SZ + side * 2.6), 0.08, Smooth, rgb(236, 232, 222)))
				deco(part(c, "StrapRing", Vector3.new(0.5, 0.5, 0.1), Vector3.new(x, ft + 8.05, SZ + side * 2.6), Smooth, rgb(236, 232, 222)))
			end
		end
	end
	for _, d in ipairs(doors) do
		rod(c, "Pole", Vector3.new(d, ft, SZ), Vector3.new(d, ft + H, SZ), 0.2, Metal, STEEL)
	end
	for _, dx in ipairs({ -10, 10 }) do
		local lit = rng:NextNumber() < 0.3
		deco(box(c, "CarLight", cx + dx - 5, cx + dx + 5, ft + H - 0.2, ft + H, SZ - 0.5, SZ + 0.5, if lit then Neon else Smooth, if lit then rgb(240, 238, 226) else rgb(170, 170, 166)))
	end
	return c
end

local function sign(parent, cf, rng)
	label(parent, cf, Vector3.new(14, 3.2, 0.2), Enum.NormalId.Front, "かんのん\nKANNON", rgb(240, 238, 232), rgb(30, 60, 120), Smooth, Enum.Font.GothamBold)
	label(parent, cf * CFrame.new(0, -2.2, 0), Vector3.new(14, 1.1, 0.2), Enum.NormalId.Front, "← 城下町              港 →", rgb(30, 60, 120), rgb(240, 238, 232), Smooth, Enum.Font.GothamBold)
end

-- ===== The viaduct =====

local function viaduct(parent, rng)
	local v = model(parent, "Viaduct")
	local grey = rgb(150, 146, 136)
	local inner = A - 3
	for _, dir in ipairs({ -1, 1 }) do
		local a, b = SX + dir * inner, SX + dir * 262
		local xa, xb = math.min(a, b), math.max(a, b)
		-- the far end broken off, hanging
		local brk = SX + dir * 236
		local sx0, sx1 = math.min(a, brk), math.max(a, brk)
		box(v, "Deck", sx0, sx1, RAIL - 3, RAIL, SZ - 8, SZ + 8, Concrete, grey)
		for _, s in ipairs({ -1, 1 }) do
			box(v, "Parapet", sx0, sx1, RAIL, RAIL + 1.6, SZ + s * 8 - (if s > 0 then 0.8 else 0), SZ + s * 8 + (if s < 0 then 0.8 else 0), Concrete, darken(grey, 0.9))
		end
		local hang = CFrame.new(brk, RAIL - 1.5, SZ) * CFrame.Angles(0, 0, math.rad(dir * -22)) * CFrame.new(dir * 13, 0, 0)
		part(v, "BrokenDeck", Vector3.new(26, 3, 16), hang, Concrete, grey)
		for k = 0, 5 do
			deco(rod(v, "Rebar", Vector3.new(brk, RAIL - 1 - k * 0.3, SZ - 6 + k * 2.4), Vector3.new(brk + dir * rng:NextNumber(1, 4), RAIL - 2 - rng:NextNumber(0, 3), SZ - 6 + k * 2.4), 0.2, Corroded, rgb(116, 76, 48)))
		end
		-- Piers down into the haze, catenary masts along the parapet.
		local x = SX + dir * (inner + 22)
		while (x - brk) * dir < -4 do
			cylinder(v, "Pier", 700, 6, CFrame.new(x, RAIL - 3 - 350, SZ) * CFrame.Angles(0, 0, math.rad(90)), Concrete, rgb(110, 108, 102))
			box(v, "PierCap", x - 3, x + 3, RAIL - 5, RAIL - 3, SZ - 7, SZ + 7, Concrete, grey)
			rod(v, "CatenaryMast", Vector3.new(x, RAIL, SZ + 7.4), Vector3.new(x, RAIL + 18, SZ + 7.4), 0.5, Metal, STEEL)
			rod(v, "CatenaryArm", Vector3.new(x, RAIL + 17, SZ + 7.4), Vector3.new(x, RAIL + 17, SZ - 1), 0.3, Metal, STEEL)
			x += dir * 34
		end
		deco(rod(v, "ContactWire", Vector3.new(SX + dir * inner, RAIL + 16.4, SZ), Vector3.new(brk, RAIL + 16.4, SZ), 0.1, Metal, DARK))
	end
	-- The track, right through her: rails and sleepers.
	for _, s in ipairs({ -2.5, 2.5 }) do
		box(v, "Rail", SX - 236, SX + 236, RAIL, RAIL + 0.5, SZ + s - 0.2, SZ + s + 0.2, Metal, rgb(130, 126, 120))
	end
	for x = SX - 234, SX + 234, 4 do
		box(v, "Sleeper", x - 0.5, x + 0.5, RAIL - 0.02, RAIL + 0.2, SZ - 4, SZ + 4, Concrete, rgb(120, 116, 110))
	end
end

-- ===== The arms =====

-- A tapered limb from a (radius ra) to b (radius rb) in a few pieces.
local function limb(parent, name, a, b, ra, rb, rng)
	local n = 3
	for k = 0, n - 1 do
		local p0, p1 = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
		local r = ra + (rb - ra) * (k + 0.5) / n
		cylinder(parent, name, (p1 - p0).Magnitude + r * 0.4, r * 2, CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.Angles(0, math.pi / 2, 0), Concrete, stoneAt(p0.Y, rng))
	end
end

-- ===== Overgrowth =====

local function overgrowth(parent, rng, arm)
	local g = model(parent, "Overgrowth")
	for _ = 1, 45 do
		local y = FEET + (rng:NextNumber() ^ 0.7) * (40 - FEET)
		local a = rng:NextNumber(0, math.pi * 2)
		do
			local rx, rz = radii(y)
			local p = surface(a, y, rx + 0.8, rz + 0.8)
			local s = rng:NextNumber(3, 9)
			deco(ellipsoid(g, "Moss", Vector3.new(s, s * rng:NextNumber(0.6, 1.6), 1.6), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))), Enum.Material.LeafyGrass, jitter(rgb(80, 110, 60), rng, 0.15)))
		end
	end
	-- Vines hanging off her arms and shoulders.
	for _ = 1, 16 do
		local limbPair = pick({ { arm.elbow, arm.wrist }, { arm.shoulder, arm.elbow }, { arm.lShoulder, arm.lElbow }, { arm.lElbow, arm.lHand } }, rng)
		local from, to = limbPair[1], limbPair[2]
		local top = from:Lerp(to, rng:NextNumber(0.1, 0.9)) + Vector3.new(pick({ -1, 1 }, rng) * rng:NextNumber(8, 11), -rng:NextNumber(2, 6), rng:NextNumber(-3, 3))
		local len = rng:NextNumber(12, 45)
		local prev = top
		for k = 1, 4 do
			local p = top + Vector3.new(rng:NextNumber(-1.5, 1.5), -len * k / 4, rng:NextNumber(-1.5, 1.5))
			deco(rod(g, "Vine", prev, p, 0.35, Wood, rgb(70, 90, 50)))
			if rng:NextNumber() < 0.6 then
				deco(ellipsoid(g, "Leaves", Vector3.new(2.4, 1.8, 2.4), CFrame.new(p), Enum.Material.LeafyGrass, jitter(rgb(80, 120, 60), rng, 0.15)))
			end
			prev = p
		end
	end
	-- A tree seeded on her left shoulder.
	local holder = model(g, "ShoulderTree")
	Clutter.rooftopTree(holder, Vector3.new(SX + 38, 44, SZ - 6), rng)
end

-- ===== Her arms (the stand-in statue) =====

-- Her right hand raised before her chest, palm out; her left hanging by
-- her side with a vase and a willow sprig. Returns the joints (for vines).
local function arms(parent, rng)
	local a = model(parent, "Arms")
	local shoulder = Vector3.new(SX - 44, 22, SZ - 2)
	local elbow = Vector3.new(SX - 52, -34, SZ + 16)
	local wrist = Vector3.new(SX - 40, -6, SZ + 44)
	ellipsoid(a, "Shoulder", Vector3.new(28, 28, 26), CFrame.new(shoulder), Concrete, stoneAt(22, rng))
	limb(a, "UpperArm", shoulder, elbow, 12, 11, rng)
	ellipsoid(a, "Elbow", Vector3.new(22, 22, 22), CFrame.new(elbow), Concrete, stoneAt(-34, rng))
	limb(a, "Forearm", elbow, wrist, 11, 8.5, rng)
	ellipsoid(a, "Sleeve", Vector3.new(8, 34, 22), CFrame.new(elbow:Lerp(wrist, 0.45) - Vector3.new(0, 16, 0)), Concrete, stoneAt(-40, rng))
	local palm = CFrame.lookAt(wrist + Vector3.new(0, 9, 3), wrist + Vector3.new(0, 9, 30))
	ellipsoid(a, "Palm", Vector3.new(14, 18, 5), palm, Concrete, STONE)
	for k = 0, 3 do
		limb(a, "Finger", (palm * CFrame.new(-4.5 + k * 3, 8, 0)).Position, (palm * CFrame.new(-4.8 + k * 3.2, 16 - math.abs(k - 1.5) * 1.5, -0.5)).Position, 1.5, 1.3, rng)
	end
	limb(a, "Thumb", (palm * CFrame.new(7, -2, 0)).Position, (palm * CFrame.new(10, 4, -1)).Position, 1.8, 1.5, rng)
	local lShoulder = Vector3.new(SX + 44, 22, SZ - 2)
	local lElbow = Vector3.new(SX + 48, -40, SZ + 8)
	local lHand = Vector3.new(SX + 34, -54, SZ + 38)
	ellipsoid(a, "Shoulder", Vector3.new(28, 28, 26), CFrame.new(lShoulder), Concrete, stoneAt(22, rng))
	limb(a, "UpperArm", lShoulder, lElbow, 12, 11, rng)
	ellipsoid(a, "Elbow", Vector3.new(22, 22, 22), CFrame.new(lElbow), Concrete, stoneAt(-40, rng))
	limb(a, "Forearm", lElbow, lHand, 11, 8, rng)
	ellipsoid(a, "Hand", Vector3.new(12, 8, 12), CFrame.new(lHand), Concrete, STONE)
	ellipsoid(a, "Vase", Vector3.new(8, 12, 8), CFrame.new(lHand + Vector3.new(0, 8, 3)), Concrete, darken(STONE, 0.9))
	cylinder(a, "VaseNeck", 5, 3, CFrame.new(lHand + Vector3.new(0, 15.5, 3)) * CFrame.Angles(0, 0, math.rad(90)), Concrete, darken(STONE, 0.9))
	for k = 1, 3 do
		deco(rod(a, "Willow", lHand + Vector3.new(0, 17, 3), lHand + Vector3.new(rng:NextNumber(-4, 4), 24 + k, 3 + rng:NextNumber(-2, 2)), 0.4, Wood, rgb(90, 110, 60)))
	end
	return { shoulder = shoulder, elbow = elbow, wrist = wrist, lShoulder = lShoulder, lElbow = lElbow, lHand = lHand }
end

-- ===== The pedestal =====
-- An octagonal stone hall on a pillar out of the haze, the lotus throne
-- on its roof. The line goes through it east to west; the station is the
-- hall.

-- Half the octagon's width at z (from its centre), less `inset`.
local function octHalf(z, inset)
	local a = A - (inset or 0)
	return math.max(0, math.min(a, a * math.sqrt(2) - math.abs(z)))
end

-- A floor filling the octagon (less `inset`) with its top at y, in strips
-- along x; `keep(z)` picks strips, `cut(x0, x1, z)` returns x spans to
-- leave out.
local function octFloor(parent, name, y, thick, inset, keep, cuts, material, color)
	for z = -A + inset + 1, A - inset - 1, 2 do
		if not keep or keep(z) then
			local half = octHalf(z, inset)
			local spans = { { -half, half } }
			for _, c in ipairs(cuts or {}) do
				if z > c.z0 and z < c.z1 then
					local nextSpans = {}
					for _, sp in ipairs(spans) do
						if c.x0 > sp[1] then
							table.insert(nextSpans, { sp[1], math.min(sp[2], c.x0) })
						end
						if c.x1 < sp[2] then
							table.insert(nextSpans, { math.max(sp[1], c.x1), sp[2] })
						end
					end
					spans = nextSpans
				end
			end
			for _, sp in ipairs(spans) do
				if sp[2] - sp[1] > 0.3 then
					box(parent, name, SX + sp[1], SX + sp[2], y - thick, y, SZ + z - 1, SZ + z + 1, material, color)
				end
			end
		end
	end
end

-- One wall of the octagon (face k, its outward normal at k * 45 degrees)
-- from y0 to y1, with openings { c (along the face), w, b, t } cut out.
local function faceWall(parent, k, y0, y1, openings, rng)
	local a = k * math.pi / 4
	local n = Vector3.new(math.cos(a), 0, math.sin(a))
	local along = Vector3.new(-math.sin(a), 0, math.cos(a))
	local centre = Vector3.new(SX, 0, SZ) + n * (A - 1.5)
	local frame = CFrame.fromMatrix(centre, along, Vector3.yAxis)
	local half = SIDE / 2 + 1.2
	-- columns between the openings' edges
	local cuts = { -half, half }
	for _, o in ipairs(openings) do
		table.insert(cuts, o.c - o.w / 2)
		table.insert(cuts, o.c + o.w / 2)
	end
	table.sort(cuts)
	for i = 1, #cuts - 1 do
		local u0, u1 = cuts[i], cuts[i + 1]
		if u1 - u0 > 0.05 then
			local mid = (u0 + u1) / 2
			local gaps = {}
			for _, o in ipairs(openings) do
				if mid > o.c - o.w / 2 and mid < o.c + o.w / 2 then
					table.insert(gaps, { o.b, o.t })
				end
			end
			table.sort(gaps, function(p, q)
				return p[1] < q[1]
			end)
			local y = y0
			for _, g in ipairs(gaps) do
				if g[1] - y > 0.05 then
					part(parent, "HallWall", Vector3.new(u1 - u0, g[1] - y, 3), frame * CFrame.new(mid, (y + g[1]) / 2, 0), Concrete, jitter(HALL, rng, 0.03))
				end
				y = math.max(y, g[2])
			end
			if y1 - y > 0.05 then
				part(parent, "HallWall", Vector3.new(u1 - u0, y1 - y, 3), frame * CFrame.new(mid, (y + y1) / 2, 0), Concrete, jitter(HALL, rng, 0.03))
			end
		end
	end
	return frame
end

local function pedestal(parent, rng)
	local p = model(parent, "Pedestal")
	cylinder(p, "Plinth", 1740, 190, CFrame.new(SX, DRUM_BOTTOM - 870, SZ) * CFrame.Angles(0, 0, math.rad(90)), Concrete, rgb(96, 96, 92))
	octFloor(p, "HallBase", DRUM_BOTTOM + 2, 2, 0, nil, nil, Concrete, rgb(110, 108, 102))
	for k = 0, 7 do
		local openings = {}
		local windows = { -32, -12, 12, 32 }
		if k == 0 or k == 4 then
			-- the line in and out
			table.insert(openings, { c = 0, w = 18, b = RAIL - 1, t = RAIL + 22 })
			windows = { -32, 32 }
		elseif k == 2 then
			-- the pilgrims' way in from the gym, at platform level
			table.insert(openings, { c = 0, w = 12, b = PLATFORM, t = PLATFORM + 14 })
		end
		for _, u in ipairs(windows) do
			table.insert(openings, { c = u, w = 7, b = ROOF - 26, t = ROOF - 8 })
		end
		local frame = faceWall(p, k, DRUM_BOTTOM, ROOF - 2, openings, rng)
		-- Glass in the windows, some broken; frames; relief panels below.
		for _, u in ipairs(windows) do
			if rng:NextNumber() < 0.7 then
				part(p, "HallWindow", Vector3.new(7, 18, 0.2), frame * CFrame.new(u, ROOF - 17, 0), Glass, rgb(70, 80, 86)).Transparency = 0.5
			end
			part(p, "WindowArch", Vector3.new(8.4, 1.4, 3.6), frame * CFrame.new(u, ROOF - 7.3, 0), Concrete, darken(HALL, 0.9))
			part(p, "WindowSill", Vector3.new(8.4, 1, 3.8), frame * CFrame.new(u, ROOF - 26.5, 0), Concrete, darken(HALL, 0.9))
		end
		for _, u in ipairs({ -24, 0, 24 }) do
			local panel = frame * CFrame.new(u, DRUM_BOTTOM + 50, -1.7)
			part(p, "ReliefPanel", Vector3.new(16, 22, 0.6), panel, Concrete, darken(HALL, 0.94))
			cylinder(p, "DharmaWheel", 0.6, 11, panel * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi / 2, 0), Concrete, darken(HALL, 0.86))
			for j = 0, 7 do
				local ang = j / 8 * math.pi * 2
				deco(part(p, "WheelSpoke", Vector3.new(0.6, 9, 0.4), panel * CFrame.new(0, 0, -0.9) * CFrame.Angles(0, 0, ang), Concrete, darken(HALL, 0.8)))
			end
		end
		-- Cornices round the drum.
		for _, y in ipairs({ DRUM_BOTTOM + 2, ROOF - 48, ROOF - 3.5 }) do
			part(p, "Cornice", Vector3.new(SIDE + 6, 3, 4), frame * CFrame.new(0, y, -2), Concrete, darken(HALL, 0.92))
		end
		-- A pilaster at the corner.
		local ca = (k + 0.5) * math.pi / 4
		local corner = Vector3.new(SX + math.cos(ca) * (A / math.cos(math.pi / 8) - 1), 0, SZ + math.sin(ca) * (A / math.cos(math.pi / 8) - 1))
		part(p, "Pilaster", Vector3.new(6, ROOF + 4 - DRUM_BOTTOM, 6), CFrame.new(corner.X, (DRUM_BOTTOM + ROOF + 4) / 2, corner.Z) * CFrame.Angles(0, -ca, 0), Concrete, darken(HALL, 0.95))
		-- The parapet round the roof (open on the north for the bridge).
		if k == 2 then
			for _, u in ipairs({ -1, 1 }) do
				part(p, "Parapet", Vector3.new(SIDE / 2 - 5, 3.5, 1.4), frame * CFrame.new(u * (SIDE / 4 + 3.5), ROOF + 1.75, 0.8), Concrete, HALL)
			end
			part(p, "Shutter", Vector3.new(12, 14, 0.4), frame * CFrame.new(0, PLATFORM + 7, 0), Metal, rgb(120, 122, 116))
			for y = PLATFORM + 0.6, PLATFORM + 13.6, 0.8 do
				deco(part(p, "ShutterSlat", Vector3.new(12, 0.1, 0.5), frame * CFrame.new(0, y, 0), Metal, rgb(100, 102, 98)))
			end
			label(p, frame * CFrame.new(0, PLATFORM + 9, -0.3), Vector3.new(6, 1.6, 0.1), Enum.NormalId.Front, "閉鎖  CLOSED", rgb(200, 40, 34), rgb(240, 236, 226))
		else
			part(p, "Parapet", Vector3.new(SIDE + 2, 3.5, 1.4), frame * CFrame.new(0, ROOF + 1.75, 0.8), Concrete, HALL)
		end
	end
	-- The name over the way in.
	local north = CFrame.fromMatrix(Vector3.new(SX, 0, SZ + A + 0.2), Vector3.new(-1, 0, 0), Vector3.yAxis)
	label(p, north * CFrame.new(0, PLATFORM + 20, 0), Vector3.new(34, 7, 0.4), Enum.NormalId.Front, "観音駅", rgb(120, 30, 30), rgb(240, 226, 196), Smooth, Enum.Font.GothamBlack)
	-- The roof, with the stair hole over the flight up from the south
	-- platform.
	octFloor(p, "HallRoof", ROOF, 2, 0, nil, { { x0 = -20, x1 = 6, z0 = -93, z1 = -87 }, { x0 = -104, x1 = -88, z0 = -10, z1 = 10 } }, Concrete, rgb(150, 146, 136))
	for _ = 1, 8 do
		local s3 = Vector3.new(rng:NextNumber(1.5, 4), rng:NextNumber(0.6, 1.6), rng:NextNumber(1.5, 4))
		part(p, "BrokenEdge", s3, CFrame.new(SX + pick({ -104, -88 }, rng) + rng:NextNumber(-2, 2), ROOF + 0.2, SZ + rng:NextNumber(-10, 10)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4)), Concrete, rgb(150, 146, 136))
	end
	-- The lotus throne.
	local lotus = model(p, "Lotus")
	cylinder(lotus, "LotusStep", 6, 168, CFrame.new(SX, ROOF + 3, SZ) * CFrame.Angles(0, 0, math.rad(90)), Concrete, darken(HALL, 0.9))
	for k = 0, 19 do
		local a = k / 20 * math.pi * 2
		local q = Vector3.new(SX + math.cos(a) * 78, ROOF + 16, SZ + math.sin(a) * 78)
		ellipsoid(lotus, "Petal", Vector3.new(36, 34, 12), CFrame.lookAt(q, q + Vector3.new(math.cos(a), -0.45, math.sin(a))), Concrete, jitter(rgb(206, 196, 186), rng, 0.04))
	end
	local coreBottom, coreTop = ROOF + 6, LOTUS_TOP - 3
	cylinder(lotus, "LotusCore", coreTop - coreBottom, 150, CFrame.new(SX, (coreBottom + coreTop) / 2, SZ) * CFrame.Angles(0, 0, math.rad(90)), Concrete, rgb(200, 192, 180))
	cylinder(lotus, "LotusTop", 3, 150, CFrame.new(SX, LOTUS_TOP - 1.5, SZ) * CFrame.Angles(0, 0, math.rad(90)), Concrete, rgb(214, 206, 196))
end

-- ===== People in the station =====

local TARPS = { rgb(60, 110, 160), rgb(70, 120, 80), rgb(180, 120, 50), rgb(160, 60, 50), rgb(120, 120, 126) }
local CARD = rgb(176, 138, 96)

-- A tarp shelter at cf (its open front towards -z): poles, a sloping
-- tarp, cardboard walls behind and down one side, bedding, a crate.
local function shelter(parent, cf, rng, lit)
	local s = model(parent, "Shelter")
	local w, d = rng:NextNumber(6, 8), rng:NextNumber(5, 6.5)
	local hf, hb = 6.5, 4.6
	for _, dx in ipairs({ -w / 2, w / 2 }) do
		rod(s, "ShelterPole", (cf * CFrame.new(dx, 0, -d / 2)).Position, (cf * CFrame.new(dx, hf, -d / 2)).Position, 0.22, Wood, TIMBER)
		rod(s, "ShelterPole", (cf * CFrame.new(dx, 0, d / 2)).Position, (cf * CFrame.new(dx, hb, d / 2)).Position, 0.22, Wood, TIMBER)
	end
	local slope = math.atan2(hf - hb, d)
	part(s, "Tarp", Vector3.new(w + 1, 0.1, d / math.cos(slope) + 1.2), cf * CFrame.new(0, (hf + hb) / 2 + 0.12, 0) * CFrame.Angles(slope, 0, 0), Fabric, pick(TARPS, rng))
	part(s, "Cardboard", Vector3.new(w - 0.4, hb - 0.4, 0.15), cf * CFrame.new(0, (hb - 0.4) / 2, d / 2 - 0.2), Smooth, jitter(CARD, rng, 0.08))
	part(s, "Cardboard", Vector3.new(0.15, hb - 0.6, d - 0.6), cf * CFrame.new(-w / 2 + 0.2, (hb - 0.6) / 2, 0), Smooth, jitter(CARD, rng, 0.08))
	part(s, "Futon", Vector3.new(w - 2, 0.4, 2.6), cf * CFrame.new(0.5, 0.2, d / 2 - 1.8), Fabric, pick({ rgb(222, 216, 200), rgb(180, 60, 60), rgb(80, 100, 150) }, rng))
	deco(part(s, "Blanket", Vector3.new(2.6, 0.2, 2.4), cf * CFrame.new(1, 0.5, d / 2 - 1.8) * CFrame.Angles(0, 0.2, 0), Fabric, pick({ rgb(200, 150, 60), rgb(120, 60, 80), rgb(60, 110, 90) }, rng)))
	part(s, "Crate", Vector3.new(1.6, 1.4, 1.2), cf * CFrame.new(w / 2 - 1.2, 0.7, -d / 2 + 1.6) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), Wood, rgb(150, 112, 70))
	for _, dx in ipairs({ -0.4, 0.4 }) do
		deco(part(s, "Shoe", Vector3.new(0.35, 0.3, 0.8), cf * CFrame.new(-1 + dx, 0.15, -d / 2 - 0.6), Smooth, DARK))
	end
	if lit then
		local l = ellipsoid(s, "Lantern", Vector3.new(0.8, 1.1, 0.8), cf * CFrame.new(w / 2 - 1.2, 1.95, -d / 2 + 1.6), Neon, rgb(240, 150, 90))
		l.CanCollide = false
		glow(l, 12)
	end
	lootSpot(s, (cf * CFrame.new(-1.5, 0, d / 2 - 1.6)).Position)
	return s
end

-- A shopping-basket bicycle (a mamachari) along cf's z, maybe lying down.
local function bike(parent, cf, rng, fallen)
	local b = model(parent, "Bicycle")
	if fallen then
		cf = cf * CFrame.Angles(0, 0, math.rad(86))
	end
	local col = pick({ rgb(200, 200, 196), rgb(160, 40, 40), rgb(40, 60, 120), rgb(40, 40, 42), rgb(220, 180, 60) }, rng)
	local function p(x, y, z)
		return (cf * CFrame.new(x, y, z)).Position
	end
	for _, z in ipairs({ -1.4, 1.4 }) do
		deco(cylinder(b, "Wheel", 0.12, 2.2, cf * CFrame.new(0, 1.1, z), Smooth, DARK))
		deco(cylinder(b, "Hub", 0.2, 0.4, cf * CFrame.new(0, 1.1, z), Metal, STEEL))
	end
	for _, r in ipairs({
		{ p(0, 1.1, 1.4), p(0, 0.9, 0.2) }, { p(0, 1.1, 1.4), p(0, 2.2, 0.5) }, { p(0, 0.9, 0.2), p(0, 2.3, 0.6) },
		{ p(0, 0.9, 0.2), p(0, 2.1, -0.9) }, { p(0, 2.1, -0.9), p(0, 1.1, -1.4) }, { p(0, 2.1, -0.9), p(0, 2.8, -1) },
	}) do
		deco(rod(b, "Frame", r[1], r[2], 0.14, Metal, col))
	end
	deco(rod(b, "Handlebar", p(-0.8, 2.8, -1), p(0.8, 2.8, -1), 0.1, Metal, STEEL))
	deco(part(b, "Saddle", Vector3.new(0.5, 0.2, 0.9), cf * CFrame.new(0, 2.4, 0.6), Smooth, DARK))
	deco(part(b, "Basket", Vector3.new(1.1, 0.8, 0.9), cf * CFrame.new(0, 2.5, -1.8), Metal, STEEL)).Transparency = 0.3
end

-- A pigeon standing at pos.
local function pigeon(parent, pos, rng)
	local c = pick({ rgb(120, 122, 132), rgb(100, 104, 112), rgb(200, 200, 204), rgb(130, 110, 96) }, rng)
	local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	deco(ellipsoid(parent, "Pigeon", Vector3.new(0.45, 0.42, 0.8), cf * CFrame.new(0, 0.24, 0), Smooth, c))
	deco(ellipsoid(parent, "PigeonHead", Vector3.new(0.26, 0.26, 0.28), cf * CFrame.new(0, 0.5, -0.36), Smooth, darken(c, 0.85)))
	deco(part(parent, "PigeonTail", Vector3.new(0.3, 0.06, 0.4), cf * CFrame.new(0, 0.25, 0.5) * CFrame.Angles(math.rad(-15), 0, 0), Smooth, darken(c, 0.8)))
end

-- Steam or smoke rising off a small invisible part at pos.
local function steam(parent, pos, rate, size)
	local s = part(parent, "Steam", Vector3.new(1, 0.2, 1), pos, Smooth, rgb(0, 0, 0))
	s.Transparency = 1
	s.CanCollide = false
	s.CanQuery = false
	s.CanTouch = false
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = rate
	e.Lifetime = NumberRange.new(2, 3.5)
	e.Speed = NumberRange.new(1, 2.2)
	e.SpreadAngle = Vector2.new(12, 12)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(226, 224, 220))
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = s
	return s
end

-- The platforms, filled: columns holding the roof; the squatters' camp on
-- the north platform (shelters round a drum fire, washing strung between
-- the columns, a soba stand going again, a bicycle man by the lockers,
-- planters under the hole in the roof); and on the south platform, where
-- you come down, what everyone left behind — bicycles, luggage, a fallen
-- sign — a message board, and a little shrine to her at the stair foot.
local function stationLife(st, rng)
	local white = rgb(236, 234, 226)
	local navy = rgb(30, 60, 120)
	local life = model(st, "StationLife")
	-- ----- Columns -----
	local colTop = {}
	for _, s in ipairs({ -1, 1 }) do
		for x = -72, 72, 24 do
			local cx, cz = SX + x, SZ + s * 46
			part(life, "Column", Vector3.new(3, ROOF - 3 - (PLATFORM + 0.5), 3), Vector3.new(cx, (ROOF - 3 + PLATFORM + 0.5) / 2, cz), Concrete, jitter(HALL, rng, 0.03))
			part(life, "ColumnFoot", Vector3.new(3.6, 1, 3.6), Vector3.new(cx, PLATFORM + 0.5, cz), Concrete, darken(HALL, 0.8))
			part(life, "ColumnCap", Vector3.new(5, 1.5, 5), Vector3.new(cx, ROOF - 2.75, cz), Concrete, darken(HALL, 0.92))
			colTop[s * 1000 + x] = Vector3.new(cx, PLATFORM + 8, cz + s * 1.6)
			-- On the face towards the track: a poster, a hydrant box, or a
			-- scrawl.
			local faceZ = cz - s * 1.53
			local faceCF = CFrame.new(cx, PLATFORM, faceZ) * CFrame.Angles(0, if s > 0 then 0 else math.pi, 0)
			local roll = rng:NextNumber()
			if roll < 0.35 then
				deco(part(life, "Poster", Vector3.new(2.4, 3.4, 0.05), faceCF * CFrame.new(0, 5.5, 0), Smooth, jitter(pick({ rgb(200, 150, 140), rgb(150, 170, 200), rgb(210, 200, 150) }, rng), rng, 0.1)))
			elseif roll < 0.55 then
				part(life, "HydrantBox", Vector3.new(2, 2.6, 0.5), faceCF * CFrame.new(0, 2.6, -0.25), Metal, rgb(190, 40, 34))
				label(life, faceCF * CFrame.new(0, 3.3, -0.52), Vector3.new(1.6, 0.6, 0.02), Enum.NormalId.Front, "消火栓", rgb(190, 40, 34), white)
			elseif roll < 0.75 then
				label(life, faceCF * CFrame.new(0, rng:NextNumber(3, 5), -0.02) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-10, 10))), Vector3.new(2.8, 1.2, 0.02), Enum.NormalId.Front, pick({ "生きてる", "OK", "月", "ここ", "♡" }, rng), HALL, pick({ rgb(200, 40, 60), rgb(40, 60, 200), rgb(30, 30, 30) }, rng), Smooth, Enum.Font.PermanentMarker).Transparency = 1
			end
		end
	end

	-- ----- The camp on the north platform -----
	local camp = model(life, "NorthCamp")
	local fire = Vector3.new(SX, PLATFORM, SZ + 70)
	local spots = { { -42, 60, true }, { -50, 82, false }, { -24, 90, false }, { 24, 90, true }, { 36, 60, false } }
	for _, sp in ipairs(spots) do
		local pos = Vector3.new(SX + sp[1], PLATFORM, SZ + sp[2])
		shelter(camp, CFrame.lookAt(pos, Vector3.new(fire.X, PLATFORM, fire.Z)) * CFrame.Angles(0, rng:NextNumber(-0.25, 0.25), 0), rng, sp[3])
	end
	-- The drum fire, with seats round it.
	upright(camp, "FireDrum", 3, 2.2, CFrame.new(fire), 0, 1.5, 0, Corroded, rgb(120, 70, 40))
	local embers = part(camp, "Embers", Vector3.new(1.7, 0.2, 1.7), fire + Vector3.new(0, 3.1, 0), Neon, rgb(255, 120, 40))
	embers.CanCollide = false
	local flame = Instance.new("Fire")
	flame.Size = 3
	flame.Heat = 5
	flame.Color = rgb(255, 140, 60)
	flame.SecondaryColor = rgb(255, 60, 20)
	flame.Parent = embers
	glow(embers, 22, rgb(255, 150, 80))
	deco(rod(camp, "Grill", fire + Vector3.new(-1.3, 3.3, 0), fire + Vector3.new(1.3, 3.3, 0), 0.12, Metal, DARK))
	deco(upright(camp, "Kettle", 0.8, 0.9, CFrame.new(fire), 0.5, 3.8, 0, Metal, rgb(80, 80, 84)))
	for k = 0, 5 do
		local ang = k / 6 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local q = fire + Vector3.new(math.cos(ang) * 4.5, 0, math.sin(ang) * 4.5)
		local roll = rng:NextNumber()
		if roll < 0.4 then
			upright(camp, "BucketSeat", 1.4, 1.2, CFrame.new(q), 0, 0.7, 0, Smooth, pick({ rgb(60, 110, 170), rgb(200, 60, 50), rgb(220, 200, 60) }, rng))
		elseif roll < 0.75 then
			part(camp, "CrateSeat", Vector3.new(1.6, 1.3, 1.2), CFrame.new(q + Vector3.new(0, 0.65, 0)) * CFrame.Angles(0, ang, 0), Wood, rgb(150, 112, 70))
		else
			part(camp, "Cushion", Vector3.new(1.6, 0.4, 1.6), CFrame.new(q + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, ang, 0), Fabric, pick(TARPS, rng))
		end
	end
	Shacks.cat(camp, CFrame.new(fire + Vector3.new(2.6, 0, -2.4)) * CFrame.Angles(0, 2.2, 0), rng)
	Shacks.cat(camp, CFrame.new(Vector3.new(SX - 40, PLATFORM, SZ + 55)) * CFrame.Angles(0, 0.6, 0), rng)
	-- Washing strung between the columns and a couple of poles.
	local poleA, poleB = Vector3.new(SX - 14, PLATFORM, SZ + 76), Vector3.new(SX + 14, PLATFORM, SZ + 58)
	for _, pl in ipairs({ poleA, poleB }) do
		rod(camp, "LinePole", pl, pl + Vector3.new(0, 8.6, 0), 0.25, Wood, TIMBER)
		part(camp, "PoleFoot", Vector3.new(1.4, 0.8, 1.4), pl + Vector3.new(0, 0.4, 0), Concrete, rgb(120, 118, 110))
	end
	local lineY = Vector3.new(0, 8, 0)
	Shacks.washingLine(camp, colTop[1000 - 24], poleA + lineY, rng)
	Shacks.washingLine(camp, poleA + lineY, poleB + lineY, rng)
	Shacks.washingLine(camp, poleB + lineY, colTop[1000 + 24], rng)
	Shacks.washingLine(camp, colTop[1000 - 72], colTop[1000 - 48], rng)
	Shacks.washingLine(camp, colTop[1000 + 48], Vector3.new(SX + 44, PLATFORM + 7.8, SZ + 72.5), rng)
	-- The soba stand, going again.
	local so = model(camp, "SobaStand")
	local sx0, sx1, sz0, sz1 = SX + 44, SX + 56, SZ + 74, SZ + 80
	box(so, "SobaCounter", sx0, sx1, PLATFORM, PLATFORM + 3.4, sz0, sz0 + 1.4, Wood, rgb(130, 90, 56))
	box(so, "SobaCounterTop", sx0 - 0.2, sx1 + 0.2, PLATFORM + 3.4, PLATFORM + 3.6, sz0 - 0.3, sz0 + 1.6, Wood, rgb(90, 60, 40))
	box(so, "SobaBack", sx0, sx1, PLATFORM, PLATFORM + 8, sz1 - 0.3, sz1, Plywood, rgb(150, 120, 84))
	for _, x in ipairs({ sx0, sx1 }) do
		for _, z in ipairs({ sz0 - 1, sz1 - 0.2 }) do
			rod(so, "SobaPost", Vector3.new(x, PLATFORM, z), Vector3.new(x, PLATFORM + 8, z), 0.3, Wood, TIMBER)
		end
	end
	box(so, "SobaRoof", sx0 - 1, sx1 + 1, PLATFORM + 8, PLATFORM + 8.3, sz0 - 1.8, sz1 + 0.5, Corroded, rgb(120, 90, 70))
	for k = 0, 4 do
		local nx = sx0 + 1.2 + k * 2.4
		if k == 2 then
			label(so, CFrame.new(nx, PLATFORM + 7.1, sz0 - 1.3), Vector3.new(2.2, 1.7, 0.05), Enum.NormalId.Front, "そば", navy, white, Fabric)
		else
			deco(part(so, "Noren", Vector3.new(2.2, 1.7, 0.05), CFrame.new(nx, PLATFORM + 7.1, sz0 - 1.3), Fabric, navy))
		end
	end
	upright(so, "Stove", 1.6, 2, CFrame.new(SX + 48, PLATFORM, SZ + 78), 0, 0.8, 0, Metal, DARK)
	upright(so, "Pot", 1.4, 1.8, CFrame.new(SX + 48, PLATFORM, SZ + 78), 0, 2.3, 0, Metal, rgb(160, 160, 158))
	steam(so, Vector3.new(SX + 48, PLATFORM + 3.1, SZ + 78), 5, 0.6)
	for k = 0, 3 do
		deco(upright(so, "Bowl", 0.35, 0.8, CFrame.new(sx0 + 2 + k * 2.3, PLATFORM + 3.6, sz0 + 0.5), 0, 0.18, 0, Smooth, pick({ rgb(200, 60, 40), rgb(30, 30, 34), white }, rng)))
	end
	local cho = ellipsoid(so, "Chochin", Vector3.new(1.2, 1.7, 1.2), CFrame.new(sx1 + 0.6, PLATFORM + 6.6, sz0 - 1.6), Neon, rgb(240, 120, 70))
	cho.CanCollide = false
	glow(cho, 16)
	for k = 0, 2 do
		upright(so, "BucketStool", 1.3, 1.1, CFrame.new(sx0 + 3 + k * 3.2, PLATFORM, sz0 - 2.4), 0, 0.65, 0, Smooth, pick({ rgb(60, 110, 170), rgb(200, 60, 50) }, rng))
	end
	lootSpot(so, Vector3.new(sx0 + 2, PLATFORM, sz1 - 1.6))
	-- The coin lockers on the north wall, some forced; the bicycle man's
	-- corner in front of them.
	local lz1 = SZ + A - 3.02
	local lz0 = lz1 - 1.8
	box(life, "Lockers", SX + 14, SX + 38, PLATFORM, PLATFORM + 6.8, lz0, lz1, Metal, rgb(200, 196, 180))
	for i = 0, 11 do
		for j = 0, 3 do
			local dx, dy = SX + 15 + i * 2, PLATFORM + 0.85 + j * 1.7
			if rng:NextNumber() < 0.2 then
				deco(part(life, "LockerHole", Vector3.new(1.8, 1.5, 0.02), CFrame.new(dx, dy, lz0 - 0.02), Smooth, rgb(30, 30, 32)))
				deco(part(life, "LockerDoor", Vector3.new(1.85, 1.55, 0.08), CFrame.new(dx - 0.92, dy, lz0 - 0.04) * CFrame.Angles(0, math.rad(rng:NextNumber(70, 110)), 0) * CFrame.new(0.92, 0, 0), Metal, rgb(206, 202, 188)))
			else
				deco(part(life, "LockerDoor", Vector3.new(1.85, 1.55, 0.08), CFrame.new(dx, dy, lz0 - 0.04), Metal, rgb(206, 202, 188)))
			end
		end
	end
	label(life, CFrame.new(SX + 26, PLATFORM + 7.6, lz0 + 0.5), Vector3.new(8, 1, 0.1), Enum.NormalId.Front, "コインロッカー", navy, white)
	for k, x in ipairs({ 18, 21, 24, 27 }) do
		bike(life, CFrame.new(SX + x, PLATFORM, SZ + 98), rng, k == 4)
	end
	part(life, "RepairCrate", Vector3.new(2, 1.6, 1.6), Vector3.new(SX + 32, PLATFORM + 0.8, SZ + 97), Wood, rgb(150, 112, 70))
	bike(life, CFrame.new(SX + 32, PLATFORM + 4.2, SZ + 97) * CFrame.Angles(0, 0, math.pi), rng)
	deco(part(life, "Toolbox", Vector3.new(1.6, 0.8, 0.8), Vector3.new(SX + 35, PLATFORM + 0.4, SZ + 95), Metal, rgb(190, 40, 34)))
	label(life, CFrame.new(SX + 34, PLATFORM + 4.5, SZ + 95.3) * CFrame.Angles(0, 0, math.rad(-4)), Vector3.new(4, 1.2, 0.1), Enum.NormalId.Front, "自転車なおします", rgb(220, 214, 196), rgb(30, 30, 34), Plywood, Enum.Font.PermanentMarker)
	rod(life, "SignStick", Vector3.new(SX + 34, PLATFORM, SZ + 95.4), Vector3.new(SX + 34, PLATFORM + 3.9, SZ + 95.4), 0.15, Wood, TIMBER)
	-- Planters under the hole in the roof at the west end.
	for _, x in ipairs({ -82, -76 }) do
		for _, z in ipairs({ 24, 29, 34 }) do
			Shacks.garden(camp, CFrame.new(SX + x, PLATFORM, SZ + z) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), 4, 2.2, rng, rng:NextNumber() < 0.2)
		end
	end
	upright(camp, "WateringCan", 1, 0.9, CFrame.new(SX - 70, PLATFORM, SZ + 27), 0, 0.5, 0, Metal, rgb(80, 150, 90))

	-- ----- The south platform: what was left behind -----
	local left = model(life, "LeftBehind")
	for k = 1, 6 do
		bike(left, CFrame.new(SX - 68 + k * 2.2 + rng:NextNumber(-0.5, 0.5), PLATFORM, SZ - 58 + rng:NextNumber(-3, 3)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), rng, rng:NextNumber() < 0.5)
	end
	for k = 1, 8 do
		local s3 = Vector3.new(rng:NextNumber(1.6, 2.6), rng:NextNumber(1.2, 2), rng:NextNumber(0.6, 1))
		local y = if k <= 4 then s3.Y / 2 else 2 + s3.Y / 2
		part(left, "Suitcase", s3, CFrame.new(SX + 44 + rng:NextNumber(-3, 3), PLATFORM + y, SZ - 62 + rng:NextNumber(-2, 2)) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.15, 0.15)), Smooth, pick({ rgb(120, 40, 40), rgb(40, 50, 80), rgb(60, 60, 64), rgb(170, 140, 90), rgb(90, 120, 110) }, rng))
	end
	-- The name board off its posts, face up.
	local fallen = CFrame.new(SX - 26, PLATFORM + 0.5, SZ - 54) * CFrame.Angles(math.rad(-78), 0.3, 0)
	label(left, fallen, Vector3.new(8, 3, 0.2), Enum.NormalId.Back, "かんのん\nKANNON", white, rgb(20, 20, 22), Smooth, Enum.Font.GothamBold).CanCollide = true
	for _ = 1, 10 do
		local s3 = Vector3.new(rng:NextNumber(1, 2.4), rng:NextNumber(0.8, 1.8), rng:NextNumber(1, 2.4))
		part(left, "Box", s3, CFrame.new(SX + rng:NextNumber(-80, 80), PLATFORM + s3.Y / 2, SZ - rng:NextNumber(44, 72)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, jitter(CARD, rng, 0.1))
	end
	for _, pos in ipairs({ Vector3.new(SX - 4, PLATFORM, SZ - 50), Vector3.new(SX + 58, PLATFORM, SZ - 66) }) do
		local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		deco(part(left, "Trolley", Vector3.new(1.8, 1.8, 2.6), cf * CFrame.new(0, 1.9, 0), Metal, STEEL)).Transparency = 0.4
		for _, dx in ipairs({ -0.8, 0.8 }) do
			for _, dz in ipairs({ -1.1, 1.1 }) do
				deco(rod(left, "TrolleyLeg", (cf * CFrame.new(dx, 0.2, dz)).Position, (cf * CFrame.new(dx, 1, dz)).Position, 0.1, Metal, STEEL))
			end
		end
	end
	upright(left, "UmbrellaStand", 2.2, 1.6, CFrame.new(SX + 16, PLATFORM, SZ - 74), 0, 1.1, 0, Metal, rgb(90, 110, 90))
	for k = 1, 6 do
		local a0 = Vector3.new(SX + 16, PLATFORM + 0.6, SZ - 74)
		deco(rod(left, "Umbrella", a0, a0 + Vector3.new(rng:NextNumber(-0.8, 0.8), 3.2, rng:NextNumber(-0.8, 0.8)), 0.3, Smooth, pick({ rgb(30, 30, 34), rgb(236, 236, 240), rgb(40, 60, 120), rgb(160, 40, 40) }, rng)))
	end
	-- The message board by the gates.
	local mb = model(left, "MessageBoard")
	local bcf = CFrame.new(SX + 30, PLATFORM, SZ - 70)
	part(mb, "Board", Vector3.new(11, 5.5, 0.3), bcf * CFrame.new(0, 4.6, 0), Wood, rgb(44, 70, 54))
	part(mb, "BoardFrame", Vector3.new(11.6, 0.4, 0.5), bcf * CFrame.new(0, 7.5, 0), Wood, rgb(120, 84, 56))
	for _, dx in ipairs({ -5, 5 }) do
		rod(mb, "BoardLeg", (bcf * CFrame.new(dx, 0, 0.3)).Position, (bcf * CFrame.new(dx, 7.4, 0.3)).Position, 0.3, Wood, rgb(120, 84, 56))
	end
	label(mb, bcf * CFrame.new(0, 8.4, 0), Vector3.new(4, 1.2, 0.1), Enum.NormalId.Front, "伝言板", white, navy)
	local notes = {
		"ミカへ 西の団地にいます —母", "水は屋上のタンクから", "無事です！ 北ホーム3番テント",
		"TOMO — gone to the harbour. come find us", "ケンジ、待ってるよ", "観音さまが見てる", "薬あります 交換で",
	}
	for i, note in ipairs(notes) do
		local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
		label(mb, bcf * CFrame.new(-2.7 + col * 5.4 + rng:NextNumber(-0.3, 0.3), 6.5 - row * 1.25, -0.17) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-4, 4))), Vector3.new(5, 0.9, 0.02), Enum.NormalId.Front, note, white, rgb(236, 236, 226), Smooth, Enum.Font.PatrickHand).Transparency = 1
	end
	-- The shrine at the stair foot.
	local sh = model(left, "Offerings")
	local ox, oz = SX - 32, SZ - A + 5
	box(sh, "OfferingTable", ox - 4, ox + 4, PLATFORM, PLATFORM + 2.6, oz - 1.2, oz + 1.2, Wood, rgb(120, 80, 50))
	part(sh, "TableCloth", Vector3.new(8.2, 0.1, 2.6), Vector3.new(ox, PLATFORM + 2.65, oz), Fabric, rgb(236, 230, 220))
	deco(ellipsoid(sh, "LittleKannon", Vector3.new(1.1, 2.6, 0.9), CFrame.new(ox, PLATFORM + 4, oz + 0.4), Concrete, rgb(206, 200, 188)))
	deco(ellipsoid(sh, "LittleKannonHead", Vector3.new(0.6, 0.7, 0.6), CFrame.new(ox, PLATFORM + 5.5, oz + 0.4), Concrete, rgb(206, 200, 188)))
	for k = 0, 5 do
		local cx = ox - 3 + k * 1.2
		deco(upright(sh, "Candle", 0.6 + (k % 3) * 0.2, 0.25, CFrame.new(cx, PLATFORM + 2.7, oz - 0.6), 0, 0.35, 0, Smooth, white))
		deco(ellipsoid(sh, "CandleFlame", Vector3.new(0.14, 0.3, 0.14), CFrame.new(cx, PLATFORM + 3.4 + (k % 3) * 0.2, oz - 0.6), Neon, rgb(255, 190, 90)))
	end
	glow(sh:FindFirstChild("CandleFlame"), 12, rgb(255, 180, 100))
	for _, x in ipairs({ -3.4, 3.4 }) do
		deco(upright(sh, "FlowerCup", 0.8, 0.6, CFrame.new(ox + x, PLATFORM + 2.7, oz + 0.3), 0, 0.4, 0, Glass, rgb(180, 200, 200)))
		for _ = 1, 4 do
			deco(ellipsoid(sh, "Flower", Vector3.one * 0.35, CFrame.new(ox + x + rng:NextNumber(-0.3, 0.3), PLATFORM + 3.7 + rng:NextNumber(0, 0.5), oz + 0.3 + rng:NextNumber(-0.3, 0.3)), Smooth, pick({ rgb(240, 200, 60), rgb(230, 230, 236), rgb(220, 90, 120), rgb(160, 90, 200) }, rng)))
		end
	end
	for k = 0, 4 do
		deco(part(sh, "Photo", Vector3.new(0.7, 0.9, 0.04), CFrame.new(ox - 2.2 + k * 1.1, PLATFORM + 3.1, oz + 0.9) * CFrame.Angles(math.rad(-15), 0, math.rad(rng:NextNumber(-8, 8))), Smooth, pick({ rgb(236, 232, 222), rgb(200, 190, 170) }, rng)))
	end
	label(sh, CFrame.new(ox, PLATFORM + 1.6, oz - 1.25), Vector3.new(4, 1, 0.05), Enum.NormalId.Front, "観音さまへ", rgb(236, 230, 220), rgb(120, 30, 30), Smooth, Enum.Font.PatrickHand)
	-- Strings of paper cranes, hung over it from a bar.
	local barY = PLATFORM + 11
	rod(sh, "CraneBar", Vector3.new(ox - 4, barY, oz), Vector3.new(ox + 4, barY, oz), 0.2, Wood, TIMBER)
	for _, x in ipairs({ ox - 4, ox + 4 }) do
		rod(sh, "CranePost", Vector3.new(x, PLATFORM + 2.6, oz - 1), Vector3.new(x, barY + 0.2, oz), 0.2, Wood, TIMBER)
	end
	local crane = { rgb(220, 60, 60), rgb(240, 160, 60), rgb(240, 220, 80), rgb(90, 180, 90), rgb(70, 140, 220), rgb(150, 90, 200), rgb(240, 140, 180) }
	for k = 0, 6 do
		local x = ox - 3.3 + k * 1.1
		deco(rod(sh, "CraneString", Vector3.new(x, barY, oz), Vector3.new(x, barY - 6.4, oz), 0.03, Fabric, white))
		for j = 0, 9 do
			deco(part(sh, "Crane", Vector3.new(0.5, 0.12, 0.3), CFrame.new(x, barY - 0.5 - j * 0.6, oz) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, crane[(k + j) % #crane + 1]))
		end
	end

	-- ----- Pigeons -----
	for _ = 1, 16 do
		local s = pick({ -1, 1 }, rng)
		pigeon(life, Vector3.new(SX + rng:NextNumber(-80, 80), PLATFORM, SZ + s * rng:NextNumber(7, 13)), rng)
	end
	for _ = 1, 6 do
		pigeon(life, Vector3.new(SX + pick({ 52.15, 57.85 }, rng), PLATFORM + 17 + 3.3 + 0.05, SZ + rng:NextNumber(-9, 9)), rng)
	end
	-- A fallen platform sign down on the track at the west end.
	label(life, CFrame.new(SX - 80, RAIL + 0.6, SZ + 1) * CFrame.Angles(math.rad(-70), 0.4, 0), Vector3.new(4, 2, 0.2), Enum.NormalId.Back, "1番線", rgb(20, 20, 22), white, Smooth, Enum.Font.GothamBold).CanCollide = true
end

-- ===== The station in the hall =====

local function station(parent, rng)
	local st = model(parent, "Station")
	local slab = rgb(138, 134, 124)
	local grime = rgb(70, 66, 58)
	local white = rgb(236, 234, 226)
	local navy = rgb(30, 60, 120)
	octFloor(st, "TrackBed", RAIL, 1, 3, nil, nil, Concrete, rgb(84, 80, 72))
	octFloor(st, "Platform", PLATFORM, PLATFORM - RAIL, 3, function(z)
		return math.abs(z) > 6.2
	end, nil, Concrete, slab)
	local ex = A - 4
	for _, s in ipairs({ 1, -1 }) do
		-- The platform edge: a white line, the yellow tactile strip, the
		-- coping crumbling away here and there.
		box(st, "EdgeLine", SX - ex + 8, SX + ex - 8, PLATFORM, PLATFORM + 0.05, SZ + s * 6.5, SZ + s * 6.9, Smooth, white)
		local x = SX - ex + 8
		while x < SX + ex - 8 do
			local len = rng:NextNumber(6, 16)
			if rng:NextNumber() < 0.85 then
				box(st, "Tactile", x, math.min(x + len, SX + ex - 8), PLATFORM, PLATFORM + 0.07, SZ + s * 7.6, SZ + s * 8.6, Smooth, jitter(rgb(220, 190, 50), rng, 0.12))
			end
			x += len + rng:NextNumber(0, 2)
		end
		for _ = 1, 6 do
			local cx = SX + rng:NextNumber(-ex + 12, ex - 12)
			deco(box(st, "Chipped", cx - rng:NextNumber(0.6, 2), cx + rng:NextNumber(0.6, 2), PLATFORM - 0.6, PLATFORM + 0.02, SZ + s * 6.15, SZ + s * 6.6, Concrete, rgb(96, 92, 84)))
			deco(part(st, "Chunk", Vector3.new(rng:NextNumber(0.6, 1.4), 0.5, rng:NextNumber(0.5, 1.1)), CFrame.new(cx + rng:NextNumber(-2, 2), RAIL + 0.45, SZ + s * rng:NextNumber(4, 5.8)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), 0), Concrete, slab))
		end
		for _, e in ipairs({ -1, 1 }) do
			local rx = SX + e * (ex - 2)
			rail(st, Vector3.new(rx, PLATFORM, SZ + s * 6.2), Vector3.new(rx, PLATFORM, SZ + s * 12))
		end
		-- Station name boards standing on the platform, platform numbers
		-- hung over it.
		for _, bx in ipairs({ -52, 44 }) do
			local cf = CFrame.new(SX + bx, PLATFORM, SZ + s * 14) * CFrame.Angles(0, if s > 0 then math.pi else 0, 0)
			for _, dx in ipairs({ -3.4, 3.4 }) do
				rod(st, "BoardPost", (cf * CFrame.new(dx, 0, 0)).Position, (cf * CFrame.new(dx, 7.4, 0)).Position, 0.3, Metal, rgb(90, 92, 94))
			end
			label(st, cf * CFrame.new(0, 6, 0), Vector3.new(8, 3, 0.2), Enum.NormalId.Front, "かんのん\nKANNON", white, rgb(20, 20, 22), Smooth, Enum.Font.GothamBold)
			label(st, cf * CFrame.new(0, 4.1, 0), Vector3.new(8, 0.8, 0.2), Enum.NormalId.Front, "← じょうかまち          みなと →", navy, white, Smooth, Enum.Font.GothamBold)
			-- dirt down its face
			deco(part(st, "BoardGrime", Vector3.new(rng:NextNumber(1, 3), rng:NextNumber(1, 2.5), 0.02), cf * CFrame.new(rng:NextNumber(-2.5, 2.5), 5.8, -0.12), Smooth, grime)).Transparency = 0.4
		end
		for _, hx in ipairs({ -20, 70 }) do
			local cf = CFrame.new(SX + hx, PLATFORM + 11, SZ + s * 11) * CFrame.Angles(0, if s > 0 then math.pi else 0, 0)
			label(st, cf, Vector3.new(4, 2, 0.2), Enum.NormalId.Front, if s > 0 then "2番線" else "1番線", rgb(20, 20, 22), white, Smooth, Enum.Font.GothamBold)
			for _, dx in ipairs({ -1.6, 1.6 }) do
				deco(rod(st, "SignHanger", (cf * CFrame.new(dx, 1, 0)).Position, Vector3.new((cf * CFrame.new(dx, 1, 0)).X, ROOF - 2, (cf * CFrame.new(dx, 1, 0)).Z), 0.1, Metal, STEEL))
			end
		end
		-- Benches, some broken or tipped; bins, one knocked over.
		for _, x in ipairs({ -64, -34, 22, 70 }) do
			local b = model(st, "Bench")
			local cf = CFrame.new(SX + x, PLATFORM, SZ + s * 17)
			if rng:NextNumber() < 0.25 then
				cf = cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(80 * s), rng:NextNumber(-0.3, 0.3), 0) * CFrame.new(0, -0.6, 0)
			end
			part(b, "BenchSeat", Vector3.new(6, 0.3, 1.6), cf * CFrame.new(0, 1.65, 0), Smooth, jitter(rgb(60, 100, 150), rng, 0.15))
			if rng:NextNumber() < 0.8 then
				part(b, "BenchBack", Vector3.new(6, 1.4, 0.2), cf * CFrame.new(0, 2.6, s * 0.75), Smooth, jitter(rgb(60, 100, 150), rng, 0.15))
			end
			for _, dx in ipairs({ -2.5, 2.5 }) do
				part(b, "BenchLeg", Vector3.new(0.3, 1.5, 1.2), cf * CFrame.new(dx, 0.75, 0), Metal, STEEL)
			end
		end
		for _, x in ipairs({ -45, 8, 40 }) do
			local cf = CFrame.new(SX + x, PLATFORM, SZ + s * 20)
			if rng:NextNumber() < 0.35 then
				upright(st, "Bin", 2, 1.4, cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, -0.7, 0), 0, 0, 0, Metal, rgb(90, 110, 90))
				for _ = 1, 5 do
					deco(part(st, "Litter", Vector3.new(rng:NextNumber(0.3, 0.9), 0.05, rng:NextNumber(0.3, 0.9)), cf * CFrame.new(rng:NextNumber(-2, 2), 0.03, rng:NextNumber(0.5, 3)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, pick({ white, rgb(200, 190, 150), rgb(200, 60, 50) }, rng)))
				end
			else
				upright(st, "Bin", 2, 1.4, cf, 0, 1, 0, Metal, rgb(90, 110, 90))
			end
		end
		-- Posters on the walls behind, faded and peeling.
		for _ = 1, 8 do
			local x = rng:NextNumber(-38, 38)
			local wallZ = s * (A - 3.1)
			local p = CFrame.new(SX + x, PLATFORM + rng:NextNumber(5, 8), SZ + wallZ) * CFrame.Angles(0, if s > 0 then math.pi else 0, 0)
			local poster = part(st, "Poster", Vector3.new(rng:NextNumber(3, 5), rng:NextNumber(4, 6), 0.05), p, Smooth, jitter(pick({ rgb(200, 150, 140), rgb(150, 170, 200), rgb(210, 200, 150), rgb(180, 190, 170) }, rng), rng, 0.1))
			deco(poster)
			if rng:NextNumber() < 0.5 then
				deco(part(st, "PeeledCorner", Vector3.new(1.2, 1.2, 0.05), p * CFrame.new(rng:NextNumber(-1, 1), -1.5, -0.2) * CFrame.Angles(math.rad(-30), 0, math.rad(20)), Smooth, white))
			end
		end
	end
	-- Graffiti, here and there.
	local tags = { "ここにいた", "帰りたい", "LOST", "月", "まだ待ってる", "NO TRAINS", "観音さま", "HELLO?" }
	for _ = 1, 7 do
		local s = pick({ -1, 1 }, rng)
		local x = rng:NextNumber(-38, 38)
		label(st, CFrame.new(SX + x, PLATFORM + rng:NextNumber(2, 4), SZ + s * (A - 3.12)) * CFrame.Angles(0, if s > 0 then math.pi else 0, math.rad(rng:NextNumber(-8, 8))), Vector3.new(rng:NextNumber(6, 10), 2.2, 0.03), Enum.NormalId.Front, pick(tags, rng), slab, pick({ rgb(200, 40, 60), rgb(40, 60, 200), rgb(30, 30, 30), rgb(240, 200, 40) }, rng), Smooth, Enum.Font.PermanentMarker).Transparency = 1
	end
	-- The ceiling: long light troughs hung on wires, nearly all dead, a few
	-- hanging askew; cables down; panels fallen.
	for x = -84, 84, 21 do
		for _, z in ipairs({ -40, -16, 16, 40 }) do
			local fall = rng:NextNumber() < 0.15
			local cf = CFrame.new(SX + x, ROOF - 8, SZ + z)
			if fall then
				cf = cf * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, math.rad(pick({ -1, 1 }, rng) * rng:NextNumber(20, 40)))
			end
			local lit = not fall and rng:NextNumber() < 0.14
			local trough = part(st, "LightTrough", Vector3.new(8, 0.5, 1), cf, if lit then Neon else Smooth, if lit then rgb(236, 236, 226) else rgb(150, 150, 146))
			trough.CanCollide = false
			if lit then
				glow(trough, 26, rgb(226, 230, 220))
				if rng:NextNumber() < 0.5 then
					trough:AddTag("FlickerLight")
				end
			end
			for _, dx in ipairs({ -3, 3 }) do
				if not (fall and dx > 0) then
					deco(rod(st, "LightWire", (cf * CFrame.new(dx, 0.25, 0)).Position, Vector3.new((cf * CFrame.new(dx, 0, 0)).X, ROOF - 2, (cf * CFrame.new(dx, 0, 0)).Z), 0.06, Metal, DARK))
				end
			end
		end
	end
	for _ = 1, 14 do
		local x, z = rng:NextNumber(-90, 90), rng:NextNumber(-90, 90)
		if octHalf(z, 6) > math.abs(x) and math.abs(z) > 8 then
			local len = rng:NextNumber(4, 16)
			deco(rod(st, "HangingCable", Vector3.new(SX + x, ROOF - 2, SZ + z), Vector3.new(SX + x + rng:NextNumber(-2, 2), ROOF - 2 - len, SZ + z + rng:NextNumber(-2, 2)), 0.12, Smooth, DARK))
		end
	end
	for _ = 1, 12 do
		local x, z = rng:NextNumber(-90, 90), rng:NextNumber(-95, 95)
		if octHalf(z, 6) > math.abs(x) and math.abs(z) > 8 then
			part(st, "FallenPanel", Vector3.new(4, 0.2, 4), CFrame.new(SX + x, PLATFORM + 0.3, SZ + z) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)), Smooth, rgb(190, 186, 176))
		end
	end
	-- The west end of the roof has come in: a pile of rubble on the
	-- platform ends, daylight and vines through the hole.
	for _ = 1, 14 do
		local s = Vector3.new(rng:NextNumber(2, 6), rng:NextNumber(1, 4), rng:NextNumber(2, 6))
		part(st, "Rubble", s, CFrame.new(SX - 96 + rng:NextNumber(-8, 6), PLATFORM + s.Y * 0.35, SZ + pick({ -1, 1 }, rng) * rng:NextNumber(14, 34)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Concrete, jitter(slab, rng, 0.1))
	end
	for _ = 1, 8 do
		local top = Vector3.new(SX - 96 + rng:NextNumber(-7, 7), ROOF - 2, SZ + rng:NextNumber(-9, 9))
		local len = rng:NextNumber(10, 26)
		deco(rod(st, "Vine", top, top - Vector3.new(0, len, 0), 0.35, Wood, rgb(70, 90, 50)))
		deco(ellipsoid(st, "Leaves", Vector3.new(3, 2.4, 3), CFrame.new(top - Vector3.new(0, len, 0)), Enum.Material.LeafyGrass, jitter(rgb(80, 120, 60), rng, 0.15)))
	end
	-- Weeds on the platforms and along the track, puddles where it leaks.
	for _ = 1, 26 do
		local x, z = rng:NextNumber(-95, 95), rng:NextNumber(-95, 95)
		if octHalf(z, 6) > math.abs(x) then
			local holder = model(st, "Growth")
			local onTrack = math.abs(z) < 6
			local c = Vector3.new(SX + x, if onTrack then RAIL else PLATFORM, SZ + (if onTrack then z * 0.5 else z))
			if onTrack or rng:NextNumber() < 0.5 then
				Clutter.weeds(holder, c, rng)
			else
				Clutter.puddle(holder, c, rng)
			end
		end
	end
	-- A clock stopped long ago; the departure board.
	local clockCF = CFrame.new(SX + 14, PLATFORM + 9, SZ + 13) * CFrame.Angles(0, math.pi / 2, 0)
	local clock = cylinder(st, "Clock", 0.3, 3, clockCF, Smooth, white)
	deco(clock)
	deco(part(st, "HourHand", Vector3.new(0.12, 0.8, 0.05), CFrame.new(SX + 14, PLATFORM + 9, SZ + 12.8) * CFrame.Angles(0, 0, math.rad(-125)) * CFrame.new(0, 0.4, 0), Smooth, DARK))
	deco(part(st, "MinuteHand", Vector3.new(0.08, 1.2, 0.05), CFrame.new(SX + 14, PLATFORM + 9, SZ + 12.8) * CFrame.Angles(0, 0, math.rad(-72)) * CFrame.new(0, 0.6, 0), Smooth, DARK))
	rod(st, "ClockPost", Vector3.new(SX + 14, PLATFORM, SZ + 13.3), Vector3.new(SX + 14, PLATFORM + 7.5, SZ + 13.3), 0.25, Metal, DARK)
	label(st, CFrame.new(SX - 12, PLATFORM + 9, SZ + 13.5) * CFrame.Angles(0, math.pi, 0), Vector3.new(8, 2.6, 0.2), Enum.NormalId.Front, "運転見合わせ\n-- : --", rgb(20, 20, 22), rgb(250, 160, 60), Smooth, Enum.Font.Code)
	-- A waiting room on the north platform: a glass box gone grey, its
	-- benches, a door off its runner.
	local wr = model(st, "WaitingRoom")
	local wx0, wx1, wz0, wz1 = SX - 20, SX - 4, SZ + 24, SZ + 34
	box(wr, "WaitingFrame", wx0, wx1, PLATFORM + 8, PLATFORM + 8.6, wz0, wz1, Metal, rgb(90, 92, 94))
	for _, w in ipairs({ { wx0, wx1, wz0, wz0 + 0.2 }, { wx0, wx0 + 0.2, wz0, wz1 }, { wx1 - 0.2, wx1, wz0, wz1 }, { wx0, wx1 - 6, wz1 - 0.2, wz1 } }) do
		local g = box(wr, "WaitingGlass", w[1], w[2], PLATFORM, PLATFORM + 8, w[3], w[4], Glass, rgb(150, 160, 160))
		g.Transparency = 0.55
	end
	part(wr, "SlidingDoor", Vector3.new(4, 7.6, 0.2), CFrame.new(wx1 - 3, PLATFORM + 3.6, wz1 + 0.6) * CFrame.Angles(0, 0, math.rad(8)), Glass, rgb(150, 160, 160)).Transparency = 0.55
	box(wr, "WaitingBench", wx0 + 1, wx1 - 1, PLATFORM + 1.5, PLATFORM + 1.8, wz0 + 0.6, wz0 + 2, Smooth, rgb(150, 60, 50))
	box(wr, "WaitingBenchBase", wx0 + 1, wx1 - 1, PLATFORM, PLATFORM + 1.5, wz0 + 1, wz0 + 1.8, Metal, STEEL)
	lootSpot(wr, Vector3.new(wx0 + 4, PLATFORM, wz0 + 6))
	-- A footbridge over the track between the two platforms.
	local fb = model(st, "Footbridge")
	local bx0, bx1 = SX + 52, SX + 58
	local deckY = PLATFORM + 17
	for _, s in ipairs({ 1, -1 }) do
		local zNear, zFar = SZ + s * 10, SZ + s * 36
		local n = math.ceil(17 / 0.75)
		for i = 1, n do
			local za = zFar + (zNear - zFar) * (i - 1) / n
			local zb = zFar + (zNear - zFar) * i / n
			local top = PLATFORM + 17 * i / n
			box(fb, "Step", bx0, bx1, top - 0.35, top, za, zb + s * -0.02, Concrete, rgb(150, 146, 136))
		end
		for _, x in ipairs({ bx0 + 0.15, bx1 - 0.15 }) do
			rail(fb, Vector3.new(x, PLATFORM, zFar), Vector3.new(x, deckY, zNear))
		end
		for _, x in ipairs({ bx0, bx1 }) do
			rod(fb, "StairPier", Vector3.new(x, PLATFORM, (zNear + zFar) / 2), Vector3.new(x, PLATFORM + 8, (zNear + zFar) / 2), 0.5, Metal, rgb(90, 92, 94))
		end
	end
	box(fb, "Span", bx0, bx1, deckY - 0.5, deckY, SZ - 10, SZ + 10, Concrete, rgb(150, 146, 136))
	for _, x in ipairs({ bx0 + 0.15, bx1 - 0.15 }) do
		rail(fb, Vector3.new(x, deckY, SZ - 10), Vector3.new(x, deckY, SZ + 10))
	end
	box(fb, "SpanGirder", bx0, bx1, deckY - 2, deckY - 0.5, SZ - 10, SZ + 10, Metal, rgb(90, 92, 94))
	label(fb, CFrame.new((bx0 + bx1) / 2, deckY - 1.25, SZ - 10.1), Vector3.new(6, 1.5, 0.1), Enum.NormalId.Front, "1 ⇄ 2", navy, white)
	-- Dead ticket machines and gates at the foot of the stairs up.
	local gz = SZ - 78
	for k = -4, 4 do
		if k ~= 0 then
			local tilt = if rng:NextNumber() < 0.15 then CFrame.Angles(math.rad(rng:NextNumber(-60, 60)), 0, 0) else CFrame.identity
			part(st, "TicketGate", Vector3.new(1, 3.4, 3.2), CFrame.new(SX + k * 3, PLATFORM + 1.7, gz) * tilt, Metal, rgb(170, 170, 166))
		end
	end
	label(st, CFrame.new(SX, PLATFORM + 7.5, gz), Vector3.new(12, 1.4, 0.2), Enum.NormalId.Back, "改札口  出口 ↓", navy, white)
	for k = 0, 3 do
		local mx = SX - 26 + k * 3.4
		box(st, "TicketMachine", mx - 1.5, mx + 1.5, PLATFORM, PLATFORM + 5, SZ - 84, SZ - 82, Metal, rgb(200, 200, 196))
		deco(box(st, "MachineScreen", mx - 1, mx + 1, PLATFORM + 3, PLATFORM + 4.2, SZ - 81.99, SZ - 81.9, Glass, rgb(30, 34, 36)))
	end
	label(st, CFrame.new(SX - 21, PLATFORM + 7.5, SZ - 82.9), Vector3.new(14, 3, 0.2), Enum.NormalId.Back, "運賃表  FARES", white, navy)
	-- The vending machines, dark, one pushed over; a kiosk shuttered.
	for k = 0, 1 do
		local vx = SX + 22 + k * 3.6
		local cf = CFrame.new(vx, PLATFORM, SZ - 30)
		if k == 1 then
			cf = cf * CFrame.new(0, 1.2, -2) * CFrame.Angles(math.rad(-86), 0, 0) * CFrame.new(0, -1.2, 0)
		end
		part(st, "VendingMachine", Vector3.new(3.4, 6, 2.4), cf * CFrame.new(0, 3, 0), Metal, pick({ rgb(160, 60, 50), rgb(60, 90, 140) }, rng))
		deco(part(st, "VendingDisplay", Vector3.new(2.8, 2.6, 0.1), cf * CFrame.new(0, 4.1, 1.22), Glass, rgb(40, 44, 46)))
	end
	box(st, "KioskShutter", SX - 44, SX - 34, PLATFORM, PLATFORM + 7, SZ - 30.2, SZ - 30, Metal, rgb(150, 152, 146))
	box(st, "KioskBody", SX - 44, SX - 34, PLATFORM, PLATFORM + 7.4, SZ - 36, SZ - 30.2, Smooth, rgb(200, 190, 170))
	label(st, CFrame.new(SX - 39, PLATFORM + 6, SZ - 29.9), Vector3.new(8, 1, 0.1), Enum.NormalId.Back, "KIOSK", rgb(40, 100, 160), white)
	-- One camp at the east end, where somebody still sleeps.
	local camp = model(st, "Camp")
	local cx, kz = SX + 76, SZ - 40
	for _, s in ipairs({ -1, 1 }) do
		rod(camp, "TentPole", Vector3.new(cx + s * 3, PLATFORM, kz), Vector3.new(cx, PLATFORM + 5, kz), 0.15, Wood, TIMBER)
		part(camp, "Tent", Vector3.new(0.1, 5.5, 6), CFrame.new(cx + s * 1.5, PLATFORM + 2.4, kz) * CFrame.Angles(0, 0, math.rad(s * 31)), Fabric, rgb(60, 110, 150))
	end
	part(camp, "Futon", Vector3.new(5, 0.4, 3), Vector3.new(cx, PLATFORM + 0.2, kz + 5), Fabric, rgb(222, 216, 200))
	upright(camp, "Stove", 0.8, 1.4, CFrame.new(cx + 5, PLATFORM, kz + 3), 0, 0.4, 0, Metal, DARK)
	local l = ellipsoid(camp, "Lantern", Vector3.new(0.8, 1.1, 0.8), CFrame.new(cx + 2.5, PLATFORM + 0.6, kz + 3.5), Neon, rgb(240, 150, 90))
	l.CanCollide = false
	glow(l, 12)
	lootSpot(camp, Vector3.new(cx - 1, PLATFORM, kz - 5))
	-- Lost things.
	deco(box(st, "Suitcase", SX + 4, SX + 6.4, PLATFORM, PLATFORM + 1.6, SZ + 16, SZ + 17, Smooth, rgb(120, 40, 40)))
	deco(rod(st, "Umbrella", Vector3.new(SX - 6, PLATFORM + 0.2, SZ - 9), Vector3.new(SX - 3, PLATFORM + 0.3, SZ - 10), 0.2, Smooth, rgb(30, 30, 34)))
	-- The stairs up to the roof terrace: two flights along the south wall.
	local st2 = model(st, "RoofStairs")
	local function flight(xa, xb, za, zb, ya, yb)
		local n = math.ceil(math.abs(yb - ya) / 0.8)
		for i = 1, n do
			local x0 = xa + (xb - xa) * (i - 1) / n
			local x1 = xa + (xb - xa) * i / n
			local top = ya + (yb - ya) * i / n
			box(st2, "Step", x0, x1 + (if xb > xa then 0.02 else -0.02), top - 0.5, top, za, zb, Concrete, darken(HALL, 0.9))
		end
	end
	local midY = (PLATFORM + ROOF) / 2
	flight(SX - 20, SX + 20, SZ - 99, SZ - 93, PLATFORM, midY)
	box(st2, "Landing", SX + 20, SX + 26, midY - 0.5, midY, SZ - 99, SZ - 87, Concrete, darken(HALL, 0.9))
	flight(SX + 20, SX - 20, SZ - 93, SZ - 87, midY, ROOF)
	rail(st2, Vector3.new(SX - 20, PLATFORM, SZ - 98.8), Vector3.new(SX + 20, midY, SZ - 98.8))
	rail(st2, Vector3.new(SX + 20, midY, SZ - 93.1), Vector3.new(SX - 20, ROOF, SZ - 93.1))
	rail(st2, Vector3.new(SX + 20, midY, SZ - 87.1), Vector3.new(SX - 20, ROOF, SZ - 87.1))
	rail(st2, Vector3.new(SX + 26, midY, SZ - 87.2), Vector3.new(SX + 20, midY, SZ - 87.2))
	rail(st2, Vector3.new(SX + 6, ROOF, SZ - 86.8), Vector3.new(SX - 20, ROOF, SZ - 86.8))
	rail(st2, Vector3.new(SX + 6, ROOF, SZ - 93.2), Vector3.new(SX - 20, ROOF, SZ - 93.2))
	rail(st2, Vector3.new(SX + 6.2, ROOF, SZ - 93.2), Vector3.new(SX + 6.2, ROOF, SZ - 86.8))
	label(st2, CFrame.new(SX - 26, PLATFORM + 6, SZ - 96), Vector3.new(0.2, 1.4, 6), Enum.NormalId.Right, "出口 ↑", navy, white)
	stationLife(st, rng)
end

-- ===== The pilgrims' bridge from the gym =====

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }

local function torii(parent, cf, w, h, scrap, rng)
	local red = rgb(200, 60, 40)
	for _, s in ipairs({ -1, 1 }) do
		if scrap then
			-- Scaffold pipe, painted red once, lashed where it was joined.
			rod(parent, "ToriiPillar", (cf * CFrame.new(s * w / 2, 0, 0)).Position, (cf * CFrame.new(s * w / 2, h, 0)).Position, 0.9, Metal, pick({ red, rgb(170, 70, 50) }, rng))
			for _ = 1, 3 do
				deco(upright(parent, "Lashing", 0.4, 1.05, cf, s * w / 2, rng:NextNumber(2, h - 2), 0, Fabric, rgb(170, 150, 110)))
			end
		else
			cylinder(parent, "ToriiPillar", h, 1.2, cf * CFrame.new(s * w / 2, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Smooth, red)
		end
	end
	if scrap then
		-- A rusted girder for the top beam, a plank under it, a pipe
		-- through.
		part(parent, "Kasagi", Vector3.new(w + 4, 0.9, 1.4), cf * CFrame.new(0, h + 0.3, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-3, 3))), Corroded, rgb(110, 70, 50))
		part(parent, "Shimaki", Vector3.new(w + 2.5, 0.8, 1), cf * CFrame.new(0, h - 0.5, 0), Wood, jitter(rgb(150, 70, 50), rng, 0.1))
		rod(parent, "Nuki", (cf * CFrame.new(-w / 2 - 1, h - 2.6, 0)).Position, (cf * CFrame.new(w / 2 + 1, h - 2.6, 0)).Position, 0.5, Metal, STEEL)
	else
		part(parent, "Kasagi", Vector3.new(w + 4, 0.9, 1.6), cf * CFrame.new(0, h + 0.3, 0), Smooth, DARK)
		part(parent, "Shimaki", Vector3.new(w + 3, 0.8, 1.3), cf * CFrame.new(0, h - 0.5, 0), Smooth, red)
		part(parent, "Nuki", Vector3.new(w + 1.5, 0.6, 0.8), cf * CFrame.new(0, h - 2.6, 0), Smooth, red)
	end
	-- A straw rope with paper streamers across, under the beam.
	local prev = (cf * CFrame.new(-w / 2, h - 3.4, 0)).Position
	for k = 1, 6 do
		local t = k / 6
		local q = (cf * CFrame.new(-w / 2 + w * t, h - 3.4 - 1 * 4 * t * (1 - t), 0)).Position
		deco(rod(parent, "Shimenawa", prev, q, 0.45, Fabric, rgb(200, 180, 120)))
		if k < 6 and k % 2 == 1 then
			for j = 0, 2 do
				deco(part(parent, "Shide", Vector3.new(0.4, 0.5, 0.03), CFrame.new(q + Vector3.new(0, -0.5 - j * 0.45, 0)) * cf.Rotation * CFrame.Angles(0, 0, if j % 2 == 0 then 0.3 else -0.3), Smooth, rgb(246, 246, 240)))
			end
		end
		prev = q
	end
end

-- One length of the bridge's handrail from p0 to p1 (at deck level), in
-- whatever was to hand: timber, scaffold pipe, a bit of fence, a sheet of
-- roofing, rope. All of it solid enough to lean on.
local function railSeg(parent, p0, p1, style, rng, last)
	local up = Vector3.yAxis
	local len = (p1 - p0).Magnitude
	if style == "sheet" then
		local mid = (p0 + p1) / 2 + up * 1.6
		part(parent, "SheetRail", Vector3.new(0.15, 3.2, len + 0.1), CFrame.lookAt(mid, mid + (p1 - p0)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-5, 5))), Corroded, pick({ rgb(120, 90, 70), rgb(90, 110, 120), rgb(150, 120, 70), rgb(170, 70, 50) }, rng))
		return
	end
	local mat, col, dia, h = Wood, jitter(TIMBER, rng, 0.1), 0.22, 3.3
	if style == "pipe" or style == "fence" then
		mat, col, dia, h = Metal, pick({ STEEL, rgb(200, 170, 40), rgb(170, 60, 40), rgb(60, 110, 70) }, rng), 0.2, rng:NextNumber(3, 3.6)
	elseif style == "rope" then
		dia, h = 0.26, 3.2
	end
	local posts = { p0 }
	if last then
		table.insert(posts, p1)
	end
	for _, p in ipairs(posts) do
		rod(parent, "RailPost", p - up * 0.3, p + up * 3.75, dia + 0.06, mat, col)
	end
	if style == "rope" then
		for _, hh in ipairs({ h, h * 0.55 }) do
			local prev = p0 + up * hh
			for k = 1, 4 do
				local t = k / 4
				local q = p0:Lerp(p1, t) + up * (hh - 0.5 * 4 * t * (1 - t))
				rod(parent, "RailRope", prev, q, 0.14, Fabric, rgb(190, 170, 120))
				prev = q
			end
		end
		return
	end
	rod(parent, "RailBar", p0 + up * h, p1 + up * h, dia, mat, col)
	rod(parent, "RailBar", p0 + up * h * 0.5, p1 + up * h * 0.5, dia * 0.9, mat, col)
	if style == "fence" then
		local n = math.floor(len / 0.6)
		for k = 1, n - 1 do
			local q = p0:Lerp(p1, k / n)
			deco(rod(parent, "Baluster", q + up * 0.1, q + up * h, 0.08, Metal, col))
		end
	end
end

-- The pilgrims' bridge from the gym to the hall roof: patched together
-- out of whatever there was. Planks of every age, a door or two, sheets
-- of roofing and a pallet in the deck; the handrail a different thing
-- every few steps; one pier concrete, the other a scaffold trestle; a
-- hose running along it, cables stayed off the torii, ema tied on near
-- the far end, prayer flags overhead.
local function pilgrimBridge(parent, rng)
	local b = model(parent, "PilgrimBridge")
	local edgeZ = -203
	local hit = workspace:Raycast(Vector3.new(SX, 150, edgeZ + 3), Vector3.new(0, -400, 0), terrainOnly)
	local groundY = math.clamp(if hit then hit.Position.Y else ROOF, ROOF - 20, ROOF + 20)
	local a = Vector3.new(SX, groundY, edgeZ + 2)
	local c = Vector3.new(SX, ROOF, SZ + A - 1)
	workspace.Terrain:FillBall(Vector3.new(SX, groundY - 6, edgeZ + 1), 9, Enum.Material.Rock)
	local dir = (c - a).Unit
	local len = (c - a).Magnitude
	local frame = CFrame.lookAt(a, c)
	local right = frame.RightVector
	local up = Vector3.yAxis
	-- It sags a little in the middle.
	local SAG = 1.4
	local function deckAt(t)
		return a:Lerp(c, t) - up * (SAG * 4 * t * (1 - t))
	end

	-- Under the deck: two stringers, each length something different, a
	-- crosspiece lashed under every joint.
	local n = 8
	for i = 1, n do
		local t0, t1 = (i - 1) / n, i / n
		for _, s in ipairs({ -1, 1 }) do
			local lat = s * (3.4 + (i % 2) * 0.12)
			local p0, p1 = deckAt(t0) + right * lat - up, deckAt(t1) + right * lat - up
			local cf, l = CFrame.lookAt((p0 + p1) / 2, p1), (p1 - p0).Magnitude
			local kind = rng:NextNumber()
			if kind < 0.45 then
				part(b, "Stringer", Vector3.new(0.7, 1.3, l + 0.5), cf, Corroded, jitter(rgb(116, 76, 48), rng, 0.1))
			elseif kind < 0.8 then
				part(b, "Stringer", Vector3.new(0.8, 1.2, l + 0.5), cf, Wood, jitter(TIMBER, rng, 0.1))
			else
				local e = dir * 0.3
				rod(b, "StringerTube", p0 - e + up * 0.3, p1 + e + up * 0.3, 0.6, Metal, STEEL)
				rod(b, "StringerTube", p0 - e - up * 0.3, p1 + e - up * 0.3, 0.6, Metal, STEEL)
			end
		end
		local j = deckAt(t0) - up * 1.9
		part(b, "CrossBeam", Vector3.new(8.6, 0.6, 0.7), CFrame.new(j) * frame.Rotation, Wood, jitter(TIMBER, rng, 0.1))
		for _, s in ipairs({ -1, 1 }) do
			deco(part(b, "Lashing", Vector3.new(0.9, 1.9, 0.9), CFrame.new(j + right * s * 3.4 + up * 0.7) * frame.Rotation, Fabric, rgb(170, 150, 110)))
		end
	end

	-- The deck.
	local PLANKS = { rgb(150, 120, 84), rgb(130, 104, 74), rgb(120, 116, 108), rgb(96, 76, 56), rgb(160, 140, 110) }
	local PAINT = { rgb(170, 60, 50), rgb(60, 100, 140), rgb(220, 214, 196), rgb(90, 130, 90) }
	local RUST = { rgb(120, 80, 56), rgb(140, 100, 70), rgb(96, 110, 116) }
	local function piece(d, w, across, lateral, material, color, name, yaw)
		local p0, p1 = deckAt(d / len), deckAt(math.min(d + w, len) / len)
		local thick = rng:NextNumber(0.25, 0.4)
		local cf = CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(lateral, -thick / 2 + rng:NextNumber(0, 0.05), 0) * CFrame.Angles(0, yaw or 0, 0)
		return part(b, name, Vector3.new(across, thick, (p1 - p0).Magnitude + 0.04), cf, material, color), cf
	end
	local d, gaps = 0, 3
	while d < len - 0.05 do
		local roll = rng:NextNumber()
		local mid = d > 5 and d < len - 6
		local w
		if roll < 0.07 and mid then
			-- a door laid across
			w = 3.2
			local _, cf = piece(d, w, 8.6, rng:NextNumber(-0.3, 0.3), Plywood, pick(PAINT, rng), "DoorDeck", rng:NextNumber(-0.03, 0.03))
			deco(part(b, "DoorKnob", Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(3.4, 0.3, 1), Metal, rgb(200, 170, 80)))
		elseif roll < 0.15 and mid then
			-- a sheet of corrugated roofing
			w = rng:NextNumber(2.5, 4)
			local _, cf = piece(d, w, 9, 0, Corroded, pick(RUST, rng), "SheetDeck", rng:NextNumber(-0.04, 0.04))
			for k = -4, 4 do
				deco(part(b, "Rib", Vector3.new(0.12, 0.06, w), cf * CFrame.new(k, 0.18, 0), Corroded, pick(RUST, rng)))
			end
		elseif roll < 0.21 and mid then
			-- a pallet
			w = 3.6
			local col = jitter(rgb(170, 140, 100), rng, 0.08)
			for k = 0, 5 do
				piece(d + k * 0.62, 0.48, 8, 0, Wood, col, "PalletSlat")
			end
		else
			w = rng:NextNumber(0.8, 1.4)
			local col = if rng:NextNumber() < 0.08 then pick(PAINT, rng) else jitter(pick(PLANKS, rng), rng, 0.08)
			if rng:NextNumber() < 0.15 then
				-- two short boards side by side
				piece(d, w, 4.7, -2.25, Wood, col, "Plank", rng:NextNumber(-0.05, 0.05))
				piece(d, w, 4.7, 2.25, Wood, jitter(pick(PLANKS, rng), rng, 0.08), "Plank", rng:NextNumber(-0.05, 0.05))
			else
				piece(d, w, rng:NextNumber(7.6, 9.6), rng:NextNumber(-0.5, 0.5), Wood, col, "Plank", rng:NextNumber(-0.06, 0.06))
			end
		end
		d += w
		if gaps > 0 and mid and rng:NextNumber() < 0.07 then
			d += rng:NextNumber(0.4, 0.7)
			gaps -= 1
		end
	end

	-- The handrails.
	local STYLES = { "timber", "timber", "pipe", "pipe", "fence", "sheet", "rope" }
	local m = math.ceil(len / 5)
	for _, s in ipairs({ -1, 1 }) do
		for i = 1, m do
			railSeg(b, deckAt((i - 1) / m) + right * s * 4.3, deckAt(i / m) + right * s * 4.3, pick(STYLES, rng), rng, i == m)
		end
	end

	-- A concrete pier, cracked and banded; a scaffold trestle for the other.
	local p = deckAt(0.3)
	cylinder(b, "BridgePier", 500, 5, CFrame.new(p.X, p.Y - 252.9, p.Z) * CFrame.Angles(0, 0, math.rad(90)), Concrete, rgb(110, 108, 102))
	part(b, "PierHead", Vector3.new(11, 2, 5), CFrame.new(p - up * 3.2) * frame.Rotation, Concrete, rgb(150, 146, 136))
	part(b, "Shims", Vector3.new(9.6, 0.6, 1.4), CFrame.new(p - up * 1.95) * frame.Rotation, Wood, jitter(TIMBER, rng, 0.1))
	for k = 1, 3 do
		deco(upright(b, "PierBand", 0.6, 5.3, CFrame.new(p), 0, -6 - k * 5, 0, Corroded, rgb(120, 76, 50)))
	end
	local q = deckAt(0.66)
	for _, lat in ipairs({ -3.4, 3.4 }) do
		for _, al in ipairs({ -2, 2 }) do
			local top = q + right * lat + dir * al - up * 1.7
			rod(b, "TrestleLeg", top, top - up * 480, 0.5, Metal, STEEL)
		end
		local t0 = q + right * lat - up * 1.7
		for y = 0, 40, 8 do
			deco(rod(b, "TrestleBrace", t0 - dir * 2 - up * y, t0 + dir * 2 - up * (y + 8), 0.25, Metal, STEEL))
		end
	end
	for y = 0, 40, 8 do
		deco(rod(b, "TrestleBrace", q - right * 3.4 - up * (1.7 + y), q + right * 3.4 - up * (9.7 + y), 0.25, Metal, STEEL))
	end
	part(b, "TrestleHead", Vector3.new(8.6, 0.5, 5), CFrame.new(q - up * 2.45) * frame.Rotation, Metal, STEEL)

	-- Torii: a scrap one at the gym end, the old one at the hall.
	torii(b, CFrame.new(a + dir * 3) * frame.Rotation, 10, 13, true, rng)
	torii(b, CFrame.new(c - dir * 6) * frame.Rotation, 10, 13, false, rng)
	for _, s in ipairs({ -1, 1 }) do
		local base = a - dir * 2 + right * s * 7
		part(b, "StoneLantern", Vector3.new(2, 4, 2), CFrame.new(base + up * 2), Concrete, rgb(150, 150, 144))
		part(b, "LanternCap", Vector3.new(3.2, 0.8, 3.2), CFrame.new(base + up * 4.6), Concrete, rgb(130, 130, 124))
	end
	-- An offertory box just past the first torii; a sign.
	local boxCF = CFrame.new(deckAt(6 / len) + right * 3 + up * 0.8) * frame.Rotation
	part(b, "OffertoryBox", Vector3.new(2.2, 1.6, 1.4), boxCF, Wood, rgb(110, 70, 44))
	for k = -2, 2 do
		deco(part(b, "BoxSlat", Vector3.new(2.2, 0.1, 0.14), boxCF * CFrame.new(0, 0.82, k * 0.26), Wood, rgb(80, 52, 34)))
	end
	local signAt = deckAt(4 / len) - right * 4.6 + up * 4.4
	label(b, CFrame.lookAt(signAt, signAt - dir), Vector3.new(3.6, 1.6, 0.15), Enum.NormalId.Front, "一人ずつ\nONE AT A TIME", rgb(220, 214, 196), rgb(160, 30, 30), Plywood, Enum.Font.PermanentMarker)
	rod(b, "SignPost", deckAt(4 / len) - right * 4.6 - up * 0.3, signAt, 0.2, Wood, TIMBER)

	-- Stay cables off the torii down to the deck edges.
	for _, s in ipairs({ -1, 1 }) do
		deco(rod(b, "Stay", a + dir * 3 + right * s * 5 + up * 12.8, deckAt(0.3) + right * s * 4.7, 0.14, Metal, DARK))
		deco(rod(b, "Stay", c - dir * 6 + right * s * 5 + up * 12.8, deckAt(0.72) + right * s * 4.7, 0.14, Metal, DARK))
	end
	-- A hose along one edge (they bring water over).
	local prev = deckAt(0) + right * 3.8 + up * 0.25
	for k = 1, 14 do
		local h = deckAt(k / 14) + right * (3.8 + rng:NextNumber(-0.2, 0.2)) + up * 0.25
		deco(rod(b, "Hose", prev, h, 0.3, Smooth, rgb(50, 110, 170)))
		prev = h
	end
	-- Ema on the rail near the hall.
	for k = 1, 12 do
		local e = deckAt(0.78 + k * 0.014) - right * 4.15 + up * 2.5
		deco(part(b, "Ema", Vector3.new(0.7, 0.5, 0.06), CFrame.lookAt(e, e + right) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-8, 8))), Wood, jitter(rgb(210, 180, 130), rng, 0.06)))
		deco(rod(b, "EmaCord", e + up * 0.25, e + up * 0.6, 0.04, Fabric, rgb(200, 40, 40)))
	end
	-- Things hung under: a tarp, buckets on ropes.
	deco(part(b, "UnderTarp", Vector3.new(7, 0.1, 6), CFrame.new(deckAt(0.5) - up * 3) * frame.Rotation * CFrame.Angles(math.rad(8), 0, math.rad(-5)), Fabric, pick(TARPS, rng)))
	for _, t in ipairs({ 0.2, 0.44, 0.58, 0.85 }) do
		local top = deckAt(t) + right * pick({ -3.6, 3.6 }, rng) - up * 2.2
		local drop = rng:NextNumber(2, 6)
		deco(rod(b, "Rope", top, top - up * drop, 0.1, Fabric, rgb(190, 170, 120)))
		deco(upright(b, "Bucket", 1.1, 1, CFrame.new(top - up * (drop + 0.55)), 0, 0, 0, Smooth, pick({ rgb(60, 110, 170), rgb(200, 60, 50), rgb(220, 200, 60) }, rng)))
	end

	-- The lantern line between the torii, and prayer flags either side.
	local top0, top1 = a + dir * 3 + up * 12.4, c - dir * 6 + up * 12.4
	local prevL = top0
	local nl = 12
	for i = 1, nl do
		local t = i / nl
		local pl = top0:Lerp(top1, t) - up * (2.5 * 4 * t * (1 - t))
		deco(rod(b, "LanternLine", prevL, pl, 0.08, Fabric, DARK))
		if i < nl then
			local lit = rng:NextNumber() < 0.45
			local l = deco(ellipsoid(b, "Chochin", Vector3.new(1.1, 1.5, 1.1), CFrame.new(pl - up), if lit then Neon else Fabric, if lit then rgb(240, 150, 90) else rgb(190, 60, 50)))
			if lit and i % 4 == 0 then
				glow(l, 14)
			end
		end
		prevL = pl
	end
	local FLAGS = { rgb(60, 110, 190), rgb(240, 236, 226), rgb(200, 60, 50), rgb(90, 160, 80), rgb(240, 200, 60) }
	for _, s in ipairs({ -1, 1 }) do
		local f0, f1 = top0 + right * s * 6 + up * 0.8, top1 + right * s * 6 + up * 0.8
		local prevF = f0
		local nf = math.floor(len / 1.6)
		for i = 1, nf do
			local t = i / nf
			local pf = f0:Lerp(f1, t) - up * (3.5 * 4 * t * (1 - t))
			deco(rod(b, "FlagLine", prevF, pf, 0.05, Fabric, rgb(200, 190, 170)))
			if i < nf then
				deco(part(b, "PrayerFlag", Vector3.new(0.05, 1.3, 1), CFrame.new(pf - up * 0.65) * frame.Rotation, Fabric, FLAGS[i % #FLAGS + 1]))
			end
			prevF = pf
		end
	end
end

-- ===== Placing her =====

-- She leans forward over the gym, a little to the east, as if the rock
-- under her lotus gave way.
local TILT = CFrame.Angles(math.rad(10), 0, math.rad(-4))

-- Your statue from ServerStorage > PropLibrary > Kannon, or nil. Scaled
-- to 420 studs, turned to face the school (FacingDegrees attribute on
-- the model to correct its facing), leaning. Meshes without a proper
-- collision shape are left walk-through.
local function meshStatue(parent, rng)
	local m = PropLibrary.take("Kannon", rng)
	if not m then
		return nil
	end
	m.Parent = parent
	-- Plain matte stone by default: a grainy material at her size breaks
	-- her face up into noise, and SmoothPlastic gleams. A StatueMaterial
	-- attribute (e.g. "Limestone", "Slate", "Concrete") picks another.
	local statueMaterial = Enum.Material.Plastic
	local named = m:GetAttribute("StatueMaterial")
	if type(named) == "string" then
		pcall(function()
			statueMaterial = Enum.Material[named]
		end)
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("MeshPart") then
			if d.CollisionFidelity == Enum.CollisionFidelity.Box or d.CollisionFidelity == Enum.CollisionFidelity.Hull then
				d.CanCollide = false
			end
			-- Weathered, darker stone. (A textured mesh keeps its texture
			-- unless the model has a StripTexture attribute set true.)
			if m:GetAttribute("StripTexture") then
				d.TextureID = ""
			end
			if d.TextureID == "" then
				d.Material = statueMaterial
			end
			d.Color = STATUE_STONE
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				pcall(function()
					sa.Color = STATUE_STONE:Lerp(Color3.new(1, 1, 1), 0.2)
				end)
			end
		end
	end
	local turn = m:GetAttribute("FacingDegrees") or 180
	local ok, err = pcall(PropLibrary.fit, m, CFrame.new(SX, LOTUS_TOP - 5, SZ) * TILT * CFrame.Angles(0, math.rad(turn), 0), 420)
	if not ok then
		warn("[Kannon] couldn't place the statue: " .. tostring(err))
		m:Destroy()
		return nil
	end
	return m, 420
end

-- The stand-in when there's no mesh: the statue built from panels,
-- stood on the lotus and tilted the same way.
local function standInStatue(parent, rng)
	local m = model(parent, "StandInKannon")
	body(m, rng)
	local joints = arms(m, rng)
	overgrowth(m, rng, joints)
	m.WorldPivot = CFrame.new(SX, FEET, SZ)
	m:PivotTo(CFrame.new(SX, LOTUS_TOP - 5, SZ) * TILT)
	return m, 121 - FEET
end

-- A great aureole behind her: a halo behind her head and a flame-edged
-- mandorla round her whole figure, in her own leaning frame.
local function aureole(parent, base, H, rng)
	local a = model(parent, "Aureole")
	local behind = -0.13 * H
	local function at(x, y)
		return (base * CFrame.new(x, y, behind)).Position
	end
	local stone = rgb(200, 196, 184)
	-- The mandorla's outline: wide at her shoulders, meeting in a point
	-- over her head, both sides.
	local n = 22
	for _, s in ipairs({ -1, 1 }) do
		local prev
		for i = 0, n do
			local t = i / n
			local w = H * (0.2 + 0.16 * math.sin(math.pi * t)) * (1 - t ^ 3)
			local p = at(s * w, t * H * 1.06)
			if prev then
				rod(a, "Mandorla", prev, p, 6, Concrete, jitter(stone, rng, 0.04))
				if i % 2 == 0 and i < n then
					local mid = (prev + p) / 2
					local out = (base:VectorToWorldSpace(Vector3.new(s, 0.3, 0))).Unit
					ellipsoid(a, "Flame", Vector3.new(7, 16, 3), CFrame.lookAt(mid + out * 6, mid + out * 12, base.LookVector) * CFrame.Angles(math.rad(90), 0, 0), Concrete, jitter(stone, rng, 0.05))
				end
			end
			prev = p
		end
	end
	-- The halo behind her head.
	local hc = at(0, 0.86 * H)
	local r = 0.14 * H
	local seg = 28
	for k = 0, seg - 1 do
		local a0, a1 = k / seg * math.pi * 2, (k + 1) / seg * math.pi * 2
		rod(a, "Halo", (base * CFrame.new(math.cos(a0) * r, 0.86 * H + math.sin(a0) * r, behind + 2)).Position, (base * CFrame.new(math.cos(a1) * r, 0.86 * H + math.sin(a1) * r, behind + 2)).Position, 4, Concrete, jitter(stone, rng, 0.04))
	end
	for k = 0, 15 do
		local ang = k / 16 * math.pi * 2
		rod(a, "HaloRay", (base * CFrame.new(math.cos(ang) * r * 0.45, 0.86 * H + math.sin(ang) * r * 0.45, behind + 2)).Position, (base * CFrame.new(math.cos(ang) * r * 0.95, 0.86 * H + math.sin(ang) * r * 0.95, behind + 2)).Position, 1.6, Concrete, jitter(stone, rng, 0.04))
	end
	-- Struts back from the mandorla to the lotus, holding it up.
	for _, s in ipairs({ -1, 1 }) do
		rod(a, "AureoleStrut", at(s * H * 0.2, 2), (base * CFrame.new(s * H * 0.12, 0, behind * 0.3)).Position, 5, Concrete, darken(stone, 0.9))
	end
end

-- ===== Climbing her =====

-- Rays from `from` along `dir` against her; nil if none. She's put into
-- the workspace for a moment so the rays can find her.
local function hitsOn(statue, rays)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { statue }
	local old = statue.Parent
	statue.Parent = workspace
	local out = {}
	for i, r in ipairs(rays) do
		local h = workspace:Raycast(r[1], r[2], params)
		out[i] = if h then h.Position else false
	end
	statue.Parent = old
	return out
end

-- ===== Light on her face =====

-- The sun sits low in the south and she faces north, so her front is
-- always in her own shadow, lit only by the flat sky, and reads as a lump
-- of rock. A spread of big, dim, far-off lights over her front stands in
-- for the daylight that would bounce back onto her off the city: no
-- spotlight, just enough to give her face and robe some shape. A touch
-- stronger from the east, so her features aren't lit dead flat.
-- Invisible cards with SurfaceLights on them; the numbers are in LIGHTS
-- (h = how far up her, x = east/west, brightness).
local LIGHTS = {
	{ h = 0.91, x = 18, brightness = 0.45 },
	{ h = 0.91, x = -18, brightness = 0.3 },
	{ h = 0.84, x = 20, brightness = 0.4 },
	{ h = 0.84, x = -20, brightness = 0.28 },
	{ h = 0.74, x = 22, brightness = 0.3 },
	{ h = 0.6, x = 20, brightness = 0.35 },
	{ h = 0.6, x = -20, brightness = 0.25 },
	{ h = 0.44, x = 0, brightness = 0.3 },
}
local BOUNCE = rgb(214, 210, 200) -- the colour of the light off the city
local LIGHT_OUT = 52 -- how far in front of her middle the cards hang
local function faceLights(parent, statue, H, base)
	local fl = model(parent, "FaceLights")
	for _, spec in ipairs(LIGHTS) do
		local p = base.Position + base.UpVector * (spec.h * H)
		local target = p
		local from = target + Vector3.new(spec.x, -4, LIGHT_OUT)
		local card = part(fl, "LightCard", Vector3.new(48, 48, 0.2), CFrame.lookAt(from, target), Smooth, rgb(0, 0, 0))
		card.Transparency = 1
		card.CanCollide = false
		card.CanQuery = false
		card.CanTouch = false
		card.CastShadow = false
		local l = Instance.new("SurfaceLight")
		l.Face = Enum.NormalId.Front
		l.Range = 60
		l.Angle = 120
		l.Brightness = spec.brightness
		l.Color = BOUNCE
		l.Shadows = false
		l.Parent = card
	end
end

-- A scaffold tower of tubes, platforms every so often with a hatch, a
-- climbable ladder up through them.
local function scaffoldTower(parent, base, top, rng, openAt)
	local s = model(parent, "Scaffold")
	local half = 4.5
	local HATCH = 4.6
	local h = top - base.Y
	for _, dx in ipairs({ -half, half }) do
		for _, dz in ipairs({ -half, half }) do
			rod(s, "ScaffoldPost", base + Vector3.new(dx, -0.5, dz), base + Vector3.new(dx, h + 4, dz), 0.45, Metal, STEEL)
		end
	end
	for y = 5, h, 8 do
		for _, e in ipairs({ { -half, -half, half, -half }, { half, -half, half, half }, { half, half, -half, half }, { -half, half, -half, -half } }) do
			deco(rod(s, "Ledger", base + Vector3.new(e[1], y, e[2]), base + Vector3.new(e[3], y, e[4]), 0.25, Metal, STEEL))
		end
		deco(rod(s, "Brace", base + Vector3.new(-half, y, half), base + Vector3.new(half, y + 8, half), 0.2, Metal, STEEL))
	end
	local levels = {}
	local y = 0
	while y < h - 0.5 do
		local nextY = math.min(h, y + 30)
		local ladder = Instance.new("TrussPart")
		ladder.Name = "ScaffoldLadder"
		ladder.Anchored = true
		ladder.Size = Vector3.new(2, nextY - y + 2, 2)
		ladder.Position = base + Vector3.new(half - 1.8, (y + nextY) / 2 + 1, half - 1.8)
		ladder.Material = Metal
		ladder.Color = rgb(200, 170, 40)
		ladder.Parent = s
		-- The platform at the top of this ladder, a hatch for it.
		local py = nextY
		-- (The hatch is wide, so you don't bang your head on the deck
		-- climbing through it.)
		box(s, "ScaffoldDeck", base.X - half, base.X + half - HATCH, base.Y + py - 0.3, base.Y + py, base.Z - half, base.Z + half, Diamond, rgb(96, 98, 100))
		box(s, "ScaffoldDeck", base.X + half - HATCH, base.X + half, base.Y + py - 0.3, base.Y + py, base.Z - half, base.Z + half - HATCH, Diamond, rgb(96, 98, 100))
		-- Railed round, except the east side where a walk leaves from.
		local edges = { { -half, -half, half, -half }, { -half, half, -half, -half }, { -half, half, half - HATCH, half } }
		if not openAt(#levels + 1, math.ceil(h / 30)) then
			table.insert(edges, { half, -half, half, half - HATCH })
		end
		for _, e in ipairs(edges) do
			rail(s, base + Vector3.new(e[1], py, e[2]), base + Vector3.new(e[3], py, e[4]))
		end
		table.insert(levels, base.Y + py)
		y = nextY
	end
	return levels
end

-- A walkway from a to b (level), railed, with a deck at its end.
local function walkway(parent, name, a, b, rng)
	local w = model(parent, name)
	local len = (b - a).Magnitude
	local frame = CFrame.lookAt(a, b)
	part(w, "Walk", Vector3.new(3.6, 0.4, len), frame * CFrame.new(0, -0.2, -len / 2), Diamond, rgb(96, 98, 100))
	for _, s in ipairs({ -1.8, 1.8 }) do
		rail(w, a + frame.RightVector * s, b + frame.RightVector * s)
		deco(rod(w, "Truss", a + frame.RightVector * s - Vector3.new(0, 1.8, 0), b + frame.RightVector * s - Vector3.new(0, 1.8, 0), 0.3, Metal, STEEL))
	end
	return w, frame
end

local function climb(parent, statue, H, base, rng)
	local up = base.UpVector
	local function axisAt(h)
		return base.Position + up * h
	end
	-- Find her west side low down, to stand the tower clear of her.
	local rays = {}
	for h = 10, H * 0.6, 20 do
		local p = axisAt(h)
		table.insert(rays, { Vector3.new(p.X - 200, p.Y, SZ + 20), Vector3.new(200, 0, 0) })
	end
	local hits = hitsOn(statue, rays)
	local minX = SX - 40
	for _, h in ipairs(hits) do
		if h then
			minX = math.min(minX, h.X)
		end
	end
	-- On the lotus if it fits there; otherwise out on the terrace, clear of
	-- the petals.
	local tx, tz = minX - 9, SZ + 20
	local dz = tz - SZ
	local r = math.sqrt((tx - SX) ^ 2 + dz ^ 2)
	local baseY = LOTUS_TOP
	if r >= 68 then
		baseY = ROOF
		r = math.clamp(r, 92, A - 8)
		tx = SX - math.sqrt(r * r - dz * dz)
	end
	local faceH = 0.85 * H
	local top = axisAt(faceH).Y
	local function openAt(i, n)
		return i == math.max(1, math.floor(n * 0.55)) or i == n
	end
	local levels = scaffoldTower(parent, Vector3.new(tx, baseY, tz), top, rng, openAt)
	-- Her balcony: a deck out from the tower at about her middle, up
	-- against her robe.
	local midY = levels[math.max(1, math.floor(#levels * 0.55))]
	local mh = hitsOn(statue, { { Vector3.new(tx + 5, midY + 2, tz), Vector3.new(160, 0, 0) } })[1]
	if mh then
		local a, b = Vector3.new(tx + 4.5, midY, tz), Vector3.new(mh.X - 2.5, midY, tz)
		if (b - a).Magnitude > 2 then
			local w = walkway(parent, "Balcony", a, b, rng)
			box(w, "BalconyDeck", b.X - 5, b.X + 0.5, midY - 0.4, midY, tz - 5, tz + 5, Plywood, rgb(150, 120, 84))
			rail(w, Vector3.new(b.X - 5, midY, tz - 5), Vector3.new(b.X + 0.5, midY, tz - 5))
			rail(w, Vector3.new(b.X - 5, midY, tz + 5), Vector3.new(b.X + 0.5, midY, tz + 5))
			local l = ellipsoid(w, "Lantern", Vector3.new(0.9, 1.2, 0.9), CFrame.new(b.X - 2, midY + 1, tz + 4), Neon, rgb(240, 150, 90))
			l.CanCollide = false
			glow(l, 14)
			for k = 0, 5 do
				deco(part(w, "PrayerFlag", Vector3.new(1, 1.4, 0.05), CFrame.new(b.X - 4.5 + k * 0.9, midY + 3.6, tz - 4.9), Fabric, pick({ rgb(60, 110, 190), rgb(240, 236, 226), rgb(200, 60, 50), rgb(90, 160, 80), rgb(240, 200, 60) }, rng)))
			end
			lootSpot(w, Vector3.new(b.X - 3, midY, tz - 2))
		end
	end
	-- At the top, a jib out to a cradle hung in front of her face.
	local fc = axisAt(faceH)
	local front = hitsOn(statue, { { Vector3.new(fc.X, top + 1, fc.Z + 300), Vector3.new(0, 0, -300) } })[1]
	local cradleZ = if front then front.Z + 5 else fc.Z + 0.12 * H
	local jibA = Vector3.new(tx + 4.5, top, tz)
	local jibB = Vector3.new(fc.X, top, cradleZ)
	local w = walkway(parent, "Jib", jibA, jibB, rng)
	box(w, "Cradle", jibB.X - 4, jibB.X + 4, top - 0.4, top, jibB.Z - 2, jibB.Z + 2, Diamond, rgb(200, 170, 40))
	for _, s in ipairs({ -1, 1 }) do
		rail(w, Vector3.new(jibB.X - 4, top, jibB.Z + s * 2), Vector3.new(jibB.X + 4, top, jibB.Z + s * 2))
	end
	deco(rod(w, "CradleCable", jibB + Vector3.new(-3.6, 3.2, 0), jibB + Vector3.new(-3.6, 30, 0), 0.12, Metal, DARK))
	deco(rod(w, "CradleCable", jibB + Vector3.new(3.6, 3.2, 0), jibB + Vector3.new(3.6, 30, 0), 0.12, Metal, DARK))
	lootSpot(w, jibB + Vector3.new(2.5, 0, 0))
	-- A walk from the lotus (or the terrace) round to the tower's foot.
	return Vector3.new(tx, baseY, tz)
end

-- The stair tower on the terrace up onto the lotus: three flights in a
-- scaffold, a walk across to the lotus top.
local function lotusStair(parent, rng)
	local s = model(parent, "LotusStair")
	local cx, cz = SX + 93, SZ + 38
	local x0, x1, z0, z1 = cx - 5, cx + 5, cz - 11, cz + 11
	local rise = (LOTUS_TOP - ROOF) / 3
	local zS, zN = z0 + 3.5, z1 - 3.5
	for k = 1, 3 do
		local yb = ROOF + (k - 1) * rise
		local north = k % 2 == 1
		local xa, xb = if north then x0 else cx, if north then cx else x1
		local n = math.ceil(rise / 0.75)
		local run = (zN - zS) / n
		for i = 1, n do
			local top = yb + i * rise / n
			local za = if north then zS + (i - 1) * run else zN - i * run
			local zb = if north then zS + i * run + 0.02 else zN - (i - 1) * run
			box(s, "Step", xa, xb, top - 0.3, top, za, zb, Wood, jitter(rgb(150, 112, 76), rng, 0.08))
		end
		local ly = yb + rise
		if north then
			box(s, "Landing", x0, x1, ly - 0.4, ly, zN, z1, Diamond, rgb(96, 98, 100))
		else
			box(s, "Landing", x0, x1, ly - 0.4, ly, z0, zS, Diamond, rgb(96, 98, 100))
		end
		for _, x in ipairs({ xa + 0.15, xb - 0.15 }) do
			rod(s, "StairRail", Vector3.new(x, yb + 3.2, if north then zS else zN), Vector3.new(x, yb + rise + 3.2, if north then zN else zS), 0.18, Wood, TIMBER)
		end
	end
	for _, x in ipairs({ x0 - 0.3, x1 + 0.3 }) do
		for _, z in ipairs({ z0 - 0.3, z1 + 0.3 }) do
			rod(s, "ScaffoldPost", Vector3.new(x, ROOF, z), Vector3.new(x, LOTUS_TOP + 4, z), 0.4, Metal, STEEL)
		end
	end
	-- Across from the top landing to the lotus.
	walkway(s, "LotusWalk", Vector3.new(cx - 3, LOTUS_TOP, z1 - 2), Vector3.new(SX + 64, LOTUS_TOP, SZ + 28), rng)
end

-- Moss and vines on the hall, the lotus weathered.
local function hallGrowth(parent, rng)
	local g = model(parent, "HallGrowth")
	for _ = 1, 40 do
		local k = rng:NextInteger(0, 7)
		local a = k * math.pi / 4
		local u = rng:NextNumber(-SIDE / 2 + 4, SIDE / 2 - 4)
		local y = rng:NextNumber(DRUM_BOTTOM + 4, ROOF - 4)
		local p = Vector3.new(SX, y, SZ) + Vector3.new(math.cos(a), 0, math.sin(a)) * (A + 0.3) + Vector3.new(-math.sin(a), 0, math.cos(a)) * u
		local sz = rng:NextNumber(3, 10)
		deco(ellipsoid(g, "Moss", Vector3.new(sz, sz * rng:NextNumber(0.5, 1.6), 1.2), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))), Enum.Material.LeafyGrass, jitter(rgb(80, 110, 60), rng, 0.15)))
	end
	for _ = 1, 14 do
		local k = rng:NextInteger(0, 7)
		local a = k * math.pi / 4
		local u = rng:NextNumber(-SIDE / 2 + 4, SIDE / 2 - 4)
		local top = Vector3.new(SX, ROOF + 1, SZ) + Vector3.new(math.cos(a), 0, math.sin(a)) * (A + 0.6) + Vector3.new(-math.sin(a), 0, math.cos(a)) * u
		local len = rng:NextNumber(15, 60)
		local prev = top
		for j = 1, 4 do
			local q = top + Vector3.new(0, -len * j / 4, 0) + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(0, 0.8)
			deco(rod(g, "Vine", prev, q, 0.35, Wood, rgb(70, 90, 50)))
			if rng:NextNumber() < 0.6 then
				deco(ellipsoid(g, "Leaves", Vector3.new(2.6, 2, 2.6), CFrame.new(q), Enum.Material.LeafyGrass, jitter(rgb(80, 120, 60), rng, 0.15)))
			end
			prev = q
		end
	end
	for _ = 1, 10 do
		local ang, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(86, A - 6)
		local holder = model(g, "Growth")
		local c = Vector3.new(SX + math.cos(ang) * d, ROOF, SZ + math.sin(ang) * d)
		if rng:NextNumber() < 0.6 then
			Clutter.weeds(holder, c, rng)
		else
			Clutter.bush(holder, c, rng)
		end
	end
end

function Kannon.build(parent, rng)
	lightsLeft = 24
	local m = model(parent, "Kannon")
	pedestal(m, rng)
	task.wait()
	station(m, rng)
	for k, cx in ipairs({ SX - 40, SX, SX + 40 }) do
		car(m, cx, pick({ rgb(60, 140, 90), rgb(220, 120, 40), rgb(60, 110, 190) }, rng), if k == 1 then -1 elseif k == 3 then 1 else 0, rng)
	end
	viaduct(m, rng)
	task.wait()
	pilgrimBridge(m, rng)
	lotusStair(m, rng)
	hallGrowth(m, rng)
	local statue, H = meshStatue(m, rng)
	if not statue then
		statue, H = standInStatue(m, rng)
	end
	task.wait()
	local base = CFrame.new(SX, LOTUS_TOP - 5, SZ) * TILT
	aureole(m, base, H, rng)
	climb(m, statue, H, base, rng)
	faceLights(m, statue, H, base)
end

return Kannon
