# Decision Record: Virtual Health Lifecycle and Monetized Mid-Run Respawn

**Date:** 2026-11-01

**Status:** Accepted (`PROC-2`)

**Decided by:** Engineering & Product Management

## Context

In the initial prototype, joining players spawned directly at `(0, 0.5, 0)` inside the combat arena, and taking lethal damage set `humanoid.Health = 0`. Relying on Roblox's built-in `Humanoid` death state and `Players.RespawnTime = 3` created three structural blockers for our product and monetization roadmap (`LOOP-1..6`, `MON-1..3`, `POL-1`):

1. **No Mid-Run Respawn / Revive Window (`MON-2`):** Killing the Roblox `Humanoid` immediately breaks character joints, triggers ragdoll death, and destroys/recreates the character model 3 seconds later with a wiped upgrade build. Players cannot be offered a 10-second **Soul Revive** window to keep their build and clear the screen.  
2. **No End-of-Run Summary Screen (`LOOP-3`):** Auto-respawning after 3 seconds prevents showing run statistics (**Time Survived**, **Enemies Vanquished**, **Level Reached**, **Souls Harvested**) or letting the player choose between **Play Again** and **Return to Lobby**.  
3. **No Sanctuary Lobby Staging (`LOOP-1`, `LOOP-6`):** Dropping players straight into combat on join leaves no safe social staging space for inspecting currency, grouping up with friends, or spending meta-currency between runs.

Because player lifecycle state transitions, character authority, and `MarketplaceService.ProcessReceipt` handling affect every gameplay service, `PROC-2` requires a Decision Record before implementation.

## Options considered

| Option | Pros | Cons |
| :---- | :---- | :---- |
| **Option 1: Keep native `Humanoid.Health = 0` death \+ manual `Player:LoadCharacter()`** | Uses default Roblox ragdoll death animation. | Destroys character model on death; reviving requires spawning a new character, re-attaching camera/HUD, and restoring build state; causes camera pop and network ownership delay. |
| **Option 2: Single-Place Virtual Health & Explicit 4-Phase State Machine (`Lobby -> InRun -> Downed -> Summary`) in `PlayerState`** | Instantaneous transitions via server `PivotTo`; zero character reload overhead on Revive or Play Again; preserves upgrades seamlessly; keeps Lobby and Arena in one place for `<1s` deployment (`LOOP-1`) and live arena spectating from the Lobby balcony. | Requires keeping `Humanoid.Health = 100` on the engine instance and managing health/death exclusively through `PlayerState` attributes (`Health`, `MaxHealth`, `Phase`). |
| **Option 3: Separate Lobby Place \+ `TeleportService` into Arena Place** | Isolates lobby memory from combat servers. | Adds 5-15 second cross-place loading screens on every run start and end, violating `LOOP-1` (`<10s` FTUE) and hurting First-Play Bounce Rate (`DISC-1`). |

## Decision

We chose **Option 2**: manage player health and lifecycle strictly inside `PlayerState.luau` using an explicit 4-phase state machine (`"Lobby" | "InRun" | "Downed" | "Summary"`) within the same place file, paired with a dedicated `MonetizationService.luau` implementing `MarketplaceService.ProcessReceipt` (`POL-1`) for the **Soul Revive** Developer Product (capped at `MAX_REVIVES_PER_RUN = 2` per run).

## Consequences

- **What becomes easier:**  
  - **Instant Soul Revives (`MON-2`, `LOOP-2`):** When `ProcessReceipt` grants a revive, the server simply sets `Phase = "InRun"`, restores `state.health = state.maxHealth`, unanchors `HumanoidRootPart`, grants 3 seconds of invulnerability, and triggers `EnemyService.shockwaveClear`—all in a single frame without recreating the character.  
  - **Zero-Friction FTUE & Loop Pacing (`LOOP-1`, `LOOP-3`):** Deploying from the Sanctuary Lobby into the arena (or clicking **Play Again** on the End-of-Run Summary) is an instant `PivotTo` teleport with zero loading screens.  
  - **Clean Target Filtering:** `PlayerState.buildTargets()` only includes players with `state.phase == "InRun"`, automatically making `"Lobby"`, `"Downed"`, and `"Summary"` players ignored by enemies, bolts, orbs, and XP crystals.  
- **What must change in code and docs:**  
  - `PlayerState.luau` replaces `kill(state)` (`humanoid.Health = 0`) with `enterDownedOrSummary(state)` and manages `phase`, `revivesUsed`, `souls`, and portal proximity.  
  - `MonetizationService.luau` registers `MarketplaceService.ProcessReceipt` once (`POL-1`) and provides a Studio test fallback when `REVIVE_PRODUCT_ID == 0`.  
  - `Arena.luau` builds the elevated **Haunted Sanctuary Courtyard Lobby** at `Z = -282, Y = 14` with a **Runic Crypt Portal** at `Z = -262`.  
  - `LobbyAndDeathUi.luau` renders the Lobby CTA, the 10-second Downed / Soul Revive Offer Modal with dynamic localized pricing (`MON-3`), and the End-of-Run Summary Screen (`LOOP-3`).  
- **How we would undo or evolve it:**  
  - When player counts or lobby systems grow large enough to warrant dedicated multi-party matchmaking hubs, the `"Lobby"` phase can be extracted into a separate place while keeping the `"InRun" -> "Downed" -> "Summary"` virtual health state machine unchanged inside combat servers.