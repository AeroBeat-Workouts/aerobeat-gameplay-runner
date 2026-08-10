extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const PlayableContentLoaderScript := preload("res://scripts/playable_content_loader.gd")

func test_song_load_reports_available_modes_when_scene_mode_is_missing() -> void:
	var package_path := ProjectSettings.globalize_path("res://assets/songs/beatsaver_regression_pool/29be2/song.package.yaml")
	var result := PlayableContentLoaderScript.new().load_package(package_path, "boxing")

	assert_false(result.ok)
	assert_eq(result.error, "chart_for_mode_missing")
	assert_eq(result.available_modes, ["flow"])
	assert_true(String(result.message).contains("flow/ExpertPlus"))
	assert_true(String(result.message).contains("boxing"))

func test_song_load_keeps_exact_mode_match_and_exposes_selected_difficulty() -> void:
	var package_path := ProjectSettings.globalize_path("res://assets/songs/song_package_yaml_valid_splat_with_preview_audio/song.package.yaml")
	var result := PlayableContentLoaderScript.new().load_package(package_path, "boxing")

	assert_true(result.ok)
	assert_eq(result.mode, "boxing")
	assert_eq(result.difficulty, "Normal")
	assert_eq(result.available_modes, ["boxing"])
	assert_true(result.events.size() > 0)

