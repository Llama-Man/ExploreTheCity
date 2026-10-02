-- The chain of ships.
--
-- The trawler's anchor doesn't just hang: it's pulled out at an angle by a
-- colossal chain that runs from its crown east, out over the drop and down,
-- in one long sag, into the fog: to the winch of a dead harbour that
-- stands at the fog's edge as if it were the sea (Port.lua). From it hang
-- ships, by their bows, nose up and stern down, the further ones with
-- their sterns already in the fog, all of them near their real size: fishing boats,
-- sailing ships, junks, tugs, a ferry, a container ship with its boxes
-- sticking out sideways, a yacht, a submarine, rowing boats in bunches.
--
-- The way across is the chain itself: planks lashed along its top, railed,
-- all the way down to the harbour. From it, rope ladders drop
-- to a hole in each ship's deck near the bow. Hung like this, a ship is a
-- tower: its bulkheads are floors, with a ladder running up through the
-- hatches in them, and neighbouring ships are joined by rope bridges
-- through holes torn in their sides. A ladder from the trawler's bow comes
-- The walk starts on the trawler's foredeck, where the chain goes out over
-- her stem; a rope bridge crosses from the ledge where the tunnels come out on
-- the crag's east face into the side of the first ship.
--
-- Ships are built in their own frame (keel at y = 0, bow toward +X, deck
-- at y = D, beam along Z) and pivoted into their hanging pose.

local BuildUtil = require(script.Parent.BuildUtil)
local Fixtures = require(script.Parent.StoreFixtures)
local TunnelProps = require(script.Parent.TunnelProps)
local Port = require(script.Parent.Port)
local Config = require(script.Parent.SchoolConfig)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local label = Fixtures.label
local ellipsoid = TunnelProps.ellipsoid
local Wood, Planks, Metal, Rust, Smooth, Fabric, Neon, Glass, Plate = Enum.Material.Wood, Enum.Material.WoodPlanks, Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.SmoothPlastic, Enum.Material.Fabric, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.DiamondPlate
local rgb = Color3.fromRGB
local UP = Vector3.yAxis
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local RUST = rgb(116, 72, 44)
local DARK = rgb(28, 28, 30)
local ROPE = rgb(170, 150, 110)
local TIMBER = rgb(110, 84, 58)
local WINDOW = rgb(40, 46, 50)
local LADDER = rgb(200, 170, 40)
local WEED = { rgb(60, 80, 44), rgb(84, 90, 50), rgb(70, 60, 40) }

