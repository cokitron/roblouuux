--!strict
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local EnemyCandidates = {}

-- Audited, script-free Roblox Creator Store 3D Assets (PROC-6 verified)
EnemyCandidates.CREATOR_STORE_ASSETS = {
	-- Full Creature Models (TypeId = 10)
	SkeletonModel = 122900915480688, -- "Szkielet" by Matipre3
	BatModel = 13844735682, -- "bat" by Woofdadoggamer
	GolemModel = 15721914045, -- "Golem Mesh" by Pantasticker
	SpiderModel = 136579301883061, -- "Spider" by Thugtastico
	SlimeModel = 15115599443, -- "Slime Monster" by mamakoa256
	FrostWyrmModel = 127058673521936, -- "Ice Dragon Statue" by botolparfumm
	GrimReaperModel = 2199985564, -- "Grim Reaper" by TaddychicAdvenclub

	-- Individual 3D MeshParts (TypeId = 40)
	GlassBow = 524541876, -- "Glass Bow" by pitaden (MeshId 524541858, TexId 524541866)
	AncientNordBow = 871059549, -- "Ancient Nord Bow" by pitaden (MeshId 871059516, TexId 871059532)
	ExecutionerAxe = 867643066, -- "Executioner's Axe" by pitaden (MeshId 867643049, TexId 867643060)
	BattleAxe = 133920191867907, -- "Stylized Fantasy Battle Axe" by Tong_p05 (MeshId 82620371185842)
	FlintlockPistol = 101559657970017, -- "Flintlock Pistol" by imdie5677878 (MeshId 123641875079236)
	StaffOfMagnus = 591079857, -- "Staff of Magnus" by pitaden (MeshId 591079842, TexId 591079849)
	CrystalStaff = 72223197697975, -- "Crystal Wizard Staff" by bearsigb (MeshId 80377494756156)
	RunicGrimoire = 109820689568362, -- "yuno book/grimoire" by AZelister12 (MeshId 120062356602177)
	GothicLantern = 8260717445, -- "lantern" by fireflanger (MeshId 8260717364, TexId 8260717404)
	OldIronLamp = 14951552941, -- "OldLamp" by NikaChanik (MeshId 14951552727, TexId 14951552888)
	SkullOfAinz = 2445801226, -- "Skull of Ainz" by BLODSWIPER (MeshId 2445801147)
	SkeletonRibcage = 3284551923, -- "Skeleton Torso" by The Kingdom of Mordor (MeshId 3284551878)
	EliteHelm = 2456506230, -- "Elite Knight Helmet" by BLODSWIPER (MeshId 2456506198)
	GothicSword = 5579516226, -- "GOTHIC italian fantasy SWORD 01" by LordLucifers (MeshId 5579516174)
	PolyhexScythe = 1561827216, -- "Polyhex Scythe" by zmby2 (MeshId 1561827194)
	NordArrow = 871018403, -- "Ancient Nord Arrow" by pitaden (MeshId 871018391, TexId 871018398)
	BatWings = 12444481426, -- "Bat wings" by LoopLoop85 (MeshId 12444481320, TexId 12444481363)
	DemonHorns = 15555147076, -- "Black Demon Horns" by gamenawesome100 (MeshId 15555147009)
	DragonHead = 1513601847, -- "Dragon Head" by Narutorobert (MeshId 1513601819)
	QuartzCluster = 447264636, -- "Quartz Crystal Cluster" by XenoSynthesis (MeshId 447264627)
}

export type EnemyCandidateDef = {
	name: string,
	title: string,
	archetype: string,
	health: number,
	speed: number,
	damage: number,
	experience: number,
	radius: number,
	size: Vector3,
	color: Color3,
	shape: Enum.PartType,
	description: string,
}

EnemyCandidates.CATALOG = {
	-- Wave 1: First 12 Candidates
	{
		name = "Wraith",
		title = "The Mourning Specter",
		archetype = "Ethereal / Phase",
		health = 10,
		speed = 13,
		damage = 6,
		experience = 1,
		radius = 1.3,
		size = Vector3.new(2.4, 3.2, 2.4),
		color = Color3.fromRGB(45, 52, 65),
		shape = Enum.PartType.Block,
		description = "Fast drifting hooded ghost with tattered cowl, glowing soul cyan eyes, and inner soul flame.",
	},
	{
		name = "CryptGhoul",
		title = "Feral Carrion Feeder",
		archetype = "Hunched Rusher",
		health = 14,
		speed = 12,
		damage = 9,
		experience = 2,
		radius = 1.4,
		size = Vector3.new(2.6, 2.6, 2.6),
		color = Color3.fromRGB(125, 120, 110),
		shape = Enum.PartType.Block,
		description = "Emaciated feral corpse low to the ground with elongated jagged talons and feverish amber eyes.",
	},
	{
		name = "PlagueCrow",
		title = "Carrion Raven",
		archetype = "Aerial Swarmer",
		health = 8,
		speed = 16,
		damage = 5,
		experience = 1,
		radius = 1.2,
		size = Vector3.new(3.0, 1.8, 2.8),
		color = Color3.fromRGB(28, 28, 36),
		shape = Enum.PartType.Ball,
		description = "Giant carrion bird with bone skull beak, hooked talons, swept wings, and toxic green eyes.",
	},
	{
		name = "BoneHound",
		title = "Skeletal Stalker",
		archetype = "Fast Flanker",
		health = 16,
		speed = 13.5,
		damage = 8,
		experience = 2,
		radius = 1.5,
		size = Vector3.new(2.2, 2.4, 4.2),
		color = Color3.fromRGB(220, 210, 185),
		shape = Enum.PartType.Block,
		description = "Quadruped skeletal beast with arched spine, barbed ribs, snapping canine jaws, and crimson eyes.",
	},
	{
		name = "DeathKnight",
		title = "Fallen Revenant",
		archetype = "Armored Elite",
		health = 55,
		speed = 7.5,
		damage = 16,
		experience = 5,
		radius = 2.2,
		size = Vector3.new(3.6, 4.8, 3.6),
		color = Color3.fromRGB(42, 44, 50),
		shape = Enum.PartType.Block,
		description = "Corrupted heavy plate warrior with spiked pauldrons, horned greathelm, runic greatsword, and crimson visor.",
	},
	{
		name = "BoneScarab",
		title = "Tomb Scarab Beetle",
		archetype = "Armored Swarmer",
		health = 22,
		speed = 10,
		damage = 7,
		experience = 2,
		radius = 1.4,
		size = Vector3.new(2.8, 1.6, 3.2),
		color = Color3.fromRGB(38, 34, 42),
		shape = Enum.PartType.Ball,
		description = "Chittering catacomb scarab with domed obsidian shell, bone dorsal ridge, sharp mandibles, and amber eyes.",
	},
	{
		name = "AbyssalWatcher",
		title = "Eldritch Eye",
		archetype = "Floating Artillery",
		health = 15,
		speed = 9.5,
		damage = 11,
		experience = 3,
		radius = 1.5,
		size = Vector3.new(2.8, 3.4, 2.8),
		color = Color3.fromRGB(150, 60, 210),
		shape = Enum.PartType.Ball,
		description = "Floating fleshy eye sphere with radiant violet iris, slit abyss pupil, and four dangling tendrils.",
	},
	{
		name = "NecromancerAcolyte",
		title = "Bone Cultist",
		archetype = "Summoner / Support",
		health = 24,
		speed = 8,
		damage = 12,
		experience = 4,
		radius = 1.6,
		size = Vector3.new(2.6, 4.4, 2.6),
		color = Color3.fromRGB(48, 32, 64),
		shape = Enum.PartType.Block,
		description = "Antler-crowned cultist in dark ceremonial robes carrying a gnarled skull staff with purple soul flame.",
	},
	{
		name = "CursedGargoyle",
		title = "Living Grotesque",
		archetype = "Stone Bruiser",
		health = 38,
		speed = 10.5,
		damage = 14,
		experience = 4,
		radius = 2.0,
		size = Vector3.new(4.2, 4.0, 3.2),
		color = Color3.fromRGB(72, 76, 82),
		shape = Enum.PartType.Block,
		description = "Weathered slate grotesque with folded stone wings, curved demon horns, clawed talons, and molten orange eyes.",
	},
	{
		name = "RotWorm",
		title = "Carrion Leech",
		archetype = "Segmented Sponge",
		health = 28,
		speed = 7,
		damage = 10,
		experience = 3,
		radius = 1.6,
		size = Vector3.new(2.4, 2.2, 5.0),
		color = Color3.fromRGB(88, 70, 80),
		shape = Enum.PartType.Ball,
		description = "Segmented bloated maggot crawling from grave loam, needle maw ring, dorsal spines, and toxic bile core.",
	},
	{
		name = "ShadowStalker",
		title = "Umbral Shade",
		archetype = "Stealth Assassin",
		health = 12,
		speed = 16.5,
		damage = 11,
		experience = 2,
		radius = 1.2,
		size = Vector3.new(2.0, 3.6, 2.0),
		color = Color3.fromRGB(15, 15, 20),
		shape = Enum.PartType.Block,
		description = "Razor-limbed smoky silhouette with piercing white eye sparks, needle-thin talons, and smoky wisps.",
	},
	{
		name = "OssuaryBehemoth",
		title = "Tomb Titan",
		archetype = "Colossal Boss",
		health = 180,
		speed = 5.5,
		damage = 30,
		experience = 15,
		radius = 4.0,
		size = Vector3.new(7.0, 8.5, 6.0),
		color = Color3.fromRGB(78, 74, 70),
		shape = Enum.PartType.Block,
		description = "Massive stitched titan fused with grave rubble and chains, cyclopean red eye, wielding a broken tombstone club.",
	},

	-- Wave 2: 12 More Candidates
	{
		name = "BarrowWight",
		title = "The Entombed King",
		archetype = "Mummified Sovereign",
		health = 42,
		speed = 8.5,
		damage = 15,
		experience = 4,
		radius = 1.8,
		size = Vector3.new(2.4, 4.4, 2.2),
		color = Color3.fromRGB(130, 120, 105),
		shape = Enum.PartType.Block,
		description = "Ancient embalmed undead king in rotting burial shrouds, spiked bronze circlet, and curved sickle khopesh.",
	},
	{
		name = "CatacombRat",
		title = "Plague Vermin",
		archetype = "Fast Swarmer",
		health = 6,
		speed = 17,
		damage = 4,
		experience = 1,
		radius = 1.0,
		size = Vector3.new(1.8, 1.4, 3.2),
		color = Color3.fromRGB(48, 42, 45),
		shape = Enum.PartType.Ball,
		description = "Diseased oversized sewer rodent with bristling ragged fur, long scaly tail, and sickly yellow incisors.",
	},
	{
		name = "GraveReaper",
		title = "Scythe Fiend",
		archetype = "Wide Sweeper",
		health = 32,
		speed = 9.0,
		damage = 18,
		experience = 4,
		radius = 2.0,
		size = Vector3.new(3.2, 5.0, 3.0),
		color = Color3.fromRGB(20, 20, 26),
		shape = Enum.PartType.Block,
		description = "Grim hovering specter in deep black cowl wielding a towering two-handed bone scythe with wide reach.",
	},
	{
		name = "CandelabraMimic",
		title = "Possessed Reliquary",
		archetype = "Spurred Ambush",
		health = 20,
		speed = 11.5,
		damage = 8,
		experience = 2,
		radius = 1.4,
		size = Vector3.new(2.4, 3.4, 2.4),
		color = Color3.fromRGB(36, 38, 42),
		shape = Enum.PartType.Block,
		description = "Wrought iron altar candelabra that sprouted spider-like iron legs, fangs, and 3 purple necrotic candle flames.",
	},
	{
		name = "BloodLeech",
		title = "Crimson Lamprey",
		archetype = "Lifesteal Parasite",
		health = 22,
		speed = 11.0,
		damage = 9,
		experience = 2,
		radius = 1.3,
		size = Vector3.new(2.0, 1.8, 3.8),
		color = Color3.fromRGB(110, 32, 42),
		shape = Enum.PartType.Ball,
		description = "Segmented bloated crimson parasite with a circular radial ring of needle fangs and glowing blood gorge.",
	},
	{
		name = "SkeletalArcher",
		title = "Bone Marksman",
		archetype = "Ranged Sniper",
		health = 14,
		speed = 8.5,
		damage = 10,
		experience = 2,
		radius = 1.4,
		size = Vector3.new(2.4, 3.8, 2.2),
		color = Color3.fromRGB(226, 218, 195),
		shape = Enum.PartType.Block,
		description = "Bleached skeleton clutching a composite bone longbow with a quiver of sharpened ribs over its shoulder.",
	},
	{
		name = "TormentMaiden",
		title = "Torture Automaton",
		archetype = "Armored Battering",
		health = 65,
		speed = 6.0,
		damage = 20,
		experience = 6,
		radius = 2.4,
		size = Vector3.new(3.4, 5.2, 2.8),
		color = Color3.fromRGB(48, 42, 40),
		shape = Enum.PartType.Block,
		description = "Walking rusted iron maiden sarcophagus with half-open spiked doors revealing an inner burning orange furnace.",
	},
	{
		name = "FleshHound",
		title = "Twin-Headed Flayed Beast",
		archetype = "Dual-Bite Leaper",
		health = 26,
		speed = 14.0,
		damage = 11,
		experience = 3,
		radius = 1.7,
		size = Vector3.new(2.8, 2.6, 4.4),
		color = Color3.fromRGB(135, 45, 52),
		shape = Enum.PartType.Block,
		description = "Quadruped muscular flayed beast of exposed sinew with twin snapping fanged heads and spiked iron collar.",
	},
	{
		name = "BansheeShrieker",
		title = "Screaming Poltergeist",
		archetype = "AoE Screamer",
		health = 18,
		speed = 12.5,
		damage = 10,
		experience = 3,
		radius = 1.5,
		size = Vector3.new(2.6, 3.6, 2.4),
		color = Color3.fromRGB(160, 205, 215),
		shape = Enum.PartType.Block,
		description = "Floating ghostly maiden with wild streaming spectral hair and wide agape maw radiating glowing teal shrieks.",
	},
	{
		name = "GraveMound",
		title = "Charnel Earth Elemental",
		archetype = "Heavy Earth Juggernaut",
		health = 48,
		speed = 6.5,
		damage = 14,
		experience = 4,
		radius = 2.5,
		size = Vector3.new(4.8, 2.8, 4.8),
		color = Color3.fromRGB(56, 46, 38),
		shape = Enum.PartType.Block,
		description = "Living pile of graveyard dirt, embedded broken wooden cross, tomb fragments, and reaching skeletal arms.",
	},
	{
		name = "HollowArmor",
		title = "Possessed Sentry",
		archetype = "Shielded Guardian",
		health = 36,
		speed = 8.0,
		damage = 12,
		experience = 3,
		radius = 1.8,
		size = Vector3.new(3.0, 4.4, 2.2),
		color = Color3.fromRGB(70, 75, 84),
		shape = Enum.PartType.Block,
		description = "Empty plate harness with floating winged helm, tower shield, and broadsword with cyan soul light inside.",
	},
	{
		name = "LichLord",
		title = "Crypt Sovereign",
		archetype = "Arch-Sorcerer Boss",
		health = 150,
		speed = 6.5,
		damage = 25,
		experience = 12,
		radius = 3.2,
		size = Vector3.new(4.0, 6.0, 3.4),
		color = Color3.fromRGB(38, 22, 52),
		shape = Enum.PartType.Block,
		description = "Floating sovereign necromancer with jagged obsidian crown, velvet mantle, ribcage phylactery, and soul crystal.",
	},
} :: { EnemyCandidateDef }

