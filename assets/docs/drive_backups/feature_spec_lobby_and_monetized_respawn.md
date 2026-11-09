# Feature Spec: Haunted Sanctuary Lobby and Monetized Mid-Run Respawn

**Owner:** Engineering & Product Management

**Status:** Approved for Implementation (`PROC-1`)

**Date:** 2026-11-01

## Goal & target discovery signal (PM-4)

Introduce the complete pre-run and post-run Core Loop Wrapper: an elevated **Haunted Sanctuary Courtyard Lobby** overlooking the graveyard, a **10-second Monetized Mid-Run Respawn ("Soul Revive")** window with an Eldritch Shockwave screen clear, and an **End-of-Run Summary Screen** that awards persistent **Souls** meta-currency.

This directly targets three 28-day Roblox Home Recommendation ("Recommended For You") signals (`DISC-1`):

- **Spend Days & Robux Spent per User (`MON-2`):** Introduces our primary repeatable impulse Developer Product (**Mid-Run Soul Revive \+ Shockwave Clear**, capped at 2 per run) at the highest-emotion moment of a run.  
- **Playtime per User & 10-Minute Session Pacing (`LOOP-4`):** Allows invested players to salvage a deep run (minutes 6-11) with their upgrade build intact so sessions cross the 10-minute Creator Rewards active session threshold, while the End-of-Run Summary provides a 1-click **Play Again** flow (`LOOP-3`).  
- **First-Play Bounce Rate / PTR (`LOOP-1`):** Preserves our `<10s` Zero-Friction FTUE by pairing the physical Crypt Portal in the Sanctuary Lobby with a prominent 1-click **"Enter the Graveyard"** HUD button.

## Player experience

### 1\. Haunted Sanctuary Courtyard Lobby (`Phase = "Lobby"`)

- Joining players spawn inside the **Haunted Sanctuary Courtyard** at `(0, 14, -295)`—a lantern-lit Gothic stone terrace perched above the north gate of the graveyard arena.  
- From the south balcony railing (`Z = -258`), players can look down into the live Haunted Graveyard arena while safe from enemy aggro.  
- A glowing cyan/emerald **Runic Crypt Portal** stands 30 studs ahead at `(0, 14, -262)`, flanked by a **Soul Altar** displaying a floating Soul Crystal.  
- The Lobby HUD hides combat health/XP bars to keep the screen clean, shows the player's **Souls Wallet** (`Souls`) and **Best Run Record**, and presents a large bottom-center **"ENTER THE GRAVEYARD (START RUN)"** CTA button.  
- Walking into the Runic Crypt Portal **or** clicking the HUD button immediately teleports the player to `(0, 3, 0)` inside the arena (`Phase = "InRun"`) with 2.0 seconds of spawn damage immunity.

### 2\. Downed & Soul Revive Offer Modal (`Phase = "Downed"`, `MON-2`, `LOOP-2`)

- When a player's health reaches `0` during a run and they have used fewer than `MAX_REVIVES_PER_RUN` (`2`) revives:  
  - Instead of killing the Roblox `Humanoid` (which would break joints and force a 3-second character wipe), the server transitions the player to `Phase = "Downed"`, sets `Health = 0`, and anchors their `HumanoidRootPart`.  
  - If no other living player is actively fighting in `"InRun"`, the shared `GameClock` pauses so enemies freeze around the downed player.  
  - A high-contrast **Soul Revive Offer Modal** appears on the client with a live **10-second countdown bar**:  
    - **Primary CTA — "RISE AGAIN (KEEP BUILD \+ SHOCKWAVE)":** Prompts the **Soul Revive** Developer Product (`MarketplaceService:PromptProductPurchase`), displaying the dynamic localized Robux price fetched via `GetProductInfoAsync` (`MON-3`). In Roblox Studio when `REVIVE_PRODUCT_ID == 0`, clicking triggers a server-verified Studio Test Revive so the complete loop can be tested without spending Robux.  
    - **Mechanical Juice on Revive (`LOOP-2`):** Restores **100% Max Health**, preserves all **Levels & Upgrades**, grants **3.0 seconds of Invulnerability**, and detonates a **36-stud Eldritch Shockwave** (`WORLD_EVENT_SHOCKWAVE`) that blasts back and clears surrounding enemies.  
    - **Secondary CTA — "Accept Fate (End Run)":** Immediately skips the remaining countdown and opens the End-of-Run Summary.

