-- Reusable furniture and fittings shared by the room styles. Unless noted,
-- pieces are built around a floor-level centre point facing +X (toward a
-- room's board wall) and rotated afterwards with BuildUtil.place.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)

local part, cylinder, model, place, placeTilted = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.place, BuildUtil.placeTilted
local darken, jitter, pick = BuildUtil.darken, BuildUtil.jitter, BuildUtil.pick

local Wood, Metal, Fabric, Smooth = Enum.Material.Wood, Enum.Material.Metal, Enum.Material.Fabric, Enum.Material.SmoothPlastic
local METAL = Config.METAL_COLOR

local Props = {}

Props.DESK_W, Props.DESK_D, Props.DESK_H = 4.2, 3.0, 3.3
Props.SEAT, Props.SEAT_H = 2.4, 2.0
Props.DESK_TOP_COLOR = Color3.fromRGB(190, 154, 108)
Props.CARDBOARD_COLOR = Color3.fromRGB(180, 144, 100)

Props.BOOK_COLORS = {
	Color3.fromRGB(122, 42, 40),
	Color3.fromRGB(40, 60, 100),
	Color3.fromRGB(58, 88, 60),
	Color3.fromRGB(150, 120, 62),
	Color3.fromRGB(84, 62, 50),
	Color3.fromRGB(205, 196, 176),
	Color3.fromRGB(52, 52, 58),
}
Props.FABRIC_COLORS = {
	Color3.fromRGB(128, 72, 58),
	Color3.fromRGB(78, 94, 74),
	Color3.fromRGB(70, 82, 110),
	Color3.fromRGB(150, 125, 80),
	Color3.fromRGB(96, 70, 90),
}
Props.PAPER_COLORS = {
	Color3.fromRGB(240, 238, 228),
	Color3.fromRGB(236, 230, 204),
	Color3.fromRGB(214, 226, 234),
	Color3.fromRGB(236, 218, 216),
}

local DESK_W, DESK_D, DESK_H = Props.DESK_W, Props.DESK_D, Props.DESK_H
local SEAT, SEAT_H = Props.SEAT, Props.SEAT_H
local CURTAIN_COLOR = Color3.fromRGB(218, 208, 182)
local STUDENT_NAMES = { "田中", "佐藤", "鈴木", "高橋", "渡辺", "伊藤", "山本", "中村" }
local LESSONS = { "数学　二次関数", "現代文　羅生門", "英語　Unit 5", "日本史　明治維新", "化学　モル計算", "物理　運動方程式" }

-- ===== Desks & chairs =====

-- Student desk: wood top with a dark edge band, steel tube legs and foot
-- rails, and the open book tray under the top.
function Props.studentDesk(parent, c, topColor, rng)
	local m = model(parent, "Desk")
	part(m, "DeskTop", Vector3.new(DESK_D, 0.25, DESK_W), c + Vector3.new(0, DESK_H - 0.125, 0), Wood, topColor)
	part(m, "DeskEdge", Vector3.new(DESK_D + 0.06, 0.1, DESK_W + 0.06), c + Vector3.new(0, DESK_H - 0.2, 0), Enum.Material.Plastic, darken(topColor, 0.55))

	local trayY = DESK_H - 0.8
	part(m, "BookTray", Vector3.new(DESK_D - 0.5, 0.08, DESK_W - 0.5), c + Vector3.new(0.15, trayY, 0), Metal, METAL)
	part(m, "BookTrayBack", Vector3.new(0.08, 0.55, DESK_W - 0.5), c + Vector3.new(DESK_D / 2 - 0.35, trayY + 0.28, 0), Metal, METAL)
	for _, s in ipairs({ -1, 1 }) do
		part(m, "BookTraySide", Vector3.new(DESK_D - 0.5, 0.55, 0.08), c + Vector3.new(0.15, trayY + 0.28, s * (DESK_W / 2 - 0.29)), Metal, METAL)
		part(m, "DeskRail", Vector3.new(DESK_D - 0.5, 0.15, 0.15), c + Vector3.new(0, 0.45, s * (DESK_W / 2 - 0.3)), Metal, METAL)
		for _, sx in ipairs({ -1, 1 }) do
			part(m, "DeskLeg", Vector3.new(0.2, DESK_H - 0.25, 0.2), c + Vector3.new(sx * (DESK_D / 2 - 0.3), (DESK_H - 0.25) / 2, s * (DESK_W / 2 - 0.3)), Metal, METAL)
		end
	end

	if rng:NextNumber() < 0.25 then
		local y = DESK_H
		for _ = 1, rng:NextInteger(1, 3) do
			local size = Vector3.new(rng:NextNumber(1.0, 1.4), rng:NextNumber(0.1, 0.22), rng:NextNumber(1.4, 1.9))
			local at = c + Vector3.new(rng:NextNumber(-0.4, 0.4), y + size.Y / 2, rng:NextNumber(-0.9, 0.9))
			part(m, "Book", size, CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), Smooth, pick(Props.BOOK_COLORS, rng))
			y += size.Y
		end
	end
	if rng:NextNumber() < 0.15 then
		local s = if rng:NextNumber() < 0.5 then -1 else 1
		part(m, "SchoolBag", Vector3.new(1.5, 1.2, 0.45), c + Vector3.new(-0.1, DESK_H - 1.0, s * (DESK_W / 2 + 0.3)), Enum.Material.Leather, Color3.fromRGB(30, 28, 32))
	end
	return m
