extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const CameraSourcePickerState := preload("res://scripts/camera_source_picker_state.gd")
const PlayableTestbedHarness := preload("res://scripts/playable_testbed_harness.gd")

func test_live_camera_settings_are_ready_for_provider_registration() -> void:
	var picker := CameraSourcePickerState.new()
	picker.select_live("2")
	var settings := picker.provider_settings()

	assert_true(picker.is_configured())
	assert_eq(settings.camera_source, "2")
	assert_eq(settings.selected_camera_device_id, "2")
	assert_eq(settings.source.kind, CameraSourcePickerState.MODE_LIVE)
	assert_eq(settings.source.camera_id, "2")

func test_replay_video_settings_pass_local_path_to_provider() -> void:
	var picker := CameraSourcePickerState.new()
	picker.select_replay("/tmp/aerobeat/replay.mp4")
	var settings := picker.provider_settings()

	assert_true(picker.is_configured())
	assert_eq(settings.camera_source, "/tmp/aerobeat/replay.mp4")
	assert_eq(settings.selected_camera_device_id, "/tmp/aerobeat/replay.mp4")
	assert_eq(settings.source.kind, CameraSourcePickerState.MODE_REPLAY)
	assert_eq(settings.source.path, "/tmp/aerobeat/replay.mp4")

func test_empty_replay_path_is_not_configured() -> void:
	var picker := CameraSourcePickerState.new()
	picker.select_replay(" ")

	assert_false(picker.is_configured())
	assert_true(picker.provider_settings().is_empty())

func test_playable_targets_are_copied_into_typed_dictionary_array() -> void:
	var source := [{"id": "a"}, "skip", {"id": "b"}]
	var targets: Array[Dictionary] = PlayableTestbedHarness.dictionary_array(source)

	assert_eq(targets.size(), 2)
	assert_eq(targets[0].id, "a")
	assert_eq(targets[1].id, "b")

	source[0].id = "changed"
	assert_eq(targets[0].id, "a")
