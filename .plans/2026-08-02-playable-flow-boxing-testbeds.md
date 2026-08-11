# Playable Flow and Boxing Gameplay Testbeds

**Date:** 2026-08-02  
**Status:** Blocked  
**Last Updated:** 2026-08-11 06:35 EDT
**Blocked Reason:** Task 8 fixed the runner-owned startup parse errors by restoring the missing camera-recording testbed dependency. Task 11 removed the remaining GUT vendor UID fallback warnings at the owning vendor source. Task 12 removed the remaining ObjectDB import-exit warning by updating the owning GUT vendor plugin headless-import path in commit `99f1939`, and zero-noise import/GUT/scene-open validation now passes. Final closure remains blocked on `aerobeat-gameplay-runner-an1` until Derrick manually observes a real playable session proving calibration/playback, overlays, audio/gameplay sync, hits/misses, recalibration, completion summary, environment display, and first-person cells `0/3/8/11`. Environment-owned splat-display follow-up remains tracked by `aerobeat-tool-environment-1ds`.
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
| `REF-13` | Derrick screenshot of gameplay runner testbed startup warnings/errors | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/08/10/image-4f11017b.png` |
| `REF-14` | Derrick screenshot of remaining GUT vendor UID fallback warnings | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/08/10/image-1ae9606d.png` |

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

### Task 5: QA Retry After Camera Source Selection

