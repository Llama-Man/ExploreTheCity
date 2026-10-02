-- Signs of disuse layered on top of rooms and the corridor. Every function
-- takes an `amount` (0-1, normally derived from SchoolConfig.DISUSE) that
-- scales how much of it appears. Deliberately physical (debris, peeling
-- plaster, streaks) rather than painted-on grime: flat translucent parts
-- can't make convincing dirt; that needs texture-based MaterialVariants.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)

local part, jitter, pick = BuildUtil.part, BuildUtil.jitter, BuildUtil.pick
local Smooth = Enum.Material.SmoothPlastic
local H = Config.WALL_HEIGHT

local STAIN_COLOR = Color3.fromRGB(92, 74, 52)
local WEB_COLOR = Color3.fromRGB(225, 225, 220)
local PAPER_COLOR = Color3.fromRGB(232, 228, 212)
local LEAF_COLORS = {
	Color3.fromRGB(150, 96, 40),
	Color3.fromRGB(120, 72, 34),
	Color3.fromRGB(170, 130, 60),
	Color3.fromRGB(96, 80, 40),
}

local Weathering = {}

local function overlay(p)
	p.CanCollide = false
	p.CastShadow = false
	return p
end

local function count(amount, lo, hi, rng)
	return math.floor(amount * rng:NextNumber(lo, hi) + 0.5)
end

-- Pulls a colour a little toward dusty grey.
function Weathering.dusty(color, amount)
	return color:Lerp(Config.DUST_COLOR, amount * 0.25)
end

-- Floor: loose papers, leaves blown in under windows, and now and then a
-- heap of plaster fallen from a patch of bare ceiling above it.
-- `windows` entries are { center, width, z, inward } (inward = +1/-1 on Z).
function Weathering.floor(parent, b, rng, amount, windows)
	local function randomPoint(margin)
		return rng:NextNumber(b.x0 + margin, b.x1 - margin), rng:NextNumber(b.z0 + margin, b.z1 - margin)
	end

	for _ = 1, count(amount, 4, 14, rng) do
		local x, z = randomPoint(1)
		local p = part(parent, "LoosePaper", Vector3.new(1.1, 0.02, 1.5), CFrame.new(x, 0.03 + rng:NextNumber(0, 0.03), z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(-3, 3))), Smooth, jitter(PAPER_COLOR, rng, 0.08))
		overlay(p)
	end

	for _, w in ipairs(windows or {}) do
		for _ = 1, count(amount, 3, 12, rng) do
			local x = w.center + rng:NextNumber(-w.width / 2, w.width / 2)
			local z = w.z + w.inward * (0.6 + rng:NextNumber() ^ 2 * 5)
			local leaf = part(parent, "Leaf", Vector3.new(0.5, 0.03, 0.35), CFrame.new(x, 0.03, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), Smooth, pick(LEAF_COLORS, rng))
			overlay(leaf)
		end
	end

	if rng:NextNumber() < amount * 0.6 then
		local x, z = randomPoint(4)
		part(parent, "BareCeilingLath", Vector3.new(rng:NextNumber(2, 3.5), 0.05, rng:NextNumber(1.5, 3)), Vector3.new(x, H - 0.02, z), Enum.Material.Wood, Color3.fromRGB(70, 52, 36))
		for _ = 1, rng:NextInteger(4, 9) do
			local s = rng:NextNumber(0.25, 0.9)
			local chunk = part(parent, "PlasterChunk", Vector3.new(s, s * 0.4, s * rng:NextNumber(0.6, 1)), CFrame.new(x + rng:NextNumber(-1.5, 1.5), s * 0.2, z + rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, math.pi), rng:NextNumber(-0.3, 0.3)), Enum.Material.Plaster, jitter(Config.PLASTER_COLOR, rng, 0.06))
			chunk.CanCollide = false
		end
	end
end

local function blockedByOpening(openings, along, halfWidth, yBottom, yTop)
	for _, o in ipairs(openings) do
		if math.abs(along - o.center) < o.width / 2 + halfWidth + 0.3 and o.top > yBottom and o.bottom < yTop then
			return true
		end
	end
	return false
end

