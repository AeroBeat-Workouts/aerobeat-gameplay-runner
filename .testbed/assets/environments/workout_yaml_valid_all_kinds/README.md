# workout_yaml_valid_all_kinds

Runner-local copy of the environment-loader all-kind workout fixture.

This copy keeps one set each for image, video, GLB, and gaussian splat loading. The environment YAML files point at sibling media under `../media/...` so the gameplay-runner testbed can load the fixture without depending on neighboring source repos.

Only the GLB environment keeps a `configPath`, because the copied `alien-moon-icescape` source includes a committed config sidecar. The selected image, video, and splat source assets do not have committed configs, so their runner-local environment YAML omits `configPath`.
