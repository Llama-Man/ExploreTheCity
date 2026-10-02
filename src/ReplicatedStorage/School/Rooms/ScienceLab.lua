-- Science lab: black-topped lab benches with sinks and gas taps in a grid,
-- a demonstration bench at the front, glass cabinets of bottles along the
-- back wall and a faded periodic table above them.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)

local part, cylinder, model, place, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.place, BuildUtil.darken
local Wood, Metal, Smooth = Enum.Material.Wood, Enum.Material.Metal, Enum.Material.SmoothPlastic

local BENCH_L, BENCH_D, BENCH_H = 8, 4.5, 3.4
local GLASS_TINT = Color3.fromRGB(210, 225, 225)

local function beaker(parent, pos, rng, knocked)
	local h, d = rng:NextNumber(0.7, 1.1), rng:NextNumber(0.5, 0.7)
	local cf = if knocked
		then CFrame.new(pos + Vector3.new(0, d / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		else CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local glass = cylinder(parent, "Beaker", h, d, cf, Enum.Material.Glass, GLASS_TINT)
	glass.Transparency = 0.4
end

-- Lab bench running along X, sink at the +X end.
local function labBench(parent, c, woodColor, rng, mess)
	local m = model(parent, "LabBench")
	part(m, "BenchBase", Vector3.new(BENCH_L - 0.4, BENCH_H - 0.3, BENCH_D - 0.4), c + Vector3.new(0, (BENCH_H - 0.3) / 2, 0), Wood, woodColor)
	for _, s in ipairs({ -1, 1 }) do
		for k = -1, 1 do
			part(m, "CupboardSeam", Vector3.new(0.06, BENCH_H - 0.8, 0.04), c + Vector3.new(k * BENCH_L / 4, BENCH_H / 2, s * (BENCH_D / 2 - 0.19)), Wood, darken(woodColor, 0.5))
		end
	end
	part(m, "BenchTop", Vector3.new(BENCH_L, 0.3, BENCH_D), c + Vector3.new(0, BENCH_H - 0.15, 0), Enum.Material.Slate, Color3.fromRGB(38, 38, 40))
	part(m, "Sink", Vector3.new(1.6, 0.06, 1.8), c + Vector3.new(BENCH_L / 2 - 1.2, BENCH_H + 0.01, 0), Metal, Color3.fromRGB(70, 72, 74))
	cylinder(m, "Faucet", 1.2, 0.15, CFrame.new(c + Vector3.new(BENCH_L / 2 - 0.25, BENCH_H + 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Metal, Color3.fromRGB(170, 170, 172))
	cylinder(m, "Spout", 0.8, 0.12, CFrame.new(c + Vector3.new(BENCH_L / 2 - 0.6, BENCH_H + 1.15, 0)), Metal, Color3.fromRGB(170, 170, 172))
	for _, s in ipairs({ -1, 1 }) do
		part(m, "GasTap", Vector3.new(0.2, 0.3, 0.2), c + Vector3.new(0, BENCH_H + 0.15, s * 1.2), Metal, Color3.fromRGB(170, 140, 60))
	end
	for _ = 1, rng:NextInteger(0, 3) do
		beaker(m, c + Vector3.new(rng:NextNumber(-3, 1.5), BENCH_H, rng:NextNumber(-1.6, 1.6)), rng, rng:NextNumber() < mess * 0.4)
	end
	return m
end

local function periodicTable(parent, x, y, z)
	local poster = part(parent, "PeriodicTable", Vector3.new(0.05, 3.6, 7), Vector3.new(x, y, z), Smooth, Color3.fromRGB(228, 224, 210))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30

	for period = 1, 7 do
		for group = 1, 18 do
			local present = (period == 1 and (group == 1 or group == 18)) or (period <= 3 and period > 1 and (group <= 2 or group >= 13)) or period >= 4
			if present then
				local cell = Instance.new("Frame")
				cell.BorderSizePixel = 0
				cell.Size = UDim2.fromScale(1 / 18 - 0.004, 1 / 8.5 - 0.01)
				cell.Position = UDim2.fromScale((group - 1) / 18 + 0.002, 0.14 + (period - 1) / 8.5)
				cell.BackgroundColor3 = if group <= 2 then Color3.fromRGB(214, 146, 126) elseif group >= 13 then Color3.fromRGB(146, 184, 200) else Color3.fromRGB(218, 204, 150)
				cell.BackgroundTransparency = 0.2
				cell.Parent = gui
			end
		end
	end
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.12)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(60, 60, 64)
	title.Text = "元素周期表"
	title.Parent = gui
	gui.Parent = poster
end

return function(parent, room, rng)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2
	local benchWood = darken(room.wood, 0.9)

	Props.whiteboard(parent, room, rng, if rng:NextNumber() < 0.6 then "writing" else "blank")

	for _, col in ipairs({ -1, 1 }) do
		for row = 1, 3 do
			local c = Vector3.new(b.x0 + 8 + (row - 1) * 10.5, 0, zMid + col * 7.5)
			local bench = labBench(parent, c, benchWood, rng, room.mess)
			place(bench, c, Vector3.zero, math.rad(rng:NextNumber(-1, 1)))
			for _, side in ipairs({ -1, 1 }) do
				for _, dx in ipairs({ -2, 2 }) do
					if rng:NextNumber() > 0.15 + room.mess * 0.15 then
						local sc = c + Vector3.new(dx, 0, side * 3.3)
						place(Props.stool(parent, sc, darken(room.wood, 0.8)), sc, Vector3.new(rng:NextNumber(-0.3, 0.3), 0, side * rng:NextNumber(0, 0.6)), 0)
					end
				end
			end
		end
	end

	local demo = Vector3.new(b.x1 - 6, 0, zMid)
	place(labBench(parent, demo, benchWood, rng, room.mess), demo, Vector3.zero, math.rad(90))

	for i = 1, 3 do
		Props.glassCabinet(parent, Vector3.new(b.x0 + 1.1, 0, zMid + (i - 2) * 4.8), 0, room.wood, rng)
	end
	periodicTable(parent, b.x0 + 0.05, 10, zMid)
end
