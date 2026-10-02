-- Library: shelving along the back wall, rows of freestanding double-sided
-- stacks, reading tables near the front and a lending counter by the front
-- door. Neglect shows as books fallen to the floor.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)

local part, place, darken, pick = BuildUtil.part, BuildUtil.place, BuildUtil.darken, BuildUtil.pick
local Wood, Smooth = Enum.Material.Wood, Enum.Material.SmoothPlastic

return function(parent, room, rng)
	local b = room.bounds
	local unitW = 4.6

	local wallCount = math.floor((b.z1 - b.z0 - 6) / unitW)
	for i = 1, wallCount do
		Props.bookcase(parent, Vector3.new(b.x0 + 1.1, 0, b.z0 + 2 + (i - 0.5) * unitW), 0, room.wood, rng, 0.85)
	end

	for _, x in ipairs({ b.x0 + 7.5, b.x0 + 13.5, b.x0 + 19.5 }) do
		for j = 1, 4 do
			local z = b.z0 + 4 + (j - 0.5) * unitW
			for _, side in ipairs({ -1, 1 }) do
				Props.bookcase(parent, Vector3.new(x + side * 0.8, 0, z), if side == -1 then math.pi else 0, room.wood, rng, 0.75)
			end
		end
		for _ = 1, math.floor(room.mess * rng:NextNumber(2, 8)) do
			local bookPos = Vector3.new(x + rng:NextNumber(-3, 3), 0.1, b.z0 + rng:NextNumber(4, 22))
			part(parent, "FallenBook", Vector3.new(1.2, 0.2, 1.6), CFrame.new(bookPos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), Smooth, pick(Props.BOOK_COLORS, rng))
		end
	end

	local tableColor = darken(room.wood, 0.8)
	local chairColor = BuildUtil.jitter(Props.DESK_TOP_COLOR, rng, 0.05)
	for _, tz in ipairs({ b.z0 + 8, b.z0 + 20 }) do
		local c = Vector3.new(b.x0 + 30, 0, tz)
		place(Props.table(parent, c, Vector3.new(10, 3.2, 4), tableColor, darken(tableColor, 0.8)), c, Vector3.zero, math.rad(rng:NextNumber(-2, 2)))
		for _, side in ipairs({ -1, 1 }) do
			for _, dx in ipairs({ -3.3, 0, 3.3 }) do
				if rng:NextNumber() > 0.15 + room.mess * 0.1 then
					local cc = c + Vector3.new(dx, 0, side * 3.2)
					local yaw = side * math.rad(90)
					local chair = Props.studentChair(parent, cc, chairColor)
					if rng:NextNumber() < room.mess * 0.15 then
						Props.tipChair(chair, cc + Vector3.new(0, 0, side * 1.5), yaw)
					else
						place(chair, cc, Vector3.new(rng:NextNumber(-0.3, 0.3), 0, side * rng:NextNumber(0, 1)), yaw + math.rad(rng:NextNumber(-12, 12)))
					end
				end
			end
		end
		if rng:NextNumber() < 0.5 then
			part(parent, "OpenBook", Vector3.new(1.6, 0.12, 2.2), CFrame.new(c + Vector3.new(rng:NextNumber(-3, 3), 3.26, rng:NextNumber(-1, 1))) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), Smooth, Props.PAPER_COLORS[2])
		end
	end

	-- Lending counter by the front door, with the librarian's chair behind it.
	local counter = Vector3.new(b.x1 - 3, 0, b.z1 - 8)
	part(parent, "Counter", Vector3.new(2.5, 3.6, 7), counter + Vector3.new(0, 1.8, 0), Wood, room.trim)
	part(parent, "CounterTop", Vector3.new(3, 0.2, 7.4), counter + Vector3.new(0, 3.7, 0), Wood, darken(room.wood, 0.9))
	part(parent, "ReturnedBooks", Vector3.new(1.2, 0.8, 1.6), counter + Vector3.new(0, 4.2, rng:NextNumber(-2, 2)), Smooth, pick(Props.BOOK_COLORS, rng))
	local chairPos = counter + Vector3.new(2.2, 0, 0)
	place(Props.studentChair(parent, chairPos, chairColor), chairPos, Vector3.zero, math.pi + math.rad(rng:NextNumber(-15, 15)))

	local cart = Vector3.new(rng:NextNumber(b.x0 + 24, b.x0 + 34), 0, b.z0 + 14)
	local cartModel = Props.table(parent, cart, Vector3.new(3, 3, 1.6), room.trim, room.trim)
	Props.bookRow(cartModel, cart + Vector3.new(0, 3, 0), 1.4, 1.2, rng)
	place(cartModel, cart, Vector3.zero, rng:NextNumber(0, math.pi))

	Props.pottedPlant(parent, Vector3.new(b.x1 - 2.5, 0, b.z0 + 2.5), rng, rng:NextNumber() < room.mess)
end
