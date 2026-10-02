-- The maze of rooms and corridors beside the facility's bottom hall, the
-- way through to the fire exit and the courtyard.
--
-- A grid of steel-walled rooms at the bottom hall's floor level, joined by
-- doorways (some with doors jammed half open) and knocked-through gaps.
-- It's braided: most dead ends are opened up into loops, so there's
-- always another way round (the plan is for something to hunt you in
-- here one day). Every room is lit well enough to find the way, and a
-- green 非常口 sign every two or three doorways marks the route out. The
-- rooms are what the facility was: offices, stores with pallet racking,
-- server rooms, plant rooms, pipe corridors, and a few where the rock has
-- come in through the ceiling.
--
-- Built in the facility's frame (see Facility.lua) into its model, before
-- that model is pivoted into place. Rooms that would poke out of the crag
-- are left out.

local BuildUtil = require(script.Parent.BuildUtil)
local RouteCheck = require(script.Parent.RouteCheck)

local part, cylinder, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local Metal, Plate, Smooth, Concrete, Neon, Wood, Plastic = Enum.Material.Metal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic, Enum.Material.Concrete, Enum.Material.Neon, Enum.Material.Wood, Enum.Material.Plastic
local Glass, Cardboard = Enum.Material.Glass, Enum.Material.Cardboard

local terrain = workspace.Terrain
local AIR = Enum.Material.Air

local STEEL = Color3.fromRGB(96, 98, 100)
local WALL = Color3.fromRGB(88, 92, 94)
local DARK = Color3.fromRGB(58, 60, 62)
local BLACK = Color3.fromRGB(26, 27, 30)
local EXIT_GREEN = Color3.fromRGB(40, 140, 70)
local SAFETY_YELLOW = Color3.fromRGB(214, 176, 40)
local CELL = 16
local H = 10 -- ceiling height
local DOOR_W, DOOR_H = 6, 8
local CORRIDOR_W = 6
local INNER = CELL / 2 - 0.4 -- from a room's centre to its wall faces
local SEG_END = 7 -- usable wall runs out to here (the corner pillars beyond)
local DOOR_CLEAR = 3.7 -- keep this far from a doorway's centre line
-- Crag interior (world), with a margin: rooms must stay inside it.
local WORLD = { x0 = 471, x1 = 749, z0 = -121, z1 = 165 }
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local FacilityMaze = {}

-- ===== Helpers =====

