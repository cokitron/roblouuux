# Product Management, Gamification and Monetization Rules

*The product management, growth, gamification and monetization ruleset for roblouuux and future Roblox experiences, synthesized from the Roblox Product, Marketing, Gamification and Monetization Research doc (06 Research, November 2026). Companion to Safe and Scalable Roblox Rules (03 Engineering Rules). Claude Code and Antigravity read the condensed rules from* ***.claude/rules/product-growth-monetization.md*** *and* ***AGENTS.md*** *in the repository—keep them in sync. Cite rule codes (`DISC-1`, `LOOP-3`, `MON-2`, `PM-1`) in specs and reviews.*

## Principles

- **Retention before monetization, onboarding before paid traffic.** Never buy ads for a leaky bucket. Prove the first 60 seconds and Day 1 return loop before scaling spend.  
- **No dead runs.** Every session—even a 2-minute death—must advance a persistent goal so the player leaves richer than they arrived.  
- **Amplify fun, never paywall skill.** Sell convenience, build variety, social generosity, cosmetic identity, and late-run second chances. Never sell raw unavoidable power that invalidates skill or co-op teammates.  
- **Design for the 28-day algorithm.** Every product feature must intentionally move at least one of the five core Roblox Home Recommendation signals: Play-Through Rate (PTR), Playtime, Play Days, Intentional Co-Play, or Spend Days.

## 1\. Discovery, Marketing and Acquisition (`DISC`)

| Code | Rule |
| :---- | :---- |
| DISC-1 | **Optimize for the 28-Day RFY Signals:** Feature prioritization must target the per-user 28-day Home Recommendation signals: **PTR / First-Play Bounce Rate**, **Playtime per User**, **Play Days per User**, **Intentional Co-Play Days**, and **Spend Days / Robux Spent per User**. Because only organic Home traffic feeds RFY ranking, protect organic cohort quality above all else. |
| DISC-2 | **Thumbnail Personalization Discipline:** Maintain up to 5 distinct thumbnail variations in Thumbnail Personalization testing distinct player motivations (swarm combat, boss climax, co-op squad, weapon evolution). Run every test for at least **7 days** (or until the next content update) without premature resets, and retire variations that underperform qPTR. |
| DISC-3 | **Soft-Launch Gatekeeping (Experience Betas before Ads):** Launch new experiences or major reworks in **Experience Beta** first. Do not run paid Sponsored Experiences in Ads Manager until Onboarding Funnel completion is **\> 70%** and D1 Retention is **\>= 20%**. |
| DISC-4 | **Event-Driven Update Cadence:** Ship updates on a predictable weekly or bi-weekly cadence. Every content update must be paired with a scheduled **Creator Hub Experience Event**, an **Update Announcement**, and an updated event thumbnail to trigger RSVP notifications. |
| DISC-5 | **In-Game Viral & Re-Engagement Prompts:** Integrate `SocialService:PromptGameInvite()` (with custom launch context) and `ExperienceNotificationService:PromptOptIn()` (for 13+ users via `CanPromptOptInAsync()`). Trigger opt-in and invite prompts only after high-dopamine moments (boss kill, new record, daily reward claim) or via a non-intrusive HUD/Lobby Friend Boost button—never on initial spawn. |
| DISC-6 | **Protect Addressable Market (`Mild` Maturity Target):** Keep visual combat feedback (skeletons, bats, spiders, golems, magic hits) cartoon/fantasy-stylized without realistic blood, gore, or horror shocks so the **Maturity & Compliance Questionnaire** stays `Minimal` or `Mild`. Escalating to `Moderate` blocks the Roblox Kids tier and requires a Decision Record (`PROC-2`). |

## 2\. Gamification, Core Loop and Retention (`LOOP`)

