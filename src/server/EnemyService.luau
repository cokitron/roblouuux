--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Arena = require(script.Parent.Arena)
local DataService = require(script.Parent.DataService)
local GemService = require(script.Parent.GemService)
local PlayerState = require(script.Parent.PlayerState)
local Replication = require(script.Parent.Replication)
local ServerTypes = require(script.Parent.ServerTypes)
local Constants = require(ReplicatedStorage.Shared.Constants)
local EnemyVisuals = require(ReplicatedStorage.Shared.EnemyVisuals)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local RpgConfig = require(ReplicatedStorage.Shared.RpgConfig)

type Enemy = ServerTypes.Enemy

type Definition = {
	health: number,
	speed: number,
	damage: number,
	experience: number,
	radius: number,
	aiKind: string,
	isFlyer: boolean?,
	isBoss: boolean?,
	displayName: string?,
	ccKind: string?,
	ccDuration: number?,
	ccChance: number?,
	ccRange: number?,
}

local DEFINITIONS: { [string]: Definition } = {
	Skeleton = { health = 24, speed = 9.2, damage = 9, experience = 1, radius = 1.5, aiKind = "Legionnaire" },
	Bat = {
		health = 14,
		speed = 14.2,
		damage = 6,
		experience = 1,
		radius = 1.1,
		aiKind = "Flyer",
		isFlyer = true,
	},
	Spider = {
		health = 34,
		speed = 11.4,
		damage = 8,
		experience = 2,
		radius = 1.6,
		aiKind = "Charger",
		ccKind = "Snare",
		ccDuration = Constants.CC_SNARE_DURATION,
		ccChance = 0.72,
		ccRange = 4.2,
	},
	Golem = {
		health = 135,
		speed = 6.4,
		damage = 20,
		experience = 6,
		radius = 3,
		aiKind = "Pursuer",
		ccKind = "Snare",
		ccDuration = 1.8,
		ccChance = 0.65,
		ccRange = 5.2,
	},
	Wisp = {
		health = 13,
		speed = 15.0,
		damage = 7,
		experience = 1,
		radius = 1.2,
		aiKind = "Flyer",
		isFlyer = true,
		ccKind = "Charm",
		ccDuration = Constants.CC_CHARM_DURATION,
		ccChance = 0.45,
		ccRange = 4.8,
	},
	PlagueSlime = {
		health = 44,
		speed = 8.8,
		damage = 10,
		experience = 2,
		radius = 1.6,
		aiKind = "Pursuer",
		ccKind = "Snare",
		ccDuration = Constants.CC_SNARE_DURATION,
		ccChance = 0.78,
		ccRange = 4.4,
	},
	InfernalImp = { health = 30, speed = 13.6, damage = 11, experience = 2, radius = 1.3, aiKind = "Skirmisher" },
	FrostWyrm = {
		health = 110,
		speed = 10.2,
		damage = 17,
		experience = 6,
		radius = 2.2,
		aiKind = "Flyer",
		isFlyer = true,
		ccKind = "Freeze",
		ccDuration = Constants.CC_FREEZE_DURATION,
		ccChance = 0.82,
		ccRange = 6.2,
	},
	CryptGhoul = { health = 32, speed = 12.6, damage = 10, experience = 1, radius = 1.4, aiKind = "Pursuer" },
	BoneHound = {
		health = 35,
		speed = 14.2,
		damage = 9,
		experience = 2,
		radius = 1.5,
		aiKind = "Charger",
		ccKind = "Snare",
		ccDuration = 1.6,
		ccChance = 0.45,
		ccRange = 3.6,
	},
	AbyssalWatcher = {
		health = 42,
		speed = 9.6,
		damage = 12,
		experience = 3,
		radius = 1.5,
		aiKind = "Skirmisher",
		ccKind = "Confuse",
		ccDuration = Constants.CC_CONFUSE_DURATION,
		ccChance = 0.78,
		ccRange = 7.8,
	},
	NecromancerAcolyte = {
		health = 56,
		speed = 8.2,
		damage = 13,
		experience = 3,
		radius = 1.6,
		aiKind = "Skirmisher",
		ccKind = "Charm",
		ccDuration = Constants.CC_CHARM_DURATION,
		ccChance = 0.72,
		ccRange = 7.2,
	},
	DeathKnight = {
		health = 120,
		speed = 7.8,
		damage = 19,
		experience = 6,
		radius = 2.2,
		aiKind = "Charger",
		ccKind = "Freeze",
		ccDuration = 0.95,
		ccChance = 0.60,
		ccRange = 4.5,
	},
	BansheeShrieker = {
		health = 38,
		speed = 12.8,
		damage = 11,
		experience = 3,
		radius = 1.5,
		aiKind = "Flyer",
		isFlyer = true,
		ccKind = "Confuse",
		ccDuration = Constants.CC_CONFUSE_DURATION,
		ccChance = 0.78,
		ccRange = 7.0,
	},
	CandelabraMimic = {
		health = 48,
		speed = 11.6,
		damage = 10,
		experience = 2,
		radius = 1.4,
		aiKind = "Pursuer",
		ccKind = "Charm",
		ccDuration = Constants.CC_CHARM_DURATION,
		ccChance = 0.75,
		ccRange = 5.4,
	},
	GraveReaper = {
		health = 380,
		speed = 10.6,
		damage = 20,
		experience = 35,
		radius = 2.4,
		aiKind = "Charger",
		isBoss = true,
		displayName = "⚔️ Grave Reaper (Mini-Boss)",
		ccKind = "Charm",
		ccDuration = 1.45,
		ccChance = 0.88,
		ccRange = 8.2,
	},
	HollowArmor = {
		health = 560,
		speed = 8.8,
		damage = 26,
		experience = 60,
		radius = 2.8,
		aiKind = "Charger",
		isBoss = true,
		displayName = "🛡️ Hollow Dreadnought (Mini-Boss)",
		ccKind = "Snare",
		ccDuration = 2.4,
		ccChance = 0.90,
		ccRange = 8.0,
	},
	OssuaryBehemoth = {
		health = 780,
		speed = 7.4,
		damage = 32,
		experience = 90,
		radius = 3.6,
		aiKind = "Pursuer",
		isBoss = true,
		displayName = "🦴 Ossuary Behemoth (Mini-Boss)",
		ccKind = "Confuse",
		ccDuration = 1.85,
		ccChance = 0.90,
		ccRange = 9.0,
	},
	LichLord = {
		health = 1150,
		speed = 8.0,
		damage = 38,
		experience = 150,
		radius = 3.5,
		aiKind = "Skirmisher",
		isBoss = true,
		displayName = "👑 The Lich Lord (Crypt Sovereign)",
		ccKind = "Freeze",
		ccDuration = 1.30,
		ccChance = 0.92,
		ccRange = 9.5,
	},
}

