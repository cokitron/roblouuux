# Roblox project (agentic development)

Luau code lives in `src/` and syncs into Studio via Rojo (`default.project.json`). Agents also drive Studio live through the built-in Studio MCP server (`Roblox_Studio`), build/export 3D CAD & mesh assets through the SolidCraft MCP server (`solidcraft`), and bake/paint 3D PBR textures & smart materials through the TextureCraft MCP server (`texturecraft`, both part of the ArtCraft Suite; see `.mcp.json` and `~/.gemini/config/mcp_config.json`).

## Layout
- `src/server` → ServerScriptService.Server (server-only: data, validation, game rules)
- `src/client` → StarterPlayerScripts.Client (input, UI, camera, effects)
- `src/shared` → ReplicatedStorage.Shared (types, constants, pure utilities, remote definitions)
- Subdirectory `CLAUDE.md` files in `src/server` and `src/client` hold the rules for each side.

## Source of truth
- Files on disk are the source of truth for scripts. Edit them here, not in Studio.
- Use MCP `script_*` / `multi_edit` tools only for scripts that exist solely in the open place (not Rojo-managed), and say so.
- Instances, terrain, lighting and UI built in Studio live in the place file. Keep the `.rbxl` under version control or back it up before bulk MCP edits.

## Workflow
1. Understand: `search_game_tree` / `inspect_instance` before changing anything in Studio.
2. Edit Luau on disk, run `stylua src` and `selene src` (when installed).
3. Verify in Studio: `start_stop_play`, then `get_console_output`; use `screen_capture` for UI/visual work. Don't call a change done until the console is clean.
4. `execute_luau` runs arbitrary code in the open place. Prefer the `Edit` datamodel for inspection, and say what a call will do before running it.

## Luau conventions
- `--!strict` at the top of every file. Type exported tables and function signatures.
- `local` everything. Modules return a table; no globals, no `_G`/`shared`.
- `task.wait`/`task.spawn`/`task.delay`, never `wait`/`spawn`/`delay`.
- Names: PascalCase for modules, classes and services; camelCase for locals and functions; UPPER_SNAKE for constants.
- Clean up connections and instances (Maid/Janitor-style or explicit `:Disconnect()`/`:Destroy()`), especially per-player.

## Security rules (non-negotiable)
- The client is untrusted; the server is the source of truth. Never put authority, currency, damage or inventory logic on the client.
- Validate every remote argument on the server: type, `math.isfinite` for numbers (rejects NaN/inf), range, instance class and location, and that the player is allowed to do it.
- Rate-limit per player on the server (e.g. token bucket). Check distance/context for ProximityPrompt, ClickDetector and DragDetector handlers.
- Server acts as gatekeeper, not a relay between clients.

## Performance
- Assume `StreamingEnabled`: client code must tolerate instances not being present yet (`WaitForChild`, `PersistentLoaded`, atomic models).
- Tween on the client, never with TweenService on the server.
- Keep remote payloads small; throttle input-driven replication.

## Project skills and agents
- Skills in `.claude/skills/` (also linked at `.agents/skills/`):
  - Roblox playbooks: `remote-security`, `datastore-patterns`, `studio-mcp-playtest`
  - SolidCraft, TextureCraft & ArtCraft Suite playbooks: `solidcraft-roblox-assets`, `texturecraft-pbr-painting`, `solidcraft-modeling`, `solidcraft-mechanisms`, `solidcraft-editing`, `solidcraft-checking`
- `.claude/agents/roblox-reviewer.md` reviews a diff against the rules above.
- `.claude/rules/safe-scalable-roblox.md` holds the coded engineering rule set (`SEC/DATA/POL/PERF/PROC`) from the Nov 2026 best-practices research. Cite rule codes in reviews.
- `.claude/rules/product-growth-monetization.md` holds the coded product management, discovery, gamification and monetization rule set (`DISC/LOOP/MON/PM`). Cite rule codes in feature specs, design reviews and balancing decisions.

