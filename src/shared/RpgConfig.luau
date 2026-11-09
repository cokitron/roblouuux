--!strict

export type GearSlot = "Head" | "Shoulders" | "Chest" | "Ring" | "Trinket1" | "Trinket2"

export type GearItem = {
	uid: string,
	slot: GearSlot,
	name: string,
	rarity: number, -- 1 Common, 2 Uncommon, 3 Rare, 4 Epic, 5 Legendary, 6 Heirloom
	ilvl: number,
	setId: string?,
	hp: number,
	damagePct: number,
	critPct: number,
	hastePct: number,
	armor: number,
	magnetPct: number,
	xpPct: number,
	ward: number,
	procDesc: string?,
}

export type TalentNode = {
	id: string,
	name: string,
	icon: string,
	row: number,
	reqPoints: number,
	maxRank: number,
	costs: { number },
	descPerRank: string,
	flavor: string,
}

export type DailyQuestDef = {
	id: string,
	title: string,
	desc: string,
	target: number,
	rewardSouls: number,
	rewardDust: number,
	rewardRep: number,
	rewardDice: number,
}

export type GrimoireEntry = {
	id: string,
	name: string,
	icon: string,
	category: "Monster" | "Boss" | "Evolution",
	hint: string,
}

export type RpgSyncPayload = {
	souls: number,
	arcaneDust: number,
	fateDice: number,
	heroLevel: number,
	heroXp: number,
	heroXpToNext: number,
	restedXp: number,
	reputation: number,
	title: string,
	avgIlvl: number,
	activeSetCount: number,
	activeSetName: string,
	highestKeystone: number,
	selectedKeystone: number,
	weeklyRuns: number,
	vaultClaimed: boolean,
	starterPackOwned: boolean,
	passMagnet: boolean,
	passFourthCard: boolean,
	passDoubleSouls: boolean,
	bloodMoonEndsAt: number,
	bloodMoonBuyer: string,
	talents: { [string]: number },
	slotEnchants: { [string]: number },
	equippedGear: { [string]: GearItem },
	bagGear: { GearItem },
	weaponMastery: { [string]: number },
	dailyProgress: { [string]: number },
	dailyClaimed: { [string]: boolean },
	grimoireCount: number,
	grimoire: { [string]: boolean },
	lastLootDrop: GearItem?,
}

local GEAR_SLOTS: { GearSlot } = {
	"Head",
	"Shoulders",
	"Chest",
	"Ring",
	"Trinket1",
	"Trinket2",
}

local SLOT_LABELS: { [GearSlot]: { name: string, icon: string } } = {
	Head = { name = "Head", icon = "🪖" },
	Shoulders = { name = "Shoulders", icon = "🛡️" },
	Chest = { name = "Chest", icon = "🥋" },
	Ring = { name = "Finger", icon = "💍" },
	Trinket1 = { name = "Trinket I", icon = "🏺" },
	Trinket2 = { name = "Trinket II", icon = "🔮" },
}

local RARITY_INFO = {
	{ name = "Common", hex = "ffffff", color = Color3.fromRGB(255, 255, 255), dustValue = 2 },
	{ name = "Uncommon", hex = "1eff00", color = Color3.fromRGB(30, 255, 0), dustValue = 5 },
	{ name = "Rare", hex = "0070dd", color = Color3.fromRGB(0, 112, 221), dustValue = 12 },
	{ name = "Epic", hex = "a335ee", color = Color3.fromRGB(163, 53, 238), dustValue = 30 },
	{ name = "Legendary", hex = "ff8000", color = Color3.fromRGB(255, 128, 0), dustValue = 75 },
	{ name = "Heirloom", hex = "e6cc80", color = Color3.fromRGB(230, 204, 128), dustValue = 50 },
}

local ITEM_SETS: { [string]: { name: string, bonus2: string, bonus4: string } } = {
	VioletStar = {
		name = "Vestments of the Violet Star",
		bonus2 = "(2) Set: +12% All Weapon & Aura Damage",
		bonus4 = "(4) Set: +8% Crit Chance, +10% Attack Haste & +20 Arcane Ward",
	},
	BoneReaper = {
		name = "Battlegear of the Bone Reaper",
		bonus2 = "(2) Set: +12% All Weapon & Aura Damage",
		bonus4 = "(4) Set: +35 Max Health, +2 Armor & +10% Attack Haste",
	},
	AshenPyre = {
		name = "Raiment of the Ashen Pyre",
		bonus2 = "(2) Set: +12% All Weapon & Aura Damage",
		bonus4 = "(4) Set: +25% Crystal Magnet, +15% XP Gain & +8% Crit Chance",
	},
}

