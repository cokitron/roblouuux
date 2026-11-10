--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(script.Parent.Arena)
local EnemyService = require(script.Parent.EnemyService)
local GemService = require(script.Parent.GemService)
local PlayerState = require(script.Parent.PlayerState)
local Replication = require(script.Parent.Replication)
local ServerTypes = require(script.Parent.ServerTypes)
local Constants = require(ReplicatedStorage.Shared.Constants)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Types = require(ReplicatedStorage.Shared.Types)

type State = ServerTypes.State
type Enemy = ServerTypes.Enemy

type Projectile = {
	id: number,
	owner: Player,
	damage: number,
	pierceLeft: number,
	speed: number,
	t0: number,
	ox: number,
	oz: number,
	x: number,
	z: number,
	lastX: number,
	lastZ: number,
	dirX: number,
	dirZ: number,
	overcharge: boolean,
	hit: { [Enemy]: boolean },
}

type FlamePool = {
	x: number,
	z: number,
	radius: number,
	damagePerTick: number,
	expiresAt: number,
	nextTick: number,
	owner: State,
}

type PlayerWeapons = {
	boltCooldown: number,
	cleaveCooldown: number,
	cinderCooldown: number,
	bowCooldown: number,
	pistolCooldown: number,
	stormCooldown: number,
	consecratedTimer: number,
	hallowedPyreTimer: number,
	boltShots: number,
	cleaveSwings: number,
	cinderLobs: number,
	bowShots: number,
	pistolShots: number,
	stormCasts: number,
}

local projectiles: { Projectile } = {}
local flamePools: { FlamePool } = {}
local playerWeapons: { [Player]: PlayerWeapons } = {}
local nextBoltId = 0
local rng = Random.new()

local WeaponService = {}

local function hasWeapon(state: State, wId: string): boolean
	if state.selectedWeapon == wId then
		return true
	end
	return table.find(state.equippedWeapons, wId) ~= nil
end

local function getWeapons(player: Player): PlayerWeapons
	local weapons = playerWeapons[player]
	if not weapons then
		weapons = {
			boltCooldown = 0,
			cleaveCooldown = 0,
			cinderCooldown = 0,
			bowCooldown = 0,
			pistolCooldown = 0,
			stormCooldown = 0,
			consecratedTimer = 0,
			hallowedPyreTimer = 0,
			boltShots = 0,
			cleaveSwings = 0,
			cinderLobs = 0,
			bowShots = 0,
			pistolShots = 0,
			stormCasts = 0,
		}
		playerWeapons[player] = weapons
	end
	return weapons
end

local function onUrnShattered(ux: number, uz: number, state: State)
	GemService.spawn(Vector3.new(ux, 0, uz), 1)
	state.health = math.min(state.maxHealth, state.health + 8)
	state.player:SetAttribute("Health", math.ceil(state.health))
	Replication.queueShockwave(ux, uz, 6)
end

