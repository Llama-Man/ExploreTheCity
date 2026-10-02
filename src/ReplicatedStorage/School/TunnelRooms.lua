-- Rooms that break up the tunnel maze: some junctions open into something
-- other than bare cave. Each type has a `carve` step (run with the other
-- terrain carving) and a `furnish` step (run once the rock is final).
-- `p` is the floor centre of the maze cell the room sits on.

local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local TunnelProps = require(script.Parent.TunnelProps)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local Concrete, Metal, Wood, Smooth, Fabric, Brick, Neon = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.Wood, Enum.Material.SmoothPlastic, Enum.Material.Fabric, Enum.Material.Brick, Enum.Material.Neon

local terrain = workspace.Terrain
local AIR, ROCK, WATER = Enum.Material.Air, Enum.Material.Rock, Enum.Material.Water
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local STEEL = Color3.fromRGB(96, 98, 100)
local RUST_COLOR = Color3.fromRGB(116, 76, 48)

local function box(parent, name, center, size, material, color, cframe)
	return part(parent, name, size, if cframe then cframe else center, material, color)
end

local function rod(parent, name, a, b, diameter, material, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return cylinder(parent, name, len, diameter, CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), material, color)
end

local function lamp(parent, at, rng, color)
	local bulb = part(parent, "RoomLamp", Vector3.new(0.7, 0.7, 0.7), at, Enum.Material.Neon, color or Color3.fromRGB(255, 210, 150))
	bulb.Shape = Enum.PartType.Ball
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.2
	light.Color = color or Color3.fromRGB(255, 200, 140)
	light.Parent = bulb
	if rng:NextNumber() < 0.3 then
		bulb:AddTag("FlickerLight")
	end
end

local function carveBox(p, size)
	terrain:FillBlock(CFrame.new(p + Vector3.new(0, size.Y / 2, 0)), size, AIR)
	terrain:FillBlock(CFrame.new(p - Vector3.new(0, 2, 0)), Vector3.new(size.X, 4, size.Z), ROCK)
end

local function carveCave(p, radius)
	terrain:FillBall(p + Vector3.new(0, radius * 0.45, 0), radius, AIR)
	terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, radius - 1, ROCK)
end

local rooms = {}

-- ===== A classroom the rock has swallowed =====

