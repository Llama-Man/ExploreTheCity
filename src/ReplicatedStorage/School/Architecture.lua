-- Building shell pieces in the style of an old Japanese wooden schoolhouse:
-- individual floorboards, plaster walls with wood wainscoting, exposed
-- beams and posts, multi-pane sash windows, and sliding classroom doors.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)

local part, darken, jitter = BuildUtil.part, BuildUtil.darken, BuildUtil.jitter
local Wood, Metal = Enum.Material.Wood, Enum.Material.Metal

local H, T = Config.WALL_HEIGHT, Config.WALL_THICKNESS

-- Only used for panel-to-panel shade variation, which doesn't need to be
-- reproducible, so it's kept separate from the layout rng.
local shadeRng = Random.new()

local Architecture = {}

-- The structure of one floor of the stacked school, built at y = 0: a dark
-- subfloor that shows through the board seams (thick enough to meet the
-- ceiling of the floor below), a concrete band round the outside at
-- ceiling level marking each storey, a footing under the bottom floor and
-- a slate roof over the top one.
function Architecture.floorShell(parent, xStart, xEnd, zStart, zEnd, isBottom, isTop)
	local cx, cz = (xStart + xEnd) / 2, (zStart + zEnd) / 2
	local sx, sz = xEnd - xStart, zEnd - zStart
	part(parent, "Subfloor", Vector3.new(sx, 0.5, sz), Vector3.new(cx, -0.35, cz), Wood, Color3.fromRGB(42, 30, 20))

	local bandColor = Color3.fromRGB(128, 124, 116)
	local band0, band1 = H - 0.2, Config.FLOOR_SPACING + 0.1
	local bandY, bandH = (band0 + band1) / 2, band1 - band0
	part(parent, "StoreyBand", Vector3.new(sx + 0.8, bandH, 0.8), Vector3.new(cx, bandY, zStart), Enum.Material.Concrete, bandColor)
	part(parent, "StoreyBand", Vector3.new(sx + 0.8, bandH, 0.8), Vector3.new(cx, bandY, zEnd), Enum.Material.Concrete, bandColor)

	if isBottom then
		part(parent, "Foundation", Vector3.new(sx + 0.6, 4, sz + 0.6), Vector3.new(cx, -2.6, cz), Enum.Material.Concrete, Color3.fromRGB(140, 138, 130))
	end
	if isTop then
		part(parent, "Roof", Vector3.new(sx + 5, 0.7, sz + 5), Vector3.new(cx, H + 1.35, cz), Enum.Material.Slate, Color3.fromRGB(72, 74, 78))
	end
end

-- Boards run along X with staggered joints and slight per-board tone
-- variation; the thin gaps between them show the dark subfloor. A few
-- boards are missing depending on `missingChance`.
function Architecture.floorboards(parent, xStart, xEnd, zStart, zEnd, baseColor, rng, missingChance)
	local width = zEnd - zStart
	local count = math.max(1, math.floor(width / Config.BOARD_WIDTH + 0.5))
	local boardW = width / count
	for i = 1, count do
		local z = zStart + boardW * (i - 0.5)
		local x = xStart
		local segLen = rng:NextNumber(4, 18)
		while x < xEnd - 0.05 do
			local e = x + segLen
			if xEnd - e < 3 then
				e = xEnd
			end
			if rng:NextNumber() >= (missingChance or 0) then
				part(parent, "Floorboard", Vector3.new(e - x - 0.06, 0.4, boardW - 0.07), Vector3.new((x + e) / 2, -0.2, z), Wood, jitter(baseColor, rng, 0.07))
			end
			x = e
			segLen = rng:NextNumber(12, 24)
		end
	end
end

