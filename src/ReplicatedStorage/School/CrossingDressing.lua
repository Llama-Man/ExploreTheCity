-- The west crossing's dressing: what makes it look abandoned, lived-in
-- once, and out in the weather - without more wires across the sky.
-- Everything here is for looking at (nothing you can stand on or bump
-- into), and a lot of it moves in the wind (Windblown.lua).
--
--   catwalk()  along a catwalk: tape and rags tied to the rails, tarps
--              lashed to them, loose cable ends and buckets dangling
--              underneath, signs hanging off one bolt, weeds, rust
--              running down the steel, now and then a conduit slung under
--              it, and a crow if there's one to use.
--   hub()      on a hub: a windsock and torn streamers on the mast, a
--              banner down the column, vines, a laundry line on the low
--              deck, tarps flapping off the hut and over a stack of
--              stores on the top, a roof vent spinning.
--   cable()    things caught on the big cables: shoes over the wire, a
--              plastic bag, a rag.
--
-- Models from the toolbox: put them in a folder ReplicatedStorage.
-- CrossingAssets and they're used where they fit. So far: "Crow" (a
-- model, about a stud and a half tall, its pivot at its feet, facing
-- -Z).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local TunnelProps = require(script.Parent.TunnelProps)
local Wind = require(script.Parent.Windblown)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local Metal, Rust, Smooth, Fabric, Grass, Concrete = Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.SmoothPlastic, Enum.Material.Fabric, Enum.Material.LeafyGrass, Enum.Material.Concrete
local rgb = Color3.fromRGB
local UP = Vector3.yAxis

local RUST = rgb(116, 76, 50)
local DARK = rgb(34, 34, 36)
local ROPE = rgb(170, 150, 110)
local WEED = rgb(84, 112, 58)
local SIGNS = { "立入禁止", "足元注意", "危険", "通行止", "落下注意", "関係者以外立入禁止" }

local Dress = {}

local function deco(p)
	if p then
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
	end
	return p
end

local function rod(parent, name, a, b, d, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	return deco(cylinder(parent, name, len, d, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color))
end

local function flat(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-4 then f.Unit else Vector3.new(-1, 0, 0)
end

local function asset(name)
	local folder = ReplicatedStorage:FindFirstChild("CrossingAssets")
	local a = folder and folder:FindFirstChild(name)
	return if a and a:IsA("Model") then a else nil
end

local function crow(parent, cf)
	local src = asset("Crow")
	if not src then
		return false
	end
	local c = src:Clone()
	c:PivotTo(cf)
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			deco(d)
		end
	end
	c.Parent = parent
	return true
end

-- ===== Hanging things =====

-- A sign hanging off a rail by one bolt, from `top`, its face looking
-- `face`.
local function sign(parent, top, face, rng)
	local m = model(parent, "HangingSign")
	local drop = rng:NextNumber(0.6, 1.2)
	rod(m, "SignWire", top, top - UP * drop, 0.08, Metal, DARK)
	local c = top - UP * (drop + 0.7)
	local plate = label(m, CFrame.lookAt(c, c + face) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12))), Vector3.new(2.4, 1.3, 0.08), Enum.NormalId.Front, pick(SIGNS, rng), pick({ rgb(236, 232, 222), rgb(220, 180, 40) }, rng), rgb(170, 30, 26), Smooth, Enum.Font.GothamBlack)
	deco(plate)
	Wind.sway(m, top, 0.14, rng)
end

-- A loose cable hanging from `top`, a plug or a torn end on it.
local function looseCable(parent, top, rng)
	local m = model(parent, "LooseCable")
	local len = rng:NextNumber(3, 8)
	local color = pick({ DARK, rgb(40, 40, 40), rgb(160, 60, 40), rgb(60, 60, 120) }, rng)
	-- (a little kink part way down)
	local mid = top - UP * (len * 0.55) + Vector3.new(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3))
	rod(m, "Cable", top, mid, 0.18, Smooth, color)
	rod(m, "Cable", mid, top - UP * len, 0.18, Smooth, color)
	deco(part(m, "CableEnd", Vector3.new(0.4, 0.6, 0.3), top - UP * (len + 0.3), Smooth, pick({ DARK, rgb(200, 196, 186) }, rng)))
	Wind.sway(m, top, 0.2, rng, rng:NextNumber(1.6, 2.6))
end

