-- Ordinary classroom. Desk layout varies: evenly spaced rows, rows of
-- paired desks, or islands of four for group work.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)

local DESK_W, DESK_D, SEAT = Props.DESK_W, Props.DESK_D, Props.SEAT

local function rowsLayout(parent, room, rng, topColor, paired)
	local b = room.bounds
	local frontEdge, backLimit = b.x1 - 7.5, b.x0 + 5
	local rowPitch = 6.2
	local rowDepth = DESK_D + SEAT - 0.7
	local maxRows = math.max(1, math.floor((frontEdge - backLimit - rowDepth) / rowPitch) + 1)
	local rows = math.min(rng:NextInteger(3, 5), maxRows)
	local zMid = (b.z0 + b.z1) / 2
	local usable = b.z1 - b.z0 - 5

	local zs = {}
	if paired then
		local pairW, aisle = 2 * DESK_W, 2.4
		local pairCount = math.max(1, math.floor((usable + aisle) / (pairW + aisle)))
		local z = zMid - (pairCount * pairW + (pairCount - 1) * aisle) / 2
		for _ = 1, pairCount do
			table.insert(zs, z + DESK_W / 2)
			table.insert(zs, z + DESK_W * 1.5)
			z += pairW + aisle
		end
	else
		local colPitch = DESK_W + 1.6
		local cols = math.clamp(math.floor((usable + 1.6) / colPitch), 1, 6)
		for col = 1, cols do
			table.insert(zs, zMid + (col - (cols + 1) / 2) * colPitch)
		end
	end

	for r = 1, rows do
		local x = frontEdge - DESK_D / 2 - (r - 1) * rowPitch
		for _, z in ipairs(zs) do
			if rng:NextNumber() > 0.08 + room.mess * 0.1 then
				Props.placeStudent(parent, Vector3.new(x, 0, z), 0, topColor, rng, room.mess)
			end
		end
	end
end

-- Islands of four: two desks facing +Z meeting two facing -Z.
local function groupsLayout(parent, room, rng, topColor)
	local b = room.bounds
	local islandX, islandZ = 2 * DESK_W, 2 * DESK_D + 2 * (SEAT - 0.2)
	local x0, x1 = b.x0 + 5, b.x1 - 7.5
	local z0, z1 = b.z0 + 2, b.z1 - 2
	local nx = math.max(1, math.floor((x1 - x0) / (islandX + 3)))
	local nz = math.max(1, math.floor((z1 - z0) / (islandZ + 2)))

	for i = 1, nx do
		for j = 1, nz do
			local gx = x0 + (x1 - x0) * (i - 0.5) / nx
			local gz = z0 + (z1 - z0) * (j - 0.5) / nz
			for _, side in ipairs({ -1, 1 }) do
				local yaw = if side == -1 then math.rad(-90) else math.rad(90)
				for _, dx in ipairs({ -DESK_W / 2, DESK_W / 2 }) do
					if rng:NextNumber() > 0.08 + room.mess * 0.1 then
						Props.placeStudent(parent, Vector3.new(gx + dx, 0, gz + side * DESK_D / 2), yaw, topColor, rng, room.mess)
					end
				end
			end
		end
	end
end

return function(parent, room, rng)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2
	local topColor = BuildUtil.jitter(Props.DESK_TOP_COLOR, rng, 0.05)

	Props.whiteboard(parent, room, rng, if rng:NextNumber() < 0.7 then "writing" else "blank")
	Props.teacherArea(parent, room, rng, { lectern = rng:NextNumber() < 0.85 })

	local layout = rng:NextNumber()
	if layout < 0.5 then
		rowsLayout(parent, room, rng, topColor, false)
	elseif layout < 0.8 then
		rowsLayout(parent, room, rng, topColor, true)
	else
		groupsLayout(parent, room, rng, topColor)
	end

	Props.cubbyLockers(parent, room, rng)
	Props.bulletinBoard(parent, "Z", b.x0, 1, zMid, (b.z1 - b.z0) * 0.55, 5.6, 3.4, rng, room.trim)
	if rng:NextNumber() < 0.8 then
		Props.cleaningLocker(parent, room)
	end
	if rng:NextNumber() < 0.5 then
		Props.pottedPlant(parent, Vector3.new(b.x0 + 3, 0, b.z0 + 2.5), rng, rng:NextNumber() < room.mess)
	end
end
