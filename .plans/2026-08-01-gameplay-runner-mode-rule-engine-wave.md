# Gameplay Runner And Mode Rule-Engine Wave

**Date:** 2026-08-01  
**Status:** Draft  
**Last Updated:** 2026-08-01 22:10 EDT
**Blocked Reason:** High-level phase order and runner/mode-core envelope split approved; contract ownership freeze proposal in progress before implementation.  
**Agent:** pico

---

## Goal

Plan the next AeroBeat implementation wave: gameplay runner contract hardening, shared mode-core contracts, Boxing and Flow pure rule engines, fixtures, and runner `.testbed` composition.

---

## Overview

The previous architecture discussion is complete and archived in `aerobeat-mode-core`. The frozen direction is that `aerobeat-gameplay-runner` owns song-run orchestration while Boxing and Flow own mode-specific rule evaluation. Runner binds to timing from `aerobeat-tool-audio-player`; it does not implement audio-clock truth directly. `aerobeat-assembly-community` stays late in the cycle and should consume the proven runner/mode/input/content composition rather than becoming the first integration surface.

This plan is intentionally staged. First, Derrick reviews the high-level phase split. Then we freeze the architecture details one seam at a time before any implementation begins. The plan should become executable only after those freeze decisions are captured here and converted into repo-local Beads across the affected polyrepos.

The most important current mismatch is in `aerobeat-input-core`: the archived architecture freeze says Boxing punch inputs are per-arm active events only with no power/strength/intensity concept, but the current `BoxingInput` and `InputManager` signals still include `power: float`. That contract correction is part of the next wave and must be frozen explicitly before Boxing engines or runner envelopes depend on the old shape.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Frozen gameplay architecture discussion | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/.plans/archive/2026-08-01-aerobeat-gameplay-architecture-resume.md` |
| `REF-02` | Gameplay runner package | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/README.md` |
| `REF-03` | Gameplay runner facade/session code | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/src/` |
| `REF-04` | Shared mode contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-core/README.md` |
| `REF-05` | Boxing mode repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-boxing/README.md` |
| `REF-06` | Flow mode repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-mode-flow/README.md` |
| `REF-07` | Input contracts needing punch-shape correction | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/boxing_input.gd` |
| `REF-08` | Input manager signal mirror needing punch-shape correction | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` |
| `REF-09` | Content contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md` |
| `REF-10` | Audio clock source repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-audio-player/README.md` |

---

## High-Level Phase Proposal

### Phase 0: Approval And Freeze Gates

Before implementation, freeze these seams in this plan:

- **Contract ownership:** which DTOs/interfaces live in `aerobeat-mode-core` vs `aerobeat-gameplay-runner`.
- **Runner timing:** the exact narrow clock interface runner consumes from `aerobeat-tool-audio-player`.
- **Input event shape:** Boxing punches become active per-arm events with no scalar; Flow primarily consumes `BodyCellInput`.
- **Fixture strategy:** tiny purpose-built fixtures for unit/contract tests plus BeatSaver-converted maps for full runner `.testbed` and E2E validation.
- **Rule engine boundary:** Boxing/Flow engines are pure and mode-local; no camera, raw landmarks, UI shell, or assembly concerns.
- **Runner `.testbed` target:** first composition target remains `aerobeat-gameplay-runner/.testbed`; `aerobeat-assembly-community` is late-cycle integration.

### Phase 1: Normalize Shared Contracts

Implement only the contract minimum needed for rule engines and runner integration:

- Add or adjust `aerobeat-mode-core` DTOs/interfaces for mode identity, chart object handoff, mode runner lifecycle, judgement events, score deltas, run result fragments, and test fixtures.
- Correct `aerobeat-input-core` Boxing punch signals from `signal straight_left(power: float)` style to no-scalar active events.
- Keep portable mode contracts and mode-produced result fragments in `aerobeat-mode-core`; keep session-level envelopes, clock/timeline orchestration state, aggregation, and testbed transport in `aerobeat-gameplay-runner`.
- Keep camera-tracking debug payloads provider/testbed-local.

