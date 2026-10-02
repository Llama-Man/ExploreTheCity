-- Rooftop clutter to fill the walkable space between the big features:
-- machinery and junk (vents, pallets, crates, drums, tyres, cable spools,
-- dishes, antennae, tarps, old school desks, sheds, tanks, cones,
-- cabinets, scaffolding, cooling towers, pipe sections, containers), signs
-- of people (benches, planters, washing lines), and things growing back
-- (weeds, bushes, trees, mossy rubble) and puddles.
--
-- Each builder makes its piece at a "normal" size around `c` (the centre
-- at roof level). Rooftop.lua then scales it anywhere between the entry's
-- `min` and `max`, mostly near the small end, so the occasional piece is
-- much bigger than the rest. `radius` is the footprint at scale 1.

local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local TunnelProps = require(script.Parent.TunnelProps)

local part, cylinder, model, place, jitter, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.place, BuildUtil.jitter, BuildUtil.pick
local Concrete, Metal, Rust, Smooth, Wood, Fabric = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.SmoothPlastic, Enum.Material.Wood, Enum.Material.Fabric

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local STEEL = Color3.fromRGB(120, 122, 124)
local RUST_COLOR = Color3.fromRGB(116, 76, 48)
local PALLET = Color3.fromRGB(150, 122, 86)
local CLOTH = {
	Color3.fromRGB(200, 196, 184),
	Color3.fromRGB(96, 120, 150),
	Color3.fromRGB(170, 70, 60),
	Color3.fromRGB(120, 140, 100),
	Color3.fromRGB(60, 60, 70),
}

local function spin(rng)
	return CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

-- Roof vents on a square of flashing: a mushroom cowl, a spinning turbine
-- vent, or a gooseneck turned back on itself.
local function roofVent(parent, c, rng)
	local m = model(parent, "RoofVent")
	local d = rng:NextNumber(1.2, 2.2)
	local h = rng:NextNumber(2, 4)
	local metal = jitter(STEEL, rng, 0.1)
	part(m, "VentFlashing", Vector3.new(d * 2, 0.15, d * 2), c + Vector3.new(0, 0.08, 0), Metal, BuildUtil.darken(metal, 0.8))
	cylinder(m, "VentCollar", 0.4, d + 0.35, CFrame.new(c + Vector3.new(0, 0.35, 0)) * UPRIGHT, Metal, BuildUtil.darken(metal, 0.9))
	local roll = rng:NextNumber()
	if roll < 0.4 then
		cylinder(m, "VentPipe", h, d, CFrame.new(c + Vector3.new(0, h / 2, 0)) * UPRIGHT, Metal, metal)
		TunnelProps.ellipsoid(m, "VentCowl", Vector3.new(d * 2, d * 0.9, d * 2), CFrame.new(c + Vector3.new(0, h + d * 0.3, 0)), Metal, metal)
		for _, s in ipairs({ -1, 1 }) do
			part(m, "VentStrut", Vector3.new(0.12, d * 0.5, 0.12), c + Vector3.new(s * d * 0.4, h + 0.1, 0), Metal, STEEL)
		end
	elseif roll < 0.75 then
		-- Turbine: a ball of curved vanes on a short throat.
		cylinder(m, "VentPipe", h * 0.6, d, CFrame.new(c + Vector3.new(0, h * 0.3, 0)) * UPRIGHT, Metal, metal)
		local hub = c + Vector3.new(0, h * 0.6 + d * 0.7, 0)
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			part(m, "TurbineVane", Vector3.new(0.08, d * 1.3, d * 0.5), CFrame.new(hub) * CFrame.Angles(0, a, 0) * CFrame.new(d * 0.62, 0, 0) * CFrame.Angles(0, 0.5, math.rad(12)), Metal, metal)
		end
		cylinder(m, "TurbineCap", 0.2, d * 1.2, CFrame.new(hub + Vector3.new(0, d * 0.65, 0)) * UPRIGHT, Metal, metal)
	else
		-- Gooseneck: up, over, and down again.
		local top = c + Vector3.new(0, h, 0)
		cylinder(m, "VentPipe", h, d, CFrame.new(c + Vector3.new(0, h / 2, 0)) * UPRIGHT, Metal, metal)
		local bendAt = spin(rng)
		local over = top + bendAt:VectorToWorldSpace(Vector3.new(d * 1.3, 0, 0))
		rod(m, "VentBend", top, over + Vector3.new(0, d * 0.3, 0), d, Metal, metal)
		rod(m, "VentMouth", over + Vector3.new(0, d * 0.3, 0), over - Vector3.new(0, d * 0.6, 0), d, Metal, metal)
		part(m, "VentJoint", Vector3.one * d, top, Metal, metal).Shape = Enum.PartType.Ball
		local grille = cylinder(m, "VentGrille", 0.05, d * 0.9, CFrame.new(over - Vector3.new(0, d * 0.62, 0)) * UPRIGHT, Metal, Color3.fromRGB(30, 30, 32))
		grille.CanCollide = false
	end
end

local function palletStack(parent, c, rng)
	local m = model(parent, "PalletStack")
	local count = rng:NextInteger(0, 5)
	for k = 0, count do
		local y = k * 0.9
		local cf = CFrame.new(c + Vector3.new(rng:NextNumber(-0.3, 0.3), y, rng:NextNumber(-0.3, 0.3))) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0)
		for _, dz in ipairs({ -1.6, 0, 1.6 }) do
			part(m, "PalletBlock", Vector3.new(4, 0.5, 0.6), cf * CFrame.new(0, 0.25, dz), Wood, jitter(PALLET, rng, 0.1))
		end
		for i = -3, 3 do
			part(m, "PalletSlat", Vector3.new(0.45, 0.2, 4), cf * CFrame.new(i * 0.6, 0.6, 0), Wood, jitter(PALLET, rng, 0.1))
		end
	end
	-- Sometimes a load of bags still strapped to the top pallet.
	if rng:NextNumber() < 0.35 then
		local topY = (count + 1) * 0.9 - 0.2
		for i = 0, rng:NextInteger(2, 5) do
			local bag = TunnelProps.ellipsoid(m, "CementBag", Vector3.new(1.8, 0.7, 1.2), CFrame.new(c + Vector3.new(-0.9 + (i % 2) * 1.8, topY + 0.35 + math.floor(i / 2) * 0.6, (i % 3 - 1) * 1.2)), Fabric, jitter(Color3.fromRGB(190, 180, 160), rng, 0.05))
			bag.CanCollide = true
		end
		for _, dx in ipairs({ -1, 1 }) do
			part(m, "Strap", Vector3.new(0.12, 0.05, 4.2), c + Vector3.new(dx, topY + 1.3, 0), Smooth, Color3.fromRGB(40, 90, 160)).CanCollide = false
		end
	end
