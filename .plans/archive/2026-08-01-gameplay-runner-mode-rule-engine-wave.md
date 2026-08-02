# Gameplay Runner And Mode Rule-Engine Wave

**Date:** 2026-08-01  
**Status:** Complete  
**Last Updated:** 2026-08-01 22:32 EDT
**Blocked Reason:** None
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
- 2026-08-01: Derrick approved the contract ownership freeze: `aerobeat-mode-core` owns portable mode contracts and mode-produced fragments; `aerobeat-gameplay-runner` owns full session envelopes, timeline/clock orchestration, aggregation, fake stream/testbed transport, and assembly-facing session facade.
- 2026-08-01: Derrick provided the first BeatSaver regression candidate pool. Fast Sonic heavy metal/rock maps cover upper-end speed, K-Pop Demon Hunters and Game Grumps/NSP cover simpler reference songs, and Linkin Park covers mid-level challenge relative to Derrick's Expert play baseline.
- 2026-08-01: Derrick approved continuing the current plan through the remaining freeze tickets. Input event shape and timing/fixture freeze proposals are approved for conversion into implementation beads.

## BeatSaver Regression Candidate Pool

These are full-run regression candidates Derrick knows by feel from Shadowboxr and Hit Beat on Meta Quest. Use these after tiny purpose-built fixtures prove contracts/rule engines locally.

| Group | Feel / Difficulty Role | BeatSaver IDs |
| --- | --- | --- |
| Sonic Songs - Heavy Metal / Rock | Very fast upper-end speed references | `29be2`, `349f2`, `2b4e6`, `304ea` |
| Kpop Demon Hunters - K-Pop | Simpler reference songs | `48727`, `48088`, `48792`, `47fb6` |
| Game Grumps / NSP - Meme | Simpler/meme reference songs | `3d44b`, `472d3` |
| Linkin Park - Rock Alternative | Mid-level challenge references for Derrick's Expert baseline | `226e`, `2f3d7`, `4858`, `19e5e` |

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

## Input Event Shape Freeze Proposal

**Approval Status:** Approved by Derrick on 2026-08-01.

### Boundary Rule

Freeze v1 gameplay input as stable `aerobeat-input-core` signal contracts plus runner/test-owned fake event frames that mirror those signals exactly. Mode engines consume normalized input intent events; they do not consume camera frames, raw landmarks, detector debug dictionaries, product UI events, or provider-specific gesture state.

### Boxing V1 Signal Contract

`aerobeat-input-core/src/interfaces/boxing_input.gd` and the matching `InputManager` proxy signals should freeze to these exact no-arg punch and state signatures:

```gdscript
signal straight_left
signal straight_right
signal uppercut_left
signal uppercut_right
signal hook_left
signal hook_right
signal guard_enabled
signal guard_disabled
signal squat_enabled
signal squat_disabled
signal weave_left_enabled
signal weave_left_disabled
signal weave_right_enabled
signal weave_right_disabled
```

Required correction from the current repo state:

- Remove `power: float` from `straight_left`, `straight_right`, `uppercut_left`, `uppercut_right`, `hook_left`, and `hook_right` in `BoxingInput`.
- Remove `power: float` from the matching `InputManager` proxy signals.
- Change `InputManager._connect_boxing_signals()` punch proxy callbacks from one-arg forwarding to no-arg forwarding.
- Do not add `active: bool`, `power`, `strength`, `intensity`, confidence, velocity, or detector score to these punch signals in v1.

Boxing rule-engine meaning:

- The six punch signals are instantaneous active intent events. The event itself means the punch became active for evaluation.
- Guard, squat, and weave signals are state transitions, represented by explicit `_enabled` and `_disabled` events.
- Boxing v1 evaluates authored Boxing targets against these signals and runner timestamps; any detector confidence/debug payload remains provider/testbed-local unless a later plan promotes it.
- `BoxingInput` may continue extending `BodyCellInput`, but the Boxing v1 rule engine should primarily consume the explicit Boxing signals above.

### Flow V1 Signal Contract

Flow should primarily consume the shared calibrated `BodyCellInput` lane. Freeze these exact body-cell signatures as the main Flow v1 note input surface:

```gdscript
signal left_wrist_cell_entered(cell: int, direction: int)
signal right_wrist_cell_entered(cell: int, direction: int)
signal nose_cell_entered(cell: int, direction: int)
signal calibration_session_updated(session: Dictionary)
```

