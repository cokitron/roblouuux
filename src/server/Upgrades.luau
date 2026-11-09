--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerTypes = require(script.Parent.ServerTypes)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

type State = ServerTypes.State
type OfferSlot = ServerTypes.OfferSlot

-- values[tier] is the strength of one rank at that rarity (Common, Rare, Elite, Legendary). Every pick is
-- one rank whatever its rarity, so a Legendary rank is worth more but does not raise maxLevel.
type Definition = {
	id: string,
	tree: string, -- "ArcanistStaff" | "CryptCleaver" | "SoulflameLantern" | "Universal"
	name: string,
	icon: string,
	flavor: string,
	maxLevel: number,
	values: { number },
	describe: (value: number, tier: number) -> string,
	apply: (state: State, value: number, tier: number) -> (),
	requires: ((state: State) -> boolean)?,
}

-- Rarity weights per card (Common, Rare, Elite, Legendary). Server-only (SEC-7); Fortune scales the
-- three non-Common weights by (1 + luck).
local TIER_WEIGHTS = { 68, 22, 8, 2 }

local function percent(value: number): string
	return string.format("%d%%", math.floor(value * 100 + 0.5))
end

local DEFINITIONS: { Definition } = {
	-- =========================================================================
	-- 1. ARCANIST'S STAFF TALENT TREE (Magic Bolt + Guardian Orb)
	-- =========================================================================
	-- Branch A: Primary Attack Mastery (Magic Bolt)
	{
		id = "bolt_damage",
		tree = "ArcanistStaff",
		name = "Sharper Magic",
		icon = "🗡️",
		flavor = "The blade remembers every wound.",
		maxLevel = 5,
		values = { 0.25, 0.45, 0.70, 1.0 },
		describe = function(value)
			return "+" .. percent(value) .. " bolt damage"
		end,
		apply = function(state, value)
			state.damageMultiplier += value
		end,
	},
	{
		id = "bolt_cooldown",
		tree = "ArcanistStaff",
		name = "Quickcast",
		icon = "⚡",
		flavor = "Words of power, spoken faster.",
		maxLevel = 5,
		values = { 0.12, 0.18, 0.25, 0.35 },
		describe = function(value)
			return "-" .. percent(value) .. " bolt cooldown"
		end,
		apply = function(state, value)
			state.cooldownMultiplier =
				math.max(state.cooldownMultiplier * (1 - value), Constants.MIN_COOLDOWN_MULTIPLIER)
		end,
	},
	{
		id = "bolt_count",
		tree = "ArcanistStaff",
		name = "Extra Bolt",
		icon = "✨",
		flavor = "Why cast once when the night is long?",
		maxLevel = 3,
		values = { 1, 1, 2, 2 },
		describe = function(value, tier)
			local text = string.format("+%d bolt%s per volley", value, if value > 1 then "s" else "")
			if tier == 2 then
				text ..= ", +10% damage"
			elseif tier == 4 then
				text ..= ", +1 pierce"
			end
			return text
		end,
		apply = function(state, value, tier)
			state.boltCount += value
			if tier == 2 then
				state.damageMultiplier += 0.10
			elseif tier == 4 then
				state.boltPierce += 1
			end
		end,
	},
	{
		id = "bolt_pierce",
		tree = "ArcanistStaff",
		name = "Piercing Bolts",
		icon = "🏹",
		flavor = "Bone, bark and shadow alike.",
		maxLevel = 3,
		values = { 1, 2, 3, 4 },
		describe = function(value)
			return string.format("Bolts pass through %d more %s", value, if value > 1 then "enemies" else "enemy")
		end,
		apply = function(state, value)
			state.boltPierce += value
		end,
		requires = function(state)
			return (state.upgrades["bolt_damage"] or 0) >= 1
		end,
	},
	{
		id = "bolt_reach",
		tree = "ArcanistStaff",
		name = "Arcane Velocity",
		icon = "🎯",
		flavor = "Further than the lantern light.",
		maxLevel = 4,
		values = { 0.15, 0.25, 0.40, 0.60 },
		describe = function(value)
			return "+" .. percent(value) .. " bolt speed and range"
		end,
		apply = function(state, value)
			state.boltSpeedMultiplier += value
		end,
	},
	{
		id = "bolt_crit",
		tree = "ArcanistStaff",
		name = "Keen Focus",
		icon = "💥",
		flavor = "Find the crack. Strike it.",
		maxLevel = 4,
		values = { 0.06, 0.10, 0.15, 0.22 },
		describe = function(value)
			return "+" .. percent(value) .. " chance to deal double damage"
		end,
		apply = function(state, value)
			state.critChance += value
		end,
	},

	-- Branch B: Aura Augmentation (Guardian Orb)
	{
		id = "orb_count",
		tree = "ArcanistStaff",
		name = "Celestial Moons",
		icon = "🔮",
		flavor = "Little moons that bite.",
		maxLevel = 4,
		values = { 1, 1, 2, 2 },
		describe = function(value, tier)
			local text = string.format("+%d orb%s circle you", value, if value > 1 then "s" else "")
			if tier == 2 or tier == 4 then
				text ..= ", +25% orb damage"
			end
			return text
		end,
		apply = function(state, value, tier)
			state.orbCount += value
			if tier == 2 or tier == 4 then
				state.orbDamageMultiplier += 0.25
			end
		end,
	},
	{
		id = "orb_power",
		tree = "ArcanistStaff",
		name = "Empowered Astrolabe",
		icon = "☄️",
		flavor = "Each moon carries a grudge.",
		maxLevel = 5,
		values = { 0.30, 0.50, 0.75, 1.10 },
		describe = function(value)
			return "+" .. percent(value) .. " orb damage"
		end,
		apply = function(state, value)
			state.orbDamageMultiplier += value
		end,
		requires = function(state)
			return state.orbCount > 0
		end,
	},
	{
		id = "orb_orbit",
		tree = "ArcanistStaff",
		name = "Cosmic Drift",
		icon = "🌀",
		flavor = "The circle widens. The circle quickens.",
		maxLevel = 4,
		values = { 0.15, 0.25, 0.40, 0.60 },
		describe = function(value)
			return "Orbs circle " .. percent(value) .. " wider and faster"
		end,
		apply = function(state, value)
			state.orbRadiusMultiplier += value
			state.orbSpeedMultiplier += value
		end,
		requires = function(state)
			return state.orbCount > 0
		end,
	},
	{
		id = "orb_resonance",
		tree = "ArcanistStaff",
		name = "Planetary Harmonic",
		icon = "💫",
		flavor = "When the spheres align, the earth trembles.",
		maxLevel = 3,
		values = { 4, 8, 14, 22 },
		describe = function(value)
			return string.format("Orb hits emit a resonant pulse for %d AoE damage", value)
		end,
		apply = function(state, value)
			state.orbResonanceDamage += value
		end,
		requires = function(state)
			return state.orbCount >= 2
		end,
	},

	-- Branch C: Arcanist Thematic Defense & Survivability
	{
		id = "arcane_ward",
		tree = "ArcanistStaff",
		name = "Aether Barrier",
		icon = "🛡️",
		flavor = "Woven from unspent starlight.",
		maxLevel = 4,
		values = { 15, 25, 40, 65 },
		describe = function(value)
			return string.format("+%d regenerating shield points", value)
		end,
		apply = function(state, value)
			state.arcaneWardMax += value
			state.arcaneWardCurrent = state.arcaneWardMax
		end,
	},
	{
		id = "arcane_drift",
		tree = "ArcanistStaff",
		name = "Fleet Step",
		icon = "👢",
		flavor = "The forest floor forgets your steps.",
		maxLevel = 4,
		values = { 0.10, 0.16, 0.22, 0.32 },
		describe = function(value)
			return "+" .. percent(value) .. " move speed"
		end,
		apply = function(state, value)
			state.moveSpeedMultiplier += value
		end,
	},
	{
		id = "arcane_regen",
		tree = "ArcanistStaff",
		name = "Mystic Renewal",
		icon = "🌿",
		flavor = "Mana recirculates, closing every tear.",
		maxLevel = 4,
		values = { 0.6, 1.0, 1.6, 2.5 },
		describe = function(value)
			return string.format("+%.1f health per second", value)
		end,
		apply = function(state, value)
			state.regenPerSecond += value
		end,
	},
	{
		id = "arcane_deflect",
		tree = "ArcanistStaff",
		name = "Phase Armor",
		icon = "💎",
		flavor = "Displace kinetic impact across dimensions.",
		maxLevel = 3,
		values = { 1, 2, 3, 5 },
		describe = function(value)
			return string.format("Take %d less damage per hit", value)
		end,
		apply = function(state, value)
			state.armor += value
		end,
		requires = function(state)
			return state.arcaneWardMax > 0
		end,
	},

	-- =========================================================================
	-- 2. CRYPT CLEAVER TALENT TREE (Reaper's Cleave + Bone Whirlwind)
	-- =========================================================================
	-- Branch A: Primary Attack Mastery (Reaper's Cleave)
	{
		id = "cleave_damage",
		tree = "CryptCleaver",
		name = "Heavy Edge",
		icon = "🪓",
		flavor = "Weight behind the swing, iron meeting bone.",
		maxLevel = 5,
		values = { 0.25, 0.45, 0.70, 1.0 },
		describe = function(value)
			return "+" .. percent(value) .. " cleave damage"
		end,
		apply = function(state, value)
			state.cleaveDamageMultiplier += value
		end,
	},
	{
		id = "cleave_speed",
		tree = "CryptCleaver",
		name = "Blood Haste",
		icon = "🩸",
		flavor = "The blade hungers faster with every strike.",
		maxLevel = 5,
		values = { 0.12, 0.18, 0.25, 0.35 },
		describe = function(value)
			return "-" .. percent(value) .. " cleave cooldown"
		end,
		apply = function(state, value)
			state.cleaveCooldownMultiplier =
				math.max(state.cleaveCooldownMultiplier * (1 - value), Constants.MIN_COOLDOWN_MULTIPLIER)
		end,
	},
	{
		id = "cleave_arc",
		tree = "CryptCleaver",
		name = "Wide Sweep",
		icon = "🌪️",
		flavor = "Reap the whole row in one pass.",
		maxLevel = 4,
		values = { 15, 25, 40, 60 },
		describe = function(value, tier)
			local reach = if tier == 1 then 2 elseif tier == 2 then 4 elseif tier == 3 then 6 else 9
			return string.format("+%d° cleave arc and +%d reach", value, reach)
		end,
		apply = function(state, value, tier)
			state.cleaveArcBonus += value
			local reach = if tier == 1 then 2 elseif tier == 2 then 4 elseif tier == 3 then 6 else 9
			state.cleaveReachBonus += reach
		end,
	},
	{
		id = "cleave_rend",
		tree = "CryptCleaver",
		name = "Sundering Blow",
		icon = "⚔️",
		flavor = "Split shield, split breastplate, split spine.",
		maxLevel = 3,
		values = { 2, 3, 5, 7 },
		describe = function(value)
			return string.format("Cleave hits %d more enemies per swing", value)
		end,
		apply = function(state, value)
			state.cleavePierce += value
		end,
		requires = function(state)
			return (state.upgrades["cleave_damage"] or 0) >= 1
		end,
	},
	{
		id = "cleave_execute",
		tree = "CryptCleaver",
		name = "Grim Decapitation",
		icon = "💀",
		flavor = "The wounded shall not linger.",
		maxLevel = 3,
		values = { 0.15, 0.25, 0.35, 0.50 },
		describe = function(value)
			return "Instantly execute enemies below " .. percent(value) .. " health"
		end,
		apply = function(state, value)
			state.cleaveExecuteThreshold = math.max(state.cleaveExecuteThreshold, value)
		end,
	},

	-- Branch B: Aura Augmentation (Bone Whirlwind)
	{
		id = "bone_count",
		tree = "CryptCleaver",
		name = "Ossuary Spiral",
		icon = "🦴",
		flavor = "More fragments rise from the dust.",
		maxLevel = 4,
		values = { 1, 1, 2, 2 },
		describe = function(value, tier)
			local text = string.format("+%d bone shard%s in whirlwind", value, if value > 1 then "s" else "")
			if tier == 2 or tier == 4 then
				text ..= ", +20% damage"
			end
			return text
		end,
		apply = function(state, value, tier)
			state.boneCount += value
			if tier == 2 or tier == 4 then
				state.boneDamageMultiplier += 0.20
			end
		end,
	},
	{
		id = "bone_damage",
		tree = "CryptCleaver",
		name = "Serrated Ribs",
		icon = "🗡️",
		flavor = "Honed to razor points.",
		maxLevel = 5,
		values = { 0.30, 0.50, 0.75, 1.10 },
		describe = function(value)
			return "+" .. percent(value) .. " bone whirlwind damage"
		end,
		apply = function(state, value)
			state.boneDamageMultiplier += value
		end,
		requires = function(state)
			return state.boneCount > 0
		end,
	},
	{
		id = "bone_repulsion",
		tree = "CryptCleaver",
		name = "Gravewarden's Thrust",
		icon = "🛡️",
		flavor = "Back to your graves!",
		maxLevel = 3,
		values = { 0.40, 0.70, 1.10, 1.60 },
		describe = function(value)
			return "+" .. percent(value) .. " bone knockback force"
		end,
		apply = function(state, value)
			state.boneKnockbackMultiplier += value
		end,
		requires = function(state)
			return state.boneCount > 0
		end,
	},
	{
		id = "bone_shatter",
		tree = "CryptCleaver",
		name = "Grave Burst",
		icon = "💥",
		flavor = "Their own remains turn against them.",
		maxLevel = 3,
		values = { 12, 20, 32, 50 },
		describe = function(value)
			return string.format("Enemies killed in whirlwind explode for %d AoE damage", value)
		end,
		apply = function(state, value)
			state.boneShatterDamage += value
		end,
		requires = function(state)
			return state.boneCount >= 2
		end,
	},

	-- Branch C: Cleaver Thematic Defense & Survivability
	{
		id = "cleaver_armor",
		tree = "CryptCleaver",
		name = "Ossuary Plating",
		icon = "🛡️",
		flavor = "Borrowed from those who fell before.",
		maxLevel = 5,
		values = { 1, 2, 4, 6 },
		describe = function(value)
			return string.format("Take %d less damage per hit", value)
		end,
		apply = function(state, value)
			state.armor += value
		end,
	},
	{
		id = "cleaver_vampirism",
		tree = "CryptCleaver",
		name = "Marrow Feast",
		icon = "🦇",
		flavor = "The night feeds those who hunt it.",
		maxLevel = 4,
		values = { 0.04, 0.07, 0.11, 0.16 },
		describe = function(value, tier)
			local amount = if tier == 1 then 4 elseif tier == 2 then 5 elseif tier == 3 then 7 else 10
			return "+" .. percent(value) .. string.format(" chance to heal %d on kill", amount)
		end,
		apply = function(state, value, tier)
			state.lifestealChance += value
			local amount = if tier == 1 then 4 elseif tier == 2 then 5 elseif tier == 3 then 7 else 10
			state.lifestealAmount = math.max(state.lifestealAmount, amount)
		end,
	},
	{
		id = "cleaver_thorns",
		tree = "CryptCleaver",
		name = "Barbed Carapace",
		icon = "🥀",
		flavor = "Touch the scythe, pay the price.",
		maxLevel = 4,
		values = { 8, 15, 26, 42 },
		describe = function(value)
			return string.format("Enemies that hit you take %d damage", value)
		end,
		apply = function(state, value)
			state.thorns += value
		end,
	},
	{
		id = "cleaver_vitality",
		tree = "CryptCleaver",
		name = "Colossus Frame",
		icon = "❤️",
		flavor = "A heart too stubborn to stop.",
		maxLevel = 4,
		values = { 30, 55, 85, 130 },
		describe = function(value)
			return string.format("+%d max health", value)
		end,
		apply = function(state, value)
			state.maxHealth += value
			state.health = math.min(state.maxHealth, state.health + value)
		end,
	},

	-- =========================================================================
	-- 3. SOULFLAME LANTERN TALENT TREE (Spirit Cinders + Consecrated Ground)
	-- =========================================================================
	-- Branch A: Primary Attack Mastery (Spirit Cinders)
	{
		id = "cinder_damage",
		tree = "SoulflameLantern",
		name = "Ghostfire Intensity",
		icon = "🔥",
		flavor = "Green flames that burn down to the soul.",
		maxLevel = 5,
		values = { 0.25, 0.45, 0.70, 1.0 },
		describe = function(value)
			return "+" .. percent(value) .. " cinder and burn pool damage"
		end,
		apply = function(state, value)
			state.cinderDamageMultiplier += value
		end,
	},
	{
		id = "cinder_cooldown",
		tree = "SoulflameLantern",
		name = "Stoked Hearth",
		icon = "⚡",
		flavor = "The ember never sleeps.",
		maxLevel = 5,
		values = { 0.12, 0.18, 0.25, 0.35 },
		describe = function(value)
			return "-" .. percent(value) .. " cinder throw cooldown"
		end,
		apply = function(state, value)
			state.cinderCooldownMultiplier =
				math.max(state.cinderCooldownMultiplier * (1 - value), Constants.MIN_COOLDOWN_MULTIPLIER)
		end,
	},
	{
		id = "cinder_cluster",
		tree = "SoulflameLantern",
		name = "Multi-Censer",
		icon = "🏮",
		flavor = "Scatter the cinders across the whole yard.",
		maxLevel = 3,
		values = { 1, 1, 2, 2 },
		describe = function(value)
			return string.format("Hurls +%d additional cinder cluster%s", value, if value > 1 then "s" else "")
		end,
		apply = function(state, value)
			state.cinderClusterCount += value
		end,
	},
	{
		id = "cinder_pool",
		tree = "SoulflameLantern",
		name = "Lingering Pyre",
		icon = "🔥",
		flavor = "Ghostly fire that clings to the dry earth.",
		maxLevel = 4,
		values = { 0.30, 0.50, 0.80, 1.20 },
		describe = function(value, tier)
			local dur = if tier == 1 then 0.5 elseif tier == 2 then 1.0 elseif tier == 3 then 1.5 else 2.2
			return "+" .. percent(value) .. string.format(" pool area and +%.1fs duration", dur)
		end,
		apply = function(state, value, tier)
			state.cinderSplashMultiplier += value
			local dur = if tier == 1 then 0.5 elseif tier == 2 then 1.0 elseif tier == 3 then 1.5 else 2.2
			state.cinderDurationBonus += dur
		end,
	},
	{
		id = "cinder_incinerate",
		tree = "SoulflameLantern",
		name = "Spreading Inferno",
		icon = "☄️",
		flavor = "One spark sets the cemetery alight.",
		maxLevel = 3,
		values = { 4, 6, 8, 12 },
		describe = function(value)
			return string.format("Burning foes ignite others within %d studs", value)
		end,
		apply = function(state, value)
			state.cinderIncinerateRadius = math.max(state.cinderIncinerateRadius, value)
		end,
		requires = function(state)
			return (state.upgrades["cinder_damage"] or 0) >= 1
		end,
	},

	-- Branch B: Aura Augmentation (Consecrated Ground)
	{
		id = "hallowed_radius",
		tree = "SoulflameLantern",
		name = "Sacred Boundary",
		icon = "⭕",
		flavor = "Expand the perimeter of holy soil.",
		maxLevel = 4,
		values = { 0.20, 0.35, 0.55, 0.80 },
		describe = function(value)
			return "+" .. percent(value) .. " consecrated ground radius"
		end,
		apply = function(state, value)
			state.consecratedRadius *= 1 + value
		end,
	},
	{
		id = "hallowed_damage",
		tree = "SoulflameLantern",
		name = "Cleansing Flame",
		icon = "✨",
		flavor = "No corruption may walk here unpunished.",
		maxLevel = 5,
		values = { 0.30, 0.50, 0.75, 1.10 },
		describe = function(value)
			return "+" .. percent(value) .. " consecrated ground tick damage"
		end,
		apply = function(state, value)
			state.consecratedDamageMultiplier += value
		end,
	},
	{
		id = "hallowed_sloth",
		tree = "SoulflameLantern",
		name = "Binding Rites",
		icon = "⛓️",
		flavor = "Their feet sink into sanctified clay.",
		maxLevel = 4,
		values = { 0.08, 0.16, 0.26, 0.38 },
		describe = function(value)
			return "+" .. percent(value) .. " additional enemy movement slow"
		end,
		apply = function(state, value)
			state.consecratedSlowMultiplier = math.min(0.65, state.consecratedSlowMultiplier + value)
		end,
	},
	{
		id = "hallowed_pyre",
		tree = "SoulflameLantern",
		name = "Judgment Sigil",
		icon = "⚡",
		flavor = "A sudden flash of celestial wrath.",
		maxLevel = 3,
		values = { 20, 35, 60, 95 },
		describe = function(value)
			return string.format("Every 4s, the sacred circle pulses for %d AoE damage", value)
		end,
		apply = function(state, value)
			state.hallowedPyreDamage += value
		end,
		requires = function(state)
			return (state.upgrades["hallowed_radius"] or 0) >= 1
		end,
	},

	-- Branch C: Lantern Thematic Defense & Survivability
	{
		id = "lantern_resilience",
		tree = "SoulflameLantern",
		name = "Iron Will",
		icon = "🛡️",
		flavor = "Faith is sturdier than iron.",
		maxLevel = 4,
		values = { 25, 45, 75, 115 },
		describe = function(value, tier)
			local arm = if tier == 1 then 1 elseif tier == 2 then 2 elseif tier == 3 then 3 else 4
			return string.format("+%d max health and +%d armor", value, arm)
		end,
		apply = function(state, value, tier)
			state.maxHealth += value
			state.health = math.min(state.maxHealth, state.health + value)
			local arm = if tier == 1 then 1 elseif tier == 2 then 2 elseif tier == 3 then 3 else 4
			state.armor += arm
		end,
	},
	{
		id = "lantern_soothe",
		tree = "SoulflameLantern",
		name = "Sanctuary Mending",
		icon = "🌿",
		flavor = "The holy ground restores your spirit.",
		maxLevel = 4,
		values = { 0.8, 1.4, 2.2, 3.4 },
		describe = function(value)
			return string.format("+%.1f health per second in consecrated ground", value)
		end,
		apply = function(state, value)
			state.regenPerSecond += value
		end,
	},
	{
		id = "lantern_magnet",
		tree = "SoulflameLantern",
		name = "Soul Beacon",
		icon = "🧲",
		flavor = "Spirits drawn to the light like moths.",
		maxLevel = 4,
		values = { 0.40, 0.65, 1.0, 1.50 },
		describe = function(value)
			return "+" .. percent(value) .. " XP and soul pickup radius"
		end,
		apply = function(state, value)
			state.pickupRadius *= 1 + value
		end,
	},
	{
		id = "lantern_purge",
		tree = "SoulflameLantern",
		name = "Retributive Flare",
		icon = "💥",
		flavor = "Strike the lantern, taste the flame.",
		maxLevel = 3,
		values = { 15, 28, 45, 70 },
		describe = function(value)
			return string.format("Taking damage triggers a flash burst for %d damage", value)
		end,
		apply = function(state, value)
			state.retributiveFlareDamage += value
		end,
	},

	-- =========================================================================
	-- 4. PHANTOM LONGBOW TALENT TREE (Spectral Arrow Volley)
	-- =========================================================================
	{
		id = "bow_damage",
		tree = "PhantomBow",
		name = "Nightshade Draw",
		icon = "🏹",
		flavor = "Draw the string to the ear; let the banshee sing.",
		maxLevel = 5,
		values = { 0.25, 0.45, 0.70, 1.0 },
		describe = function(value)
			return "+" .. percent(value) .. " spectral arrow damage"
		end,
		apply = function(state, value)
			state.bowDamageMultiplier += value
		end,
	},
	{
		id = "bow_speed",
		tree = "PhantomBow",
		name = "Windrunner's Cadence",
		icon = "🌪️",
		flavor = "Nock and loose before the previous shaft lands.",
		maxLevel = 5,
		values = { 0.12, 0.18, 0.25, 0.35 },
		describe = function(value)
			return "-" .. percent(value) .. " bow volley cooldown"
		end,
		apply = function(state, value)
			state.bowCooldownMultiplier =
				math.max(state.bowCooldownMultiplier * (1 - value), Constants.MIN_COOLDOWN_MULTIPLIER)
		end,
	},
	{
		id = "bow_multishot",
		tree = "PhantomBow",
		name = "Split-String Volley",
		icon = "✨",
		flavor = "One draw, a fan of ghostly shafts.",
		maxLevel = 4,
		values = { 1, 1, 2, 2 },
		describe = function(value, tier)
			local text = string.format("+%d arrow%s per volley", value, if value > 1 then "s" else "")
			if tier >= 3 then
				text ..= ", +6% crit chance"
			end
			return text
		end,
		apply = function(state, value, tier)
			state.bowCount += value
			if tier >= 3 then
				state.critChance += 0.06
			end
		end,
	},
	{
		id = "bow_pierce",
		tree = "PhantomBow",
		name = "Bodkin Broadheads",
		icon = "🗡️",
		flavor = "Forged to skewer an entire column of undead.",
		maxLevel = 3,
		values = { 1, 2, 3, 4 },
		describe = function(value)
			return string.format("Arrows pierce +%d more foes and +5%% crit chance", value)
		end,
		apply = function(state, value)
			state.bowPierce += value
			state.critChance += 0.05
		end,
	},

	-- =========================================================================
	-- 5. HEXLOCK PISTOLS TALENT TREE (Twin Silver Bullets)
	-- =========================================================================
	{
		id = "pistol_damage",
		tree = "HexlockPistols",
		name = "Blessed Silver Rounds",
		icon = "🔫",
		flavor = "Etched with inquisitor sigils that sear undead flesh.",
		maxLevel = 5,
		values = { 0.25, 0.45, 0.70, 1.0 },
		describe = function(value)
			return "+" .. percent(value) .. " silver bullet damage"
		end,
		apply = function(state, value)
			state.pistolDamageMultiplier += value
		end,
	},
	{
		id = "pistol_haste",
		tree = "HexlockPistols",
		name = "Hair-Trigger Cylinder",
		icon = "⚡",
		flavor = "Fan the hammer until the barrels glow white-hot.",
		maxLevel = 5,
		values = { 0.12, 0.18, 0.25, 0.35 },
		describe = function(value)
			return "-" .. percent(value) .. " pistol fire cooldown"
		end,
		apply = function(state, value)
			state.pistolCooldownMultiplier =
				math.max(state.pistolCooldownMultiplier * (1 - value), Constants.MIN_COOLDOWN_MULTIPLIER)
		end,
	},
	{
		id = "pistol_salvo",
		tree = "HexlockPistols",
		name = "Gunslinger's Salvo",
		icon = "💥",
		flavor = "More barrels, more lead in the air.",
		maxLevel = 4,
		values = { 1, 1, 2, 2 },
		describe = function(value)
			return string.format("Fires +%d additional silver bullet%s per burst", value, if value > 1 then "s" else "")
		end,
		apply = function(state, value)
			state.pistolCount += value
		end,
	},
	{
		id = "pistol_ricochet",
		tree = "HexlockPistols",
		name = "Silver Ricochet",
		icon = "🎯",
		flavor = "Bullets punch through bone and strike the next target.",
		maxLevel = 3,
		values = { 1, 2, 3, 4 },
		describe = function(value)
			return string.format("Bullets pierce +%d foes and +25%% crit damage", value)
		end,
		apply = function(state, value)
			state.pistolPierce += value
			state.critMultiplier += 0.25
		end,
	},

	-- =========================================================================
	-- 6. STORMCALLER GRIMOIRE TALENT TREE (Chain Lightning)
	-- =========================================================================
	{
		id = "storm_damage",
		tree = "StormcallerTome",
		name = "High Voltage",
		icon = "⚡",
		flavor = "The air smells of ozone and charred bone.",
		maxLevel = 5,
		values = { 0.25, 0.45, 0.70, 1.0 },
		describe = function(value)
			return "+" .. percent(value) .. " chain lightning damage"
		end,
		apply = function(state, value)
			state.stormDamageMultiplier += value
		end,
	},
	{
		id = "storm_cooldown",
		tree = "StormcallerTome",
		name = "Tempest Channeling",
		icon = "🌪️",
		flavor = "The storm does not pause between thunderclaps.",
		maxLevel = 5,
		values = { 0.12, 0.18, 0.25, 0.35 },
		describe = function(value)
			return "-" .. percent(value) .. " chain lightning cooldown"
		end,
		apply = function(state, value)
			state.stormCooldownMultiplier =
				math.max(state.stormCooldownMultiplier * (1 - value), Constants.MIN_COOLDOWN_MULTIPLIER)
		end,
	},
	{
		id = "storm_chains",
		tree = "StormcallerTome",
		name = "Forked Arcs",
		icon = "🌩️",
		flavor = "Every skull is a lightning rod for the next.",
		maxLevel = 4,
		values = { 1, 2, 3, 4 },
		describe = function(value)
			return string.format("Chain lightning bounces to +%d additional targets", value)
		end,
		apply = function(state, value)
			state.stormChains += value
		end,
	},
	{
		id = "storm_overload",
		tree = "StormcallerTome",
		name = "Superconductor",
		icon = "🔮",
		flavor = "Static charges your ward and sharpens every arc.",
		maxLevel = 3,
		values = { 0.06, 0.10, 0.15, 0.22 },
		describe = function(value)
			return "+" .. percent(value) .. " crit chance and +20 Arcane Ward"
		end,
		apply = function(state, value)
			state.critChance += value
			state.arcaneWardMax += 20
			state.arcaneWardCurrent = math.min(state.arcaneWardMax, state.arcaneWardCurrent + 20)
		end,
	},

	-- =========================================================================
	-- 7. UNIVERSAL CRITICAL STRIKE & REPLAYABILITY TALENTS
	-- =========================================================================
	{
		id = "universal_crit_chance",
		tree = "Universal",
		name = "Eagle's Precision",
		icon = "🎯",
		flavor = "Every monster has a fatal seam.",
		maxLevel = 5,
		values = { 0.07, 0.11, 0.16, 0.24 },
		describe = function(value)
			return "+" .. percent(value) .. " Critical Strike Chance (all weapons)"
		end,
		apply = function(state, value)
			state.critChance += value
		end,
	},
	{
		id = "universal_crit_damage",
		tree = "Universal",
		name = "Vorpal Ferocity",
		icon = "💥",
		flavor = "When the blow lands true, make the earth shake.",
		maxLevel = 4,
		values = { 0.30, 0.50, 0.75, 1.10 },
		describe = function(value, tier)
			local bonusCrit = if tier >= 2 then ", +4% Crit Chance" else ""
			return "+" .. percent(value) .. " Critical Strike Damage" .. bonusCrit
		end,
		apply = function(state, value, tier)
			state.critMultiplier += value
			if tier >= 2 then
				state.critChance += 0.04
			end
		end,
	},
	{
		id = "universal_crit_nova",
		tree = "Universal",
		name = "Shattering Crits",
		icon = "⚡",
		flavor = "Critical strikes detonate a shockwave through nearby foes.",
		maxLevel = 3,
		values = { 14, 24, 38, 55 },
		describe = function(value)
			return string.format("Critical hits blast nearby enemies for %d AoE damage", value)
		end,
		apply = function(state, value)
			state.critNovaDamage += value
		end,
		requires = function(state)
			return state.critChance >= 0.14
		end,
	},

	-- =========================================================================
	-- 8. IN-RUN SECONDARY WEAPON UNLOCKS (Vampire Survivors Multi-Weapon Draft)
	-- =========================================================================
	{
		id = "unlock_bow",
		tree = "Universal",
		name = "Arsenal: Phantom Longbow",
		icon = "🏹",
		flavor = "Claim the Nightshade Ranger's bow as an active secondary weapon!",
		maxLevel = 1,
		values = { 1, 1, 1, 1 },
		describe = function()
			return "NEW WEAPON: Fires piercing Spectral Arrow Volleys (+5% Crit Chance)"
		end,
		apply = function(state)
			local PS = require(script.Parent.PlayerState) :: any
			PS.unlockWeaponInRun(state, "PhantomBow", false)
		end,
		requires = function(state)
			return state.level >= 3
				and #state.equippedWeapons < Constants.MAX_EQUIPPED_WEAPONS
				and not table.find(state.equippedWeapons, "PhantomBow")
		end,
	},
	{
		id = "unlock_pistols",
		tree = "Universal",
		name = "Arsenal: Hexlock Pistols",
		icon = "🔫",
		flavor = "Draw the Witch Hunter's twin flintlocks alongside your main weapon!",
		maxLevel = 1,
		values = { 1, 1, 1, 1 },
		describe = function()
			return "NEW WEAPON: Rapid-fires Twin Silver Bullets & 360° Bullet Storms"
		end,
		apply = function(state)
			local PS = require(script.Parent.PlayerState) :: any
			PS.unlockWeaponInRun(state, "HexlockPistols", false)
		end,
		requires = function(state)
			return state.level >= 3
				and #state.equippedWeapons < Constants.MAX_EQUIPPED_WEAPONS
				and not table.find(state.equippedWeapons, "HexlockPistols")
		end,
	},
	{
		id = "unlock_storm",
		tree = "Universal",
		name = "Arsenal: Stormcaller Tome",
		icon = "⚡",
		flavor = "Unseal the Tempest Grimoire to arc lightning across the horde!",
		maxLevel = 1,
		values = { 1, 1, 1, 1 },
		describe = function()
			return "NEW WEAPON: Casts 4-Target Chain Lightning & Sky Thunderbolts"
		end,
		apply = function(state)
			local PS = require(script.Parent.PlayerState) :: any
			PS.unlockWeaponInRun(state, "StormcallerTome", false)
		end,
		requires = function(state)
			return state.level >= 3
				and #state.equippedWeapons < Constants.MAX_EQUIPPED_WEAPONS
				and not table.find(state.equippedWeapons, "StormcallerTome")
		end,
	},
	{
		id = "unlock_cleaver",
		tree = "Universal",
		name = "Arsenal: Crypt Cleaver",
		icon = "🪓",
		flavor = "Wield the Executioner's Scythe to sweep frontal cones!",
		maxLevel = 1,
		values = { 1, 1, 1, 1 },
		describe = function()
			return "NEW WEAPON: Cleaves a 125° Frontal Cone + summons Bone Whirlwind"
		end,
		apply = function(state)
			local PS = require(script.Parent.PlayerState) :: any
			PS.unlockWeaponInRun(state, "CryptCleaver", false)
		end,
		requires = function(state)
			return state.level >= 3
				and #state.equippedWeapons < Constants.MAX_EQUIPPED_WEAPONS
				and not table.find(state.equippedWeapons, "CryptCleaver")
		end,
	},
	{
		id = "unlock_staff",
		tree = "Universal",
		name = "Arsenal: Arcanist's Staff",
		icon = "🔮",
		flavor = "Channel celestial spears and orbiting astrolabes!",
		maxLevel = 1,
		values = { 1, 1, 1, 1 },
		describe = function()
			return "NEW WEAPON: Fires lead-predicted Magic Bolts + Guardian Orb"
		end,
		apply = function(state)
			local PS = require(script.Parent.PlayerState) :: any
			PS.unlockWeaponInRun(state, "ArcanistStaff", false)
		end,
		requires = function(state)
			return state.level >= 3
				and #state.equippedWeapons < Constants.MAX_EQUIPPED_WEAPONS
				and not table.find(state.equippedWeapons, "ArcanistStaff")
		end,
	},
	{
		id = "unlock_lantern",
		tree = "Universal",
		name = "Arsenal: Soulflame Lantern",
		icon = "🏮",
		flavor = "Ignite the cemetery with ghostfire cinders and sanctified soil!",
		maxLevel = 1,
		values = { 1, 1, 1, 1 },
		describe = function()
			return "NEW WEAPON: Lobs Spirit Cinder pools + Consecrated Ground aura"
		end,
		apply = function(state)
			local PS = require(script.Parent.PlayerState) :: any
			PS.unlockWeaponInRun(state, "SoulflameLantern", false)
		end,
		requires = function(state)
			return state.level >= 3
				and #state.equippedWeapons < Constants.MAX_EQUIPPED_WEAPONS
				and not table.find(state.equippedWeapons, "SoulflameLantern")
		end,
	},

	-- =========================================================================
	-- 9. CAPSTONE WEAPON EVOLUTIONS (Unlocked at Rank 2+ Primary Attack)
	-- =========================================================================
	{
		id = "evolve_staff",
		tree = "ArcanistStaff",
		name = "EVOLUTION: Astral Starfall",
		icon = "🌟",
		flavor = "The scepter awakens, raining cosmic lances without end.",
		maxLevel = 1,
		values = { 0.45, 0.55, 0.70, 0.90 },
		describe = function(value)
			return "EVOLUTION: +2 Bolts, +2 Pierce, and +" .. percent(value) .. " Damage"
		end,
		apply = function(state, value)
			state.boltCount += 2
			state.boltPierce += 2
			state.damageMultiplier += value
		end,
		requires = function(state)
			return (state.upgrades["bolt_damage"] or 0) >= 2
		end,
	},
	{
		id = "evolve_cleaver",
		tree = "CryptCleaver",
		name = "EVOLUTION: Crimson Guillotine",
		icon = "🩸",
		flavor = "A blood-soaked crescent that reaps an entire hemisphere.",
		maxLevel = 1,
		values = { 0.50, 0.65, 0.80, 1.0 },
		describe = function(value)
			return "EVOLUTION: +55° Frontal Cone, +" .. percent(value) .. " Cleave DMG & +10% Lifesteal"
		end,
		apply = function(state, value)
			state.cleaveArcBonus += 55
			state.cleaveReachBonus += 5
			state.cleaveDamageMultiplier += value
			state.lifestealChance += 0.10
		end,
		requires = function(state)
			return (state.upgrades["cleave_damage"] or 0) >= 2
		end,
	},
	{
		id = "evolve_lantern",
		tree = "SoulflameLantern",
		name = "EVOLUTION: Ashen Hellstorm",
		icon = "🔥",
		flavor = "The censer overflows with undying purgatory fire.",
		maxLevel = 1,
		values = { 0.45, 0.60, 0.75, 0.95 },
		describe = function(value)
			return "EVOLUTION: +2 Cinder Clusters, +40% Pool Area & +" .. percent(value) .. " Burn DMG"
		end,
		apply = function(state, value)
			state.cinderClusterCount += 2
			state.cinderSplashMultiplier += 0.40
			state.cinderDamageMultiplier += value
		end,
		requires = function(state)
			return (state.upgrades["cinder_damage"] or 0) >= 2
		end,
	},
	{
		id = "evolve_bow",
		tree = "PhantomBow",
		name = "EVOLUTION: Thousand-Arrow Tempest",
		icon = "🏹",
		flavor = "Blot out the moon with a hurricane of spectral shafts.",
		maxLevel = 1,
		values = { 0.45, 0.60, 0.75, 0.95 },
		describe = function(value)
			return "EVOLUTION: +2 Arrows, +2 Pierce, +15% Crit & +" .. percent(value) .. " Bow DMG"
		end,
		apply = function(state, value)
			state.bowCount += 2
			state.bowPierce += 2
			state.critChance += 0.15
			state.bowDamageMultiplier += value
		end,
		requires = function(state)
			return (state.upgrades["bow_damage"] or 0) >= 2
		end,
	},
	{
		id = "evolve_pistols",
		tree = "HexlockPistols",
		name = "EVOLUTION: Silver Executioner",
		icon = "🔫",
		flavor = "No chamber ever empties; every bullet finds a heart.",
		maxLevel = 1,
		values = { 0.45, 0.60, 0.75, 0.95 },
		describe = function(value)
			return "EVOLUTION: +2 Silver Bullets, +50% Crit DMG & +" .. percent(value) .. " Pistol DMG"
		end,
		apply = function(state, value)
			state.pistolCount += 2
			state.pistolPierce += 1
			state.critMultiplier += 0.50
			state.pistolDamageMultiplier += value
		end,
		requires = function(state)
			return (state.upgrades["pistol_damage"] or 0) >= 2
		end,
	},
	{
		id = "evolve_storm",
		tree = "StormcallerTome",
		name = "EVOLUTION: Mjolnir's Wrath",
		icon = "⚡",
		flavor = "The heavens split open, chaining living lightning across the crypts.",
		maxLevel = 1,
		values = { 0.45, 0.60, 0.75, 0.95 },
		describe = function(value)
			return "EVOLUTION: +3 Lightning Bounces, -20% Cooldown & +" .. percent(value) .. " Storm DMG"
		end,
		apply = function(state, value)
			state.stormChains += 3
			state.stormCooldownMultiplier =
				math.max(Constants.MIN_COOLDOWN_MULTIPLIER, state.stormCooldownMultiplier * 0.80)
			state.stormDamageMultiplier += value
		end,
		requires = function(state)
			return (state.upgrades["storm_damage"] or 0) >= 2
		end,
	},
	{
		id = "scholar",
		tree = "Universal",
		name = "Scholar",
		icon = "📜",
		flavor = "Every fallen foe is a lesson.",
		maxLevel = 4,
		values = { 0.10, 0.16, 0.24, 0.35 },
		describe = function(value)
			return "+" .. percent(value) .. " experience gained"
		end,
		apply = function(state, value)
			state.xpMultiplier += value
		end,
	},
	{
		id = "fortune",
		tree = "Universal",
		name = "Fortune",
		icon = "🍀",
		flavor = "The forest favours the bold.",
		maxLevel = 3,
		values = { 0.30, 0.60, 1.0, 1.50 },
		describe = function(value)
			return "Rare and better upgrades " .. percent(value) .. " more likely"
		end,
		apply = function(state, value)
			state.luck += value
		end,
	},
}

local HEAL: Definition = {
	id = "heal",
	tree = "Universal",
	name = "Second Wind",
	icon = "💗",
	flavor = "Not yet. Not tonight.",
	maxLevel = math.huge,
	values = { 40, 40, 40, 40 },
	describe = function(value)
		return string.format("Restore %d health", value)
	end,
	apply = function(state, value)
		state.health = math.min(state.maxHealth, state.health + value)
	end,
}

local BY_ID: { [string]: Definition } = { [HEAL.id] = HEAL }
for _, definition in DEFINITIONS do
	assert(#definition.values == #TIER_WEIGHTS, definition.id .. " needs one value per rarity tier")
	BY_ID[definition.id] = definition
end

local rng = Random.new()

local Upgrades = {}

local function rollTier(state: State): number
	local weights = table.clone(TIER_WEIGHTS)
	local total = 0
	for tier, weight in weights do
		if tier > 1 then
			weight *= 1 + state.luck
			weights[tier] = weight
		end
		total += weight
	end
	local roll = rng:NextNumber() * total
	for tier, weight in weights do
		roll -= weight
		if roll < 0 then
			return tier
		end
	end
	return 1
end

function Upgrades.roll(state: State, count: number): { OfferSlot }
	-- Filter pool by active equipped weapon trees + universal tree
	local activeTrees: { [string]: boolean } = { Universal = true }
	if state.equippedWeapons and #state.equippedWeapons > 0 then
		for _, wId in state.equippedWeapons do
			activeTrees[wId] = true
		end
	else
		activeTrees[state.selectedWeapon or "ArcanistStaff"] = true
	end

	local pool: { Definition } = {}
	for _, definition in DEFINITIONS do
		if activeTrees[definition.tree] then
			local requires = definition.requires
			if (state.upgrades[definition.id] or 0) < definition.maxLevel and (requires == nil or requires(state)) then
				table.insert(pool, definition)
			end
		end
	end

	local slots: { OfferSlot } = {}
	while #slots < count and #pool > 0 do
		local index = rng:NextInteger(1, #pool)
		table.insert(slots, { id = pool[index].id, tier = rollTier(state) })
		table.remove(pool, index)
	end
	if #slots == 0 then
		table.insert(slots, { id = HEAL.id, tier = 1 })
	end
	return slots
end

function Upgrades.describe(state: State, slots: { OfferSlot }): { Types.UpgradeOffer }
	local offers: { Types.UpgradeOffer } = {}
	for _, slot in slots do
		local definition = BY_ID[slot.id]
		if definition then
			table.insert(offers, {
				name = definition.name,
				description = definition.describe(definition.values[slot.tier], slot.tier),
				flavor = definition.flavor,
				icon = definition.icon,
				rarity = slot.tier,
				rank = (state.upgrades[slot.id] or 0) + 1,
				maxRank = if definition.maxLevel == math.huge then 0 else definition.maxLevel,
			})
		end
	end
	return offers
end

function Upgrades.apply(state: State, slot: OfferSlot): boolean
	local definition = BY_ID[slot.id]
	local value = definition and definition.values[slot.tier]
	if not definition or not value then
		return false
	end
	state.upgrades[slot.id] = (state.upgrades[slot.id] or 0) + 1
	definition.apply(state, value, slot.tier)
	return true
end

return Upgrades