end

local function crates(parent, c, rng)
	local m = model(parent, "Crates")
	for _ = 1, rng:NextInteger(1, 3) do
		local size = Vector3.new(rng:NextNumber(2.4, 3.8), rng:NextNumber(2, 3.4), rng:NextNumber(2.2, 3.4))
		local cf = CFrame.new(c + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)
		TunnelProps.crate(m, cf, size, rng, if rng:NextNumber() < 0.15 then "open" else nil)
		if rng:NextNumber() < 0.35 then
			local top = size * rng:NextNumber(0.6, 0.85)
			TunnelProps.crate(m, cf * CFrame.new(rng:NextNumber(-0.3, 0.3), size.Y, rng:NextNumber(-0.3, 0.3)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), top, rng, nil)
		end
	end
end

local function drums(parent, c, rng)
	local m = model(parent, "Drums")
	for _ = 1, rng:NextInteger(2, 5) do
		local at = c + Vector3.new(rng:NextNumber(-2.2, 2.2), 0, rng:NextNumber(-2.2, 2.2))
		if rng:NextNumber() < 0.25 then
			TunnelProps.drum(m, CFrame.new(at + Vector3.new(0, 1.1, 0)) * spin(rng) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, -1.7, 0), rng)
		else
			TunnelProps.drum(m, CFrame.new(at) * spin(rng), rng)
		end
	end
end

-- A tyre: rubber casing, tread grooves, the dark hole in the middle.
local function tyre(m, cf)
	cylinder(m, "Tyre", 0.9, 2.8, cf, Enum.Material.Rubber, Color3.fromRGB(28, 28, 30))
	for _, dx in ipairs({ -0.25, 0.25 }) do
		cylinder(m, "TreadGroove", 0.08, 2.84, cf * CFrame.new(dx, 0, 0), Enum.Material.Rubber, Color3.fromRGB(18, 18, 20))
	end
	cylinder(m, "TyreHole", 0.92, 1.4, cf, Smooth, Color3.fromRGB(12, 12, 14))
end