**Bead ID:** `aerobeat-gameplay-runner-an1`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01` through `REF-12`
**Prompt:** Claim bead `aerobeat-gameplay-runner-an1` on start. At commit `987d1bd`, perform the QA retry for the playable Flow and Boxing testbeds after Task 4 removed the stale provider-startup blocker. Verify that camera source selection happens during setup/calibration before provider startup; live camera and replay video modes are exposed; replay uses a local `FileDialog` path and passes that path into camera-tracking provider settings before registration. Rerun GodotEnv sync, headless import, full GUT, fresh headless Flow and Boxing scene opens, fresh non-headless Flow and Boxing scene opens with log inspection, class-name scan, and `git diff --check`. Exercise or truthfully classify the remaining manual/high-fidelity gates from this plan, including song/environment FileDialog selection, replay/live camera feed availability, T-pose calibration, overlay fade, audio/gameplay sync, hit SFX, misses, recalibration pause/resume, completion summary, and cells `0/3/8/11` first-person placement. Do not close the bead; leave notes and a QA pass/blocker decision for final audit.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - recorded QA retry evidence and remaining manual/high-fidelity gate classification.

**Status:** ✅ Complete

**Results:** QA retry passed for the Task 4 camera-source seam and all automated/runtime-open gates at HEAD `c550f76`, after implementation commit `987d1bd`. QA verified provider startup is deferred out of `_ready()`/setup and into calibration request flow; Flow and Boxing expose `Live Camera` and `Replay Video`; replay uses a local filesystem `FileDialog`; selected replay paths are shaped into camera-tracking provider settings before `InputManager.register_provider`; and switching source before calibration unregisters any previous provider registration. Validation passed: GodotEnv sync, headless import with accepted pre-existing third-party GUT invalid UID fallback/ObjectDB import-exit warnings, full GUT (`4` scripts, `19` tests, `202` assertions), fresh headless Flow and Boxing opens, fresh non-headless Flow and Boxing opens with clean normal Godot/Vulkan output, class-name scan (`0` collisions, all severity buckets `0`), and `git diff --check`. QA classified the remaining manual/high-fidelity gates as not live-observed rather than failed: real live/replay camera feed, real T-pose calibration, audio/gameplay sync, hit SFX audibility, misses, recalibration pause/resume, completion summary, interactive FileDialog package/environment display, live overlay fade, and first-person cell `0/3/8/11` observation. Bead `aerobeat-gameplay-runner-an1` remains open for final audit/manual gate closure.

### Task 6: Final Manual/High-Fidelity Audit Retry

**Bead ID:** `aerobeat-gameplay-runner-an1`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01` through `REF-12`
**Prompt:** Claim bead `aerobeat-gameplay-runner-an1` on start. Independently audit the playable Flow and Boxing testbeds after camera-source selection and QA retry. Verify the current plan, bead notes, commit history, automated validation, fresh Godot scene opens, and remaining Manual Validation Gate items. Close the bead only if the final high-fidelity gate is truthfully proven; otherwise append audit notes, push Beads, and leave the bead open with the concrete blocker.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/`

**Files Created/Deleted/Modified:**
- None by the auditor.
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - orchestrator recorded the audit outcome.

**Status:** ❌ Blocked

**Results:** Auditor retry at HEAD `2b59ee5` confirmed the repo was clean, verified commits `987d1bd`, `c550f76`, and `2b59ee5` were present, and appended final audit notes to bead `aerobeat-gameplay-runner-an1`. The camera-source seam passed audit: provider startup is deferred until calibration, Flow/Boxing expose live and replay controls, replay uses filesystem `FileDialog`, selected replay paths are passed into provider settings before `InputManager.register_provider`, and source switching resets prior provider registration. Fresh validation passed: GodotEnv sync, headless import with only accepted third-party GUT UID/ObjectDB import-exit warnings, full GUT (`4` scripts, `19` tests, `202` assertions), fresh headless Flow and Boxing opens, fresh non-headless Flow and Boxing opens with no warning/error lines, class-name scan (`0` collisions), and `git diff --check`. The auditor left `aerobeat-gameplay-runner-an1` open because the full Manual Validation Gate is still not proven live: actual live/replay camera feed through UI selection, real T-pose calibration, song/environment FileDialog selection in a playable run, image/video/GLB/splat display, overlay fade after calibration, audio/gameplay sync, hit SFX, misses, recalibration pause/resume, completion summary, and first-person visual observation of cells `0/3/8/11`. Concrete next slice: run a real high-fidelity manual session with usable camera or replay video selected through the runner UI, real song/environment fixtures selected through FileDialogs, calibration, and short gameplay, then record the visual/audio/gameplay observations before closing the bead.

---

### Task 7: Fix Playable Manual Gate Startup Blockers

**Bead ID:** `aerobeat-gameplay-runner-eqo`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-08`
**Prompt:** Claim bead `aerobeat-gameplay-runner-eqo` on start. Fix the 2026-08-10 QA blockers: typed target assignment in `playable_testbed_harness.gd` and replay provider registration failing even though selected replay settings contain the local video path. Add focused coverage, rerun the manual-gate validation slice, update this plan and bead notes, and leave `aerobeat-gameplay-runner-an1` open unless the full Manual Validation Gate passes.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/playable_testbed_harness.gd` - converts loaded content events into a typed `Array[Dictionary]`; primes `AeroCameraTracking` with the selected live/replay source, vendor runtime config, and tracking session before `InputManager.register_provider`.
- `.testbed/addons.jsonc` - adds the missing `aerobeat-vendor-mediapipe-python` testbed dependency required by `aerobeat-tool-camera-tracking` replay startup.
- `.testbed/tests/test_camera_source_picker_state.gd` - adds focused coverage that target dictionaries are deeply copied into a typed array.
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` - source-owned minimal fix so Boxing punch provider signals with a power payload can proxy through the no-argument input-core gameplay intent signals without runtime signal-call errors.
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - recorded this task and validation evidence.

**Status:** ✅ Implemented

