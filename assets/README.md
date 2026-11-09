# roblouuux: Master Asset Catalog & Documentation Backup

This directory houses the complete asset pipeline, 3D CAD sources, PBR texture projects, export meshes, high-resolution renders, in-engine playtest screenshots, and technical documentation backups for **roblouuux** (Gothic Graveyard Survivor).

---

## 1. Directory Structure

```
assets/
├── README.md                              # This Master Catalog & Index
├── docs/                                  # Technical specifications & pipeline learnings
│   ├── starting_weapons_and_talent_trees_design.md
│   ├── lobby_and_respawn_monetization_plan.md
│   ├── artcraft_asset_pipeline_learnings.md
│   ├── solidcraft_graveyard_assets.md
│   ├── solidcraft_ground_assets.md
│   ├── solidcraft_combat_assets.md
│   └── drive_backups/                     # 14 Google Drive documentation markdown backups
│       ├── 00_start_here.md
│       ├── game_design_document.md
│       ├── feature_spec_starter_weapons_and_talent_trees.md
│       ├── feature_spec_lobby_and_monetized_respawn.md
│       ├── architecture_overview.md
│       ├── networking_protocol.md
│       ├── development_workflow_and_tooling.md
│       ├── decision_record_virtual_health_lifecycle.md
│       ├── safe_and_scalable_roblox_rules.md
│       ├── security_review_checklist.md
│       ├── asset_pipeline_and_credits.md
│       ├── product_management_gamification_and_monetization_rules.md
│       ├── roadmap_and_known_limits.md
│       └── release_checklist.md
├── solidcraft/                            # Parametric CAD Source Designs (.sc)
├── texturecraft/                          # Native PBR Texturing & Smart Material Projects (.tcraft)
├── exports/                               # Production 3D Meshes (.glb, .obj, .stl) & Baked Textures
│   └── textures/                          # PBR maps (BaseColor, Normal, Roughness, Metallic, Emissive)
├── renders/                               # High-Resolution Pathtraced Renders & Previews (.png)
└── screenshots/                           # In-Engine Studio Playtest Verification Screenshots (.jpg)
```

---

## 2. Master Asset Catalog

### Category A: Combat Weapons, Projectiles & Auras

| Asset | Description | SolidCraft (.sc) | TextureCraft (.tcraft) | Export (.glb / .obj) | Pathtraced Render | In-Engine Luau Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Magic Bolt** | Arcane crystal spearhead with crossed cyan blades and bronze fin collar | `solidcraft/magic_bolt.sc` | `texturecraft/magic_bolt.tcraft` | `exports/magic_bolt_textured.glb` | `renders/magic_bolt_preview.png` | `src/client/WorldRenderer.luau` (`buildBoltHead`) |
| **Guardian Orb** | Runic astrolabe with solar core, equatorial & meridian gimbal rings | `solidcraft/guardian_orb.sc` | `texturecraft/guardian_orb.tcraft` | `exports/guardian_orb_textured.glb` | `renders/guardian_orb_preview.png` | `src/client/WorldRenderer.luau` (`buildOrbAstrolabe`) |
| **Arcanist's Staff** | Gilded runic staff relic with spinning cyan focusing gem | Altar procedural prefab | Native PBR palette | Altar Model | Altar & HUD | `src/server/Arena.luau` (`Relic_ArcanistStaff`) |
| **Crypt Cleaver** | Heavy iron pole scythe with serrated back-spine and bone wraps | Altar procedural prefab | Native PBR palette | Altar Model | Altar & HUD | `src/server/Arena.luau` (`Relic_CryptCleaver`) |
| **Soulflame Lantern** | Hexagonal gothic iron lantern housing a floating necrotic soul ember | Altar procedural prefab | Native PBR palette | Altar Model | Altar & HUD | `src/server/Arena.luau` (`Relic_SoulflameLantern`) |
| **Bone Whirlwind** | Curved serrated bone shards orbiting in kinetic defensive ring | Procedural Luau mesh | Bleached Bone palette | Procedural Part | In-engine VFX | `src/client/WorldRenderer.luau` (`buildBoneShard`) |
| **Consecrated Ground** | Glowing runic sacred circle slowing and burning undead foes | Procedural Luau mesh | Sacred Cyan palette | Procedural Part | In-engine VFX | `src/client/WorldRenderer.luau` (`updateConsecrated`) |

### Category B: Drops & Pickups

