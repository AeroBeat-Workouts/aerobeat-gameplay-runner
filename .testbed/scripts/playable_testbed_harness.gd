extends Node3D

const ConfigLoader := preload("res://scripts/playable_config_loader.gd")
const PlayfieldMapperScript := preload("res://scripts/playfield_mapper.gd")
const AudioClock := preload("res://scripts/audio_loader_clock.gd")
const InputStream := preload("res://scripts/input_manager_stream.gd")
const ContentLoader := preload("res://scripts/playable_content_loader.gd")
const EnvironmentAdapter := preload("res://scripts/environment_loader_adapter.gd")
const TargetRegions := preload("res://scripts/playable_target_regions.gd")
const CameraSourcePickerState := preload("res://scripts/camera_source_picker_state.gd")
const CameraTrackingConfigScript := preload("res://addons/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd")
const GameplayRunConfig := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_config.gd")
const GameplayRunState := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_state.gd")
const GameplaySession := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_session.gd")
const BoxingModeRunner := preload("res://addons/aerobeat-mode-boxing/src/boxing_mode_runner.gd")
const FlowModeRunner := preload("res://addons/aerobeat-mode-flow/src/flow_mode_runner.gd")
const InputManagerScript := preload("res://addons/aerobeat-input-core/src/input_manager.gd")
const CameraTrackingInputProviderScript := preload("res://addons/aerobeat-input-camera-tracking/src/input_provider.gd")
const AeroAudioLoaderScript := preload("res://addons/aerobeat-tool-audio-player/src/AeroAudioLoader.gd")
const ModeJudgementEvent := preload("res://addons/aerobeat-mode-core/src/data_types/mode_judgement_event.gd")

@export_enum("flow", "boxing") var mode_id := "flow"

var _config := {}
var _mapper: PlayfieldMapper
var _target_regions: RefCounted
var _session: RefCounted = null
var _clock: RefCounted = null
var _input_stream: RefCounted = null
var _input_manager: Node = null
var _camera_source: RefCounted = null
var _camera_provider_registered := false
var _audio_loader: Node = null
var _environment_adapter: Node = null
var _loaded_content := {}
var _targets: Array[Dictionary] = []
var _target_nodes := {}
var _calibration_started_playback := false
var _paused_for_recalibration := false
var _overlay_visible_until_ms := 0

@onready var _player_rig: Node3D = %PlayerRig
@onready var _camera: Camera3D = %Camera3D
@onready var _targets_root: Node3D = %Targets
@onready var _grid_root: Node3D = %Grid
@onready var _markers_root: Node3D = %Markers
@onready var _environment_canvas: Control = %EnvironmentCanvas
@onready var _environment_world: Node3D = %EnvironmentWorld
@onready var _hud: Label = %HudLabel
@onready var _summary: Label = %SummaryLabel
@onready var _camera_source_label: Label = %CameraSourceLabel
@onready var _song_dialog: FileDialog = %SongDialog
@onready var _environment_dialog: FileDialog = %EnvironmentDialog
@onready var _replay_video_dialog: FileDialog = %ReplayVideoDialog

func _ready() -> void:
	_config = ConfigLoader.new().load_config()
	_mapper = PlayfieldMapperScript.new(_config)
	_target_regions = TargetRegions.new(_mapper.columns, _mapper.rows)
	_camera_source = CameraSourcePickerState.new()
	_camera.transform = _mapper.get_camera_start_transform()
	_audio_loader = AeroAudioLoaderScript.new()
	_audio_loader.name = "AeroAudioLoader"
	add_child(_audio_loader)
	_clock = AudioClock.new(_audio_loader, String(_config.get("audio", {}).get("music_slot", "default")))
	_input_stream = InputStream.new()
	_setup_input()
	_setup_environment()
	_build_grid()
	_setup_dialogs()
	_update_camera_source_label()
	_update_hud("Choose camera source, song package, and environment, then T-pose to calibrate.")

