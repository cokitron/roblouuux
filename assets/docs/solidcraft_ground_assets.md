# Haunted Ground System & Clutter Units — SolidCraft & TextureCraft

To support survivor-style swarms (up to 150 enemies) with crisp mobile performance (`PERF-1`) and zero-obstacle floor math, we have created the complete **Modular Ground System**:
1. **Low-Poly 3D Ground Clutter Props (`SolidCraft` + `TextureCraft`)**: Non-colliding scatter units placed around headstones, trees, and paths.
2. **Tileable Cemetery Loam Surface PBR (`TextureCraft`)**: Base ground material for the arena floor slab.

---

## 1. Ground Clutter & Surface Gallery (128-spp GPU Path-Traced)

````carousel
![1. Stylized Cemetery Grass Tuft — GPU Path-Traced Render](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/ground_grass_tuft_pathtraced.png)
**1. Stylized Cemetery Grass Tuft (`ground_grass_tuft.tcraft`)**
- **Mesh:** 3 organic curved blades modeled via lofted sections in SolidCraft (`340` triangles, single body).
- **Materials:** Dark damp cemetery grass base with procedural autumn withered yellow/brown tips driven by a `Position` gradient generator.
<!-- slide -->
![2. Gnarled Dead Roots — GPU Path-Traced Render](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/ground_dead_roots_pathtraced.png)
**2. Gnarled Dead Roots (`ground_dead_roots.tcraft`)**
- **Mesh:** Creeping subterranean root cluster breaking through topsoil with branching root (`1,414` triangles, single body).
- **Materials:** Weathered decaying wood (`wood_weathered` smart material) with dark moss creeping along the base and crevices (`ambientOcclusion` generator).
<!-- slide -->
![3. Cemetery Rubble & Stone Cluster — GPU Path-Traced Render](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/ground_rubble_cluster_pathtraced.png)
**3. Cemetery Rubble & Stone Cluster (`ground_rubble_cluster.tcraft`)**
- **Mesh:** Trio of polygonal fractured stones resting flat on `Z = 0`.
- **Materials:** Mottled granite slate with damp crevice dirt and upper moss accumulation (`stone_mossy` smart material).
<!-- slide -->
![4. Tileable Cemetery Loam & Moss Surface — GPU Path-Traced Render](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/surface_cemetery_dirt_pathtraced.png)
**4. Tileable Cemetery Loam & Moss Surface (`surface_cemetery_dirt.tcraft`)**
- **Surface Layers:** Deep rich peat loam base + patchy cemetery moss turf (`Cells` mask) + wet mud depression pools with high specular roughness.
- **Export:** Exported as full Roblox `SurfaceAppearance` maps ready to apply to arena base floor slabs.
````

---

## 2. Asset & Export Matrix

| Asset | Type | SolidCraft / TextureCraft | Exported Textured GLB | Triangles | PBR Material Treatment |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **`ground_grass_tuft`** | Scatter Prop | [ground_grass_tuft.sc](file:///Users/m/roblouuux/assets/solidcraft/ground_grass_tuft.sc)<br>[ground_grass_tuft.tcraft](file:///Users/m/roblouuux/assets/texturecraft/ground_grass_tuft.tcraft) | [ground_grass_tuft_textured.glb](file:///Users/m/roblouuux/assets/exports/ground_grass_tuft_textured.glb) (`1.7 MB`) | `340` | Dark damp peat grass + withered autumn tips (`Position` gradient). |
| **`ground_dead_roots`** | Scatter Prop | [ground_dead_roots.sc](file:///Users/m/roblouuux/assets/solidcraft/ground_dead_roots.sc)<br>[ground_dead_roots.tcraft](file:///Users/m/roblouuux/assets/texturecraft/ground_dead_roots.tcraft) | [ground_dead_roots_textured.glb](file:///Users/m/roblouuux/assets/exports/ground_dead_roots_textured.glb) (`821 KB`) | `1,414` | Gnarled weathered wood + crevice moss (`ambientOcclusion`). |
| **`ground_rubble_cluster`** | Scatter Prop | [ground_rubble_cluster.sc](file:///Users/m/roblouuux/assets/solidcraft/ground_rubble_cluster.sc)<br>[ground_rubble_cluster.tcraft](file:///Users/m/roblouuux/assets/texturecraft/ground_rubble_cluster.tcraft) | [ground_rubble_cluster_textured.glb](file:///Users/m/roblouuux/assets/exports/ground_rubble_cluster_textured.glb) (`2.5 MB`) | `8,376` | Chipped granite rock cluster with mossy tops (`stone_mossy`). |
| **`surface_cemetery_dirt`** | Tileable Floor | [surface_cemetery_dirt.tcraft](file:///Users/m/roblouuux/assets/texturecraft/surface_cemetery_dirt.tcraft) | [textures/surface_cemetery_dirt/](file:///Users/m/roblouuux/assets/exports/textures/surface_cemetery_dirt/) (`1024×1024`) | N/A | Tileable loam soil + dead moss patches + wet mud depressions. |

---

## 3. Roblox Implementation & Performance Strategy (`PERF-1`)

1. **Floor Slab (`Y = 0`)**:
   - The playable arena floor is built with standard flat Parts using the `surface_cemetery_dirt` `SurfaceAppearance` texture set.
   - Ground level is strictly at `Y = 0`, ensuring server raycasts and mathematical distance checks for XP gems, bullets, and enemies are instantaneous and never glitch on bumpy voxels.
2. **Visual-Only Scatter Rules**:
   - Clutter props (`ground_grass_tuft`, `ground_dead_roots`, `ground_rubble_cluster`) are clustered organically around the bases of tombstone monuments and fence lines.
   - All clutter instances have:
     - `CanCollide = false`
     - `CanTouch = false`
     - `CanQuery = false`
     - `CastShadow = false` (or low-cost shadows on major pieces only)
   - Zero interference with player character movement or enemy pathing.