### Phase 2: Harden Gameplay Runner

Move runner from scaffold to real orchestration surface:

- Bind session lifecycle to a narrow timeline clock interface sourced from `aerobeat-tool-audio-player`.
- Dispatch chart timeline events into an active mode runner.
- Subscribe to a fake/test input stream first; defer live camera binding until mode engines and runner are stable.
- Emit common session events, pause/resume/retry state, and result envelopes.
- Add focused GUT coverage for lifecycle, dispatch order, terminal states, and result aggregation.

### Phase 3: Build Boxing Pure Rule Engine

In `aerobeat-mode-boxing`:

- Consume explicit Boxing input events: straight/hook/uppercut left/right active events, guard, squat, weave.
- Do not consume punch power, strength, intensity, or raw landmark data in v1.
- Evaluate authored Boxing chart targets against hit windows and fake input streams.
- Produce judgement/score events through the shared contract.
- Cover with small purpose-built fixtures before runner composition.

### Phase 4: Build Flow Pure Rule Engine

In `aerobeat-mode-flow`:

- Consume `BodyCellInput` events as the primary v1 Flow input surface.
- Keep Flow-specific state minimal, such as squat if retained by authored beat semantics.
- Evaluate authored cell/direction/timing objects against fake body-cell streams.
- Produce judgement/score events through the shared contract.
- Cover with small purpose-built fixtures before runner composition.

### Phase 5: Runner Testbed Composition

In `aerobeat-gameplay-runner/.testbed`:

- Compose runner + mode-core + content-core + input-core + Boxing/Flow engines.
- Run fixture-based songs with fake input streams.
- Add BeatSaver-converted map coverage for realism/regression.
- Validate via headless import and GUT where possible, plus fresh Godot scene-open/log inspection for the runtime testbed seam.

### Phase 6: Late Assembly Integration

Only after runner `.testbed` passes:

- Wire `aerobeat-assembly-community` as a consumer of the proven runner/mode/input/content package set.
- Keep product UI, environment loading, settings, and camera UX in assembly/tool repos.
- Do not move rule-engine or runner contract truth into assembly.

---

## Proposed Approval Questions

1. Does this phase order match the way you want to reduce risk?
2. Should runner envelopes live in `aerobeat-gameplay-runner`, `aerobeat-mode-core`, or split between runner-local transport and mode-core result DTOs?
3. Do we freeze the Boxing input-core correction now as signal-with-no-args, or should punch signals carry an explicit boolean `active` even though the event itself implies active?
4. Should the first fake input stream be runner-owned test infrastructure or live in `aerobeat-input-core` as shared test utilities?
5. Which BeatSaver-converted maps should be the first full-run regression fixtures, or should we start with any tiny converted map and swap later?

## Approval Notes

- 2026-08-01: Derrick approved the high-level phase order for risk reduction.
- 2026-08-01: Derrick approved the split where `aerobeat-mode-core` owns portable mode contracts and mode-produced result fragments, while `aerobeat-gameplay-runner` owns session-level envelopes, clock/timeline orchestration state, aggregation, and testbed transport.
- 2026-08-01: Boxing punch input correction is approved as signal-with-no-args; v1 punch events do not carry `power`, `strength`, scalar intensity, or an explicit `active` boolean.
- 2026-08-01: First fake input streams should be runner-owned test infrastructure. `aerobeat-input-core` remains contract-only for this seam.
- 2026-08-01: BeatSaver regression fixtures will wait for Derrick-provided BeatSaver IDs from songs he already knows by feel from Shadowboxr and Hit Beat on Meta Quest.

---

## Contract Ownership Freeze Proposal

### Boundary Rule

Freeze the v1 seam as a wrapper relationship:

- `aerobeat-mode-core` owns portable mode contracts and the fragments a mode rule engine produces while interpreting authored content and normalized input.
- `aerobeat-gameplay-runner` owns the complete run/session envelope, timeline/clock orchestration state, aggregation, dispatch history, fake stream/testbed transport, and assembly-facing session facade.
- Modes may depend on `aerobeat-mode-core`, `aerobeat-content-core`, and `aerobeat-input-core`; modes should not depend on `aerobeat-gameplay-runner`.
- Runner may depend on `aerobeat-mode-core` fragment DTOs/interfaces and wrap mode-produced fragments into complete run/session results.