-- The great chain's curve: one long sag from the anchor's crown down to
-- FAR, where the port's winch holds it, just above the fog (Port.lua). A
-- parabola whose lowest point would be SAG_PAST beyond the winch: steep
-- off the trawler, easing as it comes down, still falling as it arrives.
local FAR = { x = Port.CHAIN_END_X, y = Port.CHAIN_END_Y }
local SAG_PAST = 800
local PATH_END_X = FAR.x - 330 -- the ships you can climb about in stop about here
local WALK_END_X = FAR.x -- the walk goes on, all the way to the port
-- The ships you climb about in hang clear of the fog (the rest don't).
local KEEP_ABOVE = Config.FOG_TOP + 8
local CHAIN_Z = 62 -- it drifts north of the anchor, clear of the ledge
-- The great chain's links, and the top of the walk laid along them.
local LINK, WIDE, BAR = 22, 10, 3
local WALK_Y = WIDE / 2 + BAR / 2 + 0.4 -- above the chain's centre line
local WALK_HALF = 2.8

local ChainOfShips = {}

-- ===== Bits =====

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function deco(p)
	if p then
		p.CanCollide = false
		p.CastShadow = false
	end
	return p
end

local function marker(parent, name, tag, pos)
	local p = part(parent, name, Vector3.new(2, 2, 2), pos + UP, Smooth, rgb(255, 0, 0))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p:AddTag(tag)
	return p
end

local lightsLeft = 0
local function glow(p, range, color)
	if lightsLeft > 0 then
		lightsLeft -= 1
		local l = Instance.new("PointLight")
		l.Range = range
		l.Brightness = 1.2
		l.Color = color or rgb(255, 196, 130)
		l.Parent = p
	end
end

-- A climbable ladder between two points: a hidden truss (Roblox climbs
-- those) behind two ropes and rungs, or a steel ladder you can see.
local function ladder(parent, a, b, steel)
	local len = (b - a).Magnitude
	local t = Instance.new("TrussPart")
	t.Name = "LadderTruss"
	t.Anchored = true
	t.Size = Vector3.new(2, math.max(2, math.ceil(len / 2) * 2), 2)
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else UP
	t.CFrame = CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(-math.pi / 2, 0, 0)
	t.Material = Metal
	t.Color = LADDER
	t.Transparency = if steel then 0 else 1
	t.Parent = parent
	if not steel then
		local dir = (b - a).Unit
		local side = dir:Cross(Vector3.xAxis)
		side = if side.Magnitude < 0.1 then dir:Cross(Vector3.zAxis).Unit else side.Unit
		for _, s in ipairs({ -1, 1 }) do
			deco(rod(parent, "LadderRope", a + side * s * 1.1, b + side * s * 1.1, 0.16, Fabric, ROPE))
		end
		for d = 1, len - 0.5, 1.2 do
			local p = a + dir * d
			deco(rod(parent, "Rung", p - side * 1.1, p + side * 1.1, 0.22, Wood, TIMBER))
		end
	end
	return t
end

-- ===== The great chain =====

local crown -- the anchor's crown, where it starts (set in build)
local vertexX, vertexY -- the sag's lowest point, past the winch (set in build)

local function chainY(x)
	local t = (vertexX - x) / (vertexX - crown.X)
	return vertexY + (crown.Y - vertexY) * t * t
end

local function chainSlope(x)
	return -2 * (crown.Y - vertexY) * (vertexX - x) / (vertexX - crown.X) ^ 2
end

local function chainZ(x)
	local t = math.clamp((x - crown.X) / 320, 0, 1)
	t = t * t * (3 - 2 * t)
	return crown.Z + (CHAIN_Z - crown.Z) * t + 18 * math.sin((x - crown.X) / 300) * t
end

local function chainAt(x)
	return Vector3.new(x, chainY(x), chainZ(x))
end

-- The heading along the chain at x (horizontal).
local function headingAt(x)
	local dz = (chainZ(x + 2) - chainZ(x - 2)) / 4
	return Vector3.new(1, 0, dz).Unit
end

-- Links like rings: two side bars and two ends, turned alternately flat
-- and upright, all the way out into the fog.
local function greatChain(parent, rng)
	local m = model(parent, "GreatChain")
	local step = LINK * 0.74
	local x = crown.X + LINK * 0.45
	local k = 0
	while x < FAR.x do
		local p = chainAt(x)
		local slope = chainSlope(x)
		local dir = (headingAt(x) + UP * slope).Unit
		local side = dir:Cross(UP).Unit
		local vert = side:Cross(dir).Unit
		local a = if k % 2 == 0 then side else vert
		local color = jitter(RUST, rng, 0.08)
		for _, s in ipairs({ -1, 1 }) do
			rod(m, "Link", p + a * s * (WIDE / 2) - dir * (LINK / 2 - BAR), p + a * s * (WIDE / 2) + dir * (LINK / 2 - BAR), BAR, Rust, color)
			rod(m, "Link", p + dir * s * (LINK / 2 - BAR / 2) - a * (WIDE / 2), p + dir * s * (LINK / 2 - BAR / 2) + a * (WIDE / 2), BAR, Rust, color)
		end
		if rng:NextNumber() < 0.14 then
			deco(rod(m, "ChainWeed", p - vert * 4, p - vert * 4 - UP * rng:NextNumber(3, 10), 0.6, Fabric, pick(WEED, rng)))
		end
		x += step / math.sqrt(1 + slope * slope)
		k += 1
	end
	return m
end

-- The walk along the top of the chain, from `x0` to WALK_END_X: planks
-- lashed across the links, a rope rail each side (gaps where a ladder
-- goes down, `gaps` = list of { x, side }).
local function chainWalk(parent, x0, gaps, rng)
	local m = model(parent, "ChainWalk")
	local function walkAt(x)
		return chainAt(x) + UP * WALK_Y
	end
	local function gapNear(x, side)
		for _, g in ipairs(gaps) do
			if g.side == side and math.abs(g.x - x) < 3.5 then
				return true
			end
		end
		return false
	end
	local x = x0
	local prevPost = {}
	while x < WALK_END_X do
		local slope = chainSlope(x)
		local run = 1.4 / math.sqrt(1 + slope * slope)
		local a, b = walkAt(x), walkAt(x + run)
		local h = headingAt(x)
		local across = Vector3.new(-h.Z, 0, h.X)
		part(m, "Plank", Vector3.new(WALK_HALF * 2, 0.4, (b - a).Magnitude + 0.06), CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -0.2, 0), Wood, jitter(rgb(140, 112, 80), rng, 0.1))
		-- Rails: a post every four or so, rope between.
		local i = math.floor((x - x0) / 1.4 + 0.5)
		if i % 3 == 0 then
			for _, s in ipairs({ -1, 1 }) do
				local p = a + across * s * (WALK_HALF - 0.2)
				if gapNear(x, s) then
					prevPost[s] = nil
				else
					rod(m, "RailPost", p - UP * 0.4, p + UP * 3.4, 0.24, Wood, TIMBER)
					if prevPost[s] then
						for _, y in ipairs({ 1.7, 3.2 }) do
							rod(m, "RailRope", prevPost[s] + UP * y, p + UP * y, 0.18, Fabric, ROPE)
						end
					end
					prevPost[s] = p
				end
			end
		end
		if i % 7 == 0 then
			-- lashed down to the link under it
			deco(rod(m, "Lashing", a + across * 1.5 - UP * 0.4, a + across * 1.5 - UP * (WALK_Y + 0.5), 0.3, Fabric, ROPE))
		end
		x += run
	end
	return m
end

-- A chain or a hawser from a to b, not solid.
local function hangLine(parent, a, b, heavy, rng)
	if not heavy then
		deco(rod(parent, "Hawser", a, b, 0.7, Fabric, jitter(ROPE, rng, 0.08)))
		return
	end
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local n = math.max(1, math.floor(len / 4))
	for i = 0, n - 1 do
		local p = a + dir * ((i + 0.5) * len / n)
		deco(part(parent, "HangLink", Vector3.new(1.6, 0.6, 5), CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, if i % 2 == 0 then 0 else math.pi / 2), Rust, RUST))
	end
end

-- ===== Ships =====

local WOOD_PAINT = { rgb(70, 110, 140), rgb(200, 196, 180), rgb(120, 60, 44), rgb(60, 100, 80), rgb(150, 120, 80) }
local STEEL_PAINT = { rgb(40, 60, 90), rgb(34, 36, 40), rgb(50, 80, 64), rgb(110, 40, 36), rgb(170, 90, 40) }
local CONTAINERS = { rgb(170, 60, 40), rgb(40, 90, 150), rgb(60, 120, 70), rgb(200, 150, 40), rgb(130, 130, 130), rgb(120, 60, 110) }
local NAMES = { "第三福丸", "SEAGULL", "朝日丸", "MARY ROSE", "第八光洋丸", "HOPE", "海神", "NORTH STAR", "潮騒", "LUCKY 7", "白鳥", "ORCA", "明神丸", "KESTREL" }