local SET_IDS = { "VioletStar", "BoneReaper", "AshenPyre" }

local TALENT_NODES: { TalentNode } = {
	-- Row 1 (Requires 0 Total Points)
	{
		id = "meta_might",
		name = "Graveborn Might",
		icon = "⚔️",
		row = 1,
		reqPoints = 0,
		maxRank = 5,
		costs = { 40, 80, 150, 260, 420 },
		descPerRank = "+5% All Weapon & Aura Damage per rank",
		flavor = "Strength drawn from a thousand forgotten tombs.",
	},
	{
		id = "meta_vitality",
		name = "Undying Vessel",
		icon = "❤️",
		row = 1,
		reqPoints = 0,
		maxRank = 5,
		costs = { 40, 80, 150, 260, 420 },
		descPerRank = "+15 Starting Max Health per rank",
		flavor = "Flesh tempered by moonlight refuses to yield.",
	},
	{
		id = "meta_magnet",
		name = "Soul Siphon",
		icon = "🧲",
		row = 1,
		reqPoints = 0,
		maxRank = 5,
		costs = { 45, 90, 165, 280, 450 },
		descPerRank = "+12% Soul Crystal Pickup Radius per rank",
		flavor = "The departed gravitate toward a vessel of power.",
	},
	-- Row 2 (Requires 5 Total Points in Tree)
	{
		id = "meta_crit",
		name = "Cruelty",
		icon = "⚡",
		row = 2,
		reqPoints = 5,
		maxRank = 5,
		costs = { 60, 120, 220, 360, 550 },
		descPerRank = "+3% Critical Strike Chance per rank",
		flavor = "Strike where the armor is rusted through.",
	},
	{
		id = "meta_haste",
		name = "Phantom Stride",
		icon = "🥾",
		row = 2,
		reqPoints = 5,
		maxRank = 5,
		costs = { 60, 120, 220, 360, 550 },
		descPerRank = "+4% Base Movement Speed per rank",
		flavor = "Step lightly across the sunken flagstones.",
	},
	{
		id = "meta_wisdom",
		name = "Ancient Scholar",
		icon = "📖",
		row = 2,
		reqPoints = 5,
		maxRank = 5,
		costs = { 65, 130, 240, 400, 600 },
		descPerRank = "+8% In-Run XP & Hero XP Gain per rank",
		flavor = "Every epitaph holds a lesson in survival.",
	},
	-- Row 3 (Requires 10 Total Points in Tree)
	{
		id = "meta_ward",
		name = "Sanctuary Ward",
		icon = "🛡️",
		row = 3,
		reqPoints = 10,
		maxRank = 3,
		costs = { 120, 280, 550 },
		descPerRank = "Start runs with +12 Recharging Arcane Ward per rank",
		flavor = "An aetheric bulwark blessed by the Ashen Order.",
	},
	{
		id = "meta_dice",
		name = "Hand of Fate",
		icon = "🎲",
		row = 3,
		reqPoints = 10,
		maxRank = 3,
		costs = { 140, 320, 650 },
		descPerRank = "Gain +1 Bonus Roll Coin at the start of every run",
		flavor = "Even the Fates can be bribed with enough Souls.",
	},
	{
		id = "meta_fortune",
		name = "Gilded Fate",
		icon = "🍀",
		row = 3,
		reqPoints = 10,
		maxRank = 5,
		costs = { 90, 180, 320, 520, 800 },
		descPerRank = "+8% Rare, Epic & Legendary Card and Loot Odds per rank",
		flavor = "Fortune favors the bold—and the well-prepared.",
	},
	-- Row 4 Capstones (Requires 15 Total Points in Tree)
	{
		id = "meta_power_infusion",
		name = "Power Infusion",
		icon = "👑",
		row = 4,
		reqPoints = 15,
		maxRank = 1,
		costs = { 750 },
		descPerRank = "KEYSTONE: +15% Attack Speed & +15% All Damage permanently",
		flavor = "Pure arcane radiance courses through your veins.",
	},
	{
		id = "meta_cheat_death",
		name = "Bulwark of the Undying",
		icon = "🩸",
		row = 4,
		reqPoints = 15,
		maxRank = 1,
		costs = { 750 },
		descPerRank = "KEYSTONE: +2 Flat Armor & +1.5 HP/s Sanctuary Regeneration",
		flavor = "Even the Reaper hesitates before your resolve.",
	},
}

