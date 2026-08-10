# AeroBeat Gameplay Runner Testbed Song And Environment Assets

**Date:** 2026-08-10  
**Status:** In Progress  
**Last Updated:** 2026-08-10 11:55 EDT  
**Blocked Reason:** None  
**Agent:** pico

---

## Goal

Copy curated AeroBeat song packages and environment media/config fixtures from the existing polyrepos into `aerobeat-gameplay-runner/.testbed/assets/` so gameplay-runner tests and manual testbeds can reference stable local assets.

---

## Overview

The gameplay-runner testbed currently has `res://assets/` reserved for local showcase/test assets, but it only contains the hit SFX placeholder set. Existing song package fixtures already live in `aerobeat-content-core`, and existing environment media assets live in `aerobeat-environment-community`; environment YAML examples live in `aerobeat-environment-loader`.

This plan stages copied assets under explicit runner-owned folders rather than adding cross-repo runtime dependencies to the testbed file dialogs. The intended destination shape is `res://assets/songs/...` for song packages and `res://assets/environments/...` for environment YAML plus media payloads. Source paths should be copied non-interactively with overwrite-safe commands such as `cp -rf` or scripted equivalent, then verified through fresh Godot import/test logs with zero warnings/errors.

The first slice should focus on a small curated set that is useful for boxing/flow runner testing: one lightweight hand-authored splat song package with preview metadata, a few BeatSaver regression packages covering boxing and flow, and representative environment assets for image, video, GLB, and gaussian splat loading. If execution discovers that source fixture YAML points at stale or differently-cased media paths, fix the copied runner fixture paths in the runner-owned copy while leaving upstream repos untouched unless a true source bug is found.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Gameplay-runner testbed asset policy | `.testbed/assets/README.md` |
| `REF-02` | Gameplay-runner GodotEnv dependency contract | `.testbed/addons.jsonc` |
| `REF-03` | Playable boxing testbed scene with Song and Environment file pickers | `.testbed/scenes/boxing_playable_testbed.tscn` |
| `REF-04` | Environment loader adapter and supported environment file handling | `.testbed/scripts/environment_loader_adapter.gd` |
| `REF-05` | Hand-authored valid splat song package with preview metadata | `../aerobeat-content-core/fixtures/song_package_yaml_valid_splat_with_preview_audio/` |
| `REF-06` | BeatSaver regression song package pool | `../aerobeat-content-core/fixtures/beatsaver_regression_pool/` |
| `REF-07` | Environment loader all-kind YAML fixture package | `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/` |
| `REF-08` | Existing environment media assets: images, videos, GLB models, gaussian splats | `../aerobeat-environment-community/.testbed/assets/` |

---

## Tasks

### Task 1: Inventory And Select Testbed Asset Set