| Code | Rule |
| :---- | :---- |
| LOOP-1 | **The First 60 Seconds (Zero-Friction FTUE):** Never block new players with wall-of-text tutorials, unskippable cutscenes, or long lobby intermissions. From spawn, a new player must move and land their first auto-attack within **10 seconds**, collect their first XP gem within **20 seconds**, and receive their first Level-Up upgrade choice within **35 to 45 seconds**. |
| LOOP-2 | **Mechanical Juice Over Flat Math:** At least half of all in-run upgrades and milestones must visibly change gameplay mechanics (extra projectiles, pierce, orbiting shields, chain/area effects, weapon evolutions combining maxed weapons \+ passives) rather than invisible flat percentage buffs. Every hit, kill, gem pickup, and level-up requires crisp audiovisual feedback (client-side hit flash, damage numbers, sound, death tween). |
| LOOP-3 | **No Dead Runs (Meta-Progression Bridge):** Every run—whether ending in death or victory—must award persistent meta-currency (e.g., Souls/Essence) on an immediate **End-of-Run Summary Screen** showing survival time, kills, mini-bosses defeated, and currency earned, paired with a 1-click **Upgrade / Play Again** flow. Tuning must guarantee that a normal first run earns enough currency to purchase the player's **first permanent upgrade in Session 1**. |
| LOOP-4 | **Paced 10-to-12-Minute Runs & Creator Rewards Alignment:** Structure runs around a **10-to-12-minute stage clear climax** (with timed mini-bosses and multi-item chests at \~3m, 6m, and 9m, a stage boss at 10–12m, and an optional Endless mode after victory). This matches mobile session habits and ensures active sessions naturally cross the **10-minute threshold** required for **Roblox Creator Rewards Daily Engagement** payouts. |
| LOOP-5 | **Habit Engines for 28-Day Play Days:** To drive the `Play Days per User` signal, maintain three lightweight retention systems once persistence (`DATA-1`) ships: a **7-Day Login Streak Calendar**, **3 rotating Daily Quests** (e.g., *Kill 300 Skeletons*, *Survive 8 Minutes*, *Pick Guardian Orbs*), and a **Bestiary / Grimoire Compendium** that grants one-time milestone rewards for discovering enemies, upgrades, and weapon evolutions. |
| LOOP-6 | **Intentional Co-Play Multipliers:** Directly incentivize playing with friends to boost the `Intentional Co-Play Days` signal: grant a visible **\+10% XP / Meta-Currency Friend Bonus** per friend in the server (up to a cap), replace instant solo respawns in co-op with a **Downed Teammate Revive Ring** (standing near a downed ally for 3s revives them with their build intact), and share boss chest drops across living co-op players. |

## 3\. Monetization, Pricing and Economy (`MON`)

| Code | Rule |
| :---- | :---- |
| MON-1 | **Amplify, Never Paywall Core Skill:** All stages, enemies, and weapon evolutions must be completable skill-first without spending Robux. Monetize **convenience** (pickup magnet), **build agency** (+1 upgrade card choice / rerolls), **progression speed** (2x meta-currency), **social generosity** (server-wide boosts), **cosmetic identity** (classes/skins/auras), and **emotional run-salvage** (mid-run revives). |
| MON-2 | **Balanced Product Architecture (Starter, Passes, Impulse, Social):** Structure the store in four tiers: (1) a high-value, low-anchor **Starter Pack (49–99 R\$)** to convert first-time payers; (2) **Permanent Game Passes** (Extended Magnet, \+1 Upgrade Choice, 2x Meta-Currency, VIP); (3) **Repeatable Impulse Developer Products** (Mid-Run Revive \+ Screen Clear capped at 1–2 per run, Upgrade Reroll / Claim-All-3); and (4) **Server-Wide Boost Totems** (15m 2x XP/Souls for the whole arena with a global chat announcement celebrating the buyer). |
| MON-3 | **Managed Pricing & Dynamic Price Labels:** Enable **Regional Pricing** and **Price Optimization** on all passes and products. Never hardcode Robux numbers in UI strings—always fetch localized prices dynamically on the client via `MarketplaceService:GetProductInfoAsync` or `GetDeveloperProductsAsync` (wrapped in `pcall` with a fallback label). |
| MON-4 | **Subscriptions & Season Passes:** When offering a monthly Subscription or 4–6 week Dual-Track Season Pass (Free \+ Premium track), tie progression to daily/weekly quests rather than raw AFK hours, and verify subscription entitlements on the server via `MarketplaceService:GetUserSubscriptionStatusAsync`. |
| MON-5 | **Closed-Loop Economy (Documented Sources & Sinks):** Every virtual currency must have documented **Sources** (run rewards, quests, compendium milestones) and deep **Sinks** (talent tree scaling, character unlocks, reroll crafting, cosmetic rolls) in the GDD. Log every source and sink with `AnalyticsService:LogEconomyEvent` and monitor net wallet balance to prevent currency hyper-inflation. |
| MON-6 | **Safe & Ethical Purchase UX (No Combat Pop-Ups or Dark Patterns):** Strictly enforce `POL-1` (idempotent `ProcessReceipt`) and `POL-2` (`PolicyService` gating \+ 100% odds disclosure for any randomized chest/item). Never trigger a purchase prompt over active gameplay controls without an explicit button click, add a **0.8s input grace delay** on the Death/Revive screen so frantic combat clicks cannot accidentally click Buy, and never use fake countdown timers or hidden close buttons. |

