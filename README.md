# FUTUREWAR

Mobile-first military science-fiction FPS built with **Godot 4 / GDScript**.

## Current production target — Coastline Fortress

The **main branch** is now the active production branch.

`COASTLINE FORTRESS // BROKEN TIDE` is the visual priority and default deployment world. The level uses original FUTUREWAR geometry and only studies classic FPS maps for composition, pacing, traversal and landmarking.

Current production pass includes:

- original procedural cliff-island terrain;
- animated ocean shader with vertex waves and fresnel response;
- procedural terrain surface variation;
- irregular generated cliff/rock chunks with moss/strata shading;
- panelized HELIX metal shader;
- layered central command hub and reactor;
- radial bridges, railings and assault ramp;
- side batteries and northern monolith;
- VANGUARD landing zone;
- compact combat HUD;
- slimmer VX-7 first-person production model;
- HELIX infantry, Heavy, Commander and drones;
- mission loop: land → breach fortress → eliminate HELIX → return to LZ;
- 30 FPS cinematic mobile target with 60 FPS test mode.

## Playable worlds

1. **COASTLINE FORTRESS — Broken Tide** — active production world.
2. **ASTER VALLEY — First Contact** — playable legacy world.
3. **RIFT CANYON — Three Levels** — planned.
4. **FROST RANGE — White Signal** — planned.
5. **NOVA CITY — Neon Siege** — planned.
6. **HELIX ASCENT — Last Directive** — planned.

## Run locally

```bash
git checkout main
git pull origin main
```

Open the repository in Godot 4.7.x and press **F5**.

The command screen now selects **Coastline Fortress by default**.

If you press **F6** while `scenes/main.tscn` is open, it also launches the Coastline production world directly.

## Desktop controls

```text
WASD        Move
Shift       Sprint
Space       Jump
Mouse       Look
LMB         Fire
RMB         ADS
R           Reload
Esc         Capture/release mouse
```

## Android controls

- Left screen region: movement.
- Right screen region: camera drag.
- FIRE: shoot.
- ADS: aim.
- JUMP: jump.
- RLD: reload.
- Landscape orientation.

## Important art rule

No Halo geometry, textures, models, sounds or other copyrighted game assets are shipped in FUTUREWAR. Uploaded maps are used only as private level-design references. Shipping content must remain original or properly licensed.

## Security

Never commit Android keystores, `.jks` files, signing passwords, API keys, secrets or generated Android build directories.
