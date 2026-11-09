--!strict

-- `model` names a template in ReplicatedStorage.EnemyModels (visual parts only, pivot at bottom-centre,
-- facing -Z). If the template is missing the client falls back to a primitive of `shape`/`size`/`color`.
export type Visual = {
	name: string,
	model: string?,
	size: Vector3,
	color: Color3,
	shape: Enum.PartType,
	floatAmp: number?,
	floatFreq: number?,
}

local list: { Visual } = {
	{
		name = "Skeleton",
		model = "Skeleton",
		size = Vector3.new(3, 3, 3),
		color = Color3.fromRGB(226, 216, 190),
		shape = Enum.PartType.Block,
	},
	{
		name = "Bat",
		model = "Bat",
		size = Vector3.new(2.2, 2.2, 2.2),
		color = Color3.fromRGB(160, 65, 220),
		shape = Enum.PartType.Ball,
		floatAmp = 0.45,
		floatFreq = 7.5,
	},
	{
		name = "Golem",
		model = "Golem",
		size = Vector3.new(6, 6, 6),
		color = Color3.fromRGB(70, 195, 235),
		shape = Enum.PartType.Block,
	},
	{
		name = "Spider",
		model = "Spider",
		size = Vector3.new(3, 2, 3),
		color = Color3.fromRGB(85, 235, 65),
		shape = Enum.PartType.Ball,
	},
	{
		name = "Wisp",
		model = "Wisp",
		size = Vector3.new(2.4, 3, 2.4),
		color = Color3.fromRGB(0, 240, 255),
		shape = Enum.PartType.Ball,
		floatAmp = 0.55,
		floatFreq = 5.0,
	},
	{
		name = "GraveReaper",
		model = "GraveReaper",
		size = Vector3.new(3.5, 4.8, 3.5),
		color = Color3.fromRGB(165, 55, 235),
		shape = Enum.PartType.Block,
		floatAmp = 0.35,
		floatFreq = 3.5,
	},
	{
		name = "HollowArmor",
		model = "HollowArmor",
		size = Vector3.new(4.2, 5.2, 4.2),
		color = Color3.fromRGB(70, 185, 255),
		shape = Enum.PartType.Block,
	},
	{
		name = "OssuaryBehemoth",
		model = "OssuaryBehemoth",
		size = Vector3.new(6.5, 6.8, 6.5),
		color = Color3.fromRGB(255, 95, 45),
		shape = Enum.PartType.Block,
	},
	{
		name = "LichLord",
		model = "LichLord",
		size = Vector3.new(5.5, 6.5, 5.5),
		color = Color3.fromRGB(52, 245, 195),
		shape = Enum.PartType.Block,
		floatAmp = 0.45,
		floatFreq = 3.0,
	},
	{
		name = "PlagueSlime",
		model = "PlagueSlime",
		size = Vector3.new(3.2, 2.8, 3.2),
		color = Color3.fromRGB(55, 245, 85),
		shape = Enum.PartType.Ball,
	},
	{
		name = "InfernalImp",
		model = "InfernalImp",
		size = Vector3.new(2.6, 3.4, 2.6),
		color = Color3.fromRGB(255, 65, 45),
		shape = Enum.PartType.Block,
		floatAmp = 0.4,
		floatFreq = 6.5,
	},
	{
		name = "FrostWyrm",
		model = "FrostWyrm",
		size = Vector3.new(4.5, 4.5, 5.2),
		color = Color3.fromRGB(65, 215, 255),
		shape = Enum.PartType.Block,
		floatAmp = 0.5,
		floatFreq = 4.2,
	},
	{
		name = "CryptGhoul",
		model = "CryptGhoul",
		size = Vector3.new(2.6, 2.8, 2.6),
		color = Color3.fromRGB(255, 185, 45),
		shape = Enum.PartType.Block,
	},
	{
		name = "BoneHound",
		model = "BoneHound",
		size = Vector3.new(2.4, 2.5, 4.2),
		color = Color3.fromRGB(255, 55, 75),
		shape = Enum.PartType.Block,
	},
	{
		name = "AbyssalWatcher",
		model = "AbyssalWatcher",
		size = Vector3.new(2.8, 3.4, 2.8),
		color = Color3.fromRGB(185, 65, 255),
		shape = Enum.PartType.Ball,
		floatAmp = 0.5,
		floatFreq = 4.5,
	},
	{
		name = "NecromancerAcolyte",
		model = "NecromancerAcolyte",
		size = Vector3.new(2.6, 4.4, 2.6),
		color = Color3.fromRGB(175, 55, 255),
		shape = Enum.PartType.Block,
	},
	{
		name = "DeathKnight",
		model = "DeathKnight",
		size = Vector3.new(3.6, 4.8, 3.6),
		color = Color3.fromRGB(255, 45, 65),
		shape = Enum.PartType.Block,
	},
	{
		name = "BansheeShrieker",
		model = "BansheeShrieker",
		size = Vector3.new(2.6, 3.8, 2.4),
		color = Color3.fromRGB(85, 245, 235),
		shape = Enum.PartType.Block,
		floatAmp = 0.55,
		floatFreq = 5.5,
	},
	{
		name = "CandelabraMimic",
		model = "CandelabraMimic",
		size = Vector3.new(2.6, 3.4, 2.6),
		color = Color3.fromRGB(215, 85, 255),
		shape = Enum.PartType.Block,
	},
}

local indexByName: { [string]: number } = {}
for index, visual in list do
	indexByName[visual.name] = index
end

return {
	list = list,
	indexByName = indexByName,
}
