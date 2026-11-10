--!strict
local AnalyticsService = game:GetService("AnalyticsService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local RpgConfig = require(ReplicatedStorage.Shared.RpgConfig)

type GearItem = RpgConfig.GearItem
type GearSlot = RpgConfig.GearSlot

export type Profile = {
	version: number,
	souls: number,
	arcaneDust: number,
	fateDice: number,
	heroLevel: number,
	heroXp: number,
	restedXp: number,
	reputation: number,
	bestTime: number,
	bestKills: number,
	totalRuns: number,
	highestKeystone: number,
	selectedKeystone: number,
	weeklyRuns: number,
	vaultWeek: number,
	vaultClaimed: boolean,
	dailyDay: number,
	dailyProgress: { [string]: number },
	dailyClaimed: { [string]: boolean },
	starterPackOwned: boolean,
	passMagnet: boolean,
	passFourthCard: boolean,
	passDoubleSouls: boolean,
	talents: { [string]: number },
	slotEnchants: { [string]: number },
	equippedGear: { [string]: GearItem },
	bagGear: { GearItem },
	weaponMastery: { [string]: number },
	grimoire: { [string]: boolean },
	processedReceipts: { [string]: boolean },
	lastLootDrop: GearItem?,
}

export type ComputedBonuses = {
	bonusHp: number,
	damageMult: number,
	critBonus: number,
	cooldownMult: number,
	moveSpeedMult: number,
	magnetMult: number,
	xpMult: number,
	luckBonus: number,
	armorBonus: number,
	wardBonus: number,
	regenBonus: number,
	startingDice: number,
	soulsMult: number,
	avgIlvl: number,
	activeSetCount: number,
	activeSetName: string,
}

local STORE_NAME = "roblouuux_PlayerProfile_v1"
local SCHEMA_VERSION = 1
local MAX_BAG_ITEMS = 18
local MAX_ENCHANT_LEVEL = 10
local AUTOSAVE_INTERVAL = 120

local rpgSyncRemote = Remotes.get("RpgSync")
local profiles: { [Player]: Profile } = {}
local loadFailed: { [Player]: boolean } = {}
local rng = Random.new()
local store: DataStore? = nil
local bloodMoonEndsAt = 0
local bloodMoonBuyer = ""

pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local DataService = {}

local function currentUtcDay(): number
	return math.floor(os.time() / 86400)
end

local function currentUtcWeek(): number
	return math.floor(os.time() / (86400 * 7))
end

local function newDefaultProfile(): Profile
	local starterHelm = RpgConfig.rollGearItem(rng, 1, 0, 2, 0, "Head")
	starterHelm.name = "Initiate's Dreadmist Hood"
	starterHelm.ilvl = 12
	starterHelm.hp = 15
	starterHelm.damagePct = 5

	return {
		version = SCHEMA_VERSION,
		souls = 60, -- Starter Souls so new players can inspect or test the Sanctuary Altar immediately
		arcaneDust = 10,
		fateDice = 2,
		heroLevel = 1,
		heroXp = 0,
		restedXp = 65, -- Full Rested XP bar on Day 1
		reputation = 500,
		bestTime = 0,
		bestKills = 0,
		totalRuns = 0,
		highestKeystone = 1, -- Allow trying Mythic +1 or Normal right away
		selectedKeystone = 0,
		weeklyRuns = 0,
		vaultWeek = currentUtcWeek(),
		vaultClaimed = false,
		dailyDay = currentUtcDay(),
		dailyProgress = {
			slay_undead = 0,
			survive_time = 0,
			reach_level = 0,
		},
		dailyClaimed = {},
		starterPackOwned = false,
		passMagnet = false,
		passFourthCard = false,
		passDoubleSouls = false,
		talents = {},
		slotEnchants = {
			Head = 0,
			Shoulders = 0,
			Chest = 0,
			Ring = 0,
			Trinket1 = 0,
			Trinket2 = 0,
		},
		equippedGear = {
			Head = starterHelm,
		},
		bagGear = {},
		weaponMastery = {
			ArcanistStaff = 1,
			CryptCleaver = 1,
			SoulflameLantern = 1,
			PhantomBow = 1,
			HexlockPistols = 1,
			StormcallerTome = 1,
		},
		grimoire = {
			Skeleton = true,
		},
		processedReceipts = {},
		lastLootDrop = nil,
	}
end

local function reconcileProfile(raw: any): Profile
	local def = newDefaultProfile()
	if typeof(raw) ~= "table" then
		return def
	end
	for k, v in pairs(def) do
		if raw[k] == nil then
			raw[k] = v
		end
	end
	for wId, rank in pairs(def.weaponMastery) do
		if raw.weaponMastery[wId] == nil then
			raw.weaponMastery[wId] = rank
		end
	end
	raw.version = SCHEMA_VERSION

	-- Refresh Daily Quests & Rested XP on new UTC day
	local today = currentUtcDay()
	if raw.dailyDay ~= today then
		raw.dailyDay = today
		raw.dailyProgress = { slay_undead = 0, survive_time = 0, reach_level = 0 }
		raw.dailyClaimed = {}
		local maxRested = math.floor(RpgConfig.heroXpForLevel(raw.heroLevel) * 1.5)
		raw.restedXp = math.max(raw.restedXp or 0, maxRested)
	end

	-- Refresh Weekly Great Vault on new UTC week
	local thisWeek = currentUtcWeek()
	if raw.vaultWeek ~= thisWeek then
		raw.vaultWeek = thisWeek
		raw.weeklyRuns = 0
		raw.vaultClaimed = false
	end

	return raw :: Profile
end

local function countGrimoire(profile: Profile): number
	local count = 0
	for _, unlocked in pairs(profile.grimoire) do
		if unlocked then
			count += 1
		end
	end
	return count
end

function DataService.getTotalTalentPoints(profile: Profile): number
	local total = 0
	for _, rank in pairs(profile.talents) do
		total += rank
	end
	return total
end

function DataService.computeBonuses(player: Player): ComputedBonuses
	local profile = profiles[player]
	if not profile then
		return {
			bonusHp = 0,
			damageMult = 1,
			critBonus = 0,
			cooldownMult = 1,
			moveSpeedMult = 1,
			magnetMult = 1,
			xpMult = 1,
			luckBonus = 0,
			armorBonus = 0,
			wardBonus = 0,
			regenBonus = 0,
			startingDice = 0,
			soulsMult = 1,
			avgIlvl = 0,
			activeSetCount = 0,
			activeSetName = "",
		}
	end

	if profile.starterPackOwned and profile.equippedGear.Trinket1 then
		if profile.equippedGear.Trinket1.rarity == 6 then
			profile.equippedGear.Trinket1 = RpgConfig.makeHeirloomTrinket(profile.heroLevel)
		end
	end

	local gCount = countGrimoire(profile)
	local bonusHp = (profile.heroLevel - 1) * 4 + gCount * 1
	local damagePct = (profile.heroLevel - 1) * 1.5 + gCount * 0.5
	local critPct = 0
	local hastePct = 0
	local moveSpeedPct = 0
	local magnetPct = 0
	local xpPct = 0
	local luckPct = 0
	local armorBonus = 0
	local wardBonus = 0
	local regenBonus = 0
	local startingDice = 0

	-- 1. Tiered Sanctuary Talent Tree
	local t = profile.talents
	damagePct += (t.meta_might or 0) * 5
	bonusHp += (t.meta_vitality or 0) * 15
	magnetPct += (t.meta_magnet or 0) * 12
	critPct += (t.meta_crit or 0) * 3
	moveSpeedPct += (t.meta_haste or 0) * 4
	xpPct += (t.meta_wisdom or 0) * 8
	wardBonus += (t.meta_ward or 0) * 12
	startingDice += (t.meta_dice or 0) * 1
	luckPct += (t.meta_fortune or 0) * 8
	if (t.meta_power_infusion or 0) >= 1 then
		damagePct += 15
		hastePct += 15
	end
	if (t.meta_cheat_death or 0) >= 1 then
		armorBonus += 2
		regenBonus += 1.5
	end
	local ascensionRanks = t.meta_ascension or 0
	if ascensionRanks > 0 then
		damagePct += ascensionRanks * 2
		bonusHp += ascensionRanks * 4
	end

	-- 2. Equipped 6-Slot Gear + Slot Enchantments + Set Count
	local totalIlvl = 0
	local setCounts: { [string]: number } = {}
	for _, slot in RpgConfig.GEAR_SLOTS do
		local ench = profile.slotEnchants[slot] or 0
		local item = profile.equippedGear[slot]
		if item then
			totalIlvl += item.ilvl + ench * 2
			bonusHp += item.hp + ench * 4
			damagePct += item.damagePct + ench * 1.5
			critPct += item.critPct
			hastePct += item.hastePct
			armorBonus += item.armor
			magnetPct += item.magnetPct
			xpPct += item.xpPct
			wardBonus += item.ward
			if item.setId then
				setCounts[item.setId] = (setCounts[item.setId] or 0) + 1
			end
		else
			totalIlvl += ench * 2
			bonusHp += ench * 4
			damagePct += ench * 1.5
		end
	end

	-- 3. Tier Set Bonuses (2-Piece & 4-Piece)
	local bestSetId = ""
	local bestSetCount = 0
	for setId, count in pairs(setCounts) do
		if count > bestSetCount then
			bestSetCount = count
			bestSetId = setId
		end
		if count >= 2 then
			damagePct += 12
		end
		if count >= 4 then
			if setId == "VioletStar" then
				critPct += 8
				hastePct += 10
				wardBonus += 20
			elseif setId == "BoneReaper" then
				bonusHp += 35
				armorBonus += 2
				hastePct += 10
			elseif setId == "AshenPyre" then
				magnetPct += 25
				xpPct += 15
				critPct += 8
			end
		end
	end

	-- 4. Game Passes & Server-Wide Blood Moon Banner
	if profile.passMagnet or profile.starterPackOwned then
		magnetPct += if profile.passMagnet then 50 else 15
	end
	if profile.passFourthCard then
		startingDice += 1
	end

	local soulsMult = 1 + (t.meta_ascension or 0) * 0.03
	-- Order of the Violet Star Reputation passive standing rewards
	if profile.reputation >= 15000 then
		soulsMult *= 1.15
		damagePct += 10
		startingDice += 1
	elseif profile.reputation >= 7000 then
		soulsMult *= 1.10
		damagePct += 6
	elseif profile.reputation >= 3000 then
		soulsMult *= 1.06
		damagePct += 3
	elseif profile.reputation >= 1000 then
		soulsMult *= 1.03
	end
	-- Co-Op Friend Boost (+10% Bonus XP & Souls per friend in server, LOOP-6)
	local friendBoostPct = (player:GetAttribute("FriendBoostPct") :: number?) or 0
	if friendBoostPct > 0 then
		xpPct += friendBoostPct
		soulsMult *= (1 + friendBoostPct / 100)
	end
	if profile.passDoubleSouls then
		soulsMult *= 2
	end
	local keystoneInfo = RpgConfig.getKeystoneInfo(profile.selectedKeystone)
	soulsMult *= keystoneInfo.soulsMult

	if os.clock() < bloodMoonEndsAt then
		soulsMult *= 2
		xpPct += 50
		moveSpeedPct += 12
		hastePct += 12
	end

	local avgIlvl = math.floor(totalIlvl / #RpgConfig.GEAR_SLOTS)
	local setMeta = if bestSetId ~= "" then RpgConfig.ITEM_SETS[bestSetId] else nil

	return {
		bonusHp = math.floor(bonusHp),
		damageMult = 1 + damagePct / 100,
		critBonus = math.clamp(critPct / 100, 0, 0.75),
		cooldownMult = math.max(Constants.MIN_COOLDOWN_MULTIPLIER, 1 - math.min(0.60, hastePct / 100)),
		moveSpeedMult = 1 + moveSpeedPct / 100,
		magnetMult = 1 + magnetPct / 100,
		xpMult = 1 + xpPct / 100,
		luckBonus = luckPct / 100,
		armorBonus = armorBonus,
		wardBonus = wardBonus,
		regenBonus = regenBonus,
		startingDice = startingDice,
		soulsMult = soulsMult,
		avgIlvl = avgIlvl,
		activeSetCount = bestSetCount,
		activeSetName = if setMeta then setMeta.name else "",
	}
end

function DataService.sync(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local bonuses = DataService.computeBonuses(player)
	local title = RpgConfig.getHeroTitle(profile.heroLevel, profile.reputation, profile.highestKeystone)
	local xpToNext = RpgConfig.heroXpForLevel(profile.heroLevel)
	local bloodMoonLeft = math.max(0, math.ceil(bloodMoonEndsAt - os.clock()))

	player:SetAttribute("Souls", profile.souls)
	player:SetAttribute("ArcaneDust", profile.arcaneDust)
	player:SetAttribute("FateDice", profile.fateDice)
	player:SetAttribute("HeroLevel", profile.heroLevel)
	player:SetAttribute("HeroXp", profile.heroXp)
	player:SetAttribute("HeroXpToNext", xpToNext)
	player:SetAttribute("RestedXp", profile.restedXp)
	player:SetAttribute("Reputation", profile.reputation)
	player:SetAttribute("HeroTitle", title)
	player:SetAttribute("AvgIlvl", bonuses.avgIlvl)
	player:SetAttribute("HighestKeystone", profile.highestKeystone)
	player:SetAttribute("SelectedKeystone", profile.selectedKeystone)
	player:SetAttribute("PassFourthCard", profile.passFourthCard)
	player:SetAttribute("BloodMoonRemaining", bloodMoonLeft)
	player:SetAttribute("BloodMoonBuyer", bloodMoonBuyer)

	local payload: RpgConfig.RpgSyncPayload = {
		souls = profile.souls,
		arcaneDust = profile.arcaneDust,
		fateDice = profile.fateDice,
		heroLevel = profile.heroLevel,
		heroXp = profile.heroXp,
		heroXpToNext = xpToNext,
		restedXp = profile.restedXp,
		reputation = profile.reputation,
		title = title,
		avgIlvl = bonuses.avgIlvl,
		activeSetCount = bonuses.activeSetCount,
		activeSetName = bonuses.activeSetName,
		highestKeystone = profile.highestKeystone,
		selectedKeystone = profile.selectedKeystone,
		weeklyRuns = profile.weeklyRuns,
		vaultClaimed = profile.vaultClaimed,
		starterPackOwned = profile.starterPackOwned,
		passMagnet = profile.passMagnet,
		passFourthCard = profile.passFourthCard,
		passDoubleSouls = profile.passDoubleSouls,
		bloodMoonEndsAt = bloodMoonLeft,
		bloodMoonBuyer = bloodMoonBuyer,
		talents = profile.talents,
		slotEnchants = profile.slotEnchants,
		equippedGear = profile.equippedGear,
		bagGear = profile.bagGear,
		weaponMastery = profile.weaponMastery,
		dailyProgress = profile.dailyProgress,
		dailyClaimed = profile.dailyClaimed,
		grimoireCount = countGrimoire(profile),
		grimoire = profile.grimoire,
		lastLootDrop = profile.lastLootDrop,
	}
	rpgSyncRemote:FireClient(player, payload)
end

function DataService.getProfile(player: Player): Profile?
	return profiles[player]
end

function DataService.loadPlayer(player: Player): Profile
	local existing = profiles[player]
	if existing then
		return existing
	end

	local loaded: any = nil
	if store and player.UserId > 0 then
		local ok = false
		for attempt = 1, 3 do
			local callOk, result = pcall(function()
				return (store :: DataStore):GetAsync("User_" .. tostring(player.UserId))
			end)
			if callOk then
				ok = true
				loaded = result
				break
			end
			if attempt < 3 then
				task.wait(0.4 * attempt)
			end
		end
		if not ok then
			loadFailed[player] = true
		end
	end

	local profile = reconcileProfile(loaded)
	profiles[player] = profile
	DataService.sync(player)

	-- Reconcile web/store GamePass ownership on join (MON-2)
	if player.UserId > 0 then
		task.spawn(function()
			local changed = false
			if not profile.passMagnet and Constants.PASS_MAGNET_ID > 0 then
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Constants.PASS_MAGNET_ID)
				end)
				if ok and owns then
					profile.passMagnet = true
					changed = true
				end
			end
			if not profile.passFourthCard and Constants.PASS_FOURTH_CARD_ID > 0 then
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Constants.PASS_FOURTH_CARD_ID)
				end)
				if ok and owns then
					profile.passFourthCard = true
					changed = true
				end
			end
			if not profile.passDoubleSouls and Constants.PASS_DOUBLE_SOULS_ID > 0 then
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Constants.PASS_DOUBLE_SOULS_ID)
				end)
				if ok and owns then
					profile.passDoubleSouls = true
					changed = true
				end
			end
			if changed and profiles[player] == profile then
				DataService.sync(player)
			end
		end)
	end

	return profile
