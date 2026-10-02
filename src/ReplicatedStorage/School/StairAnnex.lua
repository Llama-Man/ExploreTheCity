-- The toilet block beside each stairwell. The stairwells only span the
-- corridor, so beside each one (out past the end classroom, over to the
-- south face) there'd otherwise be an open shaft down the building. It's
-- filled the way Japanese schools usually fill it: a toilet on every
-- floor, entered through a door off the stairwell landing. Boys' and
-- girls' alternate floor by floor and end by end.
--
-- Each storey is built at y = 0 and pivoted up into place, like the main
-- floors.

local Config = require(script.Parent.SchoolConfig)
local BuildUtil = require(script.Parent.BuildUtil)
local Architecture = require(script.Parent.Architecture)
local Weathering = require(script.Parent.Weathering)

local part, cylinder, model, jitter, pick, darken = BuildUtil.part, BuildUtil.cylinder, BuildUtil.model, BuildUtil.jitter, BuildUtil.pick, BuildUtil.darken
local Wood, Smooth, Tiles, Metal, Glass, Concrete = Enum.Material.Wood, Enum.Material.SmoothPlastic, Enum.Material.CeramicTiles, Enum.Material.Metal, Enum.Material.Glass, Enum.Material.Concrete

local H, T = Config.WALL_HEIGHT, Config.WALL_THICKNESS
local LEN = Config.STAIRWELL_LENGTH
local Z_FAR = Config.CLASSROOM_Z_FAR
local ZN = Config.CORRIDOR_Z_MIN
local DOOR_S, DOOR_W, DOOR_H = 3.5, 4, 8 -- the door off the stairwell landing
local TILE_H = 4.5
local PORCELAIN = Color3.fromRGB(226, 226, 220)
local TILE_COLORS = { Color3.fromRGB(206, 214, 212), Color3.fromRGB(196, 210, 214), Color3.fromRGB(214, 212, 200) }

local StairAnnex = {}
StairAnnex.DOOR_S, StairAnnex.DOOR_W, StairAnnex.DOOR_H = DOOR_S, DOOR_W, DOOR_H

local function rollLight(rng, mess)
	local roll = rng:NextNumber()
	if roll < 0.1 + mess * 0.2 then
		return "dead"
	elseif roll < 0.16 + mess * 0.28 then
		return "flicker"
	end
	return "on"
end

