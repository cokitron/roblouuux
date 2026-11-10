--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local GraveyardBuildings = require(script.Parent.GraveyardBuildings)
local PlayerState = require(script.Parent.PlayerState)
local Constants = require(ReplicatedStorage.Shared.Constants)

export type Obstacle = {
	cx: number,
	cz: number,
	halfX: number,
	halfZ: number,
	cos: number,
	sin: number,
	boundRadius: number,
	tier: number,
}

export type CryptAnchor = {
	x: number,
	z: number,
}

export type SoulUrn = {
	x: number,
	z: number,
	health: number,
	radius: number,
	dead: boolean,
	model: Model?,
}

export type BrazierShrine = {
	id: number,
	name: string,
	x: number,
	z: number,
	progress: number,
	ignited: boolean,
	flamePart: Part?,
	beamPart: Part?,
	ringPart: Part?,
	label: TextLabel?,
}

export type ReliquaryChest = {
	x: number,
	z: number,
	isBoss: boolean,
	claimed: boolean,
	model: Model?,
}

export type TrainingDummy = {
	id: number,
	name: string,
	x: number,
	y: number,
	z: number,
	radius: number,
}

local HALF = Constants.ARENA_HALF_SIZE
local SIZE = HALF * 2
local WALL_HEIGHT = 40
local WALL_THICKNESS = 4
local SPAWN_CLEAR_RADIUS = 20
local MIN_OBSTACLE_CLEARANCE = 15

local STONE_DARK = Color3.fromRGB(68, 73, 78)
local STONE_MID = Color3.fromRGB(88, 94, 100)
local STONE_MOSS = Color3.fromRGB(62, 78, 64)
local IRON_DARK = Color3.fromRGB(36, 38, 43)
local BRONZE_PLAQUE = Color3.fromRGB(116, 92, 62)
local RUNE_CYAN = Color3.fromRGB(52, 215, 185)
local NECROTIC_VIOLET = Color3.fromRGB(145, 82, 235)
local LANTERN_AMBER = Color3.fromRGB(255, 178, 72)
local GRASS_DARK = Color3.fromRGB(48, 74, 56)
local GRASS_FROST = Color3.fromRGB(74, 112, 92)
local ROOT_BARK = Color3.fromRGB(66, 50, 38)

local Arena = {
	groundY = 0,
	gemsFolder = nil :: Folder?,
}

local arenaFolder: Folder? = nil
local obstacles: { Obstacle } = {}
local cryptAnchors: { CryptAnchor } = {}
local soulUrns: { SoulUrn } = {}
local shrines: { BrazierShrine } = {}
local reliquaryChests: { ReliquaryChest } = {}
local trainingDummies: { TrainingDummy } = {}
local dummyHits: { { t: number, dmg: number } } = {}
local totalDummyDamage = 0
local dpsMeterLabel: TextLabel? = nil
local coopPortalLabel: TextLabel? = nil
local championsWestLabel: TextLabel? = nil
local championsEastLabel: TextLabel? = nil
local prefabs: { [string]: Model } = {}

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	shape: Enum.PartType?,
	canCollide: boolean?,
	transparency: number?,
	castShadow: boolean?,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material
	part.Shape = props.shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = props.canCollide or false
	part.CanTouch = false
	part.CanQuery = (props.canCollide or false) and (props.transparency or 0) < 0.9
	part.Transparency = props.transparency or 0
	part.CastShadow = if props.castShadow ~= nil then props.castShadow else false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

local function createPivotBase(model: Model, size: Vector3): Part
	local root = makePart({
		name = "PivotRoot",
		size = size,
		cframe = CFrame.new(0, size.Y * 0.5, 0),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
		transparency = 1,
	})
	model.PrimaryPart = root
	return root
end

