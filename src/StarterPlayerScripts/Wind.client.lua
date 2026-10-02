-- The wind (ReplicatedStorage.School.Windblown), on each player's machine:
--
--   * everything tagged "Windblown" - tarps, flags, vines, tape, signs on
--     chains, roof vents, tethered turbines - moved each frame while you're near enough to
--     see it (and now and then out to further off);
--   * Roblox's own wind (workspace.GlobalWind) kept in step with the
--     gusts, for anything that listens to it (grass, particles that
--     drift);
--   * out in the open, over the crossing and the town: streaks of air
--     going by, and bits of paper and plastic blowing past;
--   * a wind sound, if there's one to play: a Sound called WindLoop (and
--     one called Gust, if you like) in a folder ReplicatedStorage.
--     CrossingAssets. Without them, it's just quiet.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Wind = require(ReplicatedStorage:WaitForChild("School"):WaitForChild("Windblown"))

local player = Players.LocalPlayer
local UP = Vector3.yAxis
local NEAR, FAR = 260, 520 -- (every frame nearer than NEAR; every fourth out to FAR)

-- ===== The things it moves =====

local items, list = {}, {}

local function add(m)
	if not m:IsA("Model") or items[m] then
		return
	end
	local it = { model = m, info = Wind.info(m), ready = false }
	items[m] = it
	table.insert(list, it)
end

for _, m in ipairs(CollectionService:GetTagged("Windblown")) do
	add(m)
end
CollectionService:GetInstanceAddedSignal("Windblown"):Connect(add)

-- Find its parts (they come with it, but maybe a moment after).
local function collect(it)
	local info, m = it.info, it.model
	local parts = {}
	if info.kind == "Cloth" or info.kind == "Flag" then
		for i = 1, info.n do
			local p = m:FindFirstChild("S" .. i)
			if not p then
				return
			end
			parts[i] = p
			if info.kind == "Cloth" then
				info.offs[i] = p:GetAttribute("X")
			end
		end
		it.anchor = info.top or info.anchor
	elseif info.pivot then
		-- every part's place from the pivot, as built (a Sway or a Kite is
		-- built in its average lean: take that off)
		local rest = CFrame.new(info.pivot)
		local undo = CFrame.identity
		if info.kind == "Sway" then
			undo = Wind.swayTurn(info, 0, Wind.AVERAGE):Inverse()
		elseif info.kind == "Kite" then
			undo = Wind.kiteTurn(info, 0, Wind.AVERAGE):Inverse()
		end
		it.offs = {}
		it.rotor = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
				table.insert(it.offs, undo * rest:ToObjectSpace(d.CFrame))
				it.rotor[#parts] = d:GetAttribute("Rotor") == true
			end
		end
		if #parts == 0 then
			return
		end
		it.rest, it.angle, it.anchor = rest, info.phase, info.pivot
	else
		return
	end
	it.parts = parts
	it.ready = true
end

local frame = 0
local moveParts, moveTo = {}, {}

local function update(it, t, dt)
	local info = it.info
	local s = Wind.strength(t, it.anchor)
	if info.kind == "Cloth" or info.kind == "Flag" then
		local poses = if info.kind == "Cloth" then Wind.clothPose(info, t, s) else Wind.flagPose(info, t, s)
		for k, p in ipairs(it.parts) do
			table.insert(moveParts, p)
			table.insert(moveTo, poses[k])
		end
	else
		local turn
		if info.kind == "Sway" then
			turn = Wind.swayTurn(info, t, s)
		elseif info.kind == "Kite" then
			turn = Wind.kiteTurn(info, t, s)
			-- its rotor, turning about its own axis
			it.angle = (it.angle + info.rate * (0.4 + s) * dt) % (math.pi * 2)
			local rc = info.rotorC - info.pivot
			local spin = CFrame.new(rc) * CFrame.fromAxisAngle(info.rotorAxis, it.angle) * CFrame.new(-rc)
			local cf = it.rest * turn
			for k, p in ipairs(it.parts) do
				table.insert(moveParts, p)
				table.insert(moveTo, if it.rotor[k] then cf * spin * it.offs[k] else cf * it.offs[k])
			end
			return
		else
			it.angle = (it.angle + info.rate * s * dt) % (math.pi * 2)
			turn = CFrame.fromAxisAngle(info.axis, it.angle)
		end
		local cf = it.rest * turn
		for k, p in ipairs(it.parts) do
			table.insert(moveParts, p)
			table.insert(moveTo, cf * it.offs[k])
		end
	end
end

-- ===== Out in the open: air going by, and litter =====

local camera = workspace.CurrentCamera
local exposure = 0 -- (0 sheltered or far from the edge .. 1 right out in it)

local air = Instance.new("Part")
air.Name = "WindAir"
air.Anchored, air.CanCollide, air.CanQuery, air.CanTouch = true, false, false, false
air.Transparency = 1
air.Size = Vector3.new(2, 50, 110)
air.Parent = camera
local streaks = Instance.new("ParticleEmitter")
streaks.Texture = "rbxasset://textures/particles/smoke_main.dds"
streaks.EmissionDirection = Enum.NormalId.Right
streaks.Orientation = Enum.ParticleOrientation.VelocityParallel
streaks.Squash = NumberSequence.new(2.6)
streaks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.45) })
streaks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) })
streaks.Color = ColorSequence.new(Color3.fromRGB(226, 230, 234))
streaks.Lifetime = NumberRange.new(1.4, 2)
streaks.Speed = NumberRange.new(60, 80)
streaks.Rate = 0
streaks.Parent = air