local function tyres(parent, c, rng)
	local m = model(parent, "TyreStack")
	local count = rng:NextInteger(2, 6)
	for k = 0, count - 1 do
		tyre(m, CFrame.new(c + Vector3.new(rng:NextNumber(-0.15, 0.15), 0.45 + k * 0.9, rng:NextNumber(-0.15, 0.15))) * UPRIGHT)
	end
	if rng:NextNumber() < 0.6 then
		tyre(m, CFrame.new(c + Vector3.new(2.2, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(20)))
	end
end

local function cableSpool(parent, c, rng)
	local m = model(parent, "CableSpool")
	local d = rng:NextNumber(4, 6)
	local frame = CFrame.new(c + Vector3.new(0, d / 2, 0)) * spin(rng)
	local wood = jitter(PALLET, rng, 0.1)
	for _, s in ipairs({ -1, 1 }) do
		cylinder(m, "SpoolFlange", 0.4, d, frame * CFrame.new(s * 1.4, 0, 0), Wood, wood)
		cylinder(m, "SpoolHub", 0.5, d * 0.2, frame * CFrame.new(s * 1.55, 0, 0), Metal, STEEL)
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2
			part(m, "FlangeBolt", Vector3.new(0.5, 0.25, 0.25), frame * CFrame.new(s * 1.62, math.cos(a) * d * 0.3, math.sin(a) * d * 0.3), Metal, STEEL)
		end
	end
	local cableColor = pick({ Color3.fromRGB(30, 30, 30), Color3.fromRGB(150, 60, 40) }, rng)
	cylinder(m, "SpoolCable", 2.4, d * 0.7, frame, Enum.Material.Rubber, cableColor)
	-- A loose end trailing off across the roof.
	local start = (frame * CFrame.new(0.4, -d * 0.35, 0)).Position
	local prev = start
	for k = 1, 3 do
		local nxt = Vector3.new(start.X, c.Y + 0.15, start.Z) + frame:VectorToWorldSpace(Vector3.new(rng:NextNumber(-1, 1), 0, -k * 1.6))
		rod(m, "LooseCable", prev, nxt, 0.25, Enum.Material.Rubber, cableColor)
		prev = nxt
	end
end

-- A satellite dish: curved reflector on a yoke, three struts out to the
-- feed horn, on a weighted frame.
local function satelliteDish(parent, c, rng)
	local m = model(parent, "SatelliteDish")
	local d = rng:NextNumber(3.5, 6)
	part(m, "DishBallast", Vector3.new(2.6, 0.6, 2.6), c + Vector3.new(0, 0.3, 0), Concrete, Color3.fromRGB(120, 118, 110))
	cylinder(m, "DishPole", 3, 0.4, CFrame.new(c + Vector3.new(0, 2, 0)) * UPRIGHT, Metal, STEEL)
	local aim = spin(rng) * CFrame.Angles(math.rad(rng:NextNumber(20, 50)), 0, 0)
	local dishCf = CFrame.new(c + Vector3.new(0, 3.6, 0)) * aim
	local white = jitter(Color3.fromRGB(206, 204, 196), rng, 0.08)
	TunnelProps.ellipsoid(m, "Dish", Vector3.new(d, d, d * 0.22), dishCf, Metal, white)
	part(m, "DishYoke", Vector3.new(0.6, 0.6, 0.8), dishCf * CFrame.new(0, 0, d * 0.12), Metal, STEEL)
	local horn = dishCf * CFrame.new(0, 0, -d * 0.55)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		rod(m, "FeedStrut", (dishCf * CFrame.new(math.cos(a) * d * 0.42, math.sin(a) * d * 0.42, -d * 0.06)).Position, horn.Position, 0.1, Metal, STEEL)
	end
	part(m, "FeedHorn", Vector3.new(0.4, 0.4, 0.6), horn, Smooth, Color3.fromRGB(40, 40, 42))
	rod(m, "DishCable", (dishCf * CFrame.new(0, 0, d * 0.12)).Position, c + Vector3.new(0.9, 0.1, 1.4), 0.1, Enum.Material.Rubber, Color3.fromRGB(30, 30, 30))
end

-- A cluster of masts: TV aerials with their crossed elements, whips,
-- guy wires down to the roof.
local function antennae(parent, c, rng)
	local m = model(parent, "Antennae")
	part(m, "AntennaBase", Vector3.new(3, 1, 3), c + Vector3.new(0, 0.5, 0), Concrete, Color3.fromRGB(120, 118, 110))
	for _ = 1, rng:NextInteger(2, 4) do
		local h = rng:NextNumber(5, 16)
		local foot = c + Vector3.new(rng:NextNumber(-1, 1), 1, rng:NextNumber(-1, 1))
		local top = foot + Vector3.new(rng:NextNumber(-0.3, 0.3), h, rng:NextNumber(-0.3, 0.3))
		rod(m, "Antenna", foot, top, 0.18, Metal, STEEL)
		if rng:NextNumber() < 0.6 then
			-- Yagi: a boom with a row of cross elements, longest at the back.
			local boom = CFrame.new(top - Vector3.new(0, 0.6, 0)) * spin(rng)
			local len = rng:NextNumber(3, 5)
			part(m, "AerialBoom", Vector3.new(0.1, 0.1, len), boom, Metal, STEEL)
			for k = 0, 5 do
				local z = -len / 2 + k * len / 5
				part(m, "AerialElement", Vector3.new(2.4 - k * 0.25, 0.06, 0.06), boom * CFrame.new(0, 0, z), Metal, STEEL)
			end
		end
		if h > 9 then
			for k = 0, 2 do
				local a = k / 3 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
				rod(m, "GuyWire", foot + Vector3.new(0, h * 0.7, 0), c + Vector3.new(math.cos(a) * h * 0.45, 0.05, math.sin(a) * h * 0.45), 0.04, Metal, Color3.fromRGB(150, 150, 150))
			end
		end
	end
end

local function bench(parent, c, rng)
	local m = model(parent, "Bench")
	local wood = jitter(Color3.fromRGB(120, 92, 62), rng, 0.1)
	local iron = Color3.fromRGB(50, 50, 52)
	for i = 0, 2 do
		if rng:NextNumber() > 0.08 then
			part(m, "BenchSlat", Vector3.new(7, 0.25, 0.6), c + Vector3.new(0, 2, -0.8 + i * 0.8), Wood, wood)
		end
	end
	for i = 0, 1 do
		part(m, "BenchBack", Vector3.new(7, 0.5, 0.2), CFrame.new(c + Vector3.new(0, 2.9 + i * 0.7, 1.25 + i * 0.12)) * CFrame.Angles(math.rad(-10), 0, 0), Wood, wood)
	end
	for _, dx in ipairs({ -3, 3 }) do
		-- Cast-iron end frame: front leg, back leg rising into the back
		-- rest, an armrest.
		part(m, "BenchLeg", Vector3.new(0.3, 2, 0.3), c + Vector3.new(dx, 1, -1), Metal, iron)
		part(m, "BenchLeg", Vector3.new(0.3, 3.8, 0.3), CFrame.new(c + Vector3.new(dx, 1.9, 1.1)) * CFrame.Angles(math.rad(-8), 0, 0), Metal, iron)
		part(m, "BenchRail", Vector3.new(0.25, 0.25, 2.4), c + Vector3.new(dx, 1.85, 0.05), Metal, iron)
		part(m, "BenchArm", Vector3.new(0.3, 0.2, 2.4), c + Vector3.new(dx, 2.9, 0), Metal, iron)
	end
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi * 2))
end

local function planter(parent, c, rng)
	local m = model(parent, "Planter")
	part(m, "PlanterBox", Vector3.new(6, 2, 3), c + Vector3.new(0, 1, 0), Concrete, Color3.fromRGB(128, 124, 116))
	part(m, "PlanterCoping", Vector3.new(6.3, 0.25, 3.3), c + Vector3.new(0, 2.05, 0), Concrete, Color3.fromRGB(144, 140, 132))
	part(m, "PlanterSoil", Vector3.new(5.4, 0.2, 2.4), c + Vector3.new(0, 1.95, 0), Enum.Material.Ground, Color3.fromRGB(62, 48, 36))
	for _ = 1, rng:NextInteger(2, 5) do
		local s = rng:NextNumber(0.8, 1.8)
		local shrub = TunnelProps.ellipsoid(m, "DeadShrub", Vector3.new(s, s * 0.8, s), CFrame.new(c + Vector3.new(rng:NextNumber(-2.2, 2.2), 2 + s * 0.35, rng:NextNumber(-0.8, 0.8))), Enum.Material.LeafyGrass, jitter(Color3.fromRGB(110, 94, 60), rng, 0.15))
		shrub.CanCollide = false
	end
	for _ = 1, rng:NextInteger(2, 6) do
		local base = c + Vector3.new(rng:NextNumber(-2.4, 2.4), 2.05, rng:NextNumber(-1, 1))
		rod(m, "DryStalk", base, base + Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(1.5, 3), rng:NextNumber(-0.5, 0.5)), 0.08, Wood, Color3.fromRGB(140, 120, 80)).CanCollide = false
	end
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi))
end

