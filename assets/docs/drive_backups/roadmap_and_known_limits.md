# roblouuux: Roadmap and Known Limits

*Last updated 2026-11-01. Move items to Done with a date when they ship.*

## Where the project is

The Haunted Graveyard combat core is fully playable: movement with server-side anti-cheat displacement checks, auto-firing Magic Bolts and orbiting Guardian Orbs active from 00:00, 5 distinct enemy types (Skeleton, Bat, Wisp, Spider, Golem), multi-part faceted Soul XP Crystals with dynamic magnetism, level-up card selection with time-pause, 18 upgrades \+ Second Wind across 4 rarity tiers, a time-based difficulty ramp, and a procedural per-run graveyard layout with 36 randomized blocking choke points and enemy wall-sliding.

The **Core Loop Wrapper (Haunted Sanctuary Lobby, Monetized Mid-Run Soul Revive & End-of-Run Summary Screen)** is fully specified and approved for implementation ([Feature Spec](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit), [Decision Record](https://docs.google.com/document/d/145nB_NYq5SxP_yKbCtfDKrkK50mIt3mYZf7vL5GkqbA/edit)).

## Known limits (from the code)

| Limit | Impact | Fix direction |
| :---- | :---- | :---- |
| No lobby or end-of-run wrapper yet *(In Progress)* | Players drop straight into combat and auto-respawn after 3s on death | Implement approved [Sanctuary Lobby & Soul Revive Feature Spec](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit) (`Lobby -> InRun -> Downed -> Summary`) |
| No cross-session data persistence | Souls and records reset when leaving the server | Single data module with session locking (`DATA-1` ProfileStore) in M3 |
| Gems are server Parts | Minor step effect while magnetized; Part replication cost | Simulate gems as plain tables and render on client like enemies (`PERF-4`) |
| Every client gets every enemy | \~34 KB/s per client at 150 enemies | Per-client interest culling, coordinate quantization (`PERF-5`) |
| `separate()` is O(n^2) | Fine at 150 enemies, too slow above 300 | Uniform spatial grid (`PERF-3`) |
| No stage boss end condition | Runs only end by death | Add 10-to-12 minute stage boss climax (`LOOP-4`) |
| Not a git repository | No history, no rollback | `git init`, commit place file backup |

## Milestones

### M1: Foundation (engineering) \- Mostly Complete

- Movement speed, distance budget, and teleport anti-cheat (`PlayerState.checkMovement`).  
- Level-up game clock pause with character freeze and auto-pick timeout.  
- Outer perimeter fence ring, procedural per-run graveyard layout, and enemy obstacle sliding.  
- Git repository with place file backed up.  
- CI running StyLua and Selene.  
- Unit tests for pure modules (XP curve, upgrade rolls, rate limiter, obstacle collision).

### M2: Core Loop Wrapper, Monetized Respawn & Content *(Active)*

- **Next Up — Haunted Sanctuary Courtyard Lobby & Runic Crypt Portal (`LOOP-1`, `LOOP-6`):** Elevated lobby overlooking the north graveyard gate \+ 1-click **"Enter the Graveyard"** button.  
- **Next Up — Monetized Mid-Run Respawn ("Soul Revive", `MON-1..3`, `POL-1`):** 10-second `"Downed"` window offering 100% HP restore \+ preserved build \+ 36-stud Eldritch Shockwave clear via `MarketplaceService.ProcessReceipt` (capped at 2 per run).  
- **Next Up — End-of-Run Summary Screen & Souls Harvest (`LOOP-3`):** Summary modal awarding Souls based on kills and survival time with 1-click **Play Again** and **Sanctuary Lobby** buttons.  
- 10-to-12-minute stage boss climax and victory summary screen (`LOOP-3`, `LOOP-4`).  
- Audio and SFX (hits, kills, level-up fanfare, shockwave blast, eerie graveyard ambience).  
- Gems moved to client-side table rendering (`PERF-4`).

### M3: Retention & Meta-Progression

- Cross-session persistence (`DATA-1` ProfileStore) for Souls, Best Run records, and `ProcessReceipt` history.  
- Permanent Sanctuary Altar talent upgrades in the Lobby (`MON-5`).  
- Starter Pack (`49-99 R$`), Permanent Game Passes (Magnet, \+1 Card Choice, 2x Souls), and Server Boost Totems (`MON-2`).  
- 7-Day login calendar, 3 daily quests, and Grimoire / Bestiary Compendium (`LOOP-5`).

### M4: Public launch

- Maturity & Compliance Questionnaire (`DISC-6`).  
- Creator Hub event announcements and 5 thumbnail variations (`DISC-2`).  
- Soft launch in Experience Beta (`DISC-3`).

## Done

- **2026-11-01:** Authored and approved [Feature Spec: Haunted Sanctuary Lobby and Monetized Mid-Run Respawn](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit) (`PROC-1`) and [Decision Record: Virtual Health Lifecycle and Monetized Mid-Run Respawn](https://docs.google.com/document/d/145nB_NYq5SxP_yKbCtfDKrkK50mIt3mYZf7vL5GkqbA/edit) (`PROC-2`).  
- **2026-11-01:** Registered complete ArtCraft Suite (SolidCraft \+ TextureCraft) 3D & PBR workflow learnings into project skills and documentation.  
- **2026-11-01:** Complete transition to pure Haunted Graveyard theme; removed all legacy `NaturePack` assets.  
- **2026-11-01:** Modeled, baked, and textured 12 custom SolidCraft & TextureCraft assets (combat, graveyard kit, ground clutter).  
- **2026-11-01:** Integrated multi-part `XpSoulCrystal`, `MagicBolt` spearhead, and `GuardianOrb` astrolabe models into gameplay.  
- **2026-11-01:** Implemented continuous outer perimeter wrought-iron fence ring with 4 Gothic Gateways.  
- **2026-11-01:** Implemented procedural per-run layout regeneration (`Arena.rebuild`) with 36 randomized blocking choke points and cemetery plots.  
- **2026-11-01:** Added 2D circle-vs-OBB obstacle collision with tangential wall-sliding for enemies (`Arena.resolveObstacle`).  
- **2026-11-01:** Implemented server-side character movement displacement budget check (`PlayerState.checkMovement`).  
- **2026-11-01:** Implemented global level-up pause system (`GameClock.pause/resume`, character anchoring, auto-pick timer, pick-confirmation fix).  
- **2026-11-01:** Added 5th enemy type: Will-o'-Wisp (`Wisp`), and scaled all 5 enemies to spawn from run start.