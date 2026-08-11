# AeroBeat Gameplay Runner Stub Scene Cleanup

**Date:** 2026-08-11  
**Status:** Complete  
**Last Updated:** 2026-08-11 07:58 EDT  
**Blocked Reason:** None  
**Agent:** primary

---

## Goal

Delete the stale gameplay runner stub scene and make the testbed project start in the Flow playable scene.

---

## Overview

`res://scenes/gameplay_runner_testbed.tscn` is only a root `Node` stub and has become misleading because the actual playable harnesses are the Flow and Boxing scenes. The testbed project still points `run/main_scene` at the stub, so default project launch opens the wrong surface.

This slice removes the stub scene and repoints `.testbed/project.godot` to `res://scenes/flow_playable_testbed.tscn`. Validation should prove the testbed imports and the Flow scene opens without unexpected warning/error noise.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Stale stub scene to remove | `.testbed/scenes/gameplay_runner_testbed.tscn` |
| `REF-02` | Testbed project main scene setting | `.testbed/project.godot` |
| `REF-03` | Desired main playable scene | `.testbed/scenes/flow_playable_testbed.tscn` |

---

## Tasks

### Task 1: Remove Stub And Repoint Main Scene

**Bead ID:** `aerobeat-gameplay-runner-r2l`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Use `primary` as the coder role. Read the runner README before touching the repo. Claim bead `aerobeat-gameplay-runner-r2l` on start with `bd update aerobeat-gameplay-runner-r2l --claim`. Delete `.testbed/scenes/gameplay_runner_testbed.tscn` and update `.testbed/project.godot` so `run/main_scene` points to `res://scenes/flow_playable_testbed.tscn`. Run focused validation that the testbed imports and the Flow playable scene opens cleanly. Commit and push the durable change before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/gameplay_runner_testbed.tscn`
- `.testbed/project.godot`
- `.plans/2026-08-11-remove-stub-main-scene.md`

**Status:** ✅ Complete

**Results:** Deleted the stale root-`Node` stub scene and repointed the testbed project main scene to `res://scenes/flow_playable_testbed.tscn`.

---

## Final Results

**Status:** Complete

**What We Built:** Removed `.testbed/scenes/gameplay_runner_testbed.tscn`; updated `.testbed/project.godot` so `run/main_scene` launches the Flow playable testbed.

**Reference Check:** `REF-01` deleted, `REF-02` updated, and `REF-03` confirmed loadable/instantiable in headless Godot.

**Validation:**
- `godot --headless --path .testbed --import` — passed.
- `godot --headless --path .testbed --editor --quit res://scenes/flow_playable_testbed.tscn` — passed.
- `godot --headless --path .testbed --script /tmp/aerobeat-r2l-open-flow.gd` — passed; loaded and instantiated the Flow playable scene.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/test_playable_content_loader.gd -gexit` — passed, 2/2 tests.
- Log scan across the passing import, scene-open, direct scene-load, and GUT logs found no unexpected `warning`, `error`, `script error`, `parse error`, `ObjectDB`, `leak`, or `resource` noise.

**Commits:** `Remove stub gameplay runner main scene`; final hash reported in handoff after amend.

**Lessons Learned:** A focused import plus explicit Flow scene load is sufficient for this scene-pointer deletion, and the nearby playable-content GUT test is quick enough to include as an extra regression check.

---

*Completed on 2026-08-11*
