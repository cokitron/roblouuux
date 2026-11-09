# roblouuux: Asset Pipeline and Credits

*In-Studio instances live in the place file, while custom parametric 3D designs live in `assets/solidcraft/` and exported meshes/textures in `assets/exports/`. Keep the place saved and backed up. Last synced 2026-11-01.*

## Where art lives

| Location | Contents | Used by |
| :---- | :---- | :---- |
| `assets/solidcraft/*.sc` | Native parametric SolidCraft 3D source files (weapons, orbs, soul gems, graveyard kit, ground clutter) | SolidCraft app & `solidcraft` MCP server |
| `assets/texturecraft/*.tcraft` | TextureCraft PBR painting projects (materials, smart masks, baked curvature/AO/normal maps) | TextureCraft app & `texturecraft` MCP server |
| `assets/exports/*` | Exported `.glb` textured models, `.obj` meshes, PBR texture maps, and rendered `.png` previews/icons | Imported into Roblox Studio or client renderer |
| `ServerStorage.GraveyardAssets` | 10 pure graveyard & ground clutter prefabs (tombstones, fences, sarcophagi, lanterns, dead trees, obelisks, ground units) | `Arena.luau` clones dynamically per run |
| `ReplicatedStorage.EnemyModels` | Sanitized templates for all 5 enemies: Skeleton, Bat, Spider, Golem, Wisp | `WorldRenderer.luau` clones one per enemy |

*Note: All legacy `ServerStorage.NaturePack` forest assets have been completely retired from the game.*

## Haunted Graveyard & Combat Asset Kit (SolidCraft & TextureCraft)

All assets below were modeled parametrically in SolidCraft, mesh maps baked and textured in TextureCraft with PBR materials, and exported to `assets/exports/`:

| Asset Name | SolidCraft Source | TextureCraft Project | Tris | PBR Materials & Visual Details |
| :---- | :---- | :---- | :---- | :---- |
| **Xp Soul Crystal** | `xp_soul_crystal.sc` | `xp_soul_crystal.tcraft` | 140 | Faceted dual-pyramid soul gem with tarnished bronze runic collar and pulsing inner soul light (Emerald / Arcane Sapphire / Eldritch Amethyst). |
| **Magic Bolt** | `magic_bolt.sc` | `magic_bolt.tcraft` | 76 | Arcane spearhead crystal bolt with crossed cyan blades, ornamental bronze collar, stabilizer fins, and trail emitter. |
| **Guardian Orb** | `guardian_orb.sc` | `guardian_orb.tcraft` | 196 | Runic astrolabe featuring a solar neon core, tumbling bronze equatorial/meridian gimbal rings, and gold cardinal spikes. |
| **Grave Cross Headstone** | `grave_cross_headstone.sc` | `grave_cross_headstone.tcraft` | 160 | Weathered slate cross with mossy stepped plinth and engraved bronze epitaph plaque. |
| **Grave Arched Tombstone** | `grave_arched_tombstone.sc` | `grave_arched_tombstone.tcraft` | 710 | Gothic arched tablet on mossy curb with glowing cyan runic cross medallion. |
| **Graveyard Iron Fence** | `graveyard_iron_fence.sc` | `graveyard_iron_fence.tcraft` | 500 | Wrought-iron fence panel with stone end pillars, horizontal rails, and spearhead finials. |
| **Graveyard Lantern Post** | `graveyard_lantern_post.sc` | `graveyard_lantern_post.tcraft` | 172 | Forged iron lantern post on cobblestone pedestal with warm amber PointLight flame. |
| **Graveyard Sarcophagus** | `graveyard_sarcophagus.sc` | `graveyard_sarcophagus.tcraft` | 176 | Cursed crypt sarcophagus with ajar lid revealing a necrotic violet seam and carved relief cross. |
| **Ground Grass Tuft** | `ground_grass_tuft.sc` | `ground_grass_tuft.tcraft` | 340 | Clustered dark cemetery grass with frosted tips for ground accenting. |
| **Ground Dead Roots** | `ground_dead_roots.sc` | `ground_dead_roots.tcraft` | 1,414 | Gnarled dark wood tree roots creeping across cobblestones and headstone bases. |
| **Ground Rubble Cluster** | `ground_rubble_cluster.sc` | `ground_rubble_cluster.tcraft` | 8,376 | Broken tombstone slate shards and mossy cobblestone rubble piles. |
| **Cemetery Dirt Surface** | (Procedural shader) | `surface_cemetery_dirt.tcraft` | 2 | 1024x1024 seamless cemetery soil texture with dark earth and gravel. |

