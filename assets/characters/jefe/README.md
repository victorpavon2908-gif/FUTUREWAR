# JEFE — character integration

JEFE is the playable FUTUREWAR supersoldier.

## Preferred production asset

The runtime now prefers the AccuRIG export at:

`res://assets/characters/jefe/jefe_rigged.fbx`

If that file is not present, the game falls back to:

`res://assets/characters/jefe/jefe.glb`

## Rigged runtime movement

The AccuRIG FBX uses the Reallusion / Character Creator skeleton (`CC_Base_*`).
`scripts/jefe_body.gd` detects the `Skeleton3D` automatically and drives a gameplay locomotion layer directly from the bones, so no paid motion pack is required for the first playable version.

Implemented procedural states:

- idle breathing / head stabilization
- walk
- run
- sprint
- jump / fall pose
- landing compression
- arm swing and torso counter-rotation

The CharacterBody3D controller remains authoritative for movement and collision; bone movement is visual only.

## Visual direction

- Heavy, grounded military sci-fi silhouette.
- Olive-drab layered armor over a near-black technical undersuit.
- Reflective amber/gold visor.
- Broad chest and shoulder protection, reinforced forearms, thighs, knees, shins and boots.
- Worn metallic finish; serious and realistic rather than cartoon/low-poly styling.

## Asset requirements

- Godot 4-compatible FBX/GLB.
- Approximately 2.1–2.2 m armored height.
- Origin centered at the character/controller origin.
- PBR materials preferred.
- AccuRIG skeleton expected bone names include `CC_Base_Hip`, `CC_Base_Spine01`, `CC_Base_Spine02`, `CC_Base_L_Thigh`, `CC_Base_R_Thigh`, `CC_Base_L_Calf`, `CC_Base_R_Calf`, `CC_Base_L_Upperarm`, `CC_Base_R_Upperarm`, and related bones.