local function buildPrefabTemplates(): { [string]: Model }
	local built: { [string]: Model } = {}

	-- 1. Gothic Cross Headstone (matches grave_cross_headstone.sc + PBR palette)
	do
		local model = Instance.new("Model")
		model.Name = "Grave_Cross"
		createPivotBase(model, Vector3.new(2.2, 4.2, 0.95))

		makePart({
			name = "MossyPlinth",
			size = Vector3.new(2.2, 0.55, 0.95),
			cframe = CFrame.new(0, 0.275, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "UpperPlinth",
			size = Vector3.new(1.75, 0.45, 0.78),
			cframe = CFrame.new(0, 0.75, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "CrossShaft",
			size = Vector3.new(0.82, 3.25, 0.55),
			cframe = CFrame.new(0, 2.55, 0),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "CrossArm",
			size = Vector3.new(2.05, 0.72, 0.58),
			cframe = CFrame.new(0, 2.95, 0),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "EpitaphPlaque",
			size = Vector3.new(0.64, 0.82, 0.6),
			cframe = CFrame.new(0, 1.65, 0),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			parent = model,
		})
		built.Grave_Cross = model
	end

	-- 2. Arched Rune Tombstone (matches grave_arched_tombstone.sc + glowing cyan rune cross)
	do
		local model = Instance.new("Model")
		model.Name = "Grave_Arched"
		createPivotBase(model, Vector3.new(2.5, 4.0, 0.95))

		makePart({
			name = "MossyPlinth",
			size = Vector3.new(2.5, 0.55, 0.95),
			cframe = CFrame.new(0, 0.275, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "TabletBody",
			size = Vector3.new(2.1, 2.45, 0.68),
			cframe = CFrame.new(0, 1.75, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "ArchCrown",
			size = Vector3.new(0.68, 2.1, 2.1),
			cframe = CFrame.new(0, 2.95, 0) * CFrame.Angles(0, math.pi * 0.5, 0),
			color = STONE_MID,
			material = Enum.Material.Slate,
			shape = Enum.PartType.Cylinder,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "RuneVertical",
			size = Vector3.new(0.18, 1.45, 0.72),
			cframe = CFrame.new(0, 2.25, 0),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			parent = model,
		})
		makePart({
			name = "RuneHorizontal",
			size = Vector3.new(0.95, 0.18, 0.72),
			cframe = CFrame.new(0, 2.48, 0),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			parent = model,
		})
		built.Grave_Arched = model
	end

	-- 3. Cursed Crypt Sarcophagus (matches graveyard_sarcophagus.sc; collidable monument)
	do
		local model = Instance.new("Model")
		model.Name = "Grave_Sarcophagus"
		createPivotBase(model, Vector3.new(3.8, 2.65, 7.2))

		makePart({
			name = "SteppedBase",
			size = Vector3.new(3.8, 0.55, 7.2),
			cframe = CFrame.new(0, 0.275, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "CoffinBody",
			size = Vector3.new(3.2, 1.65, 6.5),
			cframe = CFrame.new(0, 1.35, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
			canCollide = true,
			castShadow = true,
		})
		makePart({
			name = "NecroticSeam",
			size = Vector3.new(3.05, 0.16, 6.35),
			cframe = CFrame.new(0, 2.18, 0),
			color = NECROTIC_VIOLET,
			material = Enum.Material.Neon,
			parent = model,
		})
		local lidCf = CFrame.new(0.12, 2.42, 0) * CFrame.Angles(0, math.rad(3.5), 0)
		makePart({
			name = "CoffinLid",
			size = Vector3.new(3.4, 0.38, 6.75),
			cframe = lidCf,
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "LidCrossSpine",
			size = Vector3.new(0.38, 0.14, 4.6),
			cframe = lidCf * CFrame.new(0, 0.24, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "LidCrossBar",
			size = Vector3.new(1.85, 0.14, 0.38),
			cframe = lidCf * CFrame.new(0, 0.24, -0.85),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
		built.Grave_Sarcophagus = model
	end

	-- 4. Haunted Lantern Post (matches graveyard_lantern_post.sc + warm PointLight)
	do
		local model = Instance.new("Model")
		model.Name = "Graveyard_Lantern"
		createPivotBase(model, Vector3.new(1.6, 7.4, 1.6))

		makePart({
			name = "StonePedestal",
			size = Vector3.new(1.35, 1.35, 1.35),
			cframe = CFrame.new(0, 0.675, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "IronPost",
			size = Vector3.new(0.32, 5.8, 0.32),
			cframe = CFrame.new(0, 4.2, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "CrossArm",
			size = Vector3.new(1.45, 0.24, 0.24),
			cframe = CFrame.new(0.52, 6.95, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		makePart({
			name = "LanternHood",
			size = Vector3.new(0.82, 0.26, 0.82),
			cframe = CFrame.new(1.05, 6.55, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		local flame = makePart({
			name = "FlameCore",
			size = Vector3.new(0.46, 0.68, 0.46),
			cframe = CFrame.new(1.05, 6.08, 0),
			color = LANTERN_AMBER,
			material = Enum.Material.Neon,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 182, 92)
		light.Brightness = 2.0
		light.Range = 38
		light.Shadows = false
		light.Parent = flame

		built.Graveyard_Lantern = model
	end

	-- 5. Wrought-Iron & Stone Fence Panel (8 studs wide; used for interior blocking walls)
	do
		local model = Instance.new("Model")
		model.Name = "Graveyard_Fence"
		createPivotBase(model, Vector3.new(8.0, 4.4, 1.1))

		makePart({
			name = "StoneCurb",
			size = Vector3.new(8.0, 0.65, 0.78),
			cframe = CFrame.new(0, 0.325, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		for _, side in { -3.65, 3.65 } do
			makePart({
				name = "StonePillar",
				size = Vector3.new(1.05, 4.1, 1.05),
				cframe = CFrame.new(side, 2.05, 0),
				color = STONE_DARK,
				material = Enum.Material.Slate,
				parent = model,
				castShadow = true,
			})
			makePart({
				name = "PillarCap",
				size = Vector3.new(1.3, 0.34, 1.3),
				cframe = CFrame.new(side, 4.25, 0),
				color = STONE_MID,
				material = Enum.Material.Slate,
				parent = model,
			})
		end
		makePart({
			name = "BottomRail",
			size = Vector3.new(6.4, 0.2, 0.2),
			cframe = CFrame.new(0, 1.05, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		makePart({
			name = "TopRail",
			size = Vector3.new(6.4, 0.2, 0.2),
			cframe = CFrame.new(0, 3.55, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		for i = -2, 2 do
			local bx = i * 1.15
			makePart({
				name = "IronPicket",
				size = Vector3.new(0.18, 3.25, 0.18),
				cframe = CFrame.new(bx, 2.25, 0),
				color = IRON_DARK,
				material = Enum.Material.CorrodedMetal,
				parent = model,
			})
			makePart({
				name = "SpearFinial",
				size = Vector3.new(0.26, 0.36, 0.26),
				cframe = CFrame.new(bx, 4.02, 0) * CFrame.Angles(0, math.pi * 0.25, 0),
				color = IRON_DARK,
				material = Enum.Material.CorrodedMetal,
				parent = model,
			})
		end
		built.Graveyard_Fence = model
	end

	-- 6. Ground Clutter: Overgrown Cemetery Grass Tuft (matches ground_grass_tuft.sc)
	do
		local model = Instance.new("Model")
		model.Name = "Ground_GrassTuft"
		createPivotBase(model, Vector3.new(1.8, 1.4, 1.8))

		local bladeOffsets = {
			{ x = 0, z = 0, h = 1.35, rx = 0.12, rz = -0.08, col = GRASS_FROST },
			{ x = -0.38, z = 0.22, h = 1.1, rx = -0.24, rz = 0.28, col = GRASS_DARK },
			{ x = 0.42, z = 0.18, h = 1.15, rx = 0.22, rz = -0.3, col = GRASS_DARK },
			{ x = -0.22, z = -0.36, h = 0.95, rx = -0.3, rz = -0.18, col = GRASS_FROST },
			{ x = 0.28, z = -0.32, h = 1.0, rx = 0.26, rz = 0.22, col = GRASS_DARK },
		}
		for _, b in bladeOffsets do
			makePart({
				name = "GrassBlade",
				size = Vector3.new(0.22, b.h, 0.34),
				cframe = CFrame.new(b.x, b.h * 0.45, b.z) * CFrame.Angles(b.rx, 0, b.rz),
				color = b.col,
				material = Enum.Material.Grass,
				parent = model,
			})
		end
		built.Ground_GrassTuft = model
	end

	-- 7. Ground Clutter: Gnarled Dead Roots (matches ground_dead_roots.sc)
	do
		local model = Instance.new("Model")
		model.Name = "Ground_DeadRoots"
		createPivotBase(model, Vector3.new(3.2, 0.75, 3.2))

		makePart({
			name = "RootMain",
			size = Vector3.new(2.8, 0.36, 0.42),
			cframe = CFrame.new(0, 0.18, 0) * CFrame.Angles(0.08, 0.25, 0.12),
			color = ROOT_BARK,
			material = Enum.Material.Wood,
			parent = model,
		})
		makePart({
			name = "RootBranchA",
			size = Vector3.new(2.1, 0.28, 0.34),
			cframe = CFrame.new(-0.35, 0.15, 0.55) * CFrame.Angles(-0.1, 1.15, -0.08),
			color = ROOT_BARK,
			material = Enum.Material.Wood,
			parent = model,
		})
		makePart({
			name = "RootBranchB",
			size = Vector3.new(1.85, 0.25, 0.3),
			cframe = CFrame.new(0.45, 0.14, -0.48) * CFrame.Angles(0.12, -0.95, 0.1),
			color = STONE_MOSS,
			material = Enum.Material.Wood,
			parent = model,
		})
		built.Ground_DeadRoots = model
	end

	-- 8. Ground Clutter: Broken Slate Rubble Cluster (matches ground_rubble_cluster.sc)
	do
		local model = Instance.new("Model")
		model.Name = "Ground_RubbleCluster"
		createPivotBase(model, Vector3.new(2.8, 0.5, 2.8))

		makePart({
			name = "TombShardMain",
			size = Vector3.new(1.35, 0.28, 0.95),
			cframe = CFrame.new(-0.25, 0.14, 0.15) * CFrame.Angles(0.06, 0.4, -0.08),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "MossCobbleA",
			size = Vector3.new(0.85, 0.24, 0.75),
			cframe = CFrame.new(0.68, 0.12, -0.32) * CFrame.Angles(-0.05, 1.1, 0.04),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "MossCobbleB",
			size = Vector3.new(0.68, 0.2, 0.62),
			cframe = CFrame.new(0.22, 0.1, 0.78) * CFrame.Angles(0.04, -0.6, -0.05),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
		})
		built.Ground_RubbleCluster = model
	end

	-- 9. Haunted Withered Dead Tree (replaces bright green NaturePack trees)
	do
		local model = Instance.new("Model")
		model.Name = "Graveyard_DeadTree"
		createPivotBase(model, Vector3.new(3.5, 9.5, 3.5))

		makePart({
			name = "RootMound",
			size = Vector3.new(2.8, 0.6, 2.8),
			cframe = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0.4, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "GnarledTrunk",
			size = Vector3.new(1.35, 6.2, 1.35),
			cframe = CFrame.new(0, 3.2, 0) * CFrame.Angles(0.08, 0.2, -0.06),
			color = ROOT_BARK,
			material = Enum.Material.Wood,
			parent = model,
			canCollide = true,
			castShadow = true,
		})
		makePart({
			name = "UpperBoughA",
			size = Vector3.new(0.68, 4.2, 0.68),
			cframe = CFrame.new(-1.1, 7.2, 0.4) * CFrame.Angles(0.28, 0.3, 0.48),
			color = ROOT_BARK,
			material = Enum.Material.Wood,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "UpperBoughB",
			size = Vector3.new(0.62, 3.8, 0.62),
			cframe = CFrame.new(1.15, 6.8, -0.35) * CFrame.Angles(-0.24, -0.4, -0.52),
			color = ROOT_BARK,
			material = Enum.Material.Wood,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "UpperBoughC",
			size = Vector3.new(0.45, 3.1, 0.45),
			cframe = CFrame.new(0.15, 7.6, 1.05) * CFrame.Angles(0.55, 0.1, -0.15),
			color = ROOT_BARK,
			material = Enum.Material.Wood,
			parent = model,
		})
		built.Graveyard_DeadTree = model
	end

	-- 10. Gothic Cemetery Obelisk Monument (replaces NaturePack rocks/shrubs)
	do
		local model = Instance.new("Model")
		model.Name = "Graveyard_Obelisk"
		createPivotBase(model, Vector3.new(2.8, 6.8, 2.8))

		makePart({
			name = "SteppedPlinth",
			size = Vector3.new(2.8, 0.75, 2.8),
			cframe = CFrame.new(0, 0.375, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "LowerColumn",
			size = Vector3.new(1.85, 2.8, 1.85),
			cframe = CFrame.new(0, 2.1, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
			canCollide = true,
			castShadow = true,
		})
		makePart({
			name = "UpperSpire",
			size = Vector3.new(1.35, 3.1, 1.35),
			cframe = CFrame.new(0, 4.95, 0),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
			castShadow = true,
		})
		makePart({
			name = "SpireCrown",
			size = Vector3.new(0.85, 0.75, 0.85),
			cframe = CFrame.new(0, 6.75, 0) * CFrame.Angles(0, math.pi * 0.25, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "ObeliskRune",
			size = Vector3.new(0.22, 2.2, 1.42),
			cframe = CFrame.new(0, 4.85, 0),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			parent = model,
		})
		built.Graveyard_Obelisk = model
	end

	-- 11. Sanctuary Relic Showcase: Giant Faceted Soul XP Crystal (matches xp_soul_crystal.sc)
	do
		local model = Instance.new("Model")
		model.Name = "Relic_SoulCrystal"
		createPivotBase(model, Vector3.new(2.2, 4.4, 2.2))

		makePart({
			name = "CrystalFacetOuter",
			size = Vector3.new(1.5, 3.4, 1.5),
			cframe = CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(14), math.rad(25), math.rad(-12)),
			color = Color3.fromRGB(36, 195, 142),
			material = Enum.Material.Glass,
			transparency = 0.15,
			parent = model,
		})
		local core = makePart({
			name = "SoulCoreInner",
			size = Vector3.new(1.25, 2.95, 1.25),
			cframe = CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(14), math.rad(70), math.rad(-12)),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			parent = model,
		})
		makePart({
			name = "RunicBronzeCollar",
			size = Vector3.new(1.95, 0.42, 1.95),
			cframe = CFrame.new(0, 1.45, 0) * CFrame.Angles(0, math.pi * 0.25, 0),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = RUNE_CYAN
		light.Brightness = 2.2
		light.Range = 24
		light.Shadows = false
		light.Parent = core
		built.Relic_SoulCrystal = model
	end

	-- 12. Sanctuary Relic Showcase: Runic Astrolabe Guardian Orb (matches guardian_orb.sc)
	do
		local model = Instance.new("Model")
		model.Name = "Relic_GuardianOrb"
		createPivotBase(model, Vector3.new(2.8, 3.2, 2.8))

		local core = makePart({
			name = "SolarCore",
			size = Vector3.new(1.6, 1.6, 1.6),
			cframe = CFrame.new(0, 1.8, 0),
			color = LANTERN_AMBER,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = model,
		})
		makePart({
			name = "EquatorialRing",
			size = Vector3.new(0.26, 2.6, 2.6),
			cframe = CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			parent = model,
		})
		makePart({
			name = "MeridianRing",
			size = Vector3.new(0.22, 2.45, 2.45),
			cframe = CFrame.new(0, 1.8, 0) * CFrame.Angles(math.pi * 0.32, 0, 0),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = LANTERN_AMBER
		light.Brightness = 1.6
		light.Range = 16
		light.Shadows = false
		light.Parent = core
		built.Relic_GuardianOrb = model
	end

	-- 13. Sanctuary Relic Showcase: Arcane Spearhead Magic Bolt (matches magic_bolt.sc)
	do
		local model = Instance.new("Model")
		model.Name = "Relic_MagicBolt"
		createPivotBase(model, Vector3.new(2.0, 3.4, 2.0))

		local boltRot = CFrame.new(0, 1.9, 0) * CFrame.Angles(math.rad(-55), math.rad(25), 0)
		local core = makePart({
			name = "SpearCore",
			size = Vector3.new(0.48, 0.48, 2.75),
			cframe = boltRot,
			color = Color3.fromRGB(90, 220, 255),
			material = Enum.Material.Neon,
			parent = model,
		})
		makePart({
			name = "CrystalBladeH",
			size = Vector3.new(1.35, 0.24, 1.85),
			cframe = boltRot * CFrame.new(0, 0, -0.25),
			color = Color3.fromRGB(38, 165, 250),
			material = Enum.Material.Neon,
			parent = model,
		})
		makePart({
			name = "CrystalBladeV",
			size = Vector3.new(0.24, 1.35, 1.85),
			cframe = boltRot * CFrame.new(0, 0, -0.25),
			color = Color3.fromRGB(38, 165, 250),
			material = Enum.Material.Neon,
			parent = model,
		})
		makePart({
			name = "ArcaneCollar",
			size = Vector3.new(0.88, 0.88, 0.38),
			cframe = boltRot * CFrame.new(0, 0, 0.45) * CFrame.Angles(0, 0, math.pi * 0.25),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(90, 220, 255)
		light.Brightness = 1.6
		light.Range = 16
		light.Shadows = false
		light.Parent = core
		built.Relic_MagicBolt = model
	end

	-- Relic_CryptCleaver
	do
		local model = Instance.new("Model")
		model.Name = "Relic_CryptCleaver"
		createPivotBase(model, Vector3.new(3.5, 3.5, 1.2))
		local bladeCf = CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(-30))
		makePart({
			name = "ScytheShaft",
			size = Vector3.new(0.35, 3.8, 0.35),
			cframe = bladeCf,
			color = ROOT_BARK,
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
		local blade = makePart({
			name = "CrescentBlade",
			size = Vector3.new(2.8, 0.25, 1.4),
			cframe = bladeCf * CFrame.new(1.1, 1.6, 0) * CFrame.Angles(0, 0, math.rad(45)),
			color = Color3.fromRGB(195, 130, 255),
			material = Enum.Material.Neon,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(180, 100, 255)
		light.Brightness = 1.6
		light.Range = 16
		light.Shadows = false
		light.Parent = blade
		built.Relic_CryptCleaver = model
	end

	-- Relic_PhantomBow
	do
		local model = Instance.new("Model")
		model.Name = "Relic_PhantomBow"
		createPivotBase(model, Vector3.new(2.8, 3.6, 1.2))
		local bowCf = CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.rad(-18))
		makePart({
			name = "BowLimbUpper",
			size = Vector3.new(0.28, 1.9, 0.32),
			cframe = bowCf * CFrame.new(0.2, 0.85, 0) * CFrame.Angles(0, 0, math.rad(22)),
			color = ROOT_BARK,
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
		makePart({
			name = "BowLimbLower",
			size = Vector3.new(0.28, 1.9, 0.32),
			cframe = bowCf * CFrame.new(0.2, -0.85, 0) * CFrame.Angles(0, 0, math.rad(-22)),
			color = ROOT_BARK,
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
		local arrow = makePart({
			name = "SpectralArrowShaft",
			size = Vector3.new(2.6, 0.22, 0.22),
			cframe = bowCf * CFrame.new(0.3, 0, 0),
			color = Color3.fromRGB(80, 255, 165),
			material = Enum.Material.Neon,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(80, 255, 165)
		light.Brightness = 1.6
		light.Range = 15
		light.Shadows = false
		light.Parent = arrow
		built.Relic_PhantomBow = model
	end

	-- Relic_HexlockPistols
	do
		local model = Instance.new("Model")
		model.Name = "Relic_HexlockPistols"
		createPivotBase(model, Vector3.new(2.8, 3.2, 1.4))
		for _, side in { -1, 1 } do
			local pCf = CFrame.new(side * 0.35, 1.75, 0) * CFrame.Angles(0, 0, side * math.rad(28))
			makePart({
				name = "PistolGrip",
				size = Vector3.new(0.34, 1.1, 0.38),
				cframe = pCf * CFrame.new(0, -0.45, 0),
				color = ROOT_BARK,
				material = Enum.Material.WoodPlanks,
				parent = model,
			})
			local barrel = makePart({
				name = "HexBarrel",
				size = Vector3.new(1.85, 0.36, 0.36),
				cframe = pCf * CFrame.new(side * 0.55, 0.25, 0),
				color = Color3.fromRGB(255, 95, 125),
				material = Enum.Material.Neon,
				parent = model,
			})
			if side == 1 then
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 95, 125)
				light.Brightness = 1.5
				light.Range = 15
				light.Shadows = false
				light.Parent = barrel
			end
		end
		built.Relic_HexlockPistols = model
	end

	-- Relic_StormcallerTome
	do
		local model = Instance.new("Model")
		model.Name = "Relic_StormcallerTome"
		createPivotBase(model, Vector3.new(2.6, 3.2, 2.2))
		local tomeCf = CFrame.new(0, 1.85, 0) * CFrame.Angles(math.rad(-25), 0, 0)
		makePart({
			name = "TomeCoverLeft",
			size = Vector3.new(1.25, 0.24, 1.75),
			cframe = tomeCf * CFrame.new(-0.6, 0, 0) * CFrame.Angles(0, 0, math.rad(16)),
			color = Color3.fromRGB(48, 36, 82),
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "TomeCoverRight",
			size = Vector3.new(1.25, 0.24, 1.75),
			cframe = tomeCf * CFrame.new(0.6, 0, 0) * CFrame.Angles(0, 0, math.rad(-16)),
			color = Color3.fromRGB(48, 36, 82),
			material = Enum.Material.Slate,
			parent = model,
		})
		local runeCore = makePart({
			name = "StormRuneCore",
			size = Vector3.new(0.95, 0.95, 0.95),
			cframe = CFrame.new(0, 2.55, 0) * CFrame.Angles(math.rad(35), math.rad(45), 0),
			color = Color3.fromRGB(115, 210, 255),
			material = Enum.Material.Neon,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(115, 210, 255)
		light.Brightness = 1.7
		light.Range = 16
		light.Shadows = false
		light.Parent = runeCore
		built.Relic_StormcallerTome = model
	end

	-- 15. Destructible Cursed Soul Urn (shatters for XP Gems & Soul Sparks when hit by auto-attacks)
	do
		local model = Instance.new("Model")
		model.Name = "Graveyard_SoulUrn"
		createPivotBase(model, Vector3.new(2.2, 3.2, 2.2))

		makePart({
			name = "StonePedestal",
			size = Vector3.new(2.1, 0.55, 2.1),
			cframe = CFrame.new(0, 0.275, 0),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "UrnBelly",
			size = Vector3.new(1.75, 1.85, 1.75),
			cframe = CFrame.new(0, 1.45, 0),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			shape = Enum.PartType.Ball,
			parent = model,
			castShadow = true,
		})
		local runeBand = makePart({
			name = "RuneBand",
			size = Vector3.new(0.32, 1.92, 1.92),
			cframe = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Cylinder,
			parent = model,
		})
		makePart({
			name = "UrnRim",
			size = Vector3.new(0.38, 1.35, 1.35),
			cframe = CFrame.new(0, 2.48, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = RUNE_CYAN
		light.Brightness = 1.4
		light.Range = 12
		light.Shadows = false
		light.Parent = runeBand
		built.Graveyard_SoulUrn = model
	end

	-- 16. Outer Gothic Cliff Crag & Spire (frames the horizon beyond the perimeter fence)
	do
		local model = Instance.new("Model")
		model.Name = "Graveyard_CliffCrag"
		createPivotBase(model, Vector3.new(18, 36, 14))

		makePart({
			name = "CragMain",
			size = Vector3.new(16, 32, 12),
			cframe = CFrame.new(0, 15, 0) * CFrame.Angles(0.08, 0.25, -0.06),
			color = Color3.fromRGB(42, 46, 54),
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "CragShoulder",
			size = Vector3.new(12, 22, 10),
			cframe = CFrame.new(-7, 10, 2) * CFrame.Angles(-0.06, -0.35, 0.12),
			color = STONE_DARK,
			material = Enum.Material.Rock,
			parent = model,
		})
		makePart({
			name = "GothicSpire",
			size = Vector3.new(3.2, 14, 3.2),
			cframe = CFrame.new(2, 34, -1),
			color = Color3.fromRGB(54, 58, 68),
			material = Enum.Material.Slate,
			parent = model,
		})
		built.Graveyard_CliffCrag = model
	end

	-- Build and sync the 4 custom Graveyard Architectural Buildings via GraveyardBuildings.luau
	-- (Gothic_Mausoleum, Caretaker_Lodge, Catacomb_Descent_Portal, Mortuary_Chapel)
	GraveyardBuildings.syncToServerStorage()
	for name, bModel in GraveyardBuildings.buildAll() do
		built[name] = bModel
	end

	return built
end

local function syncPrefabsToServerStorage()
	local oldNature = ServerStorage:FindFirstChild("NaturePack")
	if oldNature then
		oldNature:Destroy()
	end
	local graveyardFolder = ServerStorage:FindFirstChild("GraveyardAssets")
	if not graveyardFolder then
		graveyardFolder = Instance.new("Folder")
		graveyardFolder.Name = "GraveyardAssets"
		graveyardFolder.Parent = ServerStorage
	end
	for name, template in prefabs do
		local existing = graveyardFolder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local copy = template:Clone()
		copy.Parent = graveyardFolder
	end
end

local function buildPerimeterFence(parent: Instance)
	local perimeterFolder = Instance.new("Folder")
	perimeterFolder.Name = "PerimeterFence"
	perimeterFolder.Parent = parent

	local edgeOffset = HALF - 1.2
	local spanLength = 12
	local spanCount = math.floor((SIZE - 4) / spanLength)
	local halfSpanTotal = (spanCount * spanLength) * 0.5

	local sides = {
		{ name = "North", cx = 0, cz = -edgeOffset, yaw = 0 },
		{ name = "South", cx = 0, cz = edgeOffset, yaw = math.pi },
		{ name = "East", cx = edgeOffset, cz = 0, yaw = -math.pi * 0.5 },
		{ name = "West", cx = -edgeOffset, cz = 0, yaw = math.pi * 0.5 },
	}

	for _, side in sides do
		local sideBaseCf = CFrame.new(side.cx, 0, side.cz) * CFrame.Angles(0, side.yaw, 0)
		for i = 0, spanCount - 1 do
			local localX = -halfSpanTotal + (i + 0.5) * spanLength
			local isGateCenter = math.abs(localX) < spanLength * 0.6
			local spanCf = sideBaseCf * CFrame.new(localX, 0, 0)

			-- Pillar at the start of each 12-stud span
			local pillarX = -spanLength * 0.5
			local isGatePillar = math.abs(localX + pillarX) <= spanLength * 0.65
			local pillarHeight = if isGatePillar then 6.4 else 4.5
			local pillarWidth = if isGatePillar then 1.85 else 1.25

			makePart({
				name = "PerimeterPillar",
				size = Vector3.new(pillarWidth, pillarHeight, pillarWidth),
				cframe = spanCf * CFrame.new(pillarX, pillarHeight * 0.5, 0),
				color = STONE_DARK,
				material = Enum.Material.Slate,
				parent = perimeterFolder,
				castShadow = true,
			})
			makePart({
				name = "PerimeterPillarCap",
				size = Vector3.new(pillarWidth + 0.3, 0.4, pillarWidth + 0.3),
				cframe = spanCf * CFrame.new(pillarX, pillarHeight + 0.2, 0),
				color = STONE_MID,
				material = Enum.Material.Slate,
				parent = perimeterFolder,
			})

			if isGatePillar then
				local beacon = makePart({
					name = "GateLanternFlame",
					size = Vector3.new(0.65, 0.85, 0.65),
					cframe = spanCf * CFrame.new(pillarX, pillarHeight + 0.82, 0),
					color = LANTERN_AMBER,
					material = Enum.Material.Neon,
					parent = perimeterFolder,
				})
				local gateLight = Instance.new("PointLight")
				gateLight.Color = Color3.fromRGB(255, 180, 88)
				gateLight.Brightness = 1.6
				gateLight.Range = 30
				gateLight.Shadows = false
				gateLight.Parent = beacon
			end

			-- Low stone plinth wall & wrought-iron rails
			makePart({
				name = "PerimeterCurb",
				size = Vector3.new(spanLength, 0.75, 0.85),
				cframe = spanCf * CFrame.new(0, 0.375, 0),
				color = STONE_MOSS,
				material = Enum.Material.Cobblestone,
				parent = perimeterFolder,
			})
			makePart({
				name = "PerimeterBottomRail",
				size = Vector3.new(spanLength, 0.22, 0.22),
				cframe = spanCf * CFrame.new(0, 1.15, 0),
				color = IRON_DARK,
				material = Enum.Material.CorrodedMetal,
				parent = perimeterFolder,
			})
			local topRailY = if isGateCenter then 4.65 else 3.85
			makePart({
				name = "PerimeterTopRail",
				size = Vector3.new(spanLength, 0.24, 0.24),
				cframe = spanCf * CFrame.new(0, topRailY, 0),
				color = IRON_DARK,
				material = Enum.Material.CorrodedMetal,
				parent = perimeterFolder,
			})

			-- Vertical wrought-iron bars along the span
			local barHeight = topRailY - 0.65
			for b = -2, 2 do
				local bx = b * 2.0
				makePart({
					name = "PerimeterBar",
					size = Vector3.new(0.2, barHeight, 0.2),
					cframe = spanCf * CFrame.new(bx, 0.65 + barHeight * 0.5, 0),
					color = IRON_DARK,
					material = Enum.Material.CorrodedMetal,
					parent = perimeterFolder,
				})
			end
		end
	end
end

local function spawnPrefabAtY(
	name: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	scale: number,
	tiltX: number,
	tiltZ: number,
	parent: Instance
): Model?
	local template = prefabs[name]
	if not template then
		return nil
	end
	local clone = template:Clone()
	if math.abs(scale - 1) > 0.01 then
		clone:ScaleTo(scale)
	end
	local cf = CFrame.new(x, y, z) * CFrame.Angles(tiltX, yaw, tiltZ)
	clone:PivotTo(cf)
	clone.Parent = parent
	return clone
end

local function spawnPrefab(
	name: string,
	x: number,
	z: number,
	yaw: number,
	scale: number,
	tiltX: number,
	tiltZ: number,
	parent: Instance
): Model?
	return spawnPrefabAtY(name, x, 0, z, yaw, scale, tiltX, tiltZ, parent)
end

local function canPlaceObstacle(cx: number, cz: number, boundRadius: number, clearance: number): boolean
	if #obstacles >= Constants.MAX_ARENA_OBSTACLES then
		return false
	end
	local minCenterDist = SPAWN_CLEAR_RADIUS + boundRadius + 12
	if cx * cx + cz * cz < minCenterDist * minCenterDist then
		return false
	end
	local maxCoord = HALF - boundRadius - 18
	if math.abs(cx) > maxCoord or math.abs(cz) > maxCoord then
		return false
	end
	for _, obs in obstacles do
		local minDist = obs.boundRadius + boundRadius + clearance
		local dx = cx - obs.cx
		local dz = cz - obs.cz
		if dx * dx + dz * dz < minDist * minDist then
			return false
		end
	end
	return true
end

local function registerObstacle(cx: number, cz: number, halfX: number, halfZ: number, yaw: number, tier: number?)
	if #obstacles >= Constants.MAX_ARENA_OBSTACLES then
		return
	end
	local boundRadius = math.sqrt(halfX * halfX + halfZ * halfZ)
	table.insert(obstacles, {
		cx = cx,
		cz = cz,
		halfX = halfX,
		halfZ = halfZ,
		cos = math.cos(yaw),
		sin = math.sin(yaw),
		boundRadius = boundRadius,
		tier = tier or 1,
	})
end

local function spawnSoulUrn(x: number, z: number, rng: Random, parent: Instance)
	if #soulUrns >= Constants.MAX_DESTRUCTIBLE_URNS then
		return
	end
	local model = spawnPrefab("Graveyard_SoulUrn", x, z, rng:NextNumber(0, math.pi * 2), 1, 0, 0, parent)
	table.insert(soulUrns, {
		x = x,
		z = z,
		health = 14,
		radius = 1.6,
		dead = false,
		model = model,
	})
end

local function spawnBrazierShrine(id: number, districtName: string, x: number, z: number, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Shrine_" .. tostring(id)
	model.Parent = parent

	makePart({
		name = "ShrinePlinth",
		size = Vector3.new(4.8, 0.7, 4.8),
		cframe = CFrame.new(x, 0.35, z),
		color = STONE_MOSS,
		material = Enum.Material.Cobblestone,
		parent = model,
		canCollide = true,
	})
	makePart({
		name = "ShrineAltar",
		size = Vector3.new(2.8, 2.4, 2.8),
		cframe = CFrame.new(x, 1.55, z),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
		canCollide = true,
		castShadow = true,
	})
	makePart({
		name = "BrazierBowl",
		size = Vector3.new(0.65, 3.2, 3.2),
		cframe = CFrame.new(x, 2.95, z) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = BRONZE_PLAQUE,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})
	local flame = makePart({
		name = "ShrineFlame",
		size = Vector3.new(1.8, 2.2, 1.8),
		cframe = CFrame.new(x, 3.9, z),
		color = RUNE_CYAN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		transparency = 0.25,
		parent = model,
	})
	local light = Instance.new("PointLight")
	light.Color = RUNE_CYAN
	light.Brightness = 2.4
	light.Range = 28
	light.Shadows = false
	light.Parent = flame

	local beam = makePart({
		name = "ShrineBeacon",
		size = Vector3.new(28, 0.75, 0.75),
		cframe = CFrame.new(x, 18, z) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = RUNE_CYAN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		transparency = 0.55,
		parent = model,
	})

	local ring = makePart({
		name = "CaptureRing",
		size = Vector3.new(0.18, Constants.SHRINE_CAPTURE_RADIUS * 2, Constants.SHRINE_CAPTURE_RADIUS * 2),
		cframe = CFrame.new(x, 0.14, z) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = RUNE_CYAN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		transparency = 0.65,
		parent = model,
	})

	local bb = Instance.new("BillboardGui")
	bb.Name = "ShrineBillboard"
	bb.Size = UDim2.fromOffset(220, 54)
	bb.StudsOffset = Vector3.new(0, 5.2, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 95
	bb.Parent = flame

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.RichText = true
	lbl.TextColor3 = Color3.fromRGB(130, 255, 235)
	lbl.TextStrokeColor3 = Color3.fromRGB(10, 16, 24)
	lbl.TextStrokeTransparency = 0.15
	lbl.TextSize = 16
	lbl.Text = string.format(
		"🔥 %s Shrine\n<font size='13' color='#ffd878'>Stand in Circle (+15 Souls & Buff)</font>",
		districtName
	)
	lbl.Parent = bb

	registerObstacle(x, z, 1.6, 1.6, 0, 2)
	table.insert(shrines, {
		id = id,
		name = districtName,
		x = x,
		z = z,
		progress = 0,
		ignited = false,
		flamePart = flame,
		beamPart = beam,
		ringPart = ring,
		label = lbl,
	})
end

local function spawnBlockingFenceWall(
	cx: number,
	cz: number,
	yaw: number,
	panelCount: number,
	rng: Random,
	parent: Instance
)
	local panelWidth = 8.0
	local totalWidth = panelCount * panelWidth
	local halfX = totalWidth * 0.5
	local halfZ = 0.75
	-- Tier 2 = Low Cover (blocks ground enemies & players, but flyers glide over & projectiles shoot over)
	registerObstacle(cx, cz, halfX, halfZ, yaw, 2)

	local wallCf = CFrame.new(cx, 0, cz) * CFrame.Angles(0, yaw, 0)
	-- Invisible single physics collider for the entire multi-panel fence wall
	makePart({
		name = "FenceWallCollider",
		size = Vector3.new(totalWidth, 5.5, 1.3),
		cframe = wallCf * CFrame.new(0, 2.75, 0),
		color = IRON_DARK,
		material = Enum.Material.SmoothPlastic,
		parent = parent,
		canCollide = true,
		transparency = 1,
	})

	for i = 1, panelCount do
		local localX = -halfX + (i - 0.5) * panelWidth
		local panelPos = wallCf * CFrame.new(localX, 0, 0)
		spawnPrefab("Graveyard_Fence", panelPos.Position.X, panelPos.Position.Z, yaw, 1, 0, 0, parent)
	end

	-- Organic base clutter along the blocking fence wall
	for i = 1, panelCount do
		local localX = -halfX + (i - 0.5) * panelWidth + rng:NextNumber(-2.2, 2.2)
		local localZ = (if rng:NextNumber() < 0.5 then 1 else -1) * rng:NextNumber(0.9, 1.8)
		local clutterPos = wallCf * CFrame.new(localX, 0, localZ)
		local clutterKind = if rng:NextNumber() < 0.55 then "Ground_GrassTuft" else "Ground_DeadRoots"
		spawnPrefab(
			clutterKind,
			clutterPos.Position.X,
			clutterPos.Position.Z,
			rng:NextNumber(0, math.pi * 2),
			rng:NextNumber(0.85, 1.25),
			0,
			0,
			parent
		)
	end
end

local function spawnBlockingCrypt(cx: number, cz: number, yaw: number, rng: Random, parent: Instance)
	-- Grave_Sarcophagus is 3.8 wide (X) by 7.2 long (Z) -> Tier 2 Low Cover + Crypt Emergence Anchor
	registerObstacle(cx, cz, 2.0, 3.7, yaw, 2)
	spawnPrefab("Grave_Sarcophagus", cx, cz, yaw, 1, 0, 0, parent)

	local cryptCf = CFrame.new(cx, 0, cz) * CFrame.Angles(0, yaw, 0)
	local emergePos = cryptCf * CFrame.new(0, 0, -5.2)
	table.insert(cryptAnchors, { x = emergePos.Position.X, z = emergePos.Position.Z })

	for _ = 1, 3 do
		local ox = rng:NextNumber(-3.2, 3.2)
		local oz = rng:NextNumber(-4.6, 4.6)
		if math.abs(ox) > 2.1 or math.abs(oz) > 3.8 then
			local p = cryptCf * CFrame.new(ox, 0, oz)
			local kind = if rng:NextNumber() < 0.5 then "Ground_RubbleCluster" else "Ground_DeadRoots"
			spawnPrefab(
				kind,
				p.Position.X,
				p.Position.Z,
				rng:NextNumber(0, math.pi * 2),
				rng:NextNumber(0.9, 1.3),
				0,
				0,
				parent
			)
		end
	end
end

local BUILDING_SPECS: { { name: string, label: string, halfX: number, halfZ: number, height: number } } = {
	{ name = "Gothic_Mausoleum", label = "Weeping Mausoleum", halfX = 10.2, halfZ = 13.2, height = 16 },
	{ name = "Mortuary_Chapel", label = "Mortuary Chapel", halfX = 10.2, halfZ = 15.2, height = 22 },
	{ name = "Caretaker_Lodge", label = "Caretaker's Lodge", halfX = 9.2, halfZ = 8.2, height = 14 },
	{ name = "Catacomb_Descent_Portal", label = "Abyssal Breach", halfX = 11.2, halfZ = 5.8, height = 13 },
}

local function spawnBlockingBuilding(
	id: number,
	spec: { name: string, label: string, halfX: number, halfZ: number, height: number },
	cx: number,
	cz: number,
	yaw: number,
	rng: Random,
	parent: Instance
)
	if not prefabs[spec.name] then
		return
	end
	-- Tier 1 = Tall Solid Building (blocks projectiles, flyers, ground enemies, and players)
	registerObstacle(cx, cz, spec.halfX, spec.halfZ, yaw, 1)
	spawnPrefab(spec.name, cx, cz, yaw, 1, 0, 0, parent)

	local bCf = CFrame.new(cx, 0, cz) * CFrame.Angles(0, yaw, 0)
	makePart({
		name = spec.name .. "_Collider",
		size = Vector3.new(spec.halfX * 2, spec.height, spec.halfZ * 2),
		cframe = bCf * CFrame.new(0, spec.height * 0.5, 0),
		color = STONE_DARK,
		material = Enum.Material.SmoothPlastic,
		parent = parent,
		canCollide = true,
		transparency = 1,
	})

	-- Paved Cobblestone Forecourt in front of the Landmark Building (-Z)
	local forecourtPos = bCf * CFrame.new(0, 0.06, -(spec.halfZ + 9.5))
	makePart({
		name = spec.name .. "_Forecourt",
		size = Vector3.new(20, 0.12, 16),
		cframe = forecourtPos,
		color = STONE_MOSS,
		material = Enum.Material.Cobblestone,
		parent = parent,
	})

	-- Register Crypt Emergence Anchor at the building doorway
	local doorPos = bCf * CFrame.new(0, 0, -(spec.halfZ + 4.5))
	table.insert(cryptAnchors, { x = doorPos.Position.X, z = doorPos.Position.Z })

	-- Place Activateable Soul Brazier Shrine in the forecourt
	local shrinePos = bCf * CFrame.new(0, 0, -(spec.halfZ + 11.0))
	if math.abs(shrinePos.Position.X) < HALF - 16 and math.abs(shrinePos.Position.Z) < HALF - 16 then
		spawnBrazierShrine(id, spec.label, shrinePos.Position.X, shrinePos.Position.Z, parent)
	end

	-- Frame the entrance (-Z) with Haunted Lantern Posts, Cursed Soul Urn & weathered ground clutter
	local lanternPos = bCf * CFrame.new(spec.halfX * 0.65, 0, -(spec.halfZ + 2.8))
	spawnPrefab("Graveyard_Lantern", lanternPos.Position.X, lanternPos.Position.Z, yaw, 1, 0, 0, parent)
	local urnPos = bCf * CFrame.new(-spec.halfX * 0.65, 0, -(spec.halfZ + 3.2))
	spawnSoulUrn(urnPos.Position.X, urnPos.Position.Z, rng, parent)

	for _ = 1, 4 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local p = bCf
			* CFrame.new(side * (spec.halfX + rng:NextNumber(1.2, 2.8)), 0, rng:NextNumber(-spec.halfZ, spec.halfZ))
		local kind = if rng:NextNumber() < 0.5 then "Ground_DeadRoots" else "Ground_GrassTuft"
		spawnPrefab(kind, p.Position.X, p.Position.Z, rng:NextNumber(0, math.pi * 2), 1.15, 0, 0, parent)
	end
end

function Arena.isPointBlocked(x: number, z: number, radius: number, maxTier: number?): boolean
	local allowedTier = maxTier or 2
	for _, obs in obstacles do
		if obs.tier <= allowedTier then
			local dx = x - obs.cx
			local dz = z - obs.cz
			local reach = obs.boundRadius + radius
			if dx * dx + dz * dz < reach * reach then
				local lx = dx * obs.cos - dz * obs.sin
				local lz = dx * obs.sin + dz * obs.cos
				local cx = math.clamp(lx, -obs.halfX, obs.halfX)
				local cz = math.clamp(lz, -obs.halfZ, obs.halfZ)
				local ox = lx - cx
				local oz = lz - cz
				if ox * ox + oz * oz < radius * radius then
					return true
				end
			end
		end
	end
	return false
end

-- Fast 2D segment-vs-OBB slab test against obstacles with tier <= maxTier (default 1 = Tall Blockers).
function Arena.hasLineOfSight(ax: number, az: number, bx: number, bz: number, maxTier: number?): boolean
	local allowedTier = maxTier or 1
	local abx = bx - ax
	local abz = bz - az
	local segLen = math.sqrt(abx * abx + abz * abz)
	if segLen < 1e-4 then
		return true
	end
	local midX = (ax + bx) * 0.5
	local midZ = (az + bz) * 0.5
	local halfSeg = segLen * 0.5

	for _, obs in obstacles do
		if obs.tier <= allowedTier then
			local mdx = midX - obs.cx
			local mdz = midZ - obs.cz
			local maxReach = halfSeg + obs.boundRadius
			if mdx * mdx + mdz * mdz <= maxReach * maxReach then
				local dax = ax - obs.cx
				local daz = az - obs.cz
				local lax = dax * obs.cos - daz * obs.sin
				local laz = dax * obs.sin + daz * obs.cos

				local dbx = bx - obs.cx
				local dbz = bz - obs.cz
				local lbx = dbx * obs.cos - dbz * obs.sin
				local lbz = dbx * obs.sin + dbz * obs.cos

				local dlx = lbx - lax
				local dlz = lbz - laz
				local tMin = 0.0
				local tMax = 1.0
				local hit = true

				if math.abs(dlx) < 1e-6 then
					if lax < -obs.halfX or lax > obs.halfX then
						hit = false
					end
				else
					local t1 = (-obs.halfX - lax) / dlx
					local t2 = (obs.halfX - lax) / dlx
					if t1 > t2 then
						t1, t2 = t2, t1
					end
					tMin = math.max(tMin, t1)
					tMax = math.min(tMax, t2)
					if tMin > tMax then
						hit = false
					end
				end

				if hit then
					if math.abs(dlz) < 1e-6 then
						if laz < -obs.halfZ or laz > obs.halfZ then
							hit = false
						end
					else
						local t1 = (-obs.halfZ - laz) / dlz
						local t2 = (obs.halfZ - laz) / dlz
						if t1 > t2 then
							t1, t2 = t2, t1
						end
						tMin = math.max(tMin, t1)
						tMax = math.min(tMax, t2)
						if tMin > tMax then
							hit = false
						end
					end
				end

				if hit then
					return false
				end
			end
		end
	end
	return true
end

-- Look-ahead whisker steering: probes ahead of an enemy and blends its heading around the nearer OBB corner
-- so hordes flow around walls instead of piling up on wall centers.
function Arena.steerAroundObstacles(
	x: number,
	z: number,
	dirX: number,
	dirZ: number,
	radius: number,
	entityId: number,
	isFlyer: boolean?
): (number, number)
	local lookAhead = radius + 5.5
	local probeX = x + dirX * lookAhead * 0.65
	local probeZ = z + dirZ * lookAhead * 0.65
	local maxTier = if isFlyer then 1 else 2

	for _, obs in obstacles do
		if obs.tier <= maxTier then
			local dx = probeX - obs.cx
			local dz = probeZ - obs.cz
			local reach = obs.boundRadius + radius + 3.0
			if dx * dx + dz * dz < reach * reach then
				local lx = (x - obs.cx) * obs.cos - (z - obs.cz) * obs.sin
				local lz = (x - obs.cx) * obs.sin + (z - obs.cz) * obs.cos
				local ldirX = dirX * obs.cos - dirZ * obs.sin
				local ldirZ = dirX * obs.sin + dirZ * obs.cos

				local pLx = lx + ldirX * lookAhead
				local pLz = lz + ldirZ * lookAhead
				local padX = obs.halfX + radius + 0.8
				local padZ = obs.halfZ + radius + 0.8

				if math.abs(pLx) < padX and math.abs(pLz) < padZ then
					local fallbackSign = if entityId % 2 == 0 then 1 else -1
					local tx: number
					local tz: number
					if math.abs(lz) / math.max(obs.halfZ, 0.5) >= math.abs(lx) / math.max(obs.halfX, 0.5) then
						local signX = if math.abs(lx) > 0.4 then math.sign(lx) else fallbackSign
						tx = signX * (padX + 1.5) - lx
						tz = 0
					else
						local signZ = if math.abs(lz) > 0.4 then math.sign(lz) else fallbackSign
						tx = 0
						tz = signZ * (padZ + 1.5) - lz
					end
					local tLen = math.max(math.sqrt(tx * tx + tz * tz), 0.001)
					tx /= tLen
					tz /= tLen
					local wTx = tx * obs.cos + tz * obs.sin
					local wTz = -tx * obs.sin + tz * obs.cos
					local bx = dirX * 0.45 + wTx * 0.55
					local bz = dirZ * 0.45 + wTz * 0.55
					local bLen = math.max(math.sqrt(bx * bx + bz * bz), 0.001)
					return bx / bLen, bz / bLen
				end
			end
		end
	end
	return dirX, dirZ
end

-- Resolves 2D circle against active blocking OBB obstacles with tangential wall-sliding.
function Arena.resolveObstacle(
	x: number,
	z: number,
	radius: number,
	stepDist: number?,
	isFlyer: boolean?
): (number, number)
	local slide = if stepDist ~= nil then stepDist * 0.85 else 0
	local maxTier = if isFlyer then 1 else 2
	for _, obs in obstacles do
		if obs.tier <= maxTier then
			local dx = x - obs.cx
			local dz = z - obs.cz
			local broadReach = obs.boundRadius + radius
			if dx * dx + dz * dz < broadReach * broadReach then
				-- Transform into obstacle's local frame matching CFrame.Angles(0, yaw, 0)
				local lx = dx * obs.cos - dz * obs.sin
				local lz = dx * obs.sin + dz * obs.cos
				local clampedX = math.clamp(lx, -obs.halfX, obs.halfX)
				local clampedZ = math.clamp(lz, -obs.halfZ, obs.halfZ)
				local ox = lx - clampedX
				local oz = lz - clampedZ
				local distSq = ox * ox + oz * oz

				if distSq < radius * radius then
					if distSq > 1e-6 then
						local dist = math.sqrt(distSq)
						local pen = radius - dist
						local nx = ox / dist
						local nz = oz / dist
						lx += nx * pen
						lz += nz * pen

						if slide > 0 then
							if math.abs(nz) >= math.abs(nx) then
								local dir = if math.abs(lx) > 0.15
									then math.sign(lx)
									else (if (obs.cx + obs.cz) >= 0 then 1 else -1)
								lx += dir * slide
							else
								local dir = if math.abs(lz) > 0.15
									then math.sign(lz)
									else (if (obs.cx - obs.cz) >= 0 then 1 else -1)
								lz += dir * slide
							end
						end
					else
						local penX = obs.halfX + radius - math.abs(lx)
						local penZ = obs.halfZ + radius - math.abs(lz)
						if penX < penZ then
							local signX = if lx >= 0 then 1 else -1
							lx = signX * (obs.halfX + radius)
						else
							local signZ = if lz >= 0 then 1 else -1
							lz = signZ * (obs.halfZ + radius)
						end
					end

					x = obs.cx + lx * obs.cos + lz * obs.sin
					z = obs.cz - lx * obs.sin + lz * obs.cos
				end
			end
		end
	end
	return x, z
end

function Arena.getObstacles(): { Obstacle }
	return obstacles
end

function Arena.getCryptAnchors(): { CryptAnchor }
	return cryptAnchors
end

function Arena.damageUrnsInRadius(
	x: number,
	z: number,
	radius: number,
	damage: number,
	onShatter: (ux: number, uz: number) -> ()
)
	for _, urn in soulUrns do
		if not urn.dead then
			local dx = urn.x - x
			local dz = urn.z - z
			local reach = urn.radius + radius
			if dx * dx + dz * dz <= reach * reach then
				urn.health -= damage
				if urn.health <= 0 then
					urn.dead = true
					if urn.model then
						urn.model:Destroy()
						urn.model = nil
					end
					onShatter(urn.x, urn.z)
				end
			end
		end
	end
end

local function compassDir(dx: number, dz: number): string
	local angle = math.deg(math.atan2(dx, -dz))
	if angle < 0 then
		angle += 360
	end
	local dirs = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
	local idx = (math.floor((angle + 22.5) / 45) % 8) + 1
	return dirs[idx]
end

function Arena.spawnReliquaryChest(x: number, z: number, isBoss: boolean)
	if #reliquaryChests >= Constants.MAX_RELIQUARY_CHESTS then
		if isBoss then
			local evicted = false
			for idx = 1, #reliquaryChests do
				if not reliquaryChests[idx].isBoss then
					local old = reliquaryChests[idx]
					if old.model then
						old.model:Destroy()
					end
					table.remove(reliquaryChests, idx)
					evicted = true
					break
				end
			end
			if not evicted then
				return
			end
		else
			return
		end
	end
	local root = arenaFolder or Workspace:FindFirstChild("Arena")
	local decor = root and root:FindFirstChild("RunDecor")
	if not decor then
		return
	end

	local cx, cz =
		Arena.resolveObstacle(math.clamp(x, -(HALF - 8), HALF - 8), math.clamp(z, -(HALF - 8), HALF - 8), 2.0, 0, false)

	local model = Instance.new("Model")
	model.Name = if isBoss then "BossReliquaryChest" else "CryptReliquaryChest"

	local baseColor = if isBoss then Color3.fromRGB(88, 32, 128) else Color3.fromRGB(58, 42, 28)
	local trimColor = if isBoss then Color3.fromRGB(255, 215, 55) else Color3.fromRGB(235, 175, 45)
	local glowColor = if isBoss then Color3.fromRGB(255, 200, 45) else Color3.fromRGB(85, 245, 215)

	makePart({
		name = "ChestPlinth",
		size = Vector3.new(3.4, 0.45, 2.4),
		cframe = CFrame.new(cx, 0.225, cz),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ChestBody",
		size = Vector3.new(2.8, 1.45, 1.85),
		cframe = CFrame.new(cx, 1.15, cz),
		color = baseColor,
		material = Enum.Material.WoodPlanks,
		parent = model,
		castShadow = true,
	})
	makePart({
		name = "ChestVaultLid",
		size = Vector3.new(2.85, 0.95, 1.9),
		cframe = CFrame.new(cx, 1.9, cz) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = trimColor,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})
	local seam = makePart({
		name = "ReliquaryCore",
		size = Vector3.new(2.9, 0.26, 1.95),
		cframe = CFrame.new(cx, 1.75, cz),
		color = glowColor,
		material = Enum.Material.Neon,
		parent = model,
	})
	makePart({
		name = "SkyBeacon",
		size = Vector3.new(28, 1.1, 1.1),
		cframe = CFrame.new(cx, 15, cz) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = glowColor,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		transparency = 0.72,
		parent = model,
	})

	local light = Instance.new("PointLight")
	light.Color = glowColor
	light.Brightness = 2.8
	light.Range = 28
	light.Shadows = false
	light.Parent = seam

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 48)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 150
	bb.Parent = seam

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.RichText = true
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(255, 240, 120)
	lbl.TextStrokeColor3 = Color3.fromRGB(8, 5, 18)
	lbl.TextStrokeTransparency = 0.08
	lbl.Text = if isBoss
		then "👑 BOSS RELIQUARY CHEST!\n<font size='12' color='#a8ffeb'>Walk Over to Claim (+Souls, Coin & XP!)</font>"
		else "🎁 CRYPT RELIQUARY CACHE\n<font size='12' color='#a8ffeb'>Walk Over to Open (+Souls, Heal & XP!)</font>"
	lbl.Parent = bb

	model.Parent = decor
	table.insert(reliquaryChests, {
		x = cx,
		z = cz,
		isBoss = isBoss,
		claimed = false,
		model = model,
	})
end

function Arena.stepShrines(
	dt: number,
	targets: { PlayerState.Target },
	onShrineIgnited: (shrine: BrazierShrine, capTarget: PlayerState.Target) -> ()
)
	local capRadSq = Constants.SHRINE_CAPTURE_RADIUS * Constants.SHRINE_CAPTURE_RADIUS
	for _, shrine in shrines do
		if not shrine.ignited then
			local capturer: PlayerState.Target? = nil
			for _, t in targets do
				local dx = t.position.X - shrine.x
				local dz = t.position.Z - shrine.z
				if dx * dx + dz * dz <= capRadSq then
					capturer = t
					break
				end
			end
			if capturer then
				shrine.progress = math.min(Constants.SHRINE_CAPTURE_SECONDS, shrine.progress + dt)
				if shrine.label then
					local pct = math.floor((shrine.progress / Constants.SHRINE_CAPTURE_SECONDS) * 100)
					shrine.label.Text = string.format(
						"🔥 %s Shrine (%d%%)\n<font size='13' color='#55ff99'>Channeling Soul Blessing...</font>",
						shrine.name,
						pct
					)
				end
				if shrine.progress >= Constants.SHRINE_CAPTURE_SECONDS then
					shrine.ignited = true
					if shrine.flamePart then
						shrine.flamePart.Color = LANTERN_AMBER
						shrine.flamePart.Size = Vector3.new(2.6, 3.4, 2.6)
					end
					if shrine.beamPart then
						shrine.beamPart.Transparency = 0.88
						shrine.beamPart.Color = LANTERN_AMBER
					end
					if shrine.ringPart then
						shrine.ringPart.Color = LANTERN_AMBER
						shrine.ringPart.Transparency = 0.8
					end
					if shrine.label then
						shrine.label.TextColor3 = Color3.fromRGB(255, 220, 110)
						shrine.label.Text = string.format(
							"✨ %s Ignited!\n<font size='13' color='#a5ffeb'>+15 Souls & Sanctuary Blessing Active</font>",
							shrine.name
						)
					end
					onShrineIgnited(shrine, capturer)
				end
			elseif shrine.progress > 0 then
				shrine.progress = math.max(0, shrine.progress - dt * 0.5)
				if shrine.label then
					shrine.label.Text = string.format(
						"🔥 %s Shrine\n<font size='13' color='#ffd878'>Stand in Circle (+15 Souls & Buff)</font>",
						shrine.name
					)
				end
			end
		end
	end

	-- Step Reliquary Treasure Chests
	local chestRadSq = Constants.RELIQUARY_PICKUP_RADIUS * Constants.RELIQUARY_PICKUP_RADIUS
	for i = #reliquaryChests, 1, -1 do
		local chest = reliquaryChests[i]
		if not chest.claimed then
			for _, t in targets do
				local dx = t.position.X - chest.x
				local dz = t.position.Z - chest.z
				if dx * dx + dz * dz <= chestRadSq then
					chest.claimed = true
					if chest.model then
						chest.model:Destroy()
						chest.model = nil
					end
					for _, runner in targets do
						PlayerState.grantReliquaryChest(runner.state, chest.isBoss)
					end
					local Replication = require(script.Parent.Replication)
					Replication.queueShockwave(chest.x, chest.z, 16)
					table.remove(reliquaryChests, i)
					break
				end
			end
		end
	end

	-- Update Nearest Objective Compass per active runner
	for _, t in targets do
		local bestText = ""
		local bestDistSq = math.huge
		for _, chest in reliquaryChests do
			if not chest.claimed then
				local dx = chest.x - t.position.X
				local dz = chest.z - t.position.Z
				local dSq = dx * dx + dz * dz
				if dSq < bestDistSq then
					bestDistSq = dSq
					bestText = string.format(
						"🎁 %s: %dm %s",
						if chest.isBoss then "Boss Reliquary" else "Reliquary Chest",
						math.floor(math.sqrt(dSq)),
						compassDir(dx, dz)
					)
				end
			end
		end
		if bestText == "" then
			for _, shrine in shrines do
				if not shrine.ignited then
					local dx = shrine.x - t.position.X
					local dz = shrine.z - t.position.Z
					local dSq = dx * dx + dz * dz
					if dSq < bestDistSq then
						bestDistSq = dSq
						bestText = string.format(
							"🧭 %s Brazier: %dm %s",
							shrine.name,
							math.floor(math.sqrt(dSq)),
							compassDir(dx, dz)
						)
					end
				end
			end
		end
		if bestText == "" then
			bestText = "✨ All 4 Soul Braziers Ignited!"
		end
		if t.state.player:GetAttribute("ObjectiveCompass") ~= bestText then
			t.state.player:SetAttribute("ObjectiveCompass", bestText)
		end
	end
end

function Arena.rebuild(seed: number?)
	local root = arenaFolder or Workspace:FindFirstChild("Arena")
	if not root or not root:IsA("Folder") then
		return
	end
	arenaFolder = root

	table.clear(obstacles)
	table.clear(cryptAnchors)
	table.clear(soulUrns)
	table.clear(shrines)
	table.clear(reliquaryChests)
	local oldDecor = root:FindFirstChild("RunDecor")
	if oldDecor then
		oldDecor:Destroy()
	end
	local decor = Instance.new("Folder")
	decor.Name = "RunDecor"
	decor.Parent = root

	local rng = if seed ~= nil then Random.new(seed) else Random.new()
	local baseAngle = rng:NextNumber(0, math.pi * 0.5)
	local pathWeavePhase = rng:NextNumber(0, math.pi * 2)

	local function getPathAngle(armIndex: number, radius: number): number
		local cardinal = baseAngle + (armIndex - 1) * (math.pi * 0.5)
		return cardinal + 0.12 * math.sin(radius * 0.032 + pathWeavePhase + armIndex)
	end

	-- ZONE 0: Central Ossuary Ritual Plaza (layered cobblestone & slate courtyard with runic compass inlay)
	makePart({
		name = "CentralPlazaOuter",
		size = Vector3.new(0.14, 38, 38),
		cframe = CFrame.new(0, 0.07, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = STONE_MOSS,
		material = Enum.Material.Cobblestone,
		shape = Enum.PartType.Cylinder,
		parent = decor,
	})
	makePart({
		name = "CentralPlazaInner",
		size = Vector3.new(0.18, 22, 22),
		cframe = CFrame.new(0, 0.09, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		shape = Enum.PartType.Cylinder,
		parent = decor,
	})
	makePart({
		name = "CentralRunicCompass",
		size = Vector3.new(0.22, 12, 12),
		cframe = CFrame.new(0, 0.11, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = RUNE_CYAN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		transparency = 0.55,
		parent = decor,
	})

	-- ZONE 1: Central Spawn Plaza & 4 Crossroads Lanterns (safe clear radius for spawning)
	for arm = 1, 4 do
		local angle = getPathAngle(arm, 22) + math.pi * 0.25
		local lx = math.cos(angle) * 21
		local lz = math.sin(angle) * 21
		spawnPrefab("Graveyard_Lantern", lx, lz, -angle + math.pi, 1, 0, 0, decor)
		spawnPrefab("Ground_RubbleCluster", lx * 0.9, lz * 0.9, rng:NextNumber(0, math.pi * 2), 1.05, 0, 0, decor)
		spawnPrefab("Ground_GrassTuft", lx * 1.05, lz * 1.05, rng:NextNumber(0, math.pi * 2), 1.1, 0, 0, decor)
	end

	-- ZONE 1.5: 4 Winding Paved Cobblestone Avenues radiating from the Central Plaza out to the Perimeter
	for arm = 1, 4 do
		for r = 24, 206, 14 do
			local a1 = getPathAngle(arm, r)
			local a2 = getPathAngle(arm, r + 14)
			local x1, z1 = math.cos(a1) * r, math.sin(a1) * r
			local x2, z2 = math.cos(a2) * (r + 14), math.sin(a2) * (r + 14)
			local midX, midZ = (x1 + x2) * 0.5, (z1 + z2) * 0.5
			local segCf = CFrame.lookAt(Vector3.new(midX, 0.05, midZ), Vector3.new(x2, 0.05, z2))
			makePart({
				name = "CobbleRoadSlab",
				size = Vector3.new(9.2, 0.1, 15.2),
				cframe = segCf,
				color = STONE_MOSS,
				material = Enum.Material.Cobblestone,
				parent = decor,
			})
			makePart({
				name = "SlateRoadCenter",
				size = Vector3.new(4.6, 0.12, 14.8),
				cframe = segCf * CFrame.new(0, 0.01, 0),
				color = STONE_DARK,
				material = Enum.Material.Slate,
				parent = decor,
			})
		end
	end

	-- ZONE 2 & ZONE 3A: 4 Winding Lantern-Lit Pathways + Gated Fence Choke Points Across Paths
	local pathRadii = { 54, 98, 144, 190 }
	for arm = 1, 4 do
		local gateRadiusIndex = rng:NextInteger(2, 3)
		for idx, r in pathRadii do
			local angle = getPathAngle(arm, r)
			local px = math.cos(angle) * r
			local pz = math.sin(angle) * r
			-- Tangent direction perpendicular to the radial avenue
			local perpX = -math.sin(angle)
			local perpZ = math.cos(angle)
			local fenceYaw = -angle

			if idx == gateRadiusIndex then
				-- Place a Gated Wrought-Iron Fence Choke Point across the avenue (11-stud open gateway in the middle)
				local wingOffset = 9.5
				for _, sign in { -1, 1 } do
					local wx = px + perpX * (sign * wingOffset)
					local wz = pz + perpZ * (sign * wingOffset)
					if canPlaceObstacle(wx, wz, 4.2, 6) then
						spawnBlockingFenceWall(wx, wz, fenceYaw, 1, rng, decor)
					end
				end
				-- Frame the gateway with a Lantern Post & a Destructible Soul Urn
				local lx = px + perpX * 4.6
				local lz = pz + perpZ * 4.6
				spawnPrefab("Graveyard_Lantern", lx, lz, fenceYaw, 1, 0, 0, decor)
				spawnSoulUrn(px - perpX * 4.8, pz - perpZ * 4.8, rng, decor)
			else
				-- Path-side Haunted Lantern Post + cobblestone/grass edging
				local side = if (arm + idx) % 2 == 0 then 1 else -1
				local lx = px + perpX * (side * 6.5)
				local lz = pz + perpZ * (side * 6.5)
				spawnPrefab("Graveyard_Lantern", lx, lz, fenceYaw + (if side > 0 then math.pi else 0), 1, 0, 0, decor)
				spawnPrefab(
					"Ground_RubbleCluster",
					px + perpX * (-side * 4.5),
					pz + perpZ * (-side * 4.5),
					rng:NextNumber(0, math.pi * 2),
					rng:NextNumber(0.9, 1.25),
					0,
					0,
					decor
				)
			end
		end
	end

	-- ZONE 2.5: 4 Landmark Graveyard Buildings + Forecourts + Soul Brazier Shrines
	for idx, spec in BUILDING_SPECS do
		local bBound = math.sqrt(spec.halfX * spec.halfX + spec.halfZ * spec.halfZ)
		for _ = 1, 16 do
			local quadAngle = (idx - 1) * (math.pi * 0.5) + math.pi * 0.25 + rng:NextNumber(-0.28, 0.28)
			local r = rng:NextNumber(88, 158)
			local bx = math.cos(quadAngle) * r
			local bz = math.sin(quadAngle) * r
			if canPlaceObstacle(bx, bz, bBound, 18) then
				local bYaw = rng:NextInteger(0, 3) * (math.pi * 0.5)
				spawnBlockingBuilding(idx, spec, bx, bz, bYaw, rng, decor)
				break
			end
		end
	end

	-- ZONE 3B: Randomized Interior Blocking Fence Barricades & Crypt Monuments ("blocking paths here and there")
	for i = 1, 18 do
		local placed = false
		for _ = 1, 14 do
			local r = rng:NextNumber(40, HALF - 34)
			local theta = rng:NextNumber(0, math.pi * 2)
			local cx = math.cos(theta) * r
			local cz = math.sin(theta) * r

			local isFence = i <= 12
			local panels = if rng:NextNumber() < 0.45 then 3 else 2
			local boundRadius = if isFence then (panels * 4.0 + 1.0) else 4.3

			if canPlaceObstacle(cx, cz, boundRadius, MIN_OBSTACLE_CLEARANCE) then
				-- Snap orientation to either cardinal cemetery grid or tangent/radial choke angle
				local yawMode = rng:NextInteger(1, 3)
				local yaw = if yawMode == 1
					then rng:NextInteger(0, 3) * (math.pi * 0.5)
					elseif yawMode == 2 then -theta
					else -theta + math.pi * 0.5

				if isFence then
					spawnBlockingFenceWall(cx, cz, yaw, panels, rng, decor)
				else
					spawnBlockingCrypt(cx, cz, yaw, rng, decor)
				end
				placed = true
				break
			end
		end
		if not placed and #obstacles >= Constants.MAX_ARENA_OBSTACLES then
			break
		end
	end

	-- ZONE 4: 10 Coherent Cemetery Plots (Organized Grave Rows, Crypt Centerpieces, & Soul Urns)
	local plotCenters: { Vector3 } = {}
	for _ = 1, 10 do
		for _ = 1, 16 do
			local r = rng:NextNumber(46, HALF - 38)
			local theta = rng:NextNumber(0, math.pi * 2)
			local px = math.cos(theta) * r
			local pz = math.sin(theta) * r

			local tooCloseToPlot = false
			for _, other in plotCenters do
				local dx = px - other.X
				local dz = pz - other.Z
				if dx * dx + dz * dz < 42 * 42 then
					tooCloseToPlot = true
					break
				end
			end

			if not tooCloseToPlot and canPlaceObstacle(px, pz, 4.5, 13) then
				table.insert(plotCenters, Vector3.new(px, 0, pz))
				local plotYaw = rng:NextInteger(0, 3) * (math.pi * 0.5) + rng:NextNumber(-0.12, 0.12)
				local plotCf = CFrame.new(px, 0, pz) * CFrame.Angles(0, plotYaw, 0)

				-- Anchor the head of the cemetery plot with a collidable Crypt Sarcophagus + Lantern + Soul Urn
				spawnBlockingCrypt(px, pz, plotYaw, rng, decor)
				local lanternPos = plotCf * CFrame.new(3.6, 0, -2.5)
				spawnPrefab(
					"Graveyard_Lantern",
					lanternPos.Position.X,
					lanternPos.Position.Z,
					plotYaw,
					0.95,
					0,
					0,
					decor
				)
				local urnPos = plotCf * CFrame.new(-3.6, 0, -2.2)
				spawnSoulUrn(urnPos.Position.X, urnPos.Position.Z, rng, decor)

				-- 2 Rows x 3 Columns of Cross Headstones & Arched Rune Tombstones aligned with the plot
				local cols = rng:NextInteger(3, 4)
				for row = 1, 2 do
					for col = 1, cols do
						local gx = (col - (cols + 1) * 0.5) * 4.8 + rng:NextNumber(-0.35, 0.35)
						local gz = 5.5 + row * 5.6 + rng:NextNumber(-0.35, 0.35)
						local gravePos = plotCf * CFrame.new(gx, 0, gz)
						local wx = gravePos.Position.X
						local wz = gravePos.Position.Z

						if
							math.abs(wx) < HALF - 14
							and math.abs(wz) < HALF - 14
							and not Arena.isPointBlocked(wx, wz, 1.5)
						then
							local graveKind = if (row + col + rng:NextInteger(0, 1)) % 2 == 0
								then "Grave_Cross"
								else "Grave_Arched"
							local tiltX = rng:NextNumber(-0.07, 0.07)
							local tiltZ = rng:NextNumber(-0.07, 0.07)
							local graveYaw = plotYaw + rng:NextNumber(-0.14, 0.14)
							local scale = rng:NextNumber(0.9, 1.15)
							spawnPrefab(graveKind, wx, wz, graveYaw, scale, tiltX, tiltZ, decor)

							-- Cluster grass tufts, gnarled roots, or rubble right at the base of the headstone
							local basePos = gravePos * CFrame.new(rng:NextNumber(-0.6, 0.6), 0, 0.85)
							local clutterRoll = rng:NextNumber()
							local clutterKind = if clutterRoll < 0.5
								then "Ground_GrassTuft"
								elseif clutterRoll < 0.8 then "Ground_RubbleCluster"
								else "Ground_DeadRoots"
							spawnPrefab(
								clutterKind,
								basePos.Position.X,
								basePos.Position.Z,
								rng:NextNumber(0, math.pi * 2),
								rng:NextNumber(0.85, 1.2),
								0,
								0,
								decor
							)
						end
					end
				end
				break
			end
		end
	end

	-- ZONE 5: Pure Haunted Graveyard Ground Clutter, Withered Dead Trees & Gothic Obelisks (zero NaturePack)
	for _ = 1, 95 do
		local r = rng:NextNumber(14, HALF - 8)
		local theta = rng:NextNumber(0, math.pi * 2)
		local x = math.cos(theta) * r
		local z = math.sin(theta) * r
		if not Arena.isPointBlocked(x, z, 1.6) then
			local roll = rng:NextNumber()
			local kind = if roll < 0.46
				then "Ground_GrassTuft"
				elseif roll < 0.76 then "Ground_RubbleCluster"
				else "Ground_DeadRoots"
			spawnPrefab(kind, x, z, rng:NextNumber(0, math.pi * 2), rng:NextNumber(0.85, 1.4), 0, 0, decor)
		end
	end

	-- Outer border Withered Dead Trees & Gothic Obelisks framing the perimeter iron fence
	for _ = 1, 44 do
		local r = rng:NextNumber(HALF - 32, HALF - 6)
		local theta = rng:NextNumber(0, math.pi * 2)
		local x = math.clamp(math.cos(theta) * r, -(HALF - 7), HALF - 7)
		local z = math.clamp(math.sin(theta) * r, -(HALF - 7), HALF - 7)
		if not Arena.isPointBlocked(x, z, 2.5) then
			local kind = if rng:NextNumber() < 0.68 then "Graveyard_DeadTree" else "Graveyard_Obelisk"
			local scale = rng:NextNumber(0.85, 1.25)
			local yaw = rng:NextNumber(0, math.pi * 2)
			spawnPrefab(kind, x, z, yaw, scale, rng:NextNumber(-0.04, 0.04), rng:NextNumber(-0.04, 0.04), decor)
			local halfSize = if kind == "Graveyard_DeadTree" then 0.85 * scale else 1.15 * scale
			registerObstacle(x, z, halfSize, halfSize, yaw, 1)
		end
	end

	-- Scattered interior Withered Dead Trees & lone weathered Tombstones/Obelisks
	for _ = 1, 22 do
		local r = rng:NextNumber(34, HALF - 36)
		local theta = rng:NextNumber(0, math.pi * 2)
		local x = math.cos(theta) * r
		local z = math.sin(theta) * r
		if not Arena.isPointBlocked(x, z, 2.8) then
			local roll = rng:NextNumber()
			local kind = if roll < 0.45
				then "Graveyard_DeadTree"
				elseif roll < 0.72 then "Graveyard_Obelisk"
				elseif roll < 0.86 then "Grave_Cross"
				else "Grave_Arched"
			local scale = rng:NextNumber(0.9, 1.18)
			local yaw = rng:NextNumber(0, math.pi * 2)
			spawnPrefab(kind, x, z, yaw, scale, rng:NextNumber(-0.05, 0.05), rng:NextNumber(-0.05, 0.05), decor)
			if kind == "Graveyard_DeadTree" or kind == "Graveyard_Obelisk" then
				local halfSize = if kind == "Graveyard_DeadTree" then 0.85 * scale else 1.15 * scale
				registerObstacle(x, z, halfSize, halfSize, yaw, 1)
			end
		end
	end

	-- ZONE 6: Outer Horizon Gothic Cliff Crags & Spires (frames the dark valley beyond the ±240 fence)
	for i = 1, 16 do
		local angle = (i - 1) * (math.pi * 2 / 16) + rng:NextNumber(-0.08, 0.08)
		local r = HALF + rng:NextNumber(16, 34)
		local cx = math.cos(angle) * r
		local cz = math.sin(angle) * r
		spawnPrefab("Graveyard_CliffCrag", cx, cz, -angle + math.pi * 0.5, rng:NextNumber(0.9, 1.35), 0, 0, decor)
	end

	-- Spawn 2 initial Field Reliquary Caches along the avenues so players have early spatial objectives
	for i = 1, 2 do
		local a = getPathAngle(i * 2 - 1, 56) + 0.18
		Arena.spawnReliquaryChest(math.cos(a) * 56, math.sin(a) * 56, false)
	end

	local first = obstacles[1]
	root:SetAttribute("ObstacleCount", #obstacles)
	root:SetAttribute(
		"LayoutSignature",
		if first then string.format("%d:%.1f,%.1f", #obstacles, first.cx, first.cz) else "0"
	)
end

function Arena.build()
	local existing = Workspace:FindFirstChild("Arena")
	if existing then
		existing:Destroy()
	end
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate then
		defaultBaseplate:Destroy()
	end
	local defaultSpawn = Workspace:FindFirstChild("SpawnLocation")
	if defaultSpawn then
		defaultSpawn:Destroy()
	end

	Lighting.ClockTime = 21.5
	Lighting.Brightness = 1.65
	Lighting.Ambient = Color3.fromRGB(78, 88, 108)
	Lighting.OutdoorAmbient = Color3.fromRGB(92, 104, 126)
	Lighting.ColorShift_Top = Color3.fromRGB(140, 165, 210)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.26
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(55, 65, 78)
	atmosphere.Decay = Color3.fromRGB(35, 40, 52)
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local folder = Instance.new("Folder")
	folder.Name = "Arena"
	folder.Parent = Workspace
	arenaFolder = folder

	local gems = Instance.new("Folder")
	gems.Name = "Gems"
	gems.Parent = folder
	Arena.gemsFolder = gems
	Arena.groundY = 0
	Workspace:SetAttribute("GroundY", Arena.groundY)

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(SIZE, 4, SIZE)
	floor.Position = Vector3.new(0, -2, 0)
	floor.Color = Color3.fromRGB(36, 40, 34)
	floor.Material = Enum.Material.Ground
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = folder

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Constants.LOBBY_SPAWN
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	local walls = {
		{
			Vector3.new(SIZE + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS),
			Vector3.new(0, WALL_HEIGHT / 2, -HALF - WALL_THICKNESS / 2),
		},
		{
			Vector3.new(SIZE + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS),
			Vector3.new(0, WALL_HEIGHT / 2, HALF + WALL_THICKNESS / 2),
		},
		{ Vector3.new(WALL_THICKNESS, WALL_HEIGHT, SIZE), Vector3.new(-HALF - WALL_THICKNESS / 2, WALL_HEIGHT / 2, 0) },
		{ Vector3.new(WALL_THICKNESS, WALL_HEIGHT, SIZE), Vector3.new(HALF + WALL_THICKNESS / 2, WALL_HEIGHT / 2, 0) },
	}
	for _, spec in walls do
		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Anchored = true
		wall.Transparency = 1
		wall.CastShadow = false
		wall.CanQuery = false
		wall.Size = spec[1]
		wall.Position = spec[2]
		wall.Parent = folder
	end

	prefabs = buildPrefabTemplates()
	syncPrefabsToServerStorage()

	-- Build the Grand Sanctuary Chapel Interior Lobby (matches sanctuary_chapel_interior.sc & .tcraft)
	do
		local lobby = Instance.new("Folder")
		lobby.Name = "SanctuaryLobby"
		lobby.Parent = folder

		local ly = Constants.LOBBY_FLOOR_Y
		local lobbyCenterZ = -294
		local lobbyWidth = 76
		local lobbyDepth = 92

		-- Main sanctuary chapel stone foundation & flagstone floor
		makePart({
			name = "SanctuaryFoundation",
			size = Vector3.new(lobbyWidth + 4, ly, lobbyDepth + 4),
			cframe = CFrame.new(0, ly * 0.5 - 1, lobbyCenterZ),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = lobby,
			canCollide = true,
			castShadow = true,
		})
		makePart({
			name = "SanctuaryTerraceFloor",
			size = Vector3.new(lobbyWidth, 1.5, lobbyDepth),
			cframe = CFrame.new(0, ly - 0.75, lobbyCenterZ),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = lobby,
			canCollide = true,
		})

		-- Spawn the Grand Sanctuary Chapel Interior (Walls, Rose Window, 6 Lancet Windows, 8 Columns, Vault Ribs, 8 Oak Pews, High Altar)
		spawnPrefabAtY("Sanctuary_Chapel_Interior", 0, ly, lobbyCenterZ, 0, 1, 0, 0, lobby)

		-- Invisible safety boundary walls aligned with the Chapel Nave perimeter
		local lobbyWalls = {
			{ Vector3.new(lobbyWidth, 26, 2), Vector3.new(0, ly + 13, lobbyCenterZ - lobbyDepth * 0.5) },
			{ Vector3.new(lobbyWidth, 26, 2), Vector3.new(0, ly + 13, lobbyCenterZ + lobbyDepth * 0.5) },
			{ Vector3.new(2, 26, lobbyDepth), Vector3.new(-lobbyWidth * 0.5, ly + 13, lobbyCenterZ) },
			{ Vector3.new(2, 26, lobbyDepth), Vector3.new(lobbyWidth * 0.5, ly + 13, lobbyCenterZ) },
		}
		for _, w in lobbyWalls do
			makePart({
				name = "LobbyBoundaryWall",
				size = w[1],
				cframe = CFrame.new(w[2]),
				color = IRON_DARK,
				material = Enum.Material.SmoothPlastic,
				parent = lobby,
				canCollide = true,
				transparency = 1,
			})
		end

		-- =====================================================================
		-- PILLAR 4A: Solo Instant Catacomb Portal at South Narthex Archway (0, 14, -252)
		-- =====================================================================
		spawnPrefabAtY(
			"Catacomb_Descent_Portal",
			Constants.LOBBY_PORTAL_POS.X,
			ly,
			Constants.LOBBY_PORTAL_POS.Z,
			0,
			1,
			0,
			0,
			lobby
		)

		local vortex = makePart({
			name = "RunicPortalVortex",
			size = Vector3.new(6.8, 9.2, 0.45),
			cframe = CFrame.new(Constants.LOBBY_PORTAL_POS.X, ly + 5.2, Constants.LOBBY_PORTAL_POS.Z - 0.4),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			transparency = 0.2,
			parent = lobby,
		})
		local vortexLight = Instance.new("PointLight")
		vortexLight.Color = RUNE_CYAN
		vortexLight.Brightness = 3.0
		vortexLight.Range = 36
		vortexLight.Shadows = false
		vortexLight.Parent = vortex

		makePart({
			name = "PortalTriggerRing",
			size = Vector3.new(0.25, Constants.LOBBY_PORTAL_RADIUS * 2, Constants.LOBBY_PORTAL_RADIUS * 2),
			cframe = CFrame.new(Constants.LOBBY_PORTAL_POS.X, ly + 0.14, Constants.LOBBY_PORTAL_POS.Z - 2.5)
				* CFrame.Angles(0, 0, math.pi * 0.5),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Cylinder,
			transparency = 0.45,
			parent = lobby,
		})

		local bb = Instance.new("BillboardGui")
		bb.Name = "PortalBillboard"
		bb.Size = UDim2.fromOffset(330, 76)
		bb.StudsOffset = Vector3.new(0, 8.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 120
		bb.Parent = vortex

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.fromScale(1, 1)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.Merriweather
		titleLabel.RichText = true
		titleLabel.TextColor3 = Color3.fromRGB(165, 255, 235)
		titleLabel.TextStrokeColor3 = Color3.fromRGB(10, 18, 22)
		titleLabel.TextStrokeTransparency = 0.15
		titleLabel.TextSize = 20
		titleLabel.Text =
			'<b>⚔️ SOLO INSTANT PORTAL</b>\n<font size="14" color="#ffd878">Walk In for 0s Instant Drop-In</font>'
		titleLabel.Parent = bb

		-- =====================================================================
		-- PILLAR 4B: Co-Op Squad Expedition Ring (1-4 Players, +15% Souls & +15 Ward)
		-- =====================================================================
		local coopPos = Constants.LOBBY_COOP_PORTAL_POS
		local coopRing = makePart({
			name = "CoopPortalTriggerRing",
			size = Vector3.new(0.28, Constants.LOBBY_COOP_PORTAL_RADIUS * 2, Constants.LOBBY_COOP_PORTAL_RADIUS * 2),
			cframe = CFrame.new(coopPos.X, ly + 0.16, coopPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5),
			color = Color3.fromRGB(255, 205, 70),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Cylinder,
			transparency = 0.35,
			parent = lobby,
		})
		local coopBeacon = makePart({
			name = "CoopPortalBeacon",
			size = Vector3.new(10, 8.5, 8.5),
			cframe = CFrame.new(coopPos.X, ly + 5.0, coopPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5),
			color = Color3.fromRGB(95, 245, 175),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Cylinder,
			transparency = 0.82,
			parent = lobby,
		})
		local coopBb = Instance.new("BillboardGui")
		coopBb.Name = "CoopPortalBillboard"
		coopBb.Size = UDim2.fromOffset(320, 74)
		coopBb.StudsOffset = Vector3.new(0, 6.2, 0)
		coopBb.AlwaysOnTop = true
		coopBb.MaxDistance = 110
		coopBb.Parent = coopRing

		local coopLbl = Instance.new("TextLabel")
		coopLbl.Size = UDim2.fromScale(1, 1)
		coopLbl.BackgroundTransparency = 1
		coopLbl.Font = Enum.Font.GothamBlack
		coopLbl.RichText = true
		coopLbl.TextColor3 = Color3.fromRGB(255, 230, 120)
		coopLbl.TextStrokeColor3 = Color3.fromRGB(8, 12, 18)
		coopLbl.TextStrokeTransparency = 0.12
		coopLbl.TextSize = 15
		coopLbl.Text =
			"🤝 CO-OP SQUAD RING (0/4)\n<font size='12' color='#9effd8'>Step In to Queue • +15% Souls & +15 Starting Ward!</font>"
		coopLbl.Parent = coopBb
		coopPortalLabel = coopLbl
		local _ = coopBeacon

		-- =====================================================================
		-- PILLAR 6: Central Crossing Sanctuary Soul Font (0, 14, -296)
		-- =====================================================================
		local fontPos = Constants.LOBBY_SOUL_FONT_POS
		makePart({
			name = "SoulFontPedestal",
			size = Vector3.new(5.6, 2.2, 5.6),
			cframe = CFrame.new(fontPos.X, ly + 1.1, fontPos.Z),
			color = BRONZE_PLAQUE,
			material = Enum.Material.Metal,
			parent = lobby,
			canCollide = true,
		})
		local fontBasin = makePart({
			name = "SoulFontBasin",
			size = Vector3.new(6.6, 0.75, 6.6),
			cframe = CFrame.new(fontPos.X, ly + 2.4, fontPos.Z),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = lobby,
			canCollide = true,
		})
		makePart({
			name = "SoulFontWaterPool",
			size = Vector3.new(5.4, 0.35, 5.4),
			cframe = CFrame.new(fontPos.X, ly + 2.75, fontPos.Z),
			color = RUNE_CYAN,
			material = Enum.Material.Neon,
			parent = lobby,
		})
		spawnPrefabAtY("Relic_SoulCrystal", fontPos.X, ly + 2.8, fontPos.Z, 0, 1.05, 0, 0, lobby)

		local fontBb = Instance.new("BillboardGui")
		fontBb.Size = UDim2.fromOffset(290, 62)
		fontBb.StudsOffset = Vector3.new(0, 6.4, 0)
		fontBb.AlwaysOnTop = true
		fontBb.MaxDistance = 95
		fontBb.Parent = fontBasin

		local fontLbl = Instance.new("TextLabel")
		fontLbl.Size = UDim2.fromScale(1, 1)
		fontLbl.BackgroundTransparency = 1
		fontLbl.Font = Enum.Font.GothamBlack
		fontLbl.RichText = true
		fontLbl.TextColor3 = Color3.fromRGB(130, 255, 235)
		fontLbl.TextStrokeColor3 = Color3.fromRGB(8, 12, 18)
		fontLbl.TextStrokeTransparency = 0.1
		fontLbl.TextSize = 15
		fontLbl.Text =
			"✨ SANCTUARY SOUL FONT\n<font size='12' color='#ffe898'>Press [E] for Free Run Blessing (+20 Ward & +10% Speed)</font>"
		fontLbl.Parent = fontBb

		local fontPrompt = Instance.new("ProximityPrompt")
		fontPrompt.ActionText = "Claim Blessing"
		fontPrompt.ObjectText = "✨ Sanctuary Soul Font (+20 Ward & +10% Speed)"
		fontPrompt.HoldDuration = 0
		fontPrompt.MaxActivationDistance = 14
		fontPrompt.RequiresLineOfSight = false
		fontPrompt.Triggered:Connect(function(player)
			PlayerState.claimSanctuaryBlessing(player)
		end)
		fontPrompt.Parent = fontBasin

		-- =====================================================================
		-- PILLAR 2: Complete 6-Weapon Reliquary Gallery along West Colonnade Aisle (X = -27.5)
		-- =====================================================================
		local weaponPedestals = {
			{
				id = "ArcanistStaff",
				title = "🔮 Arcanist's Staff",
				subtitle = "Homing Bolts • Evo: Astral Starfall",
				prefab = "Relic_MagicBolt",
				z = -265,
				color = Color3.fromRGB(95, 225, 255),
			},
			{
				id = "CryptCleaver",
				title = "🪓 Crypt Cleaver",
				subtitle = "125° Frontal Cone • Evo: Crimson Guillotine",
				prefab = "Relic_CryptCleaver",
				z = -276,
				color = Color3.fromRGB(205, 135, 255),
			},
			{
				id = "SoulflameLantern",
				title = "🏮 Soulflame Lantern",
				subtitle = "Sacred Burn Zones • Evo: Ashen Hellstorm",
				prefab = "Graveyard_Lantern",
				z = -287,
				color = Color3.fromRGB(255, 185, 80),
			},
			{
				id = "PhantomBow",
				title = "🏹 Phantom Longbow",
				subtitle = "High-Crit Piercing • Evo: Thousand-Arrow Tempest",
				prefab = "Relic_PhantomBow",
				z = -298,
				color = Color3.fromRGB(95, 255, 170),
			},
			{
				id = "HexlockPistols",
				title = "🔫 Hexlock Pistols",
				subtitle = "Rapid Twin-Shot • Evo: Silver Executioner",
				prefab = "Relic_HexlockPistols",
				z = -309,
				color = Color3.fromRGB(255, 105, 135),
			},
			{
				id = "StormcallerTome",
				title = "⚡ Stormcaller Grimoire",
				subtitle = "Chain Lightning • Evo: Mjolnir's Wrath",
				prefab = "Relic_StormcallerTome",
				z = -320,
				color = Color3.fromRGB(125, 210, 255),
			},
		}

		for _, wp in weaponPedestals do
			local px = -27.5
			local ped = makePart({
				name = "ReliquaryPedestal_" .. wp.id,
				size = Vector3.new(3.4, 2.4, 3.4),
				cframe = CFrame.new(px, ly + 1.8, wp.z),
				color = BRONZE_PLAQUE,
				material = Enum.Material.Metal,
				parent = lobby,
				canCollide = true,
			})
			makePart({
				name = "ReliquaryCap_" .. wp.id,
				size = Vector3.new(4.0, 0.45, 4.0),
				cframe = CFrame.new(px, ly + 3.1, wp.z),
				color = wp.color,
				material = Enum.Material.Neon,
				transparency = 0.25,
				parent = lobby,
			})
			spawnPrefabAtY(wp.prefab, px, ly + 3.3, wp.z, math.pi * 0.5, 1.05, 0, 0, lobby)

			local wBb = Instance.new("BillboardGui")
			wBb.Size = UDim2.fromOffset(230, 52)
			wBb.StudsOffset = Vector3.new(0, 4.8, 0)
			wBb.AlwaysOnTop = false
			wBb.MaxDistance = 42
			wBb.Parent = ped

			local wLbl = Instance.new("TextLabel")
			wLbl.Size = UDim2.fromScale(1, 1)
			wLbl.BackgroundTransparency = 1
			wLbl.Font = Enum.Font.GothamBlack
			wLbl.RichText = true
			wLbl.TextColor3 = wp.color
			wLbl.TextStrokeColor3 = Color3.fromRGB(8, 10, 16)
			wLbl.TextStrokeTransparency = 0.1
			wLbl.TextSize = 13
			wLbl.Text = string.format("%s\n<font size='11' color='#e2e8f0'>%s</font>", wp.title, wp.subtitle)
			wLbl.Parent = wBb

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Equip"
			prompt.ObjectText = wp.title
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Triggered:Connect(function(player)
				local state = PlayerState.get(player)
				if state then
					PlayerState.setWeapon(state, wp.id)
				end
			end)
			prompt.Parent = ped
		end

		-- =====================================================================
		-- PILLAR 1: East Transept Combat Training Yard & 3 Target Dummies (X = +27.5)
		-- =====================================================================
		table.clear(trainingDummies)
		local dummySpecs = {
			{ id = 1, name = "🎯 Straw Target Dummy", z = -272, color = Color3.fromRGB(215, 175, 95), scale = 1.0 },
			{
				id = 2,
				name = "🛡️ Armored Crypt Dummy",
				z = -290,
				color = Color3.fromRGB(130, 155, 190),
				scale = 1.2,
			},
			{
				id = 3,
				name = "💀 Swarm Cluster Dummy",
				z = -308,
				color = Color3.fromRGB(190, 110, 235),
				scale = 0.95,
			},
		}

		for _, dm in dummySpecs do
			local dx = 27.5
			local dy = ly + 0.6
			makePart({
				name = "DummyBase_" .. dm.id,
				size = Vector3.new(3.2, 0.5, 3.2),
				cframe = CFrame.new(dx, dy + 0.25, dm.z),
				color = STONE_DARK,
				material = Enum.Material.Cobblestone,
				parent = lobby,
				canCollide = true,
			})
			makePart({
				name = "DummyPost_" .. dm.id,
				size = Vector3.new(0.8, 5.2 * dm.scale, 0.8),
				cframe = CFrame.new(dx, dy + 2.6 * dm.scale, dm.z),
				color = ROOT_BARK,
				material = Enum.Material.WoodPlanks,
				parent = lobby,
				canCollide = true,
			})
			local torso = makePart({
				name = "DummyTorso_" .. dm.id,
				size = Vector3.new(2.2 * dm.scale, 2.8 * dm.scale, 2.2 * dm.scale),
				cframe = CFrame.new(dx, dy + 3.4 * dm.scale, dm.z),
				color = dm.color,
				material = Enum.Material.Slate,
				shape = Enum.PartType.Cylinder,
				parent = lobby,
				canCollide = true,
			})
			makePart({
				name = "DummyCrossbar_" .. dm.id,
				size = Vector3.new(0.65, 0.65, 4.2 * dm.scale),
				cframe = CFrame.new(dx, dy + 4.1 * dm.scale, dm.z),
				color = ROOT_BARK,
				material = Enum.Material.WoodPlanks,
				parent = lobby,
			})
			makePart({
				name = "DummyHead_" .. dm.id,
				size = Vector3.new(1.5 * dm.scale, 1.5 * dm.scale, 1.5 * dm.scale),
				cframe = CFrame.new(dx, dy + 5.5 * dm.scale, dm.z),
				color = dm.color,
				material = Enum.Material.Cobblestone,
				shape = Enum.PartType.Ball,
				parent = lobby,
			})

			local dBb = Instance.new("BillboardGui")
			dBb.Size = UDim2.fromOffset(200, 36)
			dBb.StudsOffset = Vector3.new(0, 3.6, 0)
			dBb.AlwaysOnTop = false
			dBb.MaxDistance = 42
			dBb.Parent = torso

			local dLbl = Instance.new("TextLabel")
			dLbl.Size = UDim2.fromScale(1, 1)
			dLbl.BackgroundTransparency = 1
			dLbl.Font = Enum.Font.GothamBlack
			dLbl.TextColor3 = dm.color
			dLbl.TextStrokeColor3 = Color3.fromRGB(8, 10, 16)
			dLbl.TextStrokeTransparency = 0.1
			dLbl.TextSize = 13
			dLbl.Text = dm.name
			dLbl.Parent = dBb

			if dm.id == 2 then
				local dpsBb = Instance.new("BillboardGui")
				dpsBb.Name = "SanctuaryDpsBillboard"
				dpsBb.Size = UDim2.fromOffset(340, 74)
				dpsBb.StudsOffset = Vector3.new(0, 6.8, 0)
				dpsBb.AlwaysOnTop = false
				dpsBb.MaxDistance = 55
				dpsBb.Parent = torso

				local dpsLbl = Instance.new("TextLabel")
				dpsLbl.Size = UDim2.fromScale(1, 1)
				dpsLbl.BackgroundTransparency = 1
				dpsLbl.Font = Enum.Font.GothamBlack
				dpsLbl.RichText = true
				dpsLbl.TextColor3 = Color3.fromRGB(255, 225, 110)
				dpsLbl.TextStrokeColor3 = Color3.fromRGB(8, 10, 16)
				dpsLbl.TextStrokeTransparency = 0.08
				dpsLbl.TextSize = 15
				dpsLbl.Text =
					"⚔️ CHAPEL TRAINING YARD — LIVE DPS\n<font size='12' color='#9effd8'>Stand Nearby to Auto-Attack • Press [Space] to Dash!</font>"
				dpsLbl.Parent = dpsBb
				dpsMeterLabel = dpsLbl
			end

			table.insert(trainingDummies, {
				id = dm.id,
				name = dm.name,
				x = dx,
				y = dy + 3.2,
				z = dm.z,
				radius = 2.2 * dm.scale,
			})
		end

		-- =====================================================================
		-- PILLAR 3: Diegetic 3D Chapel Alcove Stations (Talents, Armory, Keystone/Vault, Treasury)
		-- =====================================================================
		local stations = {
			{
				modal = "Talents",
				title = "✨ HIGH ALTAR OF TALENTS [N]",
				subtitle = "Spend Soul Points & Unlock Class Ascendancies",
				pos = Vector3.new(0, ly + 2.4, -325),
				color = Color3.fromRGB(185, 130, 255),
			},
			{
				modal = "Armory",
				title = "🛡️ SACRISTY ARMORY & GRIMOIRE [C / B]",
				subtitle = "Equip Relics, Enchant Gear & View Bestiary",
				pos = Vector3.new(-14.5, ly + 0.8, -325),
				color = Color3.fromRGB(95, 215, 255),
			},
			{
				modal = "Keystone",
				title = "🗝️ MYTHIC+ KEYSTONE & GREAT VAULT [J]",
				subtitle = "Activate +1 to +15 Affixes & Claim Weekly Loot",
				pos = Vector3.new(14.5, ly + 0.8, -325),
				color = Color3.fromRGB(255, 185, 65),
			},
			{
				modal = "Shop",
				title = "💎 SANCTUARY TREASURY & QUESTS [M / V]",
				subtitle = "Claim Daily Quests, Streaks & Blessings",
				pos = Vector3.new(16.5, ly + 0.2, -256),
				color = Color3.fromRGB(95, 250, 175),
			},
		}

		for _, st in stations do
			local ring = makePart({
				name = "ChapelStation_" .. st.modal,
				size = Vector3.new(0.24, 6.2, 6.2),
				cframe = CFrame.new(st.pos.X, st.pos.Y + 0.14, st.pos.Z) * CFrame.Angles(0, 0, math.pi * 0.5),
				color = st.color,
				material = Enum.Material.Neon,
				shape = Enum.PartType.Cylinder,
				transparency = 0.38,
				parent = lobby,
			})
			local sBb = Instance.new("BillboardGui")
			sBb.Size = UDim2.fromOffset(260, 56)
			sBb.StudsOffset = Vector3.new(0, 4.4, 0)
			sBb.AlwaysOnTop = false
			sBb.MaxDistance = 52
			sBb.Parent = ring

			local sLbl = Instance.new("TextLabel")
			sLbl.Size = UDim2.fromScale(1, 1)
			sLbl.BackgroundTransparency = 1
			sLbl.Font = Enum.Font.GothamBlack
			sLbl.RichText = true
			sLbl.TextColor3 = st.color
			sLbl.TextStrokeColor3 = Color3.fromRGB(8, 10, 16)
			sLbl.TextStrokeTransparency = 0.1
			sLbl.TextSize = 13
			sLbl.Text = string.format("%s\n<font size='11' color='#e2e8f0'>%s</font>", st.title, st.subtitle)
			sLbl.Parent = sBb

			local sPrompt = Instance.new("ProximityPrompt")
			sPrompt.ActionText = "Open " .. st.modal
			sPrompt.ObjectText = st.title
			sPrompt.HoldDuration = 0
			sPrompt.MaxActivationDistance = 12
			sPrompt.RequiresLineOfSight = false
			sPrompt.Triggered:Connect(function(player)
				player:SetAttribute("OpenLobbyModal", st.modal .. ";" .. tostring(os.clock()))
			end)
			sPrompt.Parent = ring
		end

		-- =====================================================================
		-- PILLAR 5: Hall of Champions Steles flanking the North Chancel Steps
		-- =====================================================================
		for _, side in { -1, 1 } do
			local stele = makePart({
				name = if side == -1 then "HallOfChampionsWest" else "HallOfChampionsEast",
				size = Vector3.new(4.2, 6.8, 0.8),
				cframe = CFrame.new(side * 12.5, ly + 3.8, -315),
				color = IRON_DARK,
				material = Enum.Material.Slate,
				parent = lobby,
				canCollide = true,
			})
			makePart({
				name = "SteleGoldFrame",
				size = Vector3.new(4.5, 7.1, 0.6),
				cframe = CFrame.new(side * 12.5, ly + 3.8, -315.1),
				color = BRONZE_PLAQUE,
				material = Enum.Material.Metal,
				parent = lobby,
			})
			local hBb = Instance.new("BillboardGui")
			hBb.Size = UDim2.fromOffset(230, 110)
			hBb.StudsOffset = Vector3.new(0, 1.2, 0)
			hBb.AlwaysOnTop = false
			hBb.MaxDistance = 52
			hBb.Parent = stele

			local hLbl = Instance.new("TextLabel")
			hLbl.Size = UDim2.fromScale(1, 1)
			hLbl.BackgroundTransparency = 0.25
			hLbl.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
			hLbl.Font = Enum.Font.GothamBold
			hLbl.RichText = true
			hLbl.TextColor3 = Color3.fromRGB(255, 225, 130)
			hLbl.TextStrokeColor3 = Color3.fromRGB(6, 8, 12)
			hLbl.TextStrokeTransparency = 0.15
			hLbl.TextSize = 12
			hLbl.Parent = hBb
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = hLbl

			if side == -1 then
				hLbl.Text =
					"<b>🏆 HALL OF CHAMPIONS</b>\n<font color='#9effd8'>Top Hero Level & Mythic+</font>\nAwaiting Heroes..."
				championsWestLabel = hLbl
			else
				hLbl.Text =
					"<b>💀 SLAYERS OF THE CRYPT</b>\n<font color='#ffd080'>Top Undying Kills & Souls</font>\nAwaiting Heroes..."
				championsEastLabel = hLbl
			end
		end
	end

	-- Outer perimeter wrought-iron & stone fence ring around the entire arena boundary
	buildPerimeterFence(folder)

	-- Initial randomized graveyard run layout
	Arena.rebuild()
end

function Arena.getTrainingDummies(): { TrainingDummy }
	return trainingDummies
end

function Arena.recordDummyHit(damage: number, isCrit: boolean)
	local now = os.clock()
	totalDummyDamage += damage
	table.insert(dummyHits, { t = now, dmg = damage })
	local idx = 1
	local windowSum = 0
	while idx <= #dummyHits do
		if now - dummyHits[idx].t > 5.0 then
			table.remove(dummyHits, idx)
		else
			windowSum += dummyHits[idx].dmg
			idx += 1
		end
	end
	local dps = math.floor(windowSum / 5.0 + 0.5)
	if dpsMeterLabel then
		local critTag = if isCrit then " <font color='#ff6888'>(CRIT!)</font>" else ""
		dpsMeterLabel.Text = string.format(
			"⚔️ CHAPEL TRAINING YARD — LIVE DPS: <font color='#55ffaa'>%d/s</font>\n<font size='12' color='#ffe898'>Last Hit: %d%s • Total Damage: %d</font>",
			dps,
			math.floor(damage + 0.5),
			critTag,
			math.floor(totalDummyDamage + 0.5)
		)
	end
end

function Arena.updateCoopPortalBillboard(queuedCount: number, remainingSec: number?)
	if not coopPortalLabel then
		return
	end
	if queuedCount > 0 and remainingSec ~= nil then
		coopPortalLabel.Text = string.format(
			"🤝 CO-OP SQUAD DEPLOYING (%d/4) — %.1fs!\n<font size='12' color='#55ffaa'>+15%% Co-Op Souls & +15 Starting Ward Active!</font>",
			queuedCount,
			math.max(0, remainingSec)
		)
	else
		coopPortalLabel.Text =
			"🤝 CO-OP SQUAD RING (0/4)\n<font size='12' color='#9effd8'>Step In to Queue • +15% Souls & +15 Starting Ward!</font>"
	end
end

function Arena.updateHallOfChampions(westText: string, eastText: string)
	if championsWestLabel then
		championsWestLabel.Text = westText
	end
	if championsEastLabel then
		championsEastLabel.Text = eastText
	end
end

return Arena
