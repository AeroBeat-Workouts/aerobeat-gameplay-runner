# Gameplay Runner And Mode Rule-Engine Implementation

**Date:** 2026-08-02  
**Status:** In Progress  
**Last Updated:** 2026-08-02 10:14 EDT  
**Blocked Reason:** None  
**Agent:** pico

---

## Goal

Implement the frozen AeroBeat gameplay architecture through the existing mode-core, input-core, runner, Boxing, Flow, content, and runner testbed beads.

---

## Overview

The architecture-freeze wave is complete and archived. The frozen direction is that `aerobeat-gameplay-runner` owns session orchestration, timeline dispatch, pause/resume/retry, result envelopes, event fanout, fake input/testbed transport, and aggregation. `aerobeat-mode-core` owns portable mode contracts and mode-produced fragments. Boxing and Flow repos own pure rule engines; they do not own product UI, camera providers, raw landmark processing, or assembly composition.

This implementation wave should reduce risk by landing the shared contract seams first. `aerobeat-mode-core` adds the portable mode DTO/interface minimum, while `aerobeat-input-core` corrects Boxing punch events to no-arg active signals. Runner, Boxing, and Flow then adopt those seams independently before the runner `.testbed` composes them with content fixtures.

The first implementation beads already exist from the previous session. Some adjacent repo Beads remotes still need sync repair before their local bead state can be pushed: mode-core has no Beads Dolt `origin`, and input-core, mode-boxing, mode-flow, and content-core reported Dolt `no common ancestor`. Do not force-push bead state; preserve both local and remote issue history.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Frozen gameplay architecture discussion | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/.plans/archive/2026-08-01-aerobeat-gameplay-architecture-resume.md` |
| `REF-02` | Completed runner/mode rule-engine planning freeze | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/archive/2026-08-01-gameplay-runner-mode-rule-engine-wave.md` |
| `REF-03` | Latest canonical handoff | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-08-01T22-31-48-04-00-aerobeat.md` |
| `REF-04` | Gameplay runner package | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/README.md` |
| `REF-05` | Gameplay runner source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/` |
| `REF-06` | Shared mode contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/README.md` |
| `REF-07` | Input-core Boxing contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/boxing_input.gd` |
| `REF-08` | Input manager Boxing signal mirror | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` |
| `REF-09` | Boxing mode repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-boxing/README.md` |
| `REF-10` | Flow mode repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-flow/README.md` |
| `REF-11` | Content contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md` |
| `REF-12` | Audio clock source repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-audio-player/README.md` |
| `REF-13` | GodotEnv sync helper | `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` |
| `REF-14` | AeroBeat GodotEnv convention contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/godotenv-convention-contract.md` |

---

## Frozen Implementation Rules

- `aerobeat-mode-core` owns `ModeDescriptor`, `ModeRunConfig`, `ModeRunner`, `ModeTickFrame`, `ModeEvent`, `ModeJudgementEvent`, `ModeScoreDelta`, `ModeRunFragment`, and `ModeFixtureCase` or their repo-conventional equivalents.
- `aerobeat-gameplay-runner` owns `GameplayRunConfig`, `GameplayRunState`, `GameplayRunResult`, `GameplaySession`, `GameplayTimelineClock`, `GameplayInputStream`, event dispatch/history, score aggregation, fake streams, and `.testbed` transport.
- Boxing punch signals are exact no-arg active events: `straight_left`, `straight_right`, `uppercut_left`, `uppercut_right`, `hook_left`, and `hook_right`.
- Boxing v1 must not add punch `power`, `strength`, scalar intensity, confidence, velocity, detector score, or explicit `active` booleans.
- Flow v1 primarily consumes `BodyCellInput` events: `left_wrist_cell_entered(cell, direction)`, `right_wrist_cell_entered(cell, direction)`, `nose_cell_entered(cell, direction)`, and `calibration_session_updated(session)`, plus optional Flow squat transitions.
- Runner production clock consumption is limited to `reset()`, `get_position_sec()`, `get_duration_sec()`, `get_state()`, and `is_complete()`. Audio timing truth remains in `aerobeat-tool-audio-player`.
- Tiny contract/rule fixtures land before BeatSaver-derived regression fixtures. BeatSaver fixtures use Derrick's approved pool from `REF-02`.
- GodotEnv dependency manifest or installed-addon updates must use the workspace sync helper from `REF-13`, targeting the repo or `.testbed` project root being changed. Use the helper's safe default path unless the plan/bead explicitly calls for `--dry-run`, `--refresh-caches`, or another documented option; do not manually patch generated installed addon state or rely on raw `godotenv addons install` as the primary update path.

---

## Tasks

### Task 1: Repair Beads Sync Readiness

**Bead ID:** `afc-r7s`, `aerobeat-input-core-9r2`, `aerobeat-mode-boxing-0ui`, `aerobeat-mode-flow-bsb`, `aerobeat-content-core-gyn`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Claim or update the relevant Beads sync repair bead(s) at start where possible. In the `research` role on `primary`, inspect Beads Dolt configuration/status for `aerobeat-mode-core`, `aerobeat-input-core`, `aerobeat-mode-boxing`, `aerobeat-mode-flow`, and `aerobeat-content-core`. Determine the non-destructive repair path for mode-core missing remote and the no-common-ancestor repos. Do not force-push or discard local/remote bead state. Report exact commands that are safe to run, any commands actually run, and final sync status. Leave implementation beads untouched unless sync repair directly requires metadata updates.

**Folders Created/Deleted/Modified:**
- Pending

**Files Created/Deleted/Modified:**
- Pending

**Status:** ✅ Complete

**Results:** PASS. `primary` SubAgent repaired Beads sync readiness non-destructively across all five repos. `aerobeat-mode-core` now has its Beads Dolt `origin` remote configured, the no-common-ancestor repos were repaired by preserving local JSONL exports and backup Dolt branches before unioning local issue history into remote-based history, and `bd dolt push` now succeeds for all five repos. Sync repair beads `afc-r7s`, `aerobeat-input-core-9r2`, `aerobeat-mode-boxing-0ui`, `aerobeat-mode-flow-bsb`, and `aerobeat-content-core-gyn` were closed. Implementation beads remained open. Parent verification confirmed `bd dolt push` succeeds in `aerobeat-mode-core`, `afc-r7s` is closed, and `afc-z8o` remains open.

---

### Task 2: Implement Portable Mode-Core Contracts

**Bead ID:** `afc-z8o`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-06`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `afc-z8o` with `bd update afc-z8o --claim --json` at start. In the `coder` role on `primary`, implement the approved portable mode-core v1 contract minimum: mode descriptor/config, mode runner lifecycle, tick frame, mode event/judgement/score/run fragments, and tiny contract fixtures/tests using repo-local conventions. Keep session envelopes, clocks, fake streams, testbed transport, camera/provider debug payloads, and assembly concerns out of mode-core. If dependency manifests or installed GodotEnv addon state must change, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo <repo-or-testbed-root>` per `REF-13`/`REF-14` and report the exact target. Run relevant repo tests and validation, perform any required Godot fresh-open/log pass if runtime scenes or Godot UI paths are touched, then commit and push. Do not close the bead unless the implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/.gitignore`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/.testbed/project.godot`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/.testbed/tests/test_mode_core_contract.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/plugin.cfg`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/plugin.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/src/AeroModeCore.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/src/data_types/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/src/interfaces/mode_runner.gd`

**Status:** ✅ Complete

**Results:** PASS pending QA/audit. `primary` coder implemented portable mode-core v1 contracts and tiny GUT fixtures in commit `e0027f811f9dfbd91256c9d8fe40f5c8ea3f0de8`, pushed to `main`. GodotEnv sync was run with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core`. Validation reported by coder and repeated by Pico: `godot --headless --path .testbed --import` passed, and GUT passed 5/5 tests with 26 assertions. Scope scan found only expected runner-agnostic contract language and explicit exclusions for session envelopes, clocks, fake input streams, testbed transport, camera/provider payloads, raw landmarks, UI, and assembly. Bead `afc-z8o` remains `in_progress` for QA/audit.