-- Palette
local BONE_PALE = Color3.fromRGB(226, 218, 195)
local BONE_DARK = Color3.fromRGB(195, 185, 165)
local SHROUD_BLACK = Color3.fromRGB(24, 26, 32)
local SHROUD_MID = Color3.fromRGB(40, 44, 52)
local GHOUL_FLESH = Color3.fromRGB(120, 115, 105)
local GHOUL_CLAW = Color3.fromRGB(38, 34, 36)
local RAVEN_DARK = Color3.fromRGB(26, 26, 32)
local RAVEN_FEATHER = Color3.fromRGB(38, 40, 48)
local IRON_DARK = Color3.fromRGB(36, 38, 42)
local IRON_RUST = Color3.fromRGB(52, 44, 40)
local STONE_SLATE = Color3.fromRGB(72, 76, 82)
local STONE_COBBLE = Color3.fromRGB(60, 64, 70)
local CULTIST_ROBE = Color3.fromRGB(42, 28, 56)
local CULTIST_WOOD = Color3.fromRGB(62, 46, 34)
local WORM_FLESH = Color3.fromRGB(85, 68, 78)
local SHADE_VOID = Color3.fromRGB(12, 12, 16)
local TITAN_FLESH = Color3.fromRGB(78, 72, 68)

-- New Wave 2 Palette
local MUMMY_WRAP = Color3.fromRGB(135, 125, 110)
local BRONZE_CORRODED = Color3.fromRGB(148, 118, 62)
local RAT_FUR = Color3.fromRGB(46, 40, 44)
local RAT_SNOUT = Color3.fromRGB(72, 58, 62)
local REAPER_BLACK = Color3.fromRGB(18, 18, 22)
local BLOOD_DARK = Color3.fromRGB(115, 30, 40)
local BLOOD_FLESH = Color3.fromRGB(138, 42, 52)
local TORMENT_IRON = Color3.fromRGB(46, 42, 40)
local BANSHEE_GHOST = Color3.fromRGB(180, 220, 228)
local EARTH_DIRT = Color3.fromRGB(56, 46, 38)
local ARMOR_STEEL = Color3.fromRGB(72, 76, 84)
local LICH_PURPLE = Color3.fromRGB(36, 20, 50)
local LICH_MANTLE = Color3.fromRGB(64, 28, 85)

-- Glowing accents
local NEON_SOUL_CYAN = Color3.fromRGB(52, 215, 185)
local NEON_AMBER = Color3.fromRGB(255, 185, 45)
local NEON_TOXIC_GREEN = Color3.fromRGB(90, 240, 65)
local NEON_BLOOD_RED = Color3.fromRGB(255, 35, 35)
local NEON_VOID_PURPLE = Color3.fromRGB(175, 55, 255)
local NEON_SHADOW_WHITE = Color3.fromRGB(250, 250, 255)
local NEON_MOLTEN_ORANGE = Color3.fromRGB(255, 125, 25)
local NEON_ICE_BLUE = Color3.fromRGB(75, 225, 255)
local NEON_TOXIC_YELLOW = Color3.fromRGB(215, 240, 45)

type PartProps = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	shape: Enum.PartType?,
	meshType: Enum.MeshType?,
	transparency: number?,
	castShadow: boolean?,
	storeAssetId: number?,
	keepStoreTexture: boolean?,
}

type PendingUpgrade = {
	placeholder: BasePart,
	props: PartProps,
	assetId: number,
}

local pendingMeshUpgrades: { PendingUpgrade } = {}
local storeMeshCache: { [number]: MeshPart } = {}

-- Direct FileMesh fallbacks so 3D Creator Store & Roblox meshes render immediately in live published servers
-- even when InsertService:LoadAsset is restricted for third-party model containers.
local STORE_FILE_MESHES: { [number]: { meshId: string, textureId: string?, scale: Vector3? } } = {
	[101559657970017] = {
		meshId = "rbxassetid://97885475",
		textureId = "rbxassetid://97885499",
		scale = Vector3.new(1.35, 1.35, 1.35),
	},
	[524541876] = {
		meshId = "rbxassetid://524541858",
		textureId = "rbxassetid://524541866",
		scale = Vector3.new(0.045, 0.045, 0.045),
	},
	[867643066] = {
		meshId = "rbxassetid://867643049",
		textureId = "rbxassetid://867643060",
		scale = Vector3.new(0.045, 0.045, 0.045),
	},
	[591079857] = {
		meshId = "rbxassetid://591079842",
		textureId = "rbxassetid://591079849",
		scale = Vector3.new(0.045, 0.045, 0.045),
	},
	[8260717445] = {
		meshId = "rbxassetid://8260717364",
		textureId = "rbxassetid://8260717404",
		scale = Vector3.new(0.35, 0.35, 0.35),
	},
	[109820689568362] = {
		meshId = "rbxassetid://120062356602177",
		scale = Vector3.new(0.45, 0.45, 0.45),
	},
}

local function inferStoreAssetId(name: string): number?
	local assets = EnemyCandidates.CREATOR_STORE_ASSETS
	if name == "SkullCranium" or name == "TrappedSkull" then
		return assets.SkullOfAinz
	elseif name == "RibArch2" then
		return assets.SkeletonRibcage
	elseif name == "Weapon_Runesword" or name == "Blade" or name == "Broadsword" then
		return assets.GothicSword
	elseif name == "DragonSkull" then
		return assets.DragonHead
	elseif name == "HornLeft" or name == "HornRight" or name == "FrostHornL" or name == "FrostHornR" then
		return assets.DemonHorns
	elseif name == "RunicCoreCrystal" or name == "CrystalSpikeL" or name == "CrystalSpikeR" then
		return assets.QuartzCluster
	elseif name == "SlimeOuterBody" then
		return assets.SlimeModel
	elseif name == "ScytheBlade" then
		return assets.PolyhexScythe
	elseif name == "WingLeft_Inner" or name == "WingRight_Inner" then
		return assets.BatWings
	end
	return nil
end

local function applyMeshPartProps(meshPart: MeshPart, props: PartProps)
	meshPart.Name = props.name
	meshPart.Size = props.size
	meshPart.CFrame = props.cframe
	meshPart.Color = props.color
	meshPart.Material = props.material
	meshPart.Anchored = true
	meshPart.CanCollide = false
	meshPart.CanTouch = false
	meshPart.CanQuery = false
	meshPart.Transparency = props.transparency or 0
	meshPart.CastShadow = if props.castShadow ~= nil then props.castShadow else true
	if not props.keepStoreTexture then
		meshPart.TextureID = ""
	end
end

local function inferMeshType(name: string, shape: Enum.PartType?): Enum.MeshType?
	if name == "PivotRoot" or string.find(name, "Pedestal") or string.find(name, "RuneRing") then
		return nil
	end
	if shape == Enum.PartType.Cylinder or string.find(name, "Puddle") or string.find(name, "Ring") then
		return Enum.MeshType.Cylinder
	end
	if
		shape == Enum.PartType.Ball
		or string.find(name, "Skull")
		or string.find(name, "Head")
		or string.find(name, "Cranium")
		or string.find(name, "Eye")
		or string.find(name, "Orb")
		or string.find(name, "Core")
		or string.find(name, "Heart")
		or string.find(name, "Nucleus")
		or string.find(name, "Bubble")
		or string.find(name, "Abdomen")
		or string.find(name, "Carapace")
		or string.find(name, "Shell")
		or string.find(name, "Thorax")
		or string.find(name, "Pauldron")
		or string.find(name, "Shoulder")
		or string.find(name, "Cowl")
		or string.find(name, "Hood")
		or string.find(name, "Slime")
		or string.find(name, "Mound")
		or string.find(name, "Gorge")
		or string.find(name, "Body")
		or string.find(name, "Segment")
		or string.find(name, "Ember")
	then
		return Enum.MeshType.Sphere
	end
	if
		shape == Enum.PartType.Wedge
		or string.find(name, "Horn")
		or string.find(name, "Spike")
		or string.find(name, "Claw")
		or string.find(name, "Talon")
		or string.find(name, "Fang")
		or string.find(name, "Tooth")
		or string.find(name, "Beak")
		or string.find(name, "Mandible")
		or string.find(name, "Blade")
		or string.find(name, "Scythe")
		or string.find(name, "Ear")
		or string.find(name, "Crown")
		or string.find(name, "Shard")
		or string.find(name, "Flame")
	then
		return Enum.MeshType.Sphere
	end
	if
		string.find(name, "Torso")
		or string.find(name, "Chest")
		or string.find(name, "Cuirass")
		or string.find(name, "Robe")
		or string.find(name, "Shroud")
		or string.find(name, "Mantle")
	then
		return Enum.MeshType.Torso
	end
	return Enum.MeshType.Head
end

local function makePart(props: PartProps): BasePart
	local assetId = props.storeAssetId or inferStoreAssetId(props.name)
	if assetId and storeMeshCache[assetId] then
		local cloned = storeMeshCache[assetId]:Clone()
		applyMeshPartProps(cloned, props)
		cloned.Parent = props.parent
		return cloned
	end

	local part = Instance.new("Part")
	part.Name = props.name
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material
	part.Shape = Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = props.transparency or 0
	part.CastShadow = if props.castShadow ~= nil then props.castShadow else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	local fileMeshInfo = if assetId then STORE_FILE_MESHES[assetId] else nil
	if fileMeshInfo then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = fileMeshInfo.meshId
		if fileMeshInfo.textureId and props.keepStoreTexture then
			mesh.TextureId = fileMeshInfo.textureId
		end
		if fileMeshInfo.scale then
			mesh.Scale = fileMeshInfo.scale
		end
		mesh.Parent = part
	else
		local resolvedMesh = props.meshType or inferMeshType(props.name, props.shape)
		if resolvedMesh then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = resolvedMesh
			if resolvedMesh == Enum.MeshType.Head then
				mesh.Scale = Vector3.new(1.22, 1.22, 1.22)
			end
			mesh.Parent = part
		end
	end

	part.Parent = props.parent
	if assetId then
		table.insert(pendingMeshUpgrades, {
			placeholder = part,
			props = props,
			assetId = assetId,
		})
	end
	return part
end

local function addSoulLight(parent: Instance, color: Color3, brightness: number?, range: number?)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.4
	light.Range = range or 10
	light.Shadows = false
	light.Parent = parent
end

local function addAuraParticles(parent: Instance, c0: Color3, c1: Color3, rate: number?, sizeScale: number?)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(c0, c1)
	emitter.LightEmission = 0.85
	emitter.LightInfluence = 0.15
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, (sizeScale or 0.35) * 0.5),
		NumberSequenceKeypoint.new(0.5, sizeScale or 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.8, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.45, 0.85)
	emitter.Rate = rate or 10
	emitter.Speed = NumberRange.new(1.2, 2.8)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Parent = parent
end

local function createPivot(model: Model): BasePart
	local root = makePart({
		name = "PivotRoot",
		size = Vector3.new(1, 0.05, 1),
		cframe = CFrame.new(0, 0, 0),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
		transparency = 1,
		castShadow = false,
	})
	model.PrimaryPart = root
	model.WorldPivot = CFrame.new(0, 0, 0)
	return root
end

-- =====================================================================
-- Wave 1 Builders (1-12)
-- =====================================================================