**Bead ID:** `aerobeat-gameplay-runner-lxa`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Spawn a `primary` SubAgent in the `research` role. It must read `README.md` in `aerobeat-gameplay-runner` before touching the repo, claim `aerobeat-gameplay-runner-lxa`, inventory the exact source files for the runner-local song/environment asset copy, and update the plan with the selected source/destination mapping. It should prefer a minimal but useful set: `song_package_yaml_valid_splat_with_preview_audio`, two to four BeatSaver regression packages covering boxing and flow, and representative image/video/GLB/splat environment assets. It should flag path mismatches such as environment YAML references that do not match committed media names.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/songs/`
- `.testbed/assets/environments/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-10-testbed-song-environment-assets.md`

**Status:** ✅ Complete

**Results:** Selected a minimal runner-local copy set. No assets were copied in this research step.

Song package mappings:

| Source | Destination | Notes |
| --- | --- | --- |
| `../aerobeat-content-core/fixtures/song_package_yaml_valid_splat_with_preview_audio/song.package.yaml` | `.testbed/assets/songs/song_package_yaml_valid_splat_with_preview_audio/song.package.yaml` | Hand-authored splat demo package with boxing Normal/Hard charts and preview metadata. Source package references `media/cover/splat-demo-cover.png`, `media/audio/splat-demo.ogg`, and `media/audio/splat-demo-preview.ogg`, but the fixture directory currently commits only YAML files. |
| `../aerobeat-content-core/fixtures/song_package_yaml_valid_splat_with_preview_audio/charts/ab-chart-splat-demo-boxing-normal.yaml` | `.testbed/assets/songs/song_package_yaml_valid_splat_with_preview_audio/charts/ab-chart-splat-demo-boxing-normal.yaml` | Boxing Normal. |
| `../aerobeat-content-core/fixtures/song_package_yaml_valid_splat_with_preview_audio/charts/ab-chart-splat-demo-boxing-hard.yaml` | `.testbed/assets/songs/song_package_yaml_valid_splat_with_preview_audio/charts/ab-chart-splat-demo-boxing-hard.yaml` | Boxing Hard. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/226e/song.package.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/226e/song.package.yaml` | BeatSaver `226e`, Linkin Park/Rock Alternative, boxing Expert. Synthetic metadata/chart slice only; referenced placeholder audio is not committed in the source fixture. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/226e/charts/ab-chart-beatsaver-226e-boxing-expert.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/226e/charts/ab-chart-beatsaver-226e-boxing-expert.yaml` | Boxing Expert. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/3d44b/song.package.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/3d44b/song.package.yaml` | BeatSaver `3d44b`, Game Grumps/NSP meme reference, boxing Normal. Synthetic metadata/chart slice only; referenced placeholder audio is not committed in the source fixture. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/3d44b/charts/ab-chart-beatsaver-3d44b-boxing-normal.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/3d44b/charts/ab-chart-beatsaver-3d44b-boxing-normal.yaml` | Boxing Normal. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/29be2/song.package.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/29be2/song.package.yaml` | BeatSaver `29be2`, Sonic/Heavy Metal/Rock, flow ExpertPlus. Synthetic metadata/chart slice only; referenced placeholder audio is not committed in the source fixture. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/29be2/charts/ab-chart-beatsaver-29be2-flow-expertplus.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/29be2/charts/ab-chart-beatsaver-29be2-flow-expertplus.yaml` | Flow ExpertPlus. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/47fb6/song.package.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/47fb6/song.package.yaml` | BeatSaver `47fb6`, Kpop Demon Hunters/K-Pop, flow Normal. Synthetic metadata/chart slice only; referenced placeholder audio is not committed in the source fixture. |
| `../aerobeat-content-core/fixtures/beatsaver_regression_pool/47fb6/charts/ab-chart-beatsaver-47fb6-flow-normal.yaml` | `.testbed/assets/songs/beatsaver_regression_pool/47fb6/charts/ab-chart-beatsaver-47fb6-flow-normal.yaml` | Flow Normal. |

Environment fixture mappings:

