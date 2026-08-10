extends Node

const AeroEnvironmentLoaderScript := preload("res://addons/aerobeat-environment-loader/src/AeroEnvironmentLoader.gd")
const AeroEnvironmentConstants := preload("res://addons/aerobeat-environment-core/src/contracts/globals/aero_environment_constants.gd")
const SimpleYamlParserScript := preload("res://addons/aerobeat-content-core/validators/simple_yaml_parser.gd")

const ENVIRONMENT_TYPE_TO_KIND := {
	"image_background": "image",
	"video_background": "video",
	"glb_environment": "glb",
	"splat": "splat",
}

signal status_changed(message: String)

var loader: Node = null

func setup(canvas_root: Control, world_root: Node3D) -> void:
	if loader == null:
		loader = AeroEnvironmentLoaderScript.new()
		loader.name = "AeroEnvironmentLoader"
		loader.create_default_roots = false
		add_child(loader)
	loader.canvas_root_path = loader.get_path_to(canvas_root)
	loader.world_root_path = loader.get_path_to(world_root)
	loader.environment_load_started.connect(func(request: Dictionary) -> void:
		status_changed.emit("Environment loading: %s" % request.get("asset_path", ""))
	)
	loader.environment_load_succeeded.connect(func(result: Dictionary) -> void:
		status_changed.emit("Environment ready: %s" % result.get("kind", ""))
	)
	loader.environment_load_failed.connect(func(error: Dictionary) -> void:
		status_changed.emit("Environment failed: %s" % error.get("message", error.get("error_code", "")))
	)

func load_environment_file(path: String) -> void:
	if loader == null:
		status_changed.emit("Environment loader unavailable")
		return
	var request := build_environment_request(path)
	if not bool(request.get("ok", false)):
		status_changed.emit(String(request.get("message", "Unsupported environment format.")))
		return
	match String(request.get("loader_method", "load_environment")):
		"load_environment_from_workout_yaml":
			loader.load_environment_from_workout_yaml(String(request.get("workout_path", path)), _base_context())
		_:
			loader.load_environment(Dictionary(request.get("request", {})))

func build_environment_request(path: String) -> Dictionary:
	var normalized := path.strip_edges()
	if normalized.is_empty():
		return _unsupported_environment_result()
	if normalized.to_lower().ends_with(".yaml") or normalized.to_lower().ends_with(".yml"):
		return _request_for_yaml(normalized)
	var kind := _kind_for_path(normalized)
	if kind.is_empty():
		return _unsupported_environment_result()
	return {
		"ok": true,
		"loader_method": "load_environment",
		"request": _media_request(kind, normalized, {"source": "media_file"}),
	}

func _request_for_yaml(path: String) -> Dictionary:
	var parsed: Variant = SimpleYamlParserScript.new().parse_file(path)
	if not parsed is Dictionary:
		return {"ok": false, "message": "Environment YAML could not be loaded: %s" % path}
	var record := Dictionary(parsed)
	var schema_id := String(record.get("schemaId", "")).strip_edges()
	if schema_id == "aerobeat.workout-package.v1" or path.get_file() == "workout.yaml":
		return {
			"ok": true,
			"loader_method": "load_environment_from_workout_yaml",
			"workout_path": path,
		}
	if schema_id == "aerobeat.environment.v1" or record.has("resourcePath"):
		return _request_for_environment_descriptor(path, record)
	return {"ok": false, "message": "Unsupported environment YAML. Choose workout.yaml, an environment descriptor, or direct media."}

func _request_for_environment_descriptor(descriptor_path: String, record: Dictionary) -> Dictionary:
	var kind := String(ENVIRONMENT_TYPE_TO_KIND.get(String(record.get("type", "")).strip_edges(), "")).strip_edges()
	if kind.is_empty():
		return {"ok": false, "message": "Unsupported environment type: %s" % record.get("type", "")}
	var resource_path := String(record.get("resourcePath", "")).strip_edges()
	if resource_path.is_empty():
		return {"ok": false, "message": "Environment descriptor is missing resourcePath: %s" % descriptor_path}
	var asset_path := _resolve_descriptor_relative_path(descriptor_path, resource_path)
	var config_path := String(record.get("configPath", "")).strip_edges()
	if not config_path.is_empty():
		config_path = _resolve_descriptor_relative_path(descriptor_path, config_path)
	return {
		"ok": true,
		"loader_method": "load_environment",
		"request": _media_request(kind, asset_path, {
			"source": "environment_yaml",
			"environment_id": String(record.get("environmentId", "")),
			"environment_name": String(record.get("environmentName", "")),
			"environment_record_path": descriptor_path,
			"resource_path": resource_path,
		}, config_path),
	}

func _media_request(kind: String, asset_path: String, metadata: Dictionary, config_path: String = "") -> Dictionary:
	var request := {
		"request_id": "runner_testbed_%d" % Time.get_ticks_msec(),
		"kind": kind,
		"asset_path": asset_path,
		"fit_mode": AeroEnvironmentConstants.FIT_MODE_COVER,
		"metadata": {"owner": "runner_testbed"},
	}
	request.metadata.merge(metadata, true)
	if not config_path.is_empty():
		request["config_path"] = config_path
	return request

func _base_context() -> Dictionary:
	return {
		"request_id": "runner_testbed_%d" % Time.get_ticks_msec(),
		"fit_mode": AeroEnvironmentConstants.FIT_MODE_COVER,
		"metadata": {"owner": "runner_testbed"},
	}

func _resolve_descriptor_relative_path(descriptor_path: String, value: String) -> String:
	if value.begins_with("/") or value.begins_with("res://") or value.begins_with("user://"):
		return value
	return descriptor_path.get_base_dir().path_join(value).simplify_path()

func _unsupported_environment_result() -> Dictionary:
	return {
		"ok": false,
		"message": "Unsupported environment format. Supported: YAML descriptors/workouts or %s" % JSON.stringify(AeroEnvironmentConstants.OFFICIAL_FORMATS),
	}

func _kind_for_path(path: String) -> String:
	var lower := path.to_lower()
	for kind in AeroEnvironmentConstants.SUPPORTED_KINDS:
		var format := String(AeroEnvironmentConstants.OFFICIAL_FORMATS.get(kind, ""))
		if not format.is_empty() and lower.ends_with(format):
			return String(kind)
	return ""
