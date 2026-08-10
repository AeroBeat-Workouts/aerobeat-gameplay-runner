extends RefCounted

const SimpleYamlParserScript := preload("res://addons/aerobeat-content-core/validators/simple_yaml_parser.gd")

## Runner testbed adapter for authored target footprints.
## Boxing transition regions prefer the input-camera-tracking gesture YAML and
## fall back to the frozen 4x3 defaults from the playable-flow plan.

const DEFAULT_BOXING_GESTURE_CONFIG_PATH := "res://addons/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml"
const LEFT_PUNCH_CELL := 5
const RIGHT_PUNCH_CELL := 6

var _columns := 4
var _rows := 3
var _boxing_config := {}

func _init(columns: int = 4, rows: int = 3, boxing_config_path: String = DEFAULT_BOXING_GESTURE_CONFIG_PATH) -> void:
	_columns = maxi(1, columns)
	_rows = maxi(1, rows)
	_boxing_config = _load_yaml_dict(boxing_config_path)

func flow_cells_for_target(target: Dictionary) -> Array[int]:
	var cells: Array[int] = []
	_append_cell(cells, target.get("placement", null))
	_append_cell(cells, target.get("tailPlacement", null))
	_append_cell(cells, target.get("startPlacement", null))
	_append_cell(cells, target.get("endPlacement", null))
	for cell in _as_array(target.get("cells", [])):
		_append_cell(cells, cell)
	return _fallback_if_empty(cells)

func boxing_cells_for_target(target: Dictionary) -> Array[int]:
	var event_name := String(target.get("event", target.get("type", "")))
	match event_name:
		"straight_left", "uppercut_left", "hook_left":
			return [LEFT_PUNCH_CELL]
		"straight_right", "uppercut_right", "hook_right":
			return [RIGHT_PUNCH_CELL]
		"weave_left_enabled", "weave_left_disabled":
			return _weave_cells("left_obstacle", _cells_for_columns([0, 1]))
		"weave_right_enabled", "weave_right_disabled":
			return _weave_cells("right_obstacle", _cells_for_columns([2, 3]))
		"squat_enabled", "squat_disabled":
			return _squat_cells()
		"guard_enabled", "guard_disabled", "neutral", "status":
			return _cells_for_columns([1, 2])
		_:
			return _cells_for_columns([1, 2])

func debug_pose_overlay_visible(debug_config: Dictionary, now_ms: int, visible_until_ms: int) -> bool:
	return bool(debug_config.get("show_body_pose_overlay", true)) or now_ms <= visible_until_ms

func debug_grid_visible(debug_config: Dictionary) -> bool:
	return bool(debug_config.get("show_body_grid_overlay", true))

func debug_marker_enabled(debug_config: Dictionary, marker_name: String) -> bool:
	match marker_name:
		"nose":
			return bool(debug_config.get("show_nose_marker", true))
		"left_wrist":
			return bool(debug_config.get("show_left_wrist_marker", true))
		"right_wrist":
			return bool(debug_config.get("show_right_wrist_marker", true))
		_:
			return true

func _squat_cells() -> Array[int]:
	var obstacle := _as_dict(_as_dict(_as_dict(_boxing_config.get("squat", {})).get("grid_avoidance", {})).get("obstacle", {}))
	var blocked_from_edge := String(obstacle.get("blocked_from_edge", "top"))
	var ratio := clampf(float(obstacle.get("blocked_height_ratio", 0.50)), 0.0, 1.0)
	var blocked_rows := maxi(1, ceili(float(_rows) * ratio))
	var rows_to_block: Array[int] = []
	if blocked_from_edge == "bottom":
		for row in range(_rows - blocked_rows, _rows):
			rows_to_block.append(row)
	else:
		for row in range(blocked_rows):
			rows_to_block.append(row)
	return _cells_for_rows(rows_to_block)

func _weave_cells(obstacle_key: String, fallback: Array[int]) -> Array[int]:
	var obstacle := _as_dict(_as_dict(_as_dict(_boxing_config.get("weave", {})).get("grid_avoidance", {})).get(obstacle_key, {}))
	var authored_cells := _as_array(obstacle.get("occupied_cells", []))
	if not authored_cells.is_empty():
		var cells: Array[int] = []
		for cell in authored_cells:
			_append_cell(cells, cell)
		return _fallback_if_empty(cells, fallback)
	var authored_columns := _as_array(obstacle.get("occupied_columns", []))
	if not authored_columns.is_empty():
		return _cells_for_columns(authored_columns)
	return fallback

func _cells_for_columns(columns: Array) -> Array[int]:
	var cells: Array[int] = []
	for row in range(_rows):
		for column in columns:
			_append_cell(cells, (row * _columns) + int(column))
	return cells

func _cells_for_rows(rows: Array) -> Array[int]:
	var cells: Array[int] = []
	for row in rows:
		for column in range(_columns):
			_append_cell(cells, (int(row) * _columns) + column)
	return cells

func _fallback_if_empty(cells: Array[int], fallback: Array[int] = [0]) -> Array[int]:
	return cells if not cells.is_empty() else fallback

func _append_cell(cells: Array[int], value: Variant) -> void:
	if value == null:
		return
	var cell := clampi(int(value), 0, (_columns * _rows) - 1)
	if not cells.has(cell):
		cells.append(cell)

func _load_yaml_dict(path: String) -> Dictionary:
	var resolved := path
	if path.begins_with("res://"):
		resolved = ProjectSettings.globalize_path(path)
	var parsed: Variant = SimpleYamlParserScript.new().parse_file(resolved)
	return parsed.duplicate(true) if parsed is Dictionary else {}

func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

func _as_array(value: Variant) -> Array:
	return value if value is Array else []