-- Water streaks running down from the ceiling, and patches where plaster
-- has fallen away to show the wooden laths behind it.
function Weathering.wallWear(parent, axis, face, normal, spanStart, spanEnd, openings, rng, amount)
	local length = spanEnd - spanStart
	local WH = Config.WAINSCOT_HEIGHT

	for i = 1, count(amount, 0.5, 2, rng) * math.max(1, math.floor(length / 25)) do
		local w, h = rng:NextNumber(0.6, 2.2), rng:NextNumber(2, 6)
		local along = rng:NextNumber(spanStart + w, spanEnd - w)
		if not blockedByOpening(openings, along, w / 2, H - h, H) then
			-- Each streak sits a hair further out than the last so overlaps don't flicker.
			local offset = 0.012 + (i % 10) * 0.004
			local size, pos = BuildUtil.axisBox(axis, w, h, 0.02, along, H - h / 2, face + normal * offset)
			overlay(part(parent, "WaterStain", size, pos, Smooth, STAIN_COLOR)).Transparency = rng:NextNumber(0.8, 0.9)
			local coreSize, corePos = BuildUtil.axisBox(axis, w * 0.4, h * 0.8, 0.02, along, H - h * 0.4, face + normal * (offset + 0.002))
			overlay(part(parent, "WaterStain", coreSize, corePos, Smooth, STAIN_COLOR)).Transparency = rng:NextNumber(0.75, 0.85)
		end
	end

	for _ = 1, count(amount, 0, 1.5, rng) * math.max(1, math.floor(length / 20)) do
		local w, h = rng:NextNumber(1, 3), rng:NextNumber(0.8, 2.2)
		local along = rng:NextNumber(spanStart + w, spanEnd - w)
		local y = rng:NextNumber(WH + 1.5 + h / 2, H - 1.5 - h / 2)
		if not blockedByOpening(openings, along, w / 2 + 0.3, y - h / 2 - 0.3, y + h / 2 + 0.3) then
			local rimSize, rimPos = BuildUtil.axisBox(axis, w + 0.5, h + 0.4, 0.04, along, y, face + normal * 0.07)
			part(parent, "PeelingPlasterEdge", rimSize, rimPos, Enum.Material.Plaster, jitter(Config.PLASTER_COLOR, rng, 0.1)).CanCollide = false
			local lathSize, lathPos = BuildUtil.axisBox(axis, w, h, 0.05, along, y, face + normal * 0.08)
			part(parent, "ExposedLath", lathSize, lathPos, Enum.Material.WoodPlanks, jitter(Color3.fromRGB(96, 76, 56), rng, 0.1)).CanCollide = false
		end
	end
end

-- Translucent triangular webs tucked into the top corners of a space.
-- Each is a flattened WedgePart with its right-angled corner in the room
-- corner.
local CORNER_YAW = {
	["1,1"] = 0,
	["1,-1"] = math.rad(90),
	["-1,1"] = math.rad(-90),
	["-1,-1"] = math.pi,
}

function Weathering.cobwebs(parent, b, rng, amount)
	local corners = { { b.x1, b.z1, 1, 1 }, { b.x1, b.z0, 1, -1 }, { b.x0, b.z1, -1, 1 }, { b.x0, b.z0, -1, -1 } }
	for _, c in ipairs(corners) do
		if rng:NextNumber() < amount * 0.8 then
			local yaw = CORNER_YAW[c[3] .. "," .. c[4]]
			for layer = 1, rng:NextInteger(1, 2) do
				local s = rng:NextNumber(1.2, 2.6)
				local web = Instance.new("WedgePart")
				web.Name = "Cobweb"
				web.Anchored = true
				web.Size = Vector3.new(0.02, s, s)
				web.CFrame = CFrame.new(c[1] - c[3] * s / 2, H - 0.1 - layer * 0.35, c[2] - c[4] * s / 2) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(90))
				web.Material = Smooth
				web.Color = WEB_COLOR
				web.Transparency = rng:NextNumber(0.72, 0.85)
				overlay(web)
				web.Parent = parent
			end
		end
	end
end

-- Throws a sheet over a piece of furniture (a box a little bigger than it).
function Weathering.dustSheet(parent, model, rng)
	local cf, size = model:GetBoundingBox()
	return part(parent, "DustSheet", size + Vector3.new(0.3, 0.1, 0.3), cf * CFrame.new(0, 0.05, 0), Enum.Material.Fabric, jitter(Color3.fromRGB(214, 210, 200), rng, 0.03))
end

return Weathering