local MAX_ENEMY_ID = 65535
local CRIT_MULTIPLIER = 2
local LIFESTEAL_HEAL = 3
local CELL_SIZE = Constants.SPATIAL_CELL_SIZE
local GRID_STRIDE = 128

local rng = Random.new()
local enemies: { Enemy } = {}
local spatialGrid: { [number]: { Enemy } } = {}
local activeCellKeys: { number } = {}
local nextId = 0

local EnemyService = {}

local function getCellKey(cx: number, cz: number): number
	return (cx + 64) * GRID_STRIDE + (cz + 64)
end

local function rebuildSpatialGrid()
	for i = 1, #activeCellKeys do
		local key = activeCellKeys[i]
		local bucket = spatialGrid[key]
		if bucket then
			table.clear(bucket)
		end
	end
	table.clear(activeCellKeys)

	for _, enemy in enemies do
		if not enemy.dead then
			local cx = math.floor(enemy.x / CELL_SIZE)
			local cz = math.floor(enemy.z / CELL_SIZE)
			local key = getCellKey(cx, cz)
			local bucket = spatialGrid[key]
			if not bucket then
				bucket = {}
				spatialGrid[key] = bucket
			end
			if #bucket == 0 then
				table.insert(activeCellKeys, key)
			end
			table.insert(bucket, enemy)
		end
	end