### 3\. End-of-Run Summary Screen (`Phase = "Summary"`, `LOOP-3`)

- Triggered when the 10-second revive timer expires, the player clicks **"Accept Fate"**, or the player dies after exhausting all `2` revives in a run.  
- Displays a Gothic summary card with:  
  - **Time Survived** (`MM:SS`)  
  - **Enemies Vanquished** (`Kills`)  
  - **Level Reached** (`LV X`)  
  - **Souls Harvested** (`+X Souls`, calculated as `max(1, floor(kills + survivedSeconds * 0.25))`)  
- Provides two 1-click actions:  
  - **"PLAY AGAIN (DEPLOY NOW)":** Resets run stats/upgrades and deploys the player straight into `(0, 3, 0)` for a fresh run (`Phase = "InRun"`).  
  - **"RETURN TO SANCTUARY LOBBY":** Teleports the player back to `(0, 14, -295)` in the Sanctuary Courtyard (`Phase = "Lobby"`).

## Rules and numbers

| Constant | Value | Reason & ConfigService note (PM-2) |
| :---- | :---- | :---- |
| `LOBBY_SPAWN` | `Vector3.new(0, 14, -295)` | Safe Sanctuary Courtyard spawn point overlooking the north graveyard gate |
| `LOBBY_PORTAL_POS` | `Vector3.new(0, 14, -262)` | Runic Crypt Portal walk-in trigger position |
| `LOBBY_PORTAL_RADIUS` | `7` studs | Horizontal activation radius for walking into the Crypt Portal |
| `ARENA_SPAWN` | `Vector3.new(0, 3, 0)` | Central plaza deployment coordinates when entering a run |
| `SPAWN_IMMUNE_SECONDS` | `2.0` s | Damage grace window when deploying into the arena |
| `REVIVE_WINDOW_SECONDS` | `10` s | Countdown duration on the Downed / Soul Revive modal (ConfigService A/B candidate: 8s vs 10s vs 12s) |
| `REVIVE_PROMPT_GRACE_SECONDS` | `25` s | Extra server timeout hold while Roblox's native purchase prompt is open |
| `MAX_REVIVES_PER_RUN` | `2` | Hard cap per run so skill is never paywalled (`MON-1`, `MON-2`) |
| `REVIVE_IMMUNE_SECONDS` | `3.0` s | Post-revive invulnerability window |
| `REVIVE_SHOCKWAVE_RADIUS` | `36` studs | Radius of the Eldritch Shockwave triggered on revive (`LOOP-2`) |
| `REVIVE_SHOCKWAVE_DAMAGE` | `250` | Damage dealt to enemies inside the shockwave (clears regular mobs, heavily damages Golems) |
| `REVIVE_SHOCKWAVE_KNOCKBACK` | `28` studs | Radial knockback distance applied to surviving enemies |
| `REVIVE_PRODUCT_ID` | `0` (placeholder) | Developer Product ID for Soul Revive; `0` enables Studio Test Grant when `RunService:IsStudio()` |

## Economy sources and sinks (MON-5)

- **Source — End-of-Run Souls Harvest (`LOOP-3`):** Every completed run awards `max(1, floor(kills + survivedSeconds * 0.25))` **Souls** when transitioning into `Phase = "Summary"`. Even a short 30-second first run with 8 kills awards \~15 Souls so there are **no dead runs**.  
- **Impulse Robux Monetization (`MON-2`):** Mid-Run **Soul Revive** Developer Product (`REVIVE_PRODUCT_ID`), capped at `MAX_REVIVES_PER_RUN = 2` per run. Does not grant permanent stat advantages over non-payers (`MON-1`).  
- **Planned Sinks (M3 Persistence):** Permanent Sanctuary Altar talent upgrades, starter class unlocks, and cosmetic weapon/orb skins in the Lobby.

