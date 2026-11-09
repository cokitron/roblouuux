# roblouuux: Networking Protocol

*Last synced with the code and approved specs on 2026-11-02. Change packet layout only through the SNAPSHOT\_* constants in Constants.luau; an assert in Replication.luau guards the 900-byte unreliable payload limit (SEC-4).\*

## Remotes

All remotes are created by the server inside `ReplicatedStorage.Remotes` through the shared `Remotes` module (`src/shared/Remotes.luau`).

| Name | Class | Direction | Payload | Rate & Validation |
| :---- | :---- | :---- | :---- | :---- |
| `EnemySnapshot` | `UnreliableRemoteEvent` | Server to all clients | `buffer` (layout below) | 20 Hz, up to 60 enemies per packet (`<= 670 bytes`) |
| `WorldEvents` | `RemoteEvent` | Server to all clients | `WorldEventsPayload` table | At most once per server frame, only when hits, kills, bolts, cleaves, cinders, shockwaves, or clears occur |
| `BoltsFired` | `RemoteEvent` | Server to all clients | array of `BoltRecord` | One per volley (Arcanist Staff) |
| `LevelUpOffer` | `RemoteEvent` | Server to one client | `LevelUpPayload` (`{seq, timeout, offers}`) | On level-up, auto-pick timeout, or offer close (`offers = {}`) |
| `ChooseUpgrade` | `RemoteEvent` | Client to server | `(seq: number, slot: number)` | Whole numbers (`seq >= 1`, `slot in 1..3`), must match open `state.offerSeq`. Token bucket: 10 burst, 5/s (`SEC-1`) |
| `SessionAction` | `RemoteEvent` | Client to server | `(action: string, data: any?)` | Actions: `"StartRun"`, `"RequestRevive"`, `"DeclineRevive"`, `"ReturnToLobby"`, `"SelectWeapon"` (`data: StarterWeaponId`). Rejects extra args, validates state phase, token bucket: 6 burst, 3/s (`SEC-1`) |

## EnemySnapshot packet

Little-endian buffer. Header 10 bytes, then 11 bytes per enemy. `10 + 60 * 11 = 670` bytes per full packet (well under the 900-byte safety assert and 1,000-byte engine unreliable payload ceiling, `SEC-4`).

| Offset | Type | Field |
| :---- | :---- | :---- |
| `0` | `f64` | Game clock time (`GameClock.now()`) |
| `8` | `u16` | Entry count (`1..60`) |
| `10 + 11i` | `u16` | Enemy id (`1..65535`, wraps) |
| `12 + 11i` | `u8` | Kind index into `EnemyVisuals.list` (`1 = Skeleton, 2 = Bat, 3 = Spider, 4 = Golem, 5 = Wisp`) |
| `13 + 11i` | `f32` | `x` world coordinate |
| `17 + 11i` | `f32` | `z` world coordinate |

The client rejects anything that is not a buffer or is shorter than the header or the declared count.

## WorldEventsPayload

- **t**: `GameClock.now()` timestamp of the flush.  
- **hits**: enemy ids that took damage (client flashes them white).  
- **kills**: enemy ids that died (client plays death tween and tombstones id for 2 s so late snapshots cannot revive it).  
- **bolts**: bolt ids removed early because they hit an enemy without remaining pierce.  
- **cleaves**: `{ { ox: number, oz: number, dirX: number, dirZ: number, arc: number, radius: number } }?` — triggers expanding spectral crescent wave VFX for Crypt Cleaver attacks (`PERF-8`).  
- **cinders**: `{ { ox: number, oz: number, tx: number, tz: number, splashRadius: number, duration: number } }?` — triggers lobbed fireball arc and lingering necrotic pool VFX for Soulflame Lantern (`PERF-8`).  
- **shockwaves**: `{ { x: number, z: number, radius: number } }?` — triggers expanding Eldritch Shockwave ring VFX when a player revives (`LOOP-2`, `PERF-8`).  
- **clear**: round reset. The client drops any snapshot older than `t` and clears active projectiles and pools.

