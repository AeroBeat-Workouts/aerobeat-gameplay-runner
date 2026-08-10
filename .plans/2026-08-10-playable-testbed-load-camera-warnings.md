# AeroBeat Gameplay Runner Playable Testbed Load/Camera Warnings

**Date:** 2026-08-10  
**Status:** In Progress  
**Last Updated:** 2026-08-10 15:57 EDT  
**Blocked Reason:** Task 4 QA is blocked/failed on live-camera hardware and runtime noise; no `/dev/video*` devices are available, and camera provider registration/unregistration produced unexpected error noise during the playable workflow probe.
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
- `../aerobeat-content-core/validators/`, `../aerobeat-content-core/tests/`
- `../aerobeat-environment-core/src/contracts/`
- `../aerobeat-environment-loader/src/`, `../aerobeat-environment-loader/.testbed/tests/`
- `../aerobeat-mode-core/src/data_types/`
- `../aerobeat-mode-boxing/src/`
- `../aerobeat-mode-flow/src/`
- `../aerobeat-vendor-gdgs/src/importers/decoders/`, `../aerobeat-vendor-gdgs/src/runtime/render/`
- Runner `.testbed/addons/` refreshed with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync`; no tracked runner sync changes.

**Files Created/Deleted/Modified:**
- `../aerobeat-content-core/validators/content_package_validator.gd`
- `../aerobeat-content-core/tests/test_beatsaver_regression_fixtures.gd`
- `../aerobeat-content-core/tests/test_chart_event_contract.gd`
- `../aerobeat-content-core/tests/test_content_manifest_contract.gd`
- `../aerobeat-content-core/tests/test_content_mode_contract.gd`
- `../aerobeat-content-core/tests/test_content_reference_validation.gd`
- `../aerobeat-content-core/tests/test_environment_contract.gd`
- `../aerobeat-content-core/tests/test_legacy_package_contract.gd`
- `../aerobeat-content-core/tests/test_song_package_yaml_contract.gd`
- `../aerobeat-content-core/tests/test_song_preview_audio_contract.gd`
- `../aerobeat-content-core/tests/test_song_timing_validation.gd`
- `../aerobeat-environment-core/src/contracts/data_types/environment_error.gd`
- `../aerobeat-environment-core/src/contracts/data_types/environment_media_config.gd`
- `../aerobeat-environment-core/src/contracts/data_types/environment_operation.gd`
- `../aerobeat-environment-core/src/contracts/data_types/environment_progress.gd`
- `../aerobeat-environment-core/src/contracts/data_types/environment_request.gd`
- `../aerobeat-environment-core/src/contracts/data_types/environment_result.gd`
- `../aerobeat-environment-core/src/contracts/interfaces/environment_fulfillment.gd`
- `../aerobeat-environment-core/src/contracts/interfaces/environment_kind_handler.gd`
- `../aerobeat-environment-core/src/contracts/validators/environment_request_validator.gd`
- `../aerobeat-environment-loader/src/AeroEnvironmentLoader.gd`
- `../aerobeat-environment-loader/src/AeroWorkoutYamlEnvironmentBridge.gd`
- `../aerobeat-environment-loader/.testbed/tests/test_AeroEnvironmentLoader.gd`
- `../aerobeat-environment-loader/.testbed/tests/test_example.gd`
- `../aerobeat-mode-core/src/data_types/mode_descriptor.gd`
- `../aerobeat-mode-core/src/data_types/mode_fixture_case.gd`
- `../aerobeat-mode-core/src/data_types/mode_run_fragment.gd`
- `../aerobeat-mode-core/src/data_types/mode_tick_frame.gd`
- `../aerobeat-mode-boxing/src/boxing_mode_runner.gd`
- `../aerobeat-mode-flow/src/flow_mode_runner.gd`
- `../aerobeat-vendor-gdgs/src/importers/decoders/compressed_ply_decoder.gd`
- `../aerobeat-vendor-gdgs/src/importers/decoders/sog_decoder.gd`
- `../aerobeat-vendor-gdgs/src/runtime/render/gaussian_scene_registry.gd`

**Status:** ✅ Complete

**Results:** Source-owned warning cleanup completed and pushed 2026-08-10 16:05 EDT. Changes made:
- Removed duplicate global-class preload constant warnings by renaming script preloads in content core, environment core, Boxing, and Flow.
- Added static types to reload-visible generic iterators in content, environment loader, mode core, Boxing, and Flow.
- Fixed integer-division warnings in environment loader splat estimates and GDGS compressed/sog decoder indexing.
- Renamed GDGS `NodeEntry.visible` state to `is_visible` to avoid shadowing engine visibility.
- Made environment-loader device detection optional without hardcoded missing-script load noise when no `AeroDeviceDetection` autoload/addon exists.
- Added descriptor-relative environment `resourcePath`/`configPath` resolution with package-root fallback, plus focused loader coverage.
- Updated environment-loader manifest test expectations for the already-committed `aerobeat-tool-headless-manager` dependency so the repo-local suite remains exact and passing.

**Commits Pushed:**
- `aerobeat-content-core` `86ec83a` - Clean content reload warnings
- `aerobeat-environment-core` `de2e66b` - Clean environment contract reload warnings
- `aerobeat-environment-loader` `27db7a9` - Clean environment loader warnings
- `aerobeat-mode-core` `89087c4` - Clean mode core reload warnings
- `aerobeat-mode-boxing` `64e85e1` - Clean boxing mode reload warnings
- `aerobeat-mode-flow` `1a40756` - Clean flow mode reload warnings
- `aerobeat-vendor-gdgs` `f3ffe4d` - Clean gdgs reload warnings

**Validation:**
- Source repo imports/tests:
  - `aerobeat-content-core`: import passed; `godot --headless --path .testbed --script res://../tests/run_contract_tests.gd` passed all contract cases.
  - `aerobeat-environment-core`: import passed; GUT passed 17/17 tests.
  - `aerobeat-environment-loader`: import passed; GUT passed 42/42 tests, including new descriptor-relative path coverage.
  - `aerobeat-mode-core`: import passed; GUT passed 5/5 tests.
  - `aerobeat-mode-boxing`: import passed; GUT passed 7/7 tests.
  - `aerobeat-mode-flow`: import passed; GUT passed 9/9 tests.
  - `aerobeat-vendor-gdgs`: import passed in its `.testbed`.
