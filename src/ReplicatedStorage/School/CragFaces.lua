-- The crag's south and east faces (what you see of it from the Kannon, the
-- gym and the ledge), and the root below it, shaped so it reads as a
-- great pillar of rock rather than a box:
--   * shoulders bulging out near the top and ribs of rock running down,
--     with gullies between them, so the outline steps in and out and the
--     whole mass seems to narrow towards the haze;
--   * strata: ledges of harder rock standing out every so often, some
--     grassed over;
--   * a curtain of basalt columns on the south face, facing the Kannon;
--   * a waterfall out of a cleft, pouring down over the columns into the
--     haze, spray and mist;
--   * old mine adits opening onto ledges, their timbers, rails running
--     out to the edge, a cart tipped over it, crates, lanterns;
--   * hanging gardens: trees growing sideways off the ledges, curtains of
--     vines;
--   * a tapering root of rock below it, into the haze.
--
-- Everything here only adds rock, apart from the short adits, which are
-- cut in bands well clear of the tunnels (above), the facility incline
-- and the maze (below). The tunnels are carved afterwards anyway.

local BuildUtil = require(script.Parent.BuildUtil)
local TunnelProps = require(script.Parent.TunnelProps)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Metal, Smooth, Wood = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Wood
local ellipsoid = TunnelProps.ellipsoid
local rgb = Color3.fromRGB
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local terrain = workspace.Terrain
local AIR = Enum.Material.Air

local CragFaces = {}

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function thin(p)
	if p then
		p.CanCollide = false
	end
	return p
end

local function rockMaterial(rng, y)
	local roll = rng:NextNumber()
	if roll < 0.22 then
		return Enum.Material.Slate
	elseif roll < 0.34 then
		return Enum.Material.Basalt
	elseif roll < 0.42 and y > -250 then
		return Enum.Material.Limestone
	end
	return Enum.Material.Rock
end

-- A face: where a point `u` along it, at height y, `out` studs out from it
-- is; and which way is out.
local function faces(c)
	return {
		south = {
			u0 = 494, u1 = c.x1 - 2,
			at = function(u, y, out)
				return Vector3.new(u, y, c.z0 - out)
			end,
			normal = Vector3.new(0, 0, -1),
			along = Vector3.new(1, 0, 0),
		},
		east = {
			u0 = c.z0 + 2, u1 = c.z1 - 2,
			at = function(u, y, out)
				return Vector3.new(c.x1 + out, y, u)
			end,
			normal = Vector3.new(1, 0, 0),
			along = Vector3.new(0, 0, 1),
			-- the ledge off the tunnels, and the drop it looks over
			keepClear = function(u, y)
				return u > -30 and u < 70
			end,
		},
	}
end

-- ===== The rock =====

local function shape(c, f, rng, seed)
	local keep = f.keepClear or function()
		return false
	end
	-- Ribs down the face, a gully between each pair.
	local u = f.u0 + rng:NextNumber(6, 20)
	while u < f.u1 - 6 do
		local y = c.bottom + rng:NextNumber(0, 20)
		while y < c.top - 4 do
			local r = rng:NextNumber(9, 15)
			if not keep(u, y) then
				local out = r * rng:NextNumber(0.35, 0.75)
				terrain:FillBall(f.at(u + rng:NextNumber(-3, 3), math.min(y, c.top - r * 0.6), out), r, rockMaterial(rng, y))
			end
			y += r * rng:NextNumber(1, 1.4)
		end
		u += rng:NextNumber(30, 55)
	end
	-- Lumps between, and shoulders swelling out near the top so the mass
	-- seems to narrow downwards.
	for uu = f.u0, f.u1, 12 do
		for y = c.bottom + 8, c.top - 6, 14 do
			if not keep(uu, y) then
				local high = math.clamp((y - (c.top - 170)) / 170, 0, 1)
				local r = rng:NextNumber(6, 11) + high * rng:NextNumber(4, 12)
				local out = (math.noise(uu / 40, y / 40, seed) + 0.4) * 6 + high * 10 - r * 0.6
				if out > -r * 0.8 then
					terrain:FillBall(f.at(uu + rng:NextNumber(-4, 4), math.min(y, c.top - r * 0.7), out), r, rockMaterial(rng, y))
				end
			end
		end
	end
	-- Strata: ledges of harder rock standing out, some grassed.
	local ledges = {}
	local y = c.bottom + rng:NextNumber(30, 50)
	while y < c.top - 30 do
		local band = pick({ Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Limestone, Enum.Material.Rock }, rng)
		local thick = rng:NextNumber(3, 6)
		for uu = f.u0, f.u1 - 8, 14 do
			if not keep(uu, y) and rng:NextNumber() < 0.8 then
				local out = 4 + (math.noise(uu / 30, y / 30, seed + 7) + 0.5) * 6
				local centre = f.at(uu + 7, y, out / 2 - 2)
				local size = if f.along.X ~= 0 then Vector3.new(15, thick, out + 4) else Vector3.new(out + 4, thick, 15)
				terrain:FillBlock(CFrame.new(centre), size, band)
				if rng:NextNumber() < 0.35 then
					terrain:FillBall(f.at(uu + 7 + rng:NextNumber(-4, 4), y + thick / 2, out * 0.6), rng:NextNumber(2.5, 4), if rng:NextNumber() < 0.7 then Enum.Material.LeafyGrass else Enum.Material.Grass)
				end
				table.insert(ledges, { u = uu + 7, y = y + thick / 2, out = out })
			end
		end
		y += rng:NextNumber(28, 46)
	end
	return ledges