local function box(parent, name, xa, xb, ya, yb, za, zb, material, color)
	return part(parent, name, Vector3.new(xb - xa, yb - ya, zb - za), Vector3.new((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2), material, color)
end

-- A part placed relative to a frame `cf` (x across, y up, z; -z is "out
-- from the wall into the room" for wall frames).
local function at(parent, name, cf, x, y, z, size, material, color)
	return part(parent, name, size, cf * CFrame.new(x, y, z), material, color)
end

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function wall(parent, axis, fixed, a, b, y0, y1, openings)
	BuildUtil.strip(parent, {
		name = "MazeWall",
		axis = axis,
		fixed = fixed,
		spanStart = a,
		spanEnd = b,
		bottom = y0,
		top = y1,
		thickness = 0.8,
		openings = openings,
		material = Metal,
		color = WALL,
	})
end

local function label(parent, cframe, size, face, text, bg, fg, material)
	local plate = part(parent, "Sign", size, cframe, material or Smooth, bg)
	plate.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = fg
	t.Text = text
	t.Parent = gui
	gui.Parent = plate
	return plate
end

local function exitSign(parent, cframe, size, face)
	local plate = label(parent, cframe, size, face, "非常口", EXIT_GREEN, Color3.fromRGB(236, 250, 236), Neon)
	local glow = Instance.new("SurfaceLight")
	glow.Face = face
	glow.Range = 6
	glow.Brightness = 0.6
	glow.Color = Color3.fromRGB(120, 255, 150)
	glow.Parent = plate
	return plate
end

local function ceilingLight(parent, cf, rng, deadChance)
	local lit = rng:NextNumber() > (deadChance or 0.1)
	part(parent, "LightHousing", Vector3.new(1.4, 0.3, 8.4), cf * CFrame.new(0, 0.15, 0), Metal, Color3.fromRGB(200, 200, 194))
	local strip = part(parent, "LightStrip", Vector3.new(1, 0.1, 8), cf * CFrame.new(0, -0.05, 0), if lit then Neon else Smooth, if lit then Color3.fromRGB(226, 234, 222) else Color3.fromRGB(80, 82, 80))
	strip.CanCollide = false
	if lit then
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 18
		light.Angle = 150
		light.Brightness = 1
		light.Color = Color3.fromRGB(220, 232, 214)
		light.Parent = strip
		if rng:NextNumber() < 0.2 then
			strip:AddTag("FlickerLight")
		end
	end
end

-- Centres for `n` items of width `w` along a wall run [a, b], spaced by
-- at least `gap`, as many as fit.
local function slots(a, b, w, gap)
	local len = b - a
	local n = math.floor((len + gap) / (w + gap))
	if n < 1 then
		return {}
	end
	local used = n * w + (n - 1) * gap
	local out = {}
	for k = 0, n - 1 do
		table.insert(out, a + (len - used) / 2 + w / 2 + k * (w + gap))
	end
	return out
end

-- ===== Furniture and fittings =====
-- Builders take a frame on the floor at the item's back-centre, facing out
-- into the room along its LookVector (so "in front" is -Z).

local function officeChair(m, cf, rng)
	local c = Color3.fromRGB(46, 48, 54)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local tip = (cf * CFrame.new(math.cos(a) * 1.1, 0.25, math.sin(a) * 1.1)).Position
		rod(m, "ChairBase", (cf * CFrame.new(0, 0.3, 0)).Position, tip, 0.18, Metal, DARK)
		local wheel = part(m, "Castor", Vector3.new(0.3, 0.3, 0.3), tip - Vector3.new(0, 0.1, 0), Plastic, BLACK)
		wheel.Shape = Enum.PartType.Ball
	end
	cylinder(m, "ChairColumn", 1.7, 0.28, cf * CFrame.new(0, 1.15, 0) * UPRIGHT, Metal, STEEL)
	at(m, "ChairSeat", cf, 0, 2.1, 0, Vector3.new(1.8, 0.35, 1.8), Enum.Material.Fabric, c)
	at(m, "ChairBack", cf, 0, 3.4, 0.85, Vector3.new(1.7, 2.1, 0.3), Enum.Material.Fabric, c)
	rod(m, "ChairBackPost", (cf * CFrame.new(0, 2.2, 0.8)).Position, (cf * CFrame.new(0, 2.6, 0.85)).Position, 0.15, Metal, DARK)
end

local function monitor(m, cf, rng)
	at(m, "MonitorFoot", cf, 0, 0.04, 0, Vector3.new(0.8, 0.08, 0.6), Plastic, BLACK)
	at(m, "MonitorNeck", cf, 0, 0.5, 0.15, Vector3.new(0.15, 0.9, 0.12), Plastic, BLACK)
	at(m, "MonitorBody", cf, 0, 1.3, 0, Vector3.new(2, 1.25, 0.14), Plastic, BLACK)
	local on = rng:NextNumber() < 0.3
	local screen = at(m, "MonitorScreen", cf, 0, 1.32, -0.08, Vector3.new(1.8, 1.05, 0.02), if on then Neon else Glass, if on then Color3.fromRGB(40, 80, 120) else Color3.fromRGB(20, 22, 26))
	screen.Transparency = if on then 0.3 else 0
	screen.CanCollide = false
end

local function desk(m, cf, rng)
	local top = Color3.fromRGB(176, 170, 156)
	local frame = Color3.fromRGB(110, 112, 110)
	at(m, "DeskTop", cf, 0, 3.05, -1.1, Vector3.new(3.6, 0.15, 2.2), Plastic, jitter(top, rng, 0.04))
	for _, s in ipairs({ -1, 1 }) do
		at(m, "DeskSide", cf, s * 1.7, 1.5, -1.1, Vector3.new(0.12, 2.95, 2.1), Metal, frame)
	end
	at(m, "DeskModesty", cf, 0, 2.2, -0.15, Vector3.new(3.3, 1.5, 0.08), Metal, frame)
	-- Drawer pedestal.
	at(m, "DeskPedestal", cf, 1.05, 1.45, -1.1, Vector3.new(1.2, 2.8, 2), Metal, frame)
	for k = 0, 2 do
		at(m, "DrawerLine", cf, 1.05, 0.5 + k * 0.9, -2.11, Vector3.new(1.1, 0.04, 0.02), Metal, DARK)
		at(m, "DrawerHandle", cf, 1.05, 0.8 + k * 0.9, -2.14, Vector3.new(0.4, 0.08, 0.06), Metal, STEEL)
	end
	monitor(m, cf * CFrame.new(rng:NextNumber(-0.5, 0.3), 3.13, -0.6) * CFrame.Angles(0, math.rad(rng:NextNumber(-15, 15)), 0), rng)
	at(m, "Keyboard", cf, rng:NextNumber(-0.4, 0.2), 3.16, -1.6, Vector3.new(1.3, 0.06, 0.45), Plastic, Color3.fromRGB(200, 198, 190))
	for _ = 1, rng:NextInteger(0, 3) do
		local paper = at(m, "Paper", cf * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rng:NextNumber(-1.4, 1.4), 3.14, rng:NextNumber(-1.8, -0.4), Vector3.new(0.9, 0.02, 1.2), Smooth, Color3.fromRGB(226, 222, 206))
		paper.CanCollide = false
	end
	if rng:NextNumber() < 0.5 then
		cylinder(m, "Mug", 0.4, 0.35, cf * CFrame.new(-1.3, 3.33, -1.5) * UPRIGHT, Smooth, pick({ Color3.fromRGB(200, 60, 50), Color3.fromRGB(230, 230, 224), Color3.fromRGB(60, 90, 150) }, rng))
	end
	local chairCF = cf * CFrame.new(rng:NextNumber(-0.4, 0.4), 0, -2.8) * CFrame.Angles(0, math.rad(rng:NextNumber(150, 210)), 0)
	if rng:NextNumber() < 0.15 then
		chairCF = cf * CFrame.new(rng:NextNumber(-0.5, 0.5), 0.9, -3.4) * CFrame.Angles(math.rad(90), rng:NextNumber(0, 3), 0)
	end
	officeChair(m, chairCF, rng)
end

local function filingCabinet(m, cf, rng)
	local c = jitter(Color3.fromRGB(150, 150, 140), rng, 0.08)
	at(m, "FilingCabinet", cf, 0, 2.2, -1, Vector3.new(1.6, 4.4, 2), Metal, c)
	for k = 0, 3 do
		local open = k == rng:NextInteger(0, 6)
		local dz = if open then -1.2 else 0
		at(m, "Drawer", cf, 0, 0.55 + k * 1.08, -2 + dz / 2, Vector3.new(1.5, 1, 0.08 + math.abs(dz)), Metal, darken(c, 0.95))
		at(m, "DrawerHandle", cf, 0, 0.8 + k * 1.08, -2.06 + dz, Vector3.new(0.5, 0.1, 0.08), Metal, STEEL)
	end
end

local function whiteboard(m, cf, rng)
	at(m, "Whiteboard", cf, 0, 5.2, -0.08, Vector3.new(5, 2.8, 0.1), Smooth, Color3.fromRGB(236, 238, 234))
	at(m, "WhiteboardFrame", cf, 0, 3.75, -0.2, Vector3.new(5.1, 0.12, 0.35), Metal, STEEL)
	for _ = 1, rng:NextInteger(3, 8) do
		local line = at(m, "Scrawl", cf * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6))), rng:NextNumber(-1.9, 1.9), rng:NextNumber(4.3, 6.2), -0.14, Vector3.new(rng:NextNumber(0.5, 2), 0.06, 0.02), Smooth, pick({ Color3.fromRGB(30, 40, 90), Color3.fromRGB(150, 30, 30), BLACK }, rng))
		line.CanCollide = false
	end
end

local function waterCooler(m, cf, rng)
	at(m, "CoolerBody", cf, 0, 1.8, -0.8, Vector3.new(1.2, 3.6, 1.2), Plastic, Color3.fromRGB(220, 220, 214))
	local bottle = cylinder(m, "CoolerBottle", 1.6, 1.1, cf * CFrame.new(0, 4.4, -0.8) * UPRIGHT, Glass, Color3.fromRGB(140, 190, 220))
	bottle.Transparency = if rng:NextNumber() < 0.5 then 0.5 else 0.8
end