-- Near their real sizes (about 3 studs to a metre). S is how much bigger
-- than a small one of its kind, for the fittings.
local function spec(kind, rng)
	local s = { kind = kind, bow = 0.72, stern = 0.82, keelRise = 0.45, bulwark = 3.4, heavy = false }
	local r = function(a, b)
		return rng:NextNumber(a, b)
	end
	if kind == "fishing" then
		s.L, s.B, s.D, s.S = r(70, 100), r(20, 26), r(12, 15), 1.8
		s.mat, s.color, s.bottom = Wood, pick(WOOD_PAINT, rng), rgb(126, 52, 40)
		s.deckMat, s.deckColor = Planks, rgb(130, 104, 76)
	elseif kind == "sailing" then
		s.L, s.B, s.D, s.S = r(130, 170), r(30, 38), r(18, 22), 2
		s.mat, s.color, s.bottom = Wood, jitter(rgb(84, 62, 44), rng, 0.1), rgb(80, 110, 90)
		s.deckMat, s.deckColor = Planks, rgb(150, 124, 90)
		s.bulwark, s.bow = 4, 0.7
	elseif kind == "junk" then
		s.L, s.B, s.D, s.S = r(90, 120), r(26, 32), r(15, 18), 1.9
		s.mat, s.color, s.bottom = Wood, jitter(rgb(120, 80, 50), rng, 0.1), rgb(60, 50, 40)
		s.deckMat, s.deckColor = Planks, rgb(140, 110, 76)
		s.stern, s.bow, s.keelRise = 0.95, 0.8, 0.3
	elseif kind == "cargo" then
		s.L, s.B, s.D, s.S = r(260, 330), r(44, 52), r(26, 30), 2.4
		s.mat, s.color, s.bottom = Rust, pick(STEEL_PAINT, rng), rgb(130, 50, 40)
		s.deckMat, s.deckColor = Plate, rgb(96, 94, 90)
		s.bulwark, s.bow, s.heavy = 4, 0.8, true
	elseif kind == "tug" then
		s.L, s.B, s.D, s.S = r(70, 90), r(26, 30), r(14, 16), 2.2
		s.mat, s.color, s.bottom = Rust, pick({ rgb(160, 50, 40), rgb(34, 36, 40), rgb(200, 110, 40) }, rng), rgb(120, 46, 36)
		s.deckMat, s.deckColor = Plate, rgb(96, 94, 90)
		s.bow, s.stern, s.heavy = 0.66, 0.9, true
	elseif kind == "ferry" then
		s.L, s.B, s.D, s.S = r(200, 250), r(40, 46), r(20, 24), 2.1
		s.mat, s.color, s.bottom = Metal, rgb(214, 214, 206), rgb(40, 60, 110)
		s.deckMat, s.deckColor = Plate, rgb(120, 118, 112)
		s.bow, s.heavy = 0.78, true
	elseif kind == "yacht" then
		s.L, s.B, s.D, s.S = r(60, 84), r(18, 22), r(10, 12), 2
		s.mat, s.color, s.bottom = Smooth, rgb(230, 230, 226), rgb(30, 40, 70)
		s.deckMat, s.deckColor = Planks, rgb(170, 140, 100)
		s.bulwark, s.bow = 2.4, 0.6
	elseif kind == "sub" then
		s.L, s.B, s.D, s.S = r(200, 240), r(24, 28), r(18, 20), 2.4
		s.mat, s.color, s.bottom = Metal, rgb(30, 32, 34), rgb(30, 32, 34)
		s.deckMat, s.deckColor = Plate, rgb(44, 46, 48)
		s.bulwark, s.bow, s.stern, s.keelRise, s.heavy = 0, 0.8, 0.35, 0.5, true
	else -- rowboat
		s.L, s.B, s.D, s.S = r(14, 18), r(5, 6), 2.6, 1
		s.mat, s.color, s.bottom = Wood, pick(WOOD_PAINT, rng), rgb(110, 90, 70)
		s.deckMat, s.deckColor = Planks, rgb(130, 104, 76)
		s.bulwark, s.bow = 0.8, 0.6
	end
	s.T = if s.L > 120 then 1.4 else 0.8
	s.n = math.clamp(math.floor(s.L / 8), 6, 34)
	s.SL = s.L / s.n
	s.skipDeck, s.skipSide = {}, {}
	return s
end

local function beamFrac(s, u)
	if u > s.bow then
		return 0.06 + 0.94 * math.cos(math.min(1, (u - s.bow) / (1 - s.bow)) * math.pi / 2) ^ 0.7
	elseif u < 0.12 then
		return s.stern + (1 - s.stern) * (math.max(0, u) / 0.12) ^ 0.6
	end
	return 1
end

local function keelAt(s, u)
	local k0 = s.bow - 0.05
	if u > k0 then
		return s.D * s.keelRise * ((u - k0) / (1 - k0)) ^ 1.6
	end
	return 0
end

