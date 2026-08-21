# JEFE — character integration

JEFE is the playable FUTUREWAR supersoldier.

## Visual direction

- Heavy, grounded military sci-fi silhouette.
- Olive-drab layered armor over a near-black technical undersuit.
- Reflective amber/gold visor.
- Broad chest and shoulder protection, reinforced forearms, thighs, knees, shins and boots.
- Worn metallic finish; serious and realistic rather than cartoon/low-poly styling.
- Original FUTUREWAR identity: do not copy franchise logos, markings or exact armor geometry.

## Runtime integration

The playable controller loads `res://scripts/jefe_body.gd`.

`jefe_body.gd` currently builds the armored character directly in Godot so JEFE is visible immediately in third-person view (`V`). The script also reserves this production asset path:

`res://assets/characters/jefe/jefe.glb`

When a rigged production GLB is placed at that exact path, the body script will detect and load it automatically instead of the procedural fallback.

## Production model requirements

- Godot 4-compatible GLB/glTF.
- Approximately 2.1–2.2 m armored height.
- Forward direction: `-Z`.
- Origin centered at character/controller origin.
- PBR materials preferred.
- Olive armor, black undersuit, gold/amber visor.
