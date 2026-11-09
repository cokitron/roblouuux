# roblouuux: Development Workflow and Tooling

*How code and 3D/2D PBR assets get from disk into Studio, how changes are verified, and how Claude Code and Antigravity are set up to work on this project. Last synced 2026-11-01.*

## Tools in use

| Tool | Purpose | Config / Binary |
| :---- | :---- | :---- |
| Rojo | Syncs `src/` into Studio (`ServerScriptService`, `StarterPlayerScripts`, `ReplicatedStorage`) | `default.project.json` |
| StyLua | Luau formatter (tabs, 120 columns, double quotes, always call parentheses) | `stylua.toml` |
| Selene | Luau linter with `std = "roblox+isfinite"` patch | `selene.toml`, `roblox.yml`, `isfinite.yml` |
| Roblox Studio MCP | Inspects the live DataModel, executes Luau, runs playtests, reads console output, uploads textures, and captures screenshots | `.mcp.json`, `~/.gemini/config/mcp_config.json` |
| SolidCraft MCP & CLI | Parametric 3D CAD modeling (`.sc`), mesh export (`.obj`, `.stl`, `.3mf`, `.step`), and studio-lit path-traced PNG rendering | `.mcp.json`, `/Applications/SolidCraft.app/Contents/MacOS/solidcraft-cli` |
| TextureCraft MCP | 3D PBR texture painting (`.tcraft`), mesh map baking (AO, Curvature, Normal, Position), procedural smart materials, and textured `.glb` / PBR map export | `.mcp.json`, `/Applications/TextureCraft.app/Contents/MacOS/texturecraft-mcp` |
| ArtCraft Suite | Creative suite launcher (`SolidCraft`, `TextureCraft`, `PhotoCraft`, `VectorCraft`, `SoundCraft`, `FigCraft`, `PdfCraft`) | `/Applications/ArtCraft Launcher.app` |
| Google Drive & Docs CLIs | Syncs engineering, design, architecture, and product documentation directly with the `roblouuux Game Docs` Drive hub | `gdrive`, `gdocs` skills |
| Claude Code & Antigravity | Agentic development with shared engineering rules (`SEC/DATA/POL/PERF/PROC`), product rules (`DISC/LOOP/MON/PM`), playbooks, and reviewer agent | `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/` |

Not set up yet: version control (the folder is not a git repository), a package manager (Wally or pesde), a headless unit test runner, CI.

## Daily code & Studio loop

1. Start Rojo serve and connect the Studio plugin.  
2. Edit Luau on disk in `src/`. Never edit Rojo-managed scripts in Studio; the next sync overwrites them.  
3. Run `stylua src` and `selene src` until both exit with 0 errors and 0 warnings.  
4. Playtest in Studio (`start_stop_play`), verify `get_console_output` is completely clean, and capture a viewport screenshot (`screen_capture`) for visual/UI work.  
5. Save the `.rbxl` place file whenever `ServerStorage.GraveyardAssets`, `ReplicatedStorage.EnemyModels`, or lighting change.

## ArtCraft Suite 3D CAD & PBR Asset Pipeline (`SolidCraft` \-\> `TextureCraft` \-\> `Roblox Studio`)

All custom 3D weapons, pickups, and graveyard environment props follow our 3-stage ArtCraft pipeline (documented in detail in `.claude/skills/solidcraft-roblox-assets/SKILL.md` and `.claude/skills/texturecraft-pbr-painting/SKILL.md`):

### Stage 1: Parametric 3D Modeling in SolidCraft (`solidcraft` MCP)

- **Pivot & Scale Contract:** Model with bottom-center at world origin `(0, 0, 0)`, forward axis facing `-Z`, and `Y` up. Reference sizes: `1 Roblox stud = 10 mm` in CAD (`30-50 mm` for pickups/projectiles, `60-180 mm` for graveyard props).  
- **Separate Bodies by Material Region:** Use `operation = "NewBody"` on extrudes, revolves, lofts, and sweeps that represent distinct materials (e.g., `GraniteBody`, `IronTrim`, `SoulCore`, `BronzeCollar`). When exported to `.obj`, each body becomes a separate named mesh/texture set in TextureCraft, enabling zero-bleed multi-material assignment without manual UV masking.  
- **Avoid Degenerate Sweeps & Zero-Thickness Primitives:**  
  - Never place a `create_circle` profile inside the same sketch as a collinear sweep path (`Sweep error: Wire projection failed`). Place the profile on an orthogonal plane at the start of the path.  
  - Ensure all extrusions and circular patterns are `>= 1.5 mm` thick so they survive mesh tessellation and Roblox collision checks.  
- **Save & Export:** Save native parametric designs to `assets/solidcraft/<name>.sc` and export `.obj` meshes to `assets/exports/<name>.obj`.

### Stage 2: Mesh Map Baking & PBR Material Authoring in TextureCraft (`texturecraft` MCP)

