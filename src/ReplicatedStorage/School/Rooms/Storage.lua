-- Preparation/storage room. Either tidy (bookcases on both end walls and a
-- worktable) or a junk room (boxes everywhere, spare furniture under dust
-- sheets).

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)
local Weathering = require(School.Weathering)

local darken = BuildUtil.darken

local function tidy(parent, room, rng)
	local b = room.bounds
	local cx, zMid = (b.x0 + b.x1) / 2, (b.z0 + b.z1) / 2

	local length = rng:NextNumber(12, 16)
	local c = Vector3.new(cx, 0, zMid)
	local tableColor = darken(room.wood, 0.9)
	local worktable = Props.table(parent, c, Vector3.new(length, 3.4, 5), tableColor, darken(tableColor, 0.85))
	BuildUtil.part(worktable, "PaperStack", Vector3.new(1.2, 0.3, 0.9), c + Vector3.new(rng:NextNumber(-length / 3, length / 3), 3.55, rng:NextNumber(-1.2, 1.2)), Enum.Material.SmoothPlastic, Props.PAPER_COLORS[1])
	BuildUtil.part(worktable, "CardboardBox", Vector3.new(2.0, 1.4, 1.6), c + Vector3.new(rng:NextNumber(-length / 3, length / 3), 4.1, rng:NextNumber(-1, 1)), Enum.Material.Cardboard, Props.CARDBOARD_COLOR)
	BuildUtil.place(worktable, c, Vector3.zero, math.rad(rng:NextNumber(-3, 3)))

	local slots = math.floor(length / 3.5)
	for _, side in ipairs({ -1, 1 }) do
		for k = 1, slots do
			if rng:NextNumber() < 0.6 then
				local sc = Vector3.new(cx + (k - (slots + 1) / 2) * 3.5, 0, zMid + side * 3.6)
				BuildUtil.place(Props.stool(parent, sc, darken(room.wood, 0.8)), sc, Vector3.new(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)), 0)
			end
		end
	end

	for _, corner in ipairs({ Vector3.new(b.x0 + 4.5, 0, b.z0 + 2.5), Vector3.new(b.x1 - 4.5, 0, b.z0 + 2.5) }) do
		if rng:NextNumber() < 0.8 then
			Props.cardboardStack(parent, corner, rng)
		end
	end
end

local function junk(parent, room, rng)
	local b = room.bounds
	for _ = 1, rng:NextInteger(6, 11) do
		Props.cardboardStack(parent, Vector3.new(rng:NextNumber(b.x0 + 5, b.x1 - 3), 0, rng:NextNumber(b.z0 + 3, b.z1 - 5)), rng, 4)
	end
	for _ = 1, rng:NextInteger(2, 4) do
		local c = Vector3.new(rng:NextNumber(b.x0 + 8, b.x1 - 6), 0, rng:NextNumber(b.z0 + 5, b.z1 - 7))
		local heap = BuildUtil.model(parent, "SheetedFurniture")
		Props.studentDesk(heap, c, Props.DESK_TOP_COLOR, rng)
		if rng:NextNumber() < 0.6 then
			Props.flip(Props.studentDesk(heap, c, Props.DESK_TOP_COLOR, rng), c, 2 * Props.DESK_H, 0)
		end
		BuildUtil.place(heap, c, Vector3.zero, rng:NextNumber(0, math.pi))
		Weathering.dustSheet(parent, heap, rng)
	end
end

return function(parent, room, rng)
	local b = room.bounds
	local zMid = (b.z0 + b.z1) / 2
	local isJunk = rng:NextNumber() < 0.45

	local unitW = 4.6
	local count = math.floor((b.z1 - b.z0 - 3) / unitW)
	local walls = { { x = b.x0 + 1.1, yaw = 0 } }
	if not isJunk then
		table.insert(walls, { x = b.x1 - 1.1, yaw = math.pi })
	end
	for _, wall in ipairs(walls) do
		for i = 1, count do
			if not isJunk or rng:NextNumber() < 0.6 then
				Props.bookcase(parent, Vector3.new(wall.x, 0, zMid + (i - (count + 1) / 2) * unitW), wall.yaw, room.wood, rng, rng:NextNumber(0.3, 0.8))
			end
		end
	end

	if isJunk then
		junk(parent, room, rng)
	else
		tidy(parent, room, rng)
	end
end
