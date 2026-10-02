-- The moves the west crossing (WestCrossing.lua) is built for, run on each
-- player's own machine for their own character:
--
--   ZipLine    a model tagged ZipLine, attributes From and To (Vector3, the
--              cable's ends) and a ProximityPrompt in it: press it and you
--              ride the cable down, hanging from a trolley; jump to let go.
--   SwingRope  a model tagged SwingRope, attributes Pivot (Vector3),
--              Length, Dir (horizontal Vector3, the way it swings), Amp
--              (radians) and Period: it swings on its own; jump into its
--              end to grab on, jump again to let go and fly.
--   Crumble    a part tagged Crumble: step on it and it shakes, gives way,
--              and comes back a while later.
--   SteamJet   a part tagged SteamJet (an invisible box round a vent),
--              attributes Period, OnTime, Offset, Push (Vector3), Mode:
--              "blast" (steam: it hisses, then blasts, and for as long as
--              you're in it you're driven along with it) or "wind" (fans:
--              gusts that keep pushing you while they blow).
--   Bounce     a part tagged Bounce, attribute Launch (Vector3): step on it
--              and you're fired off with that velocity.
--
-- And falling into the fog out west ends quickly: you're gone once you're
-- well down in it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local UP = Vector3.yAxis
local HANG = 3.1 -- how far below the cable/rope your middle hangs

local function body()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum and hum.Health > 0 then
		return char, hrp, hum
	end
	return nil
end

-- ===== Holding on (zip lines and ropes share this) =====

local holding = nil -- { kind, release = fn(velocity) }
local letGo = false
UserInputService.JumpRequest:Connect(function()
	if holding then
		letGo = true
	end
end)

local function hold(hum)
	hum.PlatformStand = true
	hum.AutoRotate = false
end

local function unhold(hum)
	hum.PlatformStand = false
	hum.AutoRotate = true
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
end

-- ===== Zip lines =====

local function ride(zip)
	local _, hrp, hum = body()
	if not hrp or holding then
		return
	end
	local a, b = zip:GetAttribute("From"), zip:GetAttribute("To")
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		return
	end
	local dir = (b - a).Unit
	local len = (b - a).Magnitude
	local d = math.clamp((hrp.Position - a):Dot(dir), 0, len - 3)
	local speed = 18
	holding = { kind = "zip" }
	letGo = false
	hold(hum)
	-- a trolley on the cable, over your head, just for you
	local trolley = Instance.new("Part")
	trolley.Name = "Trolley"
	trolley.Size = Vector3.new(0.8, 0.8, 1.8)
	trolley.Material = Enum.Material.Metal
	trolley.Color = Color3.fromRGB(200, 170, 40)
	trolley.Anchored = true
	trolley.CanCollide = false
	trolley.CanQuery = false
	trolley.Parent = workspace
	local flat = Vector3.new(dir.X, 0, dir.Z).Unit
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local alive = body()
		speed = math.min(speed + 22 * dt, 55)
		d += speed * dt
		local cable = a + dir * math.min(d, len)
		trolley.CFrame = CFrame.lookAt(cable, cable + dir)
		if not alive or letGo or d >= len - 1 then
			conn:Disconnect()
			trolley:Destroy()
			holding = nil
			if alive then
				unhold(hum)
				hrp.AssemblyLinearVelocity = dir * speed * (if d >= len - 1 then 0.25 else 0.8) + UP * 6
			end
			return
		end
		local p = cable - UP * HANG
		hrp.CFrame = CFrame.lookAt(p, p + flat)
		hrp.AssemblyLinearVelocity = dir * speed
	end)
end

-- (Any prompt at all: a zip line's prompt can load in after its model.)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	local node = prompt.Parent
	while node and node ~= workspace do
		if CollectionService:HasTag(node, "ZipLine") then
			ride(node)
			return
		end
		node = node.Parent
	end
end)