rooms.buriedClassroom = {
	carve = function(p, rng)
		carveBox(p, Vector3.new(26, 14, 22))
		-- The rock pushing back in at a couple of corners.
		for _ = 1, 2 do
			local corner = Vector3.new(pick({ -1, 1 }, rng) * 12, 0, pick({ -1, 1 }, rng) * 10)
			terrain:FillBall(p + corner + Vector3.new(0, rng:NextNumber(4, 8), 0), rng:NextNumber(5, 7), ROCK)
		end
	end,
	furnish = function(parent, p, rng)
		local m = model(parent, "BuriedClassroom")
		for z = -9, 9, 1.5 do
			if rng:NextNumber() > 0.15 then
				box(m, "Floorboard", nil, Vector3.new(22, 0.4, 1.4), Wood, jitter(Color3.fromRGB(140, 104, 70), rng, 0.1), CFrame.new(p + Vector3.new(0, 0.2, z)) * CFrame.Angles(math.rad(rng:NextNumber(-2, 2)), 0, math.rad(rng:NextNumber(-1.5, 1.5))))
			end
		end
		-- A fragment of the outer wall: plaster over wood panelling, the
		-- window frames empty, glass all over the floor under them.
		local plaster = Color3.fromRGB(176, 166, 146)
		local panel = Color3.fromRGB(110, 80, 54)
		local wz = p.Z + 10.5
		box(m, "WallFragment", p + Vector3.new(-7, 4.5, 10.5), Vector3.new(8, 9, 1), Enum.Material.Plaster, plaster)
		box(m, "WallFragment", p + Vector3.new(6, 2, 10.5), Vector3.new(10, 4, 1), Enum.Material.Plaster, plaster)
		box(m, "Wainscot", p + Vector3.new(-7, 1.6, 9.9), Vector3.new(8, 3.2, 0.25), Wood, panel)
		box(m, "Wainscot", p + Vector3.new(6, 1.6, 9.9), Vector3.new(10, 3.2, 0.25), Wood, panel)
		for _, dx in ipairs({ 1, 5.5, 10 }) do
			box(m, "WindowFrame", Vector3.new(p.X + dx, p.Y + 7, wz), Vector3.new(0.4, 6, 0.6), Wood, Color3.fromRGB(80, 60, 40))
		end
		box(m, "WindowFrame", Vector3.new(p.X + 5.5, p.Y + 10, wz), Vector3.new(9.4, 0.4, 0.6), Wood, Color3.fromRGB(80, 60, 40))
		box(m, "WindowSill", Vector3.new(p.X + 5.5, p.Y + 4.1, wz - 0.3), Vector3.new(9.8, 0.25, 1.2), Wood, Color3.fromRGB(80, 60, 40))
		for _ = 1, rng:NextInteger(8, 14) do
			local shard = part(m, "GlassShard", Vector3.new(rng:NextNumber(0.3, 1.2), 0.05, rng:NextNumber(0.3, 1)), CFrame.new(p + Vector3.new(rng:NextNumber(1, 10), 0.45, rng:NextNumber(6, 9.5))) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Enum.Material.Glass, Color3.fromRGB(168, 176, 166))
			shard.Transparency = 0.4
			shard.CanCollide = false
		end
		-- The blackboard: frame, chalk tray, the last lesson still on it.
		local bb = CFrame.new(p + Vector3.new(-12.6, 4.8, -2)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6)))
		local board = part(m, "Blackboard", Vector3.new(0.3, 4, 9), bb, Smooth, Color3.fromRGB(38, 64, 50))
		part(m, "BoardFrame", Vector3.new(0.4, 4.4, 9.4), bb * CFrame.new(-0.06, 0, 0), Wood, Color3.fromRGB(96, 70, 46))
		part(m, "ChalkTray", Vector3.new(0.8, 0.2, 9), bb * CFrame.new(0.4, -2.1, 0), Wood, Color3.fromRGB(96, 70, 46))
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Right
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(0.9, 0.8)
		t.Position = UDim2.fromScale(0.05, 0.1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.IndieFlower
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(220, 224, 214)
		t.TextTransparency = 0.35
		t.Text = pick({ "日直  ー\n明日は地下へ行かないこと", "避難経路\n→ 東階段", "三月十日\n静かに待つこと" }, rng)
		t.Parent = gui
		gui.Parent = board
		for _ = 1, rng:NextInteger(3, 6) do
			local at = p + Vector3.new(rng:NextNumber(-9, 9), -rng:NextNumber(0, 0.8), rng:NextNumber(-7, 7))
			if rng:NextNumber() < 0.6 then
				local desk = Props.studentDesk(m, at, Props.DESK_TOP_COLOR, rng)
				if rng:NextNumber() < 0.5 then
					Props.tipDesk(desk, at, rng:NextNumber(0, 6.28))
				else
					BuildUtil.place(desk, at, Vector3.zero, rng:NextNumber(-0.6, 0.6))
				end
			else
				Props.tipChair(Props.studentChair(m, at, Props.DESK_TOP_COLOR), at, rng:NextNumber(0, 6.28))
			end
		end
		-- The wall clock, down on the floor.
		cylinder(m, "FallenClock", 0.25, 2.2, CFrame.new(p + Vector3.new(rng:NextNumber(-6, 2), 0.55, rng:NextNumber(-6, 0))) * UPRIGHT, Smooth, Color3.fromRGB(230, 226, 214))
		-- Rubble where the rock came in.
		for _ = 1, rng:NextInteger(8, 14) do
			local s = Vector3.new(rng:NextNumber(0.6, 2.2), rng:NextNumber(0.4, 1.4), rng:NextNumber(0.6, 2.2))
			part(m, "Rubble", s, CFrame.new(p + Vector3.new(pick({ -1, 1 }, rng) * rng:NextNumber(7, 11), s.Y * 0.4, pick({ -1, 1 }, rng) * rng:NextNumber(5, 9))) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Enum.Material.Slate, jitter(Color3.fromRGB(90, 88, 84), rng, 0.1))
		end
		-- A classroom light still hanging, askew, on one chain.
		local lightAt = p + Vector3.new(rng:NextNumber(-3, 3), 9.5, rng:NextNumber(-3, 3))
		cylinder(m, "LightChain", 3, 0.1, CFrame.new(lightAt + Vector3.new(0, 1.6, 0)) * UPRIGHT, Metal, STEEL)
		local housing = part(m, "LightHousing", Vector3.new(5, 0.3, 1), CFrame.new(lightAt) * CFrame.Angles(0, rng:NextNumber(0, 3), math.rad(rng:NextNumber(15, 30))), Smooth, Color3.fromRGB(222, 220, 212))
		housing.CanCollide = false
		lamp(m, lightAt - Vector3.new(0, 0.5, 0), rng, Color3.fromRGB(240, 236, 210))
	end,
}

-- ===== A flooded pump room =====

