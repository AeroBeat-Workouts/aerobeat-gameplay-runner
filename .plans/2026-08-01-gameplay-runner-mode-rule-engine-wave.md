# Gameplay Runner And Mode Rule-Engine Wave

**Date:** 2026-08-01  
**Status:** Draft  
**Last Updated:** 2026-08-01 22:08 EDT  
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

**Results:** Research bead created and claimed. Waiting for SubAgent contract ownership freeze proposal.

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