## In-Engine Procedural Graveyard Prefabs

In addition to the mesh models, `Arena.luau` generates procedural multi-part graveyard landmarks in `ServerStorage.GraveyardAssets`:

- **`Graveyard_DeadTree`:** Gnarled dark bark trunk with sprawling skeletal branches and root mound.  
- **`Graveyard_Obelisk`:** Stepped mossy plinth with four-sided tapered slate spire and glowing cyan runic channel.

## Enemy & Weapon Models & Creator Store Credits (`PROC-6`)

| Asset / Enemy / Weapon | Asset ID (`MeshId` / `TextureId`) | Creator | Notes |
| :---- | :---- | :---- | :---- |
| **Skeleton (`Szkielet`)** | `122900915480688` | Matipre3 | Stripped to visual mesh parts; 15 parts |
| **Bat (`bat`)** | `13844735682` (`12444481426` wings) | Woofdadoggamer / LoopLoop85 | Swooping bat mesh + articulated wing flaps |
| **Spider (`Spider`)** | `136579301883061` | Thugtastico | Multi-part arachnid model |
| **Golem (`Golem Mesh`)** | `15721914045` (`447264636` crystal) | Pantasticker / XenoSynthesis | High-health mini-boss + Quartz Crystal Cluster |
| **Plague Slime (`Slime Monster`)** | `15115599443` (`2445801226` skull) | mamakoa256 / BLODSWIPER | 1,326-tri slime mesh + trapped skull core |
| **Frost Wyrm (`Ice Dragon`)** | `127058673521936` (`1513601847` head) | botolparfumm / Narutorobert | 2,992-tri horned dragon + glacial wings |
| **Infernal Imp (`Demon Horns`)** | `15555147076` (`MeshId 15555147009`) | gamenawesome100 | Curved black/crimson demon horns |
| **Grave Reaper (`Grim Reaper`)** | `2199985564` / `1561827216` scythe | TaddychicAdvenclub / zmby2 | Hooded reaper + Polyhex Scythe |
| **Skeleton / Armor Details** | `3284551923` ribcage, `2456506230` helm, `5579516226` sword | The Kingdom of Mordor / BLODSWIPER / LordLucifers | Ribcage torso, Elite Knight Helmet, Gothic Sword |
| **`PhantomBow` (*Glass Bow*)** | `524541876` (`MeshId 524541858`, `TexId 524541866`) | pitaden | Emerald crystal recurve bow + `871018403` Nord Arrow |
| **`CryptCleaver` (*Executioner's Axe*)** | `867643066` (`MeshId 867643049`, `TexId 867643060`) | pitaden | Heavy executioner great-cleaver |
| **`HexlockPistols` (*Flintlock Pistol*)** | `101559657970017` (`MeshId 123641875079236`) | imdie5677878 | Dual-wielded witch-hunter flintlock pistols |
| **`ArcanistStaff` (*Staff of Magnus*)** | `591079857` (`MeshId 591079842`, `TexId 591079849`) | pitaden | Claw-cradled astral mage staff |
| **`SoulflameLantern` (*Gothic Lantern*)** | `8260717445` / `14951552941` | fireflanger / NikaChanik | Wrought-iron gothic lantern censer + Wisp cage |
| **`StormcallerTome` (*Runic Grimoire*)** | `109820689568362` (`MeshId 120062356602177`) | AZelister12 | Levitating storm-bound grimoire |

All external Creator Store assets are free, audited (`hasScripts = false`), and stripped of non-visual instances via `hydratePendingStoreMeshes` in `src/server/EnemyCandidates.luau`; per-asset licenses were not independently verified beyond store terms.