end

-- Student chair: wood seat and backrest on a steel frame; backrest on -X.
function Props.studentChair(parent, c, woodColor)
	local m = model(parent, "Chair")
	part(m, "ChairSeat", Vector3.new(SEAT, 0.22, SEAT), c + Vector3.new(0, SEAT_H - 0.11, 0), Wood, woodColor)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "ChairLeg", Vector3.new(0.17, SEAT_H - 0.22, 0.17), c + Vector3.new(sx * (SEAT / 2 - 0.25), (SEAT_H - 0.22) / 2, sz * (SEAT / 2 - 0.25)), Metal, METAL)
		end
	end
	for _, sz in ipairs({ -1, 1 }) do
		part(m, "ChairBackPost", Vector3.new(0.17, 2.3, 0.17), c + Vector3.new(-(SEAT / 2 - 0.2), SEAT_H + 1.04, sz * (SEAT / 2 - 0.25)), Metal, METAL)
	end
	part(m, "ChairBack", Vector3.new(0.2, 1.1, SEAT - 0.1), c + Vector3.new(-(SEAT / 2 - 0.1), SEAT_H + 1.5, 0), Wood, woodColor)
	return m
end

-- Chair lying on its back, legs sticking out.
function Props.tipChair(chair, pivot, yaw)
	placeTilted(chair, pivot, SEAT / 2, yaw, CFrame.Angles(0, 0, math.rad(90)))
end

-- Desk knocked onto its side.
function Props.tipDesk(desk, pivot, yaw)
	placeTilted(desk, pivot, DESK_W / 2, yaw, CFrame.Angles(math.rad(90), 0, 0))
end

-- Upside down, resting at `restHeight` (e.g. a chair on a desk top).
function Props.flip(m, pivot, restHeight, yaw)
	placeTilted(m, pivot, restHeight, yaw or 0, CFrame.Angles(math.pi, 0, 0))
end

-- Desk with its chair behind it, both turned to `yaw` (0 = facing +X).
-- `mess` (0-1) scales how askew things are and the odds of a missing or
-- knocked-over chair.
function Props.placeStudent(parent, deskCenter, yaw, topColor, rng, mess)
	local desk = Props.studentDesk(parent, deskCenter, topColor, rng)
	local drift = 1 + mess * 2
	if rng:NextNumber() < mess * 0.04 then
		Props.tipDesk(desk, deskCenter, yaw + rng:NextNumber(-0.5, 0.5))
	else
		place(desk, deskCenter, Vector3.new(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.2, 0.2)) * drift, yaw + math.rad(rng:NextNumber(-3, 3) * drift))
	end

	if rng:NextNumber() < 0.05 + mess * 0.12 then
		return
	end
	local chairCenter = deskCenter + BuildUtil.rotate(Vector3.new(-(DESK_D / 2 + SEAT / 2 - 0.7), 0, 0), yaw)
	local chair = Props.studentChair(parent, chairCenter, topColor)
	local pullOut = BuildUtil.rotate(Vector3.new(-rng:NextNumber(0, 0.6 + mess), 0, rng:NextNumber(-0.3, 0.3)), yaw)
	local chairYaw = yaw + math.rad(rng:NextNumber(-12, 12) * drift)
	if rng:NextNumber() < mess * 0.22 then
		Props.tipChair(chair, chairCenter + pullOut * 2, chairYaw)
	else
		place(chair, chairCenter, pullOut, chairYaw)
	end
