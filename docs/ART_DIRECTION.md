# FUTUREWAR — Art Direction

## Visual target

FUTUREWAR uses an **original, mobile-first military science-fiction style** built around the readability and physical presence of classic console-era sci-fi shooters, modernized with cleaner hard-surface shapes, restrained emissive lighting and contemporary cinematic presentation.

The project may take inspiration from broad genre ideas such as armored supersoldiers, futuristic military hardware and alien/AI warfare, but it must not reproduce any existing game's armor, helmets, weapons, faction marks, vehicles, maps or named designs.

## Core visual rules

1. **Strong silhouette before detail.** A character should remain recognizable as a 2–3 cm figure on a phone screen.
2. **Large armor panels.** Avoid excessive tiny mechanical pieces that cost geometry and disappear on mobile.
3. **One primary glow language per faction.** VANGUARD uses cyan/blue; HELIX uses red/orange.
4. **Dark neutral materials + controlled highlights.** Graphite, titanium, concrete and ceramic plates carry most surfaces.
5. **No neon rainbow.** Emissive elements indicate function, faction or danger.
6. **Architecture uses large readable forms.** Gates, bridges, towers, pylons and industrial systems should guide navigation.
7. **Effects are short and intentional.** Muzzle flash, tracers and impact sparks should be visible but cheap.

# VANGUARD character language

## Silhouette

- broad upper torso;
- protected neck;
- full helmet;
- medium-large shoulder shells;
- separated thigh/shin plates;
- compact backpack/energy block;
- stable military stance.

## Helmet

The VANGUARD helmet should use an original shape with:

- one continuous or split cyan visor;
- reinforced jaw/cheek geometry;
- top sensor ridge;
- rear armor shell;
- no recognizable geometry copied from another franchise.

## Materials

Primary:

- graphite ceramic;
- dark titanium;
- matte flexible undersuit.

Secondary:

- desaturated military green, steel or dark blue depending on class.

Emissive:

- cyan/ice blue.

## Class accents

- Assault: cyan + gunmetal.
- Ghost: cool violet-blue + near-black.
- Titan: orange warning details + heavy graphite.
- Tech: teal/cyan + sensor modules.

# HELIX character language

HELIX should feel related to human military technology but modified by machine logic.

## Silhouette

- sharper shoulder lines;
- slightly narrower head openings;
- red sensor strips;
- asymmetrical equipment blocks;
- external cooling elements on elite units.

## Variants

### Rifleman
Balanced armor proportions and conventional rifle silhouette.

### Scout
Slimmer armor, reduced shoulders, longer sensor visor.

### Heavy
Oversized shoulder/chest plates, wider stance and visible rear power unit.

### Commander
Cleaner elite shell, brighter crimson sensor language and unique chest mark.

### Drone
Compact central sensor core, two lateral structures and visible red energy core.

# Weapon language

Weapons should combine believable military ergonomics with fictional energy/sensor technology.

## VX-7

- blocky receiver;
- compact stock;
- long handguard;
- short holographic optic;
- cyan ammunition/status strip;
- dark metal body;
- physically readable barrel and muzzle.

Weapon silhouettes must differ at a glance. Do not create five guns that are only recolors of the same mesh.

# HUD language

The HUD is a military visor interface rather than a generic mobile overlay.

## Color

- information: cyan;
- neutral text: cold white;
- secondary: desaturated blue-gray;
- warning: orange;
- critical: red;
- success/extraction: green-cyan.

## Geometry

- thin borders;
- rectangular panels;
- 2–4 px corner cuts/rounding;
- high transparency;
- generous empty space;
- no large opaque blocks over combat.

## Required information hierarchy

Highest priority:

1. crosshair;
2. shield/health;
3. ammo;
4. objective;
5. damage warning.

Lower priority:

- mission name;
- class information;
- secondary status text.

# World palettes

## City Zero

- charcoal concrete;
- wet/dark road;
- cold blue ambient light;
- cyan infrastructure;
- orange/red HELIX threat lights;
- sparse fire in later production art.

## Iron Wasteland

- rusted steel;
- dark iron;
- furnace orange;
- yellow industrial markings;
- black smoke.

## Skyline Arc

- dark glass;
- blue-white architectural light;
- controlled magenta/violet ads only as background accents;
- polished metal.

## Frost Bastion

- blue-gray ice;
- white snow;
- gunmetal base structures;
- cyan emergency lights;
- red hostile sensors.

## Red Sand Colony

- red/orange terrain;
- cream/gray colony panels;
- black equipment;
- cyan human systems;
- red HELIX systems.

## Helix Core

- near-black architecture;
- deep gray structural layers;
- crimson energy lines;
- occasional sterile white machine spaces.

# Environment construction rules

For mobile, build worlds modularly.

Recommended kit categories:

- wall 2m / 4m / 8m;
- floor tiles;
- road/curb;
- pillars;
- doors;
- window/light strips;
- bridge modules;
- cover blocks;
- rubble clusters;
- large hero structures.

Each world should get a small reusable kit rather than hundreds of unique pieces.

# Production art stages

## Stage A — Greybox

Primitives only. Validate scale, movement, sight lines and combat.

## Stage B — Style blockout

Replace major primitives with low-poly original hard-surface modules. Establish materials and lighting.

## Stage C — Production low-poly

Add UVs, baked details, optimized materials, LODs and collision proxies.

## Stage D — VFX/audio polish

Add controlled particles, impact decals, ambient effects and sound.

The current 0.02 branch is between Stage A and early Stage B: its procedural armor and environment communicate the intended silhouette while remaining asset-free.