-- ===== Swinging ropes =====

local ropes = {}

local function addRope(m)
	local pivot = m:GetAttribute("Pivot")
	if typeof(pivot) ~= "Vector3" then
		return
	end
	local dir = m:GetAttribute("Dir") or Vector3.xAxis
	table.insert(ropes, {
		model = m,
		pivot = pivot,
		len = m:GetAttribute("Length") or 24,
		dir = Vector3.new(dir.X, 0, dir.Z).Unit,
		amp = m:GetAttribute("Amp") or 0.4,
		omega = 2 * math.pi / (m:GetAttribute("Period") or 3),
		base = if typeof(m:GetAttribute("Rest")) == "CFrame" then m:GetAttribute("Rest") else m:GetPivot(),
	})
end

local function ropeAngle(r, t)
	return r.amp * math.sin(r.omega * t)
end

local function ropeEnd(r, theta)
	return r.pivot + r.dir * (math.sin(theta) * r.len) - UP * (math.cos(theta) * r.len)
end

local ropeHeld = nil
local regrabAfter = 0

local function grab(r)
	local _, hrp, hum = body()
	holding = { kind = "rope" }
	ropeHeld = r
	letGo = false
	hold(hum)
end

-- ===== Crumbling bits =====

local crumbling = {}

local function crumble(p)
	if crumbling[p] then
		return
	end
	crumbling[p] = true
	local home = p.CFrame
	task.spawn(function()
		for _ = 1, 10 do
			p.CFrame = home * CFrame.new(math.random() * 0.2 - 0.1, math.random() * 0.1, math.random() * 0.2 - 0.1)
			task.wait(0.06)
		end
		p.CanCollide = false
		for k = 1, 20 do
			p.CFrame = home * CFrame.new(0, -k * k * 0.12, 0) * CFrame.Angles(k * 0.02, 0, k * 0.015)
			p.Transparency = math.min(1, k / 20)
			task.wait(0.03)
		end
		task.wait(5)
		p.CFrame = home
		p.Transparency = p:GetAttribute("BaseTransparency") or 0
		p.CanCollide = true
		crumbling[p] = nil
	end)
end

local function watchCrumble(p)
	p:SetAttribute("BaseTransparency", p.Transparency)
	p.Touched:Connect(function(hit)
		local char = player.Character
		if char and hit:IsDescendantOf(char) then
			crumble(p)
		end
	end)
end

-- ===== Steam =====

local jets = {}

local function addJet(p)
	local e = p:FindFirstChildWhichIsA("ParticleEmitter")
	table.insert(jets, { part = p, emitter = e, period = p:GetAttribute("Period") or 4, on = p:GetAttribute("OnTime") or 1, offset = p:GetAttribute("Offset") or 0, push = p:GetAttribute("Push") or Vector3.new(40, 10, 0), wind = p:GetAttribute("Mode") == "wind" })
end

local function inside(p, pos)
	local q = p.CFrame:PointToObjectSpace(pos)
	local h = p.Size / 2
	return math.abs(q.X) <= h.X and math.abs(q.Y) <= h.Y and math.abs(q.Z) <= h.Z
end

-- ===== Launch pads =====

local launchedAt = 0
local function watchBounce(p)
	p.Touched:Connect(function(hit)
		local char = player.Character
		local _, hrp = body()
		local now = os.clock()
		if hrp and char and hit:IsDescendantOf(char) and now - launchedAt > 0.6 and not holding then
			launchedAt = now
			hrp.AssemblyLinearVelocity = p:GetAttribute("Launch") or Vector3.new(0, 90, 0)
			local s = p:FindFirstChildWhichIsA("Sound")
			if s then
				s:Play()
			end
		end
	end)
end

-- ===== Hooking things up =====

for _, p in ipairs(CollectionService:GetTagged("Bounce")) do
	watchBounce(p)