local TALENT_BY_ID: { [string]: TalentNode } = {}
for _, node in TALENT_NODES do
	TALENT_BY_ID[node.id] = node
end

local DAILY_QUESTS: { DailyQuestDef } = {
	{
		id = "slay_undead",
		title = "Emissary: Cull the Swarm",
		desc = "Slay 120 Undead Foes across any Graveyard runs",
		target = 120,
		rewardSouls = 75,
		rewardDust = 15,
		rewardRep = 250,
		rewardDice = 1,
	},
	{
		id = "survive_time",
		title = "Emissary: Night Watch",
		desc = "Survive 240 Cumulative Seconds in the Graveyard",
		target = 240,
		rewardSouls = 90,
		rewardDust = 20,
		rewardRep = 300,
		rewardDice = 1,
	},
	{
		id = "reach_level",
		title = "Emissary: Ascendant Power",
		desc = "Reach Run Level 6 or defeat a Mini-Boss",
		target = 6,
		rewardSouls = 110,
		rewardDust = 25,
		rewardRep = 350,
		rewardDice = 2,
	},
}

local SLOT_BASE_NAMES: { [GearSlot]: { string } } = {
	Head = { "Dreadmist Cowl", "Helm of Domination", "Crown of Eternal Night", "Ashen Visage", "Cryptstalker Hood" },
	Shoulders = {
		"Pauldrons of Wrath",
		"Mantle of the Blackwing",
		"Spaulders of Valor",
		"Boneguard Shoulders",
		"Plagueheart Mantle",
	},
	Chest = {
		"Robes of Transcendence",
		"Breastplate of Might",
		"Vestments of Prophecy",
		"Deathbone Cuirass",
		"Soulforge Hauberk",
	},
	Ring = {
		"Band of Accuria",
		"Signet of the Fallen",
		"Ring of Spell Power",
		"Ashen Band of Wisdom",
		"Seal of the Archmage",
	},
	Trinket1 = {
		"Neltharion's Tear",
		"Drake Fang Talisman",
		"Phylactery of the Lich",
		"Briarwood Reed",
		"Hand of Justice",
	},
	Trinket2 = {
		"Darkmoon Card: Maelstrom",
		"Eye of the Beast",
		"Mind Quickening Gem",
		"Skull of Gul'dan",
		"Talisman of Ephemeral Power",
	},
}

local SUFFIXES = {
	"of the Tiger",
	"of the Whale",
	"of the Eagle",
	"of the Quickblade",
	"of the Lich",
	"of the Archmage",
	"of the Bear",
	"of the Shadow",
}

local TRINKET_PROCS = {
	"Equip: Critical hits surge with arcane energy (+10% Crit & Haste).",
	"Equip: Slaying elites restores vitality and empowers your aura.",
	"Equip: Surrounds the bearer with a resonant ward of the Ashen Order.",
	"Equip: Channels ancient haste, reducing weapon cooldowns.",
}

local KEYSTONE_AFFIXES: { [number]: { name: string, desc: string } } = {
	[0] = {
		name = "Normal Crypt",
		desc = "Standard Graveyard threat. Defeat the Lich Lord at 10:00 to earn Keystones.",
	},
	[1] = { name = "Mythic +1 (Fortified)", desc = "+25% Enemy HP & Damage • +25% Souls • +5 Min Loot iLvl" },
	[2] = {
		name = "Mythic +2 (Volcanic)",
		desc = "+50% Enemy Power • +50% Souls • +10 Min Loot iLvl • Elite Foes Haste",
	},
	[3] = {
		name = "Mythic +3 (Sanguine)",
		desc = "+80% Enemy Power • +75% Souls • +15 Min Loot iLvl • Guaranteed Rare+ Drops",
	},
	[4] = {
		name = "Mythic +4 (Bolstering)",
		desc = "+115% Enemy Power • +100% Souls • +20 Min Loot iLvl • Higher Epic Odds",
	},
	[5] = {
		name = "Mythic +5 (Tyrannical)",
		desc = "+150% Enemy Power • +150% Souls • +28 Min Loot iLvl • High Epic/Legendary Odds",
	},
}