**Results:** The typed target blocker is fixed: the recreated high-fidelity runner selected real Flow and Boxing song packages and loaded nonzero targets/target nodes without the prior typed-array script error (`Flow: 3 targets/3 target node groups`, `Boxing: 4 targets/4 target node groups`). The replay registration blocker is fixed in the runner-owned seam: replay source selection now starts/primes the `AeroCameraTracking` autoload with the selected MP4, passes the vendor Python runtime/entrypoint/model from the installed addon when available, injects the prepared tracking session into the camera provider before `InputManager` probes it, and preserves the selected replay path through active provider selection. The validation runner proved `camera_tracking` registers for both scenes with the selected local replay path as `get_active_provider_selected_camera_device_id()`. A small input-core owner fix was required after replay startup began emitting Boxing punch signals with power payloads; the manager now accepts and drops that optional payload while preserving the no-arg public signal contract.

Validation passed: GodotEnv sync, vendor runtime prep (`python3 scripts/prepare_vendor_runtime.py --json` in `aerobeat-vendor-mediapipe-python`), Godot import smoke, runner full GUT (`20` tests, `206` assertions), fresh non-headless Flow and Boxing scene opens with clean normal Godot/Vulkan output, recreated high-fidelity replay/song validation for Flow and Boxing, input-core full GUT (`41` tests, `442` assertions), class-name scan (`0` collisions), and `git diff --check` for both runner and input-core. Accepted exceptions: headless import still reports existing third-party GUT invalid UID fallback warnings and an ObjectDB leak warning on editor-import exit; the replay validation emits upstream MediaPipe/TFLite informational warnings and an ObjectDB/resource leak warning on scripted exit, but exits `0` with no runner script errors and no provider registration failure. `aerobeat-gameplay-runner-an1` remains open because the complete live/manual session gate still needs human-observed calibration, playback, overlays, audio/gameplay, hits/misses, recalibration, completion summary, environment display, and first-person cell observation.

---

### Task 8: Fix Gameplay Runner Testbed Startup Warnings and Errors

**Bead ID:** `aerobeat-gameplay-runner-3yf`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-13`
**Prompt:** Claim bead `aerobeat-gameplay-runner-3yf` on start. Read the runner README before touching the repo. Fix the startup warnings/errors Derrick reported after opening the gameplay runner testbed, using `REF-13` as the screenshot source. The parse errors show `aerobeat-tool-camera-tracking` preloads `res://addons/aerobeat-tool-camera-recording/src/manifest/SessionManifestV1.gd`, `src/validation/SavedSessionValidator.gd`, and `src/pose/PoseFrameRecord.gd`, but the runner `.testbed` does not restore `aerobeat-tool-camera-recording`. Make the source-owned dependency/import fix, not a generated `/addons/` edit. Investigate the GUT invalid UID fallback warnings too: fix them in the owning source if appropriate, or document why they remain an accepted third-party/vendor exception. Rerun GodotEnv sync, fresh Flow and Boxing gameplay runner testbed opens with editor/runtime log inspection, relevant GUT/import checks, class-name scan, and `git diff --check`. Update this plan and bead notes with changed files and validation evidence. Commit and push when the fix is complete. Leave parent bead `aerobeat-gameplay-runner-an1` open unless the complete manual/high-fidelity gate passes.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/addons.jsonc` - adds the missing local symlink-backed `aerobeat-tool-camera-recording` testbed dependency required by `aerobeat-tool-camera-tracking` replay backend preloads.
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - records Task 8 implementation, validation output, and accepted third-party/vendor exceptions.

**Status:** ✅ Implemented

**Results:** The runner-owned startup parse errors are fixed. `aerobeat-tool-camera-tracking` preloads `SessionManifestV1.gd`, `SavedSessionValidator.gd`, and `PoseFrameRecord.gd` from `res://addons/aerobeat-tool-camera-recording`; the runner `.testbed/addons.jsonc` now restores `aerobeat-tool-camera-recording` from the local sibling repo using the same symlink-backed manifest style as the other AeroBeat testbed dependencies. After `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo .testbed --install --scrub-uids`, Godot import registered `SessionManifestV1`, `PoseFrameRecord`, `SavedSessionValidator`, and `CameraRecordingManager`, and the prior camera-tracking preload/parse errors did not recur.