end

-- The root: rock tapering down from the crag's underside into the haze.
local function root(c, rng)
	local cx, cz = (c.x0 + c.x1) / 2, (c.z0 + c.z1) / 2
	local hx, hz = (c.x1 - c.x0) / 2, (c.z1 - c.z0) / 2
	for y = c.bottom, c.bottom - 300, -18 do
		local t = (c.bottom - y) / 300
		local sx, sz = hx * (1 - 0.7 * t), hz * (1 - 0.7 * t)
		terrain:FillBlock(CFrame.new(cx, y - 9, cz), Vector3.new(sx * 1.5, 20, sz * 1.5), Enum.Material.Rock)
		for k = 0, 17 do
			local a = k / 18 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
			local r = rng:NextNumber(18, 30) * (1 - 0.5 * t)
			terrain:FillBall(Vector3.new(cx + math.cos(a) * (sx - r * 0.4), y + rng:NextNumber(-8, 8), cz + math.sin(a) * (sz - r * 0.4)), r, rockMaterial(rng, y))
		end
	end
end

-- ===== Basalt columns =====

local function basalt(parent, c, f, rng)
	local m = model(parent, "BasaltColumns")
	local u0, u1 = 548, 640
	terrain:FillBlock(CFrame.new(f.at((u0 + u1) / 2, -190, 16)), Vector3.new(u1 - u0 + 4, 270, 31), AIR)
	local dark = rgb(62, 62, 64)
	for row = 0, 1 do
		local u = u0 + row * 3.6
		while u < u1 do
			local d = rng:NextNumber(6.5, 8)
			-- the columns step down towards the sides of the curtain
			local mid = 1 - math.abs((u - (u0 + u1) / 2) / ((u1 - u0) / 2))
			local top = -70 - (1 - mid) * 50 - rng:NextNumber(0, 16) - row * 8
			local bottom = -310 + rng:NextNumber(-20, 30)
			local p = f.at(u, (top + bottom) / 2, 1.5 + row * 5.5 + rng:NextNumber(-0.6, 0.6))
			cylinder(m, "BasaltColumn", top - bottom, d, CFrame.new(p) * UPRIGHT, Enum.Material.Basalt, jitter(dark, rng, 0.08))
			-- a cap on the top, and broken stubs that have fallen off
			cylinder(m, "ColumnCap", 1.2, d - 0.6, CFrame.new(f.at(u, top + 0.6, 1.5 + row * 5.5)) * UPRIGHT, Enum.Material.Basalt, jitter(rgb(74, 74, 76), rng, 0.08))
			u += d * 0.92
		end
	end
	-- Rock round it so the columns look set into the face.
	for y = -320, -60, 20 do
		terrain:FillBall(f.at(u0 - 6, y, 2), rng:NextNumber(8, 12), Enum.Material.Slate)
		terrain:FillBall(f.at(u1 + 6, y, 2), rng:NextNumber(8, 12), Enum.Material.Slate)
	end
	return { u = (u0 + u1) / 2 + 12 }
