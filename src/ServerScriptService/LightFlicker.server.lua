-- Makes ceiling lights tagged "FlickerLight" stutter now and then, with the
-- occasional longer blackout.

local CollectionService = game:GetService("CollectionService")

local function flicker(fixture)
	local light = fixture:FindFirstChildWhichIsA("Light", true)
	if not light then
		return
	end
	local tubes = {}
	for _, child in fixture:GetChildren() do
		if child.Name == "LightTube" then
			table.insert(tubes, child)
		end
	end

	local rng = Random.new()
	local function set(on)
		light.Enabled = on
		for _, tube in tubes do
			tube.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end

	task.spawn(function()
		while fixture.Parent do
			task.wait(rng:NextNumber(1.5, 7))
			for _ = 1, rng:NextInteger(2, 6) do
				set(false)
				task.wait(rng:NextNumber(0.03, 0.15))
				set(true)
				task.wait(rng:NextNumber(0.03, 0.25))
			end
			if rng:NextNumber() < 0.25 then
				set(false)
				task.wait(rng:NextNumber(0.5, 3))
				set(true)
			end
		end
	end)
end

for _, fixture in CollectionService:GetTagged("FlickerLight") do
	flicker(fixture)
end
CollectionService:GetInstanceAddedSignal("FlickerLight"):Connect(flicker)
