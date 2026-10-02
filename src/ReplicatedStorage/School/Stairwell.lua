-- Switchback stairwell at one end of the corridor, running the full height
-- of the stacked school. Each floor's corridor opens onto a landing; flight
-- A climbs away along the south half to a half landing at the far end, and
-- flight B climbs back along the north half to the next floor's landing.
--
-- Positions along the stairwell are measured as `s` outward from the
-- corridor's end wall (x = xFace + dir * s), so the same code builds both
-- ends.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Architecture = require(script.Parent.Architecture)

local part, jitter = BuildUtil.part, BuildUtil.jitter
local Concrete, Metal = Enum.Material.Concrete, Enum.Material.Metal

local T = Config.WALL_THICKNESS
local SP = Config.FLOOR_SPACING
local LEN = Config.STAIRWELL_LENGTH
local ZN, ZX = Config.CORRIDOR_Z_MIN, Config.CORRIDOR_Z_MAX
local LANDING_END = 7 -- flights start here
local TURN_START = 21 -- and end here, at the half landing
local STEPS = 10
local RISE = SP / 2 / STEPS
local RUN = (TURN_START - LANDING_END) / STEPS

local STAIR_COLOR = Color3.fromRGB(150, 146, 136)
local RAIL_COLOR = Color3.fromRGB(90, 92, 94)

local Stairwell = {}