## 4\. Product Operations, Telemetry and Experimentation (`PM`)

| Code | Rule |
| :---- | :---- |
| PM-1 | **Mandatory Analytics Instrumentation Before Launch:** Before exiting Experience Beta, the server must log: (1) `LogOnboardingFunnelStepEvent` across the 7 FTUE steps (`Spawned` → `FirstKill` → `FirstGem` → `FirstLevelOffer` → `FirstUpgradeChosen` → `FirstRunEnded` → `FirstMetaUpgrade`); (2) `LogFunnelStepEvent` for run survival minutes and shop conversion; (3) `LogEconomyEvent` for currency flows; and (4) `LogCustomEvent` for upgrade pick rates and death causes (staying well under the 100 custom event name ceiling by passing details via `customFields`). |
| PM-2 | **Live Configs & A/B Experiments Over Blind Balance Changes:** Once live, expose key balance and economy constants (`ENEMIES_PER_SECOND`, XP curve, upgrade multipliers, meta-currency drop rates) to `ConfigService` (`GetConfigForPlayerAsync`) and validate major tuning changes with 14-to-60-day **Creator Hub Experiments** (1 baseline \+ up to 2 variants) measuring retention and spend lift. |
| PM-3 | **Milestone KPI Gatekeeping:** Progression across release stages requires meeting target benchmarks: **M2 (Core Loop)** requires \<18% First-Play Bounce and \>70% FTUE completion; **M3 (Retention)** requires \>=10 min median session length and \>=20% D1 / \>=8% D7 retention; **M4 (Scale)** requires \>=2.5% Payer CVR and positive ROAS on test ad cohorts. |
| PM-4 | **Product Spec Requirements:** Every Feature Spec (`PROC-1`) must state: (1) which 28-day discovery signal (`PTR`, `Playtime`, `Play Days`, `Co-Play`, `Spend`) the feature targets; (2) its impact on the 60-second FTUE or 10-minute run pacing; (3) any Economy Sources/Sinks added; and (4) the exact `AnalyticsService` events that verify its success. |

## Where roblouuux stands today (2026-11-01)

| Rule | Status | Notes & Next Product Actions |
| :---- | :---- | :---- |
| LOOP-1 (First 60s FTUE) | **Meets (Core)** | Players spawn directly in the arena, bolts auto-fire every 0.9s, and Level 2 only costs 8 XP (\~20–35s). Needs subtle visual prompt for WASD/thumbstick \+ gem pickup arrow on Run 1\. |
| LOOP-2 (Mechanical Juice) | **Partial** | Extra Bolt, Piercing Bolts, and Guardian Orbs change mechanics visibly; 6 other upgrades are flat stat multipliers. No weapon evolutions, damage numbers, or audio yet. |
| LOOP-3 (No Dead Runs / Meta) | **Gap (High Priority)** | Death currently respawns after 3s with a wiped state and no End-of-Run Summary or persistent currency. Needs `DATA-1` persistence \+ Souls currency \+ Talent/Class screen. |
| LOOP-4 (10-12m Pacing & Bosses) | **Gap** | Difficulty scales endlessly with no mini-bosses (3/6/9m), boss chests, or 10–12m stage boss climax. |
| LOOP-5 (Habit Loops) | **Not started** | Needs Daily Login Streak, 3 Daily Quests, and Haunted Grimoire (Compendium) once persistence lands. |
| LOOP-6 (Co-Play Multipliers) | **Gap** | Co-op shares the arena, but lacks Friend XP/Soul boost, Downed Ally Revive Rings, and shared boss chests. |
| DISC-1 to DISC-6 | **Not started** | Pre-launch prototype. Keep combat `Mild`\-compliant (no blood/gore); prepare 5 thumbnails and Experience Beta setup for M4. |
| MON-1 to MON-6 | **Not started** | Zero monetization implemented. First priorities after `DATA-1`: Starter Pack, Magnet/Card Passes, Mid-Run Revive, Reroll, and Server 2x Totem. |
| PM-1 to PM-4 | **Gap** | No `AnalyticsService` calls or `ConfigService` hooks yet; update Feature Spec template to include PM sections. |

