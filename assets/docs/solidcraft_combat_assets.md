# SolidCraft 3D Asset Batch 1: Core Combat & Pickups

Built live via the `solidcraft` MCP server (`SolidCraft 0.29.0`) following our low-poly Haunted Forest art direction and strict triangle/part budgets (`PERF-1`, `PERF-4`).

````carousel
![XP Soul Crystal — Studio Render (92 tris, 2 bodies)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/xp_soul_crystal_icon.png)
<!-- slide -->
![Arcane Magic Bolt — Studio Render (52 tris, 2 bodies)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/magic_bolt_icon.png)
<!-- slide -->
![Guardian Rune Orb — Studio Render (188 tris, 3 bodies)](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/guardian_orb_icon.png)
<!-- slide -->
![XP Soul Crystal — SolidCraft Viewport](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/xp_soul_crystal_preview.png)
<!-- slide -->
![Arcane Magic Bolt — SolidCraft Viewport](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/magic_bolt_preview.png)
<!-- slide -->
![Guardian Rune Orb — SolidCraft Viewport](/Users/m/.gemini/antigravity/brain/748196be-574b-4d5d-87ed-9567996dd19d/guardian_orb_preview.png)
````

---

## Parametric & Performance Summary

| Asset | Source File (`.sc`) | Exported Meshes & Icons | Bodies | Triangles | Total Volume ($\text{mm}^3$) | Bounding Box ($\text{mm}$, $Z \ge 0$) |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **XP Soul Crystal** | [xp_soul_crystal.sc](file:///Users/m/roblouuux/assets/solidcraft/xp_soul_crystal.sc) | [xp_soul_crystal.obj](file:///Users/m/roblouuux/assets/exports/xp_soul_crystal.obj) (`10 KB`), [xp_soul_crystal.stl](file:///Users/m/roblouuux/assets/exports/xp_soul_crystal.stl), [xp_soul_crystal_icon.png](file:///Users/m/roblouuux/assets/exports/xp_soul_crystal_icon.png) | 2 (`CrystalCore`, `RuneCollar`) | **92** | `37,490.24` | `[-21, -18.19, 0]` to `[21, 18.19, 64]` |
| **Arcane Magic Bolt** | [magic_bolt.sc](file:///Users/m/roblouuux/assets/solidcraft/magic_bolt.sc) | [magic_bolt.obj](file:///Users/m/roblouuux/assets/exports/magic_bolt.obj) (`5.2 KB`), [magic_bolt.stl](file:///Users/m/roblouuux/assets/exports/magic_bolt.stl), [magic_bolt_icon.png](file:///Users/m/roblouuux/assets/exports/magic_bolt_icon.png) | 2 (`BoltCore`, `BoltCollar`) | **52** | `14,152.67` | `[-19, -36, 0]` to `[19, 28, 38]` (nose at $-Y$) |
| **Guardian Rune Orb** | [guardian_orb.sc](file:///Users/m/roblouuux/assets/solidcraft/guardian_orb.sc) | [guardian_orb.obj](file:///Users/m/roblouuux/assets/exports/guardian_orb.obj) (`18 KB`), [guardian_orb.stl](file:///Users/m/roblouuux/assets/exports/guardian_orb.stl), [guardian_orb_icon.png](file:///Users/m/roblouuux/assets/exports/guardian_orb_icon.png) | 3 (`OrbCore`, `EquatorialRing`, `MeridianRing`) | **188** | `25,721.72` | `[-25, -25, 0]` to `[25, 25, 50]` |

> [!TIP]
> **Low-Poly Mesh Optimization (`PERF-1`):** Replacing the analytical NURBS sphere in `Guardian Rune Orb` with a 26-face octagonal bipyramid crystal dome cut the exported `.obj` triangle count from **10,352 triangles (4.3 MB)** down to **188 triangles (18 KB)**—a **99.6% reduction** while matching the faceted crystal style of the Soul Crystal and Magic Bolt.