func _process(delta: float) -> void:
	_update_player_rig_from_nose()
	_update_debug_markers()
	if _session != null and _session.get_state() == GameplayRunState.RUNNING:
		var emitted: Array = _session.tick(delta)
		_apply_judgements(emitted)
		_update_targets(float(_clock.get_position_sec()))
		if _session.get_state() == GameplayRunState.COMPLETED:
			_finish_session()

func _setup_input() -> void:
	_input_manager = InputManagerScript.new()
	_input_manager.name = "InputManager"
	add_child(_input_manager)
	if DisplayServer.get_name() == "headless":
		_update_hud("Headless run: camera provider registration waits for an editor/runtime source selection.")
		_input_stream.bind(_input_manager, _clock)
		return
	_input_stream.bind(_input_manager, _clock)
	_input_manager.body_grid_calibration_started.connect(_on_calibration_started)
	_input_manager.body_grid_calibration_succeeded.connect(_on_calibration_succeeded)
	_input_manager.body_grid_calibration_failed.connect(_on_calibration_failed)
	_input_manager.body_grid_calibration_canceled.connect(_on_calibration_canceled)

func _setup_environment() -> void:
	_environment_adapter = EnvironmentAdapter.new()
	add_child(_environment_adapter)
	_environment_adapter.setup(_environment_canvas, _environment_world)
	_environment_adapter.status_changed.connect(func(message: String) -> void:
		_update_hud(message)
	)

func _setup_dialogs() -> void:
	_song_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_song_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_song_dialog.filters = PackedStringArray(["song.package.yaml ; AeroBeat song package"])
	_song_dialog.file_selected.connect(func(path: String) -> void:
		_load_song(path)
	)
	_environment_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_environment_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_environment_dialog.filters = PackedStringArray(["*.yaml,*.yml,*.png,*.ogv,*.glb,*.compressed.ply ; AeroBeat environments"])
	_environment_dialog.file_selected.connect(func(path: String) -> void:
		_environment_adapter.load_environment_file(path)
	)
	_replay_video_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_replay_video_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_replay_video_dialog.filters = PackedStringArray(["*.mp4,*.mov,*.mkv,*.webm,*.ogv,*.avi ; Replay video files"])
	_replay_video_dialog.file_selected.connect(func(path: String) -> void:
		_select_replay_video_source(path)
	)
	%LiveCameraButton.pressed.connect(func() -> void: _select_live_camera_source())
	%ReplayVideoButton.pressed.connect(func() -> void: _replay_video_dialog.popup_centered_ratio(0.75))
	%PickSongButton.pressed.connect(func() -> void: _song_dialog.popup_centered_ratio(0.75))
	%PickEnvironmentButton.pressed.connect(func() -> void: _environment_dialog.popup_centered_ratio(0.75))
	%CalibrateButton.pressed.connect(_request_calibration)

func _load_song(path: String) -> void:
	_loaded_content = ContentLoader.new().load_package(path, mode_id)
	if not bool(_loaded_content.get("ok", false)):
		_update_hud("Song load failed: %s" % _song_load_error_text(_loaded_content))
		return
	_targets = dictionary_array(_loaded_content.get("events", []))
	_build_target_nodes()
	var audio_path := String(_loaded_content.get("audio_path", ""))
	if not audio_path.is_empty():
		_audio_loader.load({"kind": "file", "path": audio_path}, String(_config.get("audio", {}).get("music_slot", "default")))
	_load_hit_sfx()
	var difficulty := String(_loaded_content.get("difficulty", "")).strip_edges()
	var difficulty_text := " %s" % difficulty if not difficulty.is_empty() else ""
	_update_hud("Loaded %s%s chart with %d events. T-pose calibration starts playback." % [mode_id, difficulty_text, _targets.size()])

func _request_calibration() -> void:
	if _session != null and _session.get_state() == GameplayRunState.RUNNING:
		_pause_for_recalibration()
	if not _ensure_input_provider_registered():
		return
	if _input_manager != null and _input_manager.has_method("start_calibration"):
		if not _input_manager.start_calibration():
			_update_hud("Calibration request unavailable. %s" % _camera_tracking_diagnostics_text())