end

-- Generic four-legged table.
function Props.table(parent, c, size, topColor, legColor, topMaterial)
	local m = model(parent, "Table")
	part(m, "TableTop", Vector3.new(size.X, 0.3, size.Z), c + Vector3.new(0, size.Y - 0.15, 0), topMaterial or Wood, topColor)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "TableLeg", Vector3.new(0.4, size.Y - 0.3, 0.4), c + Vector3.new(sx * (size.X / 2 - 0.4), (size.Y - 0.3) / 2, sz * (size.Z / 2 - 0.4)), Wood, legColor)
		end
	end
	return m
end

function Props.stool(parent, c, color)
	local m = model(parent, "Stool")
	cylinder(m, "StoolSeat", 0.25, 1.8, CFrame.new(c + Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Wood, color)
	for _, o in ipairs({ Vector3.new(0.5, 0, 0.5), Vector3.new(-0.5, 0, 0.5), Vector3.new(0.5, 0, -0.5), Vector3.new(-0.5, 0, -0.5) }) do
		part(m, "StoolLeg", Vector3.new(0.16, 2.2, 0.16), c + o + Vector3.new(0, 1.1, 0), Metal, METAL)
	end
	return m
end

-- Sofa facing +X; `length` along Z (use ~3.2 for an armchair).
function Props.sofa(parent, c, fabric, woodColor, length)
	local m = model(parent, "Sofa")
	local L = length or 7
	part(m, "SofaBase", Vector3.new(3.0, 1.1, L), c + Vector3.new(0, 0.85, 0), Fabric, darken(fabric, 0.85))
	part(m, "SofaSeat", Vector3.new(2.4, 0.55, L - 1.2), c + Vector3.new(0.25, 1.65, 0), Fabric, fabric)
	part(m, "SofaBack", Vector3.new(0.8, 2.3, L), c + Vector3.new(-1.1, 2.3, 0), Fabric, fabric)
	for _, s in ipairs({ -1, 1 }) do
		part(m, "SofaArm", Vector3.new(3.0, 1.0, 0.6), c + Vector3.new(0, 1.9, s * (L / 2 - 0.3)), Fabric, darken(fabric, 0.92))
		for _, sx in ipairs({ -1, 1 }) do
			part(m, "SofaLeg", Vector3.new(0.3, 0.3, 0.3), c + Vector3.new(sx * 1.2, 0.15, s * (L / 2 - 0.4)), Wood, darken(woodColor, 0.6))
		end
	end
	return m
end

-- ===== Storage =====

function Props.bookRow(parent, base, length, maxHeight, rng, gapChance)
	local z = base.Z - length / 2
	local limit = base.Z + length / 2
	while true do
		local w = rng:NextNumber(0.28, 0.5)
		if z + w > limit then
			break
		end
		if rng:NextNumber() >= (gapChance or 0.08) then
			local h = rng:NextNumber(maxHeight * 0.6, maxHeight * 0.92)
			part(parent, "Book", Vector3.new(rng:NextNumber(1.0, 1.25), h, w - 0.02), Vector3.new(base.X, base.Y + h / 2, z + w / 2), Smooth, jitter(pick(Props.BOOK_COLORS, rng), rng, 0.08))
		end
		z += w
	end
end

-- Tall open bookcase (1.6 deep, 8 tall, 4.5 wide). `fill` 0-1 is how full
-- the shelves are.
function Props.bookcase(parent, c, yaw, woodColor, rng, fill)
	fill = fill or 0.6
	local m = model(parent, "Bookcase")
	local D, Hh, W = 1.6, 8, 4.5
	part(m, "BookcaseBack", Vector3.new(0.1, Hh, W), c + Vector3.new(-D / 2 + 0.05, Hh / 2, 0), Wood, darken(woodColor, 0.8))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "BookcaseSide", Vector3.new(D, Hh, 0.15), c + Vector3.new(0, Hh / 2, s * (W / 2 - 0.075)), Wood, woodColor)
	end
	part(m, "BookcaseTop", Vector3.new(D + 0.1, 0.15, W + 0.1), c + Vector3.new(0, Hh - 0.075, 0), Wood, woodColor)
	part(m, "BookcaseKick", Vector3.new(D, 0.35, W), c + Vector3.new(0, 0.175, 0), Wood, darken(woodColor, 0.75))

	for i, y in ipairs({ 0.35, 2.25, 4.15, 6.05 }) do
		if i > 1 then
			part(m, "BookcaseShelf", Vector3.new(D - 0.1, 0.12, W - 0.3), c + Vector3.new(0, y - 0.06, 0), Wood, woodColor)
		end
		local roll = rng:NextNumber()
		if roll < fill then
			Props.bookRow(m, c + Vector3.new(0.05, y, 0), W - 0.4, 1.75, rng, 0.08 + (1 - fill) * 0.3)
		elseif roll < fill + 0.2 then
			part(m, "StorageBox", Vector3.new(1.3, 1.1, 1.8), CFrame.new(c + Vector3.new(0, y + 0.55, rng:NextNumber(-1.1, 1.1))) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), Enum.Material.Cardboard, Props.CARDBOARD_COLOR)
		end
	end

	place(m, c, Vector3.zero, yaw)
	return m
