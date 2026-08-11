# AeroBeat Gameplay Runner Godot Editor QA Gate Repair

**Date:** 2026-08-11  
**Status:** In Progress  
**Last Updated:** 2026-08-11 09:24 EDT  
**Blocked Reason:** None  
**Agent:** pico

---

## Goal

Repair the AeroBeat gameplay-runner validation gap where QA/audit accepted command-line scene evidence while the real Godot editor still shows warnings, and restore OpenClaw Godot editor-control tooling if the LTS upgrade dropped it.

---

## Overview

Derrick opened `flow_playable_testbed.tscn` in the real Godot editor on Cookie and saw 19 editor Errors-panel warnings. That is a QA/audit escape. The canonical gate already requires a fresh Godot scene open plus clean editor/runtime logs, but the last QA pass substituted non-headless command-line runtime probes because `godot_execute` was not exposed in the subagent session.

Initial investigation shows the gate is defined in both the built `AGENTS.md` and its source sections. The runner testbed already has the `aerobeat-tool-headless-manager` dependency in `.testbed/addons.jsonc` and the `AeroHeadlessManager` autoload in `.testbed/project.godot`, so the missing singleton is not the current blocker. The OpenClaw Godot gateway extension is a stronger suspect: `tool_search` does not expose `godot_execute`, `~/.openclaw/extensions/godot/` is empty, and gateway config currently lists only the `codex` plugin under `plugins.entries`.

This plan should not treat editor warnings as acceptable tool noise. The fix is to restore/verify the editor-control toolchain, encode the validation distinction so agents cannot silently downgrade to CLI-only scene runs, then clean the actual warning sources in their owning repos and prove the Flow/Boxing scenes in the real editor on Pico and Cookie.

Derrick approved the plan and confirmed the likely root cause is the OpenClaw LTS upgrade breaking Godot tool registration. Persistent OpenClaw gateway config changes must be made in `/home/derrick/.openclaw/config/openclaw.template.json`; `openclaw.json` is generated from that template by the next `update.sh` run. During this repair, do not call the full updater unless explicitly requested; if `update.sh` is used for regeneration or validation, pass `--skip-gateway-restart`. A narrow `openclaw gateway restart` is allowed if needed to activate the Godot extension, but it must be handled carefully and recorded.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Canonical Godot QA/audit gate in built instructions | `/home/derrick/.openclaw/workspace/AGENTS.md` |
| `REF-02` | Source section for orchestrator QA/audit gate | `/home/derrick/.openclaw/workspace/agents-sections/02-orchestrator-mode.md` |
| `REF-03` | Source section for normal Godot test safety workflow | `/home/derrick/.openclaw/workspace/agents-sections/05-safety.md` |
| `REF-04` | Prior runner warning cleanup plan that recorded editor-control fallback | `.plans/archive/2026-08-10-playable-testbed-load-camera-warnings.md` |
| `REF-05` | Runner active playable testbed plan/manual gate | `.plans/2026-08-02-playable-flow-boxing-testbeds.md` |
| `REF-06` | Runner testbed Godot project config | `.testbed/project.godot` |
| `REF-07` | Runner testbed GodotEnv dependency manifest | `.testbed/addons.jsonc` |
| `REF-08` | OpenClaw Godot skill and gateway extension source | `/home/derrick/.openclaw/workspace/skills/godot/` |
| `REF-09` | Headless manager consumer setup contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-headless-manager/README.md` |
| `REF-10` | Derrick screenshot of current Flow editor warnings | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/08/11/image-0fb4d5a2.png` |

---

## Initial Findings

- `REF-01` lines 70-80 require fresh Godot scene/path open, editor/runtime log inspection, zero warning/error noise, QA repeat of the fresh-open pass, and auditor verification of that evidence.
- `REF-02` and `REF-03` are the source sections that generate those `AGENTS.md` rules.
- `REF-04` explicitly records the escape: `godot_execute`/editor tools were unavailable, so QA used non-headless runtime scene driving and command-line logs.
- `REF-06` already contains:
  - `AeroHeadlessManager="*res://addons/aerobeat-tool-headless-manager/src/AeroHeadlessManager.gd"`
- `REF-07` already contains:
  - `aerobeat-tool-headless-manager` as a symlink dependency.
- OpenClaw gateway status is healthy at version `v2026.6.33`, but plugin config currently only has `plugins.entries.codex`.
- `~/.openclaw/extensions/godot/` exists but has no installed extension files.
- `tool_search` does not expose `godot_execute`, despite the Godot skill file describing it.
- The screenshot warnings include duplicate global-class/preload-name warnings and static GDScript warnings, so the real editor path is still noisy.

---

## Tasks

### Task 1: Diagnose and Restore OpenClaw Godot Editor Tooling

