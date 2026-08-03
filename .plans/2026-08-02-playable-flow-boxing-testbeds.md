# Playable Flow and Boxing Gameplay Testbeds

**Date:** 2026-08-02  
**Status:** Blocked  
**Last Updated:** 2026-08-02 20:16 EDT
**Blocked Reason:** Final manual/high-fidelity audit is blocked by playable scene camera/replay provider startup and unproven environment splat display. Runner camera-source selection is now active follow-up work in Task 4.
**Agent:** pico

---

## Goal

Build rudimentary first-person Godot developer testbed scenes for AeroBeat Flow and Boxing that prove real content, input calibration/tracking, audio timing, environment loading, gameplay runner dispatch, mode judgements, and hit/miss feedback in a playable loop.

---

## Overview

The existing gameplay runner smoke tests prove the non-visual contract path with generated inputs and a fake clock. This next slice should keep that contract coverage but add live Godot testbed scenes where a developer can choose an already-converted AeroBeat song package, choose a background environment, calibrate with the same T-pose flow used by the camera tracking testbeds, and play a rough first-person version of Flow or Boxing.

This is not a production gameplay shell. The target is a useful developer workbench with generated dummy visuals, simple hit effects, score/miss counters, completion summary, and enough spatial grounding to judge whether the gameplay feels promising. The implementation should reuse the input, environment, audio, content, runner, and mode repos instead of creating parallel local versions of those systems.

Spatial behavior must be grid-driven. The play area is defined by translating the authored gameplay grid and athlete-space calibrated cells into world-space target positions. Camera start pose, movement limits, beat target paths, and obstacle placement must all respect that mapping rather than using an arbitrary 1 meter assumption. Public tuning values for the testbed playfield, target travel, hit boxes, debug overlays, and calibration-overlay fade must live in runner-root `assets/` YAML using the exact documentation-comment shape as the input camera tracking testbed/debug YAMLs.

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
| `REF-11` | Public YAML documentation/comment style for runtime tuning assets | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.testbed_debug.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml` |
| `REF-12` | Proposed first-class normalized body-grid pose contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md` |

---

## Frozen Requirements

### Scene Flow

1. Choose an already-converted AeroBeat song package from disk.
2. Choose a background environment from disk.
3. Stand in T-pose to calibrate and start the song.
4. During unpaused gameplay, activate the same T-pose calibration gesture to pause and enter recalibration/status mode.
5. Successful recalibration resumes gameplay automatically; pause and unpause are tied to the same T-pose calibration gesture event.
6. Play a hit sound on successful hits.
7. Track misses.
8. On completion, show successful hits and misses.

### Frozen Spatial Defaults

