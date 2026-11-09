# roblouuux: Game Design Document

*Status: playable prototype \+ approved Lobby, Monetized Respawn, 3rd-Person Camera & Starter Weapons/Talent Trees spec. Last synced on 2026-11-02. Source of truth for numbers is src/shared/Constants.luau, src/shared/WeaponConfig.luau, src/server/EnemyService.luau, src/server/Arena.luau, and src/server/Upgrades.luau; update this doc when those change.*

## One-pager

**Genre:** 3rd-person survivor (Vampire Survivors meets Dark Souls), co-op, Roblox.

**Theme:** pure Haunted Graveyard. Weathered crypt sarcophagi, wrought-iron fences, arched runic tombstones, gothic obelisks, and withered dead trees under a dark moonlit sky. Skeletons, bats, spiders, golems, and will-o'-wisps swarm from the graveyard shadows while the player auto-casts magic, cleaves with heavy spectral scythes, or lob necrotic embers and commands protective auras.

**Pitch:** you steer and position your character in responsive 3rd-person. Weapons fire and auras pulse automatically, enemies swarm in growing numbers through randomized graveyard pathways and choke points, and every level-up pauses time with three upgrade cards drawn from your equipped weapon's dedicated talent tree. Survive as long as you can, salvage deep runs with an Eldritch Soul Revive, and harvest Souls on every run.

**Session length target:** 10 to 12 minutes per run (aligned with Creator Rewards Daily Engagement thresholds, `LOOP-4`).

## Core loop & Wrapper (`LOOP-1`, `LOOP-3`, `MON-2`)

1. **Sanctuary Courtyard Lobby (`Phase = "Lobby"`):** Players spawn in an elevated Gothic Sanctuary Courtyard (`(0, 14, -295)`) overlooking the north gate of the graveyard. Players can choose their **Starting Weapon** via 3 interactive altar pedestals or the **"STARTING WEAPON"** HUD button, inspect their **Souls** wallet and personal bests, then walk into the glowing **Runic Crypt Portal** (`(0, 14, -262)`) or click the **"ENTER THE GRAVEYARD"** HUD button to deploy into combat within seconds (`LOOP-1 <10s` FTUE).  
2. **Active Graveyard Run (`Phase = "InRun"`):** Move through the graveyard avenues in 3rd-person to evade the swarm and navigate choke points. Primary attacks fire automatically at the nearest enemy; paired semi-defensive/offensive auras damage and hinder surrounding foes.  
3. **XP & Level-Up Pause:** Killed enemies drop faceted Soul XP Crystals (`XpSoulCrystal`). Crystals inside your pickup radius fly to you with dynamic magnetism. Enough XP triggers a level-up: the global game clock pauses, players freeze, and the screen reveals three fantasy MMO-style upgrade cards drawn from your weapon's talent tree (click or press 1, 2, 3).  
4. **Downed & Monetized Mid-Run Respawn (`Phase = "Downed"`, `MON-2`):** When a player's health hits `0` (and they have used fewer than `MAX_REVIVES_PER_RUN = 2` revives), they enter a **10-second Downed window** with the **Soul Revive Offer Modal**:  
   - **Soul Revive (Keep Build \+ Eldritch Shockwave):** Restores **100% Max Health**, keeps all **Levels & Upgrades**, grants **3.0s of Invulnerability**, and triggers a **36-stud Eldritch Shockwave** that blasts back and clears surrounding enemies (`LOOP-2`).  
   - **Accept Fate (End Run):** Skips the countdown and transitions to the End-of-Run Summary.  
5. **End-of-Run Summary & Souls Harvest (`Phase = "Summary"`, `LOOP-3`):** Displays **Time Survived**, **Enemies Vanquished**, **Level Reached**, and **Souls Harvested** (`max(1, floor(kills + survivedSeconds * 0.25))`), with 1-click buttons to **Play Again (Deploy Now)** or **Return to Sanctuary Lobby**.  
6. **Procedural Round Reset:** When no players remain in `"InRun"` or `"Downed"`, the round clears: all enemies, crystals, and projectiles are wiped, the clock restarts, and the arena regenerates a fresh randomized graveyard layout (`Arena.rebuild()`).