**Bead ID:** `aerobeat-gameplay-runner-l9i`  
**SubAgent:** `primary`  
**Role:** `research` / `coder`  
**References:** `REF-08`, `REF-09`  
**Prompt:** Use `primary` as the research/coder role. Read the runner README and `/home/derrick/.openclaw/workspace/skills/godot/SKILL.md` before touching anything. Claim bead `aerobeat-gameplay-runner-l9i` on start with `bd update aerobeat-gameplay-runner-l9i --claim --json`. Diagnose why `godot_execute` is not exposed after the OpenClaw LTS upgrade. Check the gateway plugin config, `~/.openclaw/extensions/godot/`, the Godot extension install script, plugin manifest compatibility with OpenClaw `v2026.6.33`, and whether the extension must be installed/enabled/restarted through the current gateway config schema. If persistent config changes are needed, edit `/home/derrick/.openclaw/config/openclaw.template.json`, not generated `/home/derrick/.openclaw/openclaw.json`. Do not run the full updater unless Derrick explicitly asks; if you must use `/home/derrick/.openclaw/workspace/scripts/update.sh`, use `--skip-gateway-restart`. If safe and scoped, restore the extension using the documented install/config path, restart the gateway via narrow OpenClaw gateway tooling only when necessary, and verify `tool_search` exposes `godot_execute` plus `console.getLogs`, `scene.open`, `editor.play`, and `editor.stop` functionality against a connected Godot editor. Do not modify AeroBeat source code in this task. Close the bead only if tool registration is restored or if a precise blocker is recorded.

**Folders Created/Deleted/Modified:**
- `~/.openclaw/extensions/godot/` if extension install is needed
- `~/.openclaw/openclaw.json` if plugin config enablement is needed

**Files Created/Deleted/Modified:**
- Gateway/plugin config files if needed

**Status:** ⚠️ Partial / In Progress

**Results:** Installed/restored the Godot gateway extension files under `/home/derrick/.openclaw/extensions/godot/`, updated `/home/derrick/.openclaw/config/openclaw.template.json` to allow and enable the `godot` plugin, regenerated `/home/derrick/.openclaw/openclaw.json`, and performed a narrow gateway restart. `openclaw plugins list --enabled` now shows `Godot Plugin` enabled from `global:godot/index.ts`, and `openclaw godot status` reports the plugin loaded its `/godot/*` HTTP endpoints. Remaining blocker: this Codex session's `tool_search` still does not expose `godot_execute`, and `openclaw godot status` reports no connected Godot sessions. Keep bead `aerobeat-gameplay-runner-l9i` open until a fresh agent/tool surface can call `godot_execute` and verify `scene.open`, `console.getLogs`, `editor.play`, and `editor.stop` against a connected editor, or until the exact remaining OpenClaw/Codex bridge blocker is isolated.

---

### Task 2: Make the QA Gate Explicitly Reject CLI-Only Substitutions

**Bead ID:** `aerobeat-gameplay-runner-5mk`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Use `primary` as the coder role. Claim bead `aerobeat-gameplay-runner-5mk` on start with `bd update aerobeat-gameplay-runner-5mk --claim --json`. Update the owning source instructions and active runner plan so Godot runtime-scene QA/audit cannot pass with only headless import, GUT, `--quit-after`, direct script probes, or command-line scene launches when the requirement says editor fresh-open. The updated gate must require either actual `godot_execute`/editor-control evidence or an explicit Derrick-approved exception recorded in the plan/bead. It must also require screenshot/log evidence from the real editor Errors panel or `console.getLogs` after opening the exact scene. Update the built `AGENTS.md` only through the repo's normal build path if source sections change. Do not alter source code behavior in this task. Close the bead when the source instructions, built AGENTS.md, and active runner plan reflect the stricter gate.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/agents-sections/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/agents-sections/02-orchestrator-mode.md`
- `/home/derrick/.openclaw/workspace/agents-sections/05-safety.md`
- `/home/derrick/.openclaw/workspace/AGENTS.md`
- `.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Updated `/home/derrick/.openclaw/workspace/agents-sections/02-orchestrator-mode.md` and `/home/derrick/.openclaw/workspace/agents-sections/05-safety.md` so Godot runtime-scene/proving-harness/inspector/UI paths require real editor-control evidence through `godot_execute`/OpenClaw Godot tooling, or a Derrick-approved case-specific exception recorded in the plan and bead. The gate now explicitly says headless import, GUT, `--quit-after`, direct probes, and command-line scene launches are supporting evidence only and cannot satisfy a required real-editor fresh-open by themselves. It also requires the exact scene path plus editor Errors panel screenshot/log capture or `console.getLogs` after opening the scene, and keeps unexpected warnings/errors failing by default. Rebuilt `/home/derrick/.openclaw/workspace/AGENTS.md` through the normal build script and updated `REF-05` with the stricter evidence requirement. Closed bead `aerobeat-gameplay-runner-5mk`.

---

### Task 3: Reproduce Current Flow/Boxing Editor Warnings in the Real Editor

**Bead ID:** `aerobeat-gameplay-runner-31a`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-05`, `REF-06`, `REF-07`, `REF-10`  
**Prompt:** Use `primary` as the QA role. Claim bead `aerobeat-gameplay-runner-31a` on start with `bd update aerobeat-gameplay-runner-31a --claim --json`. Read the runner README. After Task 1 restores editor-control tooling, open `.testbed/project.godot` in Godot through the human-equivalent editor path, open `res://scenes/flow_playable_testbed.tscn` and `res://scenes/boxing_playable_testbed.tscn`, inspect the editor Errors panel/console logs, and capture exact warning/error text with source file/line details where available. Verify whether the warnings appear on Pico, Cookie, or both. Do not fix code in this task; produce a precise source-ownership map for every warning class.