-- A bucket on a rope.
local function bucket(parent, top, rng)
	local m = model(parent, "Bucket")
	local len = rng:NextNumber(2, 5)
	rod(m, "BucketRope", top, top - UP * len, 0.1, Fabric, ROPE)
	deco(cylinder(m, "Bucket", 1, 0.9, CFrame.new(top - UP * (len + 0.5)) * CFrame.Angles(0, 0, math.rad(90)), Metal, jitter(rgb(120, 124, 120), rng, 0.2)))
	Wind.sway(m, top, 0.1, rng)
end

-- A pair of trainers thrown over a cable, hanging by their laces.
local function shoes(parent, top, rng)
	local m = model(parent, "Shoes")
	local color = pick({ rgb(236, 236, 230), rgb(40, 40, 44), rgb(180, 50, 40) }, rng)
	for _, s in ipairs({ -1, 1 }) do
		local drop = rng:NextNumber(1.2, 2)
		local foot = top + Vector3.new(s * 0.3, -drop, 0)
		rod(m, "Lace", top, foot + UP * 0.2, 0.05, Fabric, rgb(236, 232, 222))
		deco(part(m, "Shoe", Vector3.new(0.45, 0.4, 1.1), CFrame.new(foot) * CFrame.Angles(math.rad(70), 0, 0), Fabric, color))
		deco(part(m, "Sole", Vector3.new(0.47, 0.12, 1.12), CFrame.new(foot) * CFrame.Angles(math.rad(70), 0, 0) * CFrame.new(0, -0.22, 0), Smooth, rgb(236, 232, 222)))
	end
	Wind.sway(m, top, 0.22, rng, rng:NextNumber(1.8, 2.6))
end

-- ===== Catwalks =====

-- Dress a catwalk a -> b, `w` wide, with rails on `rails` ("both",
-- "left", "right", "none").
function Dress.catwalk(ctx, m, a, b, w, rails)
	local rng = ctx.rng
	local len = (b - a).Magnitude
	if len < 5 then
		return
	end
	local dir = (b - a).Unit
	local right = flat(b - a):Cross(UP)
	local sides = {}
	if rails == "both" or rails == "left" then
		table.insert(sides, -1)
	end
	if rails == "both" or rails == "right" then
		table.insert(sides, 1)
	end
	local dm = model(m, "Dressing")
	local d = rng:NextNumber(2, 6)
	while d < len - 2 do
		local p = a + dir * d
		local s = if #sides > 0 then pick(sides, rng) else pick({ -1, 1 }, rng)
		local edge = p + right * s * (w / 2)
		local r = rng:NextNumber()
		if #sides > 0 and r < 0.26 then
			-- tape or a rag tied to a post
			Wind.tape(dm, edge + right * s * 0.1 + UP * rng:NextNumber(1.6, 3.3), rng)
		elseif #sides > 0 and r < 0.42 then
			-- a tarp lashed to the rail, hanging over the side
			local half = rng:NextNumber(1.2, 2.2)
			local top = UP * 3.25 + right * s * 0.25
			Wind.cloth(dm, edge - dir * half + top, edge + dir * half + top, rng:NextNumber(2.5, 4.5), right * s, rng, {
				name = "Tarp", color = pick(Wind.TARPS, rng), tattered = rng:NextNumber() < 0.6, thick = 0.1,
			})
		elseif r < 0.6 then
			looseCable(dm, p + right * s * (w / 2 - 0.4) - UP * 1.2, rng)
		elseif #sides > 0 and r < 0.68 then
			sign(dm, edge + right * s * 0.2 + UP * 3.1, right * s, rng)
		elseif r < 0.73 then
			bucket(dm, p + right * s * (w / 2 + 0.3) - UP * 1.1, rng)
		elseif r < 0.86 then
			-- weeds where the grating meets the stringer
			for _ = 1, rng:NextInteger(2, 4) do
				local q = p + dir * rng:NextNumber(-1.5, 1.5) + right * s * (w / 2 - 0.35)
				local sz = rng:NextNumber(0.4, 0.9)
				deco(ellipsoid(dm, "Weed", Vector3.new(sz, sz * 0.7, sz), CFrame.new(q + UP * sz * 0.2), Grass, jitter(WEED, rng, 0.2)))
			end
		else
			-- rust run down the stringer
			for _ = 1, rng:NextInteger(1, 3) do
				local q = p + dir * rng:NextNumber(-1.5, 1.5) + right * s * (w / 2 + 0.02)
				deco(part(dm, "RustRun", Vector3.new(0.04, rng:NextNumber(0.8, 1.6), rng:NextNumber(0.2, 0.5)), CFrame.lookAt(q - UP * 0.9, q - UP * 0.9 + dir), Rust, jitter(RUST, rng, 0.15)))
			end
		end
		if #sides > 0 and rng:NextNumber() < 0.05 then
			local s2 = pick(sides, rng)
			crow(dm, CFrame.lookAt(p + right * s2 * (w / 2 - 0.1) + UP * 3.45, p + right * s2 * (w / 2 + 3) + UP * 3.45 + dir * rng:NextNumber(-2, 2)))
		end
		d += rng:NextNumber(6, 11)
	end
	-- now and then a conduit slung along under it
	if len > 10 and rng:NextNumber() < 0.35 then
		local s = pick({ -1, 1 }, rng)
		local off = right * s * (w / 2 - 0.6) - UP * 1.55
		local color = pick({ rgb(120, 110, 96), rgb(96, 100, 96), RUST, rgb(70, 96, 110) }, rng)
		rod(dm, "Conduit", a + off + dir * 0.5, b + off - dir * 0.5, 0.45, Metal, color)
		for k = 2, len - 1, 4 do
			deco(part(dm, "ConduitClip", Vector3.new(0.7, 0.5, 0.2), CFrame.lookAt(a + dir * k + off + UP * 0.25, a + dir * k + off + UP * 0.25 + dir), Metal, darken(color, 0.7)))
		end
	end