rooms.pumpRoom = {
	carve = function(p, _rng)
		carveBox(p, Vector3.new(24, 14, 24))
	end,
	furnish = function(parent, p, rng)
		local m = model(parent, "PumpRoom")
		local grey = Color3.fromRGB(120, 118, 112)
		box(m, "ConcreteFloor", p + Vector3.new(0, 0.25, 0), Vector3.new(24, 0.5, 24), Concrete, grey)
		for _, side in ipairs({ -1, 1 }) do
			box(m, "ConcreteWall", p + Vector3.new(side * 11.5, 5, 0), Vector3.new(1, 10, 14), Concrete, jitter(grey, rng, 0.06))
		end
		for k = 0, 1 do
			local c = p + Vector3.new(-5 + k * 10, 0.5, -5)
			box(m, "PumpPlinth", c + Vector3.new(0, 0.4, 0), Vector3.new(5.5, 0.8, 5.5), Concrete, darken(grey, 0.9))
			cylinder(m, "PumpBody", 5, 4, CFrame.new(c + Vector3.new(0, 3.3, 0)) * UPRIGHT, Metal, Color3.fromRGB(70, 90, 110))
			for _, y in ipairs({ 1.2, 5.4 }) do
				cylinder(m, "PumpFlange", 0.4, 4.6, CFrame.new(c + Vector3.new(0, y, 0)) * UPRIGHT, Metal, Color3.fromRGB(56, 72, 88))
			end
			box(m, "PumpMotor", c + Vector3.new(0, 6.6, 0), Vector3.new(3, 2, 3), Metal, Color3.fromRGB(60, 62, 64))
			for f = 0, 3 do
				box(m, "MotorFin", c + Vector3.new(0, 5.8 + f * 0.5, 0), Vector3.new(3.3, 0.12, 3.3), Metal, Color3.fromRGB(50, 52, 54))
			end
			cylinder(m, "PumpPipe", 10, 1.4, CFrame.new(c + Vector3.new(0, 2, 6)) * CFrame.Angles(0, math.pi / 2, 0), Enum.Material.CorrodedMetal, RUST_COLOR)
			local gauge = cylinder(m, "Gauge", 0.2, 1, CFrame.new(c + Vector3.new(-2.1, 4.2, 0)), Smooth, Color3.fromRGB(236, 236, 230))
			gauge.CanCollide = false
			part(m, "GaugeNeedle", Vector3.new(0.05, 0.4, 0.06), CFrame.new(c + Vector3.new(-2.22, 4.2, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-60, 60)), 0, 0), Smooth, Color3.fromRGB(180, 30, 26)).CanCollide = false
			for s = 0, 5 do
				local a0, a1 = s / 6 * math.pi * 2, (s + 1) / 6 * math.pi * 2
				local w = c + Vector3.new(2.3, 4.3, 0)
				local p0, p1 = w + Vector3.new(0, math.sin(a0), math.cos(a0)), w + Vector3.new(0, math.sin(a1), math.cos(a1))
				cylinder(m, "ValveWheel", (p1 - p0).Magnitude, 0.2, CFrame.lookAt((p0 + p1) / 2, p1, Vector3.xAxis) * CFrame.Angles(0, math.pi / 2, 0), Metal, Color3.fromRGB(170, 40, 34))
			end
		end
		cylinder(m, "MainPipe", 24, 2.2, CFrame.new(p + Vector3.new(0, 11, 9)), Enum.Material.CorrodedMetal, RUST_COLOR)
		for x = -9, 9, 6 do
			cylinder(m, "PipeFlange", 0.4, 2.8, CFrame.new(p + Vector3.new(x, 11, 9)), Metal, Color3.fromRGB(90, 70, 52))
		end
		-- Control panel on the wall: dials and a row of dead indicator lamps
		-- (one still lit).
		local panelAt = p + Vector3.new(-10.6, 4.5, 4)
		box(m, "ControlPanel", panelAt, Vector3.new(1, 5, 5), Metal, Color3.fromRGB(150, 150, 140))
		for k = 0, 2 do
			cylinder(m, "Dial", 0.15, 1, CFrame.new(panelAt + Vector3.new(0.55, 1, -1.5 + k * 1.5)), Smooth, Color3.fromRGB(236, 236, 230))
		end
		for k = 0, 4 do
			local lit = k == rng:NextInteger(0, 4)
			local ind = part(m, "Indicator", Vector3.new(0.2, 0.35, 0.35), panelAt + Vector3.new(0.55, -0.6, -1.8 + k * 0.9), if lit then Enum.Material.Neon else Smooth, if lit then Color3.fromRGB(230, 60, 40) else Color3.fromRGB(80, 40, 36))
			ind.CanCollide = false
		end
		-- A grating catwalk along one side, above the water.
		box(m, "Catwalk", p + Vector3.new(0, 2.2, 9.5), Vector3.new(22, 0.3, 3.4), Enum.Material.DiamondPlate, STEEL)
		for x = -10, 10, 4 do
			cylinder(m, "CatwalkLeg", 2, 0.3, CFrame.new(p + Vector3.new(x, 1.1, 8)) * UPRIGHT, Metal, STEEL)
			cylinder(m, "CatwalkPost", 3.2, 0.2, CFrame.new(p + Vector3.new(x, 3.9, 7.9)) * UPRIGHT, Metal, Color3.fromRGB(214, 176, 40))
		end
		cylinder(m, "CatwalkRail", 22, 0.2, CFrame.new(p + Vector3.new(0, 5.4, 7.9)), Metal, Color3.fromRGB(214, 176, 40))
		local ladder = Instance.new("TrussPart")
		ladder.Name = "PumpLadder"
		ladder.Anchored = true
		ladder.Size = Vector3.new(2, 13, 2)
		ladder.Position = p + Vector3.new(10, 6.5, 8)
		ladder.Material = Enum.Material.CorrodedMetal
		ladder.Color = RUST_COLOR
		ladder.Parent = m
		terrain:FillBlock(CFrame.new(p + Vector3.new(0, 1, 0)), Vector3.new(22, 1.6, 22), WATER)
		lamp(m, p + Vector3.new(0, 12, -3), rng, Color3.fromRGB(220, 230, 210))
	end,
}

