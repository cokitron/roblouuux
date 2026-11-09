# Comprehensive Game Design: Starting Weapons & Talent Trees

**Project:** roblouuux (Gothic Graveyard Survivor)  
**Author:** Pair Programming Agent & Core Team  
**Status:** Approved for Implementation  
**Applicable Rules:** `PROC-1`, `PROC-2`, `LOOP-1`, `LOOP-2`, `LOOP-3`, `MON-1`, `MON-2`, `SEC-1`, `SEC-6`, `PERF-4`

---

## 1\. Executive Summary & Design Pillars

In classic survivor-style action RPGs (*Vampire Survivors*, *Halls of Torment*, *Death Must Die*), the **Starting Weapon** defines a character's core mechanical identity, sensory feedback ("game juice"), and tactical approach to surviving the swarm.

Up to this point, our prototype bundled a single hardcoded auto-attack (`MagicBolt`) and orbiting shield (`GuardianOrb`) into one global upgrade pool. This document formalizes a major architectural leap:

1. **Weapon-Centric Skill Bundles:** Every weapon equips an active **Primary Auto-Attack** paired with a complementary **Semi-Defensive / Offensive Aura**.  
2. **Dedicated Talent Trees per Weapon:** Instead of an undifferentiated pool of flat stats, each weapon commands its own structured **Talent Tree** spanning three distinct branches:  
   - **Branch A (Offensive Mastery):** Attack rate, extra projectiles, velocity, pierce, splash, and critical lethality.  
   - **Branch B (Aura Augmentation):** Orbit radius, rotational speed, hazard duration, tick rates, and shockwaves.  
   - **Branch C (Thematic Defense & Survivability):** Weapon-specific defensive layers (Damage Mitigation, Vampiric Siphon, Health Regen, Barriers, Thorns).  
3. **The 3 Starter Weapons:** Players choose their starting weapon in the **Haunted Sanctuary Courtyard Lobby** prior to entering the run.  
4. **Discoverable Skills Engine (Future Extensibility):** While players begin with their selected Starter Weapon, the system is architected so that in-run drops from elite enemies, sarcophagus chests, and boss kills can grant additional skill trees that plug directly into the player's active level-up roll slots.

```
flowchart TD
    subgraph Lobby ["Haunted Sanctuary Lobby"]
        WSelect["Weapon Arsenal Pedestals / UI<br/>(Choose 1 of 3 Starters)"]
    end

    subgraph RunStart ["Portal Deployment (InRun)"]
        W1["Arcanist's Staff<br/>(Magic Bolt + Guardian Orb)"]
        W2["Crypt Cleaver<br/>(Reaper's Cleave + Bone Whirlwind)"]
        W3["Soulflame Lantern<br/>(Spirit Cinders + Consecrated Ground)"]
    end

    subgraph TreeArch ["Weapon Talent Tree (Active Roll Pool)"]
        BranchAtk["Branch A: Primary Attack Mastery<br/>(Damage, Cooldown, Projectiles, Pierce)"]
        BranchAura["Branch B: Aura Mastery<br/>(Radius, Tick Rate, Knockback, Count)"]
        BranchDef["Branch C: Thematic Defense<br/>(Armor, Ward, Vampirism, Health)"]
        BranchUni["Universal Talents<br/>(Scholar XP, Fortune Luck, Second Wind)"]
    end

    subgraph LevelUp ["Level-Up Upgrade Slots (3 Cards / Choice)"]
        Cards["Roll 3 Cards from Active Trees<br/>(Weighted by Tier & Prerequisites)"]
    end

    WSelect --> W1
    WSelect --> W2
    WSelect --> W3
    W1 --> TreeArch
    W2 --> TreeArch
    W3 --> TreeArch
    TreeArch --> LevelUp
```

---

## 2\. The 3 Starter Weapons: Mechanical & Sensory Spec

Each starter weapon delivers a distinct tactile cadence, combat range, and risk/reward dynamic. All weapons pair a directional auto-attack with a personal defensive/offensive perimeter aura per the design mandate.

---

### Starter Weapon 1: Arcanist's Staff (The Celestial Scepter)

> *"Forged from fallen starlight and crypt iron, it channels the cold clarity of the void."*  
> 

