# Testbed Assets

This directory is reserved for showcase scenes, UI, art, and media used by the hidden Godot testbed. Reusable package assets belong at the repo root only when downstream consumers need them.

## Copied Fixture Roots

- `songs/song_package_yaml_valid_splat_with_preview_audio/` mirrors `../aerobeat-content-core/fixtures/song_package_yaml_valid_splat_with_preview_audio/`.
- `songs/beatsaver_regression_pool/{226e,3d44b,29be2,47fb6}/` mirrors the matching folders under `../aerobeat-content-core/fixtures/beatsaver_regression_pool/`.
- `environments/workout_yaml_valid_all_kinds/` copies fixture YAML from `../aerobeat-environment-loader/.testbed/fixtures/workout_yaml_valid_all_kinds/` and media from `../aerobeat-environment-community/.testbed/assets/`.

The environment YAML files in the runner-owned copy use local `../media/...` paths. Image, video, and splat entries omit `configPath` because the selected source media has no committed config files for those assets; the GLB entry keeps its copied `alien-moon-icescape.config.yaml`.
