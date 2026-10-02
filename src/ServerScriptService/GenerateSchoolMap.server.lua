-- Builds the school into workspace.GeneratedSchool when the game starts.
-- Play-mode changes are discarded on Stop, so every Play gives a fresh
-- random layout.
--
-- Generation takes a few seconds and yields as it goes, so characters are
-- held back until it's finished; otherwise players would spawn in empty
-- space and fall.
--
-- Prints a size report to Output each time: build time per stage, and
-- parts / lights per section, so we can see what the map costs as it grows.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SchoolGenerator = require(ReplicatedStorage:WaitForChild("School"):WaitForChild("SchoolGenerator"))

if workspace:FindFirstChild("GeneratedSchool") then
	return
end

Players.CharacterAutoLoads = false

-- The map goes far deeper than Roblox's default kill height (-500): the
-- hidden sea's surface is at -520 and the building's body runs down to
-- -1900. Try to lower it; the report says if it has to be set by hand.
local KILL_HEIGHT = -2500
pcall(function()
	workspace.FallenPartsDestroyHeight = KILL_HEIGHT
end)

-- Remove Studio's template objects so the corridor spawn is the only one.
for _, name in ipairs({ "SpawnLocation", "Baseplate" }) do
	local default = workspace:FindFirstChild(name)
	if default then
		default:Destroy()
	end
end

local started = os.clock()
local root, timings, routesChecked, routeReport = SchoolGenerator.generate()
local total = os.clock() - started

-- ===== Size report =====

local function measure(instance)
	local parts, lights = 0, 0
	for _, d in ipairs(instance:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("Light") then
			lights += 1
		end
	end
	return parts, lights
end

local rows = {}
local floorParts, floorLights = 0, 0
for _, child in ipairs(root:GetChildren()) do
	local parts, lights = measure(child)
	if child.Name:match("^Floor%d+$") then
		floorParts += parts
		floorLights += lights
	elseif parts > 0 then
		table.insert(rows, { child.Name, parts, lights })
	end
end
table.insert(rows, { "School floors (all)", floorParts, floorLights })
table.sort(rows, function(a, b)
	return a[2] > b[2]
end)

local lines = { "", "===== Map size report =====" }
local allParts, allLights = 0, 0
for _, r in ipairs(rows) do
	table.insert(lines, string.format("  %-24s %7d parts  %4d lights", r[1], r[2], r[3]))
	allParts += r[2]
	allLights += r[3]
end
table.insert(lines, string.format("  %-24s %7d parts  %4d lights", "TOTAL", allParts, allLights))
table.insert(lines, "  Build time:")
for _, t in ipairs(timings) do
	table.insert(lines, string.format("    %-26s %6.2fs", t[1], t[2]))
end
table.insert(lines, string.format("    %-26s %6.2fs", "TOTAL", total))
table.insert(lines, string.format("  Routes: %d checked, %d had rock in the way (cleared)", routesChecked, #routeReport))
for _, r in ipairs(routeReport) do
	table.insert(lines, "    " .. r)
end
table.insert(lines, if workspace.FallenPartsDestroyHeight <= KILL_HEIGHT then string.format("  Kill height: %d", workspace.FallenPartsDestroyHeight) else string.format("  Kill height: %d  <-- set Workspace.FallenPartsDestroyHeight to %d in Properties", workspace.FallenPartsDestroyHeight, KILL_HEIGHT))
table.insert(lines, string.format("  Streaming: %s", if workspace.StreamingEnabled then "ON" else "OFF (turn on in Workspace properties)"))
print(table.concat(lines, "\n"))

-- ===== Let players in =====

local spawn = root:FindFirstChild("CorridorSpawn")

local function spawnPlayer(player)
	if player.Character then
		return
	end
	-- With streaming on, make sure the corridor has reached the player
	-- before their character drops into it.
	if workspace.StreamingEnabled and spawn then
		pcall(function()
			player:RequestStreamAroundAsync(spawn.Position, 10)
		end)
	end
	player:LoadCharacter()
end

Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	task.spawn(spawnPlayer, player)
end