* **Archetype:** Long-Range Precision Sniper & Orbiting Kinetic Barrier (Kiting / Spatial Control).  
* **Primary Auto-Attack — `MagicBolt`:**  
  * **Behavior:** Fires high-velocity arcane crystal spears toward the nearest enemy in range.  
  * **Base Values:** 8 Damage, 0.9s Cooldown, 75 Studs/s Speed, 80 Studs Range, 0 Pierce, 1 Bolt.  
  * **Visual & Sound:** Neon cyan crystal spearhead (`magic_bolt.sc`) leaving a soft cyan trail; crisp crystalline impact sound on hit.  
* **Paired Aura — `GuardianOrb`:**  
  * **Behavior:** Runic astrolabe cores orbit the caster continuously, colliding with and slicing through swarming enemies that attempt to close the distance.  
  * **Base Values:** 6 Damage, 9 Studs Orbit Radius, 2.4 rad/s Orbital Speed, 0.6s Hit Interval per enemy, 1 Orb.  
  * **Visual:** Golden solar spheres surrounded by spinning bronze gimbal rings with radiant point lights (`guardian_orb.sc`).  
* **Tactical Role:** Safe, deliberate spacing. Guardian Orbs chew through low-health sprinters (Bats/Spiders), keeping the Arcanist safe while Magic Bolts snipe high-threat Golems and Skeletons from afar.

---

### Starter Weapon 2: Crypt Cleaver (The Executioner's Scythe)

> *"A rusted executioner's crescent, hungry for the marrow of the unburied."*  
> 

* **Archetype:** Close/Mid-Range Sweeping Cleave & Radial Bone Repulsion (Aggressive Swarm-Buster).  
* **Primary Auto-Attack — `ReapersCleave`:**  
  * **Behavior:** Swings a sweeping crescent arc of spectral steel in the direction of the highest enemy density within front-facing range (110° cone). Slices through multiple enemies simultaneously with innate piercing.  
  * **Base Values:** 15 Damage, 1.35s Cooldown, 22 Studs Sweep Reach, 110° Front Arc, 3 Pierce (hits up to 4 foes per swing).  
  * **Visual & Sound:** Expanding spectral crescent blade wave (silver-violet gradient) slicing forward along the floor; heavy iron blade whoosh followed by bone-cracking impact.  
* **Paired Aura — `BoneWhirlwind`:**  
  * **Behavior:** Sharp gravestone shards and jagged ossuary ribs rotate closely around the warrior (5.5 studs radius). When an enemy enters the ring, the shards lash out, dealing damage and knocking enemies back to mid-range.  
  * **Base Values:** 8 Damage, 5.5 Studs Radius, 14 Studs Radial Knockback, 0.8s Hit Interval, 2 Bone Shards.  
  * **Visual:** Carved limestone headstone fragments and bleached ribs swirling in a spiraling vortex with purple necrotic trail wisps.  
* **Tactical Role:** Frontline brawler. Thrives when completely surrounded. The Bone Whirlwind keeps melee swarms at the exact optimal distance for the Cleaver's heavy crescent arc to decapitate them in batches.

---

### Starter Weapon 3: Soulflame Lantern (The Grave Censer)

> *"Burning with eternal ghostfire that devours both corpse and shadow."*  
> 

* **Archetype:** Area-of-Effect Hazard & Sanctified Ground Aura (Zone Denial / Chokepoint Pyre).  
* **Primary Auto-Attack — `SpiritCinders`:**  
  * **Behavior:** Hurls a cluster of spectral green-blue embers at the target area. On impact, the embers detonate in a fiery splash, leaving a small lingering necrotic pool (DoT) for 1.2 seconds.  
  * **Base Values:** 10 Direct Impact Damage \+ 3 Ticks of 2 Burn Damage over 1.2s, 1.1s Cooldown, 55 Studs/s Lobs, 65 Studs Range, 7 Studs Splash Radius.  
  * **Visual & Sound:** Arcing cyan-emerald fireball bursting into an ethereal flame pool; sizzle and ghostly hiss.  
* **Paired Aura — `ConsecratedGround`:**  
  * **Behavior:** An etched runic circle of sanctified grave ground radiates outward from the player's feet (12 studs radius). Enemies crossing into the circle suffer continuous soul burn and have their movement speed crippled.  
  * **Base Values:** 4 Damage every 0.5s, 12 Studs Radius, \-20% Enemy WalkSpeed Slow, 100% uptime aura.  
  * **Visual:** Intricate glowing runic seal projected onto the dirt with rising cyan wisps and embers.  
