-- Keeps the ways through the map walkable.
--
-- The world is carved out of terrain by a lot of separate steps (tunnels,
-- landslide, facility, rooms that bring rock in), and a later fill can
-- land across an earlier passage. So each part of the generator registers
-- the passages people must be able to walk (a floor-level centre line, a
-- half width and a clear height), and once everything is built, run()
-- walks them all: any rock found in that walking space is cleared, and
-- reported in Output so the cause can be tracked down.

local RouteCheck = {}

local terrain = workspace.Terrain
local AIR, WATER = Enum.Material.Air, Enum.Material.Water
local routes = {}

-- `points` is a list of floor-level points (world space) the route runs
-- through in order. `always` clears the route wide whether or not any
-- rock is found (for the few routes that must never, ever be blocked).
function RouteCheck.add(name, points, halfWidth, height, always)
	table.insert(routes, { name = name, points = points, halfWidth = halfWidth, height = height, always = always })
end

-- Rock voxels inside the walking space of the stretch a -> b.
local function blockedVoxels(a, b, halfWidth, height)
	local lo = Vector3.new(math.min(a.X, b.X) - halfWidth, math.min(a.Y, b.Y), math.min(a.Z, b.Z) - halfWidth)
	local hi = Vector3.new(math.max(a.X, b.X) + halfWidth, math.max(a.Y, b.Y) + height, math.max(a.Z, b.Z) + halfWidth)
	local region = Region3.new(lo, hi):ExpandToGrid(4)
	local materials, occupancy = terrain:ReadVoxels(region, 4)
	local corner = region.CFrame.Position - region.Size / 2
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local flatLen2 = math.max(flat:Dot(flat), 1e-6)
	local found = {}
	local size = materials.Size
	for ix = 1, size.X do
		for iy = 1, size.Y do
			for iz = 1, size.Z do
				local m = materials[ix][iy][iz]
				if m ~= AIR and m ~= WATER and occupancy[ix][iy][iz] > 0.25 then
					local c = corner + Vector3.new(ix - 0.5, iy - 0.5, iz - 0.5) * 4
					local t = math.clamp(Vector3.new(c.X - a.X, 0, c.Z - a.Z):Dot(flat) / flatLen2, 0, 1)
					local on = a:Lerp(b, t)
					local across = Vector3.new(c.X - on.X, 0, c.Z - on.Z).Magnitude
					local up = c.Y - on.Y
					-- Anything reaching into the walking space counts, from
					-- knee height up, including blobs coming in from the sides
					-- (voxel centres sit 2 studs into their 4-stud cell).
					if across < halfWidth + 1 and up > 2.5 and up < height + 1 then
						table.insert(found, { at = c, material = m })
					end
				end
			end
		end
	end
	return found
end

-- Clear the walking space of a -> b (above the floor, so floors stay),
-- a good few studs wider than the route so part-cleared voxels at the
-- edges don't leave blobs of rock behind.
local function clear(a, b, halfWidth, height)
	local lift = Vector3.new(0, 0.6 + (height + 2) / 2, 0)
	local size = Vector3.new(halfWidth * 2 + 8, height + 2, 0)
	local len = (b - a).Magnitude
	if len < 0.5 then
		terrain:FillBlock(CFrame.new(a + lift), size + Vector3.new(0, 0, halfWidth * 2 + 8), AIR)
		return
	end
	terrain:FillBlock(CFrame.lookAt((a + b) / 2 + lift, b + lift), size + Vector3.new(0, 0, len + 4), AIR)
end

-- Check every registered route; clear and report blockages. Returns the
-- number of routes checked and a list of report lines.
function RouteCheck.run()
	local lines = {}
	local checked = #routes
	for _, r in ipairs(routes) do
		local reported = false
		for k = 1, #r.points - 1 do
			local a, b = r.points[k], r.points[k + 1]
			local len = (b - a).Magnitude
			local pieces = math.max(1, math.ceil(len / 8))
			for p = 0, pieces - 1 do
				local p0, p1 = a:Lerp(b, p / pieces), a:Lerp(b, (p + 1) / pieces)
				local found = blockedVoxels(p0, p1, r.halfWidth, r.height)
				if r.always then
					clear(p0, p1, r.halfWidth, r.height)
				end
				if #found > 0 then
					clear(p0, p1, r.halfWidth, r.height)
					if not reported then
						reported = true
						local f = found[1]
						table.insert(lines, string.format("%s: %d rock voxels (%s) near (%.0f, %.0f, %.0f), cleared", r.name, #found, f.material.Name, f.at.X, f.at.Y, f.at.Z))
					end
				end
			end
		end
	end
	routes = {}
	return checked, lines
end

return RouteCheck
