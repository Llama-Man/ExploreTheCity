-- The colossal structure the school crowns, and the city around it.
-- The school's floors sit on top of a sheer body that drops away into the
-- haze; the courtyard is a shaft cut down into it. All around stand towers
-- of absurd size (some joined by skybridges), with a few structures that
-- make no sense at all: a stairway climbing into the sky, a ring the size
-- of a district.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)

local part, cylinder, jitter = BuildUtil.part, BuildUtil.cylinder, BuildUtil.jitter
local Concrete, Smooth = Enum.Material.Concrete, Enum.Material.SmoothPlastic

local TOTAL = Config.TOTAL_LENGTH
local STAIR = Config.STAIRWELL_LENGTH
local CZ0 = Config.COURTYARD_NEAR_Z
local CZ1 = CZ0 + Config.COURTYARD_DEPTH
local WALL_T = Config.WING_THICKNESS

local BODY_COLOR = Color3.fromRGB(80, 80, 78)
local BAND_COLOR = Color3.fromRGB(26, 28, 32)
local BODY_BOTTOM = -1900 -- far below the haze; the ground is never seen

-- Everything we build near the school lies inside this box; the city keeps
-- its distance from it.
-- (South as far as the Kannon and her viaduct, past the gym.)
local SITE = { x0 = -STAIR - 30, x1 = TOTAL + STAIR + 300, z0 = -580, z1 = CZ1 + WALL_T + 20 }

local Megastructure = {}

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

-- Dark window bands down one outer face. `axis` "X" = face at fixed z.
local function bands(parent, axis, fixed, normal, spanStart, spanEnd, top)
	local y = top - 18
	while y > -800 do
		if axis == "X" then
			box(parent, "FacadeBand", spanStart, spanEnd, y - 3, y + 3, fixed + math.min(0, normal * 0.6), fixed + math.max(0, normal * 0.6), Smooth, BAND_COLOR)
		else
			box(parent, "FacadeBand", fixed + math.min(0, normal * 0.6), fixed + math.max(0, normal * 0.6), y - 3, y + 3, spanStart, spanEnd, Smooth, BAND_COLOR)
		end
		y -= 36
	end
end

-- The body under the school (and its stairwells) and under the courtyard.
local function body(parent)
	local schoolBottom = Config.BOTTOM_Y - 4.6
	local x0, x1 = -STAIR - 0.5, TOTAL + STAIR + 0.5
	local zSouth = Config.CLASSROOM_Z_FAR - 0.5
	-- Stops a stud short of the courtyard so its face hides behind the
	-- courtyard's near wall instead of flickering against it.
	box(parent, "Substructure", x0, x1, BODY_BOTTOM, schoolBottom, zSouth, CZ0 - 1, Concrete, BODY_COLOR)
	-- Under the courtyard the body is hollow: the hidden sea's hall
	-- (Config.SEA), walled in all round, with a way in through its east wall.
	local S = Config.SEA
	local bx0, bx1, bz0, bz1 = -WALL_T, TOTAL + WALL_T, CZ0, CZ1 + WALL_T
	local seaWall = Color3.fromRGB(58, 60, 60)
	box(parent, "Substructure", bx0, bx1, S.ceiling, Config.COURTYARD_FLOOR - 5, bz0, bz1, Concrete, BODY_COLOR)
	box(parent, "Substructure", bx0, bx1, BODY_BOTTOM, S.floor, bz0, bz1, Concrete, BODY_COLOR)
	box(parent, "Substructure", bx0, S.x0, S.floor, S.ceiling, bz0, bz1, Concrete, seaWall)
	box(parent, "Substructure", S.x0, S.x1, S.floor, S.ceiling, bz0, S.z0, Concrete, seaWall)
	box(parent, "Substructure", S.x0, S.x1, S.floor, S.ceiling, S.z1, bz1, Concrete, seaWall)
	BuildUtil.strip(parent, {
		name = "Substructure",
		axis = "Z",
		fixed = (S.x1 + bx1) / 2,
		spanStart = bz0,
		spanEnd = bz1,
		bottom = S.floor,
		top = S.ceiling,
		thickness = bx1 - S.x1,
		openings = { { center = S.entryZ, width = 12, bottom = S.entryY - 1, top = S.entryY + 11 } },
		material = Concrete,
		color = seaWall,
	})

	bands(parent, "X", zSouth, -1, x0, x1, schoolBottom)
	bands(parent, "Z", x0, -1, zSouth, CZ0 - 1, schoolBottom)
	-- (The courtyard walls above vary in height; the bands stay below the
	-- lowest of them.)
	bands(parent, "X", CZ1 + WALL_T, 1, -WALL_T, TOTAL + WALL_T, Config.COURTYARD_WALLS.low)
	bands(parent, "Z", -WALL_T, -1, CZ0, CZ1 + WALL_T, Config.COURTYARD_WALLS.low)
end

-- ===== The city beyond =====

-- The chain of ships runs east out of the site through here
-- (ChainOfShips.lua); nothing's built across it.
local CHAIN_WAY = { x0 = 740, x1 = 3700, z0 = -320, z1 = 420 }

local function farFromSite(x, z, clearance)
	local dx = math.max(SITE.x0 - x, 0, x - SITE.x1)
	local dz = math.max(SITE.z0 - z, 0, z - SITE.z1)
	return math.sqrt(dx * dx + dz * dz) > clearance
end

-- And the west crossing and the stilt town (WestCrossing.lua, StiltTown.lua).
local WEST_WAY = { x0 = -1100, x1 = -40, z0 = -420, z1 = 420 }

