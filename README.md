# roblouuux — Haunted Crypt Action-RPG Survivor

A multiplayer Gothic Action-RPG Survivor built on Roblox using **strict Luau**, **Rojo**, and a **data-driven 60 Hz server simulation** (`ServerScriptService` tables + `UnreliableRemoteEvent` binary buffer snapshots + client-side `BulkMoveTo` rendering).

## Highlights

- **Zero-Instance Server Simulation (`PERF-4`):** Up to 150 active enemies, projectiles, and guardian orbs simulated as pure server tables at 60 Hz and replicated at 20 Hz via binary buffers (`<= 900` bytes/packet).
- **6 Starting Weapons, Multi-Weapon Drafting & 6 Legendary Evolutions:**
  - `🔮 Arcanist's Staff` → **Astral Starfall**
  - `🪓 Crypt Cleaver` (125° directional frontal cleave) → **Crimson Guillotine**
  - `🏮 Soul Lantern` → **Ashen Hellstorm**
  - `🏹 Phantom Longbow` → **Thousand-Arrow Tempest**
  - `🔫 Dual Hexlock Pistols` → **Silver Executioner**
  - `⚡ Stormcaller's Tome` → **Mjolnir's Wrath**
- **Active Tactical Combat:**
  - **Spectral Dash (`[Space]` / `[LeftShift]` / `[E]` + Mobile Touch Button):** Phase-dodge burst with brief immunity and shockwave knockback (`SEC-5` movement-budget aware).
  - **Crypt Soul Braziers, Cursed Soul Urns, 3D Reliquary Chests & Dynamic Wave Bounties.**
- **Deep WoW-Inspired Sanctuary Meta-Progression (`LOOP-3`, `LOOP-5`):**
  - **6-Slot RPG Armory & Enchanting Forge (`[C]`):** Rarity tiers, 3 Item Sets (2pc/4pc bonuses), Disenchanting, and `+1` to `+10` Slot Enchanting.
  - **Sanctuary Soul Altar Talent Tree (`[N]`):** 4-row specialization tree with Row 4 Capstones and free respec.
  - **Mythic+ Crypt Keystones, Daily Emissary Bounties & Weekly Great Vault (`[J]`).**
  - **24-Entry Bestiary & Evolution Grimoire Compendium (`[B]`):** Permanent `+0.5% All Damage & +1 Max HP` per discovered creature or weapon evolution.
  - **Adventurer's Field Guide & Evolution Codex (`[H]`).**

## Repository Layout

- `src/server/` — Server-authoritative simulation (`PlayerState`, `EnemyService`, `WeaponService`, `GemService`, `Director`, `Arena`, `Replication`, `DataService`, `Upgrades`)
- `src/client/` — Client rendering & UI (`WorldRenderer`, `Hud`, `LevelUpUi`, `LobbyAndDeathUi`, `SoundService`)
- `src/shared/` — Shared configs, constants, clock & remotes (`Constants`, `WeaponConfig`, `RpgConfig`, `EnemyVisuals`, `GameClock`, `Remotes`)
- `assets/solidcraft/` — Parametric SolidCraft (`.sc`) 3D CAD source files
- `assets/meshy_inputs/` & `assets/renders/` — 3D reference sheets and renders
- `assets/docs/` — Design briefs, architecture docs, and Google Drive mirrors
- `.claude/rules/` — Engineering (`SEC/DATA/POL/PERF/PROC`) & Product (`DISC/LOOP/MON/PM`) rulesets
- `roblouuux.rbxl` — Roblox Studio place file

## Development & Tooling

```powershell
# Format & lint
stylua src
selene src

# Build standalone place file or sync live with Rojo
rojo build default.project.json -o roblouuux.rbxl
rojo serve default.project.json
```