local GRIMOIRE_ENTRIES: { GrimoireEntry } = {
	{
		id = "Skeleton",
		name = "Skeleton Warrior",
		icon = "💀",
		category = "Monster",
		hint = "Pursuer • Common Undead",
	},
	{
		id = "Bat",
		name = "Vampire Nightbat",
		icon = "🦇",
		category = "Monster",
		hint = "Flyer • Swoops Over Walls",
	},
	{
		id = "Spider",
		name = "Venom Tomb Spider",
		icon = "🕷️",
		category = "Monster",
		hint = "Charger • Lunges Forward",
	},
	{
		id = "Wisp",
		name = "Soul Lantern Wisp",
		icon = "🏮",
		category = "Monster",
		hint = "Flyer • Ghostfire Drifter",
	},
	{
		id = "PlagueSlime",
		name = "Plague Ooze Slime",
		icon = "🟢",
		category = "Monster",
		hint = "Pursuer • Toxic Crypt Mass",
	},
	{
		id = "InfernalImp",
		name = "Infernal Pyre Imp",
		icon = "🔥",
		category = "Monster",
		hint = "Skirmisher • Flanks in Rings",
	},
	{
		id = "CryptGhoul",
		name = "Ravenous Crypt Ghoul",
		icon = "🧟",
		category = "Monster",
		hint = "Pursuer • Fast Pack Hunter",
	},
	{
		id = "BoneHound",
		name = "Skeletal Bone Hound",
		icon = "🐺",
		category = "Monster",
		hint = "Charger • High-Speed Pounce",
	},
	{
		id = "CandelabraMimic",
		name = "Candelabra Mimic",
		icon = "🕯️",
		category = "Monster",
		hint = "Pursuer • Haunted Relic",
	},
	{
		id = "AbyssalWatcher",
		name = "Abyssal Eye Watcher",
		icon = "👁️",
		category = "Monster",
		hint = "Skirmisher • Eldritch Gaze",
	},
	{
		id = "NecromancerAcolyte",
		name = "Necromancer Acolyte",
		icon = "🧙",
		category = "Monster",
		hint = "Skirmisher • Dark Cultist",
	},
	{
		id = "BansheeShrieker",
		name = "Wailing Banshee",
		icon = "👻",
		category = "Monster",
		hint = "Flyer • Spectral Shrieker",
	},
	{
		id = "FrostWyrm",
		name = "Glacial Frost Wyrm",
		icon = "❄️",
		category = "Monster",
		hint = "Flyer Elite • Drops Reliquaries",
	},
	{
		id = "Golem",
		name = "Runic Stone Golem",
		icon = "🗿",
		category = "Monster",
		hint = "Juggernaut • Drops Reliquaries",
	},
	{
		id = "DeathKnight",
		name = "Crypt Death Knight",
		icon = "⚔️",
		category = "Monster",
		hint = "Phalanx Captain • Drops Reliquaries",
	},
	{
		id = "GraveReaper",
		name = "Grave Reaper",
		icon = "镰",
		category = "Boss",
		hint = "3:00 Mini-Boss • Drops Boss Chest",
	},
	{
		id = "HollowArmor",
		name = "Hollow Dreadnought",
		icon = "🛡️",
		category = "Boss",
		hint = "6:00 Mini-Boss • Drops Boss Chest",
	},
	{
		id = "OssuaryBehemoth",
		name = "Ossuary Behemoth",
		icon = "🦴",
		category = "Boss",
		hint = "9:00 Mini-Boss • Drops Boss Chest",
	},
	{
		id = "LichLord",
		name = "The Lich Lord",
		icon = "👑",
		category = "Boss",
		hint = "10:00 Stage Boss • Unlocks Keystones",
	},
	{
		id = "evolve_staff",
		name = "Astral Starfall",
		icon = "🌟",
		category = "Evolution",
		hint = "Evolve Staff (Rank 2+ Bolt DMG)",
	},
	{
		id = "evolve_cleaver",
		name = "Crimson Guillotine",
		icon = "🩸",
		category = "Evolution",
		hint = "Evolve Cleaver (Rank 2+ Cleave DMG)",
	},
	{
		id = "evolve_lantern",
		name = "Ashen Hellstorm",
		icon = "🔥",
		category = "Evolution",
		hint = "Evolve Lantern (Rank 2+ Cinder DMG)",
	},
	{
		id = "evolve_bow",
		name = "Thousand-Arrow Tempest",
		icon = "🏹",
		category = "Evolution",
		hint = "Evolve Bow (Rank 2+ Bow DMG)",
	},
	{
		id = "evolve_pistols",
		name = "Silver Executioner",
		icon = "🔫",
		category = "Evolution",
		hint = "Evolve Pistols (Rank 2+ Pistol DMG)",
	},
	{
		id = "evolve_storm",
		name = "Mjolnir's Wrath",
		icon = "⚡",
		category = "Evolution",
		hint = "Evolve Tome (Rank 2+ Storm DMG)",
	},
}