-- The hull: side plates angled slice to slice, a bulwark along the top,
-- deck, bottom; weed and barnacles on what was under water. Slices listed
-- in s.skipDeck / s.skipSide[i][side] are left open.
local function hull(m, s, rng)
	local T = s.T
	local wl = s.D * 0.45
	for i = 1, s.n do
		local u0, u1 = (i - 1) / s.n, i / s.n
		local x0, x1 = -s.L / 2 + s.L * u0, -s.L / 2 + s.L * u1
		local h0, h1 = s.B / 2 * beamFrac(s, u0), s.B / 2 * beamFrac(s, u1)
		local k = keelAt(s, (u0 + u1) / 2)
		for _, side in ipairs({ -1, 1 }) do
			local p0, p1 = Vector3.new(x0, 0, side * h0), Vector3.new(x1, 0, side * h1)
			local len = (p1 - p0).Magnitude + 0.1
			local base = CFrame.lookAt((p0 + p1) / 2, p1)
			if not (s.skipSide[i] and s.skipSide[i][side]) then
				if wl - k > 0.3 then
					part(m, "Hull", Vector3.new(T, wl - k, len), base * CFrame.new(0, (k + wl) / 2, 0), s.mat, s.bottom)
				end
				local lo = math.max(k, wl)
				part(m, "Hull", Vector3.new(T, s.D - lo, len), base * CFrame.new(0, (lo + s.D) / 2, 0), s.mat, s.color)
			else
				-- torn edges round the hole
				for _, y in ipairs({ k + 0.6, s.D - 0.6 }) do
					deco(part(m, "TornPlate", Vector3.new(T, 1.2, rng:NextNumber(1, 3)), base * CFrame.new(0, y, rng:NextNumber(-len / 2, len / 2)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), 0, 0), s.mat, darken(s.color, 0.7)))
				end
			end
			if s.bulwark > 0 then
				part(m, "Bulwark", Vector3.new(T, s.bulwark, len), base * CFrame.new(0, s.D + s.bulwark / 2, 0), s.mat, s.color)
				part(m, "Bulwark", Vector3.new(T + 0.4, 0.4, len), base * CFrame.new(0, s.D + s.bulwark + 0.2, 0), s.mat, darken(s.color, 0.8))
			end
		end
		local w = 2 * math.min(h0, h1)
		if w > 1 then
			part(m, "Bottom", Vector3.new(x1 - x0 + 0.05, T, w), CFrame.new((x0 + x1) / 2, k + T / 2, 0), s.mat, s.bottom)
			if not s.skipDeck[i] and w - T * 1.2 > 0.6 then
				part(m, "Deck", Vector3.new(x1 - x0 + 0.02, 0.5, w - T * 1.2), CFrame.new((x0 + x1) / 2, s.D - 0.25, 0), s.deckMat, jitter(s.deckColor, rng, 0.04))
			end
		end
		if rng:NextNumber() < 0.5 then
			local wx, wz = rng:NextNumber(x0, x1), rng:NextNumber(-w / 2, w / 2)
			deco(rod(m, "Weed", Vector3.new(wx, k, wz), Vector3.new(wx - rng:NextNumber(2, 10), k - rng:NextNumber(0, 2), wz), 0.5, Fabric, pick(WEED, rng)))
		end
	end
	-- The transom (the floor, now, at the very bottom).
	local hs = s.B / 2 * beamFrac(s, 0)
	part(m, "Transom", Vector3.new(T, s.D, 2 * hs), CFrame.new(-s.L / 2, s.D / 2, 0), s.mat, s.color)
	for _ = 1, math.floor(s.L / 8) do
		local u = rng:NextNumber(0.1, 0.8)
		local side = pick({ -1, 1 }, rng)
		deco(ellipsoid(m, "Barnacles", Vector3.new(rng:NextNumber(2, 6), rng:NextNumber(1, 3), 0.5), CFrame.new(-s.L / 2 + s.L * u, rng:NextNumber(0.5, wl), side * (s.B / 2 * beamFrac(s, u) + 0.3)), Smooth, rgb(200, 196, 184)))
	end
end

-- Hung nose up, the bulkheads are floors: across the hull at local x,
-- with a hatch for the ladder at (LADDER_Y, 0).
local function ladderY(s)
	return s.D * 0.62
end

local function bulkhead(m, s, x)
	local u = (x + s.L / 2) / s.L
	local h = s.B / 2 * math.min(beamFrac(s, u - 0.5 / s.n), beamFrac(s, u + 0.5 / s.n)) - s.T / 2
	local k = keelAt(s, u) + s.T
	local yl = ladderY(s)
	local top = s.D - 0.1
	if h < 3.2 or top - k < 5 then
		return false
	end
	local color = darken(s.color, 0.75)
	local cx = x - 0.3
	local function piece(y0, y1, z0, z1)
		if y1 - y0 > 0.2 and z1 - z0 > 0.2 then
			part(m, "Floor", Vector3.new(0.6, y1 - y0, z1 - z0), CFrame.new(cx, (y0 + y1) / 2, (z0 + z1) / 2), s.mat == Wood and Wood or Plate, color)
		end
	end
	if yl - 3 > k and yl + 3 < top then
		piece(k, yl - 3, -h, h)
		piece(yl + 3, top, -h, h)
		piece(yl - 3, yl + 3, -h, -3)
		piece(yl - 3, yl + 3, 3, h)
	else
		piece(k, top, -h, h)
	end
	return true
end

-- A deckhouse: a solid block with a window band and a roof.
local function house(m, s, x0, x1, halfW, h, color)
	part(m, "House", Vector3.new(x1 - x0, h, halfW * 2), CFrame.new((x0 + x1) / 2, s.D + h / 2, 0), s.mat == Wood and Wood or Metal, color)
	part(m, "HouseRoof", Vector3.new(x1 - x0 + 0.8, 0.6, halfW * 2 + 0.8), CFrame.new((x0 + x1) / 2, s.D + h + 0.3, 0), Metal, darken(color, 0.85))
	for _, side in ipairs({ -1, 1 }) do
		for y = s.D + 3, s.D + h - 2, 5 do
			deco(part(m, "Windows", Vector3.new(x1 - x0 - 2, 1.8, 0.1), CFrame.new((x0 + x1) / 2, y, side * (halfW + 0.05)), Glass, WINDOW))
		end
	end
	deco(part(m, "Windows", Vector3.new(0.1, 2, halfW * 2 - 2), CFrame.new(x1 + 0.05, s.D + h - 2.4, 0), Glass, WINDOW))
end

local function mast(m, s, x, h)
	cylinder(m, "Mast", h, 1.2 * s.S ^ 0.5, CFrame.new(x, s.D + h / 2, 0) * UPRIGHT, Wood, TIMBER)
	return s.D + h
end

local function container(m, x, y, z, color, rng)
	-- A real one: 20 feet long.
	part(m, "Container", Vector3.new(18, 7.8, 7.3), CFrame.new(x, y + 3.9, z) * CFrame.Angles(rng:NextNumber(-0.02, 0.02), 0, rng:NextNumber(-0.02, 0.02)), Rust, jitter(color, rng, 0.08))
end

