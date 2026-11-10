--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(script.Parent.Arena)
local PlayerState = require(script.Parent.PlayerState)
local Constants = require(ReplicatedStorage.Shared.Constants)

type Gem = {
	model: Model,
	x: number,
	z: number,
	value: number,
}

local GEM_ROTATION = CFrame.Angles(math.rad(34), math.rad(38), math.rad(-22))
local GEM_HEIGHT = 1.25
local COLLAR_BRONZE = Color3.fromRGB(142, 110, 62)

local gems: { Gem } = {}

local GemService = {}

local function styleFor(value: number): (Color3, Color3, number)
	if value >= 20 then
		return Color3.fromRGB(195, 65, 240), Color3.fromRGB(255, 150, 255), 1.65
	elseif value >= 5 then
		return Color3.fromRGB(45, 130, 255), Color3.fromRGB(135, 215, 255), 1.3
	end
	return Color3.fromRGB(36, 195, 142), Color3.fromRGB(115, 255, 198), 1.0
end

local function makeCrystalPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material
	part.Color = color
	part.Transparency = transparency
	part.Size = size
	part.CFrame = cframe
	part.Parent = parent
	return part
end

-- Faceted Soul XP Crystal (matches xp_soul_crystal.sc + TextureCraft necrotic emerald/gold palette)
local function buildSoulCrystal(outerColor: Color3, coreColor: Color3, scale: number): Model
	local model = Instance.new("Model")
	model.Name = "XpSoulCrystal"

	local body = makeCrystalPart(
		"CrystalFacetA",
		Vector3.new(0.88, 1.95, 0.88) * scale,
		CFrame.identity,
		outerColor,
		Enum.Material.Glass,
		0.12,
		model
	)
	model.PrimaryPart = body

	local core = makeCrystalPart(
		"SoulCoreFacetB",
		Vector3.new(0.82, 1.72, 0.82) * scale,
		CFrame.Angles(0, math.pi * 0.25, 0),
		coreColor,
		Enum.Material.Neon,
		0.02,
		model
	)
	makeCrystalPart(
		"ApexCrown",
		Vector3.new(0.52, 2.25, 0.52) * scale,
		CFrame.Angles(0, math.pi * 0.125, 0),
		coreColor,
		Enum.Material.Neon,
		0,
		model
	)
	makeCrystalPart(
		"RunicCollar",
		Vector3.new(1.18, 0.3, 1.18) * scale,
		CFrame.Angles(0, math.pi * 0.25, 0),
		COLLAR_BRONZE,
		Enum.Material.Metal,
		0,
		model
	)

	local glow = Instance.new("PointLight")
	glow.Color = coreColor
	glow.Brightness = 1.35
	glow.Range = 8 * scale
	glow.Shadows = false
	glow.Parent = core

	return model
end

local function place(gem: Gem)
	gem.model:PivotTo(CFrame.new(gem.x, Arena.groundY + GEM_HEIGHT, gem.z) * GEM_ROTATION)
end

function GemService.spawn(position: Vector3, value: number)
	if #gems >= Constants.MAX_GEMS then
		local oldest = table.remove(gems, 1)
		if oldest then
			value += oldest.value
			oldest.model:Destroy()
		end
	end

	local outerColor, coreColor, scale = styleFor(value)
	local model = buildSoulCrystal(outerColor, coreColor, scale)
	model.Parent = Arena.gemsFolder

	local gem: Gem = { model = model, x = position.X, z = position.Z, value = value }
	place(gem)
	table.insert(gems, gem)
end

function GemService.step(dt: number)
	local targets = PlayerState.getTargets()
	if #targets == 0 then
		return
	end

	for i = #gems, 1, -1 do
		local gem = gems[i]
		local nearest: PlayerState.Target? = nil
		local nearestDistSq = math.huge
		for _, target in targets do
			local dx = target.position.X - gem.x
			local dz = target.position.Z - gem.z
			local distSq = dx * dx + dz * dz
			if distSq < nearestDistSq then
				nearest = target
				nearestDistSq = distSq
			end
		end

		if nearest and nearestDistSq <= nearest.state.pickupRadius ^ 2 then
			local dist = math.sqrt(nearestDistSq)
			if dist <= Constants.GEM_COLLECT_DISTANCE then
				local val = gem.value
				table.remove(gems, i)
				gem.model:Destroy()
				PlayerState.addXp(nearest.state, val)
			else
				local step = math.min(dist, Constants.GEM_MAGNET_SPEED * dt)
				gem.x += (nearest.position.X - gem.x) / dist * step
				gem.z += (nearest.position.Z - gem.z) / dist * step
				place(gem)
			end
		end
	end
end

function GemService.clearAll()
	for _, gem in gems do
		gem.model:Destroy()
	end
	table.clear(gems)
end

return GemService
