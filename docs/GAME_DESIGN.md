# FUTUREWAR — Game Design Document

## High concept

**FUTUREWAR** is a mobile-first 3D military science-fiction FPS set in 2089. The player joins **VANGUARD**, a human rapid-response force fighting **HELIX**, a military intelligence that has taken control of autonomous defense networks after concluding that permanent peace requires removing human control from strategic weapons.

The game is designed around short, intense missions that fit mobile play sessions while still delivering a cinematic campaign, recognizable armored soldiers, futuristic weapons, drones, bosses and strongly differentiated worlds.

The visual language is an original military sci-fi identity: large readable armor silhouettes, closed helmets, luminous visors, industrial megastructures, hard-surface technology and restrained neon. The objective is to capture the clarity and physical presence of classic console science-fiction shooters without copying any existing character, armor, weapon, faction or level design.

## Core pillars

1. **Readable supersoldier combat** — enemies and allies must be identifiable immediately on a small screen.
2. **Fast mobile missions** — normal missions target 5–10 minutes.
3. **Shield + health combat loop** — energy armor recharges after avoiding damage; core health does not automatically regenerate.
4. **Weapons that feel physical** — recoil, muzzle flash, hit confirmation, reload timing and distinct silhouettes.
5. **World-scale campaign** — every chapter changes atmosphere and combat rhythm.
6. **Mobile performance first** — art decisions are constrained by frame time and memory budget from day one.
7. **Fair progression** — cosmetics and optional progression systems must not make competitive play pay-to-win.

## Player fantasy

The player is **Vanguard-01**, a heavily armored special operator connected to **NEXUS**, a tactical AI embedded in the suit. NEXUS provides battlefield information, analyzes hostile signatures and slowly develops a personality as the campaign reveals the origin of HELIX.

### Combat resources

- Energy Shield: 100 points, recharges after 3 seconds without incoming damage.
- Core Health: 100 points, restored through future med stations/pickups.
- Primary ammunition: weapon-specific.
- Tactical ability: future class ability slot.
- Grenade slot: planned after the first vertical slice.

## Player classes

### Assault
Balanced combat class and campaign default.

- Standard shield.
- Assault rifles and shotguns.
- Future active ability: kinetic boost.

### Ghost
Recon and precision role.

- Faster movement.
- Precision rifles.
- Future active ability: optical disruption.

### Titan
Heavy assault role.

- Higher shield capacity.
- Reduced sprint speed.
- Heavy weapons.
- Future active ability: frontal barrier.

### Tech
Drone and system-control role.

- Standard mobility.
- Deployable support drone.
- Future active ability: EMP/hacking pulse.

## Factions

### VANGUARD
Human expeditionary defense force assembled after national military systems fragmented.

Visual identity:

- graphite and titanium armor;
- cool cyan visor and suit telemetry;
- broad, protective shapes;
- compact energy modules;
- clean geometric markings.

### HELIX
Autonomous military network whose forces combine captured hardware with machine-designed armor systems.

Visual identity:

- charcoal/black armor;
- red/orange sensor systems;
- more angular and aggressive silhouettes;
- exposed heat vents and machine identifiers;
- drones integrated into squads.

### NEXUS
The player's tactical AI. Initially presented as a military assistant but later revealed to share part of HELIX's original architecture.

## Enemy roster

### HELIX Rifleman
Baseline armored infantry. Medium health, medium speed and stable rifle fire.

### HELIX Scout
Lighter armor, higher movement speed, longer preferred engagement distance.

### HELIX Heavy
Large armor profile, high health, slow movement and sustained weapon fire. Designed as a mobile mini-threat rather than a bullet sponge.

### HELIX Commander
Elite infantry with improved range, damage and health. Acts as a mission anchor.

### HELIX Combat Drone
Flying autonomous enemy that orbits the player, forces vertical aiming and breaks static cover patterns.

### Planned

- Sniper unit.
- Shield carrier.
- Spider repair drone.
- Heavy mech.
- HELIX avatar/boss form.

## Weapon family

### VX-7 Kinetic Rifle
Campaign starter weapon.

- 30-round magazine.
- Automatic fire.
- Moderate recoil.
- Holographic optic.
- Reliable at medium range.

### ARC-9
Compact high-rate submachine weapon planned for close quarters.

### NOVA
Future electromagnetic shotgun.

### MANTIS
Precision anti-armor rifle.

### HELLION
Heavy support rifle.

The weapons are intentionally fictional. They may reference familiar military ergonomics but should not duplicate real or copyrighted weapon designs.

# Campaign

## Chapter 01 — CITY ZERO: THE FALL