end

-- ===== The waterfall =====

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function emitter(parent, pos, size, rate, lifetime, speed, accel, color, transparency, down)
	local a = part(parent, "WaterEmitter", Vector3.new(6, 0.4, 1), pos, Smooth, color)
	a.Transparency = 1
	a.CanCollide = false
	a.CanQuery = false
	a.CastShadow = false
	local e = Instance.new("ParticleEmitter")
	e.EmissionDirection = if down then Enum.NormalId.Bottom else Enum.NormalId.Top
	e.Texture = SMOKE
	e.Rate = rate
	e.Lifetime = NumberRange.new(lifetime * 0.8, lifetime * 1.2)
	e.Speed = NumberRange.new(speed * 0.7, speed * 1.3)
	e.Acceleration = accel
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 2.2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, transparency), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(color)
	e.SpreadAngle = Vector2.new(12, 6)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-20, 20)
	e.LightEmission = 0.15
	e.Parent = a
	return a
end

local function waterfall(parent, c, f, u, rng)
	local m = model(parent, "Waterfall")
	local top = -34
	-- The cleft it comes out of: a lip of rock above, moss round it.
	terrain:FillBall(f.at(u, top + 6, 8), 8, Enum.Material.Slate)
	for _ = 1, 8 do
		terrain:FillBall(f.at(u + rng:NextNumber(-10, 10), top + rng:NextNumber(-8, 6), rng:NextNumber(2, 5)), rng:NextNumber(2.5, 4.5), Enum.Material.LeafyGrass)
	end
	-- The falling sheet, clear of the columns, arcing a little further out
	-- as it goes down.
	local y = top
	local out = 12
	local w = 7
	local seg = 0
	while y > c.bottom - 60 do
		local len = rng:NextNumber(40, 60)
		local nextOut = out + len * 0.04
		local a, b = f.at(u, y, out), f.at(u, y - len, nextOut)
		local sheet = part(m, "WaterSheet", Vector3.new(w, (b - a).Magnitude + 1, 1.2), CFrame.lookAt((a + b) / 2, b, f.normal) * CFrame.Angles(math.rad(90), 0, 0), Smooth, rgb(186, 214, 222))
		sheet.Transparency = 0.45
		sheet.CanCollide = false
		sheet.CastShadow = false
		if seg % 2 == 0 then
			emitter(m, f.at(u, y - 4, out + 1), 5, 26, 5, 12, Vector3.new(0, -26, 0), rgb(226, 236, 240), 0.35, true)
		end
		y -= len
		out = nextOut
		w += 1.2
		seg += 1
	end
	-- Spray where it leaves the lip and mist lower down.
	emitter(m, f.at(u, top, 12), 3, 18, 2, 4, Vector3.new(0, -4, 0), rgb(236, 242, 244), 0.4, true)
	for _, h in ipairs({ -160, -260, -380 }) do
		emitter(m, f.at(u, h, 14), 16, 5, 7, 2, Vector3.new(0, 1, 0), rgb(220, 228, 232), 0.7)
	end
	-- A pool on a ledge partway down where some of it catches.
	local ly = -150
	terrain:FillBlock(CFrame.new(f.at(u, ly - 3, 8)), if f.along.X ~= 0 then Vector3.new(22, 6, 16) else Vector3.new(16, 6, 22), Enum.Material.Slate)
	terrain:FillBlock(CFrame.new(f.at(u, ly + 0.6, 8)), if f.along.X ~= 0 then Vector3.new(14, 1.4, 10) else Vector3.new(10, 1.4, 14), Enum.Material.Water)
	for _ = 1, 6 do
		terrain:FillBall(f.at(u + rng:NextNumber(-10, 10), ly + 1, rng:NextNumber(10, 15)), rng:NextNumber(2, 3.5), Enum.Material.LeafyGrass)
	end
	return m
end

-- ===== Adits =====