local function washingLine(parent, c, rng)
	local m = model(parent, "WashingLine")
	local len = rng:NextNumber(9, 14)
	for _, s in ipairs({ -1, 1 }) do
		cylinder(m, "LinePole", 6, 0.3, CFrame.new(c + Vector3.new(s * len / 2, 3, 0)) * UPRIGHT, Metal, STEEL)
		part(m, "LineCrossbar", Vector3.new(0.2, 0.2, 2.4), c + Vector3.new(s * len / 2, 5.9, 0), Metal, STEEL)
		part(m, "PoleFoot", Vector3.new(1.2, 0.4, 1.2), c + Vector3.new(s * len / 2, 0.2, 0), Concrete, Color3.fromRGB(120, 118, 110))
	end
	for _, z in ipairs({ -0.9, 0.9 }) do
		cylinder(m, "Line", len, 0.06, CFrame.new(c + Vector3.new(0, 5.8, z)), Smooth, Color3.fromRGB(200, 200, 196))
	end
	for _, z in ipairs({ -0.9, 0.9 }) do
		local x = -len / 2 + 1
		while x < len / 2 - 1 do
			if rng:NextNumber() < 0.55 then
				local w, h = rng:NextNumber(1, 2.4), rng:NextNumber(1.2, 2.6)
				local cloth = part(m, "Laundry", Vector3.new(w, h, 0.05), CFrame.new(c + Vector3.new(x + w / 2, 5.8 - h / 2, z)) * CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), 0, 0), Fabric, jitter(pick(CLOTH, rng), rng, 0.1))
				cloth.CanCollide = false
				for _, px in ipairs({ x + 0.2, x + w - 0.2 }) do
					part(m, "Peg", Vector3.new(0.12, 0.35, 0.12), c + Vector3.new(px, 5.8, z), Smooth, pick({ Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 140, 220), Color3.fromRGB(230, 200, 60) }, rng)).CanCollide = false
				end
				x += w + 0.3
			else
				x += 1
			end
		end
	end
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi))
end

-- A tarp thrown over a heap of something, roped down and weighted.
local function tarpPile(parent, c, rng)
	local m = model(parent, "TarpPile")
	local size = Vector3.new(rng:NextNumber(5, 8), rng:NextNumber(2, 3.5), rng:NextNumber(4, 6))
	local cf = CFrame.new(c) * spin(rng)
	local color = pick({ Color3.fromRGB(46, 76, 120), Color3.fromRGB(70, 90, 60), Color3.fromRGB(150, 110, 60) }, rng)
	TunnelProps.ellipsoid(m, "TarpMound", size * Vector3.new(1, 2, 1), cf, Fabric, color).CanCollide = true
	-- Skirt where it spreads out on the roof.
	part(m, "TarpSkirt", Vector3.new(size.X + 1, 0.1, size.Z + 1), cf * CFrame.new(0, 0.05, 0), Fabric, BuildUtil.darken(color, 0.92))
	for _, dx in ipairs({ -size.X / 4, size.X / 4 }) do
		part(m, "TarpRope", Vector3.new(0.12, 0.12, size.Z + 0.6), cf * CFrame.new(dx, size.Y * 0.85, 0) * CFrame.Angles(0, 0, 0), Fabric, Color3.fromRGB(200, 190, 150)).CanCollide = false
	end
	for _ = 1, rng:NextInteger(2, 4) do
		part(m, "TarpWeight", Vector3.new(1.4, 0.6, 1), cf * CFrame.new(rng:NextNumber(-size.X / 2, size.X / 2), 0.3, pick({ -1, 1 }, rng) * (size.Z / 2 + 0.3)) * spin(rng), Concrete, Color3.fromRGB(120, 118, 110))
	end
end

-- Old school desks and chairs dumped on the roof.
local function deskPile(parent, c, rng)
	for _ = 1, rng:NextInteger(2, 4) do
		local at = c + Vector3.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-2.5, 2.5))
		if rng:NextNumber() < 0.5 then
			local desk = Props.studentDesk(parent, at, Props.DESK_TOP_COLOR, rng)
			if rng:NextNumber() < 0.5 then
				Props.tipDesk(desk, at, rng:NextNumber(0, math.pi * 2))
			else
				place(desk, at, Vector3.zero, rng:NextNumber(0, math.pi * 2))
			end
		else
			local chair = Props.studentChair(parent, at, Props.DESK_TOP_COLOR)
			Props.tipChair(chair, at, rng:NextNumber(0, math.pi * 2))
		end
	end
end