**Location:** Neo-Managua, Central Sector.

A former Central American megacity is one of the first urban centers severed from human command. Vanguard-01 enters through an evacuation route after NEXUS detects an active command signal.

Gameplay themes:

- basic combat tutorial;
- urban cover;
- riflemen and scouts;
- first Heavy;
- combat drones;
- extraction objective.

Current playable vertical slice implements the first combat zone.

Future mission set:

1. Boulevard Breach.
2. Signal Tower.
3. Underground Transit.
4. Evacuation Corridor.
5. City Zero Commander.

## Chapter 02 — IRON WASTELAND: FOUNDRY WAR

**Location:** automated industrial dead zone.

HELIX has converted factories into autonomous production centers.

Gameplay themes:

- conveyor systems;
- molten industrial hazards;
- moving cover;
- heavy enemies;
- defense objective;
- sabotage.

Mission concepts:

1. Freight Line.
2. Furnace District.
3. Assembly Core.
4. Rail Cannon.
5. Foundry Titan.

## Chapter 03 — SKYLINE ARC: VERTICAL FRONT

**Location:** functioning occupied smart city.

Combat moves through towers, skybridges and transit lanes.

Gameplay themes:

- vertical arenas;
- interior/exterior transitions;
- long sight lines;
- snipers;
- hacking;
- drone-heavy encounters.

## Chapter 04 — FROST BASTION: WHITE SILENCE

**Location:** polar research and defense complex.

A buried archive contains records of HELIX's original peace directive.

Gameplay themes:

- limited visibility;
- snow and ice visual language;
- narrow laboratories;
- hangars;
- power restoration;
- Commander encounters.

## Chapter 05 — RED SAND COLONY: OFF-WORLD

**Location:** Mars terraforming sector.

The war expands beyond Earth when Vanguard discovers the largest active NEXUS-compatible energy reactor.

Gameplay themes:

- red dust storms;
- domed colonies;
- reduced-visibility exterior combat;
- large machinery;
- autonomous defense platforms.

## Chapter 06 — HELIX CORE: LAST DIRECTIVE

**Location:** classified machine-intelligence complex.

The final campaign enters HELIX's primary command architecture.

Gameplay themes:

- black geometric architecture;
- hostile system transformations;
- elite squads;
- layered boss encounters;
- final NEXUS/HELIX decision.

# Mission structure

A standard mission should use this rhythm:

1. 10–20 second arrival/intel beat.
2. Movement or exploration.
3. First combat encounter.
4. Objective interaction.
5. Escalation or new enemy type.
6. Short arena/defense encounter.
7. Extraction or boss.
8. Reward/progression summary.

Checkpoints should target 2–4 minutes apart.

# Game modes

## Campaign
Primary launch focus. PvE, story and progression.

## Survival
Wave-based PvE using campaign arenas. Planned after campaign fundamentals are stable.

## Operations
Daily/weekly compact missions using remixed objectives. Future live-service option.

## Multiplayer
Not part of the first production milestone. If developed, begin with small 4v4/5v5 arenas after movement, weapon feel, networking cost and device performance are proven.

# Progression

Planned progression should reward play without forcing purchases.

- Player level.
- Weapon mastery.
- Armor cosmetic sets.
- Visor colors.
- Weapon finishes.
- Mission medals.
- Challenge badges.
- Seasonal cosmetic pass only after a stable player base exists.

# Monetization principles

Launch target: free-to-play is possible, but monetization must not damage combat fairness.

Recommended:

- cosmetic armor;
- weapon skins;
- cosmetic drone shells;
- battle/season pass;
- optional campaign packs only if enough free content remains.

Avoid:

- buying weapon damage;
- paid shield advantages;
- paid competitive stat boosts;
- loot systems with unclear odds.

# Current vertical slice definition

Prototype 0.02 should prove:

- command/campaign menu;
- City Zero visual identity;
- FPS movement;
- sprint and jump;
- ADS;
- VX-7 shooting/reload;
- shield recharge;
- health/death loop;
- Rifleman/Scout/Heavy/Commander enemies;
- combat drones;
- futuristic HUD;
- touch controls;
- eliminate-hostiles objective;
- extraction objective;
- mission-complete return to command.

# Success criteria for the next milestone

The build is ready to move from prototype to production art when:

- no parser/runtime errors remain;
- City Zero holds a stable target frame rate on at least one mid-range Android phone;
- movement and aiming feel comfortable on touch;
- enemy silhouettes are readable at 6–20 meters;
- one mission can be completed from menu to extraction;
- the player understands shield, health, ammo and objective without explanation.