-- ===== A brick storage vault =====

rooms.storageVault = {
	carve = function(p, _rng)
		carveBox(p, Vector3.new(22, 13, 26))
	end,
	furnish = function(parent, p, rng)
		local m = model(parent, "StorageVault")
		local brick = Color3.fromRGB(130, 76, 60)
		box(m, "VaultFloor", p + Vector3.new(0, 0.25, 0), Vector3.new(22, 0.5, 26), Concrete, Color3.fromRGB(110, 106, 100))
		for _, side in ipairs({ -1, 1 }) do
			box(m, "VaultWall", p + Vector3.new(side * 10.5, 4.5, 0), Vector3.new(1, 9, 24), Brick, jitter(brick, rng, 0.06))
		end
		-- Brick arches across the vault.
		for z = -10, 10, 5 do
			for s = 0, 7 do
				local a0, a1 = math.pi * s / 8, math.pi * (s + 1) / 8
				local p0 = p + Vector3.new(math.cos(a0) * 10.5, 9 + math.sin(a0) * 3.5, z)
				local p1 = p + Vector3.new(math.cos(a1) * 10.5, 9 + math.sin(a1) * 3.5, z)
				part(m, "Arch", Vector3.new(1.2, 1, (p1 - p0).Magnitude + 0.3), CFrame.lookAt((p0 + p1) / 2, p1), Brick, jitter(brick, rng, 0.06))
			end
		end
		for _, side in ipairs({ -1, 1 }) do
			for level = 0, 2 do
				box(m, "Shelf", p + Vector3.new(side * 8.8, 1.5 + level * 2.6, 0), Vector3.new(2.2, 0.25, 20), Wood, Color3.fromRGB(110, 84, 58))
				for z = -9, 9, 1.4 do
					if rng:NextNumber() < 0.6 then
						local h = rng:NextNumber(0.8, 1.6)
						local jar = cylinder(m, "Jar", h, rng:NextNumber(0.6, 1), CFrame.new(p + Vector3.new(side * 8.8, 1.6 + level * 2.6 + h / 2, z)) * UPRIGHT, Enum.Material.Glass, pick({ Color3.fromRGB(110, 90, 50), Color3.fromRGB(80, 110, 90), Color3.fromRGB(160, 150, 130) }, rng))
						jar.Transparency = 0.3
					end
				end
			end
			for _, z in ipairs({ -10, 10 }) do
				box(m, "ShelfUpright", p + Vector3.new(side * 8.8, 4, z), Vector3.new(2.2, 8, 0.3), Wood, Color3.fromRGB(96, 72, 50))
			end
		end
		-- Supplies down the middle aisle.
		for _, z in ipairs({ -8, 6 }) do
			TunnelProps.supplyHeap(m, p + Vector3.new(rng:NextNumber(-2, 2), 0.5, z + rng:NextNumber(-2, 2)), rng, 2)
		end
		lamp(m, p + Vector3.new(0, 10, 0), rng)
	end,
}

-- ===== A grotto of glowing fungus =====