-- A corrugated shed: ribbed walls, a lean-to roof with a gutter, a framed
-- door with a padlock hasp, a small window.
local function shed(parent, c, rng)
	local m = model(parent, "Shed")
	local color = jitter(pick({ Color3.fromRGB(110, 116, 110), Color3.fromRGB(130, 100, 70), Color3.fromRGB(90, 100, 120) }, rng), rng, 0.08)
	local dark = BuildUtil.darken(color, 0.85)
	part(m, "ShedBody", Vector3.new(9, 7, 7), c + Vector3.new(0, 3.5, 0), Metal, color)
	for i = -4, 4 do
		part(m, "ShedRib", Vector3.new(0.3, 7, 7.2), c + Vector3.new(i, 3.5, 0), Metal, dark)
	end
	part(m, "ShedRoof", Vector3.new(10, 0.4, 8.4), CFrame.new(c + Vector3.new(0, 7.3, 0)) * CFrame.Angles(math.rad(6), 0, 0), Rust, RUST_COLOR)
	cylinder(m, "Gutter", 10, 0.5, CFrame.new(c + Vector3.new(0, 6.7, 4.3)), Metal, STEEL)
	cylinder(m, "Downpipe", 6.5, 0.35, CFrame.new(c + Vector3.new(4.8, 3.4, 4.3)) * UPRIGHT, Metal, STEEL)
	part(m, "DoorFrame", Vector3.new(3.6, 6, 0.2), c + Vector3.new(1.5, 3, -3.6), Metal, BuildUtil.darken(color, 0.7))
	part(m, "ShedDoor", Vector3.new(3, 5.5, 0.12), c + Vector3.new(1.5, 2.75, -3.72), Metal, if rng:NextNumber() < 0.3 then Color3.fromRGB(34, 34, 36) else dark)
	part(m, "Hasp", Vector3.new(0.3, 0.6, 0.15), c + Vector3.new(0.2, 3, -3.82), Metal, STEEL)
	part(m, "Padlock", Vector3.new(0.35, 0.4, 0.15), c + Vector3.new(0.2, 2.6, -3.9), Metal, Color3.fromRGB(180, 150, 60))
	local glass = part(m, "ShedWindow", Vector3.new(2, 1.4, 0.1), c + Vector3.new(-2.4, 4.8, -3.64), Enum.Material.Glass, Color3.fromRGB(60, 70, 72))
	glass.Transparency = 0.3
	part(m, "WindowFrame", Vector3.new(2.3, 1.7, 0.08), c + Vector3.new(-2.4, 4.8, -3.6), Metal, BuildUtil.darken(color, 0.7))
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi * 2))
end

-- A water tank on a stand: banded, with an access ladder and a pipe down.
local function smallTank(parent, c, rng)
	local m = model(parent, "SmallTank")
	for _, o in ipairs({ Vector3.new(2, 0, 2), Vector3.new(-2, 0, 2), Vector3.new(2, 0, -2), Vector3.new(-2, 0, -2) }) do
		part(m, "TankLeg", Vector3.new(0.4, 2, 0.4), c + o + Vector3.new(0, 1, 0), Metal, STEEL)
	end
	for _, s in ipairs({ -1, 1 }) do
		rod(m, "LegBrace", c + Vector3.new(-2, 0.3, s * 2), c + Vector3.new(2, 1.8, s * 2), 0.15, Metal, STEEL)
	end
	part(m, "TankPlatform", Vector3.new(5, 0.3, 5), c + Vector3.new(0, 2.1, 0), Metal, STEEL)
	local color = jitter(Color3.fromRGB(150, 146, 136), rng, 0.08)
	cylinder(m, "Tank", 5, 6, CFrame.new(c + Vector3.new(0, 4.7, 0)) * UPRIGHT, Rust, color)
	for _, y in ipairs({ 3.2, 4.7, 6.2 }) do
		cylinder(m, "TankBand", 0.25, 6.2, CFrame.new(c + Vector3.new(0, y, 0)) * UPRIGHT, Metal, BuildUtil.darken(color, 0.75))
	end
	cylinder(m, "TankLid", 0.4, 2, CFrame.new(c + Vector3.new(0, 7.4, 0)) * UPRIGHT, Metal, STEEL)
	for k = 0, 6 do
		part(m, "LadderRung", Vector3.new(0.9, 0.1, 0.1), c + Vector3.new(0, 2.6 + k * 0.7, -3.2), Metal, STEEL)
	end
	for _, dx in ipairs({ -0.45, 0.45 }) do
		part(m, "LadderRail", Vector3.new(0.1, 5, 0.1), c + Vector3.new(dx, 4.7, -3.2), Metal, STEEL)
	end
	rod(m, "TankOutlet", c + Vector3.new(2.6, 2.8, 0), c + Vector3.new(3.4, 0.2, 0), 0.4, Metal, STEEL)
end

-- Broken concrete: chunks and a slab or two, rebar sticking out.
local function rubble(parent, c, rng)
	for _ = 1, rng:NextInteger(5, 10) do
		local s = Vector3.new(rng:NextNumber(0.6, 2.4), rng:NextNumber(0.4, 1.4), rng:NextNumber(0.6, 2.4))
		local cf = CFrame.new(c + Vector3.new(rng:NextNumber(-2.5, 2.5), s.Y * 0.4, rng:NextNumber(-2.5, 2.5))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4))
		part(parent, "Rubble", s, cf, Concrete, jitter(Color3.fromRGB(110, 108, 100), rng, 0.12))
		if s.X > 1.8 and rng:NextNumber() < 0.4 then
			local from = (cf * CFrame.new(s.X / 2, 0, 0)).Position
			rod(parent, "Rebar", from, from + Vector3.new(rng:NextNumber(0.4, 1.4), rng:NextNumber(0.2, 1.2), rng:NextNumber(-0.6, 0.6)), 0.12, Rust, RUST_COLOR)
		end
	end
end

local function cones(parent, c, rng)
	for _ = 1, rng:NextInteger(1, 4) do
		local at = c + Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		local m = model(parent, "TrafficCone")
		part(m, "ConeBase", Vector3.new(1.4, 0.2, 1.4), at + Vector3.new(0, 0.1, 0), Enum.Material.Rubber, Color3.fromRGB(30, 30, 30))
		for k, d in ipairs({ 1, 0.75, 0.5 }) do
			cylinder(m, "Cone", 0.6, d, CFrame.new(at + Vector3.new(0, 0.2 + k * 0.6 - 0.3, 0)) * UPRIGHT, Smooth, if k == 2 then Color3.fromRGB(220, 220, 214) else Color3.fromRGB(214, 90, 30))
		end
		if rng:NextNumber() < 0.4 then
			BuildUtil.placeTilted(m, at, 0.5, rng:NextNumber(0, math.pi * 2), CFrame.Angles(0, 0, math.rad(90)))
		end
	end
end

