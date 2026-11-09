# **Safe and Scalable Roblox Rules**

*The engineering rules for this project and future Roblox games, based on the Roblox Best Practices Research doc (06 Research, November 2026). Claude Code reads the same rules from **.claude/rules/safe-scalable-roblox.md** in the repository, so keep the two in sync. Rule codes are for citing in reviews ("violates SEC-2").*

## **Principles**

> * **The server decides, the client draws.** Every outcome is computed on the server. The client sends intent and renders results.  
> * **Everything that grows has a cap.** Entity counts, packet sizes, request rates and memory all have written budgets.  
> * **Simulate as data, render as Instances.** High-count things are tables on the server and visuals on the client.  
> * **Write it down before it is hard to change.** Specs for features, decision records for irreversible choices, docs kept in sync with code.

## **Security**

| Code | Rule |
| :---- | :---- |
| SEC-1 | Every client-to-server handler rejects extra arguments, checks typeof, checks math.isfinite before range checks, caps string length, checks permission and game state, checks context (distance, phase), and applies a per-player rate limit. |
| SEC-2 | Instance arguments: typeof is Instance, IsA the expected class, IsDescendantOf the expected container, then distance or ownership. Prefer ids the server looks up. |
| SEC-3 | Never RemoteFunction:InvokeClient. Server-to-client traffic uses RemoteEvents. |
| SEC-4 | Unreliable packets stay at or under 1,000 bytes (this project asserts 900), carry a server timestamp or sequence number, and stale packets are dropped. The engine allows about 500 requests/s per client per remote type; our own limits are far lower. |
| SEC-5 | Character position is client-owned and untrusted. Sanitize it, and add a displacement check (rubber-band, do not kick) before anything rewards position. Moving to Server Authority mode requires a decision record. |
| SEC-6 | No outcome, currency, damage, XP, inventory or purchase grant is decided on the client. |
| SEC-7 | Anything replicated is readable. Secrets, weighted drop tables and anti-cheat thresholds stay in ServerScriptService or ServerStorage. |
| SEC-8 | The server is a gatekeeper, not a relay. Never forward one client's raw payload to others. |

## **Data**

| Code | Rule |
| :---- | :---- |
| DATA-1 | One data module, keyed User\_{UserId}, with session locking (ProfileStore unless a decision record says otherwise). |
| DATA-2 | UpdateAsync for read-modify-write; SetAsync only for independent values; retries with capped exponential backoff and jitter. |
| DATA-3 | Save on an interval shorter than the lock expiry, on leave, after purchases, and in BindToClose (30 seconds total, all players in parallel, skipped in Studio). |
| DATA-4 | Profiles carry a version field; migrations run on load and are tested. |
| DATA-5 | Keep the UserId in every store key and add a right-to-erasure template for every new store. |
| DATA-6 | MemoryStore only for ephemeral cross-server state. |
| DATA-7 | Respect quotas (per server 60 \+ 40 x players get and set per minute each, 4 MB per value). Never call DataStores per frame or per kill. |

## **Monetization and policy**

| Code | Rule |
| :---- | :---- |
| POL-1 | ProcessReceipt is idempotent: claim the PurchaseId atomically, grant, save, then return PurchaseGranted; return NotProcessedYet on any failure. |
| POL-2 | Paid random items disclose all odds before purchase and are gated on PolicyService, failing closed. |
| POL-3 | All player-written text that others see is filtered on the server, re-filtered when loaded, and hidden if filtering fails. |
| POL-4 | Content changes touching violence, fear, social features or monetization trigger a review of the Maturity and Compliance Questionnaire. |

## **Performance and scale**

| Code | Rule |
| :---- | :---- |
| PERF-1 | Server step under 16.67 ms with headroom (our target: game systems under 8 ms at the player cap). Client holds 60 FPS on a low-end phone at the enemy cap. Server memory under 50%. |
| PERF-2 | Every collection that grows with play has a hard cap in Constants.luau. |
| PERF-3 | No O(n squared) loops over entities that can exceed about 200; use a spatial grid. |
| PERF-4 | High-count entities are server tables replicated as buffers or events, never server Instances or Humanoids. |
| PERF-5 | Replicate on change. Every new replication path has a bytes-per-second estimate in the Networking Protocol doc. |
| PERF-6 | Per-player state, connections and client instances are cleaned up or pooled. |
| PERF-7 | Client code tolerates instances that have not streamed in yet. |
| PERF-8 | Tweens and VFX run on the client only. |

## **Process**

| Code | Rule |
| :---- | :---- |
| PROC-1 | New gameplay features start from the Feature Spec template. |
| PROC-2 | Hard-to-reverse choices get a Decision Record before code. |
| PROC-3 | Done means formatted, lint clean, playtested with a clean console (two players for multiplayer changes), reviewed, and docs updated. |
| PROC-4 | Docs in this folder stay in sync with numbers, remotes, packet layouts, enemies and upgrades. |
| PROC-5 | Pure logic lives in Instance-free modules so it can be unit tested. |
| PROC-6 | Store assets are inserted into ServerStorage, audited, stripped and credited. |
| PROC-7 | Platform limits and policies are re-checked against create.roblox.com before launch work; unverified facts are labelled. |

## **Where the current code stands (2026-11-01)**

| Rule | Status | Notes |
| :---- | :---- | :---- |
| SEC-1, SEC-6, SEC-8 | Meets | ChooseUpgrade is arg-count, type, length and rate checked and accepted only from the server's own offer. All outcomes are server side. |
| SEC-3, SEC-4 | Meets | No RemoteFunctions. Snapshots are timestamped, size-asserted at 900 bytes, and validated on the client. |
| SEC-5 | Gap | Positions are sanitized and clamped, but there is no speed or teleport check. |
| DATA-\* | Not started | No persistence yet. |
| POL-\* | Not started | No monetization or user text. Questionnaire not yet completed. |
| PERF-2, PERF-4, PERF-8 | Meets | Enemies capped at 150 and gems at 250\. Enemies, bolts and orbs have no server Instances. Tweens are client-only. |
| PERF-3 | Watch | separate() is O(n squared), acceptable at the current cap of 150\. |
| PERF-4 | Partial | Gems are still server Parts. |
| PERF-6 | Mostly meets | PlayerRemoving clears PlayerState, WeaponService and the rate limiter. PlayerCharacterDestroyBehavior has not been checked. |
| PROC-3, PROC-5 | Gap | No git, CI or unit tests yet. |