## Client and server split

| Server decides (`SEC-6`) | Client does (`PERF-8`) |
| :---- | :---- |
| Player `Phase` transitions (`Lobby`, `InRun`, `Downed`, `Summary`) | Renders Lobby HUD, Downed Revive Modal, and End-of-Run Summary Screen from replicated Player attributes |
| Portal proximity detection (`LOBBY_PORTAL_RADIUS`) and character teleportation (`PivotTo`) | Queries dynamic localized Robux price via `pcall(MarketplaceService.GetProductInfoAsync, ...)` (`MON-3`) |
| Downed countdown expiration (`downedExpiresAt`) and `revivesUsed < MAX_REVIVES_PER_RUN` enforcement | Fires `SessionAction` remote when clicking UI buttons (`"StartRun"`, `"RequestRevive"`, `"DeclineRevive"`, `"ReturnToLobby"`) |
| `MarketplaceService.ProcessReceipt` verification, idempotent `PurchaseId` tracking, and revive grant (`POL-1`) | Animates the expanding Eldritch Shockwave ring VFX (`WORLD_EVENT_SHOCKWAVE`) via `TweenService` |
| Eldritch Shockwave enemy damage, knockback, kill credit, and Souls calculation | Adjusts HUD visibility based on `Phase` |

## Remotes and replication

### 1\. Client-to-Server Remote: `SessionAction` (`RemoteEvent`)

- **Payload:** `(action: string)` — single string argument; no extra arguments allowed.  
- **Allowed values:** `"StartRun"`, `"RequestRevive"`, `"DeclineRevive"`, `"ReturnToLobby"`.  
- **Server validation (`SEC-1`):**  
  1. Reject if `select("#", ...) > 0` (extra arguments).  
  2. Check `typeof(action) == "string"` and `#action <= 24`.  
  3. Check per-player `RateLimiter.new(6, 3)`.  
  4. Verify state transition legality:  
     - `"StartRun"` requires `state.phase == "Lobby"` or `state.phase == "Summary"`.  
     - `"RequestRevive"` requires `state.phase == "Downed"` and `state.revivesUsed < Constants.MAX_REVIVES_PER_RUN`.  
     - `"DeclineRevive"` requires `state.phase == "Downed"`.  
     - `"ReturnToLobby"` requires `state.phase == "Summary"`.

### 2\. Server-to-Client `WorldEvents` Addition

- Adds `shockwaves: { { x: number, z: number, radius: number } }?` to `WorldEventsPayload` when a player revives, allowing `WorldRenderer.luau` to render the expanding shockwave ring at the exact timestamp `t`.

### 3\. Replicated Player Attributes

- `Phase`: `"Lobby" | "InRun" | "Downed" | "Summary"`  
- `RevivesUsed`: `number` (`0..2`)  
- `MaxRevives`: `number` (`2`)  
- `DownedExpiresAt`: `number` (server `GameClock` / remaining seconds for UI countdown)  
- `DownedDuration`: `number` (`10`)  
- `Souls`: `number` (session total Souls)  
- `LastRunSouls`: `number`  
- `LastRunTime`: `number` (seconds survived)  
- `LastRunKills`: `number`  
- `LastRunLevel`: `number`  
- `BestTime`: `number`  
- `BestKills`: `number`

## Data and persistence

- Session-persistent fields (`souls`, `bestTime`, `bestKills`, and `processedReceipts`) are stored on the server per player across runs and character reloads, structured so they drop cleanly into the `User_{UserId}` `ProfileStore` schema when `DATA-1` lands in M3.

## Performance budget

- **Sanctuary Lobby Instances:** \~35 anchored static parts (terrace floor, wrought-iron railings, 4 corner lanterns, Soul Altar sarcophagus, Runic Crypt Portal archway). Zero server Heartbeat cost.  
- **Server CPU:** `<0.05 ms/frame` for portal distance check and downed timer expiration across 8 players (`PERF-1`).  
- **Bandwidth:** Attribute updates only fire on phase transitions (`Lobby -> InRun -> Downed -> Summary`), adding `<50 bytes` per transition (`PERF-5`).