- The play area is derived from the authored grid dimensions and calibrated athlete-space cell bounds, not from an arbitrary fixed 1 meter box.
- First implementation default is a 4x3 calibrated grid unless selected chart/package metadata explicitly provides a supported grid definition.
- Cell indices are row-major from top-left: `0..11`. This must match the input testbed and `aerobeat-input-core` body-cell contract.
- Cell coordinates are derived as `col = cell_index % 4`, `row = floor(cell_index / 4)`.
- Godot world axes for the testbed are: `X = grid columns`, `Y = grid rows`, `Z = target travel depth`.
- Top-left cell `0` maps to the world-space upper-left target position in first-person view; if a beat travels toward cell `0`, the athlete should swing/reach to the visible top-left playfield cell.
- The runner `.testbed` owns a `PlayfieldMapper` helper that converts chart cells and calibrated nose positions into world-space positions using top-left indexed grid semantics.
- The `PlayfieldMapper` must explicitly define grid origin, cell width, cell height, target travel depth, target spawn distance, target hit plane, target hit box range, camera start position, and camera rotation.
- Initial camera behavior: camera rig starts centered horizontally on the grid and vertically at the calibrated neutral nose position, facing Godot forward `-Z` down the incoming target lane toward the hit plane, with fixed rotation during gameplay.
- Nose tracking maps continuously into world `X/Y`, not snapped to cells.
- Nose/camera movement clamps to the nearest valid in-grid world `X/Y` position once the athlete leaves calibrated grid bounds. The camera must not continue following the nose outside the grid.
- Camera movement behavior: move a parent `PlayerRig`/gameplay rig from clamped nose world `X/Y`; keep the `Camera3D` as a child with fixed local transform and rotation during gameplay. Implementation must not mix direct `Camera3D` movement with a separate player-rig offset.
- Movement range should stay within the playable grid unless plan review finds a mode-specific reason to allow margin beyond the grid.
- If athlete height is known or supplied, the mapper may convert calibrated athlete-space cell bounds to meters by using the ratio between captured athlete-space body height and configured `athlete_height_m`. Without a known height, the mapper uses public YAML fallback dimensions and must expose that it is running in fallback scale mode.
- Continuous nose, left-wrist, and right-wrist tracking in normalized calibrated grid space must become first-class `aerobeat-input-core` surfaces before the playable testbed consumes them. The proposed contract is tracked in `REF-12`.
- The playable testbed must consume the final per-body-part `InputManager` body-grid signals/queries frozen by `REF-12`, not camera-tracking provider debug/landmark internals.
- Calibration lifecycle must be consumed from separate `InputManager` calibration events/queries, not bundled with pose/body-part data.
- The normalized body-grid pose contract must preserve top-left athlete-space semantics: cell `0` is athlete upper-left, with normalized `x = 0.0` at the athlete-space left edge and `y = 0.0` at the top edge.
- Flow notes and bombs use `placement`; Flow bursts use `placement` and `tailPlacement`; Flow obstacles use `cells`; Flow arcs use `startPlacement` and `endPlacement`. These authored cells are the source of truth for target lanes and obstacle placement.
- Boxing charts do not currently carry authored cells. Boxing placement is semantic per event type for this testbed, not a chart-cell contract change.
- Boxing left punch targets, including `straight_left`, `uppercut_left`, and `hook_left`, use center row `1`, column `1`.
- Boxing right punch targets, including `straight_right`, `uppercut_right`, and `hook_right`, use center row `1`, column `2`.
- Boxing transition targets are judged by the current Boxing runner and must be visualized/mapped when present: `guard_enabled`, `guard_disabled`, `squat_enabled`, `squat_disabled`, `weave_left_enabled`, `weave_left_disabled`, `weave_right_enabled`, and `weave_right_disabled`.
- Boxing guard and neutral/status prompts span center columns `1..2`; squat prompts use the configured upper blocked band from the input-camera-tracking YAML; weave prompts use the configured blocked columns/cells from the input-camera-tracking YAML.
- Do not add authored Boxing cell placement to content contracts in this slice.
- Left and right beat colors are black and white for the rudimentary testbed visuals.
- Target spawn distance, travel time, and hit box range must be public YAML config values. Initial values are Beat Saber-inspired approximations for this developer testbed, with the implementation documenting the approximation instead of hiding magic numbers in scripts.
- Target travel uses `target.approach_time_sec` as the default rule. A beat becomes visible at `beat_position_sec - approach_time_sec`, starts `spawn_distance_m` behind the hit plane along `-Z`, reaches `target.hit_plane_z_m` at `beat_position_sec`, and is judged by the mode runner's timing window.

### Frozen Mapper Formula

- For a grid with `columns` and `rows`:

```text
col = cell_index % columns
row = floor(cell_index / columns)

normalized_center_x = (col + 0.5) / columns
normalized_center_y = (row + 0.5) / rows

world_x = (normalized_center_x - 0.5) * playfield_width_m
world_y = (0.5 - normalized_center_y) * playfield_height_m
world_z = target.hit_plane_z_m
```

- Godot `Y` is intentionally inverted from normalized grid `y`: row `0` maps to positive/higher world `Y` so the top row renders visually above the player center in first-person.
- Nose/world camera movement uses the same normalized mapping, then clamps `x/y` into `[0.0, 1.0]` before converting to world `X/Y`.
- Scale is computed from athlete height when available:

```text
playfield_height_m = athlete_height_m * scale.playfield_height_ratio
cell_height_m = playfield_height_m / rows
cell_width_m = cell_height_m * scale.cell_aspect_ratio
playfield_width_m = cell_width_m * columns
```

- If athlete height is not available, use YAML fallback cell dimensions:

```text
playfield_height_m = scale.fallback_cell_height_m * rows
playfield_width_m = scale.fallback_cell_width_m * columns
```

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
- The YAML must use the same documentation shape as `REF-11`: every field has a short human comment directly above it, allowed options appear in the comment where relevant, tuning tradeoff notes are included where useful, and debug/runtime fields include ownership tags such as `runner testbed runtime only` or `runner testbed debug only`.
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
  - body pose overlay toggle
  - nose marker overlay toggle
  - left-wrist marker overlay toggle
  - right-wrist marker overlay toggle
  - grid overlay toggle
  - body-grid pose overlay visibility after calibration in milliseconds
- First-pass values:
  - `grid.columns: 4`
  - `grid.rows: 3`
  - `grid.origin: top_left`
  - `scale.mode: athlete_height_or_fallback`
  - `scale.playfield_height_ratio: 0.95`
  - `scale.cell_aspect_ratio: 1.2`
  - `scale.fallback_cell_width_m: 0.60`
  - `scale.fallback_cell_height_m: 0.50`
  - `camera.rotation_deg: [0.0, 0.0, 0.0]`
  - `target.hit_plane_z_m: -1.0`
  - `target.spawn_distance_m: 12.0`
  - `target.approach_time_sec: 1.5`
  - `target.hit_box_radius_m: 0.35`
  - `target.spawn_distance_is_relative_to: hit_plane`
  - `debug.body_grid_pose_visible_after_calibration_ms: 2000`
  - `debug.show_body_pose_overlay: true`
  - `debug.show_body_grid_overlay: true`
  - `debug.show_nose_marker: true`
  - `debug.show_left_wrist_marker: true`
  - `debug.show_right_wrist_marker: true`

### Mode-Specific Visualization

- Flow scene: render incoming beats and obstacles at their authored cells, moving toward the player/hit plane in first person.
- Boxing scene: render incoming boxing punches and transition targets in the semantic center-lane regions described above, with clear left/right black/white target distinction and simple hit/transition feedback.
- Both scenes use generated dummy assets for notes, obstacles, hit effects, lane/grid affordances, and debug overlays.
- After calibration, both scenes show the calibrated grid plus body pose, nose, left-wrist, and right-wrist debug markers sourced from the normalized body-grid pose contract and existing camera-tracking testbed debug visual patterns. The markers fade after `debug.body_grid_pose_visible_after_calibration_ms`, default `2000`, unless the developer overlay toggles keep them visible.

### Integration Requirements

- The scenes must use `aerobeat-content-core` for package/chart loading and validation.
- The scenes must use `aerobeat-gameplay-runner` for session lifecycle, timeline dispatch, score/result aggregation, and mode-runner orchestration.
- The scenes must use `aerobeat-mode-flow` and `aerobeat-mode-boxing` for the actual mode judgement logic.
- The scenes must use `aerobeat-input-core` contracts and the camera-tracking input repos for live input events, separate calibration status/events, T-pose detection, and normalized nose/left-wrist/right-wrist grid tracking.
- The scenes must reuse the existing camera tracking testbed calibration/status pattern rather than inventing a separate gesture UI.
- The scenes must use `aerobeat-tool-audio-player` for music playback and as the timing/audio-clock source.
- The runner `.testbed` owns an audio-clock adapter that wraps `AeroAudioLoader` into the gameplay runner clock interface. It must not create an independent timer or fake runtime clock.
- Pre-song T-pose starts calibration; successful calibration starts audio playback and gameplay together.
- During unpaused gameplay, the T-pose calibration gesture pauses gameplay ticking and audio playback together, enters calibration/status mode, and resumes both automatically after successful recalibration.
- Failed/canceled recalibration leaves gameplay and audio paused, with status visible, until the next successful calibration or explicit stop/retry action.
- Hit windows and target timing derive only from the audio clock position. Wall-clock timers may animate visuals between audio-clock samples but must not be the authority for judgement timing.
- Hit sounds must use a second `AeroAudioLoader` audio slot such as `hit_sfx`; the dummy hit SFX asset can live in runner `.testbed/assets/`.
- The environment stack ownership is: environment repos are fully responsible for correctly displaying environments. `aerobeat-environment-loader` owns runtime mounting/display handoff, `aerobeat-environment-core` owns contracts/constants, and `aerobeat-environment-community` owns sample assets.
- Environment support must use `AeroEnvironmentConstants.SUPPORTED_KINDS` and `OFFICIAL_FORMATS` through `aerobeat-environment-loader`: image `.png`, video `.ogv`, GLB `.glb`, and splat `.compressed.ply`. The runner testbed must not bypass loader/core contracts, render environments itself, implement runner-local splat rendering, or promise direct splat tool compatibility formats outside that path.
- If an environment kind does not display correctly, that is an environment repo bug/follow-up, not runner/testbed ownership. The runner testbed can surface environment-loader status/errors, but it must not carry bespoke renderer fixes.
- Song and environment picking can be runner `.testbed` local `FileDialog` UI unless Derrick wants a reusable picker package.