* **Tactical Role:** Defensive kite master. Forces enemies into choke points or trails behind the player; enemies who charge through the slow field are incinerated by the lingering pools before reaching the player.

---

## 3\. Detailed Talent Trees Specifications

Every starter weapon unlocks a dedicated **20-Talent Grid** divided into **Attack Mastery**, **Aura Augmentation**, and **Weapon-Thematic Defense**, alongside the **Universal Talents**.

Card Rarity Tiers:

* **Common (Tier 1 \- 68%):** Reliable foundational increments.  
* **Rare (Tier 2 \- 22%):** Noticeable mechanical shifts \+ stat bumps.  
* **Elite (Tier 3 \- 8%):** Significant mechanical alterations.  
* **Legendary (Tier 4 \- 2%):** Capstone multipliers, transformative behaviors, and evolution-tier power.

---

### Talent Tree 1: Arcanist's Staff (Arcane & Celestial)

#### Branch A: Primary Attack Mastery (Magic Bolt)

1. `bolt_damage` (**Sharper Magic** \- Max 5):  
   * *Common/Rare/Elite/Legendary:* `+25% / +45% / +70% / +100%` Bolt Damage.  
2. `bolt_cooldown` (**Quickcast** \- Max 5):  
   * *Values:* `-12% / -18% / -25% / -35%` Bolt Cooldown.  
3. `bolt_count` (**Extra Bolt** \- Max 3):  
   * *Values:* `+1 / +1 (+10% dmg) / +2 / +2 (+1 pierce)` Bolts per Volley.  
4. `bolt_pierce` (**Piercing Bolts** \- Max 3, Requires `bolt_damage >= 1`):  
   * *Values:* `+1 / +2 / +3 / +4` Enemy Pierce.  
5. `bolt_reach` (**Arcane Velocity** \- Max 4):  
   * *Values:* `+15% / +25% / +40% / +60%` Bolt Speed and Range.  
6. `bolt_crit` (**Keen Focus** \- Max 4):  
   * *Values:* `+6% / +10% / +15% / +22%` Critical Strike Chance (2x damage).

#### Branch B: Aura Augmentation (Guardian Orb)

7. `orb_count` (**Celestial Moons** \- Max 4):  
   * *Values:* `+1 / +1 (+15% dmg) / +2 / +2 (+25% dmg)` Orbiting Orbs.  
8. `orb_power` (**Empowered Astrolabe** \- Max 5):  
   * *Values:* `+30% / +50% / +75% / +110%` Orb Impact Damage.  
9. `orb_orbit` (**Cosmic Drift** \- Max 4, Requires `orb_count >= 1`):  
   * *Values:* `+15% / +25% / +40% / +60%` Orb Orbit Radius and Rotational Speed.  
10. `orb_resonance` (**Planetary Harmonic** \- Max 3, Requires `orb_count >= 2`):  
    * *Values:* When an Orb hits an enemy, it emits a resonant pulse dealing `4 / 8 / 14 / 22` AoE damage to adjacent enemies within 6 studs.

#### Branch C: Arcanist Thematic Defense & Survivability

11. `arcane_ward` (**Aether Barrier** \- Max 4):  
    * *Values:* Creates a shimmering mana ward granting `15 / 25 / 40 / 65` temporary shield points. The shield recharges fully if the player avoids damage for 6 seconds.  
12. `arcane_drift` (**Fleet Step** \- Max 4):  
    * *Values:* `+10% / +16% / +22% / +32%` Player Movement Speed.  
13. `arcane_regen` (**Mystic Renewal** \- Max 4):  
    * *Values:* `+0.6 / +1.0 / +1.6 / +2.5` Health Regenerated per second.  
14. `arcane_deflect` (**Phase Armor** \- Max 3, Requires `arcane_ward >= 1`):  
    * *Values:* Flat damage reduction: Take `1 / 2 / 3 / 5` less damage per hit.

---

### Talent Tree 2: Crypt Cleaver (Blood & Bone)

#### Branch A: Primary Attack Mastery (Reaper's Cleave)

1. `cleave_damage` (**Heavy Edge** \- Max 5):  
   * *Values:* `+25% / +45% / +70% / +100%` Cleave Damage.  