| Source | Destination | Notes |
| --- | --- | --- |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/README.md` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/README.md` | Fixture index. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/workout.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/workout.yaml` | Includes image, video, GLB, and splat set order. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/sets/ab-set-image-demo-round.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/sets/ab-set-image-demo-round.yaml` | Image set. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/sets/ab-set-video-demo-round.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/sets/ab-set-video-demo-round.yaml` | Video set. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/sets/ab-set-glb-demo-round.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/sets/ab-set-glb-demo-round.yaml` | GLB set. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/sets/ab-set-splat-demo-round.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/sets/ab-set-splat-demo-round.yaml` | Splat set; fallback points at the image environment. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/environments/ab-environment-image-demo.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/environments/ab-environment-image-demo.yaml` | Runner copy should rewrite `resourcePath` to `../media/images/perfect-hue-may-14-2026/perfect-hue-may-14-2026.png`. Source YAML currently points at `../../assets/images/perfect-hue-may-14-2026.png`, but committed media is nested one directory deeper. Source `configPath` points at a non-committed config file. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/environments/ab-environment-video-demo.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/environments/ab-environment-video-demo.yaml` | Runner copy should rewrite `resourcePath` to `../media/videos/calm_blue_sea_1/calm_blue_sea_1.ogv`. Source YAML currently points at `../../assets/videos/calm_blue_sea_1.ogv`, but committed media is nested one directory deeper. Source `configPath` points at a non-committed config file. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/environments/ab-environment-glb-demo.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/environments/ab-environment-glb-demo.yaml` | Runner copy should rewrite `resourcePath` to `../media/models/alien-moon-icescape/alien-moon-icescape.glb` and `configPath` to `../media/models/alien-moon-icescape/alien-moon-icescape.config.yaml` to use the only committed GLB config found in the community assets. Source YAML points at root-level `alien-planet.glb`/`alien-planet.config.yaml`; committed `alien-planet` media is nested and has no config file. |
| `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/environments/ab-environment-splat-demo.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/environments/ab-environment-splat-demo.yaml` | Runner copy should rewrite `resourcePath` to `../media/splats/countryside-farm/countryside-farm.compressed.ply`. Source YAML currently points at `../../assets/splats/CountrySide farm.compressed.ply`, but committed media is lowercase hyphenated and nested. Source `configPath` points at a non-committed config file. |
| `../aerobeat-environment-community/.testbed/assets/images/perfect-hue-may-14-2026/perfect-hue-may-14-2026.png` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/images/perfect-hue-may-14-2026/perfect-hue-may-14-2026.png` | Representative image background media. Do not copy `.import`; let runner testbed import regenerate it. |
| `../aerobeat-environment-community/.testbed/assets/videos/calm_blue_sea_1/calm_blue_sea_1.ogv` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/videos/calm_blue_sea_1/calm_blue_sea_1.ogv` | Representative video background media. Do not copy `.uid`; let runner testbed import/regenerate local IDs if needed. |
| `../aerobeat-environment-community/.testbed/assets/models/alien-moon-icescape/alien-moon-icescape.glb` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/models/alien-moon-icescape/alien-moon-icescape.glb` | Representative GLB media with a committed config file. |
| `../aerobeat-environment-community/.testbed/assets/models/alien-moon-icescape/alien-moon-icescape.config.yaml` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/models/alien-moon-icescape/alien-moon-icescape.config.yaml` | GLB transform config. |
| `../aerobeat-environment-community/.testbed/assets/models/alien-moon-icescape/alien-moon-icescape_0.png` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/models/alien-moon-icescape/alien-moon-icescape_0.png` | GLB texture payload. Do not copy `.import`; let runner testbed import regenerate it. |
| `../aerobeat-environment-community/.testbed/assets/splats/countryside-farm/countryside-farm.compressed.ply` | `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/splats/countryside-farm/countryside-farm.compressed.ply` | Representative gaussian splat media. No committed splat config was found for this asset; runner copy should remove `configPath` if the loader treats it as optional, or add a runner-owned minimal config in Task 2 if required. |

Path mismatch notes:

- The environment YAML files in `workout_yaml_valid_all_kinds/environments/` currently use `../../assets/...` paths that do not match the committed community media layout. The runner-owned copies should be rewritten to point at the destination `../media/...` paths above.
- Image and video media are nested under `images/perfect-hue-may-14-2026/` and `videos/calm_blue_sea_1/`, while the loader YAML references flat filenames.
- The GLB YAML references `alien-planet.config.yaml`, but the only committed model config discovered is `models/alien-moon-icescape/alien-moon-icescape.config.yaml`; use `alien-moon-icescape` for the runner-local GLB fixture.
- The splat YAML references `CountrySide farm.compressed.ply` and `CountrySide farm.config.yaml`; the committed media is `splats/countryside-farm/countryside-farm.compressed.ply`, and no matching config file was found.
- Selected song packages are YAML-only contract fixtures. Their `song.package.yaml` files reference placeholder audio and, for the splat demo, cover/preview files that are not committed under the source fixture directories.

---

### Task 2: Copy Curated Assets Into Gameplay Runner Testbed

**Bead ID:** `aerobeat-gameplay-runner-rxr`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Spawn a `primary` SubAgent in the `coder` role. It must read `README.md` in `aerobeat-gameplay-runner` before touching the repo, claim `aerobeat-gameplay-runner-rxr`, copy the selected AeroBeat song packages and environment assets into `.testbed/assets/` using non-interactive overwrite-safe file operations, and keep destination paths deterministic. It should add or update a concise README/index under `.testbed/assets/` documenting the copied fixture roots and source repos. If copied environment YAML needs runner-local `resourcePath` or `configPath` values, adjust only the runner-owned copies. Run repo-local validation, including `godot --headless --path .testbed --import`, and resolve all warning/error noise before handoff. Commit and push by default.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/songs/`
- `.testbed/assets/environments/`

**Files Created/Deleted/Modified:**
- `.testbed/assets/README.md`
- `.testbed/assets/songs/**`
- `.testbed/assets/environments/**`
- `.plans/2026-08-10-testbed-song-environment-assets.md`

**Status:** ✅ Complete

**Results:** Copied the curated runner-local asset fixtures into `.testbed/assets/` with deterministic paths.

Folders changed:

- Created `.testbed/assets/songs/song_package_yaml_valid_splat_with_preview_audio/` from `../aerobeat-content-core/fixtures/song_package_yaml_valid_splat_with_preview_audio/`.
- Created `.testbed/assets/songs/beatsaver_regression_pool/{226e,3d44b,29be2,47fb6}/` from the matching `../aerobeat-content-core/fixtures/beatsaver_regression_pool/` folders.
- Created `.testbed/assets/environments/workout_yaml_valid_all_kinds/{sets/,environments/,media/}` from the selected environment-loader fixture YAML and environment-community media payloads.

