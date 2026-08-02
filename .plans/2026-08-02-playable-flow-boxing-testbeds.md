# Playable Flow and Boxing Gameplay Testbeds

**Date:** 2026-08-02  
**Status:** Draft  
**Last Updated:** 2026-08-02 14:43 EDT
**Blocked Reason:** Pending plan review and requirement freeze  
**Agent:** pico

---

## Goal

Build rudimentary first-person Godot developer testbed scenes for AeroBeat Flow and Boxing that prove real content, input calibration/tracking, audio timing, environment loading, gameplay runner dispatch, mode judgements, and hit/miss feedback in a playable loop.

---

## Overview

The existing gameplay runner smoke tests prove the non-visual contract path with generated inputs and a fake clock. This next slice should keep that contract coverage but add live Godot testbed scenes where a developer can choose an already-converted AeroBeat song package, choose a background environment, calibrate with the same T-pose flow used by the camera tracking testbeds, and play a rough first-person version of Flow or Boxing.

This is not a production gameplay shell. The target is a useful developer workbench with generated dummy visuals, simple hit effects, score/miss counters, completion summary, and enough spatial grounding to judge whether the gameplay feels promising. The implementation should reuse the input, environment, audio, content, runner, and mode repos instead of creating parallel local versions of those systems.

Spatial behavior must be grid-driven. The play area is defined by translating the authored gameplay grid and athlete-space calibrated cells into world-space target positions. Camera start pose, movement limits, beat target paths, and obstacle placement must all respect that mapping rather than using an arbitrary 1 meter assumption. Public tuning values for the testbed playfield, target travel, and hit boxes must live in runner-root `assets/` YAML using the same documentation-comment style as the input camera tracking gesture YAMLs.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current runner smoke/integration testbed and GUT contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/` |
| `REF-02` | Input camera tracking proving scenes and shared T-pose calibration/status behavior | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-03` | Input camera tracking calibration badge and related testbed scripts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/t_pose_calibration_badge.gd` |
| `REF-04` | Camera tracking grid overlays and body/nose tracking references | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/flow_grid_overlay.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-05` | AeroBeat content package and chart parsing contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core` |
| `REF-06` | Flow mode rule engine and chart event contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-flow` |
| `REF-07` | Boxing mode rule engine and chart event contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-boxing` |
| `REF-08` | Input event contract surfaces | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core` |
| `REF-09` | Audio playback and clock source package | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-audio-player` |
| `REF-10` | Environment loading and background package contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-environment-core`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-environment-loader`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-environment-community` |
| `REF-11` | Public YAML documentation/comment style for runtime tuning assets | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |

---

## Frozen Requirements Candidate

### Scene Flow

1. Choose an already-converted AeroBeat song package from disk.
2. Choose a background environment from disk.
3. Stand in T-pose to calibrate and start the song.
4. During unpaused gameplay, activate the same T-pose calibration gesture to pause and enter recalibration/status mode.
5. Successful recalibration resumes gameplay automatically; pause and unpause are tied to the same T-pose calibration gesture event.
6. Play a hit sound on successful hits.
7. Track misses.
8. On completion, show successful hits and misses.

### Frozen Spatial Defaults Candidate

