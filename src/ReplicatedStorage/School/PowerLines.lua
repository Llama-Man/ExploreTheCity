-- Power lines, here and there: the city still has a grid of sorts, patched
-- together.
--   * A run of concrete utility poles across the school's roof, down to
--     the rooftop's landing and on over its blocks (plant
--     block, cradle, mast block), crossarms and insulators, a transformer
--     can on some; a long drop from the plant block across to the
--     department store's shacks.
--   * Cables slung right across the courtyard pit from the school's face
--     to the far wall, with a pair of shoes over one and washing pegged
--     out along another.
-- Thin cables are walk-through; the poles are solid.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Rooftop = require(script.Parent.Rooftop)
local TunnelProps = require(script.Parent.TunnelProps)

local part, cylinder, model, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick
local Metal, Smooth, Concrete, Fabric = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Fabric
local ellipsoid = TunnelProps.ellipsoid
local rgb = Color3.fromRGB

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local CABLE = rgb(30, 30, 32)
local POLE = rgb(170, 166, 156)
local STEEL = rgb(110, 112, 114)
local CLOTHES = { rgb(230, 226, 214), rgb(200, 60, 60), rgb(60, 100, 170), rgb(240, 200, 70), rgb(90, 140, 90), rgb(230, 150, 180), rgb(60, 60, 66) }

local PowerLines = {}

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

-- A cable sagging from a to b; returns its points.
local function cable(parent, a, b, sag, diameter)
	local len = (b - a).Magnitude
	local n = math.clamp(math.floor(len / 5), 5, 28)
	local points = {}
	local prev = a
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		thin(rod(parent, "PowerCable", prev, p, diameter or 0.12, Smooth, CABLE))
		table.insert(points, p)
		prev = p
	end
	return points
end

-- A concrete utility pole standing on y = base.Y, facing `yaw` (its
-- crossarms run across that direction). Returns the three attachment
-- points on its top arm and one lower (the telephone line).
local function pole(parent, base, yaw, rng)
	local m = model(parent, "UtilityPole")
	local h = rng:NextNumber(17, 20)
	local cf = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	cylinder(m, "Pole", h, 0.9, cf * CFrame.new(0, h / 2, 0) * UPRIGHT, Concrete, jitter(POLE, rng, 0.04))
	part(m, "PoleFoot", Vector3.new(1.6, 0.4, 1.6), cf * CFrame.new(0, 0.2, 0), Concrete, rgb(140, 136, 128))
	local points = {}
	for k, y in ipairs({ h - 0.8, h - 2.6 }) do
		part(m, "Crossarm", Vector3.new(k == 1 and 5 or 4, 0.35, 0.35), cf * CFrame.new(0, y, 0), Metal, STEEL)
		for _, x in ipairs(k == 1 and { -2.2, 0.8, 2.2 } or { -1.7, 1.7 }) do
			cylinder(m, "Insulator", 0.5, 0.35, cf * CFrame.new(x, y + 0.42, 0) * UPRIGHT, Smooth, rgb(236, 232, 222))
			if k == 1 then
				table.insert(points, (cf * CFrame.new(x, y + 0.7, 0)).Position)
			end
		end
	end
	table.insert(points, (cf * CFrame.new(0.5, h - 5.5, 0)).Position)
	part(m, "PhoneBox", Vector3.new(0.5, 0.8, 0.4), cf * CFrame.new(0.55, h - 5.5, 0), Metal, rgb(90, 92, 94))
	if rng:NextNumber() < 0.5 then
		cylinder(m, "Transformer", 2, 1.4, cf * CFrame.new(-1, h - 4.4, 0.8) * UPRIGHT, Metal, rgb(150, 156, 150))
		thin(rod(m, "TransformerLead", (cf * CFrame.new(-1, h - 3.4, 0.8)).Position, points[1], 0.08, Smooth, CABLE))
	end
	-- Step bolts up the side, a striped guard low down, a notice.
	for y = 4, h - 4, 1.5 do
		local s = if math.floor(y / 1.5) % 2 == 0 then 1 else -1
		part(m, "StepBolt", Vector3.new(0.7, 0.12, 0.12), cf * CFrame.new(s * 0.7, y, 0), Metal, STEEL)
	end
	for k = 0, 3 do
		cylinder(m, "Guard", 0.5, 0.96, cf * CFrame.new(0, 1.25 + k * 0.5, 0) * UPRIGHT, Smooth, if k % 2 == 0 then rgb(240, 200, 40) else rgb(30, 30, 32))
	end
	return points
end