### Proposed V1 DTOs And Interfaces

| Proposed contract | Owner repo | Responsibility | Reason |
| --- | --- | --- | --- |
| `ModeDescriptor` | `aerobeat-mode-core` | Portable mode identity: `mode_id`, display name/key, supported chart/input contract IDs, and mode contract version. | Boxing and Flow both need a shared way to advertise what they implement without importing runner session envelopes. |
| `ModeRunConfig` | `aerobeat-mode-core` | Mode-local immutable setup subset: `mode_id`, chart/content handle or chart object reference, seed, mode tuning/scoring options. | This is the portion a mode rule engine needs to start; it should be reusable in mode-local tests and runner composition. Runner can derive it from its session config. |
| `ModeRunner` | `aerobeat-mode-core` | Pure rule-engine lifecycle interface: `start(config)`, `tick(frame)`, `is_complete()`, and `stop(reason)`, returning mode fragments/events only. | The current runner file `src/interfaces/gameplay_mode_runner.gd` documents a mode-facing interface. That contract should be portable so Boxing/Flow can implement and test it without depending on runner. |
| `ModeTickFrame` | `aerobeat-mode-core` | Per-tick input to a mode: timeline position, delta, chart events due for evaluation, and normalized input events/frame. | Keeps the mode engine contract explicit and portable while avoiding runner-owned session state. |
| `ModeEvent` | `aerobeat-mode-core` | Shared base event shape emitted by modes: event type, mode ID, target/chart object reference, timestamp/position, metadata. | Runner dispatch should normalize and store events, but the mode-emitted vocabulary must be shared across Boxing and Flow. |
| `ModeJudgementEvent` | `aerobeat-mode-core` | Judgement fragment for hit/miss/late/early/perfect-style outcomes, including timing offset and authored target reference. | Judgement semantics are produced by mode rule engines and should be testable in mode repos. |
| `ModeScoreDelta` | `aerobeat-mode-core` | Mode-produced scoring fragment: score delta, combo effect, accuracy contribution, and optional mode metadata. | Runner aggregates score, but the unit of scoring emitted by a mode is mode-core contract truth. |
| `ModeRunFragment` | `aerobeat-mode-core` | Start/stop/completion fragment produced by a mode: mode state/result reason, emitted summaries, mode-local metadata. | Lets runner wrap mode completion details without making the mode know about full sessions. |
| `ModeFixtureCase` | `aerobeat-mode-core` | Minimal shared fixture case shape for mode rule-engine contract tests: config, chart snippet reference, input/tick frames, expected events/fragments. | Boxing and Flow need comparable focused tests before runner composition; runner can have its own transport fixtures separately. |
| `GameplayRunConfig` | `aerobeat-gameplay-runner` | Complete session setup envelope: selected song/package/chart IDs, selected mode, timeline binding config, scoring aggregation settings, transport/testbed metadata, and derived `ModeRunConfig`. | This contains session orchestration concerns beyond what a pure mode should receive. Existing `src/data_types/gameplay_run_config.gd` should stay runner-owned, but pass only a mode subset into mode engines. |
| `GameplayRunState` | `aerobeat-gameplay-runner` | Session lifecycle state names: idle, ready, running, paused, completed, stopped, failed. | Pause/resume/retry and terminal state are runner session behavior, not portable mode-rule vocabulary. Existing `src/data_types/gameplay_run_state.gd` should stay. |
| `GameplayRunResult` | `aerobeat-gameplay-runner` | Complete run result envelope: final session state, aggregated score/combo/accuracy/duration, reason, event history, mode fragments, and runner metadata. | Runner wraps mode-core fragments into a complete product/testbed result. Existing `src/data_types/gameplay_run_result.gd` should stay runner-owned and evolve to carry mode-core fragments explicitly. |
| `GameplaySession` | `aerobeat-gameplay-runner` | Runtime session coordinator for start/tick/pause/resume/stop, active mode runner, clock, input stream, event dispatch, aggregation, and final result creation. | This is the conductor approved for runner. Existing `src/runtime/gameplay_session.gd` should stay. |
| `GameplayTimelineClock` | `aerobeat-gameplay-runner` | Narrow clock adapter interface consumed by runner from `aerobeat-tool-audio-player`: reset/advance or sample current position/completion. | Audio clock truth is outside runner, but the runner-owned adapter seam coordinates session timeline. Existing `src/interfaces/gameplay_timeline_clock.gd` should stay runner-owned until the timing freeze defines exact methods. |
| `GameplayInputStream` | `aerobeat-gameplay-runner` | Runner/testbed fake input stream interface that supplies normalized input frames/events at timeline positions. | Derrick approved first fake input streams as runner-owned test infrastructure; `aerobeat-input-core` remains the stable input contract source. Existing `src/interfaces/gameplay_input_stream.gd` should stay runner-owned. |
| `GameplayEventDispatcher` | `aerobeat-gameplay-runner` | Runner dispatch/history transport that accepts mode-core `ModeEvent` fragments and stores/emits session events. | Event storage/fanout is session/testbed orchestration, not a pure mode contract. Existing `src/runtime/gameplay_event_dispatcher.gd` should stay but should stop inventing mode event fields beyond wrapper metadata. |
| `GameplayScoreAggregator` | `aerobeat-gameplay-runner` | Aggregates mode-core `ModeScoreDelta`/judgement fragments into session score, combo, hit/miss totals, and accuracy. | Scoring fragments come from modes; the final accumulated scoreboard is runner-owned. Existing `src/runtime/gameplay_score_aggregator.gd` should stay. |
| `GameplayTestbedTransport` | `aerobeat-gameplay-runner` | Testbed-only serialized event/result transport for runner `.testbed` scenes, fake streams, and headless validation. | Transport is a runner validation concern and should not leak into portable mode-core contracts. Add only when the runner `.testbed` needs a named seam. |