-- An electrical cabinet on a plinth: louvred door, handle, warning plate,
-- conduit running off across the roof.
local function electricalBox(parent, c, rng)
	local m = model(parent, "ElectricalCabinet")
	local color = jitter(Color3.fromRGB(150, 156, 150), rng, 0.06)
	part(m, "Plinth", Vector3.new(3.4, 0.4, 2), c + Vector3.new(0, 0.2, 0), Concrete, Color3.fromRGB(120, 118, 110))
	part(m, "Cabinet", Vector3.new(3, 5, 1.6), c + Vector3.new(0, 2.9, 0), Metal, color)
	part(m, "CabinetHood", Vector3.new(3.3, 0.2, 1.9), c + Vector3.new(0, 5.5, -0.1), Metal, BuildUtil.darken(color, 0.9))
	part(m, "CabinetSeam", Vector3.new(0.05, 4.6, 0.05), c + Vector3.new(0, 2.9, -0.82), Metal, Color3.fromRGB(70, 72, 72))
	for k = 0, 4 do
		part(m, "Louvre", Vector3.new(1, 0.08, 0.05), c + Vector3.new(-0.8, 1.2 + k * 0.25, -0.82), Metal, BuildUtil.darken(color, 0.6))
	end
	part(m, "Handle", Vector3.new(0.1, 0.6, 0.12), c + Vector3.new(0.3, 3, -0.86), Metal, Color3.fromRGB(30, 30, 32))
	part(m, "WarningPlate", Vector3.new(0.8, 0.8, 0.05), c + Vector3.new(0.8, 4.2, -0.82), Smooth, Color3.fromRGB(220, 190, 40))
	cylinder(m, "Conduit", 3, 0.4, CFrame.new(c + Vector3.new(0, 1.2, 1.6)) * CFrame.Angles(0, math.pi / 2, 0), Metal, STEEL)
	cylinder(m, "ConduitRun", 5, 0.4, CFrame.new(c + Vector3.new(0, 0.25, 5.4)) * CFrame.Angles(0, math.pi / 2, 0), Metal, STEEL)
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi * 2))
end

-- A scaffold bay: tubes, couplers, two boarded lifts with toe boards, a
-- cross brace.
local function scaffold(parent, c, rng)
	local m = model(parent, "Scaffold")
	local w, h, d = 7, rng:NextNumber(7, 11), 3
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			cylinder(m, "ScaffoldTube", h, 0.25, CFrame.new(c + Vector3.new(sx * w / 2, h / 2, sz * d / 2)) * UPRIGHT, Metal, STEEL)
			part(m, "BasePlate", Vector3.new(0.8, 0.1, 0.8), c + Vector3.new(sx * w / 2, 0.05, sz * d / 2), Metal, STEEL)
		end
	end
	for _, y in ipairs({ h * 0.5, h }) do
		for i = -1, 1 do
			part(m, "ScaffoldBoard", Vector3.new(w, 0.2, 0.9), c + Vector3.new(0, y, i * 0.95), Wood, jitter(PALLET, rng, 0.1))
		end
		part(m, "ToeBoard", Vector3.new(w, 0.6, 0.1), c + Vector3.new(0, y + 0.4, -d / 2), Wood, jitter(PALLET, rng, 0.1))
		for _, sz in ipairs({ -1, 1 }) do
			cylinder(m, "ScaffoldTube", w, 0.2, CFrame.new(c + Vector3.new(0, y + 1, sz * d / 2)), Metal, STEEL)
			for _, sx in ipairs({ -1, 1 }) do
				part(m, "Coupler", Vector3.new(0.4, 0.4, 0.4), c + Vector3.new(sx * w / 2, y + 1, sz * d / 2), Metal, Color3.fromRGB(80, 82, 84))
			end
		end
	end
	rod(m, "ScaffoldBrace", c + Vector3.new(-w / 2, 0.3, d / 2), c + Vector3.new(w / 2, h * 0.5, d / 2), 0.2, Metal, STEEL)
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi))
end

-- ===== Growing back =====

local GREENS = {
	Color3.fromRGB(72, 100, 52),
	Color3.fromRGB(96, 116, 58),
	Color3.fromRGB(58, 82, 48),
	Color3.fromRGB(120, 124, 66),
}

-- Tufts of grass and weeds pushing up through the roof.
local function weeds(parent, c, rng)
	local m = model(parent, "Weeds")
	for _ = 1, rng:NextInteger(8, 18) do
		local h = rng:NextNumber(0.6, 2.2)
		local at = c + Vector3.new(rng:NextNumber(-1.5, 1.5), h / 2, rng:NextNumber(-1.5, 1.5))
		local blade = part(m, "WeedBlade", Vector3.new(0.12, h, rng:NextNumber(0.2, 0.5)), CFrame.new(at) * spin(rng) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)), Enum.Material.LeafyGrass, jitter(pick(GREENS, rng), rng, 0.12))
		blade.CanCollide = false
	end
end

local function bush(parent, c, rng)
	local m = model(parent, "Bush")
	for _ = 1, rng:NextInteger(3, 7) do
		local s = rng:NextNumber(1.4, 3)
		local ball = part(m, "Foliage", Vector3.new(s, s, s), c + Vector3.new(rng:NextNumber(-1.6, 1.6), s * 0.4 + rng:NextNumber(0, 1), rng:NextNumber(-1.6, 1.6)), Enum.Material.LeafyGrass, jitter(pick(GREENS, rng), rng, 0.12))
		ball.Shape = Enum.PartType.Ball
		ball.CanCollide = false
	end
	weeds(m, c, rng)
end