end

-- Glass-fronted cabinet with bottles/jars on the shelves (lab, infirmary).
function Props.glassCabinet(parent, c, yaw, woodColor, rng)
	local m = model(parent, "GlassCabinet")
	local D, Hh, W = 1.6, 7, 4.5
	part(m, "CabinetBody", Vector3.new(0.1, Hh, W), c + Vector3.new(-D / 2 + 0.05, Hh / 2, 0), Wood, darken(woodColor, 0.8))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "CabinetSide", Vector3.new(D, Hh, 0.15), c + Vector3.new(0, Hh / 2, s * (W / 2 - 0.075)), Wood, woodColor)
	end
	part(m, "CabinetTop", Vector3.new(D + 0.1, 0.2, W + 0.1), c + Vector3.new(0, Hh - 0.1, 0), Wood, woodColor)
	part(m, "CabinetBase", Vector3.new(D, 1.6, W), c + Vector3.new(0, 0.8, 0), Wood, darken(woodColor, 0.9))
	local glassDoor = part(m, "CabinetGlass", Vector3.new(0.06, Hh - 1.8, W - 0.3), c + Vector3.new(D / 2 - 0.05, 1.6 + (Hh - 1.8) / 2, 0), Enum.Material.Glass, Config.GLASS_COLOR)
	glassDoor.Transparency = 0.55
	part(m, "CabinetMullion", Vector3.new(0.1, Hh - 1.8, 0.15), c + Vector3.new(D / 2 - 0.05, 1.6 + (Hh - 1.8) / 2, 0), Wood, woodColor)

	local bottleColors = { Color3.fromRGB(110, 70, 30), Color3.fromRGB(200, 214, 210), Color3.fromRGB(70, 110, 80), Color3.fromRGB(150, 150, 160) }
	for _, y in ipairs({ 1.6, 3.4, 5.2 }) do
		if y > 1.6 then
			local shelf = part(m, "CabinetShelf", Vector3.new(D - 0.2, 0.1, W - 0.3), c + Vector3.new(0, y - 0.05, 0), Enum.Material.Glass, Config.GLASS_COLOR)
			shelf.Transparency = 0.5
		end
		local z = -W / 2 + 0.5
		while z < W / 2 - 0.5 do
			if rng:NextNumber() < 0.7 then
				local h = rng:NextNumber(0.6, 1.3)
				local d = rng:NextNumber(0.35, 0.6)
				local bottle = cylinder(m, "Bottle", h, d, CFrame.new(c + Vector3.new(rng:NextNumber(-0.3, 0.3), y + h / 2, z)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Glass, pick(bottleColors, rng))
				bottle.Transparency = 0.3
			end
			z += rng:NextNumber(0.5, 0.8)
		end
	end

	place(m, c, Vector3.zero, yaw)
	return m
end

function Props.cardboardStack(parent, c, rng, maxBoxes)
	local y = 0
	for _ = 1, rng:NextInteger(1, maxBoxes or 3) do
		local s = Vector3.new(rng:NextNumber(1.8, 2.8), rng:NextNumber(1.3, 2.0), rng:NextNumber(1.8, 2.8))
		local offset = Vector3.new(rng:NextNumber(-0.3, 0.3), y + s.Y / 2, rng:NextNumber(-0.3, 0.3))
		part(parent, "CardboardBox", s, CFrame.new(c + offset) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), Enum.Material.Cardboard, jitter(Props.CARDBOARD_COLOR, rng, 0.06))
		y += s.Y
	end
