-- Light, steady rain for the whole world, using buildthomas's Rain module
-- (ReplicatedStorage.Rain, Apache 2.0 - its licence notice stays in the
-- module). The module handles everything that makes rain convincing:
-- proper streak textures, rain that stops at roofs and ledges (with
-- straight streaks still falling past open edges), splashes where drops
-- land, and a rain sound that fades out as you move indoors.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rain = require(ReplicatedStorage:WaitForChild("Rain"))

-- Light rather than stormy: fewer drops, slightly slower, a soft
-- blue-grey. Falls almost straight down: any real slant carries streaks
-- that spawn over open sky in under the edges of roofs.
Rain:SetIntensityRatio(0.4)
Rain:SetSpeedRatio(0.85)
Rain:SetColor(Color3.fromRGB(206, 214, 224))
Rain:SetTransparency(0.15)
Rain:SetDirection(Vector3.new(0.03, -1, 0.015).Unit)
Rain:SetVolume(0.15)

-- Rain is stopped by solid-looking things but passes through anything
-- mostly see-through (windows, fence mesh, cobwebs, vines).
Rain:SetCollisionMode(Rain.CollisionMode.Function, function(part)
	return part.Transparency < 0.5
end)

Rain:Enable()