local LITTER = {
	{ Vector3.new(0.9, 0.02, 1.2), Color3.fromRGB(226, 222, 210), Enum.Material.SmoothPlastic }, -- paper
	{ Vector3.new(1, 0.02, 1.4), Color3.fromRGB(200, 196, 186), Enum.Material.SmoothPlastic }, -- newspaper
	{ Vector3.new(1.4, 0.03, 1.6), Color3.fromRGB(236, 238, 240), Enum.Material.Plastic }, -- a bag
	{ Vector3.new(1.2, 0.03, 1.5), Color3.fromRGB(90, 130, 190), Enum.Material.Plastic }, -- a blue bag
	{ Vector3.new(0.5, 0.02, 0.6), Color3.fromRGB(120, 100, 60), Enum.Material.SmoothPlastic }, -- a leaf
}
local scraps = {}
for i = 1, 12 do
	local kind = LITTER[(i - 1) % #LITTER + 1]
	local p = Instance.new("Part")
	p.Name = "Litter"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.Color, p.Material = kind[1], kind[2], kind[3]
	p.Transparency = 1
	p.Parent = camera
	table.insert(scraps, { part = p, life = 0, pos = Vector3.zero, spin = Vector3.new(math.random(), math.random(), math.random()).Unit, seed = math.random() * 10 })
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function place(sc, here, s)
	local across = Vector3.new(-Wind.DIR.Z, 0, Wind.DIR.X)
	sc.pos = here - Wind.DIR * (40 + math.random() * 30) + across * (math.random() * 90 - 45) + UP * (math.random() * 30 - 12)
	sc.life = 6 + math.random() * 4
	sc.part.Transparency = 0
end

-- ===== Sound =====

local loop, gust
local function findSounds()
	local folder = ReplicatedStorage:FindFirstChild("CrossingAssets")
	if not folder then
		return
	end
	local l = folder:FindFirstChild("WindLoop")
	if l and l:IsA("Sound") and not loop then
		loop = l:Clone()
		loop.Looped = true
		loop.Volume = 0
		loop.Parent = SoundService
		loop:Play()
	end
	local g = folder:FindFirstChild("Gust")
	if g and g:IsA("Sound") and not gust then
		gust = g:Clone()
		gust.Parent = SoundService
	end
end
task.spawn(function()
	ReplicatedStorage:WaitForChild("CrossingAssets", 60)
	findSounds()
end)

-- ===== Each frame =====

local slow = 0
local lastS = 1
local gustReady = true

RunService.RenderStepped:Connect(function(dt)
	frame += 1
	local t = workspace:GetServerTimeNow()
	local here = camera.CFrame.Position
	table.clear(moveParts)
	table.clear(moveTo)
	for i = #list, 1, -1 do
		local it = list[i]
		if not it.model.Parent then
			items[it.model] = nil
			table.remove(list, i)
		else
			if not it.ready then
				collect(it)
			end
			if it.ready then
				local d = (it.anchor - here).Magnitude
				local every = if d < NEAR then 1 elseif d < FAR then 4 else 0
				if every > 0 and (frame + i) % every == 0 then
					if it.parts[1].Parent then
						update(it, t, dt * every)
					else
						it.ready = false
					end
				end
			end
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveTo, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local s = Wind.strength(t, here)
	-- a few times a second: Roblox's wind, how exposed you are, the sound
	slow += dt
	if slow > 0.25 then
		slow = 0
		workspace.GlobalWind = Wind.DIR * (8 + 20 * s)
		-- out west (over the crossing and the town), and not under cover
		local out = here.X < -40 and here.Y > -150
		if out then
			local char = player.Character
			rayParams.FilterDescendantsInstances = { camera, char }
			if workspace:Raycast(here, UP * 60, rayParams) then
				out = false
			end
		end
		local height = math.clamp((here.Y + 60) / 260, 0.3, 1)
		exposure += ((if out then height else 0) - exposure) * 0.35
		if loop then
			loop.Volume = exposure * (0.12 + 0.3 * math.min(s, 1.8))
			loop.PlaybackSpeed = 0.9 + 0.12 * math.min(s, 1.8)
		end
		if gust then
			if s > 1.35 and lastS <= 1.35 and gustReady and exposure > 0.3 then
				gust.Volume = exposure * 0.5
				gust:Play()
				gustReady = false
			elseif s < 1 then
				gustReady = true
			end
		end
		lastS = s
	end
	-- streaks of air, upwind of you and blowing past
	local pos = here - Wind.DIR * 45 + UP * 4
	air.CFrame = CFrame.fromMatrix(pos, Wind.DIR, UP)
	streaks.Rate = exposure * 10 * s
	streaks.Speed = NumberRange.new(40 * s + 20, 55 * s + 25)
	-- litter
	for k, sc in ipairs(scraps) do
		if sc.life <= 0 then
			if exposure > 0.25 and math.random() < dt * 0.6 * exposure * s then
				place(sc, here, s)
			else
				sc.part.Transparency = 1
				continue
			end
		end
		sc.life -= dt
		local lift = math.sin(t * 1.7 + sc.seed) * 3 + math.sin(t * 4.1 + sc.seed * 2) * 1.5
		sc.pos += (Wind.DIR * (12 + 18 * s) + UP * lift) * dt
		local spin = t * (3 + 3 * s) + sc.seed
		sc.part.CFrame = CFrame.new(sc.pos) * CFrame.fromAxisAngle(sc.spin, spin) * CFrame.Angles(math.sin(t * 5 + k) * 0.6, 0, 0)
		if sc.life <= 0 or (sc.pos - here).Magnitude > 110 then
			sc.life = 0
			sc.part.Transparency = 1
		end
	end
end)
