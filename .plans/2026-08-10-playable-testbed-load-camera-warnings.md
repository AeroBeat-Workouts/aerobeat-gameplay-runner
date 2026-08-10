# AeroBeat Gameplay Runner Playable Testbed Load/Camera Warnings

**Date:** 2026-08-10  
**Status:** In Progress  
**Last Updated:** 2026-08-10 15:26 EDT  
**Blocked Reason:** None  
**Agent:** pico

---

## Goal

Clean up the warnings/issues seen when loading runner testbed songs/environments and attempting to start the live camera path.

---

## Overview

Derrick reported warnings/issues after the copied song and environment assets reached the gameplay-runner `.testbed/assets/` folder. The attached screenshots show two distinct classes of problems: visible runtime harness failures (`Song load failed: chart_for_mode_missing`, live camera status still at `0`) and Godot reload warnings from runner/addon scripts.

The first pass will preserve source ownership: runner testbed scripts may be edited in `aerobeat-gameplay-runner`, while addon warnings should be traced to their owning source repos before any durable fixes. The runner should make the copied assets easy to use in the playable scenes: song selection should guide or recover from wrong-mode packages, environment selection should support the copied YAML descriptors and local media paths, and live camera startup should produce clear status/errors rather than a silent/stale label.

Because this touches Godot runtime scenes, validation must include a fresh open of the affected playable scene(s), interaction with song/environment/live-camera paths in the highest-fidelity available environment, and inspection of editor/runtime logs. Zero unexpected warning/error noise remains the default gate unless Derrick grants a case-specific exception.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | User screenshot showing Godot reload warnings | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/08/10/image-3228139a.png` |
| `REF-02` | User screenshot showing song load/live camera runtime status | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/08/10/image-74ff1fc6.png` |
| `REF-03` | Runner playable harness scene/scripts | `.testbed/scenes/*playable_testbed.tscn`, `.testbed/scripts/` |
| `REF-04` | Copied runner testbed song/environment assets | `.testbed/assets/songs/`, `.testbed/assets/environments/` |
| `REF-05` | Source-owned content/environment/input/mode addons mounted by GodotEnv | sibling `aerobeat-*` source repos and runner `.testbed/addons/` |

---

## Tasks

### Task 1: Diagnose Load And Camera Failures

**Bead ID:** `aerobeat-gameplay-runner-k1f`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Use `primary` as the research role. Read the runner README before touching the repo. Claim bead `aerobeat-gameplay-runner-k1f` on start with `bd update aerobeat-gameplay-runner-k1f --claim`. Reproduce or trace the reported playable testbed failures from the screenshots: `chart_for_mode_missing`, environment load/picker issues, and live camera startup/status. Identify the owning source files/repos for each warning/error, distinguish runner UX defects from source-owned addon warnings, and record exact reproduction steps plus expected fixes. Do not make code changes in this research task. Close the bead on completion with `bd close aerobeat-gameplay-runner-k1f --reason="Diagnosis complete"`.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-10-playable-testbed-load-camera-warnings.md`

**Status:** ✅ Complete

**Results:** Research completed and bead closed 2026-08-10 15:25 EDT. Key findings:
- `chart_for_mode_missing` is runner-owned UX from strict scene-mode package loading; packages should expose available modes/difficulties and guide/filter selection instead of ending at an unclear failure.
- Runner environment picker/adapter accepts only direct media files today; copied YAML descriptors/workout YAML need runner handling, while `aerobeat-environment-loader` separately owns descriptor-relative `resourcePath` resolution.
- Live camera registration can succeed while tracking state reports `no_live_cameras_found`; runner status should surface camera list/readiness/last error and calibration should report the underlying provider error.
- Reload warnings split between runner-owned testbed script warnings and source-owned addon warnings; runner-owned cleanup belongs in Task 2 and source-owned cleanup remains Task 3.
- Validation during diagnosis: headless import passed and GUT passed `20/20` tests.

---

### Task 2: Fix Runner Testbed Song/Environment/Camera UX

**Bead ID:** `aerobeat-gameplay-runner-98n`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Use `primary` as the coder role. Read the runner README before touching the repo. Claim bead `aerobeat-gameplay-runner-98n` on start with `bd update aerobeat-gameplay-runner-98n --claim`. Implement the runner-owned fixes found by research: make copied song packages easy to load without unclear `chart_for_mode_missing` dead ends, make environment selection/load support the copied YAML environment descriptors and local media paths, and make live camera registration/startup report clear success/failure status. Add or update focused GUT coverage where practical. Run repo-local validation and a fresh Godot import/log pass. Commit and push runner changes before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/`

