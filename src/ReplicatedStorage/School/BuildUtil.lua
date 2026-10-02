local BuildUtil = {}

function BuildUtil.part(parent, name, size, placement, material, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	if typeof(placement) == "CFrame" then
		p.CFrame = placement
	else
		p.Position = placement
	end
	p.Material = material
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Roblox cylinders run along their local X axis; rotate `cframe` to aim it.
function BuildUtil.cylinder(parent, name, length, diameter, cframe, material, color)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(length, diameter, diameter)
	p.CFrame = cframe
	p.Material = material
	p.Color = color
	p.Parent = parent
	return p
end

-- Flat round piece lying horizontally (stains, splatters, rugs).
function BuildUtil.disc(parent, name, diameter, thickness, position, material, color)
	return BuildUtil.cylinder(parent, name, thickness, diameter, CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), material, color)
end

function BuildUtil.rotate(vector, yaw)
	return CFrame.Angles(0, yaw, 0):VectorToWorldSpace(vector)
end

function BuildUtil.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Furniture is built axis-aligned around `pivot`, then nudged/rotated as a
-- whole so rows of desks and chairs don't look machine-perfect.
function BuildUtil.place(model, pivot, offset, yaw)
	model.WorldPivot = CFrame.new(pivot)
	model:PivotTo(CFrame.new(pivot + (offset or Vector3.zero)) * CFrame.Angles(0, yaw or 0, 0))
end

-- Same, but with an extra tilt applied after the yaw (tipping things over,
-- turning them upside down). `lift` raises the pivot so it rests on the floor.
function BuildUtil.placeTilted(model, pivot, lift, yaw, tilt)
	model.WorldPivot = CFrame.new(pivot)
	model:PivotTo(CFrame.new(pivot + Vector3.new(0, lift, 0)) * CFrame.Angles(0, yaw, 0) * tilt)
end

function BuildUtil.darken(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

function BuildUtil.jitter(color, rng, amount)
	local f = 1 + rng:NextNumber(-amount, amount)
	return Color3.new(math.clamp(color.R * f, 0, 1), math.clamp(color.G * f, 0, 1), math.clamp(color.B * f, 0, 1))
end

function BuildUtil.pick(list, rng)
	return list[rng:NextInteger(1, #list)]
end

-- Size/position for a box lying along a wall: `along` runs with the wall,
-- `depth` is through it, `fixed` is the wall-plane coordinate.
function BuildUtil.axisBox(axis, alongLen, height, depth, alongPos, y, fixed)
	if axis == "X" then
		return Vector3.new(alongLen, height, depth), Vector3.new(alongPos, y, fixed)
	end
	return Vector3.new(depth, height, alongLen), Vector3.new(fixed, y, alongPos)
end

-- Fills the rectangle [spanStart, spanEnd] x [bottom, top] in a wall plane
-- with boxes, leaving holes for `openings` ({center, width, bottom, top}).
-- Used for wall cores and for every overlay (wainscot, rails, baseboards)
-- so they all break cleanly around the same doors and windows. With
-- `spec.rng`, each piece gets a slightly different shade (`spec.jitter`).
function BuildUtil.strip(parent, spec)
	local openings = {}
	for _, o in ipairs(spec.openings or {}) do
		local oStart, oEnd = o.center - o.width / 2, o.center + o.width / 2
		local oBottom, oTop = math.max(o.bottom, spec.bottom), math.min(o.top, spec.top)
		if oEnd > spec.spanStart and oStart < spec.spanEnd and oTop > oBottom then
			table.insert(openings, {
				start = math.max(oStart, spec.spanStart),
				finish = math.min(oEnd, spec.spanEnd),
				bottom = oBottom,
				top = oTop,
			})
		end
	end
	table.sort(openings, function(a, b)
		return a.start < b.start
	end)

	local function piece(s, e, b, t)
		if e - s < 0.02 or t - b < 0.02 then
			return
		end
		local size, pos = BuildUtil.axisBox(spec.axis, e - s, t - b, spec.thickness, (s + e) / 2, (b + t) / 2, spec.fixed)
		local color = if spec.rng then BuildUtil.jitter(spec.color, spec.rng, spec.jitter or 0.05) else spec.color
		local p = BuildUtil.part(parent, spec.name, size, pos, spec.material, color)
		if spec.transparency then
			-- Translucent decal-like overlay: no collision or shadow.
			p.Transparency = spec.transparency
			p.CanCollide = false
			p.CastShadow = false
		end
	end

	local cursor = spec.spanStart
	for _, o in ipairs(openings) do
		piece(cursor, o.start, spec.bottom, spec.top)
		piece(o.start, o.finish, spec.bottom, o.bottom)
		piece(o.start, o.finish, o.top, spec.top)
		cursor = math.max(cursor, o.finish)
	end
	piece(cursor, spec.spanEnd, spec.bottom, spec.top)
end

return BuildUtil
