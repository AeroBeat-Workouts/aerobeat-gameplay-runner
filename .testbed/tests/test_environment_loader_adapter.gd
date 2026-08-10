extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const EnvironmentLoaderAdapterScript := preload("res://scripts/environment_loader_adapter.gd")

func test_environment_descriptor_resolves_media_relative_to_descriptor_file() -> void:
	var descriptor_path := ProjectSettings.globalize_path("res://assets/environments/workout_yaml_valid_all_kinds/environments/ab-environment-image-demo.yaml")
	var adapter := EnvironmentLoaderAdapterScript.new()
	var result := adapter.build_environment_request(descriptor_path)

	assert_true(result.ok)
	assert_eq(result.loader_method, "load_environment")
	assert_eq(result.request.kind, "image")
	assert_true(String(result.request.asset_path).ends_with("/media/images/perfect-hue-may-14-2026/perfect-hue-may-14-2026.png"))
	assert_eq(result.request.metadata.environment_id, "ab-environment-image-demo")
	adapter.free()

func test_workout_yaml_routes_to_workout_loader_bridge() -> void:
	var workout_path := ProjectSettings.globalize_path("res://assets/environments/workout_yaml_valid_all_kinds/workout.yaml")
	var adapter := EnvironmentLoaderAdapterScript.new()
	var result := adapter.build_environment_request(workout_path)

	assert_true(result.ok)
	assert_eq(result.loader_method, "load_environment_from_workout_yaml")
	assert_eq(result.workout_path, workout_path)
	adapter.free()

func test_direct_environment_media_still_routes_by_kind() -> void:
	var media_path := ProjectSettings.globalize_path("res://assets/environments/workout_yaml_valid_all_kinds/media/videos/calm_blue_sea_1/calm_blue_sea_1.ogv")
	var adapter := EnvironmentLoaderAdapterScript.new()
	var result := adapter.build_environment_request(media_path)

	assert_true(result.ok)
	assert_eq(result.request.kind, "video")
	assert_eq(result.request.asset_path, media_path)
	adapter.free()