end

function DataService.savePlayer(player: Player)
	local profile = profiles[player]
	if not profile or loadFailed[player] or not store or player.UserId <= 0 then
		return
	end
	local copy = table.clone(profile)
	copy.lastLootDrop = nil
	for attempt = 1, 3 do
		local ok = pcall(function()
			(store :: DataStore):UpdateAsync("User_" .. tostring(player.UserId), function()
				return copy
			end)
		end)
		if ok then
			break
		end
		if attempt < 3 then
			task.wait(0.5 * attempt)
		end
	end
end

function DataService.removePlayer(player: Player)
	DataService.savePlayer(player)
	profiles[player] = nil
	loadFailed[player] = nil
end

function DataService.addLootItem(player: Player, item: GearItem)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.lastLootDrop = item
	local currentEquipped = profile.equippedGear[item.slot]
	if not currentEquipped then
		profile.equippedGear[item.slot] = item
	elseif #profile.bagGear < MAX_BAG_ITEMS then
		table.insert(profile.bagGear, 1, item)
	else
		local rInfo = RpgConfig.RARITY_INFO[item.rarity] or RpgConfig.RARITY_INFO[1]
		profile.arcaneDust += rInfo.dustValue
	end
	DataService.sync(player)
end

function DataService.recordDiscovery(player: Player, key: string): number
	local profile = profiles[player]
	if not profile or profile.grimoire[key] then
		return 0
	end
	profile.grimoire[key] = true
	profile.souls += 15
	profile.reputation += 40
	for _, entry in RpgConfig.GRIMOIRE_ENTRIES do
		if entry.id == key then
			player:SetAttribute(
				"FieldEventBanner",
				string.format(
					"📖 GRIMOIRE DISCOVERED: %s %s! +15 Souls & Permanent +0.5%% DMG! (%d)",
					entry.icon,
					entry.name,
					math.floor(os.clock() * 10)
				)
			)
			break
		end
	end
	DataService.sync(player)
	return 15