-- A tree that has seeded itself in a crack and grown crooked.
local function rooftopTree(parent, c, rng)
	local m = model(parent, "RooftopTree")
	local h = rng:NextNumber(7, 12)
	local lean = CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))
	local trunk = CFrame.new(c) * lean
	local bark = jitter(Color3.fromRGB(78, 64, 50), rng, 0.1)
	cylinder(m, "Trunk", h, rng:NextNumber(0.7, 1.1), trunk * CFrame.new(0, h / 2, 0) * UPRIGHT, Wood, bark)
	local crown = trunk * CFrame.new(0, h, 0)
	for _ = 1, rng:NextInteger(2, 4) do
		local dir = spin(rng) * CFrame.Angles(math.rad(rng:NextNumber(30, 60)), 0, 0)
		local len = rng:NextNumber(2.5, 4.5)
		local branch = crown * CFrame.new(0, -rng:NextNumber(0, 2.5), 0) * dir
		cylinder(m, "Branch", len, 0.4, branch * CFrame.new(0, len / 2, 0) * UPRIGHT, Wood, bark)
		local tip = (branch * CFrame.new(0, len, 0)).Position
		for _ = 1, rng:NextInteger(1, 3) do
			local s = rng:NextNumber(2.5, 4.5)
			local ball = part(m, "Foliage", Vector3.new(s, s, s), tip + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 1), rng:NextNumber(-1, 1)), Enum.Material.LeafyGrass, jitter(pick(GREENS, rng), rng, 0.15))
			ball.Shape = Enum.PartType.Ball
			ball.CanCollide = false
		end
	end
	weeds(m, c, rng)
end

-- A heap of broken concrete with weeds and a bush growing over it.
local function mossyMound(parent, c, rng)
	rubble(parent, c, rng)
	weeds(parent, c + Vector3.new(0, 0.8, 0), rng)
	if rng:NextNumber() < 0.6 then
		bush(parent, c + Vector3.new(rng:NextNumber(-1.5, 1.5), 0.5, rng:NextNumber(-1.5, 1.5)), rng)
	end
end

-- Rainwater collected in a dip: a few overlapping patches of still water,
-- each a hair higher than the last so they don't flicker.
local function puddle(parent, c, rng)
	local m = model(parent, "Puddle")
	for i = 1, rng:NextInteger(2, 4) do
		local d = rng:NextNumber(2.5, 6)
		local water = BuildUtil.disc(m, "Water", d, 0.04, c + Vector3.new(rng:NextNumber(-1.8, 1.8), 0.03 + i * 0.004, rng:NextNumber(-1.8, 1.8)), Smooth, Color3.fromRGB(40, 46, 48))
		water.Transparency = 0.15
		water.Reflectance = 0.4
		water.CanCollide = false
	end
	if rng:NextNumber() < 0.4 then
		weeds(m, c + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)), rng)
	end
end

-- ===== Big machinery =====

-- A packaged cooling tower: louvred box on legs, a fan stack with the fan
-- blades showing through its grille, a ladder, pipes in and out.
local function coolingTower(parent, c, rng)
	local m = model(parent, "CoolingTower")
	local color = jitter(Color3.fromRGB(140, 142, 138), rng, 0.08)
	local dark = BuildUtil.darken(color, 0.7)
	for _, o in ipairs({ Vector3.new(6, 0, 6), Vector3.new(-6, 0, 6), Vector3.new(6, 0, -6), Vector3.new(-6, 0, -6) }) do
		part(m, "TowerLeg", Vector3.new(0.8, 3, 0.8), c + o + Vector3.new(0, 1.5, 0), Metal, STEEL)
	end
	part(m, "TowerBody", Vector3.new(15, 9, 15), c + Vector3.new(0, 7.5, 0), Metal, color)
	for _, face in ipairs({ -1, 1 }) do
		for i = -3, 3 do
			part(m, "Louvre", Vector3.new(15.2, 0.3, 0.25), c + Vector3.new(0, 4.5 + (i + 3) * 1.1, face * 7.55), Metal, dark)
		end
	end
	cylinder(m, "FanStack", 3, 11, CFrame.new(c + Vector3.new(0, 13.5, 0)) * UPRIGHT, Metal, color)
	cylinder(m, "FanOpening", 0.1, 10, CFrame.new(c + Vector3.new(0, 14.2, 0)) * UPRIGHT, Smooth, Color3.fromRGB(24, 24, 26))
	local bladeSpin = rng:NextNumber(0, math.pi)
	for k = 0, 4 do
		part(m, "FanBlade", Vector3.new(4.4, 0.12, 1.2), CFrame.new(c + Vector3.new(0, 14.4, 0)) * CFrame.Angles(0, bladeSpin + k / 5 * math.pi * 2, 0) * CFrame.new(2.4, 0, 0) * CFrame.Angles(math.rad(20), 0, 0), Metal, Color3.fromRGB(70, 72, 74))
	end
	cylinder(m, "FanHub", 0.6, 1.4, CFrame.new(c + Vector3.new(0, 14.4, 0)) * UPRIGHT, Metal, Color3.fromRGB(50, 52, 54))
	for k = -2, 2 do
		part(m, "FanGrille", Vector3.new(10.4, 0.12, 0.12), c + Vector3.new(0, 15.05, k * 2), Metal, dark).CanCollide = false
		part(m, "FanGrille", Vector3.new(0.12, 0.12, 10.4), c + Vector3.new(k * 2, 15.05, 0), Metal, dark).CanCollide = false
	end
	for k = 0, 11 do
		part(m, "LadderRung", Vector3.new(1, 0.12, 0.12), c + Vector3.new(7.8, 3.4 + k * 0.9, -4), Metal, STEEL)
	end
	for _, dz in ipairs({ -4.5, -3.5 }) do
		part(m, "LadderRail", Vector3.new(0.12, 11, 0.12), c + Vector3.new(7.8, 8.4, dz), Metal, STEEL)
	end
	for _, dz in ipairs({ -3, 3 }) do
		rod(m, "TowerPipe", c + Vector3.new(-7.5, 4, dz), c + Vector3.new(-12, 1, dz), 1.2, Metal, if dz < 0 then STEEL else RUST_COLOR)
	end
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi / 2))
end

