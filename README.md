# FUTUREWAR

Mobile-first military science-fiction FPS built with **Godot 4 / GDScript**.

## Prototype 0.03 — ASTER VALLEY

The active `development` branch now uses a heavier, more realistic open-environment direction: large natural landscapes, monumental original sci-fi architecture, supersoldier combat and a cinematic mobile profile.

## Active world — Aster Valley

`ASTER VALLEY // FIRST CONTACT` is now the first playable campaign world.

The level is generated without external assets and currently includes:

- 260 x 320 meter procedural terrain.
- Mountain valley heightfield with real collision.
- Large distant mountain masses.
- River channel.
- 200+ instanced pine trees.
- 90+ instanced boulders.
- VANGUARD landing zone.
- HELIX occupation fortress.
- Futuristic bridge.
- Monumental sci-fi skyline landmark.
- Distant outpost/city silhouette.
- Warm sun + cool sky fill lighting.
- Procedural sky and atmospheric fog.
- Rechargeable VANGUARD shield system.
- VX-7 automatic rifle with ADS.
- HELIX Rifleman, Scout, Heavy and Commander units.
- HELIX combat drones.
- Mission loop: breach the valley → eliminate occupation force → return to extraction.

## Campaign worlds

1. **ASTER VALLEY — First Contact** — playable.
2. **COASTLINE FORTRESS — Broken Tide** — planned.
3. **NOVA CITY — Neon Siege** — planned.
4. **FROST RANGE — White Signal** — planned.
5. **RED DESERT FRONT — Colony War** — planned.
6. **HELIX ASCENT — Last Directive** — planned.

The campaign screen has been redesigned around these large-biome worlds.

## Visual direction

FUTUREWAR is not intended to be a copy of any existing franchise. The target is an original military sci-fi identity built around:

- large outdoor battle spaces;
- forests, cliffs, water, snow, deserts and cities;
- clean monumental future architecture;
- readable supersoldier silhouettes;
- strong visor/energy accents;
- realistic daylight and atmospheric depth;
- heavier geometry on the cinematic profile;
- scalable quality for Android devices.

## Performance profiles

The command screen currently defaults to a **30 FPS cinematic profile** to favor visual density. A 60 FPS profile can be toggled from the campaign interface for testing.

This does not guarantee 30/60 FPS on every Android device. Physical-device profiling is required before release.

## Run locally

```bash
git checkout development
git pull origin development
```

Open the repository folder in Godot 4.7.x and press **F5**.

Boot scene:

```text
res://scenes/boot.tscn
```

Active gameplay scene:

```text
res://scenes/main.tscn
```

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

## Active structure

```text
FUTUREWAR/
├── docs/
│   ├── GAME_DESIGN.md
│   ├── ART_DIRECTION.md
│   └── MOBILE_TARGETS.md
├── scenes/
│   ├── boot.tscn
│   └── main.tscn
├── scripts/
│   ├── boot_v2.gd
│   ├── aster_valley.gd
│   ├── main_v2.gd
│   ├── player_v2.gd
│   ├── weapon_v2.gd
│   ├── enemy_v2.gd
│   └── drone.gd
├── project.godot
└── icon.svg
```

The original prototype scripts remain temporarily as fallback/reference while the new world direction is tested.

## Automated validation

GitHub Actions imports the Godot project headlessly and smoke-tests both the command interface and the gameplay scene. This catches parser and many startup errors before local testing.

## Security

Never commit Android keystores, `.jks` files, signing passwords, API keys, secrets or generated Android build directories. These are excluded by `.gitignore`.