local function segmentDistanceSquared(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number
	local abx = bx - ax
	local abz = bz - az
	local lengthSq = abx * abx + abz * abz
	local t = 0
	if lengthSq > 1e-6 then
		t = math.clamp(((px - ax) * abx + (pz - az) * abz) / lengthSq, 0, 1)
	end
	local dx = px - (ax + abx * t)
	local dz = pz - (az + abz * t)
	return dx * dx + dz * dz
end

-- Selects best enemy in range, penalizing targets obscured behind Tier-1 tall blockers when checkLos is true
local function selectBestTarget(position: Vector3, range: number, checkLos: boolean): Enemy?
	local best: Enemy? = nil
	local bestScore = math.huge
	local rangeSq = range * range
	for _, enemy in EnemyService.getEnemies() do
		if not enemy.dead then
			local dx = enemy.x - position.X
			local dz = enemy.z - position.Z
			local distSq = dx * dx + dz * dz
			if distSq <= rangeSq then
				local score = math.sqrt(distSq)
				if checkLos and not Arena.hasLineOfSight(position.X, position.Z, enemy.x, enemy.z, 1) then
					score += 35
				end
				if score < bestScore then
					best = enemy
					bestScore = score
				end
			end
		end
	end
	return best
end

-- =============================================================================
-- 1. ARCANIST'S STAFF: Magic Bolt (Ranged Sniper + Velocity Lead + 5th-Shot Arcane Lance)
-- =============================================================================
local function updateBolt(state: State, weapons: PlayerWeapons, position: Vector3, dt: number)
	if state.boltCount <= 0 then
		return
	end
	weapons.boltCooldown -= dt
	if weapons.boltCooldown > 0 or #projectiles >= Constants.MAX_PROJECTILES then
		return
	end
	local target = selectBestTarget(position, Constants.BOLT_RANGE * state.boltSpeedMultiplier, true)
	if not target then
		weapons.boltCooldown = 0
		return
	end
	weapons.boltCooldown = Constants.BOLT_COOLDOWN * state.cooldownMultiplier
	weapons.boltShots += 1
	local isOvercharge = (weapons.boltShots % Constants.BOLT_OVERCHARGE_EVERY == 0)

	local speed = Constants.BOLT_SPEED * state.boltSpeedMultiplier
	local rawDx = target.x - position.X
	local rawDz = target.z - position.Z
	local rawDist = math.max(math.sqrt(rawDx * rawDx + rawDz * rawDz), 0.001)
	local tFlight = (rawDist / speed) * Constants.BOLT_LEAD_FACTOR

	local aimX = target.x + target.vx * tFlight
	local aimZ = target.z + target.vz * tFlight
	local dx = aimX - position.X
	local dz = aimZ - position.Z
	local dist = math.max(math.sqrt(dx * dx + dz * dz), 0.001)
	dx /= dist
	dz /= dist

	local count = state.boltCount
	local spread = math.rad(Constants.BOLT_SPREAD_DEGREES)
	local time = GameClock.now()
	local boltDamage = Constants.BOLT_DAMAGE * state.damageMultiplier * (if isOvercharge then 1.75 else 1.0)
	local boltPierce = state.boltPierce + (if isOvercharge then 3 else 0)
	local records: { Types.BoltRecord } = {}
	for i = 1, count do
		local angle = (i - (count + 1) / 2) * spread
		local c = math.cos(angle)
		local s = math.sin(angle)
		local dirX = dx * c - dz * s
		local dirZ = dx * s + dz * c

		nextBoltId += 1
		table.insert(projectiles, {
			id = nextBoltId,
			owner = state.player,
			damage = boltDamage,
			pierceLeft = boltPierce,
			speed = speed,
			t0 = time,
			ox = position.X,
			oz = position.Z,
			x = position.X,
			z = position.Z,
			lastX = position.X,
			lastZ = position.Z,
			dirX = dirX,
			dirZ = dirZ,
			overcharge = isOvercharge,
			hit = {},
		})
		table.insert(records, {
			id = nextBoltId,
			ox = position.X,
			oz = position.Z,
			dx = dirX,
			dz = dirZ,
			t0 = time,
			v = speed,
			overcharge = isOvercharge,
		})
	end
	Replication.fireBolts(records)
end

-- =============================================================================
-- 1B. ARCANIST'S STAFF: Guardian Orb (Orbital Defense)
-- =============================================================================
local function updateOrbs(state: State, position: Vector3)
	local orbCount = state.orbCount
	if orbCount <= 0 then
		return
	end

	local now = GameClock.now()
	local orbRadius = Constants.ORB_RADIUS * state.orbRadiusMultiplier
	local baseAngle = (GameClock.now() * Constants.ORB_SPEED * state.orbSpeedMultiplier) % (math.pi * 2)
	local damage = Constants.ORB_DAMAGE * state.damageMultiplier * state.orbDamageMultiplier
	local enemies = EnemyService.getEnemies()

	for index = 1, orbCount do
		local angle = baseAngle + (index - 1) * math.pi * 2 / orbCount
		local ox = position.X + math.cos(angle) * orbRadius
		local oz = position.Z + math.sin(angle) * orbRadius

		for _, enemy in enemies do
			if not enemy.dead then
				local dx = enemy.x - ox
				local dz = enemy.z - oz
				local reach = enemy.radius + Constants.ORB_HIT_RADIUS
				local lastHit = enemy.orbHitAt[state.player.UserId] or -math.huge
				if dx * dx + dz * dz <= reach * reach and now - lastHit >= Constants.ORB_HIT_INTERVAL then
					enemy.orbHitAt[state.player.UserId] = now
					EnemyService.damage(enemy, damage, state)

					-- Planetary Harmonic: Resonant pulse AoE
					if state.orbResonanceDamage > 0 then
						for _, other in enemies do
							if not other.dead and other ~= enemy then
								local odx = other.x - ox
								local odz = other.z - oz
								if odx * odx + odz * odz <= 6 * 6 then
									EnemyService.damage(other, state.orbResonanceDamage * state.damageMultiplier, state)
								end
							end
						end
					end
				end
			end
		end
	end
end

-- =============================================================================
-- 2. CRYPT CLEAVER: Reaper's Cleave (Directional Frontal Cone + 4th-Swing 360 Maelstrom)
-- =============================================================================
local function updateCleave(state: State, weapons: PlayerWeapons, position: Vector3, lookDir: Vector3, dt: number)
	if not hasWeapon(state, "CryptCleaver") then
		return
	end
	weapons.cleaveCooldown -= dt
	if weapons.cleaveCooldown > 0 then
		return
	end

	local baseReach = Constants.CLEAVE_REACH + state.cleaveReachBonus
	local nearby = selectBestTarget(position, baseReach + 5, false)
	if not nearby then
		weapons.cleaveCooldown = 0
		return
	end
	weapons.cleaveCooldown = Constants.CLEAVE_COOLDOWN * state.cooldownMultiplier * state.cleaveCooldownMultiplier
	weapons.cleaveSwings += 1
	local isOvercharge = (weapons.cleaveSwings % Constants.CLEAVE_MAELSTROM_EVERY == 0)

	local reach = baseReach + (if isOvercharge then 4 else 0)
	-- True directional frontal cone: swings directly in the direction the player faces/moves!
	local lLen = math.sqrt(lookDir.X * lookDir.X + lookDir.Z * lookDir.Z)
	local dirX = if lLen > 0.05 then lookDir.X / lLen else 0
	local dirZ = if lLen > 0.05 then lookDir.Z / lLen else -1

	local arcDeg = if isOvercharge then 360 else (Constants.CLEAVE_ARC_DEGREES + state.cleaveArcBonus)
	local halfArcRad = math.rad(arcDeg * 0.5)
	local cosHalfArc = math.cos(halfArcRad)
	local damage = Constants.CLEAVE_DAMAGE
		* state.damageMultiplier
		* state.cleaveDamageMultiplier
		* (if isOvercharge then 1.5 else 1.0)
	local maxHits = (state.cleavePierce + 1) + (if isOvercharge then 6 else 0)

	Arena.damageUrnsInRadius(position.X, position.Z, reach, damage, function(ux, uz)
		onUrnShattered(ux, uz, state)
	end)

	-- Gather valid candidates inside the frontal cone and sort by ascending distance
	local candidates: { { enemy: Enemy, distSq: number, edx: number, edz: number, edist: number } } = {}
	for _, enemy in EnemyService.getEnemies() do
		if not enemy.dead then
			local edx = enemy.x - position.X
			local edz = enemy.z - position.Z
			local edistSq = edx * edx + edz * edz
			if edistSq <= (reach + enemy.radius) * (reach + enemy.radius) then
				local edist = math.max(math.sqrt(edistSq), 0.001)
				local dot = (edx * dirX + edz * dirZ) / edist
				-- Also catch enemies right on top of the player (edist <= 3.5) so point-blank foes never slip behind the cone vertex
				if isOvercharge or dot >= cosHalfArc or edist <= 3.5 then
					table.insert(candidates, {
						enemy = enemy,
						distSq = edistSq,
						edx = edx,
						edz = edz,
						edist = edist,
					})
				end
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.distSq < b.distSq
	end)

	local hitLimit = math.min(#candidates, maxHits)
	for i = 1, hitLimit do
		local c = candidates[i]
		local enemy = c.enemy
		if state.cleaveExecuteThreshold > 0 and (enemy.health <= 40 * state.cleaveExecuteThreshold) then
			EnemyService.damage(enemy, enemy.health + 100, state, 2)
		else
			EnemyService.damage(enemy, damage, state)
		end
		if isOvercharge and not enemy.dead then
			local kx = enemy.x + (c.edx / c.edist) * 8
			local kz = enemy.z + (c.edz / c.edist) * 8
			enemy.x, enemy.z = Arena.resolveObstacle(kx, kz, enemy.radius, 1, enemy.isFlyer)
		end
	end

	Replication.queueCleave(position.X, position.Z, dirX, dirZ, arcDeg, reach, isOvercharge)
end

-- =============================================================================
-- 2B. CRYPT CLEAVER: Bone Whirlwind (Close Radial Knockback)
-- =============================================================================
local function updateBoneWhirlwind(state: State, position: Vector3)
	local boneCount = state.boneCount
	if boneCount <= 0 then
		return
	end

	local now = GameClock.now()
	local radius = state.boneRadius
	local baseAngle = (now * state.boneSpeed) % (math.pi * 2)
	local damage = Constants.BONE_DAMAGE * state.damageMultiplier * state.boneDamageMultiplier
	local knockback = Constants.BONE_KNOCKBACK * state.boneKnockbackMultiplier
	local enemies = EnemyService.getEnemies()

	for index = 1, boneCount do
		local angle = baseAngle + (index - 1) * math.pi * 2 / boneCount
		local bx = position.X + math.cos(angle) * radius
		local bz = position.Z + math.sin(angle) * radius

		for _, enemy in enemies do
			if not enemy.dead then
				local dx = enemy.x - bx
				local dz = enemy.z - bz
				local reach = enemy.radius + 1.2
				local lastHit = enemy.orbHitAt[state.player.UserId] or -math.huge
				if dx * dx + dz * dz <= reach * reach and now - lastHit >= Constants.BONE_HIT_INTERVAL then
					enemy.orbHitAt[state.player.UserId] = now
					local wasAlive = not enemy.dead
					EnemyService.damage(enemy, damage, state)

					-- Knock enemy radially away from player
					local rdx = enemy.x - position.X
					local rdz = enemy.z - position.Z
					local rdist = math.max(math.sqrt(rdx * rdx + rdz * rdz), 0.001)
					enemy.x += (rdx / rdist) * knockback
					enemy.z += (rdz / rdist) * knockback

					-- Grave Burst detonation if enemy died from bone hit
					if wasAlive and enemy.dead and state.boneShatterDamage > 0 then
						for _, other in enemies do
							if not other.dead and other ~= enemy then
								local odx = other.x - enemy.x
								local odz = other.z - enemy.z
								if odx * odx + odz * odz <= 8 * 8 then
									EnemyService.damage(other, state.boneShatterDamage * state.damageMultiplier, state)
								end
							end
						end
					end
				end
			end
		end
	end
end

-- =============================================================================
-- 3. SOULFLAME LANTERN: Spirit Cinders (Cluster Targeting + 4th-Lob Purgatory Geyser)
-- =============================================================================
local function updateCinders(state: State, weapons: PlayerWeapons, position: Vector3, dt: number)
	if not hasWeapon(state, "SoulflameLantern") or state.cinderClusterCount <= 0 then
		return
	end
	weapons.cinderCooldown -= dt
	if weapons.cinderCooldown > 0 then
		return
	end

	local target = selectBestTarget(position, Constants.CINDER_RANGE, false)
	if not target then
		weapons.cinderCooldown = 0
		return
	end
	weapons.cinderCooldown = Constants.CINDER_COOLDOWN * state.cooldownMultiplier * state.cinderCooldownMultiplier
	weapons.cinderLobs += 1
	local isOvercharge = (weapons.cinderLobs % Constants.CINDER_GEYSER_EVERY == 0)

	local clusterTarget = if isOvercharge
		then (EnemyService.findHighestDensityCluster(position.X, position.Z, Constants.CINDER_RANGE) or target)
		else target

	local now = GameClock.now()
	local clusterCount = state.cinderClusterCount
	local splashRadius = Constants.CINDER_SPLASH_RADIUS
		* state.cinderSplashMultiplier
		* (if isOvercharge then 1.5 else 1.0)
	local poolDuration = Constants.CINDER_POOL_DURATION + state.cinderDurationBonus
	local impactDamage = Constants.CINDER_DAMAGE
		* state.damageMultiplier
		* state.cinderDamageMultiplier
		* (if isOvercharge then 1.5 else 1.0)
	local dotTickDamage = Constants.CINDER_DOT_DAMAGE * state.damageMultiplier * state.cinderDamageMultiplier

	for i = 1, clusterCount do
		local offset = if i == 1 then Vector2.zero else Vector2.new(rng:NextNumber(-4, 4), rng:NextNumber(-4, 4))
		local tx = clusterTarget.x + offset.X
		local tz = clusterTarget.z + offset.Y

		-- Create ground burn pool
		table.insert(flamePools, {
			x = tx,
			z = tz,
			radius = splashRadius,
			damagePerTick = dotTickDamage,
			expiresAt = now + poolDuration,
			nextTick = now + 0.3,
			owner = state,
		})

		Arena.damageUrnsInRadius(tx, tz, splashRadius, impactDamage, function(ux, uz)
			onUrnShattered(ux, uz, state)
		end)

		-- Immediate direct impact damage in splash zone
		local enemies = EnemyService.getEnemies()
		for _, enemy in enemies do
			if not enemy.dead then
				local dx = enemy.x - tx
				local dz = enemy.z - tz
				if dx * dx + dz * dz <= splashRadius * splashRadius then
					EnemyService.damage(enemy, impactDamage, state)
					if isOvercharge and not enemy.dead then
						EnemyService.applySlow(enemy, 0.35, 2.5)
					end
				end
			end
		end

		Replication.queueCinder(position.X, position.Z, tx, tz, splashRadius, poolDuration, isOvercharge)
	end
end

-- =============================================================================
-- 3B. SOULFLAME LANTERN: Consecrated Ground (Sanctified Soil Aura)
-- =============================================================================
local function updateConsecratedGround(state: State, weapons: PlayerWeapons, position: Vector3, dt: number)
	local radius = state.consecratedRadius
	if radius <= 0 then
		return
	end

	weapons.consecratedTimer -= dt
	weapons.hallowedPyreTimer -= dt

	local enemies = EnemyService.getEnemies()
	local radSq = radius * radius

	-- Apply non-destructive temporary slow to foes standing on sacred ground (restores baseSpeed outside)
	if state.consecratedSlowMultiplier > 0 then
		for _, enemy in enemies do
			if not enemy.dead then
				local dx = enemy.x - position.X
				local dz = enemy.z - position.Z
				if dx * dx + dz * dz <= radSq then
					EnemyService.applySlow(enemy, state.consecratedSlowMultiplier, 0.5)
				end
			end
		end
	end

	-- Periodic sanctified fire burn tick
	if weapons.consecratedTimer <= 0 then
		weapons.consecratedTimer = Constants.CONSECRATED_INTERVAL
		local damage = Constants.CONSECRATED_DAMAGE * state.damageMultiplier * state.consecratedDamageMultiplier
		for _, enemy in enemies do
			if not enemy.dead then
				local dx = enemy.x - position.X
				local dz = enemy.z - position.Z
				if dx * dx + dz * dz <= radSq then
					EnemyService.damage(enemy, damage, state)
				end
			end
		end
	end

	-- Judgment Sigil pulse every 4 seconds
	if state.hallowedPyreDamage > 0 and weapons.hallowedPyreTimer <= 0 then
		weapons.hallowedPyreTimer = 4.0
		local pyreDamage = state.hallowedPyreDamage * state.damageMultiplier
		for _, enemy in enemies do
			if not enemy.dead then
				local dx = enemy.x - position.X
				local dz = enemy.z - position.Z
				if dx * dx + dz * dz <= radSq then
					EnemyService.damage(enemy, pyreDamage, state)
				end
			end
		end
		Replication.queueShockwave(position.X, position.Z, radius)
	end
end

-- =============================================================================
-- 4. PHANTOM LONGBOW: Spectral Arrow Volley (Piercing Fan + 4th-Shot Gale Barrage)
-- =============================================================================
local function updateBow(state: State, weapons: PlayerWeapons, position: Vector3, dt: number)
	if not hasWeapon(state, "PhantomBow") or state.bowCount <= 0 then
		return
	end
	weapons.bowCooldown -= dt
	if weapons.bowCooldown > 0 or #projectiles >= Constants.MAX_PROJECTILES then
		return
	end
	local target = selectBestTarget(position, Constants.BOW_RANGE, true)
	if not target then
		weapons.bowCooldown = 0
		return
	end
	weapons.bowCooldown = Constants.BOW_COOLDOWN * state.cooldownMultiplier * state.bowCooldownMultiplier
	weapons.bowShots += 1
	local isOvercharge = (weapons.bowShots % Constants.BOW_BARRAGE_EVERY == 0)

	local speed = Constants.BOW_SPEED * state.boltSpeedMultiplier
	local rawDx = target.x - position.X
	local rawDz = target.z - position.Z
	local rawDist = math.max(math.sqrt(rawDx * rawDx + rawDz * rawDz), 0.001)
	local tFlight = (rawDist / speed) * Constants.BOLT_LEAD_FACTOR

	local aimX = target.x + target.vx * tFlight
	local aimZ = target.z + target.vz * tFlight
	local dx = aimX - position.X
	local dz = aimZ - position.Z
	local dist = math.max(math.sqrt(dx * dx + dz * dz), 0.001)
	dx /= dist
	dz /= dist

	local count = state.bowCount + (if isOvercharge then 2 else 0)
	local spread = math.rad(Constants.BOW_SPREAD_DEGREES)
	local time = GameClock.now()
	local arrowDamage = Constants.BOW_DAMAGE
		* state.damageMultiplier
		* state.bowDamageMultiplier
		* (if isOvercharge then 1.4 else 1.0)
	local arrowPierce = state.bowPierce + (if isOvercharge then 2 else 0)
	local records: { Types.BoltRecord } = {}

	for i = 1, count do
		local angle = (i - (count + 1) / 2) * spread
		local c = math.cos(angle)
		local s = math.sin(angle)
		local dirX = dx * c - dz * s
		local dirZ = dx * s + dz * c

		nextBoltId += 1
		table.insert(projectiles, {
			id = nextBoltId,
			owner = state.player,
			damage = arrowDamage,
			pierceLeft = arrowPierce,
			speed = speed,
			t0 = time,
			ox = position.X,
			oz = position.Z,
			x = position.X,
			z = position.Z,
			lastX = position.X,
			lastZ = position.Z,
			dirX = dirX,
			dirZ = dirZ,
			overcharge = isOvercharge,
			hit = {},
		})
		table.insert(records, {
			id = nextBoltId,
			ox = position.X,
			oz = position.Z,
			dx = dirX,
			dz = dirZ,
			t0 = time,
			v = speed,
			overcharge = isOvercharge,
			kind = "Arrow",
		})
	end
	Replication.fireBolts(records)
end

-- =============================================================================
-- 5. HEXLOCK PISTOLS: Twin Silver Bullets + 6th-Shot 360 Fan-of-Guns
-- =============================================================================
local function updatePistols(state: State, weapons: PlayerWeapons, position: Vector3, dt: number)
	if not hasWeapon(state, "HexlockPistols") or state.pistolCount <= 0 then
		return
	end
	weapons.pistolCooldown -= dt
	if weapons.pistolCooldown > 0 or #projectiles >= Constants.MAX_PROJECTILES then
		return
	end
	local target = selectBestTarget(position, Constants.PISTOL_RANGE, true)
	if not target then
		weapons.pistolCooldown = 0
		return
	end
	weapons.pistolCooldown = Constants.PISTOL_COOLDOWN * state.cooldownMultiplier * state.pistolCooldownMultiplier
	weapons.pistolShots += 1
	local isOvercharge = (weapons.pistolShots % Constants.PISTOL_FAN_EVERY == 0)

	local speed = Constants.PISTOL_SPEED * state.boltSpeedMultiplier
	local dx = target.x - position.X
	local dz = target.z - position.Z
	local dist = math.max(math.sqrt(dx * dx + dz * dz), 0.001)
	dx /= dist
	dz /= dist

	local count = if isOvercharge then math.max(8, state.pistolCount + 4) else state.pistolCount
	local spread = if isOvercharge then (math.pi * 2 / count) else math.rad(7)
	local time = GameClock.now()
	local bulletDamage = Constants.PISTOL_DAMAGE
		* state.damageMultiplier
		* state.pistolDamageMultiplier
		* (if isOvercharge then 1.35 else 1.0)
	local bulletPierce = state.pistolPierce + (if isOvercharge then 2 else 0)
	local records: { Types.BoltRecord } = {}

	for i = 1, count do
		local angle = if isOvercharge then (i - 1) * spread else (i - (count + 1) / 2) * spread
		local c = math.cos(angle)
		local s = math.sin(angle)
		local dirX = dx * c - dz * s
		local dirZ = dx * s + dz * c

		nextBoltId += 1
		table.insert(projectiles, {
			id = nextBoltId,
			owner = state.player,
			damage = bulletDamage,
			pierceLeft = bulletPierce,
			speed = speed,
			t0 = time,
			ox = position.X,
			oz = position.Z,
			x = position.X,
			z = position.Z,
			lastX = position.X,
			lastZ = position.Z,
			dirX = dirX,
			dirZ = dirZ,
			overcharge = isOvercharge,
			hit = {},
		})
		table.insert(records, {
			id = nextBoltId,
			ox = position.X,
			oz = position.Z,
			dx = dirX,
			dz = dirZ,
			t0 = time,
			v = speed,
			overcharge = isOvercharge,
			kind = "Bullet",
		})
	end
	Replication.fireBolts(records)
end

-- =============================================================================
-- 6. STORMCALLER GRIMOIRE: Bouncing Chain Lightning + 4th-Cast Sky Thunderbolt
-- =============================================================================
local function updateStorm(state: State, weapons: PlayerWeapons, position: Vector3, dt: number)
	if not hasWeapon(state, "StormcallerTome") or state.stormChains <= 0 then
		return
	end
	weapons.stormCooldown -= dt
	if weapons.stormCooldown > 0 then
		return
	end
	local first = selectBestTarget(position, Constants.STORM_RANGE, false)
	if not first then
		weapons.stormCooldown = 0
		return
	end
	weapons.stormCooldown = Constants.STORM_COOLDOWN * state.cooldownMultiplier * state.stormCooldownMultiplier
	weapons.stormCasts += 1
	local isOvercharge = (weapons.stormCasts % Constants.STORM_CATACLYSM_EVERY == 0)

	local maxChains = state.stormChains + (if isOvercharge then 2 else 0)
	local damage = Constants.STORM_DAMAGE
		* state.damageMultiplier
		* state.stormDamageMultiplier
		* (if isOvercharge then 1.5 else 1.0)
	local hitSet: { [Enemy]: boolean } = {}
	local enemies = EnemyService.getEnemies()

	local curr: Enemy? = if isOvercharge
		then (EnemyService.findHighestDensityCluster(position.X, position.Z, Constants.STORM_RANGE) or first)
		else first
	local prevX, prevZ = position.X, position.Z

	for bounce = 1, maxChains do
		if not curr then
			break
		end
		hitSet[curr] = true
		Replication.queueLightning(prevX, prevZ, curr.x, curr.z, isOvercharge and bounce == 1)
		EnemyService.damage(curr, damage, state)

		if isOvercharge and bounce == 1 then
			Replication.queueShockwave(curr.x, curr.z, 10)
			for _, other in enemies do
				if not other.dead and other ~= curr then
					local odx = other.x - curr.x
					local odz = other.z - curr.z
					if odx * odx + odz * odz <= 10 * 10 then
						EnemyService.damage(other, damage * 0.65, state)
					end
				end
			end
		end

		prevX, prevZ = curr.x, curr.z
		local nextTarget: Enemy? = nil
		local bestDistSq = Constants.STORM_CHAIN_RADIUS * Constants.STORM_CHAIN_RADIUS
		for _, candidate in enemies do
			if not candidate.dead and not hitSet[candidate] then
				local cdx = candidate.x - prevX
				local cdz = candidate.z - prevZ
				local dSq = cdx * cdx + cdz * cdz
				if dSq <= bestDistSq then
					bestDistSq = dSq
					nextTarget = candidate
				end
			end
		end
		curr = nextTarget
	end
end

-- =============================================================================
-- Active Flame Pools Step (DoT ticks)
-- =============================================================================
local function updateFlamePools()
	local now = GameClock.now()
	local enemies = EnemyService.getEnemies()
	for i = #flamePools, 1, -1 do
		local pool = flamePools[i]
		if now >= pool.expiresAt then
			table.remove(flamePools, i)
		elseif now >= pool.nextTick then
			pool.nextTick = now + 0.35
			local radSq = pool.radius * pool.radius
			for _, enemy in enemies do
				if not enemy.dead then
					local dx = enemy.x - pool.x
					local dz = enemy.z - pool.z
					if dx * dx + dz * dz <= radSq then
						EnemyService.damage(enemy, pool.damagePerTick, pool.owner)
					end
				end
			end
		end
	end
end

-- =============================================================================
-- Active Bolt Projectiles Step (Tier-1 Obstacle Collision + Destructible Urns)
-- =============================================================================
local function updateProjectiles()
	local enemies = EnemyService.getEnemies()
	local now = GameClock.now()
	for i = #projectiles, 1, -1 do
		local projectile = projectiles[i]
		local age = now - projectile.t0
		local travelled = projectile.speed * math.min(age, Constants.BOLT_LIFETIME)
		projectile.lastX = projectile.x
		projectile.lastZ = projectile.z
		projectile.x = projectile.ox + projectile.dirX * travelled
		projectile.z = projectile.oz + projectile.dirZ * travelled

		local ownerState = PlayerState.get(projectile.owner)
		if ownerState then
			Arena.damageUrnsInRadius(projectile.x, projectile.z, 2.2, projectile.damage, function(ux, uz)
				onUrnShattered(ux, uz, ownerState)
			end)
		end

		local remove = age >= Constants.BOLT_LIFETIME
		-- Shatter against Tier-1 Tall Buildings/Obelisks while flying cleanly over Tier-2 Low Cover
		if not remove and Arena.isPointBlocked(projectile.x, projectile.z, 0.45, 1) then
			remove = true
			Replication.queueBoltRemoved(projectile.id)
		end

		if not remove then
			for _, enemy in enemies do
				if not enemy.dead and not projectile.hit[enemy] then
					local reach = enemy.radius + Constants.BOLT_HIT_RADIUS
					local distSq = segmentDistanceSquared(
						enemy.x,
						enemy.z,
						projectile.lastX,
						projectile.lastZ,
						projectile.x,
						projectile.z
					)
					if distSq <= reach * reach then
						projectile.hit[enemy] = true
						EnemyService.damage(enemy, projectile.damage, ownerState)
						-- Overcharged Arcane Lance detonates a 5.5-stud splash pulse on hit
						if projectile.overcharge then
							for _, other in enemies do
								if not other.dead and other ~= enemy then
									local odx = other.x - enemy.x
									local odz = other.z - enemy.z
									if odx * odx + odz * odz <= 5.5 * 5.5 then
										EnemyService.damage(other, projectile.damage * 0.5, ownerState)
									end
								end
							end
						end
						if projectile.pierceLeft <= 0 then
							remove = true
							Replication.queueBoltRemoved(projectile.id)
							break
						end
						projectile.pierceLeft -= 1
					end
				end
			end
		end

		if remove then
			table.remove(projectiles, i)
		end
	end
end

function WeaponService.step(dt: number)
	local alive: { [Player]: boolean } = {}
	for _, target in PlayerState.getTargets() do
		local state = target.state
		local player = state.player
		alive[player] = true
		local weapons = getWeapons(player)

		updateBolt(state, weapons, target.position, dt)
		updateOrbs(state, target.position)
		updateCleave(state, weapons, target.position, target.lookDir, dt)
		updateBoneWhirlwind(state, target.position)
		updateCinders(state, weapons, target.position, dt)
		updateConsecratedGround(state, weapons, target.position, dt)
		updateBow(state, weapons, target.position, dt)
		updatePistols(state, weapons, target.position, dt)
		updateStorm(state, weapons, target.position, dt)
	end

	-- Sanctuary Chapel East Transept Combat Training Yard (Live Dummy Practice + DPS Meter)
	local dummies = Arena.getTrainingDummies()
	if #dummies > 0 then
		for _, player in Players:GetPlayers() do
			local state = PlayerState.get(player)
			if state and state.phase == "Lobby" then
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if root and root:IsA("BasePart") then
					local pos = root.Position
					local nearestDummy = nil
					local bestDistSq = 25 * 25
					for _, d in dummies do
						local dx = d.x - pos.X
						local dz = d.z - pos.Z
						local dSq = dx * dx + dz * dz
						if dSq <= bestDistSq then
							bestDistSq = dSq
							nearestDummy = d
						end
					end

					if nearestDummy then
						alive[player] = true
						local weapons = getWeapons(player)
						weapons.boltCooldown = math.max(0, weapons.boltCooldown - dt)
						if weapons.boltCooldown <= 0 then
							local wId = state.selectedWeapon
							local cd = 0.72 * state.cooldownMultiplier
							local rawDmg = Constants.BOLT_DAMAGE * state.damageMultiplier
							if wId == "CryptCleaver" then
								cd = Constants.CLEAVE_COOLDOWN * state.cooldownMultiplier
								rawDmg = Constants.CLEAVE_DAMAGE * state.damageMultiplier
							elseif wId == "SoulflameLantern" then
								cd = Constants.CINDER_COOLDOWN * state.cooldownMultiplier
								rawDmg = Constants.CINDER_DAMAGE * state.damageMultiplier
							elseif wId == "PhantomBow" then
								cd = Constants.BOW_COOLDOWN * state.cooldownMultiplier
								rawDmg = Constants.BOW_DAMAGE * state.damageMultiplier
							elseif wId == "HexlockPistols" then
								cd = Constants.PISTOL_COOLDOWN * state.cooldownMultiplier
								rawDmg = Constants.PISTOL_DAMAGE * state.damageMultiplier
							elseif wId == "StormcallerTome" then
								cd = Constants.STORM_COOLDOWN * state.cooldownMultiplier
								rawDmg = Constants.STORM_DAMAGE * state.damageMultiplier
							end
							weapons.boltCooldown = math.max(0.22, cd)
							weapons.boltShots += 1
							local isOvercharge = (weapons.boltShots % 4 == 0)
							local isCrit = rng:NextNumber() < state.critChance
							local critMult = if isCrit then state.critMultiplier else 1.0
							local finalDmg =
								math.max(1, math.floor(rawDmg * critMult * (if isOvercharge then 1.45 else 1.0) + 0.5))
							local critTier = if isCrit then (if isOvercharge then 2 else 1) else 0

							local dx = nearestDummy.x - pos.X
							local dz = nearestDummy.z - pos.Z
							local dist = math.max(math.sqrt(dx * dx + dz * dz), 0.001)
							local dirX, dirZ = dx / dist, dz / dist

							if wId == "CryptCleaver" then
								Replication.queueCleave(pos.X, pos.Z, dirX, dirZ, 125, 14, isOvercharge)
							elseif wId == "SoulflameLantern" then
								Replication.queueCinder(
									pos.X,
									pos.Z,
									nearestDummy.x,
									nearestDummy.z,
									6,
									1.5,
									isOvercharge
								)
							elseif wId == "StormcallerTome" then
								Replication.queueLightning(pos.X, pos.Z, nearestDummy.x, nearestDummy.z, isOvercharge)
								for _, otherD in dummies do
									if otherD ~= nearestDummy then
										Replication.queueLightning(
											nearestDummy.x,
											nearestDummy.z,
											otherD.x,
											otherD.z,
											false
										)
										Replication.queueHit(
											900 + otherD.id,
											math.floor(finalDmg * 0.75),
											critTier,
											otherD.x,
											otherD.z
										)
										Arena.recordDummyHit(math.floor(finalDmg * 0.75), isCrit)
									end
								end
							else
								nextBoltId += 1
								local kind = if wId == "PhantomBow"
									then "Arrow"
									elseif wId == "HexlockPistols" then "Bullet"
									else nil
								Replication.fireBolts({
									{
										id = nextBoltId,
										ox = pos.X,
										oz = pos.Z,
										dx = dirX,
										dz = dirZ,
										t0 = GameClock.now(),
										v = 56,
										overcharge = isOvercharge,
										kind = kind,
									},
								})
							end

							Replication.queueHit(
								900 + nearestDummy.id,
								finalDmg,
								critTier,
								nearestDummy.x,
								nearestDummy.z
							)
							Arena.recordDummyHit(finalDmg, isCrit)
						end
					end
				end
			end
		end
	end

	for player in playerWeapons do
		if not alive[player] then
			playerWeapons[player] = nil
		end
	end

	updateProjectiles()
	updateFlamePools()
end

function WeaponService.removePlayer(player: Player)
	playerWeapons[player] = nil
end

function WeaponService.clearAll()
	table.clear(projectiles)
	table.clear(flamePools)
	table.clear(playerWeapons)
end

return WeaponService