## Documentation (Google Drive)
- Hub: "roblouuux Game Docs" folder (https://drive.google.com/drive/folders/1bMOzPkOLv8y0vE985PvvUfp916b54lPq), index doc "00 Start Here". Folders: 01 Game Design, 02 Architecture and Systems, 03 Engineering Rules, 04 Art and Assets, 05 Production and Release (includes "Product Management, Gamification and Monetization Rules"), 06 Research (includes engineering and product/monetization research), 07 Templates.
- When a change alters numbers, remotes, packet layout, enemy kinds, upgrades or economy flows, name the stale doc (Game Design Document, Architecture Overview, Networking Protocol, Product Management Rules) and update it when a Google Docs editor connector is available.

## Current game: survivor-style prototype (theme undecided)
- One shared 60 Hz loop in `src/server/init.server.luau` steps `PlayerState` → `EnemyService` → `WeaponService` → `GemService` → `Director` → `Replication`. Add new systems as `step(dt)` modules there.
- Enemies, bolts and orbs have **no server Instances**. The server simulates plain tables and `Replication.luau` sends them: enemy position snapshots (20 Hz, buffer over `EnemySnapshot` UnreliableRemoteEvent, ≤60 per packet), plus reliable `WorldEvents` (hits/kills/bolt removals/clear) and `BoltsFired` (origin+direction+server time). `src/client/WorldRenderer.luau` draws them: enemies are interpolated `RENDER_DELAY` behind server time, bolts move analytically from their record, orbs are a pure function of server time around the live player. Server hit detection uses the same formulas, so hits match visuals. Change the packet layout only via the `SNAPSHOT_*` constants (an `assert` guards the 900-byte limit).
- Player stats replicate as Player attributes (`Health`, `Xp`, `Level`, `Kills`, `Dead`, `RunStart`, `OrbCount`, `OrbRadius`, `OrbSpeed`); the HUD and renderer only read them. The only remotes are `LevelUpOffer` (server→client, `{seq, timeout, offers}`; empty offers closes the picker) and `ChooseUpgrade` (client→server, `(seq, slot)`: whole numbers, seq must match the open offer; ids and rarity never come from the client).
- **Game clock:** everything timed (bolt `t0`, snapshot and WorldEvents timestamps, orb angle, orb hit cooldown, `RunStart`, Director pacing) uses `GameClock.now()` (`src/shared/GameClock.luau`), not `GetServerTimeNow()`. It is server time minus total paused time, published as one string attribute `workspace.GameClock` (`"offset;pausedAt"`, pausedAt -1 when running). On the client it never goes backwards (hides the latency jump at pause/resume). New timed systems must use it too, or they will run during pauses and desync.
- **Level-up pause:** while any living, non-AFK player has an offer open, `init.server.luau` skips the whole step, pauses the clock and anchors every HumanoidRootPart (`PlayerState.setFrozen`); resume hands network ownership back and gives `RESUME_GRACE_SECONDS` of damage immunity. Offers auto-pick at random after `OFFER_TIMEOUT_SECONDS` (+0.5 s server grace) and mark the player AFK: an AFK player's offers no longer pause anyone and time out after `AFK_OFFER_TIMEOUT_SECONDS`, until they pick by hand. The client reopens the cards if a pick gets no answer within 1.5 s.
- Upgrades live in `src/server/Upgrades.luau`: 18 upgrades plus the Second Wind fallback, each with `values[tier]` for Common/Rare/Elite/Legendary. Rarity is rolled per card on the server (`TIER_WEIGHTS` 68/22/8/2, server-only per SEC-7; Fortune scales the non-Common weights by `1 + luck`). One pick = one rank whatever its rarity. `requires` hides orb upgrades until the player has orbs. Bolt cooldown is floored at `MIN_COOLDOWN_MULTIPLIER` and live bolts capped at `MAX_PROJECTILES`. The WoW-tooltip-style cards are built in code in `src/client/LevelUpUi.luau` (Merriweather font, emoji icons, no image assets). Tuning numbers in `src/shared/Constants.luau`; enemy kinds in `EnemyService.luau`.
- Theme: **haunted forest**. Enemies are Skeleton, Bat, Spider, Golem (stats in `EnemyService.luau`, spawn mix in `Director.pickKind`, visuals in `src/shared/EnemyVisuals.luau`; list order = the `kind` byte on the wire, so append, never reorder).
- Art lives in the **place file, not Rojo**, so keep the place saved: `ServerStorage.NaturePack` (arena decor, scattered at runtime) and `ReplicatedStorage.EnemyModels` (one sanitized template per enemy: visual parts only, anchored, no collision, pivot at world origin = bottom-centre, facing -Z). The client clones a template per enemy and moves all its parts with one `BulkMoveTo`; if a template is missing it falls back to a primitive.
- Adding or replacing an enemy model: insert it into `ServerStorage` (never Workspace), audit it (scripts, part count), then strip everything but visual parts, `ScaleTo` its hitbox, rotate so its own front vector (the `HumanoidRootPart` look vector for R15 rigs) maps to -Z, and drop its bounding box to the origin. Keep part count low (skeleton is 15, which is the practical ceiling for the most common enemy; the move step cost ~2 ms/frame at 1,800 parts). Delete the raw candidate afterwards.
- Do not insert Toolbox models without auditing them first: a zombie model tried earlier contained 5 scripts, and an R15 skeleton arrived with an AI script and an Animate script (benign, but stripped anyway). Free-asset search is mostly spam; check thumbnails before inserting.
- Asset credits (Creator Store, free; per-asset licences not independently verified beyond the store's terms): Low Poly Nature Pack (asset 129384388788570, creator not recorded), "Szkielet" skeleton (122900915480688, by Matipre3), "bat" (13844735682, by Woofdadoggamer), "Golem Mesh" (15721914045, by Pantasticker), "Spider" (136579301883061, by Thugtastico).
- Player character position is client-owned physics: `PlayerState.buildTargets` drops non-finite positions, runs `checkMovement` on the raw position, then clamps to the arena before any gameplay reads it. `checkMovement` is a horizontal distance budget (refilled at walk speed x `MOVE_SPEED_TOLERANCE` over real time, capped at `MOVE_BURST_STUDS`); overshoot is followed only as far as the budget allows and snaps the character back when the excess is over `MOVE_SNAP_STUDS`. 1 s grace after spawn. Thresholds are local to `PlayerState` (server-only, SEC-7). Accepted risk: a ~25% speed hack and saved-up 16-stud blinks pass.
- `math.isfinite` exists in the Studio runtime but not in the generated `roblox.yml`; `isfinite.yml` + `std = "roblox+isfinite"` in `selene.toml` patches that.
- Known limits: gems are still server Parts (steppy while magnetized); every client receives every enemy (no distance culling); `separate()` is O(n²) (fine at 150); no data persistence yet.

## Caveat on conventions
Security, streaming, tween and MCP guidance above is from Roblox Creator Docs. Folder layout, strict typing, naming and tooling choices are community convention, not verified by official sources. Questions still open: Wally vs pesde, ProfileStore vs raw DataStore, framework choice (Knit is archived), headless test runner.