Validation passed: GodotEnv sync, headless import smoke, runner full GUT (`20` tests, `206` assertions), fresh non-headless Flow scene open with clean normal Godot/Vulkan output, fresh non-headless Boxing scene open with clean normal Godot/Vulkan output, class-name scan (`0` collisions; blocker=0, warn_embedded_overlap=0, warn_root_nonruntime=0, info_hidden_testbed=0), and `git diff --check`. Accepted exceptions: headless import still reports third-party `aerobeat-vendor-godot-unit-test` invalid UID fallback warnings for GUT editor UI scenes and a Godot ObjectDB import-exit leak warning. The GUT UID warnings are vendor-owned, fall back to valid text paths inside the third-party GUT addon, do not appear in fresh Flow/Boxing runtime opens, and are not hiding runner/tool parse errors after the camera-recording dependency restore. `aerobeat-gameplay-runner-an1` remains open because the complete live/manual session gate still needs human-observed calibration, playback, overlays, audio/gameplay sync, hits/misses, recalibration, completion summary, environment display, and first-person cell observation.

---

### Task 9: QA Gameplay Runner Testbed Startup Cleanup

**Bead ID:** `aerobeat-gameplay-runner-6xb`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-13`
**Prompt:** Claim bead `aerobeat-gameplay-runner-6xb` on start. Read the runner README before touching the repo. Verify commit `682aa90` fixed the gameplay runner testbed startup warnings/errors from Derrick's screenshot. Confirm GodotEnv restore includes `aerobeat-tool-camera-recording`, fresh Flow/Boxing opens no longer show camera-tracking preload/parse errors, runner GUT/import checks remain green, class-name scan remains clean, and any remaining GUT invalid UID/ObjectDB warnings are truthfully classified. Update this plan and bead notes with QA evidence, close the bead only if QA passes, and leave `aerobeat-gameplay-runner-an1` open unless the full manual/high-fidelity gate passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - records Task 9 QA evidence and pass decision.

**Status:** ✅ QA Passed

**Results:** QA passed at commit `682aa90`. The `.testbed/addons.jsonc` diff restores `aerobeat-tool-camera-recording` as a local sibling symlink dependency (`url: "../../aerobeat-tool-camera-recording"`, `source: "symlink"`, `subfolder: "/"`), and `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo .testbed --install --scrub-uids` resolved it from `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-recording` without requiring generated addon edits or pruning generated cache state. The installed symlink exposes the three screenshot-missing files at `res://addons/aerobeat-tool-camera-recording/src/manifest/SessionManifestV1.gd`, `src/validation/SavedSessionValidator.gd`, and `src/pose/PoseFrameRecord.gd`.

Validation passed: GodotEnv sync, `godot --headless --path .testbed --import --quit`, full runner GUT (`4` scripts, `20` tests, `206` assertions), fresh non-headless Flow open (`godot --path .testbed --scene res://scenes/flow_playable_testbed.tscn --quit-after 5`), fresh non-headless Boxing open (`godot --path .testbed --scene res://scenes/boxing_playable_testbed.tscn --quit-after 5`), `/home/derrick/.openclaw/workspace/scripts/scan-godot-class-names --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner` (`0` collisions; blocker=0, warn_embedded_overlap=0, warn_root_nonruntime=0, info_hidden_testbed=0), and `git diff --check`.

Targeted log inspection found no `SessionManifestV1`, `SavedSessionValidator`, `PoseFrameRecord`, camera-tracking preload, parse, script, or runner/tool errors in sync/import/GUT/Flow/Boxing logs. Remaining warnings are limited to the accepted third-party `aerobeat-vendor-godot-unit-test` invalid UID fallback lines during headless import plus Godot's ObjectDB import-exit leak warning; the UID warnings fall back to text paths inside the GUT vendor addon and are not present in fresh Flow/Boxing runtime opens. `aerobeat-gameplay-runner-an1` remains open because this QA did not run the full human-observed manual/high-fidelity gate.