end

function EnemyService.getEnemies(): { Enemy }
	return enemies
end

function EnemyService.count(): number
	return #enemies
end

function EnemyService.applySlow(enemy: Enemy, slowFraction: number, duration: number)
	local now = GameClock.now()
	enemy.slowUntil = math.max(enemy.slowUntil, now + duration)
	enemy.slowMult = math.clamp(1 - slowFraction, 0.35, 1)
end

function EnemyService.findHighestDensityCluster(cx: number, cz: number, range: number): Enemy?
	local bestEnemy: Enemy? = nil
	local bestCount = 0
	local rangeSq = range * range
	for i = 1, #activeCellKeys do
		local key = activeCellKeys[i]
		local bucket = spatialGrid[key]
		if bucket and #bucket > bestCount then
			local sample = bucket[1]
			local dx = sample.x - cx
			local dz = sample.z - cz
			if dx * dx + dz * dz <= rangeSq then
				bestCount = #bucket
				bestEnemy = sample
			end
		end
	end
	return bestEnemy
end

function EnemyService.randomRingPosition(center: Vector3, minRad: number?, maxRad: number?): (number, number)
	local limit = Constants.ARENA_HALF_SIZE - 2
	local rMin = minRad or Constants.SPAWN_RADIUS_MIN
	local rMax = maxRad or Constants.SPAWN_RADIUS_MAX
	for _ = 1, 8 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(rMin, rMax)
		local x = center.X + math.cos(angle) * radius
		local z = center.Z + math.sin(angle) * radius
		if math.abs(x) <= limit and math.abs(z) <= limit and not Arena.isPointBlocked(x, z, 2.5) then
			return x, z
		end
	end
	local fx = math.clamp(center.X, -limit, limit)
	local fz = math.clamp(center.Z, -limit, limit)
	return Arena.resolveObstacle(fx, fz, 2.5, 0, false)
end

