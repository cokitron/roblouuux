--!strict

export type PlayerPhase = "Lobby" | "InRun" | "Downed" | "Summary"

-- rarity: 1 Common, 2 Rare, 3 Elite, 4 Legendary. maxRank 0 means unlimited.
export type UpgradeOffer = {
	name: string,
	description: string,
	flavor: string,
	icon: string,
	rarity: number,
	rank: number,
	maxRank: number,
}

-- An empty offers list closes the picker (the server auto-picked the last pending level-up).
export type LevelUpPayload = {
	seq: number,
	timeout: number,
	offers: { UpgradeOffer },
}

export type BoltRecord = {
	id: number,
	ox: number,
	oz: number,
	dx: number,
	dz: number,
	t0: number,
	v: number,
	overcharge: boolean?,
	kind: string?, -- "Bolt" | "Arrow" | "Bullet"
}

export type HitEvent = {
	id: number,
	dmg: number,
	crit: number, -- 0 normal, 1 crit, 2 super-crit / execute / overcharge
	x: number,
	z: number,
}

export type ShockwaveEvent = {
	x: number,
	z: number,
	radius: number,
}

export type CleaveEvent = {
	ox: number,
	oz: number,
	dirX: number,
	dirZ: number,
	arc: number,
	radius: number,
	overcharge: boolean?,
}

export type CinderEvent = {
	ox: number,
	oz: number,
	tx: number,
	tz: number,
	splashRadius: number,
	duration: number,
	overcharge: boolean?,
}

export type EmergenceEvent = {
	x: number,
	z: number,
}

export type LightningEvent = {
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	overcharge: boolean?,
}

export type WorldEventsPayload = {
	t: number,
	hits: { HitEvent },
	kills: { number },
	bolts: { number },
	shockwaves: { ShockwaveEvent }?,
	cleaves: { CleaveEvent }?,
	cinders: { CinderEvent }?,
	emergences: { EmergenceEvent }?,
	lightnings: { LightningEvent }?,
	clear: boolean,
}

return {}