- The play area is derived from the authored grid dimensions and calibrated athlete-space cell bounds, not from an arbitrary fixed 1 meter box.
- First implementation default is a 4x3 calibrated grid unless selected chart/package metadata explicitly provides a supported grid definition.
- Cell indices are row-major from top-left: `0..11`. This must match the input testbed and `aerobeat-input-core` body-cell contract.
- Cell coordinates are derived as `col = cell_index % 4`, `row = floor(cell_index / 4)`.
- Godot world axes for the testbed are: `X = grid columns`, `Y = grid rows`, `Z = target travel depth`.
- Top-left cell `0` maps to the world-space upper-left target position in first-person view; if a beat travels toward cell `0`, the athlete should swing/reach to the visible top-left playfield cell.
- The runner `.testbed` owns a `PlayfieldMapper` helper that converts chart cells and calibrated nose positions into world-space positions using top-left indexed grid semantics.
- The `PlayfieldMapper` must explicitly define grid origin, cell width, cell height, target travel depth, target spawn distance, target hit plane, target hit box range, camera start position, and camera rotation.
- Initial camera candidate: camera rig starts centered horizontally on the grid and vertically at the calibrated neutral nose position, facing Godot forward `-Z` down the incoming target lane toward the hit plane, with fixed rotation during gameplay.
- Nose tracking maps continuously into world `X/Y`, not snapped to cells.
- Nose/camera movement clamps to the nearest valid in-grid world `X/Y` position once the athlete leaves calibrated grid bounds. The camera must not continue following the nose outside the grid.
- Camera movement candidate freeze: move a parent `PlayerRig`/gameplay rig from clamped nose world `X/Y`; keep the `Camera3D` as a child with fixed local transform and rotation during gameplay. Implementation must not mix direct `Camera3D` movement with a separate player-rig offset.
- Movement range should stay within the playable grid unless plan review finds a mode-specific reason to allow margin beyond the grid.
- If athlete height is known or supplied, the mapper may convert calibrated athlete-space cell bounds to meters by using the ratio between captured athlete-space body height and configured `athlete_height_m`. Without a known height, the mapper uses public YAML fallback dimensions and must expose that it is running in fallback scale mode.
- Continuous nose position is not a formal `aerobeat-input-core` body-cell contract today. First implementation must either consume camera-tracking provider debug/landmark data explicitly as a testbed-only dependency, or add an explicit input-camera-tracking surface in that repo before using it. Do not pretend cell-entry signals alone provide continuous nose `X/Y`.
- Flow notes and bombs use `placement`; Flow bursts use `placement` and `tailPlacement`; Flow obstacles use `cells`; Flow arcs use `startPlacement` and `endPlacement`. These authored cells are the source of truth for target lanes and obstacle placement.
- Boxing charts do not currently carry authored cells. Boxing placement is semantic per event type for this testbed, not a chart-cell contract change.
- Boxing left punch targets, including `straight_left`, `uppercut_left`, and `hook_left`, use center row `1`, column `1`.
- Boxing right punch targets, including `straight_right`, `uppercut_right`, and `hook_right`, use center row `1`, column `2`.
- Boxing transition targets are judged by the current Boxing runner and must be visualized/mapped when present: `guard_enabled`, `guard_disabled`, `squat_enabled`, `squat_disabled`, `weave_left_enabled`, `weave_left_disabled`, `weave_right_enabled`, and `weave_right_disabled`.
- Boxing guard and neutral/status prompts span center columns `1..2`; squat prompts use the configured upper blocked band from the input-camera-tracking YAML; weave prompts use the configured blocked columns/cells from the input-camera-tracking YAML.
- Do not add authored Boxing cell placement to content contracts in this slice.
- Left and right beat colors are black and white for the rudimentary testbed visuals.
- Target spawn distance, travel time, and hit box range must be public YAML config values. Initial values are Beat Saber-inspired approximations pending source confirmation, with the implementation documenting any approximation instead of hiding magic numbers in scripts.
- Target travel candidate freeze: use `target.approach_time_sec` as the default rule. A beat becomes visible at `beat_position_sec - approach_time_sec`, starts `spawn_distance_m` behind the hit plane along `-Z`, reaches `target.hit_plane_z_m` at `beat_position_sec`, and is judged by the mode runner's timing window.

### Cell Mapping Acceptance

- The plan must preserve two distinct ideas: input/provider athlete-space cell indexing and first-person visual placement. Both must agree that cell `0` means athlete upper-left.
- Required acceptance examples for a 4x3 top-left grid:
  - Cell `0`: row `0`, col `0`, visual upper-left, athlete upper-left reach/swing.
  - Cell `3`: row `0`, col `3`, visual upper-right, athlete upper-right reach/swing.
  - Cell `8`: row `2`, col `0`, visual lower-left, athlete lower-left reach/swing.
  - Cell `11`: row `2`, col `3`, visual lower-right, athlete lower-right reach/swing.