-- A section of giant pipe lying where it was dumped: a bolted flange at
-- one end, the open bore at the other, rust run down its side.
local function bigPipe(parent, c, rng)
	local m = model(parent, "PipeSection")
	local d, len = rng:NextNumber(4, 6), rng:NextNumber(12, 20)
	local frame = CFrame.new(c + Vector3.new(0, d / 2, 0)) * spin(rng)
	cylinder(m, "Pipe", len, d, frame, Rust, jitter(RUST_COLOR, rng, 0.1))
	local flange = frame * CFrame.new(len / 2, 0, 0)
	cylinder(m, "PipeFlange", 0.6, d + 1.2, flange, Rust, BuildUtil.darken(RUST_COLOR, 0.8))
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		cylinder(m, "FlangeBolt", 1, 0.3, flange * CFrame.new(0, math.cos(a) * (d / 2 + 0.35), math.sin(a) * (d / 2 + 0.35)), Metal, STEEL)
	end
	cylinder(m, "PipeBore", 0.1, d - 0.6, frame * CFrame.new(-len / 2 - 0.02, 0, 0), Smooth, Color3.fromRGB(20, 18, 16))
	cylinder(m, "PipeLip", 0.4, d + 0.1, frame * CFrame.new(-len / 2 + 0.2, 0, 0), Rust, BuildUtil.darken(RUST_COLOR, 0.9))
	for k = 1, 3 do
		cylinder(m, "WeldSeam", 0.15, d + 0.05, frame * CFrame.new(-len / 2 + k * len / 4, 0, 0), Rust, BuildUtil.darken(RUST_COLOR, 0.7))
	end
end

-- Shipping containers: corrugated sides, corner castings, top rails, and
-- cargo doors at one end with their locking bars.
local function containerStack(parent, c, rng)
	local m = model(parent, "ContainerStack")
	for k = 0, rng:NextInteger(0, 2) do
		local color = jitter(pick({ Color3.fromRGB(150, 50, 40), Color3.fromRGB(40, 90, 120), Color3.fromRGB(180, 140, 50), Color3.fromRGB(70, 100, 70) }, rng), rng, 0.08)
		local dark = BuildUtil.darken(color, 0.8)
		local cf = CFrame.new(c + Vector3.new(rng:NextNumber(-1, 1), 4.25 + k * 8.5, rng:NextNumber(-1, 1))) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0)
		part(m, "ContainerBody", Vector3.new(36, 8.5, 8), cf, Rust, color)
		for i = -8, 8 do
			part(m, "Corrugation", Vector3.new(0.5, 7.8, 8.2), cf * CFrame.new(i * 2, 0, 0), Rust, BuildUtil.darken(color, 0.85))
		end
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part(m, "TopRail", Vector3.new(36, 0.35, 0.35), cf * CFrame.new(0, sy * 4.1, sz * 3.95), Metal, dark)
			end
			for _, sx in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					part(m, "CornerCasting", Vector3.new(0.7, 0.7, 0.7), cf * CFrame.new(sx * 17.7, sy * 3.9, sz * 3.7), Metal, Color3.fromRGB(60, 60, 62))
				end
			end
		end
		-- Doors: two leaves, four locking bars with handles.
		local doors = cf * CFrame.new(18.05, 0, 0)
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "ContainerDoor", Vector3.new(0.15, 7.8, 3.8), doors * CFrame.new(0, 0, sz * 1.95), Rust, dark)
		end
		for _, z in ipairs({ -3, -1, 1, 3 }) do
			part(m, "LockBar", Vector3.new(0.15, 7.6, 0.12), doors * CFrame.new(0.12, 0, z), Metal, STEEL)
			part(m, "LockHandle", Vector3.new(0.12, 0.12, 0.8), doors * CFrame.new(0.2, -1, z + 0.35), Metal, STEEL)
		end
	end
	place(m, c, Vector3.zero, rng:NextNumber(0, math.pi))
end

-- { build, radius at scale 1, weight, min scale, max scale, big }. `big`
-- marks the pieces that can dominate an area; blocks that want a heavier,
-- more industrial feel boost those.
local function entry(build, radius, weight, min, max, big)
	return { build = build, radius = radius, weight = weight, min = min, max = max, big = big or false }
end

local entries = {
	entry(roofVent, 2, 3, 0.8, 4.5, true),
	entry(palletStack, 3, 2, 1, 1.6),
	entry(crates, 4, 2, 0.7, 3),
	entry(drums, 3.5, 2, 1, 1.3),
	entry(tyres, 3, 1, 1, 3),
	entry(cableSpool, 3.5, 1, 0.8, 3),
	entry(satelliteDish, 3.5, 1.2, 0.8, 5, true),
	entry(antennae, 2.5, 1.2, 1, 4),
	entry(bench, 4, 1, 1, 1.1),
	entry(planter, 4, 1, 1, 2.5),
	entry(washingLine, 7.5, 0.8, 1, 1.3),
	entry(tarpPile, 4.5, 1.2, 1, 3.5),
	entry(deskPile, 5, 1, 1, 1.2),
	entry(shed, 6, 0.6, 0.9, 2.5, true),
	entry(smallTank, 4, 0.8, 1, 4.5, true),
	entry(rubble, 3.5, 1.4, 0.8, 4.5),
	entry(cones, 2.5, 0.8, 1, 1.2),
	entry(electricalBox, 2.5, 1, 1, 2.2),
	entry(scaffold, 5, 0.6, 1, 3, true),
	entry(weeds, 2, 3, 0.8, 2.5),
	entry(bush, 3, 1.8, 0.7, 3.5),
	entry(rooftopTree, 5, 0.9, 0.8, 3),
	entry(mossyMound, 4, 1.2, 1, 3.5),
	entry(puddle, 4, 2.5, 0.8, 3),
	entry(coolingTower, 9, 0.35, 1, 2, true),
	entry(bigPipe, 10, 0.4, 1, 2.2, true),
	entry(containerStack, 18, 0.3, 1, 1, true),
}

-- A few builders other areas reuse directly (the list above is still what
-- ipairs sees).
entries.weeds = weeds
entries.bush = bush
entries.puddle = puddle
entries.rubble = rubble
entries.rooftopTree = rooftopTree
entries.mossyMound = mossyMound

return entries
