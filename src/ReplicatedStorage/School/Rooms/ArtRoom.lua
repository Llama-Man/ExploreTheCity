-- Art room: easels in an arc around a plaster bust on a plinth, big
-- paint-splattered worktables at the back, a sink counter and shelves of
-- clay pots.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)

local part, cylinder, disc, model, place, darken, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.disc, BuildUtil.model, BuildUtil.place, BuildUtil.darken, BuildUtil.pick
local Wood, Smooth, Plaster = Enum.Material.Wood, Enum.Material.SmoothPlastic, Enum.Material.Plaster

local PAINT_COLORS = {
	Color3.fromRGB(190, 60, 50),
	Color3.fromRGB(60, 106, 180),
	Color3.fromRGB(220, 180, 60),
	Color3.fromRGB(70, 140, 86),
	Color3.fromRGB(140, 80, 150),
	Color3.fromRGB(220, 124, 60),
}
local EASEL_WOOD = Color3.fromRGB(150, 118, 80)
local PLASTER_WHITE = Color3.fromRGB(222, 218, 208)

local function splatters(parent, center, spread, y, count, rng)
	for _ = 1, count do
		local p = disc(parent, "PaintSplatter", rng:NextNumber(0.3, 0.9), 0.02, center + Vector3.new(rng:NextNumber(-spread.X, spread.X), y, rng:NextNumber(-spread.Z, spread.Z)), Smooth, pick(PAINT_COLORS, rng))
		p.Transparency = rng:NextNumber(0.1, 0.35)
		p.CanCollide = false
	end
end

local function paintCanvas(canvas, rng)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	for _ = 1, rng:NextInteger(3, 9) do
		local blob = Instance.new("Frame")
		blob.BorderSizePixel = 0
		blob.BackgroundColor3 = pick(PAINT_COLORS, rng)
		blob.BackgroundTransparency = rng:NextNumber(0.1, 0.45)
		blob.Size = UDim2.fromScale(rng:NextNumber(0.15, 0.6), rng:NextNumber(0.1, 0.5))
		blob.Position = UDim2.fromScale(rng:NextNumber(0, 0.6), rng:NextNumber(0, 0.6))
		blob.Rotation = rng:NextNumber(-30, 30)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(rng:NextNumber(0.1, 0.5), 0)
		corner.Parent = blob
		blob.Parent = gui
	end
	gui.Parent = canvas
end

