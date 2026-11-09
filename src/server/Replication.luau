--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerTypes = require(script.Parent.ServerTypes)
local Constants = require(ReplicatedStorage.Shared.Constants)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

-- Snapshot packet: f64 gameTime, u16 count, then count * (u16 id, u8 kind, f32 x, f32 z).
local HEADER_BYTES = Constants.SNAPSHOT_HEADER_BYTES
local ENTRY_BYTES = Constants.SNAPSHOT_ENTRY_BYTES
local UNRELIABLE_PAYLOAD_LIMIT = 900

assert(
	HEADER_BYTES + Constants.SNAPSHOT_CHUNK * ENTRY_BYTES <= UNRELIABLE_PAYLOAD_LIMIT,
	"SNAPSHOT_CHUNK would exceed the UnreliableRemoteEvent payload limit"
)

local snapshotEvent = Remotes.getUnreliable("EnemySnapshot")
local worldEvents = Remotes.get("WorldEvents")
local boltsFired = Remotes.get("BoltsFired")

local hits: { Types.HitEvent } = {}
local hitById: { [number]: Types.HitEvent } = {}
local kills: { number } = {}
local removedBolts: { number } = {}
local shockwaves: { Types.ShockwaveEvent } = {}
local cleaves: { Types.CleaveEvent } = {}
local cinders: { Types.CinderEvent } = {}
local emergences: { Types.EmergenceEvent } = {}
local lightnings: { Types.LightningEvent } = {}
local clearRequested = false
local snapshotTimer = 0

local Replication = {}

function Replication.queueHit(id: number, dmg: number, crit: number, x: number, z: number)
	local existing = hitById[id]
	if existing then
		existing.dmg += dmg
		existing.crit = math.max(existing.crit, crit)
		existing.x = x
		existing.z = z
	else
		local entry: Types.HitEvent = { id = id, dmg = dmg, crit = crit, x = x, z = z }
		hitById[id] = entry
		table.insert(hits, entry)
	end
end

function Replication.queueKill(id: number)
	table.insert(kills, id)
end

function Replication.queueBoltRemoved(id: number)
	table.insert(removedBolts, id)
end

function Replication.queueShockwave(x: number, z: number, radius: number)
	table.insert(shockwaves, { x = x, z = z, radius = radius })
end

function Replication.queueCleave(
	ox: number,
	oz: number,
	dirX: number,
	dirZ: number,
	arc: number,
	radius: number,
	overcharge: boolean?
)
	table.insert(
		cleaves,
		{ ox = ox, oz = oz, dirX = dirX, dirZ = dirZ, arc = arc, radius = radius, overcharge = overcharge }
	)
end

function Replication.queueCinder(
	ox: number,
	oz: number,
	tx: number,
	tz: number,
	splashRadius: number,
	duration: number,
	overcharge: boolean?
)
	table.insert(cinders, {
		ox = ox,
		oz = oz,
		tx = tx,
		tz = tz,
		splashRadius = splashRadius,
		duration = duration,
		overcharge = overcharge,
	})
end

function Replication.queueEmergence(x: number, z: number)
	table.insert(emergences, { x = x, z = z })
end

function Replication.queueLightning(x1: number, z1: number, x2: number, z2: number, overcharge: boolean?)
	table.insert(lightnings, { x1 = x1, z1 = z1, x2 = x2, z2 = z2, overcharge = overcharge })
end

function Replication.queueClear()
	clearRequested = true
end

function Replication.fireBolts(records: { Types.BoltRecord })
	boltsFired:FireAllClients(records)
end

local function flushEvents()
	if
		#hits == 0
		and #kills == 0
		and #removedBolts == 0
		and #shockwaves == 0
		and #cleaves == 0
		and #cinders == 0
		and #emergences == 0
		and #lightnings == 0
		and not clearRequested
	then
		return
	end
	local payload: Types.WorldEventsPayload = {
		t = GameClock.now(),
		hits = hits,
		kills = kills,
		bolts = removedBolts,
		shockwaves = if #shockwaves > 0 then shockwaves else nil,
		cleaves = if #cleaves > 0 then cleaves else nil,
		cinders = if #cinders > 0 then cinders else nil,
		emergences = if #emergences > 0 then emergences else nil,
		lightnings = if #lightnings > 0 then lightnings else nil,
		clear = clearRequested,
	}
	worldEvents:FireAllClients(payload)
	hits = {}
	table.clear(hitById)
	kills = {}
	removedBolts = {}
	shockwaves = {}
	cleaves = {}
	cinders = {}
	emergences = {}
	lightnings = {}
	clearRequested = false
end

local function sendSnapshot(alive: { ServerTypes.Enemy })
	local time = GameClock.now()
	local total = #alive
	for first = 1, math.max(total, 1), Constants.SNAPSHOT_CHUNK do
		local last = math.min(first + Constants.SNAPSHOT_CHUNK - 1, total)
		local count = math.max(last - first + 1, 0)
		local packet = buffer.create(HEADER_BYTES + count * ENTRY_BYTES)
		buffer.writef64(packet, 0, time)
		buffer.writeu16(packet, 8, count)
		local offset = HEADER_BYTES
		for i = first, last do
			local enemy = alive[i]
			buffer.writeu16(packet, offset, enemy.id)
			buffer.writeu8(packet, offset + 2, enemy.kindIndex)
			buffer.writef32(packet, offset + 3, enemy.x)
			buffer.writef32(packet, offset + 7, enemy.z)
			offset += ENTRY_BYTES
		end
		snapshotEvent:FireAllClients(packet)
	end
end

function Replication.step(dt: number, enemies: { ServerTypes.Enemy })
	flushEvents()

	snapshotTimer += dt
	if snapshotTimer < Constants.SNAPSHOT_INTERVAL then
		return
	end
	snapshotTimer = 0

	local alive: { ServerTypes.Enemy } = {}
	for _, enemy in enemies do
		if not enemy.dead then
			table.insert(alive, enemy)
		end
	end
	if #alive > 0 then
		sendSnapshot(alive)
	end
end

return Replication