### Runtime Ownership

- Runner `.testbed` owns playable scenes, adapters, dummy visuals, dummy hit SFX, picker UI, and developer-only overlays.
- Content-core owns AeroBeat package and chart validation.
- Mode repos own judgement logic and gameplay event semantics.
- Input-camera-tracking owns calibration, body tracking, T-pose recognition, and provider-side nose/wrist tracking implementation.
- Input-core owns normalized input event contracts.
- Input-core owns the first-class normalized body-grid per-body-part surfaces that proxy calibrated nose, left-wrist, and right-wrist positions to gameplay/debug consumers.
- Input-core owns separate calibration lifecycle event contracts consumed by the runner testbed.
- Audio-player owns music/SFX playback and clock truth.
- Environment repos own environment mounting and correct display; runner/testbed only asks them to load/display the chosen environment.

---

## Frozen Build Decisions

1. Athlete-height conversion is frozen for v1: use supplied/known `athlete_height_m` and `scale.playfield_height_ratio` when available; otherwise use public YAML fallback cell dimensions and show fallback scale mode in debug UI.
2. Beat Saber-inspired approximation defaults are frozen for first implementation: `hit_plane_z_m: -1.0`, `spawn_distance_m: 12.0`, `approach_time_sec: 1.5`, `hit_box_radius_m: 0.35`, `fallback_cell_width_m: 0.60`, `fallback_cell_height_m: 0.50`, `playfield_height_ratio: 0.95`, and `cell_aspect_ratio: 1.2`.
3. The normalized body-grid pose dependency is frozen per `REF-12`: one event/query per body part, separate calibration lifecycle events, top-left athlete-space normalized `x/y`, per-anchor validity, clamped gameplay-ready `x/y`, required raw `raw_x/raw_y`, schema-shaped invalid query data, provider-generated `calibration_id`, and active-provider-only `InputManager` proxy semantics.
4. Runtime movement/travel is frozen: parent `PlayerRig` moves from clamped nose `X/Y`, child `Camera3D` keeps fixed local transform/rotation, and target travel uses `approach_time_sec` with `spawn_distance_m` relative to the hit plane.
5. Pause/recalibration/audio behavior is frozen: gameplay and audio pause together, successful recalibration resumes both, failed/canceled recalibration keeps both paused, and hit windows derive from audio clock only.
6. Environment ownership is frozen: the environment repos must correctly display supported environments; runner/testbed only requests loading/display and reports status/errors.

### Readiness Audit Results

Task 2 readiness audit initially returned `BLOCKED`; the blockers were promoted into frozen requirements. The final readiness audit passed, closed `aerobeat-gameplay-runner-7l8`, and approved breaking the work into implementation seams:

- Input-core body-grid pose v1 is frozen in `REF-12`.
- Runner overlay fade semantics are frozen: fade starts only on separate calibration success event, `0 = no post-calibration persistence`, and always-visible behavior is controlled only by debug toggles.
- Exact world-space mapper formulas, including Godot `Y` sign, are frozen above.
- Environment repo ownership/readiness path is frozen above.
- Pause/recalibration audio behavior is frozen above.
- Minimum manual validation gate is frozen below.

### Manual Validation Gate

Before QA and audit can pass, the coder/QA evidence must include:

- Fresh open of Boxing playable scene in Godot and clean editor/runtime logs.
- Fresh open of Flow playable scene in Godot and clean editor/runtime logs.
- Camera source selection happens during the calibration/setup step before gameplay starts, before `InputManager` provider startup is probed.
- Camera source selection supports live camera input and replay video input.
- Replay video input can be selected from a local filesystem path through a runner testbed `FileDialog`/file-browser path lookup, and that selected path is passed into the camera-tracking provider before registration/startup.
- Camera feed live, or an explicit recorded/replay fallback selected through the testbed UI and documented in the bead.
- Song package selected from disk and validated through content-core.
- Environment selected from disk and displayed through environment-loader/core for each supported kind in scope: image, video, GLB, and splat. If a supported kind fails to display, file/update an environment-owned bead or blocker rather than accepting runner-local placeholder rendering.
- T-pose calibration succeeds before playback.
- Body pose/grid/nose/left-wrist/right-wrist debug visuals appear after calibration and fade after the configured `2000ms` default unless always-visible debug toggles are enabled.
- Audio and gameplay start together after calibration.
- At least one successful hit produces hit SFX.
- Misses are tracked.
- T-pose during gameplay pauses audio/gameplay, recalibrates, and auto-resumes both on success.
- Completion summary shows successful hits and misses.
- Cells `0`, `3`, `8`, and `11` visually land in upper-left, upper-right, lower-left, and lower-right first-person positions respectively.

---

## Tasks

### Task 1: Plan Consistency and Freeze Review

**Bead ID:** `aerobeat-input-core-ij5`, `aerobeat-input-camera-tracking-8fbh`, `aerobeat-gameplay-runner-an1`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-11`
**Prompt:** Review `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md` against the referenced AeroBeat repos. Do not implement code. Identify contradictions, missing decisions, likely repo-boundary mistakes, unclear contract assumptions, and anything that must be frozen before execution beads are created. Pay special attention to grid-to-world mapping, camera start pose/rotation, clamped nose tracking, Flow cell placement, Boxing center-lane placement, T-pose calibration/pause/auto-resume semantics, public runner-root `assets/` YAML config ownership/comment style, audio-clock ownership, hit SFX ownership, and environment package loading including splat support. Return concrete plan edits or questions.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Carson completed an independent plan review. Findings were folded into this plan, then Derrick corrected and expanded the requirements: 4x3 row-major grid defaults with top-left input-contract origin, world axis mapping, `PlayfieldMapper` ownership, continuous nose-to-grid clamping, fixed camera rotation, Flow authored-cell source of truth, semantic Boxing lanes, public runner-root YAML tuning, audio-clock adapter ownership, SFX slot ownership, environment loader/core/community boundaries, environment stack format support including splats, local `FileDialog` picker approval, and stronger Godot validation requirements. A follow-up auditor review was completed and folded in: explicit cell mapping acceptance for cells `0`, `3`, `8`, and `11`; `tailPlacement` and other Flow placement fields; Boxing transition events as judged prompts; Beat Saber values labeled approximations; environment support tied to `AeroEnvironmentConstants`; and the continuous nose-position API risk. Remaining freeze questions were later promoted into frozen build decisions.

### Task 1B: Normalized Body Grid Pose Contract Review

**Bead ID:** `aerobeat-input-core-00d`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-08`, `REF-12`  
**Prompt:** Claim bead `aerobeat-input-core-00d` on start. Review `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md` and this playable testbed plan. Do not implement code. Find inconsistencies and missing freeze decisions around first-class normalized nose/left-wrist/right-wrist grid-space contracts, top-left athlete-space semantics, provider mirroring risks, per-anchor validity, clamped/raw coordinate reporting, calibration session identity, `InputManager` proxy behavior, and runner debug overlay fade YAML defaulting to `2000ms`. Return concrete plan edits/questions, then close bead `aerobeat-input-core-00d` only if the review is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Auditor review completed and bead `aerobeat-input-core-00d` was closed. The review confirmed the repo boundary: input-core owns the first-class API, camera-tracking owns concrete pose/calibration math, and runner consumes only `InputManager`. Derrick then corrected the preferred API shape: v1 should expose one event/query per body part rather than one bundled pose frame, and calibration lifecycle events must be emitted separately from pose/body-part updates. The plan now also requires runner debug visual options for body pose, nose, left wrist, and right wrist, following the input-camera-tracking testbed debug visual patterns.

---

### Task 2: Freeze Build Plan After Review

