# Haunted Graveyard Scenario Kit — SolidCraft & TextureCraft 3D Assets

All **5 Haunted Graveyard Scenario Kit** props have been modeled in **SolidCraft** (`assets/solidcraft/*.sc`), oriented `+Y` up (`assets/exports/*_yup.obj`), and textured in **TextureCraft** (`assets/texturecraft/*.tcraft`) with GPU-baked mesh maps (`ambient_occlusion`, `curvature`, `position`, `thickness`, `world_space_normals`), smart materials (`Stone Mossy`, `Iron Rusted`, `Bronze Statue`, `Copper Oxidized`), emissive soul/lantern channels, textured `.glb` exports, and Roblox `SurfaceAppearance` PBR texture sets.

---

## 1. TextureCraft GPU Path-Traced PBR Showcase (All 5 Graveyard Assets)

> [!TIP]
> **Coordinate Orientation Rule (`+Z` up → `+Y` up):** SolidCraft models are built `+Z` up, whereas TextureCraft and Roblox Studio use `+Y` up (`-Z` forward). Rotating the exported `.obj` by $-90^\circ$ around $X$ (`(x, y, z) -> (x, z, -y)`) before `mesh_import` ensures TextureCraft's `Direction` and `Position` generators place moss on upward-facing horizontal ledges (`+Y`) and ground dirt at the base (`Y = 0`), while emissive parts (`RuneMedallion`, `LanternGlow`, `CryptSoulGem`) cast physically based bounce light in path-traced renders (`128 samples/pixel`).

````carousel
![1. Gothic Cross Headstone — GPU Path-Traced PBR Render (128 spp)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_cross_headstone_pathtraced.png)
**1. Gothic Cross Headstone (`grave_cross_headstone.tcraft`) — 128 spp Path-Traced**
- `HeadstoneBody`: Customized **Stone Mossy** smart material (`Clouds` granite + `Fine noise` micro-bump normal + AO `Dirt` + upward-facing `Direction` moss on cross arms, shoulders, and plinth steps).
- `EpitaphPlaque`: **Bronze Statue** smart material (aged bronze with green verdigris streaks).
<!-- slide -->
![2. Arched Rune Tombstone — GPU Path-Traced PBR Render (128 spp)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_arched_tombstone_pathtraced.png)
**2. Arched Rune Tombstone (`grave_arched_tombstone.tcraft`) — 128 spp Path-Traced**
- `TombstoneBody`: Weathered dark cemetery slate + **Stone Mossy** over the curved arch crown, recessed arch ledge, and stepped base.
- `RuneMedallion`: **Copper Oxidized** + cellular cyan `emissive` soul-rune glow casting cyan bounce light inside the arch niche.
<!-- slide -->
![3. Haunted Wrought-Iron & Stone Fence — GPU Path-Traced PBR Render (128 spp)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_iron_fence_pathtraced.png)
**3. Haunted Wrought-Iron & Stone Fence (`graveyard_iron_fence.tcraft`) — 128 spp Path-Traced**
- `StonePillarL` & `StonePillarL (2)`: **Stone Mossy** with mossy obelisk caps and mottled weathered granite shafts.
- `IronFence`: **Iron Rusted** smart material across the twin horizontal rails and 5 peaked Gothic spear-tip pickets.
<!-- slide -->
![4. Gothic Graveyard Lantern Post — GPU Path-Traced PBR Render (128 spp)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_lantern_post_pathtraced.png)
**4. Gothic Graveyard Lantern Post (`graveyard_lantern_post.tcraft`) — 128 spp Path-Traced**
- `StonePedestal`: **Stone Mossy** stepped granite pedestal.
- `IronLampPost`: **Iron Rusted** wrought-iron post, collar, cross-arm, and lantern roof.
- `LanternGlow`: Warm amber `emissive` lantern glass illuminating the underside of the iron roof and bottom pan.
<!-- slide -->
![5. Cursed Crypt Sarcophagus — GPU Path-Traced PBR Render (128 spp)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_sarcophagus_pathtraced.png)
**5. Cursed Crypt Sarcophagus (`graveyard_sarcophagus.tcraft`) — 128 spp Path-Traced**
- `CryptBase` & `CryptLid`: Two-tone dark granite trough and mossy beveled slate lid (`Stone Mossy`).
- `ReliefCross`: **Bronze Statue** aged bronze cross with verdigris patina.
- `CryptSoulGem`: Cellular violet `emissive` soul gem casting purple light onto the bronze cross.
<!-- slide -->
![Gothic Cross Headstone — 2D UV Texture Sheet](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_cross_headstone_uv2d.png)
**6. Sample 2D UV Unwrap & Composite Sheet (`HeadstoneBody`, 1024×1024)**
Automatic non-overlapping UV unwrap (`overlapRatio = 0.0`) with infinite seam dilation on export.
<!-- slide -->
![Gothic Cross Headstone — Tangent-Space Normal Map](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/mesh_HeadstoneBody_Normal.png)
**7. Sample Exported Tangent-Space Normal Map (`mesh_HeadstoneBody_Normal.png`)**
Baked base normals combined with procedural stone micro-bump and moss relief.
````

