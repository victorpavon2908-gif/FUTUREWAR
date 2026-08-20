# FUTUREWAR

Mobile-first military science-fiction FPS built with **Godot 4 / GDScript**.

## Prototype 0.02 — NEXUS FALL

The active `development` branch now includes a larger vertical slice focused on an original classic-sci-fi supersoldier feel, modernized for Android.

### Command / campaign UI

- Futuristic main menu.
- Campaign selector.
- Six defined worlds.
- Performance and battery FPS profiles.
- City Zero deployment flow.

### City Zero vertical slice

- Redesigned urban battlefield generated without external assets.
- Futuristic boulevard, ruins, gate, transit bridge, skyline, barricades and emissive navigation elements.
- Mobile-friendly visual-only distant geometry and debris.
- Objective flow: eliminate HELIX forces → reach extraction → mission complete → return to command.

### VANGUARD player

- FPS movement.
- Sprint.
- Jump.
- Mouse/touch camera.
- Rechargeable 100-point energy shield.
- 100-point core health.
- Damage feedback.
- Mobile controls.

### VX-7 rifle

- Automatic hitscan fire.
- 30-round magazine.
- Reserve ammunition.
- Reload animation motion.
- ADS / aim-down-sights.
- Recoil.
- Muzzle flash.
- Hit sparks.
- Futuristic first-person procedural model and armored forearms.

### HELIX enemy roster

- Rifleman.
- Scout.
- Heavy.
- Commander.
- Combat Drone.
- Line-of-sight attacks.
- Red/orange tracer fire.
- Different speed, health, range and damage profiles.

### HUD

- VANGUARD shield bar.
- Core health bar.
- VX-7 ammunition panel.
- Mission objective.
- Hostile counter.
- Hitmarker.
- Damage overlay.
- NEXUS tactical status messages.
- Android FIRE / ADS / JUMP / RELOAD buttons.

## Campaign worlds

1. **CITY ZERO — The Fall**
2. **IRON WASTELAND — Foundry War**
3. **SKYLINE ARC — Vertical Front**
4. **FROST BASTION — White Silence**
5. **RED SAND COLONY — Off-World**
6. **HELIX CORE — Last Directive**

Only City Zero is currently deployable. The other five chapters are represented in the campaign interface and defined in the design documents for future production.

## Run locally

```bash
git checkout development
git pull origin development
```

Open the repository folder in Godot 4.7.x and press **F6/F5**.

The project now boots into:

```text
res://scenes/boot.tscn
```

Campaign deployment loads:

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

- Left screen region: virtual movement input.
- Right screen region: camera drag.
- FIRE: shoot.
- ADS: aim.
- JUMP: jump.
- RLD: reload.
- Landscape layout.

## Active v2 structure

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
│   ├── boot.gd
│   ├── main_v2.gd
│   ├── player_v2.gd
│   ├── weapon_v2.gd
│   ├── enemy_v2.gd
│   └── drone.gd
├── project.godot
└── icon.svg
```

The original Prototype 0.01 scripts remain in the repository temporarily as fallback/reference while 0.02 is tested on the user's Godot installation.

## Design documents

- `docs/GAME_DESIGN.md` — story, factions, classes, enemies, weapons, campaign, modes and monetization principles.
- `docs/ART_DIRECTION.md` — original armor, faction, HUD, weapon and world visual language.
- `docs/MOBILE_TARGETS.md` — Android frame-rate, geometry, texture, lighting, physics and profiling targets.

## Current priority

Before adding production 3D models, animations or multiplayer, Prototype 0.02 must be run in Godot and on a physical Android phone. Any parser/runtime errors should be fixed first, then we profile City Zero and move into production art.

## Security

Never commit:

- Android keystores / `.jks` files;
- signing passwords;
- API keys;
- secrets;
- generated Android build directories.

These are excluded by `.gitignore`.