**Bead ID:** `aerobeat-gameplay-runner-7l8`  
**SubAgent:** `primary` (for `research` / `auditor` workflow roles)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-11`
**Prompt:** Claim bead `aerobeat-gameplay-runner-7l8` on start. Review this plan and `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md` for missing holes, unanswered questions, inconsistent repo boundaries, and readiness to break the work into executable implementation seams. Do not implement code. If no blocking questions remain, propose concrete implementation seams with repo ownership, bead ordering, coder/QA/auditor loop boundaries, and validation gates. Close bead `aerobeat-gameplay-runner-7l8` only if the review is complete and clearly states whether implementation can begin.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Initial readiness audit returned `BLOCKED`. The blockers were promoted into frozen requirements across this plan and `REF-12`: exact input-core per-body-part APIs, separate calibration lifecycle events, invalid anchor shape, tracking-loss behavior, stable `calibration_id`, exact mapper formulas, athlete-height/fallback scale defaults, pause/recalibration/audio-clock behavior, environment ownership, YAML comment shape, and manual validation. Final readiness audit passed and closed `aerobeat-gameplay-runner-7l8`; implementation can begin in the seam order recorded below.

---

### Task 3: Implementation Seams

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder` / `qa` / `auditor` workflow roles)  
**Role:** `coder`  
**References:** `REF-01` through `REF-12`  
**Prompt:** Create ordered implementation beads and execute them through coder, QA, and auditor loops. Dependency order is: input-core contract first; input-camera-tracking provider emission second; gameplay-runner playable testbed consumption/scenes third; QA fourth; final audit last.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/`

**Files Created/Deleted/Modified:**
- Pending implementation.

**Status:** ⏳ In Progress

**Results:** Execution beads created. Cross-repo dependencies could not be represented with local `bd dep add`, so dependency order is recorded in bead notes and enforced by orchestration. The input-core contract seam passed QA/audit and closed `aerobeat-input-core-ij5`; the camera-tracking body-grid anchor seam passed implementation/QA/audit and closed `oc-zex8`. Runner implementation landed in commit `c1bb79a` with playable Flow and Boxing `.testbed` scenes, runner-owned `assets/playable_testbed.yaml`, `PlayfieldMapper`, shared playable harness/adapters, FileDialog song/environment selection, dummy hit SFX, generated mesh/debug visuals, and GodotEnv dependencies wired into the testbed. Coder validation passed targeted GUT (`11` tests, `174` assertions), fresh headless Flow and Boxing scene opens, GodotEnv sync, and class-name collision scan. QA returned `BLOCKED`: debug overlay YAML toggles were not individually honored, Flow burst/arc multi-placement visualization only rendered one cell, and Boxing transition/blocked-region visualization mapped spans/bands to single cells. Coder follow-up commit `e362153` fixed those static QA blockers by adding `playable_target_regions.gd`, rendering one visual per required authored/semantic cell or region, honoring the independent debug overlay toggles, and adding focused GUT coverage. Coder validation after the fix passed GodotEnv sync, headless import, GUT (`16` tests, `190` assertions), fresh headless Flow and Boxing scene opens, class-name scan, and `git diff --check`. QA retry passed the static/headless scope at commit `5abcd88`: GodotEnv sync, headless import, full GUT (`16` tests, `190` assertions), fresh headless Flow and Boxing scene opens, class-name scan, and `git diff --check` all passed, with the three prior static blockers confirmed fixed in code and tests. Final manual/high-fidelity audit at commit `04e300b` returned `BLOCKED`: fresh non-headless Flow and Boxing runtime opens exit `0` but logs are not clean because `InputManager` reports `Provider 'camera_tracking' failed startup test`; the playable scenes do not expose a scene/UI/settings path to choose replay before provider startup, so live/replay camera, T-pose calibration, overlay fade, audio/gameplay sync, hit SFX, miss tracking, recalibration pause/resume, completion summary, FileDialog selection/display, and first-person runtime cell placement remain unproven. Follow-up runner bead `aerobeat-gameplay-runner-o9t` was created and linked as a dependency of `aerobeat-gameplay-runner-an1`. Environment-loader follow-up bead `aerobeat-tool-environment-1ds` was created for visible splat rendering beyond the current placeholder/anchor path.

---

### Task 4: Pre-Gameplay Camera Source Selection

**Bead ID:** `aerobeat-gameplay-runner-o9t`
**SubAgent:** `primary` (for `coder` / `qa` / `auditor` workflow roles)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-08`, `REF-11`
**Prompt:** Claim bead `aerobeat-gameplay-runner-o9t` on start. Implement runner-owned camera source selection for the Flow and Boxing playable testbed scenes. The testbed must let the developer choose the camera source during setup/calibration before gameplay starts and before `InputManager` probes/registers the camera-tracking provider. It must support live camera and replay video modes. Replay mode must include a local filesystem `FileDialog`/file-browser path lookup for a video file and pass that selected local path into the camera-tracking provider settings before startup. Reuse the existing camera-tracking provider contracts and proving-scene patterns; do not modify generated `addons/` copies directly. Add focused GUT or script-level coverage for the provider settings/picker state where feasible, run GodotEnv sync, headless import, targeted/full GUT, fresh Flow and Boxing scene opens, class-name scan, and `git diff --check`. Because this touches Godot runtime scenes, also perform fresh non-headless Flow and Boxing opens and inspect editor/runtime logs; unexpected warnings/errors must be fixed or explicitly recorded as accepted exceptions. Commit and push on completion, leaving bead notes with changed files and validation output. Do not close `aerobeat-gameplay-runner-an1`; that remains for QA/audit after this blocker.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/camera_source_picker_state.gd` - added runner-owned live/replay picker state and provider settings shaping.
- `.testbed/scripts/playable_testbed_harness.gd` - deferred camera-tracking provider registration until the developer chooses live camera or replay video before calibration; passes selected settings/path into `InputManager.register_provider`.
- `.testbed/scenes/flow_playable_testbed.tscn` - added live camera/replay video controls, source status label, and replay `FileDialog`.
- `.testbed/scenes/boxing_playable_testbed.tscn` - added the same camera source controls and replay `FileDialog`.
- `.testbed/tests/test_camera_source_picker_state.gd` - added focused GUT coverage for live/replay provider settings and empty replay state.
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - recorded Task 4 implementation and validation results.

**Status:** ✅ Implemented

**Results:** Implemented runner-owned camera source selection in the shared Flow/Boxing playable harness. Provider registration is no longer attempted in `_ready()`; calibration now requires the developer to choose `Live Camera` or `Replay Video` first. Replay mode opens a local filesystem `FileDialog` and stores the selected path in provider settings as `camera_source`, `selected_camera_device_id`, and `source: {kind: "video_file", path: ...}` before `InputManager.register_provider` performs its startup probe. Live mode stores `source: {kind: "live_camera", camera_id/id: ...}`. Switching source before calibration unregisters the prior camera provider registration so the next calibration uses the newly selected settings. Validation passed: GodotEnv sync, headless import, full GUT (`19` tests, `202` assertions), fresh headless Flow and Boxing scene opens, fresh non-headless Flow and Boxing scene opens with clean runtime output, class-name scan, and `git diff --check`. Accepted exception: headless import still reports existing third-party GUT invalid UID fallback warnings and an ObjectDB leak warning on editor-import exit; the fresh scene opens and GUT run are clean.

---

## Final Results

**Status:** ❌ Blocked

**What We Built:** Frozen implementation plan plus independent readiness audit. Input-core and camera-tracking prerequisite seams are implemented, QA/audited, committed, and pushed. Runner implementation is committed and pushed, coder follow-up fixes for the static QA blockers are committed and pushed, and the static/headless QA retry passed. Final manual/high-fidelity audit is blocked on runner camera/replay startup (`aerobeat-gameplay-runner-o9t`) and environment-loader splat display ownership (`aerobeat-tool-environment-1ds`).

**Reference Check:** Subagent reviews completed against referenced repos. The final readiness audit passed after freeze edits and closed `aerobeat-gameplay-runner-7l8`.

**Commits:**
- `c1bb79a` - Add playable Flow and Boxing testbeds
- `7d847a8` - Record playable testbed implementation handoff
- `076ca8e` - Record playable testbed QA blockers
- `e362153` - Fix playable testbed QA blockers
- `5abcd88` - Record playable testbed QA retry
- `04e300b` - Record playable testbed QA retry in plan

**Lessons Learned:** Static/headless coverage can prove the target mapping and overlay toggle regressions, but the playable seam still needs an explicit live/replay provider configuration path before manual runtime validation can prove calibration and gameplay behavior.

---

*Completed on Pending*
