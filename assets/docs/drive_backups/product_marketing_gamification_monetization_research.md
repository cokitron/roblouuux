# **onceRoblox Product, Marketing, Gamification and Monetization Research (November 2026\)**

*Researched 2026-11-01. Companion to Roblox Best Practices Research (Nov 2026). Tags:* ***\[docs\]*** *official Creator Hub page,* ***\[official\]*** *Roblox announcement or blog,* ***\[community\]*** *DevForum or industry benchmark,* ***\[unverified\]*** *not confirmed on an official page or subject to change. Re-check discovery and payout rules on create.roblox.com before major launch spend.*

## **Summary for roblouuux**

- **What we have today:** A fast, responsive co-op haunted-forest survivor core loop (server-simulated enemies, bolts, orbs, XP gems, 9 level-up upgrades, 4 enemy kinds, 60 Hz server tick, zero Humanoid lag). This already nails the \#1 technical prerequisite for survivor games on Roblox: smooth 60 FPS swarm combat on mobile without frame drops.  
- **What is missing from a Product & Growth perspective:**  
  - **No End-of-Run Loop or Meta-Progression:** When players die, they respawn after 3 seconds with everything reset, and when all players die the round wipes. Without persistent meta-currency (e.g., Souls/Essence), permanent upgrades, unlockable classes, or an End-of-Run Summary Screen, every run ends in total loss—causing massive Day 1 (D1) churn.  
  - **No Paced Run Climax (10-Minute Target):** The difficulty curve caps at 150 enemies around 6.6 minutes solo and scales health indefinitely with no mini-bosses, boss chests, weapon evolutions, or stage clear condition. Mobile Roblox sessions average 10 to 15 minutes, and Roblox's **Creator Rewards Daily Engagement** payout requires Active Spenders to play at least **10 minutes**.  
  - **No Co-Play Hooks:** Co-op shares the arena, but XP is individual, death is a 3-second solo respawn, and there is no friend multiplier, downed-ally revive ring, or `SocialService:PromptGameInvite` flow to drive the algorithm's **Intentional Co-Play Days** signal.  
  - **No Habit Loops (28-Day Play Days):** No daily login streaks, quests, compendium/bestiary milestones, or seasonal pass to pull players back across the 28-day recommendation window.  
  - **No Monetization or Telemetry:** No Starter Pack, Game Passes, Mid-Run Revive / Reroll Developer Products, or `AnalyticsService` funnel/economy instrumentation.

## **1\. Discovery and the 28-Day Recommendation Algorithm**

Roblox's primary organic growth engine is the **"Recommended For You" (RFY)** sort on the Home page, operating in two stages: **Retrieval** (selecting candidate experiences matching a user's history and broad quality signals) and **Ranking** (sequencing candidates by predicted per-user engagement and satisfaction).