- The implementation must add a mapper-level test or Godot-visible debug check that proves cells `0`, `3`, `8`, and `11` render in those positions from the first-person camera.
- The input camera tracking testbed has preview/debug mirroring paths; the playable mapper must explicitly document whether it consumes provider/debug coordinates before or after any preview mirroring and must fail QA if cell `0` visually lands on the athlete's right side.

### Public Testbed YAML Contract

- Add a runner-root config such as `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/assets/playable_testbed.yaml`.
- The YAML must use the same documentation style as `REF-11`: short human comments directly above fields, allowed options where relevant, tuning tradeoff notes, and ownership tags such as `runner/testbed/runtime/debug`.
- The YAML should expose, at minimum:
  - schema/version/profile
  - default grid columns/rows
  - top-left cell origin/indexing mode
  - optional `athlete_height_m`
  - fallback cell width/height in meters
  - camera start position and rotation
  - horizontal/vertical camera clamp behavior
  - target hit plane depth
  - target spawn distance/depth
  - target travel time or travel speed rule
  - target hit box radius/range
  - hit SFX path/slot
  - debug overlay toggles
- Approximate first values to freeze unless implementation research finds repo-local precedent or better Beat Saber reference data:
  - `grid.columns: 4`
  - `grid.rows: 3`
  - `grid.origin: top_left`
  - `scale.mode: athlete_height_or_fallback`
  - `scale.fallback_cell_width_m: 0.60`
  - `scale.fallback_cell_height_m: 0.50`
  - `camera.rotation_deg: [0.0, 0.0, 0.0]`
  - `target.hit_plane_z_m: -1.0`
  - `target.spawn_distance_m: 12.0`
  - `target.approach_time_sec: 1.5`
  - `target.hit_box_radius_m: 0.35`
  - `target.spawn_distance_is_relative_to: hit_plane`

### Mode-Specific Visualization

- Flow scene: render incoming beats and obstacles at their authored cells, moving toward the player/hit plane in first person.
- Boxing scene: render incoming boxing punches and transition targets in the semantic center-lane regions described above, with clear left/right black/white target distinction and simple hit/transition feedback.
- Both scenes use generated dummy assets for notes, obstacles, hit effects, lane/grid affordances, and debug overlays.

### Integration Requirements

- The scenes must use `aerobeat-content-core` for package/chart loading and validation.
- The scenes must use `aerobeat-gameplay-runner` for session lifecycle, timeline dispatch, score/result aggregation, and mode-runner orchestration.
- The scenes must use `aerobeat-mode-flow` and `aerobeat-mode-boxing` for the actual mode judgement logic.
- The scenes must use `aerobeat-input-core` contracts and the camera-tracking input repos for live input events, calibration status, T-pose detection, and nose/camera tracking.
- The scenes must reuse the existing camera tracking testbed calibration/status pattern rather than inventing a separate gesture UI.
- The scenes must use `aerobeat-tool-audio-player` for music playback and as the timing/audio-clock source.
- The runner `.testbed` owns an audio-clock adapter that wraps `AeroAudioLoader` into the gameplay runner clock interface. It must not create an independent timer or fake runtime clock.
- Hit sounds must use a second `AeroAudioLoader` audio slot such as `hit_sfx`; the dummy hit SFX asset can live in runner `.testbed/assets/`.
- The environment stack ownership is: `aerobeat-environment-loader` for runtime mounting, `aerobeat-environment-core` for contracts, and `aerobeat-environment-community` for sample assets.
- Environment support must use `AeroEnvironmentConstants.SUPPORTED_KINDS` and `OFFICIAL_FORMATS` through `aerobeat-environment-loader`: image `.png`, video `.ogv`, GLB `.glb`, and splat `.compressed.ply`. The runner testbed must not bypass loader/core contracts or promise direct splat tool compatibility formats outside that path.
- Song and environment picking can be runner `.testbed` local `FileDialog` UI unless Derrick wants a reusable picker package.