end
CollectionService:GetInstanceAddedSignal("Bounce"):Connect(watchBounce)

for _, m in ipairs(CollectionService:GetTagged("SwingRope")) do
	addRope(m)
end
CollectionService:GetInstanceAddedSignal("SwingRope"):Connect(addRope)
for _, p in ipairs(CollectionService:GetTagged("Crumble")) do
	watchCrumble(p)
end
CollectionService:GetInstanceAddedSignal("Crumble"):Connect(watchCrumble)
for _, p in ipairs(CollectionService:GetTagged("SteamJet")) do
	addJet(p)
end
CollectionService:GetInstanceAddedSignal("SteamJet"):Connect(addJet)

player.CharacterAdded:Connect(function()
	holding, ropeHeld, letGo = nil, nil, false
end)

RunService.Heartbeat:Connect(function(dt)
	-- (the server's clock, so ropes and vents are in time for everyone)
	local t = workspace:GetServerTimeNow()
	local _, hrp, hum = body()
	-- Ropes swing (near enough to see); grab one by jumping into its end.
	for i = #ropes, 1, -1 do
		local r = ropes[i]
		if not r.model.Parent then
			table.remove(ropes, i)
		elseif hrp and (hrp.Position - r.pivot).Magnitude < 400 then
			local theta = ropeAngle(r, t)
			local axis = r.dir:Cross(UP)
			r.model:PivotTo(CFrame.new(r.pivot) * CFrame.fromAxisAngle(axis, theta) * CFrame.new(-r.pivot) * r.base)
			local tip = ropeEnd(r, theta)
			if ropeHeld == r then
				local p = tip - UP * 0.4
				hrp.CFrame = CFrame.lookAt(p, p + r.dir)
				hrp.AssemblyLinearVelocity = Vector3.zero
				if letGo then
					-- off with the rope's own speed, and a little lift
					local dtheta = r.amp * r.omega * math.cos(r.omega * t)
					local vel = (r.dir * math.cos(theta) + UP * math.sin(theta)) * (dtheta * r.len)
					ropeHeld, holding = nil, nil
					regrabAfter = t + 0.6
					unhold(hum)
					hrp.AssemblyLinearVelocity = vel + UP * 14
				end
			elseif not holding and hum and t > regrabAfter and hum.FloorMaterial == Enum.Material.Air and (hrp.Position - tip).Magnitude < 3.2 then
				grab(r)
			end
		end
	end
	-- Steam: a hiss before, then the blast.
	for _, j in ipairs(jets) do
		local phase = (t + j.offset) % j.period
		local blasting = phase < j.on
		local hissing = phase > j.period - 0.9
		if j.emitter then
			j.emitter.Rate = if j.wind then (if blasting then 14 else 0) elseif blasting then 90 elseif hissing then 8 else 0
		end
		if blasting and hrp and not holding and inside(j.part, hrp.Position) then
			local v = hrp.AssemblyLinearVelocity
			if j.wind then
				-- a gust: it carries you along while it blows (walk into it
				-- and you can hold your ground; stand there and you go)
				local drift = Vector3.new(j.push.X, 0, j.push.Z)
				local ramp = math.clamp(phase / 0.4, 0, 1)
				hrp.CFrame += drift.Unit * math.min(drift.Magnitude / 10, 12) * ramp * dt
			else
				-- steam: while you're in it, you go where it goes
				local push = Vector3.new(j.push.X, 0, j.push.Z)
				local along = v:Dot(push.Unit)
				local keep = v - push.Unit * along
				hrp.AssemblyLinearVelocity = keep * 0.4 + push.Unit * math.max(along, push.Magnitude) + Vector3.new(0, math.max(v.Y, j.push.Y * 0.5), 0)
			end
		end
	end
	-- Into the fog out west: gone.
	if hrp and hrp.Position.X < -40 and hrp.Position.Y < -400 then
		hum.Health = 0
	end
end)
