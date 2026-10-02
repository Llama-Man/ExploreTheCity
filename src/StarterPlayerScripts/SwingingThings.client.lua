-- Things hung on ropes that sway a little: the cage and the kibble in the
-- chasm, and anything else tagged "Swing". Each is a model with a
-- SwingPivot attribute (the point it hangs from), SwingDegrees (how far
-- it swings) and SwingPeriod (seconds per swing). They're moved here, on
-- each player's machine, only while you're near enough to see them.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local NEAR = 700

local swings = {}

local function add(m)
	if not m:IsA("Model") then
		return
	end
	local pivot = m:GetAttribute("SwingPivot")
	if typeof(pivot) ~= "Vector3" then
		return
	end
	local top = CFrame.new(pivot)
	table.insert(swings, {
		model = m,
		top = top,
		offset = top:ToObjectSpace(m:GetPivot()),
		amp = math.rad(m:GetAttribute("SwingDegrees") or 1),
		omega = 2 * math.pi / math.max(0.5, m:GetAttribute("SwingPeriod") or 5),
		phase = math.random() * 10,
	})
end

for _, m in ipairs(CollectionService:GetTagged("Swing")) do
	add(m)
end
CollectionService:GetInstanceAddedSignal("Swing"):Connect(add)

RunService.Heartbeat:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local t = os.clock()
	local here = camera.CFrame.Position
	for i = #swings, 1, -1 do
		local s = swings[i]
		if not s.model.Parent then
			table.remove(swings, i)
		elseif (here - s.top.Position).Magnitude < NEAR then
			-- Two slightly different swings at right angles, so it wanders in
			-- a slow ellipse rather than ticking back and forth; a slight turn.
			local a = s.amp * math.sin(s.omega * t + s.phase)
			local b = s.amp * 0.6 * math.sin(s.omega * 1.07 * t + s.phase * 1.7)
			local turn = s.amp * 0.8 * math.sin(s.omega * 0.31 * t + s.phase)
			s.model:PivotTo(s.top * CFrame.Angles(a, turn, b) * s.offset)
		end
	end
end)