-- What's on deck, by kind (it all sticks out sideways, hung like this).
-- Keeps a clear strip down the deck by the +Z bulwark for the ladder in.
local function dress(m, s, rng)
	local S = s.S
	local lanternAt = {}
	local clear = s.B / 2 - 6 -- keep houses within this of the centre line
	if s.kind == "fishing" then
		house(m, s, s.sternX + 4, s.sternX + 4 + s.L * 0.2, math.min(clear, 5 * S), 7 * S, rgb(210, 206, 196))
		mast(m, s, s.L * 0.08, 14 * S)
		deco(part(m, "Nets", Vector3.new(8, 2.4, 5), CFrame.new(s.L * 0.2, s.D + 1.2, -s.B / 4) * CFrame.Angles(0, 0.2, 0.1), Fabric, rgb(60, 90, 70)))
		for k = 0, 5 do
			local p = Vector3.new(s.L * 0.08 + 3, s.D + 5 + k * 3.5 * S, 0)
			local lit = rng:NextNumber() < 0.3
			deco(ellipsoid(m, "SquidLamp", Vector3.new(1.4, 2, 1.4), CFrame.new(p), if lit then Neon else Glass, if lit then rgb(255, 240, 200) else rgb(200, 200, 190)))
			if lit then
				table.insert(lanternAt, p)
			end
		end
	elseif s.kind == "sailing" or s.kind == "junk" then
		local xs = if s.kind == "junk" then { -s.L * 0.22, s.L * 0.08, s.L * 0.3 } else { -s.L * 0.24, s.L * 0.04, s.L * 0.28 }
		for i, x in ipairs(xs) do
			local h = math.min(70, s.L * (if i == 2 then 0.42 else 0.32))
			local top = mast(m, s, x, h)
			rod(m, "Yard", Vector3.new(x, top - 4, -s.B / 2), Vector3.new(x, top - 4, s.B / 2), 0.8, Wood, TIMBER)
			for _, side in ipairs({ -1, 1 }) do
				deco(rod(m, "Shroud", Vector3.new(x, top - 2, 0), Vector3.new(x - 4, s.D + s.bulwark, side * (s.B / 2 - 0.6)), 0.2, Fabric, ROPE))
			end
		end
		house(m, s, s.sternX + 3, s.sternX + 3 + s.L * 0.12, math.min(clear, 5 * S), 5 * S, darken(s.color, 0.9))
		table.insert(lanternAt, Vector3.new(s.sternX + 1.5, s.D + 5, 0))
	elseif s.kind == "cargo" then
		local hw = clear
		local bx0 = s.sternX + 6
		local bh = 40
		house(m, s, bx0, bx0 + 34, hw, bh, rgb(214, 210, 200))
		cylinder(m, "Funnel", 16, 11, CFrame.new(bx0 + 8, s.D + bh + 7, 0) * UPRIGHT, Metal, rgb(40, 40, 42))
		local x = bx0 + 46
		while x < s.bowX - 30 do
			for z = -hw + 4, hw - 4, 7.6 do
				if rng:NextNumber() < 0.8 then
					for t = 0, rng:NextInteger(0, 2) do
						container(m, x, s.D + t * 7.8, z, pick(CONTAINERS, rng), rng)
					end
				end
			end
			x += 19
		end
		table.insert(lanternAt, Vector3.new(bx0 + 34.6, s.D + 10, 0))
	elseif s.kind == "tug" then
		house(m, s, -s.L * 0.12, s.L * 0.16, math.min(clear, 7), 13, rgb(220, 216, 206))
		cylinder(m, "Funnel", 10, 6, CFrame.new(-s.L * 0.04, s.D + 18, 0) * UPRIGHT, Metal, rgb(34, 34, 36))
		for u = 0.15, 0.85, 0.07 do
			for _, side in ipairs({ -1, 1 }) do
				local x = -s.L / 2 + s.L * u
				deco(cylinder(m, "Tyre", 1.6, 4.4, CFrame.new(x, s.D - 2.4, side * (s.B / 2 * beamFrac(s, u) + 0.9)) * CFrame.Angles(0, math.pi / 2, 0), Smooth, DARK))
			end
		end
		table.insert(lanternAt, Vector3.new(s.L * 0.16 + 0.8, s.D + 10, 0))
	elseif s.kind == "ferry" then
		local x0, x1 = s.sternX + 10, s.L * 0.22
		local h = 26
		house(m, s, x0, x1, clear, h, rgb(226, 226, 220))
		for _, side in ipairs({ -1, 1 }) do
			deco(part(m, "Stripe", Vector3.new(s.L * 0.8, 2, 0.1), CFrame.new(0, s.D - 3, side * (s.B / 2 + 0.05)), Smooth, rgb(40, 80, 160)))
		end
		cylinder(m, "Funnel", 12, 10, CFrame.new((x0 + x1) / 2, s.D + h + 6, 0) * UPRIGHT, Metal, rgb(40, 80, 160))
		table.insert(lanternAt, Vector3.new(x1 + 0.8, s.D + 6, 0))
	elseif s.kind == "yacht" then
		house(m, s, -s.L * 0.22, s.L * 0.14, clear, 7, rgb(236, 236, 232))
		mast(m, s, s.L * 0.02, math.min(80, s.L * 0.9))
	elseif s.kind == "sub" then
		part(m, "Sail", Vector3.new(26, 18, 6), CFrame.new(s.L * 0.1, s.D + 9, 0), Metal, s.color)
		for _, side in ipairs({ -1, 1 }) do
			part(m, "Planes", Vector3.new(6, 0.8, 22), CFrame.new(s.L * 0.1, s.D + 12, side * 3), Metal, s.color)
		end
	else -- rowboat
		for k = -1, 1 do
			part(m, "Thwart", Vector3.new(0.8, 0.2, s.B - 1.2), CFrame.new(k * s.L * 0.22, s.D - 0.6, 0), Wood, TIMBER)
		end
	end
	for _, p in ipairs(lanternAt) do
		local l = deco(ellipsoid(m, "ShipLantern", Vector3.new(1.4, 2, 1.4), CFrame.new(p), Neon, rgb(255, 196, 120)))
		glow(l, 28)
	end
	if s.L > 25 and s.kind ~= "sub" then
		local name = pick(NAMES, rng)
		for _, side in ipairs({ -1, 1 }) do
			local u = 0.62
			label(m, CFrame.new(-s.L / 2 + s.L * u, s.D - 3, side * (s.B / 2 * beamFrac(s, u) + 0.12)) * CFrame.Angles(0, if side > 0 then 0 else math.pi, 0), Vector3.new(math.min(28, s.L * 0.15), 4.5, 0.05), Enum.NormalId.Back, name, s.color, rgb(236, 232, 222), Smooth, Enum.Font.GothamBold).Transparency = 1
		end
	end
end