---

### Task 10: Audit Gameplay Runner Testbed Startup Cleanup

**Bead ID:** `aerobeat-gameplay-runner-bvw`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-13`
**Prompt:** Claim bead `aerobeat-gameplay-runner-bvw` on start after `aerobeat-gameplay-runner-6xb` closes. Read the runner README before touching the repo. Independently audit the startup warning/error cleanup against the bead, plan, commit diff, dependency manifest, validation evidence, and repo status. Close only if startup parse errors are fixed without generated addon edits and remaining warnings are accepted/source-owned. Update plan/beads and push Beads as needed. Leave `aerobeat-gameplay-runner-an1` open unless the full manual/high-fidelity gate passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - records Task 10 audit evidence and pass decision.

**Status:** ✅ Audit Passed

**Results:** Audit passed at HEAD after QA commit `2287dd1`. Required startup was completed: README was read first, `bd prime` was run, bead `aerobeat-gameplay-runner-bvw` was claimed, and plan Tasks 8/9/10 plus beads `aerobeat-gameplay-runner-3yf` and `aerobeat-gameplay-runner-6xb` were reviewed. Repo status was clean and tracking `origin/main` with no ahead/behind markers. `git show --stat 682aa90` shows the source fix touched only `.testbed/addons.jsonc` and this plan; `git show --stat 2287dd1` shows QA evidence touched only this plan.

The fix is appropriate for runner ownership: `.testbed/addons.jsonc` restores `aerobeat-tool-camera-recording` from the local sibling repo with `url: "../../aerobeat-tool-camera-recording"`, `source: "symlink"`, and `subfolder: "/"`. No generated addon files are tracked (`git ls-files .testbed/addons` returned empty). The installed symlink exposes the screenshot-missing preload targets required by `aerobeat-tool-camera-tracking`: `SessionManifestV1.gd`, `SavedSessionValidator.gd`, and `PoseFrameRecord.gd`; targeted search confirmed `SessionManifestReplayBackend.gd` and `SavedSessionReplayBackend.gd` preload those exact paths.

QA evidence is sufficient for the startup cleanup scope. Task 9 and bead `aerobeat-gameplay-runner-6xb` record passing GodotEnv sync, headless import, full runner GUT (`4` scripts, `20` tests, `206` assertions), fresh non-headless Flow and Boxing opens, class-name scan with `0` collisions, and `git diff --check`. QA targeted log inspection found no `SessionManifestV1`, `SavedSessionValidator`, `PoseFrameRecord`, camera-tracking preload, parse, script, runner, or tool errors. The remaining GUT invalid UID fallback lines and Godot ObjectDB import-exit leak warning are accepted third-party/vendor/import-exit noise, do not appear in fresh Flow/Boxing runtime opens, and are not hiding the reported startup errors. `git diff --check` passed during audit. Bead `aerobeat-gameplay-runner-bvw` may close; parent `aerobeat-gameplay-runner-an1` remains open because the full human-observed manual/high-fidelity gate has not passed.

---

### Task 11: Clean GUT Vendor UID Warning Noise

**Bead ID:** `aerobeat-gameplay-runner-08f`
**SubAgent:** `primary` (for `coder` / `qa` / `auditor` workflow roles)
**Role:** `coder` → `qa` → `auditor`
**References:** `REF-01`, `REF-14`
**Prompt:** Claim bead `aerobeat-gameplay-runner-08f` on start. Read the runner README and the GUT vendor README before touching repos. Clean the remaining GUT vendor UID fallback warnings shown in `REF-14` at the owning source in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test`, not in generated runner `.testbed/addons/` state. Remove stale invalid external-resource UID references while preserving path/id scene references, refresh the runner testbed with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo .testbed --install --scrub-uids`, rerun import/GUT/fresh Flow and Boxing scene-open validation with log inspection, update the plan and bead with evidence, commit and push touched repos, then sync Cookie's AeroBeat repos after the fix lands.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/GutScene.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/UserFileViewer.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/gui/*.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/gui/GutSceneTheme.tres`
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - records the zero-noise cleanup task.

