# AeroBeat Gameplay Runner

Reusable gameplay-session runtime package for AeroBeat mode orchestration.

## Repository Scope

This repo is a Godot addon package. The root is the reusable package boundary and contains only package code, metadata, plans, beads, CI, and documentation. It intentionally does not contain `project.godot`, `addons.jsonc`, or showcase media.

The hidden `.testbed/` directory owns local Godot project state, GodotEnv dependency restoration, showcase scenes, and tests.

## Package Surface

- `src/AeroGameplayRunner.gd` provides a facade for creating sessions, configs, and result objects.
- `src/data_types/` contains gameplay run config, result, and state constants.
- `src/interfaces/` documents the runner, clock, and input stream method contracts.
- `src/runtime/` contains the session, event dispatcher, and score aggregator.

## GodotEnv Development Flow

From the repo root:

```bash
cd .testbed
godotenv addons install
```

Run an import smoke check:

```bash
godot --headless --path .testbed --import
```

Run GUT tests:

```bash
godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

## Validation Notes

- `.testbed/addons.jsonc` is the committed dev/test dependency contract.
- `.testbed/project.godot` is the only Godot project file in this package repo.
- Downstream consumers install the package from the repo root with `subfolder: "/"`.
