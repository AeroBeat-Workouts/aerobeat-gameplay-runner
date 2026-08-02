class_name PlayfieldMapper
extends RefCounted
## Runner-owned mapper for input-core top-left body-grid anchors and target cells.
##
## The mapper consumes InputManager/body-grid anchors after provider calibration
## and after any provider/debug preview mirroring. Cell 0 must therefore mean the
## athlete-space upper-left cell and render as first-person upper-left.

const DEFAULT_COLUMNS := 4
const DEFAULT_ROWS := 3

var columns := DEFAULT_COLUMNS
var rows := DEFAULT_ROWS
var origin := "top_left"
var indexing := "row_major"
var athlete_height_m: Variant = null
var playfield_height_ratio := 0.95
var cell_aspect_ratio := 1.2
var fallback_cell_width_m := 0.60
var fallback_cell_height_m := 0.50
var hit_plane_z_m := -1.0
var spawn_distance_m := 12.0
var approach_time_sec := 1.5
var hit_box_radius_m := 0.35
var camera_start_position := Vector3.ZERO
var camera_rotation_deg := Vector3.ZERO
var clamp_horizontal := true
var clamp_vertical := true

func _init(config: Dictionary = {}) -> void:
	apply_config(config)

func apply_config(config: Dictionary) -> void:
	var grid := _dict(config.get("grid", {}))
	columns = maxi(1, int(grid.get("columns", columns)))
	rows = maxi(1, int(grid.get("rows", rows)))
	origin = String(grid.get("origin", origin)).strip_edges()
	indexing = String(grid.get("indexing", indexing)).strip_edges()

	var scale := _dict(config.get("scale", {}))
	athlete_height_m = scale.get("athlete_height_m", athlete_height_m)
	playfield_height_ratio = maxf(0.001, float(scale.get("playfield_height_ratio", playfield_height_ratio)))
	cell_aspect_ratio = maxf(0.001, float(scale.get("cell_aspect_ratio", cell_aspect_ratio)))
	fallback_cell_width_m = maxf(0.001, float(scale.get("fallback_cell_width_m", fallback_cell_width_m)))
	fallback_cell_height_m = maxf(0.001, float(scale.get("fallback_cell_height_m", fallback_cell_height_m)))

	var camera := _dict(config.get("camera", {}))
	camera_start_position = _vector3(camera.get("start_position_m", camera_start_position))
	camera_rotation_deg = _vector3(camera.get("rotation_deg", camera_rotation_deg))
	clamp_horizontal = bool(camera.get("clamp_horizontal", clamp_horizontal))
	clamp_vertical = bool(camera.get("clamp_vertical", clamp_vertical))

	var target := _dict(config.get("target", {}))
	hit_plane_z_m = float(target.get("hit_plane_z_m", hit_plane_z_m))
	spawn_distance_m = maxf(0.0, float(target.get("spawn_distance_m", spawn_distance_m)))
	approach_time_sec = maxf(0.001, float(target.get("approach_time_sec", approach_time_sec)))
	hit_box_radius_m = maxf(0.0, float(target.get("hit_box_radius_m", hit_box_radius_m)))

func get_playfield_size() -> Vector2:
	if _has_known_athlete_height():
		var height := float(athlete_height_m) * playfield_height_ratio
		var cell_height := height / float(rows)
		return Vector2(cell_height * cell_aspect_ratio * float(columns), height)
	return Vector2(fallback_cell_width_m * float(columns), fallback_cell_height_m * float(rows))

func get_cell_size() -> Vector2:
	var size := get_playfield_size()
	return Vector2(size.x / float(columns), size.y / float(rows))

func is_fallback_scale() -> bool:
	return not _has_known_athlete_height()

func cell_to_row_col(cell_index: int) -> Vector2i:
	var clamped := clampi(cell_index, 0, columns * rows - 1)
	return Vector2i(clamped % columns, clamped / columns)

func cell_center_to_world(cell_index: int, z_override: Variant = null) -> Vector3:
	var col_row := cell_to_row_col(cell_index)
	return normalized_to_world(
		Vector2((float(col_row.x) + 0.5) / float(columns), (float(col_row.y) + 0.5) / float(rows)),
		z_override
	)

func normalized_to_world(normalized: Vector2, z_override: Variant = null) -> Vector3:
	var size := get_playfield_size()
	return Vector3(
		(normalized.x - 0.5) * size.x,
		(0.5 - normalized.y) * size.y,
		float(z_override) if z_override != null else hit_plane_z_m
	)

func anchor_to_rig_position(anchor: Dictionary) -> Vector3:
	var x := float(anchor.get("x", 0.5)) if anchor.get("x", null) != null else 0.5
	var y := float(anchor.get("y", 0.5)) if anchor.get("y", null) != null else 0.5
	var normalized := Vector2(
		clampf(x, 0.0, 1.0) if clamp_horizontal else x,
		clampf(y, 0.0, 1.0) if clamp_vertical else y
	)
	var world := normalized_to_world(normalized, 0.0)
	world.z = 0.0
	return world

func target_spawn_z() -> float:
	return hit_plane_z_m - spawn_distance_m

func target_z_at_time(position_sec: float, audio_position_sec: float) -> float:
	var visible_at := position_sec - approach_time_sec
	var ratio := clampf((audio_position_sec - visible_at) / approach_time_sec, 0.0, 1.0)
	return lerpf(target_spawn_z(), hit_plane_z_m, ratio)

func target_visible(position_sec: float, audio_position_sec: float) -> bool:
	return audio_position_sec >= position_sec - approach_time_sec and audio_position_sec <= position_sec + approach_time_sec

func get_camera_start_transform() -> Transform3D:
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(camera_rotation_deg.x),
		deg_to_rad(camera_rotation_deg.y),
		deg_to_rad(camera_rotation_deg.z)
	))
	return Transform3D(basis, camera_start_position)

func debug_snapshot() -> Dictionary:
	var size := get_playfield_size()
	var cell_size := get_cell_size()
	return {
		"columns": columns,
		"rows": rows,
		"origin": origin,
		"indexing": indexing,
		"playfield_width_m": size.x,
		"playfield_height_m": size.y,
		"cell_width_m": cell_size.x,
		"cell_height_m": cell_size.y,
		"hit_plane_z_m": hit_plane_z_m,
		"spawn_z_m": target_spawn_z(),
		"approach_time_sec": approach_time_sec,
		"hit_box_radius_m": hit_box_radius_m,
		"scale_mode": "fallback" if is_fallback_scale() else "athlete_height"
	}

func _has_known_athlete_height() -> bool:
	return athlete_height_m != null and float(athlete_height_m) > 0.0

static func _dict(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}

static func _vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is String:
		var cleaned := String(value).strip_edges().trim_prefix("[").trim_suffix("]")
		var parts := cleaned.split(",", false)
		if parts.size() >= 3:
			return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	return Vector3.ZERO