-- Where the deck ends at the bow and stern (wide enough to stand on).
local function deckEnds(s)
	local ub = 1
	while ub > 0.5 and beamFrac(s, ub) * s.B / 2 < 3 do
		ub -= 0.01
	end
	local us = 0
	while us < 0.3 and beamFrac(s, us) * s.B / 2 < 3 do
		us += 0.01
	end
	s.bowX = -s.L / 2 + s.L * ub - 1
	s.sternX = -s.L / 2 + s.L * us + 1.5
end

-- Hung up, whatever sails were left hang straight down off the masts in
-- rags.
local function rags(m, s, rng)
	local color = if s.kind == "junk" then rgb(150, 70, 44) else rgb(210, 200, 176)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "Mast" or d.Name == "Yard") then
			local half = d.Size.X / 2
			for _ = 1, math.floor(d.Size.X / 8) do
				local p = d.CFrame:PointToWorldSpace(Vector3.new(rng:NextNumber(-half, half), 0, 0))
				local len = rng:NextNumber(6, 24)
				local w = rng:NextNumber(3, 8)
				deco(part(m, "SailRag", Vector3.new(w, len, 0.12), CFrame.new(p - UP * len / 2) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.08, 0.08)), Fabric, jitter(color, rng, 0.08)))
			end
		end
	end
end

-- Build a ship of spec `s` in its own frame, then pivot to `cf`.
local function buildShip(parent, s, cf, rng, floors)
	local m = model(parent, "HangingShip")
	hull(m, s, rng)
	dress(m, s, rng)
	if floors then
		for _, x in ipairs(floors) do
			bulkhead(m, s, x)
		end
	end
	m.WorldPivot = CFrame.identity
	m:PivotTo(cf)
	rags(m, s, rng)
	return m
end

-- A ship hung nose up from `tip` (her stem head), her deck facing
-- `faceSide` across the chain and her beam along it; `tilt` small.
local function hungPose(s, tip, heading, faceSide, tilt)
	local vY = heading:Cross(UP) * faceSide
	local R = CFrame.fromMatrix(Vector3.zero, UP, vY, heading * faceSide)
	return CFrame.new(tip) * tilt * R * CFrame.new(-s.L / 2, -s.D / 2, 0)
end

-- ===== Walkways =====

-- A walkway from a to b (floor-level points): a plank bridge (sagging if
-- it's long) when it's gentle, a stair when it's steep; railed.
local function walkway(parent, a, b, rng, sag)
	local m = model(parent, "Bridge")
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local run = flat.Magnitude
	if run < 0.5 then
		return m
	end
	local h = flat.Unit
	local side = Vector3.new(-h.Z, 0, h.X)
	local steep = math.abs(b.Y - a.Y) / run > 0.45
	local function at(t)
		return a:Lerp(b, t) - UP * ((sag or 0) * 4 * t * (1 - t))
	end
	if steep then
		local n = math.ceil(math.abs(b.Y - a.Y) / 0.8)
		for i = 1, n do
			local p = at((i - 0.5) / n)
			local top = a.Y + (b.Y - a.Y) * (if b.Y > a.Y then i / n else (i - 1) / n)
			part(m, "Tread", Vector3.new(4.6, 0.4, run / n + 0.1), CFrame.lookAt(Vector3.new(p.X, top - 0.2, p.Z), Vector3.new(p.X, top - 0.2, p.Z) + h), Wood, jitter(TIMBER, rng, 0.1))
		end
	else
		local n = math.max(2, math.ceil((b - a).Magnitude / 1.1))
		for i = 1, n do
			local p0, p1 = at((i - 1) / n), at(i / n)
			part(m, "Plank", Vector3.new(4.6, 0.3, (p1 - p0).Magnitude + 0.08), CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, -0.15, 0), Wood, jitter(rgb(140, 112, 80), rng, 0.1))
		end
	end
	local np = math.max(1, math.ceil(run / 4))
	for _, s2 in ipairs({ -1, 1 }) do
		local prev
		for k = 0, np do
			local p = at(k / np) + side * s2 * 2.35
			rod(m, "RailPost", p - UP * 0.3, p + UP * 3.4, 0.22, Wood, TIMBER)
			if prev then
				for _, y in ipairs({ 1.7, 3.2 }) do
					rod(m, "RailRope", prev + UP * y, p + UP * y, 0.16, Fabric, ROPE)
				end
			end
			prev = p
		end
	end
	return m
end

-- ===== Assembly =====

local PATH_KINDS = { "fishing", "fishing", "fishing", "sailing", "sailing", "junk", "junk", "cargo", "tug", "tug", "ferry", "yacht", "yacht", "sub" }

-- Floors (local x) for a ship hung nose up: every 15 studs or so up from
-- the stern, on slice boundaries, as far up as the hull's wide enough.
local function floorsFor(s)
	local every = math.max(1, math.floor(15 / s.SL + 0.5))
	local list = {}
	for i = every, s.n - 1, every do
		local x = -s.L / 2 + i * s.SL
		local u = i / s.n
		if s.B / 2 * math.min(beamFrac(s, u - 0.5 / s.n), beamFrac(s, u + 0.5 / s.n)) > 5 and keelAt(s, u) < s.D * 0.35 then
			table.insert(list, { x = x, i = i })
		end
	end
	return list
end

-- The shipwright's kit, for the harbour's own ships (Port.lua): a spec of
-- a kind, and a ship built from it at a CFrame (her keel's middle, bow
-- toward +X). `lights` is how many lanterns may carry a real light.
ChainOfShips.kit = {
	spec = function(kind, rng)
		local s = spec(kind, rng)
		deckEnds(s)
		return s
	end,
	build = function(parent, s, cf, rng, lights)
		lightsLeft = lights or 0
		return buildShip(parent, s, cf, rng, nil)
	end,
}

