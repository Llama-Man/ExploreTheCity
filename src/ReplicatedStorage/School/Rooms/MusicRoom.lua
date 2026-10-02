-- Music room: an upright piano in the front corner, chairs in curved rows
-- facing the conductor's spot, music stands, composer portraits along the
-- back wall and instrument cases leaning beneath them.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)
local Weathering = require(School.Weathering)

local part, cylinder, model, place, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.place, BuildUtil.pick
local Smooth, Metal = Enum.Material.SmoothPlastic, Enum.Material.Metal

local PIANO_BLACK = Color3.fromRGB(28, 22, 20)
local CASE_COLORS = { Color3.fromRGB(30, 28, 30), Color3.fromRGB(60, 40, 30), Color3.fromRGB(40, 44, 60) }

-- Upright piano against a wall, keys facing -X.
local function piano(parent, c)
	local m = model(parent, "Piano")
	local body = part(m, "PianoBody", Vector3.new(2.0, 4.4, 5.6), c + Vector3.new(0, 2.2, 0), Smooth, PIANO_BLACK)
	body.Reflectance = 0.05
	part(m, "PianoLid", Vector3.new(2.2, 0.15, 5.8), c + Vector3.new(0, 4.45, 0), Smooth, PIANO_BLACK)
	part(m, "Keybed", Vector3.new(1.3, 0.35, 5.4), c + Vector3.new(-1.6, 2.45, 0), Smooth, PIANO_BLACK)
	part(m, "WhiteKeys", Vector3.new(1.0, 0.12, 5.0), c + Vector3.new(-1.7, 2.68, 0), Smooth, Color3.fromRGB(226, 220, 204))
	local keyW = 5.0 / 17
	for i = 1, 16 do
		local idx = i % 7
		if idx ~= 3 and idx ~= 0 then -- no black key between E-F and B-C
			part(m, "BlackKey", Vector3.new(0.6, 0.12, 0.16), c + Vector3.new(-1.5, 2.8, -2.5 + i * keyW), Smooth, Color3.fromRGB(15, 15, 15))
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		part(m, "PianoLeg", Vector3.new(0.3, 2.3, 0.3), c + Vector3.new(-1.65, 1.15, s * 2.45), Smooth, PIANO_BLACK)
	end
	part(m, "Pedals", Vector3.new(0.5, 0.1, 1.2), c + Vector3.new(-1.2, 0.3, 0), Metal, Color3.fromRGB(176, 150, 80))
	return m
end

local function musicStand(parent, pos, yaw)
	part(parent, "StandBase", Vector3.new(1, 0.1, 1), pos + Vector3.new(0, 0.05, 0), Metal, Color3.fromRGB(40, 40, 42))
	cylinder(parent, "StandPole", 3.4, 0.12, CFrame.new(pos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Metal, Color3.fromRGB(40, 40, 42))
	part(parent, "StandDesk", Vector3.new(0.06, 1.1, 1.7), CFrame.new(pos + Vector3.new(0, 3.7, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(20)), Metal, Color3.fromRGB(40, 40, 42))
end

return function(parent, room, rng)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2

	Props.whiteboard(parent, room, rng, "music")

	local pianoPos = Vector3.new(b.x1 - 1.3, 0, b.z0 + 4.5)
	local p = piano(parent, pianoPos)
	part(parent, "PianoBench", Vector3.new(1.4, 1.9, 3), pianoPos + Vector3.new(-3.6, 0.95, rng:NextNumber(-0.5, 0.5)), Smooth, PIANO_BLACK)
	if rng:NextNumber() < room.mess * 0.6 then
		Weathering.dustSheet(parent, p, rng)
	end

	-- Chairs in curved rows around the conductor's podium.
	local conductor = Vector3.new(b.x1 - 7, 0, zMid)
	part(parent, "Podium", Vector3.new(3, 0.5, 3), conductor + Vector3.new(0, 0.25, 0), Enum.Material.Wood, room.trim)
	local chairColor = BuildUtil.jitter(Props.DESK_TOP_COLOR, rng, 0.05)
	for ring = 1, 3 do
		local radius = 7 + ring * 4.5
		local n = math.max(3, math.floor(radius * math.rad(110) / 3.3))
		for k = 1, n do
			local a = math.rad(-55) + (k - 0.5) / n * math.rad(110)
			local pos = conductor + Vector3.new(-math.cos(a) * radius, 0, math.sin(a) * radius)
			if pos.Z > b.z0 + 2 and pos.Z < b.z1 - 3 and pos.X > b.x0 + 3 and rng:NextNumber() > 0.1 + room.mess * 0.1 then
				local dir = conductor - pos
				local yaw = math.atan2(-dir.Z, dir.X)
				local chair = Props.studentChair(parent, pos, chairColor)
				if rng:NextNumber() < room.mess * 0.2 then
					Props.tipChair(chair, pos, yaw + rng:NextNumber(-0.5, 0.5))
				else
					place(chair, pos, Vector3.new(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3)), yaw + math.rad(rng:NextNumber(-10, 10)))
				end
				if rng:NextNumber() < 0.35 then
					musicStand(parent, pos + dir.Unit * 2, yaw)
				end
			end
		end
	end

	Props.frames(parent, "Z", b.x0, 1, zMid, 5, 6, 9.6, Vector2.new(2.4, 3), rng)

	for _ = 1, rng:NextInteger(3, 6) do
		local depth, height, width = rng:NextNumber(0.8, 1.4), rng:NextNumber(1.2, 3.8), rng:NextNumber(1.2, 3.5)
		local z = rng:NextNumber(b.z0 + 3, b.z1 - 5)
		local lean = CFrame.Angles(0, 0, math.rad(rng:NextNumber(0, 10)))
		part(parent, "InstrumentCase", Vector3.new(depth, height, width), CFrame.new(b.x0 + 0.5 + depth / 2, height / 2, z) * lean, Smooth, pick(CASE_COLORS, rng))
	end
	local drumPos = Vector3.new(b.x0 + 3, 0, b.z1 - 7)
	cylinder(parent, "Drum", 1.6, 2.4, CFrame.new(drumPos + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(150, 40, 36))
	BuildUtil.disc(parent, "DrumHead", 2.3, 0.05, drumPos + Vector3.new(0, 1.62, 0), Enum.Material.Fabric, Color3.fromRGB(230, 226, 214))
end