**Status:** ✅ QA passed after vendor ObjectDB follow-up cleanup.

**Results:** Coder removed stale `uid="uid://..."` attributes from all GUT vendor `.tscn`/`.tres` `ext_resource` lines while preserving `type`, `path`, and `id` references. The cleanup covered 50 external-resource references across `GutScene.tscn`, `UserFileViewer.tscn`, and the GUT `gui/` scenes/resource, including the REF-14 warning files (`GutScene.tscn`, `NormalGui.tscn`, `ResizeHandle.tscn`, `MinGui.tscn`, `RunExternally.tscn`).

QA verified the source fix is in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test` at HEAD `ddd52cd` (`Remove stale GUT ext_resource UIDs`), not in generated runner `.testbed/addons` state. `git show HEAD` removes 50 stale `uid="uid://..."` attributes from GUT `ext_resource` lines across 22 `.tscn`/`.tres` source files while preserving `type`, `path`, and `id`; `rg '^\\[ext_resource.*uid="uid://'` returns no matches in both the vendor source repo and the refreshed runner `.testbed/addons/aerobeat-vendor-godot-unit-test` copy.

QA validation ran `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo .testbed --install --scrub-uids`, `godot --headless --path .testbed --import --quit`, full runner GUT (`4` scripts, `20` tests, `206` assertions), fresh headless Flow scene open, fresh headless Boxing scene open, fresh non-headless Flow scene open, fresh non-headless Boxing scene open, and `git diff --check` in both runner and vendor repos. Targeted log inspection across sync/import/GUT/Flow/Boxing logs found no `invalid UID`, `Failed to load resource: UID`, `uid://`, parse, script, camera-tracking preload, or runner/tool error lines.

Initial QA could not pass because the required import log still emitted `WARNING: ObjectDB instances leaked at exit (run with --verbose for details).` A verbose import identified one leaked `SceneTreeTimer` with reference count `1`; the owning source was the GUT editor plugin startup path awaiting `get_tree().create_timer(1).timeout` in `aerobeat-vendor-godot-unit-test/gut_plugin.gd` while the headless import exited. The follow-up vendor source cleanup skips the editor-only update/timer startup path in headless mode and guards the optional update UI cleanup. After refreshing the runner `.testbed`, final targeted log inspection across sync/import/GUT/Flow/Boxing logs found no `invalid UID`, `Failed to load resource: UID`, `uid://`, warning, error, parse, script, camera-tracking preload, runner/tool, ObjectDB, resource leak, or leak lines. Cookie was then synced with `git-sync --all-aerobeat` and `godotenv-sync --all-aerobeat --install --scrub-uids`; Cookie's direct AeroBeat repo sweep checked 73 git repos and found all clean.

### Task 12: Clean Remaining ObjectDB Import-Exit Warning

**Bead ID:** `aerobeat-gameplay-runner-08f`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-14`
**Prompt:** Claim bead `aerobeat-gameplay-runner-08f` on start. Read the runner README before touching the repo. Investigate the remaining `WARNING: ObjectDB instances leaked at exit (run with --verbose for details).` from `godot --headless --path .testbed --import --quit` after the GUT UID cleanup. Run the import with verbose detail, identify the owning source if local cleanup is possible, fix it at the owning source rather than generated `.testbed/addons/` state, rerun the required import/GUT/fresh Flow and Boxing validation with log inspection, update this plan and bead with evidence, commit and push touched repos, and leave `aerobeat-gameplay-runner-an1` open unless the full human-observed Manual Validation Gate passes. If the warning is truly unavoidable upstream Godot behavior, do not close the bead; record exact evidence and escalate for Derrick's case-specific exception decision.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/gut_plugin.gd`
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - records Task 12 zero-noise evidence.