- **Project Creation & UV Unwrap:** Call `project_new` with `mesh_path = "assets/exports/<name>.obj"`, `resolution = 1024`, and `auto_unwrap = true`.  
- **Self-Bake Curvature & AO Maps (`use_low_as_high = true`):** Run `bake` with `maps = ["ao", "curvature", "position", "world_space_normal"]` and `use_low_as_high = true`. This extracts crisp edge curvature and cavity ambient occlusion directly from the SolidCraft geometry without needing a separate ZBrush sculpt.  
- **Layered Smart Materials & Procedural Generators:**  
  - Apply base materials via `material_load` (`Built-in: Granite`, `Cobblestone`, `Cast Iron`, `Rusted Iron`, `Bronze`, `Gold`, `Jade`, `Oak Wood`, `Charcoal`).  
  - Stack fill layers (`layer.add_fill`) with procedural noises (`layer.set_fill_procedural` using `voronoi`, `fbm`, `perlin`, `brick`, `gradient`) and bake-driven masks (`mask.add_generator` with `curvature` for weathered edge highlights, `ao` for mossy/soot crevices, and `position` for ground dirt gradients).  
  - Notice: `command_batch` wraps commands in an undo transaction; for multi-texture-set switching (`session.select_texture_set`), use sequential `command_run` calls to avoid state resets.  
- **Save & Export:** Save `.tcraft` projects to `assets/texturecraft/<name>.tcraft`, export PBR PNG maps (`BaseColor`, `Normal`, `Roughness`, `Metallic`, `AO`) via `textures_export` to `assets/exports/textures/<name>/`, and export combined `.glb` models via `mesh_export` to `assets/exports/<name>_textured.glb`.  
- **Path-Traced Verification:** Render a 64-SPP path-traced studio preview (`viewport_render`) to verify material roughness, metallic response, and silhouette readability before importing into Roblox.

### Stage 3: Roblox Studio Prefab Assembly & Moderation Resilience

- **Multi-Part Prefabs & Templates:** Store reusable arena templates in `ServerStorage.GraveyardAssets` (`Anchored = true`, `CanQuery = false`, `CastShadow = true`) and enemy/combat visual templates in `ReplicatedStorage`.  
- **Texture Upload Moderation Note:** Newly uploaded image assets via `upload_image` return a `rbxassetid://` immediately, but Roblox CDN moderation/thumbnail generation takes several minutes. While pending, attaching raw `Texture` / `SurfaceAppearance` instances emits `Asset content representation is being generated` console warnings. Keep runtime prefabs clean using matched PBR `Part` colors/materials until asset IDs clear moderation, so the Studio console remains 100% warning-free (`PROC-3`).

## Agent setup (Claude Code & Antigravity)

| File | Role |
| :---- | :---- |
| `CLAUDE.md` & `AGENTS.md` | Project rules: layout, source of truth, workflow, Luau conventions, security, performance, current game notes. |
| `src/server/CLAUDE.md` | Server-only rules (validation, persistence, cleanup). |
| `src/client/CLAUDE.md` | Client-only rules (rendering, streaming tolerance, throttling). |
| `.claude/rules/safe-scalable-roblox.md` | Condensed version of the Safe and Scalable Roblox Rules doc (`SEC/DATA/POL/PERF/PROC`). |
| `.claude/rules/product-growth-monetization.md` | Condensed version of the Product Management, Gamification and Monetization Rules doc (`DISC/LOOP/MON/PM`). |
| `.claude/skills/remote-security` | Playbook for writing or reviewing client-to-server handlers. |
| `.claude/skills/datastore-patterns` | Playbook for saved data. |
| `.claude/skills/studio-mcp-playtest` | Playbook for verifying a change in Studio. |
| `.claude/skills/solidcraft-roblox-assets` | Playbook for modeling in SolidCraft \+ ArtCraft Suite, exporting meshes/renders, and importing into Roblox Studio. |
| `.claude/skills/texturecraft-pbr-painting` | Playbook for baking AO/Curvature maps, procedural smart materials, and PBR texture export in TextureCraft. |
| `.claude/skills/solidcraft-*` | Bundled SolidCraft skills (`solidcraft-modeling`, `solidcraft-mechanisms`, `solidcraft-editing`, `solidcraft-checking`). |
| `.claude/agents/roblox-reviewer.md` | Read-only reviewer that checks a diff against the rules. |

## Definition of done for a change (`PROC-3`, `PROC-4`)

- Formatted (`stylua src`) and lint clean (`selene src`).  
- Playtested in Studio with a completely clean console (solo, and a 2-player local server test for anything multiplayer).  
- Any new client-to-server input passes the remote checklist in the Security Review Checklist doc.  
- Docs in `roblouuux Game Docs` updated whenever numbers, remotes, packet layouts, assets, economy flows, or architecture change.