local RpgConfig = {
	GEAR_SLOTS = GEAR_SLOTS,
	SLOT_LABELS = SLOT_LABELS,
	RARITY_INFO = RARITY_INFO,
	ITEM_SETS = ITEM_SETS,
	TALENT_NODES = TALENT_NODES,
	TALENT_BY_ID = TALENT_BY_ID,
	DAILY_QUESTS = DAILY_QUESTS,
	GRIMOIRE_ENTRIES = GRIMOIRE_ENTRIES,
}

function RpgConfig.heroXpForLevel(level: number): number
	local clamped = math.max(1, level)
	return math.floor(40 + clamped * 25 + clamped ^ 1.55)
end

function RpgConfig.getReputationBracket(rep: number): (string, number, number, Color3)
	if rep >= 42000 then
		return "Exalted", rep - 42000, 1000, Color3.fromRGB(255, 128, 0)
	elseif rep >= 21000 then
		return "Revered", rep - 21000, 21000, Color3.fromRGB(163, 53, 238)
	elseif rep >= 9000 then
		return "Honored", rep - 9000, 12000, Color3.fromRGB(0, 168, 255)
	elseif rep >= 3000 then
		return "Friendly", rep - 3000, 6000, Color3.fromRGB(30, 255, 0)
	end
	return "Neutral", rep, 3000, Color3.fromRGB(215, 200, 130)
end

function RpgConfig.getHeroTitle(heroLevel: number, rep: number, highestKeystone: number): string
	if highestKeystone >= 5 or rep >= 42000 then
		return "the Undying Cryptlord"
	elseif highestKeystone >= 3 or heroLevel >= 25 or rep >= 21000 then
		return "High Arcanist of the Dawn"
	elseif heroLevel >= 12 or rep >= 9000 then
		return "Knight of the Ashen Order"
	elseif heroLevel >= 5 or rep >= 3000 then
		return "Gravewalker"
	end
	return "Initiate of the Sanctuary"
end

function RpgConfig.getEnchantCost(currentLevel: number): (number, number)
	local nextLvl = currentLevel + 1
	local souls = nextLvl * 45
	local dust = nextLvl * 8
	return souls, dust
end

function RpgConfig.getKeystoneInfo(level: number): {
	name: string,
	desc: string,
	enemyMult: number,
	soulsMult: number,
	ilvlBonus: number,
}
	local clamped = math.clamp(math.floor(level), 0, 15)
	local preset = KEYSTONE_AFFIXES[math.min(clamped, 5)] or KEYSTONE_AFFIXES[0]
	local name = if clamped <= 5 then preset.name else string.format("Mythic +%d (Tyrannical + Bolstering)", clamped)
	local enemyMult = 1 + clamped * 0.28
	local soulsMult = 1 + clamped * 0.25
	local ilvlBonus = clamped * 6
	local desc = if clamped == 0
		then preset.desc
		else string.format(
			"+%d%% Enemy Power • +%d%% Souls & Hero XP • +%d Loot iLvl",
			math.floor((enemyMult - 1) * 100),
			math.floor((soulsMult - 1) * 100),
			ilvlBonus
		)
	return {
		name = name,
		desc = desc,
		enemyMult = enemyMult,
		soulsMult = soulsMult,
		ilvlBonus = ilvlBonus,
	}
end

