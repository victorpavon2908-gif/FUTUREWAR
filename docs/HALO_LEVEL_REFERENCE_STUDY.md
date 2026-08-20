# FUTUREWAR — Halo CE level reference study

This document records level-design lessons extracted from the five `.map` archives supplied for private reference during FUTUREWAR development. The Halo assets themselves are **not** copied into FUTUREWAR; the goal is to study composition, pacing, silhouettes, traversal and the contrast between natural terrain and monumental science-fiction architecture, then build original environments.

## Files inspected

- `a30.map` — campaign level commonly known as Halo / A30.
- `b30.map` — The Silent Cartographer / B30.
- `b40.map` — Assault on the Control Room / B40.
- `H2_Blood_Gulch.map` — community Halo CE map based on the Blood Gulch idea.
- `danger canyon v2.map` — community canyon map.

String/tag inspection confirms the maps contain terrain, sky, water, cliff, metal, scenery and level tags associated with their respective environments. No original map data is redistributed in this repository.

---

## A30 — lessons for ASTER VALLEY

### What works
- Large natural bowl with strong mountain walls framing the player.
- Open combat fields broken by rock shelves and forest masses.
- Technology appears as a monumental interruption in nature rather than filling every square meter.
- Distant horizon geometry makes the world feel far larger than the playable path.
- Movement alternates between broad vistas and narrower transitions.

### FUTUREWAR translation
- ASTER VALLEY should keep long visual axes and a readable central corridor.
- Mountain walls must be angular and layered, not spherical blobs.
- Forest should cluster near the valley walls, leaving readable combat lanes.
- VANGUARD and HELIX structures should be sparse, large and memorable.
- The first landmark must be visible soon after deployment.

---

## B30 — lessons for COASTLINE FORTRESS

### What works
- Water creates a natural world boundary without visible artificial walls.
- Cliffs produce believable vertical containment.
- Military / alien architecture is embedded into the island rather than placed on a flat plane.
- Circular and radial structures create a memorable central objective.
- Bridges and elevated pads create readable tactical layers.
- The island silhouette remains understandable from many angles.

### FUTUREWAR translation
- COASTLINE FORTRESS uses a cliff island surrounded by open ocean.
- A central HELIX command platform sits above a lagoon cut into the rock.
- Three radial bridges connect the command platform to side batteries and the southern assault route.
- Cliff shelves provide alternate sightlines but remain visually simple enough for mobile.
- Water, rock and dark military metal are the dominant materials.

---

## B40 — lessons for FROST RANGE

### What works
- Monumental vertical architecture gives scale beyond normal buildings.
- Bridges and shafts become landmarks visible from several encounter spaces.
- Natural mountains and hard geometric structures create a very strong silhouette contrast.
- Long exterior traversal is punctuated by interior or compressed combat zones.

### FUTUREWAR translation
- FROST RANGE will use very tall HELIX monoliths, deep ravines and bridge combat.
- Exterior snow fields must be visually broad, while the actual combat lanes remain controlled.
- The player should repeatedly see the same massive landmark from new angles as progress is made.

---

## Blood Gulch — lessons for multiplayer readability

### What works
- Two opposite ends create instant spatial orientation.
- The valley bowl supports vehicles and long-range combat while hills provide flanking routes.
- The center is deliberately less cluttered than the edges.
- Each end has an obvious home-base silhouette.

### FUTUREWAR translation
- Survival / PvP arenas should use clear opposing landmarks and a low-clutter center.
- Terrain edges can hide flank routes without confusing the overall map.
- Bases need distinct faction silhouettes and lighting language.

---

## Danger Canyon — lessons for RIFT CANYON

### What works
- Canyon walls create strong direction and naturally prevent players leaving the battlefield.
- Elevated bridges and tunnel-like routes add vertical choices without needing a huge footprint.
- Beacon-like objects and colored lights assist navigation in repetitive rock environments.

### FUTUREWAR translation
- RIFT CANYON should have stacked routes: canyon floor, bridge level and ridge overlook.
- Strong cyan/red beacons mark friendly/enemy territory.
- Distant city / structure silhouettes should sell a world beyond the canyon.

---

# Shared design rules adopted for FUTUREWAR

1. **Nature first, structure second.** Terrain establishes the place; architecture becomes the landmark.
2. **One dominant landmark per encounter region.** The player should know where to go by looking, not by reading the HUD.
3. **Long sightlines + controlled combat pockets.** A world can feel huge while combat remains performant on mobile.
4. **Strong silhouette language.** Mountains, bridges, towers and bases must read clearly at phone-screen scale.
5. **No artificial perimeter walls when geography can do the job.** Ocean, cliffs, ravines and mountain walls form believable boundaries.
6. **Vertical layers must be visually obvious.** Bridges, shelves and upper platforms should have clear entrances and exits.
7. **Sparse sci-fi architecture feels larger.** A few monumental structures are stronger than dozens of small cubes.
8. **Color guides navigation.** VANGUARD = cyan / cool white. HELIX = orange-red / deep graphite.
9. **Original assets only in the shipping game.** Reference maps inform design decisions; FUTUREWAR geometry, materials, names and layouts remain original.

# Current production target

The next world is **COASTLINE FORTRESS**, built as an original cliff-island assault level using the B30 lessons above while also borrowing A30's horizon scale, B40's monumental architecture, Blood Gulch's readable opposing ends and Danger Canyon's layered bridge routes.