---

### Task 3: QA Mode-Core Contracts

**Bead ID:** `afc-z8o`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-06`  
**Prompt:** With bead `afc-z8o` still active, perform an independent QA pass on the mode-core contract implementation. Verify the new contracts match the frozen ownership rules, fixtures/tests exercise the contract seam, no runner/session/clock/testbed transport concerns leaked into mode-core, and the coder's validation evidence is real. Run the highest-fidelity repo validation available and repeat the Godot fresh-open/log pass if relevant. Report pass/fail with exact evidence; do not close the bead.

**Folders Created/Deleted/Modified:**
- Pending

**Files Created/Deleted/Modified:**
- Pending

**Status:** ✅ Complete

**Results:** PASS. `primary` QA independently reviewed the plan, references, bead, commit `e0027f811f9dfbd91256c9d8fe40f5c8ea3f0de8`, contract files, and fixtures. QA reran `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core`, `godot --headless --path .testbed --import`, and GUT, all passing. QA confirmed mode-core owns only portable mode DTOs/interfaces and mode-produced fragments; no forbidden runner/session/clock/fake-stream/testbed-transport/camera/raw-landmark/UI/assembly/product aggregation concerns leaked into public `src`. QA added evidence to bead notes and left `afc-z8o` in progress for audit.

---

### Task 4: Audit Mode-Core Contracts

**Bead ID:** `afc-z8o`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-06`  
**Prompt:** Independently audit bead `afc-z8o` against the plan, freeze references, diff, and validation output. If complete, close `afc-z8o` with `bd close afc-z8o --reason "Implemented, QA verified, and audited against frozen mode-core contract scope" --json`. If not complete, leave it open and report the exact gap.