func _on_calibration_started(_event: Dictionary) -> void:
	if _session != null and _session.get_state() == GameplayRunState.RUNNING:
		_pause_for_recalibration()
	_update_hud("Calibration running...")

func _on_calibration_succeeded(_event: Dictionary) -> void:
	_overlay_visible_until_ms = Time.get_ticks_msec() + int(_config.get("debug", {}).get("body_grid_pose_visible_after_calibration_ms", 2000))
	if _session == null:
		_start_session()
	elif _paused_for_recalibration:
		_resume_after_recalibration()
	_update_hud("Calibration succeeded.")

func _on_calibration_failed(event: Dictionary) -> void:
	_paused_for_recalibration = true
	_update_hud("Calibration failed: %s Audio/gameplay remain paused." % _camera_error_text(event))

func _on_calibration_canceled(_event: Dictionary) -> void:
	_paused_for_recalibration = true
	_update_hud("Calibration canceled; audio/gameplay remain paused.")

func _start_session() -> void:
	if not bool(_loaded_content.get("ok", false)):
		_update_hud("Load a song package before playback.")
		return
	_session = GameplaySession.new()
	var config := GameplayRunConfig.new({
		"mode_id": mode_id,
		"chart_id": String(_loaded_content.get("chart_id", "playable_chart")),
		"chart_data": _mode_chart_data(),
		"metadata": {"runner_testbed": true, "clock_authority": "aero_audio_loader"}
	})
	var runner: Variant = BoxingModeRunner.new() if mode_id == "boxing" else FlowModeRunner.new()
	_session.start(config, runner, _clock, _input_stream)
	_audio_loader.play(String(_config.get("audio", {}).get("music_slot", "default")))
	_summary.text = ""
	_update_hud("Playing %s from audio clock." % mode_id)

func _pause_for_recalibration() -> void:
	if _session != null:
		_session.pause()
	_audio_loader.pause(String(_config.get("audio", {}).get("music_slot", "default")))
	_paused_for_recalibration = true

func _resume_after_recalibration() -> void:
	if _session != null:
		_session.resume()
	_audio_loader.resume(String(_config.get("audio", {}).get("music_slot", "default")))
	_paused_for_recalibration = false

func _finish_session() -> void:
	_session.stop("complete")
	var summary: Dictionary = _session.get_score_summary()
	_audio_loader.stop(String(_config.get("audio", {}).get("music_slot", "default")))
	_summary.text = "Complete  Hits: %d  Misses: %d  Score: %d" % [summary.get("hits", 0), summary.get("misses", 0), summary.get("score", 0)]
	_update_hud("Complete.")

func _select_live_camera_source(camera_id: String = "0") -> void:
	if _camera_source == null:
		return
	_camera_source.select_live(camera_id)
	_reset_camera_provider_registration()
	_update_camera_source_label()
	_update_hud("Live camera selected. T-pose will register camera tracking before calibration.")

func _select_replay_video_source(path: String) -> void:
	if _camera_source == null:
		return
	_camera_source.select_replay(path)
	_reset_camera_provider_registration()
	_update_camera_source_label()
	_update_hud("Replay video selected. T-pose will pass the local path into camera tracking before calibration.")

func _reset_camera_provider_registration() -> void:
	if _camera_provider_registered and _input_manager != null and _input_manager.has_method("unregister_provider"):
		_input_manager.unregister_provider("camera_tracking")
	_camera_provider_registered = false