local function adit(parent, c, f, u, y, rng)
	local m = model(parent, "Adit")
	local W, H, deep = 8, 9, 14
	-- Cut the adit, and a shelf of rock out in front of it.
	local inside = f.at(u, y + H / 2, -deep / 2 + 1)
	terrain:FillBlock(CFrame.new(inside), if f.along.X ~= 0 then Vector3.new(W, H, deep + 2) else Vector3.new(deep + 2, H, W), AIR)
	local shelf = f.at(u, y - 3, 6)
	terrain:FillBlock(CFrame.new(shelf), if f.along.X ~= 0 then Vector3.new(W + 10, 6, 12) else Vector3.new(12, 6, W + 10), Enum.Material.Rock)
	for _ = 1, 4 do
		terrain:FillBall(f.at(u + rng:NextNumber(-8, 8), y - 5, rng:NextNumber(6, 11)), rng:NextNumber(3, 5), rockMaterial(rng, y))
	end
	-- The back has fallen in.
	terrain:FillBall(f.at(u, y + 1, -deep + 1), 4.5, Enum.Material.Rock)
	-- Timbers round the mouth.
	local timber = rgb(96, 72, 50)
	for _, s in ipairs({ -1, 1 }) do
		rod(m, "AditPost", f.at(u + s * (W / 2 - 0.5), y, 0.2), f.at(u + s * (W / 2 - 0.5), y + H - 0.4, 0.2), 0.8, Wood, timber)
	end
	rod(m, "AditLintel", f.at(u - W / 2, y + H - 0.4, 0.2), f.at(u + W / 2, y + H - 0.4, 0.2), 0.9, Wood, timber)
	for k = 1, 2 do
		rod(m, "AditSet", f.at(u - W / 2 + 0.4, y + H - 0.6, -k * 4), f.at(u + W / 2 - 0.4, y + H - 0.6, -k * 4), 0.6, Wood, timber)
	end
	-- Rails from inside out to the edge of the shelf, a cart gone over.
	for _, s in ipairs({ -1.2, 1.2 }) do
		rod(m, "MineRail", f.at(u + s, y + 0.2, -deep + 3), f.at(u + s, y + 0.2, 10), 0.2, Metal, rgb(110, 90, 70))
	end
	local cartAt = f.at(u, y - 1.5, 12.5)
	local cart = CFrame.lookAt(cartAt, cartAt + f.normal) * CFrame.Angles(math.rad(rng:NextNumber(55, 80)), 0, math.rad(rng:NextNumber(-15, 15)))
	part(m, "MineCart", Vector3.new(3.2, 2.4, 4.4), cart, Enum.Material.CorrodedMetal, rgb(120, 80, 50))
	for _, s in ipairs({ -1.6, 1.6 }) do
		cylinder(m, "CartWheel", 0.4, 1.4, cart * CFrame.new(s, -1.3, 0), Metal, rgb(50, 50, 52))
	end
	-- Things left on the shelf.
	TunnelProps.crate(m, CFrame.new(f.at(u + W / 2 + 2, y, 5)), Vector3.new(2.4, 2, 2.4), rng)
	if rng:NextNumber() < 0.6 then
		TunnelProps.barrel(m, CFrame.new(f.at(u - W / 2 - 2, y, 4)), rng)
	end
	local lit = rng:NextNumber() < 0.6
	TunnelProps.lantern(m, CFrame.new(f.at(u - W / 2 + 0.6, y + H - 2, 0.9)), rng, lit)
	-- A rope ladder down the face, a rusted pipe out of the rock.
	for _, s in ipairs({ -0.6, 0.6 }) do
		thin(rod(m, "RopeLadder", f.at(u + W / 2 + 4 + s, y, 11), f.at(u + W / 2 + 4 + s, y - rng:NextNumber(20, 40), 11.5), 0.12, Enum.Material.Fabric, rgb(150, 130, 96)))
	end
	local pipeY = y + rng:NextNumber(-10, 10)
	rod(m, "Pipe", f.at(u - W / 2 - 6, pipeY, -1), f.at(u - W / 2 - 6, pipeY, 3), 1.4, Enum.Material.CorrodedMetal, rgb(116, 76, 48))
	rod(m, "Pipe", f.at(u - W / 2 - 6, pipeY, 3), f.at(u - W / 2 - 6, pipeY - rng:NextNumber(20, 40), 3), 1.4, Enum.Material.CorrodedMetal, rgb(116, 76, 48))
end