end

-- ===== Walls & fittings =====

function Props.bulletinBoard(parent, axis, face, normal, center, length, bottom, height, rng, frameColor)
	local function box(name, len, h, depth, along, y, offset, material, color)
		local size, pos = BuildUtil.axisBox(axis, len, h, depth, along, y, face + normal * offset)
		return part(parent, name, size, pos, material, color)
	end

	box("NoticeFrame", length + 0.4, height + 0.4, 0.15, center, bottom + height / 2, 0.075, Wood, frameColor)
	box("Cork", length, height, 0.08, center, bottom + height / 2, 0.19, Fabric, Color3.fromRGB(168, 130, 90))

	for _ = 1, rng:NextInteger(2, 7) do
		local w, h = rng:NextNumber(0.9, 1.5), rng:NextNumber(1.1, 1.7)
		if w + 0.4 < length and h + 0.4 < height then
			local along = center + rng:NextNumber(-(length - w) / 2 + 0.2, (length - w) / 2 - 0.2)
			local y = bottom + rng:NextNumber(h / 2 + 0.2, height - h / 2 - 0.2)
			local paper = box("Notice", w, h, 0.03, along, y, 0.245, Smooth, pick(Props.PAPER_COLORS, rng))
			local tilt = math.rad(rng:NextNumber(-8, 8))
			paper.CFrame *= if axis == "X" then CFrame.Angles(0, 0, tilt) else CFrame.Angles(tilt, 0, 0)
			local pinSize, pinPos = BuildUtil.axisBox(axis, 0.15, 0.15, 0.1, along, y + h / 2 - 0.15, face + normal * 0.28)
			part(parent, "Pin", pinSize, pinPos, Smooth, Color3.fromRGB(180, 40, 40))
		end
	end
end

-- Wall clock facing -X on the wall at `x`, stopped at a random time.
function Props.wallClock(parent, x, y, z, rng)
	cylinder(parent, "ClockRim", 0.25, 1.9, CFrame.new(x - 0.125, y, z), Smooth, Color3.fromRGB(40, 40, 42))
	cylinder(parent, "ClockFace", 0.08, 1.6, CFrame.new(x - 0.27, y, z), Smooth, Color3.fromRGB(236, 234, 224))
	local function hand(name, len, width, angle)
		part(parent, name, Vector3.new(0.04, len, width), CFrame.new(x - 0.33, y, z) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, len / 2 - 0.05, 0), Smooth, Color3.fromRGB(25, 25, 25))
	end
	hand("HourHand", 0.45, 0.09, rng:NextNumber(0, math.pi * 2))
	hand("MinuteHand", 0.68, 0.06, rng:NextNumber(0, math.pi * 2))
end

-- Cream curtains gathered at both sides of each outer window, in pleats.
function Props.curtains(parent, room, rng)
	local z = room.bounds.z0 + 0.6
	local top, bottom = Config.WINDOW_TOP + 0.4, 1.0
	for _, w in ipairs(room.windows) do
		part(parent, "CurtainRail", Vector3.new(w.width + 1.6, 0.15, 0.15), Vector3.new(w.center, top + 0.1, z), Metal, Color3.fromRGB(190, 190, 184))
		for _, side in ipairs({ -1, 1 }) do
			-- Sometimes half-drawn across the window, sometimes bunched away.
			local drawn = if rng:NextNumber() < 0.3 then rng:NextNumber(4, w.width / 2) else rng:NextNumber(1.6, 3.4)
			local pleats = math.max(3, math.floor(drawn / 1.2))
			local pleatW = drawn / pleats
			local outer = w.center + side * (w.width / 2 + 0.8)
			local color = jitter(CURTAIN_COLOR, rng, 0.04)
			for p = 1, pleats do
				local along = outer - side * pleatW * (p - 0.5)
				part(parent, "Curtain", Vector3.new(pleatW + 0.05, top - bottom, 0.3), Vector3.new(along, (top + bottom) / 2, z + (p % 2 == 0 and 0.12 or 0)), Fabric, color)
			end
		end
	end
