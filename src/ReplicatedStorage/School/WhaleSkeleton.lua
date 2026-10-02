-- A huge whale skeleton lying loosely curled on the ground: skull and
-- jawbones at one end, a spine that wanders round in an uneven curve,
-- ribs arching from the spine down to the ground (tall enough to walk
-- under), flipper bones beside the ribcage, and bones that have come
-- loose over time. `opts.scale` multiplies every dimension (1 = ~130 studs
-- nose to tail).

local BuildUtil = require(script.Parent.BuildUtil)

local part, jitter = BuildUtil.part, BuildUtil.jitter

local BONE = Color3.fromRGB(196, 186, 162)
local BONE_DARK = Color3.fromRGB(62, 54, 44)
local BONE_MATERIAL = Enum.Material.Limestone

local WhaleSkeleton = {}

-- Part shown as an ellipsoid of its own size (skull pieces).
local function ellipsoid(parent, name, size, cframe, color)
	local p = part(parent, name, size, cframe, BONE_MATERIAL, color)
	p.CanCollide = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Cylinder bone from a to b. `up` must not be parallel to b - a.
local function bone(parent, a, b, diameter, up, rng)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return nil
	end
	local cf = CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0)
	return BuildUtil.cylinder(parent, "Bone", len + diameter * 0.3, diameter, cf, BONE_MATERIAL, jitter(BONE, rng, 0.08))
end

