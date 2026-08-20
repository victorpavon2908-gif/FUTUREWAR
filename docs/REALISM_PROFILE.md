# FUTUREWAR — Cinematic Mobile Realism Profile

## Intent

FUTUREWAR targets a visually heavy mobile presentation rather than a minimal mobile look. The default campaign profile is therefore cinematic and currently caps frame rate at 30 FPS while development focuses on environment quality.

## Current rendering priorities

- Large outdoor terrain.
- Long sightlines.
- Directional sun shadows.
- Atmospheric fog.
- Dense instanced vegetation.
- Instanced rocks and distant mountain forms.
- Multiple original sci-fi architecture silhouettes.
- First-person weapon, shield HUD and enemy combat effects.

## Scaling plan

The game will ultimately expose at least three device profiles:

### Cinematic
- 30 FPS target.
- Highest vegetation density.
- Longest environment visibility.
- Full sun shadows.
- Highest material/terrain detail available to the mobile renderer.

### Balanced
- 45 FPS target where supported.
- Reduced vegetation distance/density.
- Medium shadows and VFX density.

### Performance
- 60 FPS target where supported.
- Lower shadow distance.
- Reduced secondary vegetation and distant props.
- Reduced VFX density.

These are development targets, not guarantees. Final thresholds must be established through physical Android profiling.

## Art philosophy

Realism should come from scale, lighting, atmospheric depth, material breakup, believable terrain and strong silhouettes before raw polygon count. High-detail art must remain readable on a small landscape display.