- Runner dependency refresh: `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner` completed `ok`; no tracked runner addon changes.
- Runner GUT: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` passed 25/25 tests.
- Runner fresh import: `godot --headless --path .testbed --import` passed.
- Runner scene logs:
  - `godot --headless --path .testbed --quit-after 2 res://scenes/flow_playable_testbed.tscn` passed.
  - `godot --headless --path .testbed --quit-after 2 res://scenes/boxing_playable_testbed.tscn` passed.
  - Final log scan found no `WARNING`, `ERROR`, `SCRIPT ERROR`, `Parse Error`, leak/orphan/failed noise in the final source and runner validation logs.

**Remaining source-owned warnings:** None found in the runner playable-scene validation path.

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

**Status:** ❌ Blocked / Failed QA

**Results:** QA attempted 2026-08-10 15:57 EDT and the bead remains open. Evidence:
- Highest-fidelity available runtime path was a non-headless Godot run on X11/Vulkan (`godot --path .testbed --script res://qa_playable_workflow_probe.gd` using a temporary QA probe that was removed after capture). The probe loaded:
  - Flow scene `res://scenes/flow_playable_testbed.tscn` with `res://assets/songs/beatsaver_regression_pool/47fb6/song.package.yaml`: HUD reported `Loaded flow Normal chart with 3 events`.
  - Boxing scene `res://scenes/boxing_playable_testbed.tscn` with `res://assets/songs/beatsaver_regression_pool/3d44b/song.package.yaml`: HUD reported `Loaded boxing Normal chart with 3 events`.
  - Environment descriptors `ab-environment-image-demo.yaml`, `ab-environment-video-demo.yaml`, `ab-environment-glb-demo.yaml`, and `ab-environment-splat-demo.yaml`: HUD reported `Environment ready: image`, `Environment ready: video`, `Environment ready: glb`, and `Environment ready: splat` in both scenes.
  - Live camera selection `0` and calibration attempt in both scenes: HUD reported `Calibration request unavailable. AeroCameraTracking ready: yes. Cameras: none reported. Last error: No live camera candidates were found during MediaPipe Python probe`.
- Hardware blocker: `find /dev -maxdepth 2 \( -name 'video*' -o -name 'media*' \) -print` and `ls -l /dev/video*` returned no live camera devices, so a real camera provider/calibration pass could not be validated.
- Unexpected warning/error noise blocks QA under the zero-noise gate:
  - `/tmp/aerobeat-runner-qa-playable-probe-cleanup.log` ended with `WARNING: ObjectDB instances leaked at exit` and `ERROR: 7 resources still in use at exit` after live-camera provider registration was attempted.
  - `/tmp/aerobeat-runner-qa-playable-probe-final.log` showed that calling the scene's normal provider unregister path after registration emits repeated `ERROR: Cannot disconnect from '<signal>': the provided callable is null` from `res://addons/aerobeat-input-core/src/input_manager.gd:507`, followed by the same leak/resource errors.
- Clean baseline validation still passed:
  - `godot --headless --path .testbed --import > /tmp/aerobeat-runner-qa-import.log 2>&1` exited 0; noise scan found no warning/error matches.
  - `godot --headless --path .testbed --script res://addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit > /tmp/aerobeat-runner-qa-gut.log 2>&1` exited 0; 25/25 tests passed; noise scan found no warning/error matches.
  - `godot --path .testbed --quit-after 2 res://scenes/flow_playable_testbed.tscn > /tmp/aerobeat-runner-qa-flow-runtime.log 2>&1` exited 0; noise scan found no warning/error matches.
  - `godot --path .testbed --quit-after 2 res://scenes/boxing_playable_testbed.tscn > /tmp/aerobeat-runner-qa-boxing-runtime.log 2>&1` exited 0; noise scan found no warning/error matches.
- Editor-control stop evidence is missing because the Godot editor-control MCP tool was not available in this subagent session; runtime scene launch/quit evidence is included above, but this does not satisfy the requested editor play/stop workflow.

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