---

## 2. SolidCraft CAD Viewport & Studio Icon Gallery

````carousel
![Gothic Cross Headstone — Viewport Preview](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_cross_headstone_preview.png)
**1a. Gothic Cross Headstone (`grave_cross_headstone.sc`) — SolidCraft Viewport**
<!-- slide -->
![Gothic Cross Headstone — Studio Icon](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_cross_headstone_icon.png)
**1b. Gothic Cross Headstone — 1024×1024 Transparent Studio Render**
<!-- slide -->
![Arched Rune Tombstone — Viewport Preview](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_arched_tombstone_preview.png)
**2a. Arched Rune Tombstone (`grave_arched_tombstone.sc`) — SolidCraft Viewport**
<!-- slide -->
![Arched Rune Tombstone — Studio Icon](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/grave_arched_tombstone_icon.png)
**2b. Arched Rune Tombstone — 1024×1024 Transparent Studio Render**
<!-- slide -->
![Haunted Wrought-Iron & Stone Fence — Viewport Preview](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_iron_fence_preview.png)
**3a. Haunted Wrought-Iron & Stone Fence (`graveyard_iron_fence.sc`) — SolidCraft Viewport**
<!-- slide -->
![Haunted Wrought-Iron & Stone Fence — Studio Icon](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_iron_fence_icon.png)
**3b. Haunted Wrought-Iron & Stone Fence — 1024×1024 Transparent Studio Render**
<!-- slide -->
![Gothic Graveyard Lantern Post — Viewport Preview](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_lantern_post_preview.png)
**4a. Gothic Graveyard Lantern Post (`graveyard_lantern_post.sc`) — SolidCraft Viewport**
<!-- slide -->
![Gothic Graveyard Lantern Post — Studio Icon](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_lantern_post_icon.png)
**4b. Gothic Graveyard Lantern Post — 1024×1024 Transparent Studio Render**
<!-- slide -->
![Cursed Crypt Sarcophagus — Viewport Preview](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_sarcophagus_preview.png)
**5a. Cursed Crypt Sarcophagus (`graveyard_sarcophagus.sc`) — SolidCraft Viewport**
<!-- slide -->
![Cursed Crypt Sarcophagus — Studio Icon](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/graveyard_sarcophagus_icon.png)
**5b. Cursed Crypt Sarcophagus — 1024×1024 Transparent Studio Render**
````

---

## 3. Complete Asset & Export Matrix

