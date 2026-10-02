-- Moving things, on each player's machine, all on the server's clock
-- (GetServerTimeNow) so everyone sees each one in the same place.
--
-- Models tagged "Mover", by their Motion attribute:
--   "swing"   Pivot (Vector3), Axis (Vector3), Amp (radians), Period (s)
--   "slide"   Delta (Vector3), Period (s), Dwell (0..0.45, the share of
--             each end it waits at): out along Delta and back, easing
--   "rotate"  Pivot, Axis, Speed (radians a second)
--   Phase (0..1) offsets any of them. Rest (CFrame) is where the server
--   built it.
-- Every part is placed from where it was built (its offset from Rest),
-- not by moving the model as a whole: with streaming, parts can arrive
-- late, and they'd be left behind in the wrong place otherwise.
-- If you're standing on one, you go with it. Parts in one tagged "Knock"
-- fling you when they hit you: off the way that bit of them was going,
-- and up, and for a moment you can't do anything about it.
--
-- Parts tagged "Blink" come and go: Period (s), On (the share of it
-- they're there), Offset (0..1); they flicker just before they go.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local NEAR = 700
local UP = Vector3.yAxis

local movers = {}
local list = {}
local models = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function refreshRay()
	rayParams.FilterDescendantsInstances = models
end

local function track(mv, d)
	if d:IsA("BasePart") then
		-- (it's where the server put it when it arrives: at rest)
		mv.parts[d] = mv.rest:ToObjectSpace(d.CFrame)
		if CollectionService:HasTag(d, "Knock") then
			mv.knock[d] = d.CFrame
		end
	end
end

local function add(m)
	if movers[m] or not m:IsA("Model") or not m:GetAttribute("Motion") then
		return
	end
	local rest = m:GetAttribute("Rest")
	if typeof(rest) ~= "CFrame" then
		rest = m:GetPivot()
	end
	local mv = { model = m, rest = rest, pose = rest, parts = {}, knock = {} }
	movers[m] = mv
	table.insert(list, mv)
	for _, d in ipairs(m:GetDescendants()) do
		track(mv, d)
	end
	m.DescendantAdded:Connect(function(d)
		track(mv, d)
	end)
	m.DescendantRemoving:Connect(function(d)
		mv.parts[d] = nil
		mv.knock[d] = nil
	end)
	table.insert(models, m)
	refreshRay()
end

for _, m in ipairs(CollectionService:GetTagged("Mover")) do
	add(m)
end
CollectionService:GetInstanceAddedSignal("Mover"):Connect(add)

local blinks = {}
local function addBlink(p)
	if p:IsA("BasePart") then
		table.insert(blinks, { part = p, base = p.Transparency, solid = p.CanCollide, lights = p:GetDescendants() })
	end
end
for _, p in ipairs(CollectionService:GetTagged("Blink")) do
	addBlink(p)
end
CollectionService:GetInstanceAddedSignal("Blink"):Connect(addBlink)

local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function poseAt(mv, t)
	local m = mv.model
	local period = m:GetAttribute("Period") or 6
	local phase = m:GetAttribute("Phase") or 0
	local motion = m:GetAttribute("Motion")
	if motion == "swing" then
		local pivot = m:GetAttribute("Pivot")
		local axis = m:GetAttribute("Axis") or Vector3.xAxis
		local amp = m:GetAttribute("Amp") or 0.3
		local theta = amp * math.sin((t / period + phase) * math.pi * 2)
		return CFrame.new(pivot) * CFrame.fromAxisAngle(axis.Unit, theta) * CFrame.new(-pivot) * mv.rest
	elseif motion == "rotate" then
		local pivot = m:GetAttribute("Pivot")
		local axis = m:GetAttribute("Axis") or UP
		local theta = (m:GetAttribute("Speed") or 1) * t + phase * math.pi * 2
		return CFrame.new(pivot) * CFrame.fromAxisAngle(axis.Unit, theta % (math.pi * 2)) * CFrame.new(-pivot) * mv.rest
	elseif motion == "slide" then
		local delta = m:GetAttribute("Delta") or Vector3.zero
		local dwell = m:GetAttribute("Dwell") or 0.2
		local u = (t / period + phase) % 1
		local tri = if u < 0.5 then u * 2 else (1 - u) * 2
		return mv.rest + delta * smooth((tri - dwell) / (1 - 2 * dwell))
	end
	return mv.rest
end

local function standingOn(hrp, hum)
	local reach = hum.HipHeight + hrp.Size.Y / 2 + 1.6
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -reach, 0), rayParams)
	if not hit then
		return nil
	end
	local node = hit.Instance
	while node and node ~= workspace do
		if movers[node] then
			return movers[node]
		end
		node = node.Parent
	end
	return nil