**Status:** ✅ Complete

**Results:** PASS. `primary` auditor independently audited `afc-z8o` against the active plan, frozen references, bead notes, coder commit `e0027f811f9dfbd91256c9d8fe40f5c8ea3f0de8`, implementation diff, and QA evidence. Auditor reran GodotEnv sync, headless import, and GUT; validation passed with 5/5 tests and 26 assertions. Auditor confirmed no forbidden runner/session/clock/fake-stream/testbed-transport/camera/raw-landmark/UI/assembly/product aggregation concerns leaked into public contracts. `afc-z8o` was closed with reason `Implemented, QA verified, and audited against frozen mode-core contract scope`, and `bd dolt push` completed. Parent verification confirmed the bead is closed and mode-core is clean.

---

### Task 5: Correct Input-Core Boxing Punch Signals

**Bead ID:** `aerobeat-input-core-6xl`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `aerobeat-input-core-6xl` with `bd update aerobeat-input-core-6xl --claim --json` at start. In the `coder` role on `primary`, update `BoxingInput` and `InputManager` proxy punch signals/callbacks to exact no-arg active events for straight/hook/uppercut left/right. Remove power/scalar forwarding and do not add active booleans or intensity fields. Update focused tests/docs where available. If dependency manifests or installed GodotEnv addon state must change, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo <repo-or-testbed-root>` per `REF-13`/`REF-14` and report the exact target. Run repo validation, perform any required Godot fresh-open/log pass if runtime scenes or Godot UI paths are touched, then commit and push. Do not close the bead unless implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/boxing_input.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/test_boxing_input_contract.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/scenes/test_scene.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/*.uid`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/unit/*.uid`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/body_cell_input.gd.uid`

**Status:** ✅ Complete

**Results:** PASS pending QA/audit. `primary` coder implemented no-arg Boxing punch signals in commit `e03795fb40e181245ea447ef84e5087d692e9828`, then a coder cleanup follow-up committed generated Godot script UID files in `8aedd7b` so headless import no longer emits missing-UID warnings. Signals/proxies now use exact no-arg active events for `straight_left`, `straight_right`, `uppercut_left`, `uppercut_right`, `hook_left`, and `hook_right`; punch `power` forwarding was removed. GodotEnv sync was run with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`. Validation reported by coder and repeated by Pico: `godot --headless --path .testbed --import` passed cleanly, GUT passed 5/5 tests with 16 assertions, and `godot --headless --path .testbed res://scenes/test_scene.tscn --quit-after 1` loaded cleanly. Bead remains `in_progress` for QA/audit.

---

### Task 6: QA Input-Core Punch Correction

**Bead ID:** `aerobeat-input-core-6xl`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`  
**Prompt:** With bead `aerobeat-input-core-6xl` still active, independently verify the Boxing punch signals and proxies are exact no-arg active events and no v1 punch scalar/active boolean leaked into contracts, tests, or docs. Run the highest-fidelity repo validation available and repeat the Godot fresh-open/log pass if relevant. Report pass/fail; do not close the bead.

**Status:** ✅ Complete

**Results:** PASS. `primary` QA independently reviewed the active plan, frozen references, bead notes, commits `e03795fb40e181245ea447ef84e5087d692e9828` and `8aedd7b`, current BoxingInput/InputManager files, focused GUT tests, and test scene text. QA verified all six Boxing punch events and InputManager proxies are exact no-arg active signals, no v1 punch scalar/active boolean leaked into the Boxing seam/tests/docs, and remaining confidence/velocity/intensity mentions belong to separate provider/UI/haptic surfaces. QA reran GodotEnv sync, clean headless import, GUT 5/5 with 16 assertions, and test scene load with no warnings/errors. QA evidence was added to bead notes and pushed; bead remains in progress for audit.

---

### Task 7: Audit Input-Core Punch Correction

**Bead ID:** `aerobeat-input-core-6xl`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`  
**Prompt:** Independently audit bead `aerobeat-input-core-6xl` against the plan, freeze references, diff, and validation output. If complete, close `aerobeat-input-core-6xl` with `bd close aerobeat-input-core-6xl --reason "Implemented, QA verified, and audited against frozen no-arg Boxing input contract" --json`. If not complete, leave it open and report the exact gap.

**Status:** ✅ Complete

**Results:** PASS. `primary` auditor independently audited the input-core no-arg Boxing punch contract against the active plan, frozen references, implementation diffs, QA evidence, and validation output. Auditor confirmed BoxingInput and InputManager expose/forward exact no-arg `straight_left`, `straight_right`, `uppercut_left`, `uppercut_right`, `hook_left`, and `hook_right` signals, with no punch power/strength/scalar intensity/confidence/velocity/detector score/explicit active boolean leaks in the Boxing seam/tests/docs. Auditor reran GodotEnv sync, clean headless import, GUT 5/5 with 16 assertions, and the touched test scene load/log pass with no warnings/errors. `aerobeat-input-core-6xl` was closed with reason `Implemented, QA verified, and audited against frozen no-arg Boxing input contract`, and `bd dolt push` completed. Parent verification confirmed the bead is closed and input-core is clean.

---

### Task 8: Adopt Contracts In Gameplay Runner

**Bead ID:** `aerobeat-gameplay-runner-snf`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-12`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `aerobeat-gameplay-runner-snf` with `bd update aerobeat-gameplay-runner-snf --claim --json` at start, after `afc-z8o` and `aerobeat-input-core-6xl` are complete. In the `coder` role on `primary`, adopt the new mode-core mode runner/event/judgement/score fragments, switch `GameplayTimelineClock` production seam to `reset/get_position_sec/get_duration_sec/get_state/is_complete`, add runner-owned fake input stream envelopes that mirror input-core signal contracts, and cover lifecycle, dispatch order, terminal states, and aggregation with focused tests. Keep audio clock truth in `aerobeat-tool-audio-player` and keep fake clocks as runner test infrastructure. If `.testbed/addons.jsonc` or installed GodotEnv addon state must change, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed` per `REF-13`/`REF-14` and report the exact command. Run repo validation and Godot fresh-open/log inspection for the `.testbed` or runtime scene seam if touched, then commit and push. Do not close the bead unless implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/tests/test_gameplay_runner_contract.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/tests/support/fake_gameplay_clock.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/tests/support/fake_gameplay_clock.gd.uid`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/tests/support/fake_gameplay_input_stream.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/tests/support/fake_gameplay_input_stream.gd.uid`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/AeroGameplayRunner.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/data_types/gameplay_run_config.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/data_types/gameplay_run_result.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/interfaces/gameplay_input_stream.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/interfaces/gameplay_mode_runner.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/interfaces/gameplay_timeline_clock.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/runtime/gameplay_event_dispatcher.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/runtime/gameplay_score_aggregator.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/runtime/gameplay_session.gd`

**Status:** ✅ Complete

**Results:** PASS pending QA/audit. `primary` coder adopted mode-core contracts in commit `bd0bf616b475b27ea012b3dded168b5b607ec2af`, pushed to `main`. Runner now derives `ModeRunConfig`, ticks mode runners with `ModeTickFrame`, captures `ModeRunFragment`, `ModeJudgementEvent`, and `ModeScoreDelta`, and wraps those fragments into runner-owned session/result envelopes. `GameplayTimelineClock` production consumption is narrowed to `reset()`, `get_position_sec()`, `get_duration_sec()`, `get_state()`, and `is_complete()`, with `advance()` retained only on the fake test clock. Runner-owned fake input stream envelopes now mirror input-core contracts, including no-arg Boxing punch events. GodotEnv sync was run with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed`. Validation reported by coder: headless import passed with accepted vendored GUT invalid-UID warnings and headless ObjectDB leak warning, GUT passed 4/4 tests with 50 assertions, and `.testbed` scene load passed cleanly. Parent verification confirmed `bd0bf61` is the pushed `main` tip, runner git is clean, and bead `aerobeat-gameplay-runner-snf` remains `in_progress` for QA/audit.

---

### Task 9: QA Gameplay Runner Contract Adoption

**Bead ID:** `aerobeat-gameplay-runner-snf`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-12`  
**Prompt:** With bead `aerobeat-gameplay-runner-snf` still active, independently verify runner contract adoption, sampled clock behavior, fake input envelope fidelity, lifecycle/dispatch/terminal state/aggregation tests, and no mode-core ownership leakage. Run the highest-fidelity repo validation available and repeat fresh Godot scene-open/log inspection for the `.testbed` or runtime seam if touched. Report pass/fail; do not close the bead.

**Status:** ✅ Complete

**Results:** PASS. `primary` QA independently reviewed the active plan refs `REF-01`/`REF-02`/`REF-04`/`REF-05`/`REF-12`, bead state, implementation commit `bd0bf616b475b27ea012b3dded168b5b607ec2af`, and current runner files/tests. QA verified runner adoption of `ModeRunConfig`, `ModeTickFrame`, `ModeRunFragment`, `ModeJudgementEvent`, and `ModeScoreDelta`; runner-owned session/result envelopes; sampled production clock usage limited to `reset()`, `get_position_sec()`, `get_duration_sec()`, `get_state()`, and `is_complete()`; fake input envelopes matching input-core v1 including no-arg Boxing punch events; and lifecycle, dispatch order, terminal completion, aggregation, and fake-envelope fidelity coverage. QA reran GodotEnv sync, headless import, GUT, and `.testbed` scene load/log validation. GodotEnv sync passed; import passed with only accepted vendored GUT GUI invalid-UID warnings and the accepted headless ObjectDB leak warning; GUT passed 4/4 tests with 50 assertions; `.testbed` scene load passed cleanly. QA evidence was added to bead notes, `bd dolt push` completed, and bead `aerobeat-gameplay-runner-snf` remains `in_progress` for audit.

---

### Task 10: Audit Gameplay Runner Contract Adoption

**Bead ID:** `aerobeat-gameplay-runner-snf`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-12`  
**Prompt:** Independently audit bead `aerobeat-gameplay-runner-snf` against the plan, freeze references, diff, and validation output. If complete, close `aerobeat-gameplay-runner-snf` with `bd close aerobeat-gameplay-runner-snf --reason "Implemented, QA verified, and audited against frozen runner contract and clock scope" --json`. If not complete, leave it open and report the exact gap.

**Status:** ✅ Complete

**Results:** PASS. `primary` auditor independently audited bead `aerobeat-gameplay-runner-snf` against Tasks 8-10, frozen references, bead notes, implementation commit `bd0bf616b475b27ea012b3dded168b5b607ec2af`, QA evidence, and the current repo state. Auditor verified runner contract adoption, sampled clock scope, runner-owned fake input envelope fidelity, lifecycle/dispatch/terminal/aggregation coverage, and mode-core ownership boundaries. Auditor reran GodotEnv sync, headless import, GUT, and `.testbed` scene load/log validation. GodotEnv sync passed; import passed with only documented vendored GUT invalid-UID warnings plus the accepted headless ObjectDB leak warning; GUT passed 4/4 tests with 50 assertions; `.testbed` scene load passed cleanly. `aerobeat-gameplay-runner-snf` was closed with reason `Implemented, QA verified, and audited against frozen runner contract and clock scope`, and `bd dolt push` completed. Parent verification confirmed the bead is closed.

---

### Task 11: Implement Boxing Pure Rule Engine

**Bead ID:** `aerobeat-mode-boxing-hz4`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-09`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `aerobeat-mode-boxing-hz4` with `bd update aerobeat-mode-boxing-hz4 --claim --json` at start, after `afc-z8o` and `aerobeat-input-core-6xl` are complete. In the `coder` role on `primary`, implement a pure Boxing v1 mode runner over normalized no-arg Boxing events: straight/hook/uppercut left/right, guard, squat, and weave transitions. Evaluate authored targets against timing windows and tiny fake input fixtures; emit mode-core judgement/score/run fragments. Do not depend on runner, camera, raw landmarks, detector payloads, UI shell, or assembly. If `.testbed/addons.jsonc` or installed GodotEnv addon state must change, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-boxing/.testbed` per `REF-13`/`REF-14` and report the exact command. Run repo validation and any relevant Godot fresh-open/log pass, then commit and push. Do not close the bead unless implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-boxing/`

**Files Created/Deleted/Modified:**
- Pending

**Status:** ⏳ In Progress

**Results:** Prerequisite beads `afc-z8o` and `aerobeat-input-core-6xl` are closed, Boxing git is clean on `main`, and `aerobeat-mode-boxing-hz4` is open for coder implementation.

---

### Task 12: QA Boxing Pure Rule Engine

**Bead ID:** `aerobeat-mode-boxing-hz4`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-09`  
**Prompt:** With bead `aerobeat-mode-boxing-hz4` still active, independently verify the Boxing engine is pure, consumes the frozen no-arg input events, emits mode-core fragments, covers hit/miss/early/late/combo/completion fixture behavior, and has no runner/camera/UI/assembly dependency. Run the highest-fidelity repo validation available and repeat any relevant Godot fresh-open/log pass. Report pass/fail; do not close the bead.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 13: Audit Boxing Pure Rule Engine

**Bead ID:** `aerobeat-mode-boxing-hz4`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-09`  
**Prompt:** Independently audit bead `aerobeat-mode-boxing-hz4` against the plan, freeze references, diff, and validation output. If complete, close `aerobeat-mode-boxing-hz4` with `bd close aerobeat-mode-boxing-hz4 --reason "Implemented, QA verified, and audited against frozen pure Boxing rule-engine scope" --json`. If not complete, leave it open and report the exact gap.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 14: Implement Flow Pure Rule Engine

**Bead ID:** `aerobeat-mode-flow-346`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-10`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `aerobeat-mode-flow-346` with `bd update aerobeat-mode-flow-346 --claim --json` at start, after `afc-z8o` is complete. In the `coder` role on `primary`, implement a pure Flow v1 mode runner over `BodyCellInput` events plus Flow squat transitions. Cover left/right wrist hits, direction-required and directionless notes, nose/obstacle semantics if retained, tiny fake input fixtures, and mode-core judgement/score/run fragments. Do not depend on runner, camera, raw landmarks, detector payloads, UI shell, or assembly. If `.testbed/addons.jsonc` or installed GodotEnv addon state must change, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-flow/.testbed` per `REF-13`/`REF-14` and report the exact command. Run repo validation and any relevant Godot fresh-open/log pass, then commit and push. Do not close the bead unless implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-flow/`

**Files Created/Deleted/Modified:**
- Pending

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 15: QA Flow Pure Rule Engine

**Bead ID:** `aerobeat-mode-flow-346`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-10`  
**Prompt:** With bead `aerobeat-mode-flow-346` still active, independently verify the Flow engine is pure, consumes the frozen BodyCellInput/Flow squat surface, emits mode-core fragments, covers required tiny fixture behavior, and has no runner/camera/UI/assembly dependency. Run the highest-fidelity repo validation available and repeat any relevant Godot fresh-open/log pass. Report pass/fail; do not close the bead.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 16: Audit Flow Pure Rule Engine

**Bead ID:** `aerobeat-mode-flow-346`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-10`  
**Prompt:** Independently audit bead `aerobeat-mode-flow-346` against the plan, freeze references, diff, and validation output. If complete, close `aerobeat-mode-flow-346` with `bd close aerobeat-mode-flow-346 --reason "Implemented, QA verified, and audited against frozen pure Flow rule-engine scope" --json`. If not complete, leave it open and report the exact gap.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 17: Convert BeatSaver Regression Fixtures

**Bead ID:** `aerobeat-content-core-xba`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-11`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `aerobeat-content-core-xba` with `bd update aerobeat-content-core-xba --claim --json` at start, after tiny mode/runner contracts pass. In the `coder` role on `primary`, convert Derrick's approved BeatSaver candidate pool from `REF-02` into content-core song-package/chart regression fixtures. Preserve group intent for Sonic speed, K-Pop and Game Grumps/NSP simpler references, and Linkin Park mid-level Expert baseline. Validate through content-core contracts before runner or mode tests consume them. If `.testbed/addons.jsonc` or installed GodotEnv addon state must change, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/.testbed` per `REF-13`/`REF-14` and report the exact command. Run repo validation and any relevant Godot fresh-open/log pass, then commit and push. Do not close the bead unless implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/`

**Files Created/Deleted/Modified:**
- Pending

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 18: QA BeatSaver Regression Fixtures

**Bead ID:** `aerobeat-content-core-xba`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-11`  
**Prompt:** With bead `aerobeat-content-core-xba` still active, independently verify the BeatSaver-derived fixtures preserve the approved candidate pool and validate through content-core contracts. Confirm fixture files are small enough or separated enough for useful regression debugging where applicable. Run highest-fidelity repo validation and repeat any relevant Godot fresh-open/log pass. Report pass/fail; do not close the bead.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 19: Audit BeatSaver Regression Fixtures

**Bead ID:** `aerobeat-content-core-xba`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-11`  
**Prompt:** Independently audit bead `aerobeat-content-core-xba` against the plan, approved BeatSaver pool, diff, and validation output. If complete, close `aerobeat-content-core-xba` with `bd close aerobeat-content-core-xba --reason "Implemented, QA verified, and audited against approved BeatSaver regression fixture scope" --json`. If not complete, leave it open and report the exact gap.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 20: Compose Runner Testbed Full-Run Regressions

**Bead ID:** `aerobeat-gameplay-runner-yij`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-09`, `REF-10`, `REF-11`, `REF-13`, `REF-14`  
**Prompt:** Claim bead `aerobeat-gameplay-runner-yij` with `bd update aerobeat-gameplay-runner-yij --claim --json` at start, after runner contract adoption, Boxing engine, Flow engine, and BeatSaver fixture conversion are complete. In the `coder` role on `primary`, compose `aerobeat-gameplay-runner/.testbed` with runner, mode-core, content-core, input-core, Boxing, and Flow engines. Use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed` per `REF-13`/`REF-14` for dependency manifest/install updates and report the exact command. Run tiny fixture songs with fake clocks/input streams first, then BeatSaver-converted regression fixtures. Validate headless import/GUT where possible and perform fresh Godot scene-open/log inspection for this runtime testbed seam. Resolve unexpected warnings/errors or document accepted exceptions, then commit and push. Do not close the bead unless implementation and validation are complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.testbed/`

**Files Created/Deleted/Modified:**
- Pending

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 21: QA Runner Testbed Full-Run Regressions

**Bead ID:** `aerobeat-gameplay-runner-yij`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-09`, `REF-10`, `REF-11`  
**Prompt:** With bead `aerobeat-gameplay-runner-yij` still active, independently verify the runner `.testbed` composition in the highest-fidelity environment available. Confirm tiny fixture runs pass before BeatSaver regressions, verify runner/mode/content/input seams are composed through the frozen boundaries, run automated validation, and repeat fresh Godot scene-open/log inspection. Unexpected runtime warnings fail unless explicitly accepted in this plan or bead notes. Report pass/fail; do not close the bead.

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 22: Audit Runner Testbed Full-Run Regressions

**Bead ID:** `aerobeat-gameplay-runner-yij`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-09`, `REF-10`, `REF-11`  
**Prompt:** Independently audit bead `aerobeat-gameplay-runner-yij` against the plan, frozen references, diff, validation output, and Godot fresh-open/log evidence. If complete, close `aerobeat-gameplay-runner-yij` with `bd close aerobeat-gameplay-runner-yij --reason "Implemented, QA verified, and audited against frozen runner testbed regression scope" --json`. If not complete, leave it open and report the exact gap.

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:** Pending.

**Lessons Learned:** Pending.

---

*Drafted on 2026-08-02*