end

function Props.pottedPlant(parent, c, rng, withered)
	local m = model(parent, "PottedPlant")
	local upright = CFrame.Angles(0, 0, math.rad(90))
	cylinder(m, "Pot", 1.5, 1.4, CFrame.new(c + Vector3.new(0, 0.75, 0)) * upright, Enum.Material.Concrete, Color3.fromRGB(150, 92, 64))
	cylinder(m, "Soil", 0.1, 1.2, CFrame.new(c + Vector3.new(0, 1.5, 0)) * upright, Enum.Material.Ground, Color3.fromRGB(60, 44, 32))
	local leafColor = if withered then Color3.fromRGB(120, 96, 56) else Color3.fromRGB(72, 104, 54)
	for _ = 1, rng:NextInteger(withered and 1 or 3, withered and 3 or 5) do
		local s = rng:NextNumber(1.3, 2.2) * (if withered then 0.7 else 1)
		local leaf = part(m, "Foliage", Vector3.new(s, s, s), c + Vector3.new(rng:NextNumber(-0.5, 0.5), 2.2 + rng:NextNumber(0, 1.5), rng:NextNumber(-0.5, 0.5)), Enum.Material.LeafyGrass, jitter(leafColor, rng, 0.12))
		leaf.Shape = Enum.PartType.Ball
		leaf.CanCollide = false
	end
end

-- ===== Classroom fixtures =====

local function boardWriting(board, rng, style)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40

	local function line(text, x, y, w, h, color)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(x, y)
		label.Size = UDim2.fromScale(w, h)
		label.Font = Enum.Font.PatrickHand
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = color or Color3.fromRGB(40, 40, 52)
		label.TextTransparency = 0.15
		label.Text = text
		label.Parent = gui
	end

	if style == "music" then
		-- Five-line staves across the board.
		for staff = 0, 2 do
			for l = 0, 4 do
				local f = Instance.new("Frame")
				f.BorderSizePixel = 0
				f.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
				f.BackgroundTransparency = 0.3
				f.Position = UDim2.fromScale(0.04, 0.12 + staff * 0.3 + l * 0.035)
				f.Size = UDim2.new(0.92, 0, 0, 2)
				f.Parent = gui
			end
		end
	elseif style ~= "blank" then
		line("5月14日（月）", 0.74, 0.05, 0.22, 0.1)
		line("日直　" .. pick(STUDENT_NAMES, rng), 0.78, 0.82, 0.18, 0.1)
		if rng:NextNumber() < 0.7 then
			line(pick(LESSONS, rng), 0.05, 0.08, 0.4, 0.12, Color3.fromRGB(30, 60, 140))
		end
	end

	-- Grey smears where it was half wiped.
	for _ = 1, rng:NextInteger(0, 4) do
		local smear = Instance.new("Frame")
		smear.BorderSizePixel = 0
		smear.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
		smear.BackgroundTransparency = rng:NextNumber(0.82, 0.92)
		smear.Position = UDim2.fromScale(rng:NextNumber(0, 0.7), rng:NextNumber(0, 0.7))
		smear.Size = UDim2.fromScale(rng:NextNumber(0.15, 0.35), rng:NextNumber(0.1, 0.3))
		smear.Rotation = rng:NextNumber(-20, 20)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = smear
		smear.Parent = gui
	end
	gui.Parent = board
end