| Asset | SolidCraft Source (`.sc`) | TextureCraft Project (`.tcraft`) | Textured glTF (`.glb`) & PBR Maps (`1024×1024`) | Texture Sets / Smart Materials | `.obj` Triangles |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **1. Gothic Cross Headstone** | [grave_cross_headstone.sc](file:///Users/m/roblouuux/assets/solidcraft/grave_cross_headstone.sc) | [grave_cross_headstone.tcraft](file:///Users/m/roblouuux/assets/texturecraft/grave_cross_headstone.tcraft) (`10 MB`) | [grave_cross_headstone_textured.glb](file:///Users/m/roblouuux/assets/exports/grave_cross_headstone_textured.glb) (`5.0 MB`)<br>[textures/grave_cross_headstone/](file:///Users/m/roblouuux/assets/exports/textures/grave_cross_headstone/) | `HeadstoneBody` (`stone_mossy`)<br>`EpitaphPlaque` (`bronze_statue`) | `160` |
| **2. Arched Rune Tombstone** | [grave_arched_tombstone.sc](file:///Users/m/roblouuux/assets/solidcraft/grave_arched_tombstone.sc) | [grave_arched_tombstone.tcraft](file:///Users/m/roblouuux/assets/texturecraft/grave_arched_tombstone.tcraft) (`13 MB`) | [grave_arched_tombstone_textured.glb](file:///Users/m/roblouuux/assets/exports/grave_arched_tombstone_textured.glb) (`4.3 MB`)<br>[textures/grave_arched_tombstone/](file:///Users/m/roblouuux/assets/exports/textures/grave_arched_tombstone/) | `TombstoneBody` (`stone_mossy`)<br>`RuneMedallion` (`copper_patina` + cyan `emissive`) | `710` |
| **3. Haunted Wrought-Iron Fence** | [graveyard_iron_fence.sc](file:///Users/m/roblouuux/assets/solidcraft/graveyard_iron_fence.sc) | [graveyard_iron_fence.tcraft](file:///Users/m/roblouuux/assets/texturecraft/graveyard_iron_fence.tcraft) (`21 MB`) | [graveyard_iron_fence_textured.glb](file:///Users/m/roblouuux/assets/exports/graveyard_iron_fence_textured.glb) (`8.1 MB`)<br>[textures/graveyard_iron_fence/](file:///Users/m/roblouuux/assets/exports/textures/graveyard_iron_fence/) | `StonePillarL` & `StonePillarL (2)` (`stone_mossy`)<br>`IronFence` (`iron_rusted`) | `500` |
| **4. Gothic Lantern Post** | [graveyard_lantern_post.sc](file:///Users/m/roblouuux/assets/solidcraft/graveyard_lantern_post.sc) | [graveyard_lantern_post.tcraft](file:///Users/m/roblouuux/assets/texturecraft/graveyard_lantern_post.tcraft) (`20 MB`) | [graveyard_lantern_post_textured.glb](file:///Users/m/roblouuux/assets/exports/graveyard_lantern_post_textured.glb) (`6.3 MB`)<br>[textures/graveyard_lantern_post/](file:///Users/m/roblouuux/assets/exports/textures/graveyard_lantern_post/) | `StonePedestal` (`stone_mossy`)<br>`IronLampPost` (`iron_rusted`)<br>`LanternGlow` (amber `emissive`) | `172` |
| **5. Cursed Crypt Sarcophagus** | [graveyard_sarcophagus.sc](file:///Users/m/roblouuux/assets/solidcraft/graveyard_sarcophagus.sc) | [graveyard_sarcophagus.tcraft](file:///Users/m/roblouuux/assets/texturecraft/graveyard_sarcophagus.tcraft) (`27 MB`) | [graveyard_sarcophagus_textured.glb](file:///Users/m/roblouuux/assets/exports/graveyard_sarcophagus_textured.glb) (`10 MB`)<br>[textures/graveyard_sarcophagus/](file:///Users/m/roblouuux/assets/exports/textures/graveyard_sarcophagus/) | `CryptBase` & `CryptLid` (`stone_mossy`)<br>`ReliefCross` (`bronze_statue`)<br>`CryptSoulGem` (violet `emissive`) | `176` |