### Existing Name And File Decisions

- Keep `src/data_types/gameplay_run_config.gd` in `aerobeat-gameplay-runner`; tighten its comments later from "passed into a gameplay mode runner" to "session envelope that derives/passes a mode config subset."
- Keep `src/data_types/gameplay_run_result.gd` in `aerobeat-gameplay-runner`; later add explicit slots for mode-core `ModeRunFragment`, `ModeJudgementEvent`, and/or `ModeScoreDelta` lists instead of generic untyped dictionaries.
- Keep `src/data_types/gameplay_run_state.gd` in `aerobeat-gameplay-runner`; these are runner session states, not mode-core states.
- Move/rename the contract documented by `src/interfaces/gameplay_mode_runner.gd` into `aerobeat-mode-core` as `ModeRunner` or `GameplayModeRunner`. Prefer `ModeRunner` because the repo rename already approved mode terminology and the contract is mode-facing. Leave a runner-local adapter only if Godot package loading needs a bridge.
- Keep `src/interfaces/gameplay_timeline_clock.gd` in `aerobeat-gameplay-runner`; it is a runner adapter to external audio timing and should be revisited in the timing freeze.
- Keep `src/interfaces/gameplay_input_stream.gd` in `aerobeat-gameplay-runner`; it is runner/testbed fake-stream infrastructure, not input-core contract truth.
- Keep `src/runtime/gameplay_session.gd`, `src/runtime/gameplay_event_dispatcher.gd`, and `src/runtime/gameplay_score_aggregator.gd` in `aerobeat-gameplay-runner`; they are orchestration/aggregation/session transport.
- Keep `src/AeroGameplayRunner.gd` in `aerobeat-gameplay-runner`; later replace "feature modes" wording with "modes" and expose factories that create runner envelopes, not mode-core contracts.
- Create `aerobeat-mode-core/src/` only when implementing the approved freeze; it is currently absent and the README says the repo is intentionally a minimal lane-definition placeholder.
- Do not move runner envelopes into `aerobeat-mode-core`, and do not make Boxing/Flow import runner just to implement a mode runner.