**Files Created/Deleted/Modified:**
- Runner-owned files determined by research.

**Status:** ✅ Complete

**Results:** Runner-owned implementation completed 2026-08-10. Changes made:
- Song loading still requires an exact scene-mode match, but `chart_for_mode_missing` now returns available chart modes/difficulties and the HUD tells the user to open the package in the matching playable scene. Successful loads include the selected difficulty in the HUD.
- Environment picker now accepts `.yaml`/`.yml` alongside direct media. Runner adapter routes `workout.yaml` through the workout bridge, loads direct environment descriptors, resolves descriptor-relative `resourcePath`/`configPath`, and still supports direct image/video/glb/splat media paths under `.testbed/assets/environments/`.
- Live camera registration/start/calibration messages now include `AeroCameraTracking` availability, tracking-session readiness, available cameras, and `get_last_error()` details. Calibration failure reports event/provider error details before the paused-playback note.
- Runner `.testbed/scripts` reload-warning cleanup covered source-shadowing preload names, typed input-manager loop variables, integer division in `PlayfieldMapper`, unused tick/result locals, shadowed `visible`, and runner ternary typing around camera diagnostics.
- Focused GUT coverage added for song mode/difficulty guidance and environment YAML/media request routing.

**Validation:**
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` passed: 25/25 tests, no orphan/leak warning output.
- `godot --headless --path .testbed --import` passed; `/tmp/aerobeat-runner-import.log` had no warning/error matches.
- `godot --headless --path .testbed --quit-after 2 res://scenes/flow_playable_testbed.tscn` passed; `/tmp/aerobeat-runner-flow-scene.log` had no warning/error matches.
- `godot --headless --path .testbed --quit-after 2 res://scenes/boxing_playable_testbed.tscn` passed; `/tmp/aerobeat-runner-boxing-scene.log` had no warning/error matches.

---

### Task 3: Clean Source-Owned Reload Warnings

**Bead ID:** `aerobeat-gameplay-runner-2sk`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-05`  
**Prompt:** Use `primary` as the coder role. Read the README for every owning source repo before edits. Claim bead `aerobeat-gameplay-runner-2sk` on start with `bd update aerobeat-gameplay-runner-2sk --claim`. Fix the source-owned Godot reload warnings visible from the runner playable scene, including duplicate global-class preload constant names, untyped loop variables where practical, unused locals/members, shadowed `visible`, integer division, and incompatible ternary typing. Edit only owning source repos, refresh runner addon state with `/workspace/scripts/godotenv-sync`, and keep generated addon copies out of source commits except via normal sync state when required. Run relevant repo tests/imports and commit/push all durable source repo changes before handoff.

**Folders Created/Deleted/Modified:**
- Source repo folders determined by research.
- Runner `.testbed/addons/` via canonical sync only if required.

**Files Created/Deleted/Modified:**
- Source-owned warning files determined by research.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: QA Playable Scene Workflows

**Bead ID:** `aerobeat-gameplay-runner-0rg`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Use `primary` as the QA role. Read the runner README before touching the repo. Claim bead `aerobeat-gameplay-runner-0rg` on start with `bd update aerobeat-gameplay-runner-0rg --claim`. Verify the fixed playable scenes in the highest-fidelity available environment: load one flow song package in the flow scene, one boxing song package in the boxing scene, load representative image/video/glb/splat environment descriptors, select live camera, attempt calibration/provider registration, stop playback with editor controls, and inspect fresh editor/runtime logs. Fail QA for unexpected warning/error noise, unclear status, or missing evidence.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-10-playable-testbed-load-camera-warnings.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Independent Audit And Sync

**Bead ID:** `aerobeat-gameplay-runner-4r0`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Use `primary` as the auditor role. Read the runner README before touching the repo, and read source repo READMEs for any source-owned diffs. Claim bead `aerobeat-gameplay-runner-4r0` on start with `bd update aerobeat-gameplay-runner-4r0 --claim`. Independently verify the plan, beads, diffs, commits, validation output, Godot fresh-open/runtime-log evidence, and Cookie sync evidence. Close the bead only if the screenshots' issues are genuinely addressed and required logs are zero-noise. If it passes, ensure final commits are pushed, `bd dolt push` succeeds, Cookie is synced with runner/source changes, and the completed plan is archived.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-10-playable-testbed-load-camera-warnings.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on pending*
