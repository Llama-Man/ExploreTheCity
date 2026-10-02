-- Shared dimensions and palette for the school generator modules.
-- Scale is roughly 1.4x real life, which reads as "real" next to Roblox
-- characters (a real classroom desk would look like doll furniture).

local SchoolConfig = {
	-- 0 = freshly cleaned and in use, 1 = long abandoned. Drives debris,
	-- cobwebs, dead/flickering lights, broken panes, tipped chairs.
	DISUSE = 0.55,

	-- The school is a stack of identical-plan floors; each is generated with
	-- its own mix of rooms. Floor PLAYER_FLOOR sits at y = 0 and the player
	-- spawns there.
	FLOORS = 6,
	PLAYER_FLOOR = 4,
	FLOOR_SPACING = 14.5,

	NUM_CLASSROOMS = 10,
	CLASSROOM_WIDTH = 44, -- along the corridor (X)
	CLASSROOM_DEPTH = 36, -- away from the corridor (-Z)
	CORRIDOR_WIDTH = 13,
	WALL_HEIGHT = 13,
	WALL_THICKNESS = 1,
	STAIRWELL_LENGTH = 26, -- how far each end stairwell extends beyond the corridor

	-- Sunken football courtyard beyond the corridor windows, a shaft cut
	-- down into the megastructure.
	COURTYARD_FLOOR = -330,
	COURTYARD_NEAR_Z = 8, -- just outside the corridor's window wall
	COURTYARD_DEPTH = 300,
	WING_THICKNESS = 20,
	-- Where the facility stair shaft comes out through the courtyard's far
	-- end wall (see Underground.lua).
	COURTYARD_DOOR_Z = 113.5,
	COURTYARD_DOOR_WIDTH = 6,
	COURTYARD_DOOR_HEIGHT = 9,

	-- The rock the rooftop and tunnels are in goes down this far; below it
	-- is concrete.
	ROCK_BOTTOM = -340,

	DOOR_WIDTH = 6,
	DOOR_HEIGHT = 9,
	DOOR_INSET = 4, -- gap between a room's side wall and its nearest doorway

	SILL_HEIGHT = 3.6,
	WINDOW_TOP = 11,
	TRANSOM_BOTTOM = 9.8,
	TRANSOM_TOP = 12,
	WAINSCOT_HEIGHT = 3.2,
	BOARD_WIDTH = 1.4,

	PLASTER_COLOR = Color3.fromRGB(196, 186, 164),
	CEILING_COLOR = Color3.fromRGB(190, 182, 164),
	CORRIDOR_WOOD = Color3.fromRGB(128, 94, 64),
	GLASS_COLOR = Color3.fromRGB(168, 176, 166),
	METAL_COLOR = Color3.fromRGB(140, 145, 150),
	LIGHT_COLOR = Color3.fromRGB(255, 236, 205),
	DUST_COLOR = Color3.fromRGB(150, 142, 128),

	-- Room wood drifts in lightness/warmth around this base, a small step per
	-- room, so it always stays "wood" and never jumps between unrelated tones.
	WOOD_BASE = Color3.fromRGB(152, 112, 76),
	WOOD_LIGHTNESS_RANGE = { 0.82, 1.16 },
	WOOD_WARMTH_RANGE = { -0.07, 0.07 },
	WOOD_LIGHTNESS_STEP = 0.06,
	WOOD_WARMTH_STEP = 0.025,
}

SchoolConfig.CORRIDOR_Z_MIN = -SchoolConfig.CORRIDOR_WIDTH / 2
SchoolConfig.CORRIDOR_Z_MAX = SchoolConfig.CORRIDOR_WIDTH / 2
SchoolConfig.CLASSROOM_Z_FAR = SchoolConfig.CORRIDOR_Z_MIN - SchoolConfig.CLASSROOM_DEPTH
SchoolConfig.TOTAL_LENGTH = SchoolConfig.NUM_CLASSROOMS * SchoolConfig.CLASSROOM_WIDTH

-- Height of floor f's floorboards (1 = bottom floor).
function SchoolConfig.floorY(f)
	return (f - SchoolConfig.PLAYER_FLOOR) * SchoolConfig.FLOOR_SPACING
end

SchoolConfig.BOTTOM_Y = SchoolConfig.floorY(1)
SchoolConfig.TOP_Y = SchoolConfig.floorY(SchoolConfig.FLOORS)
-- Top of the school's roof slab; the courtyard walls rise to the same height.
SchoolConfig.SCHOOL_TOP = SchoolConfig.TOP_Y + SchoolConfig.WALL_HEIGHT + 1.7

-- The courtyard's three plain walls vary in height from a third lower to
-- a third higher than the school's roof; the far end wall (the crag and
-- the department store behind it) stays low.
local courtyardWallSpan = SchoolConfig.SCHOOL_TOP - SchoolConfig.COURTYARD_FLOOR
SchoolConfig.COURTYARD_WALLS = {
	low = SchoolConfig.SCHOOL_TOP - courtyardWallSpan / 3,
	high = SchoolConfig.SCHOOL_TOP + courtyardWallSpan / 3,
	farEndHigh = 5,
}

-- The hidden sea: a flooded hall hollowed out of the building's body below
-- the courtyard (Megastructure leaves the void, HiddenSea fills it). The
-- way in arrives through its east wall at `entryZ`, floor `entryY`.
SchoolConfig.SEA = {
	x0 = 30,
	x1 = 430,
	z0 = 30,
	z1 = 300,
	ceiling = -350,
	water = -520,
	bed = -560,
	floor = -640,
	entryZ = 90,
	entryY = -372,
}

-- Where the world fades out into the fog (LightingZones draws it).
SchoolConfig.FOG_TOP = -360

-- The dead harbour at the far end of the chain of ships (Port.lua), down
-- at the fog: the fog is its sea. `chainEnd` is where the great chain
-- comes in to its winch; the quay's top is `quayDrop` below that, a little
-- above the fog. Going out along the chain the air thickens into sea fog
-- between `fogFrom` and `fogFull` (x).
SchoolConfig.HARBOUR = {
	chainEnd = Vector3.new(2040, SchoolConfig.FOG_TOP + 38, 0),
	quayDrop = 18,
	fogFrom = 1100,
	fogFull = 1780,
}

return SchoolConfig