end

-- ===== Hubs =====

-- h: the hub (x, z, low, high, kind, model, anchor).
function Dress.hub(h, rng)
	local m = model(h.model, "Dressing")
	local x, z, low, high = h.x, h.z, h.low, h.high
	local across = Vector3.new(-Wind.DIR.Z, 0, Wind.DIR.X)
	-- the windsock, on an arm off the mast (or the tank's rim)
	if h.kind == "tank" then
		local foot = Vector3.new(x, high + 27, z) - across * 7.2
		rod(m, "SockPole", foot, foot + UP * 4, 0.25, Metal, rgb(142, 146, 146))
		Wind.windsock(m, foot + UP * 4, rng)
	else
		local at = Vector3.new(x, high + 30, z)
		rod(m, "SockArm", at, at - across * 3.2, 0.25, Metal, rgb(142, 146, 146))
		Wind.windsock(m, at - across * 3.2, rng)
		-- what's left of flags tied on up the mast
		for _ = 1, rng:NextInteger(2, 4) do
			local y = rng:NextNumber(8, 34)
			local r = 2.5 * (1 - 0.6 * y / 40)
			Wind.flag(m, Vector3.new(x, high + y, z) + across * pick({ -r, r }, rng), rng:NextNumber(2.5, 6), rng, {
				name = "Streamer", height = rng:NextNumber(0.35, 0.8), taper = 0.4, droop = 0.7,
				colors = { pick({ rgb(180, 60, 50), rgb(236, 232, 222), rgb(60, 80, 140), rgb(220, 180, 40) }, rng) },
			})
		end
	end
	-- a banner down the column's windward side
	local wy = high - 2.3
	local half = rng:NextNumber(1.8, 2.8)
	local zo = rng:NextNumber(-2, 2)
	Wind.banner(m, Vector3.new(x - 6.15, wy, z + zo - half), Vector3.new(x - 6.15, wy, z + zo + half), rng:NextNumber(9, 16), Vector3.new(-1, 0, 0), rng, pick({ rgb(160, 50, 40), rgb(50, 60, 110), rgb(210, 204, 190), rgb(40, 40, 44) }, rng))
	rod(m, "BannerBar", Vector3.new(x - 6.2, wy + 0.1, z + zo - half - 0.3), Vector3.new(x - 6.2, wy + 0.1, z + zo + half + 0.3), 0.2, Metal, DARK)
	-- vines off the low deck's edge and down from the top
	for _ = 1, rng:NextInteger(4, 7) do
		local side = pick({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }, rng)
		local along = Vector3.new(side.Z, 0, side.X) * rng:NextNumber(-10, 10)
		Wind.vine(m, Vector3.new(x, low - 1.3, z) + side * 11.4 + along, rng:NextNumber(4, 13), side, rng)
	end
	for _ = 1, rng:NextInteger(2, 4) do
		local side = pick({ Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }, rng)
		local along = Vector3.new(side.Z, 0, side.X) * rng:NextNumber(-8, 8)
		Wind.vine(m, Vector3.new(x, high - 2, z) + side * 10.2 + along, rng:NextNumber(5, 16), side, rng)
	end
	-- a laundry line on the low deck's north side, from the lamp post
	local la, lb = Vector3.new(x + 8, low + 6.2, z + 8.6), Vector3.new(x - 8, low + 6.2, z + 8.6)
	rod(m, "LinePole", Vector3.new(x - 8, low, z + 8.6), lb + UP * 0.3, 0.25, Metal, rgb(142, 146, 146))
	rod(m, "WashingLine", la, lb, 0.06, Fabric, rgb(220, 216, 200))
	local f = rng:NextNumber(1, 3)
	while f < 15 do
		local wid = rng:NextNumber(1, 1.8)
		local p0 = la:Lerp(lb, f / 16)
		Wind.cloth(m, p0, la:Lerp(lb, (f + wid) / 16), rng:NextNumber(1.2, 2.4), Vector3.new(0, 0, 1), rng, {
			name = "Laundry", color = pick({ rgb(236, 232, 222), rgb(120, 150, 190), rgb(200, 120, 120), rgb(90, 90, 96), rgb(230, 200, 120) }, rng), thick = 0.06, strip = 0.6,
		})
		f += wid + rng:NextNumber(0.6, 2.4)
	end
	-- the hut on top: a tarp off its roof, and a vent spinning on it
	local hx, hz = x - 5, z + 5.5
	Wind.cloth(m, Vector3.new(hx - 3.3, high + 6.3, hz - 2.2), Vector3.new(hx - 3.3, high + 6.3, hz + 2.2), rng:NextNumber(2.5, 4.5), Vector3.new(-1, 0, 0), rng, {
		name = "Tarp", color = pick(Wind.TARPS, rng), tattered = true, thick = 0.1,
	})
	Wind.whirly(m, Vector3.new(hx + 1.5, high + 6.35, hz), rng)
	-- stores under a tarp, one corner torn loose
	local sc = CFrame.new(x + 6.5, high, z - 6.5) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0)
	for _, c in ipairs({ { -0.7, 0, 0.9 }, { 0.9, 0, -0.4 }, { 0.1, 1.2, 0.2 } }) do
		part(m, "Crate", Vector3.new(1.6, 1.2, 1.6), sc * CFrame.new(c[1], c[2] + 0.6, c[3]), Enum.Material.Wood, jitter(rgb(130, 100, 70), rng, 0.1))
	end
	local tarpColor = pick(Wind.TARPS, rng)
	deco(part(m, "TarpOver", Vector3.new(3.8, 0.12, 3.8), sc * CFrame.new(0.1, 2.46, 0.1), Fabric, tarpColor))
	for _, s in ipairs({ -1, 1 }) do
		deco(part(m, "TarpSide", Vector3.new(0.12, 2.2, 3.8), sc * CFrame.new(s * 1.9, 1.4, 0.1) * CFrame.Angles(0, 0, s * 0.1), Fabric, tarpColor))
	end
	local e1, e2 = (sc * CFrame.new(-1.9, 2.4, 2)).Position, (sc * CFrame.new(1.9, 2.4, 2)).Position
	Wind.cloth(m, e1, e2, 2.2, sc.LookVector * -1, rng, { name = "TarpCorner", color = tarpColor, tattered = true, thick = 0.12 })
	-- and a flag, on its own pole at the corner
	local fp = Vector3.new(x - 9, high, z - 9)
	rod(m, "FlagPole", fp, fp + UP * 8, 0.3, Metal, rgb(142, 146, 146))
	Wind.flag(m, fp + UP * 7.6, rng:NextNumber(3, 4.5), rng, {
		name = "Flag", height = 2.2, taper = 0.6, droop = 0.9,
		colors = { pick({ rgb(236, 232, 222), rgb(180, 60, 50), rgb(60, 80, 140) }, rng) },
	})
end

-- ===== On the cables =====

function Dress.cable(parent, p, rng)
	local r = rng:NextNumber()
	if r < 0.4 then
		shoes(parent, p - UP * 0.4, rng)
	elseif r < 0.75 then
		Wind.flag(parent, p - UP * 0.4, rng:NextNumber(1.2, 2), rng, {
			name = "Bag", height = rng:NextNumber(0.7, 1.1), taper = 0.5, droop = 0.8, segs = 3,
			colors = { pick({ rgb(236, 238, 240), rgb(90, 130, 190), rgb(200, 190, 60) }, rng) }, material = Enum.Material.Plastic,
		})
	else
		Wind.tape(parent, p - UP * 0.4, rng)
	end
end

return Dress