## Exploit review

- **Can an exploiter fire `"RequestRevive"` to get free revives in production?** No (`SEC-6`, `POL-1`). In production (`REVIVE_PRODUCT_ID > 0`), `"RequestRevive"` only calls `MarketplaceService:PromptProductPurchase(player, REVIVE_PRODUCT_ID)` on the server and extends the downed timer while the prompt is open. Only `MarketplaceService.ProcessReceipt` actually grants the revive after Roblox verifies payment.  
- **Can an exploiter revive more than twice per run?** No. `state.revivesUsed` is checked on the server before entering `"Downed"` and before prompting a purchase.  
- **Can an exploiter stay in `"Lobby"` while shooting enemies or collecting XP?** No. `PlayerState.buildTargets()` filters strictly for `state.phase == "InRun"`, so Lobby/Downed/Summary players never fire weapons, attract enemies, or magnetize gems.  
- **Can teleporting between Lobby and Arena trigger false movement rubber-banding?** No (`SEC-5`). Server-initiated teleports (`teleportCharacter`) explicitly reset `state.lastValidPosition`, refill `state.moveBudget`, and grant a 1-second `moveGraceUntil` window.

## Analytics (PM-1)

- Log `AnalyticsService:LogEconomyEvent` (wrapped in `pcall`) on every **Souls Harvest** (`Enum.AnalyticsEconomyFlowType.Source`, `"Souls"`) and every **Soul Revive** grant (`MON-5`).  
- Track onboarding funnel progression (`Lobby Spawn -> First Run Entered -> First Kill -> First Level Up -> First Run Summary`).

## Test plan

- **Static checks:** `stylua src` and `selene src` pass with 0 errors and 0 warnings.  
- **Studio playtest (solo):**  
  1. Verify player spawns in the Haunted Sanctuary Lobby (`Phase == "Lobby"`) overlooking the graveyard with a clean console.  
  2. Walk into the Runic Crypt Portal (and test clicking **"Enter the Graveyard"**) to verify transition to `Phase == "InRun"` at `(0, 3, 0)`.  
  3. Take lethal damage and verify transition to `Phase == "Downed"`, 10-second countdown modal, anchored character, and paused simulation.  
  4. Click **"Rise Again"** (Studio Test Grant) and verify 100% HP restoration, preserved level/upgrades, 3s invulnerability, and Eldritch Shockwave clearing nearby enemies.  
  5. Die a 3rd time (after `2` revives used) or click **"Accept Fate"** and verify transition to `Phase == "Summary"` with accurate `LastRunSouls`, `LastRunTime`, `LastRunKills`, and `LastRunLevel`.  
  6. Test both **"Play Again"** and **"Return to Sanctuary Lobby"** buttons from the Summary screen.

## Docs to update

- [Game Design Document](https://docs.google.com/document/d/1t4UT6mSyfz6qAPvWlYSy35f5fBKYhYgThuwF2ZXLSxw/edit)  
- [Architecture Overview](https://docs.google.com/document/d/1zgqYcAnbpbyfMgX4ZkcR_DXLOCMeIpeME9VniQd-840/edit)  
- [Networking Protocol](https://docs.google.com/document/d/1nU_q0LUDHdX2_CClhurBB1V9JoYrpBal__AEzLzpToI/edit)  
- [Development Workflow and Tooling](https://docs.google.com/document/d/1gN896DGisvkk-NA5C7kmdTO2vpuLY1Ji2tndC3hEuqs/edit)  
- [Roadmap and Known Limits](https://docs.google.com/document/d/1-D_cKYKGglsIo9gRkGjbgXm5eDlwwJYjExvuWGbVWxw/edit)  
- [00 Start Here](https://docs.google.com/document/d/1gGfyzPjZtnByJwP0mxme7eZ-FLDfrbpC2Pms-Omj0wM/edit)