-- A 42U-style rack: frame, side panels, a stack of servers of different
-- heights (some pulled out, some missing), status lights, mesh front door.
local function serverRack(m, cf, rng)
	local w, d, h = 2.2, 3.4, 7.6
	local frameColor = Color3.fromRGB(30, 31, 34)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			at(m, "RackPost", cf, sx * (w / 2 - 0.08), h / 2, -d / 2 + sz * (d / 2 - 0.08), Vector3.new(0.16, h, 0.16), Metal, frameColor)
		end
		at(m, "RackSide", cf, sx * (w / 2 - 0.02), h / 2, -d / 2, Vector3.new(0.04, h - 0.2, d - 0.3), Metal, Color3.fromRGB(40, 42, 46))
	end
	at(m, "RackTop", cf, 0, h - 0.06, -d / 2, Vector3.new(w, 0.12, d), Metal, frameColor)
	at(m, "RackBase", cf, 0, 0.1, -d / 2, Vector3.new(w, 0.2, d), Metal, frameColor)
	at(m, "RackBack", cf, 0, h / 2, -0.05, Vector3.new(w - 0.2, h - 0.2, 0.06), Metal, Color3.fromRGB(36, 38, 42))
	-- Servers.
	local y = 0.35
	while y < h - 0.8 do
		local unitH = pick({ 0.34, 0.34, 0.68, 0.68, 1.02 }, rng)
		if y + unitH > h - 0.3 then
			break
		end
		local roll = rng:NextNumber()
		if roll > 0.1 then
			local pulled = if roll > 0.95 then -rng:NextNumber(0.6, 1.4) else 0
			local body = pick({ Color3.fromRGB(44, 46, 50), Color3.fromRGB(60, 62, 66), Color3.fromRGB(150, 150, 146) }, rng)
			at(m, "Server", cf, 0, y + unitH / 2 - 0.02, -d / 2 - 0.1 + pulled, Vector3.new(w - 0.36, unitH - 0.04, d - 0.4), Metal, body)
			at(m, "ServerBezel", cf, 0, y + unitH / 2 - 0.02, -d + 0.12 + pulled, Vector3.new(w - 0.3, unitH - 0.06, 0.05), Plastic, darken(body, 0.7))
			if rng:NextNumber() < 0.75 then
				local led = at(m, "StatusLights", cf, rng:NextNumber(-0.6, 0.3), y + unitH / 2, -d + 0.08 + pulled, Vector3.new(rng:NextNumber(0.15, 0.5), 0.06, 0.03), Neon, pick({ Color3.fromRGB(60, 220, 90), Color3.fromRGB(60, 220, 90), Color3.fromRGB(230, 170, 40), Color3.fromRGB(230, 60, 40), Color3.fromRGB(70, 140, 240) }, rng))
				led.CanCollide = false
			end
			if unitH > 0.5 and rng:NextNumber() < 0.5 then
				-- Drive bays.
				for k = 0, 3 do
					at(m, "DriveBay", cf, -0.7 + k * 0.45, y + unitH / 2, -d + 0.09 + pulled, Vector3.new(0.38, unitH - 0.2, 0.03), Plastic, Color3.fromRGB(80, 82, 86))
				end
			end
		end
		y += unitH
	end
	-- Mesh front door: shut, open, or gone.
	local roll = rng:NextNumber()
	if roll < 0.55 then
		local door = at(m, "RackDoor", cf, 0, h / 2, -d - 0.05, Vector3.new(w - 0.1, h - 0.3, 0.06), Metal, Color3.fromRGB(34, 36, 40))
		door.Transparency = 0.55
	elseif roll < 0.85 then
		local hinge = cf * CFrame.new(w / 2 - 0.05, h / 2, -d - 0.05)
		local door = part(m, "RackDoor", Vector3.new(w - 0.1, h - 0.3, 0.06), hinge * CFrame.Angles(0, math.rad(rng:NextNumber(70, 110)), 0) * CFrame.new(-(w - 0.1) / 2, 0, 0), Metal, Color3.fromRGB(34, 36, 40))
		door.Transparency = 0.55
	end
end

local function cableTray(m, a, b, rng)
	local dir = (b - a).Unit
	local across = Vector3.new(-dir.Z, 0, dir.X)
	for _, s in ipairs({ -1, 1 }) do
		rod(m, "TrayRail", a + across * s * 0.9, b + across * s * 0.9, 0.12, Metal, STEEL)
	end
	local len = (b - a).Magnitude
	for d = 0.5, len, 1.5 do
		local p = a + dir * d
		rod(m, "TrayRung", p - across * 0.9, p + across * 0.9, 0.08, Metal, STEEL)
	end
	for k = 1, rng:NextInteger(2, 4) do
		local off = across * rng:NextNumber(-0.7, 0.7)
		rod(m, "Cable", a + off + Vector3.new(0, 0.12, 0), b + off + Vector3.new(0, 0.12, 0), rng:NextNumber(0.1, 0.25), Smooth, pick({ BLACK, Color3.fromRGB(40, 70, 140), Color3.fromRGB(200, 170, 40), Color3.fromRGB(60, 120, 60) }, rng))
	end
end

local function coolingUnit(m, cf, rng)
	local c = Color3.fromRGB(214, 210, 196)
	at(m, "CoolingUnit", cf, 0, 3.9, -1.3, Vector3.new(3, 7.8, 2.6), Metal, c)
	for k = 0, 9 do
		at(m, "Grille", cf, 0, 1 + k * 0.5, -2.61, Vector3.new(2.6, 0.12, 0.02), Metal, darken(c, 0.6))
	end
	local screen = at(m, "UnitDisplay", cf, 0.6, 6.4, -2.62, Vector3.new(0.8, 0.5, 0.02), Neon, Color3.fromRGB(60, 200, 110))
	screen.CanCollide = false
end

local function palletRack(m, cf, len, rng)
	local blue, orange = Color3.fromRGB(40, 80, 150), Color3.fromRGB(220, 110, 30)
	local d = 2.6
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -0.15, -d + 0.15 }) do
			at(m, "RackUpright", cf, sx * (len / 2 - 0.1), 3.3, z, Vector3.new(0.18, 6.6, 0.18), Metal, blue)
		end
		rod(m, "RackBrace", (cf * CFrame.new(sx * (len / 2 - 0.1), 0.4, -0.15)).Position, (cf * CFrame.new(sx * (len / 2 - 0.1), 3, -d + 0.15)).Position, 0.08, Metal, blue)
	end
	for _, level in ipairs({ 0.35, 3.2 }) do
		for _, z in ipairs({ -0.15, -d + 0.15 }) do
			at(m, "RackBeam", cf, 0, level, z, Vector3.new(len, 0.25, 0.12), Metal, orange)
		end
		-- Pallets and what's on them.
		for _, px in ipairs(slots(-len / 2 + 0.2, len / 2 - 0.2, 2.2, 0.2)) do
			if rng:NextNumber() < 0.85 then
				at(m, "Pallet", cf, px, level + 0.35, -d / 2, Vector3.new(2.1, 0.3, 2.3), Wood, jitter(Color3.fromRGB(170, 140, 100), rng, 0.08))
				local roll = rng:NextNumber()
				if roll < 0.5 then
					for _ = 1, rng:NextInteger(1, 3) do
						local s = Vector3.new(rng:NextNumber(0.8, 1.9), rng:NextNumber(0.7, 1.8), rng:NextNumber(0.8, 2))
						at(m, "Box", cf * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), px + rng:NextNumber(-0.3, 0.3), level + 0.5 + s.Y / 2, -d / 2 + rng:NextNumber(-0.2, 0.2), s, Cardboard, jitter(Color3.fromRGB(170, 140, 100), rng, 0.1))
					end
				elseif roll < 0.8 then
					for _, dz in ipairs({ -0.55, 0.55 }) do
						cylinder(m, "Drum", 2.2, 1, cf * CFrame.new(px + rng:NextNumber(-0.4, 0.4), level + 1.6, -d / 2 + dz) * UPRIGHT, Metal, pick({ Color3.fromRGB(40, 70, 150), Color3.fromRGB(200, 160, 40), Color3.fromRGB(150, 40, 30) }, rng))
					end
				else
					at(m, "Sacks", cf, px, level + 1, -d / 2, Vector3.new(1.9, 1, 2), Enum.Material.Fabric, Color3.fromRGB(200, 190, 160))
				end
			end
		end
	end