-- `anchor`: from Ship (hawse, ring, crown, stem). `ledge`: where the
-- tunnels come out on the crag's east face (from Underground).
function ChainOfShips.build(parent, anchor, ledge, rng)
	if not anchor then
		return
	end
	lightsLeft = 24
	crown = anchor.crown
	vertexX = FAR.x + SAG_PAST
	local past = (SAG_PAST / (vertexX - crown.X)) ^ 2
	vertexY = (FAR.y - crown.Y * past) / (1 - past)
	-- (where it ends, for the port)
	ChainOfShips.endPoint = chainAt(FAR.x)
	ChainOfShips.walkTop = chainAt(FAR.x) + UP * WALK_Y
	local root = model(parent, "ChainOfShips")
	greatChain(root, rng)
	task.wait()

	-- ----- Plan the walkable ships, side by side along the chain -----
	local ships = {}
	local x = crown.X + 14
	local lastKind
	while true do
		-- (the first is big enough to reach down past the tunnels' ledge;
		-- further down the chain there's less and less room over the fog,
		-- so only the smaller ones fit)
		local s, cx, kind
		for try = 1, 8 do
			kind = if #ships == 0 then "ferry" elseif try > 5 then pick({ "yacht", "fishing", "tug" }, rng) else pick(PATH_KINDS, rng)
			if kind == lastKind and (kind == "cargo" or kind == "ferry" or kind == "sub") then
				kind = "fishing"
			end
			local c = spec(kind, rng)
			local ccx = x + c.B / 2
			if c.L + 24 < chainY(ccx) - KEEP_ABOVE then
				s, cx = c, ccx
				break
			end
		end
		if not s or cx > PATH_END_X then
			break
		end
		deckEnds(s)
		s.hang = rng:NextNumber(10, 22)
		s.face = pick({ -1, 1 }, rng)
		s.heading = headingAt(cx)
		local tip = chainAt(cx) - UP * s.hang
		local tilt = CFrame.Angles(0, math.rad(rng:NextNumber(-8, 8)), 0)
		s.cf = hungPose(s, tip, s.heading, s.face, tilt)
		s.floors = floorsFor(s)
		s.cx = cx
		table.insert(ships, s)
		lastKind = kind
		x = cx + s.B / 2 + rng:NextNumber(10, 16)
	end

	-- Local z on each ship that faces east (along the chain) is s.face.
	local function floorWorld(s, f, side)
		local u = f.i / s.n
		local h = s.B / 2 * math.min(beamFrac(s, u - 0.5 / s.n), beamFrac(s, u + 0.5 / s.n))
		return s.cf:PointToWorldSpace(Vector3.new(f.x, (keelAt(s, u) + s.D) / 2, side * (h - 0.4)))
	end
	local function openSide(s, f, side)
		local e = math.max(1, math.ceil(10 / s.SL))
		for i = f.i + 1, math.min(s.n, f.i + e) do
			s.skipSide[i] = s.skipSide[i] or {}
			s.skipSide[i][side] = true
		end
	end
	local function nearestFloor(s, y, avoid)
		local best, bd
		for _, f in ipairs(s.floors) do
			if f ~= avoid then
				local d = math.abs(floorWorld(s, f, 1).Y - y)
				if not bd or d < bd then
					best, bd = f, d
				end
			end
		end
		return best
	end

	-- Each ship's way in from the chain walk: the top floor, a hole in the
	-- deck over it, a ladder down the deck face to it.
	local gaps = {}
	for _, s in ipairs(ships) do
		local top = s.floors[#s.floors]
		s.top = top
		if top then
			local e = math.max(1, math.ceil(10 / s.SL))
			for i = top.i + 1, math.min(s.n, top.i + e) do
				s.skipDeck[i] = true
			end
			local u = top.i / s.n
			local zl = s.B / 2 * beamFrac(s, u) - 3.4
			s.ladderLocal = Vector3.new(top.x, s.D + 1.6, zl)
		end
	end
	-- Rope bridges between neighbours, through holes torn in their sides,
	-- once or twice down their length.
	local bridges = {}
	for k = 1, #ships - 1 do
		local a, b = ships[k], ships[k + 1]
		if a.top and b.top then
			local yTop = math.min(floorWorld(a, a.top, 1).Y, floorWorld(b, b.top, 1).Y) - 12
			local yBot = math.max(a.cf.Position.Y - a.L / 2 + 20, b.cf.Position.Y - b.L / 2 + 20)
			local levels = if yTop - yBot > 120 then 2 else 1
			for l = 1, levels do
				if yTop > yBot then
					local y = yBot + (yTop - yBot) * (if levels == 1 then rng:NextNumber(0.3, 0.8) else (l - 0.5) / levels + rng:NextNumber(-0.1, 0.1))
					local fa = nearestFloor(a, y, a.top)
					local fb = fa and nearestFloor(b, floorWorld(a, fa, a.face).Y, b.top)
					if fa and fb then
						openSide(a, fa, a.face)
						openSide(b, fb, -b.face)
						table.insert(bridges, { floorWorld(a, fa, a.face), floorWorld(b, fb, -b.face) })
					end
				end
			end
		end
	end
	-- The rope bridge from the ledge into the west side of the first ship.
	local ledgeBridge
	if ledge and ships[1] then
		local s = ships[1]
		local f = nearestFloor(s, ledge.Y, s.top)
		if f then
			openSide(s, f, -s.face)
			ledgeBridge = { ledge + Vector3.new(-1, 0, 0), floorWorld(s, f, -s.face) }
		end
	end

	-- ----- Build them -----
	local path = model(root, "Walkable")
	for k, s in ipairs(ships) do
		local xs = {}
		for _, f in ipairs(s.floors) do
			table.insert(xs, f.x)
		end
		s.model = buildShip(path, s, s.cf, rng, xs)
		-- Hung by the stem head: two chains up to the great chain.
		for _, dz in ipairs({ -2, 2 }) do
			local stem = s.cf:PointToWorldSpace(Vector3.new(s.L / 2 - 2, s.D * 0.75, dz))
			hangLine(s.model, stem, chainAt(stem.X) - UP * 3, true, rng)
		end
		-- The ladder up through the floors inside, stern to top floor.
		if s.top then
			local yl = ladderY(s)
			ladder(s.model, s.cf:PointToWorldSpace(Vector3.new(-s.L / 2 + 1, yl, 0)), s.cf:PointToWorldSpace(Vector3.new(s.top.x + 4, yl, 0)), true)
			-- And the ladder down the deck face from the chain walk.
			local foot = s.cf:PointToWorldSpace(s.ladderLocal)
			local walkY = chainY(foot.X) + WALK_Y
			local topP = Vector3.new(foot.X, walkY + 3.2, foot.Z)
			ladder(s.model, foot - UP * 1, topP, false)
			-- A little jetty out to it from the walk.
			local c = chainAt(foot.X)
			local out = Vector3.new(foot.X - c.X, 0, foot.Z - c.Z)
			local dir = out.Unit
			local j0 = Vector3.new(c.X, walkY, c.Z) + dir * (WALK_HALF - 0.4)
			local j1 = Vector3.new(foot.X, walkY, foot.Z) - dir * 1.4
			if (j1 - j0):Dot(dir) > 0.5 then
				local jl = (j1 - j0).Magnitude
				part(s.model, "Jetty", Vector3.new(4, 0.4, jl + 0.4), CFrame.lookAt((j0 + j1) / 2, j1) * CFrame.new(0, -0.2, 0), Wood, jitter(rgb(140, 112, 80), rng, 0.1))
				local across = Vector3.new(-dir.Z, 0, dir.X)
				for _, sd in ipairs({ -1, 1 }) do
					rod(s.model, "RailRope", j0 + across * sd * 1.9 + UP * 3.2, j1 + across * sd * 1.9 + UP * 3.2, 0.16, Fabric, ROPE)
					for _, p in ipairs({ j0, j1 }) do
						rod(s.model, "RailPost", p + across * sd * 1.9 - UP * 0.3, p + across * sd * 1.9 + UP * 3.4, 0.22, Wood, TIMBER)
					end
				end
			end
			-- (which side of the walk the jetty leaves from)
			local h = headingAt(c.X)
			local across = Vector3.new(-h.Z, 0, h.X)
			table.insert(gaps, { x = c.X, side = if out:Dot(across) > 0 then 1 else -1 })
		end
		if rng:NextNumber() < 0.4 and #s.floors > 1 then
			local f = s.floors[rng:NextInteger(1, #s.floors - 1)]
			marker(s.model, "LootSpot", "LootSpot", s.cf:PointToWorldSpace(Vector3.new(f.x, s.D * 0.3, -s.B / 5)))
		end
		if k % 3 == 0 then
			task.wait()
		end
	end
	for _, br in ipairs(bridges) do
		walkway(path, br[1], br[2], rng)
	end
	if ledgeBridge then
		local b = walkway(root, ledgeBridge[1], ledgeBridge[2], rng, (ledgeBridge[2] - ledgeBridge[1]).Magnitude * 0.03)
		b.Name = "LedgeBridge"
	end
	marker(root, "ChainEnd", "ChainEnd", chainAt(PATH_END_X) + UP * WALK_Y)

	-- ----- The way on: from the trawler's foredeck out along the chain -----
	local walkStart = crown.X + 12
	local ramp = walkway(root, anchor.deck, chainAt(walkStart) + UP * WALK_Y, rng)
	ramp.Name = "OntoTheChain"
	chainWalk(root, walkStart, gaps, rng)
	task.wait()

	-- ----- The rest: further out and deeper, into the fog -----
	local hung = model(root, "Hanging")
	local count = 0
	local hx = crown.X + 40
	while hx < FAR.x - 100 do
		hx += rng:NextNumber(70, 150)
		local kind = pick({ "fishing", "fishing", "sailing", "junk", "cargo", "tug", "ferry", "yacht", "sub" }, rng)
		local s = spec(kind, rng)
		deckEnds(s)
		local c = chainAt(hx)
		local beyond = hx > PATH_END_X
		local lateral = if beyond then rng:NextNumber(-40, 40) else pick({ -1, 1 }, rng) * rng:NextNumber(150, 240)
		local drop = if beyond then rng:NextNumber(10, 40) else rng:NextNumber(40, 110)
		local tip = c + Vector3.new(0, -drop, lateral)
		local byStern = rng:NextNumber() < 0.15
		local tilt = CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(-10, 10)))
		local cf
		if byStern then
			-- hung the other way, by her stern
			cf = CFrame.new(tip) * tilt * CFrame.fromMatrix(Vector3.zero, -UP, Vector3.xAxis, Vector3.zAxis) * CFrame.new(s.L / 2, -s.D / 2, 0)
		else
			cf = hungPose(s, tip, Vector3.xAxis, 1, tilt)
		end
		if not beyond or hx < FAR.x - 110 then
			local sm = buildShip(hung, s, cf, rng, nil)
			local attach = cf:PointToWorldSpace(Vector3.new(if byStern then -s.L / 2 + 2 else s.L / 2 - 2, s.D * 0.6, 0))
			hangLine(sm, attach, c - UP * 3, s.heavy or rng:NextNumber() < 0.5, rng)
			count += 1
			if count % 3 == 0 then
				task.wait()
			end
		end
	end
	-- Bunches of rowing boats, tied together on one rope.
	for _ = 1, 5 do
		local bx = rng:NextNumber(crown.X + 150, PATH_END_X)
		local c = chainAt(bx)
		local knot = c + Vector3.new(0, -rng:NextNumber(20, 40), pick({ -1, 1 }, rng) * rng:NextNumber(100, 130))
		deco(rod(hung, "BunchRope", c, knot, 0.6, Fabric, ROPE))
		for _ = 1, rng:NextInteger(3, 6) do
			local s = spec("rowboat", rng)
			deckEnds(s)
			local p = knot + Vector3.new(rng:NextNumber(-5, 5), -rng:NextNumber(2, 6), rng:NextNumber(-5, 5))
			local cf = hungPose(s, p, Vector3.xAxis, 1, CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.3), rng:NextNumber(-0.4, 0.4)))
			local sm = buildShip(hung, s, cf, rng, nil)
			hangLine(sm, cf:PointToWorldSpace(Vector3.new(s.L / 2 - 1, s.D * 0.6, 0)), knot, false, rng)
		end
	end
end

return ChainOfShips
