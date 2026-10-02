-- Dresses rooms (shared fittings + the chosen room style + wear) and the
-- corridor side of classroom walls.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Props = require(script.Parent.Props)
local Weathering = require(script.Parent.Weathering)

local Rooms = script.Parent.Rooms
local ROOM_STYLES = {
	classroom = require(Rooms.Classroom),
	cleared = require(Rooms.ClearedClassroom),
	storage = require(Rooms.Storage),
	lounge = require(Rooms.Lounge),
	music = require(Rooms.MusicRoom),
	science = require(Rooms.ScienceLab),
	art = require(Rooms.ArtRoom),
	library = require(Rooms.Library),
	infirmary = require(Rooms.Infirmary),
}

local Furnishings = {}

-- room = { kind, bounds = {x0, x1, z0, z1} (interior faces), wood, trim,
-- mess (0-1), windows = { {center, width, z, inward} } on the outer wall }
function Furnishings.populateRoom(parent, room, rng)
	local b = room.bounds
	Props.curtains(parent, room, rng)
	Props.wallClock(parent, b.x1, 10.6, (b.z0 + b.z1) / 2, rng)
	ROOM_STYLES[room.kind](parent, room, rng)
	Weathering.floor(parent, b, rng, room.mess, room.windows)
	Weathering.cobwebs(parent, b, rng, room.mess)
end

-- Notice board, the odd fire extinguisher and a potted plant on the
-- corridor side of a classroom wall, between its two doors. `faceZ` is the
-- corridor-side face.
function Furnishings.dressCorridorWall(parent, spanStart, spanEnd, faceZ, rng)
	local trim = BuildUtil.darken(Config.CORRIDOR_WOOD, 0.7)
	local length = math.min(12, spanEnd - spanStart - 2)
	if length > 3 and rng:NextNumber() < 0.65 then
		Props.bulletinBoard(parent, "X", faceZ, 1, (spanStart + spanEnd) / 2, length, 4.6, 3.6, rng, trim)
	end
	if rng:NextNumber() < 0.3 then
		local x = if rng:NextNumber() < 0.5 then spanStart + 0.6 else spanEnd - 0.6
		local c = Vector3.new(x, 0, faceZ + 0.75)
		local upright = CFrame.Angles(0, 0, math.rad(90))
		if rng:NextNumber() < Config.DISUSE * 0.3 then
			-- Knocked over and rolled against the wall.
			BuildUtil.cylinder(parent, "FireExtinguisher", 1.7, 0.7, CFrame.new(c + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), Enum.Material.SmoothPlastic, Color3.fromRGB(170, 34, 32))
		else
			BuildUtil.cylinder(parent, "FireExtinguisher", 1.7, 0.7, CFrame.new(c + Vector3.new(0, 0.85, 0)) * upright, Enum.Material.SmoothPlastic, Color3.fromRGB(170, 34, 32))
			BuildUtil.part(parent, "ExtinguisherHead", Vector3.new(0.3, 0.35, 0.3), c + Vector3.new(0, 1.85, 0), Enum.Material.Metal, Color3.fromRGB(30, 30, 30))
		end
	end
end

return Furnishings