-- Board on the room's front (x1) wall. `style`: "writing", "blank", "music".
function Props.whiteboard(parent, room, rng, style)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2
	local w = (b.z1 - b.z0) * 0.55
	local bottom, height = 3.9, 5
	local x = b.x1
	local aluminium = Color3.fromRGB(176, 178, 180)

	part(parent, "BoardFrame", Vector3.new(0.2, height + 0.5, w + 0.5), Vector3.new(x - 0.1, bottom + height / 2, zMid), Metal, aluminium)
	local board = part(parent, "Whiteboard", Vector3.new(0.1, height, w), Vector3.new(x - 0.22, bottom + height / 2, zMid), Smooth, Color3.fromRGB(236, 236, 230))
	part(parent, "MarkerTray", Vector3.new(0.6, 0.15, w * 0.8), Vector3.new(x - 0.45, bottom - 0.1, zMid), Metal, aluminium)

	for _, color in ipairs({ Color3.fromRGB(20, 20, 20), Color3.fromRGB(180, 30, 30), Color3.fromRGB(30, 60, 150) }) do
		if rng:NextNumber() < 0.7 then
			part(parent, "Marker", Vector3.new(0.18, 0.18, 0.7), Vector3.new(x - 0.45, bottom + 0.06, zMid + rng:NextNumber(-w * 0.35, w * 0.35)), Smooth, color)
		end
	end
	part(parent, "Eraser", Vector3.new(0.35, 0.25, 1.0), Vector3.new(x - 0.45, bottom + 0.1, zMid + rng:NextNumber(-w * 0.35, w * 0.35)), Fabric, Color3.fromRGB(60, 60, 64))

	boardWriting(board, rng, style)
end

-- Raised platform across the front, optionally a lectern and the
-- teacher's steel desk + chair in the front corner by the windows.
function Props.teacherArea(parent, room, rng, opts)
	opts = opts or {}
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2
	local width = (b.z1 - b.z0) * 0.6

	part(parent, "Platform", Vector3.new(4.5, 0.6, width), Vector3.new(b.x1 - 2.25, 0.3, zMid), Wood, darken(room.wood, 0.85))
	part(parent, "PlatformEdge", Vector3.new(0.3, 0.62, width + 0.02), Vector3.new(b.x1 - 4.35, 0.31, zMid), Wood, room.trim)

	if opts.lectern ~= false then
		local lx = b.x1 - 3.6
		local lz = zMid + rng:NextNumber(-1, 1)
		part(parent, "Lectern", Vector3.new(1.8, 3.3, 3.0), Vector3.new(lx, 0.6 + 1.65, lz), Wood, room.trim)
		part(parent, "LecternTop", Vector3.new(2.3, 0.2, 3.5), CFrame.new(lx, 0.6 + 3.35, lz) * CFrame.Angles(0, 0, math.rad(-8)), Wood, darken(room.trim, 0.9))
	end

	if opts.teacherDesk == false then
		return
	end
	local tz = b.z0 + 3.6
	local c = Vector3.new(b.x1 - 3.5, 0, tz)
	local steel = Color3.fromRGB(150, 152, 148)
	local desk = model(parent, "TeacherDesk")
	part(desk, "TeacherDeskTop", Vector3.new(3.2, 0.2, 5.6), c + Vector3.new(0, 3.3, 0), Metal, Color3.fromRGB(164, 166, 160))
	part(desk, "DeskMat", Vector3.new(2.4, 0.04, 3.6), c + Vector3.new(0.2, 3.42, 0), Enum.Material.Rubber, Color3.fromRGB(62, 88, 72))
	part(desk, "DrawerPedestal", Vector3.new(3.0, 3.2, 1.8), c + Vector3.new(0, 1.6, 1.8), Metal, steel)
	for i = 1, 3 do
		part(desk, "DrawerFront", Vector3.new(0.06, 0.85, 1.6), c + Vector3.new(1.53, 0.55 + (i - 1) * 1.0, 1.8), Metal, Color3.fromRGB(164, 166, 162))
		part(desk, "DrawerHandle", Vector3.new(0.08, 0.12, 0.6), c + Vector3.new(1.58, 0.75 + (i - 1) * 1.0, 1.8), Metal, Color3.fromRGB(60, 60, 62))
	end
	part(desk, "ModestyPanel", Vector3.new(0.1, 2.9, 5.4), c + Vector3.new(-1.5, 1.75, 0), Metal, steel)
	part(desk, "DeskEndPanel", Vector3.new(2.9, 3.2, 0.15), c + Vector3.new(0, 1.6, -2.65), Metal, steel)
	part(desk, "PaperStack", Vector3.new(0.9, 0.25, 1.2), c + Vector3.new(0.3, 3.53, -1.6), Smooth, Props.PAPER_COLORS[2])
	cylinder(desk, "Mug", 0.45, 0.35, CFrame.new(c + Vector3.new(0.4, 3.63, 1.9)) * CFrame.Angles(0, 0, math.rad(90)), Smooth, pick(Props.FABRIC_COLORS, rng))
	place(desk, c, Vector3.zero, math.rad(rng:NextNumber(-2, 2)))

	local chairCenter = Vector3.new(b.x1 - 1.4, 0, tz - 0.6)
	local chair = Props.studentChair(parent, chairCenter, darken(room.wood, 0.8))
	place(chair, chairCenter, Vector3.zero, math.pi + math.rad(rng:NextNumber(-15, 15)))