function Architecture.ceiling(parent, xStart, xEnd, zStart, zEnd, beamCount, beamColor)
	local cz = (zStart + zEnd) / 2
	part(parent, "Ceiling", Vector3.new(xEnd - xStart, 1, zEnd - zStart), Vector3.new((xStart + xEnd) / 2, H + 0.5, cz), Enum.Material.Plaster, Config.CEILING_COLOR)
	for i = 1, beamCount - 1 do
		local x = xStart + (xEnd - xStart) * i / beamCount
		part(parent, "CeilingBeam", Vector3.new(0.8, 0.7, zEnd - zStart), Vector3.new(x, H - 0.35, cz), Wood, beamColor)
	end
end

function Architecture.wall(parent, axis, fixed, spanStart, spanEnd, openings)
	BuildUtil.strip(parent, {
		name = "Wall",
		axis = axis,
		fixed = fixed,
		spanStart = spanStart,
		spanEnd = spanEnd,
		bottom = 0,
		top = H,
		thickness = T,
		openings = openings,
		material = Enum.Material.Plaster,
		color = Config.PLASTER_COLOR,
		rng = shadeRng,
		jitter = 0.07,
	})
end

local function coveredByOpening(openings, pos, margin, below)
	for _, o in ipairs(openings) do
		if o.bottom < below and math.abs(pos - o.center) < o.width / 2 + margin then
			return true
		end
	end
	return false
end

-- Dresses one face of a wall with a wood panel band, chair rail and
-- baseboard. `face` is that face's coordinate; `normal` (+1/-1) points away
-- from the wall into the space being dressed. `stileSpacing` adds vertical
-- panel dividers for a proper framed-panel look.
function Architecture.wainscot(parent, axis, face, normal, spanStart, spanEnd, openings, woodColor, stileSpacing)
	local trim = darken(woodColor, 0.72)
	local WH = Config.WAINSCOT_HEIGHT

	local function overlay(name, bottom, top, depth, color)
		BuildUtil.strip(parent, {
			name = name,
			axis = axis,
			fixed = face + normal * depth / 2,
			spanStart = spanStart,
			spanEnd = spanEnd,
			bottom = bottom,
			top = top,
			thickness = depth,
			openings = openings,
			material = Wood,
			color = color,
			rng = shadeRng,
			jitter = 0.08,
		})
	end

	overlay("Wainscot", 0, WH, 0.12, woodColor)
	overlay("ChairRail", WH - 0.1, WH + 0.2, 0.3, trim)
	overlay("Baseboard", 0, 0.7, 0.26, trim)

	if stileSpacing then
		local pos = spanStart + stileSpacing / 2
		while pos < spanEnd do
			if not coveredByOpening(openings, pos, 0.5, WH) then
				local size, p = BuildUtil.axisBox(axis, 0.3, WH - 0.8, 0.2, pos, 0.7 + (WH - 0.8) / 2, face + normal * 0.1)
				part(parent, "WainscotStile", size, p, Wood, trim)
			end
			pos += stileSpacing
		end
	end
end

-- Traditional wooden sash window: an outer frame, sash stiles every ~4.5
-- studs, and thin muntins splitting each sash into small panes. Each sash
-- has its own slightly different grimy glass; with `opts.broken` > 0 some
-- sashes have lost their glass entirely.
function Architecture.sashWindow(parent, axis, fixed, center, width, bottom, top, frameColor, rng, opts)
	opts = opts or {}
	local rows = opts.rows or 2
	local h = top - bottom
	local midY = (bottom + top) / 2
	local left = center - width / 2

	local function box(name, along, height, depth, alongPos, y, material, color)
		local size, pos = BuildUtil.axisBox(axis, along, height, depth, alongPos, y, fixed)
		return part(parent, name, size, pos, material, color)
	end

	local sashes = math.max(1, math.floor(width / 4.5 + 0.5))
	local sashW = width / sashes
	for i = 1, sashes do
		if rng:NextNumber() >= (opts.broken or 0) then
			local glass = box("WindowGlass", sashW, h, 0.1, left + sashW * (i - 0.5), midY, Enum.Material.Glass, jitter(Config.GLASS_COLOR, rng, 0.05))
			glass.Transparency = rng:NextNumber(0.3, 0.55)
		end
	end

	box("WindowFrame", width, 0.35, T * 0.7, center, bottom + 0.175, Wood, frameColor)
	box("WindowFrame", width, 0.35, T * 0.7, center, top - 0.175, Wood, frameColor)
	box("WindowFrame", 0.35, h, T * 0.7, left + 0.175, midY, Wood, frameColor)
	box("WindowFrame", 0.35, h, T * 0.7, left + width - 0.175, midY, Wood, frameColor)

	for i = 1, sashes do
		local sc = left + sashW * (i - 0.5)
		if i < sashes then
			box("SashStile", 0.3, h, 0.45, left + sashW * i, midY, Wood, frameColor)
		end
		box("Muntin", 0.12, h, 0.25, sc, midY, Wood, frameColor)
		for r = 1, rows do
			box("Muntin", sashW, 0.12, 0.25, sc, bottom + h * r / (rows + 1), Wood, frameColor)
		end
	end

	if opts.sill ~= false then
		box("WindowSill", width + 0.6, 0.25, T + 0.9, center, bottom - 0.125, Wood, frameColor)
	end