Files changed:

- Updated `.testbed/assets/README.md` with a concise index of copied fixture roots and source repos/paths.
- Added the copied song YAML files under `.testbed/assets/songs/song_package_yaml_valid_splat_with_preview_audio/` and `.testbed/assets/songs/beatsaver_regression_pool/{226e,3d44b,29be2,47fb6}/`.
- Added `.testbed/assets/environments/workout_yaml_valid_all_kinds/{README.md,workout.yaml,sets/*.yaml,environments/*.yaml}`.
- Added environment media payloads under `.testbed/assets/environments/workout_yaml_valid_all_kinds/media/`: `images/perfect-hue-may-14-2026/perfect-hue-may-14-2026.png`, `videos/calm_blue_sea_1/calm_blue_sea_1.ogv`, `models/alien-moon-icescape/{alien-moon-icescape.glb,alien-moon-icescape.config.yaml,alien-moon-icescape_0.png}`, and `splats/countryside-farm/countryside-farm.compressed.ply`.
- Kept runner-local Godot-generated media sidecars after import for the copied image/model/video assets; upstream `.import` and `.uid` files were not copied.
- Rewrote only the runner-owned environment YAML files: image/video/splat `resourcePath` values now point at local `../media/...` payloads and omit missing optional `configPath`; GLB points at local `alien-moon-icescape` `.glb` and `.config.yaml`.
- Updated `.testbed/assets/environments/workout_yaml_valid_all_kinds/README.md` so the copied fixture documentation matches the runner-local media layout.
- Updated this plan file.

Validation evidence:

