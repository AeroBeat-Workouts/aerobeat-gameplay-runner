# Playable Flow and Boxing Gameplay Testbeds

**Date:** 2026-08-02  
**Status:** Draft  
**Last Updated:** 2026-08-02 14:18 EDT  
**Blocked Reason:** Pending plan review and requirement freeze  
**Agent:** pico

---

## Goal

Build rudimentary first-person Godot developer testbed scenes for AeroBeat Flow and Boxing that prove real content, input calibration/tracking, audio timing, environment loading, gameplay runner dispatch, mode judgements, and hit/miss feedback in a playable loop.

---

## Overview

The existing gameplay runner smoke tests prove the non-visual contract path with generated inputs and a fake clock. This next slice should keep that contract coverage but add live Godot testbed scenes where a developer can choose an already-converted AeroBeat song package, choose a background environment, calibrate with the same T-pose flow used by the camera tracking testbeds, and play a rough first-person version of Flow or Boxing.

This is not a production gameplay shell. The target is a useful developer workbench with generated dummy visuals, simple hit effects, score/miss counters, completion summary, and enough spatial grounding to judge whether the gameplay feels promising. The implementation should reuse the input, environment, audio, content, runner, and mode repos instead of creating parallel local versions of those systems.

Spatial behavior must be grid-driven. The play area is defined by translating the authored gameplay grid and cell dimensions into world-space target positions. Camera start pose, movement limits, beat target paths, and obstacle placement must all respect that mapping rather than using an arbitrary 1 meter assumption.

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

---

## Frozen Requirements Candidate

### Scene Flow

1. Choose an already-converted AeroBeat song package from disk.
2. Choose a background environment from disk.
3. Stand in T-pose to calibrate and start the song.
4. During unpaused gameplay, activate the same T-pose calibration gesture to pause and enter recalibration/status mode.
5. Resume after recalibration using the same confirmed calibration flow unless plan review finds an existing better input-testbed precedent.
6. Play a hit sound on successful hits.
7. Track misses.
8. On completion, show successful hits and misses.

### Frozen Spatial Defaults Candidate

- The play area is derived from the authored grid dimensions and cell size, not from an arbitrary fixed 1 meter box.
- First implementation default is a 4x3 calibrated grid unless selected chart/package metadata explicitly provides a supported grid definition.
- Cell indices are row-major from bottom-left: `0..11`.
- Cell coordinates are derived as `col = cell_index % 4`, `row = floor(cell_index / 4)`.
- Godot world axes for the testbed are: `X = grid columns`, `Y = grid rows`, `Z = target travel depth`.
- The grid origin should align with the camera-tracking `gameplay_bottom_left` convention from `REF-04`.
- The runner `.testbed` owns a `PlayfieldMapper` helper that converts chart cells and calibrated nose positions into world-space positions.
- The `PlayfieldMapper` must explicitly define grid origin, cell width, cell height, target travel depth, target spawn distance, target hit plane, camera start position, and camera rotation.
- Initial camera candidate: camera rig starts centered on the grid, facing Godot forward `-Z` down the incoming target lane toward the hit plane, with fixed rotation during gameplay.
- Nose tracking maps continuously into world `X/Y`, not snapped to cells.
- Nose/camera movement clamps to the nearest valid in-grid world `X/Y` position once the athlete leaves calibrated grid bounds.
- Camera movement should move one gameplay rig or child camera rig consistently; implementation must not mix direct `Camera3D` movement with a separate player-rig offset.
- Movement range should stay within the playable grid unless plan review finds a mode-specific reason to allow margin beyond the grid.
- Flow beats and obstacles already define `placement`, `cells`, `startPlacement`, or `endPlacement`; those authored cells are the source of truth for target lanes and obstacle placement.
- Boxing charts do not currently carry authored cells. Boxing placement is semantic per event type for this testbed, not a chart-cell contract change.
- Boxing left punch targets use center row `1`, column `1`.
- Boxing right punch targets use center row `1`, column `2`.
- Boxing guard, squat, weave, or neutral prompts are non-scoring/status visuals unless the existing mode contract says otherwise; when visualized, they span center columns `1..2`.
- Do not add authored Boxing cell placement to content contracts in this slice.
- Left and right beat colors are black and white for the rudimentary testbed visuals.

### Mode-Specific Visualization

- Flow scene: render incoming beats and obstacles at their authored cells, moving toward the player/hit plane in first person.
- Boxing scene: render incoming boxing beats in the center row/center column region, with clear left/right black/white target distinction and simple punch hit feedback.
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
- The first environment slice accepts image and GLB environment assets by default. `.ogv` is optional only if review confirms the current environment stack supports it without broadening the slice.
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

1. What exact cell world width/height should the first playable testbed use when chart/package metadata does not provide it?
2. Where exactly is the hit plane relative to the camera start pose and grid origin?
3. What is the target spawn distance and travel time rule from chart beat time to visible approach?
4. Should successful recalibration auto-resume gameplay, or should gameplay require an explicit resume after calibration succeeds? Current recommendation: explicit resume to avoid accidental unpause.
5. Should the camera movement move the actual `Camera3D`, a parent player rig, or a child gameplay rig while keeping UI/environment camera behavior stable?
6. Are runner `.testbed` local `FileDialog` pickers acceptable for the first slice?
7. Should `.ogv` environments be accepted in the first slice, or should it stay image/GLB only?
8. What minimum manual/Godot runtime verification must pass before QA and audit: fresh scene open, camera feed live or explicit replay fallback, calibration pass, song load, environment load, gameplay start, hit/miss feedback, pause/recalibrate/resume, completion summary, and clean editor/runtime logs?

---

## Tasks

### Task 1: Plan Consistency and Freeze Review

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-10`  
**Prompt:** Review `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md` against the referenced AeroBeat repos. Do not implement code. Identify contradictions, missing decisions, likely repo-boundary mistakes, unclear contract assumptions, and anything that must be frozen before execution beads are created. Pay special attention to grid-to-world mapping, camera start pose/rotation, clamped nose tracking, Flow cell placement, Boxing center-lane placement, T-pose calibration/pause semantics, audio-clock ownership, hit SFX ownership, and environment package loading. Return concrete plan edits or questions.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Carson completed an independent plan review. Findings were folded into this plan: 4x3 row-major grid defaults, bottom-left origin, world axis mapping, `PlayfieldMapper` ownership, continuous nose-to-grid clamping, fixed camera rotation candidate, Flow authored-cell source of truth, semantic Boxing lanes, audio-clock adapter ownership, SFX slot ownership, environment loader/core/community boundaries, first-slice environment format limits, local `FileDialog` picker candidate, and stronger Godot validation requirements. Remaining freeze questions are listed above.

---

### Task 2: Freeze Build Plan After Review

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` / `auditor` workflow roles)  
**Role:** `research`  
**References:** `REF-01` through `REF-10`  
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
