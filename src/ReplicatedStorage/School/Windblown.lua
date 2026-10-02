-- The wind, and things that move in it.
--
-- One wind for the whole world, off the fog in the west: a steady blow
-- that swells and drops, with gusts that roll across from west to east
-- (so a gust hits the far hubs a moment before the near ones). It's all
-- worked out from the server's clock, so everyone sees the same gusts.
--
-- The things it moves are built here, on the server, and moved on each
-- player's machine (Wind.client) - models tagged "Windblown", by their
-- Kind attribute:
--   Cloth   a sheet hung from an edge, in strips: tarps, rags, banners,
--           vines, laundry. With a Bottom, tied at the foot too, so it
--           billows instead.
--   Flag    a strip streaming out from a point: flags, tape, streamers,
--           a torn bag caught on a cable, a windsock.
--   Sway    a thing hung from one point, rocking in the gusts: signs on a
--           chain, a loose cable end, a bucket, shoes over a wire.
--   Spin    something the wind turns: a roof vent, a pinwheel.
--   Kite    something flying on a tether: it leans downwind from its
--           tether's foot and bobs, and its rotor (parts with a Rotor
--           attribute) spins - Kazami's floating wind turbines.
-- Every one is built already in the pose the wind would give it, so it
-- looks right even before it moves.

local BuildUtil = require(script.Parent.BuildUtil)

local part, cylinder, model, jitter = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter
local rgb = Color3.fromRGB
local UP = Vector3.yAxis

local Wind = {}

-- The way it blows (towards: east, a little north).
Wind.DIR = Vector3.new(0.94, 0, 0.34).Unit
-- (the axis a hung thing leans about, to lean downwind)
local LEAN_AXIS = Wind.DIR:Cross(UP)

-- How hard it's blowing at `pos` at time `t`: about 0.3 in a lull, 0.6
-- on average, up to about 1.2 in the worst of a gust.
function Wind.strength(t, pos)
	local u = t - (if pos then pos:Dot(Wind.DIR) / 45 else 0)
	local base = 0.5 + 0.12 * math.sin(u * 0.13) + 0.07 * math.sin(u * 0.31 + 1.3)
	local g1 = (math.sin(u * 0.29) * 0.5 + 0.5) ^ 6
	local g2 = (math.sin(u * 0.71 + 2) * 0.5 + 0.5) ^ 8
	return base + 0.45 * g1 + 0.2 * g2
