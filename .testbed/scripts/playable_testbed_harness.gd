extends Node3D

const ConfigLoader := preload("res://scripts/playable_config_loader.gd")
const PlayfieldMapperScript := preload("res://scripts/playfield_mapper.gd")
const AudioClock := preload("res://scripts/audio_loader_clock.gd")
const InputStream := preload("res://scripts/input_manager_stream.gd")
const ContentLoader := preload("res://scripts/playable_content_loader.gd")
const EnvironmentAdapter := preload("res://scripts/environment_loader_adapter.gd")
const TargetRegions := preload("res://scripts/playable_target_regions.gd")
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
var _audio_loader: Node = null
var _environment_adapter: Node = null
var _loaded_content := {}
var _targets: Array[Dictionary] = []
var _target_nodes := {}
var _last_tick_msec := 0
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
@onready var _song_dialog: FileDialog = %SongDialog
@onready var _environment_dialog: FileDialog = %EnvironmentDialog

func _ready() -> void:
	_config = ConfigLoader.new().load_config()
	_mapper = PlayfieldMapperScript.new(_config)
	_target_regions = TargetRegions.new(_mapper.columns, _mapper.rows)
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
	_update_hud("Choose song package and environment, then T-pose to calibrate.")

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _last_tick_msec == 0:
		_last_tick_msec = now
	_update_player_rig_from_nose()
	_update_debug_markers()
	if _session != null and _session.get_state() == GameplayRunState.RUNNING:
		var emitted: Array = _session.tick(delta)
		_apply_judgements(emitted)
		_update_targets(float(_clock.get_position_sec()))
		if _session.get_state() == GameplayRunState.COMPLETED:
			_finish_session()
	_last_tick_msec = now

func _setup_input() -> void:
	_input_manager = InputManagerScript.new()
	_input_manager.name = "InputManager"
	add_child(_input_manager)
	if DisplayServer.get_name() == "headless":
		_update_hud("Headless run: live camera provider registration skipped; use the editor for live input proof.")
		return
	var provider := CameraTrackingInputProviderScript.new()
	provider.name = "CameraTrackingInputProvider"
	if not _input_manager.register_provider(provider, {}):
		_update_hud("Camera input provider unavailable in this run; scene remains open for package/environment setup.")
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
	_environment_dialog.filters = PackedStringArray(["*.png,*.ogv,*.glb,*.compressed.ply ; AeroBeat environments"])
	_environment_dialog.file_selected.connect(func(path: String) -> void:
		_environment_adapter.load_environment_file(path)
	)
	%PickSongButton.pressed.connect(func() -> void: _song_dialog.popup_centered_ratio(0.75))
	%PickEnvironmentButton.pressed.connect(func() -> void: _environment_dialog.popup_centered_ratio(0.75))
	%CalibrateButton.pressed.connect(_request_calibration)

func _load_song(path: String) -> void:
	_loaded_content = ContentLoader.new().load_package(path, mode_id)
	if not bool(_loaded_content.get("ok", false)):
		_update_hud("Song load failed: %s" % _loaded_content.get("error", "unknown"))
		return
	_targets = _as_array(_loaded_content.get("events", [])).duplicate(true)
	_build_target_nodes()
	var audio_path := String(_loaded_content.get("audio_path", ""))
	if not audio_path.is_empty():
		_audio_loader.load({"kind": "file", "path": audio_path}, String(_config.get("audio", {}).get("music_slot", "default")))
	_load_hit_sfx()
	_update_hud("Loaded %s chart with %d events. T-pose calibration starts playback." % [mode_id, _targets.size()])

func _request_calibration() -> void:
	if _session != null and _session.get_state() == GameplayRunState.RUNNING:
		_pause_for_recalibration()
	if _input_manager != null and _input_manager.has_method("start_calibration"):
		if not _input_manager.start_calibration():
			_update_hud("Calibration request unavailable; camera provider may not be ready.")

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

func _on_calibration_failed(_event: Dictionary) -> void:
	_paused_for_recalibration = true
	_update_hud("Calibration failed; audio/gameplay remain paused.")

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
	var result: RefCounted = _session.stop("complete")
	var summary: Dictionary = _session.get_score_summary()
	_audio_loader.stop(String(_config.get("audio", {}).get("music_slot", "default")))
	_summary.text = "Complete  Hits: %d  Misses: %d  Score: %d" % [summary.get("hits", 0), summary.get("misses", 0), summary.get("score", 0)]
	_update_hud("Complete.")

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
	var visible: bool = _target_regions.debug_pose_overlay_visible(debug_config, Time.get_ticks_msec(), _overlay_visible_until_ms)
	_markers_root.visible = visible
	if not visible or _input_manager == null:
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
	_hud.text = "%s\nMode: %s  Clock: %.3fs  Scale: %s\nCells: 0 UL, 3 UR, 8 LL, 11 LR" % [
		message,
		mode_id,
		float(_clock.get_position_sec()) if _clock != null else 0.0,
		summary.get("scale_mode", ""),
	]

func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

func _as_array(value: Variant) -> Array:
	return value if value is Array else []