| Asset | Description | SolidCraft (.sc) | TextureCraft (.tcraft) | Export (.glb / .obj) | Pathtraced Render | In-Engine Luau Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **XP Soul Crystal** | Multi-tier faceted soul gem with chiseled rune collar and light trail | `solidcraft/xp_soul_crystal.sc` | `texturecraft/xp_soul_crystal.tcraft` | `exports/xp_soul_crystal_textured.glb` | `renders/xp_soul_crystal_preview.png` | `src/server/GemService.luau` (`buildSoulCrystal`) |

### Category C: Graveyard Monuments & Headstones

| Asset | Description | SolidCraft (.sc) | TextureCraft (.tcraft) | Export (.glb / .obj) | Pathtraced Render | In-Engine Luau Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Grave Arched Tombstone** | Stepped limestone headstone with chiseled epitaph plaque and rune arch | `solidcraft/grave_arched_tombstone.sc` | `texturecraft/grave_arched_tombstone.tcraft` | `exports/grave_arched_tombstone_textured.glb` | `renders/grave_arched_tombstone_pathtraced.png` | `src/server/Arena.luau` (`Graveyard_ArchedHeadstone`) |
| **Grave Cross Headstone** | Weathered granite cross monument with beveled finials and pedestal | `solidcraft/grave_cross_headstone.sc` | `texturecraft/grave_cross_headstone.tcraft` | `exports/grave_cross_headstone_textured_3d.png` | `renders/grave_cross_headstone_pathtraced.png` | `src/server/Arena.luau` (`Graveyard_CrossHeadstone`) |
| **Graveyard Sarcophagus** | Raised crypt sarcophagus with chamfered lid, relief cross, and glowing soul gem | `solidcraft/graveyard_sarcophagus.sc` | `texturecraft/graveyard_sarcophagus.tcraft` | `exports/graveyard_sarcophagus_textured.glb` | `renders/graveyard_sarcophagus_pathtraced.png` | `src/server/Arena.luau` (`Graveyard_Sarcophagus`) |
| **Graveyard Lantern Post** | Forged wrought-iron lamp post with hooked finial, glass panes, and amber light | `solidcraft/graveyard_lantern_post.sc` | `texturecraft/graveyard_lantern_post.tcraft` | `exports/graveyard_lantern_post_textured.glb` | `renders/graveyard_lantern_post_pathtraced.png` | `src/server/Arena.luau` (`Graveyard_LanternPost`) |
| **Graveyard Iron Fence** | Continuous wrought-iron perimeter fence with stone pillars and gothic pickets | `solidcraft/graveyard_iron_fence.sc` | `texturecraft/graveyard_iron_fence.tcraft` | `exports/graveyard_iron_fence_textured.glb` | `renders/graveyard_iron_fence_pathtraced.png` | `src/server/Arena.luau` (`Graveyard_IronFence`) |

### Category D: Ground Clutter & Natural Surface

| Asset | Description | SolidCraft (.sc) | TextureCraft (.tcraft) | Export (.glb / .obj) | Pathtraced Render | In-Engine Luau Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Ground Grass Tuft** | 9-blade asymmetric withered grave grass cluster with curved tips | `solidcraft/ground_grass_tuft.sc` | `texturecraft/ground_grass_tuft.tcraft` | `exports/ground_grass_tuft_textured.glb` | `renders/ground_grass_tuft_pathtraced.png` | `src/server/Arena.luau` (`Ground_GrassTuft`) |
| **Ground Dead Roots** | Multi-branching twisted root tangle emerging from cemetery soil | `solidcraft/ground_dead_roots.sc` | `texturecraft/ground_dead_roots.tcraft` | `exports/ground_dead_roots_textured.glb` | `renders/ground_dead_roots_pathtraced.png` | `src/server/Arena.luau` (`Ground_DeadRoots`) |
| **Ground Rubble Cluster** | 7-part tumbled ashlar masonry rubble pile around monuments | `solidcraft/ground_rubble_cluster.sc` | `texturecraft/ground_rubble_cluster.tcraft` | `exports/ground_rubble_cluster_textured.glb` | `renders/ground_rubble_cluster_pathtraced.png` | `src/server/Arena.luau` (`Ground_RubbleCluster`) |
| **Surface Cemetery Dirt** | Ground surface texture with damp soil, broken bone fragments, and moss | — | `texturecraft/surface_cemetery_dirt.tcraft` | `exports/textures/` | `renders/surface_cemetery_dirt_pathtraced.png` | `src/server/Arena.luau` (Ground Material) |