rooms.fungusGrotto = {
	carve = function(p, rng)
		carveCave(p, 18)
		terrain:FillBall(p + Vector3.new(rng:NextNumber(-5, 5), 10, rng:NextNumber(-5, 5)), 15, AIR)
		-- Side lobes, floored level with the rest.
		for _ = 1, 2 do
			local a = rng:NextNumber(0, math.pi * 2)
			local lobe = p + Vector3.new(math.cos(a) * 14, 0, math.sin(a) * 14)
			terrain:FillBall(lobe + Vector3.new(0, 5, 0), 10, AIR)
			terrain:FillCylinder(CFrame.new(lobe - Vector3.new(0, 2, 0)), 4, 9, ROCK)
		end
		terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2, 0)), 4, 6, AIR)
		terrain:FillCylinder(CFrame.new(p - Vector3.new(0, 2.6, 0)), 2.8, 6, WATER)
	end,
	furnish = function(parent, p, rng)
		local m = model(parent, "FungusGrotto")
		local palettes = { TunnelProps.GLOWS[1], TunnelProps.GLOWS[3], TunnelProps.GLOWS[1], TunnelProps.GLOWS[2] }
		local bases = {}
		-- Towering mushrooms round the pool, caps big enough to stand on,
		-- each throwing its light down onto the floor beneath.
		for _ = 1, rng:NextInteger(5, 7) do
			local a = rng:NextNumber(0, math.pi * 2)
			local at = TunnelProps.floorAt(p + Vector3.new(math.cos(a) * rng:NextNumber(8, 15), 0, math.sin(a) * rng:NextNumber(8, 15)))
			local palette = pick(palettes, rng)
			local h, capD = rng:NextNumber(7, 15), rng:NextNumber(7, 13)
			local top = TunnelProps.mushroom(m, at, h, capD, palette, rng, { solid = true, capTransparency = 0.05 })
			local under = part(m, "CapGlow", Vector3.new(0.2, 0.2, 0.2), top - Vector3.new(0, 0.6, 0), Smooth, palette.cap)
			under.Transparency = 1
			under.CanCollide = false
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Angle = 120
			light.Range = h + 10
			light.Brightness = 1.6
			light.Color = palette.cap
			light.Parent = under
			table.insert(bases, at)
			-- Smaller ones crowding its foot.
			TunnelProps.mushroomCluster(m, at + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)), rng, rng:NextNumber(0.8, 1.4), palette)
		end
		for _ = 1, rng:NextInteger(6, 10) do
			local a = rng:NextNumber(0, math.pi * 2)
			local at = TunnelProps.floorAt(p + Vector3.new(math.cos(a) * rng:NextNumber(4, 17), 0, math.sin(a) * rng:NextNumber(4, 17)))
			TunnelProps.mushroomCluster(m, at, rng, rng:NextNumber(0.5, 1.2), pick(palettes, rng))
			table.insert(bases, at)
		end
		-- Glowing threads of mycelium across the floor between them.
		for k = 1, #bases - 1 do
			local a, b = bases[k], bases[k + 1]
			local len = (b - a).Magnitude
			if len < 18 then
				local mid = (a + b) / 2 + Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
				for _, seg in ipairs({ { a, mid }, { mid, b } }) do
					local s0, s1 = seg[1] + Vector3.new(0, 0.05, 0), seg[2] + Vector3.new(0, 0.05, 0)
					local thread = part(m, "Mycelium", Vector3.new(0.12, 0.05, (s1 - s0).Magnitude), CFrame.lookAt((s0 + s1) / 2, s1), Neon, pick(palettes, rng).cap)
					thread.Transparency = 0.45
					thread.CanCollide = false
				end
			end
		end
		-- Shelf fungi up the cave walls, tendrils from the roof, spores.
		for k = 0, 15 do
			local a = k / 16 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
			for _, h in ipairs({ 2.5, 7 }) do
				if rng:NextNumber() < 0.55 then
					local hit = TunnelProps.wallHit(p + Vector3.new(0, h, 0), Vector3.new(math.cos(a), 0, math.sin(a)), 34)
					if hit then
						TunnelProps.bracketFungus(m, hit.Position, hit.Normal, rng, pick(palettes, rng))
					end
				end
			end
		end
		TunnelProps.tendrils(m, p + Vector3.new(0, 6, 0), rng:NextInteger(18, 28), rng, palettes[1])
		TunnelProps.spores(m, p + Vector3.new(0, 1, 0), 14, rng:NextInteger(50, 80), rng, palettes[1])
		TunnelProps.spores(m, p + Vector3.new(0, 1, 0), 12, rng:NextInteger(20, 40), rng, palettes[2])
		-- The pool glows from within.
		local poolGlow = cylinder(m, "PoolGlow", 0.1, 11, CFrame.new(p - Vector3.new(0, 1.9, 0)) * UPRIGHT, Neon, Color3.fromRGB(60, 200, 210))
		poolGlow.Transparency = 0.55
		poolGlow.CanCollide = false
		local poolLight = Instance.new("PointLight")
		poolLight.Range = 16
		poolLight.Brightness = 1.2
		poolLight.Color = Color3.fromRGB(70, 210, 220)
		poolLight.Parent = poolGlow
		-- Stalagmites.
		for _ = 1, rng:NextInteger(4, 7) do
			local a = rng:NextNumber(0, math.pi * 2)
			local at = TunnelProps.floorAt(p + Vector3.new(math.cos(a) * rng:NextNumber(12, 18), 0, math.sin(a) * rng:NextNumber(12, 18)))
			local h, d = rng:NextNumber(2, 6), rng:NextNumber(1.2, 2.4)
			for s = 0, 2 do
				cylinder(m, "Stalagmite", h / 3 + 0.2, d * (1 - s * 0.3), CFrame.new(at + Vector3.new(0, h / 6 + s * h / 3, 0)) * UPRIGHT, Enum.Material.Slate, Color3.fromRGB(96, 94, 90))
			end
		end
		-- Somebody got this far: hard hat, pack and lantern, grown over.
		local a = rng:NextNumber(0, math.pi * 2)
		local lost = TunnelProps.floorAt(p + Vector3.new(math.cos(a) * 11, 0, math.sin(a) * 11))
		local hat = TunnelProps.ellipsoid(m, "HardHat", Vector3.new(1.4, 0.8, 1.6), CFrame.new(lost + Vector3.new(0.6, 0.35, 0)) * CFrame.Angles(0.3, rng:NextNumber(0, 3), 0.2), Smooth, Color3.fromRGB(220, 180, 40))
		hat.CanCollide = false
		cylinder(m, "HatBrim", 0.08, 1.9, CFrame.new(lost + Vector3.new(0.6, 0.1, 0)) * UPRIGHT, Smooth, Color3.fromRGB(200, 160, 30))
		part(m, "Backpack", Vector3.new(1.6, 2, 1), CFrame.new(lost + Vector3.new(-1, 0.8, 0.6)) * CFrame.Angles(0, rng:NextNumber(0, 3), math.rad(70)), Fabric, Color3.fromRGB(70, 80, 60))
		TunnelProps.lantern(m, CFrame.new(lost + Vector3.new(0.4, 0, 1.4)) * CFrame.Angles(0, 0, math.rad(80)), rng, false)
		part(m, "Notebook", Vector3.new(0.7, 0.1, 1), CFrame.new(lost + Vector3.new(1.4, 0.05, -0.6)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Smooth, Color3.fromRGB(120, 40, 30))
		TunnelProps.mushroomCluster(m, lost, rng, 0.5, palettes[3])
	end,
}