-- ===== Hanging gardens =====

local function sidewaysTree(parent, base, outward, rng)
	local m = model(parent, "LedgeTree")
	local bark = jitter(rgb(78, 64, 50), rng, 0.1)
	local lean = rng:NextNumber(0.5, 1.1)
	local dir = (outward * math.sin(lean) + Vector3.yAxis * math.cos(lean)).Unit
	local len = rng:NextNumber(10, 18)
	local tip = base + dir * len
	rod(m, "Trunk", base, tip, rng:NextNumber(0.9, 1.4), Wood, bark)
	for _ = 1, rng:NextInteger(2, 4) do
		local from = base:Lerp(tip, rng:NextNumber(0.5, 0.95))
		local bdir = (dir + Vector3.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0, 0.8), rng:NextNumber(-0.8, 0.8))).Unit
		local b = from + bdir * rng:NextNumber(4, 7)
		rod(m, "Branch", from, b, 0.5, Wood, bark)
		for _ = 1, rng:NextInteger(1, 3) do
			local s = rng:NextNumber(3, 5.5)
			thin(ellipsoid(m, "Foliage", Vector3.new(s, s * 0.8, s), CFrame.new(b + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 1), rng:NextNumber(-1, 1))), Enum.Material.LeafyGrass, jitter(rgb(76, 110, 58), rng, 0.15)))
		end
	end
	local s = rng:NextNumber(4, 6)
	thin(ellipsoid(m, "Foliage", Vector3.new(s, s * 0.8, s), CFrame.new(tip), Enum.Material.LeafyGrass, jitter(rgb(76, 110, 58), rng, 0.15)))
end

local function vine(parent, top, outward, rng)
	local len = rng:NextNumber(12, 45)
	local prev = top
	local n = 4
	for k = 1, n do
		local p = top + Vector3.new(0, -len * k / n, 0) + outward * rng:NextNumber(0, 0.8) + Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
		thin(rod(parent, "Vine", prev, p, 0.35, Wood, rgb(70, 90, 50)))
		if rng:NextNumber() < 0.55 then
			thin(ellipsoid(parent, "Leaves", Vector3.new(2.4, 2, 2.4), CFrame.new(p), Enum.Material.LeafyGrass, jitter(rgb(80, 120, 60), rng, 0.15)))
		end
		prev = p
	end
end

local function gardens(parent, f, ledges, rng)
	local m = model(parent, "HangingGardens")
	local trees = 0
	for _, l in ipairs(ledges) do
		local edge = f.at(l.u, l.y, l.out + 1)
		if rng:NextNumber() < 0.22 and trees < 9 then
			trees += 1
			sidewaysTree(m, edge - f.normal * 0.5, f.normal, rng)
		end
		if rng:NextNumber() < 0.5 then
			for _ = 1, rng:NextInteger(1, 3) do
				vine(m, edge + f.along * rng:NextNumber(-6, 6) - Vector3.new(0, 1, 0), f.normal, rng)
			end
		end
	end
end

function CragFaces.build(parent, c, rng)
	local seed = rng:NextNumber(0, 1000)
	local m = model(parent, "CragFaces")
	local F = faces(c)
	root(c, rng)
	task.wait()
	local ledges = {}
	for name, f in pairs(F) do
		ledges[name] = shape(c, f, rng, seed + (if name == "south" then 0 else 50))
		task.wait()
	end
	-- The south-east corner, rounded off.
	for y = c.bottom + 10, c.top - 10, 16 do
		local r = rng:NextNumber(12, 20)
		terrain:FillBall(Vector3.new(c.x1 + rng:NextNumber(-4, 4), y, c.z0 + rng:NextNumber(-4, 4)), r, rockMaterial(rng, y))
	end
	local cols = basalt(m, c, F.south, rng)
	waterfall(m, c, F.south, cols.u, rng)
	-- Adits, in the bands clear of the tunnels, the incline and the maze.
	adit(m, c, F.south, 522, -232, rng)
	adit(m, c, F.south, 662, -196, rng)
	adit(m, c, F.east, 112, -228, rng)
	adit(m, c, F.east, -70, -262, rng)
	gardens(m, F.south, ledges.south, rng)
	gardens(m, F.east, ledges.east, rng)
end

return CragFaces