**Status:** ✅ Complete; zero-noise import validation restored.

**Results:** The remaining ObjectDB import-exit warning was source-owned by the GUT vendor editor plugin, not by generated runner `.testbed/addons/` state. Verbose import had identified one leaked `SceneTreeTimer` with reference count `1`; the owning source was `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-unit-test/gut_plugin.gd`, where `_enter_tree()` awaited `get_tree().create_timer(1).timeout` during headless editor import after `_should_continue_loading_gut()` created update-check UI state.

The vendor fix landed in `aerobeat-vendor-godot-unit-test` commit `99f1939` (`Skip GUT editor update timer in headless import`). It skips the optional update dialog/update-check path when `DisplayServer.get_name() == "headless"`, skips the one-second editor startup timer in headless import, and guards `_check_for_update` cleanup because that optional UI control is no longer instantiated in the headless path.

Validation on 2026-08-10 after fast-forwarding the local vendor checkout and refreshing the runner workbench passed:
- `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo .testbed --install --scrub-uids`: `1 ok, 0 failed`.
- `godot --headless --verbose --path .testbed --import --quit`: exit `0`; targeted scan found no `WARNING`, `ERROR`, `ObjectDB`, `leak`, `SceneTreeTimer`, UID fallback, parse, or script-error lines.
- Full runner GUT: `4` scripts, `20` tests, `206` assertions, all passed; targeted scan found no warning/error/leak/UID lines.
- Fresh headless Flow and Boxing scene opens: exit `0`; targeted scans clean.
- Fresh non-headless Flow and Boxing scene opens: first run warmed Godot renderer shader-cache directories and emitted shader-cache creation errors; immediate fresh rerun exited `0` for both scenes with only normal Godot/Vulkan output and clean targeted scans.
- `git diff --check` passed in both runner and `aerobeat-vendor-godot-unit-test`.

Bead `aerobeat-gameplay-runner-08f` is closed with the same owning-source evidence. Parent bead `aerobeat-gameplay-runner-an1` remains open because Task 12 did not perform the full human-observed Manual Validation Gate.

Cookie was also refreshed after the cleanup landed: AeroBeat git sync succeeded, GodotEnv sync reported `68 ok, 0 failed`, a generated `.testbed/project.godot` diff in Cookie's runner checkout was restored to synced state, and a final direct AeroBeat repo sweep reported 73 clean repos.

### Task 13: Focused Live-Camera Regression Scene Check

**Bead ID:** `aerobeat-gameplay-runner-an1`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-05`, `REF-08`
**Prompt:** Resume the active manual-gate bead and test the gameplay runner testbed scene path with a regression AeroBeat song package and the live camera path. Prefer the actual high-fidelity playable scenes if the legacy `gameplay_runner_testbed.tscn` scene is only a stub. Select live camera `0`, load matching BeatSaver regression song packages, attempt camera provider registration/calibration through the scene/harness path, inspect logs for unexpected warning/error/leak noise, and leave `aerobeat-gameplay-runner-an1` open unless true live-camera gameplay is fully proven.

**Folders Created/Deleted/Modified:**
- None durably.

**Files Created/Deleted/Modified:**
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md` - records this focused QA evidence.

**Status:** ⚠️ Partial; scene path clean, true camera capture hardware-blocked.

**Results:** Focused local QA on 2026-08-11 used a temporary probe, removed before handoff, to open the actual high-fidelity playable scene pair. The legacy `res://scenes/gameplay_runner_testbed.tscn` was confirmed to instantiate only `GameplayRunnerTestbed:Node`, so the meaningful scene path for this manual-gate regression is `res://scenes/flow_playable_testbed.tscn` and `res://scenes/boxing_playable_testbed.tscn`.