end

local knockedUntil = 0

RunService.PreSimulation:Connect(function(dt)
	local t = workspace:GetServerTimeNow()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local alive = hrp and hum and hum.Health > 0
	local camera = workspace.CurrentCamera
	local here = if camera then camera.CFrame.Position else Vector3.zero
	local riding = if alive and hum.FloorMaterial ~= Enum.Material.Air then standingOn(hrp, hum) else nil
	for i = #list, 1, -1 do
		local mv = list[i]
		if not mv.model.Parent then
			table.remove(list, i)
			movers[mv.model] = nil
			local idx = table.find(models, mv.model)
			if idx then
				table.remove(models, idx)
			end
			refreshRay()
		elseif mv == riding or (mv.rest.Position - here).Magnitude < NEAR then
			local pose = poseAt(mv, t)
			if mv == riding then
				-- carry you by however it moved, staying upright
				local moved = pose * mv.pose:Inverse()
				local p = moved * hrp.Position
				local look = moved:VectorToWorldSpace(hrp.CFrame.LookVector)
				look = Vector3.new(look.X, 0, look.Z)
				if look.Magnitude < 0.01 then
					look = hrp.CFrame.LookVector
				end
				hrp.CFrame = CFrame.lookAt(p, p + look.Unit)
			end
			for p, off in pairs(mv.parts) do
				p.CFrame = pose * off
			end
			mv.pose = pose
			-- knocked by a moving bar, hook or pusher
			if alive then
				for p, was in pairs(mv.knock) do
					local now = p.CFrame
					if t > knockedUntil then
						local q = now:PointToObjectSpace(hrp.Position)
						local h = p.Size / 2 + Vector3.new(1.4, 2.6, 1.4)
						if math.abs(q.X) < h.X and math.abs(q.Y) < h.Y and math.abs(q.Z) < h.Z then
							-- how fast the bit of it that hit you was going
							local at = was:PointToObjectSpace(hrp.Position)
							local vel = (now:PointToWorldSpace(at) - hrp.Position) / math.max(dt, 1 / 240)
							local flat = Vector3.new(vel.X, 0, vel.Z)
							if flat.Magnitude < 1 then
								flat = Vector3.new(hrp.Position.X - now.Position.X, 0, hrp.Position.Z - now.Position.Z)
							end
							if flat.Magnitude < 0.01 then
								flat = Vector3.xAxis
							end
							hrp.AssemblyLinearVelocity = flat.Unit * math.clamp(flat.Magnitude * 1.8, 60, 110) + UP * 36
							-- knocked flying: no steering for a moment
							local knocked = hum
							knocked.PlatformStand = true
							knockedUntil = t + 0.9
							task.delay(0.55, function()
								if knocked.Parent then
									knocked.PlatformStand = false
									knocked:ChangeState(Enum.HumanoidStateType.Freefall)
								end
							end)
						end
					end
					mv.knock[p] = now
				end
			end
		end
	end
	-- the platforms that come and go
	for _, b in ipairs(blinks) do
		local p = b.part
		if p.Parent then
			local period = p:GetAttribute("Period") or 3
			local on = p:GetAttribute("On") or 0.5
			local u = (t / period + (p:GetAttribute("Offset") or 0)) % 1
			local lit = u < on
			if lit then
				p.CanCollide = b.solid
				-- a flicker in the last moment before it goes
				local warn = b.solid and on - u < 0.14 * on
				p.Transparency = if warn and math.floor(t * 12) % 2 == 0 then 0.6 else b.base
			else
				p.CanCollide = false
				p.Transparency = 1
			end
			for _, l in ipairs(b.lights) do
				if l:IsA("Light") then
					l.Enabled = lit
				end
			end
		end
	end
end)