### Runtime Ownership

- Runner `.testbed` owns playable scenes, adapters, dummy visuals, dummy hit SFX, picker UI, and developer-only overlays.
- Content-core owns AeroBeat package and chart validation.
- Mode repos own judgement logic and gameplay event semantics.
- Input-camera-tracking owns calibration, body tracking, T-pose recognition, and nose/camera tracking signals.
- Input-core owns normalized input event contracts.
- Audio-player owns music/SFX playback and clock truth.
- Environment-loader owns environment mounting.

---

## Open Questions To Freeze Before Build

1. Is the proposed athlete-height conversion acceptable for first-pass world scaling: use supplied/known `athlete_height_m` when available, otherwise fall back to public YAML cell dimensions and clearly show fallback scale mode in debug UI?
2. Are the Beat Saber-inspired approximation defaults acceptable for the initial YAML values: `hit_plane_z_m: -1.0`, `spawn_distance_m: 12.0`, `approach_time_sec: 1.5`, `hit_box_radius_m: 0.35`, `fallback_cell_width_m: 0.60`, `fallback_cell_height_m: 0.50`?
3. For continuous nose-driven camera movement, should the first implementation consume camera-tracking provider debug/landmark data as a testbed-only dependency, or should we first add a formal continuous nose-position surface to input-camera-tracking/input-core?
4. Are the candidate freezes acceptable: parent `PlayerRig` movement with fixed child `Camera3D`, and `approach_time_sec` travel timing with `spawn_distance_m` relative to the hit plane?
5. What minimum manual/Godot runtime verification must pass before QA and audit: fresh scene open, camera feed live or explicit replay fallback, calibration pass, song load, environment load for `image`, `video`, `glb`, and `splat` supported paths, gameplay start, hit/miss feedback, pause/recalibrate/auto-resume, completion summary, and clean editor/runtime logs?

---

## Tasks

### Task 1: Plan Consistency and Freeze Review

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-11`
**Prompt:** Review `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md` against the referenced AeroBeat repos. Do not implement code. Identify contradictions, missing decisions, likely repo-boundary mistakes, unclear contract assumptions, and anything that must be frozen before execution beads are created. Pay special attention to grid-to-world mapping, camera start pose/rotation, clamped nose tracking, Flow cell placement, Boxing center-lane placement, T-pose calibration/pause/auto-resume semantics, public runner-root `assets/` YAML config ownership/comment style, audio-clock ownership, hit SFX ownership, and environment package loading including splat support. Return concrete plan edits or questions.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Carson completed an independent plan review. Findings were folded into this plan, then Derrick corrected and expanded the requirements: 4x3 row-major grid defaults with top-left input-contract origin, world axis mapping, `PlayfieldMapper` ownership, continuous nose-to-grid clamping, fixed camera rotation candidate, Flow authored-cell source of truth, semantic Boxing lanes, public runner-root YAML tuning, audio-clock adapter ownership, SFX slot ownership, environment loader/core/community boundaries, environment stack format support including splats, local `FileDialog` picker approval, and stronger Godot validation requirements. A follow-up auditor review was completed and folded in: explicit cell mapping acceptance for cells `0`, `3`, `8`, and `11`; `tailPlacement` and other Flow placement fields; Boxing transition events as judged prompts; Beat Saber values labeled approximations; environment support tied to `AeroEnvironmentConstants`; and the continuous nose-position API risk. Remaining freeze questions are listed above.

---

### Task 2: Freeze Build Plan After Review

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` / `auditor` workflow roles)  
**Role:** `research`  
**References:** `REF-01` through `REF-11`
**Prompt:** After Task 1 review, update this plan with the frozen implementation decisions and create executable task slices for developer testbed implementation, QA, and audit. Do not begin implementation until Derrick confirms the plan is ready to execute.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ⏳ Pending

**Results:** Pending Derrick review of freeze questions.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft plan plus independent review pass only. No implementation started.

**Reference Check:** Subagent review completed against referenced repos and raised freeze edits/open questions now captured in this plan.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