end

function Architecture.post(parent, axis, fixed, alongPos, color)
	local size, pos = BuildUtil.axisBox(axis, 1.2, H, T + 0.5, alongPos, H / 2, fixed)
	part(parent, "Post", size, pos, Wood, color)
end

function Architecture.doorCasing(parent, axis, fixed, center, width, height, color)
	local depth = T + 0.4
	for _, side in ipairs({ -1, 1 }) do
		local size, pos = BuildUtil.axisBox(axis, 0.45, height, depth, center + side * (width / 2 + 0.2), height / 2, fixed)
		part(parent, "DoorCasing", size, pos, Wood, color)
	end
	local size, pos = BuildUtil.axisBox(axis, width + 0.85, 0.45, depth, center, height + 0.225, fixed)
	part(parent, "DoorCasing", size, pos, Wood, color)
end

function Architecture.threshold(parent, axis, fixed, center, width, color)
	local size, pos = BuildUtil.axisBox(axis, width, 0.45, T + 0.4, center, -0.175, fixed)
	part(parent, "Threshold", size, pos, Wood, color)
end

-- Classroom sliding door: wood frame, frosted glass upper half, solid lower
-- panel, running on an overhead track. It slides `slideDir` to open.
-- `openFraction` is its starting position (0 closed, 1 open, between =
-- left ajar). Tagged "SlidingDoor" with a ProximityPrompt so
-- DoorController.server.lua can open/close it. The slide is stored as a
-- relative vector (not absolute positions) because whole floors are moved
-- into place after they're built.
function Architecture.slidingDoor(parent, axis, fixed, center, slideDir, openFraction, frameColor, panelColor)
	local W, Hd = Config.DOOR_WIDTH, Config.DOOR_HEIGHT - 0.1
	local along = center
	local door = BuildUtil.model(parent, "SlidingDoor")

	local function box(name, len, height, depth, alongPos, y, material, color)
		local size, pos = BuildUtil.axisBox(axis, len, height, depth, alongPos, y, fixed)
		return part(door, name, size, pos, material, color)
	end

	local midY = Hd * 0.45
	box("DoorStile", 0.4, Hd, 0.2, along - W / 2 + 0.2, Hd / 2, Wood, frameColor)
	box("DoorStile", 0.4, Hd, 0.2, along + W / 2 - 0.2, Hd / 2, Wood, frameColor)
	box("DoorRail", W - 0.8, 0.4, 0.2, along, Hd - 0.2, Wood, frameColor)
	box("DoorRail", W - 0.8, 0.7, 0.2, along, 0.35, Wood, frameColor)
	box("DoorRail", W - 0.8, 0.3, 0.2, along, midY, Wood, frameColor)
	box("DoorPanel", W - 0.8, midY - 0.85, 0.1, along, (0.7 + midY - 0.15) / 2, Wood, panelColor)

	local glassBottom, glassTop = midY + 0.15, Hd - 0.4
	local glass = box("DoorGlass", W - 0.8, glassTop - glassBottom, 0.06, along, (glassBottom + glassTop) / 2, Enum.Material.Glass, Color3.fromRGB(226, 232, 230))
	glass.Transparency = 0.35

	local handle = box("DoorHandle", 0.12, 0.7, 0.26, along - slideDir * (W / 2 - 0.55), Hd * 0.48, Metal, Color3.fromRGB(60, 60, 62))

	local slideLen = W - 0.5
	local slideVector = if axis == "X" then Vector3.new(slideDir * slideLen, 0, 0) else Vector3.new(0, 0, slideDir * slideLen)
	local _, pivotPos = BuildUtil.axisBox(axis, 0, 0, 0, center, 0, fixed)
	door.WorldPivot = CFrame.new(pivotPos)
	door:PivotTo(CFrame.new(pivotPos + slideVector * openFraction))
	door:SetAttribute("SlideVector", slideVector)
	door:SetAttribute("OpenFraction", openFraction)
	door:SetAttribute("IsOpen", openFraction >= 0.99)
	door:AddTag("SlidingDoor")

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Door"
	prompt.ActionText = if openFraction >= 0.99 then "Close" else "Open"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = handle

	local size, pos = BuildUtil.axisBox(axis, W * 2 - 0.5, 0.25, 0.5, center + slideDir * slideLen / 2, Config.DOOR_HEIGHT + 0.12, fixed)
	part(parent, "DoorTrack", size, pos, Wood, frameColor)