| Rule / Mechanism | Why it matters for Product Management | Source |
| :---- | :---- | :---- |
| **28-Day Rolling Evaluation Window:** The algorithm evaluates user cohorts over 28 days after organic discovery (Day 1, Days 2 to 7, Days 8 to 28). | Short-lived clickbait that spikes Day 1 and craters by Day 7 loses Home distribution. Sustainable meta-progression and weekly content win. | \[docs\] [Home recommendations](https://create.roblox.com/docs/production/promotion/home-recommendations) |
| **Signal 1 — Play-Through Rate (PTR / qPTR) & First-Play Bounce Rate:** Tracks how often Home impressions convert into intentional, non-bounce sessions. | Misleading thumbnails or broken first-30-second onboarding spike First-Play Bounce Rate, throttling impressions immediately. | \[docs\] [Discovery](https://create.roblox.com/docs/production/promotion/discovery), Home recommendations |
| **Signal 2 — Playtime per User & Qualified Play Sessions:** Cumulative active session time and frequency of meaningful sessions over 28 days (with daily caps to discourage AFK farming). | Core loop depth \+ "one more run" meta reinvestment directly drive this signal. Passive AFK lobbies hit diminishing algorithmic returns. | \[docs\] Home recommendations |
| **Signal 3 — Play Days per User:** Number of distinct calendar days a user returns within the 28-day window. | Daily login calendars, 3-quest daily boards, and weekly boss rotations are direct product levers for Play Days. | \[docs\] Home recommendations |
| **Signal 4 — Intentional Co-Play Days per User:** Days where users join with friends (via party, friend-join, or in-game invite). | One of the highest-leverage multipliers for a co-op survivor game. Friend XP boosts and co-op revive mechanics turn solo players into recruiters. | \[docs\] Home recommendations |
| **Signal 5 — Spend Days per User & Robux Spent per User:** Recurring purchase days and per-user revenue over 28 days. | A low-friction Starter Pack (49 to 99 Robux) and cheap repeatable impulse items (Revive, Reroll, Server Boost) raise Spend Days better than a single expensive pass. | \[docs\] Home recommendations |
| **Strict Organic Isolation:** Only behavior from users who discovered the game organically on the Home page feeds the RFY ranking model. External links, search, and Sponsored Ads traffic are isolated. | Paid ads cannot "buy" organic ranking directly; paid ads are used to test cohorts, validate funnels, and seed social co-play networks. | \[docs\] Home recommendations |
| **Per-User Averages (Not Raw Totals):** Signals are evaluated per player, not by gross CCU. | A polished indie game with 100 CCU and top-decile per-user retention/spend will be scaled up by Retrieval \+ Ranking. | \[docs\] Home recommendations |
| **Thumbnail Personalization:** Upload up to 5 distinct thumbnail variations. Roblox's multi-armed bandit tests and personalizes thumbnails per user segment to maximize qPTR. | Run each thumbnail test for at least 7 days (or until the next update) without resetting. Test distinct motivations (swarm action, boss fight, co-op squad, magic build evolution). | \[docs\] [Thumbnail personalization](https://create.roblox.com/docs/production/promotion/thumbnail-personalization) |
| **Today's Picks:** Curated/blended Home sort highlighting novel, polished experiences and major updates. | Requires high visual polish, clean compliance history, and compelling update cadence. | \[docs\] [Today's Picks](https://create.roblox.com/docs/promotion/todays-picks) |

## **2\. Marketing, User Acquisition and Creator Rewards**

| Rule / Channel | Product Strategy & Constraints | Source |
| :---- | :---- | :---- |
| **Soft-Launch with Experience Betas:** Public and linkable for community testing, but excluded from algorithmic Home recommendations until opted out of Beta. | Prevents early bugs or untuned XP curves from poisoning your initial organic 28-day cohort metrics. Requires the Maturity Questionnaire. | \[official\] [Experience Betas](https://devforum.roblox.com/t/a-new-way-to-test-before-launch-experience-betas/4144485) |
| **Maturity & Compliance Questionnaire Reach:** `Minimal` and `Mild` reach all age tiers (including Roblox Kids); `Moderate` blocks the youngest account tiers; unrated experiences are restricted. | Keep cartoon fantasy combat (skeletons/bats/golems fading or popping into gems without gore/blood) within `Mild` to preserve maximum addressable market. | \[docs\] [Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity) |
| **Creator Rewards — Daily Engagement:** Replaced legacy Engagement-Based Payouts (EBP) and Premium Payouts. Pays Robux when an **Active Spender** plays your experience for **at least 10 minutes** (counted across their first 3 experiences launched that day). | Design the core run \+ post-run upgrade loop to naturally span **10 to 15 minutes** so a single complete session qualifies for Daily Engagement payouts. | \[docs\] [Creator Rewards](https://create.roblox.com/docs/production/monetization/creator-rewards) |
| **Creator Rewards — Audience Expansion:** Replaced the standalone Creator Affiliate Pilot. Pays a revenue share on qualifying spend when your referral links bring **new signups** or reactivate **60-day lapsed users** (requires ID verification and DevEx setup). | Use tracked referral links across all short-form video (TikTok, YouTube Shorts, Reels) and Discord community announcements. | \[docs\] Creator Rewards |
| **Experience Events & Update Announcements:** Up to 10 scheduled events can appear on the experience detail page with RSVP ("Notify Me") push notifications and dedicated event thumbnails. | Pair every weekly or bi-weekly patch with an Experience Event and Update Announcement to reactivate opted-in followers on launch hour. | \[docs\] [Experience events](https://create.roblox.com/docs/production/promotion/events) |
| **Experience Notifications (`ExperienceNotificationService`):** Personalized re-engagement notifications for opted-in users (13+). Prompt opt-in via `PromptOptIn()` after checking `CanPromptOptInAsync()`. | Prompt opt-in right after a player's first boss kill, first weapon evolution, or when claiming a daily streak reward—never on initial spawn. | \[docs\] [Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications) |
| **In-Game Friend Invites (`SocialService:PromptGameInvite`):** Native invite modal supporting custom `ExperienceInviteOptions` (launch data, prompt message). | Trigger from a dedicated "Invite Friends (+10% Soul Boost)" button in the HUD/lobby to convert solo sessions into co-play sessions. | \[docs\] [SocialService](https://create.roblox.com/docs/reference/engine/classes/SocialService) |
| **Ads Manager (Sponsored Experiences):** Self-service bidding targeted by age, gender, device, and genre across Home and Search. | Do not scale ad spend until Onboarding Funnel completion exceeds 70% and D1 retention exceeds 20%. Use small test budgets (\$50 to \$200 / equivalent ad credits) to gather cohort data first. | \[docs\] [Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager) |

## **3\. Gamification, Retention and Survivor Genre Loop Design**

Survivor / bullet-heaven games (*Vampire Survivors*, *Survivor.io*, *Brotato*, and top Roblox wave-survivors) succeed or fail on the handoff between the **In-Run Micro Loop** and the **Session-to-Session Meta Loop**.

### **The Dual-Loop Architecture for roblouuux**

| Layer | Loop Steps | Key Psychological & Gamification Principles |
| :---- | :---- | :---- |
| **FTUE (First 60 Seconds)** | Spawn → Move (\<5s) → Auto-Attack Kills Skeleton (\<10s) → Vacuum XP Gem (\<20s) → Level 2 Upgrade Offer (\<40s) | **Zero lobby friction.** Never trap new players in a slow tutorial dialogue or empty waiting room. The first 3 XP levels should require low XP (currently 8, 12, 16 XP in `Constants.xpForLevel`—already well-tuned\!) so the player experiences the card-pick dopamine within 30 to 45 seconds. |
| **In-Run Micro Loop (10 to 12 Min Stage)** | Steer & Kite → Collect Gems → Pick 1 of 3 Upgrades → Mini-Boss Chest (3m, 6m, 9m) → Evolve Weapon → Final Boss (10m) | **Mechanical variety over flat math.** Upgrades that add projectiles (`Extra Bolt`), pierce (`Piercing Bolts`), or new visual orbits (`Guardian Orbs`) feel 10x more rewarding than invisible stat bumps. Combining a max-level weapon \+ matching passive into an **Evolved Weapon** creates a mid-run power fantasy climax. |
| **End-of-Run Bridge ("No Dead Runs")** | Death or Stage Clear → Results & Tally Screen → Meta-Currency Grant (Souls) → "Upgrade Talents" CTA → Play Again | **Loss aversion mitigation.** Currently, dying in `roblouuux` simply respawns at Level 1 after 3s with zero permanent reward. Instead, every run must award **Souls/Essence** (from kills, time survived, and mini-bosses) displayed on a juicy summary card, with enough Souls from Run 1 to buy the first permanent upgrade immediately. |
| **Meta-Progression Loop (D1 to D30)** | Spend Souls on Permanent Talent Tree / Unlock Classes → Fill Bestiary/Grimoire → Complete Daily Quests → Advance Season Pass | **Endowed progress \+ goal gradient.** Give players multiple overlapping goals: a cheap next talent node (1 run away), a daily quest (2 runs away), a new character/class unlock (5 runs away), and a Season Pass tier or weapon evolution discovery (long-term). |
| **Social Co-Play Loop** | Join with Friends (+10% Souls/XP per Friend) → Revive Downed Teammates in 3s Circle → Share Boss Chests → Compete on Weekly Leaderboard | Cooperative interdependence. Instead of automatic 3s solo respawns mid-round, downed co-op players should enter a "Downed Soul" state with a ring that teammates can stand in for 3s to revive them with their current level/upgrades intact\! |

## **4\. Monetization Architecture, Pricing and Economy Design**

Roblox's discovery and payout systems reward games where monetization is **broad (high payer conversion across Spend Days)** and **non-predatory (does not cause non-payers to quit)**.

### **Recommended Product Matrix for roblouuux**

| Category | Product Name | Price Tier (Base Robux) | Player Value Proposition & Conversion Moment |
| :---- | :---- | :---- | :---- |
| **Starter Pack (One-Time)** | Haunted Hunter Starter Bundle | 49 – 99 R\$ | Offered after Run 1 or Level 5\. Includes an exclusive starter Character Class/Skin, 500 Souls, 3 Reroll Tokens, and a 30-min 2x Soul Boost. Highest first-purchase converter. |
| **Game Pass (Permanent)** | Soul Magnet / Auto-Collect Pass | 149 – 249 R\$ | Permanently boosts base `PICKUP_RADIUS` by \+50% and magnet speed. Number-one convenience pass in survivor games. |
| **Game Pass (Permanent)** | Master Arcanist (+1 Upgrade Card) | 299 – 399 R\$ | Shows **4 upgrade choices** instead of 3 on every level-up (or \+2 free rerolls per run). Huge build-crafting appeal without raw stat P2W. |
| **Game Pass (Permanent)** | 2x Souls (Meta-Currency) | 399 – 499 R\$ | Doubles persistent Soul drops at the end of every run for faster talent tree and class unlocking. |
| **Game Pass (Permanent)** | VIP / Haunted Lord Pack | 499 – 799 R\$ | Exclusive cosmetic trail/aura, chat tag, daily Soul stipend, and \+20% XP gain. |
| **Dev Product (Repeatable)** | **Second Life / Mid-Run Revive** | 29 – 49 R\$ | **Highest-impulse consumable.** When a player dies after Minute 4 with a high-level build, offer a 10-second prompt to revive at full HP, clear nearby enemies, and keep all levels/upgrades (1 or 2 max per run). |
| **Dev Product (Repeatable)** | **Reroll / "Take All 3" Upgrade** | 15 – 39 R\$ | On the Level-Up UI, let players spend a Reroll Token (earned in-game or bought) to refresh the 3 cards, or a "Jackpot: Claim All 3 Cards" button for a low Robux impulse. |
| **Dev Product (Repeatable)** | **Server-Wide 2x Souls / XP Totem (15m)** | 99 – 149 R\$ | Activates a 15-minute 2x boost for **everyone in the arena**, announcing `[Player] lit the Blood Moon Totem! Everyone gets 2x Souls for 15m!` Social status \+ reciprocity drives repeat buys. |
| **Subscription (Monthly)** | Grim Coven Pass (Monthly) | \$2.99 – \$4.99 / mo | Checked via `MarketplaceService:GetUserSubscriptionStatusAsync`. Grants daily Reroll Tokens, exclusive evolving familiar/orb cosmetic, and Premium Season Pass track access. |

### **Pricing, Economy & Compliance Rules**

| Rule | Why | Source |
| :---- | :---- | :---- |
| **Enable Managed Pricing (Regional Pricing \+ Price Optimization):** Let Roblox adjust localized prices down to local purchasing power (up to a 70% discount floor) and test optimal price points. | Unlocks payer conversion in LATAM, SEA, and Eastern Europe where US-anchored Robux prices price out 90%+ of players. | \[docs\] [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing), [Price optimization](https://create.roblox.com/docs/production/monetization/price-optimization) |
| **Never Hardcode Robux Prices in UI:** Always query `MarketplaceService:GetProductInfoAsync` or `GetDeveloperProductsAsync` on the client to display the player's actual localized/optimized price. | Required by Price Optimization and Regional Pricing; hardcoded labels show the wrong price and violate UX guidelines. | \[docs\] Price optimization |
| **Prevent Combat Mis-Clicks (Safe Purchase UX):** Never pop up a Robux purchase prompt in the center of the screen without a deliberate button press or a 0.8s grace delay on death. | In an action game where players click or press `1/2/3`, accidental purchase prompts infuriate players, trigger refund/chargeback flags, and tank retention. | \[community\] \+ \[docs\] |
| **Enforce `POL-1` (`ProcessReceipt`) and `POL-2` (`PolicyService`):** All Developer Products must use idempotent `ProcessReceipt`; any randomized reward (chests, gacha skins/pets) must disclose exact % odds summing to 100% and gate on `ArePaidRandomItemsRestricted` (failing closed). | Mandatory platform policy and regional law (NL, BE, UK, etc.). | \[docs\] [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items), [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService) |

## **5\. Product Management Benchmarks, Analytics and Experimentation**

### **Target KPI Benchmarks for Launch Readiness**

| Metric | Platform Median | Target for roblouuux (Genre Top Quartile) | How to Measure |
| :---- | :---- | :---- | :---- |
| **Onboarding Funnel Completion** | \~40 – 50% | **\> 70%** (Spawn to First Level-Up & Run 1 Meta Upgrade) | `AnalyticsService:LogOnboardingFunnelStepEvent` |
| **First-Play Bounce Rate** | \~25 – 35% | **\< 18%** | Creator Hub Discovery / Home Recommendations |
| **Qualified Play-Through Rate (qPTR)** | \~1.5 – 2.5% | **\> 3.0%** | Creator Hub Acquisition / Thumbnail Personalization |
| **Average / Median Session Length** | \~9.8 min | **12 – 18 min** (crosses 10m Creator Rewards threshold) | Creator Hub Engagement |
| **Day 1 (D1) Retention** | \~10 – 15% | **22 – 30%+** | Creator Hub Retention |
| **Day 7 (D7) Retention** | \~3 – 6% | **8 – 14%+** | Creator Hub Retention |
| **Payer Conversion Rate (CVR)** | \~1.0 – 1.5% | **2.5 – 4.5%+** | Creator Hub Monetization |

### **Telemetry & Experimentation Stack**

| Tool / API | How We Use It in roblouuux | Source |
| :---- | :---- | :---- |
| **`LogOnboardingFunnelStepEvent`:** 1-time per player FTUE funnel. | Track steps: `1_Spawned` → `2_FirstEnemyKilled` → `3_FirstGemCollected` → `4_FirstLevelUpOffered` → `5_FirstUpgradeChosen` → `6_FirstRunEnded` → `7_FirstMetaUpgradeBought`. | \[docs\] [Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events) |
| **`LogFunnelStepEvent`:** Repeatable session funnels (with `funnelSessionId`). | Track Run Progression (`Minute_1`, `Minute_3_MiniBoss`, `Minute_6_MiniBoss`, `Minute_10_Boss`, `Run_Victory`) and Shop Conversion (`PromptShown` → `PurchaseClicked` → `PurchaseGranted`). | \[docs\] Funnel events |
| **`LogEconomyEvent`:** Tracks all currency `Source` and `Sink` flows with ending balance. | Log every Soul/Essence grant (`RunReward`, `DailyQuest`, `StarterPack`) and sink (`TalentUpgrade`, `ClassUnlock`, `Reroll`). Watch net wallet balance to prevent inflation. | \[docs\] [Economy events](https://create.roblox.com/docs/production/analytics/economy-events) |
| **`LogCustomEvent`:** Up to 100 distinct event names per experience; pass details in `customFields`. | Log `UpgradePicked` (`customFields = { upgradeId = id, level = lvl }`) and `PlayerDied` (`customFields = { killerKind = kind, runSeconds = sec }`) to balance upgrades and enemies with real data. | \[docs\] [Custom events](https://create.roblox.com/docs/production/analytics/custom-events) |
| **`ConfigService` & Experiments:** Remote config and 14 to 60 day A/B tests (baseline \+ up to 2 variants). | Override `Constants.luau` tuning knobs (`ENEMIES_PER_SECOND`, `BOLT_DAMAGE`, XP curve, Soul drop rate) via `ConfigService:GetConfigForPlayerAsync` to A/B test difficulty and economy without redeploying. | \[docs\] [Experiments](https://create.roblox.com/docs/production/experiments), [Configs](https://create.roblox.com/docs/production/configs) |

