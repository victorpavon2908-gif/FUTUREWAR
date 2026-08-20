# ASTER VALLEY — Production Brief

## Goal

Create the first FUTUREWAR campaign world as a large, realistic military-science-fiction landscape designed around mountain scale, natural terrain and monumental original future architecture.

## Play space

- Approximate procedural terrain footprint: 260 x 320 meters.
- Start: VANGUARD landing zone in the southern valley.
- Midfield: forest, river, bridge and open combat lanes.
- Objective: HELIX occupation fortress in the northern valley.
- Extraction: return to the VANGUARD landing zone after all hostiles are eliminated.

## Visual pillars

1. Bright natural daylight rather than a dark greybox.
2. Mountains frame almost every major sightline.
3. Forest and rock masses make the battlefield feel embedded in a real landscape.
4. Clean, large-scale sci-fi structures contrast with organic terrain.
5. Cyan VANGUARD energy language and red HELIX energy language guide navigation.
6. Distant silhouettes make the world feel larger than the playable combat area.

## Current procedural content

- Heightfield terrain and collision.
- Procedural sky and fog.
- River plane/channel.
- Instanced pine forest.
- Instanced boulder field.
- Distant mountain masses.
- VANGUARD landing pad.
- HELIX bunker, towers, gate and barricades.
- River bridge.
- Monumental northern landmark.
- Distant outpost/city silhouette.

## Next production-art pass

The current geometry establishes scale, layout and rendering direction. Production art should replace procedural primitives gradually with original models and textures while preserving the gameplay layout.

Priority assets:

1. VANGUARD supersoldier body/arms.
2. HELIX Rifleman and Heavy bodies.
3. VX-7 production weapon model.
4. Modular cliff and rock kit.
5. Pine/forest vegetation kit.
6. VANGUARD architecture kit.
7. HELIX architecture kit.
8. Terrain grass/rock material set.
9. Water shader/material.
10. Impact, muzzle and environmental VFX.

## Mobile realism strategy

The cinematic profile intentionally favors visual density and defaults to 30 FPS. Geometry is still instanced where sensible so the scene can later be profiled and scaled across Android hardware tiers.

Real-device profiling is mandatory before locking the final vertex, shadow, texture and draw-call budgets.