-- ===== An abandoned miners' camp =====

rooms.minersCamp = {
	carve = function(p, _rng)
		carveCave(p, 13)
	end,
	furnish = function(parent, p, rng)
		local m = model(parent, "MinersCamp")
		local canvas = jitter(Color3.fromRGB(150, 140, 110), rng, 0.08)
		local pole = Color3.fromRGB(90, 70, 50)
		-- An A-frame tent: two A-shaped pole frames, a ridge pole, canvas
		-- sides, guy ropes out to pegs.
		local tent = CFrame.new(p + Vector3.new(-5, 0, -3)) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0)
		local tl, th, tw = 8, 4.2, 2.6
		for _, x in ipairs({ -tl / 2, tl / 2 }) do
			for _, s in ipairs({ -1, 1 }) do
				local foot = (tent * CFrame.new(x, 0, s * tw)).Position
				local apex = (tent * CFrame.new(x, th, 0)).Position
				cylinder(m, "TentPole", (apex - foot).Magnitude, 0.2, CFrame.lookAt((foot + apex) / 2, apex, Vector3.xAxis) * CFrame.Angles(0, math.pi / 2, 0), Wood, pole)
			end
		end
		cylinder(m, "RidgePole", tl + 0.8, 0.22, tent * CFrame.new(0, th, 0), Wood, pole)
		local slope = math.sqrt(th ^ 2 + tw ^ 2)
		for _, s in ipairs({ -1, 1 }) do
			-- Each side runs from the ridge down to its line of feet.
			local mid = (tent * CFrame.new(0, th / 2, s * tw / 2)).Position
			local down = tent:VectorToWorldSpace(Vector3.new(0, -th, s * tw))
			part(m, "TentSide", Vector3.new(tl + 0.4, 0.12, slope), CFrame.lookAt(mid, mid + down), Fabric, canvas)
			local peg = (tent * CFrame.new(0, 0.2, s * (tw + 2.5))).Position
			rod(m, "GuyRope", (tent * CFrame.new(0, th, 0)).Position, peg, 0.06, Fabric, Color3.fromRGB(190, 180, 150))
			part(m, "TentPeg", Vector3.new(0.2, 0.6, 0.2), peg, Wood, pole)
		end
		local bedroll = tent * CFrame.new(0, 0.3, 0)
		part(m, "Bedroll", Vector3.new(5.5, 0.4, 2), bedroll, Fabric, Color3.fromRGB(90, 70, 60))
		cylinder(m, "RolledBlanket", 2, 0.8, bedroll * CFrame.new(-2.4, 0.4, 0) * CFrame.Angles(0, math.pi / 2, 0), Fabric, Color3.fromRGB(120, 50, 40))
		-- Campfire: a ring of stones, charred logs, a tripod with a pot, a
		-- last few embers.
		local fire = p + Vector3.new(4, 0, 4)
		for s = 0, 8 do
			local a = s / 9 * math.pi * 2
			part(m, "FireStone", Vector3.new(0.9, 0.7, 0.9), CFrame.new(fire + Vector3.new(math.cos(a) * 1.8, 0.35, math.sin(a) * 1.8)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), a, 0), Enum.Material.Slate, jitter(Color3.fromRGB(90, 88, 84), rng, 0.1))
		end
		for _ = 1, 3 do
			cylinder(m, "CharredLog", 2.4, 0.5, CFrame.new(fire + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2)), Wood, Color3.fromRGB(30, 26, 22))
		end
		local apex = fire + Vector3.new(0, 4.5, 0)
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2
			rod(m, "Tripod", fire + Vector3.new(math.cos(a) * 2.4, 0, math.sin(a) * 2.4), apex, 0.18, Wood, pole)
		end
		rod(m, "PotChain", apex, apex - Vector3.new(0, 2, 0), 0.06, Metal, STEEL)
		cylinder(m, "CookingPot", 1.2, 1.5, CFrame.new(apex - Vector3.new(0, 2.6, 0)) * UPRIGHT, Metal, Color3.fromRGB(40, 40, 42))
		local embers = part(m, "Embers", Vector3.new(1.4, 0.2, 1.4), fire + Vector3.new(0, 0.25, 0), Enum.Material.Neon, Color3.fromRGB(255, 110, 40))
		embers.CanCollide = false
		embers.Transparency = 0.3
		local glow = Instance.new("PointLight")
		glow.Range = 10
		glow.Brightness = 0.8
		glow.Color = Color3.fromRGB(255, 120, 60)
		glow.Parent = embers
		embers:AddTag("FlickerLight")
		-- Log stools round the fire, a crate table with a lantern and a map.
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2 + 0.5
			cylinder(m, "LogStool", 1.4, 1.3, CFrame.new(fire + Vector3.new(math.cos(a) * 4, 0.7, math.sin(a) * 4)) * UPRIGHT, Wood, Color3.fromRGB(110, 84, 58))
		end
		local tableAt = CFrame.new(p + Vector3.new(6, 0, -6)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)
		TunnelProps.crate(m, tableAt, Vector3.new(3, 2.8, 2.6), rng, nil)
		part(m, "TableTop", Vector3.new(4.2, 0.25, 3.2), tableAt * CFrame.new(0, 2.95, 0), Wood, Color3.fromRGB(130, 100, 70))
		TunnelProps.lantern(m, tableAt * CFrame.new(-1.2, 3.1, 0.6), rng, true)
		local map = part(m, "Map", Vector3.new(2, 0.03, 1.5), tableAt * CFrame.new(0.6, 3.1, -0.2) * CFrame.Angles(0, 0.2, 0), Smooth, Color3.fromRGB(220, 206, 170))
		map.CanCollide = false
		-- Tools against the rock, supplies stacked.
		TunnelProps.pickaxe(m, CFrame.new(p + Vector3.new(-9, 0, 8)) * CFrame.Angles(math.rad(14), 0, math.rad(-8)))
		TunnelProps.shovel(m, CFrame.new(p + Vector3.new(-7, 0, 8.5)) * CFrame.Angles(math.rad(14), 0, math.rad(6)))
		TunnelProps.supplyHeap(m, p + Vector3.new(-2, 0, 8), rng, 2)
	end,
}