- `godot --headless --path .testbed --import` passed with exit code 0. First run imported the new PNG/GLB/texture assets with no warning/error/missing lines in `/tmp/aerobeat_gameplay_runner_import.log`; second run had no reimport work and no warning/error/missing lines in `/tmp/aerobeat_gameplay_runner_import_second.log`.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` passed with 20/20 tests and 206 assertions in `/tmp/aerobeat_gameplay_runner_gut.log`.
- Fresh Godot app log at `$HOME/.local/share/godot/app_userdata/AeroBeat Gameplay Runner Testbed/logs/godot.log` was inspected and had no warning/error/missing lines.
- Local path check verified every `resourcePath` and `configPath` in `.testbed/assets/environments/workout_yaml_valid_all_kinds/environments/*.yaml` resolves to a copied runner-local file.

---

### Task 3: QA Runner Asset Access In Highest-Fidelity Available Testbed

**Bead ID:** `aerobeat-gameplay-runner-gzm`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Spawn a `primary` SubAgent in the `qa` role. It must read `README.md` in `aerobeat-gameplay-runner` before touching the repo, claim `aerobeat-gameplay-runner-gzm`, install/refresh `.testbed` addons if needed, run the gameplay-runner test suite, and verify that the copied song and environment fixtures are visible and loadable from the runner testbed paths. Because this touches Godot runtime/testbed paths, perform a fresh testbed scene-open or highest-fidelity available equivalent and inspect fresh editor/runtime logs. QA fails on any warning/error/import noise unless Derrick grants a case-specific exception for the exact noise.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-10-testbed-song-environment-assets.md`

**Status:** ✅ Complete

**Results:** QA passed. The `.testbed` addons were already present as the expected symlink-backed GodotEnv addon set, so no refresh/install was needed.

Validation commands and logs:

- `godot --headless --path .testbed --import > /tmp/aerobeat_gameplay_runner_qa_import.log 2>&1` passed with exit code 0.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit > /tmp/aerobeat_gameplay_runner_qa_gut.log 2>&1` passed with exit code 0: 20/20 tests and 206 assertions.
- Temporary highest-fidelity asset-access validation script run with `godot --headless --path .testbed --script res://tests/qa_asset_access_validation.gd > /tmp/aerobeat_gameplay_runner_qa_asset_access.log 2>&1` passed with exit code 0. The temporary script was removed after recording evidence and was not left in the repo.
- Fresh runtime/editor log inspected at `$HOME/.local/share/godot/app_userdata/AeroBeat Gameplay Runner Testbed/logs/godot.log`.
- Noise scan command `rg -n "(?i)(warning|error|failed|missing|parse error|script error|import.*fail|can't|cannot)" /tmp/aerobeat_gameplay_runner_qa_import.log /tmp/aerobeat_gameplay_runner_qa_gut.log /tmp/aerobeat_gameplay_runner_qa_asset_access.log` returned no matches.
- Noise scan command `rg -n "(?i)(warning|error|failed|missing|parse error|script error|import.*fail|can't|cannot)" "$HOME/.local/share/godot/app_userdata/AeroBeat Gameplay Runner Testbed/logs/godot.log"` returned no matches.

Fixture access evidence:

- Verified `res://assets/songs` and `res://assets/environments/workout_yaml_valid_all_kinds` are visible from the testbed project.
- Verified `res://scenes/boxing_playable_testbed.tscn` and `res://scenes/flow_playable_testbed.tscn` load as `PackedScene` and instantiate in a fresh headless testbed scene run.
- Verified all copied song packages are visible, validate through `ContentPackageValidator.validate_song_package_yaml_package(...)`, parse through `SimpleYamlParser`, expose visible chart YAML files, and load through `.testbed/scripts/playable_content_loader.gd` for their runner mode:
  - `res://assets/songs/song_package_yaml_valid_splat_with_preview_audio/song.package.yaml` for boxing.
  - `res://assets/songs/beatsaver_regression_pool/226e/song.package.yaml` for boxing.
  - `res://assets/songs/beatsaver_regression_pool/29be2/song.package.yaml` for flow.
  - `res://assets/songs/beatsaver_regression_pool/3d44b/song.package.yaml` for boxing.
  - `res://assets/songs/beatsaver_regression_pool/47fb6/song.package.yaml` for flow.
- Confirmed those copied song package YAML files still point at upstream-placeholder audio paths that are not committed in the source fixtures; the runner content-loader path/parse validation succeeds and audio playback was not treated as available for those YAML-only contract fixtures.
- Verified `res://assets/environments/workout_yaml_valid_all_kinds/workout.yaml` is visible.
- Verified all copied environment YAML files parse and every runner-local `resourcePath`/`configPath` target resolves:
  - Image `resourcePath` resolves to `res://assets/environments/workout_yaml_valid_all_kinds/media/images/perfect-hue-may-14-2026/perfect-hue-may-14-2026.png`.
  - Video `resourcePath` resolves to `res://assets/environments/workout_yaml_valid_all_kinds/media/videos/calm_blue_sea_1/calm_blue_sea_1.ogv`.
  - GLB `resourcePath` resolves to `res://assets/environments/workout_yaml_valid_all_kinds/media/models/alien-moon-icescape/alien-moon-icescape.glb`.
  - GLB `configPath` resolves to `res://assets/environments/workout_yaml_valid_all_kinds/media/models/alien-moon-icescape/alien-moon-icescape.config.yaml`.
  - Splat `resourcePath` resolves to `res://assets/environments/workout_yaml_valid_all_kinds/media/splats/countryside-farm/countryside-farm.compressed.ply`.
- Verified the copied image, video, GLB, and splat media load through `.testbed/scripts/environment_loader_adapter.gd` and the real `AeroEnvironmentLoader` from runner-local `res://assets/...` paths, each reaching `environment_load_succeeded`.

---

### Task 4: Independent Audit, Bead Closure, And Cookie Sync

**Bead ID:** `aerobeat-gameplay-runner-nyf`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Spawn a `primary` SubAgent in the `auditor` role. It must read `README.md` in `aerobeat-gameplay-runner` before touching the repo, claim `aerobeat-gameplay-runner-nyf`, independently verify the copied assets against the plan and source refs, review the diff and validation evidence, and close the bead only if the runner testbed has clean local song/environment assets and zero warning/error validation logs. After audit passes, the orchestrator must sync Cookie using the AeroBeat sync workflow Derrick requested: run `git-sync --all-aerobeat` and `godotenv-sync --all-aerobeat --install --scrub-uids`, clean only safe generated testbed noise if produced, and verify Cookie's relevant runner/source checkouts are clean and at `origin/main`.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/`

**Files Created/Deleted/Modified:**
- `.plans/2026-08-10-testbed-song-environment-assets.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft plan only. No assets have been copied yet.

**Reference Check:** Source assets located in `REF-05` through `REF-08`; execution still needs to select the curated subset and verify runner-local paths.

**Commits:** Pending.

**Lessons Learned:** The runner testbed asset folder already exists and is intentionally scoped to local showcase/test media, making it the right place for copied fixtures rather than reusable package assets.

---

*Completed on Pending*
