--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(script.Parent.Arena)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local GemService = require(script.Parent.GemService)
local PlayerState = require(script.Parent.PlayerState)
local Replication = require(script.Parent.Replication)
local WeaponService = require(script.Parent.WeaponService)
local Constants = require(ReplicatedStorage.Shared.Constants)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local RpgConfig = require(ReplicatedStorage.Shared.RpgConfig)

local rng = Random.new()
local roundStart: number? = nil
local spawnTimer = 0
local formationTimer = 0
local spawnedMilestones: { [string]: boolean } = {}

local BOSS_SCHEDULE = {
	{ time = 180, kind = "GraveReaper" },
	{ time = 360, kind = "HollowArmor" },
	{ time = 540, kind = "OssuaryBehemoth" },
	{ time = 600, kind = "LichLord" },
}

local EARLY_MONSTERS = {
	"Skeleton",
	"Bat",
	"Spider",
	"Wisp",
	"PlagueSlime",
	"InfernalImp",
	"CryptGhoul",
	"BoneHound",
	"CandelabraMimic",
}

local MID_ELITE_MONSTERS = {
	"AbyssalWatcher",
	"NecromancerAcolyte",
	"BansheeShrieker",
	"FrostWyrm",
	"Golem",
	"DeathKnight",
}

local Director = {}