end

function DataService.recordRunCompleted(
	player: Player,
	kills: number,
	survivedSeconds: number,
	runLevel: number,
	weaponId: string,
	bossDefeated: boolean
): (number, number, GearItem?)
	local profile = profiles[player]
	if not profile then
		return 0, 0, nil
	end

	local bonuses = DataService.computeBonuses(player)
	profile.totalRuns += 1
	profile.weeklyRuns += 1
	profile.bestTime = math.max(profile.bestTime, survivedSeconds)
	profile.bestKills = math.max(profile.bestKills, kills)

	-- First-run onboarding bonus so Run 1 always affords an Altar talent
	local firstRunBonus = if profile.totalRuns == 1 then 45 else 0
	local bossBonus = if bossDefeated then 150 else 0
	local restedSoulsBonus = if profile.restedXp > 0 then 1.25 else 1.0
	local baseSouls = math.max(5, math.floor(kills + survivedSeconds * 0.30)) + firstRunBonus + bossBonus
	local earnedSouls = math.floor(baseSouls * bonuses.soulsMult * restedSoulsBonus)
	profile.souls += earnedSouls

	-- Hero XP + Rested XP consumption
	local rawHeroXp =
		math.floor((20 + kills * 1.4 + survivedSeconds * 0.45 + (if bossDefeated then 120 else 0)) * bonuses.xpMult)
	local restedUsed = math.min(profile.restedXp, rawHeroXp)
	profile.restedXp -= restedUsed
	local totalHeroXpGained = rawHeroXp + restedUsed
	profile.heroXp += totalHeroXpGained

	local needed = RpgConfig.heroXpForLevel(profile.heroLevel)
	while profile.heroXp >= needed do
		profile.heroXp -= needed
		profile.heroLevel += 1
		profile.fateDice += 1
		needed = RpgConfig.heroXpForLevel(profile.heroLevel)
	end

	-- Reputation & Weapon Artifact Mastery
	profile.reputation += math.floor(35 + kills * 0.8 + (if bossDefeated then 250 else 0))
	local currentMastery = profile.weaponMastery[weaponId] or 1
	if kills >= 15 or survivedSeconds >= 45 then
		profile.weaponMastery[weaponId] = math.min(20, currentMastery + 1)
	end

	-- Unlock next Mythic+ Keystone on Stage Boss clear (or surviving 3+ mins on Normal)
	if bossDefeated or survivedSeconds >= 180 then
		if profile.selectedKeystone >= profile.highestKeystone and profile.highestKeystone < 15 then
			profile.highestKeystone += 1
		end
	end

	-- Daily Emissary Quests Progress
	profile.dailyProgress.slay_undead = (profile.dailyProgress.slay_undead or 0) + kills
	profile.dailyProgress.survive_time = (profile.dailyProgress.survive_time or 0) + survivedSeconds
	profile.dailyProgress.reach_level = math.max(profile.dailyProgress.reach_level or 0, runLevel)

	-- Guaranteed End-of-Run Loot Drop (higher rarity for longer survival / boss kills)
	local minRarity = 2
	if bossDefeated or survivedSeconds >= 300 then
		minRarity = 4
	elseif survivedSeconds >= 120 or kills >= 40 then
		minRarity = 3
	end
	local droppedItem =
		RpgConfig.rollGearItem(rng, profile.heroLevel, profile.selectedKeystone, minRarity, bonuses.luckBonus, nil)
	DataService.addLootItem(player, droppedItem)

	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Souls",
			earnedSouls,
			profile.souls,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
			"EndOfRunHarvest"
		)
	end)

	DataService.sync(player)
	return earnedSouls, totalHeroXpGained, droppedItem