func _ensure_input_provider_registered() -> bool:
	if _input_manager == null:
		_update_hud("Input manager unavailable.")
		return false
	if _camera_source == null or not _camera_source.is_configured():
		_update_hud("Choose a live camera or replay video before calibration.")
		return false
	if DisplayServer.get_name() == "headless":
		_update_hud("Headless run: camera provider registration skipped; open the scene in the editor/runtime for camera calibration.")
		return false
	if _camera_provider_registered:
		return true
	var settings: Dictionary = _camera_source.provider_settings()
	var provider := CameraTrackingInputProviderScript.new()
	provider.name = "CameraTrackingInputProvider"
	var tracking_singleton := _prepare_camera_tracking_runtime(settings)
	if tracking_singleton != null and provider.has_method("set_tracking_session") and tracking_singleton.has_method("get_tracking_session_if_ready"):
		var tracking_session: Node = tracking_singleton.get_tracking_session_if_ready()
		if tracking_session != null:
			provider.set_tracking_session(tracking_session)
	if provider.has_method("set_selected_camera_device_id"):
		provider.set_selected_camera_device_id(String(settings.get("camera_source", "")))
	if not _input_manager.register_provider(provider, settings):
		_update_hud("Camera input provider unavailable for %s. %s" % [_camera_source.status_text(), _camera_tracking_diagnostics_text()])
		return false
	_camera_provider_registered = true
	_update_hud("Camera input provider registered with %s. %s" % [_camera_source.status_text(), _camera_tracking_diagnostics_text()])
	return true

func _prepare_camera_tracking_runtime(settings: Dictionary) -> Node:
	var tracking_singleton := get_node_or_null("/root/AeroCameraTracking")
	if tracking_singleton == null:
		_update_hud("AeroCameraTracking singleton unavailable; camera addon may not be enabled.")
		return null
	var runtime_config := _camera_tracking_runtime_config(settings)
	var source: Dictionary = settings.get("source", {}) if settings.get("source", {}) is Dictionary else {}
	var source_kind := String(source.get("kind", "")).strip_edges()
	var started := false
	if source_kind == CameraSourcePickerState.MODE_REPLAY and tracking_singleton.has_method("start_replay"):
		started = bool(tracking_singleton.start_replay(String(source.get("path", "")).strip_edges(), runtime_config))
	elif source_kind == CameraSourcePickerState.MODE_LIVE and tracking_singleton.has_method("start_live_camera"):
		started = bool(tracking_singleton.start_live_camera(String(source.get("camera_id", settings.get("camera_source", ""))).strip_edges(), runtime_config))
	elif tracking_singleton.has_method("start"):
		started = bool(tracking_singleton.start(runtime_config))
	if not started:
		_update_hud("AeroCameraTracking did not start. %s" % _camera_tracking_diagnostics_text(tracking_singleton))
	return tracking_singleton

func _camera_tracking_runtime_config(settings: Dictionary) -> Resource:
	var runtime_config := CameraTrackingConfigScript.new()
	runtime_config.profile = mode_id
	var source_id := String(settings.get("selected_camera_device_id", settings.get("camera_source", ""))).strip_edges()
	if not source_id.is_empty() and runtime_config.has_method("set_selected_camera_device_id"):
		runtime_config.set_selected_camera_device_id(source_id)
	var vendor_root := ProjectSettings.globalize_path("res://addons/aerobeat-vendor-mediapipe-python")
	var vendor_python := vendor_root.path_join(".venv/bin/python")
	var vendor_entrypoint := vendor_root.path_join("runtime/mediapipe_runtime_probe.py")
	var vendor_model := vendor_root.path_join("models/pose_landmarker_lite.task")
	if FileAccess.file_exists(vendor_python) and FileAccess.file_exists(vendor_entrypoint):
		runtime_config.runtime = {
			"python_executable": vendor_python,
			"entrypoint": vendor_entrypoint,
			"working_directory": vendor_root,
			"model_complexity": 0,
			"pose_landmarker_model_path": vendor_model if FileAccess.file_exists(vendor_model) else "",
		}
	return runtime_config

func _mode_chart_data() -> Dictionary:
	if mode_id == "boxing":
		return {"targets": _targets.duplicate(true)}
	return {"beats": _targets.duplicate(true)}

func _build_target_nodes() -> void:
	for child in _targets_root.get_children():
		child.queue_free()
	_target_nodes.clear()
	for target in _targets:
		var id := String(target.get("id", "target_%d" % _target_nodes.size()))
		var nodes: Array[Node3D] = []
		for index in range(_target_cells(target).size()):
			var node := _make_target_mesh(target)
			node.name = "%s_cell_%d" % [id, index]
			_targets_root.add_child(node)
			nodes.append(node)
		_target_nodes[id] = nodes

