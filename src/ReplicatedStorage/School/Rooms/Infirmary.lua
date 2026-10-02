-- Infirmary: metal-framed beds against the window wall with privacy
-- curtains between them, a folding screen, medicine cabinets, the nurse's
-- desk, a sink with a mirror and a height measure.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)

local part, cylinder, model, place, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.place, BuildUtil.pick
local Wood, Metal, Fabric, Smooth = Enum.Material.Wood, Enum.Material.Metal, Enum.Material.Fabric, Enum.Material.SmoothPlastic

local FRAME = Color3.fromRGB(205, 208, 206)
local BLANKETS = { Color3.fromRGB(170, 196, 190), Color3.fromRGB(196, 206, 220), Color3.fromRGB(214, 210, 196) }
local SCREEN_CURTAIN = Color3.fromRGB(190, 210, 196)

-- Bed with its head at the -Z end.
local function bed(parent, c, rng)
	local m = model(parent, "InfirmaryBed")
	local L, W, top = 7, 3.6, 2.2
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, "BedLeg", Vector3.new(0.2, top - 0.3, 0.2), c + Vector3.new(sx * (W / 2 - 0.2), (top - 0.3) / 2, sz * (L / 2 - 0.2)), Metal, FRAME)
		end
		part(m, "BedRail", Vector3.new(0.15, 0.3, L), c + Vector3.new(sx * (W / 2 - 0.1), top - 0.4, 0), Metal, FRAME)
	end
	part(m, "HeadBoard", Vector3.new(W, 2.6, 0.15), c + Vector3.new(0, top + 0.6, -L / 2 + 0.1), Metal, FRAME)
	part(m, "FootBoard", Vector3.new(W, 1.6, 0.15), c + Vector3.new(0, top + 0.1, L / 2 - 0.1), Metal, FRAME)
	part(m, "Mattress", Vector3.new(W - 0.3, 0.6, L - 0.4), c + Vector3.new(0, top, 0), Fabric, Color3.fromRGB(222, 220, 210))
	part(m, "Pillow", Vector3.new(2.2, 0.45, 1.2), CFrame.new(c + Vector3.new(rng:NextNumber(-0.2, 0.2), top + 0.5, -L / 2 + 1.1)) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), Fabric, Color3.fromRGB(232, 232, 228))

	local blanket = pick(BLANKETS, rng)
	if rng:NextNumber() < 0.5 then
		part(m, "Blanket", Vector3.new(W - 0.1, 0.12, L * 0.55), CFrame.new(c + Vector3.new(0, top + 0.36, L * 0.2)) * CFrame.Angles(0, rng:NextNumber(-0.06, 0.06), 0), Fabric, blanket)
	else
		part(m, "FoldedBlanket", Vector3.new(W - 0.6, 0.5, 1.4), c + Vector3.new(0, top + 0.55, L / 2 - 1.2), Fabric, blanket)
	end
	return m
end

-- Ceiling-hung privacy curtain running along Z at `x`.
local function privacyCurtain(parent, x, zStart, zEnd, rng)
	part(parent, "CurtainRail", Vector3.new(0.15, 0.15, zEnd - zStart), Vector3.new(x, 10.1, (zStart + zEnd) / 2), Metal, Color3.fromRGB(190, 190, 184))
	local drawn = rng:NextNumber(2, zEnd - zStart)
	local pleats = math.max(2, math.floor(drawn / 1.2))
	local pleatW = drawn / pleats
	for p = 1, pleats do
		part(parent, "PrivacyCurtain", Vector3.new(0.2, 9, pleatW + 0.05), Vector3.new(x + (p % 2 == 0 and 0.12 or 0), 5.5, zStart + pleatW * (p - 0.5)), Fabric, SCREEN_CURTAIN)
	end
end

return function(parent, room, rng)
	local b = room.bounds
	local bedCount = rng:NextInteger(2, 3)
	for i = 1, bedCount do
		local x = b.x0 + 7 + (i - 1) * 8
		local c = Vector3.new(x, 0, b.z0 + 0.8 + 3.5)
		place(bed(parent, c, rng), c, Vector3.new(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(0, 0.3)), math.rad(rng:NextNumber(-2, 2)))
		privacyCurtain(parent, x + 4, b.z0 + 1, b.z0 + 9, rng)
	end

	-- Folding screen: three panels in a zigzag.
	local screenBase = Vector3.new(b.x0 + 7 + bedCount * 8, 0, b.z0 + 12)
	for i = 1, 3 do
		local yaw = math.rad(if i % 2 == 0 then 25 else -25)
		part(parent, "ScreenPanel", Vector3.new(0.15, 5.5, 2.2), CFrame.new(screenBase + Vector3.new(0, 2.95, (i - 2) * 2.0)) * CFrame.Angles(0, yaw, 0), Fabric, Color3.fromRGB(232, 232, 226))
	end

	for _, z in ipairs({ b.z0 + 5, b.z0 + 10 }) do
		Props.glassCabinet(parent, Vector3.new(b.x1 - 1.1, 0, z), math.pi, room.wood, rng)
	end

	local desk = Vector3.new(b.x1 - 8, 0, b.z1 - 7)
	local deskModel = Props.table(parent, desk, Vector3.new(3, 3.3, 5), room.trim, room.trim)
	part(deskModel, "PaperStack", Vector3.new(0.9, 0.3, 1.2), desk + Vector3.new(0, 3.45, rng:NextNumber(-1.5, 1.5)), Smooth, Props.PAPER_COLORS[1])
	place(deskModel, desk, Vector3.zero, math.rad(rng:NextNumber(-3, 3)))
	local chairPos = desk + Vector3.new(2.2, 0, 0)
	place(Props.studentChair(parent, chairPos, room.wood), chairPos, Vector3.zero, math.pi + math.rad(rng:NextNumber(-20, 20)))

	-- Sink with a mirror above it on the back wall.
	local sink = Vector3.new(b.x0 + 1.2, 0, (b.z0 + b.z1) / 2 + 4)
	part(parent, "SinkCabinet", Vector3.new(1.8, 3.2, 3), sink + Vector3.new(0, 1.6, 0), Enum.Material.Wood, room.trim)
	part(parent, "SinkBasin", Vector3.new(1.4, 0.06, 2.2), sink + Vector3.new(0.1, 3.21, 0), Metal, Color3.fromRGB(210, 212, 210))
	cylinder(parent, "Faucet", 0.8, 0.14, CFrame.new(sink + Vector3.new(-0.6, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Metal, Color3.fromRGB(170, 170, 172))
	local mirror = part(parent, "Mirror", Vector3.new(0.05, 2.4, 2), Vector3.new(b.x0 + 0.33, 5.6, sink.Z), Smooth, Color3.fromRGB(200, 204, 206))
	mirror.Reflectance = 0.5

	-- Height measure.
	local measure = Vector3.new(b.x0 + 2, 0, b.z1 - 6)
	part(parent, "MeasureBase", Vector3.new(1.6, 0.2, 1.6), measure + Vector3.new(0, 0.1, 0), Wood, room.trim)
	part(parent, "MeasurePole", Vector3.new(0.25, 7.5, 0.25), measure + Vector3.new(-0.6, 3.85, 0), Wood, Color3.fromRGB(220, 214, 196))
	part(parent, "MeasureSlider", Vector3.new(1.2, 0.1, 0.3), measure + Vector3.new(0, rng:NextNumber(5, 6.5), 0), Wood, room.trim)
end