2. `cleave_speed` (**Blood Haste** \- Max 5):  
   * *Values:* `-12% / -18% / -25% / -35%` Cleave Cooldown.  
3. `cleave_arc` (**Wide Sweep** \- Max 4):  
   * *Values:* `+15° / +25° / +40° / +60°` Cleave Arc Width and `+2 / +4 / +6 / +9` Studs Reach.  
4. `cleave_rend` (**Sundering Blow** \- Max 3, Requires `cleave_damage >= 1`):  
   * *Values:* `+2 / +3 / +5 / +7` Enemy Pierce limit, and hit enemies are crippled (-25% speed for 2s).  
5. `cleave_execute` (**Grim Decapitation** \- Max 3):  
   * *Values:* Enemies below `15% / 25% / 35% / 50%` health struck by Cleave are instantly executed.

#### Branch B: Aura Augmentation (Bone Whirlwind)

6. `bone_count` (**Ossuary Spiral** \- Max 4):  
   * *Values:* `+1 / +1 (+15% dmg) / +2 / +2 (+25% dmg)` Whirling Bone Shards.  
7. `bone_damage` (**Serrated Ribs** \- Max 5):  
   * *Values:* `+30% / +50% / +75% / +110%` Bone Whirlwind Damage.  
8. `bone_repulsion` (**Gravewarden's Thrust** \- Max 3):  
   * *Values:* `+40% / +70% / +110% / +160%` Radial Knockback force, pushing enemies further away.  
9. `bone_shatter` (**Grave Burst** \- Max 3, Requires `bone_count >= 2`):  
   * *Values:* When an enemy dies inside the Bone Whirlwind, their bones detonate, dealing `12 / 20 / 32 / 50` damage to all surrounding enemies.

#### Branch C: Cleaver Thematic Defense & Survivability

10. `cleaver_armor` (**Ossuary Plating** \- Max 5):  
    * *Values:* Take `1 / 2 / 4 / 6` less damage from all sources.  
11. `cleaver_vampirism` (**Marrow Feast** \- Max 4):  
    * *Values:* `+4% / +7% / +11% / +16%` chance to restore `4 / 5 / 7 / 10` Health on kill.  
12. `cleaver_thorns` (**Barbed Carapace** \- Max 4):  
    * *Values:* Enemies that strike you take `8 / 15 / 26 / 42` physical retaliation damage.  
13. `cleaver_vitality` (**Colossus Frame** \- Max 4):  
    * *Values:* `+30 / +55 / +85 / +130` Max Health (and immediate heal for that amount).

---

### Talent Tree 3: Soulflame Lantern (Ghostfire & Sanctification)

#### Branch A: Primary Attack Mastery (Spirit Cinders)

1. `cinder_damage` (**Ghostfire Intensity** \- Max 5):  
   * *Values:* `+25% / +45% / +70% / +100%` Direct and DoT Damage.  
2. `cinder_cooldown` (**Stoked Hearth** \- Max 5):  
   * *Values:* `-12% / -18% / -25% / -35%` Throw Cooldown.  
3. `cinder_cluster` (**Multi-Censer** \- Max 3):  
   * *Values:* Hurls `+1 / +1 / +2 / +2` additional cinder clusters in a cluster burst.  
4. `cinder_pool` (**Lingering Pyre** \- Max 4):  
   * *Values:* `+30% / +50% / +80% / +120%` Splash Pool Area and `+0.5s / +1.0s / +1.5s / +2.2s` Pool Duration.  
5. `cinder_incinerate` (**Spreading Inferno** \- Max 3, Requires `cinder_damage >= 1`):  
   * *Values:* Burning enemies ignite other enemies who pass within `4 / 6 / 8 / 12` studs of them.

#### Branch B: Aura Augmentation (Consecrated Ground)

6. `hallowed_radius` (**Sacred Boundary** \- Max 4):  
   * *Values:* `+20% / +35% / +55% / +80%` Aura Radius.  
7. `hallowed_damage` (**Cleansing Flame** \- Max 5):  
   * *Values:* `+30% / +50% / +75% / +110%` Consecrated Ground tick damage.  
8. `hallowed_sloth` (**Binding Rites** \- Max 4):  
   * *Values:* Increases enemy movement slow from base 20% to `28% / 36% / 46% / 58%`.  
9. `hallowed_pyre` (**Judgment Sigil** \- Max 3, Requires `hallowed_radius >= 1`):  
   * *Values:* Every 4 seconds, the sacred circle flashes with divine fury, dealing `20 / 35 / 60 / 95` damage to all enemies inside and staggering them.

#### Branch C: Lantern Thematic Defense & Survivability

10. `lantern_resilience` (**Iron Will** \- Max 4):  
    * *Values:* `+25 / +45 / +75 / +115` Max Health and `+1 / +2 / +3 / +4` Armor while inside Consecrated Ground.  
11. `lantern_soothe` (**Sanctuary Mending** \- Max 4):  
    * *Values:* Regenerate `+0.8 / +1.4 / +2.2 / +3.4` Health per second while standing within Consecrated Ground.  
12. `lantern_magnet` (**Soul Beacon** \- Max 4):  
    * *Values:* `+40% / +65% / +100% / +150%` XP and Soul gem pickup radius.  
13. `lantern_purge` (**Retributive Flare** \- Max 3):  
    * *Values:* When you take damage, trigger an immediate flash burst knocking back all nearby enemies and dealing `15 / 28 / 45 / 70` damage.

---

### Universal / Shared Talents (Available to All Weapons)

1. `scholar` (**Scholar** \- Max 4): `+10% / +16% / +24% / +35%` Experience gain multiplier.  
2. `fortune` (**Fortune** \- Max 3): Higher tier card weights scaled by `+30% / +60% / +100%`.  
3. `heal` (**Second Wind** \- Unlimited Fallback): Emergency instant restoration of `40` Health.

---

## 4\. Slot Roll & Progression System ("Per Level-Up")

### Roll Algorithm Rules

1. **Dynamic Pool Assembly:**  
   When a player earns enough XP to trigger a Level-Up: \$\$\\text{RollPool} \= \\bigcup\_{W \\in \\text{EquippedWeapons}} \\text{Talents}(W) \\cup \\text{UniversalTalents}\$\$  
2. **Eligibility Filtering:**  
   A talent is eligible if and only if: \$\$\\text{CurrentRank}(\\text{Talent}) \< \\text{MaxRank}(\\text{Talent}) \\quad \\text{AND} \\quad \\text{PrerequisitesMet}(\\text{Talent}) \== \\text{true}\$\$  
3. **Weighting & Tier Rolling (`SEC-7`):**  
   Each offer card rolls its tier on the server via `TIER_WEIGHTS` `[68, 22, 8, 2]`, multiplied by \$(1 \+ \\text{luck})\$ for Rare, Elite, and Legendary tiers.  
4. **Offer Card Presentation:**  
   The server draws \$N \= 3\$ unique eligible talents from the pool and transmits them via the `LevelUpOffer` RemoteEvent.  
5. **Deterministic Fallback:**  
   If all active weapon talents and universal talents are maxed out, the system serves `Second Wind` (heal fallback), preventing softlocks.

---

## 5\. Discoverable Skills & Weapons Roadmap

Per the user's vision: *"the enemies will drop skills just not now, right now we should be able to pick and choose a starting skill, ... we will add more as discoverables in the runs"*.

### Future In-Run Drop Architecture

```
sequenceDiagram
    participant Boss as Elite / Sarcophagus Boss
    participant Drop as In-Run Skill Orb / Relic
    participant Player as Player Character
    participant Server as WeaponService / PlayerState
    participant UI as In-Run Level-Up Engine

    Boss->>Drop: Drops Golden Relic / Skill Core on Death
    Player->>Drop: Steps on Relic (Proximity Prompt or Overlap)
    Drop->>Server: Server validates proximity (SEC-1)
    Server->>Server: Attaches new Weapon Tree to player.equippedWeapons
    Server->>UI: Notifies client (Skill Acquired banner + HUD Icon)
    Note over Server,UI: Next level-up pool now rolls from BOTH Starter Tree + Dropped Tree!
```

* **Slot Allocation:** A player starts with 1 Weapon Slot (holding both the Primary Attack and Paired Aura). Future progression unlocks up to 3 active weapon/skill slots.  
* **Drop Sources:**  
  - *Mini-Boss at 3m / 6m / 9m:* Guaranteed Relic Chest dropping a new discoverable skill or weapon.  
  - *Grave Sarcophagi:* 15% chance to contain an ancient weapon scroll.

---

## 6\. Lobby Starting Weapon Selection & UI Architecture

### Lobby Courtyard Integration

The **Haunted Sanctuary Courtyard Lobby** (`Y = 14, Z = -288`) already features 3 Altar Pedestals flanking the central processional walkway:

1. **West Shrine:** Displays the **Arcanist's Staff** (`Relic_SoulCrystal` \+ `Relic_GuardianOrb`).  
2. **Center/East Shrine 1:** Displays the **Crypt Cleaver** (Executioner's crescent blade \+ spinning ossuary ribs).  
3. **Center/East Shrine 2:** Displays the **Soulflame Lantern** (Antique bronze censer glowing with ghostfire).

### Interactive Selection Flow

1. **Lobby Arsenal Button & Direct Pedestal Proximity:**  
   * Walking up to any pedestal shows a ProximityPrompt (`"Equip [Weapon Name]"`).  
   * In addition, the Sanctuary HUD features an **"🗡️ WEAPON ARSENAL"** button in the top header.  
2. **Weapon Selector Modal:**  
   * Displays the 3 starter weapons side-by-side with rich 3D-styled cards:  
     * Weapon Name, Icon, and Flavor text.  
     * Primary Auto-Attack stats (Damage, Cooldown, Type).  
     * Paired Aura stats (Aura Behavior, Damage, Radius).  
     * Talent Tree Summary preview (Offense, Aura, Defense).  
     * `"EQUIP WEAPON"` action button.  
3. **Network Security (`SEC-1` / `SEC-6`):**  
   * Fired via `SessionAction:FireServer("SelectWeapon", weaponId)`.  
   * Server validates `weaponId` against whitelist `{"ArcanistStaff", "CryptCleaver", "SoulflameLantern"}` and confirms `state.phase == "Lobby"`.  
   * The chosen weapon is stored in `state.selectedWeapon` and published as an attribute (`player:SetAttribute("SelectedWeapon", id)`).

---

## 7\. Technical Implementation Plan

| Step | Component | Files Touched | Responsibility |
| :---- | :---- | :---- | :---- |
| **1** | Weapon Definitions & Talent Registry | `src/server/WeaponDefinitions.luau`, `src/shared/Types.luau` | Pure data module registering all 3 weapons, their primary attacks, paired auras, and 3-branch talent trees. |
| **2** | Upgrade Engine Refactor | `src/server/Upgrades.luau` | Refactor `roll()` to assemble the candidate pool dynamically from the player's equipped weapon(s) and universal pool. |
| **3** | Weapon Combat Simulation | `src/server/WeaponService.luau` | Implement the simulation logic for `ReapersCleave`, `BoneWhirlwind`, `SpiritCinders`, and `ConsecratedGround`. |
| **4** | World Rendering & VFX | `src/client/WorldRenderer.luau` | Client-side visual models and analytical rendering for Cleaver crescents, bone whirlwinds, lantern cinder lobbing, and consecrated ground runic decals. |
| **5** | Lobby Selection & State | `src/server/PlayerState.luau`, `src/client/LobbyAndDeathUi.luau` | Lobby weapon selector UI, proximity prompts on pedestals, and remote event wiring with `SEC-1` validation. |
| **6** | Verification & Docs Sync | Studio Playtest, Drive Docs | `stylua` \+ `selene`, playtest all 3 starter weapons in Studio, and sync Drive docs. |

---

## 8\. Verification Plan

1. **Static Analysis:**  
   * Run `stylua src && selene src` ensuring 0 errors, 0 warnings.  
2. **Roblox Studio MCP Playtest:**  
   * Launch playtest with `start_stop_play(is_start: true)`.  
   * Test switching weapons in the Sanctuary Courtyard Lobby (verify attributes update).  
   * Deploy into Graveyard run with each of the 3 weapons:  
     * Verify Primary Attack fires correctly (spear, cleave, cinder).  
     * Verify Paired Aura behaves correctly (orbs, bones, consecrated circle).  
   * Level up and verify that the upgrade offer modal serves cards exclusively from that weapon's talent tree \+ universal pool.  
   * Verify defensive stats function (Armor absorbs damage, Vampirism restores health on kill, Ward blocks hits).  
   * Capture in-game screenshots and verify console logs are clean.