local function inChainWay(x, z, half)
	for _, w in ipairs({ CHAIN_WAY, WEST_WAY }) do
		if x + half > w.x0 and x - half < w.x1 and z + half > w.z0 and z - half < w.z1 then
			return true
		end
	end
	return false
end

-- A tower: two stacked blocks (parts max out at 2048 studs), dark bands
-- wrapped round it, sometimes a stepped crown and a mast.
local function tower(parent, x, z, w, d, top, rng)
	local color = jitter(Color3.fromRGB(72, 74, 78), rng, 0.15)
	part(parent, "Tower", Vector3.new(w, 2040, d), Vector3.new(x, top - 1020, z), Concrete, color)
	part(parent, "Tower", Vector3.new(w, 2040, d), Vector3.new(x, top - 3060, z), Concrete, color)
	for _ = 1, rng:NextInteger(2, 6) do
		local by = top - rng:NextNumber(10, 700)
		part(parent, "TowerBand", Vector3.new(w + 1, rng:NextNumber(4, 16), d + 1), Vector3.new(x, by, z), Smooth, BAND_COLOR)
	end
	local crownTop = top
	if rng:NextNumber() < 0.4 then
		local ch = rng:NextNumber(30, 120)
		part(parent, "TowerCrown", Vector3.new(w * 0.6, ch, d * 0.6), Vector3.new(x, top + ch / 2, z), Concrete, color)
		crownTop = top + ch
	end
	if rng:NextNumber() < 0.5 then
		local mh = rng:NextNumber(40, 200)
		cylinder(parent, "TowerMast", mh, 3, CFrame.new(x, crownTop + mh / 2, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 60, 62))
	end
	return { position = Vector3.new(x, 0, z), top = top }
end

local function skybridge(parent, a, b, rng)
	local y = math.min(a.top, b.top) - rng:NextNumber(20, 150)
	local p0, p1 = Vector3.new(a.position.X, y, a.position.Z), Vector3.new(b.position.X, y, b.position.Z)
	local len = (p1 - p0).Magnitude
	part(parent, "Skybridge", Vector3.new(rng:NextNumber(10, 24), rng:NextNumber(8, 14), len), CFrame.lookAt((p0 + p1) / 2, p1), Concrete, jitter(Color3.fromRGB(80, 80, 82), rng, 0.1))
end

-- A stairway the size of a mountain, climbing out of the haze into the sky.
local function colossalStair(parent, origin, heading, rng)
	local stepRun, stepRise, width = 60, 32, 360
	local dir = Vector3.new(math.cos(heading), 0, math.sin(heading))
	local color = jitter(Color3.fromRGB(88, 86, 82), rng, 0.05)
	for i = 0, 26 do
		local topY = origin.Y + i * stepRise
		local at = origin + dir * (i * stepRun)
		local center = Vector3.new(at.X, topY - 80, at.Z)
		part(parent, "ColossalStep", Vector3.new(width, 160, stepRun + 1), CFrame.lookAt(center, center + dir), Concrete, color)
	end
end

-- An upright ring, most of it standing clear of the haze.
local function giantRing(parent, center, radius, facing, rng)
	local color = jitter(Color3.fromRGB(70, 70, 72), rng, 0.05)
	local segments = 40
	local basis = CFrame.new(center) * CFrame.Angles(0, facing, 0)
	for i = 0, segments - 1 do
		local a = i / segments * math.pi * 2
		local offset = Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
		local segLen = 2 * math.pi * radius / segments + 4
		part(parent, "RingSegment", Vector3.new(segLen, 50, 70), basis * CFrame.new(offset) * CFrame.Angles(0, 0, a + math.pi / 2), Concrete, color)
	end
end

local function city(parent, rng)
	local centerX, centerZ = (SITE.x0 + SITE.x1) / 2, (SITE.z0 + SITE.z1) / 2

	-- Close neighbours, near enough to read their size.
	local near = {}
	local attempts = 0
	while #near < 10 and attempts < 200 do
		attempts += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(650, 1000)
		local x, z = centerX + math.cos(a) * r, centerZ + math.sin(a) * r
		local w, d = rng:NextNumber(90, 240), rng:NextNumber(90, 240)
		if farFromSite(x, z, 180 + math.max(w, d) / 2) and not inChainWay(x, z, math.max(w, d) / 2 + 40) then
			table.insert(near, tower(parent, x, z, w, d, rng:NextNumber(-150, 350), rng))
		end
	end

	-- The wider city, fading into the haze.
	for _ = 1, 45 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(1200, 3200)
		local s = rng:NextNumber(140, 480)
		local tx, tz = centerX + math.cos(a) * r, centerZ + math.sin(a) * r
		if not inChainWay(tx, tz, s * 0.7 + 60) then
			tower(parent, tx, tz, s, s * rng:NextNumber(0.6, 1.4), rng:NextNumber(-300, 1400), rng)
		end
	end

	for i = 1, #near do
		if rng:NextNumber() < 0.6 then
			local best, bestDist = nil, math.huge
			for j = 1, #near do
				local dist = (near[j].position - near[i].position).Magnitude
				if j ~= i and dist < bestDist then
					best, bestDist = near[j], dist
				end
			end
			if best then
				skybridge(parent, near[i], best, rng)
			end
		end
	end

	colossalStair(parent, Vector3.new(centerX + 1400, -350, centerZ + 1100), math.rad(35), rng)
	giantRing(parent, Vector3.new(centerX - 300, 250, centerZ - 1900), 520, math.rad(10), rng)
end

function Megastructure.build(parent, rng)
	body(parent)
	city(parent, rng)
end

return Megastructure
