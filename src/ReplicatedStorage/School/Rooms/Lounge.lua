-- Lounge / club room: a rug, seating around a low tea table, bookcases and
-- plants. Seating is either two facing sofas or a sofa with two armchairs;
-- in more neglected rooms some of it is under dust sheets.

local School = script.Parent.Parent
local BuildUtil = require(School.BuildUtil)
local Props = require(School.Props)
local Weathering = require(School.Weathering)

local part, cylinder, place, darken, pick = BuildUtil.part, BuildUtil.cylinder, BuildUtil.place, BuildUtil.darken, BuildUtil.pick
local Wood, Fabric, Smooth = Enum.Material.Wood, Enum.Material.Fabric, Enum.Material.SmoothPlastic

local RUG_COLORS = {
	Color3.fromRGB(116, 52, 44),
	Color3.fromRGB(60, 76, 64),
	Color3.fromRGB(142, 112, 74),
	Color3.fromRGB(70, 66, 96),
}

return function(parent, room, rng)
	local b = room.bounds
	local cx, cz = (b.x0 + b.x1) / 2, (b.z0 + b.z1) / 2
	local fabric = pick(Props.FABRIC_COLORS, rng)
	local rug = pick(RUG_COLORS, rng)
	local rugYaw = math.rad(rng:NextNumber(-8, 8))

	part(parent, "RugBorder", Vector3.new(16.8, 0.06, 11.8), CFrame.new(cx, 0.03, cz) * CFrame.Angles(0, rugYaw, 0), Enum.Material.Carpet, darken(rug, 0.7))
	part(parent, "Rug", Vector3.new(16, 0.08, 11), CFrame.new(cx, 0.04, cz) * CFrame.Angles(0, rugYaw, 0), Enum.Material.Carpet, rug)

	local seats = {}
	if rng:NextNumber() < 0.5 then
		for _, side in ipairs({ -1, 1 }) do
			local c = Vector3.new(cx + side * 5.2, 0, cz)
			local sofa = Props.sofa(parent, c, fabric, room.wood)
			place(sofa, c, Vector3.new(0, 0, rng:NextNumber(-0.4, 0.4)), (if side == -1 then 0 else math.pi) + math.rad(rng:NextNumber(-4, 4)))
			table.insert(seats, sofa)
		end
	else
		local c = Vector3.new(cx - 5.2, 0, cz)
		local sofa = Props.sofa(parent, c, fabric, room.wood)
		place(sofa, c, Vector3.zero, math.rad(rng:NextNumber(-4, 4)))
		table.insert(seats, sofa)
		for _, side in ipairs({ -1, 1 }) do
			local ac = Vector3.new(cx + 2, 0, cz + side * 5)
			local armchair = Props.sofa(parent, ac, pick(Props.FABRIC_COLORS, rng), room.wood, 3.4)
			place(armchair, ac, Vector3.zero, side * math.rad(90 + rng:NextNumber(10, 30)))
			table.insert(seats, armchair)
		end
	end
	for _, seat in ipairs(seats) do
		if rng:NextNumber() < room.mess * 0.7 then
			Weathering.dustSheet(parent, seat, rng)
		end
	end

	local tableColor = darken(room.wood, 0.75)
	local tc = Vector3.new(cx, 0, cz)
	local t = Props.table(parent, tc, Vector3.new(3.2, 1.7, 5), tableColor, tableColor)
	local teapot = part(t, "Teapot", Vector3.new(0.8, 0.8, 0.8), tc + Vector3.new(0, 2.1, 0.6), Smooth, Color3.fromRGB(70, 88, 84))
	teapot.Shape = Enum.PartType.Ball
	for i = 1, rng:NextInteger(1, 3) do
		cylinder(t, "Teacup", 0.35, 0.4, CFrame.new(tc + Vector3.new(rng:NextNumber(-1, 1), 1.88, -1.6 + i * 0.7)) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(236, 234, 226))
	end
	place(t, tc, Vector3.zero, math.rad(rng:NextNumber(-6, 6)))

	for i = 1, rng:NextInteger(1, 3) do
		Props.bookcase(parent, Vector3.new(b.x0 + 1.1, 0, cz + (i - 2) * 4.7), 0, room.wood, rng, rng:NextNumber(0.4, 0.9))
	end
	Props.pottedPlant(parent, Vector3.new(b.x1 - 2, 0, b.z0 + 2), rng, rng:NextNumber() < room.mess)
	Props.pottedPlant(parent, Vector3.new(b.x0 + 3, 0, b.z0 + 2), rng, rng:NextNumber() < room.mess)

	for _ = 1, rng:NextInteger(1, 3) do
		local c = Vector3.new(rng:NextNumber(cx - 6, cx + 6), 0.22, b.z0 + rng:NextNumber(3, 5))
		part(parent, "FloorCushion", Vector3.new(1.6, 0.45, 1.6), CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Fabric, pick(Props.FABRIC_COLORS, rng))
	end

	if rng:NextNumber() < 0.5 then
		local lampPos = Vector3.new(cx - 9, 0, cz + 6)
		cylinder(parent, "LampPole", 5.5, 0.2, CFrame.new(lampPos + Vector3.new(0, 2.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 58, 54))
		cylinder(parent, "LampShade", 1.2, 1.6, CFrame.new(lampPos + Vector3.new(0, 5.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Fabric, Color3.fromRGB(220, 206, 176))
		BuildUtil.disc(parent, "LampBase", 1.4, 0.2, lampPos + Vector3.new(0, 0.1, 0), Enum.Material.Metal, Color3.fromRGB(60, 58, 54))
	end

	Props.bulletinBoard(parent, "Z", b.x1, -1, cz, 14, 4, 4, rng, room.trim)
	part(parent, "SideTable", Vector3.new(1.8, 2.2, 1.8), Vector3.new(b.x1 - 1.6, 1.1, b.z1 - 6), Wood, room.trim)
end