function EnemyCandidates.buildWraith(): Model
	local model = Instance.new("Model")
	model.Name = "Wraith"
	createPivot(model)
	makePart({
		name = "CowlHood",
		size = Vector3.new(1.4, 1.4, 1.4),
		cframe = CFrame.new(0, 2.7, 0),
		color = SHROUD_BLACK,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "ShroudTorso",
		size = Vector3.new(1.6, 2.0, 1.2),
		cframe = CFrame.new(0, 1.3, 0),
		color = SHROUD_MID,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "SoulCore",
		size = Vector3.new(0.6, 0.8, 0.5),
		cframe = CFrame.new(0, 1.4, -0.2),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.2, 0.15, 0.2),
		cframe = CFrame.new(-0.3, 2.75, -0.65),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.2, 0.15, 0.2),
		cframe = CFrame.new(0.3, 2.75, -0.65),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "ClawLeft",
		size = Vector3.new(0.22, 0.22, 1.1),
		cframe = CFrame.new(-0.95, 1.6, -0.6) * CFrame.Angles(0.2, 0.1, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ClawRight",
		size = Vector3.new(0.22, 0.22, 1.1),
		cframe = CFrame.new(0.95, 1.6, -0.6) * CFrame.Angles(0.2, -0.1, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildCryptGhoul(): Model
	local model = Instance.new("Model")
	model.Name = "CryptGhoul"
	createPivot(model)
	makePart({
		name = "HunchedSpine",
		size = Vector3.new(1.3, 1.6, 2.0),
		cframe = CFrame.new(0, 1.6, 0.2) * CFrame.Angles(-0.35, 0, 0),
		color = GHOUL_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EmaciatedTorso",
		size = Vector3.new(1.4, 1.2, 1.5),
		cframe = CFrame.new(0, 1.3, -0.1),
		color = GHOUL_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "FeralHead",
		size = Vector3.new(1.1, 1.0, 1.2),
		cframe = CFrame.new(0, 1.8, -1.0),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LowerJaw",
		size = Vector3.new(0.8, 0.35, 0.8),
		cframe = CFrame.new(0, 1.35, -1.2),
		color = GHOUL_CLAW,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.18, 0.18, 0.18),
		cframe = CFrame.new(-0.32, 1.9, -1.5),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.18, 0.18, 0.18),
		cframe = CFrame.new(0.32, 1.9, -1.5),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "ForelegLeft",
		size = Vector3.new(0.35, 1.4, 0.35),
		cframe = CFrame.new(-0.85, 0.7, -0.6) * CFrame.Angles(0.25, 0, 0),
		color = GHOUL_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ForelegRight",
		size = Vector3.new(0.35, 1.4, 0.35),
		cframe = CFrame.new(0.85, 0.7, -0.6) * CFrame.Angles(0.25, 0, 0),
		color = GHOUL_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ClawsLeft",
		size = Vector3.new(0.4, 0.15, 0.6),
		cframe = CFrame.new(-0.85, 0.1, -0.85),
		color = GHOUL_CLAW,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "ClawsRight",
		size = Vector3.new(0.4, 0.15, 0.6),
		cframe = CFrame.new(0.85, 0.1, -0.85),
		color = GHOUL_CLAW,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildPlagueCrow(): Model
	local model = Instance.new("Model")
	model.Name = "PlagueCrow"
	createPivot(model)
	makePart({
		name = "BodyCore",
		size = Vector3.new(1.1, 0.9, 1.8),
		cframe = CFrame.new(0, 2.4, 0),
		color = RAVEN_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SkullBeak",
		size = Vector3.new(0.55, 0.55, 1.1),
		cframe = CFrame.new(0, 2.5, -1.2) * CFrame.Angles(-0.15, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.14, 0.14, 0.14),
		cframe = CFrame.new(-0.25, 2.6, -1.1),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.14, 0.14, 0.14),
		cframe = CFrame.new(0.25, 2.6, -1.1),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "WingLeft",
		size = Vector3.new(1.8, 0.15, 1.2),
		cframe = CFrame.new(-1.3, 2.5, 0.1) * CFrame.Angles(0, -0.2, 0.15),
		color = RAVEN_FEATHER,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "WingRight",
		size = Vector3.new(1.8, 0.15, 1.2),
		cframe = CFrame.new(1.3, 2.5, 0.1) * CFrame.Angles(0, 0.2, -0.15),
		color = RAVEN_FEATHER,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "TailFeathers",
		size = Vector3.new(0.8, 0.15, 1.0),
		cframe = CFrame.new(0, 2.35, 1.2) * CFrame.Angles(0.2, 0, 0),
		color = RAVEN_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "Talons",
		size = Vector3.new(0.7, 0.5, 0.5),
		cframe = CFrame.new(0, 1.8, 0.1),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildBoneHound(): Model
	local model = Instance.new("Model")
	model.Name = "BoneHound"
	createPivot(model)
	makePart({
		name = "HoundSpine",
		size = Vector3.new(0.8, 0.8, 2.6),
		cframe = CFrame.new(0, 1.6, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ThoraxRibs",
		size = Vector3.new(1.4, 1.2, 1.4),
		cframe = CFrame.new(0, 1.3, -0.4),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "CanineSkull",
		size = Vector3.new(0.9, 0.8, 1.4),
		cframe = CFrame.new(0, 1.7, -1.8) * CFrame.Angles(0.1, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "CanineJaw",
		size = Vector3.new(0.65, 0.3, 1.0),
		cframe = CFrame.new(0, 1.3, -1.9),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.14, 0.14, 0.14),
		cframe = CFrame.new(-0.28, 1.85, -2.1),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.14, 0.14, 0.14),
		cframe = CFrame.new(0.28, 1.85, -2.1),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "ForelegL",
		size = Vector3.new(0.3, 1.4, 0.3),
		cframe = CFrame.new(-0.65, 0.7, -0.9),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ForelegR",
		size = Vector3.new(0.3, 1.4, 0.3),
		cframe = CFrame.new(0.65, 0.7, -0.9),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "HindlegL",
		size = Vector3.new(0.35, 1.4, 0.35),
		cframe = CFrame.new(-0.65, 0.7, 1.0) * CFrame.Angles(-0.2, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "HindlegR",
		size = Vector3.new(0.35, 1.4, 0.35),
		cframe = CFrame.new(0.65, 0.7, 1.0) * CFrame.Angles(-0.2, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BoneTail",
		size = Vector3.new(0.2, 0.2, 1.4),
		cframe = CFrame.new(0, 1.5, 1.9) * CFrame.Angles(-0.3, 0, 0),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildDeathKnight(): Model
	local model = Instance.new("Model")
	model.Name = "DeathKnight"
	createPivot(model)
	makePart({
		name = "IronCuirass",
		size = Vector3.new(2.2, 2.0, 1.4),
		cframe = CFrame.new(0, 2.6, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "PauldronL",
		size = Vector3.new(1.1, 1.1, 1.3),
		cframe = CFrame.new(-1.6, 3.4, 0) * CFrame.Angles(0, 0, 0.3),
		color = IRON_RUST,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "PauldronR",
		size = Vector3.new(1.1, 1.1, 1.3),
		cframe = CFrame.new(1.6, 3.4, 0) * CFrame.Angles(0, 0, -0.3),
		color = IRON_RUST,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "GreatHelm",
		size = Vector3.new(1.2, 1.3, 1.2),
		cframe = CFrame.new(0, 4.2, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "VisorSlit",
		size = Vector3.new(0.8, 0.15, 0.3),
		cframe = CFrame.new(0, 4.15, -0.55),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "HelmHornL",
		size = Vector3.new(0.25, 0.8, 0.25),
		cframe = CFrame.new(-0.7, 4.8, 0) * CFrame.Angles(0, 0, 0.4),
		color = IRON_RUST,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "HelmHornR",
		size = Vector3.new(0.25, 0.8, 0.25),
		cframe = CFrame.new(0.7, 4.8, 0) * CFrame.Angles(0, 0, -0.4),
		color = IRON_RUST,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "GreaveL",
		size = Vector3.new(0.7, 1.6, 0.8),
		cframe = CFrame.new(-0.6, 0.8, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "GreaveR",
		size = Vector3.new(0.7, 1.6, 0.8),
		cframe = CFrame.new(0.6, 0.8, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "GreatswordBlade",
		size = Vector3.new(0.35, 4.2, 0.7),
		cframe = CFrame.new(1.8, 2.5, -0.9) * CFrame.Angles(0.3, 0, 0),
		color = Color3.fromRGB(110, 115, 125),
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "GreatswordCrossguard",
		size = Vector3.new(0.4, 0.3, 1.6),
		cframe = CFrame.new(1.8, 1.2, -0.6) * CFrame.Angles(0.3, 0, 0),
		color = IRON_DARK,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "RunicBladeFuller",
		size = Vector3.new(0.38, 2.8, 0.15),
		cframe = CFrame.new(1.8, 2.6, -0.9) * CFrame.Angles(0.3, 0, 0),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	return model
end

function EnemyCandidates.buildBoneScarab(): Model
	local model = Instance.new("Model")
	model.Name = "BoneScarab"
	createPivot(model)
	makePart({
		name = "Thorax",
		size = Vector3.new(1.6, 0.8, 1.4),
		cframe = CFrame.new(0, 0.7, -0.4),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "CarapaceShell",
		size = Vector3.new(2.2, 1.0, 2.2),
		cframe = CFrame.new(0, 0.9, 0.5),
		color = Color3.fromRGB(42, 38, 48),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BoneDorsalRidge",
		size = Vector3.new(0.35, 0.4, 2.0),
		cframe = CFrame.new(0, 1.5, 0.5),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "MandibleL",
		size = Vector3.new(0.3, 0.25, 0.9),
		cframe = CFrame.new(-0.55, 0.6, -1.4) * CFrame.Angles(0, -0.3, 0),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "MandibleR",
		size = Vector3.new(0.3, 0.25, 0.9),
		cframe = CFrame.new(0.55, 0.6, -1.4) * CFrame.Angles(0, 0.3, 0),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.18, 0.18, 0.18),
		cframe = CFrame.new(-0.45, 0.85, -1.0),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.18, 0.18, 0.18),
		cframe = CFrame.new(0.45, 0.85, -1.0),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "FrontLegL",
		size = Vector3.new(0.9, 0.2, 0.25),
		cframe = CFrame.new(-1.2, 0.3, -0.6) * CFrame.Angles(0, 0, 0.3),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "FrontLegR",
		size = Vector3.new(0.9, 0.2, 0.25),
		cframe = CFrame.new(1.2, 0.3, -0.6) * CFrame.Angles(0, 0, -0.3),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "RearLegL",
		size = Vector3.new(1.1, 0.2, 0.25),
		cframe = CFrame.new(-1.3, 0.3, 0.6) * CFrame.Angles(0, 0, 0.3),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "RearLegR",
		size = Vector3.new(1.1, 0.2, 0.25),
		cframe = CFrame.new(1.3, 0.3, 0.6) * CFrame.Angles(0, 0, -0.3),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildAbyssalWatcher(): Model
	local model = Instance.new("Model")
	model.Name = "AbyssalWatcher"
	createPivot(model)
	makePart({
		name = "EyeGlobe",
		size = Vector3.new(2.2, 2.2, 2.2),
		cframe = CFrame.new(0, 2.4, 0),
		color = Color3.fromRGB(195, 185, 192),
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	makePart({
		name = "IrisRing",
		size = Vector3.new(1.2, 1.2, 0.25),
		cframe = CFrame.new(0, 2.4, -1.05),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "VoidPupil",
		size = Vector3.new(0.25, 0.8, 0.3),
		cframe = CFrame.new(0, 2.4, -1.1),
		color = SHROUD_BLACK,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "EyelidTop",
		size = Vector3.new(1.8, 0.3, 0.8),
		cframe = CFrame.new(0, 3.2, -0.6) * CFrame.Angles(-0.25, 0, 0),
		color = Color3.fromRGB(120, 55, 150),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyelidBottom",
		size = Vector3.new(1.8, 0.3, 0.8),
		cframe = CFrame.new(0, 1.6, -0.6) * CFrame.Angles(0.25, 0, 0),
		color = Color3.fromRGB(120, 55, 150),
		material = Enum.Material.Slate,
		parent = model,
	})
	for i = 1, 4 do
		local angle = (i - 1) * (math.pi * 0.5) + math.pi * 0.25
		local tx = math.cos(angle) * 0.7
		local tz = math.sin(angle) * 0.7
		makePart({
			name = "Tendril_" .. i,
			size = Vector3.new(0.3, 1.6, 0.3),
			cframe = CFrame.new(tx, 1.0, tz) * CFrame.Angles(0.15 * math.cos(angle), 0, 0.15 * math.sin(angle)),
			color = Color3.fromRGB(55, 35, 75),
			material = Enum.Material.Slate,
			parent = model,
		})
	end
	return model
end

function EnemyCandidates.buildNecromancerAcolyte(): Model
	local model = Instance.new("Model")
	model.Name = "NecromancerAcolyte"
	createPivot(model)
	makePart({
		name = "CultistRobe",
		size = Vector3.new(1.6, 2.6, 1.6),
		cframe = CFrame.new(0, 1.3, 0),
		color = CULTIST_ROBE,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "ShoulderCowl",
		size = Vector3.new(2.1, 0.8, 1.8),
		cframe = CFrame.new(0, 2.7, 0),
		color = SHROUD_BLACK,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "SkullMask",
		size = Vector3.new(1.1, 1.2, 0.8),
		cframe = CFrame.new(0, 3.4, -0.45),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.18, 0.18, 0.2),
		cframe = CFrame.new(-0.25, 3.45, -0.85),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.18, 0.18, 0.2),
		cframe = CFrame.new(0.25, 3.45, -0.85),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "AntlerL",
		size = Vector3.new(0.2, 1.4, 0.2),
		cframe = CFrame.new(-0.65, 4.3, -0.2) * CFrame.Angles(0, 0, 0.4),
		color = CULTIST_WOOD,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "AntlerR",
		size = Vector3.new(0.2, 1.4, 0.2),
		cframe = CFrame.new(0.65, 4.3, -0.2) * CFrame.Angles(0, 0, -0.4),
		color = CULTIST_WOOD,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "StaffShaft",
		size = Vector3.new(0.25, 4.4, 0.25),
		cframe = CFrame.new(1.2, 2.2, -0.5),
		color = CULTIST_WOOD,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "StaffSkullHead",
		size = Vector3.new(0.65, 0.7, 0.7),
		cframe = CFrame.new(1.2, 4.4, -0.5),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "StaffSoulFlame",
		size = Vector3.new(0.45, 0.6, 0.45),
		cframe = CFrame.new(1.2, 4.9, -0.5),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	return model
end

function EnemyCandidates.buildCursedGargoyle(): Model
	local model = Instance.new("Model")
	model.Name = "CursedGargoyle"
	createPivot(model)
	makePart({
		name = "StoneTorso",
		size = Vector3.new(2.2, 2.2, 1.6),
		cframe = CFrame.new(0, 2.1, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "GrotesqueHead",
		size = Vector3.new(1.3, 1.2, 1.4),
		cframe = CFrame.new(0, 3.4, -0.4),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.2, 0.16, 0.2),
		cframe = CFrame.new(-0.35, 3.45, -1.05),
		color = NEON_MOLTEN_ORANGE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.2, 0.16, 0.2),
		cframe = CFrame.new(0.35, 3.45, -1.05),
		color = NEON_MOLTEN_ORANGE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "StoneHornL",
		size = Vector3.new(0.3, 0.9, 0.3),
		cframe = CFrame.new(-0.6, 4.1, -0.2) * CFrame.Angles(-0.2, 0, 0.35),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "StoneHornR",
		size = Vector3.new(0.3, 0.9, 0.3),
		cframe = CFrame.new(0.6, 4.1, -0.2) * CFrame.Angles(-0.2, 0, -0.35),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "WingL",
		size = Vector3.new(2.4, 1.8, 0.25),
		cframe = CFrame.new(-1.8, 2.7, 0.6) * CFrame.Angles(0, 0.4, 0.2),
		color = STONE_COBBLE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "WingR",
		size = Vector3.new(2.4, 1.8, 0.25),
		cframe = CFrame.new(1.8, 2.7, 0.6) * CFrame.Angles(0, -0.4, -0.2),
		color = STONE_COBBLE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "TalonedLegL",
		size = Vector3.new(0.7, 1.2, 0.8),
		cframe = CFrame.new(-0.65, 0.6, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "TalonedLegR",
		size = Vector3.new(0.7, 1.2, 0.8),
		cframe = CFrame.new(0.65, 0.6, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "StoneTail",
		size = Vector3.new(0.3, 0.3, 1.8),
		cframe = CFrame.new(0, 1.2, 1.2) * CFrame.Angles(-0.35, 0, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildRotWorm(): Model
	local model = Instance.new("Model")
	model.Name = "RotWorm"
	createPivot(model)
	makePart({
		name = "MawHead",
		size = Vector3.new(1.8, 1.6, 1.6),
		cframe = CFrame.new(0, 0.9, -1.8),
		color = WORM_FLESH,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "BileMouthCore",
		size = Vector3.new(1.0, 1.0, 0.4),
		cframe = CFrame.new(0, 0.9, -2.4),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "NeedleTeethH",
		size = Vector3.new(1.4, 0.2, 0.3),
		cframe = CFrame.new(0, 1.45, -2.4),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "NeedleTeethV",
		size = Vector3.new(0.2, 1.2, 0.3),
		cframe = CFrame.new(0.7, 0.9, -2.4),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BodyMid",
		size = Vector3.new(2.1, 1.8, 1.8),
		cframe = CFrame.new(0, 0.95, -0.4),
		color = WORM_FLESH,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "BodyRear",
		size = Vector3.new(1.7, 1.4, 1.6),
		cframe = CFrame.new(0, 0.8, 1.0),
		color = Color3.fromRGB(75, 60, 70),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "TailTip",
		size = Vector3.new(1.2, 1.0, 1.2),
		cframe = CFrame.new(0, 0.6, 2.2),
		color = Color3.fromRGB(65, 52, 60),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "DorsalSpines1",
		size = Vector3.new(0.3, 0.7, 1.2),
		cframe = CFrame.new(0, 1.8, -0.4),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildShadowStalker(): Model
	local model = Instance.new("Model")
	model.Name = "ShadowStalker"
	createPivot(model)
	makePart({
		name = "UmbralTorso",
		size = Vector3.new(1.5, 2.0, 0.8),
		cframe = CFrame.new(0, 2.0, 0),
		color = SHADE_VOID,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ShadeHead",
		size = Vector3.new(1.0, 1.1, 1.0),
		cframe = CFrame.new(0, 3.3, 0),
		color = SHADE_VOID,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.15, 0.15, 0.15),
		cframe = CFrame.new(-0.25, 3.35, -0.52),
		color = NEON_SHADOW_WHITE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.15, 0.15, 0.15),
		cframe = CFrame.new(0.25, 3.35, -0.52),
		color = NEON_SHADOW_WHITE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "BladeClawL",
		size = Vector3.new(0.18, 1.8, 0.4),
		cframe = CFrame.new(-0.95, 1.5, -0.3) * CFrame.Angles(0.2, 0, 0.15),
		color = Color3.fromRGB(22, 22, 28),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "BladeClawR",
		size = Vector3.new(0.18, 1.8, 0.4),
		cframe = CFrame.new(0.95, 1.5, -0.3) * CFrame.Angles(0.2, 0, -0.15),
		color = Color3.fromRGB(22, 22, 28),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "WispTail",
		size = Vector3.new(0.8, 1.2, 0.6),
		cframe = CFrame.new(0, 0.7, 0.3) * CFrame.Angles(0.25, 0, 0),
		color = SHADE_VOID,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildOssuaryBehemoth(): Model
	local model = Instance.new("Model")
	model.Name = "OssuaryBehemoth"
	createPivot(model)
	makePart({
		name = "TitanTorso",
		size = Vector3.new(4.8, 4.0, 3.2),
		cframe = CFrame.new(0, 4.4, 0),
		color = TITAN_FLESH,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "EmbeddedTombstone",
		size = Vector3.new(1.4, 3.4, 1.8),
		cframe = CFrame.new(-2.6, 6.2, 0) * CFrame.Angles(0, 0, 0.25),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "TorsoChains",
		size = Vector3.new(5.0, 0.5, 3.4),
		cframe = CFrame.new(0, 4.8, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "CyclopsHead",
		size = Vector3.new(2.2, 2.0, 2.0),
		cframe = CFrame.new(0.4, 6.5, -0.6),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BalefulEye",
		size = Vector3.new(0.65, 0.65, 0.4),
		cframe = CFrame.new(0.4, 6.5, -1.5),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "BoulderFistL",
		size = Vector3.new(1.8, 3.2, 1.8),
		cframe = CFrame.new(-2.8, 3.0, -0.4),
		color = TITAN_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ArmRight",
		size = Vector3.new(1.8, 3.2, 1.8),
		cframe = CFrame.new(2.8, 3.2, -0.4),
		color = TITAN_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "TombstoneClubShaft",
		size = Vector3.new(0.6, 6.0, 0.6),
		cframe = CFrame.new(3.2, 3.8, -1.8) * CFrame.Angles(0.3, 0, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "TombstoneClubHead",
		size = Vector3.new(2.0, 2.8, 1.2),
		cframe = CFrame.new(3.2, 6.0, -2.5) * CFrame.Angles(0.3, 0, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "PillarLegL",
		size = Vector3.new(1.8, 2.4, 2.0),
		cframe = CFrame.new(-1.4, 1.2, 0),
		color = TITAN_FLESH,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "PillarLegR",
		size = Vector3.new(1.8, 2.4, 2.0),
		cframe = CFrame.new(1.4, 1.2, 0),
		color = TITAN_FLESH,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	return model
end

-- =====================================================================
-- Wave 2 Builders (13-24)
-- =====================================================================

-- 13. BarrowWight (The Entombed King) - 10 parts
function EnemyCandidates.buildBarrowWight(): Model
	local model = Instance.new("Model")
	model.Name = "BarrowWight"
	createPivot(model)
	makePart({
		name = "MummyTorso",
		size = Vector3.new(1.8, 2.2, 1.2),
		cframe = CFrame.new(0, 2.4, 0),
		color = MUMMY_WRAP,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "BurialShroudSkirt",
		size = Vector3.new(2.0, 1.6, 1.4),
		cframe = CFrame.new(0, 0.9, 0),
		color = MUMMY_WRAP,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "WightSkull",
		size = Vector3.new(1.1, 1.2, 1.1),
		cframe = CFrame.new(0, 3.8, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BronzeCirclet",
		size = Vector3.new(1.3, 0.4, 1.3),
		cframe = CFrame.new(0, 4.3, 0),
		color = BRONZE_CORRODED,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.18, 0.16, 0.2),
		cframe = CFrame.new(-0.28, 3.85, -0.58),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.18, 0.16, 0.2),
		cframe = CFrame.new(0.28, 3.85, -0.58),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "SickleArm",
		size = Vector3.new(0.35, 1.8, 0.35),
		cframe = CFrame.new(1.2, 2.4, -0.3) * CFrame.Angles(0.3, 0, 0),
		color = MUMMY_WRAP,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SickleBlade",
		size = Vector3.new(0.2, 2.4, 0.8),
		cframe = CFrame.new(1.3, 2.8, -1.0) * CFrame.Angles(0.4, 0, 0),
		color = Color3.fromRGB(90, 95, 105),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "OffhandClaw",
		size = Vector3.new(0.35, 1.6, 0.35),
		cframe = CFrame.new(-1.1, 2.2, -0.2) * CFrame.Angles(0.2, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

-- 14. CatacombRat (Plague Vermin) - 9 parts
function EnemyCandidates.buildCatacombRat(): Model
	local model = Instance.new("Model")
	model.Name = "CatacombRat"
	createPivot(model)
	makePart({
		name = "RatBody",
		size = Vector3.new(1.3, 1.0, 2.0),
		cframe = CFrame.new(0, 0.7, 0),
		color = RAT_FUR,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "HumpBack",
		size = Vector3.new(1.1, 0.6, 1.4),
		cframe = CFrame.new(0, 1.3, -0.1),
		color = RAT_FUR,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SnoutHead",
		size = Vector3.new(0.9, 0.7, 1.2),
		cframe = CFrame.new(0, 0.75, -1.3),
		color = RAT_SNOUT,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.15, 0.15, 0.15),
		cframe = CFrame.new(-0.35, 0.95, -1.4),
		color = NEON_TOXIC_YELLOW,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.15, 0.15, 0.15),
		cframe = CFrame.new(0.35, 0.95, -1.4),
		color = NEON_TOXIC_YELLOW,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "Incisors",
		size = Vector3.new(0.3, 0.4, 0.2),
		cframe = CFrame.new(0, 0.45, -1.9),
		color = Color3.fromRGB(240, 235, 205),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "Forepaws",
		size = Vector3.new(1.4, 0.4, 0.5),
		cframe = CFrame.new(0, 0.2, -0.7),
		color = RAT_FUR,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "Hindpaws",
		size = Vector3.new(1.5, 0.5, 0.6),
		cframe = CFrame.new(0, 0.25, 0.7),
		color = RAT_FUR,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ScalyTail",
		size = Vector3.new(0.2, 0.2, 1.8),
		cframe = CFrame.new(0, 0.6, 1.8) * CFrame.Angles(-0.25, 0.3, 0),
		color = Color3.fromRGB(115, 88, 92),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	return model
end

-- 15. GraveReaper (Scythe Fiend) - 10 parts
function EnemyCandidates.buildGraveReaper(): Model
	local model = Instance.new("Model")
	model.Name = "GraveReaper"
	createPivot(model)
	makePart({
		name = "ReaperCowl",
		size = Vector3.new(1.5, 1.6, 1.5),
		cframe = CFrame.new(0, 3.6, 0),
		color = REAPER_BLACK,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "VoidFace",
		size = Vector3.new(0.8, 0.9, 0.4),
		cframe = CFrame.new(0, 3.5, -0.6),
		color = Color3.fromRGB(5, 5, 8),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.18, 0.14, 0.2),
		cframe = CFrame.new(-0.25, 3.6, -0.75),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.18, 0.14, 0.2),
		cframe = CFrame.new(0.25, 3.6, -0.75),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "ReaperTorso",
		size = Vector3.new(1.6, 2.2, 1.2),
		cframe = CFrame.new(0, 1.9, 0),
		color = REAPER_BLACK,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "TatteredRobeSkirt",
		size = Vector3.new(2.0, 1.4, 1.5),
		cframe = CFrame.new(0, 0.7, 0.2),
		color = SHROUD_MID,
		material = Enum.Material.Fabric,
		parent = model,
	})
	-- Towering Bone Scythe
	makePart({
		name = "ScytheShaft",
		size = Vector3.new(0.25, 5.4, 0.25),
		cframe = CFrame.new(1.4, 2.7, -0.5),
		color = CULTIST_WOOD,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "ScytheSpineBone",
		size = Vector3.new(0.35, 0.8, 1.8),
		cframe = CFrame.new(1.4, 5.2, -1.2) * CFrame.Angles(-0.2, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ScytheCrescentBlade",
		size = Vector3.new(0.15, 2.4, 1.0),
		cframe = CFrame.new(1.4, 4.4, -1.8) * CFrame.Angles(0.3, 0, 0),
		color = Color3.fromRGB(115, 120, 130),
		material = Enum.Material.Metal,
		parent = model,
	})
	return model
end

-- 16. CandelabraMimic (Possessed Reliquary) - 11 parts
function EnemyCandidates.buildCandelabraMimic(): Model
	local model = Instance.new("Model")
	model.Name = "CandelabraMimic"
	createPivot(model)
	makePart({
		name = "IronStemBody",
		size = Vector3.new(0.9, 1.8, 0.9),
		cframe = CFrame.new(0, 1.7, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "FangedMaw",
		size = Vector3.new(1.1, 0.6, 1.1),
		cframe = CFrame.new(0, 1.4, -0.2),
		color = Color3.fromRGB(48, 42, 46),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "MawTeeth",
		size = Vector3.new(0.9, 0.25, 0.3),
		cframe = CFrame.new(0, 1.4, -0.65),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- 4 Spurred Iron Legs
	makePart({
		name = "LegFL",
		size = Vector3.new(0.2, 1.2, 0.2),
		cframe = CFrame.new(-0.7, 0.6, -0.7) * CFrame.Angles(0.3, 0, 0.3),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "LegFR",
		size = Vector3.new(0.2, 1.2, 0.2),
		cframe = CFrame.new(0.7, 0.6, -0.7) * CFrame.Angles(0.3, 0, -0.3),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "LegBL",
		size = Vector3.new(0.2, 1.2, 0.2),
		cframe = CFrame.new(-0.7, 0.6, 0.7) * CFrame.Angles(-0.3, 0, 0.3),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "LegBR",
		size = Vector3.new(0.2, 1.2, 0.2),
		cframe = CFrame.new(0.7, 0.6, 0.7) * CFrame.Angles(-0.3, 0, -0.3),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	-- 3 Branching Candles with Purple Flames
	for idx, ox in ipairs({ -0.8, 0, 0.8 }) do
		makePart({
			name = "Candle_" .. idx,
			size = Vector3.new(0.28, 0.8, 0.28),
			cframe = CFrame.new(ox, 2.8, 0),
			color = Color3.fromRGB(235, 225, 205),
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		makePart({
			name = "Flame_" .. idx,
			size = Vector3.new(0.35, 0.45, 0.35),
			cframe = CFrame.new(ox, 3.35, 0),
			color = NEON_VOID_PURPLE,
			material = Enum.Material.Neon,
			parent = model,
			castShadow = false,
		})
	end
	return model
end

-- 17. BloodLeech (Crimson Lamprey) - 8 parts
function EnemyCandidates.buildBloodLeech(): Model
	local model = Instance.new("Model")
	model.Name = "BloodLeech"
	createPivot(model)
	makePart({
		name = "MawFunnel",
		size = Vector3.new(1.6, 1.6, 1.2),
		cframe = CFrame.new(0, 0.9, -1.4),
		color = BLOOD_DARK,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "RadialTeeth",
		size = Vector3.new(1.2, 1.2, 0.2),
		cframe = CFrame.new(0, 0.9, -1.95),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BloodGorgeCore",
		size = Vector3.new(0.8, 0.8, 0.3),
		cframe = CFrame.new(0, 0.9, -1.9),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "BodyMid",
		size = Vector3.new(1.8, 1.5, 1.6),
		cframe = CFrame.new(0, 0.85, -0.2),
		color = BLOOD_FLESH,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "BodyRear",
		size = Vector3.new(1.5, 1.3, 1.5),
		cframe = CFrame.new(0, 0.75, 1.1),
		color = BLOOD_DARK,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "TaperTail",
		size = Vector3.new(1.0, 0.9, 1.2),
		cframe = CFrame.new(0, 0.55, 2.2),
		color = BLOOD_DARK,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "DorsalFinRidge",
		size = Vector3.new(0.25, 0.6, 2.2),
		cframe = CFrame.new(0, 1.7, 0.2),
		color = Color3.fromRGB(65, 20, 30),
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

-- 18. SkeletalArcher (Bone Marksman) - 11 parts
function EnemyCandidates.buildSkeletalArcher(): Model
	local model = Instance.new("Model")
	model.Name = "SkeletalArcher"
	createPivot(model)
	makePart({
		name = "Skull",
		size = Vector3.new(0.9, 1.0, 0.9),
		cframe = CFrame.new(0, 3.3, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.14, 0.14, 0.15),
		cframe = CFrame.new(-0.25, 3.35, -0.45),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.14, 0.14, 0.15),
		cframe = CFrame.new(0.25, 3.35, -0.45),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "RibcageTorso",
		size = Vector3.new(1.4, 1.4, 0.9),
		cframe = CFrame.new(0, 2.1, 0),
		color = BONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SpinePelvis",
		size = Vector3.new(0.8, 0.8, 0.7),
		cframe = CFrame.new(0, 1.2, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegL",
		size = Vector3.new(0.3, 1.2, 0.3),
		cframe = CFrame.new(-0.4, 0.6, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegR",
		size = Vector3.new(0.3, 1.2, 0.3),
		cframe = CFrame.new(0.4, 0.6, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BowArm",
		size = Vector3.new(0.25, 1.5, 0.25),
		cframe = CFrame.new(-0.85, 2.1, -0.5) * CFrame.Angles(0.3, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BoneBowCurve",
		size = Vector3.new(0.2, 3.2, 0.5),
		cframe = CFrame.new(-0.95, 2.2, -1.2),
		color = Color3.fromRGB(180, 170, 145),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "RibQuiver",
		size = Vector3.new(0.6, 1.8, 0.6),
		cframe = CFrame.new(0.5, 2.2, 0.55) * CFrame.Angles(0, 0, 0.3),
		color = Color3.fromRGB(70, 52, 42),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	return model
end

-- 19. TormentMaiden (Torture Automaton) - 11 parts
function EnemyCandidates.buildTormentMaiden(): Model
	local model = Instance.new("Model")
	model.Name = "TormentMaiden"
	createPivot(model)
	makePart({
		name = "IronCabinetTorso",
		size = Vector3.new(2.6, 3.4, 2.0),
		cframe = CFrame.new(0, 3.0, 0),
		color = TORMENT_IRON,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "MaidenFaceMask",
		size = Vector3.new(1.3, 1.4, 0.5),
		cframe = CFrame.new(0, 4.2, -1.0),
		color = Color3.fromRGB(60, 54, 50),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "FurnaceCore",
		size = Vector3.new(1.6, 2.2, 0.4),
		cframe = CFrame.new(0, 2.6, -0.9),
		color = NEON_MOLTEN_ORANGE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "DoorL_Spikes",
		size = Vector3.new(0.35, 2.6, 1.2),
		cframe = CFrame.new(-1.25, 2.6, -1.2) * CFrame.Angles(0, 0.4, 0),
		color = TORMENT_IRON,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "DoorR_Spikes",
		size = Vector3.new(0.35, 2.6, 1.2),
		cframe = CFrame.new(1.25, 2.6, -1.2) * CFrame.Angles(0, -0.4, 0),
		color = TORMENT_IRON,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "StiltLegL",
		size = Vector3.new(0.6, 1.4, 0.6),
		cframe = CFrame.new(-0.8, 0.7, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "StiltLegR",
		size = Vector3.new(0.6, 1.4, 0.6),
		cframe = CFrame.new(0.8, 0.7, 0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "CrownFinials",
		size = Vector3.new(2.8, 0.5, 2.2),
		cframe = CFrame.new(0, 4.9, 0),
		color = Color3.fromRGB(58, 52, 48),
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	return model
end

-- 20. FleshHound (Twin-Headed Flayed Beast) - 12 parts
function EnemyCandidates.buildFleshHound(): Model
	local model = Instance.new("Model")
	model.Name = "FleshHound"
	createPivot(model)
	makePart({
		name = "FlayedTorso",
		size = Vector3.new(1.8, 1.5, 2.8),
		cframe = CFrame.new(0, 1.6, 0),
		color = BLOOD_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SpikedCollar",
		size = Vector3.new(2.4, 0.6, 0.8),
		cframe = CFrame.new(0, 2.0, -1.2),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	-- Twin Snapping Heads
	makePart({
		name = "HeadL",
		size = Vector3.new(0.9, 0.9, 1.3),
		cframe = CFrame.new(-0.7, 2.1, -1.8) * CFrame.Angles(0, 0.15, 0),
		color = BLOOD_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "HeadR",
		size = Vector3.new(0.9, 0.9, 1.3),
		cframe = CFrame.new(0.7, 2.1, -1.8) * CFrame.Angles(0, -0.15, 0),
		color = BLOOD_FLESH,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.15, 0.15, 0.15),
		cframe = CFrame.new(-0.85, 2.3, -2.2),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.15, 0.15, 0.15),
		cframe = CFrame.new(0.85, 2.3, -2.2),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "LegFL",
		size = Vector3.new(0.4, 1.2, 0.4),
		cframe = CFrame.new(-0.8, 0.6, -0.9),
		color = BLOOD_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegFR",
		size = Vector3.new(0.4, 1.2, 0.4),
		cframe = CFrame.new(0.8, 0.6, -0.9),
		color = BLOOD_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegBL",
		size = Vector3.new(0.45, 1.2, 0.45),
		cframe = CFrame.new(-0.8, 0.6, 1.0) * CFrame.Angles(-0.2, 0, 0),
		color = BLOOD_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegBR",
		size = Vector3.new(0.45, 1.2, 0.45),
		cframe = CFrame.new(0.8, 0.6, 1.0) * CFrame.Angles(-0.2, 0, 0),
		color = BLOOD_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SpineTail",
		size = Vector3.new(0.25, 0.25, 1.2),
		cframe = CFrame.new(0, 1.6, 1.8) * CFrame.Angles(-0.3, 0, 0),
		color = BLOOD_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

-- 21. BansheeShrieker (Screaming Poltergeist) - 9 parts
function EnemyCandidates.buildBansheeShrieker(): Model
	local model = Instance.new("Model")
	model.Name = "BansheeShrieker"
	createPivot(model)
	makePart({
		name = "SpecterHead",
		size = Vector3.new(1.1, 1.2, 1.1),
		cframe = CFrame.new(0, 2.8, 0),
		color = BANSHEE_GHOST,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "ShriekingMaw",
		size = Vector3.new(0.65, 0.65, 0.3),
		cframe = CFrame.new(0, 2.65, -0.55),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "WildHairL",
		size = Vector3.new(0.5, 2.0, 1.2),
		cframe = CFrame.new(-0.8, 2.7, 0.4) * CFrame.Angles(0.2, 0, 0.3),
		color = Color3.fromRGB(45, 75, 90),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "WildHairR",
		size = Vector3.new(0.5, 2.0, 1.2),
		cframe = CFrame.new(0.8, 2.7, 0.4) * CFrame.Angles(0.2, 0, -0.3),
		color = Color3.fromRGB(45, 75, 90),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "GhostTorso",
		size = Vector3.new(1.4, 1.8, 1.0),
		cframe = CFrame.new(0, 1.5, 0),
		color = Color3.fromRGB(150, 190, 200),
		material = Enum.Material.Fabric,
		transparency = 0.2,
		parent = model,
	})
	makePart({
		name = "TrailingShroud",
		size = Vector3.new(1.8, 1.2, 1.4),
		cframe = CFrame.new(0, 0.6, 0.2),
		color = Color3.fromRGB(120, 160, 175),
		material = Enum.Material.Fabric,
		transparency = 0.35,
		parent = model,
	})
	makePart({
		name = "ClawedHandL",
		size = Vector3.new(0.2, 1.2, 0.2),
		cframe = CFrame.new(-0.95, 1.8, -0.6) * CFrame.Angles(0.4, 0, 0),
		color = BANSHEE_GHOST,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	makePart({
		name = "ClawedHandR",
		size = Vector3.new(0.2, 1.2, 0.2),
		cframe = CFrame.new(0.95, 1.8, -0.6) * CFrame.Angles(0.4, 0, 0),
		color = BANSHEE_GHOST,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	return model
end

-- 22. GraveMound (Charnel Earth Elemental) - 11 parts
function EnemyCandidates.buildGraveMound(): Model
	local model = Instance.new("Model")
	model.Name = "GraveMound"
	createPivot(model)
	makePart({
		name = "DirtMoundDome",
		size = Vector3.new(3.8, 1.8, 3.8),
		cframe = CFrame.new(0, 0.9, 0),
		color = EARTH_DIRT,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "LoamRidge",
		size = Vector3.new(2.8, 1.0, 2.8),
		cframe = CFrame.new(0, 1.8, 0),
		color = Color3.fromRGB(44, 36, 30),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "BrokenCrossShaft",
		size = Vector3.new(0.35, 2.2, 0.35),
		cframe = CFrame.new(0.3, 2.8, -0.2) * CFrame.Angles(0.15, 0, -0.2),
		color = Color3.fromRGB(72, 54, 40),
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "BrokenCrossArm",
		size = Vector3.new(1.2, 0.35, 0.35),
		cframe = CFrame.new(0.3, 3.3, -0.2) * CFrame.Angles(0.15, 0, -0.2),
		color = Color3.fromRGB(72, 54, 40),
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "TombstoneShard",
		size = Vector3.new(1.2, 1.6, 0.4),
		cframe = CFrame.new(-1.1, 1.6, 0.8) * CFrame.Angles(0.2, 0.3, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SkeletalArm1",
		size = Vector3.new(0.22, 1.4, 0.22),
		cframe = CFrame.new(1.4, 1.2, 0.8) * CFrame.Angles(0.3, 0, 0.3),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SkeletalArm2",
		size = Vector3.new(0.22, 1.4, 0.22),
		cframe = CFrame.new(-1.4, 1.2, -0.8) * CFrame.Angles(-0.3, 0, -0.3),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "GraveGlowRift",
		size = Vector3.new(1.2, 0.2, 1.2),
		cframe = CFrame.new(0, 1.9, 0),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	return model
end

-- 23. HollowArmor (Possessed Sentry) - 11 parts
function EnemyCandidates.buildHollowArmor(): Model
	local model = Instance.new("Model")
	model.Name = "HollowArmor"
	createPivot(model)
	makePart({
		name = "HollowCuirass",
		size = Vector3.new(2.0, 1.9, 1.3),
		cframe = CFrame.new(0, 2.4, 0),
		color = ARMOR_STEEL,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "InnerSoulLight",
		size = Vector3.new(0.8, 1.0, 0.5),
		cframe = CFrame.new(0, 2.4, 0),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "FloatingHelm",
		size = Vector3.new(1.1, 1.2, 1.1),
		cframe = CFrame.new(0, 3.8, 0),
		color = ARMOR_STEEL,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "WingCrestL",
		size = Vector3.new(0.2, 1.1, 0.6),
		cframe = CFrame.new(-0.7, 4.3, 0) * CFrame.Angles(0, 0, 0.3),
		color = Color3.fromRGB(90, 95, 105),
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "WingCrestR",
		size = Vector3.new(0.2, 1.1, 0.6),
		cframe = CFrame.new(0.7, 4.3, 0) * CFrame.Angles(0, 0, -0.3),
		color = Color3.fromRGB(90, 95, 105),
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "TowerShield",
		size = Vector3.new(0.3, 3.2, 1.6),
		cframe = CFrame.new(-1.5, 2.2, -0.4),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "BroadswordBlade",
		size = Vector3.new(0.25, 3.4, 0.6),
		cframe = CFrame.new(1.5, 2.2, -0.6) * CFrame.Angles(0.2, 0, 0),
		color = Color3.fromRGB(125, 130, 140),
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "GreaveL",
		size = Vector3.new(0.6, 1.4, 0.7),
		cframe = CFrame.new(-0.5, 0.7, 0),
		color = ARMOR_STEEL,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "GreaveR",
		size = Vector3.new(0.6, 1.4, 0.7),
		cframe = CFrame.new(0.5, 0.7, 0),
		color = ARMOR_STEEL,
		material = Enum.Material.Metal,
		parent = model,
	})
	return model
end

-- 24. LichLord (Crypt Sovereign) - 13 parts
function EnemyCandidates.buildLichLord(): Model
	local model = Instance.new("Model")
	model.Name = "LichLord"
	createPivot(model)
	makePart({
		name = "SovereignRobe",
		size = Vector3.new(2.4, 3.2, 2.0),
		cframe = CFrame.new(0, 1.6, 0),
		color = LICH_PURPLE,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "VelvetMantle",
		size = Vector3.new(2.8, 1.0, 2.2),
		cframe = CFrame.new(0, 3.4, 0),
		color = LICH_MANTLE,
		material = Enum.Material.Fabric,
		parent = model,
	})
	makePart({
		name = "LichSkull",
		size = Vector3.new(1.2, 1.3, 1.1),
		cframe = CFrame.new(0, 4.3, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ObsidianCrown",
		size = Vector3.new(1.4, 0.8, 1.3),
		cframe = CFrame.new(0, 5.1, 0),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "CrownSoulGem",
		size = Vector3.new(0.4, 0.5, 0.4),
		cframe = CFrame.new(0, 5.3, -0.65),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.18, 0.16, 0.2),
		cframe = CFrame.new(-0.3, 4.35, -0.58),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.18, 0.16, 0.2),
		cframe = CFrame.new(0.3, 4.35, -0.58),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "PhylacteryCage",
		size = Vector3.new(1.0, 1.2, 0.6),
		cframe = CFrame.new(0, 2.6, -1.0),
		color = BRONZE_CORRODED,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "PhylacterySoulGlow",
		size = Vector3.new(0.6, 0.8, 0.4),
		cframe = CFrame.new(0, 2.6, -1.0),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "FloatingCrystalFocus",
		size = Vector3.new(0.8, 1.2, 0.8),
		cframe = CFrame.new(1.8, 3.8, -0.8) * CFrame.Angles(0.3, 0.3, 0.3),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "SkeletalArmL",
		size = Vector3.new(0.3, 1.8, 0.3),
		cframe = CFrame.new(-1.5, 2.6, -0.3) * CFrame.Angles(0.2, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SkeletalArmR",
		size = Vector3.new(0.3, 1.8, 0.3),
		cframe = CFrame.new(1.5, 2.6, -0.3) * CFrame.Angles(0.3, 0, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

-- =====================================================================
-- Build All 24 and Sync to ServerStorage.EnemyCandidates
-- =====================================================================

function EnemyCandidates.buildAll(): { [string]: Model }
	return {
		-- Wave 1
		Wraith = EnemyCandidates.buildWraith(),
		CryptGhoul = EnemyCandidates.buildCryptGhoul(),
		PlagueCrow = EnemyCandidates.buildPlagueCrow(),
		BoneHound = EnemyCandidates.buildBoneHound(),
		DeathKnight = EnemyCandidates.buildDeathKnight(),
		BoneScarab = EnemyCandidates.buildBoneScarab(),
		AbyssalWatcher = EnemyCandidates.buildAbyssalWatcher(),
		NecromancerAcolyte = EnemyCandidates.buildNecromancerAcolyte(),
		CursedGargoyle = EnemyCandidates.buildCursedGargoyle(),
		RotWorm = EnemyCandidates.buildRotWorm(),
		ShadowStalker = EnemyCandidates.buildShadowStalker(),
		OssuaryBehemoth = EnemyCandidates.buildOssuaryBehemoth(),
		-- Wave 2
		BarrowWight = EnemyCandidates.buildBarrowWight(),
		CatacombRat = EnemyCandidates.buildCatacombRat(),
		GraveReaper = EnemyCandidates.buildGraveReaper(),
		CandelabraMimic = EnemyCandidates.buildCandelabraMimic(),
		BloodLeech = EnemyCandidates.buildBloodLeech(),
		SkeletalArcher = EnemyCandidates.buildSkeletalArcher(),
		TormentMaiden = EnemyCandidates.buildTormentMaiden(),
		FleshHound = EnemyCandidates.buildFleshHound(),
		BansheeShrieker = EnemyCandidates.buildBansheeShrieker(),
		GraveMound = EnemyCandidates.buildGraveMound(),
		HollowArmor = EnemyCandidates.buildHollowArmor(),
		LichLord = EnemyCandidates.buildLichLord(),
	}
end

function EnemyCandidates.syncCandidates(): Folder
	local targetFolder = ServerStorage:FindFirstChild("EnemyCandidates")
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = "EnemyCandidates"
		targetFolder.Parent = ServerStorage
	end

	local all = EnemyCandidates.buildAll()
	for name, model in pairs(all) do
		local existing = targetFolder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		model.Parent = targetFolder
	end

	return targetFolder
end

-- Creates an edit-mode showcase pedestal in Workspace displaying all 24 enemies in 4 rows of 6
function EnemyCandidates.createShowcase(): Model
	local existing = Workspace:FindFirstChild("EnemyShowcase")
	if existing then
		existing:Destroy()
	end

	local showcase = Instance.new("Model")
	showcase.Name = "EnemyShowcase"

	local all = EnemyCandidates.buildAll()
	local names = {
		-- Row 1
		"Wraith",
		"CryptGhoul",
		"PlagueCrow",
		"BoneHound",
		"DeathKnight",
		"BoneScarab",
		-- Row 2
		"AbyssalWatcher",
		"NecromancerAcolyte",
		"CursedGargoyle",
		"RotWorm",
		"ShadowStalker",
		"OssuaryBehemoth",
		-- Row 3
		"BarrowWight",
		"CatacombRat",
		"GraveReaper",
		"CandelabraMimic",
		"BloodLeech",
		"SkeletalArcher",
		-- Row 4
		"TormentMaiden",
		"FleshHound",
		"BansheeShrieker",
		"GraveMound",
		"HollowArmor",
		"LichLord",
	}

	local spacingX = 12
	local spacingZ = 14
	for index, name in ipairs(names) do
		local model = all[name]
		if model then
			local col = (index - 1) % 6
			local row = math.floor((index - 1) / 6)
			local posX = (col - 2.5) * spacingX
			local posZ = (row - 1.5) * spacingZ

			-- Pedestal Disc
			makePart({
				name = name .. "_Pedestal",
				size = Vector3.new(8, 0.6, 8),
				cframe = CFrame.new(posX, 0.3, posZ),
				color = STONE_COBBLE,
				material = Enum.Material.Slate,
				parent = showcase,
			})
			-- Glowing Rune Ring
			makePart({
				name = name .. "_RuneRing",
				size = Vector3.new(7.2, 0.1, 7.2),
				cframe = CFrame.new(posX, 0.65, posZ),
				color = if row >= 2 then Color3.fromRGB(40, 70, 90) else Color3.fromRGB(60, 40, 80),
				material = Enum.Material.Neon,
				parent = showcase,
				transparency = 0.5,
				castShadow = false,
			})

			-- Position Enemy Model on top of pedestal (Y = 0.65)
			model:PivotTo(CFrame.new(posX, 0.65, posZ))
			model.Parent = showcase
		end
	end

	showcase.Parent = Workspace
	return showcase
end

function EnemyCandidates.buildSkeletonWarrior(): Model
	local model = Instance.new("Model")
	model.Name = "Skeleton"
	createPivot(model)
	local assets = EnemyCandidates.CREATOR_STORE_ASSETS

	-- 1. Legionnaire Pteruges War-Belt & Pelvis
	makePart({
		name = "PelvisBone",
		size = Vector3.new(1.22, 0.52, 0.82),
		cframe = CFrame.new(0, 1.42, 0),
		color = Color3.fromRGB(115, 28, 38),
		material = Enum.Material.Fabric,
		parent = model,
	})

	-- 2. Sculpted 3D Ribcage Cuirass (SkeletonRibcage 3284551923)
	makePart({
		name = "SpineRibcage",
		size = Vector3.new(1.38, 1.52, 0.95),
		cframe = CFrame.new(0, 2.26, 0),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		storeAssetId = assets.SkeletonRibcage,
		keepStoreTexture = true,
		parent = model,
	})

	-- 3. Glowing Soul-Flame Heart inside Ribcage
	makePart({
		name = "SoulHeartCore",
		size = Vector3.new(0.42, 0.52, 0.42),
		cframe = CFrame.new(0, 2.24, -0.06),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})

	-- 4 & 5. Legionnaire Iron Shoulder Pauldrons
	makePart({
		name = "PauldronL",
		size = Vector3.new(0.58, 0.44, 0.72),
		cframe = CFrame.new(-0.84, 2.78, 0) * CFrame.Angles(0, 0, 0.25),
		color = IRON_DARK,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "PauldronR",
		size = Vector3.new(0.58, 0.44, 0.72),
		cframe = CFrame.new(0.84, 2.78, 0) * CFrame.Angles(0, 0, -0.25),
		color = IRON_DARK,
		material = Enum.Material.Metal,
		parent = model,
	})

	-- 6 & 7. Sculpted 3D Skull (SkullOfAinz 2445801226) + Crimson Centurion Plume Crest
	makePart({
		name = "SkullCranium",
		size = Vector3.new(1.12, 1.14, 1.18),
		cframe = CFrame.new(0, 3.46, -0.05),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		storeAssetId = assets.SkullOfAinz,
		keepStoreTexture = true,
		parent = model,
	})
	makePart({
		name = "Head_LegionCrest",
		size = Vector3.new(0.22, 0.52, 1.24),
		cframe = CFrame.new(0, 4.12, 0.02) * CFrame.Angles(-0.12, 0, 0),
		color = Color3.fromRGB(185, 34, 48),
		material = Enum.Material.Fabric,
		parent = model,
	})

	-- 8 & 9. Blazing Cyan Soul Eye Sockets
	makePart({
		name = "Skull_EyeLeft",
		size = Vector3.new(0.24, 0.22, 0.24),
		cframe = CFrame.new(-0.26, 3.44, -0.58),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "Skull_EyeRight",
		size = Vector3.new(0.24, 0.22, 0.24),
		cframe = CFrame.new(0.26, 3.44, -0.58),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})

	-- 10 & 11. Articulated Marching Greaves (LegL / LegR)
	makePart({
		name = "LegL_Greave",
		size = Vector3.new(0.36, 1.38, 0.38),
		cframe = CFrame.new(-0.42, 0.72, 0),
		color = IRON_DARK,
		material = Enum.Material.Metal,
		parent = model,
	})
	makePart({
		name = "LegR_Greave",
		size = Vector3.new(0.36, 1.38, 0.38),
		cframe = CFrame.new(0.42, 0.72, 0),
		color = IRON_DARK,
		material = Enum.Material.Metal,
		parent = model,
	})

	-- 12 & 13. Left Shield Arm + Rectangular Legionnaire Scutum Tower Shield (Held forward in phalanx wall)
	makePart({
		name = "ArmL_Bone",
		size = Vector3.new(0.30, 1.22, 0.30),
		cframe = CFrame.new(-0.86, 2.22, -0.32) * CFrame.Angles(0.65, 0.22, 0.12),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ArmL_ScutumShield",
		size = Vector3.new(1.38, 2.18, 0.24),
		cframe = CFrame.new(-0.58, 2.08, -0.78) * CFrame.Angles(0, 0.22, 0),
		color = BRONZE_CORRODED,
		material = Enum.Material.Metal,
		parent = model,
	})

	-- 14 & 15. Right Thrusting Arm + Forward-Pointed Runic Gladius/Spear Blade (GothicSword 5579516226)
	makePart({
		name = "ArmR_Bone",
		size = Vector3.new(0.30, 1.25, 0.30),
		cframe = CFrame.new(0.88, 2.22, -0.28) * CFrame.Angles(1.15, 0, -0.08),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "Weapon_Runesword",
		size = Vector3.new(0.28, 3.05, 0.52),
		cframe = CFrame.new(0.92, 2.18, -1.65) * CFrame.Angles(1.38, 0, 0),
		color = Color3.fromRGB(130, 240, 255),
		material = Enum.Material.Neon,
		storeAssetId = assets.GothicSword,
		parent = model,
		castShadow = false,
	})
	return model
end

function EnemyCandidates.buildVampireBat(): Model
	local model = Instance.new("Model")
	model.Name = "Bat"
	createPivot(model)

	-- Sculpted Furred Chiroptera Body & Maned Chest
	makePart({
		name = "BatTorso",
		size = Vector3.new(1.15, 1.05, 1.55),
		cframe = CFrame.new(0, 2.45, 0),
		color = Color3.fromRGB(68, 34, 88),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "BatHead",
		size = Vector3.new(0.92, 0.88, 0.98),
		cframe = CFrame.new(0, 2.72, -0.82),
		color = Color3.fromRGB(52, 26, 68),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})

	-- Pointed Bat Ears & Fangs
	makePart({
		name = "EarLeft",
		size = Vector3.new(0.26, 0.78, 0.34),
		cframe = CFrame.new(-0.36, 3.25, -0.75) * CFrame.Angles(-0.15, 0, 0.28),
		color = Color3.fromRGB(95, 38, 115),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EarRight",
		size = Vector3.new(0.26, 0.78, 0.34),
		cframe = CFrame.new(0.36, 3.25, -0.75) * CFrame.Angles(-0.15, 0, -0.28),
		color = Color3.fromRGB(95, 38, 115),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.22, 0.18, 0.22),
		cframe = CFrame.new(-0.26, 2.8, -1.24),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.22, 0.18, 0.22),
		cframe = CFrame.new(0.26, 2.8, -1.24),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "FangLeft",
		size = Vector3.new(0.12, 0.32, 0.12),
		cframe = CFrame.new(-0.16, 2.42, -1.26),
		color = NEON_SHADOW_WHITE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "FangRight",
		size = Vector3.new(0.12, 0.32, 0.12),
		cframe = CFrame.new(0.16, 2.42, -1.26),
		color = NEON_SHADOW_WHITE,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Multi-Segment Articulated Wings (WingLeft / WingRight flap in WorldRenderer)
	makePart({
		name = "WingLeft_Inner",
		size = Vector3.new(1.65, 0.18, 1.35),
		cframe = CFrame.new(-1.15, 2.62, 0.05) * CFrame.Angles(0, -0.15, 0.22),
		color = Color3.fromRGB(125, 32, 95),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "WingLeft_Outer",
		size = Vector3.new(1.55, 0.14, 1.15),
		cframe = CFrame.new(-2.35, 2.75, 0.25) * CFrame.Angles(0, -0.35, -0.12),
		color = Color3.fromRGB(165, 42, 115),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "WingRight_Inner",
		size = Vector3.new(1.65, 0.18, 1.35),
		cframe = CFrame.new(1.15, 2.62, 0.05) * CFrame.Angles(0, 0.15, -0.22),
		color = Color3.fromRGB(125, 32, 95),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "WingRight_Outer",
		size = Vector3.new(1.55, 0.14, 1.15),
		cframe = CFrame.new(2.35, 2.75, 0.25) * CFrame.Angles(0, 0.35, 0.12),
		color = Color3.fromRGB(165, 42, 115),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildVenomSpider(): Model
	local model = Instance.new("Model")
	model.Name = "Spider"
	createPivot(model)

	-- Sculpted Arachnid Cephalothorax & Bulbous Widow Abdomen
	makePart({
		name = "SpiderThorax",
		size = Vector3.new(1.35, 0.95, 1.45),
		cframe = CFrame.new(0, 0.95, -0.55),
		color = Color3.fromRGB(32, 28, 44),
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "SpiderAbdomen",
		size = Vector3.new(2.15, 1.65, 2.45),
		cframe = CFrame.new(0, 1.35, 1.05) * CFrame.Angles(0.18, 0, 0),
		color = Color3.fromRGB(22, 18, 32),
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "VenomHourglassCore",
		size = Vector3.new(0.85, 0.45, 1.15),
		cframe = CFrame.new(0, 2.02, 1.02) * CFrame.Angles(0.18, 0, 0),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		meshType = Enum.MeshType.Sphere,
		parent = model,
		castShadow = false,
	})

	-- Venom Chelicerae Fangs & Multi-Eye Cluster
	makePart({
		name = "FangLeft",
		size = Vector3.new(0.28, 0.55, 0.45),
		cframe = CFrame.new(-0.35, 0.72, -1.35) * CFrame.Angles(0.4, -0.2, 0),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "FangRight",
		size = Vector3.new(0.28, 0.55, 0.45),
		cframe = CFrame.new(0.35, 0.72, -1.35) * CFrame.Angles(0.4, 0.2, 0),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeClusterL",
		size = Vector3.new(0.24, 0.24, 0.24),
		cframe = CFrame.new(-0.32, 1.18, -1.18),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeClusterR",
		size = Vector3.new(0.24, 0.24, 0.24),
		cframe = CFrame.new(0.32, 1.18, -1.18),
		color = NEON_BLOOD_RED,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})

	-- 8 Articulated Arched Spider Legs
	local zOffsets = { -0.85, -0.35, 0.20, 0.75 }
	local yawAngles = { -0.45, -0.15, 0.18, 0.48 }
	for i = 1, 4 do
		local z = zOffsets[i]
		local yaw = yawAngles[i]
		local lRole = if i % 2 == 1 then "LegL_" .. i else "LegR_" .. i
		local rRole = if i % 2 == 1 then "LegR_" .. i else "LegL_" .. i
		makePart({
			name = lRole,
			size = Vector3.new(1.65, 0.26, 0.26),
			cframe = CFrame.new(-1.25, 0.85, z) * CFrame.Angles(0, yaw, 0.42),
			color = Color3.fromRGB(48, 38, 64),
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = rRole,
			size = Vector3.new(1.65, 0.26, 0.26),
			cframe = CFrame.new(1.25, 0.85, z) * CFrame.Angles(0, -yaw, -0.42),
			color = Color3.fromRGB(48, 38, 64),
			material = Enum.Material.Slate,
			parent = model,
		})
	end
	return model
end

function EnemyCandidates.buildRunicGolem(): Model
	local model = Instance.new("Model")
	model.Name = "Golem"
	createPivot(model)

	-- Massive Sculpted Boulder Chest & Glowing Mana Core
	makePart({
		name = "GolemTorso",
		size = Vector3.new(3.2, 2.6, 2.2),
		cframe = CFrame.new(0, 3.25, 0),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	local core = makePart({
		name = "RunicCoreCrystal",
		size = Vector3.new(1.25, 1.45, 0.85),
		cframe = CFrame.new(0, 3.35, -0.85),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		meshType = Enum.MeshType.Sphere,
		parent = model,
		castShadow = false,
	})
	addSoulLight(core, NEON_ICE_BLUE, 1.6, 12)

	-- Mossy Boulder Pauldrons & Arcane Crystal Spikes
	makePart({
		name = "PauldronL",
		size = Vector3.new(1.75, 1.55, 1.75),
		cframe = CFrame.new(-2.15, 4.15, 0),
		color = STONE_COBBLE,
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "PauldronR",
		size = Vector3.new(1.75, 1.55, 1.75),
		cframe = CFrame.new(2.15, 4.15, 0),
		color = STONE_COBBLE,
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "CrystalSpikeL",
		size = Vector3.new(0.55, 1.65, 0.55),
		cframe = CFrame.new(-2.35, 5.15, 0.1) * CFrame.Angles(-0.15, 0, 0.35),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "CrystalSpikeR",
		size = Vector3.new(0.55, 1.65, 0.55),
		cframe = CFrame.new(2.35, 5.15, 0.1) * CFrame.Angles(-0.15, 0, -0.35),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})

	-- Chiseled Stone Head & Glowing Visor Eyes
	makePart({
		name = "GolemHead",
		size = Vector3.new(1.55, 1.45, 1.55),
		cframe = CFrame.new(0, 4.85, -0.25),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.38, 0.22, 0.32),
		cframe = CFrame.new(-0.38, 4.92, -0.92),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.38, 0.22, 0.32),
		cframe = CFrame.new(0.38, 4.92, -0.92),
		color = NEON_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})

	-- Articulated Crusher Arms & Pillar Legs
	makePart({
		name = "ArmL_Crusher",
		size = Vector3.new(1.35, 2.75, 1.35),
		cframe = CFrame.new(-2.35, 2.45, -0.35) * CFrame.Angles(0.28, 0, 0.12),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ArmR_Crusher",
		size = Vector3.new(1.35, 2.75, 1.35),
		cframe = CFrame.new(2.35, 2.45, -0.35) * CFrame.Angles(0.28, 0, -0.12),
		color = STONE_SLATE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegL_Pillar",
		size = Vector3.new(1.25, 1.95, 1.35),
		cframe = CFrame.new(-0.95, 0.98, 0),
		color = STONE_COBBLE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegR_Pillar",
		size = Vector3.new(1.25, 1.95, 1.35),
		cframe = CFrame.new(0.95, 0.98, 0),
		color = STONE_COBBLE,
		material = Enum.Material.Slate,
		parent = model,
	})
	return model
end

function EnemyCandidates.buildPlagueSlime(): Model
	local model = Instance.new("Model")
	model.Name = "PlagueSlime"
	createPivot(model)
	makePart({
		name = "SlimeBasePuddle",
		size = Vector3.new(0.45, 3.6, 3.6),
		cframe = CFrame.new(0, 0.22, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
		color = Color3.fromRGB(35, 215, 65),
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Cylinder,
		transparency = 0.22,
		parent = model,
	})
	local outer = makePart({
		name = "SlimeOuterBody",
		size = Vector3.new(3.1, 2.65, 3.1),
		cframe = CFrame.new(0, 1.42, 0),
		color = Color3.fromRGB(55, 245, 85),
		material = Enum.Material.Glass,
		shape = Enum.PartType.Ball,
		transparency = 0.28,
		parent = model,
	})
	addAuraParticles(outer, NEON_TOXIC_GREEN, NEON_TOXIC_YELLOW, 8, 0.35)

	local core = makePart({
		name = "ToxicNucleus",
		size = Vector3.new(1.35, 1.35, 1.35),
		cframe = CFrame.new(0, 1.45, 0.1),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	addSoulLight(core, NEON_TOXIC_GREEN, 1.4, 10)

	makePart({
		name = "TrappedSkull",
		size = Vector3.new(1.0, 1.05, 1.0),
		cframe = CFrame.new(-0.2, 1.65, -0.25) * CFrame.Angles(0.2, -0.25, 0.15),
		color = BONE_PALE,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.45, 0.45, 0.45),
		cframe = CFrame.new(-0.55, 1.78, -1.28),
		color = NEON_TOXIC_YELLOW,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.45, 0.45, 0.45),
		cframe = CFrame.new(0.55, 1.78, -1.28),
		color = NEON_TOXIC_YELLOW,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "AcidBubble1",
		size = Vector3.new(0.68, 0.68, 0.68),
		cframe = CFrame.new(0.85, 2.55, 0.35),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "AcidBubble2",
		size = Vector3.new(0.52, 0.52, 0.52),
		cframe = CFrame.new(-0.75, 2.65, -0.35),
		color = NEON_TOXIC_YELLOW,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	return model
end

function EnemyCandidates.buildInfernalImp(): Model
	local model = Instance.new("Model")
	model.Name = "InfernalImp"
	createPivot(model)
	makePart({
		name = "ImpTorso",
		size = Vector3.new(1.35, 1.65, 1.05),
		cframe = CFrame.new(0, 1.85, 0),
		color = Color3.fromRGB(220, 45, 45),
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "ImpHead",
		size = Vector3.new(1.25, 1.25, 1.25),
		cframe = CFrame.new(0, 2.95, -0.15),
		color = Color3.fromRGB(240, 60, 50),
		material = Enum.Material.Slate,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	makePart({
		name = "HornLeft",
		size = Vector3.new(0.32, 1.2, 0.32),
		cframe = CFrame.new(-0.55, 3.65, -0.1) * CFrame.Angles(-0.25, 0, 0.45),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "HornRight",
		size = Vector3.new(0.32, 1.2, 0.32),
		cframe = CFrame.new(0.55, 3.65, -0.1) * CFrame.Angles(-0.25, 0, -0.45),
		color = SHROUD_BLACK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "WingLeft",
		size = Vector3.new(1.85, 1.25, 0.22),
		cframe = CFrame.new(-1.35, 2.35, 0.35) * CFrame.Angles(0, 0.35, 0.25),
		color = Color3.fromRGB(78, 22, 88),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "WingRight",
		size = Vector3.new(1.85, 1.25, 0.22),
		cframe = CFrame.new(1.35, 2.35, 0.35) * CFrame.Angles(0, -0.35, -0.25),
		color = Color3.fromRGB(78, 22, 88),
		material = Enum.Material.Fabric,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "ArmL_Claw",
		size = Vector3.new(0.32, 1.15, 0.32),
		cframe = CFrame.new(-0.82, 1.95, -0.42) * CFrame.Angles(0.55, 0, 0.2),
		color = Color3.fromRGB(220, 45, 45),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "ArmR_Claw",
		size = Vector3.new(0.32, 1.15, 0.32),
		cframe = CFrame.new(0.82, 1.95, -0.42) * CFrame.Angles(0.55, 0, -0.2),
		color = Color3.fromRGB(220, 45, 45),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegL_Imp",
		size = Vector3.new(0.35, 1.15, 0.35),
		cframe = CFrame.new(-0.42, 0.75, 0),
		color = Color3.fromRGB(185, 32, 38),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "LegR_Imp",
		size = Vector3.new(0.35, 1.15, 0.35),
		cframe = CFrame.new(0.42, 0.75, 0),
		color = Color3.fromRGB(185, 32, 38),
		material = Enum.Material.Slate,
		parent = model,
	})
	local felOrb = makePart({
		name = "FelCoreOrb",
		size = Vector3.new(0.68, 0.68, 0.68),
		cframe = CFrame.new(0, 1.9, -0.58),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	addSoulLight(felOrb, NEON_TOXIC_GREEN, 1.5, 10)
	addAuraParticles(felOrb, NEON_MOLTEN_ORANGE, NEON_TOXIC_GREEN, 9, 0.3)

	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.24, 0.2, 0.24),
		cframe = CFrame.new(-0.32, 3.05, -0.72),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.24, 0.2, 0.24),
		cframe = CFrame.new(0.32, 3.05, -0.72),
		color = NEON_TOXIC_GREEN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	return model
end

function EnemyCandidates.buildFrostWyrm(): Model
	local model = Instance.new("Model")
	model.Name = "FrostWyrm"
	createPivot(model)
	makePart({
		name = "WyrmChest",
		size = Vector3.new(1.85, 1.55, 2.65),
		cframe = CFrame.new(0, 2.8, 0),
		color = Color3.fromRGB(220, 238, 250),
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "DragonSkull",
		size = Vector3.new(1.35, 1.2, 1.95),
		cframe = CFrame.new(0, 3.55, -1.65),
		color = Color3.fromRGB(235, 245, 255),
		material = Enum.Material.Slate,
		meshType = Enum.MeshType.Sphere,
		parent = model,
	})
	makePart({
		name = "DragonJaw",
		size = Vector3.new(0.95, 0.45, 1.55),
		cframe = CFrame.new(0, 3.02, -1.65) * CFrame.Angles(0.22, 0, 0),
		color = Color3.fromRGB(205, 225, 245),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "FrostHornL",
		size = Vector3.new(0.32, 1.45, 0.32),
		cframe = CFrame.new(-0.55, 4.25, -1.2) * CFrame.Angles(0.55, 0, 0.25),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "FrostHornR",
		size = Vector3.new(0.32, 1.45, 0.32),
		cframe = CFrame.new(0.55, 4.25, -1.2) * CFrame.Angles(0.55, 0, -0.25),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "WingLeft_Ice",
		size = Vector3.new(2.95, 0.25, 1.85),
		cframe = CFrame.new(-2.1, 3.2, 0.2) * CFrame.Angles(0, 0.2, 0.35),
		color = Color3.fromRGB(45, 185, 255),
		material = Enum.Material.Glass,
		meshType = Enum.MeshType.Sphere,
		transparency = 0.18,
		parent = model,
	})
	makePart({
		name = "WingRight_Ice",
		size = Vector3.new(2.95, 0.25, 1.85),
		cframe = CFrame.new(2.1, 3.2, 0.2) * CFrame.Angles(0, -0.2, -0.35),
		color = Color3.fromRGB(45, 185, 255),
		material = Enum.Material.Glass,
		meshType = Enum.MeshType.Sphere,
		transparency = 0.18,
		parent = model,
	})
	local heart = makePart({
		name = "GlacialHeart",
		size = Vector3.new(1.05, 1.05, 1.05),
		cframe = CFrame.new(0, 2.75, -0.35),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	addSoulLight(heart, NEON_ICE_BLUE, 1.6, 12)
	addAuraParticles(heart, NEON_ICE_BLUE, NEON_SHADOW_WHITE, 10, 0.35)

	makePart({
		name = "Tail_Wyrm",
		size = Vector3.new(0.65, 0.65, 2.35),
		cframe = CFrame.new(0, 2.3, 2.1) * CFrame.Angles(-0.3, 0, 0),
		color = Color3.fromRGB(205, 228, 245),
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "EyeLeft",
		size = Vector3.new(0.26, 0.26, 0.26),
		cframe = CFrame.new(-0.45, 3.7, -2.5),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeRight",
		size = Vector3.new(0.26, 0.26, 0.26),
		cframe = CFrame.new(0.45, 3.7, -2.5),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	return model
end

function EnemyCandidates.buildWillOWisp(): Model
	local model = Instance.new("Model")
	model.Name = "Wisp"
	createPivot(model)
	local core = makePart({
		name = "SpiritCore",
		size = Vector3.new(1.5, 1.5, 1.5),
		cframe = CFrame.new(0, 2.2, 0),
		color = NEON_ICE_BLUE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	addSoulLight(core, NEON_SOUL_CYAN, 1.5, 10)
	addAuraParticles(core, NEON_SOUL_CYAN, NEON_VOID_PURPLE, 8, 0.3)

	makePart({
		name = "RunicRing",
		size = Vector3.new(0.25, 2.4, 2.4),
		cframe = CFrame.new(0, 2.2, 0) * CFrame.Angles(0.4, 0, math.pi * 0.5),
		color = BRONZE_CORRODED,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})
	makePart({
		name = "FlameWisp1",
		size = Vector3.new(0.45, 1.6, 0.45),
		cframe = CFrame.new(0, 3.1, 0.15) * CFrame.Angles(-0.2, 0, 0),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "SparkEmber1",
		size = Vector3.new(0.42, 0.42, 0.42),
		cframe = CFrame.new(-0.95, 2.8, 0.3),
		color = NEON_VOID_PURPLE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "SparkEmber2",
		size = Vector3.new(0.42, 0.42, 0.42),
		cframe = CFrame.new(0.95, 1.7, -0.3),
		color = NEON_SOUL_CYAN,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeL",
		size = Vector3.new(0.24, 0.24, 0.24),
		cframe = CFrame.new(-0.32, 2.3, -0.72),
		color = NEON_SHADOW_WHITE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	makePart({
		name = "EyeR",
		size = Vector3.new(0.24, 0.24, 0.24),
		cframe = CFrame.new(0.32, 2.3, -0.72),
		color = NEON_SHADOW_WHITE,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	return model
end

-- =====================================================================
-- 3D Held Weapon Models (ReplicatedStorage.WeaponModels)
-- Built with verified Creator Store 3D MeshParts + Glowing Runic Cores
-- =====================================================================

function EnemyCandidates.buildWeaponModels(): Folder
	local wFolder = ReplicatedStorage:FindFirstChild("WeaponModels")
	if not wFolder then
		wFolder = Instance.new("Folder")
		wFolder.Name = "WeaponModels"
		wFolder.Parent = ReplicatedStorage
	else
		wFolder:ClearAllChildren()
	end
	local assets = EnemyCandidates.CREATOR_STORE_ASSETS

	-- 1. PhantomBow (Glass Bow 524541876 + Emerald Crystal Limbs + Bowstring)
	do
		local m = Instance.new("Model")
		m.Name = "PhantomBow"
		createPivot(m)
		local bowBody = makePart({
			name = "BowFrame",
			size = Vector3.new(0.45, 3.6, 1.15),
			cframe = CFrame.new(0, 0, -0.35),
			color = Color3.fromRGB(65, 235, 165),
			material = Enum.Material.Glass,
			storeAssetId = assets.GlassBow,
			keepStoreTexture = true,
			parent = m,
		})
		addSoulLight(bowBody, Color3.fromRGB(75, 255, 185), 1.35, 9)
		makePart({
			name = "EmeraldCrystalUpper",
			size = Vector3.new(0.28, 1.35, 0.42),
			cframe = CFrame.new(0, 1.15, -0.55) * CFrame.Angles(0.32, 0, 0),
			color = Color3.fromRGB(85, 255, 190),
			material = Enum.Material.Neon,
			parent = m,
			castShadow = false,
		})
		makePart({
			name = "EmeraldCrystalLower",
			size = Vector3.new(0.28, 1.35, 0.42),
			cframe = CFrame.new(0, -1.15, -0.55) * CFrame.Angles(-0.32, 0, 0),
			color = Color3.fromRGB(85, 255, 190),
			material = Enum.Material.Neon,
			parent = m,
			castShadow = false,
		})
		makePart({
			name = "BowString",
			size = Vector3.new(0.08, 3.35, 0.08),
			cframe = CFrame.new(0, 0, 0.22),
			color = NEON_SHADOW_WHITE,
			material = Enum.Material.Neon,
			parent = m,
			castShadow = false,
		})
		m.Parent = wFolder
	end

	-- 2. CryptCleaver (Executioner's Axe 867643066 + Glowing Cyan Rune Edge)
	do
		local m = Instance.new("Model")
		m.Name = "CryptCleaver"
		createPivot(m)
		makePart({
			name = "CleaverShaft",
			size = Vector3.new(0.28, 3.4, 0.28),
			cframe = CFrame.new(0, 0.6, 0),
			color = CULTIST_WOOD,
			material = Enum.Material.Wood,
			parent = m,
		})
		local head = makePart({
			name = "CleaverBlade",
			size = Vector3.new(0.36, 2.15, 1.85),
			cframe = CFrame.new(0, 1.65, -0.55),
			color = ARMOR_STEEL,
			material = Enum.Material.Metal,
			storeAssetId = assets.ExecutionerAxe,
			keepStoreTexture = true,
			parent = m,
		})
		local runeEdge = makePart({
			name = "RunicEdge",
			size = Vector3.new(0.18, 1.95, 0.55),
			cframe = CFrame.new(0, 1.65, -1.25),
			color = NEON_VOID_PURPLE,
			material = Enum.Material.Neon,
			parent = m,
			castShadow = false,
		})
		addSoulLight(head, NEON_VOID_PURPLE, 1.4, 9)
		runeEdge.Name = "RunicEdge"
		m.Parent = wFolder
	end

	-- 3. HexlockPistols (Free Flintlock Pistol 3D Mesh 97885475 / 101559657970017 + Silver Rune Barrel & Grip)
	do
		local m = Instance.new("Model")
		m.Name = "HexlockPistols"
		createPivot(m)
		-- Free 3D Flintlock Pistol Mesh centered on the hand grip and aiming forward (-Z)
		local flintlock = makePart({
			name = "FlintlockMesh",
			size = Vector3.new(0.36, 0.92, 2.05),
			cframe = CFrame.new(0, 0.12, -0.58),
			color = Color3.fromRGB(215, 222, 235),
			material = Enum.Material.Metal,
			storeAssetId = assets.FlintlockPistol,
			keepStoreTexture = true,
			parent = m,
		})
		-- Angled walnut pistol grip right inside the character's palm (0, 0, 0)
		makePart({
			name = "PistolGrip",
			size = Vector3.new(0.28, 0.72, 0.34),
			cframe = CFrame.new(0, -0.22, 0.14) * CFrame.Angles(math.rad(-24), 0, 0),
			color = CULTIST_WOOD,
			material = Enum.Material.Wood,
			parent = m,
		})
		-- Brass skull-cap pommel at the base of the grip
		makePart({
			name = "GripPommel",
			size = Vector3.new(0.32, 0.22, 0.36),
			cframe = CFrame.new(0, -0.52, 0.26),
			color = Color3.fromRGB(212, 168, 72),
			material = Enum.Material.Metal,
			shape = Enum.PartType.Ball,
			parent = m,
		})
		-- Gunmetal flintlock lockplate, receiver & brass trigger guard
		makePart({
			name = "LockReceiver",
			size = Vector3.new(0.34, 0.38, 0.68),
			cframe = CFrame.new(0, 0.14, -0.18),
			color = IRON_DARK,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "TriggerGuard",
			size = Vector3.new(0.14, 0.24, 0.36),
			cframe = CFrame.new(0, -0.06, -0.10),
			color = Color3.fromRGB(212, 168, 72),
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "FlintHammer",
			size = Vector3.new(0.14, 0.32, 0.16),
			cframe = CFrame.new(0, 0.32, -0.04) * CFrame.Angles(math.rad(34), 0, 0),
			color = ARMOR_STEEL,
			material = Enum.Material.Metal,
			parent = m,
		})
		-- Long octagonal silver-steel barrel + under-barrel ramrod + flared muzzle collar
		makePart({
			name = "OctagonBarrel",
			size = Vector3.new(0.26, 0.26, 1.48),
			cframe = CFrame.new(0, 0.22, -0.92),
			color = Color3.fromRGB(210, 218, 232),
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "UnderRamrod",
			size = Vector3.new(0.16, 0.14, 1.28),
			cframe = CFrame.new(0, 0.08, -0.84),
			color = Color3.fromRGB(195, 152, 64),
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "MuzzleCollar",
			size = Vector3.new(0.32, 0.32, 0.18),
			cframe = CFrame.new(0, 0.22, -1.62),
			color = Color3.fromRGB(212, 168, 72),
			material = Enum.Material.Metal,
			parent = m,
		})
		-- Glowing hex-rune sight rail along the top of the barrel
		local sight = makePart({
			name = "HexSightGlow",
			size = Vector3.new(0.12, 0.10, 1.22),
			cframe = CFrame.new(0, 0.34, -0.88),
			color = NEON_AMBER,
			material = Enum.Material.Neon,
			parent = m,
			castShadow = false,
		})
		addSoulLight(flintlock, NEON_AMBER, 1.15, 7)
		sight.Name = "HexSightGlow"
		m.Parent = wFolder
	end

	-- 4. ArcanistStaff (Staff of Magnus 591079857 + Claw-Cradled Astral Crystal)
	do
		local m = Instance.new("Model")
		m.Name = "ArcanistStaff"
		createPivot(m)
		makePart({
			name = "StaffShaft",
			size = Vector3.new(0.28, 4.2, 0.28),
			cframe = CFrame.new(0, 0.85, 0),
			color = CULTIST_WOOD,
			material = Enum.Material.Wood,
			storeAssetId = assets.StaffOfMagnus,
			keepStoreTexture = true,
			parent = m,
		})
		local orb = makePart({
			name = "AstralCrownCrystal",
			size = Vector3.new(0.85, 1.15, 0.85),
			cframe = CFrame.new(0, 2.85, 0),
			color = NEON_ICE_BLUE,
			material = Enum.Material.Neon,
			storeAssetId = assets.QuartzCluster,
			parent = m,
			castShadow = false,
		})
		addSoulLight(orb, NEON_ICE_BLUE, 1.55, 11)
		m.Parent = wFolder
	end

	-- 5. SoulflameLantern (Gothic Lantern 8260717445 + Flickering Soul Core)
	do
		local m = Instance.new("Model")
		m.Name = "SoulflameLantern"
		createPivot(m)
		makePart({
			name = "LanternCage",
			size = Vector3.new(1.15, 1.75, 1.15),
			cframe = CFrame.new(0, -0.55, 0),
			color = IRON_DARK,
			material = Enum.Material.Metal,
			storeAssetId = assets.GothicLantern,
			keepStoreTexture = true,
			parent = m,
		})
		local flame = makePart({
			name = "SoulFlameCore",
			size = Vector3.new(0.68, 0.95, 0.68),
			cframe = CFrame.new(0, -0.55, 0),
			color = NEON_SOUL_CYAN,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = m,
			castShadow = false,
		})
		addSoulLight(flame, NEON_SOUL_CYAN, 1.85, 14)
		m.Parent = wFolder
	end

	-- 6. StormcallerTome (Runic Grimoire 109820689568362 + Lightning Crest)
	do
		local m = Instance.new("Model")
		m.Name = "StormcallerTome"
		createPivot(m)
		local book = makePart({
			name = "GrimoireCover",
			size = Vector3.new(1.35, 1.75, 0.48),
			cframe = CFrame.new(0, 0.25, 0) * CFrame.Angles(-0.35, 0, 0),
			color = Color3.fromRGB(42, 68, 125),
			material = Enum.Material.Fabric,
			storeAssetId = assets.RunicGrimoire,
			keepStoreTexture = true,
			parent = m,
		})
		local crest = makePart({
			name = "StormCrest",
			size = Vector3.new(0.65, 0.95, 0.16),
			cframe = CFrame.new(0, 0.28, -0.24) * CFrame.Angles(-0.35, 0, 0),
			color = NEON_ICE_BLUE,
			material = Enum.Material.Neon,
			parent = m,
			castShadow = false,
		})
		addSoulLight(book, NEON_ICE_BLUE, 1.5, 10)
		crest.Name = "StormCrest"
		m.Parent = wFolder
	end

	return wFolder
end

-- PROC-6 Sanitizer: Audits any Creator Store asset loaded via InsertService, strips scripts/joints,
-- extracts the clean visual MeshPart, and swaps placeholders in-place.
local function hydratePendingStoreMeshes()
	if #pendingMeshUpgrades == 0 then
		return
	end
	local batch = table.clone(pendingMeshUpgrades)
	table.clear(pendingMeshUpgrades)

	local cacheFolder = ServerStorage:FindFirstChild("StoreMeshCache")
	if not cacheFolder then
		cacheFolder = Instance.new("Folder")
		cacheFolder.Name = "StoreMeshCache"
		cacheFolder.Parent = ServerStorage
	end

	task.spawn(function()
		for _, entry in batch do
			local placeholder = entry.placeholder
			if not placeholder.Parent then
				continue
			end
			local assetId = entry.assetId
			local template = storeMeshCache[assetId]

			if not template then
				local cached = cacheFolder:FindFirstChild(tostring(assetId))
				if cached and cached:IsA("MeshPart") then
					template = cached
					storeMeshCache[assetId] = cached
				else
					local ok, loaded = pcall(function()
						return InsertService:LoadAsset(assetId)
					end)
					if ok and loaded then
						-- PROC-6 Audit: strip all scripts, sounds, humanoids, joints, prompts
						local foundMesh: MeshPart? = nil
						for _, desc in loaded:GetDescendants() do
							if
								desc:IsA("LuaSourceContainer")
								or desc:IsA("Humanoid")
								or desc:IsA("Animator")
								or desc:IsA("JointInstance")
								or desc:IsA("ClickDetector")
								or desc:IsA("ProximityPrompt")
								or desc:IsA("Sound")
							then
								desc:Destroy()
							elseif desc:IsA("MeshPart") and not foundMesh then
								foundMesh = desc
							end
						end
						if foundMesh then
							local clean = foundMesh:Clone()
							clean.ClearAllChildren(clean)
							clean.Name = tostring(assetId)
							clean.Anchored = true
							clean.CanCollide = false
							clean.CanTouch = false
							clean.CanQuery = false
							clean.Parent = cacheFolder
							storeMeshCache[assetId] = clean
							template = clean
						end
						loaded:Destroy()
					end
				end
			end

			if template and placeholder.Parent then
				local parentModel = placeholder.Parent
				local wasPrimary = parentModel:IsA("Model") and parentModel.PrimaryPart == placeholder
				local upgraded = template:Clone()
				applyMeshPartProps(upgraded, entry.props)
				for _, child in placeholder:GetChildren() do
					if not child:IsA("SpecialMesh") then
						child.Parent = upgraded
					end
				end
				upgraded.Parent = parentModel
				if wasPrimary and parentModel:IsA("Model") then
					parentModel.PrimaryPart = upgraded
				end
				placeholder:Destroy()
			end
		end
	end)
end

function EnemyCandidates.syncEnemyModels(): Folder
	local folder = ReplicatedStorage:FindFirstChild("EnemyModels")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "EnemyModels"
		folder.Parent = ReplicatedStorage
	end

	local mapping: { [string]: () -> Model } = {
		Skeleton = EnemyCandidates.buildSkeletonWarrior,
		Bat = EnemyCandidates.buildVampireBat,
		Golem = EnemyCandidates.buildRunicGolem,
		Spider = EnemyCandidates.buildVenomSpider,
		Wisp = EnemyCandidates.buildWillOWisp,
		GraveReaper = EnemyCandidates.buildGraveReaper,
		HollowArmor = EnemyCandidates.buildHollowArmor,
		OssuaryBehemoth = EnemyCandidates.buildOssuaryBehemoth,
		LichLord = EnemyCandidates.buildLichLord,
		PlagueSlime = EnemyCandidates.buildPlagueSlime,
		InfernalImp = EnemyCandidates.buildInfernalImp,
		FrostWyrm = EnemyCandidates.buildFrostWyrm,
		CryptGhoul = EnemyCandidates.buildCryptGhoul,
		BoneHound = EnemyCandidates.buildBoneHound,
		AbyssalWatcher = EnemyCandidates.buildAbyssalWatcher,
		NecromancerAcolyte = EnemyCandidates.buildNecromancerAcolyte,
		DeathKnight = EnemyCandidates.buildDeathKnight,
		BansheeShrieker = EnemyCandidates.buildBansheeShrieker,
		CandelabraMimic = EnemyCandidates.buildCandelabraMimic,
	}

	for name, builder in pairs(mapping) do
		local existing = folder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local model = builder()
		model.Name = name
		if name == "GraveReaper" or name == "HollowArmor" or name == "OssuaryBehemoth" or name == "LichLord" then
			local primary = model.PrimaryPart
			if primary then
				local glowColor = if name == "LichLord"
					then NEON_SOUL_CYAN
					elseif name == "OssuaryBehemoth" then NEON_MOLTEN_ORANGE
					elseif name == "HollowArmor" then NEON_ICE_BLUE
					else NEON_VOID_PURPLE
				addSoulLight(primary, glowColor, 2.0, 16)
				addAuraParticles(primary, glowColor, NEON_SHADOW_WHITE, 14, 0.5)
			end
		end
		model.Parent = folder
	end

	EnemyCandidates.buildWeaponModels()
	hydratePendingStoreMeshes()

	return folder
end

return EnemyCandidates