-- opts: rng, bottomDoor (door in the far wall on the bottom floor),
-- topExit (door in the far wall on the top floor), lightState (fn(rng)),
-- annexDoor (the south side opens onto a toilet block, StairAnnex.lua:
-- a door off each landing instead of windows).
function Stairwell.build(parent, xFace, dir, opts)
	local rng = opts.rng
	local function xAt(s)
		return xFace + dir * s
	end
	local function box(name, s0, s1, y0, y1, z0, z1, material, color)
		local xa, xb = xAt(s0), xAt(s1)
		local x0, x1 = math.min(xa, xb), math.max(xa, xb)
		return part(parent, name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), material, color)
	end
	local function rail(s0, y0, s1, y1, z)
		local a, b = Vector3.new(xAt(s0), y0, z), Vector3.new(xAt(s1), y1, z)
		BuildUtil.cylinder(parent, "Handrail", (b - a).Magnitude, 0.25, CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), Metal, RAIL_COLOR)
		local posts = math.floor((b - a).Magnitude / 3.5)
		for i = 0, posts do
			local p = a:Lerp(b, i / posts)
			part(parent, "Baluster", Vector3.new(0.18, 3, 0.18), p - Vector3.new(0, 1.5, 0), Metal, RAIL_COLOR)
		end
	end

	local zIn0, zIn1 = ZN + T / 2, ZX - T / 2
	local sFar = LEN - T / 2
	local xMin, xMax = math.min(xAt(0), xAt(LEN)), math.max(xAt(0), xAt(LEN))

	-- Ground slab under the bottom floor and roof over the top.
	local bottomY, topY = Config.BOTTOM_Y, Config.TOP_Y
	box("StairwellFooting", 0, LEN, bottomY - 4, bottomY - 1.2, ZN - T / 2, ZX + T / 2, Concrete, Color3.fromRGB(140, 138, 130))
	box("StairwellRoof", -0.5, LEN + 1, topY + Config.WALL_HEIGHT + 1, topY + Config.WALL_HEIGHT + 1.7, ZN - 2, ZX + 2, Enum.Material.Slate, Color3.fromRGB(72, 74, 78))

	for f = 1, Config.FLOORS do
		local y = Config.floorY(f)
		local isBottom, isTop = f == 1, f == Config.FLOORS

		box("Landing", T / 2, LANDING_END, y - 1.2, y, zIn0, zIn1, Concrete, jitter(STAIR_COLOR, rng, 0.04))

		if not isTop then
			for i = 1, STEPS do
				local top = y + i * RISE
				box("Step", LANDING_END + (i - 1) * RUN, LANDING_END + i * RUN, top - RISE - 1, top, zIn0, -0.2, Concrete, STAIR_COLOR)
				local topB = y + SP / 2 + i * RISE
				box("Step", TURN_START - i * RUN, TURN_START - (i - 1) * RUN, topB - RISE - 1, topB, 0.2, zIn1, Concrete, STAIR_COLOR)
			end
			box("HalfLanding", TURN_START, sFar, y + SP / 2 - 1.2, y + SP / 2, zIn0, zIn1, Concrete, jitter(STAIR_COLOR, rng, 0.04))
			rail(LANDING_END, y + 3, TURN_START, y + SP / 2 + 3, -0.35)
			rail(TURN_START, y + SP / 2 + 3, LANDING_END, y + SP + 3, 0.35)
		else
			-- Top floor: walk along the south half to the far wall.
			box("TopFloor", LANDING_END, sFar, y - 1.2, y, zIn0, -0.2, Concrete, jitter(STAIR_COLOR, rng, 0.04))
			box("TopFloor", TURN_START, sFar, y - 1.2, y, -0.2, zIn1, Concrete, jitter(STAIR_COLOR, rng, 0.04))
			rail(LANDING_END, y + 3, TURN_START, y + 3, 0)
		end

		-- Walls for this storey, with a window on the south side at the
		-- landing and another at the half landing.
		local wallBottom = y - 1.2
		local wallTop = if isTop then y + Config.WALL_HEIGHT + 1 else y + SP - 1.2
		local function wallSpec(axis, fixed, spanStart, spanEnd, openings)
			BuildUtil.strip(parent, {
				name = "StairwellWall",
				axis = axis,
				fixed = fixed,
				spanStart = spanStart,
				spanEnd = spanEnd,
				bottom = wallBottom,
				top = wallTop,
				thickness = T,
				openings = openings,
				material = Enum.Material.Plaster,
				color = Config.PLASTER_COLOR,
				rng = rng,
				jitter = 0.06,
			})
		end
		local southOpenings
		if opts.annexDoor then
			southOpenings = { { center = xAt(opts.annexDoor.s), width = opts.annexDoor.width, bottom = y, top = y + opts.annexDoor.height, door = true } }
		else
			southOpenings = { { center = xAt(3.5), width = 3, bottom = y + 3.6, top = y + 10 } }
			if not isTop then
				table.insert(southOpenings, { center = xAt(23), width = 3, bottom = y + SP / 2 + 1.5, top = y + SP / 2 + 6.5 })
			end
		end
		wallSpec("X", ZN, xMin, xMax, southOpenings)
		wallSpec("X", ZX, xMin, xMax, {})

		local endOpenings = {}
		if isBottom and opts.bottomDoor then
			table.insert(endOpenings, { center = 3.25, width = 5, bottom = y, top = y + 5.5 })
		end
		if isTop and opts.topExit then
			table.insert(endOpenings, { center = -3.25, width = 5.5, bottom = y, top = y + 9 })
		end
		if isTop and opts.westBreach then
			-- the far wall's come away here (WestCrossing.lua)
			table.insert(endOpenings, { center = 0, width = 8, bottom = y, top = y + 10 })
		end
		wallSpec("Z", xAt(LEN), ZN, ZX, endOpenings)

		-- Glass in the south windows.
		for _, o in ipairs(southOpenings) do
			if o.door then
				continue
			end
			local glass = part(parent, "StairwellGlass", Vector3.new(o.width, o.top - o.bottom, 0.1), Vector3.new(o.center, (o.bottom + o.top) / 2, ZN), Enum.Material.Glass, jitter(Config.GLASS_COLOR, rng, 0.05))
			glass.Transparency = 0.45
		end

		-- Floor number plate on the north wall of the landing.
		local plate = part(parent, "FloorSign", Vector3.new(2.6, 1.6, 0.1), Vector3.new(xAt(4), y + 7, ZX - T / 2 - 0.06), Enum.Material.SmoothPlastic, Color3.fromRGB(226, 222, 208))
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(40, 40, 44)
		label.Text = string.format("%dF", f)
		label.Parent = gui
		gui.Parent = plate

		-- Hung under the next landing up.
		Architecture.ceilingLight(parent, Vector3.new(xAt(3.5), y + Config.WALL_HEIGHT - 0.3, 0), opts.lightState(rng))
	end
end

return Stairwell