end

-- ============================================================================
-- SANCTUARY ALTAR TALENT TREE ACTIONS
-- ============================================================================
function DataService.buyTalent(player: Player, talentId: string): boolean
	local profile = profiles[player]
	local node = RpgConfig.TALENT_BY_ID[talentId]
	if not profile or not node then
		return false
	end
	local currentRank = profile.talents[talentId] or 0
	if currentRank >= node.maxRank then
		return false
	end
	local totalPoints = DataService.getTotalTalentPoints(profile)
	if totalPoints < node.reqPoints then
		return false
	end
	local cost = node.costs[currentRank + 1] or 999999
	if profile.souls < cost then
		return false
	end

	profile.souls -= cost
	profile.talents[talentId] = currentRank + 1
	DataService.sync(player)
	return true
end

function DataService.respecTalents(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local refund = 0
	for talentId, rank in pairs(profile.talents) do
		local node = RpgConfig.TALENT_BY_ID[talentId]
		if node then
			for r = 1, rank do
				refund += node.costs[r] or 0
			end
		end
	end
	if refund <= 0 then
		return false
	end
	table.clear(profile.talents)
	profile.souls += refund
	DataService.sync(player)
	return true
end

-- ============================================================================
-- 6-SLOT ARMORY, DISENCHANTING & ENCHANTING FORGE ACTIONS
-- ============================================================================
function DataService.equipBagItem(player: Player, uid: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	for idx, item in ipairs(profile.bagGear) do
		if item.uid == uid then
			local prev = profile.equippedGear[item.slot]
			profile.equippedGear[item.slot] = item
			table.remove(profile.bagGear, idx)
			if prev then
				table.insert(profile.bagGear, idx, prev)
			end
			DataService.sync(player)
			return true
		end
	end
	return false
end

function DataService.disenchantBagItem(player: Player, uid: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	for idx, item in ipairs(profile.bagGear) do
		if item.uid == uid then
			table.remove(profile.bagGear, idx)
			local rInfo = RpgConfig.RARITY_INFO[item.rarity] or RpgConfig.RARITY_INFO[1]
			profile.arcaneDust += rInfo.dustValue + math.floor(item.ilvl * 0.2)
			DataService.sync(player)
			return true
		end
	end
	return false
end

function DataService.disenchantAllBag(player: Player): boolean
	local profile = profiles[player]
	if not profile or #profile.bagGear == 0 then
		return false
	end
	for _, item in ipairs(profile.bagGear) do
		local rInfo = RpgConfig.RARITY_INFO[item.rarity] or RpgConfig.RARITY_INFO[1]
		profile.arcaneDust += rInfo.dustValue + math.floor(item.ilvl * 0.2)
	end
	table.clear(profile.bagGear)
	DataService.sync(player)
	return true
end

function DataService.enchantSlot(player: Player, slot: string): boolean
	local profile = profiles[player]
	if not profile or profile.slotEnchants[slot] == nil then
		return false
	end
	local current = profile.slotEnchants[slot] or 0
	if current >= MAX_ENCHANT_LEVEL then
		return false
	end
	local costSouls, costDust = RpgConfig.getEnchantCost(current)
	if profile.souls < costSouls or profile.arcaneDust < costDust then
		return false
	end
	profile.souls -= costSouls
	profile.arcaneDust -= costDust
	profile.slotEnchants[slot] = current + 1
	DataService.sync(player)
	return true
end

-- ============================================================================
-- KEYSTONES, DAILY EMISSARY QUESTS & WEEKLY GREAT VAULT
-- ============================================================================
function DataService.setKeystone(player: Player, level: number): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local clamped = math.clamp(math.floor(level), 0, profile.highestKeystone)
	profile.selectedKeystone = clamped
	DataService.sync(player)
	return true
end

function DataService.claimDailyQuest(player: Player, questId: string): boolean
	local profile = profiles[player]
	if not profile or profile.dailyClaimed[questId] then
		return false
	end
	for _, def in RpgConfig.DAILY_QUESTS do
		if def.id == questId then
			local prog = profile.dailyProgress[questId] or 0
			if prog < def.target then
				return false
			end
			profile.dailyClaimed[questId] = true
			local mult = if profile.passDoubleSouls then 2 else 1
			profile.souls += def.rewardSouls * mult
			profile.arcaneDust += def.rewardDust * mult
			profile.reputation += def.rewardRep * mult
			profile.fateDice += def.rewardDice
			DataService.sync(player)
			return true
		end
	end
	return false
end

function DataService.claimGreatVault(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.vaultClaimed or profile.weeklyRuns < 1 then
		return false
	end
	profile.vaultClaimed = true
	local minRarity = if profile.weeklyRuns >= 4 then 5 else 4
	local vaultItem = RpgConfig.rollGearItem(rng, profile.heroLevel + 2, profile.highestKeystone, minRarity, 0.5, nil)
	profile.souls += 150
	DataService.addLootItem(player, vaultItem)
	return true
end

-- ============================================================================
-- MONETIZATION GRANTS (STARTER PACK, GAME PASSES, BLOOD MOON BANNER)
-- ============================================================================
function DataService.grantStarterPack(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.starterPackOwned then
		return false
	end
	profile.starterPackOwned = true
	profile.souls += 500
	profile.arcaneDust += 50
	profile.fateDice += 5
	profile.restedXp = math.floor(RpgConfig.heroXpForLevel(profile.heroLevel) * 1.5)
	local heirloom = RpgConfig.makeHeirloomTrinket(profile.heroLevel)
	DataService.addLootItem(player, heirloom)
	DataService.sync(player)
	return true
end

function DataService.grantGamePass(player: Player, passKey: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	if passKey == "Magnet" then
		profile.passMagnet = true
	elseif passKey == "FourthCard" then
		profile.passFourthCard = true
		profile.fateDice += 2
	elseif passKey == "DoubleSouls" then
		profile.passDoubleSouls = true
		profile.souls += 200
	else
		return false
	end
	DataService.sync(player)
	return true
end

function DataService.activateBloodMoonBanner(buyer: Player)
	bloodMoonEndsAt = math.max(os.clock(), bloodMoonEndsAt) + 900 -- 15 minutes
	bloodMoonBuyer = buyer.DisplayName
	local profile = profiles[buyer]
	if profile then
		profile.souls += 150
		profile.reputation += 300
	end
	for _, p in Players:GetPlayers() do
		DataService.sync(p)
	end
end

function DataService.init()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				DataService.savePlayer(player)
			end
		end
	end)

	if not RunService:IsStudio() then
		game:BindToClose(function()
			for _, player in Players:GetPlayers() do
				task.spawn(function()
					DataService.savePlayer(player)
				end)
			end
			task.wait(2)
		end)
	end
end

return DataService