`aerobeat-input-core/src/interfaces/flow_input.gd` may add only this Flow movement/state surface in v1:

```gdscript
signal squat_enabled
signal squat_disabled
```

Flow rule-engine meaning:

- `cell` is the direct calibrated 4x3 cell index `0..11` using the current BeatSaver row-major / athlete-space grid convention.
- `direction` is the recent 8-way motion direction value when valid, or `-1` when ambiguous or unavailable.
- `left_wrist_cell_entered` and `right_wrist_cell_entered` are the primary hit inputs for Flow `note`, `burst`, and `arc` evaluation.
- `nose_cell_entered` is available for Flow obstacle/body-position semantics and calibration/test visualization where authored content needs it.
- `calibration_session_updated(session: Dictionary)` remains calibration/HUD support, not a scoring event.
- Do not introduce Flow-specific `slice_*`, `swing_*`, `trail_*`, `warn_*`, `reward_*`, or raw pose events into the v1 gameplay input contract.

### Runner Fake-Input Envelope

Runner-owned fake streams and fixture rows should wrap the signal contract without changing it. The minimum event dictionary for tests should be:

```gdscript
{
	"contract": "aerobeat.input.boxing.v1" | "aerobeat.input.body_cell.v1" | "aerobeat.input.flow.v1",
	"event": String,
	"position_sec": float,
	"args": Array
}
```

Examples:

```gdscript
{"contract": "aerobeat.input.boxing.v1", "event": "straight_left", "position_sec": 12.40, "args": []}
{"contract": "aerobeat.input.body_cell.v1", "event": "right_wrist_cell_entered", "position_sec": 12.40, "args": [6, 3]}
{"contract": "aerobeat.input.flow.v1", "event": "squat_enabled", "position_sec": 12.40, "args": []}
```

Optional source/debug metadata may live beside this in testbed-only fixtures, but mode engines should not require it for v1 rule evaluation.

---

## Timing And Fixture Strategy Freeze Proposal

**Approval Status:** Approved by Derrick on 2026-08-01.

### Runner Clock Boundary

Freeze `GameplayTimelineClock` as a runner-owned adapter interface over `aerobeat-tool-audio-player`. The audio player remains timing truth; runner samples a small clock surface and must not maintain a competing audio timeline.

Exact v1 runner-consumed clock interface:

```gdscript
func reset() -> void
func get_position_sec() -> float
func get_duration_sec() -> float
func get_state() -> String
func is_complete() -> bool
```

The audio-player-backed adapter should implement those methods from the current `AeroAudioLoader` surface:

- `reset()` delegates to `AeroAudioLoader.seek(0.0, audio_id)` or resets fake/test clock state.
- `get_position_sec()` delegates to `AeroAudioLoader.get_position(audio_id)`.
- `get_duration_sec()` delegates to `AeroAudioLoader.get_duration(audio_id)`.
- `get_state()` delegates to `AeroAudioLoader.get_state(audio_id).get("state", "")`.
- `is_complete()` returns true after `audio_playback_finished(audio_id)`, or when duration is known and sampled position is at/after duration.

Runner implementation implications for the next wave:

- Replace runner reliance on clock-owned `advance(delta_sec)` for real audio-backed runs with sampled `get_position_sec()`.
- Keep any deterministic fake clock as runner test infrastructure only. It may expose helper methods for tests, but runner production code should consume only the five methods above.
- Runner pause/resume/retry can command audio through a session/audio adapter later, but the timeline clock interface itself should stay read-focused except for `reset()`.
- Do not move this clock interface into `aerobeat-mode-core`; modes receive timeline positions through `ModeTickFrame` and do not bind to audio directly.

### Fixture Strategy

Use tiny purpose-built fixtures first, then Derrick's BeatSaver regression candidate pool after local contracts and rule engines are stable.

Fixture order:

1. Mode-local tiny contract fixtures in `aerobeat-mode-boxing` and `aerobeat-mode-flow`: a few authored beats plus fake input rows that prove hit, miss, early, late, combo, and completion behavior.
2. Runner tiny fixtures in `aerobeat-gameplay-runner/.testbed`: minimal song package/chart/set records from the `aerobeat-content-core` song-package model, a fake timeline clock, and fake input streams that prove lifecycle, dispatch order, pause/resume, terminal states, and result aggregation.
3. Full-run BeatSaver-converted regression fixtures: use the Derrick-provided candidate pool below only after the tiny fixtures pass.