### Category E: Architecture & Crypt Complexes

| Asset | Description | SolidCraft (.sc) | TextureCraft (.tcraft) | Export (.glb / .obj) | Pathtraced Render | In-Engine Luau Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Catacomb Descent Portal** | Subterranean stairway entrance framed by heavy stonework and glowing rune portal | `solidcraft/catacomb_descent_portal.sc` | `texturecraft/catacomb_descent_portal.tcraft` | `exports/catacomb_descent_portal_textured.glb` | `renders/catacomb_descent_portal_preview.png` | `src/server/Arena.luau` (`Sanctuary_Portal`) |
| **Gothic Mausoleum** | Free-standing ashlar mausoleum with peaked roof, portico columns, and iron gates | `solidcraft/gothic_mausoleum.sc` | `texturecraft/gothic_mausoleum.tcraft` | `exports/gothic_mausoleum_textured.glb` | `renders/gothic_mausoleum_preview.png` | `src/server/Arena.luau` (`Graveyard_Mausoleum`) |
| **Mortuary Chapel** | Sizable cemetery chapel with lancet arch windows, rose window, and buttresses | `solidcraft/mortuary_chapel.sc` | `texturecraft/mortuary_chapel.tcraft` | `exports/mortuary_chapel_textured.glb` | `renders/mortuary_chapel_preview.png` | `src/server/Arena.luau` (Lobby Backdrop) |
| **Caretaker Lodge** | Weathered stone dwelling with timber framing, chimney, and dormer roof | `solidcraft/caretaker_lodge.sc` | `texturecraft/caretaker_lodge.tcraft` | `exports/caretaker_lodge_textured.glb` | `renders/caretaker_lodge_preview.png` | `src/server/Arena.luau` (Outskirt Landmark) |

### Category F: Custom Enemies

| Asset | Description | SolidCraft (.sc) | TextureCraft (.tcraft) | Export (.glb / .obj) | Pathtraced Render | In-Engine Luau Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Will-o'-the-Wisp** | Ethereal floating soul entity with jagged core, swirling mist, and spectral flare | `solidcraft/will_o_wisp.sc` | `texturecraft/will_o_wisp.tcraft` | `exports/will_o_wisp_textured.glb` | `renders/will_o_wisp_preview.png` | `src/server/EnemyService.luau` (`Kind = 5`) |

---

## 3. Documentation Backups (`assets/docs/`)

All project specifications, architectural guides, rulesets, and design decisions are mirrored locally in `assets/docs/`:

### Core Feature Specifications & Research
- `assets/docs/starting_weapons_and_talent_trees_design.md`: Approved comprehensive design covering the 3 starter weapons, attack/aura pairings, and 3-branch talent trees.
- `assets/docs/lobby_and_respawn_monetization_plan.md`: Approved design for the Haunted Sanctuary Courtyard Lobby and 10-second monetized Soul Revive respawn window.
- `assets/docs/artcraft_asset_pipeline_learnings.md`: Complete engineering runbook and best practices for SolidCraft CAD and TextureCraft PBR asset generation.
- `assets/docs/solidcraft_graveyard_assets.md`: Architectural specification for the graveyard monuments, sarcophagi, and iron fences.
- `assets/docs/solidcraft_ground_assets.md`: Design specification for organic cemetery ground clutter, grass tufts, roots, and rubble.
- `assets/docs/solidcraft_combat_assets.md`: Technical specification for magic bolts, guardian orbs, and soul crystals.

### Google Drive Documentation Hub Mirror (`assets/docs/drive_backups/`)
Mirrored from the cloud hub at `https://drive.google.com/drive/folders/1bMOzPkOLv8y0vE985PvvUfp916b54lPq`:

| Document | Cloud Doc ID | Local Backup Path |
| :--- | :--- | :--- |
| **00 Start Here** | `1gGfyzPjZtnByJwP0mxme7eZ-FLDfrbpC2Pms-Omj0wM` | `assets/docs/drive_backups/00_start_here.md` |
| **Game Design Document** | `1t4UT6mSyfz6qAPvWlYSy35f5fBKYhYgThuwF2ZXLSxw` | `assets/docs/drive_backups/game_design_document.md` |
| **Feature Spec: Starter Weapons & Talent Trees** | `14ky3JFHhd6bHeQ8u3oAMZ0Re7b0el6u32HZ0YyUWX9A` | `assets/docs/drive_backups/feature_spec_starter_weapons_and_talent_trees.md` |
| **Feature Spec: Sanctuary Lobby & Monetized Respawn** | `1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0` | `assets/docs/drive_backups/feature_spec_lobby_and_monetized_respawn.md` |
| **Architecture Overview** | `1zgqYcAnbpbyfMgX4ZkcR_DXLOCMeIpeME9VniQd-840` | `assets/docs/drive_backups/architecture_overview.md` |
| **Networking Protocol** | `1nU_q0LUDHdX2_CClhurBB1V9JoYrpBal__AEzLzpToI` | `assets/docs/drive_backups/networking_protocol.md` |
| **Development Workflow & Tooling** | `1gN896DGisvkk-NA5C7kmdTO2vpuLY1Ji2tndC3hEuqs` | `assets/docs/drive_backups/development_workflow_and_tooling.md` |
| **Decision Record: Virtual Health Lifecycle** | `145nB_NYq5SxP_yKbCtfDKrkK50mIt3mYZf7vL5GkqbA` | `assets/docs/drive_backups/decision_record_virtual_health_lifecycle.md` |
| **Safe & Scalable Roblox Rules** | `14aPSOr8vxaxdJeuVkj60LdgC4iL5l_Rvai3WwemxsHw` | `assets/docs/drive_backups/safe_and_scalable_roblox_rules.md` |
| **Security Review Checklist** | `1K6iFUESYOJb9uXmaKH7s4wf2K9Qa4NcFatTJfRYd14U` | `assets/docs/drive_backups/security_review_checklist.md` |
| **Asset Pipeline & Credits** | `1tyr7FuwpmlfVOzf9sxL2mbJethCRdmewVh7PB5DX4iQ` | `assets/docs/drive_backups/asset_pipeline_and_credits.md` |
| **Product Management & Monetization Rules** | `1uaCAd_F9F8a_z3bd_A253bCIDvSzBjhtElVUUon8bQk` | `assets/docs/drive_backups/product_management_gamification_and_monetization_rules.md` |
| **Roadmap & Known Limits** | `1-D_cKYKGglsIo9gRkGjbgXm5eDlwwJYjExvuWGbVWxw` | `assets/docs/drive_backups/roadmap_and_known_limits.md` |
| **Release Checklist** | `1jMID1BnnVgoRLBS1YJTBpj574reYGwqi9R6moFtjvRM` | `assets/docs/drive_backups/release_checklist.md` |

---

## 4. In-Engine Verification Screenshots (`assets/screenshots/`)

| Screenshot File | Resolution | Verified Mechanics |
| :--- | :--- | :--- |
| `third_person_combat_verified.jpg` | 1344 x 756 | Responsive 3rd-person follow camera, character auto-facing, swarm tracking, projectile trails, orbiting astrolabes |
| `third_person_lobby_verified.jpg` | 1344 x 756 | 3rd-person camera inside Sanctuary Courtyard, cobblestone terrace, glowing Runic Portal, Lobby HUD |
| `sanctuary_lobby_verified.jpg` | 1344 x 756 | Elevated Sanctuary Courtyard overlooking graveyard north gate, Runic Crypt Portal, Souls wallet badge |
| `graveyard_run_revived_verified.jpg` | 1344 x 756 | 10-second Downed revive window, 36-stud Eldritch Shockwave clear, keep-build full health restore |
| `graveyard_playtest_verified.jpg` | 1344 x 756 | Procedural graveyard obstacles, wrought-iron fences, sarcophagi, XP soul crystals, multi-enemy swarm |

---

## 5. Dual Deployment Architecture

All custom 3D models in this repository follow a **dual deployment pattern**:
1. **Engine Prefabs (`src/server/Arena.luau` & `ServerStorage.GraveyardAssets`):** Every SolidCraft model is mirrored by a 1:1 multi-part procedural Luau assembly matching the exact body hierarchy and PBR materials. This allows instantaneous, offline playtesting with zero network lag or cloud asset dependencies.
2. **Production Meshes & PBR Textures (`assets/exports/`):** When ready for production publishing, the `.glb` files and PBR textures (`SurfaceAppearance`) can be uploaded to Roblox Creator Store / Asset Manager to replace the procedural assemblies seamlessly.
