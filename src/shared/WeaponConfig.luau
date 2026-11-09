--!strict
export type StarterWeaponId =
	"ArcanistStaff"
	| "CryptCleaver"
	| "SoulflameLantern"
	| "PhantomBow"
	| "HexlockPistols"
	| "StormcallerTome"

export type WeaponMeta = {
	id: StarterWeaponId,
	name: string,
	subtitle: string,
	icon: string,
	role: string,
	flavor: string,
	attackName: string,
	attackDesc: string,
	attackStats: string,
	auraName: string,
	auraDesc: string,
	auraStats: string,
	defenseSummary: string,
}

local WEAPONS: { [StarterWeaponId]: WeaponMeta } = {
	ArcanistStaff = {
		id = "ArcanistStaff",
		name = "Arcanist's Staff",
		subtitle = "The Celestial Scepter",
		icon = "🔮",
		role = "Ranged Precision & Kinetic Barrier",
		flavor = "Forged from fallen starlight and crypt iron, channeling cold cosmic clarity.",
		attackName = "Magic Bolt",
		attackDesc = "Fires lead-predicted crystal spears with 5th-shot Arcane Lance Overcharge.",
		attackStats = "8 DMG • 0.9s CD • 80 Stud Range",
		auraName = "Guardian Orb",
		auraDesc = "Orbiting celestial astrolabes that shred swarming enemies crossing your perimeter.",
		auraStats = "6 DMG • 9 Stud Radius • 2.4 rad/s Speed",
		defenseSummary = "Aether Barrier shield ward, Phase Armor mitigation, and Fleet Step kiting.",
	},
	CryptCleaver = {
		id = "CryptCleaver",
		name = "Crypt Cleaver",
		subtitle = "The Executioner's Scythe",
		icon = "🪓",
		role = "Directional Frontal Cone Melee & Juggernaut",
		flavor = "A rusted executioner's crescent, sweeping wide frontal cones in the direction you face.",
		attackName = "Reaper's Frontal Cone",
		attackDesc = "Cleaves a directional 125° frontal fan ahead of your facing + 4th-swing 360° Maelstrom.",
		attackStats = "16 DMG • 1.25s CD • 23 Reach (125° Frontal Cone)",
		auraName = "Bone Whirlwind",
		auraDesc = "Jagged ossuary ribs and gravestone shards that damage and knock enemies back.",
		auraStats = "8 DMG • 5.5 Stud Radius • 14 Stud Knockback",
		defenseSummary = "Starts with +35 Max HP & +2 Armor. Vampiric lifesteal and Barbed Carapace thorns.",
	},
	SoulflameLantern = {
		id = "SoulflameLantern",
		name = "Soulflame Lantern",
		subtitle = "The Grave Censer",
		icon = "🏮",
		role = "Zone Denial & Chokepoint Pyre",
		flavor = "Burning with eternal ghostfire that devours both corpse and shadow.",
		attackName = "Spirit Cinders",
		attackDesc = "Hurls ghostfire embers into burn pools + 4th-lob Purgatory Geyser on dense packs.",
		attackStats = "10 DMG + 6 DoT • 1.1s CD • 7 Stud Splash",
		auraName = "Consecrated Ground",
		auraDesc = "Sanctified grave ground aura that deals continuous damage and slows foes.",
		auraStats = "4 DMG / 0.5s • 12 Stud Radius • -20% Speed Slow",
		defenseSummary = "Iron Will health & armor, Sanctuary Mending health regen, and Soul Beacon magnet.",
	},
	PhantomBow = {
		id = "PhantomBow",
		name = "Phantom Longbow",
		subtitle = "The Nightshade Ranger",
		icon = "🏹",
		role = "High-Crit Piercing Sniper & Gale Volley",
		flavor = "Strung with banshee silk; its spectral arrows pierce entire columns of the undead.",
		attackName = "Spectral Arrow Volley",
		attackDesc = "Fires high-velocity feathered arrows that pierce +2 foes + 4th-shot 5-Arrow Gale Barrage.",
		attackStats = "14 DMG • 0.78s CD • Pierces 3 Targets",
		auraName = "Eagle Eye Instinct",
		auraDesc = "Innate Ranger marksman training granting high starting Critical Strike Chance & agility.",
		auraStats = "+20% Base Crit Chance • +10% Move Speed",
		defenseSummary = "High critical strike scaling, multi-arrow fan volleys, and fleet-footed kiting.",
	},
	HexlockPistols = {
		id = "HexlockPistols",
		name = "Hexlock Pistols",
		subtitle = "The Witch Hunter's Twins",
		icon = "🔫",
		role = "Rapid-Fire Dual Gunslinger & Bullet Storm",
		flavor = "Twin silver-inlaid flintlocks that spit blessed lead faster than a heartbeat.",
		attackName = "Twin Silver Volley",
		attackDesc = "Rapid-fires silver rounds at nearby threats + 6th-shot 360° Bullet Storm Fan-of-Guns.",
		attackStats = "9 DMG x2 • 0.44s CD • 70 Stud Range",
		auraName = "Silvered Magazine",
		auraDesc = "Blessed witch-hunter rounds with innate critical precision and rapid reload cadence.",
		auraStats = "+15% Base Crit Chance • +10% Attack Haste",
		defenseSummary = "Blistering fire rate, ricochet piercing rounds, and critical execution bursts.",
	},
	StormcallerTome = {
		id = "StormcallerTome",
		name = "Stormcaller Grimoire",
		subtitle = "The Tempest Codex",
		icon = "⚡",
		role = "Bouncing Chain Lightning & Sky Thunderbolts",
		flavor = "Bound in storm-drake hide, its pages crackle with the fury of a thousand tempests.",
		attackName = "Chain Lightning",
		attackDesc = "Unleashes jagged lightning that bounces across 4 foes + 4th-cast Sky Thunderbolt Pillar.",
		attackStats = "13 DMG • 1.05s CD • 4-Target Chain",
		auraName = "Static Conduction",
		auraDesc = "Aetheric static field that expands Soul Crystal magnet reach and hastens spellcasting.",
		auraStats = "+25% Crystal Magnet • +15 Arcane Ward",
		defenseSummary = "Multi-target arc bounces, high-density thunder pillars, and regenerating ward.",
	},
}

local ORDER: { StarterWeaponId } = {
	"ArcanistStaff",
	"CryptCleaver",
	"SoulflameLantern",
	"PhantomBow",
	"HexlockPistols",
	"StormcallerTome",
}

local WeaponConfig = {}

function WeaponConfig.get(id: StarterWeaponId): WeaponMeta?
	return WEAPONS[id]
end

function WeaponConfig.getAll(): { WeaponMeta }
	local list: { WeaponMeta } = {}
	for _, id in ORDER do
		table.insert(list, WEAPONS[id])
	end
	return list
end

function WeaponConfig.isValidId(id: unknown): boolean
	return typeof(id) == "string" and WEAPONS[id :: StarterWeaponId] ~= nil
end

return WeaponConfig