**Folders Created/Deleted/Modified:**
- `.qa-logs/` if the repo uses committed QA evidence, otherwise `/tmp` only

**Files Created/Deleted/Modified:**
- Diagnostic logs/screenshots only if intentionally committed as plan evidence

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Fix Source-Owned Editor Warnings

**Bead ID:** `aerobeat-gameplay-runner-6n4`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-05`, `REF-10`  
**Prompt:** Use `primary` as the coder role. Claim bead `aerobeat-gameplay-runner-6n4` on start with `bd update aerobeat-gameplay-runner-6n4 --claim --json`. Fix the warning classes identified by Task 3 in their owning AeroBeat source repos, not in generated runner `.testbed/addons/` copies. Expected classes include duplicate global-class/preload-name constants, untyped loop iterators, unused variables, shadowing, and ternary typing warnings shown by Derrick's screenshot. Keep edits focused, run the relevant source repo tests/imports, sync runner addon state with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner --install --scrub-uids`, and leave all touched repos clean. Commit and push durable source fixes by default.

**Folders Created/Deleted/Modified:**
- Owning AeroBeat source repo folders identified by Task 3
- `.testbed/` generated addon state via GodotEnv sync

**Files Created/Deleted/Modified:**
- Exact list pending Task 3 warning ownership

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Full Editor QA on Pico and Cookie

**Bead ID:** `aerobeat-gameplay-runner-1hr`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-05`, `REF-10`  
**Prompt:** Use `primary` as the QA role. Claim bead `aerobeat-gameplay-runner-1hr` on start with `bd update aerobeat-gameplay-runner-1hr --claim --json`. Read the runner README. Sync Cookie using `git-sync --repo aerobeat-gameplay-runner` and `godotenv-sync --repo aerobeat-gameplay-runner --install --scrub-uids`, then verify both Pico and Cookie are on the same runner/source commits. On each machine, open the runner testbed in the real Godot editor, open Flow and Boxing playable scenes, load the matching regression song packages, select live camera where hardware allows, stop with editor controls or the approved in-engine/headless path only when applicable, and inspect editor/runtime logs. Fail QA for any warning/error in the editor Errors panel unless Derrick has granted a case-specific exception.

**Folders Created/Deleted/Modified:**
- None expected beyond generated local Godot import/addon state

**Files Created/Deleted/Modified:**
- QA logs/screenshots if retained as evidence

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Independent Audit and Gate Closure

**Bead ID:** `aerobeat-gameplay-runner-9gs`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-10`  
**Prompt:** Use `primary` as the auditor role. Claim bead `aerobeat-gameplay-runner-9gs` on start with `bd update aerobeat-gameplay-runner-9gs --claim --json`. Independently audit the OpenClaw Godot tooling repair, updated QA gate wording, source warning fixes, commits, GodotEnv sync evidence, and real-editor Flow/Boxing validation on Pico and Cookie. Close the bead only if `godot_execute` editor-control is available or the remaining limitation is explicitly escalated, the runner scenes open in the real editor with zero unexpected warnings/errors, Cookie is synced, Beads/Dolt are pushed, and all touched git repos are committed and pushed.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- This plan and affected task evidence

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ In Progress

**What We Built:** Derrick approved the repair plan and execution beads were created/dependency-linked. Gateway-side Godot plugin install/config was restored, and the QA/audit gate was tightened so CLI-only Godot evidence cannot satisfy a real-editor fresh-open requirement. The actual `godot_execute` Codex tool surface and connected editor validation remain blocked.

**Reference Check:** Initial investigation confirms the gate exists in `REF-01`/`REF-02`/`REF-03`, but the prior QA pass in `REF-04` used a weaker fallback. `REF-06`/`REF-07` show the runner already includes `AeroHeadlessManager`; gateway Godot plugin registration was restored on the gateway side, but `tool_search` still does not expose `godot_execute` in this Codex session and no Godot editor session is connected yet.

**Commits:**
- Pending.

**Lessons Learned:** The gate must distinguish "scene process launched without log warnings" from "real editor opened the exact scene and the Errors panel is clean." Those are not equivalent for Godot reload warnings.

---

*Drafted on 2026-08-11*
