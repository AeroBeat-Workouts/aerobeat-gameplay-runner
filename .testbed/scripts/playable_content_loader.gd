extends RefCounted

const ContentPackageValidator := preload("res://addons/aerobeat-content-core/validators/content_package_validator.gd")
const SimpleYamlParser := preload("res://addons/aerobeat-content-core/validators/simple_yaml_parser.gd")

func load_package(package_path: String, requested_mode: String) -> Dictionary:
	var package_dir := package_path
	if package_path.get_file() == "song.package.yaml":
		package_dir = package_path.get_base_dir()
	var validation: Variant = ContentPackageValidator.new().validate_song_package_yaml_package(package_dir)
	if validation != null and validation.has_method("is_valid") and not validation.is_valid():
		return {"ok": false, "error": "content_core_validation_failed", "package_dir": package_dir}

	var parser := SimpleYamlParser.new()
	var root: Variant = parser.parse_file(package_dir.path_join("song.package.yaml"))
	if not root is Dictionary:
		return {"ok": false, "error": "song_package_yaml_missing", "package_dir": package_dir}
	var chart_descriptor := _first_chart_for_mode(Dictionary(root), requested_mode)
	if chart_descriptor.is_empty():
		return {"ok": false, "error": "chart_for_mode_missing", "mode": requested_mode, "package_dir": package_dir}
	var chart_path := package_dir.path_join(String(chart_descriptor.get("path", "")))
	var chart: Variant = parser.parse_file(chart_path)
	if not chart is Dictionary:
		return {"ok": false, "error": "chart_yaml_missing", "chart_path": chart_path}

	var song := Dictionary(root.get("song", {})) if root.get("song", {}) is Dictionary else {}
	var audio := Dictionary(song.get("audio", {})) if song.get("audio", {}) is Dictionary else {}
	var audio_path := String(audio.get("resourcePath", audio.get("filePath", ""))).strip_edges()
	if not audio_path.is_empty() and not audio_path.begins_with("/") and not audio_path.begins_with("res://") and not audio_path.begins_with("user://"):
		audio_path = package_dir.path_join(audio_path)

	return {
		"ok": true,
		"package_dir": package_dir,
		"root": Dictionary(root),
		"chart": Dictionary(chart),
		"chart_path": chart_path,
		"chart_id": String(chart.get("chartId", chart_descriptor.get("chartId", ""))),
		"mode": requested_mode,
		"events": _events_for_chart(Dictionary(chart), requested_mode),
		"audio_path": audio_path
	}

func _first_chart_for_mode(root: Dictionary, requested_mode: String) -> Dictionary:
	for descriptor in Array(root.get("charts", [])):
		if descriptor is Dictionary and String(descriptor.get("mode", "")).strip_edges() == requested_mode:
			return Dictionary(descriptor)
	return {}

func _events_for_chart(chart: Dictionary, mode_id: String) -> Array:
	var events: Array = []
	for raw in Array(chart.get("beats", [])):
		if not raw is Dictionary:
			continue
		var event := Dictionary(raw).duplicate(true)
		event["position_sec"] = float(event.get("position_sec", event.get("start", 0.0)))
		event["id"] = String(event.get("id", "%s_%03d" % [chart.get("chartId", "chart"), events.size()]))
		if mode_id == "boxing":
			event["type"] = _boxing_runtime_event(String(event.get("type", "")))
		elif mode_id == "flow" and String(event.get("type", "")) == "bomb":
			event["cells"] = [int(event.get("placement", -1))]
			event["end_sec"] = float(event.get("end_sec", event.get("end", float(event.position_sec) + 0.25)))
		events.append(event)
	return events

func _boxing_runtime_event(content_type: String) -> String:
	match content_type:
		"guard":
			return "guard_enabled"
		"squat":
			return "squat_enabled"
		"weave_left":
			return "weave_left_enabled"
		"weave_right":
			return "weave_right_enabled"
		_:
			return content_type