func _make_target_mesh(target: Dictionary) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = _mapper.hit_box_radius_m
	mesh.height = _mapper.hit_box_radius_m * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	var event_name := String(target.get("event", target.get("type", "")))
	material.albedo_color = Color.BLACK if event_name.ends_with("_left") or String(target.get("hand", "")) == "left" else Color.WHITE
	if mode_id == "flow":
		material.albedo_color = Color(0.1, 0.8, 1.0) if String(target.get("hand", "left")) == "left" else Color(1.0, 0.25, 0.4)
	node.material_override = material
	node.visible = false
	return node

func _update_targets(audio_position_sec: float) -> void:
	for target in _targets:
		var id := String(target.get("id", ""))
		var nodes: Array = _target_nodes.get(id, []) if _target_nodes.get(id, []) is Array else []
		if nodes.is_empty():
			continue
		var beat_time := float(target.get("position_sec", 0.0))
		var target_visible := _mapper.target_visible(beat_time, audio_position_sec)
		var cells := _target_cells(target)
		for index in range(nodes.size()):
			var node: Node3D = nodes[index]
			node.visible = target_visible
			if target_visible and index < cells.size():
				node.position = _mapper.cell_center_to_world(cells[index], _mapper.target_z_at_time(beat_time, audio_position_sec))

func _target_cells(target: Dictionary) -> Array[int]:
	return _target_regions.flow_cells_for_target(target) if mode_id == "flow" else _target_regions.boxing_cells_for_target(target)

func _apply_judgements(emitted: Array) -> void:
	for item in emitted:
		if item is RefCounted and item.get("event_type") == "judgement":
			if String(item.get("judgement")) == ModeJudgementEvent.RESULT_HIT:
				_audio_loader.play(String(_config.get("audio", {}).get("hit_sfx_slot", "hit_sfx")))

func _update_player_rig_from_nose() -> void:
	if _input_manager == null:
		return
	var nose: Dictionary = _input_manager.get_body_grid_nose()
	if bool(nose.get("valid", false)):
		_player_rig.position = _mapper.anchor_to_rig_position(nose)

func _update_debug_markers() -> void:
	var debug_config := _as_dict(_config.get("debug", {}))
	var markers_visible: bool = _target_regions.debug_pose_overlay_visible(debug_config, Time.get_ticks_msec(), _overlay_visible_until_ms)
	_markers_root.visible = markers_visible
	if not markers_visible or _input_manager == null:
		return
	_set_marker("Nose", _input_manager.get_body_grid_nose(), Color.YELLOW, _target_regions.debug_marker_enabled(debug_config, "nose"))
	_set_marker("LeftWrist", _input_manager.get_body_grid_left_wrist(), Color.BLACK, _target_regions.debug_marker_enabled(debug_config, "left_wrist"))
	_set_marker("RightWrist", _input_manager.get_body_grid_right_wrist(), Color.WHITE, _target_regions.debug_marker_enabled(debug_config, "right_wrist"))

func _set_marker(name_text: String, anchor: Dictionary, color: Color, enabled: bool = true) -> void:
	var marker: MeshInstance3D = _markers_root.get_node_or_null(name_text)
	if marker == null:
		marker = MeshInstance3D.new()
		marker.name = name_text
		var mesh := SphereMesh.new()
		mesh.radius = 0.06
		mesh.height = 0.12
		marker.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		marker.material_override = mat
		_markers_root.add_child(marker)
	marker.visible = enabled and bool(anchor.get("valid", false))
	if marker.visible:
		marker.position = _mapper.anchor_to_rig_position(anchor) + Vector3(0.0, 0.0, _mapper.hit_plane_z_m)