end

local function electricalPanel(m, cf, rng)
	local c = jitter(Color3.fromRGB(190, 186, 170), rng, 0.05)
	at(m, "ElectricalPanel", cf, 0, 3.2, -0.6, Vector3.new(2.4, 6, 1.2), Metal, c)
	at(m, "PanelSeam", cf, 0, 3.2, -1.21, Vector3.new(0.04, 5.8, 0.02), Metal, darken(c, 0.6))
	at(m, "PanelHandle", cf, 0.3, 3.4, -1.25, Vector3.new(0.1, 0.6, 0.08), Metal, BLACK)
	label(m, cf * CFrame.new(-0.6, 5.3, -1.22), Vector3.new(0.8, 0.8, 0.02), Enum.NormalId.Front, "!", SAFETY_YELLOW, BLACK)
	for k = 0, 5 do
		at(m, "PanelVent", cf, -0.6, 1 + k * 0.25, -1.21, Vector3.new(0.8, 0.08, 0.02), Metal, darken(c, 0.5))
	end
	if rng:NextNumber() < 0.5 then
		rod(m, "Conduit", (cf * CFrame.new(0.8, 6.2, -0.6)).Position, (cf * CFrame.new(0.8, H, -0.6)).Position, 0.3, Metal, STEEL)
	end
end

local function valveWheel(m, cf, rng)
	cylinder(m, "ValveWheel", 0.15, 1.4, cf, Metal, Color3.fromRGB(180, 40, 30))
	for k = 0, 2 do
		local a = k / 3 * math.pi
		part(m, "ValveSpoke", Vector3.new(0.1, 1.3, 0.1), cf * CFrame.Angles(a, 0, 0), Metal, Color3.fromRGB(180, 40, 30))
	end
end

local function pumpSet(m, cf, rng)
	at(m, "PumpBase", cf, 0, 0.2, -1.4, Vector3.new(3.4, 0.4, 2.2), Metal, DARK)
	cylinder(m, "PumpMotor", 2, 1.5, cf * CFrame.new(-0.6, 1.2, -1.4), Metal, Color3.fromRGB(50, 100, 110))
	for k = 0, 3 do
		cylinder(m, "MotorFin", 0.1, 1.62, cf * CFrame.new(-1.4 + k * 0.5, 1.2, -1.4), Metal, Color3.fromRGB(40, 80, 90))
	end
	cylinder(m, "PumpCasing", 1.1, 1.8, cf * CFrame.new(1, 1.2, -1.4) * CFrame.Angles(0, math.rad(90), 0), Metal, Color3.fromRGB(40, 80, 120))
	local top = (cf * CFrame.new(1, 2, -1.4)).Position
	rod(m, "PumpPipe", top, Vector3.new(top.X, cf.Position.Y + H, top.Z), 0.8, Metal, STEEL)
	cylinder(m, "Flange", 0.2, 1.2, CFrame.new(top + Vector3.new(0, 3, 0)) * UPRIGHT, Metal, DARK)
	valveWheel(m, CFrame.new(top + Vector3.new(0, 4.6, 0)) * cf.Rotation * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0), rng)
	local gauge = cylinder(m, "Gauge", 0.15, 0.7, CFrame.new(top + Vector3.new(0, 2.2, 0)) * cf.Rotation * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.rad(90), 0), Smooth, Color3.fromRGB(236, 236, 230))
	gauge.CanCollide = false
end

-- ===== Rooms =====
-- ctx: cx, cz, y, rng, m, side(s) -> "wall"/"door"/"open", frame(s, along),
-- runs(s) -> usable {a, b} stretches of wall.

local ROOM = {}
local ROOM_NAMES = { office = "事務室", storage = "倉庫", servers = "サーバー室", plant = "機械室", corridor = "通路", collapsed = "立入禁止" }