-- Easel whose canvas faces -X (the painter's side); +X is toward the subject.
local function easel(parent, c, rng)
	local m = model(parent, "Easel")
	for _, s in ipairs({ -1, 1 }) do
		part(m, "EaselLeg", Vector3.new(0.15, 6.2, 0.15), CFrame.new(c + Vector3.new(0, 3.05, s * 0.9)) * CFrame.Angles(0, 0, math.rad(-6)), Wood, EASEL_WOOD)
	end
	part(m, "EaselBackLeg", Vector3.new(0.15, 6.4, 0.15), CFrame.new(c + Vector3.new(1.3, 3.0, 0)) * CFrame.Angles(0, 0, math.rad(18)), Wood, EASEL_WOOD)
	part(m, "EaselLedge", Vector3.new(0.5, 0.15, 2.4), c + Vector3.new(-0.2, 2.9, 0), Wood, EASEL_WOOD)
	local canvas = part(m, "Canvas", Vector3.new(0.08, 3.2, 2.6), CFrame.new(c + Vector3.new(-0.05, 4.6, 0)) * CFrame.Angles(0, 0, math.rad(-6)), Enum.Material.Fabric, Color3.fromRGB(232, 226, 210))
	if rng:NextNumber() < 0.7 then
		paintCanvas(canvas, rng)
	end
	return m
end

-- Plaster bust on a plinth, facing -X.
local function plasterBust(parent, c, rng)
	part(parent, "Plinth", Vector3.new(2.2, 3.4, 2.2), c + Vector3.new(0, 1.7, 0), Wood, Color3.fromRGB(120, 92, 64))
	local m = model(parent, "PlasterBust")
	part(m, "BustChest", Vector3.new(1.3, 1.3, 2.2), c + Vector3.new(0, 4.05, 0), Plaster, PLASTER_WHITE)
	cylinder(m, "BustNeck", 0.8, 0.7, CFrame.new(c + Vector3.new(0, 4.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Plaster, PLASTER_WHITE)
	local head = part(m, "BustHead", Vector3.new(1.4, 1.4, 1.4), c + Vector3.new(0, 5.8, 0), Plaster, PLASTER_WHITE)
	head.Shape = Enum.PartType.Ball
	part(m, "BustNose", Vector3.new(0.3, 0.35, 0.2), c + Vector3.new(-0.7, 5.8, 0), Plaster, PLASTER_WHITE)
	place(m, c, Vector3.zero, math.rad(rng:NextNumber(-25, 25)))
end

return function(parent, room, rng)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2

	Props.whiteboard(parent, room, rng, if rng:NextNumber() < 0.3 then "writing" else "blank")

	local subject = Vector3.new(b.x1 - 9, 0, zMid)
	plasterBust(parent, subject, rng)

	local count = rng:NextInteger(4, 7)
	for i = 1, count do
		local a = math.rad(-70) + (i - 0.5) / count * math.rad(140) + math.rad(rng:NextNumber(-6, 6))
		local radius = rng:NextNumber(6, 8)
		local pos = subject + Vector3.new(-math.cos(a) * radius, 0, math.sin(a) * radius)
		local dir = subject - pos
		local yaw = math.atan2(-dir.Z, dir.X)
		place(easel(parent, pos, rng), pos, Vector3.zero, yaw)
		if rng:NextNumber() < 0.8 then
			local stoolPos = pos - dir.Unit * 2
			place(Props.stool(parent, stoolPos, darken(room.wood, 0.8)), stoolPos, Vector3.zero, 0)
		end
		splatters(parent, pos, Vector3.new(2, 0, 2), 0.012, rng:NextInteger(0, 3), rng)
	end

	local tableColor = darken(room.wood, 0.85)
	for _, tx in ipairs({ b.x0 + 8, b.x0 + 18 }) do
		for _, side in ipairs({ -1, 1 }) do
			local c = Vector3.new(tx, 0, zMid + side * 8)
			local t = Props.table(parent, c, Vector3.new(7, 3.2, 4.5), tableColor, darken(tableColor, 0.8))
			splatters(t, c, Vector3.new(3, 0, 1.8), 3.21, rng:NextInteger(3, 8), rng)
			place(t, c, Vector3.zero, math.rad(rng:NextNumber(-3, 3)))
			for _, dx in ipairs({ -2, 2 }) do
				for _, dz in ipairs({ -3.3, 3.3 }) do
					if rng:NextNumber() < 0.6 then
						local sc = c + Vector3.new(dx, 0, dz)
						place(Props.stool(parent, sc, darken(room.wood, 0.8)), sc, Vector3.new(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3)), 0)
					end
				end
			end
		end
	end

	local counterPos = Vector3.new(b.x0 + 1.55, 0, b.z0 + 6)
	part(parent, "SinkCounter", Vector3.new(2.5, 3.4, 7), counterPos + Vector3.new(0, 1.7, 0), Wood, room.trim)
	part(parent, "SinkBasin", Vector3.new(1.8, 0.06, 2.4), counterPos + Vector3.new(0.1, 3.41, 0), Enum.Material.Metal, Color3.fromRGB(80, 82, 84))
	splatters(parent, counterPos, Vector3.new(1, 0, 3), 3.42, rng:NextInteger(3, 7), rng)

	local shelf = Vector3.new(b.x0 + 1.1, 0, zMid + 6)
	Props.bookcase(parent, shelf, 0, room.wood, rng, 0.2)
	for _ = 1, rng:NextInteger(3, 6) do
		local h = rng:NextNumber(0.6, 1.2)
		cylinder(parent, "ClayPot", h, rng:NextNumber(0.6, 1.0), CFrame.new(shelf + Vector3.new(rng:NextNumber(-0.3, 0.3), 8 + h / 2, rng:NextNumber(-1.8, 1.8))) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Concrete, Color3.fromRGB(168, 110, 76))
	end
end