Validation ran non-headless with Godot `4.6.2.stable.official.71f334935` on X11/Vulkan. The Flow scene loaded `res://assets/songs/beatsaver_regression_pool/47fb6/song.package.yaml`, reported `content_ok=true`, built `3` targets and `3` target node entries, selected `Live camera: 0`, registered `camera_tracking` as the active provider, and loaded the image environment through the environment adapter. The Boxing scene loaded `res://assets/songs/beatsaver_regression_pool/3d44b/song.package.yaml`, reported `content_ok=true`, built `3` targets and `3` target node entries, selected `Live camera: 0`, registered `camera_tracking` as the active provider, and loaded the same image environment path.

The probe exited `0`, and targeted log scanning found no `WARNING`, `ERROR`, `SCRIPT ERROR`, `Parse Error`, `ObjectDB`, `leak`, or `resource` matches. Hardware inspection still found no `/dev/video*` or `/dev/media*` devices on this host, and `AeroCameraTracking` reported `devices=[]` with last error `no_live_cameras_found` / `No live camera candidates were found during MediaPipe Python probe`. Therefore true live-camera frames, T-pose success, playback start, hits/misses, recalibration, completion summary, and human-observed cell placement remain unproven. Parent bead `aerobeat-gameplay-runner-an1` remains open for the full manual/high-fidelity gate.

---

## Final Results

**Status:** ❌ Blocked / Waiting on Manual Test

**What We Built:** Frozen implementation plan plus independent readiness audit. Input-core and camera-tracking prerequisite seams are implemented, QA/audited, committed, and pushed. Runner implementation is committed and pushed, coder follow-up fixes for the static QA blockers are committed and pushed, and the static/headless QA retry passed. The stale runner camera/replay startup blocker was addressed by Task 4 in commit `987d1bd`; Task 5 QA retry passed at `c550f76`; Task 6 audit confirmed the code and runtime-open gates were clean but blocked final closure on live/manual proof. Task 7 fixed the later typed target and replay provider registration blockers in commits `0ff2522` and `3a12f49`, and recreated high-fidelity replay/song validation now passes for Flow and Boxing. Task 8 fixed the startup parse errors in the gameplay runner testbed by restoring the missing `aerobeat-tool-camera-recording` dependency required by `aerobeat-tool-camera-tracking` replay backends; fresh Flow and Boxing opens are clean. Tasks 11 and 12 cleaned the remaining GUT vendor UID and ObjectDB import-exit warning noise at the owning vendor source; zero-noise import, GUT, and fresh scene-open validation now passes. Task 13 confirmed the real playable scenes can load matching BeatSaver regression packages and register the live-camera provider path cleanly on this host, but true camera capture remains blocked because the OS exposes no camera device. Derrick confirmed the next step is manual testing and feedback in the next AeroBeat session. Environment-loader splat display remains tracked as environment-owned follow-up `aerobeat-tool-environment-1ds`.

**Reference Check:** Subagent reviews completed against referenced repos. The final readiness audit passed after freeze edits and closed `aerobeat-gameplay-runner-7l8`.

**Commits:**
- `c1bb79a` - Add playable Flow and Boxing testbeds
- `7d847a8` - Record playable testbed implementation handoff
- `076ca8e` - Record playable testbed QA blockers
- `e362153` - Fix playable testbed QA blockers
- `5abcd88` - Record playable testbed QA retry
- `04e300b` - Record playable testbed QA retry in plan
- `987d1bd` - Add playable camera source selection
- `c550f76` - Record camera source QA retry
- `2b59ee5` - Record camera source QA plan update
- `a0ffe8b` - Record final playable testbed audit blocker
- `0ff2522` - Fix playable replay startup blockers
- `3a12f49` - Accept boxing punch payloads in input manager

**Lessons Learned:** Static/headless coverage can prove the target mapping and overlay toggle regressions. Manual runtime validation needs source selection before provider startup, then a real playable session with selected camera/replay and fixtures to prove audio, calibration, overlays, and gameplay behavior. Environment-owned display gaps should stay separate from runner-owned camera/replay flow.

---

*Blocked on manual test feedback as of 2026-08-10*