### Practical Implementation Notes For Next Wave

- First implementation step in `aerobeat-mode-core`: add only the portable mode DTOs/interfaces above and focused tests/fixtures if a testbed is introduced. Avoid adding session, clock, fake-stream, or transport types there.
- First implementation step in `aerobeat-gameplay-runner`: depend on the new mode-core contracts, adapt `GameplaySession.tick()` to pass a `ModeTickFrame`, accept mode-core event/score fragments, and wrap them into `GameplayRunResult`.
- The current runner aggregator reads generic dictionary fields such as `type`, `score`, and `score_delta`; next wave should replace that implicit event shape with mode-core judgement/score fragment fields.
- The current runner `GameplayRunConfig` includes broad `timeline`, `scoring`, and `metadata` dictionaries. Keep that flexibility for v1 bootstrap, but document which keys are runner session envelope keys and which are transformed into `ModeRunConfig`.

---

## Tasks

### Task 1: Draft And Review High-Level Plan

**Bead ID:** `aerobeat-gameplay-runner-2bh`  
**SubAgent:** `primary`  
**Role:** `primary`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-07`, `REF-08`, `REF-10`  
**Prompt:** Draft the next-phase gameplay runner / mode-core contracts / Boxing+Flow rule-engine plan, keep it as Draft, and ask Derrick for high-level approval before creating implementation beads or changing contracts.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-01-gameplay-runner-mode-rule-engine-wave.md`

**Status:** ⏳ In Progress

**Results:** Draft plan created for Derrick review. Derrick approved the high-level phase order, runner/mode-core envelope split, input-shape decision, fake-stream ownership, and BeatSaver fixture-source approach.

---

### Task 2: Freeze Contract Ownership

**Bead ID:** `aerobeat-gameplay-runner-eni`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`  
**Prompt:** Claim bead `aerobeat-gameplay-runner-eni` at start. In the `research` role, inspect `aerobeat-gameplay-runner` and `aerobeat-mode-core` contract seams and propose exactly which v1 DTOs/interfaces live in each repo. Apply the approved boundary: `aerobeat-mode-core` owns portable mode contracts and mode-produced result fragments; `aerobeat-gameplay-runner` owns session-level envelopes, clock/timeline orchestration state, aggregation, and testbed transport. Do not implement code. Update this plan with the freeze proposal and leave the bead in progress for Derrick approval.

**Status:** ⏳ In Progress

**Results:** Research bead created and claimed. Contract ownership freeze proposal added above for Derrick review; bead intentionally remains in progress pending approval.

---

### Task 3: Freeze Input Event Shapes

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-07`, `REF-08`  
**Prompt:** After high-level approval, propose the exact v1 Boxing and Flow input event signatures, including the no-power punch correction. Do not implement; update this plan and wait for Derrick approval.

**Status:** ⏳ Pending Approval

**Results:** Pending.

---

### Task 4: Freeze Timing And Fixture Strategy

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-09`, `REF-10`  
**Prompt:** After high-level approval, propose the narrow timeline clock contract and first fixture strategy for tiny unit fixtures plus BeatSaver-converted full-run fixtures. Do not implement; update this plan and wait for Derrick approval.

**Status:** ⏳ Pending Approval

**Results:** Pending.

---

### Task 5: Create Implementation Beads

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `primary`  
**References:** All approved freeze sections  
**Prompt:** Only after all freeze gates are approved, create repo-local implementation Beads across runner, mode-core, input-core, mode-boxing, mode-flow, and any fixture/content repos. Link dependencies and update this plan. Do not start implementation until Derrick approves execution.

**Status:** ⏳ Pending Approval

**Results:** Pending.

---

## Final Results

**Status:** Draft

**What We Built:** Draft plan only; no implementation.

**Reference Check:** Initial references inspected. Current mismatch recorded: Boxing input signals still carry `power: float` in input-core while the frozen architecture says no power/strength/intensity concept in v1.

**Commits:** Pending.

**Lessons Learned:** Pending.