Tiny fixture rules:

- Keep fixtures small enough that failures identify one contract or rule issue.
- Prefer direct checked-in dictionaries/resources for first rule tests; only use full song-package YAML when the content-resolution seam is under test.
- Include at least one Boxing fixture for each no-arg punch family and state family.
- Include at least one Flow fixture for left wrist, right wrist, direction-required note, directionless note, and nose/obstacle semantics if retained.
- Use generated or silent local audio only where audio loading itself is under test; most runner tests should drive a fake clock and avoid media assets.

BeatSaver regression pool:

- Use the existing candidate table in this plan as the first realism pool.
- Preserve group intent: Sonic IDs as fast upper-end speed references, K-Pop Demon Hunters and Game Grumps/NSP as simpler references, and Linkin Park as mid-level challenge references for Derrick's Expert baseline.
- Do not choose replacement BeatSaver IDs until Derrick approves or revises the pool.
- BeatSaver-derived full-run fixtures should validate through `aerobeat-content-core` song-package/chart contracts before they are used by runner or mode tests.

### Approval Gate

Implementation freeze details are approved. Create implementation Beads for input-core signal correction, mode-core tick/frame contracts, runner clock sampling, tiny fixtures, mode rule tests, runner `.testbed` composition, and BeatSaver regression conversion.

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

**Status:** ✅ Complete

**Results:** Draft plan created for Derrick review. Derrick approved the high-level phase order, runner/mode-core envelope split, input-shape decision, fake-stream ownership, and BeatSaver fixture-source approach. Bead closed after all freeze gates and implementation bead creation completed.

---

### Task 2: Freeze Contract Ownership

**Bead ID:** `aerobeat-gameplay-runner-eni`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`  
**Prompt:** Claim bead `aerobeat-gameplay-runner-eni` at start. In the `research` role, inspect `aerobeat-gameplay-runner` and `aerobeat-mode-core` contract seams and propose exactly which v1 DTOs/interfaces live in each repo. Apply the approved boundary: `aerobeat-mode-core` owns portable mode contracts and mode-produced result fragments; `aerobeat-gameplay-runner` owns session-level envelopes, clock/timeline orchestration state, aggregation, and testbed transport. Do not implement code. Update this plan with the freeze proposal and leave the bead in progress for Derrick approval.

**Status:** ✅ Complete

**Results:** Research bead created and claimed. Contract ownership freeze proposal added above and approved by Derrick. Bead closed with reason: "Derrick approved the runner vs mode-core contract ownership freeze."

---

### Task 3: Freeze Input Event Shapes

**Bead ID:** `aerobeat-gameplay-runner-8f8`
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-07`, `REF-08`  
**Prompt:** Claim bead `aerobeat-gameplay-runner-8f8` at start. In the `research` role, propose the exact v1 Boxing and Flow input event signatures, including Boxing no-arg punch signals and Flow `BodyCellInput` consumption. Do not implement; update this plan and wait for Derrick approval.

**Status:** ✅ Complete

**Results:** Input Event Shape Freeze Proposal drafted above and approved by Derrick's continuation directive. Implementation bead `aerobeat-input-core-6xl` created for the input-core correction. No implementation performed.

---

### Task 4: Freeze Timing And Fixture Strategy