See [Feature Spec: Haunted Sanctuary Lobby and Monetized Mid-Run Respawn](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit) and [Feature Spec: Starter Weapons and Weapon Talent Trees](https://docs.google.com/document/d/14ky3JFHhd6bHeQ8u3oAMZ0Re7b0el6u32HZ0YyUWX9A/edit) for full specifications.

## Player

| Stat | Base value | Notes |
| :---- | :---- | :---- |
| Max health | 100 | Raised by weapon defense talents; managed virtually in `PlayerState` |
| Walk speed | 18 studs/s | Jumping disabled; verified by server-side distance budget (`PlayerState.checkMovement`) |
| Pickup radius | 12 studs | Crystals inside it are magnetized at 55 studs/s and collected at 2.5 studs |
| Damage cooldown | 0.4 s | Minimum time between two hits taken |
| Downed revive window | 10 s | Offers Soul Revive (keep build \+ 36-stud shockwave clear), capped at 2 per run (`MAX_REVIVES_PER_RUN = 2`) |
| Starting loadout | 1 Starter Weapon | Selected in Lobby; pairs 1 primary auto-attack \+ 1 semi-defensive/offensive aura |
| Level-up pause | Full game freeze | `GameClock` pauses, characters anchor. 1 s damage immunity on resume. Auto-picks after 20 s (5 s if AFK). |

XP needed for the next level is `floor(4 + 3L + L^1.4)`: 8 at level 1, 12 at level 2, 28 at level 5, 59 at level 10\. Multiple level-ups queue up cleanly and are offered sequentially.

## The 3 Starter Weapons

Players choose one of three starter weapons in the Sanctuary Lobby before starting a run. Each weapon equips a primary auto-attack and a paired aura:

### 1\. Arcanist's Staff (`ArcanistStaff`)

- **Role:** Balanced Ranged Kiting & Kinetic Barrier.  
- **Primary Attack \- Magic Bolt:** Fires crystal spearheads at the nearest enemy within 80 studs every 0.9 s. Base damage 8, speed 75 studs/s, lifetime 1.3 s. Additional bolts fan out 12 degrees apart.  
- **Paired Aura \- Guardian Orbs:** Runic astrolabes that circle the player at radius 9 studs and 2.4 rad/s. Deals 6 damage on contact (0.6 s cooldown per enemy).  
- **Thematic Defense \- Aether Barrier & Phase Armor:** Grants a recharging Arcane Ward absorbing up to 25 damage, flat damage reduction, and bonus movement speed.

### 2\. Crypt Cleaver (`CryptCleaver`)

- **Role:** Close-Range Melee Swarm Cleaver & High Sustain.  
- **Primary Attack \- Reaper's Cleave:** Swings a heavy spectral crescent wave every 1.35 s across a 110-degree arc reaching 22 studs. Deals 15 damage and cleaves up to 3 targets with heavy radial knockback.  
- **Paired Aura \- Bone Whirlwind:** Sharp jagged bone shards orbit at tight 5.5 studs radius and 3.2 rad/s. Deals 8 damage and shoves enemies back 14 studs (0.5 s cooldown per enemy).  
- **Thematic Defense \- Ossuary Plating & Marrow Feast:** Flat damage reduction, vampiric healing on kill, thorns damage reflection, and colossal max health scaling.

### 3\. Soulflame Lantern (`SoulflameLantern`)

- **Role:** Mid-Range Artillery, Area Denial & Zone Control.  
- **Primary Attack \- Spirit Cinders:** Lobs explosive necrotic soul embers up to 65 studs every 1.1 s. Deals 10 direct impact damage \+ 7-stud splash \+ lingering necrotic flame pool dealing 2 damage per 0.4 s for 1.2 s.  
- **Paired Aura \- Consecrated Ground:** Emits a 12-stud glowing sacred circle. Deals 4 holy damage every 0.5 s, slows enemies inside by 20%, and heals allies.  
- **Thematic Defense \- Iron Will & Sanctuary Mending:** Continuous health regeneration inside consecrated soil, armor boost while standing in sacred ground, and Retributive Flare retaliation blast on taking damage.

## Weapon Talent Trees & Level-Up Upgrades

Each weapon activates its own dedicated 3-branch Talent Tree during runs. Upgrade cards are drawn from the equipped weapon's tree plus the shared universal pool.

### Arcanist's Staff Talent Tree

- **Branch A (Magic Bolt):**  
  - `staff_damage` (Sharper Bolts): \+25% / \+50% / \+75% / \+100% bolt damage (6 ranks).  
  - `staff_cooldown` (Arcane Haste): \-12% / \-18% / \-24% / \-32% bolt cooldown (6 ranks).  
  - `staff_bolt_count` (Multi-Cast): \+1 to \+2 extra bolts per volley (3 ranks).  
  - `staff_pierce` (Piercing Crystal): Bolts pierce 1 to 4 additional enemies (3 ranks).  
  - `staff_velocity` (Aether Velocity): \+15% to \+50% bolt speed and range (4 ranks).  
  - `staff_harmonic` (Planetary Resonance): \+15% to \+60% bolt damage per active Guardian Orb (4 ranks).  
- **Branch B (Guardian Orbs):**  
  - `staff_orb_count` (Additional Astrolabe): \+1 to \+2 orbiting shields (5 ranks).  
  - `staff_orb_damage` (Stellar Core): \+30% to \+100% orb damage (5 ranks).  
  - `staff_orb_orbit` (Cosmic Orbit): Orbs circle 15% to 50% wider and faster (4 ranks).  
  - `staff_gravity_well` (Aetheric Pull): \+35% to \+100% crystal pickup radius (5 ranks).  
- **Branch C (Arcane Defense):**  
  - `staff_ward` (Aether Barrier): Grants 10 to 25 recharging damage shield (4 ranks).  
  - `staff_armor` (Phase Armor): Take 1 to 5 less damage per hit (4 ranks).  
  - `staff_fleet` (Fleet Step): \+10% to \+30% movement speed (5 ranks).  
  - `staff_overcharge` (Prismatic Flare): \+5% to \+18% critical strike chance (4 ranks).

### Crypt Cleaver Talent Tree

- **Branch A (Reaper's Cleave):**  
  - `cleaver_damage` (Heavy Edge): \+25% to \+100% cleave damage (6 ranks).  
  - `cleaver_reach` (Sweeping Arc): \+15% to \+50% cleave reach and arc width (4 ranks).  
  - `cleaver_cooldown` (Relentless Momentum): \-12% to \-32% cleave cooldown (6 ranks).  
  - `cleaver_pierce` (Carve the Swarm): \+2 to \+8 max cleave targets (4 ranks).  
  - `cleaver_execute` (Grim Decapitation): Instantly executes enemies below 15% to 35% health (3 ranks).  
  - `cleaver_shatter` (Grave Burst): Cleave kills explode dealing 12 to 35 radial damage (4 ranks).  
- **Branch B (Bone Whirlwind):**  
  - `cleaver_bone_count` (Ossuary Flurry): \+1 to \+2 orbiting bone shards (5 ranks).  
  - `cleaver_bone_damage` (Serrated Spikes): \+30% to \+100% bone damage (5 ranks).  
  - `cleaver_bone_speed` (Bone Gale): Bones orbit 20% to 60% faster with \+25% knockback (4 ranks).  
- **Branch C (Brutal Survivability):**  
  - `cleaver_armor` (Ossuary Plating): Take 1 to 5 less damage per hit (4 ranks).  
  - `cleaver_vampirism` (Marrow Feast): Heals 1 to 4 health on kill (4 ranks).  
  - `cleaver_thorns` (Barbed Carapace): Retaliates for 8 to 30 damage on hit (4 ranks).  
  - `cleaver_vitality` (Colossus Frame): \+25 to \+100 max health and heal (5 ranks).

### Soulflame Lantern Talent Tree

- **Branch A (Spirit Cinders):**  
  - `lantern_damage` (Blazing Soul): \+25% to \+100% cinder impact damage (6 ranks).  
  - `lantern_splash` (Funeral Pyre): \+20% to \+75% splash radius and pool area (4 ranks).  
  - `lantern_burn` (Lingering Torment): \+30% to \+100% pool DoT damage and duration (5 ranks).  
  - `lantern_cooldown` (Quick Stoke): \-12% to \-32% lob cooldown (6 ranks).  
  - `lantern_volleys` (Twin Embers): Lobs 1 to 2 additional cinder projectiles (3 ranks).  
- **Branch B (Consecrated Ground):**  
  - `lantern_radius` (Sacred Boundary): \+20% to \+70% consecrated circle radius (4 ranks).  
  - `lantern_slow` (Judicial Chains): Increases slow from 25% up to 55% (4 ranks).  
  - `lantern_tick` (Righteous Fervor): Circle pulses damage 20% to 50% faster (4 ranks).  
  - `lantern_sigil` (Judgment Sigil): Circle periodic burst deals 15 to 45 holy damage (3 ranks).  
- **Branch C (Holy Warding):**  
  - `lantern_regen` (Sanctuary Mending): Restores 0.8 to 3.0 health per second (4 ranks).  
  - `lantern_iron_will` (Iron Will): Take 2 to 6 less damage while inside sacred ground (4 ranks).  
  - `lantern_beacon` (Soul Beacon): \+40% to \+120% pickup range and magnetism (5 ranks).  
  - `lantern_flare` (Retributive Flare): Radial blast deals 15 to 50 holy damage on taking a hit (4 ranks).

### Shared Universal Talents

- `scholar` (Scholar): \+10% / \+15% / \+22% / \+30% experience gained (4 ranks).  
- `fortune` (Fortune): Rare and better upgrades 25% to 100% more likely (3 ranks).  
- `heal` (Second Wind): Restore 40 health (unlimited fallback when active pool is depleted).

## Enemies

All 5 enemy kinds spawn from the start of each run with continuous scaling mix curves:

| Kind | Health | Speed | Contact damage | XP | Radius | Spawn probability ramp |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Skeleton | 12 | 9 | 8 | 1 | 1.5 | Primary swarm enemy (default) |
| Bat | 7 | 14 | 5 | 1 | 1.1 | 20% rising to 28% |
| Wisp | 6 | 15 | 6 | 1 | 1.2 | 16% rising to 22% (fast, high dodge) |
| Spider | 18 | 11 | 7 | 2 | 1.6 | 12% rising to 24% (heavy mid-tier) |
| Golem | 70 | 6 | 18 | 6 | 3.0 | 5% rising to 15% (tank mini-boss) |

Enemies walk toward the nearest living `"InRun"` player while resolving obstacle collision against interior graveyard fences and sarcophagi via `Arena.resolveObstacle` with 2D tangential wall-sliding. Any enemy more than 140 studs from all players is recycled to a ring 95 to 110 studs away.

## Difficulty curve (Director)

- Target enemy count: `min(150, floor((12 + 0.35 * seconds) * crowd))`, where `crowd = 1 + 0.5 * (players - 1)`.  
- Spawns happen every 0.3 s, at most 4 per batch.  
- Enemy health multiplier: `1 + seconds / 120` (double health at 2 minutes, triple at 4 minutes).  
- Active enemy cap: 150 (`Constants.MAX_ENEMIES`). Active gem cap: 250 (`Constants.MAX_GEMS`).

## Arena, Sanctuary Lobby & Procedural Graveyard Layout

A 480 x 480 stud square (`Constants.ARENA_HALF_SIZE = 240`) paired with an elevated north Sanctuary Courtyard:

1. **Sanctuary Courtyard Lobby (`Z = -282, Y = 14`):** Elevated cobblestone terrace overlooking the north gate. Features:  
   - **3 Weapon Pedestals:** Elevated stone altars with spinning 3D visual weapon relics (`Relic_ArcanistStaff`, `Relic_CryptCleaver`, `Relic_SoulflameLantern`) with interactive `ProximityPrompt`s to equip each weapon.  
   - **Runic Crypt Portal (`(0, 14, -262)`):** Stepping onto the portal or clicking the HUD button immediately deploys the player to the graveyard arena.  
   - Soul Altar, corner lanterns, and perimeter iron fences.  
2. **Outer Perimeter Fence:** Continuous wrought-iron and stone pillar fence ring at `±238.8` studs along all 4 edges, featuring stone obelisks, forged iron pickets, and 4 Gothic Gateways with glowing amber lanterns.  
3. **Procedural Per-Run Layout (`Arena.rebuild`):** Regenerates fresh randomized layout on every run reset.  
4. **Randomized Choke Points & Obstacles:** Up to 36 collidable obstacles per run (`Constants.MAX_ARENA_OBSTACLES = 64`), including 4 avenue fence gates, 12 multi-panel interior fence walls, and 6 standalone sarcophagus crypts, enforcing `>= 15` studs minimum clearance to guarantee open traversal corridors.  
5. **10 Coherent Cemetery Plots:** Each plot features an anchored crypt sarcophagus and lantern post facing rows of tilted Gothic cross and arched runic headstones, with ground clutter clustered at the base.  
6. **Zero NaturePack Assets:** All previous forest decor (trees, rocks, flowers) has been replaced by custom `Graveyard_DeadTree`, `Graveyard_Obelisk`, `Ground_GrassTuft`, `Ground_DeadRoots`, and `Ground_RubbleCluster` models.

## Economy & Monetization (`MON-1..5`, `LOOP-3`)

- **Souls Meta-Currency (`LOOP-3`):** Earned on every run (`max(1, floor(kills + survivedSeconds * 0.25))`) and displayed in the Lobby and on the End-of-Run Summary Screen.  
- **Soul Revive (`MON-2` Impulse Dev Product):** Offered during the 10-second `"Downed"` window, capped at `MAX_REVIVES_PER_RUN = 2` per run. Restores 100% HP, preserves build, grants 3s immunity, and fires a 36-stud Eldritch Shockwave. Dynamic localized price queried via `MarketplaceService:GetProductInfoAsync` (`MON-3`), fulfilled via `MarketplaceService.ProcessReceipt` (`POL-1`).

## Camera, controls & UI

- **Camera:** Responsive 3rd-person Roblox-style over-the-shoulder follow camera with user mouse control (RMB drag / mouse wheel zoom 8–32 studs, default 16 studs, height 4.2 studs, horizontal offset 1.8 studs, smoothed lerping, obstacle raycast collision prevention).  
- **Controls:** Standard Roblox WASD / thumbstick character movement with server-side speed/teleport validation (`PlayerState.checkMovement`). Character rotates smoothly toward movement or camera direction. Level-up selections accept mouse clicks or hotkeys 1, 2, 3\.  
- **HUD & Modals:**  
  - **Lobby HUD:** Souls wallet badge, personal best run stats, **"STARTING WEAPON"** badge & button (opens the **Arsenal Selection Modal** displaying all 3 starter weapons side-by-side with attack/aura details and 1-click equip), and **"ENTER THE GRAVEYARD"** CTA button.  
  - **Combat HUD:** Custom health bar with Arcane Ward shield overlay, XP progress bar with level indicator, kill counter, Souls counter, and run timer.  
  - **Level-Up Modal:** Animated WoW-tooltip-style cards with rarity glows and countdown bar, drawing from the equipped weapon's talent tree.  
  - **Downed / Soul Revive Modal:** 10s countdown bar, dynamic Robux revive CTA, and "Accept Fate" button.  
  - **End-of-Run Summary Modal:** Run stats, Souls harvested, **"Play Again"**, and **"Sanctuary Lobby"** buttons.