function EnemyService.pickEmergencePosition(center: Vector3): (number, number, boolean)
	local anchors = Arena.getCryptAnchors()
	if #anchors > 0 then
		local startIdx = rng:NextInteger(1, #anchors)
		for offset = 0, #anchors - 1 do
			local anchor = anchors[((startIdx + offset - 1) % #anchors) + 1]
			local dx = anchor.x - center.X
			local dz = anchor.z - center.Z
			local distSq = dx * dx + dz * dz
			if distSq >= 26 * 26 and distSq <= 76 * 76 and not Arena.isPointBlocked(anchor.x, anchor.z, 2.2) then
				local jitterX = anchor.x + rng:NextNumber(-2.5, 2.5)
				local jitterZ = anchor.z + rng:NextNumber(-2.5, 2.5)
				Replication.queueEmergence(jitterX, jitterZ)
				return jitterX, jitterZ, true
			end
		end
	end
	local rx, rz = EnemyService.randomRingPosition(center)
	return rx, rz, false
end

function EnemyService.spawn(kind: string, position: Vector3, healthMultiplier: number): Enemy?
	local definition = DEFINITIONS[kind]
	local kindIndex = EnemyVisuals.indexByName[kind]
	if not definition or not kindIndex then
		return nil
	end

	nextId = nextId % MAX_ENEMY_ID + 1
	local maxHp = definition.health * healthMultiplier
	local enemy: Enemy = {
		id = nextId,
		kind = kind,
		kindIndex = kindIndex,
		health = maxHp,
		maxHealth = maxHp,
		speed = definition.speed,
		baseSpeed = definition.speed,
		damage = definition.damage,
		experience = definition.experience,
		radius = definition.radius,
		x = position.X,
		z = position.Z,
		vx = 0,
		vz = 0,
		slowUntil = 0,
		slowMult = 1,
		aiKind = definition.aiKind,
		isFlyer = definition.isFlyer == true,
		chargeCooldown = rng:NextNumber(1.5, 4.0),
		chargeUntil = 0,
		chargeDirX = 0,
		chargeDirZ = 0,
		ccCooldown = rng:NextNumber(2.0, 4.5),
		dead = false,
		isBoss = definition.isBoss == true,
		orbHitAt = {},
	}
	table.insert(enemies, enemy)
	return enemy
end

function EnemyService.damage(enemy: Enemy, amount: number, source: ServerTypes.State?, forceCritTier: number?)
	if enemy.dead then
		return
	end
	local critTier = forceCritTier or 0
	if forceCritTier == nil and source and source.critChance > 0 and rng:NextNumber() < source.critChance then
		local mult = if source.critMultiplier and source.critMultiplier > 1
			then source.critMultiplier
			else CRIT_MULTIPLIER
		amount *= mult
		critTier = 1
		-- Super-Crit roll when Crit Chance is high (>30%)
		if source.critChance > 0.30 and rng:NextNumber() < (source.critChance - 0.25) then
			amount *= 1.35
			critTier = 2
		end
	end

	local roundedDmg = math.max(1, math.floor(amount + 0.5))
	Replication.queueHit(enemy.id, roundedDmg, critTier, enemy.x, enemy.z)

	enemy.health -= amount
	local died = enemy.health <= 0
	if died then
		enemy.dead = true
	end

	-- Shattering Crits synergy: critical strikes detonate an arcane pulse around the target
	if critTier >= 1 and forceCritTier == nil and source and source.critNovaDamage > 0 then
		local novaDmg = source.critNovaDamage * source.damageMultiplier
		for _, other in enemies do
			if not other.dead and other ~= enemy then
				local odx = other.x - enemy.x
				local odz = other.z - enemy.z
				if odx * odx + odz * odz <= 6.5 * 6.5 then
					EnemyService.damage(other, novaDmg, source, 0)
				end
			end
		end
	end

	if not died then
		return
	end
	Replication.queueKill(enemy.id)
	GemService.spawn(Vector3.new(enemy.x, 0, enemy.z), enemy.experience)
	if source then
		PlayerState.addKill(source)
		DataService.recordDiscovery(source.player, enemy.kind)
		if source.lifestealChance > 0 and rng:NextNumber() < source.lifestealChance then
			local healAmount = if source.lifestealAmount and source.lifestealAmount > 0
				then source.lifestealAmount
				else LIFESTEAL_HEAL
			PlayerState.heal(source, healAmount)
		end
	end

	if enemy.isBoss then
		Arena.spawnReliquaryChest(enemy.x, enemy.z, true)
		local minRarity = if enemy.kind == "LichLord" then 4 else 3
		for _, st in PlayerState.getAllRunners() do
			local p = st.player
			local profile = DataService.getProfile(p)
			if profile then
				profile.souls += if enemy.kind == "LichLord" then 100 else 30
				st.souls = profile.souls
				local drop =
					RpgConfig.rollGearItem(rng, profile.heroLevel, profile.selectedKeystone, minRarity, st.luck, nil)
				DataService.addLootItem(p, drop)
			end
			if enemy.kind == "LichLord" then
				st.bossDefeated = true
			end
		end
	elseif
		(enemy.kind == "DeathKnight" or enemy.kind == "Golem" or enemy.kind == "FrostWyrm")
		and rng:NextNumber() < 0.30
	then
		Arena.spawnReliquaryChest(enemy.x, enemy.z, false)
	end
end

function EnemyService.clearAll()
	table.clear(enemies)
	rebuildSpatialGrid()
	Workspace:SetAttribute("ActiveBossName", "")
	Workspace:SetAttribute("ActiveBossHpPct", 0)
	Replication.queueClear()
end

-- Detonates an Eldritch Shockwave around a revived player: blasts enemies within radius for massive
-- damage and radial knockback so the revived player has immediate breathing room (LOOP-2, MON-2).
function EnemyService.shockwaveClear(
	center: Vector3,
	radius: number,
	damage: number,
	knockback: number,
	source: ServerTypes.State?
)
	local radiusSq = radius * radius
	local limit = Constants.ARENA_HALF_SIZE - 2
	for _, enemy in enemies do
		if not enemy.dead then
			local dx = enemy.x - center.X
			local dz = enemy.z - center.Z
			local distSq = dx * dx + dz * dz
			if distSq <= radiusSq then
				EnemyService.damage(enemy, damage, source)
				if not enemy.dead then
					local dist = math.sqrt(distSq)
					local nx = if dist > 1e-3 then dx / dist else 1
					local nz = if dist > 1e-3 then dz / dist else 0
					local rx, rz = Arena.resolveObstacle(
						enemy.x + nx * knockback,
						enemy.z + nz * knockback,
						enemy.radius,
						0,
						enemy.isFlyer
					)
					enemy.x = math.clamp(rx, -limit, limit)
					enemy.z = math.clamp(rz, -limit, limit)
				end
			end
		end
	end
	Replication.queueShockwave(center.X, center.Z, radius)
end

local function compact()
	local write = 0
	local total = #enemies
	for read = 1, total do
		local enemy = enemies[read]
		if not enemy.dead then
			write += 1
			enemies[write] = enemy
		end
	end
	for i = total, write + 1, -1 do
		enemies[i] = nil
	end
end

-- O(N) Spatial Hash Grid separation (PERF-3): checks same cell + 4 forward neighbor cells.
local NEIGHBOR_OFFSETS = {
	{ 1, 0 },
	{ 0, 1 },
	{ 1, 1 },
	{ -1, 1 },
}

local function pushPair(a: Enemy, b: Enemy)
	local dx = b.x - a.x
	local dz = b.z - a.z
	local minDist = (a.radius + b.radius) * 0.82
	local distSq = dx * dx + dz * dz
	if distSq < minDist * minDist and distSq > 0.0001 then
		local dist = math.sqrt(distSq)
		local push = (minDist - dist) * 0.5 * Constants.SEPARATION_STRENGTH
		local nx = dx / dist * push
		local nz = dz / dist * push
		a.x -= nx
		a.z -= nz
		b.x += nx
		b.z += nz
	end
end

local function separateSpatial()
	for idx = 1, #activeCellKeys do
		local key = activeCellKeys[idx]
		local cell = spatialGrid[key]
		if cell then
			local cellCount = #cell
			for i = 1, cellCount - 1 do
				local a = cell[i]
				for j = i + 1, cellCount do
					pushPair(a, cell[j])
				end
			end
			for _, off in NEIGHBOR_OFFSETS do
				local nKey = key + off[1] * GRID_STRIDE + off[2]
				local nCell = spatialGrid[nKey]
				if nCell and #nCell > 0 then
					for i = 1, cellCount do
						local a = cell[i]
						for j = 1, #nCell do
							pushPair(a, nCell[j])
						end
					end
				end
			end
		end
	end
end

function EnemyService.step(dt: number)
	compact()
	local count = #enemies
	local targets = PlayerState.getTargets()
	if #targets == 0 or count == 0 then
		rebuildSpatialGrid()
		if Workspace:GetAttribute("ActiveBossName") ~= "" then
			Workspace:SetAttribute("ActiveBossName", "")
			Workspace:SetAttribute("ActiveBossHpPct", 0)
		end
		return
	end

	local now = GameClock.now()
	local activeBoss: Enemy? = nil
	local despawnSq = Constants.DESPAWN_DISTANCE ^ 2
	local safeDt = math.max(dt, 0.001)
	local legionThrustCycle = now % 1.85

	-- Track active close-range Crypt Legionnaire launchers per player target (capped at 2 per group)
	local activeLegionLaunchers: { [PlayerState.Target]: number } = {}
	for _, enemy in enemies do
		if not enemy.dead and enemy.aiKind == "Legionnaire" and now < enemy.chargeUntil + 0.55 then
			local nearest = targets[1]
			local nearestDistSq = math.huge
			for _, target in targets do
				local dx = target.position.X - enemy.x
				local dz = target.position.Z - enemy.z
				local distSq = dx * dx + dz * dz
				if distSq < nearestDistSq then
					nearest = target
					nearestDistSq = distSq
				end
			end
			activeLegionLaunchers[nearest] = (activeLegionLaunchers[nearest] or 0) + 1
		end
	end

	for _, enemy in enemies do
		if enemy.isBoss and not enemy.dead then
			activeBoss = enemy
		end

		enemy.speed = enemy.baseSpeed * (if now < enemy.slowUntil then enemy.slowMult else 1)

		local nearest = targets[1]
		local nearestDistSq = math.huge
		for _, target in targets do
			local dx = target.position.X - enemy.x
			local dz = target.position.Z - enemy.z
			local distSq = dx * dx + dz * dz
			if distSq < nearestDistSq then
				nearest = target
				nearestDistSq = distSq
			end
		end

		if nearestDistSq > despawnSq and not enemy.isBoss then
			enemy.x, enemy.z = EnemyService.randomRingPosition(nearest.position)
			enemy.vx = 0
			enemy.vz = 0
		else
			local prevX = enemy.x
			local prevZ = enemy.z
			local dist = math.sqrt(nearestDistSq)
			local ai = enemy.aiKind

			if dist > enemy.radius then
				-- Velocity interception & crescent flank fan (anti-conga-line steering)
				local leadWeight = math.clamp((dist - 10) / 32, 0, 0.45)
				local aimX = nearest.position.X + nearest.velocity.X * leadWeight
				local aimZ = nearest.position.Z + nearest.velocity.Z * leadWeight
				local rawDx = aimX - enemy.x
				local rawDz = aimZ - enemy.z
				local rawLen = math.max(math.sqrt(rawDx * rawDx + rawDz * rawDz), 0.001)
				local dirX = rawDx / rawLen
				local dirZ = rawDz / rawLen

				if dist > 10 and ai ~= "Legionnaire" then
					local flankBlend = math.clamp((dist - 10) / 28, 0, 1)
					local flankAngle = ((enemy.id % 7) - 3) * 0.17 * flankBlend
					local c = math.cos(flankAngle)
					local s = math.sin(flankAngle)
					dirX, dirZ = dirX * c - dirZ * s, dirX * s + dirZ * c
				end

				local speedMult = 1.0

				if ai == "Legionnaire" then
					enemy.chargeCooldown -= dt
					if now < enemy.chargeUntil then
						-- Active close-range Breacher Launch (at most 2 per group)
						dirX = enemy.chargeDirX
						dirZ = enemy.chargeDirZ
						speedMult = 2.75
					elseif
						enemy.chargeCooldown <= 0
						and dist >= 4.0
						and dist <= 10.5
						and (activeLegionLaunchers[nearest] or 0) < 2
					then
						activeLegionLaunchers[nearest] = (activeLegionLaunchers[nearest] or 0) + 1
						enemy.chargeCooldown = rng:NextNumber(4.4, 6.8)
						enemy.chargeUntil = now + 0.42
						enemy.chargeDirX = dirX
						enemy.chargeDirZ = dirZ
						speedMult = 2.75
					else
						-- Loose 8-Unit Phalanx Cohort Alignment (2 ranks of 4): hold formation depth & width
						local cx = math.floor(enemy.x / CELL_SIZE)
						local cz = math.floor(enemy.z / CELL_SIZE)
						local sumX = 0
						local sumZ = 0
						local squadCount = 0
						for ox = -1, 1 do
							for oz = -1, 1 do
								local bucket = spatialGrid[getCellKey(cx + ox, cz + oz)]
								if bucket then
									for _, mate in bucket do
										if
											mate ~= enemy
											and not mate.dead
											and mate.aiKind == "Legionnaire"
											and now >= mate.chargeUntil
										then
											local mdx = mate.x - enemy.x
											local mdz = mate.z - enemy.z
											if mdx * mdx + mdz * mdz <= 256 then
												sumX += mate.x
												sumZ += mate.z
												squadCount += 1
											end
										end
									end
								end
							end
						end
						if squadCount > 0 and dist > 4.5 then
							local cenX = sumX / squadCount
							local cenZ = sumZ / squadCount
							local relX = enemy.x - cenX
							local relZ = enemy.z - cenZ
							local perpX = -dirZ
							local perpZ = dirX
							-- alongOffset > 0 means ahead of cohort center; < 0 means behind cohort center
							local alongOffset = relX * dirX + relZ * dirZ
							local latOffset = relX * perpX + relZ * perpZ
							-- Keep 2-rank phalanx depth (~3.1 studs between front and rear rank)
							if alongOffset < -1.8 then
								speedMult = math.clamp(1.0 + (-1.8 - alongOffset) * 0.16, 1.0, 1.34)
							elseif alongOffset > 1.8 then
								speedMult = math.clamp(1.0 - (alongOffset - 1.8) * 0.14, 0.80, 1.0)
							end
							-- Reform lateral shield-wall width if a unit drifted wider than the 4-column line
							if math.abs(latOffset) > 5.8 then
								local pullSign = if latOffset > 0 then -1 else 1
								dirX = dirX * 0.80 + perpX * pullSign * 0.20
								dirZ = dirZ * 0.80 + perpZ * pullSign * 0.20
								local nLen = math.max(math.sqrt(dirX * dirX + dirZ * dirZ), 0.001)
								dirX /= nLen
								dirZ /= nLen
							end
						end
						-- Synchronized Phalanx Thrust Cadence when within 14.5 studs of the player
						if dist <= 14.5 then
							if legionThrustCycle < 0.30 then
								speedMult *= 0.55 -- Cohort braces shields together before thrusting
							elseif legionThrustCycle < 0.58 then
								speedMult *= 1.48 -- Synchronized phalanx forward thrust step!
							end
						end
					end
				elseif ai == "Charger" then
					enemy.chargeCooldown -= dt
					if now < enemy.chargeUntil then
						dirX = enemy.chargeDirX
						dirZ = enemy.chargeDirZ
						speedMult = 2.05
					elseif enemy.chargeCooldown <= 0 and dist <= 24 and dist >= 7 then
						enemy.chargeCooldown = 4.8
						enemy.chargeUntil = now + 0.45
						enemy.chargeDirX = dirX
						enemy.chargeDirZ = dirZ
						speedMult = 2.05
					end
				elseif ai == "Skirmisher" then
					-- Spiral inward tangentially when within 9 studs so Skirmishers & LichLord surround and engage the player
					if dist < 9 then
						local orbitSign = if enemy.id % 2 == 0 then 1 else -1
						local perpX = -dirZ * orbitSign
						local perpZ = dirX * orbitSign
						local radialWeight = math.clamp((dist - 3.2) / 5.5, 0.22, 0.65)
						dirX = dirX * radialWeight + perpX * 0.72
						dirZ = dirZ * radialWeight + perpZ * 0.72
						local len = math.max(math.sqrt(dirX * dirX + dirZ * dirZ), 0.001)
						dirX /= len
						dirZ /= len
					end
				elseif ai == "Flyer" then
					-- Sinusoidal swoop weave; glides over low cover
					local weave = math.sin(now * 5.2 + enemy.id * 1.1) * 0.28
					local c = math.cos(weave)
					local s = math.sin(weave)
					dirX, dirZ = dirX * c - dirZ * s, dirX * s + dirZ * c
				end

				-- Look-ahead obstacle whisker steering (Legionnaires break formation around obstacles and reform)
				dirX, dirZ =
					Arena.steerAroundObstacles(enemy.x, enemy.z, dirX, dirZ, enemy.radius, enemy.id, enemy.isFlyer)

				local stepDist = enemy.speed * speedMult * dt
				enemy.x += dirX * stepDist
				enemy.z += dirZ * stepDist
				enemy.x, enemy.z = Arena.resolveObstacle(enemy.x, enemy.z, enemy.radius, stepDist, enemy.isFlyer)
			end

			enemy.vx = (enemy.x - prevX) / safeDt
			enemy.vz = (enemy.z - prevZ) / safeDt

			enemy.ccCooldown = math.max(0, enemy.ccCooldown - dt)
			local def = DEFINITIONS[enemy.kind]
			if def and def.ccKind and enemy.ccCooldown <= 0 then
				local ccRange = def.ccRange or (enemy.radius + Constants.PLAYER_RADIUS + 1.2)
				if dist <= ccRange then
					enemy.ccCooldown = if enemy.isBoss then 5.2 else 6.5
					if rng:NextNumber() < (def.ccChance or 0.70) then
						local applied = PlayerState.applyCrowdControl(
							nearest.state,
							def.ccKind,
							def.ccDuration or 1.4,
							enemy.x,
							enemy.z
						)
						if applied and ccRange > enemy.radius + Constants.PLAYER_RADIUS + 0.5 then
							Replication.queueShockwave(enemy.x, enemy.z, math.min(8.5, ccRange))
						end
					end
				end
			end

			local hitReach = enemy.radius + Constants.PLAYER_RADIUS
			if ai == "Legionnaire" then
				if now < enemy.chargeUntil then
					hitReach += 1.1
				elseif legionThrustCycle >= 0.32 and legionThrustCycle <= 0.56 then
					hitReach += 1.35
				end
			end

			if dist < hitReach then
				local state = nearest.state
				if ai == "Legionnaire" and now < enemy.chargeUntil then
					enemy.chargeUntil = 0
					if PlayerState.applyKnockback(state, enemy.chargeDirX, enemy.chargeDirZ, 6.2) then
						Replication.queueShockwave(nearest.position.X, nearest.position.Z, 5.2)
					end
				end
				if PlayerState.damage(state, enemy.damage) and state.thorns > 0 then
					EnemyService.damage(enemy, state.thorns * state.damageMultiplier, state)
				end
			end
		end
	end

	if activeBoss then
		local def = DEFINITIONS[activeBoss.kind]
		local label = if def and def.displayName then def.displayName else activeBoss.kind
		local pct = math.clamp(activeBoss.health / math.max(1, activeBoss.maxHealth), 0, 1)
		Workspace:SetAttribute("ActiveBossName", label)
		Workspace:SetAttribute("ActiveBossHpPct", pct)
	elseif Workspace:GetAttribute("ActiveBossName") ~= "" then
		Workspace:SetAttribute("ActiveBossName", "")
		Workspace:SetAttribute("ActiveBossHpPct", 0)
	end

	rebuildSpatialGrid()
	separateSpatial()

	local limit = Constants.ARENA_HALF_SIZE - 2
	for _, enemy in enemies do
		local x, z = Arena.resolveObstacle(enemy.x, enemy.z, enemy.radius, 0, enemy.isFlyer)
		enemy.x = math.clamp(x, -limit, limit)
		enemy.z = math.clamp(z, -limit, limit)
	end
end

return EnemyService