function RpgConfig.rollGearItem(
	rng: Random,
	heroLevel: number,
	keystoneLevel: number,
	minRarity: number,
	luckBonus: number,
	forcedSlot: GearSlot?
): GearItem
	local slot: GearSlot = forcedSlot or GEAR_SLOTS[rng:NextInteger(1, #GEAR_SLOTS)]
	local baseIlvl = 10 + (heroLevel - 1) * 3 + keystoneLevel * 6 + rng:NextInteger(0, 6)

	local roll = rng:NextNumber() * (1 + luckBonus)
	local rarity = 2
	if roll > 0.96 then
		rarity = 5 -- Legendary
	elseif roll > 0.80 then
		rarity = 4 -- Epic
	elseif roll > 0.45 then
		rarity = 3 -- Rare
	else
		rarity = 2 -- Uncommon
	end
	rarity = math.clamp(math.max(rarity, minRarity), 1, 5)

	local ilvl = baseIlvl + (rarity - 1) * 6
	local names = SLOT_BASE_NAMES[slot]
	local baseName = names[rng:NextInteger(1, #names)]
	local suffix = SUFFIXES[rng:NextInteger(1, #SUFFIXES)]
	local setId: string? = nil
	if rarity >= 3 and (slot == "Head" or slot == "Shoulders" or slot == "Chest" or slot == "Ring") then
		setId = SET_IDS[rng:NextInteger(1, #SET_IDS)]
	end

	local scale = ilvl / 20
	local rarityMult = 0.85 + rarity * 0.22

	local hp = 0
	local damagePct = 0
	local critPct = 0
	local hastePct = 0
	local armor = 0
	local magnetPct = 0
	local xpPct = 0
	local ward = 0
	local procDesc: string? = nil

	if slot == "Head" then
		hp = math.floor(12 * scale * rarityMult)
		damagePct = math.floor(3 * rarityMult + scale * 1.5)
		if rarity >= 3 then
			hastePct = math.floor(2 + rarity * 1.5)
		end
	elseif slot == "Shoulders" then
		damagePct = math.floor(5 * rarityMult + scale * 2)
		critPct = math.floor(2 + rarity * 1.2)
		if rarity >= 4 then
			hp = math.floor(10 * scale)
		end
	elseif slot == "Chest" then
		hp = math.floor(20 * scale * rarityMult)
		armor = math.max(1, math.floor(rarity * 0.8))
		if rarity >= 3 then
			ward = math.floor(6 * rarity)
		end
	elseif slot == "Ring" then
		damagePct = math.floor(3 * rarityMult + scale)
		magnetPct = math.floor(6 + rarity * 3)
		xpPct = math.floor(4 + rarity * 2.5)
	else
		-- Trinket1 or Trinket2
		damagePct = math.floor(4 * rarityMult + scale * 1.5)
		critPct = math.floor(2 + rarity * 1.5)
		hastePct = math.floor(2 + rarity * 1.5)
		if rarity >= 3 then
			procDesc = TRINKET_PROCS[rng:NextInteger(1, #TRINKET_PROCS)]
		end
	end

	local uid = string.format("%s_%d_%d", slot, math.floor(os.clock() * 1000) % 1000000, rng:NextInteger(100, 999))
	return {
		uid = uid,
		slot = slot,
		name = baseName .. " " .. suffix,
		rarity = rarity,
		ilvl = ilvl,
		setId = setId,
		hp = hp,
		damagePct = damagePct,
		critPct = critPct,
		hastePct = hastePct,
		armor = armor,
		magnetPct = magnetPct,
		xpPct = xpPct,
		ward = ward,
		procDesc = procDesc,
	}
end

function RpgConfig.makeHeirloomTrinket(heroLevel: number): GearItem
	local ilvl = math.max(35, 15 + heroLevel * 4)
	return {
		uid = "heirloom_signet_of_the_first_warden",
		slot = "Trinket1",
		name = "Heirloom Phylactery of the First Warden",
		rarity = 6,
		ilvl = ilvl,
		setId = "VioletStar",
		hp = 25 + heroLevel * 2,
		damagePct = 12 + math.floor(heroLevel * 0.5),
		critPct = 6,
		hastePct = 8,
		armor = 1,
		magnetPct = 20,
		xpPct = 15,
		ward = 15,
		procDesc = "Heirloom: Scales with Hero Level. Grants +15% Hero XP & +20% Crystal Magnet.",
	}
end

return RpgConfig
