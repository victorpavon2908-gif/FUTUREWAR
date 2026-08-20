# FUTUREWAR

Mobile-first military science-fiction FPS built with **Godot 4 / GDScript**.

## Current production target — TERRAIN MASTER PASS

The **main branch** is the active production branch.

For this pass, combat, enemies, weapons and fortress art are intentionally frozen while the terrain is rebuilt first. `scenes/main.tscn` and the Coastline deployment now open a terrain-only survey world.

### Terrain goals

- one continuous 340 x 340 meter playable ground mesh;
- no intentional holes between platforms or terrain pieces;
- full collision across the visible ground;
- broad mountain walls and hero rock formations;
- open central valley inspired by classic large-scale sci-fi FPS level composition;
- traversable shelves and natural elevation changes;
- shallow winding river with a real riverbed beneath it;
- grass, rock, highland and riverbank surface variation;
- procedural terrain shader for macro/micro variation;
- scattered rock fields and pine groves;
- perimeter collision to stop accidental map exits;
- hidden emergency catch floor and automatic rescue if the player somehow falls below the map.

No enemies, gun or combat HUD are used in the terrain survey scene. The point of this pass is to judge only the land, scale, routes, mountains, river and traversal quality before architecture is added back.

## Playable worlds

1. **COASTLINE TERRAIN MASTER** — active terrain production pass.
2. **ASTER VALLEY — First Contact** — legacy comparison world.
3. **RIFT CANYON — Three Levels** — planned.
4. **FROST RANGE — White Signal** — planned.
5. **NOVA CITY — Neon Siege** — planned.
6. **HELIX ASCENT — Last Directive** — planned.

## Run locally

```bash
git checkout main
git pull origin main
```

Open the repository in Godot 4.7.x.

- **F5** → command screen → Coastline deploy opens the terrain-only pass.
- **F6** on `scenes/main.tscn` → opens the terrain survey directly.

## Terrain survey controls

```text
WASD        Move
Shift       Sprint
Space       Jump
Mouse       Look
Esc         Capture/release mouse
```

## Important art rule

No Halo geometry, textures, models, sounds or other copyrighted game assets are shipped in FUTUREWAR. Uploaded maps are used only as private level-design references. Shipping content must remain original or properly licensed.

## Security

Never commit Android keystores, `.jks` files, signing passwords, API keys, secrets or generated Android build directories.