end

-- Open cubby lockers along the back (x0) wall.
function Props.cubbyLockers(parent, room, rng)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2
	local length = (b.z1 - b.z0) * 0.62
	local depth, height, rows = 1.8, 4.6, 3
	local cols = math.max(1, math.floor(length / 2.2))
	local cellW = length / cols
	local cx = b.x0 + 0.3 + depth / 2
	local m = model(parent, "CubbyLockers")

	part(m, "LockerBack", Vector3.new(0.1, height, length), Vector3.new(b.x0 + 0.35, height / 2, zMid), Wood, darken(room.wood, 0.8))
	part(m, "LockerBase", Vector3.new(depth, 0.3, length), Vector3.new(cx, 0.15, zMid), Wood, room.trim)

	local rowH = (height - 0.3) / rows
	for k = 1, rows do
		part(m, "LockerShelf", Vector3.new(depth, 0.12, length), Vector3.new(cx, 0.3 + k * rowH - 0.06, zMid), Wood, room.wood)
	end
	for j = 0, cols do
		part(m, "LockerDivider", Vector3.new(depth, height, 0.12), Vector3.new(cx, height / 2, zMid - length / 2 + j * cellW), Wood, room.wood)
	end

	for k = 1, rows do
		for j = 1, cols do
			if rng:NextNumber() < 0.3 then
				local size = Vector3.new(1.2, rowH * rng:NextNumber(0.45, 0.7), cellW * rng:NextNumber(0.5, 0.75))
				local y = 0.3 + (k - 1) * rowH + size.Y / 2
				local z = zMid - length / 2 + (j - 0.5) * cellW
				part(m, "CubbyItem", size, Vector3.new(cx + 0.1, y, z), Fabric, pick(Props.FABRIC_COLORS, rng))
			end
		end
	end
end

-- Grey steel cleaning-supplies locker in the back corner by the door.
function Props.cleaningLocker(parent, room)
	local b = room.bounds
	local c = Vector3.new(b.x0 + 1.3, 0, b.z1 - 1.8)
	local seam = Color3.fromRGB(80, 84, 88)
	part(parent, "CleaningLocker", Vector3.new(2.0, 6.4, 2.4), c + Vector3.new(0, 3.2, 0), Metal, Color3.fromRGB(140, 146, 150))
	part(parent, "LockerDoorSeam", Vector3.new(0.04, 6.0, 0.05), c + Vector3.new(1.01, 3.2, 0), Metal, seam)
	for i = 1, 3 do
		part(parent, "LockerVent", Vector3.new(0.04, 0.08, 1.2), c + Vector3.new(1.01, 5.4 + i * 0.22, 0), Metal, seam)
	end
end

-- Picture frames in a row along a wall (composer portraits, notices...).
function Props.frames(parent, axis, face, normal, center, spacing, count, y, size, rng)
	for i = 1, count do
		local along = center + (i - (count + 1) / 2) * spacing
		local fs, fp = BuildUtil.axisBox(axis, size.X + 0.3, size.Y + 0.3, 0.15, along, y, face + normal * 0.08)
		part(parent, "PictureFrame", fs, fp, Wood, Color3.fromRGB(60, 44, 30))
		local ps, pp = BuildUtil.axisBox(axis, size.X, size.Y, 0.05, along, y, face + normal * 0.18)
		part(parent, "Picture", ps, pp, Smooth, jitter(Color3.fromRGB(70, 60, 50), rng, 0.25))
	end
end

return Props
