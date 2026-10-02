-- Props that come from outside the code: models you've put in the place
-- yourself (from the Toolbox, or your own), and mannequins built from
-- Roblox's own character rig.
--
-- To use your own model for something, make a Folder in ServerStorage
-- called PropLibrary, a Folder inside it named for the kind (Mannequin,
-- Sofa, Bed, Plush, Plant) and drop one or more Models into that. The
-- generator picks one at random, strips out any scripts and sounds,
-- anchors it, scales it to the size the spot wants and sets it down on
-- the floor. With nothing there it builds its own. (ServerStorage isn't
-- part of the Rojo project, so what you put there is saved with the
-- place file, not in this folder.)

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local PropLibrary = {}

-- Anything that could run or make noise comes out; everything that's
-- left stays put.
local function sanitise(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
end

-- Scale `m` so it's `height` tall (and no wider than `footprint`, if
-- given), then set its bottom centre down at `cf`, upright in cf's frame.
function PropLibrary.fit(m, cf, height, footprint)
	local _, size = m:GetBoundingBox()
	if size.Y <= 0 then
		return
	end
	local k = if height then height / size.Y else 1
	if footprint then
		k = math.min(k, footprint / math.max(size.X, size.Z))
	end
	if math.abs(k - 1) > 0.01 then
		m:ScaleTo(m:GetScale() * k)
	end
	local box, s = m:GetBoundingBox()
	local pivot = m:GetPivot()
	local bottom = CFrame.new((box * CFrame.new(0, -s.Y / 2, 0)).Position) * pivot.Rotation
	m:PivotTo(cf * bottom:ToObjectSpace(pivot))
end

-- A clean copy of one of your models of this kind, or nil.
function PropLibrary.take(kind, rng)
	local lib = ServerStorage:FindFirstChild("PropLibrary")
	local folder = lib and lib:FindFirstChild(kind)
	if not folder then
		return nil
	end
	local options = {}
	if folder:IsA("Model") then
		options = { folder }
	else
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("Model") or c:IsA("BasePart") then
				table.insert(options, c)
			end
		end
	end
	if #options == 0 then
		return nil
	end
	local copy = options[rng:NextInteger(1, #options)]:Clone()
	if not copy then
		return nil -- not Archivable
	end
	if copy:IsA("BasePart") then
		local holder = Instance.new("Model")
		holder.Name = copy.Name
		copy.Parent = holder
		copy = holder
	end
	sanitise(copy)
	return copy
end

-- One of your models of this kind, fitted to the spot, or nil.
function PropLibrary.place(parent, kind, cf, rng, height, footprint)
	local m = PropLibrary.take(kind, rng)
	if not m then
		return nil
	end
	m.Parent = parent
	local ok, err = pcall(PropLibrary.fit, m, cf, height, footprint)
	if not ok then
		warn("[PropLibrary] couldn't place a " .. kind .. ": " .. tostring(err))
		m:Destroy()
		return nil
	end
	return m
end

-- ===== Mannequins from the character rig =====

PropLibrary.BODY = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local rigTemplate -- the blank figure; false if it couldn't be built

local function buildRig()
	local d = Instance.new("HumanoidDescription")
	d.HeightScale = 1.05
	d.WidthScale = 0.88
	d.DepthScale = 0.9
	d.HeadScale = 0.92
	local rig = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	for _, x in ipairs(rig:GetDescendants()) do
		if x:IsA("LuaSourceContainer") or x:IsA("Decal") or x:IsA("BodyColors") or x:IsA("Accessory") then
			x:Destroy()
		end
	end
	rig.Name = "Mannequin"
	return rig
end

-- A fresh, faceless, uncoloured R15 figure (still jointed, so it can be
-- posed), or nil if the rig couldn't be made.
function PropLibrary.rig()
	if rigTemplate == nil then
		local ok, rig = pcall(buildRig)
		rigTemplate = if ok then rig else false
		if not ok then
			warn("[PropLibrary] couldn't build a mannequin rig, using dress forms: " .. tostring(rig))
		end
	end
	return if rigTemplate then rigTemplate:Clone() else nil
end

-- Pose a rig from PropLibrary.rig(): `angles` maps joint names (Neck,
-- Waist, LeftShoulder, RightElbow, LeftHip, RightKnee, ...) to rotations
-- in the joint. The figure is then frozen: joints, Humanoid and root part
-- removed, everything anchored.
function PropLibrary.pose(rig, angles)
	local root = rig:FindFirstChild("HumanoidRootPart")
	local motors = {}
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("Motor6D") then
			table.insert(motors, d)
		end
	end
	local done = {}
	if root then
		done[root] = true
	end
	local progress = true
	while progress do
		progress = false
		for _, j in ipairs(motors) do
			local p0, p1 = j.Part0, j.Part1
			if p0 and p1 and done[p0] and not done[p1] then
				p1.CFrame = p0.CFrame * j.C0 * (angles[j.Name] or CFrame.identity) * j.C1:Inverse()
				done[p1] = true
				progress = true
			end
		end
	end
	for _, j in ipairs(motors) do
		j:Destroy()
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:Destroy()
	end
	if root then
		root:Destroy()
	end
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

return PropLibrary