-- ===== A tiny cave shrine =====

rooms.shrineCave = {
	carve = function(p, _rng)
		carveCave(p, 11)
	end,
	furnish = function(parent, p, rng)
		local m = model(parent, "CaveShrine")
		local stone = Color3.fromRGB(120, 118, 110)
		local vermilion = Color3.fromRGB(200, 60, 40)
		local at = p + Vector3.new(0, 0, -5)
		box(m, "ShrineBase", at + Vector3.new(0, 0.6, 0), Vector3.new(4, 1.2, 3), Concrete, stone)
		box(m, "Hokora", at + Vector3.new(0, 2.6, 0), Vector3.new(2.6, 2.8, 2.2), Wood, Color3.fromRGB(110, 80, 56))
		box(m, "HokoraDoor", at + Vector3.new(0, 2.5, 1.12), Vector3.new(1.6, 2, 0.05), Wood, Color3.fromRGB(70, 50, 36))
		for _, s in ipairs({ -1, 1 }) do
			part(m, "HokoraRoof", Vector3.new(3.4, 0.3, 1.9), CFrame.new(at + Vector3.new(0, 4.4, s * 0.7)) * CFrame.Angles(s * math.rad(-30), 0, 0), Wood, Color3.fromRGB(60, 50, 44))
			local candle = at + Vector3.new(s * 2.8, 0, 1.2)
			cylinder(m, "Candle", 1, 0.35, CFrame.new(candle + Vector3.new(0, 0.5, 0)) * UPRIGHT, Smooth, Color3.fromRGB(230, 224, 206))
			local flame = part(m, "CandleFlame", Vector3.new(0.3, 0.3, 0.3), candle + Vector3.new(0, 1.2, 0), Enum.Material.Neon, Color3.fromRGB(255, 190, 90))
			flame.Shape = Enum.PartType.Ball
			flame.CanCollide = false
			local light = Instance.new("PointLight")
			light.Range = 12
			light.Brightness = 1.3
			light.Color = Color3.fromRGB(255, 170, 90)
			light.Parent = flame
			flame:AddTag("FlickerLight")
		end
		-- A little torii in front, vermilion with black caps.
		local gate = p + Vector3.new(0, 0, 3)
		for _, s in ipairs({ -1, 1 }) do
			cylinder(m, "ToriiPillar", 6.4, 0.6, CFrame.new(gate + Vector3.new(s * 2.4, 3.2, 0)) * UPRIGHT, Smooth, vermilion)
			cylinder(m, "ToriiFoot", 0.5, 0.8, CFrame.new(gate + Vector3.new(s * 2.4, 0.25, 0)) * UPRIGHT, Smooth, Color3.fromRGB(30, 28, 26))
		end
		box(m, "Nuki", gate + Vector3.new(0, 5.2, 0), Vector3.new(6, 0.4, 0.4), Smooth, vermilion)
		box(m, "Kasagi", gate + Vector3.new(0, 6.6, 0), Vector3.new(7.2, 0.5, 0.7), Smooth, vermilion)
		box(m, "KasagiCap", gate + Vector3.new(0, 7, 0), Vector3.new(7.6, 0.3, 0.8), Smooth, Color3.fromRGB(30, 28, 26))
		for _, s in ipairs({ -1, 1 }) do
			part(m, "KasagiTip", Vector3.new(0.9, 0.3, 0.8), CFrame.new(gate + Vector3.new(s * 4, 7.15, 0)) * CFrame.Angles(0, 0, s * math.rad(15)), Smooth, Color3.fromRGB(30, 28, 26))
		end
		-- Stone lanterns either side of the path.
		for _, s in ipairs({ -1, 1 }) do
			local base = p + Vector3.new(s * 3.6, 0, -1)
			box(m, "ToroBase", base + Vector3.new(0, 0.3, 0), Vector3.new(1.4, 0.6, 1.4), Concrete, stone)
			cylinder(m, "ToroPost", 1.8, 0.6, CFrame.new(base + Vector3.new(0, 1.5, 0)) * UPRIGHT, Concrete, stone)
			box(m, "ToroPlatform", base + Vector3.new(0, 2.5, 0), Vector3.new(1.3, 0.25, 1.3), Concrete, stone)
			box(m, "ToroFirebox", base + Vector3.new(0, 3.1, 0), Vector3.new(0.9, 0.9, 0.9), Concrete, stone)
			local fireLight = part(m, "ToroLight", Vector3.new(0.5, 0.5, 0.5), base + Vector3.new(0, 3.1, 0), Enum.Material.Neon, Color3.fromRGB(255, 180, 90))
			fireLight.CanCollide = false
			local light = Instance.new("PointLight")
			light.Range = 10
			light.Brightness = 0.9
			light.Color = Color3.fromRGB(255, 170, 90)
			light.Parent = fireLight
			part(m, "ToroRoof", Vector3.new(1.7, 0.4, 1.7), CFrame.new(base + Vector3.new(0, 3.75, 0)) * CFrame.Angles(0, math.rad(45), 0), Concrete, stone)
			part(m, "ToroJewel", Vector3.new(0.4, 0.4, 0.4), base + Vector3.new(0, 4.15, 0), Concrete, stone).Shape = Enum.PartType.Ball
		end
		-- Foxes guarding the shrine, red bibs round their necks.
		for _, s in ipairs({ -1, 1 }) do
			local fox = at + Vector3.new(s * 2.9, 0, 2.6)
			box(m, "FoxPlinth", fox + Vector3.new(0, 0.4, 0), Vector3.new(1.2, 0.8, 1.2), Concrete, stone)
			TunnelProps.ellipsoid(m, "FoxBody", Vector3.new(0.8, 1.3, 1), CFrame.new(fox + Vector3.new(0, 1.45, 0)), Smooth, Color3.fromRGB(230, 228, 220))
			TunnelProps.ellipsoid(m, "FoxHead", Vector3.new(0.6, 0.6, 0.8), CFrame.new(fox + Vector3.new(0, 2.25, 0.15)), Smooth, Color3.fromRGB(230, 228, 220))
			for _, e in ipairs({ -1, 1 }) do
				part(m, "FoxEar", Vector3.new(0.15, 0.4, 0.2), fox + Vector3.new(e * 0.2, 2.6, 0.05), Smooth, Color3.fromRGB(230, 228, 220))
			end
			part(m, "FoxBib", Vector3.new(0.7, 0.4, 0.1), CFrame.new(fox + Vector3.new(0, 1.85, 0.48)) * CFrame.Angles(math.rad(-15), 0, 0), Fabric, vermilion)
		end
		-- Stepping stones up to the gate.
		for k = 0, 3 do
			cylinder(m, "SteppingStone", 0.25, rng:NextNumber(1.2, 1.6), CFrame.new(p + Vector3.new(rng:NextNumber(-0.4, 0.4), 0.12, 8 - k * 2)) * UPRIGHT, Concrete, jitter(stone, rng, 0.08))
		end
		-- Shimenawa rope strung across the cave, hung with paper streamers.
		local ropeY = p.Y + 7.5
		cylinder(m, "Shimenawa", 14, 0.7, CFrame.new(p.X, ropeY, p.Z - 1), Fabric, Color3.fromRGB(200, 184, 140))
		for x = -5, 5, 2.5 do
			for k = 0, 2 do
				part(m, "Shide", Vector3.new(0.5, 0.5, 0.05), CFrame.new(p.X + x + (k % 2) * 0.3, ropeY - 0.6 - k * 0.5, p.Z - 1) * CFrame.Angles(0, 0, math.rad(if k % 2 == 0 then 10 else -10)), Smooth, Color3.fromRGB(240, 238, 230)).CanCollide = false
			end
		end
		for s = -1, 1, 2 do
			cylinder(m, "OfferingCup", 0.4, 0.6, CFrame.new(at + Vector3.new(s * 0.9, 1.4, 1.3)) * UPRIGHT, Smooth, Color3.fromRGB(236, 234, 226))
		end
		for _ = 1, rng:NextInteger(3, 7) do
			cylinder(m, "Coin", 0.05, 0.3, CFrame.new(at + Vector3.new(rng:NextNumber(-1.6, 1.6), 1.23, rng:NextNumber(0.6, 1.4))) * UPRIGHT, Metal, Color3.fromRGB(200, 170, 80))
		end
	end,
}

rooms.TYPES = { "buriedClassroom", "pumpRoom", "storageVault", "fungusGrotto", "minersCamp", "shrineCave" }

return rooms