end

-- The plate that sticks out from the corridor wall above a classroom door,
-- readable from either direction down the hall. `tilt` (radians) leaves it
-- hanging crooked.
function Architecture.classSign(parent, alongX, faceZ, text, tilt)
	local y = Config.DOOR_HEIGHT + 1.6
	local z = faceZ + 1.9
	local crooked = CFrame.Angles(tilt or 0, 0, 0)
	part(parent, "ClassSignBracket", Vector3.new(0.15, 0.25, 0.4), Vector3.new(alongX, y + 0.5, faceZ + 0.2), Metal, Color3.fromRGB(50, 50, 52))
	part(parent, "ClassSignFrame", Vector3.new(0.14, 1.5, 3.4), CFrame.new(alongX, y, z) * crooked, Wood, Color3.fromRGB(70, 50, 35))
	local sign = part(parent, "ClassSign", Vector3.new(0.22, 1.25, 3.15), CFrame.new(alongX, y, z) * crooked, Enum.Material.SmoothPlastic, Color3.fromRGB(232, 228, 214))

	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(35, 35, 38)
		label.Text = text
		label.Parent = gui
		gui.Parent = sign
	end
end

-- Twin-tube fluorescent fixture. `state` is "on", "dead" (no light, grey
-- tubes) or "flicker" (tagged for LightFlicker.server.lua).
function Architecture.ceilingLight(parent, position, state)
	local fixture = BuildUtil.model(parent, "CeilingLight")
	local housing = part(fixture, "LightHousing", Vector3.new(5, 0.25, 1), position, Enum.Material.SmoothPlastic, Color3.fromRGB(222, 220, 212))
	housing.CanCollide = false

	local dead = state == "dead"
	for _, dz in ipairs({ -0.22, 0.22 }) do
		local tube = BuildUtil.cylinder(
			fixture,
			"LightTube",
			4.6,
			0.16,
			CFrame.new(position + Vector3.new(0, -0.2, dz)),
			if dead then Enum.Material.SmoothPlastic else Enum.Material.Neon,
			if dead then Color3.fromRGB(176, 174, 166) else Color3.fromRGB(255, 244, 224)
		)
		tube.CanCollide = false
		tube.CastShadow = false
	end

	if not dead then
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 160
		light.Range = 18
		light.Brightness = 0.85
		light.Color = Config.LIGHT_COLOR
		light.Parent = housing
	end
	if state == "flicker" then
		fixture:AddTag("FlickerLight")
	end
end

return Architecture