-- Cables pole to pole: the three power lines, the phone line lower.
local function span(parent, a, b, rng)
	local len = (a[1] - b[1]).Magnitude
	for k = 1, 3 do
		cable(parent, a[k], b[k], len * rng:NextNumber(0.03, 0.05))
	end
	cable(parent, a[4], b[4], len * 0.06, 0.16)
end

local function shoes(parent, p, rng)
	local color = pick({ rgb(230, 226, 214), rgb(200, 40, 40), rgb(30, 30, 32) }, rng)
	for _, s in ipairs({ -1, 1 }) do
		local cf = CFrame.new(p + Vector3.new(s * 0.3, -0.9 - s * 0.2, 0)) * CFrame.Angles(math.rad(80), 0, 0)
		thin(rod(parent, "Laces", p, cf.Position, 0.05, Fabric, rgb(220, 216, 200)))
		thin(ellipsoid(parent, "Shoe", Vector3.new(0.4, 0.4, 1), cf, Smooth, color))
	end
end

local function laundry(parent, p, rng)
	local c = pick(CLOTHES, rng)
	if rng:NextNumber() < 0.5 then
		thin(part(parent, "Shirt", Vector3.new(1.1, 1.3, 0.05), CFrame.new(p - Vector3.new(0, 0.7, 0)), Fabric, c))
	else
		thin(part(parent, "Towel", Vector3.new(0.9, 1.6, 0.05), CFrame.new(p - Vector3.new(0, 0.8, 0)), Fabric, c))
	end
end

function PowerLines.build(parent, rng, storeFace)
	local m = model(parent, "PowerLines")
	local B = Rooftop.BLOCKS
	local roofTop = Config.SCHOOL_TOP
	local midZ = (Config.CLASSROOM_Z_FAR + Config.CORRIDOR_Z_MAX) / 2
	-- Along the school roof, down to the rooftop landing, over the blocks.
	local route = {
		Vector3.new(80, roofTop, midZ),
		Vector3.new(220, roofTop, midZ + 2),
		Vector3.new(360, roofTop, midZ - 1),
		Vector3.new(B.landing[1] + 40, B.landing[5], B.landing[3] + 6),
		Vector3.new(B.plant[1] + 38, B.plant[5], B.plant[4] - 5),
		Vector3.new(B.plant[1] + 88, B.plant[5], B.plant[4] - 4),
		Vector3.new(B.plant[2] - 6, B.plant[5], B.plant[3] + 40),
		Vector3.new(B.cradle[2] - 6, B.cradle[5], B.cradle[4] - 6),
		Vector3.new(B.mast[2] - 6, B.mast[5], B.mast[4] - 6),
	}
	local tops = {}
	for i, p in ipairs(route) do
		local nextP = route[i + 1] or route[i - 1]
		local dir = nextP - p
		local yaw = math.atan2(dir.X, dir.Z) -- crossarms across the line
		tops[i] = pole(m, p, yaw, rng)
	end
	for i = 1, #route - 1 do
		span(m, tops[i], tops[i + 1], rng)
	end
	-- The long drop from the plant block to the store's shacks.
	if storeFace then
		local from = tops[6]
		for k = 1, 2 do
			local to = storeFace + Vector3.new(k * 0.6, 0, 0)
			cable(m, from[k], to, (to - from[k]).Magnitude * 0.06)
		end
		part(m, "WallBracket", Vector3.new(2, 0.6, 0.8), storeFace + Vector3.new(0.6, 0, 0), Metal, STEEL)
	end
	-- Across the courtyard pit, school face to far wall.
	local near, far = Config.COURTYARD_NEAR_Z + 0.6, Config.COURTYARD_NEAR_Z + Config.COURTYARD_DEPTH - 0.6
	for i, x in ipairs({ 90, 230, 360 }) do
		local a = Vector3.new(x, -92 - i * 4, near)
		local b = Vector3.new(x + rng:NextNumber(-40, 40), -108 - i * 3, far)
		part(m, "WallBracket", Vector3.new(1.6, 0.8, 1.2), a + Vector3.new(0, 0, -0.2), Metal, STEEL)
		part(m, "WallBracket", Vector3.new(1.6, 0.8, 1.2), b + Vector3.new(0, 0, 0.2), Metal, STEEL)
		local points
		for k = 1, 3 do
			local off = Vector3.new((k - 2) * 0.5, -(k - 1) * 0.4, 0)
			points = cable(m, a + off, b + off, 22 + k * 2 + rng:NextNumber(0, 6), 0.14)
		end
		if i == 1 then
			shoes(m, points[math.floor(#points * 0.4)], rng)
		elseif i == 2 then
			for j = 2, #points - 1 do
				if rng:NextNumber() < 0.6 then
					laundry(m, points[j], rng)
				end
			end
		end
	end
end

return PowerLines
