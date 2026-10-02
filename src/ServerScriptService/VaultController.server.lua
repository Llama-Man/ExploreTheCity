-- The vault door at the bottom of the facility, and what's behind it.
--
-- Holding E at the door plays the opening: the red handwheel spins, the
-- locking bolts round the rim draw in, the door eases out of its frame
-- and swings wide on its hinge.
--
-- The first player to walk out onto the platform over the hidden sea
-- brings the lights up: every floodlight tagged SeaLight switches on in
-- turn, nearest first (its "Order" attribute), marching away across the
-- water. It happens once per server.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local function smooth(t)
	return t * t * (3 - 2 * t)
end

-- Run `step(alpha)` over `duration` seconds, alpha going 0 -> 1.
local function animate(duration, step)
	local start = os.clock()
	while true do
		local t = math.min((os.clock() - start) / duration, 1)
		step(t)
		if t >= 1 then
			break
		end
		task.wait()
	end
end

local function openVault(door)
	if door:GetAttribute("Opened") then
		return
	end
	door:SetAttribute("Opened", true)
	local disc = door:FindFirstChild("Door")
	local prompt = disc and disc:FindFirstChildWhichIsA("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end
	local center = disc.Position
	local outward = door:GetAttribute("Outward") or -disc.CFrame.RightVector

	-- 1. The handwheel spins.
	local wheel = door:FindFirstChild("Wheel")
	local wheelParts = {}
	for _, p in ipairs(wheel and wheel:GetChildren() or {}) do
		if p:IsA("BasePart") then
			wheelParts[p] = p.CFrame
		end
	end
	animate(1.8, function(t)
		local spin = CFrame.new(center) * CFrame.fromAxisAngle(outward, smooth(t) * math.pi * 3) * CFrame.new(-center)
		for p, cf in pairs(wheelParts) do
			p.CFrame = spin * cf
		end
	end)
	task.wait(0.2)

	-- 2. The bolts draw in.
	local bolts = {}
	for _, p in ipairs(door:GetChildren()) do
		if p.Name == "Bolt" and p:IsA("BasePart") then
			local inward = center - p.Position
			inward = (inward - outward * inward:Dot(outward)).Unit
			bolts[p] = { p.CFrame, inward }
		end
	end
	animate(0.7, function(t)
		for p, b in pairs(bolts) do
			p.CFrame = b[1] + b[2] * 1.4 * smooth(t)
		end
	end)
	task.wait(0.4)

	-- 3. It eases out of the frame...
	local closed = door:GetPivot()
	animate(1.2, function(t)
		door:PivotTo(closed + outward * 1.6 * smooth(t))
	end)
	local pulled = door:GetPivot()

	-- 4. ...and swings wide, whichever way takes it out into the hall.
	local hingeAt = pulled.Position
	local function swungTo(angle)
		return CFrame.new(hingeAt) * CFrame.Angles(0, angle, 0) * CFrame.new(-hingeAt) * pulled
	end
	local sign = 1
	local testCenter = (swungTo(math.rad(30)) * pulled:ToObjectSpace(disc.CFrame)).Position
	if (testCenter - disc.Position):Dot(outward) < 0 then
		sign = -1
	end
	animate(4.5, function(t)
		door:PivotTo(swungTo(sign * math.rad(105) * smooth(t)))
	end)
end

local function hookDoor(door)
	local disc = door:WaitForChild("Door", 10)
	local prompt = disc and disc:FindFirstChildWhichIsA("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function()
			task.spawn(openVault, door)
		end)
	end
end

-- ===== The lights over the sea =====

local revealed = false

local function reveal()
	if revealed then
		return
	end
	revealed = true
	local lights = CollectionService:GetTagged("SeaLight")
	table.sort(lights, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)
	task.wait(1.2) -- a moment in the dark first
	for i, lens in ipairs(lights) do
		lens.Material = Enum.Material.Neon
		lens.Color = Color3.fromRGB(255, 244, 222)
		local light = lens:FindFirstChildWhichIsA("Light")
		if light then
			light.Enabled = true
		end
		-- Pairs come on together (the two sides of each pillar); a beat
		-- between pairs.
		if i % 2 == 0 then
			task.wait(0.32)
		end
	end
end

local function hookTrigger(trigger)
	trigger.Touched:Connect(function(hit)
		if revealed then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		if character and Players:GetPlayerFromCharacter(character) then
			task.spawn(reveal)
		end
	end)
end

for _, door in ipairs(CollectionService:GetTagged("VaultDoor")) do
	task.spawn(hookDoor, door)
end
CollectionService:GetInstanceAddedSignal("VaultDoor"):Connect(function(door)
	task.spawn(hookDoor, door)
end)
for _, trigger in ipairs(CollectionService:GetTagged("SeaRevealTrigger")) do
	hookTrigger(trigger)
end
CollectionService:GetInstanceAddedSignal("SeaRevealTrigger"):Connect(hookTrigger)