-- One storey's toilet, built at y = 0.
local function storey(parent, xFace, dir, f, boys, rng)
	local function xAt(s)
		return xFace + dir * s
	end
	local x0, x1 = math.min(xAt(0), xAt(LEN)), math.max(xAt(0), xAt(LEN))
	local ix0, ix1 = x0 + T / 2, x1 - T / 2
	local iz0, iz1 = Z_FAR + T / 2, ZN - T / 2
	local isBottom, isTop = f == 1, f == Config.FLOORS
	local mess = math.clamp(Config.DISUSE + rng:NextNumber(-0.15, 0.25), 0, 1)
	local trim = Weathering.dusty(BuildUtil.darken(Config.CORRIDOR_WOOD, 0.8), mess)
	local tile = pick(TILE_COLORS, rng)
	-- Positions in the room: `s` out from the end classroom's wall, z as is.
	local function at(s, y, z)
		return Vector3.new(xAt(s), y, z)
	end
	local function box(name, s0, s1, y0, y1, z0, z1, material, color)
		local xa, xb = xAt(s0), xAt(s1)
		return part(parent, name, Vector3.new(math.abs(xb - xa), y1 - y0, math.abs(z1 - z0)), Vector3.new((xa + xb) / 2, (y0 + y1) / 2, (z0 + z1) / 2), material, color)
	end

	-- Shell: subfloor, storey bands, footing or roof, and the band round the
	-- end face too (floorShell only does the long faces).
	Architecture.floorShell(parent, x0, x1, Z_FAR - T / 2, ZN, isBottom, isTop)
	part(parent, "StoreyBand", Vector3.new(0.8, Config.FLOOR_SPACING + 0.3 - H, ZN - Z_FAR + 0.8), Vector3.new(xAt(LEN), (H - 0.2 + Config.FLOOR_SPACING + 0.1) / 2, (Z_FAR + ZN) / 2), Enum.Material.Concrete, Color3.fromRGB(128, 124, 116))
	part(parent, "TileFloor", Vector3.new(ix1 - ix0, 0.4, iz1 - iz0), Vector3.new((ix0 + ix1) / 2, -0.2, (iz0 + iz1) / 2), Tiles, jitter(Color3.fromRGB(170, 172, 168), rng, 0.05))
	Architecture.ceiling(parent, x0, x1, Z_FAR, ZN, 1, trim)

	-- Outer walls: frosted windows high on the south face, and on the end.
	local southWindows, endWindows = {}, {}
	for _, s in ipairs({ 7.5, 15.5, 23 }) do
		table.insert(southWindows, { center = xAt(s), width = 4.5, bottom = 7.5, top = 11.5 })
	end
	for _, z in ipairs({ -30, -18 }) do
		table.insert(endWindows, { center = z, width = 6, bottom = 6, top = 11.5 })
	end
	Architecture.wall(parent, "X", Z_FAR, x0, x1, southWindows)
	Architecture.wall(parent, "Z", xAt(LEN), Z_FAR, ZN, endWindows)
	for _, w in ipairs(southWindows) do
		Architecture.sashWindow(parent, "X", Z_FAR, w.center, w.width, w.bottom, w.top, trim, rng, { rows = 1, broken = mess * 0.15 })
	end
	for _, w in ipairs(endWindows) do
		Architecture.sashWindow(parent, "Z", xAt(LEN), w.center, w.width, w.bottom, w.top, trim, rng, { rows = 1, broken = mess * 0.15 })
	end

	-- Tiled dado round the room.
	local function dado(axis, face, normal, a, b)
		local size, pos = BuildUtil.axisBox(axis, b - a, TILE_H, 0.12, (a + b) / 2, TILE_H / 2, face + normal * 0.06)
		part(parent, "WallTiles", size, pos, Tiles, jitter(tile, rng, 0.04))
	end
	dado("X", iz0, 1, ix0, ix1)
	-- (the wall with the door in it: tiles either side, not across it)
	local dLo = math.min(xAt(DOOR_S - DOOR_W / 2), xAt(DOOR_S + DOOR_W / 2)) - 0.5
	local dHi = math.max(xAt(DOOR_S - DOOR_W / 2), xAt(DOOR_S + DOOR_W / 2)) + 0.5
	if dLo - ix0 > 0.2 then
		dado("X", iz1, -1, ix0, dLo)
	end
	if ix1 - dHi > 0.2 then
		dado("X", iz1, -1, dHi, ix1)
	end
	dado("Z", xAt(T / 2), dir, iz0, iz1)
	dado("Z", xAt(LEN - T / 2), -dir, iz0, iz1)

	-- The door from the landing: casing, and a swing door hanging open.
	local doorX = xAt(DOOR_S)
	Architecture.doorCasing(parent, "X", ZN, doorX, DOOR_W, DOOR_H, trim)
	local hinge = doorX - dir * DOOR_W / 2
	local swing = math.rad(rng:NextNumber(35, 100))
	local doorColor = jitter(pick({ Color3.fromRGB(150, 176, 186), Color3.fromRGB(196, 190, 170) }, rng), rng, 0.05)
	part(parent, "ToiletDoor", Vector3.new(DOOR_W - 0.2, DOOR_H - 0.3, 0.25), CFrame.new(hinge, DOOR_H / 2, iz1 - 0.15) * CFrame.Angles(0, dir * swing, 0) * CFrame.new(dir * (DOOR_W / 2 - 0.1), 0, 0), Wood, doorColor)

	-- A part placed relative to a frame (x across, y up, -z out into the room).
	local function pb(name, cf, x, y, z, size, material, color)
		return part(parent, name, size, cf * CFrame.new(x, y, z), material, color)
	end
	local CHROME = Color3.fromRGB(190, 192, 194)
	local WATER = Color3.fromRGB(150, 176, 180)

	-- Cubicles along the south wall.
	local cubicleDepth = 6
	local frontZ = iz0 + cubicleDepth
	local sStart, sEnd = 4.5, LEN - T / 2
	local count = 5
	local w = (sEnd - sStart) / count
	for k = 0, count do
		local s = sStart + k * w
		box("Partition", s - 0.12, s + 0.12, 0.4, 7.4, iz0, frontZ, Wood, doorColor)
		box("PartitionFoot", s - 0.15, s + 0.15, 0, 0.4, frontZ - 0.5, frontZ - 0.2, Metal, CHROME)
	end
	box("CubicleRail", sStart, sEnd, 7.4, 7.6, frontZ - 0.1, frontZ + 0.1, Metal, CHROME)
	for k = 0, count - 1 do
		local sa, sb = sStart + k * w, sStart + (k + 1) * w
		local mid = (sa + sb) / 2
		-- Frame on the floor at the back wall, facing out of the cubicle.
		local back = CFrame.lookAt(at(mid, 0, iz0), at(mid, 0, iz0 + 1))
		if rng:NextNumber() < 0.7 then
			-- Squat toilet on a tiled step, hood towards the back wall.
			pb("ToiletStep", back, 0, 0.25, -2.1, Vector3.new(w - 0.35, 0.5, 4.2), Tiles, jitter(tile, rng, 0.04))
			pb("PanPlate", back, 0, 0.52, -2.2, Vector3.new(1.5, 0.06, 2.9), Smooth, PORCELAIN)
			for _, sx in ipairs({ -0.7, 0.7 }) do
				pb("PanRim", back, sx, 0.62, -2.2, Vector3.new(0.12, 0.16, 2.8), Smooth, PORCELAIN)
			end
			pb("PanRim", back, 0, 0.62, -3.6, Vector3.new(1.5, 0.16, 0.12), Smooth, PORCELAIN)
			local water = pb("PanWater", back, 0, 0.66, -1.4, Vector3.new(1.1, 0.02, 1.1), Glass, WATER)
			water.Transparency = 0.3
			pb("PanBowl", back, 0, 0.6, -2.5, Vector3.new(1.1, 0.02, 1.4), Smooth, Color3.fromRGB(206, 206, 200))
			cylinder(parent, "PanHood", 1.4, 1.4, back * CFrame.new(0, 0.5, -0.8), Smooth, PORCELAIN)
			-- Flush: a high cistern with a pull chain, or a lever valve.
			if rng:NextNumber() < 0.5 then
				pb("Cistern", back, 0, 7.8, -0.4, Vector3.new(1.8, 1.1, 0.7), Smooth, PORCELAIN)
				cylinder(parent, "FlushPipe", 7.2, 0.22, back * CFrame.new(0, 4.2, -0.2) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
				cylinder(parent, "PullChain", 2.6, 0.05, back * CFrame.new(0.7, 6, -0.7) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
				pb("ChainHandle", back, 0.7, 4.6, -0.7, Vector3.new(0.2, 0.4, 0.2), Smooth, Color3.fromRGB(40, 40, 42))
			else
				cylinder(parent, "FlushPipe", 2.6, 0.25, back * CFrame.new(0, 1.8, -0.2) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
				pb("FlushValve", back, 0, 3.3, -0.3, Vector3.new(0.5, 0.6, 0.5), Metal, CHROME)
				pb("FlushLever", back, 0.4, 3.3, -0.45, Vector3.new(0.6, 0.1, 0.1), Metal, CHROME)
			end
		else
			-- Western toilet: bowl on a pedestal, seat, lid up, tank.
			pb("ToiletPedestal", back, 0, 0.55, -1.7, Vector3.new(0.9, 1.1, 1.4), Smooth, PORCELAIN)
			cylinder(parent, "ToiletBowl", 0.5, 1.8, back * CFrame.new(0, 1.35, -2) * CFrame.Angles(0, 0, math.rad(90)), Smooth, PORCELAIN)
			local water = cylinder(parent, "BowlWater", 0.05, 1.1, back * CFrame.new(0, 1.55, -2) * CFrame.Angles(0, 0, math.rad(90)), Glass, WATER)
			water.Transparency = 0.3
			local seatColor = if rng:NextNumber() < 0.5 then PORCELAIN else Color3.fromRGB(200, 196, 184)
			cylinder(parent, "ToiletSeat", 0.12, 1.9, back * CFrame.new(0, 1.66, -2) * CFrame.Angles(0, 0, math.rad(90)), Smooth, seatColor)
			cylinder(parent, "ToiletLid", 0.12, 1.8, back * CFrame.new(0, 2.6, -0.95) * CFrame.Angles(math.rad(10), 0, 0) * CFrame.Angles(0, math.rad(90), 0), Smooth, seatColor)
			pb("ToiletTank", back, 0, 2.2, -0.45, Vector3.new(1.8, 1.7, 0.8), Smooth, PORCELAIN)
			pb("TankLid", back, 0, 3.1, -0.45, Vector3.new(1.9, 0.15, 0.9), Smooth, PORCELAIN)
			pb("TankLever", back, -0.6, 2.8, -0.9, Vector3.new(0.4, 0.08, 0.1), Metal, CHROME)
		end
		-- Paper holder on the side partition, a brush, and a bin on girls' floors.
		local side = CFrame.lookAt(at(sb - 0.12, 0, iz0 + 3.2), at(sa, 0, iz0 + 3.2))
		pb("PaperHolder", side, 0, 2.3, -0.12, Vector3.new(0.6, 0.15, 0.25), Metal, CHROME)
		if rng:NextNumber() > mess * 0.5 then
			cylinder(parent, "PaperRoll", 0.5, 0.5, side * CFrame.new(0, 2.05, -0.3), Smooth, Color3.fromRGB(236, 234, 228))
		end
		cylinder(parent, "BrushHolder", 0.6, 0.45, back * CFrame.new(w / 2 - 0.5, 0.3, -0.4) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(230, 230, 226))
		cylinder(parent, "BrushHandle", 1.3, 0.1, back * CFrame.new(w / 2 - 0.5, 1, -0.4) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(60, 120, 170))
		if not boys then
			pb("SanitaryBin", back, -w / 2 + 0.5, 0.5, -0.6, Vector3.new(0.6, 1, 0.8), Smooth, Color3.fromRGB(226, 214, 220))
		end

		-- Front: a strip above the door, and the door shut, open, or gone.
		box("CubicleHead", sa, sb, 6.8, 7.4, frontZ - 0.12, frontZ + 0.12, Wood, doorColor)
		local roll = rng:NextNumber()
		local leafW = sb - sa - 0.3
		local leafHinge = xAt(sa + 0.15)
		local doorCF
		if roll < 0.35 then
			doorCF = CFrame.new(xAt(mid), 3.6, frontZ)
		elseif roll < 0.85 then
			local open = math.rad(rng:NextNumber(40, 110))
			doorCF = CFrame.new(leafHinge, 3.6, frontZ) * CFrame.Angles(0, -dir * open, 0) * CFrame.new(dir * leafW / 2, 0, 0)
		end
		if doorCF then
			part(parent, "CubicleDoor", Vector3.new(leafW, 6.2, 0.2), doorCF, Wood, doorColor)
			local shut = roll < 0.35
			for _, face in ipairs({ -1, 1 }) do
				part(parent, "DoorHandle", Vector3.new(0.12, 0.5, 0.15), doorCF * CFrame.new(dir * (leafW / 2 - 0.35), 0, face * 0.17), Metal, CHROME)
				part(parent, "LockIndicator", Vector3.new(0.3, 0.15, 0.05), doorCF * CFrame.new(dir * (leafW / 2 - 0.35), 0.5, face * 0.12), Smooth, if shut then Color3.fromRGB(190, 40, 40) else Color3.fromRGB(50, 90, 170))
			end
		else
			part(parent, "FallenCubicleDoor", Vector3.new(leafW, 0.2, 6.2), CFrame.new(xAt(mid), 0.2, frontZ + 3.4) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.05, 0.05)), Wood, doorColor)
		end
	end

	-- Long trough sink down the end-classroom wall: a rimmed basin on
	-- brackets, a row of taps (a lemon soap in a net hanging off some), and
	-- mirrors on a shelf above.
	local sinkZ0, sinkZ1 = -32, -14
	local sinkLen = sinkZ1 - sinkZ0
	local sink = CFrame.lookAt(at(T / 2, 0, (sinkZ0 + sinkZ1) / 2), at(T / 2 + 1, 0, (sinkZ0 + sinkZ1) / 2))
	local basin = Color3.fromRGB(196, 198, 196)
	pb("SinkBottom", sink, 0, 2.3, -1.2, Vector3.new(sinkLen, 0.15, 2.2), Smooth, darken(basin, 0.9))
	pb("SinkFront", sink, 0, 2.7, -2.3, Vector3.new(sinkLen, 0.9, 0.15), Smooth, basin)
	pb("SinkBack", sink, 0, 2.8, -0.12, Vector3.new(sinkLen, 1.1, 0.12), Smooth, basin)
	for _, e in ipairs({ -1, 1 }) do
		pb("SinkEnd", sink, e * sinkLen / 2, 2.7, -1.2, Vector3.new(0.15, 0.9, 2.3), Smooth, basin)
	end
	pb("SinkRim", sink, 0, 3.18, -2.3, Vector3.new(sinkLen + 0.1, 0.08, 0.3), Smooth, darken(basin, 0.95))
	for bz = -sinkLen / 2 + 1.5, sinkLen / 2 - 1.5, 4 do
		pb("SinkBracket", sink, bz, 1.1, -1.4, Vector3.new(0.2, 2.2, 1.8), Metal, Color3.fromRGB(120, 122, 120))
		cylinder(parent, "DrainPipe", 2.2, 0.25, sink * CFrame.new(bz + 0.8, 1.1, -0.4) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
	end
	for tz = -sinkLen / 2 + 1.5, sinkLen / 2 - 1, 3 do
		cylinder(parent, "TapArm", 0.9, 0.18, sink * CFrame.new(tz, 4, -0.45) * CFrame.Angles(0, math.rad(90), 0), Metal, CHROME)
		cylinder(parent, "TapSpout", 0.5, 0.14, sink * CFrame.new(tz, 3.75, -0.9) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
		pb("TapHandle", sink, tz, 4.25, -0.5, Vector3.new(0.6, 0.12, 0.12), Metal, CHROME)
		if rng:NextNumber() < 0.35 then
			local soap = pb("LemonSoap", sink, tz + 0.1, 3.55, -0.75, Vector3.new(0.4, 0.4, 0.4), Smooth, Color3.fromRGB(236, 220, 90))
			soap.Shape = Enum.PartType.Ball
			cylinder(parent, "SoapNet", 0.5, 0.05, sink * CFrame.new(tz + 0.1, 3.85, -0.75) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(230, 120, 60))
		end
	end
	pb("MirrorShelf", sink, 0, 4.6, -0.3, Vector3.new(sinkLen, 0.1, 0.6), Glass, Color3.fromRGB(200, 208, 210))
	for mz = -sinkLen / 2 + 2, sinkLen / 2 - 2, 3.5 do
		if rng:NextNumber() > mess * 0.3 then
			pb("MirrorFrame", sink, mz, 6.5, -0.04, Vector3.new(3.1, 3.4, 0.06), Metal, CHROME)
			local mirror = pb("Mirror", sink * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-1.5, 1.5))), mz, 6.5, -0.09, Vector3.new(2.9, 3.2, 0.04), Glass, Color3.fromRGB(200, 208, 210))
			mirror.Reflectance = rng:NextNumber(0.3, 0.6)
			mirror.Transparency = 0.1
		end
	end

	if boys then
		-- Wall-hung urinals along the end wall: porcelain, a dark bowl,
		-- dividers between, a flush pipe along the wall, a gutter below.
		local zs = {}
		for z = -31, -13, 4.5 do
			table.insert(zs, z)
		end
		local endWall = function(z)
			return CFrame.lookAt(at(LEN - T / 2, 0, z), at(LEN - T / 2 - 1, 0, z))
		end
		for _, z in ipairs(zs) do
			local u = endWall(z)
			pb("Urinal", u, 0, 2.6, -0.55, Vector3.new(1.4, 2.6, 1.1), Smooth, PORCELAIN)
			pb("UrinalBowl", u, 0, 2.3, -1.14, Vector3.new(1, 1.7, 0.04), Smooth, Color3.fromRGB(200, 206, 206))
			pb("UrinalLip", u, 0, 1.4, -1.05, Vector3.new(1.3, 0.2, 0.2), Smooth, PORCELAIN)
			cylinder(parent, "UrinalFlush", 2.4, 0.18, u * CFrame.new(0, 5.1, -0.3) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
			pb("FlushButton", u, 0, 4.5, -0.45, Vector3.new(0.3, 0.3, 0.2), Metal, CHROME)
			cylinder(parent, "UrinalDrain", 1.2, 0.2, u * CFrame.new(0, 0.7, -0.3) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)
		end
		for k = 1, #zs - 1 do
			local u = endWall((zs[k] + zs[k + 1]) / 2)
			pb("UrinalDivider", u, 0, 3, -0.9, Vector3.new(0.1, 3, 1.6), Smooth, PORCELAIN)
		end
		local first, last = endWall(zs[1] - 1), endWall(zs[#zs] + 1)
		cylinder(parent, "FlushMain", (last.Position - first.Position).Magnitude, 0.22, CFrame.lookAt((first * CFrame.new(0, 6.3, -0.3)).Position, (last * CFrame.new(0, 6.3, -0.3)).Position) * CFrame.Angles(0, math.rad(90), 0), Metal, CHROME)
		pb("Gutter", endWall((zs[1] + zs[#zs]) / 2), 0, 0.02, -1.6, Vector3.new(zs[#zs] - zs[1] + 3, 0.04, 1), Smooth, Color3.fromRGB(90, 96, 96))
	else
		-- Cleaners' corner where the urinals would be: slop sink with a tap
		-- and a mop hung over it, and a row of lockers.
		local slop = CFrame.lookAt(at(LEN - T / 2, 0, -29), at(LEN - T / 2 - 1, 0, -29))
		pb("SlopSink", slop, 0, 1, -1.2, Vector3.new(3.4, 2, 2.4), Concrete, Color3.fromRGB(170, 170, 164))
		pb("SlopBasin", slop, 0, 2.04, -1.2, Vector3.new(2.8, 0.05, 1.8), Smooth, Color3.fromRGB(110, 112, 110))
		cylinder(parent, "SlopTap", 1, 0.2, slop * CFrame.new(0, 3.6, -0.5) * CFrame.Angles(0, math.rad(90), 0), Metal, CHROME)
		cylinder(parent, "HungMop", 5, 0.15, slop * CFrame.new(1.2, 4.5, -0.3) * CFrame.Angles(0, 0, math.rad(90)), Wood, Color3.fromRGB(150, 120, 80))
		pb("MopHead", slop, 1.2, 1.9, -0.3, Vector3.new(0.9, 0.9, 0.5), Enum.Material.Fabric, Color3.fromRGB(200, 196, 180))
		for k = 0, 2 do
			local lock = CFrame.lookAt(at(LEN - T / 2, 0, -24 + k * 2.2), at(LEN - T / 2 - 1, 0, -24 + k * 2.2))
			local c = jitter(Color3.fromRGB(110, 124, 118), rng, 0.08)
			pb("CleaningLocker", lock, 0, 3.25, -0.8, Vector3.new(2.1, 6.5, 1.6), Metal, c)
			for v = 0, 3 do
				pb("LockerVent", lock, 0, 5.4 + v * 0.2, -1.64, Vector3.new(1.2, 0.06, 0.02), Metal, darken(c, 0.6))
			end
			pb("LockerHandle", lock, 0.7, 3.4, -1.65, Vector3.new(0.1, 0.5, 0.08), Metal, CHROME)
		end
	end
	-- A drain grate in the middle of the floor.
	cylinder(parent, "FloorDrain", 0.04, 0.9, CFrame.new(at(LEN / 2, 0.02, (frontZ + iz1) / 2)) * CFrame.Angles(0, 0, math.rad(90)), Metal, CHROME)

	-- Toilet slippers left by the door, a mop and bucket, a puddle or two.
	local slipperColor = if boys then Color3.fromRGB(60, 100, 150) else Color3.fromRGB(190, 90, 110)
	for k = 0, rng:NextInteger(1, 4) do
		local s, z = rng:NextNumber(3, 9), rng:NextNumber(iz1 - 4, iz1 - 1)
		local yaw = rng:NextNumber(0, math.pi * 2)
		for _, off in ipairs({ -0.35, 0.35 }) do
			part(parent, "Slipper", Vector3.new(0.55, 0.25, 1.2), CFrame.new(at(s, 0.13, z)) * CFrame.Angles(0, yaw + rng:NextNumber(-0.3, 0.3), 0) * CFrame.new(off, 0, 0), Smooth, slipperColor)
		end
	end
	if rng:NextNumber() < 0.6 then
		local s, z = rng:NextNumber(4, 20), rng:NextNumber(frontZ + 2, iz1 - 3)
		cylinder(parent, "MopBucket", 1.8, 2, CFrame.new(at(s, 0.9, z)) * CFrame.Angles(0, 0, math.rad(90)), Smooth, Color3.fromRGB(200, 170, 50))
		cylinder(parent, "MopHandle", 6, 0.2, CFrame.new(at(s, 3.4, z)) * CFrame.Angles(0, 0, math.rad(90 - rng:NextNumber(10, 25))), Wood, Color3.fromRGB(150, 120, 80))
	end
	for _ = 1, rng:NextInteger(1, 3) do
		local d = rng:NextNumber(2, 5)
		local puddle = BuildUtil.disc(parent, "Puddle", d, 0.04, at(rng:NextNumber(3, 12), 0.03, rng:NextNumber(sinkZ0, sinkZ1)), Smooth, Color3.fromRGB(60, 66, 66))
		puddle.Transparency = 0.2
		puddle.Reflectance = 0.35
		puddle.CanCollide = false
	end

	Architecture.ceilingLight(parent, at(LEN / 2, H - 0.3, (iz0 + iz1) / 2 + 4), rollLight(rng, mess))
	if rng:NextNumber() < 0.5 then
		Architecture.ceilingLight(parent, at(LEN / 2, H - 0.3, frontZ + 1), rollLight(rng, mess))
	end

	local bounds = { x0 = ix0, x1 = ix1, z0 = frontZ, z1 = iz1 }
	Weathering.cobwebs(parent, { x0 = ix0, x1 = ix1, z0 = iz0, z1 = iz1 }, rng, mess)
	Weathering.floor(parent, bounds, rng, mess * 0.6, {})
end

-- Sign over the door, on the stairwell side.
local function doorSign(parent, xFace, dir, y, boys)
	local plate = part(parent, "ToiletSign", Vector3.new(3.4, 1.2, 0.1), Vector3.new(xFace + dir * DOOR_S, y + DOOR_H + 1, ZN + T / 2 + 0.06), Smooth, Color3.fromRGB(230, 226, 214))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = if boys then Color3.fromRGB(40, 70, 140) else Color3.fromRGB(170, 40, 60)
	label.Text = if boys then "男子便所" else "女子便所"
	label.Parent = gui
	gui.Parent = plate
end

-- The whole block beside the stairwell at `xFace` (running outward in
-- direction `dir`, as Stairwell.build).
function StairAnnex.build(parent, xFace, dir, rng)
	local block = model(parent, "ToiletBlock")
	for f = 1, Config.FLOORS do
		local boys = (f + (if dir > 0 then 0 else 1)) % 2 == 0
		local floorModel = model(block, string.format("Toilet%dF", f))
		storey(floorModel, xFace, dir, f, boys, rng)
		floorModel:PivotTo(floorModel:GetPivot() + Vector3.new(0, Config.floorY(f), 0))
		doorSign(block, xFace, dir, Config.floorY(f), boys)
	end
end

return StairAnnex
