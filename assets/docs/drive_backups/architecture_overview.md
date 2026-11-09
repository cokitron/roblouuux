# roblouuux: Architecture Overview

*Last synced with the code and approved specs on 2026-11-02. Companion docs: [Game Design Document](https://docs.google.com/document/d/1t4UT6mSyfz6qAPvWlYSy35f5fBKYhYgThuwF2ZXLSxw/edit), [Feature Spec: Starter Weapons and Weapon Talent Trees](https://docs.google.com/document/d/14ky3JFHhd6bHeQ8u3oAMZ0Re7b0el6u32HZ0YyUWX9A/edit), [Feature Spec: Haunted Sanctuary Lobby and Monetized Mid-Run Respawn](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit), [Networking Protocol](https://docs.google.com/document/d/1nU_q0LUDHdX2_CClhurBB1V9JoYrpBal__AEzLzpToI/edit).*

## Summary

The server owns every gameplay decision and simulates enemies, projectiles, and orbs as plain Luau tables without server Instances. A single 60 Hz loop steps each system in a deterministic order. Clients receive compact snapshots and events, drawing enemies with `BulkMoveTo` and rendering custom multi-part projectiles, orbiting astrolabes, bone whirlwinds, consecrated ground circles, cleave arcs, and faceted soul crystals locally.

Player lifecycle is managed through a server-authoritative 4-phase state machine (`"Lobby" | "InRun" | "Downed" | "Summary"`) in `PlayerState.luau` using virtual health, enabling instantaneous transitions between the **Haunted Sanctuary Lobby**, active graveyard runs, the **10-second Monetized Soul Revive window**, and the **End-of-Run Summary Screen**. Starting weapon selection is configured in the Lobby, equipping weapon-specific attacks, auras, and dedicated 3-branch talent trees.

## Repository layout (Rojo)

| Folder on disk | Lands in Studio as | Contents |
| :---- | :---- | :---- |
| `src/server` | `ServerScriptService.Server` | Game rules, simulation, validation, replication, monetization (`ProcessReceipt`), procedural graveyard arena, Sanctuary Lobby, weapon altars |
| `src/client` | `StarterPlayerScripts.Client` | World renderer, 3rd-person camera, HUD, level-up UI, Lobby/Arsenal/Revive/Summary UI |
| `src/shared` | `ReplicatedStorage.Shared` | Constants, types, weapon definitions (`WeaponConfig.luau`), remote helper, enemy visual registry, GameClock |
| `assets/solidcraft` | (Off-engine CAD source) | Parametric `.sc` 3D source files (weapons, props, ground clutter, obstacles) |
| `assets/texturecraft` | (Off-engine PBR source) | Native `.tcraft` painting & baked mesh map projects |
| `assets/exports` | (Off-engine meshes & maps) | Exported `.glb` / `.obj` meshes and PBR texture map sets from TextureCraft |

Files on disk are the source of truth for code. Art templates live in `ServerStorage.GraveyardAssets` and `ReplicatedStorage.EnemyModels`. All legacy `NaturePack` assets have been removed.

## Server loop

`src/server/init.server.luau` initializes the arena and Sanctuary Lobby, wires player connections, registers `MonetizationService` and remote rate limiters (`ChooseUpgrade`, `SessionAction`), and runs the main `Heartbeat` loop. Frame time is capped at 0.1 s.

1. **`updatePause()`:** Checks if any living `"InRun"` player has an active level-up offer open, or if a solo player is in the 10-second `"Downed"` revive window. If so, pauses `GameClock`, anchors characters, and halts gameplay simulation until resolved.  
2. **`PlayerState.step(dt)`:** Checks Crypt Portal proximity for `"Lobby"` players, expires `"Downed"` timers, rebuilds living `"InRun"` player targets (sanitizes non-finite values, executes server-side displacement budget verification via `checkMovement`, clamps to arena), and applies health regeneration and ward recharge.  
3. **`EnemyService.step(dt)`:** Compacts dead enemies, steps positions toward nearest `"InRun"` players, slides around solid obstacles via `Arena.resolveObstacle`, applies contact damage (reduced by armor and absorbed by Arcane Ward), recycles distant stragglers, and executes separation.  
4. **`WeaponService.step(dt)`:** Evaluates attacks and auras for all 3 starter weapons: Magic Bolts \+ Guardian Orbs (Arcanist's Staff), Reaper's Cleaves \+ Bone Whirlwind (Crypt Cleaver), and Spirit Cinders \+ Consecrated Ground (Soulflame Lantern).  
5. **`GemService.step(dt)`:** Magnetizes and collects XP Soul Crystals for `"InRun"` players.  
6. **`Director.step(dt)`:** Tracks elapsed game time, spawns scaled batches of all 5 enemy types around `"InRun"` targets, and resets the round (clearing entities and calling `Arena.rebuild()`) when no players remain in `"InRun"` or `"Downed"`.  
7. **`Replication.step(dt)`:** Flushes queued hit/kill/bolt/cleave/cinder/shockwave/clear events and sends compressed 20 Hz enemy position snapshots.

## Server modules

| Module | Responsibility |
| :---- | :---- |
| `Arena` | Builds outer perimeter fence ring and elevated **Sanctuary Courtyard Lobby** once; creates 3 weapon altar pedestals with rotating relics and `ProximityPrompt`s; regenerates procedural graveyard layout (`Arena.rebuild`) on every run reset; registers 2D OBB obstacles; exports `Arena.resolveObstacle` with 2D tangential wall sliding; syncs prefabs to `ServerStorage.GraveyardAssets`. |
| `PlayerState` | Manages 4-phase player lifecycle (`Lobby -> InRun -> Downed -> Summary`), virtual health, equipped weapons (`selectedWeapon`, `equippedWeapons`), weapon stats (cleaves, bones, cinders, consecrated ground, arcane ward), Souls currency, and level-ups. Enforces movement budget validation (`checkMovement`). |
| `MonetizationService` | Registers `MarketplaceService.ProcessReceipt` once (`POL-1`) with idempotent `PurchaseId` tracking; fulfills **Soul Revive** purchases (100% HP \+ 3s immunity \+ 36-stud Eldritch Shockwave, capped at 2/run); logs economy events (`MON-5`). |
| `EnemyService` | Simulates plain-table enemies (Skeleton, Bat, Wisp, Spider, Golem). Implements obstacle avoidance, repulsion, vampiric lifesteal triggers, and `EnemyService.shockwaveClear` for Soul Revives. |
| `WeaponService` | Simulates primary attacks and defensive/attack auras for all starter weapons analytically from `GameClock.now()`. Handles projectile fan volleys, cleave arcs, lobbed splash pools, bone knockback, and holy slow fields. |
| `GemService` | Spawns multi-part faceted `XpSoulCrystal` models with tiered soul core colors and runic collars; handles dynamic magnet pull. |
| `Director` | Manages pacing curves across all 5 enemy types; triggers round resets and `Arena.rebuild()`. |
| `Upgrades` | Manages weapon talent trees (14 talents for Arcanist Staff, 13 for Crypt Cleaver, 13 for Soulflame Lantern) \+ 3 universal talents across 4 rarity tiers. `Upgrades.roll()` dynamically pulls only from active equipped weapon trees and universal pool. |
| `Replication` | Packs buffer snapshots (`<= 60` enemies/chunk, `<= 900` bytes) and fires reliable `WorldEvents` (hits, kills, bolts, cleaves, cinders, shockwaves, clear). |
| `RateLimiter` | Per-player token bucket rate limiter for client remotes. |

## Client modules

| Module | Responsibility |
| :---- | :---- |
| `WorldRenderer` | Interpolates enemy positions 0.15 s behind `GameClock.now()`; moves all enemy parts via single `BulkMoveTo`; draws `MagicBolt` spearheads, `GuardianOrb` astrolabes, rotating `BoneWhirlwind` shards, glowing `ConsecratedGround` sacred circles, expanding `cleave` crescent waves, and lobbed `cinder` fireball/burn pools; animates Eldritch Shockwave rings on revive (`PERF-8`). |
| `LobbyAndDeathUi` | Renders Sanctuary Lobby HUD (**"Enter the Graveyard"** CTA \+ Souls wallet \+ **"STARTING WEAPON"** badge & modal), the **Arsenal Selection Modal** displaying all 3 weapons with 1-click equip, the 10-second **Downed / Soul Revive Offer Modal** (`MON-3`), and the **End-of-Run Summary Screen** (`LOOP-3`). |
| `LevelUpUi` | Renders animated fantasy tooltip cards with rarity glows and countdown timer for the active weapon's talent tree. |
| `CameraController` | Responsive 3rd-person Roblox-style over-the-shoulder follow camera with RMB mouse panning, mouse wheel zoom (8–32 studs), smooth character rotation, and obstacle raycast collision avoidance. |
| `Hud` | Reads Player attributes and renders combat health with Arcane Ward shield overlay, XP bar, kills, Souls, and elapsed run timer during `"InRun"`. |

## Trust boundary & anti-cheat (`SEC-1..8`, `POL-1`)

- **Remotes:** Clients send only `ChooseUpgrade(seq, slot)` and `SessionAction(action, data)`. Every handler rejects extra arguments, validates types, weapon IDs, and state transitions on the server, and enforces a per-player `RateLimiter` (`SEC-1`).  
- **Movement validation (`SEC-5`):** Client physics are validated through `checkMovement`: horizontal displacement is budgeted against `WalkSpeed * dt * 1.25` up to a 16-stud burst tolerance. Server-initiated teleports (`Lobby <-> Arena`) explicitly reset `lastValidPosition` and grant a 1-second grace window.  
- **Purchases & Outcomes (`SEC-6`, `POL-1`):** Damage, XP gain, level-up card rolls, Souls calculation, and paid revives (`ProcessReceipt`) are 100% server authoritative.