function ROOM.office(ctx)
	local m, rng = ctx.m, ctx.rng
	local boardDone = false
	for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
		for _, run in ipairs(ctx.runs(s)) do
			for _, a in ipairs(slots(run[1], run[2], 3.7, 0.4)) do
				desk(m, ctx.frame(s, a), rng)
			end
			if run[2] - run[1] < 3.7 and run[2] - run[1] >= 1.8 then
				filingCabinet(m, ctx.frame(s, (run[1] + run[2]) / 2), rng)
			end
			if not boardDone and ctx.side(s) == "wall" then
				whiteboard(m, ctx.frame(s, 0), rng)
				boardDone = true
			end
		end
	end
	if rng:NextNumber() < 0.4 then
		for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
			if ctx.side(s) == "door" then
				waterCooler(m, ctx.frame(s, 5.8), rng)
				break
			end
		end
	end
	for _ = 1, rng:NextInteger(4, 10) do
		local paper = part(m, "Paper", Vector3.new(0.9, 0.02, 1.2), CFrame.new(ctx.cx + rng:NextNumber(-6, 6), ctx.y + 0.02, ctx.cz + rng:NextNumber(-6, 6)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, Color3.fromRGB(226, 222, 206))
		paper.CanCollide = false
	end
end

function ROOM.storage(ctx)
	local m, rng = ctx.m, ctx.rng
	for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
		for _, run in ipairs(ctx.runs(s)) do
			local len = run[2] - run[1]
			if len >= 4.6 then
				palletRack(m, ctx.frame(s, (run[1] + run[2]) / 2), math.min(len, 13.8), rng)
			elseif len >= 2.2 then
				-- Drums or a stack of empty pallets.
				local cf = ctx.frame(s, (run[1] + run[2]) / 2)
				if rng:NextNumber() < 0.5 then
					for k = 0, rng:NextInteger(2, 6) do
						at(m, "Pallet", cf * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), 0, 0.15 + k * 0.32, -1.2, Vector3.new(2.1, 0.3, 2.3), Wood, jitter(Color3.fromRGB(170, 140, 100), rng, 0.08))
					end
				else
					cylinder(m, "Drum", 2.8, 1.9, cf * CFrame.new(0, 1.4, -1.1) * UPRIGHT, Metal, pick({ Color3.fromRGB(40, 70, 150), Color3.fromRGB(200, 160, 40) }, rng))
				end
			end
		end
	end
	if rng:NextNumber() < 0.5 then
		-- A pallet jack left by a doorway.
		local cf = CFrame.new(ctx.cx + rng:NextNumber(-3, 3), ctx.y, ctx.cz + rng:NextNumber(-3, 3)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		for _, s in ipairs({ -0.6, 0.6 }) do
			at(m, "JackFork", cf, s, 0.15, -1.6, Vector3.new(0.4, 0.2, 3.6), Metal, Color3.fromRGB(200, 60, 40))
		end
		at(m, "JackBody", cf, 0, 0.5, 0.4, Vector3.new(1.6, 0.8, 0.8), Metal, Color3.fromRGB(200, 60, 40))
		rod(m, "JackHandle", (cf * CFrame.new(0, 0.8, 0.5)).Position, (cf * CFrame.new(0, 3.6, 1.5)).Position, 0.15, Metal, DARK)
	end
end

function ROOM.servers(ctx)
	local m, rng = ctx.m, ctx.rng
	-- Raised floor: pale panels with dark joints.
	box(m, "RaisedFloor", ctx.cx - INNER, ctx.cx + INNER, ctx.y, ctx.y + 0.05, ctx.cz - INNER, ctx.cz + INNER, Plastic, Color3.fromRGB(176, 178, 174))
	for k = -3, 3 do
		local joint = box(m, "FloorJoint", ctx.cx + k * 2 - 0.04, ctx.cx + k * 2 + 0.04, ctx.y + 0.05, ctx.y + 0.07, ctx.cz - INNER, ctx.cz + INNER, Smooth, Color3.fromRGB(90, 92, 94))
		joint.CanCollide = false
		joint = box(m, "FloorJoint", ctx.cx - INNER, ctx.cx + INNER, ctx.y + 0.05, ctx.y + 0.07, ctx.cz + k * 2 - 0.04, ctx.cz + k * 2 + 0.04, Smooth, Color3.fromRGB(90, 92, 94))
		joint.CanCollide = false
	end
	local cooled = false
	for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
		for _, run in ipairs(ctx.runs(s)) do
			local len = run[2] - run[1]
			if not cooled and len >= 3.2 and len < 4.6 then
				coolingUnit(m, ctx.frame(s, (run[1] + run[2]) / 2), rng)
				cooled = true
			else
				local centres = slots(run[1], run[2], 2.2, 0.05)
				for _, a in ipairs(centres) do
					if rng:NextNumber() < 0.08 then
						-- One toppled over.
						local cf = ctx.frame(s, a)
						-- Pivot on its front bottom edge, top falling out into the room.
						serverRack(m, cf * CFrame.new(0, 0, -3.4) * CFrame.Angles(-math.rad(rng:NextNumber(60, 80)), 0, 0) * CFrame.new(0, 0, 3.4), rng)
					else
						serverRack(m, ctx.frame(s, a), rng)
					end
				end
				if #centres > 0 then
					local first, last = ctx.frame(s, centres[1] - 1.1), ctx.frame(s, centres[#centres] + 1.1)
					cableTray(m, (first * CFrame.new(0, H - 1.6, -1.7)).Position, (last * CFrame.new(0, H - 1.6, -1.7)).Position, rng)
				end
			end
		end
	end
end

function ROOM.plant(ctx)
	local m, rng = ctx.m, ctx.rng
	local pumped = false
	for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
		for _, run in ipairs(ctx.runs(s)) do
			local len = run[2] - run[1]
			if not pumped and len >= 3.6 then
				pumpSet(m, ctx.frame(s, (run[1] + run[2]) / 2), rng)
				pumped = true
			else
				for _, a in ipairs(slots(run[1], run[2], 2.4, 0.3)) do
					electricalPanel(m, ctx.frame(s, a), rng)
				end
			end
		end
		-- A pipe run along every solid wall, high up, with a valve.
		if ctx.side(s) == "wall" then
			local a, b = ctx.frame(s, -SEG_END), ctx.frame(s, SEG_END)
			for k = 0, 1 do
				rod(m, "WallPipe", (a * CFrame.new(0, H - 1.2 - k * 1.1, -0.7)).Position, (b * CFrame.new(0, H - 1.2 - k * 1.1, -0.7)).Position, 0.7, Metal, if k == 0 then STEEL else Color3.fromRGB(116, 76, 48))
			end
			valveWheel(m, ctx.frame(s, rng:NextNumber(-4, 4)) * CFrame.new(0, H - 2.3, -1.5) * CFrame.Angles(0, math.rad(90), 0), rng)
		end
	end
	label(m, CFrame.new(ctx.cx, ctx.y + 0.03, ctx.cz), Vector3.new(4, 0.03, 4), Enum.NormalId.Top, "危険", SAFETY_YELLOW, BLACK)
end

function ROOM.corridor(ctx)
	local m, rng = ctx.m, ctx.rng
	for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
		if ctx.side(s) == "wall" then
			local a, b = ctx.frame(s, -SEG_END), ctx.frame(s, SEG_END)
			for k = 0, 2 do
				rod(m, "WallPipe", (a * CFrame.new(0, H - 1 - k * 0.8, -0.5)).Position, (b * CFrame.new(0, H - 1 - k * 0.8, -0.5)).Position, 0.5, Metal, STEEL)
			end
			for _, along in ipairs({ -5, 0, 5 }) do
				at(m, "PipeBracket", ctx.frame(s, along), 0, H - 1.8, -0.4, Vector3.new(0.2, 2.4, 0.8), Metal, DARK)
			end
			if rng:NextNumber() < 0.5 then
				-- Fire hose cabinet.
				local cf = ctx.frame(s, rng:NextNumber(-4, 4))
				at(m, "HoseCabinet", cf, 0, 3, -0.4, Vector3.new(2.2, 2.8, 0.8), Metal, Color3.fromRGB(190, 40, 34))
				label(m, cf * CFrame.new(0, 3.9, -0.82), Vector3.new(1.6, 0.5, 0.02), Enum.NormalId.Front, "消火栓", Color3.fromRGB(190, 40, 34), Color3.fromRGB(240, 236, 226))
			end
		end
	end
	for _, run in ipairs(ctx.runs("px")) do
		if rng:NextNumber() < 0.5 then
			local cf = ctx.frame("px", (run[1] + run[2]) / 2)
			cylinder(m, "Extinguisher", 1.8, 0.7, cf * CFrame.new(0, 1.3, -0.5) * UPRIGHT, Smooth, Color3.fromRGB(200, 40, 34))
		end
	end
end

function ROOM.collapsed(ctx)
	local m, rng = ctx.m, ctx.rng
	local cx, cz, y = ctx.cx, ctx.cz, ctx.y
	local sx, sz = ctx.hole[1], ctx.hole[2]
	local corner = Vector3.new(cx + sx * 5, y, cz + sz * 5)
	-- Rock bursting in through the corner of the ceiling (high up, so it
	-- never narrows the doorways).
	terrain:FillBall(ctx.L:PointToWorldSpace(Vector3.new(cx + sx * 8.5, y + 7, cz + sz * 8.5)), 5.5, Enum.Material.Rock)
	for _ = 1, 2 do
		part(m, "FallenCeilingPanel", Vector3.new(rng:NextNumber(4, 6), 0.5, rng:NextNumber(4, 6)), CFrame.new(corner + Vector3.new(rng:NextNumber(-2, 1) * sx, rng:NextNumber(1, 2.5), rng:NextNumber(-2, 1) * sz)) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 3), rng:NextNumber(0.3, 0.8)), Metal, jitter(DARK, rng, 0.1))
	end
	for _ = 1, rng:NextInteger(10, 18) do
		local s = Vector3.new(rng:NextNumber(0.6, 2.4), rng:NextNumber(0.4, 1.4), rng:NextNumber(0.6, 2.4))
		part(m, "Rubble", s, CFrame.new(corner.X + rng:NextNumber(-2.5, 2) * sx, y + s.Y * 0.4, corner.Z + rng:NextNumber(-2.5, 2) * sz) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Concrete, jitter(Color3.fromRGB(96, 94, 90), rng, 0.1))
	end
	-- Rebar and cables hanging from the hole's edge; a light torn loose.
	for _ = 1, 5 do
		local top = Vector3.new(cx + sx * rng:NextNumber(2.5, 7), y + H, cz + sz * rng:NextNumber(2.5, 3))
		rod(m, "Rebar", top, top + Vector3.new(rng:NextNumber(-1, 1), -rng:NextNumber(1, 3), rng:NextNumber(-1, 1)), 0.12, Enum.Material.CorrodedMetal, Color3.fromRGB(116, 76, 48))
	end
	for _ = 1, 3 do
		local top = Vector3.new(cx + sx * rng:NextNumber(2, 3), y + H, cz + sz * rng:NextNumber(2, 7))
		rod(m, "HangingCable", top, top + Vector3.new(rng:NextNumber(-1, 1), -rng:NextNumber(3, 8), rng:NextNumber(-1, 1)), 0.2, Smooth, BLACK)
	end
	local spark = part(m, "Spark", Vector3.new(0.2, 0.2, 0.2), Vector3.new(cx + sx * 2.5, y + H - 5, cz + sz * 3), Neon, Color3.fromRGB(255, 220, 140))
	spark.Shape = Enum.PartType.Ball
	spark.CanCollide = false
	local glow = Instance.new("PointLight")
	glow.Range = 6
	glow.Brightness = 1
	glow.Color = Color3.fromRGB(255, 210, 140)
	glow.Parent = spark
	spark:AddTag("FlickerLight")
end

local ROOM_WEIGHTS = { { "corridor", 3 }, { "storage", 3 }, { "office", 3 }, { "servers", 2.5 }, { "plant", 2 }, { "collapsed", 1.2 } }

local function pickRoom(rng)
	local total = 0
	for _, w in ipairs(ROOM_WEIGHTS) do
		total += w[2]
	end
	local r = rng:NextNumber() * total
	for _, w in ipairs(ROOM_WEIGHTS) do
		r -= w[2]
		if r <= 0 then
			return w[1]
		end
	end
	return "corridor"
end

-- ===== Layout =====

-- spec = {
--   L        the facility frame (for world bounds and terrain carving)
--   floorY   floor height, in the frame
--   x0, z0   the grid's corner (it runs +x in columns, -z in rows)
--   cols, rows
--   entranceCol  column of the top-row room the hall's door opens into
--   fireX    x of the fire corridor that runs from the exit to z = 0
--   exitMinZ exit rooms must be at least this far up (the fire corridor
--            has to stay inside the crag)
-- }
-- Returns the fire corridor's far end (in the frame), where the passage
-- to the courtyard door takes over.
function FacilityMaze.build(m, spec, rng)
	local L, y = spec.L, spec.floorY
	local function key(i, j)
		return i .. "," .. j
	end
	local function rect(i, j)
		local xa = spec.x0 + i * CELL
		local za = spec.z0 - (j + 1) * CELL
		return xa, xa + CELL, za, za + CELL
	end
	local function center(i, j)
		local xa, xb, za, zb = rect(i, j)
		return (xa + xb) / 2, (za + zb) / 2
	end

	-- Which rooms fit inside the crag.
	local valid = {}
	for i = 0, spec.cols - 1 do
		for j = 0, spec.rows - 1 do
			local xa, xb, za, zb = rect(i, j)
			local ok = true
			for _, c in ipairs({ { xa, za }, { xa, zb }, { xb, za }, { xb, zb } }) do
				local w = L:PointToWorldSpace(Vector3.new(c[1], y, c[2]))
				if w.X < WORLD.x0 or w.X > WORLD.x1 or w.Z < WORLD.z0 or w.Z > WORLD.z1 then
					ok = false
				end
			end
			if ok then
				valid[key(i, j)] = { i = i, j = j }
			end
		end
	end
	local entrance = valid[key(spec.entranceCol, 0)]
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	local function linkKey(a, b)
		return key(a.i, a.j) .. "|" .. key(b.i, b.j)
	end

	-- A maze (backtracker), then braided: most dead ends get knocked
	-- through to a neighbour, plus a few extra links, so nearly every room
	-- has another way out. Keep whichever of several attempts puts the exit
	-- furthest from the entrance.
	local best
	for _ = 1, 12 do
		local linked = {}
		local function link(a, b)
			linked[linkKey(a, b)] = true
			linked[linkKey(b, a)] = true
		end
		local visited = { [key(entrance.i, entrance.j)] = true }
		local stack = { entrance }
		while #stack > 0 do
			local cur = stack[#stack]
			local options = {}
			for _, d in ipairs(dirs) do
				local n = valid[key(cur.i + d[1], cur.j + d[2])]
				if n and not visited[key(n.i, n.j)] then
					table.insert(options, n)
				end
			end
			if #options == 0 then
				table.remove(stack)
			else
				local n = options[rng:NextInteger(1, #options)]
				visited[key(n.i, n.j)] = true
				link(cur, n)
				table.insert(stack, n)
			end
		end
		for _, c in pairs(valid) do
			local links, spare = 0, {}
			for _, d in ipairs(dirs) do
				local n = valid[key(c.i + d[1], c.j + d[2])]
				if n then
					if linked[linkKey(c, n)] then
						links += 1
					else
						table.insert(spare, n)
					end
				end
			end
			if links <= 1 and #spare > 0 and rng:NextNumber() < 0.85 then
				link(c, spare[rng:NextInteger(1, #spare)])
			elseif #spare > 0 and rng:NextNumber() < 0.12 then
				link(c, spare[rng:NextInteger(1, #spare)])
			end
		end
		-- Distances from the entrance, and the way back from each room.
		local dist, from = { [key(entrance.i, entrance.j)] = 0 }, {}
		local queue, head = { entrance }, 1
		while queue[head] do
			local cur = queue[head]
			head += 1
			for _, d in ipairs(dirs) do
				local n = valid[key(cur.i + d[1], cur.j + d[2])]
				if n and linked[linkKey(cur, n)] and not dist[key(n.i, n.j)] then
					dist[key(n.i, n.j)] = dist[key(cur.i, cur.j)] + 1
					from[key(n.i, n.j)] = cur
					table.insert(queue, n)
				end
			end
		end
		for j = 0, spec.rows - 1 do
			local c = valid[key(spec.cols - 1, j)]
			if c and c ~= entrance and select(2, center(c.i, c.j)) >= spec.exitMinZ and dist[key(c.i, c.j)] then
				local d = dist[key(c.i, c.j)]
				if not best or d > best.d then
					best = { d = d, exit = c, linked = linked, from = from }
				end
			end
		end
	end
	assert(best, "FacilityMaze: no exit room fits inside the crag")
	local linked, exitCell = best.linked, best.exit

	-- The route out, entrance first.
	local path = { exitCell }
	while best.from[key(path[1].i, path[1].j)] do
		table.insert(path, 1, best.from[key(path[1].i, path[1].j)])
	end

	-- ---- Every wall between rooms: solid, doorway, or knocked through ----
	-- "V"i,j is the wall at x = x0 + i*CELL between rooms (i-1, j) and
	-- (i, j); "H"i,j the wall at z = z0 - j*CELL between (i, j-1) and (i, j).
	local edgeState = {}
	local function decide(id, a, b, special)
		if not a and not b then
			return
		end
		if special then
			edgeState[id] = "door"
		elseif a and b and linked[linkKey(a, b)] then
			edgeState[id] = if rng:NextNumber() < 0.4 then "open" else "door"
		else
			edgeState[id] = "wall"
		end
	end
	for i = 0, spec.cols do
		for j = 0, spec.rows - 1 do
			local a, b = valid[key(i - 1, j)], valid[key(i, j)]
			decide("V" .. key(i, j), a, b, a == exitCell and not b)
		end
	end
	for j = 0, spec.rows do
		for i = 0, spec.cols - 1 do
			local a, b = valid[key(i, j - 1)], valid[key(i, j)]
			decide("H" .. key(i, j), a, b, b == entrance and j == 0)
		end
	end
	local function sidesOf(c)
		return {
			nx = edgeState["V" .. key(c.i, c.j)],
			px = edgeState["V" .. key(c.i + 1, c.j)],
			pz = edgeState["H" .. key(c.i, c.j)],
			nz = edgeState["H" .. key(c.i, c.j + 1)],
		}
	end

	-- ---- Terrain ----
	for _, c in pairs(valid) do
		local cx, cz = center(c.i, c.j)
		-- (Generous, so the part-cut voxels at the edges end up behind the
		-- walls rather than bulging into the rooms: the grid is at an angle
		-- to the terrain's.)
		terrain:FillBlock(L * CFrame.new(cx, y + H / 2 + 0.5, cz), Vector3.new(CELL + 5, H + 5, CELL + 5), AIR)
	end

	-- ---- Walls ----
	local function buildEdge(id, axis, fixed, a0, a1)
		local state = edgeState[id]
		if not state or state == "open" then
			return
		end
		local mid = (a0 + a1) / 2
		local openings = {}
		if state == "door" then
			table.insert(openings, { center = mid, width = DOOR_W, bottom = y, top = y + DOOR_H })
		end
		wall(m, axis, fixed, a0, a1, y, y + H, openings)
		if state == "door" then
			local function pos(along, yy, off)
				return if axis == "X" then Vector3.new(along, yy, fixed + off) else Vector3.new(fixed + off, yy, along)
			end
			local function size(along, h, t)
				return if axis == "X" then Vector3.new(along, h, t) else Vector3.new(t, h, along)
			end
			for _, s in ipairs({ -1, 1 }) do
				part(m, "DoorJamb", size(0.5, DOOR_H, 1.1), pos(mid + s * (DOOR_W / 2 + 0.1), y + DOOR_H / 2, 0), Metal, DARK)
			end
			part(m, "DoorHead", size(DOOR_W + 1, 0.5, 1.1), pos(mid, y + DOOR_H + 0.25, 0), Metal, DARK)
			if rng:NextNumber() < 0.35 then
				-- Sliding door jammed part open (still room to get past).
				part(m, "MazeDoor", size(3.4, DOOR_H - 0.2, 0.5), pos(mid - DOOR_W / 2 + 0.9, y + DOOR_H / 2, 0), Metal, jitter(Color3.fromRGB(120, 124, 120), rng, 0.06))
			end
		end
	end
	for i = 0, spec.cols do
		for j = 0, spec.rows - 1 do
			local _, _, za, zb = rect(0, j)
			buildEdge("V" .. key(i, j), "Z", spec.x0 + i * CELL, za, zb)
		end
	end
	for j = 0, spec.rows do
		for i = 0, spec.cols - 1 do
			local xa, xb = rect(i, 0)
			buildEdge("H" .. key(i, j), "X", spec.z0 - j * CELL, xa, xb)
		end
	end
	-- Pillars at the grid corners.
	for i = 0, spec.cols do
		for j = 0, spec.rows do
			local x, z = spec.x0 + i * CELL, spec.z0 - j * CELL
			if valid[key(i - 1, j - 1)] or valid[key(i, j - 1)] or valid[key(i - 1, j)] or valid[key(i, j)] then
				box(m, "MazePillar", x - 0.7, x + 0.7, y, y + H, z - 0.7, z + 0.7, Metal, DARK)
			end
		end
	end

	-- ---- Exit signs every two or three doorways along the route ----
	local countdown = rng:NextInteger(1, 2)
	for k = 1, #path - 1 do
		countdown -= 1
		if countdown <= 0 then
			countdown = rng:NextInteger(2, 3)
			local a, b = path[k], path[k + 1]
			local id, fixed, mid, sideSign
			if a.i ~= b.i then
				local i = math.max(a.i, b.i)
				local _, _, za, zb = rect(0, a.j)
				id, fixed, mid = "V" .. key(i, a.j), spec.x0 + i * CELL, (za + zb) / 2
				sideSign = if a.i < b.i then -1 else 1 -- the side you approach from
			else
				local j = math.max(a.j, b.j)
				local xa, xb = rect(a.i, 0)
				id, fixed, mid = "H" .. key(a.i, j), spec.z0 - j * CELL, (xa + xb) / 2
				sideSign = if a.j < b.j then 1 else -1
			end
			local vertical = id:sub(1, 1) == "V"
			local signY = if edgeState[id] == "door" then y + DOOR_H + 1.1 else y + H - 1.6
			local off = sideSign * 0.6
			local pos = if vertical then Vector3.new(fixed + off, signY, mid) else Vector3.new(mid, signY, fixed + off)
			local size = if vertical then Vector3.new(0.12, 1, 2.6) else Vector3.new(2.6, 1, 0.12)
			local face
			if vertical then
				face = if sideSign < 0 then Enum.NormalId.Left else Enum.NormalId.Right
			else
				face = if sideSign > 0 then Enum.NormalId.Back else Enum.NormalId.Front
			end
			exitSign(m, CFrame.new(pos), size, face)
			if edgeState[id] == "open" then
				rod(m, "SignHanger", pos + Vector3.new(0, 0.5, 0), pos + Vector3.new(0, H - (signY - y) - 0.5, 0), 0.08, Metal, DARK)
			end
		end
	end

	-- ---- Rooms: floor, ceiling, light, nameplate, contents ----
	for _, c in pairs(valid) do
		local xa, xb, za, zb = rect(c.i, c.j)
		local cx, cz = center(c.i, c.j)
		local sides = sidesOf(c)
		local kind = if c == entrance or c == exitCell then "corridor" else pickRoom(rng)
		box(m, "MazeFloor", xa, xb, y - 1, y, za, zb, if kind == "servers" then Concrete else Plate, if kind == "servers" then Color3.fromRGB(92, 92, 90) else STEEL)

		-- Collapsed rooms lose a corner of ceiling (towards a solid corner
		-- where possible).
		local hole
		if kind == "collapsed" then
			hole = { if sides.px ~= "open" then 1 else -1, if sides.pz ~= "open" then 1 else -1 }
			-- Ceiling in two pieces round a 6x6 hole in that corner.
			local hx0, hx1 = if hole[1] > 0 then xb - 6 else xa, if hole[1] > 0 then xb else xa + 6
			local hz0, hz1 = if hole[2] > 0 then zb - 6 else za, if hole[2] > 0 then zb else za + 6
			local restX0, restX1 = if hole[1] > 0 then xa else hx1, if hole[1] > 0 then hx0 else xb
			box(m, "MazeCeiling", restX0, restX1, y + H, y + H + 1, za, zb, Metal, DARK)
			box(m, "MazeCeiling", hx0, hx1, y + H, y + H + 1, if hole[2] > 0 then za else hz1, if hole[2] > 0 then hz0 else zb, Metal, DARK)
			ceilingLight(m, CFrame.new(cx - hole[1] * 3, y + H - 0.3, cz), rng, 0.4)
		else
			box(m, "MazeCeiling", xa, xb, y + H, y + H + 1, za, zb, Metal, DARK)
			ceilingLight(m, CFrame.new(cx, y + H - 0.3, cz), rng)
		end

		local function side(s)
			return sides[s]
		end
		local function frame(s, along)
			local pos, inward
			if s == "px" then
				pos, inward = Vector3.new(cx + INNER, y, cz + along), Vector3.new(-1, 0, 0)
			elseif s == "nx" then
				pos, inward = Vector3.new(cx - INNER, y, cz + along), Vector3.new(1, 0, 0)
			elseif s == "pz" then
				pos, inward = Vector3.new(cx + along, y, cz + INNER), Vector3.new(0, 0, -1)
			else
				pos, inward = Vector3.new(cx + along, y, cz - INNER), Vector3.new(0, 0, 1)
			end
			return CFrame.lookAt(pos, pos + inward)
		end
		local function runs(s)
			local st = sides[s]
			if st == "door" then
				return { { -SEG_END, -DOOR_CLEAR }, { DOOR_CLEAR, SEG_END } }
			elseif st == "wall" then
				return { { -SEG_END, SEG_END } }
			end
			return {}
		end
		ROOM[kind]({ m = m, rng = rng, cx = cx, cz = cz, y = y, L = L, side = side, frame = frame, runs = runs, hole = hole })

		-- A nameplate by the first doorway.
		for _, s in ipairs({ "px", "nx", "pz", "nz" }) do
			if sides[s] == "door" then
				label(m, frame(s, DOOR_W / 2 + 1.4) * CFrame.new(0, 6.4, -0.03), Vector3.new(1.8, 0.6, 0.04), Enum.NormalId.Front, ROOM_NAMES[kind], Color3.fromRGB(226, 224, 214), BLACK)
				break
			end
		end
	end

	-- Every way between rooms (collapsed rooms bring rock in) must stay open.
	for _, c in pairs(valid) do
		for _, d in ipairs({ { 1, 0 }, { 0, 1 } }) do
			local n = valid[key(c.i + d[1], c.j + d[2])]
			if n and linked[linkKey(c, n)] then
				local ax, az = center(c.i, c.j)
				local bx, bz = center(n.i, n.j)
				RouteCheck.add("maze doorway", { L:PointToWorldSpace(Vector3.new(ax, y, az)), L:PointToWorldSpace(Vector3.new(bx, y, bz)) }, 2.5, 7)
			end
		end
	end

	-- ---- The fire corridor: from the exit room to z = 0 ----
	local _, ez = center(exitCell.i, exitCell.j)
	local gx = spec.x0 + spec.cols * CELL -- the grid's +x edge
	local fx = spec.fireX
	local hw = CORRIDOR_W / 2
	local function corridorBox(xa, xb, za, zb)
		terrain:FillBlock(L * CFrame.new((xa + xb) / 2, y + H / 2 + 0.5, (za + zb) / 2), Vector3.new(xb - xa + 10, H + 5, zb - za + 10), AIR)
		box(m, "FireFloor", xa, xb, y - 1, y, za, zb, Plate, STEEL)
		box(m, "FireCeiling", xa, xb, y + H, y + H + 1, za, zb, Metal, DARK)
	end
	-- Leg 1: out of the grid along +x.
	corridorBox(gx, fx + hw, ez - hw, ez + hw)
	box(m, "FireWall", gx, fx + hw + 0.8, y, y + H, ez - hw - 0.8, ez - hw, Metal, WALL)
	box(m, "FireWall", gx, fx - hw, y, y + H, ez + hw, ez + hw + 0.8, Metal, WALL)
	-- Leg 2: along +z to the passage out, which leaves through a gap in
	-- the +x wall at the far end.
	local zEnd = 3
	corridorBox(fx - hw, fx + hw, ez + hw, zEnd)
	box(m, "FireWall", fx - hw - 0.8, fx - hw, y, y + H, ez + hw, zEnd + 0.8, Metal, WALL)
	box(m, "FireWall", fx + hw, fx + hw + 0.8, y, y + H, ez - hw - 0.8, zEnd - 10, Metal, WALL)
	box(m, "FireWall", fx - hw - 0.8, fx + hw + 0.8, y, y + H, zEnd, zEnd + 0.8, Metal, WALL)
	for z = ez + hw + 4, zEnd - 4, 12 do
		ceilingLight(m, CFrame.new(fx, y + H - 0.3, z), rng)
	end
	ceilingLight(m, CFrame.new((gx + fx) / 2, y + H - 0.3, ez) * CFrame.Angles(0, math.rad(90), 0), rng)
	exitSign(m, CFrame.new(fx, y + DOOR_H + 1, zEnd - 0.1), Vector3.new(2.6, 1, 0.12), Enum.NormalId.Front)
	-- A green running stripe along the floor to the door.
	box(m, "ExitStripe", gx, fx, y, y + 0.04, ez - 0.25, ez + 0.25, Neon, EXIT_GREEN).CanCollide = false
	box(m, "ExitStripe", fx - 0.25, fx + 0.25, y, y + 0.04, ez, zEnd - 5, Neon, EXIT_GREEN).CanCollide = false

	local ex, _ = center(exitCell.i, exitCell.j)
	RouteCheck.add("maze fire corridor", { L:PointToWorldSpace(Vector3.new(ex, y, ez)), L:PointToWorldSpace(Vector3.new(fx, y, ez)), L:PointToWorldSpace(Vector3.new(fx, y, zEnd - 5)), L:PointToWorldSpace(Vector3.new(fx + hw + 2, y, zEnd - 5)) }, 3, 9, true)
	return Vector3.new(fx + hw, y, zEnd - 5)
end

return FacilityMaze