end
-- (the blow everything's built in)
Wind.AVERAGE = 0.6

local function rotateAbout(v, axis, a)
	return v * math.cos(a) + axis:Cross(v) * math.sin(a) + axis * axis:Dot(v) * (1 - math.cos(a))
end

-- ===== Poses: where each part goes, for a strength and a time =====

-- Cloth. info: top (the hanging edge's middle), edge (unit, along it),
-- face (unit, flat: the way its front looks), len (each strip's), n,
-- stiff (0 limp .. 1 board), phase, offs[i] (a strip's shift along the
-- edge), and for a tied one bottom (the foot's middle) and billow.
local function clothPose(info, t, s)
	local out = {}
	local push = Wind.DIR:Dot(info.face)
	-- (blown back, it's pressed against whatever it hangs on)
	if push < 0 then
		push *= 0.2
	end
	local limp = 1 - info.stiff
	if info.bottom then
		local run = info.bottom - info.top
		local function at(k)
			local bulge = info.billow * math.sin(math.pi * k) * (0.35 + 0.65 * math.max(push, 0.25) * s) * (0.85 + 0.15 * math.sin(t * 1.6 - k * 3 + info.phase))
			return info.top + run * k + info.face * bulge
		end
		for i = 1, info.n do
			local a, b = at((i - 1) / info.n), at(i / info.n)
			local dir = (b - a).Unit
			local edge = (info.edge - dir * info.edge:Dot(dir)).Unit
			out[i] = CFrame.fromMatrix((a + b) / 2 + edge * (info.offs[i] or 0), edge, dir:Cross(edge), dir)
		end
		return out
	end
	local p = info.top
	for i = 1, info.n do
		local k = i / info.n
		local lean = push * s * (0.3 + 0.8 * k) * limp
		local flap = math.sin(t * (1.8 + 1.4 * s) - i * 0.7 + info.phase) * (0.03 + 0.14 * k) * math.min(s, 1.2) * (0.3 + 0.7 * limp)
		local a = math.clamp(lean + flap, -0.3, 1.35)
		local dir = -UP * math.cos(a) + info.face * math.sin(a)
		-- and a ripple across it
		local twist = math.sin(t * 2.4 - i * 1.1 + info.phase * 2) * 0.1 * k * math.min(s, 1.2) * limp
		local edge = rotateAbout((info.edge - dir * info.edge:Dot(dir)).Unit, dir, twist)
		out[i] = CFrame.fromMatrix(p + dir * (info.len / 2) + edge * (info.offs[i] or 0), edge, dir:Cross(edge), dir)
		p += dir * info.len
	end
	return out
end

-- Flag. info: anchor, n, seg (each segment's length), droop (radians, in
-- a lull), stiff, phase.
local function flagPose(info, t, s)
	local out = {}
	local p = info.anchor
	local limp = 1 - info.stiff
	for i = 1, info.n do
		local k = i / info.n
		local yaw = math.sin(t * (2.4 + 1.6 * s) - i * 0.7 + info.phase) * (0.05 + 0.24 * k) * (0.4 + 0.6 * math.min(s, 1.2)) * (0.35 + 0.65 * limp)
		local droop = math.clamp(info.droop * (1.4 - math.min(s, 1.2)) * (0.6 + 0.8 * k), 0, 1.3)
		local d = rotateAbout(Wind.DIR, UP, yaw)
		local dir = d * math.cos(droop) - UP * math.sin(droop)
		local c = p + dir * (info.seg / 2)
		out[i] = CFrame.lookAt(c, c + dir)
		p += dir * info.seg
	end
	return out
end

-- Sway: the whole thing's turn about its pivot. info: amount (radians
-- at an average blow), phase, period.
local function swayTurn(info, t, s)
	local lean = info.amount * 0.6 * s
	local rock = info.amount * math.sin(t * (2 * math.pi / info.period) + info.phase) * (0.3 + 0.4 * s)
	local across = info.amount * 0.4 * math.sin(t * (2 * math.pi / info.period) * 0.7 + info.phase * 1.7) * s
	return CFrame.fromAxisAngle(LEAN_AXIS, lean + rock) * CFrame.fromAxisAngle(Wind.DIR, across)
end

-- Kite: leaning over downwind from its tether's foot, bobbing and
-- drifting. info: amount (radians at an average blow), phase.
local function kiteTurn(info, t, s)
	local lean = -info.amount * (0.4 + 0.9 * s)
	local bob = info.amount * 0.25 * math.sin(t * 0.5 + info.phase)
	local across = info.amount * 0.3 * math.sin(t * 0.33 + info.phase * 1.3)
	return CFrame.fromAxisAngle(LEAN_AXIS, lean + bob) * CFrame.fromAxisAngle(Wind.DIR, across)
end

Wind.clothPose, Wind.flagPose, Wind.swayTurn, Wind.kiteTurn = clothPose, flagPose, swayTurn, kiteTurn

-- Read a model's info back from its attributes (Wind.client).
function Wind.info(m)
	local kind = m:GetAttribute("Kind")
	local info = {
		kind = kind,
		phase = m:GetAttribute("Phase") or 0,
		stiff = m:GetAttribute("Stiff") or 0,
		n = m:GetAttribute("Count") or 1,
	}
	if kind == "Cloth" then
		info.top, info.edge, info.face = m:GetAttribute("Top"), m:GetAttribute("Edge"), m:GetAttribute("Face")
		info.len = m:GetAttribute("Len")
		info.bottom, info.billow = m:GetAttribute("Bottom"), m:GetAttribute("Billow") or 0
		info.offs = {}
	elseif kind == "Flag" then
		info.anchor, info.seg, info.droop = m:GetAttribute("Anchor"), m:GetAttribute("Seg"), m:GetAttribute("Droop") or 0.6
	elseif kind == "Sway" or kind == "Kite" then
		info.pivot = m:GetAttribute("Pivot")
		info.amount, info.period = m:GetAttribute("Amount") or 0.1, m:GetAttribute("Period") or 3
		info.rotorC, info.rotorAxis, info.rate = m:GetAttribute("RotorC"), m:GetAttribute("RotorAxis"), m:GetAttribute("Rate") or 2
	elseif kind == "Spin" then
		info.pivot, info.axis, info.rate = m:GetAttribute("Pivot"), m:GetAttribute("Axis"), m:GetAttribute("Rate") or 3
	end
	return info
end

-- ===== Building them =====

local AVERAGE = Wind.AVERAGE

local function flimsy(p)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Anchored = true
	return p
end

local function tag(m, kind, attrs, phase)
	m:SetAttribute("Kind", kind)
	m:SetAttribute("Phase", phase)
	for k, v in pairs(attrs) do
		m:SetAttribute(k, v)
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m:AddTag("Windblown")
	return m
end

-- Cloth hung from edge a -> b, `drop` long, its front looking `face`
-- (made flat and square to the edge). o: color, material, stiff, strip
-- (length of each; about 0.9), tattered (ragged lower strips), bottom
-- (tie its foot: a Vector3 for the foot's middle) and billow, name.
function Wind.cloth(parent, a, b, drop, face, rng, o)
	o = o or {}
	local edge = (b - a).Unit
	local width = (b - a).Magnitude
	face = Vector3.new(face.X, 0, face.Z)
	face = (face - edge * face:Dot(edge))
	face = if face.Magnitude > 0.01 then face.Unit else edge:Cross(UP).Unit
	local n = math.clamp(math.round(drop / (o.strip or 0.9)), 2, 12)
	local len = drop / n
	local info = {
		top = (a + b) / 2, edge = edge, face = face, len = len, n = n, stiff = o.stiff or 0,
		phase = rng:NextNumber(0, 6.28), offs = {}, bottom = o.bottom, billow = o.billow or 0,
	}
	local m = model(parent, o.name or "Cloth")
	local widths = {}
	for i = 1, n do
		widths[i] = width
		if o.tattered and i > n * 0.55 then
			-- the lower strips torn narrower, and off to one side or other
			local cut = rng:NextNumber(0, 0.4) * width * (i / n)
			widths[i] = width - cut
			info.offs[i] = (if rng:NextNumber() < 0.5 then -1 else 1) * cut / 2
		end
	end
	local poses = clothPose(info, 0, AVERAGE)
	local color = o.color or rgb(70, 100, 150)
	for i = 1, n do
		local strip = flimsy(part(m, "S" .. i, Vector3.new(widths[i], o.thick or 0.08, len + 0.12), poses[i], o.material or Enum.Material.Fabric, jitter(color, rng, 0.04)))
		if info.offs[i] then
			strip:SetAttribute("X", info.offs[i])
		end
	end
	tag(m, "Cloth", { Top = info.top, Edge = edge, Face = face, Len = len, Count = n, Stiff = info.stiff, Bottom = o.bottom, Billow = info.billow }, info.phase)
	return m
end

-- A strip streaming out from `anchor`, `length` long. o: height (its
-- width, top to bottom: 0.3 for tape, 2 for a flag), colors (a list: it
-- takes them in turn, segment by segment), droop, stiff, taper (the far
-- end's height as a share of the near's), segs, thick, sock (a windsock:
-- square and tapering), name.
function Wind.flag(parent, anchor, length, rng, o)
	o = o or {}
	local n = o.segs or math.clamp(math.round(length / 0.8), 2, 10)
	local info = { anchor = anchor, n = n, seg = length / n, droop = o.droop or 0.5, stiff = o.stiff or 0, phase = rng:NextNumber(0, 6.28) }
	local m = model(parent, o.name or "Flag")
	local poses = flagPose(info, 0, AVERAGE)
	local colors = o.colors or { rgb(200, 60, 50) }
	local h = o.height or 1.5
	for i = 1, n do
		local hi = h * (1 - (1 - (o.taper or 1)) * (i - 1) / math.max(1, n - 1))
		local size = if o.sock then Vector3.new(hi, hi, info.seg + 0.05) else Vector3.new(o.thick or 0.06, hi, info.seg + 0.05)
		flimsy(part(m, "S" .. i, size, poses[i], o.material or Enum.Material.Fabric, colors[(i - 1) % #colors + 1]))
	end
	tag(m, "Flag", { Anchor = anchor, Count = n, Seg = info.seg, Droop = info.droop, Stiff = info.stiff }, info.phase)
	return m
end

-- Make model `m` (built hanging straight down from `pivot`) rock in the
-- wind. amount: radians it leans at an average blow.
function Wind.sway(m, pivot, amount, rng, period)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			flimsy(d)
		end
	end
	local phase = rng:NextNumber(0, 6.28)
	period = period or rng:NextNumber(2.2, 3.6)
	-- (built in its average lean)
	local turn = swayTurn({ amount = amount, phase = phase, period = period }, 0, AVERAGE)
	local rest = CFrame.new(pivot)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = rest * turn * rest:ToObjectSpace(d.CFrame)
		end
	end
	tag(m, "Sway", { Pivot = pivot, Amount = amount, Period = period }, phase)
	return m
end

-- Make model `m` turn about `axis` through `pivot` as the wind blows.
function Wind.spin(m, pivot, axis, rate, rng)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
		end
	end
	tag(m, "Spin", { Pivot = pivot, Axis = axis.Unit, Rate = rate }, rng:NextNumber(0, 6.28))
	return m
end

-- Make model `m` (built standing straight up from `pivot`, its tether's
-- foot) fly: leaning downwind, bobbing. Parts with a Rotor attribute spin
-- about `axis` through `rotorC` (both as built), `rate` a second in an
-- average blow.
function Wind.kite(m, pivot, amount, rotorC, axis, rate, rng)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			flimsy(d)
		end
	end
	local phase = rng:NextNumber(0, 6.28)
	local turn = kiteTurn({ amount = amount, phase = phase }, 0, AVERAGE)
	local rest = CFrame.new(pivot)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = rest * turn * rest:ToObjectSpace(d.CFrame)
		end
	end
	tag(m, "Kite", { Pivot = pivot, Amount = amount, RotorC = rotorC, RotorAxis = axis.Unit, Rate = rate }, phase)
	return m
end

-- ===== Ready-made =====

Wind.TARPS = { rgb(58, 96, 150), rgb(70, 110, 160), rgb(190, 110, 50), rgb(84, 110, 76), rgb(150, 146, 136), rgb(170, 60, 44) }

-- A hanging vine: a narrow green strip, tattered, from `top` down `drop`.
function Wind.vine(parent, top, drop, face, rng)
	local w = rng:NextNumber(0.5, 1.1)
	local edge = Vector3.new(-face.Z, 0, face.X).Unit
	return Wind.cloth(parent, top - edge * w / 2, top + edge * w / 2, drop, face, rng, {
		name = "Vine", color = rgb(70, 100, 52), material = Enum.Material.LeafyGrass, tattered = true, thick = 0.25, strip = 1.2,
	})
end

-- Hazard tape (or a rag) tied to a post, streaming off it.
function Wind.tape(parent, at, rng)
	local tape = rng:NextNumber() < 0.6
	return Wind.flag(parent, at, rng:NextNumber(2, 4.5), rng, {
		name = if tape then "Tape" else "Rag",
		height = if tape then 0.3 else rng:NextNumber(0.5, 0.9),
		colors = if tape then { rgb(220, 180, 40), rgb(30, 30, 30) } else { jitter(rgb(170, 160, 140), rng, 0.2) },
		droop = 0.8, taper = if tape then 1 else 0.5,
	})
end

-- A windsock on a little arm at `at`.
function Wind.windsock(parent, at, rng)
	return Wind.flag(parent, at, 5, rng, {
		name = "Windsock", sock = true, height = 1.6, taper = 0.45, segs = 5, stiff = 0.5, droop = 1,
		colors = { rgb(230, 100, 40), rgb(236, 232, 222) }, material = Enum.Material.Fabric,
	})
end

-- A tattered banner hung down a wall from `a` to `b` (its top edge).
function Wind.banner(parent, a, b, drop, face, rng, color)
	return Wind.cloth(parent, a, b, drop, face, rng, {
		name = "Banner", color = color or rgb(160, 50, 40), tattered = true, strip = 1.4,
	})
end

-- A little turbine vent (a roof "whirlybird"), spun by the wind.
function Wind.whirly(parent, base, rng)
	local m = model(parent, "RoofVent")
	part(m, "VentNeck", Vector3.new(1, 0.8, 1), base + UP * 0.4, Enum.Material.Metal, rgb(120, 122, 120))
	local head = model(m, "VentHead")
	local c = base + UP * 1.5
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		part(head, "Vane", Vector3.new(0.1, 1.2, 0.5), CFrame.new(c) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.65) * CFrame.Angles(0, 0.5, 0), Enum.Material.Metal, rgb(150, 152, 150))
	end
	cylinder(head, "VentCap", 0.25, 1.6, CFrame.new(c + UP * 0.7) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, rgb(140, 142, 140))
	Wind.spin(head, c, UP, rng:NextNumber(2.5, 4), rng)
	return m
end

return Wind