local function pickKind(elapsed: number): string
	local eliteChance = math.min(0.14 + elapsed / 450, 0.42)
	if rng:NextNumber() < eliteChance then
		return MID_ELITE_MONSTERS[rng:NextInteger(1, #MID_ELITE_MONSTERS)]
	end
	return EARLY_MONSTERS[rng:NextInteger(1, #EARLY_MONSTERS)]
end

local function resetRound()
	roundStart = nil
	spawnTimer = 0
	formationTimer = 0
	table.clear(spawnedMilestones)
	EnemyService.clearAll()
	GemService.clearAll()
	WeaponService.clearAll()
	Arena.rebuild()
end

local function clampAndResolveSpawn(x: number, z: number): (number, number)
	local limit = Constants.ARENA_HALF_SIZE - 4
	local cx = math.clamp(x, -limit, limit)
	local cz = math.clamp(z, -limit, limit)
	return Arena.resolveObstacle(cx, cz, 2.0, 1, false)
end

-- Spawns coordinated tactical wave formations (Bone Phalanx, Nightwing Swoop, Crypt Encirclement)
local function spawnFormation(target: PlayerState.Target, healthMultiplier: number)
	if EnemyService.count() >= Constants.MAX_ENEMIES then
		return
	end
	local formType = rng:NextInteger(1, 3)
	local pos = target.position
	local vel = target.velocity
	local baseAngle = rng:NextNumber(0, math.pi * 2)
	if vel.X * vel.X + vel.Z * vel.Z > 1.5 then
		baseAngle = math.atan2(vel.Z, vel.X)
	end

	if formType == 1 then
		-- 1. Bone Phalanx: Crescent shield-wall arc ahead of player's heading + 1 DeathKnight captain
		for i = -2, 2 do
			if EnemyService.count() >= Constants.MAX_ENEMIES then
				break
			end
			local a = baseAngle + i * math.rad(16)
			local sx, sz = clampAndResolveSpawn(pos.X + math.cos(a) * 42, pos.Z + math.sin(a) * 42)
			EnemyService.spawn("Skeleton", Vector3.new(sx, 0, sz), healthMultiplier)
		end
		if EnemyService.count() < Constants.MAX_ENEMIES then
			local cx, cz = clampAndResolveSpawn(pos.X + math.cos(baseAngle) * 46, pos.Z + math.sin(baseAngle) * 46)
			EnemyService.spawn("DeathKnight", Vector3.new(cx, 0, cz), healthMultiplier)
		end
	elseif formType == 2 then
		-- 2. Nightwing Swoop: V-flank of 6 fast flyers at +/-55 degrees
		local flyerKind = if rng:NextNumber() < 0.5 then "Bat" else "Wisp"
		for wing = -1, 1, 2 do
			local wingAngle = baseAngle + wing * math.rad(55)
			for rank = 1, 3 do
				if EnemyService.count() >= Constants.MAX_ENEMIES then
					break
				end
				local dist = 44 + rank * 3.5
				local a = wingAngle + (rank - 2) * math.rad(7)
				local sx = math.clamp(
					pos.X + math.cos(a) * dist,
					-(Constants.ARENA_HALF_SIZE - 4),
					Constants.ARENA_HALF_SIZE - 4
				)
				local sz = math.clamp(
					pos.Z + math.sin(a) * dist,
					-(Constants.ARENA_HALF_SIZE - 4),
					Constants.ARENA_HALF_SIZE - 4
				)
				EnemyService.spawn(flyerKind, Vector3.new(sx, 0, sz), healthMultiplier)
			end
		end
	else
		-- 3. Crypt Encirclement: 6 CryptGhoul / Spider in a 360-degree ring at 44 studs
		local ringKind = if rng:NextNumber() < 0.5 then "CryptGhoul" else "Spider"
		for i = 1, 6 do
			if EnemyService.count() >= Constants.MAX_ENEMIES then
				break
			end
			local a = baseAngle + (i - 1) * (math.pi * 2 / 6)
			local sx, sz = clampAndResolveSpawn(pos.X + math.cos(a) * 44, pos.Z + math.sin(a) * 44)
			EnemyService.spawn(ringKind, Vector3.new(sx, 0, sz), healthMultiplier)
		end
	end
end

local function computeHealthMultiplier(elapsed: number, keystoneLevel: number): number
	local kInfo = RpgConfig.getKeystoneInfo(keystoneLevel)
	local timeMult = 1 + (elapsed / 65) + (elapsed / 150) ^ 1.65
	local powerRatio = PlayerState.getMaxOffensivePowerRatio(elapsed)
	local adaptiveMult = math.clamp(math.sqrt(math.max(1.0, powerRatio)), 1.0, 2.35)
	return timeMult * adaptiveMult * kInfo.enemyMult
end

function Director.summonNextBoss(position: Vector3, keystoneLevel: number)
	local now = GameClock.now()
	local elapsed = if roundStart then math.max(0, now - roundStart) else 60
	local mult = computeHealthMultiplier(elapsed, keystoneLevel)
	for _, entry in ipairs(BOSS_SCHEDULE) do
		if not spawnedMilestones[entry.kind] then
			spawnedMilestones[entry.kind] = true
			local x, z = EnemyService.randomRingPosition(position)
			EnemyService.spawn(entry.kind, Vector3.new(x, 0, z), mult)
			return
		end
	end
	local x, z = EnemyService.randomRingPosition(position)
	EnemyService.spawn("LichLord", Vector3.new(x, 0, z), mult * 1.25)
end

function Director.summonMonsterKind(position: Vector3, kind: string, keystoneLevel: number)
	if EnemyService.count() >= Constants.MAX_ENEMIES then
		return
	end
	local now = GameClock.now()
	local elapsed = if roundStart then math.max(0, now - roundStart) else 30
	local mult = computeHealthMultiplier(elapsed, keystoneLevel)
	local isBoss = kind == "GraveReaper" or kind == "HollowArmor" or kind == "OssuaryBehemoth" or kind == "LichLord"
	local count = if isBoss then 1 else math.min(4, Constants.MAX_ENEMIES - EnemyService.count())
	for _ = 1, count do
		local x, z = EnemyService.randomRingPosition(position)
		EnemyService.spawn(kind, Vector3.new(x, 0, z), mult)
	end
end

function Director.step(dt: number)
	if not PlayerState.hasActiveRunners() then
		if roundStart ~= nil then
			resetRound()
		end
		return
	end
	local targets = PlayerState.getTargets()
	if #targets == 0 then
		return
	end

	local now = GameClock.now()
	local start = roundStart or now
	roundStart = start
	local elapsed = now - start

	local maxKeystone = 0
	for _, target in targets do
		local profile = DataService.getProfile(target.state.player)
		if profile and profile.selectedKeystone > maxKeystone then
			maxKeystone = profile.selectedKeystone
		end
	end
	local healthMultiplier = computeHealthMultiplier(elapsed, maxKeystone)

	-- Interactive Landmark Soul Brazier Shrines
	Arena.stepShrines(dt, targets, function(shrine, capturer)
		PlayerState.grantShrineBlessing(capturer.state)
		Replication.queueShockwave(shrine.x, shrine.z, 18)
		-- Summon Elite Shrine Guardian Pack around the ignited Brazier
		if EnemyService.count() < Constants.MAX_ENEMIES then
			local eliteKind = MID_ELITE_MONSTERS[rng:NextInteger(1, #MID_ELITE_MONSTERS)]
			local ex, ez = clampAndResolveSpawn(shrine.x + 8, shrine.z)
			Replication.queueEmergence(ex, ez)
			EnemyService.spawn(eliteKind, Vector3.new(ex, 0, ez), healthMultiplier * 1.15)
		end
		for i = 1, 3 do
			if EnemyService.count() >= Constants.MAX_ENEMIES then
				break
			end
			local a = (i - 1) * (math.pi * 2 / 3)
			local gx, gz = clampAndResolveSpawn(shrine.x + math.cos(a) * 10, shrine.z + math.sin(a) * 10)
			Replication.queueEmergence(gx, gz)
			local guardKind = EARLY_MONSTERS[rng:NextInteger(1, #EARLY_MONSTERS)]
			EnemyService.spawn(guardKind, Vector3.new(gx, 0, gz), healthMultiplier)
		end
	end)

	-- Timed 3m / 6m / 9m Mini-Bosses & 10m Stage Boss Climax (LOOP-4)
	for _, entry in ipairs(BOSS_SCHEDULE) do
		if elapsed >= entry.time and not spawnedMilestones[entry.kind] then
			spawnedMilestones[entry.kind] = true
			local target = targets[rng:NextInteger(1, #targets)]
			local bx, bz = EnemyService.randomRingPosition(target.position)
			EnemyService.spawn(entry.kind, Vector3.new(bx, 0, bz), healthMultiplier)
		end
	end

	-- Tactical Wave Formations every FORMATION_INTERVAL seconds
	formationTimer += dt
	if formationTimer >= Constants.FORMATION_INTERVAL and elapsed >= 20 then
		formationTimer = 0
		local target = targets[rng:NextInteger(1, #targets)]
		spawnFormation(target, healthMultiplier)
	end

	spawnTimer += dt
	if spawnTimer < Constants.SPAWN_INTERVAL then
		return
	end
	spawnTimer = 0

	local crowd = 1 + 0.5 * (#targets - 1)
	local desired = math.min(
		Constants.MAX_ENEMIES,
		math.floor((Constants.BASE_ENEMIES + elapsed * Constants.ENEMIES_PER_SECOND) * crowd)
	)
	local toSpawn = math.min(desired - EnemyService.count(), Constants.SPAWN_BATCH)
	for _ = 1, toSpawn do
		local target = targets[rng:NextInteger(1, #targets)]
		local kind = pickKind(elapsed)
		if rng:NextNumber() < Constants.GRAVE_EMERGE_CHANCE then
			local gx, gz, emerged = EnemyService.pickEmergencePosition(target.position)
			if emerged then
				Replication.queueEmergence(gx, gz)
			end
			EnemyService.spawn(kind, Vector3.new(gx, 0, gz), healthMultiplier)
		else
			local x, z
			if elapsed < 35 then
				-- Tighter early-run ring so first auto-attack lands within 10s (LOOP-1)
				x, z = EnemyService.randomRingPosition(
					target.position,
					Constants.SPAWN_EARLY_RADIUS_MIN,
					Constants.SPAWN_EARLY_RADIUS_MAX
				)
			else
				x, z = EnemyService.randomRingPosition(target.position)
			end
			EnemyService.spawn(kind, Vector3.new(x, 0, z), healthMultiplier)
		end
	end
end

return Director
