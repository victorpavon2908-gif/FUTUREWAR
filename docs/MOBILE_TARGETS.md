# FUTUREWAR — Mobile Technical Targets

## Platform priority

Primary launch target: **Android landscape**.

The project should remain playable on desktop for development, but design and rendering decisions must be judged first by mobile cost.

## Performance profiles

### Performance

- Target: 60 FPS.
- Internal viewport: 1280×720 baseline.
- Mobile renderer.
- Limited dynamic shadows.
- Short-lived VFX.

### Battery

- Target: 30 FPS.
- Same gameplay logic.
- Future option to reduce render scale and effects.

## Device target philosophy

Do not optimize only for flagship phones. The practical target is a mid-range Android device that can sustain a stable frame rate without thermal collapse during a 10-minute mission.

## Geometry budgets — production target

These are starting budgets, not hard engine limits.

### Hero player model

- 15k–30k triangles at LOD0.
- 8k–15k LOD1.
- 3k–6k LOD2.

### Standard enemy

- 10k–20k LOD0.
- 5k–10k LOD1.
- 2k–4k LOD2.

### Heavy / boss

- 20k–40k LOD0 if only one or two are visible.

### Weapon first-person

- 10k–20k triangles depending on screen coverage.

The procedural prototype currently uses primitive geometry and is far below these production-art budgets.

## Texture targets

- Hero armor: 1024–2048 only if profiling permits.
- Standard enemy: 1024 recommended.
- Weapon: 1024.
- Environment modules: mostly 512–1024 atlases.
- Props: 256–512 where possible.
- UI icons: atlas-based.

Use compressed Android texture formats appropriate to Godot/device support during export testing.

## Materials

Aim for a small number of reusable materials per scene.

Recommended:

- environment concrete/metal atlas;
- VANGUARD armor material set;
- HELIX armor material set;
- emissive faction material;
- transparent VFX material;
- weapon material set.

Avoid unique materials per small prop.

## Lighting

- One primary DirectionalLight3D may cast shadows.
- Most OmniLight3D and SpotLight3D effects should have shadows disabled.
- Emission should sell futuristic technology without adding light sources everywhere.
- Bake/static lighting should be considered when production environments replace procedural geometry.

## VFX

Muzzle flashes and hit sparks should last fractions of a second.

Future particle budgets should be tested on device. Prefer:

- short bursts;
- small particle counts;
- pooled projectiles/effects;
- simple shaders;
- limited transparent overdraw.

Avoid giant full-screen transparent particle layers during normal combat.

## Enemy count

Prototype target: 6–10 active enemies in a compact encounter.

Production missions may stage larger battles, but not every enemy needs full AI at the same time. Future optimization can use activation zones and simplified distant logic.

## Physics

- Primitive collision shapes whenever possible.
- Avoid mesh collision for dynamic characters.
- Do not give visual rubble individual physics unless gameplay needs it.
- Use activation areas for later complex encounters.

## UI / touch controls

Landscape-only prototype layout.

Left side:

- movement touch region / future virtual stick.

Right side:

- camera drag region;
- FIRE;
- ADS;
- JUMP;
- RELOAD.

Rules:

- buttons must remain reachable with thumbs;
- do not cover the crosshair area;
- critical buttons need large touch targets;
- UI should scale from 16:9 to wider displays;
- avoid tiny text below practical phone readability.

## Networking

Multiplayer is intentionally deferred. Do not add network synchronization overhead until the single-player combat loop and device performance are stable.

## Profiling checkpoints

Profile on a physical Android device at these milestones:

1. procedural City Zero;
2. first production soldier model;
3. first production environment kit;
4. VFX/audio pass;
5. complete 8–10 minute mission.

Measure:

- average FPS;
- worst frame time;
- CPU frame time;
- GPU frame time;
- memory;
- temperature/thermal throttling;
- battery consumption;
- APK/AAB size.

## Build discipline

Never commit:

- keystores;
- signing passwords;
- API secrets;
- generated Android build directories.

Keep high-resolution source art outside the runtime folder when it is not needed by Godot imports.