func _build_grid() -> void:
	for child in _grid_root.get_children():
		child.queue_free()
	_grid_root.visible = _target_regions.debug_grid_visible(_as_dict(_config.get("debug", {})))
	if not _grid_root.visible:
		return
	for cell in range(_mapper.columns * _mapper.rows):
		var cube := MeshInstance3D.new()
		cube.name = "Cell%d" % cell
		var mesh := BoxMesh.new()
		var cell_size := _mapper.get_cell_size()
		mesh.size = Vector3(cell_size.x * 0.96, cell_size.y * 0.96, 0.02)
		cube.mesh = mesh
		cube.position = _mapper.cell_center_to_world(cell, _mapper.hit_plane_z_m + 0.02)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.7, 1.0, 0.18)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cube.material_override = mat
		_grid_root.add_child(cube)

func _load_hit_sfx() -> void:
	var audio_cfg := _as_dict(_config.get("audio", {}))
	var sfx_path := String(audio_cfg.get("hit_sfx_path", "res://assets/hit_sfx.wav"))
	_audio_loader.load({"kind": "file", "path": sfx_path}, String(audio_cfg.get("hit_sfx_slot", "hit_sfx")))

func _update_hud(message: String) -> void:
	var summary := _mapper.debug_snapshot() if _mapper != null else {}
	var camera_text: String = _camera_source.status_text() if _camera_source != null else "Camera source: unavailable"
	_hud.text = "%s\n%s\nMode: %s  Clock: %.3fs  Scale: %s\nCells: 0 UL, 3 UR, 8 LL, 11 LR" % [
		message,
		camera_text,
		mode_id,
		float(_clock.get_position_sec()) if _clock != null else 0.0,
		summary.get("scale_mode", ""),
	]

func _update_camera_source_label() -> void:
	if _camera_source_label != null and _camera_source != null:
		_camera_source_label.text = _camera_source.status_text()

func _song_load_error_text(load_result: Dictionary) -> String:
	var message := String(load_result.get("message", "")).strip_edges()
	if not message.is_empty():
		return message
	return String(load_result.get("error", "unknown"))

func _camera_tracking_diagnostics_text(tracking_singleton: Node = null) -> String:
	var singleton: Node = tracking_singleton if tracking_singleton != null else get_node_or_null("/root/AeroCameraTracking")
	if singleton == null:
		return "AeroCameraTracking: unavailable."
	var ready := singleton.has_method("get_tracking_session_if_ready") and singleton.get_tracking_session_if_ready() != null
	var cameras := _camera_list_text(singleton)
	var error_info: Dictionary = {}
	if singleton.has_method("get_last_error"):
		error_info = singleton.get_last_error()
	var error_text := _camera_error_text(error_info)
	return "AeroCameraTracking ready: %s. Cameras: %s. Last error: %s" % [
		"yes" if ready else "no",
		cameras,
		error_text,
	]

func _camera_list_text(tracking_singleton: Node) -> String:
	var devices: Array = []
	if tracking_singleton.has_method("get_available_camera_devices"):
		devices = tracking_singleton.get_available_camera_devices()
	elif tracking_singleton.has_method("list_cameras"):
		devices = tracking_singleton.list_cameras()
	if devices.is_empty():
		return "none reported"
	var labels: Array[String] = []
	for device_variant in devices:
		if device_variant is Dictionary:
			var device := Dictionary(device_variant)
			labels.append(String(device.get("id", device.get("name", JSON.stringify(device)))))
		else:
			labels.append(String(device_variant))
	return ", ".join(labels)

func _camera_error_text(error_info: Dictionary) -> String:
	if error_info.is_empty():
		return "none reported"
	var raw_message: Variant = error_info.get("message", "")
	if String(raw_message).strip_edges().is_empty():
		raw_message = error_info.get("error", "")
	if String(raw_message).strip_edges().is_empty():
		raw_message = error_info.get("error_code", "")
	if String(raw_message).strip_edges().is_empty():
		raw_message = error_info.get("code", "")
	var message := String(raw_message).strip_edges()
	if message.is_empty():
		message = JSON.stringify(error_info)
	return message

func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

static func dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array:
		return result
	for item in value:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result
