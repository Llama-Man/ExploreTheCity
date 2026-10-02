-- A classroom that's been cleared out: desks packed against the back wall
-- with chairs upside down on them (or desks stacked two high), the rest of
-- the floor bare apart from a few strays.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)

local DESK_W, DESK_D, DESK_H, SEAT_H = Props.DESK_W, Props.DESK_D, Props.DESK_H, Props.SEAT_H

return function(parent, room, rng)
	local b = room.bounds
	local topColor = BuildUtil.jitter(Props.DESK_TOP_COLOR, rng, 0.05)

	Props.whiteboard(parent, room, rng, if rng:NextNumber() < 0.25 then "writing" else "blank")
	Props.teacherArea(parent, room, rng, { lectern = rng:NextNumber() < 0.4, teacherDesk = rng:NextNumber() < 0.5 })

	local rows = rng:NextInteger(2, 3)
	local cols = math.floor((b.z1 - b.z0 - 7) / (DESK_W + 0.1))
	for r = 1, rows do
		local x = b.x0 + 1 + DESK_D / 2 + (r - 1) * (DESK_D + 0.15)
		for col = 1, cols do
			if rng:NextNumber() > 0.12 then
				local pos = Vector3.new(x, 0, b.z0 + 2 + DESK_W / 2 + (col - 1) * (DESK_W + 0.1))
				local desk = Props.studentDesk(parent, pos, topColor, rng)
				BuildUtil.place(desk, pos, Vector3.new(rng:NextNumber(-0.1, 0.1), 0, rng:NextNumber(-0.08, 0.08)), math.rad(rng:NextNumber(-2, 2)))

				local roll = rng:NextNumber()
				if roll < 0.55 then
					-- Chair upside down on the desk, backrest hanging over the edge.
					local chairPos = pos + Vector3.new(-0.6, 0, 0)
					Props.flip(Props.studentChair(parent, chairPos, topColor), chairPos, DESK_H + SEAT_H, math.rad(rng:NextNumber(-4, 4)))
				elseif roll < 0.7 then
					Props.flip(Props.studentDesk(parent, pos, topColor, rng), pos, 2 * DESK_H, math.rad(rng:NextNumber(-3, 3)))
				end
			end
		end
	end

	for _ = 1, rng:NextInteger(1, 4) do
		local pos = Vector3.new(rng:NextNumber(b.x0 + 16, b.x1 - 9), 0, rng:NextNumber(b.z0 + 5, b.z1 - 5))
		Props.placeStudent(parent, pos, math.rad(rng:NextNumber(-40, 40)), topColor, rng, 1)
	end
	for _ = 1, rng:NextInteger(0, 2) do
		Props.cardboardStack(parent, Vector3.new(rng:NextNumber(b.x0 + 14, b.x1 - 10), 0, b.z0 + 2.5), rng)
	end
	Props.cleaningLocker(parent, room)
end