local function boneChain(parent, points, startDiameter, endDiameter, up, rng)
	for i = 1, #points - 1 do
		local d = startDiameter + (endDiameter - startDiameter) * (i - 1) / math.max(1, #points - 2)
		bone(parent, points[i], points[i + 1], d, up, rng)
	end
end

-- The skull, built from flat plates of bone (not rounded blobs) in a frame
-- where `base` is the back of the skull at ground level, `dir` points
-- forward to the snout and `lat` to the side. A baleen whale's skull seen
-- from above is a long flat triangle: a broad plate of bone sloping up at
-- the back, brow wings drooping over dark eye hollows, and a long snout of
-- two tapering blades (maxillae) with narrow bars (premaxillae) along
-- their inner edges and a groove down the middle.
local function skull(m, base, dir, lat, S, rng)
	local up = Vector3.yAxis
	-- Skull frame: X = to the side, Y = up, -Z = forward toward the snout.
	local frame = CFrame.fromMatrix(base, lat, up, -dir)
	local function at(fwd, side, height)
		return frame * CFrame.new(side * S, height * S, -fwd * S)
	end
	local function plate(name, size, cf, color, material)
		return part(m, name, size * S, cf, material or BONE_MATERIAL, color or jitter(BONE, rng, 0.04))
	end
	local SNOUT_BASE, SNOUT_TIP = 12, 52
	local snoutPitch = CFrame.Angles(math.rad(-2.8), 0, 0) -- tip lower than base

	plate("Braincase", Vector3.new(13, 5, 11), at(4, 0, 2.5))
	plate("OccipitalShield", Vector3.new(15, 1.4, 11), at(2, 0, 5.4) * CFrame.Angles(math.rad(-24), 0, 0))
	plate("FrontalShelf", Vector3.new(10, 1.3, 8), at(9, 0, 5.4))

	for _, side in ipairs({ -1, 1 }) do
		plate("SupraorbitalWing", Vector3.new(8, 1.1, 7), at(9, side * 8.5, 4.9) * CFrame.Angles(0, 0, math.rad(side * -12)))
		plate("EyeHollow", Vector3.new(2.6, 2.4, 3.4), at(9.5, side * 10.5, 2.8), BONE_DARK, Enum.Material.SmoothPlastic)
		bone(m, at(9.5, side * 11.2, 2.2).Position, at(3, side * 6.6, 2.4).Position, 1.1 * S, up, rng)
		BuildUtil.cylinder(m, "Condyle", 2 * S, 2.8 * S, at(-1, side * 2.6, 3) * CFrame.Angles(0, math.pi / 2, 0), BONE_MATERIAL, jitter(BONE, rng, 0.04))
		plate("Naris", Vector3.new(1.4, 0.3, 3.6), at(SNOUT_BASE + 1.5, side * 1.4, 5.5), BONE_DARK, Enum.Material.SmoothPlastic)

		-- Maxilla: a broad flat blade in overlapping sections, narrowing and
		-- dropping toward the tip, its outer edge drooping slightly.
		local sections = 8
		for k = 1, sections do
			local t = (k - 0.5) / sections
			local fwd = SNOUT_BASE + t * (SNOUT_TIP - SNOUT_BASE)
			local width = 1 + 7.5 * (1 - t) ^ 0.9
			local thickness = 2.2 - 1.1 * t
			local lateral = side * (1.1 + width / 2 - 0.4 * t)
			local height = 3.4 - 1.8 * t
			local inward = math.rad(side * (9 * (1 - t) + 1))
			plate("Maxilla", Vector3.new(width, thickness, 5.8), at(fwd, lateral, height) * snoutPitch * CFrame.Angles(0, inward, math.rad(side * -5)))
		end

		-- Premaxilla: narrow bar along the inner edge, standing a little proud.
		bone(m, at(SNOUT_BASE, side * 1.1, 4.5).Position, at(SNOUT_TIP, side * 0.35, 2.1).Position, 1.3 * S, up, rng)
	end
	plate("RostrumTip", Vector3.new(2.4, 1.2, 3), at(SNOUT_TIP + 0.5, 0, 1.8) * snoutPitch)
	plate("MesorostralGroove", Vector3.new(0.9, 0.3, SNOUT_TIP - SNOUT_BASE), at((SNOUT_BASE + SNOUT_TIP) / 2, 0, 3.3) * snoutPitch, BONE_DARK, Enum.Material.SmoothPlastic)
end

-- center: middle of the curl at floor level. opts: scale, phase (angle
-- where the head end starts), sweep (how far the body curls), looseArc
-- ({from, to} angles where loose bones may land).
function WhaleSkeleton.build(parent, center, rng, opts)
	opts = opts or {}
	local S = opts.scale or 1
	local floorY = center.Y
	local radius = 22 * S
	local phase = opts.phase or math.rad(-90)
	local sweep = opts.sweep or math.rad(290)
	local m = BuildUtil.model(parent, "WhaleSkeleton")

	-- Irregular curve: the radius, angle and height all wander a little so
	-- it doesn't read as a perfect spiral.
	local n1, n2, n3 = rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)

	local function heightAt(s)
		local wobble = 0.4 * math.sin(s * 19 + n3)
		if s < 0.12 then
			return (3 + (s / 0.12) * 6.5 + wobble) * S
		elseif s < 0.45 then
			return (9.5 + wobble) * S
		end
		return (1.2 + 8.3 * (1 - (s - 0.45) / 0.55) ^ 1.5 + wobble * 0.5) * S
	end

	local function spinePoint(s)
		local a = phase + s * sweep + 0.12 * math.sin(s * 14.5 + n2)
		local r = radius * (1 - 0.25 * s) * (1 + 0.08 * math.sin(s * 10.7 + n1) + 0.04 * math.sin(s * 27 + n2))
		return Vector3.new(center.X + math.cos(a) * r, floorY + heightAt(s), center.Z + math.sin(a) * r)
	end

	local function frame(s)
		local ahead, behind = spinePoint(math.min(1, s + 0.01)), spinePoint(math.max(0, s - 0.01))
		local tangent = (ahead - behind).Unit
		local flat = Vector3.new(tangent.X, 0, tangent.Z).Unit
		local lateral = Vector3.new(-flat.Z, 0, flat.X)
		return tangent, flat, lateral
	end

	local function ribSpan(s)
		return (5 + 6 * math.sin(math.pi * math.clamp((s - 0.12) / 0.34, 0, 1))) * S
	end

	-- Vertebrae, each slightly out of line; a few have fallen off the spine.
	local count = 58
	for i = 1, count do
		local s = 0.03 + (i - 1) / (count - 1) * 0.97
		local p = spinePoint(s)
		local tangent, flat, lateral = frame(s)
		local k = (if s < 0.5 then 1 else 1 - (s - 0.5) / 0.5 * 0.7) * S

		if rng:NextNumber() < 0.05 then
			local fallen = Vector3.new(p.X, floorY + 1.2 * k, p.Z) + lateral * (if rng:NextNumber() < 0.5 then -1 else 1) * rng:NextNumber(3, 8) * S
			BuildUtil.cylinder(m, "Vertebra", 1.5 * k, 2.6 * k, CFrame.new(fallen) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0), BONE_MATERIAL, jitter(BONE, rng, 0.08))
		else
			local skew = CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.12, 0.12))
			local along = CFrame.lookAt(p + lateral * rng:NextNumber(-0.3, 0.3) * S, p + tangent, Vector3.yAxis) * skew
			BuildUtil.cylinder(m, "Vertebra", 1.5 * k, 2.6 * k, along * CFrame.Angles(0, math.pi / 2, 0), BONE_MATERIAL, jitter(BONE, rng, 0.08))
			if s < 0.85 then
				part(m, "SpinousProcess", Vector3.new(0.35 * k, 3.2 * k, 1.1 * k), along * CFrame.new(0, 2.9 * k, 0) * CFrame.Angles(math.rad(-15), 0, 0), BONE_MATERIAL, jitter(BONE, rng, 0.08))
			end
			if s > 0.1 and s < 0.9 then
				part(m, "TransverseProcess", Vector3.new(5 * k, 0.3 * k, 1.0 * k), along, BONE_MATERIAL, jitter(BONE, rng, 0.08))
			end
		end

		-- Ribs on every other vertebra over the chest, each a little
		-- different; some snapped, some fallen flat on the ground.
		if s > 0.13 and s < 0.44 and i % 2 == 0 then
			local h = p.Y - floorY
			for _, side in ipairs({ -1, 1 }) do
				local span = ribSpan(s) * rng:NextNumber(0.85, 1.12)
				local sweepBack = rng:NextNumber(1.5, 3.5) * S
				local roll = rng:NextNumber()
				if roll < 0.08 then
					local base = Vector3.new(p.X, floorY + 0.4 * S, p.Z) + lateral * side * (span * 0.6 + rng:NextNumber(2, 6) * S)
					local heading = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector
					bone(m, base, base + heading * span * 1.2, 0.7 * S, Vector3.yAxis, rng)
				else
					local broken = roll < 0.22
					local uMax = if broken then rng:NextNumber(0.35, 0.7) else 1
					local points = {}
					for step = 0, 7 do
						local u = step / 7 * uMax
						local out = lateral * side * (1.8 * S + span * math.sin(u * math.pi / 2))
						local back = flat * (sweepBack * u)
						local y = floorY + 0.4 * S + (h - 0.4 * S) * math.cos(u * math.pi / 2) ^ 0.7
						table.insert(points, Vector3.new(p.X, y, p.Z) + out + back)
					end
					boneChain(m, points, 0.8 * S, 0.5 * S, flat, rng)
					if broken then
						local base = Vector3.new(p.X, floorY + 0.35 * S, p.Z) + lateral * side * (span + rng:NextNumber(1, 4) * S)
						bone(m, base, base + flat * rng:NextNumber(3, 6) * S + lateral * side * rng:NextNumber(-2, 2) * S, 0.6 * S, Vector3.yAxis, rng)
					end
				end
			end
		end
	end

	-- Skull, turned a little off the line of the spine.
	local _, headFlat = frame(0)
	local dir = CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0):VectorToWorldSpace(-headFlat)
	local lat = Vector3.new(-dir.Z, 0, dir.X)
	local p0 = spinePoint(0)
	local base = Vector3.new(p0.X, floorY, p0.Z)
	skull(m, base, dir, lat, S, rng)

	-- Jawbones bowing outward from the hinge to the tip, each with a bump
	-- for the coronoid process; one has slipped out of place.
	local up = Vector3.yAxis
	for _, side in ipairs({ -1, 1 }) do
		local slip = if side == 1 then lat * rng:NextNumber(1, 4) * S + dir * rng:NextNumber(-3, 2) * S else Vector3.zero
		local points = {}
		for step = 0, 9 do
			local u = step / 9
			local lateralOffset = side * (6 * (1 - u) + 0.8 * u + 4 * math.sin(u * math.pi)) * S
			table.insert(points, base + dir * (0 + 49 * u) * S + lat * lateralOffset + up * 0.9 * S + slip)
		end
		boneChain(m, points, 2.2 * S, 1.1 * S, up, rng)
		local coronoid = points[3] + up * 1.2 * S
		part(m, "Coronoid", Vector3.new(0.8, 2.4, 3.4) * S, CFrame.lookAt(coronoid, coronoid + dir) * CFrame.Angles(math.rad(-20), 0, 0), BONE_MATERIAL, jitter(BONE, rng, 0.05))
	end

	-- Flipper bones lying spread out beside the ribcage.
	local fs = 0.16
	local fp = spinePoint(fs)
	local _, fFlat, fLateral = frame(fs)
	for _, side in ipairs({ -1, 1 }) do
		local reach = CFrame.Angles(0, math.rad(rng:NextNumber(-15, 15)), 0):VectorToWorldSpace((fLateral * side * 0.7 - fFlat * 0.7).Unit)
		local start = Vector3.new(fp.X, floorY + 0.8 * S, fp.Z) + fLateral * side * (ribSpan(fs) + 3 * S)
		local scapula = start - reach * 2 * S
		ellipsoid(m, "Scapula", Vector3.new(4, 0.8, 5) * S, CFrame.lookAt(scapula, scapula + reach), jitter(BONE, rng, 0.05))
		bone(m, start, start + reach * 4 * S, 1.6 * S, up, rng)
		local across = Vector3.new(-reach.Z, 0, reach.X)
		for _, o in ipairs({ -0.6, 0.6 }) do
			bone(m, start + (reach * 4 + across * o) * S, start + (reach * 9 + across * o) * S, 1.0 * S, up, rng)
		end
		for digit = 1, 4 do
			local angle = math.rad(-25 + (digit - 1) * 50 / 3 + rng:NextNumber(-6, 6))
			local digitDir = CFrame.Angles(0, angle, 0):VectorToWorldSpace(reach)
			local at = start + (reach * 9.6 + across * ((digit - 2.5) * 0.7)) * S
			for _, len in ipairs({ 1.8, 1.5, 1.2 }) do
				if rng:NextNumber() < 0.9 then
					local nextAt = at + digitDir * len * S
					bone(m, at, nextAt - digitDir * 0.25 * S, 0.6 * S, up, rng)
				end
				at += digitDir * len * S
			end
		end
	end

	-- Vestigial pelvic bones beside the spine.
	local pp = spinePoint(0.52)
	local _, pFlat, pLateral = frame(0.52)
	for _, side in ipairs({ -1, 1 }) do
		local a = Vector3.new(pp.X, floorY + 0.4 * S, pp.Z) + pLateral * side * 3 * S
		bone(m, a, a + pFlat * 3 * S, 0.5 * S, up, rng)
	end

	-- Loose bones scattered around.
	local looseArc = opts.looseArc or { 0, math.pi * 2 }
	for _ = 1, rng:NextInteger(8, 14) do
		local a = rng:NextNumber(looseArc[1], looseArc[2])
		local r = radius + rng:NextNumber(4, 16) * S
		local at = Vector3.new(center.X + math.cos(a) * r, floorY + 0.5 * S, center.Z + math.sin(a) * r)
		local heading = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector
		bone(m, at, at + heading * rng:NextNumber(1, 4) * S, rng:NextNumber(0.6, 1.4) * S, up, rng)
	end

	return m
end

return WhaleSkeleton