**Bead ID:** `aerobeat-gameplay-runner-19q`
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-09`, `REF-10`  
**Prompt:** Claim bead `aerobeat-gameplay-runner-19q` at start. In the `research` role, propose the narrow timeline clock contract and first fixture strategy for tiny unit fixtures plus Derrick-provided BeatSaver-converted full-run fixtures. Use the BeatSaver regression candidate pool recorded in this plan. Do not implement; update this plan and wait for Derrick approval.

**Status:** ✅ Complete

**Results:** Timing And Fixture Strategy Freeze Proposal drafted above and approved by Derrick's continuation directive. Implementation beads created for runner clock/testbed work and BeatSaver fixture conversion. No implementation performed.

---

### Task 5: Create Implementation Beads

**Bead ID:** `aerobeat-gameplay-runner-o4d`
**SubAgent:** `primary`  
**Role:** `primary`  
**References:** All approved freeze sections  
**Prompt:** Claim bead `aerobeat-gameplay-runner-o4d` at start. Create repo-local implementation Beads across runner, mode-core, input-core, mode-boxing, mode-flow, and any fixture/content repos. Link dependencies and update this plan. Do not implement code.

**Status:** ✅ Complete

**Results:** Implementation beads created; source implementation remains pending.

| Repo | Bead ID | Slice | Dependency shape |
| --- | --- | --- | --- |
| `aerobeat-mode-core` | `afc-z8o` | Add portable mode contracts/DTOs/interfaces and tiny `ModeFixtureCase` contract fixtures. | Upstream foundation for runner adoption and Boxing/Flow engines. |
| `aerobeat-input-core` | `aerobeat-input-core-6xl` | Correct Boxing punch signals and `InputManager` proxy callbacks to no-arg events; update focused tests/docs where available. | External blocker for runner fake input envelope fidelity and Boxing engine input consumption. |
| `aerobeat-gameplay-runner` | `aerobeat-gameplay-runner-snf` | Adopt mode-core contracts, sampled `GameplayTimelineClock`, runner-owned fake input stream envelope, lifecycle/dispatch/aggregation tests. | Should wait on `afc-z8o` and `aerobeat-input-core-6xl`; cross-repo `bd dep add` could not resolve external repo IDs from runner's local database, so the blocker IDs are recorded in ticket notes/plan. |
| `aerobeat-mode-boxing` | `aerobeat-mode-boxing-hz4` | Implement pure Boxing rule engine over no-arg Boxing input events with tiny fixtures/tests. | Should wait on `afc-z8o` and `aerobeat-input-core-6xl`; cross-repo dependencies could not be stored in the local Boxing database. |
| `aerobeat-mode-flow` | `aerobeat-mode-flow-346` | Implement pure Flow rule engine over `BodyCellInput` events with tiny fixtures/tests. | Should wait on `afc-z8o`; cross-repo dependency could not be stored in the local Flow database. |
| `aerobeat-content-core` | `aerobeat-content-core-xba` | Convert Derrick's BeatSaver candidate pool into content-core song-package/chart regression fixtures. | Owns content/fixture conversion because the freeze requires BeatSaver-derived fixtures to validate through content-core contracts before runner or mode tests. |
| `aerobeat-gameplay-runner` | `aerobeat-gameplay-runner-yij` | Compose `.testbed` full-run regressions with runner, mode-core, content-core, input-core, Boxing, and Flow. | Local dependency added: `aerobeat-gameplay-runner-yij` depends on `aerobeat-gameplay-runner-snf`. It should also wait on `aerobeat-mode-boxing-hz4`, `aerobeat-mode-flow-346`, and `aerobeat-content-core-xba`; those external blockers are recorded in ticket notes/plan because local `bd dep add` cannot resolve IDs from other repo databases. |

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the architecture-freeze and implementation-bead planning wave. The plan records approved ownership, input, timing, fake-stream, and BeatSaver fixture decisions, plus repo-local implementation beads for the next coding wave. No source implementation was performed.

**Reference Check:** `REF-01` architecture freeze carried forward. `REF-07` and `REF-08` mismatch recorded and converted to `aerobeat-input-core-6xl`: Boxing input signals still carry `power: float` in input-core while the frozen architecture says no power/strength/intensity concept in v1. `REF-10` audio-player surface checked for sampled clock methods.

**Commits:** Pending.

**Lessons Learned:** Cross-repo Beads dependencies could not be stored directly from each local repo database, so the dependency shape is recorded in bead notes and this plan. Local runner dependency was stored for `aerobeat-gameplay-runner-yij` depending on `aerobeat-gameplay-runner-snf`.

**Beads Sync Caveat:** `aerobeat-gameplay-runner` Beads pushed successfully. Adjacent repo implementation beads exist locally but their Beads remotes need repair before they can sync: mode-core has no remote configured (`afc-r7s`), and input-core (`aerobeat-input-core-9r2`), mode-boxing (`aerobeat-mode-boxing-0ui`), mode-flow (`aerobeat-mode-flow-bsb`), and content-core (`aerobeat-content-core-gyn`) report Dolt `no common ancestor`. Do not force-push; preserve the local implementation beads and remote state.

*Completed on 2026-08-01*
