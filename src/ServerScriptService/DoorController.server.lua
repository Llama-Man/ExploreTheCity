-- Opens/closes every model tagged "SlidingDoor" when its ProximityPrompt is
-- triggered. Each door stores its slide as a SlideVector plus the fraction
-- it started open at, so its closed/open positions are worked out from
-- wherever it actually ended up (floors are moved after being built).

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local SLIDE_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function setupDoor(door)
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	local slide = door:GetAttribute("SlideVector")
	if not prompt or not slide then
		return
	end

	local closedPivot = door:GetPivot() - slide * (door:GetAttribute("OpenFraction") or 0)
	local openPivot = closedPivot + slide

	-- Models can't be tweened directly, so tween a CFrameValue and follow it.
	local driver = Instance.new("CFrameValue")
	driver.Value = door:GetPivot()
	driver.Changed:Connect(function(cframe)
		door:PivotTo(cframe)
	end)

	local busy = false
	prompt.Triggered:Connect(function()
		if busy then
			return
		end
		busy = true
		local opening = not door:GetAttribute("IsOpen")
		prompt.Enabled = false

		local tween = TweenService:Create(driver, SLIDE_INFO, { Value = if opening then openPivot else closedPivot })
		tween:Play()
		tween.Completed:Wait()

		door:SetAttribute("IsOpen", opening)
		prompt.ActionText = if opening then "Close" else "Open"
		prompt.Enabled = true
		busy = false
	end)
end

for _, door in CollectionService:GetTagged("SlidingDoor") do
	setupDoor(door)
end
CollectionService:GetInstanceAddedSignal("SlidingDoor"):Connect(setupDoor)