## BoltRecord

`id`, origin (`ox`, `oz`), unit direction (`dx`, `dz`), speed, and fire time `t0` (`GameClock.now()`). Both server and client compute `position = origin + direction * speed * age`, capped at the `1.3 s` lifetime, so server hits line up with what players see without per-frame projectile replication (`PERF-4`).

## LevelUpPayload & ChooseUpgrade

- **`LevelUpOffer` (Server to Client):** Sends `{ seq: number, timeout: number, offers: { UpgradeOffer } }` where each `UpgradeOffer` contains `{ id, name, tier, icon, description, nextRank, maxRank }`. Upgrades are drawn dynamically from the player's equipped weapon talent tree and universal pool. When all queued level-ups are resolved, the server sends `{ seq = state.offerSeq, timeout = 0, offers = {} }` to close the modal cleanly.  
- **`ChooseUpgrade` (Client to Server):** Sends `(seq, slot)` only. Upgrade IDs and rarity weights never come from the client (`SEC-7`).

## Player attributes (server writes, HUD & renderer read)

### Core Combat & Weapon Attributes

- `SelectedWeapon`: `"ArcanistStaff" | "CryptCleaver" | "SoulflameLantern"`  
- `Health`, `MaxHealth`, `ArcaneWard`, `ArcaneWardMax` (absorptive shield overlay for Arcanist Staff)  
- `Xp`, `XpToNext`, `Level`, `Kills`, `Dead`, `RunStart`  
- `OrbCount`, `OrbRadius`, `OrbSpeed` (used by `WorldRenderer` to draw orbiting `GuardianOrb` astrolabes)  
- `BoneCount`, `BoneRadius`, `BoneSpeed` (used by `WorldRenderer` to draw orbiting `BoneWhirlwind` shards)  
- `ConsecratedRadius` (used by `WorldRenderer` to draw glowing `ConsecratedGround` sacred circles)  
- Workspace attributes: `GroundY` (arena floor height `0`), `GameClock` (`"offset;pausedAt"`, `pausedAt = -1` when running)

### Wrapper, Lobby & Monetized Respawn Attributes

- `Phase`: `"Lobby" | "InRun" | "Downed" | "Summary"`  
- `RevivesUsed`: `number` (`0..2`)  
- `MaxRevives`: `number` (`2`)  
- `DownedExpiresAt`: `number` (countdown target for the 10-second Soul Revive modal)  
- `DownedDuration`: `number` (`10`)  
- `Souls`: `number` (session meta-currency balance)  
- `LastRunSouls`, `LastRunTime`, `LastRunKills`, `LastRunLevel`: summary screen stats (`LOOP-3`)  
- `BestTime`, `BestKills`: session personal records

## Client timing model

- `Render time = GameClock.now() - 0.15 s` (`RENDER_DELAY`). Enemies interpolate between the two samples bracketing render time and extrapolate at most `0.1 s` if packets are late.  
- While `GameClock` is paused (during a non-AFK player's level-up offer or a solo player's 10-second Downed Revive window), `GameClock.now()` freezes on both server and client so interpolation, projectiles, orbiting orbs, and bone whirlwinds pause in place without desync.  
- Up Adaptable position history: up to 4 position samples are kept per enemy. A jump over 30 studs between samples clears sample history so the enemy snaps instead of sliding.  
- Enemies with no sample for `1.0 s` are removed (`ENTITY_TIMEOUT`).  
- Events, bolts, cleaves, and cinders are queued and applied when render time reaches their timestamp.

## Bandwidth budget (`PERF-5`)

At 150 enemies, each snapshot is `670 + 670 + 340 = 1,680 bytes`, or \~`34 KB/s` per client at 20 Hz, plus engine framing and reliable events. Cleave and cinder events add small intermittent records (`<30 bytes` each) only when attacks trigger. `SessionAction` and `Phase` attribute changes occur only a few times per run (`<50 bytes` per transition).